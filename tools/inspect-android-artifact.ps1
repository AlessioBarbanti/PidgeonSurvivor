[CmdletBinding()]
param(
    [string]$ApkPath = 'exports\android\pidgeon-survivor-debug.apk',
    [ValidateRange(0, 30)]
    [int]$StabilityDelaySeconds = 2,
    [switch]$SkipStabilityCheck,
    [switch]$AsJson
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

function Get-ConfiguredEnvironmentValue {
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    $value = [Environment]::GetEnvironmentVariable($Name, 'Process')
    if ([string]::IsNullOrWhiteSpace($value)) {
        $value = [Environment]::GetEnvironmentVariable($Name, 'User')
    }
    return $value
}

function Invoke-ExternalCommand {
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,

        [Parameter(Mandatory)]
        [string[]]$Arguments
    )

    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $lines = @(& $FilePath @Arguments 2>&1 | ForEach-Object { $_.ToString() })
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousPreference
    }

    return [pscustomobject]@{
        ExitCode = $exitCode
        Output = ($lines -join [Environment]::NewLine)
    }
}

function Get-AndroidApkExpectations {
    param(
        [Parameter(Mandatory)]
        [string]$PresetPath
    )

    $content = Get-Content -LiteralPath $PresetPath -Raw
    $presetId = $null
    $presetMatches = [regex]::Matches(
        $content,
        '(?ms)^\[preset\.(?<id>\d+)\]\s*(?<body>.*?)(?=^\[|\z)'
    )
    foreach ($presetMatch in $presetMatches) {
        if ($presetMatch.Groups['body'].Value -match '(?m)^name="Android APK"\s*$') {
            $presetId = $presetMatch.Groups['id'].Value
            break
        }
    }
    if ($null -eq $presetId) {
        throw 'Preset "Android APK" non trovato in export_presets.cfg.'
    }

    $optionsMatch = [regex]::Match(
        $content,
        "(?ms)^\[preset\.$presetId\.options\]\s*(?<body>.*?)(?=^\[|\z)"
    )
    if (-not $optionsMatch.Success) {
        throw "Opzioni del preset Android APK ($presetId) non trovate."
    }
    $options = $optionsMatch.Groups['body'].Value

    function Get-QuotedOption {
        param(
            [string]$Text,
            [string]$Key
        )

        $match = [regex]::Match(
            $Text,
            '(?m)^' + [regex]::Escape($Key) + '="(?<value>[^"]*)"\s*$'
        )
        if (-not $match.Success) {
            throw "Opzione Android mancante: $Key"
        }
        return $match.Groups['value'].Value
    }

    $abis = @(
        [regex]::Matches($options, '(?m)^architectures/(?<abi>[^=]+)=true\s*$') |
            ForEach-Object { $_.Groups['abi'].Value } |
            Sort-Object -Unique
    )

    return [pscustomobject]@{
        Package = Get-QuotedOption -Text $options -Key 'package/unique_name'
        MinSdk = Get-QuotedOption -Text $options -Key 'gradle_build/min_sdk'
        TargetSdk = Get-QuotedOption -Text $options -Key 'gradle_build/target_sdk'
        Abis = $abis
    }
}

function Resolve-BuildTools {
    param(
        [Parameter(Mandatory)]
        [string]$AndroidHome
    )

    $root = Join-Path $AndroidHome 'build-tools'
    if (-not (Test-Path -LiteralPath $root)) {
        throw "Android build-tools non trovati: $root"
    }

    $candidate = Get-ChildItem -LiteralPath $root -Directory |
        Sort-Object Name -Descending |
        Where-Object {
            (Test-Path -LiteralPath (Join-Path $_.FullName 'aapt2.exe')) -and
            (Test-Path -LiteralPath (Join-Path $_.FullName 'apksigner.bat'))
        } |
        Select-Object -First 1
    if ($null -eq $candidate) {
        throw "Nessuna versione build-tools contiene aapt2 e apksigner: $root"
    }

    return [pscustomobject]@{
        Aapt2 = Join-Path $candidate.FullName 'aapt2.exe'
        ApkSigner = Join-Path $candidate.FullName 'apksigner.bat'
        Version = $candidate.Name
    }
}

