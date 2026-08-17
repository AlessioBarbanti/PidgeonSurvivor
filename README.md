# Friendship Survival

Prototipo 2D in Godot 4.7.1, organizzato a partire dal PRD in
[`docs/prd.md`](docs/prd.md).

Target co-primari:

- Windows x64;
- Android 12–16 (API 31–36), ARM64, landscape.

Il vertical slice corrente completa B06A, B09, B09A, B10, B11 e B12, usa il renderer Compatibility e
include movimento 8 direzioni,
joystick touch, arena responsive, nemici inseguitori, spawner dinamico, targeting
del vivo più vicino, fuoco automatico, proiettili, salute Player, danno da
contatto, invulnerabilità, Game Over, restart, drop XP e raccolta magnetica con
accredito singolo, livelli, soglie XP configurabili, overflow e coda delle
scelte, HUD safe-area con vita, XP, livello, timer e abilità attiva, pausa
manuale e lifecycle Android senza resume automatico. Include inoltre il
framework dati/runtime delle abilità e l'Onda d'Urto Tellurica di Magno con
input tastiera, controller e touch, cooldown, danno radiale e knockback. B10
aggiunge inoltre `UpgradeDefinition`, catalogo validato, rank per run e pesca
pesata deterministica di tre ID unici con fallback ripetibili. B11 aggiunge
l'overlay safe-area e la selezione con mouse, tastiera, controller e touch.
B12 applica velocità, frequenza, danno e raggio pickup con stacking
moltiplicativo, cap configurabili e reset completo senza mutare i Resource. Lo
stato dei gate è in
[`docs/b06a-verification.md`](docs/b06a-verification.md) e
[`docs/b12-verification.md`](docs/b12-verification.md).

## Avvio rapido

Da PowerShell, nella root del repository:

```powershell
.\tools\verify-toolchain.ps1 -RunProjectSmoke
godot_console --headless --path . --script tests/integration/_enemy_spawner_smoke.gd
godot_console --headless --path . --script tests/integration/_combat_slice_smoke.gd
godot_console --headless --path . --script tests/integration/_player_survival_smoke.gd
godot_console --headless --path . --script tests/integration/_experience_pickup_smoke.gd
godot_console --headless --path . --script tests/integration/_level_progression_smoke.gd
godot_console --headless --path . --script tests/integration/_hud_smoke.gd
godot_console --headless --path . --script tests/integration/_active_ability_smoke.gd
godot_console --headless --path . --script tests/integration/_upgrade_service_smoke.gd
godot_console --headless --path . --resolution 1280x720 --script tests/integration/_upgrade_overlay_smoke.gd
godot_console --headless --path . --resolution 1280x720 --script tests/integration/_upgrade_effects_smoke.gd
godot_console --headless --path . --script tests/integration/_platform_lifecycle_smoke.gd
godot --editor --path .
```

I comandi di export, i prerequisiti Android e le regole sulla firma sono in
[`docs/setup.md`](docs/setup.md). Il lavoro è ordinato in
[`docs/development-plan.md`](docs/development-plan.md) e le assunzioni sono
registrate in [`docs/decision-log.md`](docs/decision-log.md).
