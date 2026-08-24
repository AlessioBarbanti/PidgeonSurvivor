# B18E — Tempesta di Tuoni di Zat

Data verifica automatica: 24 agosto 2026  
Godot: `4.7.1.stable.official.a13da4feb`  
Target obbligatori: Windows x64 e Android ARM64

## Stato

`IN VERIFICA`. Implementazione, smoke dedicato, regressione completa, toolchain,
runtime Windows ed export Android statico sono verdi. Resta aperto il gate su
dispositivo Android fisico: durante questa sessione `adb devices -l` non ha
restituito dispositivi collegati.

Il nome pubblico approvato durante l'implementazione è **Tempesta di Tuoni**,
non Tempesta di Fulmini. Gli ID tecnici storici `zat_lightning_storm` e
`lightning_storm` restano stabili per compatibilità interna.

## Contratto implementato

- cooldown rank 1 `60 s` di clock `RUNNING`;
- preavviso singolo di `0,45 s` con nube e onde del tuono;
- snapshot all'impatto di tutti i nemici vivi, inclusi quelli registrati dopo
  l'attivazione, con una sola elaborazione per istanza;
- danno pari al `50%` degli HP massimi per i nemici normali e al `20%` per i
  Boss;
- un solo overlay bianco sull'intero viewport logico: salita `0,06 s`, tenuta
  `0,06 s`, dissolvenza `0,18 s`; alpha massimo `0,55` Windows e `0,40`
  Android;
- opzione persistente **Flash ridotti** nel menu pausa: alpha `0,15`, nessuna
  tenuta e nessuna modifica a preavviso, audio o danno;
- preavviso e flash restano congelati fuori da `RUNNING`; fine run, morte,
  restart e cambio personaggio rimuovono l'effetto scene-local.

## Verifica automatica

Smoke dedicato:

```powershell
godot_console --headless --path . --resolution 1280x720 `
  --script tests/integration/_zat_thunder_storm_smoke.gd
```

Marker: `B18E_ZAT_THUNDER_STORM_SMOKE_OK`.

Copertura: ritardo e pausa, bersaglio entrato nel preavviso, normali/Boss,
snapshot senza doppie hit, viewport `1280×720`, alpha Windows/Android, modalità
ridotta senza tenuta, persistenza del toggle e cleanup terminale.

La suite completa è `28/28` e non contiene `SCRIPT ERROR`, `FATAL EXCEPTION`,
`SMOKE_FAIL` o `CONTRACT_FAIL`. Il contratto della scena emette
`B18E_CONTRACT_OK`. `tools/verify-toolchain.ps1 -RunProjectSmoke` è verde con
Godot 4.7.1, Java 17 e toolchain Android prevista.

## Windows x64

L'export debug è riuscito. L'eseguibile è stato avviato realmente a `1280×720`
con renderer Compatibility/OpenGL su NVIDIA e ha emesso `SMOKE_OK` e
`B18E_CONTRACT_OK`, con exit code `0` e senza errori runtime.

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
| `exports/windows/FriendshipSurvival.pck` | `1013680` | `D2011F864A508FB869F9E92F253A75B1C3EF94D172FE51A1554EB1125BABA153` |
| `exports/android/friendship-survival-debug.apk` | `84837294` | `BD7DE4275A0E0EEF940B5F87C90A2D41187CDB1C9006A3E0C27F63A717BFF619` |

Questi controlli statici non verificano percezione del flash, multitouch,
lifecycle o cleanup sul runtime Android reale.

## Gate Android fisico aperto

Sul Pixel 9 devono ancora essere provati:

1. Zat in movimento con un dito e attivazione col secondo;
2. preavviso, singolo flash e danno ritardato, sia standard sia con **Flash
   ridotti**;
3. copertura a 20:9, leggibilità con Boss e densità elevata;
4. pausa/Back, Home, lock/resume, morte e restart durante preavviso e flash;
5. log del processo privi di `SCRIPT ERROR`, `FATAL EXCEPTION`, `ANR`,
   `SMOKE_FAIL` e `CONTRACT_FAIL`.
