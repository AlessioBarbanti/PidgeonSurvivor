---
id: PS-100
titolo: Rimuovi L'Ansia dalle Specialità di Barb
tipo: chore
area: gameplay
stato: IN VERIFICA
priorita: media
dipende_da: []
origine: PS-078
creato: 2026-09-05
aggiornato: 2026-09-07
---

# PS-100 — Rimuovi L'Ansia dalle Specialità di Barb

## Contesto

`L'Ansia` (`anxiety_signature`) è entrata nel pool delle Specialità di Barb con
[PS-077](../5_completed/PS-077-espandi-pool-specialita-barb.md): aumenta del 35%
la velocità di movimento, riduce del 20% la vita massima e offusca i bordi dello
schermo con una vignetta. Mentre si sceglievano i nuovi nomi a tema griglia per
[PS-078](../3_in_sprint/PS-078-tematizza-catalogo-specialita-barb.md), il
proprietario ha deciso che la carta non gli piace e va tolta dal gioco, non
rinominata.

La rimozione non è tematizzazione e non poteva restare dentro PS-078, che per
contratto non tocca pool, pesi né sblocchi: `anxiety_signature` è referenziata
dall'`UpgradeEffectRegistry` (parametro `vignette_intensity`), dalla lista di
definizioni di `movement_slice.gd` e da cinque suite di regressione, fra cui
`test_b18j_summer_grill.gd` che compone deliberatamente `Grigliata estiva` con
`L'Ansia`.

## Comportamento atteso

`L'Ansia` non viene più offerta da Barb né compare nel pool di level-up: le
Specialità diventano sette. Nessun'altra carta cambia effetto, peso o
probabilità di comparire, e la vignetta non resta accesa da nessun percorso.

## Criteri di accettazione

- [x] `anxiety_signature` non è più offerta né dalla ricompensa di Barb né dal
      level-up ordinario, in nessuno stato di run. Rimossa dall'`ext_resource`
      e dall'array `definitions` di `UpgradeRegistry` in
      `movement_slice.tscn`; il file `.tres` e la sua icona restano su disco
      come storico non referenziato (nessuna carta viene mai eliminata dal
      repository, solo scollegata dal catalogo di run — coerente con come
      questo progetto tratta le altre icone superate). Verificato da
      `test_ps100_anxiety_removal.gd` su Barb e su 24 pesche di level-up.
- [x] Il pool delle Specialità di Barb conta otto carte a inizio run (non
      sette: [PS-094](../4_to_test/PS-094-specialita-cariche-abilita-attiva.md),
      presa in carico prima di questa card, ha aggiunto una nona Specialità
      reale nel frattempo — 9 − 1 = 8). Le regressioni aggiornate: vedi
      Decisioni.
- [x] Gli effetti delle altre Specialità restano identici: diff verificato,
      nessuna riga toccata in nessun altro `data/upgrades/*.tres`.
- [x] La vignetta non viene mai attivata da nessun percorso rimasto, e non
      resta accesa dopo restart. `UpgradeEffectRegistry` non ha più alcun
      ramo che le assegni un'intensità diversa da zero (rimosso insieme al
      caso `ANXIETY_SIGNATURE`); il nodo `VignetteEffect` resta cablato come
      infrastruttura riusabile per una futura carta, non eliminato.
      Verificato da `test_ps100_anxiety_removal.gd` a inizio run, dopo un
      ricalcolo effetti e dopo restart.
- [x] `test_b18j_summer_grill.gd` verifica ancora la composizione di
      `Grigliata estiva` con un'altra fonte che modifica la vita massima:
      sostituita con una `UpgradeDefinition` sintetica isolata alla fixture
      del file (nessuna carta reale del catalogo tocca più
      `player_health_max_multiplier` a parte Grigliata stessa), invece di
      perdere la copertura.
- [x] Il log di verifica non contiene `SCRIPT ERROR` per riferimenti rimasti
      alla definizione rimossa. Focused 1/1 e Relevant 84/84 script verdi,
      nessun `SCRIPT ERROR`/`FATAL EXCEPTION` nei log.

## Ambito

