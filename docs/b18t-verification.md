# Verifica B18T — Carosello selezione personaggi

Data: 25 agosto 2026
Stato: `IN VERIFICA`

B18T sostituisce il selettore precedente con un carosello ciclico dati di otto
profili. Card centrale, anteprime, frecce, tastiera, D-pad/stick, click e swipe
condividono lo stesso indice; soltanto il CTA separato avvia la run. Welcome,
selezione e ricostruzione da pausa o terminale conservano `RunController.BOOT`.

## Asset e contratti

Ogni `FriendDefinition` espone un ritratto selezione `256×256` derivato dalla
sorgente HD omonima in `assets/art/characters/players/hd/`. Il processo
deterministico è `tools/process-carousel-portrait.ps1`; sorgenti, trasformazioni,
licenza di progetto e SHA-256 sono nel manifest Player. Le sorgenti HD sono
escluse da import ed export, mentre l'APK contiene gli otto `.png.import`
runtime del carosello.

Lo smoke `_character_carousel_smoke.gd` chiude wrap-around, ordine degli otto
profili, input equivalenti, swipe contro tap, conferma, Back, ricostruzione dopo
pausa/sconfitta/vittoria e layout 16:9, 20:9 e 4:3. Marker:
`B18T_CHARACTER_CAROUSEL_SMOKE_OK`.

## Verifica automatica e desktop

- regressione completa: `40/40` smoke verdi;
- `tools/verify-toolchain.ps1 -RunProjectSmoke`: verde;
- export Windows x64 e Android ARM64: verdi;
- runtime Windows con `--smoke-test`: `SMOKE_OK`, `B18T_CONTRACT_OK`,
  `B18W_CONTRACT_OK`, codice `0`;
- nessun `SCRIPT ERROR`, `FATAL EXCEPTION`, `SMOKE_FAIL` o `CONTRACT_FAIL`.

## Pixel 9

L'APK finale è stato installato sul Pixel 9 `49140DLAQ0010Y`. Sono verdi cold
launch, welcome, carosello, conferma Zat, ingresso nella run, Back/pausa,
conferma di “Cambia personaggio” e ricostruzione del carosello in `BOOT`.

La regressione sul difetto touch emulato usa la sequenza Magno → Bea con D-pad,
quindi un singolo tap ADB sull'anteprima destra: il risultato finale è Zat, non
Alea. Il tap ora è affidato al `Button` nativo e il touch grezzo gestisce soltanto
il riconoscimento dello swipe, evitando due avanzamenti sullo stesso rilascio.

Resta aperto il gate manuale con dito e il confronto percettivo fisico
conclusivo; l'iniezione ADB è evidenza di runtime sul dispositivo, non sostituisce
una prova umana del gesto.

## Artefatti finali

| Artefatto | Byte | SHA-256 |
|---|---:|---|
| `PidgeonSurvivor.exe` | `103115264` | `BFA5766944AD646D797F3FEB0172A0287A65CFD9FF08B1B1E449955985BC85FA` |
| `PidgeonSurvivor.pck` | `11366276` | `F8DB44FE1F83683BD4401C5E556F0FB033DC27706B1B179279EDA208CA53FD3E` |
| `pidgeon-survivor-debug.apk` | `95837767` | `DCC1275DECDCA537C917D885F20E4D876891B52F827BA1EBC09FE167420B1FA7` |

L'APK dichiara package `com.ilgioco.pidgeonsurvivor`, versione `0.1.0` (`1`),
`minSdk 31`, `targetSdk 36`, `compileSdk 36`, sola ABI `arm64-v8a` e firma v2
valida con un firmatario. Nessuna sorgente HD Player o CTA è inclusa.
