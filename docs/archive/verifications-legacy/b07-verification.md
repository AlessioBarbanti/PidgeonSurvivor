# Verifica B07 — drop, magnete e raccolta XP

Data: 17 agosto 2026  
Engine: Godot 4.7.1  
Stato: implementazione e gate Windows completati; APK ARM64 validato staticamente, gate runtime Android aperto

## Risultato

Il vertical slice B07 estende la scena principale con il primo tratto della
progressione:

- ogni `BaseEnemy` espone un valore XP configurabile e il suo segnale atomico
  `died` può generare al massimo un drop;
- despawn, cleanup tecnico e segnali di morte duplicati non generano ricompense;
- `ExperienceDropper` osserva soltanto i nemici registrati dallo spawner,
  istanzia il pickup nella posizione di morte e mantiene un registro locale;
- `ExperiencePickup` resta fermo fuori raggio, viene attirato entro il
  `pickup_radius` del Player e accredita una sola volta quando raggiunge il
  raggio di raccolta;
- magnete e raccolta avanzano solo in `RUNNING`; pausa, vittoria e sconfitta
  bloccano la progressione;
- `ExperienceSystem` è l'unica autorità sull'accredito XP e fornisce il punto
  di estensione per soglie, overflow e coda previsti in B08;
- il restart azzera XP, registro dei nemici già ricompensati e tutti i pickup
  ancora a terra entro la fine del frame;
- il debug HUD mostra XP correnti e numero di drop attivi.

Baseline dati B07:

| Parametro | Valore |
|---|---:|
| Ricompensa BaseEnemy | 1 XP |
| `pickup_radius` Player | 160 px |
| Velocità magnete | 460 px/s |
| Raggio di raccolta | 18 px |

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
SMOKE_OK version=4.7.1 renderer=gl_compatibility os=Windows
B03_CONTRACT_OK
B04_CONTRACT_OK
B05_CONTRACT_OK
B06_CONTRACT_OK
B07_CONTRACT_OK
```

La suite B07 copre gate di accredito in `BOOT`, pausa e terminale; movimento del
magnete dentro e fuori raggio; raccolta singola prima del `queue_free`; una sola
ricompensa per morte anche con segnale duplicato; nessuna ricompensa per
despawn; valore XP del nemico; posizione del drop; reset di XP e pickup al
restart.

## Build e runtime Windows

La build debug Windows x64 è stata rigenerata. Lo smoke dell'eseguibile
esportato ha terminato con codice `0`; un runtime reale di 240 frame a
`1280×720`, seed `1`, ha usato Compatibility/OpenGL 3.3 su NVIDIA GeForce RTX
3060 e ha terminato con codice `0`, senza errori di script o runtime.

| File | Byte | SHA-256 |
|---|---:|---|
| `FriendshipSurvival.console.exe` | 101.376 | `6948E3214518231D0E009A43D013014A17D214E1EB5807E5AC309617860E07EA` |
| `FriendshipSurvival.exe` | 103.033.344 | `47A4D4E119346D53E6A435986935BAC1C68E08DFEADF531F1422707F75061BCA` |
| `FriendshipSurvival.pck` | 223.900 | `ACF88DE341ADB3E6B083A41DEF7C64F8073D6FAA8B9A51D09497E0644FCA2D4E` |

## Build Android

L'APK debug è stato rigenerato e verificato staticamente. Il wrapper di export
Godot ha prodotto, copiato e firmato l'artefatto, ma è rimasto inattivo fino al
timeout host di 244 secondi, confermando l'anomalia già osservata in B06. La
build diretta eseguita dalla directory `android/build/` con
`gradlew.bat --no-daemon assembleDebug --console=plain` è terminata
correttamente in 35 secondi.

| Campo | Valore verificato |
|---|---|
| APK | 84.100.271 byte |
| SHA-256 | `FBD33C318588DEBFA945DFAB5B9383A15B1484413651D28C3D161C0D8F64B4F9` |
| Package | `com.ilgioco.friendshipsurvival`, versione `0.1.0` (`versionCode=1`) |
| SDK | minimo 31, target 36, compile 36 |
| ABI | solo `arm64-v8a` |
| Firma debug | APK Signature Scheme v2 valida |
| Certificato debug SHA-256 | `932BAB834EBA16A12DA88A8ACF3E40B207A946E0000641F25FD15CBE4FE7FFD3` |

`adb devices -l` non rileva alcun device. Non è quindi stato possibile eseguire
il gate runtime B07 su Android.

## Gate ancora aperti

- installazione e runtime B05–B07 su device Android ARM64, verificando kill,
  drop, magnete, accredito singolo e cleanup al restart tramite touch;
- prova sul profilo minimo Android 12/API 31;
- controller USB/Bluetooth reale su Windows;
- indagine sul mancato ritorno del wrapper Godot dopo un export Android riuscito.

Gli artefatti generati restano nelle directory ignorate `exports/` e
`android/build/` e non devono essere committati.
