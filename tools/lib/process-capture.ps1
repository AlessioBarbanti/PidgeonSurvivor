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

# La cattura passa da file, non da pipe. Drenare stdout dal processo padre in
# PowerShell strozzava il figlio: lo stesso file GUT misurava 3,7 s con output
# rediretto su file e 55,9 s letto riga per riga dalla pipe, perche' Godot
# resta bloccato in scrittura fra un giro di lettura e l'altro. Il tempo dei
# test non dipende piu' da come li si guarda.
function Update-FileTailCapture {
    param(
        [Parameter(Mandatory)]
        [hashtable]$State,

        [string]$CompletionPattern,

        [switch]$Final
    )

    if (-not (Test-Path -LiteralPath $State.Path -PathType Leaf)) {
        return
    }

    $text = ''
    $stream = $null
    try {
        # FileShare::ReadWrite: il figlio tiene il file aperto in scrittura
        # mentre lo si legge.
        $stream = [IO.File]::Open(
            $State.Path,
            [IO.FileMode]::Open,
            [IO.FileAccess]::Read,
            [IO.FileShare]::ReadWrite
        )
        if ($stream.Length -gt $State.Offset) {
            $count = [int]($stream.Length - $State.Offset)
            $null = $stream.Seek($State.Offset, [IO.SeekOrigin]::Begin)
            $buffer = New-Object byte[] $count
            $read = $stream.Read($buffer, 0, $count)
            $State.Offset += $read
            $text = [Text.Encoding]::UTF8.GetString($buffer, 0, $read)
        }
    }
    catch {
        # Il file puo' essere momentaneamente inaccessibile mentre l'albero di
        # processi viene terminato: il gia' letto resta valido.
        return
    }
    finally {
        if ($null -ne $stream) {
            $stream.Dispose()
        }
    }

    if ($text.Length -eq 0 -and -not $Final) {
        return
    }

    $pending = $State.Partial + $text
    $parts = $pending -split "`n"
    if ($Final) {
        $State.Partial = ''
    }
    else {
        # L'ultimo segmento e' una riga ancora incompleta finche' non arriva
        # il newline successivo.
        $State.Partial = $parts[-1]
        $parts = @($parts[0..($parts.Count - 2)])
    }

    $ansiPattern = "$([char]27)\[[0-9;]*m"
    foreach ($part in $parts) {
        $line = $part -replace "`r$", ''
        if ($Final -and $line.Length -eq 0 -and $parts.Count -eq 1) {
            continue
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
    }
}


function New-FileTailCaptureState {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    return @{
        Path = $Path
        Offset = 0L
        Partial = ''
        Lines = [Collections.Generic.List[string]]::new()
        MarkerSeen = $false
    }
}


# Esegue piu' processi in parallelo con un solo ciclo di sorveglianza.
#
# Nasce per il batch GUT a shard: creare un job PowerShell per shard costava
# ~1,5 s ciascuno, pagati in sequenza prima ancora che partisse un test (~9 s
# su 6 shard). I job servivano solo a riusare Invoke-CapturedProcess, che
# blocca; ora che la cattura passa da file, i processi si avviano diretti e si
# sorvegliano insieme.
#
# Ogni voce di -Specs e' una hashtable: Label, Arguments, StdoutPath,
# StderrPath e, opzionale, Environment (hashtable di variabili applicate solo
# a quel figlio).
function Invoke-CapturedProcessGroup {
    param(
        [Parameter(Mandatory)]
        [hashtable[]]$Specs,

        [Parameter(Mandatory)]
        [string]$FilePath,

        [Parameter(Mandatory)]
        [string]$WorkingDirectory,

        [ValidateRange(0, 3600)]
        [int]$TimeoutSeconds = 0,

        [ValidateRange(0, 600)]
        [int]$ProgressIntervalSeconds = 0,

        [scriptblock]$ProgressAction
    )

    $stopwatch = [Diagnostics.Stopwatch]::StartNew()
    $running = [Collections.Generic.List[object]]::new()

    foreach ($spec in $Specs) {
        New-Item -ItemType File -Path $spec.StdoutPath -Force | Out-Null
        New-Item -ItemType File -Path $spec.StderrPath -Force | Out-Null

        # Il figlio eredita l'ambiente del padre al momento dell'avvio: si
        # imposta la variabile, si avvia, si ripristina. I processi partono in
        # sequenza, quindi non si sovrappongono.
        $saved = @{}
        if ($spec.ContainsKey('Environment') -and $null -ne $spec.Environment) {
            foreach ($key in $spec.Environment.Keys) {
                $saved[$key] = [Environment]::GetEnvironmentVariable($key)
                Set-Item -Path "Env:$key" -Value $spec.Environment[$key]
            }
        }

        $argumentLine = (($spec.Arguments | ForEach-Object {
            ConvertTo-CommandLineArgument -Value $_
        }) -join ' ')
        try {
            $process = Start-Process -FilePath $FilePath -ArgumentList $argumentLine `
                -WorkingDirectory $WorkingDirectory `
                -RedirectStandardOutput $spec.StdoutPath `
                -RedirectStandardError $spec.StderrPath `
                -NoNewWindow -PassThru
        }
        finally {
            foreach ($key in $saved.Keys) {
                if ($null -eq $saved[$key]) {
                    Remove-Item -Path "Env:$key" -ErrorAction SilentlyContinue
                }
                else {
                    Set-Item -Path "Env:$key" -Value $saved[$key]
                }
            }
        }
        if ($null -eq $process) {
            throw "Impossibile avviare: $FilePath"
        }
        $null = $process.Handle

        $running.Add([pscustomobject]@{
            Label = $spec.Label
            Process = $process
            ProcessId = $process.Id
            StdoutState = New-FileTailCaptureState -Path $spec.StdoutPath
            StderrState = New-FileTailCaptureState -Path $spec.StderrPath
            StdoutPath = $spec.StdoutPath
            StderrPath = $spec.StderrPath
            TimedOut = $false
            DurationMs = 0L
        })
    }

    $lastProgressMs = 0L
    while ($true) {
        $alive = @($running | Where-Object { -not $_.Process.HasExited })
        foreach ($entry in $running) {
            Update-FileTailCapture -State $entry.StdoutState
            Update-FileTailCapture -State $entry.StderrState
            if ($entry.Process.HasExited -and $entry.DurationMs -eq 0) {
                $entry.DurationMs = $stopwatch.ElapsedMilliseconds
            }
        }
        if ($alive.Count -eq 0) {
            break
        }

        if (
            $ProgressIntervalSeconds -gt 0 -and
            $null -ne $ProgressAction -and
            ($stopwatch.ElapsedMilliseconds - $lastProgressMs) -ge ($ProgressIntervalSeconds * 1000)
        ) {
            $lastProgressMs = $stopwatch.ElapsedMilliseconds
            & $ProgressAction $stopwatch.Elapsed $alive.Count $running.Count
        }

        if (
            $TimeoutSeconds -gt 0 -and
            $stopwatch.Elapsed.TotalSeconds -ge $TimeoutSeconds
        ) {
            foreach ($entry in $alive) {
                $entry.TimedOut = $true
                $entry.DurationMs = $stopwatch.ElapsedMilliseconds
                Stop-TrackedProcessTree -RootProcessId $entry.ProcessId
            }
            break
        }

        Start-Sleep -Milliseconds 250
    }
    $stopwatch.Stop()

    # Coda dell'output: il figlio puo' tenere il file aperto un istante ancora
    # dopo l'uscita o la terminazione dell'albero.
    for ($attempt = 0; $attempt -lt 5; $attempt++) {
        foreach ($entry in $running) {
            Update-FileTailCapture -State $entry.StdoutState
            Update-FileTailCapture -State $entry.StderrState
        }
        Start-Sleep -Milliseconds 40
    }

    $results = [Collections.Generic.List[object]]::new()
    foreach ($entry in $running) {
        Update-FileTailCapture -State $entry.StdoutState -Final
        Update-FileTailCapture -State $entry.StderrState -Final

        $stdout = ($entry.StdoutState.Lines -join [Environment]::NewLine)
        $stderr = ($entry.StderrState.Lines -join [Environment]::NewLine)
        $output = @($stdout.TrimEnd(), $stderr.TrimEnd()) |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        $exitCode = if ($entry.TimedOut) { 124 } else { $entry.Process.ExitCode }
        $duration = if ($entry.DurationMs -gt 0) { $entry.DurationMs } else { $stopwatch.ElapsedMilliseconds }
        $entry.Process.Dispose()
        Remove-Item -LiteralPath $entry.StdoutPath, $entry.StderrPath -Force -ErrorAction SilentlyContinue

        $results.Add([pscustomobject]@{
            Label = $entry.Label
            ExitCode = $exitCode
            TimedOut = $entry.TimedOut
            DurationMs = $duration
            Output = ($output -join [Environment]::NewLine)
        })
    }
    return @($results)
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

    $argumentLine = (($Arguments | ForEach-Object {
        ConvertTo-CommandLineArgument -Value $_
    }) -join ' ')

    # File temporanei come destinazione diretta del figlio: la pipe non esiste
    # piu', quindi non puo' riempirsi ne' bloccare chi scrive.
    $captureId = [Guid]::NewGuid().ToString('N')
    $tempRoot = [IO.Path]::GetTempPath()
    $stdoutPath = Join-Path $tempRoot "capture-$captureId.out"
    $stderrPath = Join-Path $tempRoot "capture-$captureId.err"
    New-Item -ItemType File -Path $stdoutPath -Force | Out-Null
    New-Item -ItemType File -Path $stderrPath -Force | Out-Null

    $stopwatch = [Diagnostics.Stopwatch]::StartNew()
    $startArguments = @{
        FilePath = $FilePath
        WorkingDirectory = $WorkingDirectory
        RedirectStandardOutput = $stdoutPath
        RedirectStandardError = $stderrPath
        NoNewWindow = $true
        PassThru = $true
    }
    if (-not [string]::IsNullOrWhiteSpace($argumentLine)) {
        $startArguments['ArgumentList'] = $argumentLine
    }
    $process = Start-Process @startArguments
    if ($null -eq $process) {
        throw "Impossibile avviare: $FilePath"
    }
    # Toccare Handle subito fa memorizzare l'handle nativo: senza, l'oggetto
    # restituito da Start-Process -PassThru espone un ExitCode vuoto una volta
    # che il processo e' finito.
    $null = $process.Handle

    $processId = $process.Id
    # Lettura incrementale del file mentre cresce: servono le righe mentre
    # arrivano (marker, avanzamento), non solo alla fine.
    $stdoutState = New-FileTailCaptureState -Path $stdoutPath
    $stderrState = New-FileTailCaptureState -Path $stderrPath
    $timedOut = $false
    $terminatedAfterArtifact = $false
    $terminatedAfterMarker = $false
    $artifactChanged = $false
    $lastArtifactSignature = $null
    $artifactStableSinceMs = 0L
    $markerSeenAtMs = -1L
    $lastProgressMs = 0L

    while (-not $process.WaitForExit(250)) {
        Update-FileTailCapture -State $stdoutState -CompletionPattern $CompletionPattern
        Update-FileTailCapture -State $stderrState -CompletionPattern $CompletionPattern

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

    # Il figlio puo' avere ancora il file aperto per un istante dopo la
    # terminazione dell'albero: qualche tentativo breve basta a raccogliere la
    # coda senza attendere un EOF che potrebbe non arrivare mai.
    for ($attempt = 0; $attempt -lt 5; $attempt++) {
        Update-FileTailCapture -State $stdoutState -CompletionPattern $CompletionPattern
        Update-FileTailCapture -State $stderrState -CompletionPattern $CompletionPattern
        Start-Sleep -Milliseconds 40
    }
    Update-FileTailCapture -State $stdoutState -CompletionPattern $CompletionPattern -Final
    Update-FileTailCapture -State $stderrState -CompletionPattern $CompletionPattern -Final

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
    Remove-Item -LiteralPath $stdoutPath, $stderrPath -Force -ErrorAction SilentlyContinue

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
