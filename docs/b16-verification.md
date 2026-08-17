# Verifica B16 — Vittoria, bilanciamento e run completa

Data: 17 agosto 2026  
Engine: Godot 4.7.1  
Stato: implementazione, suite completa, export e smoke Windows, APK finale e
runtime Pixel 9 completati; playtest lungo a valori finali aperto

## Risultato

La morte del Boss assegna la ricompensa mentre la run è ancora in `RUNNING` e
richiede subito `VICTORY`. Il terminale ha priorità su eventuali level-up creati
dai `50 XP`: `UpgradeService` chiude l'offerta, il gameplay resta fermo e
`EndScreen` mostra Boss sconfitto, tempo, ricompensa e `NUOVA RUN`.

Vittoria e sconfitta usano lo stesso restart in-place. Il reset ripristina seed,
clock, Player, XP, coda level-up, offerte e rank, scheduler Boss, targeting,
nemici, pickup, proiettili Player/Boss, cooldown ed effetti dell'abilità attiva.

La baseline di bilanciamento mantiene il Boss a `04:00`. L'arma base produce
`4 × 10 = 40` danni al secondo; `2400 HP` corrispondono quindi a circa `60 s`
teorici di fuoco continuo e collocano la vittoria attorno a `05:00`. È una stima
di dati, non un risultato di playtest: upgrade, bersagli ordinari e schivate
modificano la durata effettiva e restano da misurare.

## Test automatici

Smoke B16:

```powershell
godot_console --headless --path . --resolution 1280x720 `
  --script tests/integration/_complete_run_smoke.gd
```

Esito:

```text
B16_COMPLETE_RUN_SMOKE_OK
```

Lo smoke termina cinque run consecutive in `VICTORY` sulla stessa scena. Prima
di ogni morte lascia intenzionalmente attivi un cooldown, un effetto
dell'abilità, nemici base e proiettili Boss; dopo ogni restart verifica zero
residui, nuovo seed, clock `00:00`, XP/livello/offerte/rank azzerati e UI pulita.

È stata rieseguita l'intera suite B03–B16: 17 smoke verdi, tutti con exit code
`0`, marker `*_SMOKE_OK` e nessun `SCRIPT ERROR`, `FATAL EXCEPTION` o
`SMOKE_FAIL`. Anche `tools/verify-toolchain.ps1 -RunProjectSmoke` termina con
codice `0` e conferma Godot 4.7.1, JDK 17, SDK 31/36, Build Tools 36.1.0, NDK,
template e import.

## Export Windows

L'export debug Windows e il suo smoke runtime terminano con codice `0`. Il
binario stampa `B15_CONTRACT_OK`, `B16_CONTRACT_OK` e `B16_READY` senza errori.

| Artefatto | Byte | SHA-256 |
|---|---:|---|
| `FriendshipSurvival.console.exe` | 101.376 | `6948E3214518231D0E009A43D013014A17D214E1EB5807E5AC309617860E07EA` |
| `FriendshipSurvival.exe` | 103.033.344 | `47A4D4E119346D53E6A435986935BAC1C68E08DFEADF531F1422707F75061BCA` |
| `FriendshipSurvival.pck` | 509.096 | `98FC5BFD56496DD73ADBBEF85312AF48C4FFC75A33DF3AF9586D550A28274039` |

## Export e runtime Android

L'APK finale è stato completato da Gradle; la CLI Godot è rimasta in attesa dopo
`[DONE]` ed è stato terminato soltanto il PID dell'export dopo aver verificato
che il file fosse invariato e valido.

| Artefatto | Byte | SHA-256 |
|---|---:|---|
| `friendship-survival-debug.apk` | 84.367.494 | `516B077FC3B9667C6FD9F8CCEC5C667F8CCBD3EE97660995218D3F7AF98CA216` |

L'ispezione conferma package `com.ilgioco.friendshipsurvival`, versione
`0.1.0`/code 1, `minSdk=31`, `targetSdk=36`, `compileSdk=36`, sola ABI
`arm64-v8a` e firma APK Signature Scheme v2 valida.

Sul Pixel 9 (`tokay`, Android 17/API 37) l'APK finale è stato reinstallato e
avviato a freddo. Usa Compatibility/OpenGL ES 3.2 su Mali-G715 e stampa:

```text
SMOKE_OK version=4.7.1 renderer=gl_compatibility os=Android
B15_CONTRACT_OK
B16_CONTRACT_OK
B16_READY os=Android viewport=(1616, 720) window=(2424, 1080)
```

La prova diagnostica end-to-end descritta in `b15-verification.md` ha inoltre
verificato con tap reali intro, vittoria e `NUOVA RUN`; il log Android è rimasto
privo di errori.

## Gate ancora aperti

- cinque run manuali complete con soglia `04:00` e Boss `2400 HP`, per misurare
  durata, pressione delle ondate e combinazioni upgrade/abilità;
- Android 12/API 31 e Android 16/API 36 esatti;
- controller Windows fisico e verifica manuale dei due pattern con quel device.
