# Verifica B06A — Android Back, focus e lifecycle

Data: 17 agosto 2026  
Engine: Godot 4.7.1  
Stato: implementazione e gate Windows/Pixel 9 completati; profili Android 12 e
Android 16 esatti ancora aperti

## Risultato

Il vertical slice corrente completa il contratto lifecycle B06A:

- `PlatformLifecycle` è scene-local e always-process; traduce `pause_game`,
  Android Back, focus loss e app pause in richieste a `RunController`;
- Escape e Start del controller condividono l'azione `pause_game`; il pulsante
  `PAUSA` nel lato destro del HUD copre il percorso touch e resta dentro
  `SafeAreaRoot`, separato dal joystick;
- Back durante `RUNNING` apre `MANUAL_PAUSE`; Back nell'overlay agisce come
  cancel esplicito e riprende soltanto se applicazione e focus sono validi;
- Home, lock/app pause e focus loss sospendono input e run; le notifiche di
  resume/focus-in non modificano lo stato della run;
- `PauseOverlay` continua a ricevere input con il `SceneTree` in pausa e richiede
  una scelta esplicita su `RIPRENDI`;
- tutti i touch vengono rilasciati alla sospensione; tastiera e stick mantenuti
  richiedono un ritorno al neutro prima di poter muovere di nuovo il Player;
- Back non sostituisce `LEVEL_UP`, terminali o altri modali con una pausa
  manuale, predisponendo la priorità degli overlay successivi;
- `application/config/quit_on_go_back=false` impedisce a Back di terminare
  direttamente l'app durante una run.

## Test automatici

Comandi eseguiti con Godot `4.7.1.stable.official.a13da4feb`:

```powershell
godot_console --headless --path . `
  --script tests/integration/_input_subsystem_smoke.gd

godot_console --headless --path . --resolution 1280x720 `
  --script tests/integration/_movement_slice_smoke.gd

godot_console --headless --path . --resolution 1280x720 `
  --script tests/integration/_platform_lifecycle_smoke.gd

.\tools\verify-toolchain.ps1 -RunProjectSmoke
```

Esito dedicato e contratto della scena:

```text
INPUT_SUBSYSTEM_SMOKE_OK
B03_MOVEMENT_SLICE_SMOKE_OK
B06A_PLATFORM_LIFECYCLE_SMOKE_OK
B06A_CONTRACT_OK
```

È stata eseguita anche l'intera suite B03–B09: nove smoke test verdi. La suite
B06A copre Escape/Start, pulsanti touch, Back, app pause/resume, focus loss/in,
clock fermo, rifiuto del resume mentre l'app è sospesa, touch cancellato,
neutral-to-rearm, priorità di `LEVEL_UP` e tre cicli pausa/ripresa consecutivi
senza callback duplicate.

## Build e runtime Windows

La build debug Windows x64 è stata rigenerata. Lo smoke dell'eseguibile esportato
ha terminato con codice `0` su Compatibility/OpenGL 3.3 e NVIDIA GeForce RTX
3060, stampando `B06A_CONTRACT_OK` senza errori di script o runtime.

| File | Byte | SHA-256 |
|---|---:|---|
| `FriendshipSurvival.console.exe` | 101.376 | `6948E3214518231D0E009A43D013014A17D214E1EB5807E5AC309617860E07EA` |
| `FriendshipSurvival.exe` | 103.033.344 | `47A4D4E119346D53E6A435986935BAC1C68E08DFEADF531F1422707F75061BCA` |
| `FriendshipSurvival.pck` | 350.028 | `3EC4795A581379FD268B0F1244BFD7F285040A3F88091DC4E7366E53D4CAC9CA` |

## Build e installazione Android

L'export debug ha terminato regolarmente ed è stato installato con
`adb install -r` sul Pixel 9 collegato.

| Campo | Valore verificato |
|---|---|
| APK | 84.219.108 byte |
| SHA-256 | `C66FB2E3E906C3BB693450D6A239840DF4CA0C5F3BCA8F93C52DB4D793C6DAE8` |
| Package | `com.ilgioco.friendshipsurvival`, versione `0.1.0` (`versionCode=1`) |
| SDK | minimo 31, target 36, compile 36 |
| ABI | solo `arm64-v8a` |
| Firma debug | APK Signature Scheme v2 valida |
| Certificato debug SHA-256 | `932BAB834EBA16A12DA88A8ACF3E40B207A946E0000641F25FD15CBE4FE7FFD3` |
| Device | Pixel 9, Android 17/API 37, ARM64 |

Il processo Android carica correttamente `libgodot_android.so` ARM64 e stampa
`SMOKE_OK`, `B06A_CONTRACT_OK` e `B09_READY` con viewport `1616×720`, finestra
`2424×1080` e cutout fisico sinistro di 173 px.

Il gate runtime reale sul Pixel 9 ha verificato:

- Back apre `IN PAUSA` senza chiudere l'Activity; un secondo Back riprende la
  stessa run e il PID resta invariato;
- il tap su `PAUSA` e il tap su `RIPRENDI` percorrono lo stesso contratto;
- Home durante uno swipe del joystick di 1,2 s conserva il processo; al ritorno
  il timer resta a `00:01`, l'overlay è visibile e il joystick è centrato;
- dopo `RIPRENDI`, un nuovo swipe viene accettato e sposta il Player, senza
  riutilizzare il touch precedente;
- lock/unlock conserva il PID e torna su `IN PAUSA`; il timer resta a `00:28` e
  avanza a `00:29` soltanto dopo la conferma;
- `LEVEL_UP` conserva la propria priorità: il timer si ferma e `PAUSA` resta
  disabilitato, senza sovrapporre il nuovo overlay;
- Game Over seguito da tap su `RIPROVA` mantiene il processo e ripristina
  `100/100` HP, livello 1, `0/10 XP` e timer `00:01`;
- i log del processo non contengono `SCRIPT ERROR`, `FATAL EXCEPTION` o errori
  Godot.

## Gate ancora aperti

- stessi casi durante `LEVEL_UP`, quando l'overlay sarà disponibile in B11;
- prova sul profilo minimo Android 12/API 31;
- prova sul profilo target esatto Android 16/API 36;
- controller USB/Bluetooth reale su Windows.

Gli artefatti generati restano nelle directory ignorate `exports/` e
`android/build/` e non devono essere committati.