- `scenes/game/movement_slice.tscn` (`ext_resource` e array `definitions` di
  `UpgradeRegistry`).
- `scripts/game/movement_slice.gd` (conteggio Specialità nel contratto di
  scena, lista `signature_id` del contratto B13).
- `scripts/progression/upgrade_effect_registry.gd` (costante
  `ANXIETY_SIGNATURE`, casi `can_apply()`/`recalculate_effects()`, ramo
  vignetta in `_apply_signature_effects()`, caso in
  `_has_required_signature_dependencies()`).
- `tests/unit/test_b13_signature_upgrades.gd`,
  `tests/unit/test_b18j_summer_grill.gd`,
  `tests/unit/test_b27_upgrade_icon_refresh.gd`,
  `tests/unit/test_ps012_barb_specialities.gd`,
  `tests/unit/test_ps077_barb_speciality_pool_expansion.gd`.
- Nuovo: `tests/unit/test_ps100_anxiety_removal.gd`.
- Scoperto durante l'implementazione (conseguenza diretta e necessaria,
  vedi Decisioni): `tests/unit/test_b10_upgrade_service.gd` (conteggio totale
  del catalogo composto).

Non toccare:

- l'autorità del `RunController` su stati e pausa;
- la logica di sblocco delle Specialità (`UpgradeService`, contratto PS-012);
- l'identità delle altre sette Specialità, di competenza di PS-078;
- `data/upgrades/specialities/anxiety_signature.tres` e la sua icona
  (`assets/art/icons/upgrades/generated/anxiety.png`): restano su disco come
  storico non referenziato, coerente con come questo progetto tratta le
  altre icone superate (vedi manifest). Nessun file viene eliminato.
- il nodo `VignetteEffect`/`scripts/ui/vignette_effect.gd`: restano
  infrastruttura riusabile, non vengono rimossi (vedi Decisioni).

## Verifica

- Smoke: `tests/unit/test_ps100_anxiety_removal.gd` (corretto il nome dallo
  storico refuso `test_ps099_...` della bozza) → marker
  `ANXIETY_REMOVAL_SMOKE_OK` — verifica che nessuna offerta, in nessun numero
  di iterazioni, contenga `anxiety_signature`, che il registro effetti non
  riconosca più l'`effect_id` nemmeno con dati identici a prima, che le
  Specialità bloccate a inizio run siano otto (PS-094 + PS-100) e che la
  vignetta resti spenta lungo l'intera run, anche dopo un ricalcolo effetti e
  dopo restart.
- Eseguito: Focused 1/1 PASS (con `-RefreshEditor`), Relevant 84/84 PASS
  (script), nessun `SCRIPT ERROR`/`FATAL EXCEPTION` nei log.
- Profilo minimo prima della chiusura: `Relevant`. ✅

## Gate manuali

- [ ] **Aperto** — Runtime Windows: non eseguito in questa sessione.
- [ ] **Aperto** — Validazione statica APK: non eseguita in questa sessione.
- [ ] **Aperto** — Runtime fisico Pixel 9: sconfiggi un Boss e verifica che
      l'offerta di Barb non proponga mai L'Ansia. Nessun device collegato in
      questa sessione.
- [ ] Controllo percettivo richiesto: no.

## Decisioni

- **2026-09-05 — Rimozione richiesta dal proprietario durante PS-078.**
  Motivazione dichiarata: la carta non piace. La decisione è arrivata mentre si
  approvavano i nomi a tema griglia; PS-078 è stata rescopata da otto a sette
  Specialità nello stesso momento.
- **2026-09-05 — Card separata invece che dentro PS-078.** PS-078 è
  `tipo: art` e il suo contratto esplicito è "solo identità, mai gameplay":
  rimuovere una carta dal pool tocca registry, scena di run e cinque
  regressioni, quindi è lavoro `chore` di gameplay e non può essere bundlato in
  una card di tematizzazione.
