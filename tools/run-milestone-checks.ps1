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
$cacheEnabled = -not $NoCache

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

function ConvertTo-CommandLineArgument {
    param(
        [AllowEmptyString()]
        [string]$Value
    )

    if ($Value.Length -gt 0 -and $Value -notmatch '[\s"]') {
        return $Value
    }
    return '"' + ($Value -replace '"', '\"') + '"'
}

function Stop-TrackedProcessTree {
    param(
        [Parameter(Mandatory)]
        [int]$RootProcessId
    )

    $processes = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue)
    $childrenByParent = @{}
    foreach ($item in $processes) {
        $parentKey = [string]$item.ParentProcessId
        if (-not $childrenByParent.ContainsKey($parentKey)) {
            $childrenByParent[$parentKey] = [Collections.Generic.List[int]]::new()
        }
        $childrenByParent[$parentKey].Add([int]$item.ProcessId)
    }

    $ordered = [Collections.Generic.List[int]]::new()
    function Add-Descendants {
        param([int]$ParentId)
        $key = [string]$ParentId
        if (-not $childrenByParent.ContainsKey($key)) {
            return
        }
        foreach ($childId in $childrenByParent[$key]) {
            Add-Descendants -ParentId $childId
            $ordered.Add($childId)
        }
    }
    Add-Descendants -ParentId $RootProcessId
    $ordered.Add($RootProcessId)
    foreach ($processId in $ordered) {
        Stop-Process -Id $processId -Force -ErrorAction SilentlyContinue
    }
}

function Invoke-CapturedProcess {
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,

        [Parameter(Mandatory)]
        [string[]]$Arguments,

        [Parameter(Mandatory)]
        [string]$WorkingDirectory,

        [ValidateRange(0, 3600)]
        [int]$TimeoutSeconds = 0,

        [string]$StableArtifactPath,

        [ValidateRange(0, 60)]
        [int]$StableArtifactSeconds = 0
    )

    $artifactBefore = $null
    if (
        -not [string]::IsNullOrWhiteSpace($StableArtifactPath) -and
        (Test-Path -LiteralPath $StableArtifactPath -PathType Leaf)
    ) {
        $artifactBefore = Get-Item -LiteralPath $StableArtifactPath
    }

    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $FilePath
    $startInfo.Arguments = (($Arguments | ForEach-Object {
        ConvertTo-CommandLineArgument -Value $_
    }) -join ' ')
    $startInfo.WorkingDirectory = $WorkingDirectory
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true

    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    $stopwatch = [Diagnostics.Stopwatch]::StartNew()
    if (-not $process.Start()) {
        throw "Impossibile avviare: $FilePath"
    }

    $processId = $process.Id
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    $timedOut = $false
    $terminatedAfterArtifact = $false
    $artifactChanged = $false
    $lastArtifactSignature = $null
    $artifactStableSinceMs = 0L

    while (-not $process.WaitForExit(250)) {
        if (
            $TimeoutSeconds -gt 0 -and
            $stopwatch.Elapsed.TotalSeconds -ge $TimeoutSeconds
        ) {
            $timedOut = $true
            Stop-TrackedProcessTree -RootProcessId $processId
            break
        }

        if (
            $StableArtifactSeconds -gt 0 -and
            -not [string]::IsNullOrWhiteSpace($StableArtifactPath) -and
            (Test-Path -LiteralPath $StableArtifactPath -PathType Leaf)
        ) {
            $artifactNow = Get-Item -LiteralPath $StableArtifactPath
            $artifactChanged = ($null -eq $artifactBefore) -or
                ($artifactBefore.Length -ne $artifactNow.Length) -or
                ($artifactBefore.LastWriteTimeUtc -ne $artifactNow.LastWriteTimeUtc)
            if ($artifactChanged) {
                $signature = "$($artifactNow.Length)|$($artifactNow.LastWriteTimeUtc.Ticks)"
                if ($signature -ne $lastArtifactSignature) {
                    $lastArtifactSignature = $signature
                    $artifactStableSinceMs = $stopwatch.ElapsedMilliseconds
                }
                elseif (
                    ($stopwatch.ElapsedMilliseconds - $artifactStableSinceMs) -ge
                    ($StableArtifactSeconds * 1000)
                ) {
                    $terminatedAfterArtifact = $true
                    Stop-TrackedProcessTree -RootProcessId $processId
                    break
                }
            }
        }
    }

    if (-not $process.HasExited) {
        $process.WaitForExit(5000) | Out-Null
    }
    $stopwatch.Stop()

    $stdout = if ($stdoutTask.Wait(2000)) {
        $stdoutTask.Result
    }
    else {
        '[stdout ancora aperto; consultare artifact e processi della build corrente]'
    }
    $stderr = if ($stderrTask.Wait(2000)) {
        $stderrTask.Result
    }
    else {
        '[stderr ancora aperto; consultare artifact e processi della build corrente]'
    }
    $output = @($stdout.TrimEnd(), $stderr.TrimEnd()) |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    $exitCode = if ($timedOut) {
        124
    }
    elseif ($terminatedAfterArtifact) {
        125
    }
    else {
        $process.ExitCode
    }
    $process.Dispose()

    return [pscustomobject]@{
        ExitCode = $exitCode
        TimedOut = $timedOut
        TerminatedAfterArtifact = $terminatedAfterArtifact
        ArtifactChanged = $artifactChanged
        ProcessId = $processId
        DurationMs = $stopwatch.ElapsedMilliseconds
        Output = ($output -join [Environment]::NewLine)
    }
}

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
    $runnerHash = Get-StringHash -Text (
        "$(Get-FileContentHash -Path $PSCommandPath)|" +
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
            $androidExportResult = Invoke-CapturedProcess -FilePath $godot -Arguments @(
                '--headless', '--path', $repoRoot,
                '--install-android-build-template',
                '--export-debug', 'Android APK', $androidPath
            ) -WorkingDirectory $repoRoot -TimeoutSeconds $ExportTimeoutSeconds `
                -StableArtifactPath $androidPath `
                -StableArtifactSeconds $AndroidArtifactStableSeconds
            $androidExportStep = Add-ProcessStep -Name 'android-export' -Category 'android' `
                -ProcessResult $androidExportResult -DoNotHalt
        }
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
            ($androidExportResult.TimedOut -or $androidExportResult.TerminatedAfterArtifact)
        ) {
            $androidExportStep.status = 'RECOVERED'
            $androidExportStep.note = (
                'Exporter terminato dopo APK nuovo e stabile; ispezione statica completa verde.'
            )
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
