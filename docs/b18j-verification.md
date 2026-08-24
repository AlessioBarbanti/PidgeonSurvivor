# B18J — Grigliata estiva

Data verifica automatica: 24 agosto 2026
Godot: `4.7.1.stable.official.a13da4feb`
Target obbligatori: Windows x64 e Android ARM64

## Stato

`IN VERIFICA`. Implementazione, smoke dedicato, regressione completa, toolchain,
runtime Windows, export Android statico, installazione e cold launch sul Pixel 9
sono verdi. Resta aperta la prova manuale specifica B18J con tap reali sui rank,
cura percepibile, lifecycle e reset.

## Contratto implementato

- carta comune `Grigliata estiva`, ID stabile `summer_grill`, `max_rank = 5`;
- moltiplicatore dichiarativo `×1,15` per rank e cap dati del solo contributo
  `×2,05`;
- contributi cumulativi `×1,15`, `×1,3225`, `×1,520875`, `×1,74900625` e
  `×2,0113571875`;
- composizione moltiplicativa con passive e altri upgrade salute;
- per ogni rank, massimo precedente fotografato, ricalcolo senza preservare la
  percentuale e cura esatta del solo delta positivo;
- nessuna resurrezione del Player morto; selezione applicata una volta dopo il
  commit del level-up; pausa e lifecycle non riapplicano l'effetto;
- rank, moltiplicatore, massimo e vita ripristinati all'avvio della run
  successiva;
- icona SVG originale del progetto registrata in `content-approvals.md`.

## Verifica automatica

Smoke dedicato:

```powershell
godot_console --headless --path . --resolution 1280x720 `
  --script tests/integration/_summer_grill_smoke.gd
```

Marker: `B18J_SUMMER_GRILL_SMOKE_OK`.

La fixture copre i cinque rank, contributi e cap dati, cura del delta a Player
ferito, assenza di riapplicazione in pausa, rifiuto del sesto rank, composizione
con `L'Ansia`, restart su una seconda run e anti-resurrezione. La scena emette
anche `B18J_CONTRACT_OK`.

La suite completa è `30/30`; exit code e log sono stati controllati anche per
`SCRIPT ERROR`, `FATAL EXCEPTION`, `SMOKE_FAIL` e `CONTRACT_FAIL`.
`tools/verify-toolchain.ps1 -RunProjectSmoke` è verde con Godot 4.7.1, Java 17
e la toolchain Android prevista.

## Windows x64

L'export debug è riuscito. L'eseguibile è stato avviato realmente a `1280×720`
con renderer Compatibility/OpenGL su NVIDIA e ha emesso `SMOKE_OK` e
`B18J_CONTRACT_OK`, con exit code `0` e senza errori runtime.

## Android ARM64

L'export APK debug è riuscito con exit code `0`. I controlli statici confermano:

- package `com.ilgioco.friendshipsurvival`, versione `0.1.0`/code `1`;
- `minSdk 31`, `targetSdk 36`, `compileSdk 36`;
- orientamento landscape e `resizeableActivity=true`;
- sola ABI `arm64-v8a`;
- firma APK Signature Scheme v2 valida.

| Artefatto | Byte | SHA-256 |
|---|---:|---|
| `exports/windows/FriendshipSurvival.exe` | `103033344` | `47A4D4E119346D53E6A435986935BAC1C68E08DFEADF531F1422707F75061BCA` |
| `exports/windows/FriendshipSurvival.pck` | `1067328` | `0A5C3B973F019543FD2581194969359D6CFA6C41B2B162DBC2524218E357F68F` |
| `exports/android/friendship-survival-debug.apk` | `84881301` | `FC5CFA95E46DB45DCE864EA853547557B80FDCFC3A92FB7B0B0165219C89D20C` |

Questi controlli statici non verificano tap reali, percezione della cura,
lifecycle o cleanup sul runtime Android.

### Avvio tecnico Pixel 9

L'APK aggiornato è stato installato con `adb install -r` e avviato da processo
fermato tramite `com.godot.game.GodotAppLauncher`. Evidenze:

- Pixel 9, Android 17/API 37, cold launch completato in `531 ms`;
- display landscape `2424×1080`, viewport Godot `1616×720`, safe area logica
  `1460,667×680`;
- renderer Compatibility/OpenGL ES 3.2 su Mali-G715;
- `SMOKE_OK` e `B18J_CONTRACT_OK` presenti nel log;
- nessun `SCRIPT ERROR`, `FATAL EXCEPTION`, `ANR`, `SMOKE_FAIL` o
  `CONTRACT_FAIL` del processo.

Il cold launch reale conferma packaging e contratto composto sul device, ma non
sostituisce la selezione manuale della carta durante una run.

## Gate Android fisico manuale aperto

Sul Pixel 9 devono ancora essere provati:

1. selezione touch dei cinque rank e scomparsa della carta al cap;
2. incremento del massimo e cura del delta su Player ferito;
3. composizione con `L'Ansia` senza preservare la percentuale durante
   l'applicazione di Grigliata;
4. pausa/Back, Home, lock/resume, restart e cambio personaggio senza doppie
   applicazioni o stato residuo;
5. log del processo privi di `SCRIPT ERROR`, `FATAL EXCEPTION`, `ANR`,
   `SMOKE_FAIL` e `CONTRACT_FAIL`.
