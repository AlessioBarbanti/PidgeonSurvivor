# B18I — XP confinato nell'arena

## Stato

Implementazione, commit dedicato `e58cbd0` e tutti i gate automatici, Windows e
Pixel 9 completati il 24 agosto 2026. La slice è `COMPLETATA`.

## Contratto implementato

- `ExperienceDropper` riceve l'`ArenaLayout` autorevole della scena;
- il centro di ogni drop viene clampato nel playfield corrente con
  `ArenaLayout.clamp_circle_center()`;
- il margine usa il maggiore fra raggio visivo (`10`) e raggio di raccolta
  (`18`), quindi oggi vale `18` unità logiche del mondo Godot, non pixel fisici;
- una morte già interna conserva la propria posizione;
- una morte esterna viene corretta sul lato o angolo raggiungibile più vicino;
- spawn, valore XP, magnete, raccolta singola e cleanup al restart restano
  invariati.

## Test automatico dedicato

```powershell
godot_console --headless --path . --resolution 1280x720 `
  --script tests/integration/_xp_arena_confinement_smoke.gd
```

Marker:

```text
B18I_XP_ARENA_CONFINEMENT_SMOKE_OK
```

Copertura: morte al centro, quattro lati e quattro angoli; viewport logiche
`1280×720` (16:9), `1600×720` (20:9) e `960×720` (4:3); inclusione dell'intero
raggio del pickup; una sola ricompensa per morte e cleanup completo al restart.

## Regressione e toolchain

- suite completa: `25/25` smoke verdi, senza `SCRIPT ERROR`,
  `FATAL EXCEPTION` o marker di fallimento;
- `tools/verify-toolchain.ps1 -RunProjectSmoke`: verde con Godot `4.7.1`,
  Java 17 e toolchain Android attesa;
- il project smoke e il runtime Windows emettono `B18I_CONTRACT_OK`.

## Windows

Export debug x64 completato. L'eseguibile è stato avviato realmente a
`1280×720` con Compatibility/OpenGL 3.3 su NVIDIA GeForce RTX 3060 e ha chiuso
senza errori runtime.

| Artefatto | Byte | SHA-256 |
|---|---:|---|
| `exports/windows/FriendshipSurvival.exe` | `103033344` | `47A4D4E119346D53E6A435986935BAC1C68E08DFEADF531F1422707F75061BCA` |
| `exports/windows/FriendshipSurvival.pck` | `973732` | `38F2D52DB52AC5294DF3CA99454CCCEF19AE902837590A9088E192C3415408CE` |

## Android

Export debug completato con exit code `0`; controlli statici verdi:

| Campo | Valore verificato |
|---|---|
| APK | `84819674` byte; SHA-256 `67D3F3ADC1FC8DFA955C89C5507AABA29C8EEEB315DEFF6B9D890CE03D95CD7D` |
| Package | `com.ilgioco.friendshipsurvival`, versione `0.1.0` (`versionCode=1`) |
| SDK | minimo 31, target 36, compile 36 |
| ABI | solo `arm64-v8a` |
| Firma | APK Signature Scheme v2 valida |
| Certificato debug SHA-256 | `932BAB834EBA16A12DA88A8ACF3E40B207A946E0000641F25FD15CBE4FE7FFD3` |

L'APK è stato installato e avviato sul Pixel 9 `tokay`, Android 17/API 37.

## Gate fisico chiuso

- i drop osservati vicino ai bordi restano interamente nell'arena e raggiungibili;
- raccolta e cleanup dopo `RIPROVA` non lasciano pickup della run precedente;
- il processo resta vivo e i log non contengono `SCRIPT ERROR`, `FATAL
  EXCEPTION`, `ANR`, `SMOKE_FAIL` o `CONTRACT_FAIL`.

Gli artefatti generati restano nelle directory ignorate `exports/` e
`android/build/` e non devono essere committati.