function Get-MatchValue {
    param(
        [string]$Text,
        [string]$Pattern
    )

    $match = [regex]::Match($Text, $Pattern)
    if ($match.Success) {
        return $match.Groups['value'].Value
    }
    return $null
}

try {
    $resolvedApkPath = if ([IO.Path]::IsPathRooted($ApkPath)) {
        [IO.Path]::GetFullPath($ApkPath)
    }
    else {
        [IO.Path]::GetFullPath((Join-Path $repoRoot $ApkPath))
    }
    if (-not (Test-Path -LiteralPath $resolvedApkPath -PathType Leaf)) {
        throw "APK non trovato: $resolvedApkPath"
    }

    $expectations = Get-AndroidApkExpectations -PresetPath (Join-Path $repoRoot 'export_presets.cfg')
    $androidHome = Get-ConfiguredEnvironmentValue -Name 'ANDROID_HOME'
    if ([string]::IsNullOrWhiteSpace($androidHome)) {
        throw 'ANDROID_HOME non configurata. Consulta docs/setup.md.'
    }
    $buildTools = Resolve-BuildTools -AndroidHome $androidHome

    $issues = [Collections.Generic.List[string]]::new()
    $pendingReasons = [Collections.Generic.List[string]]::new()
    $activeExportPids = @()
    try {
        $apkFileNamePattern = [regex]::Escape([IO.Path]::GetFileName($resolvedApkPath))
        $activeExportPids = @(
            Get-CimInstance Win32_Process -ErrorAction Stop |
                Where-Object {
                    $_.Name -match '^Godot.*console\.exe$' -and
                    $_.CommandLine -match '--export-debug\s+"?Android APK"?' -and
                    $_.CommandLine -match $apkFileNamePattern
                } |
                ForEach-Object { $_.ProcessId }
        )
    }
    catch {
        # Process inspection is advisory; static APK checks remain authoritative.
    }
    if ($activeExportPids.Count -gt 0) {
        $pendingReasons.Add(
            "Export Android ancora attivo (PID $($activeExportPids -join ','))."
        )
    }

    $before = Get-Item -LiteralPath $resolvedApkPath
    $stable = $true
    if (-not $SkipStabilityCheck) {
        Start-Sleep -Seconds $StabilityDelaySeconds
        $after = Get-Item -LiteralPath $resolvedApkPath
        $stable = ($before.Length -eq $after.Length) -and
            ($before.LastWriteTimeUtc -eq $after.LastWriteTimeUtc)
        if (-not $stable) {
            $issues.Add('APK ancora in scrittura: dimensione o timestamp sono cambiati.')
        }
    }
    else {
        $after = $before
    }

    $hash = (Get-FileHash -LiteralPath $resolvedApkPath -Algorithm SHA256).Hash
    $badgingResult = Invoke-ExternalCommand -FilePath $buildTools.Aapt2 -Arguments @(
        'dump', 'badging', $resolvedApkPath
    )
    if ($badgingResult.ExitCode -ne 0) {
        $issues.Add("aapt2 dump badging fallito con codice $($badgingResult.ExitCode).")
    }

    $package = Get-MatchValue -Text $badgingResult.Output -Pattern "(?m)^package: name='(?<value>[^']+)'"
    $minSdk = Get-MatchValue -Text $badgingResult.Output -Pattern "(?m)^minSdkVersion:'(?<value>\d+)'"
    $targetSdk = Get-MatchValue -Text $badgingResult.Output -Pattern "(?m)^targetSdkVersion:'(?<value>\d+)'"
    $label = Get-MatchValue -Text $badgingResult.Output -Pattern "(?m)^application-label:'(?<value>[^']*)'"
    $permissions = @(
        [regex]::Matches($badgingResult.Output, "(?m)^uses-permission: name='(?<value>[^']+)'" ) |
            ForEach-Object { $_.Groups['value'].Value } |
            Sort-Object -Unique
    )

    $manifestResult = Invoke-ExternalCommand -FilePath $buildTools.Aapt2 -Arguments @(
        'dump', 'xmltree', $resolvedApkPath, '--file', 'AndroidManifest.xml'
    )
    if ($manifestResult.ExitCode -ne 0) {
        $issues.Add("aapt2 dump xmltree fallito con codice $($manifestResult.ExitCode).")
    }
    $launcher = Get-MatchValue -Text $manifestResult.Output -Pattern (
        '(?ms)E: activity-alias.*?' +
        'android:name[^=]*="(?<value>[^"]+)".*?' +
        'android.intent.action.MAIN.*?' +
        'android.intent.category.LAUNCHER'
    )
    $screenOrientation = Get-MatchValue -Text $manifestResult.Output -Pattern (
        '(?ms)E: activity.*?android:name[^=]*="com\.godot\.game\.GodotApp".*?' +
        'screenOrientation[^=]*=(?<value>[^\s]+)'
    )
    $resizeableActivity = Get-MatchValue -Text $manifestResult.Output -Pattern (
        '(?ms)E: activity.*?android:name[^=]*="com\.godot\.game\.GodotApp".*?' +
        'resizeableActivity[^=]*=(?<value>true|false)'
    )

    if ($package -ne $expectations.Package) {
        $issues.Add("Package inatteso: '$package' (atteso '$($expectations.Package)').")
    }
    if ($minSdk -ne $expectations.MinSdk) {
        $issues.Add("minSdk inatteso: '$minSdk' (atteso '$($expectations.MinSdk)').")
    }
    if ($targetSdk -ne $expectations.TargetSdk) {
        $issues.Add("targetSdk inatteso: '$targetSdk' (atteso '$($expectations.TargetSdk)').")
    }
    if ([string]::IsNullOrWhiteSpace($launcher)) {
        $issues.Add('Launcher MAIN/LAUNCHER non rilevato nel manifest.')
    }
    if ($screenOrientation -ne '0') {
        $issues.Add("Orientamento Android inatteso: '$screenOrientation' (atteso landscape/0).")
    }

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [IO.Compression.ZipFile]::OpenRead($resolvedApkPath)
    try {
        $actualAbis = @(
            $archive.Entries |
                Where-Object { $_.FullName -match '^lib/(?<abi>[^/]+)/.+\.so$' } |
                ForEach-Object {
                    [regex]::Match($_.FullName, '^lib/(?<abi>[^/]+)/').Groups['abi'].Value
                } |
                Sort-Object -Unique
        )
    }
    finally {
        $archive.Dispose()
    }
    if (($actualAbis -join ',') -ne ($expectations.Abis -join ',')) {
        $issues.Add(
            "ABI inattese: '$($actualAbis -join ',')' (attese '$($expectations.Abis -join ',')')."
        )
    }

    $signatureResult = Invoke-ExternalCommand -FilePath $buildTools.ApkSigner -Arguments @(
        'verify', '--verbose', '--print-certs', $resolvedApkPath
    )
    $v2Signature = ($signatureResult.ExitCode -eq 0) -and
        ($signatureResult.Output -match '(?im)Verified using v2 scheme.*:\s*true')
    if (-not $v2Signature) {
        $issues.Add('Firma APK v2 non verificata.')
    }

    $adbPath = Join-Path $androidHome 'platform-tools\adb.exe'
    $devices = @()
    $adbServerRunning = $false
    if (Test-Path -LiteralPath $adbPath) {
        try {
            $adbServerRunning = @(
                Get-CimInstance Win32_Process -ErrorAction Stop |
                    Where-Object {
                        $_.Name -ieq 'adb.exe' -and
                        $_.CommandLine -match '\bfork-server\s+server\b'
                    }
            ).Count -gt 0
        }
        catch {
            # Device discovery is advisory; never start adb from a captured
            # inspector because its daemon can retain the runner output pipe.
        }
    }
    if ($adbServerRunning) {
        $adbResult = Invoke-ExternalCommand -FilePath $adbPath -Arguments @('devices', '-l')
        if ($adbResult.ExitCode -eq 0) {
            $devices = @(
                [regex]::Matches($adbResult.Output, '(?m)^(?<value>[^\s]+)\s+device\b.*$') |
                    ForEach-Object { $_.Groups['value'].Value }
            )
        }
    }

    $staticValid = $issues.Count -eq 0
    $artifactReady = $staticValid -and ($pendingReasons.Count -eq 0)
    $runtimeState = if ($devices.Count -gt 0) {
        'OPEN_DEVICE_ATTACHED_INTERACTION_NOT_RUN'
    }
    elseif (-not $adbServerRunning) {
        'OPEN_ADB_SERVER_NOT_RUNNING'
    }
    else {
        'OPEN_NO_DEVICE'
    }

    $result = [ordered]@{
        apk = $resolvedApkPath
        size_bytes = $after.Length
        last_write_utc = $after.LastWriteTimeUtc.ToString('o')
        sha256 = $hash
        stable = $stable
        build_tools = $buildTools.Version
        package = $package
        expected_package = $expectations.Package
        application_label = $label
        min_sdk = $minSdk
        expected_min_sdk = $expectations.MinSdk
        target_sdk = $targetSdk
        expected_target_sdk = $expectations.TargetSdk
        abis = @($actualAbis)
        expected_abis = @($expectations.Abis)
        v2_signature = $v2Signature
        launcher = $launcher
        screen_orientation = $screenOrientation
        resizeable_activity = $resizeableActivity
        permissions = @($permissions)
        adb_server_running = $adbServerRunning
        adb_devices = @($devices)
        active_export_pids = @($activeExportPids)
        android_static_valid = $staticValid
        artifact_ready = $artifactReady
        android_runtime = $runtimeState
        issues = @($issues)
        pending_reasons = @($pendingReasons)
    }

    if ($AsJson) {
        $result | ConvertTo-Json -Depth 6 -Compress
    }
    else {
        $statusMarker = if (-not $staticValid) {
            'ANDROID_STATIC_INVALID'
        }
        elseif (-not $artifactReady) {
            'ANDROID_STATIC_VALID_EXPORT_PENDING'
        }
        else {
            'ANDROID_STATIC_VALID'
        }
        Write-Output $statusMarker
        Write-Output "APK=$resolvedApkPath"
        Write-Output "SIZE_BYTES=$($after.Length)"
        Write-Output "SHA256=$hash"
        Write-Output "PACKAGE=$package"
        Write-Output "SDK=min:$minSdk,target:$targetSdk"
        Write-Output "ABI=$($actualAbis -join ',')"
        Write-Output "SIGNATURE_V2=$v2Signature"
        Write-Output "LAUNCHER=$launcher"
        Write-Output "SCREEN_ORIENTATION=$screenOrientation"
        Write-Output "RESIZEABLE_ACTIVITY=$resizeableActivity"
        Write-Output "PERMISSIONS=$($permissions -join ',')"
        Write-Output "ADB_DEVICES=$($devices -join ',')"
        Write-Output "ACTIVE_EXPORT_PIDS=$($activeExportPids -join ',')"
        Write-Output "ANDROID_RUNTIME=$runtimeState"
        foreach ($issue in $issues) {
            Write-Output "ISSUE=$issue"
        }
        foreach ($pendingReason in $pendingReasons) {
            Write-Output "PENDING=$pendingReason"
        }
    }

    if (-not $staticValid) {
        exit 1
    }
    if (-not $artifactReady) {
        exit 3
    }
}
catch {
    $message = $_.Exception.Message
    if ($AsJson) {
        [ordered]@{
            android_static_valid = $false
            artifact_ready = $false
            android_runtime = 'OPEN_NOT_INSPECTED'
            package = $null
            abis = @()
            sha256 = $null
            issues = @($message)
            pending_reasons = @()
        } | ConvertTo-Json -Depth 4 -Compress
    }
    else {
        Write-Output 'ANDROID_STATIC_NOT_INSPECTED'
        Write-Output "ISSUE=$message"
    }
    exit 2
}
