[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^(?:[BbMm]\d+[A-Za-z]?|[Pp][Ss]-\d+)$')]
    [string]$Milestone,

    [ValidateSet('Custom', 'Focused', 'Relevant', 'Full', 'Release')]
    [string]$Profile = 'Custom',
    [string[]]$FocusedSmoke = @(),
    [string[]]$RegressionSmoke = @(),
    [string[]]$ChangedPath = @(),
    [string]$TestMap = 'tools\milestone-test-map.json',
    [switch]$RefreshEditor,
    [switch]$RunToolchain,
    [switch]$RunProjectSmoke,
    [switch]$ExportWindows,
    [switch]$ExportAndroid,
    [switch]$InspectAndroid,
    [string]$WindowsArtifact = 'exports\windows\PidgeonSurvivor.exe',
    [string]$AndroidArtifact = 'exports\android\pidgeon-survivor-debug.apk',
    [ValidateRange(30, 3600)]
    [int]$ExportTimeoutSeconds = 120,
    [ValidateRange(3, 60)]
    [int]$AndroidArtifactStableSeconds = 8,
    [ValidateRange(10, 600)]
    [int]$RuntimeTimeoutSeconds = 120,
    [ValidateRange(60, 3600)]
    [int]$GutTimeoutSeconds = 1800,
    [ValidateSet('Compact', 'Detailed')]
    [string]$OutputMode = 'Compact',
    [switch]$NoCache,
    [switch]$PlanOnly,
    [switch]$KeepGoing,
    [switch]$AsJson
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$runnerVersion = '2'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$Milestone = $Milestone.ToUpperInvariant()
$Profile = [cultureinfo]::InvariantCulture.TextInfo.ToTitleCase($Profile.ToLowerInvariant())
$logRoot = Join-Path (
    Join-Path ([IO.Path]::GetTempPath()) 'il-gioco-verification'
) ((Get-Date -Format 'yyyyMMdd-HHmmss') + "-$Milestone")
New-Item -ItemType Directory -Force -Path $logRoot | Out-Null

$steps = [Collections.Generic.List[object]]::new()
$halted = $false
$androidInspection = $null
$failurePattern = '(?im)(SCRIPT ERROR|FATAL EXCEPTION|SMOKE_FAIL|CONTRACT_FAIL)'
$markerPattern = '(?m)\b(?:[A-Z][A-Z0-9_]*_SMOKE_OK|SMOKE_OK)\b'
# Godot dichiara la fine dell'export con '[ DONE ] export'. La stessa etichetta
# compare anche per 'first_scan_filesystem', quindi il passo va nominato: senza,
# il completamento verrebbe letto molto prima che l'APK esista.
$androidExportCompletionPattern = '^\[ DONE \]\s+export\b'
$cacheEnabled = -not $NoCache

function Set-AndroidGradleDaemonDisabled {
    param(
        [Parameter(Mandatory)]
        [string]$RepoRoot
    )

    $propertiesPath = Join-Path $RepoRoot 'android\build\gradle.properties'
    if (-not (Test-Path -LiteralPath $propertiesPath -PathType Leaf)) {
        return [pscustomobject]@{
            status = 'SKIPPED'
            note = 'android/build/gradle.properties assente: template non ancora installato.'
        }
    }

    $content = Get-Content -LiteralPath $propertiesPath -Raw
    if ($content -match '(?m)^\s*org\.gradle\.daemon\s*=\s*false\s*$') {
        return [pscustomobject]@{
            status = 'PASS'
            note = 'org.gradle.daemon=false gia'' presente.'
        }
    }

    # docs/setup.md: --install-android-build-template rigenera questo file
    # gitignored e perde questa riga. Senza, il daemon Gradle si stacca dal
    # processo Godot che esporta ma eredita i suoi handle di stdout/stderr su
    # Windows, cosicche' chi legge l'output di quel processo aspettando l'EOF
    # resta appeso anche a build e APK gia' completi.
    Add-Content -LiteralPath $propertiesPath -Encoding utf8 -Value @(
        ''
        '# Reapplied automatically by run-milestone-checks.ps1 (docs/setup.md):'
        '# without this, Gradle''s detached daemon inherits Godot''s stdout/stderr'
        '# handles on Windows and the export process hangs after the APK is done.'
        'org.gradle.daemon=false'
    )
    return [pscustomobject]@{
        status = 'PASS'
        note = 'org.gradle.daemon=false riapplicato (mancava dopo la rigenerazione del template).'
    }
}


function Get-StringHash {
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Text
    )

    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [Text.Encoding]::UTF8.GetBytes($Text)
        return ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-', '')
    }
    finally {
        $sha.Dispose()
    }
}

$cacheRoot = Join-Path (
    Join-Path ([IO.Path]::GetTempPath()) 'il-gioco-verification\cache'
) (Get-StringHash -Text $repoRoot.ToLowerInvariant())

function Get-FileContentHash {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return 'MISSING'
    }
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

. (Join-Path $PSScriptRoot 'lib\process-capture.ps1')
. (Join-Path $PSScriptRoot 'lib\gut-batch-status.ps1')


function Resolve-GodotConsole {
    $command = Get-Command godot_console.exe -ErrorAction SilentlyContinue
    if ($null -ne $command) {
        return $command.Source
    }

    $fallback = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links\godot_console.exe'
    if (Test-Path -LiteralPath $fallback -PathType Leaf) {
        return $fallback
    }
    throw 'godot_console.exe non trovato. Consulta docs/setup.md.'
}

