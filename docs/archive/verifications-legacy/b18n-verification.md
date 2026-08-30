# B18N — Cambia personaggio dal menu pausa

Data verifica: 24 agosto 2026  
Godot: `4.7.1.stable.official.a13da4feb`

## Contratto implementato

- `CAMBIA PERSONAGGIO` è disponibile soltanto in `MANUAL_PAUSE`, con target
  `64` unità logiche e navigazione focus collegata a `RIPRENDI`.
- L'azione apre una conferma modale con `ANNULLA` e `CONFERMA`, entrambe alte
  `64` unità. Annullare tramite pulsante o Back chiude soltanto la conferma e
  conserva la pausa; la run non riprende implicitamente.
- Confermare usa lo stesso `RunController.prepare_restart()` del cambio profilo
  terminale. Il relativo `restart_prepared` azzera in modo atomico clock, seed,
  input, nemici, Boss, proiettili, pickup XP, progressione, offerte, rank,
  cooldown, passive, status ed effetti/VFX prima di mostrare il selettore in
  `BOOT`.
- La nuova selezione equipaggia il profilo scelto e avvia una run pulita. Il
  cambio personaggio terminale B17A continua a usare lo stesso percorso.

## Verifica automatica

Smoke dedicato:

```powershell
godot_console --headless --path . --resolution 1280x720 `
  --script tests/integration/_pause_change_character_smoke.gd
```

Marker: `B18N_PAUSE_CHANGE_CHARACTER_SMOKE_OK`.

La fixture copre pausa → annulla → riprendi, conferma → Back, conferma →
selettore → nuova run con Bea e una run precedente popolata con nemico, Boss,
proiettile, pickup XP, rank, cooldown ed effetto attivo. Verifica inoltre
`BOOT`, seed/clock a zero, input sospeso e assenza di entità o stato residuo.

La regressione completa è `33/33`; le regressioni lifecycle, roster, run
completa, joystick e abilità sono incluse. Anche
`tools/verify-toolchain.ps1 -RunProjectSmoke` è verde. Exit code e log sono
privi di `SCRIPT ERROR`, `FATAL EXCEPTION`, `SMOKE_FAIL` e `CONTRACT_FAIL`.

## Windows x64

L'export debug `Windows Desktop` è riuscito. L'eseguibile è stato avviato
realmente a `1280×720` con renderer Compatibility/OpenGL 3.3 su NVIDIA GeForce
RTX 3060 e argomenti `--smoke-test --run-seed=18018`. Il log contiene
`SMOKE_OK`, `B18N_CONTRACT_OK` e `B17A_READY` e termina con exit code `0`.

## Android ARM64 e Pixel 9

L'export APK debug è riuscito. I controlli statici confermano:

- package `com.ilgioco.friendshipsurvival`, versione `0.1.0`/code `1`;
- `minSdk 31`, `targetSdk 36`, `compileSdk 36`;
- orientamento landscape e sola ABI `arm64-v8a`;
- firma APK Signature Scheme v2 valida.

L'APK è stato installato e avviato sul Pixel 9 fisico con Android 17/API 37,
risoluzione fisica `1080×2424` e viewport Godot landscape `1616×720`. Il cold
launch registra `SMOKE_OK`, `B18N_CONTRACT_OK` e `B17A_READY`.

Il percorso è stato esercitato sul dispositivo con tap iniettati via ADB:

1. selezione Magno e avvio della prima run;
2. pausa → cambia personaggio → Back, verificando il ritorno alla pausa senza
   resume;
3. riapertura → conferma → selettore → scelta Bea → nuova run con HUD, ritratto
   e abilità di Bea;
4. nuovo ciclo pausa → conferma → `ANNULLA` → `RIPRENDI`;
5. Home e ritorno all'app, verificando che la run resti in pausa fino a
   `RIPRENDI`.

Le schermate a `20:9` mostrano pannelli dentro la safe area, focus visibile e
target touch leggibili. L'ultimo log scan non contiene `SCRIPT ERROR`,
`FATAL EXCEPTION`, `SMOKE_FAIL`, `CONTRACT_FAIL` o ANR. I tap sono stati
iniettati sul Pixel 9 reale, non eseguiti a mano; B18N non modifica il contratto
multitouch fisico già chiuso da B18L.

## Artefatti verificati

| Artefatto | Byte | SHA-256 |
|---|---:|---|
| `exports/windows/FriendshipSurvival.exe` | `103033344` | `47A4D4E119346D53E6A435986935BAC1C68E08DFEADF531F1422707F75061BCA` |
| `exports/windows/FriendshipSurvival.pck` | `1576404` | `CD0666424745D1508A68FF22235D6D8A60586C5BA1A5417C4412F4CC09113FD3` |
| `exports/android/friendship-survival-debug.apk` | `85389124` | `2172D3C2D3DC8DAE57D2BAA8A2A80E8451ADDBD158D8C17726134EE1127F9F88` |

Gli artefatti restano esclusi dal versionamento.
