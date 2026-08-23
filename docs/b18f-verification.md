# B18F — Gran Piroetta inseguitrice di Alea

## Stato

Implementazione completata il 24 agosto 2026. Smoke dedicato, regressione
completa, verifica toolchain ed export Windows/Android sono verdi. La verifica
visiva Windows è stata approvata il 24 agosto 2026; resta aperto soltanto il
runtime su dispositivo Android reale.

## Contratto implementato

- Gran Piroetta usa la modalità `FOLLOWING_PULSE_DAMAGE`;
- l'effetto nasce centrato sul Player e aggiorna la propria posizione dalla
  sorgente per tutta la durata;
- ogni tick di danno usa la posizione aggiornata, non quella di lancio;
- le aree statiche, come Colata di Cemento, restano ancorate al terreno;
- pausa e stati non `RUNNING` congelano posizione, durata e tick;
- termine naturale, restart e cambio profilo rimuovono l'effetto.

## Test automatico dedicato

```powershell
godot_console --headless --path . --resolution 1280x720 `
  --script tests/integration/_alea_following_spin_smoke.gd
```

Marker:

```text
B18F_ALEA_FOLLOWING_SPIN_SMOKE_OK
```

Copertura: posizione iniziale, movimento su due assi, danno nella nuova
posizione, pausa/ripresa, termine naturale, restart con effetto attivo e cambio
profilo con effetto attivo.

## Regressione ed export

- suite completa: `24/24` smoke verdi, senza `SCRIPT ERROR`,
  `FATAL EXCEPTION` o leak;
- `tools/verify-toolchain.ps1 -RunProjectSmoke`: verde con Godot `4.7.1`,
  Java 17 e toolchain Android attesa;
- export Windows debug: completato; smoke dell'eseguibile con exit code `0`,
  `SMOKE_OK` e `B18F_CONTRACT_OK`;
- export Android debug: completato con exit code `0`; package
  `com.ilgioco.friendshipsurvival`, versione `0.1.0`/code 1, `minSdk 31`,
  `targetSdk 36`, `compileSdk 36`, sola ABI `arm64-v8a` e firma APK Signature
  Scheme v2 valida;
- `adb devices -l`: nessun dispositivo collegato, quindi nessuna verifica
  runtime Android è dichiarata.

| Artefatto | Byte | SHA-256 |
|---|---:|---|
| `exports/windows/FriendshipSurvival.exe` | `103033344` | `47A4D4E119346D53E6A435986935BAC1C68E08DFEADF531F1422707F75061BCA` |
| `exports/windows/FriendshipSurvival.pck` | `967384` | `646BE650E8DB02734603C9BDD65C7B12E9D5765E14A9CC3314FC31DF929C6C49` |
| `exports/android/friendship-survival-debug.apk` | `84789461` | `E9F5918F3A9C952621870997396EB9ED6B2CB1D44A13DDE7F70404773ABC7A80` |

## Gate manuali aperti

- Pixel 9: movimento con joystick e attivazione con il secondo dito;
- pausa, Home/lock, Back, ripresa esplicita, restart e cambio personaggio;
- controllo visivo 16:9, 20:9 e 4:3.

## Gate Windows approvato

Il 24 agosto 2026 è stata approvata la verifica visiva della Gran Piroetta:
l'area resta centrata su Alea durante il movimento e non rimane ancorata al
punto di attivazione.
