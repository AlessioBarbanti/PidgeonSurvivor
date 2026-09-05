---
id: PS-100
titolo: Rimuovi L'Ansia dalle Specialità di Barb
tipo: chore
area: gameplay
stato: PRONTO
priorita: media
dipende_da: []
origine: PS-078
creato: 2026-09-05
aggiornato: 2026-09-05
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

- [ ] `anxiety_signature` non è più offerta né dalla ricompensa di Barb né dal
      level-up ordinario, in nessuno stato di run.
- [ ] Il pool delle Specialità di Barb conta sette carte a inizio run, e le
      regressioni che si aspettavano otto sono aggiornate a sette con la stessa
      intenzione, non disattivate.
- [ ] Gli effetti delle altre sette Specialità restano identici: nessun
      `effect_id`, `effect_parameters`, `weight` o `max_rank` cambia per
      effetto collaterale della rimozione.
- [ ] La vignetta non viene mai attivata da nessun percorso rimasto, e non
      resta accesa dopo restart o cambio personaggio.
- [ ] `test_b18j_summer_grill.gd` verifica ancora la composizione di
      `Grigliata estiva` con un'altra Specialità che modifica la vita massima o
      la velocità, invece di perdere la copertura.
- [ ] Il log di verifica non contiene `SCRIPT ERROR` per riferimenti rimasti
      alla definizione rimossa.

## Ambito

- `data/upgrades/specialities/anxiety_signature.tres` e la sua icona runtime.
- `scripts/game/movement_slice.gd` (lista delle definizioni registrate).
- `scripts/progression/upgrade_effect_registry.gd` (costante
  `ANXIETY_SIGNATURE` e ramo `vignette_intensity`): decidere se la vignetta
  resta un meccanismo disponibile senza carte che la usano o se va rimossa
  con la carta.
- `tests/unit/test_b13_signature_upgrades.gd`,
  `tests/unit/test_b18j_summer_grill.gd`,
  `tests/unit/test_b27_upgrade_icon_refresh.gd`,
  `tests/unit/test_ps012_barb_specialities.gd`,
  `tests/unit/test_ps077_barb_speciality_pool_expansion.gd`.

Non toccare:

- l'autorità del `RunController` su stati e pausa;
- la logica di sblocco delle Specialità (`UpgradeService`, contratto PS-012);
- l'identità delle altre sette Specialità, di competenza di PS-078.

## Verifica

- Smoke: `tests/unit/test_ps099_anxiety_removal.gd` → marker
  `ANXIETY_REMOVAL_SMOKE_OK` — verifica che nessuna offerta, in nessun numero
  di iterazioni, contenga `anxiety_signature`, che le Specialità bloccate a
  inizio run siano sette e che la vignetta resti spenta lungo l'intera run.
- Profilo minimo prima della chiusura: `Relevant`.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9: sconfiggi un Boss e verifica che l'offerta di
      Barb non proponga mai L'Ansia
- [ ] Controllo percettivo richiesto: no

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

## Documenti sincronizzati

- [ ] `docs/powerup-catalog.md`, se il catalogo deve registrare la rimozione.

## Note

Aperta da PS-078. Da decidere in implementazione: se il meccanismo della
vignetta (`vignette_intensity`) resta disponibile nel registry per usi futuri
oppure sparisce con la carta. Le due scelte hanno costi di manutenzione
diversi e vanno motivate in `Decisioni`, non lasciate implicite.
