# Cattura di processi esterni per la verifica dei milestone.
#
# Vive separato dal runner per essere caricabile da solo: il runner esegue
# l'intera sequenza al caricamento, quindi non sarebbe testabile in isolamento.
# Il contratto e' coperto da tests/tooling/_process_capture_contract.ps1.

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

function Update-StreamCapture {
    param(
        [Parameter(Mandatory)]
        [hashtable]$State,

        [string]$CompletionPattern,

        [ValidateRange(0, 60000)]
        [int]$DrainMs = 0
    )

    $ansiPattern = "$([char]27)\[[0-9;]*m"
    $drainWatch = [Diagnostics.Stopwatch]::StartNew()
    while (-not $State.Complete) {
        $line = $null
        try {
            if ($null -eq $State.Pending) {
                $State.Pending = $State.Reader.ReadLineAsync()
            }

            $ready = $false
            if ($DrainMs -gt 0) {
                $remaining = $DrainMs - [int]$drainWatch.ElapsedMilliseconds
                if ($remaining -lt 0) {
                    $remaining = 0
                }
                $ready = $State.Pending.Wait($remaining)
            }
            else {
                $ready = $State.Pending.IsCompleted
            }
            if (-not $ready) {
                break
            }

            $line = $State.Pending.Result
            $State.Pending = $null
        }
        catch {
            # Lo stream puo' chiudersi bruscamente quando l'albero di processi
            # viene terminato: la cattura si ferma, il gia' letto resta valido.
            $State.Complete = $true
            break
        }

        if ($null -eq $line) {
            $State.Complete = $true
            break
        }

        $State.Lines.Add($line) | Out-Null
        if (
            -not [string]::IsNullOrEmpty($CompletionPattern) -and
            -not $State.MarkerSeen
        ) {
            # Godot colora l'output: il pattern va applicato al testo pulito.
            $plain = ($line -replace $ansiPattern, '').Trim()
            if ($plain -match $CompletionPattern) {
                $State.MarkerSeen = $true
            }
        }

        if ($DrainMs -gt 0 -and $drainWatch.ElapsedMilliseconds -ge $DrainMs) {
            break
        }
    }
}


