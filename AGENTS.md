# Repository Guidelines

## Project Structure & Module Organization

This is a Godot 4.7.1/GDScript project targeting Windows x64 and Android ARM64. Root configuration lives in `project.godot` and `export_presets.cfg`. Reusable scenes are grouped under `scenes/` (`actors/`, `app/`, `game/`, `ui/`), with corresponding logic under `scripts/`. Put content definitions in `data/`, source assets in `assets/`, automated checks in `tests/integration/`, and project decisions or verification notes in `docs/`. Development utilities belong in `tools/`.

Do not edit or commit generated content in `.godot/`, `exports/`, or `android/build/`.

## Build, Test, and Development Commands

Run these from PowerShell at the repository root:

```powershell
godot --editor --path .
.\tools\verify-toolchain.ps1 -RunProjectSmoke
godot_console --headless --path . --script tests/integration/_input_subsystem_smoke.gd
godot_console --headless --path . --resolution 1280x720 --script tests/integration/_movement_slice_smoke.gd
godot_console --headless --path . --script tests/integration/_enemy_spawner_smoke.gd
godot_console --headless --path . --export-debug "Windows Desktop" exports/windows/FriendshipSurvival.exe
godot_console --headless --path . --export-debug "Android APK" exports/android/friendship-survival-debug.apk
```

The verification script checks Godot, JDK 17, Android SDK/NDK, templates, import, and the main-scene smoke test. See `docs/setup.md` before exporting Android.

## Coding Style & Naming Conventions

Use UTF-8, LF line endings, and tabs for GDScript indentation. Prefer typed signals, parameters, return values, and exported properties. Name files, variables, and functions `snake_case`; use `PascalCase` for `class_name` declarations and scene node names; use `SCREAMING_SNAKE_CASE` for constants. Keep dependencies scene-local and signal-driven. Route movement through `InputRouter`, and derive runtime bounds from `ArenaLayout` instead of fixed screen coordinates.

## Testing Guidelines

Tests are deterministic `SceneTree` smoke scripts; no separate coverage tool is configured. Name new checks `_feature_smoke.gd`, return a nonzero exit code on failure, and print a unique `*_SMOKE_OK` marker on success. Exercise pure layout/input math and composed scene behavior. P0 gameplay changes must also be smoke-tested in a Windows export and on an Android device; record device-specific evidence in `docs/`.

## Commit & Pull Request Guidelines

The repository has no commit history yet. Until a convention is established, use short imperative subjects, for example `Add Android safe-area input gate`, and keep each commit focused. Pull requests should summarize behavior, reference the backlog item or issue, list exact test commands and platform results, and include screenshots or video for visual/touch changes. Update `docs/development-plan.md`, `docs/decision-log.md`, or verification notes when contracts change.

## Security & Configuration

Never commit keystores, credentials, `local.properties`, APKs, or AABs. Supply signing values through the documented environment variables. Do not change the pinned Godot or Android toolchain versions without updating templates, setup documentation, and both platform gates.
