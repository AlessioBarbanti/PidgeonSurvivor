[CmdletBinding()]
param(
    [switch]$RunProjectSmoke
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

function Resolve-ConfiguredPath {
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    $value = [Environment]::GetEnvironmentVariable($Name, 'Process')
    if ([string]::IsNullOrWhiteSpace($value)) {
        $value = [Environment]::GetEnvironmentVariable($Name, 'User')
    }
    if ([string]::IsNullOrWhiteSpace($value)) {
        throw "$Name non è configurata. Consulta docs/setup.md."
    }

    return $value
}

function Assert-Exists {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Description
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "$Description non trovato: $Path"
    }

    Write-Host "[OK] $Description"
}

$godotCommand = Get-Command godot_console.exe -ErrorAction SilentlyContinue
if ($null -eq $godotCommand) {
    $fallback = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links\godot_console.exe'
    Assert-Exists -Path $fallback -Description 'Godot console'
    $godot = $fallback
}
else {
    $godot = $godotCommand.Source
}

$javaHome = Resolve-ConfiguredPath -Name 'JAVA_HOME'
$androidHome = Resolve-ConfiguredPath -Name 'ANDROID_HOME'
$env:JAVA_HOME = $javaHome
$env:ANDROID_HOME = $androidHome

$java = Join-Path $javaHome 'bin\java.exe'
Assert-Exists -Path $java -Description 'JDK'
Assert-Exists -Path (Join-Path $androidHome 'platforms\android-31') -Description 'Android Platform 31'
Assert-Exists -Path (Join-Path $androidHome 'platforms\android-36') -Description 'Android Platform 36'
Assert-Exists -Path (Join-Path $androidHome 'build-tools\36.1.0\aapt2.exe') -Description 'Android Build Tools 36.1.0'
Assert-Exists -Path (Join-Path $androidHome 'platform-tools\adb.exe') -Description 'Android platform-tools'
Assert-Exists -Path (Join-Path $androidHome 'cmdline-tools\latest\bin\sdkmanager.bat') -Description 'Android Command-line Tools'
Assert-Exists -Path (Join-Path $androidHome 'ndk\29.0.14206865\source.properties') -Description 'Android NDK 29.0.14206865'
Assert-Exists -Path (Join-Path $androidHome 'cmake\3.10.2.4988404\source.properties') -Description 'CMake 3.10.2.4988404'

$templateRoot = Join-Path $env:APPDATA 'Godot\export_templates\4.7.1.stable'
Assert-Exists -Path (Join-Path $templateRoot 'windows_debug_x86_64.exe') -Description 'Template export Windows 4.7.1'
Assert-Exists -Path (Join-Path $templateRoot 'android_source.zip') -Description 'Template export Android 4.7.1'

$localBuildMarker = Join-Path $repoRoot 'android\.build_version'
Assert-Exists -Path $localBuildMarker -Description 'Template Gradle locale'
$localBuildVersion = (Get-Content -LiteralPath $localBuildMarker -Raw).Trim()
if ($localBuildVersion -ne '4.7.1.stable') {
    throw "Template Gradle locale inatteso: $localBuildVersion"
}
Write-Host '[OK] Template Gradle locale 4.7.1'

$projectSettingsPath = Join-Path $repoRoot 'project.godot'
$projectSettings = Get-Content -LiteralPath $projectSettingsPath -Raw
if ($projectSettings -notmatch 'config/features=PackedStringArray\("4\.7"') {
    throw 'project.godot non è fissato alla feature 4.7.'
}
if ($projectSettings -notmatch 'textures/vram_compression/import_etc2_astc=true') {
    throw 'La compressione texture ETC2/ASTC richiesta da Android non è attiva.'
}
if ($projectSettings -notmatch 'config/icon="res://assets/art/branding/pidgeon_survivor_app_icon\.png"') {
    throw "L'icona progetto richiesta dall'export Android non è configurata."
}
$exportPresetsPath = Join-Path $repoRoot 'export_presets.cfg'
$exportPresets = Get-Content -LiteralPath $exportPresetsPath -Raw
if ($exportPresets -notmatch 'launcher_icons/main_192x192="res://assets/art/branding/pidgeon_survivor_app_icon\.png"') {
    throw "La main icon Android Pidgeon Survivor non è configurata."
}
if ($exportPresets -notmatch 'launcher_icons/adaptive_foreground_432x432="res://assets/art/branding/pidgeon_survivor_adaptive_foreground\.png"') {
    throw "Il foreground adattivo Android Pidgeon Survivor non è configurato."
}
if ($exportPresets -notmatch 'launcher_icons/adaptive_background_432x432="res://assets/art/branding/pidgeon_survivor_adaptive_background\.png"') {
    throw "Il background adattivo Android Pidgeon Survivor non è configurato."
}
Write-Host '[OK] Impostazioni progetto Android'

$godotVersion = (& $godot --version).Trim()
if (-not $godotVersion.StartsWith('4.7.1.stable.official.')) {
    throw "Versione Godot inattesa: $godotVersion"
}
Write-Host "[OK] Godot $godotVersion"

$javaReleasePath = Join-Path $javaHome 'release'
Assert-Exists -Path $javaReleasePath -Description 'Metadati JDK'
$javaRelease = Get-Content -LiteralPath $javaReleasePath -Raw
if ($javaRelease -notmatch 'JAVA_VERSION="17\.') {
    throw "JDK 17 atteso. Metadati: $javaRelease"
}
Write-Host '[OK] Java 17'

if ($RunProjectSmoke) {
    & $godot --headless --path $repoRoot --import
    if ($LASTEXITCODE -ne 0) {
        throw "Import Godot fallito con codice $LASTEXITCODE."
    }

    $smokeOutput = (& $godot --headless --path $repoRoot -- --smoke-test 2>&1 | Out-String)
    if (($LASTEXITCODE -ne 0) -or ($smokeOutput -notmatch 'SMOKE_OK')) {
        throw "Smoke test fallito. Output: $smokeOutput"
    }
    Write-Host '[OK] Progetto importato e smoke test superato'
}

Write-Host 'Toolchain M0 pronta.'
