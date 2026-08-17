# Verifica M0 — 12 agosto 2026

## Esito

Il setup è operativo su Godot 4.7.1. Import, scena bootstrap, export Windows,
APK, generazione AAB e smoke test su telefono Android fisico sono completati.

## Toolchain verificata

| Componente | Valore |
|---|---|
| Godot | `4.7.1.stable.official.a13da4feb` |
| Renderer | `gl_compatibility` |
| JDK | Microsoft OpenJDK 17.0.20 |
| Platform SDK | 31 e 36 |
| Build Tools | 36.1.0 |
| Gradle / AGP | 8.11.1 / 8.6.1 |
| NDK | 29.0.14206865 |
| CMake | 3.10.2.4988404 |
| Template export | 4.7.1, SHA-256 archivio `86409db6200b6f8fd3230989c2d2002851f3dd18acf11d7bdbafddf5a0dd0f72` |
| Device fisico | Pixel 9 (`tokay`), Android 17/API 37, ARM64 |

Lo script `tools/verify-toolchain.ps1 -RunProjectSmoke` termina con codice `0` e
stampa `Toolchain M0 pronta`.

## Artefatti locali

Gli artefatti sono volutamente esclusi da Git.

| Artefatto | Byte | SHA-256 |
|---|---:|---|
| `FriendshipSurvival.exe` | 103.033.344 | `47A4D4E119346D53E6A435986935BAC1C68E08DFEADF531F1422707F75061BCA` |
| `friendship-survival-debug.apk` | 83.910.232 | `7946AB93D48F90D505B0DC4342A79261ED04EABDC25F89E9C31A004558B72275` |
| `friendship-survival-debug.aab` | 28.307.792 | `1C73A2C2B92DBC459CF7DB033C9CBBDAD58ED990FC3F85410BBBFA9D7AB17529` |

Il binario Windows è PE x64 (`0x8664`) e avviato in headless stampa:

```text
SMOKE_OK version=4.7.1 renderer=gl_compatibility os=Windows
```

## Contratto APK verificato

`aapt2`, `apksigner` e l'ispezione ZIP confermano:

- package `com.ilgioco.friendshipsurvival`;
- `versionCode=1`, `versionName=0.1.0`;
- `minSdk=31`, `targetSdk=36`, `compileSdk=36`;
- unica ABI `arm64-v8a`;
- orientamento landscape e categoria Game;
- icona progetto presente;
- nessun permesso Android richiesto;
- firma debug APK Schema v2 valida.

L'AAB contiene soltanto `base/lib/arm64-v8a`. È un artefatto debug strutturale
non firmato: la firma release verrà aggiunta con un keystore esterno prima di B20.

## Smoke test sul Pixel 9

L'APK è stato installato tramite ADB e verificato sul dispositivo:

- installazione streamed completata con `Success`;
- package installato con `versionCode=1`, `versionName=0.1.0`, `minSdk=31`,
  `targetSdk=36` e `primaryCpuAbi=arm64-v8a`;
- cold start completato in 410 ms;
- processo e Activity attivi in fullscreen landscape;
- renderer Compatibility su OpenGL ES 3.2 / Mali-G715;
- log runtime `SMOKE_OK version=4.7.1 renderer=gl_compatibility os=Android`;
- nessun crash, `SCRIPT ERROR`, `SMOKE_FAIL` o fatal exception nel log esaminato;
- Back non chiude il processo;
- Home porta l'app in background e la ripresa conserva lo stesso PID;
- controllo visivo 2424×1080: bootstrap centrato, leggibile e senza clipping.

## Gate ancora aperti

- verifica specifica sul profilo minimo Android 12/API 31;
- implementazione e test del vero input touch/joystick;
- test approfonditi di safe area, cutout e lifecycle durante una run;
- profiling, frame pacing e soak termico;
- nome pubblico, icone definitive e keystore release.
