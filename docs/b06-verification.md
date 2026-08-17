# Verifica B06 — salute Player, contatto, Game Over e restart

Data: 16 agosto 2026  
Engine: Godot 4.7.1  
Stato: implementazione e gate Windows completati; APK ARM64 validato, gate runtime Android aperto

## Risultato

Il vertical slice B06 è la scena principale del progetto. Include:

- `HealthComponent` esteso con finestra di invulnerabilità configurabile, clamp
  `0..health_max`, scadenza priva di residui floating point e reset atomico;
- Player con 100 HP base, segnali tipizzati, feedback di danno, arco vita e reset
  della vita massima base a ogni nuova run;
- `ContactDamage` come `Area2D` del nemico, sul layer dedicato `Player Body`, con
  20 danni e gate esplicito su `RUNNING`;
- overlap persistente e più nemici nello stesso frame protetti dalla stessa
  invulnerabilità di 0,75 s;
- morte Player tradotta in `DEFEAT` dal vertical slice, con blocco atomico di
  clock, input, danni, spawn, inseguimento e proiettili;
- `EndScreen` always-process con riepilogo `MM:SS` e pulsante `RIPROVA`, usabile
  tramite focus/`ui_accept`, mouse o tap anche mentre il `SceneTree` è in pausa;
- restart in-place consentito solo da un terminale, con nuovo seed e reset di
  Player, input, posizione, salute, i-frame, spawner, targeting, cooldown, nemici
  e proiettili.

Baseline dati B06:

| Parametro | Valore |
|---|---:|
| Vita Player | 100 HP |
| Danno contatto BaseEnemy | 20 |
| Invulnerabilità post-hit | 0,75 s di gameplay |
| Hit effettive per la sconfitta | 5 |

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

godot_console --headless --path . `
  --script tests/integration/_player_survival_smoke.gd

.\tools\verify-toolchain.ps1 -RunProjectSmoke
```

Esito:

```text
INPUT_SUBSYSTEM_SMOKE_OK
B03_MOVEMENT_SLICE_SMOKE_OK
B04_ENEMY_SPAWNER_SMOKE_OK
B05_COMBAT_SLICE_SMOKE_OK
B06_PLAYER_SURVIVAL_SMOKE_OK
SMOKE_OK version=4.7.1 renderer=gl_compatibility os=Windows
B03_CONTRACT_OK
B04_CONTRACT_OK
B05_CONTRACT_OK
B06_CONTRACT_OK
```

La suite B06 copre i-frame e scadenza numerica, danno bloccato in `BOOT`, pausa
e terminale, tempo di invulnerabilità fermo fuori da `RUNNING`, clamp letale,
reset di vita massima e HP, overlap fisico sui layer reali, transizione
`died → DEFEAT`, overlay interattivo, cleanup di nemici e proiettili e cinque
restart rapidi consecutivi senza eventi terminali doppi, nodi o timer residui.

## Build e runtime Windows

La build debug Windows x64 è stata rigenerata. Lo smoke dell'eseguibile esportato
ha terminato con codice `0`; un runtime reale di 240 frame a `1280×720`, seed `1`,
ha usato Compatibility/OpenGL 3.3 su NVIDIA GeForce RTX 3060 e ha terminato con
codice `0`, senza errori di script o runtime.

| File | Byte | SHA-256 |
|---|---:|---|
| `FriendshipSurvival.console.exe` | 101.376 | `6948E3214518231D0E009A43D013014A17D214E1EB5807E5AC309617860E07EA` |
| `FriendshipSurvival.exe` | 103.033.344 | `47A4D4E119346D53E6A435986935BAC1C68E08DFEADF531F1422707F75061BCA` |
| `FriendshipSurvival.pck` | 199.504 | `BF8C2C3E251A01EFB7B21FD9FAF670EB284B22F6A1E44BC3A090A8E27FA91E0F` |

## Build Android

L'APK debug è stato rigenerato due volte con output byte-identico e verificato
staticamente. Anche `gradlew.bat --no-daemon assembleDebug --console=plain` ha
terminato con codice `0`.

| Campo | Valore verificato |
|---|---|
| APK | 84.076.091 byte |
| SHA-256 | `D21885B8DD835170284E882F0C90F4A7CF0A516CFA9C2F9852E227FBD12582CA` |
| Package | `com.ilgioco.friendshipsurvival`, versione `0.1.0` (`versionCode=1`) |
| SDK | minimo 31, target 36, compile 36 |
| ABI | solo `arm64-v8a` |
| Firma debug | APK Signature Scheme v2 valida |
| Certificato debug SHA-256 | `932BAB834EBA16A12DA88A8ACF3E40B207A946E0000641F25FD15CBE4FE7FFD3` |

Osservazione host: in entrambe le invocazioni Godot ha completato Gradle, copiato
e firmato l'APK, ma il processo CLI è rimasto inattivo invece di terminare. È
stato chiuso soltanto dopo aver verificato timestamp, dimensione e hash stabile;
la build Gradle diretta ha poi confermato un'uscita pulita. L'anomalia del wrapper
di export va ricontrollata nel prossimo gate Android, ma non ha corrotto l'APK.

`adb devices -l` non rileva al momento alcun device. Non è quindi stato possibile
eseguire il runtime B06 su Android.

## Gate ancora aperti

- installazione e runtime B05–B06 su device Android ARM64, con touch e fuoco
  automatico durante i contatti, i-frame leggibile, Game Over e tap su `RIPROVA`;
- prova sul profilo minimo Android 12/API 31;
- controller USB/Bluetooth reale su Windows;
- ricontrollo dell'uscita del comando Godot dopo l'export Android.

Gli artefatti generati restano nelle directory ignorate `exports/` e
`android/build/` e non devono essere committati.
