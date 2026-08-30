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

$full = Invoke-Plan -Profile Full -ChangedPath @('docs/development-plan.md')
$allTestCount = @(Get-ChildItem (Join-Path $repoRoot 'tests') -Filter 'test_*.gd' -File -Recurse).Count
if (($full.focused_smokes.Count + $full.regression_smokes.Count) -ne $allTestCount) {
    throw 'Full deve pianificare ogni test una sola volta.'
}
if (-not $full.run_project_smoke -or $full.export_windows -or $full.export_android) {
    throw 'Full deve includere project smoke senza export.'
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
