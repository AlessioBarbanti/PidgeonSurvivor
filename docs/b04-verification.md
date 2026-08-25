# Verifica B04 — nemico base, ArenaLayout e spawner

Data: 12 agosto 2026  
Engine: Godot 4.7.1  
Stato: implementazione completata, gate Windows e Pixel 9 superato

## Risultato

Il vertical slice B04 è la scena principale del progetto. Include:

- `BaseEnemy` configurabile che insegue il Player soltanto durante `RUNNING`;
- `RunController` come autorità per stato, pausa, clock, seed e restart;
- profilo dati per intervallo, accelerazione, delay, cap, anello di spawn e despawn;
- spawn deterministico da seed fuori dal viewport e a distanza minima dal Player;
- fallback sull'angolo esterno più lontano, che garantisce la distanza minima
  quando è geometricamente realizzabile;
- cap di 80 nemici vivi, un solo spawn per tick e credito limitato mentre il cap
  è pieno;
- cleanup periodico oltre il despawn rect e registro svuotato immediatamente al
  restart, con liberazione dei nodi entro la fine del frame;
- HUD diagnostico responsive con tempo run e popolazione corrente.

## Test automatici

Comandi eseguiti con Godot `4.7.1.stable.official.a13da4feb`:

```powershell
godot_console --headless --path . `
  --script tests/integration/_input_subsystem_smoke.gd

godot_console --headless --path . --resolution 1280x720 `
  --script tests/integration/_movement_slice_smoke.gd

godot_console --headless --path . `
  --script tests/integration/_enemy_spawner_smoke.gd

.\tools\verify-toolchain.ps1 -RunProjectSmoke
```

Esito:

```text
INPUT_SUBSYSTEM_SMOKE_OK
B03_MOVEMENT_SLICE_SMOKE_OK
B04_ENEMY_SPAWNER_SMOKE_OK
SMOKE_OK version=4.7.1 renderer=gl_compatibility os=Windows
B03_CONTRACT_OK
B04_CONTRACT_OK
```

La suite B04 copre formula e clamp dell'intervallo, validazione del profilo,
seed riproducibile, anello di spawn su viewport traslate e ridimensionate,
distanza minima e fallback geometrico, inseguimento, collision shape per istanza,
cap, assenza di burst, despawn, stop e clock fuori da `RUNNING`, stati modali e
terminali, restart senza registro residuo e composizione della scena dopo resize.

## Build Windows

La build debug Windows x64 è stata rigenerata e avviata a `1280×720` tramite il
wrapper console. Ha terminato con codice `0` e ha stampato `SMOKE_OK`,
`B03_CONTRACT_OK`, `B04_CONTRACT_OK` e `B04_READY`.

| File | Byte | SHA-256 |
|---|---:|---|
| `FriendshipSurvival.exe` | 103.033.344 | `47A4D4E119346D53E6A435986935BAC1C68E08DFEADF531F1422707F75061BCA` |
| `FriendshipSurvival.pck` | 125.200 | `BB6963D096386DBD17AA0D235411320D635D47B26BA980C5D21243206C054ABB` |

## Build e smoke Android

L'APK debug finale è stato rigenerato, verificato, installato con `adb install -r`
e avviato a freddo sul Pixel 9 collegato.

| Campo | Valore verificato |
|---|---|
| APK | 84.004.185 byte |
| SHA-256 | `4A7804D06009DE6A4F6B064F278B01919C3186EAD79E5B7199A9CAA0224E1B70` |
| Package | `com.ilgioco.friendshipsurvival`, versione `0.1.0` (`versionCode=1`) |
| SDK | minimo 31, target 36, compile 36 |
| ABI | solo `arm64-v8a` |
| Firma debug | APK Signature Scheme v2 valida |
| Device | Pixel 9, Android 17/API 37, ARM64, 2424×1080 landscape |
| Cold start | 275 ms riportati da Activity Manager |

Marker runtime:

```text
SMOKE_OK version=4.7.1 renderer=gl_compatibility os=Android
B03_CONTRACT_OK
B04_CONTRACT_OK
B04_READY os=Android viewport=1616x720 window=2424x1080
```

Il gate sul device ha verificato:

- spawn e inseguimento visibili nella scena reale;
- crescita della popolazione da `31/80` a `36/80` durante il movimento;
- gesto OS inviato tramite `adb input swipe`, con Player spostato da `(866, 360)`
  a `(1090, 360)` e input tornato a zero al rilascio;
- raggiungimento e mantenimento del cap `80/80` dopo 162,3 secondi di run;
- safe area del cutout e joystick invariati rispetto al gate B03;
- Activity in primo piano, processo vivo e zero corrispondenze per `SCRIPT ERROR`,
  `ERROR:`, `FATAL EXCEPTION` o `CRASH` nel log del processo.

Gli screenshot diagnostici e gli artefatti sono locali in directory ignorate e
restano esclusi da Git.

## Gate ancora aperti

- prova su Android 12/API 31, che resta il minimo supportato;
- prova con un controller USB/Bluetooth reale su Windows;
- soak termico di 20 minuti e profiling del cap, pianificati in B18T;
- collisioni di combattimento: il nemico B04 è un inseguitore senza danno e B05
  aggiungerà targeting, arma, proiettile, hit e salute.
