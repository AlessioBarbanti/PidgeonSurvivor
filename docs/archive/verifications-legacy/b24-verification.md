# Verifica B24 — Scala visiva del Player

Data: 26 agosto 2026  
Stato: `IN VERIFICA`

## Contratto implementato

- `Player.visual_scale_multiplier` è configurabile nell'intervallo
  `1,00–2,00×`; la baseline candidata è `1,25×`.
- La scala base nearest-neighbor di `CharacterSprite` resta `1,65`; la scala
  effettiva neutra è quindi `2,0625`.
- Il moltiplicatore si applica soltanto allo sprite e si compone con lo squash di
  danno esistente.
- `CharacterBody2D`, collision shape/raggio `24`, layer `1`, mask `0`, velocità,
  pickup, clamp arena, raggi, `WeaponController`, origine proiettili e coordinate
  gameplay restano invariati.
- Tutti gli otto `FriendDefinition` ricevono la stessa scala in idle e camminata.

## Verifica automatica

Import/cache editor:

```powershell
godot_console --headless --editor --path . --quit
```

Esito: exit `0`, senza `SCRIPT ERROR`, `FATAL EXCEPTION`, `SMOKE_FAIL` o
`CONTRACT_FAIL`.

Focused e regressioni pertinenti:

```powershell
.\tools\run-milestone-checks.ps1 `
  -Milestone B24 `
  -RegressionSmoke tests/integration/_cast_sprites_smoke.gd,tests/integration/_player_direction_animation_smoke.gd,tests/integration/_arena_hud_minimal_smoke.gd,tests/integration/_player_survival_smoke.gd `
  -RunProjectSmoke
```

Esito: `PASS`; marker `B24_PLAYER_VISUAL_SCALE_SMOKE_OK`, più regressioni B18U,
B18C, B18Q e B06 e toolchain/project smoke verdi. Log:
`%LOCALAPPDATA%\Temp\il-gioco-verification\20260826-090146-B24`.

Regressione integrale:

```powershell
$focused = 'tests/integration/_player_visual_scale_smoke.gd'
$regressions = @(Get-ChildItem tests/integration -Filter '*_smoke.gd' -File |
  Where-Object Name -ne '_player_visual_scale_smoke.gd' |
  ForEach-Object { 'tests/integration/' + $_.Name })
.\tools\run-milestone-checks.ps1 -Milestone B24 `
  -FocusedSmoke $focused -RegressionSmoke $regressions
```

Esito: `PASS`, `44/44` smoke. Log:
`%LOCALAPPDATA%\Temp\il-gioco-verification\20260826-091521-B24`.

Lo smoke B24 copre:

- otto profili in idle e camminata;
- moltiplicatori `1,20`, `1,25` e `1,30×`;
- composizione con il feedback danno;
- hitbox, layer/mask e origine di fuoco invariati;
- clamp gameplay e visual bounds ai quattro bordi su `1280×720` (16:9),
  `1440×720` (18:9), `1600×720` (20:9) e `960×720` (4:3).

## Windows

```powershell
.\tools\run-milestone-checks.ps1 -Milestone B24 `
  -FocusedSmoke tests/integration/_player_visual_scale_smoke.gd `
  -ExportWindows
```

Esito: `PASS` per focused, export Windows e runtime con `SMOKE_OK`. Log:
`%LOCALAPPDATA%\Temp\il-gioco-verification\20260826-090829-B24`.

Il runtime automatico non congela il valore percettivo: resta richiesta una
prova umana Windows in movimento vicino ai bordi, con orde dense, Boss e VFX.

## Android

Build Gradle ripetibile, eseguita da `android/build/`:

```powershell
.\gradlew.bat --no-daemon assembleDebug --console=plain
```

Esito: `BUILD SUCCESSFUL in 45s`, `104 actionable tasks`.

Export Godot e ispezione:

```powershell
.\tools\run-milestone-checks.ps1 -Milestone B24 `
  -FocusedSmoke tests/integration/_player_visual_scale_smoke.gd `
  -ExportAndroid -ExportTimeoutSeconds 120
.\tools\inspect-android-artifact.ps1 `
  -ApkPath exports/android/pidgeon-survivor-debug.apk -AsJson
```

Esito runner: `PASS`; export `RECOVERED` perché la CLI Godot è scaduta dopo
aver scritto un APK nuovo, stabile e staticamente valido. Log:
`%LOCALAPPDATA%\Temp\il-gioco-verification\20260826-091006-B24`.

Artefatto:

- file: `exports/android/pidgeon-survivor-debug.apk` (generato, non versionato);
- dimensione: `96.117.625` byte;
- SHA-256: `11AE5B024B1317974A7B69A2A6A4EF2D6E868CE62521569FF12345E3A1F0E96C`;
- package/label: `com.ilgioco.pidgeonsurvivor` / `Pidgeon Survivor`;
- SDK: min `31`, target `36`;
- ABI: solo `arm64-v8a`;
- firma: APK Signature Scheme v2 presente;
- launcher: `com.godot.game.GodotAppLauncher`;
- orientamento landscape, activity ridimensionabile;
- ispezione statica: `android_static_valid=true`, nessun problema.

`adb` è stato avviato, ma non ha rilevato dispositivi:
`ANDROID_RUNTIME=OPEN_NO_DEVICE`. Installazione/avvio del nuovo APK e controllo
percettivo fisico Pixel 9 restano aperti.

## Gate residuo

B24 non passa a `COMPLETATO` finché un confronto umano Windows/Pixel 9 non
conferma o corregge il candidato `1,25×` osservando tutti gli otto Player durante
movimento, orde dense, Boss, VFX e vicinanza ai bordi a 16:9, 20:9 e 4:3. La
prova deve confermare leggibilità e assenza di clipping senza trasformare la
scala visuale in una modifica di hitbox o bilanciamento.
