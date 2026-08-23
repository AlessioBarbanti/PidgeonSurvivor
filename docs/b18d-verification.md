# B18D — Powerslide direzionale di Bea

## Stato

Implementazione completata il 24 agosto 2026. Smoke dedicato e regressione
completa verdi; export Windows e APK ARM64 prodotti. Restano da chiudere la
verifica runtime su Pixel 9; il comportamento Windows è stato approvato il
24 agosto 2026 prima del commit dedicato.

## Contratto implementato

- il nome pubblico e runtime è **Powerslide**;
- l'effetto fotografa `Player.get_last_movement_direction()` all'attivazione e
  non legge più `movement_input` dopo il teletrasporto;
- il Player viene teletrasportato istantaneamente lungo una linea retta e la
  scia resta sul percorso originario;
- `dash_distance: 320`, `trail_duration: 4`,
  `trail_tick_interval: 0.25` e `damage: 6` sono dati configurabili;
- distanza e larghezza della scia sono unità logiche del mondo Godot, non pixel fisici;
- dopo il teletrasporto il movimento ordinario del Player non viene bloccato;
  cambi del joystick non modificano la scia già fotografata;
- pausa e stati non `RUNNING` congelano durata e cooldown;
- morte, cambio profilo e restart ripuliscono sempre la scia.

## Icona

L'icona originale `inline_skate.svg` proviene da Pinhead `v15.17.0`, licenza
CC0 1.0. Originale, derivato con palette del progetto, URL, licenza e SHA-256
sono conservati in
[`assets/art/third_party/pinhead_inline_skate/LICENSE.md`](../assets/art/third_party/pinhead_inline_skate/LICENSE.md).

## Test automatico dedicato

```powershell
godot_console --headless --path . --resolution 1280x720 `
  --script tests/integration/_bea_powerslide_smoke.gd
```

Marker:

```text
B18D_BEA_POWERSLIDE_SMOKE_OK
```

Copertura: dati e icona, attivazione da neutro su diagonale sinistra-alto,
teletrasporto istantaneo, scia rettilinea, cambio joystick dopo l'attivazione,
pausa, danno iniziale, cleanup e seconda run su diagonale destra-basso.

## Modalità debug cooldown

Per il playtest locale la build debug accetta:

```powershell
.\exports\windows\FriendshipSurvival.exe --debug-ability-cooldown=0.2
```

Il valore vale per tutte le abilità attive, senza modificare i cooldown nei
`AbilityDefinition` o il bilanciamento documentato. Gli smoke test senza questo
argomento usano i valori normali.

## Regressione ed export

- suite completa: `23/23` smoke verdi, senza `SCRIPT ERROR`,
  `FATAL EXCEPTION` o leak;
- `tools/verify-toolchain.ps1 -RunProjectSmoke`: verde con Godot `4.7.1`,
  Java 17 e toolchain Android attesa;
- export Windows debug: completato; smoke dell'eseguibile con exit code `0`,
  `SMOKE_OK` e `B18D_CONTRACT_OK`;
- export Android debug: completato con exit code `0`; l'APK è valido come
  controllo statico, contiene soltanto `arm64-v8a`, ha `minSdk 31` e
  `targetSdk 36`;
- `adb devices -l`: nessun dispositivo collegato, quindi nessuna verifica
  runtime Android è dichiarata.

| Artefatto | Byte | SHA-256 |
|---|---:|---|
| `exports/windows/FriendshipSurvival.exe` | `103033344` | `47A4D4E119346D53E6A435986935BAC1C68E08DFEADF531F1422707F75061BCA` |
| `exports/windows/FriendshipSurvival.pck` | `960672` | `665893FF2B94CD49427BEFE555F84BCDA2D7C5F4752A342BF2D893EB6BF23DB4` |
| `exports/android/friendship-survival-debug.apk` | `84782578` | `4B76719FE0DC96A44E4F934C9DAADC65EEF68329E4C5F9A82E6465B36047E89C` |

## Gate manuali aperti

- Pixel 9: direzione dopo rilascio joystick e attivazione con il secondo dito;
- pausa, Home/lock, Back, ripresa esplicita e restart durante teletrasporto e scia;
- controllo visivo 16:9, 20:9 e 4:3.
