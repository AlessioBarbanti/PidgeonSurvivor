# Verifica B08 — livelli, soglie, overflow e coda

Data: 17 agosto 2026  
Engine: Godot 4.7.1  
Stato: implementazione e gate Windows completati; APK ARM64 validato staticamente, gate runtime Android aperto

## Risultato

Il vertical slice B08 completa il tratto di progressione fra raccolta XP e
future carte upgrade:

- `ExperienceCurve` è un `Resource` dati con soglia iniziale e crescita lineare
  configurabili;
- `ExperienceSystem` conserva separatamente XP totali, XP nella soglia
  corrente, livello e soglia successiva;
- un accredito può attraversare più soglie in una sola chiamata e conserva
  integralmente l'overflow;
- ogni livello guadagnato aggiunge il relativo livello a una coda FIFO ed
  emette un evento `level_up_started` dedicato;
- `RunController` entra in `LEVEL_UP` e mantiene il `SceneTree` in pausa fino
  al completamento dell'ultima scelta, senza un frame `RUNNING` intermedio;
- `DEFEAT` e `VICTORY` mantengono la priorità su `LEVEL_UP`; una scelta
  interrotta non viene consumata;
- il restart azzera livello, XP correnti e totali, overflow, scelta attiva e
  coda;
- il debug HUD mostra livello, progresso nella soglia, XP totali e numero di
  level-up pendenti.

La generazione delle tre carte per ciascun `level_up_started` appartiene a B10;
B08 ne stabilisce il contratto uno-a-uno e il ciclo di completamento usato dal
futuro `UpgradeService`/overlay.

Baseline dati B08:

| Parametro | Valore |
|---|---:|
| Livello iniziale | 1 |
| Prima soglia | 10 XP |
| Crescita per livello | +5 XP |
| Prime soglie | 10, 15, 20, 25 XP |

## Test automatici

Comandi eseguiti con Godot `4.7.1.stable.official.a13da4feb`:

```powershell
godot_console --headless --path . --resolution 1280x720 `
  --script tests/integration/_input_subsystem_smoke.gd

godot_console --headless --path . --resolution 1280x720 `
  --script tests/integration/_movement_slice_smoke.gd

godot_console --headless --path . --resolution 1280x720 `
  --script tests/integration/_enemy_spawner_smoke.gd

godot_console --headless --path . --resolution 1280x720 `
  --script tests/integration/_combat_slice_smoke.gd

godot_console --headless --path . --resolution 1280x720 `
  --script tests/integration/_player_survival_smoke.gd

godot_console --headless --path . --resolution 1280x720 `
  --script tests/integration/_experience_pickup_smoke.gd

godot_console --headless --path . --resolution 1280x720 `
  --script tests/integration/_level_progression_smoke.gd

.\tools\verify-toolchain.ps1 -RunProjectSmoke
```

Esito:

```text
INPUT_SUBSYSTEM_SMOKE_OK
B03_MOVEMENT_SLICE_SMOKE_OK
B04_ENEMY_SPAWNER_SMOKE_OK
B05_COMBAT_SLICE_SMOKE_OK
B06_PLAYER_SURVIVAL_SMOKE_OK
B07_EXPERIENCE_PICKUP_SMOKE_OK
B08_LEVEL_PROGRESSION_SMOKE_OK
SMOKE_OK version=4.7.1 renderer=gl_compatibility os=Windows
B03_CONTRACT_OK
B04_CONTRACT_OK
B05_CONTRACT_OK
B06_CONTRACT_OK
B07_CONTRACT_OK
B08_CONTRACT_OK
```

La suite B08 copre formula e difese della curva; soglia esatta; overflow
singolo e multiplo; equivalenza fra XP totali e soglie consumate più residuo;
ordine delle scelte; pausa continua fra due scelte; blocco di nuovi accrediti
in `LEVEL_UP`; priorità terminale; reset completo; configurazione e flusso
della scena composta.

## Build e runtime Windows

La build debug Windows x64 è stata rigenerata. Lo smoke dell'eseguibile
esportato ha terminato con codice `0`; un runtime reale di 240 frame a
`1280×720`, seed `1`, ha usato Compatibility/OpenGL 3.3 su NVIDIA GeForce RTX
3060 e ha terminato con codice `0`, senza errori di script o runtime.

| File | Byte | SHA-256 |
|---|---:|---|
| `FriendshipSurvival.console.exe` | 101.376 | `6948E3214518231D0E009A43D013014A17D214E1EB5807E5AC309617860E07EA` |
| `FriendshipSurvival.exe` | 103.033.344 | `47A4D4E119346D53E6A435986935BAC1C68E08DFEADF531F1422707F75061BCA` |
| `FriendshipSurvival.pck` | 235.884 | `AE2B4638BCB4B2C9773E288BB152A880BB87392A8C1F15E165B808E71B4CE242` |

## Build Android

L'export Godot ha generato correttamente l'APK debug in 21 secondi. Il
controllo statico conferma:

| Campo | Valore verificato |
|---|---|
| APK | 84.112.409 byte; SHA-256 `2F6146D17C282F8E7F274EB247366EE0A235725064692AA7CCEDE3DA7F4B742F` |
| Package | `com.ilgioco.friendshipsurvival`, versione `0.1.0` (`versionCode=1`) |
| SDK | minimo 31, target 36, compile 36 |
| ABI | solo `arm64-v8a` |
| Firma debug | APK Signature Scheme v2 valida |
| Certificato debug SHA-256 | `932BAB834EBA16A12DA88A8ACF3E40B207A946E0000641F25FD15CBE4FE7FFD3` |

`adb devices -l` non rileva alcun device. Non è quindi stato possibile eseguire
il gate runtime B08 su Android.

## Gate ancora aperti

- installazione e runtime B05–B08 su device Android ARM64, verificando in
  particolare `kill → pickup → level-up`, pausa e più scelte consecutive;
- prova sul profilo minimo Android 12/API 31;
- controller USB/Bluetooth reale su Windows.

Gli artefatti generati restano nelle directory ignorate `exports/` e
`android/build/` e non devono essere committati.
