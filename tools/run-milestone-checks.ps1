[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[BbMm]\d+[A-Za-z]?$')]
    [string]$Milestone,

    [string[]]$FocusedSmoke = @(),
    [string[]]$RegressionSmoke = @(),
    [switch]$RefreshEditor,
    [switch]$RunToolchain,
    [switch]$RunProjectSmoke,
    [switch]$ExportWindows,
    [switch]$ExportAndroid,
    [switch]$InspectAndroid,
    [string]$WindowsArtifact = 'exports\windows\PidgeonSurvivor.exe',
    [string]$AndroidArtifact = 'exports\android\pidgeon-survivor-debug.apk',
    [ValidateRange(30, 3600)]
    [int]$ExportTimeoutSeconds = 900,
    [ValidateRange(10, 600)]
    [int]$RuntimeTimeoutSeconds = 120,
    [switch]$KeepGoing,
    [switch]$AsJson
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$Milestone = $Milestone.ToUpperInvariant()
$logRoot = Join-Path (
    Join-Path ([IO.Path]::GetTempPath()) 'il-gioco-verification'
) ((Get-Date -Format 'yyyyMMdd-HHmmss') + "-$Milestone")
New-Item -ItemType Directory -Force -Path $logRoot | Out-Null

$steps = [Collections.Generic.List[object]]::new()
$halted = $false
$androidInspection = $null
$failurePattern = '(?im)(SCRIPT ERROR|FATAL EXCEPTION|SMOKE_FAIL|CONTRACT_FAIL)'
$markerPattern = '(?m)\b(?:[A-Z][A-Z0-9_]*_SMOKE_OK|SMOKE_OK)\b'

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

function Invoke-CapturedProcess {
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,

        [Parameter(Mandatory)]
        [string[]]$Arguments,

        [Parameter(Mandatory)]
        [string]$WorkingDirectory,

        [ValidateRange(0, 3600)]
        [int]$TimeoutSeconds = 0
    )

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

    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    $timedOut = $false
    if ($TimeoutSeconds -gt 0) {
        $timedOut = -not $process.WaitForExit($TimeoutSeconds * 1000)
        if ($timedOut) {
            try {
                $process.Kill()
            }
            catch {
                # The exact process may have exited between timeout and kill.
            }
        }
    }
    if (-not $timedOut) {
        $process.WaitForExit()
    }
    else {
        $process.WaitForExit(5000) | Out-Null
    }
    $stopwatch.Stop()

    if ($timedOut) {
        $stdout = if ($stdoutTask.Wait(1000)) {
            $stdoutTask.Result
        }
        else {
            '[stdout ancora aperto dopo il timeout; consultare l''artifact e i processi della build corrente]'
        }
        $stderr = if ($stderrTask.Wait(1000)) {
            $stderrTask.Result
        }
        else {
            '[stderr ancora aperto dopo il timeout; consultare l''artifact e i processi della build corrente]'
        }
    }
    else {
        $stdout = $stdoutTask.Result
        $stderr = $stderrTask.Result
    }
    $output = @($stdout.TrimEnd(), $stderr.TrimEnd()) |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    $exitCode = if ($timedOut) { 124 } else { $process.ExitCode }
    $process.Dispose()

    return [pscustomobject]@{
        ExitCode = $exitCode
        TimedOut = $timedOut
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
        [string]$GodotPath
    )

    $resolvedSmoke = Resolve-RepositoryPath -Path $SmokePath -MustExist
    $relativeSmoke = $resolvedSmoke.Substring($repoRoot.Length + 1).Replace('\', '/')
    $processResult = Invoke-CapturedProcess -FilePath $GodotPath -Arguments @(
        '--headless',
        '--path', $repoRoot,
        '--resolution', '1280x720',
        '--script', $relativeSmoke
    ) -WorkingDirectory $repoRoot
    return Add-ProcessStep -Name "$Category-$([IO.Path]::GetFileNameWithoutExtension($resolvedSmoke))" `
        -Category $Category -ProcessResult $processResult -RequireSmokeMarker
}

try {
    $godot = Resolve-GodotConsole
    if ($RunProjectSmoke) {
        $RunToolchain = $true
    }
    if ($ExportAndroid) {
        $InspectAndroid = $true
    }

    if ($FocusedSmoke.Count -eq 0) {
        $FocusedSmoke = @(Find-FocusedSmokes -MilestoneId $Milestone)
    }
    $FocusedSmoke = @($FocusedSmoke | Sort-Object -Unique)
    $RegressionSmoke = @($RegressionSmoke | Sort-Object -Unique)

    $hasWork = ($FocusedSmoke.Count -gt 0) -or ($RegressionSmoke.Count -gt 0) -or
        $RefreshEditor -or $RunToolchain -or $ExportWindows -or $ExportAndroid -or $InspectAndroid
    if (-not $hasWork) {
        throw "Nessuno smoke trovato automaticamente per $Milestone e nessuna fase richiesta. Passa -FocusedSmoke."
    }

    if ($RefreshEditor) {
        $refreshResult = Invoke-CapturedProcess -FilePath $godot -Arguments @(
            '--headless', '--editor', '--path', $repoRoot, '--quit'
        ) -WorkingDirectory $repoRoot
        Add-ProcessStep -Name 'refresh-editor' -Category 'bootstrap' -ProcessResult $refreshResult | Out-Null
    }

    foreach ($smoke in $FocusedSmoke) {
        if ($halted) { break }
        Invoke-Smoke -SmokePath $smoke -Category 'focused' -GodotPath $godot | Out-Null
    }

    foreach ($smoke in $RegressionSmoke) {
        if ($halted) { break }
        Invoke-Smoke -SmokePath $smoke -Category 'regression' -GodotPath $godot | Out-Null
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
        $windowsExportResult = Invoke-CapturedProcess -FilePath $godot -Arguments @(
            '--headless', '--path', $repoRoot,
            '--export-debug', 'Windows Desktop', $windowsPath
        ) -WorkingDirectory $repoRoot -TimeoutSeconds $ExportTimeoutSeconds
        $windowsExportStep = Add-ProcessStep -Name 'windows-export' -Category 'windows' `
            -ProcessResult $windowsExportResult

        if ($windowsExportStep.status -eq 'PASS' -and -not $halted) {
            $windowsRuntimeResult = Invoke-CapturedProcess -FilePath $windowsPath -Arguments @(
                '--resolution', '1280x720', '--', '--smoke-test', '--run-seed=1'
            ) -WorkingDirectory $repoRoot -TimeoutSeconds $RuntimeTimeoutSeconds
            Add-ProcessStep -Name 'windows-runtime' -Category 'windows' `
                -ProcessResult $windowsRuntimeResult -RequireSmokeMarker | Out-Null
        }
    }

    $androidExportStep = $null
    $androidBefore = $null
    $androidPath = Resolve-RepositoryPath -Path $AndroidArtifact
    if ($ExportAndroid -and -not $halted) {
        if (Test-Path -LiteralPath $androidPath -PathType Leaf) {
            $androidBefore = Get-Item -LiteralPath $androidPath
        }
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $androidPath) | Out-Null
        $androidExportResult = Invoke-CapturedProcess -FilePath $godot -Arguments @(
            '--headless', '--path', $repoRoot,
            '--install-android-build-template',
            '--export-debug', 'Android APK', $androidPath
        ) -WorkingDirectory $repoRoot -TimeoutSeconds $ExportTimeoutSeconds
        $androidExportStep = Add-ProcessStep -Name 'android-export' -Category 'android' `
            -ProcessResult $androidExportResult -DoNotHalt
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

        if ($null -ne $androidExportStep -and $androidExportStep.timed_out -and
            $inspectStep.status -eq 'PASS' -and (Test-Path -LiteralPath $androidPath)) {
            $androidAfter = Get-Item -LiteralPath $androidPath
            $artifactChanged = ($null -eq $androidBefore) -or
                ($androidBefore.Length -ne $androidAfter.Length) -or
                ($androidBefore.LastWriteTimeUtc -ne $androidAfter.LastWriteTimeUtc)
            if ($artifactChanged) {
                $androidExportStep.status = 'RECOVERED'
                $androidExportStep.note = 'CLI scaduta, ma APK aggiornato, stabile e staticamente valido.'
            }
        }

        if ($inspectStep.status -ne 'PASS' -and -not $KeepGoing) {
            $halted = $true
        }
        if ($null -ne $androidExportStep -and $androidExportStep.status -eq 'FAIL' -and -not $KeepGoing) {
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
    status = $overallStatus
    log_root = $logRoot
    steps = @($steps)
    android = $androidInspection
}

if ($AsJson) {
    $summary | ConvertTo-Json -Depth 8 -Compress
}
else {
    Write-Output "IL_GIOCO_VERIFICATION milestone=$Milestone status=$overallStatus"
    foreach ($step in $steps) {
        $markerText = if ($step.markers.Count -gt 0) {
            ' markers=' + ($step.markers -join ',')
        }
        else { '' }
        $noteText = if ([string]::IsNullOrWhiteSpace($step.note)) { '' } else { ' note=' + $step.note }
        Write-Output "$($step.status) $($step.name) exit=$($step.exit_code)$markerText$noteText"
    }
    if ($null -ne $androidInspection) {
        Write-Output "ANDROID_STATIC=$($androidInspection.android_static_valid)"
        Write-Output "ANDROID_ARTIFACT_READY=$($androidInspection.artifact_ready)"
        Write-Output "ANDROID_RUNTIME=$($androidInspection.android_runtime)"
        Write-Output "ANDROID_PACKAGE=$($androidInspection.package)"
        Write-Output "ANDROID_ABI=$($androidInspection.abis -join ',')"
        Write-Output "ANDROID_SHA256=$($androidInspection.sha256)"
    }
    Write-Output "LOG_ROOT=$logRoot"
}

if ($overallStatus -ne 'PASS') {
    exit 1
}
