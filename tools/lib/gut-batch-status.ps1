Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Distingue il fallimento di un singolo test dal fallimento del batch GUT.

.DESCRIPTION
    GUT con `-gexit` esce con codice non-zero appena un test fallisce. Quel
    rosso e' gia' attribuito al proprio script dal report JUnit, quindi non e'
    una causa di fallimento del batch: leggerlo come tale significava marcare
    `FAIL` tutti gli script del batch, 65 righe rosse per un solo test davvero
    fallito (PS-023).

    Restano fallimenti di batch soltanto le cause che il report per-script non
    puo' esprimere:

    - il timeout, perche' il processo e' stato terminato dall'esterno;
    - un errore motore fuori dalle asserzioni (`SCRIPT ERROR`,
      `FATAL EXCEPTION`, `CONTRACT_FAIL`, `SMOKE_FAIL`), che GUT puo' non
      tradurre in alcuna asserzione fallita: e' il contratto di onesta' dei
      gate in CLAUDE.md, e vale anche con report verde;
    - un'uscita anomala senza alcun test rosso, cioe' il processo morto fuori
      dai test.

    Funzione pura: nessun accesso a disco, processi o stato globale, cosi'
    `tests/tooling/_milestone_runner_contract.ps1` puo' verificarla senza
    avviare Godot.
#>
function Get-GutBatchFailureReasons {
    param(
        [Parameter(Mandatory)]
        [int]$ExitCode,

        [Parameter(Mandatory)]
        [bool]$TimedOut,

        [AllowEmptyCollection()]
        [string[]]$ErrorMarkers = @(),

        [int]$ReportedFailures = 0,

        [int]$TimeoutSeconds = 0
    )

    $reasons = [Collections.Generic.List[string]]::new()

    if ($TimedOut) {
        $reasons.Add(
            "TIMEOUT dopo $TimeoutSeconds s: processo terminato, log parziale conservato."
        )
    }
    if ($null -ne $ErrorMarkers -and $ErrorMarkers.Count -gt 0) {
        $reasons.Add(
            'Errore motore fuori dalle asserzioni GUT: ' + ($ErrorMarkers -join ', ') + '.'
        )
    }
    if (-not $TimedOut -and $ExitCode -ne 0 -and $ReportedFailures -eq 0) {
        $reasons.Add(
            "Uscita $ExitCode con report GUT verde: il processo e' morto fuori dai test."
        )
    }

    return @($reasons)
}
