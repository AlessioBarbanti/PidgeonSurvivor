# Verifica B05 — targeting, arma, proiettile e danno

Data: 12 agosto 2026  
Engine: Godot 4.7.1  
Stato: implementazione e gate Windows completati; APK ARM64 validato, gate runtime Android aperto

## Risultato

Il vertical slice B05 è la scena principale del progetto. Include:

- `TargetingSystem` con registro alimentato da `EnemySpawner`, selezione del vivo
  più vicino tramite distanza al quadrato ed esclusione sincrona dei morti;
- `WeaponController` configurato da `WeaponProfile`, cooldown attivo soltanto in
  `RUNNING`, nessun consumo del cooldown senza target e massimo un colpo per tick;
- proiettile `Area2D` con direzione, danno, velocità, lifetime e raggio fotografati
  al momento del tiro;
- `HealthComponent` con clamp, cambio di vita massima atomico, protezione dalla
  rientranza e un solo segnale di morte;
- Hurtbox del nemico separata dal `CharacterBody2D`, così le collisioni di
  combattimento non modificano l'inseguimento B04;
- latch del proiettile impostato prima del danno e gate sullo stato della run:
  callback duplicate, pausa e terminali non applicano una seconda hit;
- feedback procedurale: canna orientata, proiettile con trail, flash del nemico e
  barra HP visibile dopo il primo danno;
- cleanup di target e proiettili al restart, più nuovo spawn e nuovo target su una seconda run.

Baseline dati B05:

| Parametro | Valore |
|---|---:|
| Frequenza | 4 colpi/s |
| Danno | 10 |
| Velocità proiettile | 900 px/s |
| Lifetime | 2 s |
| Raggio proiettile | 6 px |
| Offset volata | 32 px |
| Vita BaseEnemy | 40 HP |

I 40 HP permettono al primo nemico di entrare completamente nel playfield prima
della hit letale, rendendo leggibili i flash, gli stati visibili della barra
`30 → 20 → 10` e la morte senza cambiare il contratto del bersaglio vivo più vicino.

## Test automatici

Comandi eseguiti con Godot `4.7.1.stable.official.a13da4feb`:

```powershell
godot_console --headless --path . `
  --script tests/integration/_input_subsystem_smoke.gd

godot_console --headless --path . --resolution 1280x720 `
  --script tests/integration/_movement_slice_smoke.gd

godot_console --headless --path . `
  --script tests/integration/_enemy_spawner_smoke.gd

godot_console --headless --path . `
  --script tests/integration/_combat_slice_smoke.gd

.\tools\verify-toolchain.ps1 -RunProjectSmoke
```

Esito:

```text
INPUT_SUBSYSTEM_SMOKE_OK
B03_MOVEMENT_SLICE_SMOKE_OK
B04_ENEMY_SPAWNER_SMOKE_OK
B05_COMBAT_SLICE_SMOKE_OK
SMOKE_OK version=4.7.1 renderer=gl_compatibility os=Windows
B03_CONTRACT_OK
B04_CONTRACT_OK
B05_CONTRACT_OK
```

La suite B05 copre profilo dati e clamp, salute atomica e callback rientrante,
targeting 2D non collineare, pareggio stabile, morto escluso nello stesso frame,
rebind del registro, zero colpi senza target, mira diagonale e volata, cadenza,
snapshot dei parametri, movimento e lifetime, freeze in pausa, danno bloccato in
`BOOT`/pausa/terminale, hit monouso, collisione fisica in movimento, catena
`spawn → fire → lethal hit → died → registri puliti` e seconda run senza residui.

## Build e runtime Windows

La build debug Windows x64 è stata rigenerata. Lo smoke dell'eseguibile esportato
ha terminato con codice `0`; un runtime reale di 240 frame a `1280×720`, seed `1`,
ha usato Compatibility/OpenGL 3.3 su NVIDIA GeForce RTX 3060 e ha terminato con
codice `0`, senza errori di script o runtime.

| File | Byte | SHA-256 |
|---|---:|---|
| `FriendshipSurvival.console.exe` | 101.376 | `6948E3214518231D0E009A43D013014A17D214E1EB5807E5AC309617860E07EA` |
| `FriendshipSurvival.exe` | 103.033.344 | `47A4D4E119346D53E6A435986935BAC1C68E08DFEADF531F1422707F75061BCA` |
| `FriendshipSurvival.pck` | 172.128 | `B10F702EE30BAA94E847ABF3F0FC3E621694DEB3CAF141158916AD9D5D2C79C0` |

Il controllo visivo a seed `1` ha confermato canna e proiettili leggibili, i tre
stati danneggiati della barra, flash netto sulla terza hit e morte alla quarta
quando il nemico è già interamente visibile.

## Build Android

L'APK debug è stato rigenerato e verificato staticamente:

| Campo | Valore verificato |
|---|---|
| APK | 84.050.521 byte |
| SHA-256 | `AEAD846EE94E06569FA4CF66478689542C2CBDF8DB33AB93382A1AA3AA837352` |
| Package | `com.ilgioco.friendshipsurvival`, versione `0.1.0` (`versionCode=1`) |
| SDK | minimo 31, target 36, compile 36 |
| ABI | solo `arm64-v8a` |
| Firma debug | APK Signature Scheme v2 valida |
| Certificato debug SHA-256 | `932BAB834EBA16A12DA88A8ACF3E40B207A946E0000641F25FD15CBE4FE7FFD3` |
| Permessi custom | nessuno |

Non era presente un device in `adb`. L'AVD `Medium_Phone_API_36.1` disponibile è
`x86_64` e non si avvia perché sull'host manca il driver di accelerazione Android;
l'emulatore termina con `x86_64 emulation currently requires hardware acceleration`.
Il preset ARM64 non è stato alterato per aggirare il gate.

## Gate ancora aperti

- installazione e runtime B05 su device Android ARM64, con touch e fuoco automatico
  simultanei, feedback hit leggibile e log privo di errori;
- prova sul profilo minimo Android 12/API 31;
- controller USB/Bluetooth reale su Windows;
- soak e profiling della densità di proiettili, pianificati in B19.

Gli artefatti e le catture diagnostiche sono locali in directory ignorate e
restano esclusi dal repository.