function New-StreamCaptureState {
    param(
        [Parameter(Mandatory)]
        [IO.StreamReader]$Reader
    )

    return @{
        Reader = $Reader
        Pending = $null
        Lines = [Collections.Generic.List[string]]::new()
        Complete = $false
        MarkerSeen = $false
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
        [int]$StableArtifactSeconds = 0,

        # Regex applicata a ogni riga ripulita dai codici ANSI. Quando compare,
        # lo strumento ha dichiarato da se' il completamento: e' un segnale
        # semantico, non un'euristica sui metadati dell'artefatto.
        [string]$CompletionPattern,

        [ValidateRange(0, 60000)]
        [int]$CompletionGraceMs = 2000,

        # Un batch lungo che non stampa nulla e' indistinguibile da un blocco:
        # con questi due parametri il chiamante puo' emettere una riga di
        # avanzamento mentre il processo e' ancora vivo (PS-023).
        [ValidateRange(0, 600)]
        [int]$ProgressIntervalSeconds = 0,

        [scriptblock]$ProgressAction
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
    # Lettura incrementale invece di ReadToEndAsync: servono le righe mentre
    # arrivano, non solo all'EOF della pipe. Quell'EOF puo' non arrivare mai
    # se un processo nipote detached eredita l'handle su Windows.
    $stdoutState = New-StreamCaptureState -Reader $process.StandardOutput
    $stderrState = New-StreamCaptureState -Reader $process.StandardError
    $timedOut = $false
    $terminatedAfterArtifact = $false
    $terminatedAfterMarker = $false
    $artifactChanged = $false
    $lastArtifactSignature = $null
    $artifactStableSinceMs = 0L
    $markerSeenAtMs = -1L
    $lastProgressMs = 0L

    while (-not $process.WaitForExit(250)) {
        Update-StreamCapture -State $stdoutState -CompletionPattern $CompletionPattern
        Update-StreamCapture -State $stderrState -CompletionPattern $CompletionPattern

        if (
            $ProgressIntervalSeconds -gt 0 -and
            $null -ne $ProgressAction -and
            ($stopwatch.ElapsedMilliseconds - $lastProgressMs) -ge ($ProgressIntervalSeconds * 1000)
        ) {
            $lastProgressMs = $stopwatch.ElapsedMilliseconds
            & $ProgressAction $stopwatch.Elapsed $stdoutState.Lines
        }

        if (
            $TimeoutSeconds -gt 0 -and
            $stopwatch.Elapsed.TotalSeconds -ge $TimeoutSeconds
        ) {
            $timedOut = $true
            Stop-TrackedProcessTree -RootProcessId $processId
            break
        }

        # Priorita' al marker: e' immediato e non dipende da quando il
        # filesystem smette di cambiare. La grazia lascia comunque allo
        # strumento la possibilita' di uscire da solo.
        if (
            -not [string]::IsNullOrEmpty($CompletionPattern) -and
            ($stdoutState.MarkerSeen -or $stderrState.MarkerSeen)
        ) {
            if ($markerSeenAtMs -lt 0) {
                $markerSeenAtMs = $stopwatch.ElapsedMilliseconds
            }
            elseif (
                ($stopwatch.ElapsedMilliseconds - $markerSeenAtMs) -ge $CompletionGraceMs
            ) {
                $terminatedAfterMarker = $true
                Stop-TrackedProcessTree -RootProcessId $processId
                break
            }
        }

        # Ripiego per gli strumenti che non dichiarano nulla di riconoscibile.
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

    # Drena il residuo con una scadenza: attendere l'EOF senza limite e'
    # esattamente il blocco che questa funzione deve evitare.
    Update-StreamCapture -State $stdoutState -CompletionPattern $CompletionPattern -DrainMs 2000
    Update-StreamCapture -State $stderrState -CompletionPattern $CompletionPattern -DrainMs 2000

    if (
        -not $artifactChanged -and
        -not [string]::IsNullOrWhiteSpace($StableArtifactPath) -and
        (Test-Path -LiteralPath $StableArtifactPath -PathType Leaf)
    ) {
        # Un export chiuso dal marker puo' non aver mai attraversato il ramo di
        # stabilita': il confronto finale evita di dichiarare invariato un
        # artefatto che invece e' stato riscritto.
        $artifactFinal = Get-Item -LiteralPath $StableArtifactPath
        $artifactChanged = ($null -eq $artifactBefore) -or
            ($artifactBefore.Length -ne $artifactFinal.Length) -or
            ($artifactBefore.LastWriteTimeUtc -ne $artifactFinal.LastWriteTimeUtc)
    }

    $stdout = ($stdoutState.Lines -join [Environment]::NewLine)
    $stderr = ($stderrState.Lines -join [Environment]::NewLine)
    if (-not $stdoutState.Complete) {
        if (-not [string]::IsNullOrWhiteSpace($stdout)) {
            $stdout = $stdout + [Environment]::NewLine
        }
        $stdout = $stdout + '[stdout ancora aperto; cattura chiusa alla scadenza]'
    }
    $output = @($stdout.TrimEnd(), $stderr.TrimEnd()) |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    $exitCode = if ($timedOut) {
        124
    }
    elseif ($terminatedAfterMarker) {
        126
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
        TerminatedAfterMarker = $terminatedAfterMarker
        CompletionMarkerSeen = ($stdoutState.MarkerSeen -or $stderrState.MarkerSeen)
        ArtifactChanged = $artifactChanged
        ProcessId = $processId
        DurationMs = $stopwatch.ElapsedMilliseconds
        Output = ($output -join [Environment]::NewLine)
    }
}
