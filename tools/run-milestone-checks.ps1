[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[BbMm]\d+[A-Za-z]?$')]
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

function Find-FocusedSmokes {
    param(
        [Parameter(Mandatory)]
        [string]$MilestoneId
    )

    $pattern = '\b' + [regex]::Escape($MilestoneId) + '_[A-Z0-9_]*_SMOKE_OK\b'
    return @(
        Get-ChildItem -LiteralPath (Join-Path $repoRoot 'tests\integration') -Filter '*_smoke.gd' -File |
            Where-Object { Select-String -LiteralPath $_.FullName -Pattern $pattern -Quiet } |
            ForEach-Object { $_.FullName }
    )
}

function Get-AllIntegrationSmokes {
    return @(
        Get-ChildItem -LiteralPath (Join-Path $repoRoot 'tests\integration') -Filter '*_smoke.gd' -File |
            Sort-Object Name |
            ForEach-Object { $_.FullName }
    )
}

function Get-ChangedRepositoryPaths {
    if ($ChangedPath.Count -gt 0) {
        return @($ChangedPath | ForEach-Object { $_.Replace('\', '/') } | Sort-Object -Unique)
    }

    $tracked = @(& git -C $repoRoot diff --name-only HEAD -- 2>$null)
    if ($LASTEXITCODE -ne 0) {
        throw 'git diff --name-only HEAD fallito durante la selezione dei test.'
    }
    $untracked = @(& git -C $repoRoot ls-files --others --exclude-standard 2>$null)
    if ($LASTEXITCODE -ne 0) {
        throw 'git ls-files --others fallito durante la selezione dei test.'
    }
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
    $runAll = $false

    foreach ($changed in $Paths) {
        $normalized = $changed.Replace('\', '/')
        if ($normalized -match '^tests/integration/.*_smoke\.gd$') {
            $selected.Add($normalized) | Out-Null
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
            if (
                $rule.PSObject.Properties.Name -contains 'run_all' -and
                [bool]$rule.run_all
            ) {
                $runAll = $true
            }
            foreach ($smoke in @($rule.smokes)) {
                $selected.Add([string]$smoke) | Out-Null
            }
        }
        if (-not $matched) {
            $unmatchedRuntime.Add($normalized)
        }
    }

    if ($runAll -or $unmatchedRuntime.Count -gt 0) {
        foreach ($smoke in Get-AllIntegrationSmokes) {
            $selected.Add($smoke) | Out-Null
        }
    }
    return @($selected | Sort-Object)
}

function Get-RepositoryRuntimeFiles {
    $tracked = @(& git -C $repoRoot ls-files 2>$null)
    if ($LASTEXITCODE -ne 0) {
        throw 'git ls-files fallito durante il calcolo della cache.'
    }
    $untracked = @(& git -C $repoRoot ls-files --others --exclude-standard 2>$null)
    if ($LASTEXITCODE -ne 0) {
        throw 'git ls-files --others fallito durante il calcolo della cache.'
    }
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

function Invoke-Smoke {
    param(
        [Parameter(Mandatory)]
        [string]$SmokePath,

        [Parameter(Mandatory)]
        [string]$Category,

        [Parameter(Mandatory)]
        [string]$GodotPath,

        [Parameter(Mandatory)]
        [string]$RuntimeHash,

        [Parameter(Mandatory)]
        [string]$RunnerHash,

        [Parameter(Mandatory)]
        [string]$GodotVersion
    )

    $resolvedSmoke = Resolve-RepositoryPath -Path $SmokePath -MustExist
    $relativeSmoke = ConvertTo-RepositoryRelativePath -Path $resolvedSmoke
    $name = "$Category-$([IO.Path]::GetFileNameWithoutExtension($resolvedSmoke))"
    $cacheKey = "smoke|$relativeSmoke"
    $inputHash = Get-StringHash -Text (
        "$runnerVersion|$RunnerHash|$GodotVersion|$RuntimeHash|$(Get-FileContentHash -Path $resolvedSmoke)"
    )
    $cached = Get-CachedStep -Key $cacheKey -InputHash $inputHash
    if ($null -ne $cached) {
        return Add-CachedStep -Name $name -Category $Category -CacheEntry $cached
    }

    $processResult = Invoke-CapturedProcess -FilePath $GodotPath -Arguments @(
        '--headless',
        '--path', $repoRoot,
        '--resolution', '1280x720',
        '--script', $relativeSmoke
    ) -WorkingDirectory $repoRoot
    $step = Add-ProcessStep -Name $name -Category $Category `
        -ProcessResult $processResult -RequireSmokeMarker
    Save-CachedStep -Key $cacheKey -InputHash $inputHash -Step $step
    return $step
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
            Write-Output "$($step.status) $($step.name) exit=$($step.exit_code)$markerText$noteText"
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
            Write-Output "FAIL step=$($failed.name) exit=$($failed.exit_code) log=$($failed.log)"
        }
    }
    Write-Output "LOG_ROOT=$logRoot"
}

$changedPaths = @(Get-ChangedRepositoryPaths)
if ($FocusedSmoke.Count -eq 0) {
    $FocusedSmoke = @(Find-FocusedSmokes -MilestoneId $Milestone)
}

switch ($Profile) {
    'Relevant' {
        $RegressionSmoke += @(Find-RelevantSmokes -Paths $changedPaths -MapPath $TestMap)
    }
    'Full' {
        $RegressionSmoke += @(Get-AllIntegrationSmokes)
        $RunProjectSmoke = $true
    }
    'Release' {
        $RegressionSmoke += @(Get-AllIntegrationSmokes)
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
        "$(Get-FileContentHash -Path (Resolve-RepositoryPath -Path $TestMap -MustExist))"
    )
    $runtimeHash = Get-CombinedRepositoryHash -Paths @(Get-RepositoryRuntimeFiles)

    if ($RefreshEditor) {
        $refreshResult = Invoke-CapturedProcess -FilePath $godot -Arguments @(
            '--headless', '--editor', '--path', $repoRoot, '--quit'
        ) -WorkingDirectory $repoRoot
        Add-ProcessStep -Name 'refresh-editor' -Category 'bootstrap' -ProcessResult $refreshResult | Out-Null
    }

    foreach ($smoke in $FocusedSmoke) {
        if ($halted) { break }
        Invoke-Smoke -SmokePath $smoke -Category 'focused' -GodotPath $godot `
            -RuntimeHash $runtimeHash -RunnerHash $runnerHash -GodotVersion $godotVersion | Out-Null
    }

    foreach ($smoke in $RegressionSmoke) {
        if ($halted) { break }
        Invoke-Smoke -SmokePath $smoke -Category 'regression' -GodotPath $godot `
            -RuntimeHash $runtimeHash -RunnerHash $runnerHash -GodotVersion $godotVersion | Out-Null
    }

    if ($RunToolchain -and -not $halted) {
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
            -Arguments $toolchainArguments -WorkingDirectory $repoRoot
        Add-ProcessStep -Name 'toolchain' -Category 'toolchain' -ProcessResult $toolchainResult | Out-Null
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
            $windowsExportResult = Invoke-CapturedProcess -FilePath $godot -Arguments @(
                '--headless', '--path', $repoRoot,
                '--export-debug', 'Windows Desktop', $windowsPath
            ) -WorkingDirectory $repoRoot -TimeoutSeconds $ExportTimeoutSeconds
            $windowsExportStep = Add-ProcessStep -Name 'windows-export' -Category 'windows' `
                -ProcessResult $windowsExportResult
            Save-CachedStep -Key $windowsCacheKey -InputHash $windowsInputHash `
                -Step $windowsExportStep -ArtifactPath $windowsPath
        }

        if ($windowsExportStep.status -ne 'FAIL' -and -not $halted) {
            $windowsRuntimeResult = Invoke-CapturedProcess -FilePath $windowsPath -Arguments @(
                '--resolution', '1280x720', '--', '--smoke-test', '--run-seed=1'
            ) -WorkingDirectory $repoRoot -TimeoutSeconds $RuntimeTimeoutSeconds
            Add-ProcessStep -Name 'windows-runtime' -Category 'windows' `
                -ProcessResult $windowsRuntimeResult -RequireSmokeMarker | Out-Null
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
            $androidExportResult = Invoke-CapturedProcess -FilePath $godot `
                -Arguments $androidExportArguments.ToArray() `
                -WorkingDirectory $repoRoot -TimeoutSeconds $ExportTimeoutSeconds `
                -StableArtifactPath $androidPath `
                -StableArtifactSeconds $AndroidArtifactStableSeconds `
                -CompletionPattern $androidExportCompletionPattern
            $androidExportStep = Add-ProcessStep -Name 'android-export' -Category 'android' `
                -ProcessResult $androidExportResult -DoNotHalt
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
        $shellPath = (Get-Process -Id $PID).Path
        $inspectResult = Invoke-CapturedProcess -FilePath $shellPath -Arguments @(
            '-NoProfile',
            '-ExecutionPolicy', 'Bypass',
            '-File', (Join-Path $repoRoot 'tools\inspect-android-artifact.ps1'),
            '-ApkPath', $androidPath,
            '-AsJson'
        ) -WorkingDirectory $repoRoot
        $inspectStep = Add-ProcessStep -Name 'android-static' -Category 'android' `
            -ProcessResult $inspectResult -DoNotHalt
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
    [IO.File]::WriteAllText($fatalLog, $_.Exception.ToString(), [Text.UTF8Encoding]::new($false))
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