- **2026-09-07 — La vignetta resta infrastruttura, non viene eliminata.**
  Decisione lasciata aperta dalla bozza ("Da decidere in implementazione").
  `VignetteEffect` è generico (`set_intensity`/`reset_effect`, nessun
  riferimento ad Ansia nel proprio script) e il criterio di questa stessa
  card era già scritto come "la vignetta non viene mai attivata **da nessun
  percorso rimasto**" — formulazione che presuppone il meccanismo ancora
  presente, solo senza piloti. Cancellare l'intero nodo/scena/getter avrebbe
  un raggio d'azione molto più ampio (struttura di scena, firma di
  `UpgradeEffectRegistry.configure()`, più punti di test) per un beneficio
  nullo: nessun costo di manutenzione reale nel tenere ferma un'infrastruttura
  a riposo con un'API pulita. Rimosso solo l'accoppiamento specifico
  ad Ansia (`ANXIETY_SIGNATURE` in `can_apply()`/`recalculate_effects()`/
  `_apply_signature_effects()`/`_has_required_signature_dependencies()`);
  `_apply_signature_effects()` ora forza sempre `set_intensity(0.0)` quando
  il nodo esiste.
- **2026-09-07 — I file `.tres`/icona di Ansia restano su disco, non
  eliminati.** La rimozione è dal *gioco* (catalogo di run), non
  dal repository: nessuna carta viene mai cancellata da questo progetto una
  volta generata (vedi come il manifest icone tratta le icone "superate da
  PS-078" — restano, solo non più referenziate). Stessa logica qui: file
  intatti, solo scollegati da `movement_slice.tscn`.
- **2026-09-07 — Scoperta durante l'implementazione: il numero di
  Specialità/carte non è "sette" ma "otto".** La bozza di questa card
  assumeva un catalogo fermo a otto Specialità (7 dopo la rimozione). Nel
  frattempo [PS-094](../4_to_test/PS-094-specialita-cariche-abilita-attiva.md)
  è stata presa in carico e ha aggiunto una nona Specialità reale
  (`ability_charge_stacking`) al catalogo di run: 9 − 1 = 8, non 7. Aggiornati
  di conseguenza: `movement_slice.gd::_validate_current_contract()` (8, non
  9 né 7), `test_ps012_barb_specialities.gd` (8),
  `test_ps077_barb_speciality_pool_expansion.gd` (nuova costante
  `EXPECTED_LIVE_SPECIALITY_COUNT=8` per le due prove sulla scena composta,
  separata da `EXPECTED_SPECIALITY_COUNT=7` per le fixture isolate del file,
  che non includono più Ansia), `test_b10_upgrade_service.gd` (26 carte
  totali, invariato per coincidenza numerica: +1 da PS-094, −1 da PS-100).
- **2026-09-07 — `test_b18j_summer_grill.gd`: sostituita L'Ansia con una
  carta sintetica isolata invece di un'altra Specialità reale.** Nessun'altra
  carta del catalogo tocca `player_health_max_multiplier` a parte Grigliata
  estiva stessa: la prova di composizione moltiplicativa ora usa una
  `UpgradeDefinition.new()` costruita al volo nella fixture del test (pattern
  già in uso in `test_ps077_barb_speciality_pool_expansion.gd::_make_filler`),
  selezionata dal level-up ordinario invece che dalla ricompensa Barb
  (non essendo una Specialità). Disaccoppia la copertura di
  quella regressione da qualunque altra carta di bilanciamento futura.

## Documenti sincronizzati

- [x] `docs/powerup-catalog.md`: paragrafo sull'Ansia aggiornato da "esce con
      PS-100" a rimossa, più nota sull'ottava Specialità reale non tematizzata
      (`ability_charge_stacking`, PS-094/PS-118).
- [x] `docs/prd.md`: paragrafo delle Specialità di Barb (sezione 3.3)
      aggiornato (Ansia rimossa, nuova Specialità PS-094 menzionata, conteggio
      "quattro → tre" carte a `max_rank=1`); sezione "Idee per i
      potenziamenti" (### “L'Ansia”) annotata come rimossa dal gioco invece di
      cancellata, coerente con "una card completata resta storica".

## Note

Aperta da PS-078. La domanda "la vignetta resta disponibile o sparisce con la
carta" è stata risolta in implementazione: resta disponibile come
infrastruttura riusabile, senza più alcun pilota. Vedi Decisioni per il
ragionamento completo.
