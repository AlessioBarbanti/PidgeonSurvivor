---
id: PS-129
titolo: Integra il ritratto definitivo del Piccione Malvagio nella Boss intro
tipo: fix
area: UI
stato: COMPLETATO
priorita: media
dipende_da: [PS-128]
origine:
creato: 2026-09-07
aggiornato: 2026-09-07
---

# PS-129 — Integra il ritratto definitivo del Piccione Malvagio nella Boss intro

## Contesto

PS-128 produce il busto definitivo del Boss baseline. Questa card possiede il
collegamento runtime e le verifiche che, per il contratto PS-090, non
appartengono alla produzione `tipo: art`.

## Comportamento atteso

La Boss intro del Piccione Malvagio usa il nuovo derivato `256×256` invece del
ritaglio `48×48` dello spritesheet di gameplay, senza cambiare gameplay o layout.

## Criteri di accettazione

- [x] `data/bosses/first_boss.tres` referenzia
      `assets/art/characters/piccione_malvagio/generated/portrait.png` e non
      contiene più l'`AtlasTexture` su `pigeon_special.png` per `portrait`.
- [x] HP, danno, velocità, pattern, colori e ogni altro dato del Boss baseline
      restano invariati.
- [x] `tests/unit/test_ps051_boss_intro_identity.gd` verifica che
      `BossDefinition.get_safe_portrait()` risolva il nuovo derivato.
- [x] Il profilo `Relevant` passa senza `SCRIPT ERROR`, `FATAL EXCEPTION`,
      `SMOKE_FAIL` o `CONTRACT_FAIL`.

## Ambito

- `data/bosses/first_boss.tres`, il test focalizzato e la mappa regressioni se
  necessaria.
- Sincronizzazione del riferimento corrente in `docs/enemies-bosses.md`.

Non toccare lo sprite di gameplay, il layout della Boss intro o i parametri di
bilanciamento del Boss.

## Verifica

- [x] Refresh import Godot del nuovo derivato: PASS.
- [x] Focused: `1/1` file, 5 test, 0 failure;
      `BOSS_INTRO_IDENTITY_SMOKE_OK`.
- [x] Relevant: `1/1` focused, `54/54` regressioni, 192 test, 0 failure;
      nessun `SCRIPT ERROR`, `FATAL EXCEPTION`, `SMOKE_FAIL` o `CONTRACT_FAIL`.
- [x] Release isolata da modifiche concorrenti: `122/122` regressioni,
      toolchain PASS, export/runtime Windows PASS, APK statico PASS. Export
      Android recuperato dopo il marker `[ DONE ] export`, come previsto dal
      runner.

## Gate manuali

- [x] Runtime Windows: export e avvio della candidata isolata, log puliti.
- [x] Validazione statica APK: package `com.ilgioco.pidgeonsurvivor`, min SDK
      31, target SDK 36, solo ARM64, firma v2 e launcher corretti; master HD
      coperto dai tre `exclude_filter`.
- [ ] Runtime fisico Pixel 9 della Boss intro: non eseguito. APK corrente
      installato e cold launch riuscito, ma il percorso Boss non è stato
      esercitato; gate omesso su richiesta esplicita del proprietario.
- [x] Approvazione percettiva del proprietario: leggibilità e
      coerenza con lo sprite di gameplay.

## Decisioni

- **2026-09-07 — Separata da PS-128 per PS-090.** Questa card possiede wiring,
  import, smoke, regressioni e gate di piattaforma; PS-128 resta produzione
  artistica pura.
- **2026-09-07 — Release isolata dal lavoro concorrente.** Durante il primo
  tentativo erano presenti modifiche PS-127 incomplete nei file Boss, con
  funzioni mancanti in `first_boss.gd`. La candidata PS-129 è stata quindi
  verificata in un worktree temporaneo pulito basato su `HEAD`, applicando solo
  asset, `first_boss.tres` e test PS-129. Un test arena dipendente dall'ordine
  ha fallito a 6 shard per viewport ereditata; il rerun seriale ha passato
  `122/122` senza modificare codice estraneo.
- **2026-09-07 — Gate Pixel 9 omesso dal proprietario.** Dopo installazione e
  cold launch riusciti, il proprietario ha chiesto di interrompere la verifica
  Android e ha accettato operativamente il risultato. Questa rinuncia chiude la
  card, ma non costituisce evidenza di runtime/percezione della Boss intro sul
  device.

## Documenti sincronizzati

- [x] `docs/enemies-bosses.md`.

## Note

APK isolato verificato: `127467290` byte, SHA-256
`D9412B7EF2C2B40D588E852F84081CD7D3245A05DA6C14AE2D506C7668A6214D`.
Installazione `adb install -r`: `Success`; cold launch tramite
`com.godot.game.GodotAppLauncher`: `Status: ok`, `LaunchState: COLD`, 499 ms.
Il logcat iniziale contiene `SMOKE_OK` e i contract marker, senza
`SCRIPT ERROR` o `FATAL EXCEPTION`. La navigazione fino alla Boss intro è stata
interrotta su richiesta del proprietario e non viene dichiarata verificata.
