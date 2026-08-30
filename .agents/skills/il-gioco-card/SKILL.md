---
name: il-gioco-card
description: Create, implement, validate, or close a PS-* card from docs/cards/ in the IL GIOCO (Pidgeon Survivor) Godot repository. Use for requests such as "apri una card", "risolvi PS-007", "prendi la prossima card", legacy B-series requests that must be mapped to a card, regression/export gates, or card completion evidence. Cover dependencies, card-local decisions, focused smoke tests, relevant regressions, Windows and Android gates, durable-contract synchronization, and focused commit preparation.
---

# IL GIOCO card

Treat the card board and current code as authoritative. Do not recreate a
development plan or decision log.

## Select the card

1. Run `git status --short`; preserve unrelated work.
2. Read `docs/cards/README.md` and the selected `PS-*.md` card. For "next",
   finish `IN CORSO` first, then select the highest-priority dependency-ready
   `PRONTO` card; break ties by numeric ID.
3. For a legacy B-series request, search the card frontmatter field `origine`.
   If no card owns that work, create one before implementation.
4. Stop on `DA DEFINIRE` or `BLOCCATO` and report the exact question or unmet
   `dipende_da` card. Do not bypass the board order silently.
5. Read only relevant durable contracts (`CLAUDE.md`, `docs/prd.md`, domain
   catalogs/approvals), evidence notes, code, and closest tests.

## Implement and decide

1. Set the card to `IN CORSO` and update the board row/date.
2. Implement only its acceptance criteria. Put adjacent work in a new card.
3. Preserve typed, scene-local, signal-driven GDScript; keep data declarative
   and logic in registries/controllers.
4. Record material scope, gameplay, architecture, content, or acceptance
   decisions in the card's `Decisioni` section with rationale and consequences.
   Do not create a separate decision log.
5. If a decision changes current truth, synchronize only the resulting contract
   to `CLAUDE.md`, `docs/prd.md`, `characters.md`, `powerup-catalog.md`,
   `content-approvals.md`, or `setup.md` as appropriate.

## Verify

Add or update one deterministic smoke when runtime behavior changes. Register
file-to-regression coupling in `tools/milestone-test-map.json` and refresh the
editor after new `class_name` scripts or imported assets.

The runner keeps its historical `-Milestone` parameter name but accepts card
IDs. Pass the focused smoke explicitly because markers need not contain `PS-*`:

```powershell
.\tools\run-milestone-checks.ps1 -Milestone PS-010 -Profile Focused `
  -FocusedSmoke tests/integration/_grill_defense_mode_smoke.gd
.\tools\run-milestone-checks.ps1 -Milestone PS-010 -Profile Relevant `
  -FocusedSmoke tests/integration/_grill_defense_mode_smoke.gd
.\tools\run-milestone-checks.ps1 -Milestone PS-010 -Profile Full
.\tools\run-milestone-checks.ps1 -Milestone PS-010 -Profile Release
```

Inspect logs for `SCRIPT ERROR`, `FATAL EXCEPTION`, `SMOKE_FAIL`, and
`CONTRACT_FAIL`; exit code zero alone is insufficient. After runner/test-map
changes, run `tests/tooling/_milestone_runner_contract.ps1`.

## Apply platform gates honestly

- Report Windows runtime, APK static inspection, install, and Android physical
  runtime separately.
- Close touch/lifecycle/multitouch only after installing the current APK,
  exercising the path on the device, and reading logs.
- Do not substitute screenshots or smoke tests for perceptual/physical gates.
- Record an explicit owner waiver as operational acceptance, never as evidence.

## Close the card

1. Check only criteria and gates actually satisfied.
2. Use `IN VERIFICA` while manual gates remain, `VERIFICATO` when required
   evidence is complete, and `COMPLETATO` when the card is accepted and closed.
3. Update `Decisioni`, `Documenti sincronizzati`, `Note`, date, and the board row.
4. Check that card metadata, dependencies, and the board row stay aligned.
5. Add asset/audio provenance and hashes to the local manifest when applicable.
6. Run unstaged and staged `git diff --check`; review the focused diff and keep
   generated outputs unstaged.
7. Commit only on explicit request, with Italian subject such as
   `feat(PS-010): ...`; never push unless asked.
