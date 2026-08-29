---
name: il-gioco-milestone
description: Implement or validate a named B-series milestone, the first PRONTO backlog item, or a board card in docs/cards/, in the IL GIOCO (Pidgeon Survivor) Godot repository. Use for requests such as "procedi con B18X", "prendi il primo PRONTO", "risolvi PS-007", milestone verification, regression/export gates, or completion evidence. Cover dependencies, focused smoke tests, relevant regressions, Windows and Android gates, documentation, and focused commit preparation; do not use for unrelated Godot repositories or isolated questions that require no milestone workflow.
---

# IL GIOCO milestone

Treat current repository documents and code as authoritative. Keep this skill
procedural; do not restore stale contracts from memory. The architectural
contracts are summarized in `CLAUDE.md` at the repository root.

## Establish the slice

1. Run `git status --short` and preserve every pre-existing change. Do not clean, revert, stage, or commit unrelated work.
2. Read `docs/development-plan.md`. For a named milestone, locate its status, dependencies, acceptance criteria, test strategy, and platform gates. For "first PRONTO", select the first dependency-ready `PRONTO` item in the documented work order. For a `PS-*` request, read the card in `docs/cards/` and treat it as the contract.
3. Status vocabulary, in order: `DA DEFINIRE`, `BLOCCATO`, `PRONTO`, `IN CORSO`, `IN VERIFICA` (automated checks green, manual gates open), `VERIFICATO` (all gates closed, dedicated commit missing), `COMPLETATO`. Many slices legitimately rest at `IN VERIFICA`; never promote one without the required evidence.
4. Read only the relevant parts of `docs/prd.md`, `docs/decision-log.md`, `docs/content-approvals.md`, existing verification notes, affected scenes/scripts, and the closest smoke tests.
5. Stop and report the exact dependency or external gate when the selected slice is blocked. An unavailable Android device does not block implementation or static APK validation; it leaves the physical runtime gate open.

## Implement and check

1. Implement only the selected slice with typed, scene-local, signal-driven GDScript. Preserve established contracts, especially `RunController` ownership of logical time, pause, restart, and state transitions.
2. When touching welcome, tutorial, selection, pause, or modal flow, preserve `welcome -> (tutorial) -> selezione -> run -> pausa`; keep `BOOT` inactive until confirmation, and make cancel/Back close only the active modal.
3. Keep data declarative: `.tres` resources in `data/` carry `effect_id` plus parameters, while the logic stays in `AbilityEffectRegistry` and `UpgradeEffectRegistry`.
4. Add or update one deterministic `tests/integration/_*_smoke.gd` test with a unique `*_SMOKE_OK` marker and nonzero failure exit. Register new file/regression couplings in `tools/milestone-test-map.json`, otherwise the `Relevant` profile will never run them. Refresh the editor class/import cache before smoke tests after adding `class_name` scripts or imported assets.
5. Run the focused smoke before regressions. Use the smallest runner profile that matches the checkpoint; it auto-discovers a focused smoke whose marker begins with the milestone ID when possible:

   ```powershell
   # Inner loop: only the milestone smoke.
   .\tools\run-milestone-checks.ps1 -Milestone B18X -Profile Focused

   # Checkpoint: milestone smoke plus regressions selected from changed paths.
   .\tools\run-milestone-checks.ps1 -Milestone B18X -Profile Relevant

   # Final automatic gate, then release/export gate.
   .\tools\run-milestone-checks.ps1 -Milestone B18X -Profile Full
   .\tools\run-milestone-checks.ps1 -Milestone B18X -Profile Release
   ```

6. Pass `-FocusedSmoke` or `-ChangedPath` when discovery is ambiguous. Successful smoke and export results are cached by content hash; use `-NoCache` only for a deliberate clean rerun and `-PlanOnly` to inspect the plan without starting Godot. Inspect the compact summary and open the referenced full logs only for failing steps. Use `-OutputMode Detailed` only when step-level output is needed. The complete profile contract is in `docs/verification-workflow.md`.
7. Treat exit code zero as insufficient when logs contain `SCRIPT ERROR`, `FATAL EXCEPTION`, `SMOKE_FAIL`, or `CONTRACT_FAIL`.
8. After changing the runner or the test map, run `.\tests\tooling\_milestone_runner_contract.ps1`.

## Apply platform gates honestly

- Use `tools/inspect-android-artifact.ps1` for package, SDK, ABI, signature, hash, launcher, and ADB state. It derives expected values from `export_presets.cfg`.
- Report Windows runtime, Android static validation, and Android physical runtime as separate results.
- Never close an Android runtime, touch, lifecycle, or multitouch gate without installing the current APK, exercising the changed path on an attached device, and checking logs.
- For touch changes, physically hold the joystick with one finger while repeatedly activating the ability or control with a second finger.
- Do not substitute smoke tests or screenshots for requested perceptual, geometry, controller, or device checks.
- Never convert unrecorded trials into technical evidence. An owner's operational acceptance is recorded as such, distinct from evidence.

## Finish the checkpoint

1. Update `docs/development-plan.md` as the operational source of truth. Synchronize product contracts to `docs/prd.md`, decisions to `docs/decision-log.md`, approvals/provenance to `docs/content-approvals.md`, and milestone evidence to its verification note when applicable. For a card, update its status and the table in `docs/cards/README.md`.
2. New art or audio files require a row in the folder's `ASSET-MANIFEST.md` with path, origin, author, license, transformations, and SHA-256. Only derived runtime files are referenced by the game; HD masters stay excluded from exports.
3. Run `git diff --check`, review the scoped diff, and confirm generated `.godot/`, `exports/`, and `android/build/` content is not staged.
4. Commit only when explicitly requested. Keep the commit focused, write it in Italian as `feat(B18X): ...` or `fix(B18X): ...`, and do not push unless asked.
5. Report changed behavior, exact commands and markers, Windows/Android results, open manual gates, and unrelated pre-existing changes left untouched.