function Resolve-RepositoryPath {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [switch]$MustExist
    )

    $resolved = if ([IO.Path]::IsPathRooted($Path)) {
        [IO.Path]::GetFullPath($Path)
    }
    else {
        [IO.Path]::GetFullPath((Join-Path $repoRoot $Path))
    }
    $repoPrefix = $repoRoot.TrimEnd('\') + '\'
    if (-not $resolved.StartsWith($repoPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Percorso fuori dal repository: $Path"
    }
    if ($MustExist -and -not (Test-Path -LiteralPath $resolved -PathType Leaf)) {
        throw "File non trovato: $resolved"
    }
    return $resolved
}

function ConvertTo-RepositoryRelativePath {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $resolved = Resolve-RepositoryPath -Path $Path
    return $resolved.Substring($repoRoot.Length + 1).Replace('\', '/')
}

function Get-AllGutTests {
    return @(
        Get-ChildItem -LiteralPath (Join-Path $repoRoot 'tests') -Filter 'test_*.gd' -File -Recurse |
            Sort-Object FullName |
            ForEach-Object { $_.FullName }
    )
}

# I test GUT non stampano piu' un marker <MILESTONE>_..._SMOKE_OK (rimosso in
# conversione): la conversione fedele ha comunque preservato i messaggi di
# asserzione originali, che nella maggioranza dei file citano il proprio
# milestone (es. "B18B richiede..."). Il grep sul contenuto resta quindi un
# sovrainsieme sicuro del comportamento legacy: mai piu' stretto, al piu' piu'
# ampio per i file dove il marker storico non portava un ID di milestone.
function Find-FocusedGutTests {
    param(
        [Parameter(Mandatory)]
        [string]$MilestoneId
    )

    $pattern = '\b' + [regex]::Escape($MilestoneId) + '\b'
    return @(
        Get-ChildItem -LiteralPath (Join-Path $repoRoot 'tests') -Filter 'test_*.gd' -File -Recurse |
            Where-Object { Select-String -LiteralPath $_.FullName -Pattern $pattern -Quiet } |
            ForEach-Object { $_.FullName }
    )
}

function Invoke-GitLines {
    # PS 5.1 promuove ogni riga di stderr di un comando nativo redirezionato
    # (anche con 2>$null) a NativeCommandError quando $ErrorActionPreference
    # e' 'Stop', facendo fallire lo script pure con exit code 0 (es. warning
    # CRLF/eol=lf di git). Abbassare la preference solo per la durata della
    # chiamata nativa evita la promozione senza nascondere un vero fallimento,
    # che resta rilevato dal solo $LASTEXITCODE (PS-031).
    param(
        [Parameter(Mandatory)]
        [string[]]$GitArgs,

        [Parameter(Mandatory)]
        [string]$FailureMessage
    )

    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $lines = @(& git -C $repoRoot @GitArgs 2>$null)
    } finally {
        $ErrorActionPreference = $previousPreference
    }
    if ($LASTEXITCODE -ne 0) {
        throw $FailureMessage
    }
    return @($lines)
}

function Get-ChangedRepositoryPaths {
    if ($ChangedPath.Count -gt 0) {
        return @($ChangedPath | ForEach-Object { $_.Replace('\', '/') } | Sort-Object -Unique)
    }

    $tracked = Invoke-GitLines -GitArgs @('diff', '--name-only', 'HEAD', '--') `
        -FailureMessage 'git diff --name-only HEAD fallito durante la selezione dei test.'
    $untracked = Invoke-GitLines -GitArgs @('ls-files', '--others', '--exclude-standard') `
        -FailureMessage 'git ls-files --others fallito durante la selezione dei test.'
    return @(
        @($tracked) + @($untracked) |
            ForEach-Object { $_.Replace('\', '/') } |
            Sort-Object -Unique
    )
}

function Test-IsRuntimePath {
    param([string]$Path)

    $normalized = $Path.Replace('\', '/')
    if ($normalized -match '(^|/)hd/') {
        return $false
    }
    # Un manifest, un README o un .gdignore dentro assets/ descrivono gli
    # asset, non sono asset: senza questa esclusione una card che aggiorna la
    # propria documentazione finisce fra le path runtime non mappate e viene
    # segnalata come priva di regola, anche se non ha alcuna regressione da
    # coprire (PS-023).
    if (
        $normalized -match '\.(md|txt)$' -or
        $normalized -match '(^|/)\.gdignore$'
    ) {
        return $false
    }
    return $normalized -match '^(project\.godot|export_presets\.cfg|scenes/|scripts/|data/|assets/)'
}

function Find-RelevantSmokes {
    param(
        [Parameter(Mandatory)]
        [string[]]$Paths,

        [Parameter(Mandatory)]
        [string]$MapPath
    )

    $resolvedMap = Resolve-RepositoryPath -Path $MapPath -MustExist
    $map = Get-Content -LiteralPath $resolvedMap -Raw -Encoding UTF8 | ConvertFrom-Json
    $selected = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $unmatchedRuntime = [Collections.Generic.List[string]]::new()

    foreach ($changed in $Paths) {
        $normalized = $changed.Replace('\', '/')
        if ($normalized -match '^tests/(unit|integration)/.*/?test_[^/]+\.gd$') {
            # Un test eliminato compare comunque in git diff --name-only HEAD:
            # senza questo controllo il path cancellato finiva nel set
            # "focused"/regressione e faceva crashare Resolve-RepositoryPath
            # -MustExist piu' avanti nella pipeline (PS-030).
            if (Test-Path -LiteralPath (Join-Path $repoRoot $normalized) -PathType Leaf) {
                $selected.Add($normalized) | Out-Null
            }
            continue
        }
        if (-not (Test-IsRuntimePath -Path $normalized)) {
            continue
        }

        $matched = $false
        foreach ($rule in @($map.rules)) {
            $matchesRule = $false
            foreach ($pattern in @($rule.patterns)) {
                if ($normalized -like [string]$pattern) {
                    $matchesRule = $true
                    break
                }
            }
            if (-not $matchesRule) {
                continue
            }
            $matched = $true
            foreach ($smoke in @($rule.smokes)) {
                $selected.Add([string]$smoke) | Out-Null
            }
        }
        if (-not $matched) {
            $unmatchedRuntime.Add($normalized)
        }
    }

    # Relevant resta un checkpoint delimitato: un path runtime senza regola
    # in $MapPath non fa piu' scattare l'intera suite (troppo lento per un
    # checkpoint frequente). Viene solo segnalato, cosi' chi lancia il runner
    # sa che quel path non ha regressioni automatiche e puo' aggiungerle a
    # mano con -RegressionSmoke o coprirle con un profilo Full.
    if ($unmatchedRuntime.Count -gt 0) {
        $preview = ($unmatchedRuntime | Select-Object -First 8) -join ', '
        if ($unmatchedRuntime.Count -gt 8) {
            $preview += ", ... (+$($unmatchedRuntime.Count - 8) altri)"
        }
        Write-Host (
            "... relevant: $($unmatchedRuntime.Count) path runtime senza regola in $MapPath, " +
            "nessuna regressione automatica per questi path. Path: $preview"
        )
    }
    return @($selected | Sort-Object)
}

function Get-RepositoryRuntimeFiles {
    $tracked = Invoke-GitLines -GitArgs @('ls-files') `
        -FailureMessage 'git ls-files fallito durante il calcolo della cache.'
    $untracked = Invoke-GitLines -GitArgs @('ls-files', '--others', '--exclude-standard') `
        -FailureMessage 'git ls-files --others fallito durante il calcolo della cache.'
    return @(
        @($tracked) + @($untracked) |
            ForEach-Object { $_.Replace('\', '/') } |
            Where-Object { Test-IsRuntimePath -Path $_ } |
            Sort-Object -Unique
    )
}

function Get-CombinedRepositoryHash {
    param(
        [Parameter(Mandatory)]
        [string[]]$Paths
    )

    $entries = foreach ($relative in $Paths) {
        $absolute = Join-Path $repoRoot $relative.Replace('/', '\')
        "$relative|$(Get-FileContentHash -Path $absolute)"
    }
    return Get-StringHash -Text ($entries -join "`n")
}

function Get-CacheFilePath {
    param(
        [Parameter(Mandatory)]
        [string]$Key
    )

    return Join-Path $cacheRoot ((Get-StringHash -Text $Key) + '.json')
}

function Get-CachedStep {
    param(
        [Parameter(Mandatory)]
        [string]$Key,

        [Parameter(Mandatory)]
        [string]$InputHash,

        [string]$ArtifactPath
    )

    if (-not $cacheEnabled) {
        return $null
    }
    $cachePath = Get-CacheFilePath -Key $Key
    if (-not (Test-Path -LiteralPath $cachePath -PathType Leaf)) {
        return $null
    }
    try {
        $entry = Get-Content -LiteralPath $cachePath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($entry.input_hash -ne $InputHash -or $entry.status -ne 'PASS') {
            return $null
        }
        if (-not [string]::IsNullOrWhiteSpace($ArtifactPath)) {
            if (-not (Test-Path -LiteralPath $ArtifactPath -PathType Leaf)) {
                return $null
            }
            if ((Get-FileContentHash -Path $ArtifactPath) -ne $entry.artifact_hash) {
                return $null
            }
        }
        return $entry
    }
    catch {
        return $null
    }
}

function Save-CachedStep {
    param(
        [Parameter(Mandatory)]
        [string]$Key,

        [Parameter(Mandatory)]
        [string]$InputHash,

        [Parameter(Mandatory)]
        [object]$Step,

        [string]$ArtifactPath
    )

    if (-not $cacheEnabled -or $Step.status -ne 'PASS') {
        return
    }
    New-Item -ItemType Directory -Force -Path $cacheRoot | Out-Null
    $artifactHash = if (
        -not [string]::IsNullOrWhiteSpace($ArtifactPath) -and
        (Test-Path -LiteralPath $ArtifactPath -PathType Leaf)
    ) {
        Get-FileContentHash -Path $ArtifactPath
    }
    else {
        $null
    }
    $entry = [ordered]@{
        version = $runnerVersion
        key = $Key
        input_hash = $InputHash
        status = 'PASS'
        markers = @($Step.markers)
        artifact_hash = $artifactHash
        created_utc = [DateTime]::UtcNow.ToString('o')
    }
    [IO.File]::WriteAllText(
        (Get-CacheFilePath -Key $Key),
        ($entry | ConvertTo-Json -Depth 5 -Compress),
        [Text.UTF8Encoding]::new($false)
    )
}

function Add-CachedStep {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$Category,

        [Parameter(Mandatory)]
        [object]$CacheEntry
    )

    $safeName = $Name -replace '[^A-Za-z0-9_.-]', '_'
    $logPath = Join-Path $logRoot ($safeName + '.log')
    [IO.File]::WriteAllText(
        $logPath,
        "CACHED input_hash=$($CacheEntry.input_hash) created_utc=$($CacheEntry.created_utc)",
        [Text.UTF8Encoding]::new($false)
    )
    $step = [pscustomobject]@{
        name = $Name
        category = $Category
        status = 'CACHED'
        exit_code = 0
        timed_out = $false
        duration_ms = 0
        markers = @($CacheEntry.markers)
        error_markers = @()
        note = 'Input hash invariato; risultato verde riutilizzato.'
        log = $logPath
    }
    $steps.Add($step)
    return $step
}

function Add-ProcessStep {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$Category,

        [Parameter(Mandatory)]
        [pscustomobject]$ProcessResult,

        [switch]$RequireSmokeMarker,
        [switch]$DoNotHalt
    )

    $safeName = $Name -replace '[^A-Za-z0-9_.-]', '_'
    $logPath = Join-Path $logRoot ($safeName + '.log')
    [IO.File]::WriteAllText($logPath, $ProcessResult.Output, [Text.UTF8Encoding]::new($false))

    $markers = @(
        [regex]::Matches($ProcessResult.Output, $markerPattern) |
            ForEach-Object { $_.Value } |
            Sort-Object -Unique
    )
    $errorMarkers = @(
        [regex]::Matches($ProcessResult.Output, $failurePattern) |
            ForEach-Object { $_.Value.ToUpperInvariant() } |
            Sort-Object -Unique
    )
    $passed = ($ProcessResult.ExitCode -eq 0) -and
        (-not $ProcessResult.TimedOut) -and
        ($errorMarkers.Count -eq 0) -and
        ((-not $RequireSmokeMarker) -or ($markers.Count -gt 0))

    $step = [pscustomobject]@{
        name = $Name
        category = $Category
        status = if ($passed) { 'PASS' } else { 'FAIL' }
        exit_code = $ProcessResult.ExitCode
        timed_out = $ProcessResult.TimedOut
        duration_ms = $ProcessResult.DurationMs
        markers = @($markers)
        error_markers = @($errorMarkers)
        note = $null
        log = $logPath
    }
    $steps.Add($step)

    if (-not $passed -and -not $KeepGoing -and -not $DoNotHalt) {
        $script:halted = $true
    }
    return $step
}

function Get-GutJUnitResults {
    param(
        [Parameter(Mandatory)]
        [string]$XmlPath
    )

    if (-not (Test-Path -LiteralPath $XmlPath -PathType Leaf)) {
        return $null
    }
    [xml]$xml = Get-Content -LiteralPath $XmlPath -Raw -Encoding UTF8
    $suites = [Collections.Generic.List[object]]::new()
    foreach ($suite in @($xml.testsuites.testsuite)) {
        $failures = [int]$suite.failures
        $suites.Add([pscustomobject]@{
            path = [string]$suite.name
            tests = [int]$suite.tests
            failures = $failures
            skipped = [int]$suite.skipped
            status = if ($failures -eq 0) { 'PASS' } else { 'FAIL' }
        }) | Out-Null
    }
    return @($suites)
}

# Una sola invocazione GUT copre molti file: la cache per l'intero batch (non
# per singolo file) memorizza l'esito per-script cosi' che un cache hit possa
# rimaterializzare gli stessi $steps senza rilanciare ne' riparsare l'XML.
function Get-GutCachedBatch {
    param(
        [Parameter(Mandatory)]
        [string]$Key,

        [Parameter(Mandatory)]
        [string]$InputHash
    )

    if (-not $cacheEnabled) {
        return $null
    }
    $cachePath = Get-CacheFilePath -Key $Key
    if (-not (Test-Path -LiteralPath $cachePath -PathType Leaf)) {
        return $null
    }
    try {
        $entry = Get-Content -LiteralPath $cachePath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($entry.input_hash -ne $InputHash -or $entry.status -ne 'PASS') {
            return $null
        }
        return $entry
    }
    catch {
        return $null
    }
}

function Save-GutCachedBatch {
    param(
        [Parameter(Mandatory)]
        [string]$Key,

        [Parameter(Mandatory)]
        [string]$InputHash,

        [Parameter(Mandatory)]
        [object[]]$Scripts,

        [Parameter(Mandatory)]
        [string]$Status
    )

    if (-not $cacheEnabled -or $Status -ne 'PASS') {
        return
    }
    New-Item -ItemType Directory -Force -Path $cacheRoot | Out-Null
    $entry = [ordered]@{
        version = $runnerVersion
        key = $Key
        input_hash = $InputHash
        status = $Status
        scripts = @($Scripts)
        created_utc = [DateTime]::UtcNow.ToString('o')
    }
    [IO.File]::WriteAllText(
        (Get-CacheFilePath -Key $Key),
        ($entry | ConvertTo-Json -Depth 6 -Compress),
        [Text.UTF8Encoding]::new($false)
    )
}

function Add-GutStepsFromScripts {
    param(
        [Parameter(Mandatory)]
        [object[]]$Scripts,

        [Parameter(Mandatory)]
        [string]$Category,

        [Parameter(Mandatory)]
        [string]$LogPath,

        [int]$DurationMs = 0,
        [int]$ExitCode = 0,
        [bool]$TimedOut = $false,
        [switch]$Cached
    )

    $added = [Collections.Generic.List[object]]::new()
    foreach ($scriptResult in $Scripts) {
        $status = if ($Cached) { 'CACHED' } else { $scriptResult.status }
        $note = if ($Cached) {
            'Input hash invariato; risultato GUT verde riutilizzato.'
        }
        elseif ($scriptResult.status -eq 'FAIL') {
            "GUT: $($scriptResult.failures)/$($scriptResult.tests) test falliti."
        }
        else {
            $null
        }
        $step = [pscustomobject]@{
            name = "$Category-$($scriptResult.path)"
            category = $Category
            status = $status
            exit_code = if ($Cached) { 0 } else { $ExitCode }
            timed_out = if ($Cached) { $false } else { $TimedOut }
            duration_ms = $DurationMs
            markers = @()
            error_markers = @()
            note = $note
            log = $LogPath
        }
        $steps.Add($step)
        $added.Add($step) | Out-Null
        if ($status -eq 'FAIL' -and -not $KeepGoing) {
            $script:halted = $true
        }
    }
    return @($added)
}

# Un solo processo Godot esegue tutti i file selezionati per il batch: la
# selettivita' per profilo (Focused/Relevant/Full/Release) sceglie quali
# path passare, non quanti processi lanciare.
function Invoke-GutBatch {
    param(
        [Parameter(Mandatory)]
        [string]$Category,

        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [string[]]$TestPaths,

        [Parameter(Mandatory)]
        [string]$GodotPath,

        [Parameter(Mandatory)]
        [string]$RuntimeHash,

        [Parameter(Mandatory)]
        [string]$RunnerHash,

        [Parameter(Mandatory)]
        [string]$GodotVersion
    )

    if ($TestPaths.Count -eq 0) {
        return @()
    }

    $resolvedPaths = @($TestPaths | Sort-Object -Unique)
    $relativePaths = @($resolvedPaths | ForEach-Object { ConvertTo-RepositoryRelativePath -Path $_ })
    $cacheKey = "gut|$Category|" + ($relativePaths -join ',')
    $contentSignature = (
        @($resolvedPaths | ForEach-Object { "$_|$(Get-FileContentHash -Path $_)" }) -join "`n"
    )
    $inputHash = Get-StringHash -Text (
        "$runnerVersion|$RunnerHash|$GodotVersion|$RuntimeHash|$contentSignature"
    )

    $safeName = "gut-$Category" -replace '[^A-Za-z0-9_.-]', '_'
    $logPath = Join-Path $logRoot ($safeName + '.log')

    $cached = Get-GutCachedBatch -Key $cacheKey -InputHash $inputHash
    if ($null -ne $cached) {
        [IO.File]::WriteAllText(
            $logPath,
            "CACHED input_hash=$($cached.input_hash) created_utc=$($cached.created_utc)",
            [Text.UTF8Encoding]::new($false)
        )
        return Add-GutStepsFromScripts -Scripts @($cached.scripts) -Category $Category `
            -LogPath $logPath -Cached
    }

    $junitPath = Join-Path $logRoot ($safeName + '.junit.xml')
    $resPaths = @($relativePaths | ForEach-Object { "res://$_" })
    # Silenzio e blocco si somigliano: una riga al minuto dice che il batch e'
    # vivo e a che punto e'. Write-Host, non Write-Output, per non inquinare lo
    # stdout letto da -AsJson (PS-023).
    $batchLabel = $Category
    $batchTotal = $resolvedPaths.Count
    $progressAction = {
        param([TimeSpan]$Elapsed, [object]$Lines)

        $started = @($Lines | Where-Object { $_ -match 'res://tests/[^\s,]+\.gd' })
        $last = if ($started.Count -gt 0) {
            [regex]::Match($started[-1], 'res://tests/[^\s,]+\.gd').Value
        }
        else { '(avvio)' }
        Write-Host (
            '... gut-{0} vivo da {1:hh\:mm\:ss}: {2}/{3} script, ultimo {4}' -f
                $batchLabel, $Elapsed, $started.Count, $batchTotal, $last
        )
    }.GetNewClosure()

    $processResult = Invoke-CapturedProcess -FilePath $GodotPath -Arguments @(
        '--headless',
        '--path', $repoRoot,
        '--resolution', '1280x720',
        '-s', 'addons/gut/gut_cmdln.gd',
        ('-gtest=' + ($resPaths -join ',')),
        '-gexit',
        ('-gjunit_xml_file=' + $junitPath)
    ) -WorkingDirectory $repoRoot -TimeoutSeconds $GutTimeoutSeconds `
        -ProgressIntervalSeconds 60 -ProgressAction $progressAction

    [IO.File]::WriteAllText($logPath, $processResult.Output, [Text.UTF8Encoding]::new($false))

    # Un errore Godot (SCRIPT ERROR, FATAL EXCEPTION) puo' comparire senza che
    # GUT lo traduca in un'asserzione fallita: l'exit code 0 non basta, come
    # per gli smoke legacy (CLAUDE.md, "Onesta' dei gate"). Da qui la ricerca
    # testuale sull'intero output, che alimenta Get-GutBatchFailureReasons.
    $errorMarkers = @(
        [regex]::Matches($processResult.Output, $failurePattern) |
            ForEach-Object { $_.Value.ToUpperInvariant() } |
            Sort-Object -Unique
    )
    $rawScripts = Get-GutJUnitResults -XmlPath $junitPath

    if ($null -eq $rawScripts) {
        $step = [pscustomobject]@{
            name = "$Category-gut-batch"
            category = $Category
            status = 'FAIL'
            exit_code = $processResult.ExitCode
            timed_out = $processResult.TimedOut
            duration_ms = $processResult.DurationMs
            markers = @()
            error_markers = @($errorMarkers)
            note = if ($processResult.TimedOut) {
                "TIMEOUT dopo $GutTimeoutSeconds s prima che GUT scrivesse il report: " +
                'processo terminato, log parziale conservato.'
            }
            else {
                'Report JUnit GUT assente o illeggibile: nessun test eseguito o crash prima del report.'
            }
            log = $logPath
        }
        $steps.Add($step)
        if (-not $KeepGoing) {
            $script:halted = $true
        }
        return @($step)
    }
    # @() forza il contesto array: un batch con un solo file fa collassare il
    # valore di ritorno a scalare se non viene rifatto l'wrap qui, alla
    # chiamata (gotcha noto di PowerShell sull'unwrap degli array a un
    # elemento).
    $scripts = @($rawScripts)

    $addedSteps = @(Add-GutStepsFromScripts -Scripts $scripts -Category $Category `
        -LogPath $logPath -DurationMs $processResult.DurationMs `
        -ExitCode $processResult.ExitCode -TimedOut $processResult.TimedOut)

    # GUT con -gexit esce non-zero appena un test fallisce, e quel rosso e' gia'
    # attribuito al suo script dal report JUnit. Prima bastava quell'exit code
    # per forzare FAIL su ogni script del batch: 65 righe rosse per un solo test
    # davvero fallito. Restano fallimenti di batch soltanto le cause non
    # attribuibili a un singolo script (PS-023).
    $reportedFailures = @($scripts | Where-Object { $_.status -eq 'FAIL' }).Count
    $batchReasons = @(Get-GutBatchFailureReasons `
        -ExitCode $processResult.ExitCode `
        -TimedOut ([bool]$processResult.TimedOut) `
        -ErrorMarkers @($errorMarkers) `
        -ReportedFailures $reportedFailures `
        -TimeoutSeconds $GutTimeoutSeconds)
    if ($batchReasons.Count -gt 0) {
        $batchStep = [pscustomobject]@{
            name = "$Category-gut-batch"
            category = $Category
            status = 'FAIL'
            exit_code = $processResult.ExitCode
            timed_out = $processResult.TimedOut
            duration_ms = $processResult.DurationMs
            markers = @()
            error_markers = @($errorMarkers)
            note = ($batchReasons -join ' ')
            log = $logPath
        }
        $steps.Add($batchStep)
        $addedSteps = @($addedSteps) + @($batchStep)
        if (-not $KeepGoing) {
            $script:halted = $true
        }
    }
    $overallStatus = if (@($addedSteps | Where-Object { $_.status -eq 'FAIL' }).Count -gt 0) {
        'FAIL'
    }
    else {
        'PASS'
    }
    Save-GutCachedBatch -Key $cacheKey -InputHash $inputHash -Scripts $scripts -Status $overallStatus
    return $addedSteps
}

function Get-CategorySummary {
    param([string]$Category)

    $matching = @($steps | Where-Object { $_.category -eq $Category })
    if ($matching.Count -eq 0) {
        return $null
    }
    $successful = @($matching | Where-Object { $_.status -ne 'FAIL' }).Count
    return "$successful/$($matching.Count)"
}

# Il vocabolario interno degli stati resta invariato (PASS/FAIL/CACHED/...):
# qui si distingue soltanto, in lettura, un batch scaduto da un test rosso.
function Get-StepDisplayStatus {
    param([object]$Step)

    if (
        $Step.status -eq 'FAIL' -and
        ($Step.PSObject.Properties.Name -contains 'timed_out') -and
        $Step.timed_out
    ) {
        return 'TIMEOUT'
    }
    return $Step.status
}

# Diagnostica di avanzamento: Write-Host, non Write-Output, per non
# inquinare lo stdout letto da -AsJson (stesso pattern del batch GUT sotto).
function Write-StepStart {
    param([Parameter(Mandatory)][string]$Message)

    Write-Host "==> $Message"
}

function Write-StepDone {
    param(
        [Parameter(Mandatory)][string]$Message,
        [Parameter(Mandatory)][object]$Step
    )

    Write-Host (
        '<== {0}: {1} ({2} ms)' -f $Message, (Get-StepDisplayStatus -Step $Step), $Step.duration_ms
    )
}

# Heartbeat generico per gli step non-GUT (refresh editor, toolchain, export,
# ispezione): senza, uno step lungo che non stampa nulla per conto suo e'
# indistinguibile da un blocco.
function New-GenericProgressAction {
    param([Parameter(Mandatory)][string]$Label)

    return {
        param([TimeSpan]$Elapsed, [object]$Lines)
        $lastLine = if ($Lines.Count -gt 0) { $Lines[-1] } else { '(nessun output ancora)' }
        Write-Host ('... {0} vivo da {1:hh\:mm\:ss}: {2}' -f $Label, $Elapsed, $lastLine)
    }.GetNewClosure()
}

function Write-RunnerOutput {
    param(
        [Parameter(Mandatory)]
        [object]$Summary
    )

    if ($AsJson) {
        $Summary | ConvertTo-Json -Depth 10 -Compress
        return
    }
    if ($OutputMode -eq 'Detailed') {
        Write-Output "IL_GIOCO_VERIFICATION milestone=$Milestone profile=$Profile status=$($Summary.status)"
        foreach ($step in $steps) {
            $markerText = if ($step.markers.Count -gt 0) {
                ' markers=' + ($step.markers -join ',')
            }
            else { '' }
            $noteText = if ([string]::IsNullOrWhiteSpace($step.note)) { '' } else { ' note=' + $step.note }
            # L'exit code appartiene al processo, non al singolo script del
            # batch: stamparlo accanto a un PASS ("PASS ... exit=1") confonde.
            # Resta nel JSON, dove serve alla diagnosi (PS-023).
            $exitText = if ($step.status -eq 'PASS' -or $step.status -eq 'CACHED') {
                ''
            }
            else { ' exit=' + $step.exit_code }
            Write-Output (
                "$(Get-StepDisplayStatus -Step $step) $($step.name)$exitText$markerText$noteText"
            )
        }
    }
    else {
        $parts = [Collections.Generic.List[string]]::new()
        foreach ($category in @('bootstrap', 'focused', 'regression', 'toolchain', 'windows', 'android')) {
            $categorySummary = Get-CategorySummary -Category $category
            if ($null -ne $categorySummary) {
                $parts.Add("$category=$categorySummary")
            }
        }
        $cachedCount = @($steps | Where-Object { $_.status -eq 'CACHED' }).Count
        $recoveredCount = @($steps | Where-Object { $_.status -eq 'RECOVERED' }).Count
        $failedCount = @($steps | Where-Object { $_.status -eq 'FAIL' }).Count
        $successfulCount = $steps.Count - $failedCount
        $parts.Add("steps=$successfulCount/$($steps.Count)")
        $parts.Add("cached=$cachedCount")
        if ($recoveredCount -gt 0) {
            $parts.Add("recovered=$recoveredCount")
        }
        if ($null -ne $androidInspection) {
            $parts.Add("android_static=$($androidInspection.android_static_valid)")
            $parts.Add("android_runtime=$($androidInspection.android_runtime)")
        }
        Write-Output (
            "IL_GIOCO_VERIFICATION milestone=$Milestone profile=$Profile status=$($Summary.status) " +
            ($parts -join ' ')
        )
        foreach ($failed in @($steps | Where-Object { $_.status -eq 'FAIL' })) {
            $failedNote = if ([string]::IsNullOrWhiteSpace($failed.note)) {
                ''
            }
            else { ' note=' + $failed.note }
            Write-Output (
                "$(Get-StepDisplayStatus -Step $failed) step=$($failed.name) " +
                "exit=$($failed.exit_code) log=$($failed.log)$failedNote"
            )
        }
    }
    Write-Output "LOG_ROOT=$logRoot"
}

$changedPaths = @(Get-ChangedRepositoryPaths)
if ($FocusedSmoke.Count -eq 0) {
    $FocusedSmoke = @(Find-FocusedGutTests -MilestoneId $Milestone)
}

switch ($Profile) {
    'Relevant' {
        $RegressionSmoke += @(Find-RelevantSmokes -Paths $changedPaths -MapPath $TestMap)
    }
    'Full' {
        $RegressionSmoke += @(Get-AllGutTests)
        $RunProjectSmoke = $true
    }
    'Release' {
        $RegressionSmoke += @(Get-AllGutTests)
        $RefreshEditor = $true
        $RunProjectSmoke = $true
        $ExportWindows = $true
        $ExportAndroid = $true
    }
}
if ($RunProjectSmoke) {
    $RunToolchain = $true
}
if ($ExportAndroid) {
    $InspectAndroid = $true
}

$FocusedSmoke = @(
    $FocusedSmoke |
        ForEach-Object { Resolve-RepositoryPath -Path $_ -MustExist } |
        Sort-Object -Unique
)
$focusedLookup = @{}
foreach ($smoke in $FocusedSmoke) {
    $focusedLookup[$smoke.ToLowerInvariant()] = $true
}
$RegressionSmoke = @(
    $RegressionSmoke |
        ForEach-Object { Resolve-RepositoryPath -Path $_ -MustExist } |
        Where-Object { -not $focusedLookup.ContainsKey($_.ToLowerInvariant()) } |
        Sort-Object -Unique
)

$hasWork = ($FocusedSmoke.Count -gt 0) -or ($RegressionSmoke.Count -gt 0) -or
    $RefreshEditor -or $RunToolchain -or $ExportWindows -or $ExportAndroid -or $InspectAndroid
if (-not $hasWork) {
    throw "Nessuno smoke trovato automaticamente per $Milestone e nessuna fase richiesta. Passa -FocusedSmoke."
}

$plan = [ordered]@{
    milestone = $Milestone
    profile = $Profile
    focused_smokes = @($FocusedSmoke | ForEach-Object { ConvertTo-RepositoryRelativePath -Path $_ })
    regression_smokes = @($RegressionSmoke | ForEach-Object { ConvertTo-RepositoryRelativePath -Path $_ })
    changed_paths = @($changedPaths)
    refresh_editor = [bool]$RefreshEditor
    run_toolchain = [bool]$RunToolchain
    run_project_smoke = [bool]$RunProjectSmoke
    export_windows = [bool]$ExportWindows
    export_android = [bool]$ExportAndroid
    inspect_android = [bool]$InspectAndroid
    cache_enabled = $cacheEnabled
}

Write-Host (
    "==> piano $Milestone/${Profile}: focused=$($FocusedSmoke.Count) regression=$($RegressionSmoke.Count) " +
    "refresh_editor=$($plan.refresh_editor) toolchain=$($plan.run_toolchain) " +
    "project_smoke=$($plan.run_project_smoke) export_windows=$($plan.export_windows) " +
    "export_android=$($plan.export_android) cache=$($plan.cache_enabled)"
)

if ($PlanOnly) {
    if ($AsJson) {
        $plan | ConvertTo-Json -Depth 8 -Compress
    }
    else {
        Write-Output (
            "IL_GIOCO_VERIFICATION_PLAN milestone=$Milestone profile=$Profile " +
            "focused=$($FocusedSmoke.Count) regression=$($RegressionSmoke.Count) " +
            "changed=$($changedPaths.Count) cache=$cacheEnabled"
        )
    }
    exit 0
}

try {
    $godot = Resolve-GodotConsole
    $godotVersion = (Get-Item -LiteralPath $godot).VersionInfo.FileVersion
    if ([string]::IsNullOrWhiteSpace($godotVersion)) {
        $godotVersion = 'unknown'
    }
    # La libreria di cattura e' parte del runner ai fini della cache: una
    # modifica al suo comportamento deve invalidare i risultati memorizzati.
    $runnerHash = Get-StringHash -Text (
        "$(Get-FileContentHash -Path $PSCommandPath)|" +
        "$(Get-FileContentHash -Path (Join-Path $PSScriptRoot 'lib\process-capture.ps1'))|" +
        "$(Get-FileContentHash -Path (Join-Path $PSScriptRoot 'lib\gut-batch-status.ps1'))|" +
        "$(Get-FileContentHash -Path (Resolve-RepositoryPath -Path $TestMap -MustExist))"
    )
    $runtimeHash = Get-CombinedRepositoryHash -Paths @(Get-RepositoryRuntimeFiles)

    if ($RefreshEditor) {
        Write-StepStart 'refresh-editor'
        $refreshResult = Invoke-CapturedProcess -FilePath $godot -Arguments @(
            '--headless', '--editor', '--path', $repoRoot, '--quit'
        ) -WorkingDirectory $repoRoot -ProgressIntervalSeconds 30 `
            -ProgressAction (New-GenericProgressAction -Label 'refresh-editor')
        $refreshStep = Add-ProcessStep -Name 'refresh-editor' -Category 'bootstrap' -ProcessResult $refreshResult
        Write-StepDone -Message 'refresh-editor' -Step $refreshStep
    }

    if (-not $halted) {
        Write-StepStart "focused: $($FocusedSmoke.Count) test GUT"
        Invoke-GutBatch -Category 'focused' -TestPaths $FocusedSmoke -GodotPath $godot `
            -RuntimeHash $runtimeHash -RunnerHash $runnerHash -GodotVersion $godotVersion | Out-Null
        Write-Host "<== focused: $(Get-CategorySummary -Category 'focused')"
    }

    if (-not $halted) {
        Write-StepStart "regression: $($RegressionSmoke.Count) test GUT"
        Invoke-GutBatch -Category 'regression' -TestPaths $RegressionSmoke -GodotPath $godot `
            -RuntimeHash $runtimeHash -RunnerHash $runnerHash -GodotVersion $godotVersion | Out-Null
        Write-Host "<== regression: $(Get-CategorySummary -Category 'regression')"
    }

    if ($RunToolchain -and -not $halted) {
        Write-StepStart 'toolchain: verify-toolchain.ps1'
        $shellPath = (Get-Process -Id $PID).Path
        $toolchainArguments = @(
            '-NoProfile',
            '-ExecutionPolicy', 'Bypass',
            '-File', (Join-Path $repoRoot 'tools\verify-toolchain.ps1')
        )
        if ($RunProjectSmoke) {
            $toolchainArguments += '-RunProjectSmoke'
        }
        $toolchainResult = Invoke-CapturedProcess -FilePath $shellPath `
            -Arguments $toolchainArguments -WorkingDirectory $repoRoot `
            -ProgressIntervalSeconds 30 -ProgressAction (New-GenericProgressAction -Label 'toolchain')
        $toolchainStep = Add-ProcessStep -Name 'toolchain' -Category 'toolchain' -ProcessResult $toolchainResult
        Write-StepDone -Message 'toolchain' -Step $toolchainStep
    }

    if ($ExportWindows -and -not $halted) {
        $windowsPath = Resolve-RepositoryPath -Path $WindowsArtifact
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $windowsPath) | Out-Null
        $windowsCacheKey = 'export|windows-debug'
        $windowsInputHash = Get-StringHash -Text (
            "$runnerVersion|$runnerHash|$godotVersion|$runtimeHash|windows-debug"
        )
        $cachedWindows = Get-CachedStep -Key $windowsCacheKey `
            -InputHash $windowsInputHash -ArtifactPath $windowsPath
        if ($null -ne $cachedWindows) {
            $windowsExportStep = Add-CachedStep -Name 'windows-export' `
                -Category 'windows' -CacheEntry $cachedWindows
        }
        else {
            Write-StepStart 'windows-export'
            $windowsExportResult = Invoke-CapturedProcess -FilePath $godot -Arguments @(
                '--headless', '--path', $repoRoot,
                '--export-debug', 'Windows Desktop', $windowsPath
            ) -WorkingDirectory $repoRoot -TimeoutSeconds $ExportTimeoutSeconds `
                -ProgressIntervalSeconds 30 -ProgressAction (New-GenericProgressAction -Label 'windows-export')
            $windowsExportStep = Add-ProcessStep -Name 'windows-export' -Category 'windows' `
                -ProcessResult $windowsExportResult
            Write-StepDone -Message 'windows-export' -Step $windowsExportStep
            Save-CachedStep -Key $windowsCacheKey -InputHash $windowsInputHash `
                -Step $windowsExportStep -ArtifactPath $windowsPath
        }

        if ($windowsExportStep.status -ne 'FAIL' -and -not $halted) {
            Write-StepStart 'windows-runtime'
            $windowsRuntimeResult = Invoke-CapturedProcess -FilePath $windowsPath -Arguments @(
                '--resolution', '1280x720', '--', '--smoke-test', '--run-seed=1'
            ) -WorkingDirectory $repoRoot -TimeoutSeconds $RuntimeTimeoutSeconds `
                -ProgressIntervalSeconds 30 -ProgressAction (New-GenericProgressAction -Label 'windows-runtime')
            $windowsRuntimeStep = Add-ProcessStep -Name 'windows-runtime' -Category 'windows' `
                -ProcessResult $windowsRuntimeResult -RequireSmokeMarker
            Write-StepDone -Message 'windows-runtime' -Step $windowsRuntimeStep
        }
    }

    $androidExportStep = $null
    $androidPath = Resolve-RepositoryPath -Path $AndroidArtifact
    if ($ExportAndroid -and -not $halted) {
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $androidPath) | Out-Null

        # --install-android-build-template regenerates android/build/ from
        # Godot's bundled template, overwriting gradle.properties and wiping
        # org.gradle.daemon=false in the same stroke. It only needs to run
        # once (or after a Godot version bump, per docs/setup.md) so pass it
        # only when the template isn't installed yet; every routine export
        # then leaves gradle.properties, and the daemon fix in it, untouched.
        $androidGradlePropertiesPath = Join-Path $repoRoot 'android\build\gradle.properties'
        $androidTemplateInstalled = Test-Path -LiteralPath $androidGradlePropertiesPath -PathType Leaf
        $androidExportArguments = [Collections.Generic.List[string]]::new()
        $androidExportArguments.AddRange(([string[]]@('--headless', '--path', $repoRoot)))
        if (-not $androidTemplateInstalled) {
            $androidExportArguments.Add('--install-android-build-template')
        }
        $androidExportArguments.AddRange(
            ([string[]]@('--export-debug', 'Android APK', $androidPath))
        )

        $androidCacheKey = 'export|android-debug'
        $androidInputHash = Get-StringHash -Text (
            "$runnerVersion|$runnerHash|$godotVersion|$runtimeHash|android-debug"
        )
        $cachedAndroid = Get-CachedStep -Key $androidCacheKey `
            -InputHash $androidInputHash -ArtifactPath $androidPath
        if ($null -ne $cachedAndroid) {
            $androidExportStep = Add-CachedStep -Name 'android-export' `
                -Category 'android' -CacheEntry $cachedAndroid
        }
        else {
            Write-StepStart 'android-export'
            $androidExportResult = Invoke-CapturedProcess -FilePath $godot `
                -Arguments $androidExportArguments.ToArray() `
                -WorkingDirectory $repoRoot -TimeoutSeconds $ExportTimeoutSeconds `
                -StableArtifactPath $androidPath `
                -StableArtifactSeconds $AndroidArtifactStableSeconds `
                -CompletionPattern $androidExportCompletionPattern `
                -ProgressIntervalSeconds 30 -ProgressAction (New-GenericProgressAction -Label 'android-export')
            $androidExportStep = Add-ProcessStep -Name 'android-export' -Category 'android' `
                -ProcessResult $androidExportResult -DoNotHalt
            Write-StepDone -Message 'android-export' -Step $androidExportStep
        }

        # Runs after the export, once gradle.properties is guaranteed to
        # exist (freshly regenerated by --install-android-build-template
        # above, or already there). A bootstrap run still regenerated it
        # without the fix just now; this leaves it in place for every
        # routine export from here on, since those skip the template flag.
        $daemonFixResult = Set-AndroidGradleDaemonDisabled -RepoRoot $repoRoot
        $daemonFixLogPath = Join-Path $logRoot 'android-gradle-daemon-fix.log'
        [IO.File]::WriteAllText(
            $daemonFixLogPath, $daemonFixResult.note, [Text.UTF8Encoding]::new($false)
        )
        $steps.Add([pscustomobject]@{
            name = 'android-gradle-daemon-fix'
            category = 'android'
            status = $daemonFixResult.status
            exit_code = 0
            timed_out = $false
            duration_ms = 0
            markers = @()
            error_markers = @()
            note = $daemonFixResult.note
            log = $daemonFixLogPath
        }) | Out-Null
    }

    if ($InspectAndroid -and (-not $halted -or $null -ne $androidExportStep)) {
        Write-StepStart 'android-static'
        $shellPath = (Get-Process -Id $PID).Path
        $inspectResult = Invoke-CapturedProcess -FilePath $shellPath -Arguments @(
            '-NoProfile',
            '-ExecutionPolicy', 'Bypass',
            '-File', (Join-Path $repoRoot 'tools\inspect-android-artifact.ps1'),
            '-ApkPath', $androidPath,
            '-AsJson'
        ) -WorkingDirectory $repoRoot `
            -ProgressIntervalSeconds 30 -ProgressAction (New-GenericProgressAction -Label 'android-static')
        $inspectStep = Add-ProcessStep -Name 'android-static' -Category 'android' `
            -ProcessResult $inspectResult -DoNotHalt
        Write-StepDone -Message 'android-static' -Step $inspectStep
        try {
            $androidInspection = $inspectResult.Output | ConvertFrom-Json
        }
        catch {
            $inspectStep.status = 'FAIL'
            $inspectStep.note = 'Output JSON del validatore Android non leggibile.'
        }

        if (
            $null -ne $androidExportStep -and
            $androidExportStep.status -eq 'FAIL' -and
            $inspectStep.status -eq 'PASS' -and
            (Test-Path -LiteralPath $androidPath -PathType Leaf) -and
            $null -ne $androidExportResult -and
            $androidExportResult.ArtifactChanged -and
            (
                $androidExportResult.TimedOut -or
                $androidExportResult.TerminatedAfterArtifact -or
                $androidExportResult.TerminatedAfterMarker
            )
        ) {
            $androidExportStep.status = 'RECOVERED'
            $androidExportStep.note = if ($androidExportResult.TerminatedAfterMarker) {
                'Exporter terminato dopo [ DONE ] export; ispezione statica completa verde.'
            }
            elseif ($androidExportResult.TerminatedAfterArtifact) {
                'Exporter terminato dopo APK nuovo e stabile; ispezione statica completa verde.'
            }
            else {
                'Exporter scaduto con APK nuovo valido; ispezione statica completa verde.'
            }
            Save-CachedStep -Key $androidCacheKey -InputHash $androidInputHash `
                -Step ([pscustomobject]@{ status = 'PASS'; markers = @() }) `
                -ArtifactPath $androidPath
        }

        if ($inspectStep.status -ne 'PASS' -and -not $KeepGoing) {
            $halted = $true
        }
        if (
            $null -ne $androidExportStep -and
            $androidExportStep.status -eq 'FAIL' -and
            -not $KeepGoing
        ) {
            $halted = $true
        }
    }
}
catch {
    $fatalLog = Join-Path $logRoot 'runner-fatal.log'
    [IO.File]::WriteAllText(
        $fatalLog,
        ($_.Exception.ToString() + "`n`n" + $_.InvocationInfo.PositionMessage + "`n`n" + $_.ScriptStackTrace),
        [Text.UTF8Encoding]::new($false)
    )
    $steps.Add([pscustomobject]@{
        name = 'runner'
        category = 'runner'
        status = 'FAIL'
        exit_code = 2
        timed_out = $false
        duration_ms = 0
        markers = @()
        error_markers = @()
        note = $_.Exception.Message
        log = $fatalLog
    })
}

$failedSteps = @($steps | Where-Object { $_.status -eq 'FAIL' })
$overallStatus = if ($failedSteps.Count -eq 0) { 'PASS' } else { 'FAIL' }
$summary = [ordered]@{
    milestone = $Milestone
    profile = $Profile
    status = $overallStatus
    log_root = $logRoot
    plan = $plan
    steps = @($steps)
    android = $androidInspection
}
Write-RunnerOutput -Summary $summary

if ($overallStatus -ne 'PASS') {
    exit 1
}
