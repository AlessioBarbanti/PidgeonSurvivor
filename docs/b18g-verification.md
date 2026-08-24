# B18G — Rank delle abilità principali

Data verifica: 24 agosto 2026  
Godot: `4.7.1.stable.official.a13da4feb`  
Target obbligatori: Windows x64 e Android ARM64

Stato: `IN VERIFICA`; implementazione, gate automatici, runtime Windows ed
export Android statico chiusi. Resta aperta la verifica manuale su Pixel 9.

## Contratto implementato

- Le otto `AbilityDefinition` dichiarano cinque `AbilityRankSnapshot` completi.
  Il rank `1` coincide con la baseline e i rank `2–5` applicano esattamente i
  valori congelati nel piano di sviluppo.
- `AbilityController` risolve una copia per il rank corrente senza mutare la
  risorsa condivisa. Ogni attivazione fotografa un'altra copia: un effetto o un
  cooldown già iniziato conserva durata e valori precedenti mentre il nuovo
  rank vale dalla prossima attivazione.
- Il catalogo level-up contiene una carta autorevole per ogni ability ID. Il
  servizio rende eleggibile soltanto quella equipaggiata, parte dal rank `1`,
  mostra i passaggi `1→2` fino a `4→5` e rimuove la carta al cap.
- L'offerta continua a estrarre tre ID unici. Rank, carta equipaggiata e profilo
  runtime vengono azzerati al restart e al cambio personaggio; non esiste
  meta-progressione.
- Cosplay Casuale risolve la copia al rank dichiarato e, dai rank `4–5`, evita
  l'ultima abilità quando esiste un'alternativa compatibile.

## Verifica automatica

Comandi principali:

```powershell
godot_console --headless --editor --path . --quit
godot_console --headless --path . --script tests/integration/_ability_ranks_smoke.gd
.\tools\verify-toolchain.ps1 -RunProjectSmoke
```

Risultati:

- smoke dedicato: `B18G_ABILITY_RANKS_SMOKE_OK`;
- contratto scena: `B18G_CONTRACT_OK`;
- regressione completa: `29/29`, senza `SCRIPT ERROR`, `FATAL EXCEPTION`,
  `SMOKE_FAIL` o `CONTRACT_FAIL`;
- verificati i 40 snapshot, i valori specifici delle otto progressioni, la
  completezza dei parametri ereditati e l'immutabilità della baseline;
- verificati carta unica dell'abilità equipaggiata, ID derivato dall'ability ID,
  quattro passaggi, cap, cooldown già iniziato, due run e cambio personaggio;
- gli smoke B10/B11 sono stati adeguati a contare gli incrementi rispetto al
  rango iniziale, non la somma dei valori assoluti.

## Windows x64

L'export debug `Windows Desktop` è riuscito. Il binario è stato avviato nel
renderer Compatibility/OpenGL sulla NVIDIA GeForce RTX 3060 a `1280×720`, con
seed `1807`; il log ha emesso `SMOKE_OK` e `B18G_CONTRACT_OK` senza errori o
marker di fallimento.

Un tentativo diagnostico di forzare l'eseguibile GUI esportato con `--headless`
ha prodotto un crash nativo Godot prima dell'avvio del progetto. Il gate è stato
ripetuto correttamente nel normale renderer dell'export e si è chiuso.

| Artefatto | Byte | SHA-256 |
|---|---:|---|
| `exports/windows/FriendshipSurvival.exe` | `103033344` | `47A4D4E119346D53E6A435986935BAC1C68E08DFEADF531F1422707F75061BCA` |
| `exports/windows/FriendshipSurvival.pck` | `1053548` | `C810503A109148B4E149542FC4B6B9D648BC980832860EC3245F4382DC714D09` |

## Android ARM64

L'export debug APK è riuscito. I controlli statici confermano:

- package `com.ilgioco.friendshipsurvival`, versione `0.1.0`;
- `minSdk 31`, `targetSdk 36`, `compileSdk 36`;
- sola ABI `arm64-v8a`;
- firma APK Signature Scheme v2 valida;
- activity landscape (`screenOrientation=0`) e ridimensionabile.

| Artefatto | Byte | SHA-256 |
|---|---:|---|
| `exports/android/friendship-survival-debug.apk` | `84867390` | `12159337026EE0F9C0A271D674DC6C12AB384E797DA3335BB3413B6B009E393D` |

`adb devices -l` non ha rilevato device collegati il 24 agosto 2026. L'export e
l'ispezione APK non chiudono il gate runtime Android.

## Gate Pixel 9 aperto

Sul device fisico restano da verificare:

- carta dell'unica abilità equipaggiata, passaggi `1→2→3→4→5` e scomparsa al
  cap, con tap reali nell'overlay;
- nuova attivazione con valori del rank acquisito e cooldown già iniziato non
  riscritto dal level-up;
- pausa, Home/ritorno, restart e cambio personaggio senza rank o offerta residui;
- layout 20:9 e log del processo privi di errori o marker di fallimento.
