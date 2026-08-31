[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$runner = Join-Path $repoRoot 'tools\run-milestone-checks.ps1'
$testMapPath = Join-Path $repoRoot 'tools\milestone-test-map.json'

$testMap = Get-Content -LiteralPath $testMapPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($testMap.version -ne 2 -or $testMap.rules.Count -eq 0) {
    throw 'Manifest di selezione test assente o con versione inattesa.'
}
foreach ($smoke in @($testMap.rules.smokes | Sort-Object -Unique)) {
    if (-not (Test-Path -LiteralPath (Join-Path $repoRoot $smoke) -PathType Leaf)) {
        throw "Smoke mappato inesistente: $smoke"
    }
}

function Invoke-Plan {
    param(
        [Parameter(Mandatory)]
        [string]$Profile,

        [Parameter(Mandatory)]
        [string[]]$ChangedPath
    )

    $json = & $runner -Milestone B24 -Profile $Profile -ChangedPath $ChangedPath `
        -PlanOnly -NoCache -AsJson
    if ($LASTEXITCODE -ne 0) {
        throw "Plan B24 $Profile fallito con exit $LASTEXITCODE."
    }
    return $json | ConvertFrom-Json
}

$relevant = Invoke-Plan -Profile Relevant -ChangedPath @('scripts/actors/player.gd')
if ($relevant.focused_smokes -notcontains 'tests/unit/test_b24_player_visual_scale.gd') {
    throw 'Il profilo Relevant non ha individuato il test focused B24.'
}
foreach ($expected in @(
    'tests/unit/test_b18c_player_direction_animation.gd',
    'tests/unit/test_b06_player_survival.gd',
    'tests/unit/test_b17a_complete_roster_abilities.gd'
)) {
    if ($relevant.regression_smokes -notcontains $expected) {
        throw "Mappatura Player mancante: $expected"
    }
}
if ($relevant.export_windows -or $relevant.export_android) {
    throw 'Relevant non deve esportare artefatti.'
}

$docsOnly = Invoke-Plan -Profile Relevant -ChangedPath @('docs/development-plan.md')
if ($docsOnly.regression_smokes.Count -ne 0) {
    throw 'Una modifica solo documentale non deve invalidare regressioni runtime.'
}

# PS-023: un manifest o un README *dentro* assets/ resta documentazione. Prima
# finiva fra le path runtime non mappate e faceva scattare run_all, cioe' ogni
# card che aggiornava la propria documentazione pagava un Full.
$assetDocsOnly = Invoke-Plan -Profile Relevant -ChangedPath @(
    'assets/art/vfx/ASSET-MANIFEST.md',
    'docs/cards/README.md'
)
if ($assetDocsOnly.regression_smokes.Count -ne 0) {
    throw 'Un manifest documentale dentro assets/ non deve far scattare run_all.'
}

# PS-023: un singolo script runtime mappato deve restare un checkpoint, non
# diventare la suite intera.
$singleRuntime = Invoke-Plan -Profile Relevant -ChangedPath @(
    'scripts/ui/upgrade_overlay.gd',
    'docs/cards/README.md'
)
$allGutTests = @(
    Get-ChildItem (Join-Path $repoRoot 'tests') -Filter 'test_*.gd' -File -Recurse
).Count
if ($singleRuntime.regression_smokes.Count -eq 0) {
    throw 'Uno script UI mappato deve selezionare le proprie regressioni.'
}
if ($singleRuntime.regression_smokes.Count -ge $allGutTests) {
    throw 'Uno script UI mappato non deve far scattare la suite completa.'
}

# PS-030: un test eliminato (git rm, non modificato) resta nel diff di
# git diff --name-only HEAD ma non ha piu' nulla da eseguire. Deve essere
# escluso dal set di regressione senza far crashare il plan.
$deletedTestPath = 'tests/unit/test_ps030_deleted_placeholder.gd'
if (Test-Path -LiteralPath (Join-Path $repoRoot $deletedTestPath) -PathType Leaf) {
    throw "Fixture PS-030 inattesa su disco: $deletedTestPath deve non esistere."
}
$deletedTest = Invoke-Plan -Profile Relevant -ChangedPath @($deletedTestPath)
if ($deletedTest.regression_smokes -contains $deletedTestPath) {
    throw 'Un file di test cancellato non deve comparire nel set di regressione.'
}

$full = Invoke-Plan -Profile Full -ChangedPath @('docs/development-plan.md')
$allTestCount = @(Get-ChildItem (Join-Path $repoRoot 'tests') -Filter 'test_*.gd' -File -Recurse).Count
if (($full.focused_smokes.Count + $full.regression_smokes.Count) -ne $allTestCount) {
    throw 'Full deve pianificare ogni test una sola volta.'
}
if (-not $full.run_project_smoke -or $full.export_windows -or $full.export_android) {
    throw 'Full deve includere project smoke senza export.'
}

# PS-023: il batch GUT deve avere un tetto di tempo. Senza, un test appeso
# appende il runner all'infinito e senza output.
$runnerParameters = (Get-Command $runner).Parameters
if (-not $runnerParameters.ContainsKey('GutTimeoutSeconds')) {
    throw 'Il runner deve esporre -GutTimeoutSeconds: un batch senza tetto puo'' appendersi.'
}
$timeoutRange = @(
    $runnerParameters['GutTimeoutSeconds'].Attributes |
        Where-Object { $_ -is [System.Management.Automation.ValidateRangeAttribute] }
)
if ($timeoutRange.Count -eq 0 -or [int]$timeoutRange[0].MinRange -lt 60) {
    throw 'Il timeout del batch GUT deve avere un minimo sensato.'
}

# PS-023: un test rosso e' del suo script, non del batch. GUT con -gexit esce
# non-zero appena un test fallisce: leggere quell'exit code come fallimento di
# batch marcava FAIL ogni script del batch.
. (Join-Path $repoRoot 'tools\lib\gut-batch-status.ps1')

$noReason = @(
    Get-GutBatchFailureReasons -ExitCode 1 -TimedOut $false -ErrorMarkers @() `
        -ReportedFailures 1 -TimeoutSeconds 1800
)
if ($noReason.Count -ne 0) {
    throw 'Un test rosso gia'' attribuito al suo script non deve fallire tutto il batch.'
}

$greenRun = @(
    Get-GutBatchFailureReasons -ExitCode 0 -TimedOut $false -ErrorMarkers @() `
        -ReportedFailures 0 -TimeoutSeconds 1800
)
if ($greenRun.Count -ne 0) {
    throw 'Una run pulita non deve produrre motivi di fallimento del batch.'
}

$deadProcess = @(
    Get-GutBatchFailureReasons -ExitCode 3 -TimedOut $false -ErrorMarkers @() `
        -ReportedFailures 0 -TimeoutSeconds 1800
)
if ($deadProcess.Count -ne 1) {
    throw 'Un''uscita anomala senza test rossi deve essere un fallimento di batch.'
}

# Onesta' dei gate: un errore motore vale anche con report GUT verde.
$engineError = @(
    Get-GutBatchFailureReasons -ExitCode 0 -TimedOut $false `
        -ErrorMarkers @('SCRIPT ERROR') -ReportedFailures 0 -TimeoutSeconds 1800
)
if ($engineError.Count -ne 1) {
    throw 'Un errore motore deve fallire il batch anche con report GUT verde.'
}

$timedOut = @(
    Get-GutBatchFailureReasons -ExitCode 0 -TimedOut $true -ErrorMarkers @() `
        -ReportedFailures 0 -TimeoutSeconds 1800
)
if ($timedOut.Count -ne 1 -or $timedOut[0] -notmatch 'TIMEOUT') {
    throw 'Un batch scaduto deve essere dichiarato TIMEOUT.'
}

$release = Invoke-Plan -Profile Release -ChangedPath @('docs/development-plan.md')
if (
    -not $release.refresh_editor -or
    -not $release.run_project_smoke -or
    -not $release.export_windows -or
    -not $release.export_android -or
    -not $release.inspect_android
) {
    throw 'Release deve includere refresh, suite completa ed entrambi gli export.'
}

Write-Output 'MILESTONE_RUNNER_CONTRACT_OK'
