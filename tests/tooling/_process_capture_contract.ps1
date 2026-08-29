[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Contratto della cattura di processi usata da tools/run-milestone-checks.ps1.
#
# Copre il caso che ha motivato il layer: uno strumento che dichiara di aver
# finito e poi resta aperto. Non serve Godot ne' un export reale: i processi
# finti riproducono l'output di Godot, marker e codici ANSI compresi.

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $repoRoot 'tools\lib\process-capture.ps1')

$pwsh = (Get-Process -Id $PID).Path
$esc = [char]27
# Lo stesso pattern usato dal runner per l'export Android.
$pattern = '^\[ DONE \]\s+export\b'
$failures = [Collections.Generic.List[string]]::new()

function Assert-That {
    param(
        [Parameter(Mandatory)]
        [string]$Label,

        [Parameter(Mandatory)]
        [bool]$Condition,

        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Detail
    )

    if (-not $Condition) {
        Write-Output "FAIL $Label -- $Detail"
        $script:failures.Add($Label)
    }
}

function Invoke-FakeTool {
    param(
        [Parameter(Mandatory)]
        [string]$Script,

        [hashtable]$CaptureArguments = @{}
    )

    return Invoke-CapturedProcess -FilePath $pwsh -Arguments @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', $Script
    ) -WorkingDirectory $repoRoot @CaptureArguments
}

# 1. Marker dichiarato, processo che poi resta appeso: e' il caso reale
#    dell'exporter Android su Windows.
$hangingExport = @"
Write-Output '[   0% ] first_scan_filesystem | Started'
Write-Output '$esc[92m[ DONE ]$esc[39m $esc[1mfirst_scan_filesystem$esc[22m'
Write-Output '[   0% ] export | Started Esportazione per Android (105 steps)'
Write-Output '$esc[92m[ DONE ]$esc[39m $esc[1mexport$esc[22m'
Write-Output 'Shell cwd was reset'
Start-Sleep -Seconds 120
"@
$marker = Invoke-FakeTool -Script $hangingExport -CaptureArguments @{
    TimeoutSeconds = 60
    CompletionPattern = $pattern
    CompletionGraceMs = 2000
}
Assert-That 'marker rilevato' $marker.CompletionMarkerSeen "seen=$($marker.CompletionMarkerSeen)"
Assert-That 'terminato dal marker' $marker.TerminatedAfterMarker "flag=$($marker.TerminatedAfterMarker)"
Assert-That 'exit 126 dopo il marker' ($marker.ExitCode -eq 126) "exit=$($marker.ExitCode)"
Assert-That 'niente attesa fino al timeout' ($marker.DurationMs -lt 15000) "durata=$($marker.DurationMs)ms"
Assert-That 'grazia concessa prima di terminare' ($marker.DurationMs -ge 2000) "durata=$($marker.DurationMs)ms"
Assert-That 'output catturato prima della terminazione' `
    ($marker.Output -match 'Shell cwd was reset') 'ultima riga assente'
Assert-That 'non classificato come scaduto' (-not $marker.TimedOut) "timedOut=$($marker.TimedOut)"

# 2. Godot stampa '[ DONE ]' anche per first_scan_filesystem, molto prima che
#    l'artefatto esista: quel marker non deve chiudere nulla.
$scanOnly = @"
Write-Output '$esc[92m[ DONE ]$esc[39m $esc[1mfirst_scan_filesystem$esc[22m'
Start-Sleep -Seconds 4
Write-Output 'FINE'
exit 0
"@
$scan = Invoke-FakeTool -Script $scanOnly -CaptureArguments @{
    TimeoutSeconds = 60
    CompletionPattern = $pattern
    CompletionGraceMs = 2000
}
Assert-That 'il DONE dello scan non e'' un completamento' `
    (-not $scan.CompletionMarkerSeen) "seen=$($scan.CompletionMarkerSeen)"
Assert-That 'nessuna terminazione forzata sullo scan' `
    (-not $scan.TerminatedAfterMarker) "flag=$($scan.TerminatedAfterMarker)"
Assert-That 'exit reale preservato' ($scan.ExitCode -eq 0) "exit=$($scan.ExitCode)"
Assert-That 'output completo dopo il marker ignorato' ($scan.Output -match 'FINE') 'riga FINE assente'

# 3. Chi esce da solo dopo il marker non va ucciso ne' riclassificato.
$cleanExit = @"
Write-Output '$esc[92m[ DONE ]$esc[39m $esc[1mexport$esc[22m'
exit 0
"@
$clean = Invoke-FakeTool -Script $cleanExit -CaptureArguments @{
    TimeoutSeconds = 60
    CompletionPattern = $pattern
    CompletionGraceMs = 2000
}
Assert-That 'marker rilevato su uscita pulita' $clean.CompletionMarkerSeen "seen=$($clean.CompletionMarkerSeen)"
Assert-That 'uscito da solo, non terminato' (-not $clean.TerminatedAfterMarker) "flag=$($clean.TerminatedAfterMarker)"
Assert-That 'exit reale su uscita pulita' ($clean.ExitCode -eq 0) "exit=$($clean.ExitCode)"

# 4. Senza marker riconoscibile resta il ripiego sulla stabilita' dell'artefatto.
$artifact = Join-Path ([IO.Path]::GetTempPath()) 'process-capture-contract.bin'
if (Test-Path -LiteralPath $artifact) {
    Remove-Item -LiteralPath $artifact -Force
}
try {
    $writeThenHang = @"
Set-Content -LiteralPath '$artifact' -Value 'contenuto' -Encoding utf8
Start-Sleep -Seconds 120
"@
    $stable = Invoke-FakeTool -Script $writeThenHang -CaptureArguments @{
        TimeoutSeconds = 60
        StableArtifactPath = $artifact
        StableArtifactSeconds = 3
    }
    Assert-That 'terminato dopo artefatto stabile' `
        $stable.TerminatedAfterArtifact "flag=$($stable.TerminatedAfterArtifact)"
    Assert-That 'exit 125 sul ripiego' ($stable.ExitCode -eq 125) "exit=$($stable.ExitCode)"
    Assert-That 'artefatto riconosciuto come riscritto' `
        $stable.ArtifactChanged "changed=$($stable.ArtifactChanged)"
    Assert-That 'ripiego piu'' rapido del timeout' `
        ($stable.DurationMs -lt 20000) "durata=$($stable.DurationMs)ms"
}
finally {
    if (Test-Path -LiteralPath $artifact) {
        Remove-Item -LiteralPath $artifact -Force
    }
}

# 5. Senza alcun segnale resta la scadenza esterna.
$timeout = Invoke-FakeTool -Script 'Start-Sleep -Seconds 120' -CaptureArguments @{
    TimeoutSeconds = 5
    CompletionPattern = $pattern
}
Assert-That 'scaduto senza segnali' $timeout.TimedOut "timedOut=$($timeout.TimedOut)"
Assert-That 'exit 124 sul timeout' ($timeout.ExitCode -eq 124) "exit=$($timeout.ExitCode)"

if ($failures.Count -gt 0) {
    Write-Output "CONTRACT_FAIL: $($failures.Count) asserzioni fallite."
    exit 1
}

Write-Output 'PROCESS_CAPTURE_CONTRACT_OK'
