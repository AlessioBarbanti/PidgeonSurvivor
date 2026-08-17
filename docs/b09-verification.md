# Verifica B09 — HUD responsive, safe area, vita, XP e timer

Data: 17 agosto 2026  
Engine: Godot 4.7.1  
Stato: implementazione e gate Windows completati; APK ARM64 validato staticamente, gate runtime Android aperto

## Risultato

Il vertical slice B09 sostituisce il pannello diagnostico con un HUD in-game
riutilizzabile e passivo rispetto al gameplay:

- `GameHud` osserva `RunController`, `HealthComponent` ed `ExperienceSystem`
  attraverso i loro segnali, senza modificare stato o statistiche;
- la barra vita in alto a sinistra mostra valore corrente e massimo e reagisce
  nello stesso evento di danno/reset;
- la barra XP occupa tutta la larghezza utile superiore, mostra livello,
  progresso e soglia corrente e adotta subito la nuova soglia al level-up;
- il timer centrale usa esclusivamente `RunController.run_time_changed`, è
  formattato `MM:SS` e non possiede un clock locale;
- pausa manuale, `LEVEL_UP`, `DEFEAT` e gli altri stati diversi da `RUNNING`
  non avanzano il timer; il restart riporta timer, vita, livello e XP ai
  valori iniziali;
- `HUD` riempie `SafeAreaRoot`; `MarginContainer`, `VBoxContainer`,
  `HBoxContainer` e slot laterali simmetrici mantengono la barra XP nella
  larghezza sicura, la vita a sinistra e il timer al centro;
- il vecchio pannello debug e il suggerimento con offset fissi sono stati
  rimossi dalla scena principale.

Il framework e l'indicatore dell'abilità attiva, originariamente esclusi da
questo gate, sono stati completati nel successivo
[`B09A`](./b09a-verification.md).

## Profili layout verificati

Lo smoke dedicato usa safe rect deterministici e controlla contenimento,
larghezza utile, centratura e assenza di sovrapposizioni:

| Profilo | Safe rect simulato | Esito |
|---|---:|---|
| 16:9 | `1240×680` a `(20, 20)` | Barra XP full-width, vita e timer contenuti |
| 20:9 con cutout | `1472×680` a `(64, 20)` | Offset del cutout rispettato, timer centrato |
| 4:3 | `920×680` a `(20, 20)` | Vita leggibile a 240 px, nessuna sovrapposizione |

I margini interni del HUD sono 18 px orizzontali e 14 px verticali, applicati
dopo la safe area calcolata da `ArenaLayout`.

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

godot_console --headless --path . --resolution 1280x720 `
  --script tests/integration/_hud_smoke.gd

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
B09_HUD_SMOKE_OK
SMOKE_OK version=4.7.1 renderer=gl_compatibility os=Windows
B03_CONTRACT_OK
B04_CONTRACT_OK
B05_CONTRACT_OK
B06_CONTRACT_OK
B07_CONTRACT_OK
B08_CONTRACT_OK
B09_CONTRACT_OK
```

La suite B09 copre valori iniziali; aggiornamento signal-driven di vita, XP,
livello e soglia; formattazione del timer; stop e ripresa in pausa e level-up;
stop terminale; reset; valori non finiti; composizione della scena principale;
safe area e layout sui tre aspect ratio richiesti.

## Build e runtime Windows

La build debug Windows x64 è stata rigenerata. Lo smoke dell'eseguibile
esportato ha terminato con codice `0`; un runtime reale di 240 frame a
`1280×720`, seed `1`, ha usato Compatibility/OpenGL 3.3 su NVIDIA GeForce RTX
3060 e ha terminato con codice `0`, senza errori di script o runtime.

| File | Byte | SHA-256 |
|---|---:|---|
| `FriendshipSurvival.console.exe` | 101.376 | `6948E3214518231D0E009A43D013014A17D214E1EB5807E5AC309617860E07EA` |
| `FriendshipSurvival.exe` | 103.033.344 | `47A4D4E119346D53E6A435986935BAC1C68E08DFEADF531F1422707F75061BCA` |
| `FriendshipSurvival.pck` | 252.084 | `9A4B11FC5F0E7AF23F7043FE2AD7D3D5DBCA9EBD7CB048E258EB2B56F596F0DC` |

## Build Android

L'export Godot ha generato correttamente l'APK debug. Il controllo statico
conferma:

| Campo | Valore verificato |
|---|---|
| APK | 84.126.814 byte; SHA-256 `2A1DD27DD5FCFE29EADFCC0F81478569480DB6D588B98CA04FEED39CEDE1B5EC` |
| Package | `com.ilgioco.friendshipsurvival`, versione `0.1.0` (`versionCode=1`) |
| SDK | minimo 31, target 36, compile 36 |
| ABI | solo `arm64-v8a` |
| Firma debug | APK Signature Scheme v2 valida |
| Certificato debug SHA-256 | `932BAB834EBA16A12DA88A8ACF3E40B207A946E0000641F25FD15CBE4FE7FFD3` |

Il 17 agosto 2026 l'APK aggiornato è stato installato sul Pixel 9 Android 17/API
37 durante il gate B06A. Il runtime ha confermato safe area 20:9 con cutout,
aggiornamenti di vita/XP/livello, timer fermo in pausa e `LEVEL_UP`, Game Over e
restart touch; i dettagli sono in [`b06a-verification.md`](./b06a-verification.md).

## Gate ancora aperti

- prova sul profilo minimo Android 12/API 31;
- prova sul profilo target esatto Android 16/API 36 e su tablet/emulazione 4:3;
- controller USB/Bluetooth reale su Windows;
- profili Android 12/API 31 e Android 16/API 36 esatti e controller fisico;
  il gate B09A su Pixel 9/Android 17 è documentato in
  [`b09a-verification.md`](./b09a-verification.md).

Gli artefatti generati restano nelle directory ignorate `exports/` e
`android/build/` e non devono essere committati.
