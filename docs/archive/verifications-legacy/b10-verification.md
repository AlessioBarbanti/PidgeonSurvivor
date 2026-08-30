# Verifica B10 — Resource upgrade, registry e pesca

Data: 17 agosto 2026  
Engine: Godot 4.7.1  
Stato: implementazione, test automatici, export e gate runtime Windows/Pixel 9 completati

## Risultato

B10 collega il catalogo delle carte alla coda di level-up B08 senza anticipare
l'overlay B11 o gli effetti gameplay B12:

- `UpgradeDefinition` espone ID stabile, titolo, descrizione, icona,
  `effect_id`, parametri, peso, rank massimo, ripetibilità, tag e prerequisiti;
- gli ID sono snake_case validi; pesi, rank, tag e prerequisiti malformati
  invalidano la definizione;
- `UpgradeRegistry` indicizza le definizioni per ID ed esclude valori nulli,
  ID duplicati e prerequisiti non registrati;
- `UpgradeService` ascolta un solo `level_up_started`, possiede RNG e rank della
  run, pesca in modo pesato senza reinserimento e pubblica esattamente tre
  definizioni distinte;
- le carte al rank massimo e quelle con prerequisiti non soddisfatti vengono
  filtrate prima della pesca;
- le quattro carte statistiche normali ripetibili mantengono sempre tre opzioni
  distinte senza una categoria fallback;
- ogni scelta aggiorna un solo rank, consuma una sola voce B08 e genera subito
  l'offerta successiva se la coda contiene altri livelli, senza un frame di
  gameplay intermedio;
- restart e nuova run azzerano rank, offerta, contatore delle pesche e stream
  RNG; lo stesso seed con le stesse scelte riproduce la stessa sequenza.

Il catalogo composto contiene anche `swift_steps`, `rapid_fire` e
`wide_magnet`. I relativi `effect_id` sono già dati dichiarativi, ma B10 non
modifica ancora statistiche del Player o dell'arma: l'applicazione appartiene
a B12. B11 aggiungerà la UI che mostra e conferma l'offerta corrente.

## Test automatici

Comando dedicato:

```powershell
godot_console --headless --path . --resolution 1280x720 `
  --script tests/integration/_upgrade_service_smoke.gd
```

Lo smoke copre:

- validazione del Resource e rifiuto di ID non validi, duplicati, fallback con
  cap e prerequisiti assenti;
- filtro di prerequisiti e rank massimo;
- sequenze identiche a parità di seed, catalogo e scelte;
- pesca pesata senza duplicati;
- passaggio da una primaria limitata a tre fallback distinti;
- ricomparsa e stacking di un fallback ripetibile oltre `max_rank`;
- tre level-up consecutivi nella scena composta;
- reset completo dei rank e dello stream RNG al restart.

Esito dedicato:

```text
B10_UPGRADE_SERVICE_SMOKE_OK
```

È stata rieseguita l'intera suite B03–B10: undici smoke test verdi, tutti con
codice `0` e marker `*_SMOKE_OK`. Anche
`tools/verify-toolchain.ps1 -RunProjectSmoke` termina con codice `0`; il
contratto della scena principale stampa:

```text
B10_CONTRACT_OK
B10_READY
```

## Export Windows e Android

Gli export debug sono stati rigenerati nelle directory ignorate. Lo smoke
dell'eseguibile Windows esportato termina con codice `0`, usa Compatibility su
NVIDIA GeForce RTX 3060 e stampa `B10_CONTRACT_OK`.

| Artefatto | Byte | SHA-256 |
|---|---:|---|
| `FriendshipSurvival.console.exe` | 101.376 | `6948E3214518231D0E009A43D013014A17D214E1EB5807E5AC309617860E07EA` |
| `FriendshipSurvival.exe` | 103.033.344 | `47A4D4E119346D53E6A435986935BAC1C68E08DFEADF531F1422707F75061BCA` |
| `FriendshipSurvival.pck` | 341.304 | `2D2D9EA6575722B1F8E54ED18991D3107D07706FB6DEA0FCDDA0AC13BFE363BB` |
| `friendship-survival-debug.apk` | 84.210.895 | `B61995FB5BDFF073FB6CDCB8D0B99E7E8BCBFFF8062266C5A17889206DCD4D06` |

`aapt2`, `apksigner` e l'ispezione ZIP confermano package
`com.ilgioco.friendshipsurvival`, versione `0.1.0`/code 1, minSdk 31,
target/compileSdk 36, sola ABI `arm64-v8a` e firma debug APK Signature Scheme
v2 valida.

## Runtime Pixel 9

L'APK B10 è stato installato con `adb install -r` sul Pixel 9 (`tokay`),
Android 17/API 37, ARM64. Il processo usa Compatibility/OpenGL ES 3.2 su
Mali-G715 e ha stampato:

```text
SMOKE_OK version=4.7.1 renderer=gl_compatibility os=Android
B10_CONTRACT_OK
B10_READY os=Android viewport=(1616, 720) window=(2424, 1080)
```

Il contratto runtime ha risolto i sei Resource, i tre fallback e i collegamenti
fra `UpgradeRegistry`, `UpgradeService`, `ExperienceSystem` e `RunController`.
Nel log del processo non risultano `SCRIPT ERROR`, `FATAL EXCEPTION` o crash.

## Gate ancora aperti

- visualizzazione e conferma touch/controller delle carte: B11;
- applicazione e stacking degli effetti statistici: B12;
- prova sui profili esatti Android 12/API 31 e Android 16/API 36;
- prova con controller USB/Bluetooth reale.
