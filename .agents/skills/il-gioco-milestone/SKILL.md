---
name: il-gioco-milestone
description: Implement or validate a named B-series milestone, or the first PRONTO backlog item, in the IL GIOCO Godot repository. Use for requests such as "procedi con B18X", "prendi il primo PRONTO", milestone verification, regression/export gates, or completion evidence. Cover dependencies, focused smoke tests, relevant regressions, Windows and Android gates, documentation, and focused commit preparation; do not use for unrelated Godot repositories or isolated questions that require no milestone workflow.
---

# IL GIOCO milestone

Treat current repository documents and code as authoritative. Keep this skill procedural; do not restore stale contracts from memory.

## Establish the slice

1. Run `git status --short` and preserve every pre-existing change. Do not clean, revert, stage, or commit unrelated work.
2. Read `docs/development-plan.md`. For a named milestone, locate its status, dependencies, acceptance criteria, test strategy, and platform gates. For "first PRONTO", select the first dependency-ready `PRONTO` item in the documented work order.
3. Read only the relevant parts of `docs/prd.md`, `docs/decision-log.md`, `docs/content-approvals.md`, existing verification notes, affected scenes/scripts, and the closest smoke tests.
4. Stop and report the exact dependency or external gate when the selected slice is blocked. An unavailable Android device does not block implementation or static APK validation; it leaves the physical runtime gate open.

## Implement and check

1. Implement only the selected slice with typed, scene-local, signal-driven GDScript. Preserve established contracts, especially `RunController` ownership of logical time, pause, restart, and state transitions.
2. When touching welcome, selection, pause, or modal flow, preserve `welcome -> selezione -> run -> pausa`; keep `BOOT` inactive until confirmation, and make cancel/Back close only the active modal.
3. Add or update one deterministic `tests/integration/_*_smoke.gd` test with a unique `*_SMOKE_OK` marker and nonzero failure exit. Refresh the editor class/import cache before smoke tests after adding `class_name` scripts or imported assets.
4. Run the focused smoke before regressions. Use the compact runner; it auto-discovers a focused smoke whose marker begins with the milestone ID when possible:

   ```powershell
   .\tools\run-milestone-checks.ps1 `
     -Milestone B18X `
     -RegressionSmoke tests/integration/_relevant_smoke.gd `
     -RunProjectSmoke
   ```

5. Pass `-FocusedSmoke` when auto-discovery is ambiguous. Add `-ExportWindows` and `-ExportAndroid` only after headless checks pass. Inspect the compact summary and open the referenced full logs only for failing steps.
6. Treat exit code zero as insufficient when logs contain `SCRIPT ERROR`, `FATAL EXCEPTION`, `SMOKE_FAIL`, or `CONTRACT_FAIL`.

## Apply platform gates honestly

- Use `tools/inspect-android-artifact.ps1` for package, SDK, ABI, signature, hash, launcher, and ADB state. It derives expected values from `export_presets.cfg`.
- Report Windows runtime, Android static validation, and Android physical runtime as separate results.
- Never close an Android runtime, touch, lifecycle, or multitouch gate without installing the current APK, exercising the changed path on an attached device, and checking logs.
- For touch changes, physically hold the joystick with one finger while repeatedly activating the ability or control with a second finger.
- Do not substitute smoke tests or screenshots for requested perceptual, geometry, controller, or device checks.

## Finish the checkpoint

1. Update `docs/development-plan.md` as the operational source of truth. Synchronize product contracts to `docs/prd.md`, decisions to `docs/decision-log.md`, approvals/provenance to `docs/content-approvals.md`, and milestone evidence to its verification note when applicable.
2. Run `git diff --check`, review the scoped diff, and confirm generated `.godot/`, `exports/`, and `android/build/` content is not staged.
3. Commit only when explicitly requested. Keep the commit focused and do not push unless asked.
4. Report changed behavior, exact commands and markers, Windows/Android results, open manual gates, and unrelated pre-existing changes left untouched.
