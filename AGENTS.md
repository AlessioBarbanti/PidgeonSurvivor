# Repository Guidelines

## Project Structure & Module Organization

This is a Godot 4.7.1/GDScript project targeting Windows x64 and Android ARM64. Root configuration lives in `project.godot` and `export_presets.cfg`. Reusable scenes belong under `scenes/` (`actors/`, `app/`, `game/`, `ui/`), with corresponding behavior under `scripts/`. Store game definitions in `data/`, source assets and their manifests in `assets/`, deterministic checks in `tests/integration/`, project decisions and verification evidence in `docs/`, and development utilities in `tools/`.

Treat `docs/development-plan.md` as the operational source of truth for milestone status, dependencies, and gates. Do not edit or commit generated content from `.godot/`, `exports/`, or `android/build/`.

## Build, Test, and Development Commands

Run commands from PowerShell at the repository root:

```powershell
godot --editor --path .
.\tools\verify-toolchain.ps1 -RunProjectSmoke
godot_console --headless --path . --script tests/integration/_input_subsystem_smoke.gd
godot_console --headless --path . --resolution 1280x720 --script tests/integration/_movement_slice_smoke.gd
godot_console --headless --path . --export-debug "Windows Desktop" exports/windows/PidgeonSurvivor.exe
godot_console --headless --path . --export-debug "Android APK" exports/android/pidgeon-survivor-debug.apk
```

The editor command imports and runs the project. The verification script checks Godot, JDK 17, Android tooling, templates, imports, and the main-scene smoke. Use `tools/run-milestone-checks.ps1` for a documented B-series verification sequence. Consult `docs/setup.md` before Android exports.

## Coding Style & Naming Conventions

Use UTF-8, LF line endings, and tabs for GDScript indentation. Prefer typed signals, parameters, returns, and exported properties. Use `snake_case` for files, variables, and functions; `PascalCase` for `class_name` declarations and scene nodes; and `SCREAMING_SNAKE_CASE` for constants. Keep dependencies scene-local and signal-driven. Route movement through `InputRouter`; derive bounds from `ArenaLayout`, not fixed screen coordinates.

## Testing Guidelines

Tests are deterministic `SceneTree` smoke scripts; no coverage framework is configured. Name tests `_feature_smoke.gd`, exit nonzero on failure, and print a unique `*_SMOKE_OK` marker. Cover pure layout/input math and composed scene behavior. P0 gameplay changes require focused smoke, relevant regression, a Windows export run, and physical Android validation when applicable; record platform evidence in `docs/`.

## Commit & Pull Request Guidelines

Recent history uses short imperative subjects such as `Polish active ability visuals`; keep commits focused. Pull requests should identify the milestone or issue, summarize behavior, list exact commands and platform results, and include screenshots or video for visual or touch changes. Update the development plan, decision log, and verification notes when contracts change.

## Security & Configuration

Never commit credentials, keystores, `local.properties`, APKs, or AABs. Provide signing values through documented environment variables. Changes to pinned Godot or Android versions must update templates, setup documentation, and both platform gates.
