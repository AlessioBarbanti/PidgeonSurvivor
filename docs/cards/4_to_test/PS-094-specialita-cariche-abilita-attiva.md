---
id: PS-094
titolo: Introduci una Specialità di Barb per cariche multiple dell'abilità attiva
tipo: feat
area: gameplay
stato: IN VERIFICA
priorita: media
dipende_da: []
origine: conversazione del proprietario 2026-09-04
creato: 2026-09-04
aggiornato: 2026-09-07
---

# PS-094 — Introduci una Specialità di Barb per cariche multiple dell'abilità attiva

## Contesto

Oggi l'abilità attiva di ogni personaggio ha un modello a **cooldown singolo**:
una carica, si usa, si aspetta la ricarica, si può riusare
([scripts/abilities/ability_controller.gd:21-22,36](../../../scripts/abilities/ability_controller.gd#L21),
`_cooldown_remaining`/`_ready_state` scalari, `try_activate()` blocca se
`_cooldown_remaining > 0.0`). Nessun concetto di "cariche multiple" esiste nel
runtime: né in `AbilityController`, né in `AbilityDefinition`/
`AbilityRankSnapshot` ([scripts/abilities/ability_rank_snapshot.gd](../../../scripts/abilities/ability_rank_snapshot.gd)),
che scala solo parametri dell'effetto (danno, raggio, durata, cooldown) per
rank del personaggio, non il numero di utilizzi disponibili.

Il proprietario propone una nuova Specialità di Barb, universale (si applica
a qualunque abilità attiva del personaggio in gioco, come già fa "Ravviva la
Brace!" per il cooldown — non richiede dati per personaggio), che introduce
cariche multiple con un andamento a cinque ranghi. Correzione del
proprietario rispetto alla prima formulazione: le cariche si aggiungono ai
ranghi dispari, non a tre passi consecutivi.

Tabella confermata dal proprietario (rango 1 → +1 carica, rango 3 → +2
cariche cumulative, rango 5 → +3 cariche cumulative; i ranghi pari
completano la sequenza sulla ricarica, proiettando la formulazione
originale a tre passi — carica, dimezza ricarica, carica+raddoppia
ricarica — sui nuovi ranghi dispari):

| Rango | Effetto | Cariche massime | Moltiplicatore ricarica per carica |
|---|---|---|---|
| 1 | +1 carica | 2 (base 1 + 1) | `×1,0` |
| 2 | dimezza la ricarica | 2 | `×0,5` |
| 3 | +1 carica | 3 (+2 cumulativo) | `×0,5` |
| 4 | raddoppia la ricarica | 3 | `×1,0` (si compone con il rango 2: `×0,5 × ×2 = ×1,0`) |
| 5 | +1 carica | 4 (+3 cumulativo) | `×1,0` |

A rango 5 e a cariche piene: 4 utilizzi consecutivi dell'abilità attiva,
con la stessa velocità di ricarica per carica della baseline (nessun bonus
né penalità netta sulla ricarica, solo più cariche) — confermato dal
proprietario ("con tutto carico puoi lanciare 4 volte di fila la tua
abilità").

**Perché il rango 4 è un malus, non un errore di bilanciamento**: è l'unico
punto di tensione reale della progressione. Ai ranghi 1, 2, 3 e 5 il
personaggio guadagna e basta; al rango 4 la ricarica per carica peggiora
rispetto a dove si trovava al rango 3 (torna da `×0,5` a `×1,0`) *prima* di
ottenere la quarta carica al rango 5. Poiché le carte upgrade in questo
gioco si scelgono fra tre offerte casuali a ogni level-up — non vengono mai
imposte — questo crea una scommessa reale e sotto il controllo del
giocatore: prendere il rango 4 quando la run sta andando bene (ci si aspetta
di sopravvivere fino a un altro level-up e incassare il rango 5), ignorarlo
e scegliere una delle altre due offerte quando la run è in difficoltà. La
carta resta disponibile al rango 3 finché non viene scelta: non è un rifiuto
permanente, solo una scommessa rimandabile. Il rischio onesto — restare con
la ricarica lenta del rango 4 se la run finisce prima di un altro
level-up — è coerente con altre Specialità che già portano un compromesso
permanente (es. "L'Ansia": `+35%` velocità ma `-20%` vita max), solo che qui
il pagamento è differito invece che immediato.

## Comportamento atteso

Con questa Specialità sbloccata e potenziata, il personaggio può accumulare
fino a un massimo di cariche dell'abilità attiva (crescente col rango, vedi
tabella) invece di un solo utilizzo per ciclo di cooldown; ogni carica si
ricarica in modo indipendente, con la velocità di ricarica per singola
carica che cambia secondo la tabella sopra. L'effetto è universale: si
applica a qualunque abilità attiva del personaggio in gioco, come "Ravviva
la Brace!".

## Criteri di accettazione

- [x] `AbilityController` guadagna un modello a cariche multiple:
      `_available_charges`/`_max_charges` più due array paralleli
      (`_charge_timer_remaining`/`_charge_timer_total`, uno per carica in
      ricarica). `try_activate()` consuma una carica (`_available_charges<=0`
      blocca) invece di richiedere un singolo cooldown scalare; ogni carica
      mancante ha il proprio timer indipendente, restituito a
      `_available_charges` (capped a `_max_charges`) al proprio termine.
      Verificato da `test_ability_charge_stacking` (ricarica indipendente:
      due cariche usate a metà ricarica l'una dall'altra tornano disponibili
      in momenti distinti, non insieme né mai).
- [x] Il comportamento odierno resta identico bit-per-bit senza la
      Specialità: con `_max_charges=1` l'array timer contiene al più una
      voce, con la stessa aritmetica `maxf(remaining-delta,0.0)` di prima.
      Verificato dalla prima sezione dello smoke (attivazione, blocco
      immediato, ricarica singola, tutto bit-identico al modello precedente).
- [x] Segnale dedicato `charges_changed(available_charges: int, max_charges:
      int)` affianca `cooldown_changed`/`readiness_changed` (che restano
      semanticamente invariati: `readiness_changed` riflette
      `_available_charges > 0`).
- [x] `scripts/ui/hud.gd` inoltra `charges_changed` a
      `TouchAbilityButton.set_charge_state()`; il pulsante disegna il numero
      di cariche disponibili (solo il valore corrente, mai il tetto massimo)
      in basso a destra, decentrato rispetto al testo di cooldown centrale,
      solo quando `max_charges > 1` (nessun disegno extra senza la
      Specialità — verificato anche dallo smoke via i getter
      `get_max_charges()`/`get_available_charges()` del pulsante). Leggibilità
      reale a dimensione schermo: gate percettivo manuale, vedi sotto.
- [x] Nuova `UpgradeDefinition` in
      `data/upgrades/specialities/ability_charge_stacking.tres`:
      `is_speciality = true`, `max_rank = 5`, `repeatable = false` (default).
- [x] I cinque ranghi sono dati (`charges_by_rank`/
      `cooldown_multiplier_by_rank`, array indicizzati per rango in
      `effect_parameters`), letti dal nuovo handler `ABILITY_CHARGE_STACKING`
      in `UpgradeEffectRegistry` (`can_apply()` valida la tabella con
      `_is_valid_charge_stacking_table()`, `recalculate_effects()` legge
      l'indice `rank-1`); nessun valore inciso nello script.
- [x] `effect_id`/`effect_parameters`/`weight`/`max_rank` delle otto
      Specialità esistenti e del catalogo ordinario restano bit-per-bit
      identici: diff verificato, nessuna riga toccata in nessun altro
      `data/upgrades/*.tres`.
- [x] Icona e titolo definitivo **non** sono prodotti da questa card (PS-090):
      titolo di lavoro "Bis alla Griglia" (non approvato), icona sostituita
      da un placeholder deterministico
      (`tools/generate-art-placeholder.ps1`, firma magenta `(0,0)` intatta).
      Generazione dell'icona e nome definitivo aperti in handoff su
      [PS-118](../2_to_do/PS-118-nome-e-icona-nona-specialita-cariche-abilita.md).
- [x] [PS-078](../4_to_test/PS-078-tematizza-catalogo-specialita-barb.md) era
      già `IN VERIFICA` quando questa card è stata presa in carico: non
      riaperta. La propria tematizzazione (nome + icona) è quindi la card
      di handoff [PS-118](../2_to_do/PS-118-nome-e-icona-nona-specialita-cariche-abilita.md),
      come previsto da questo stesso criterio.

## Ambito

- `scripts/abilities/ability_controller.gd`: modello a cariche multiple,
  timer di ricarica per carica, segnali.
- `scripts/ui/hud.gd`: visualizzazione delle cariche disponibili.
- `scripts/progression/upgrade_effect_registry.gd`: nuovo handler per
  l'effetto a cariche, letto da `effect_parameters` per rango.
- `data/upgrades/specialities/`: nuova `UpgradeDefinition`.
- `scripts/ui/touch_ability_button.gd`: disegno del numero di cariche.
- `scenes/game/movement_slice.tscn`: nuovo `ext_resource` e voce in
  `UpgradeRegistry.definitions`.
- `docs/powerup-catalog.md` o documento equivalente per le Specialità, se il
  proprietario vuole registrare qui la nuova carta.

Scoperto durante l'implementazione, non nell'ambito originale ma necessario
per coerenza con la nona Specialità nel catalogo di run reale (vedi
Decisioni): `movement_slice.gd::_validate_current_contract()`,
`test_ps012_barb_specialities.gd`, `test_ps077_barb_speciality_pool_expansion.gd`,
`test_b10_upgrade_service.gd` (conteggi hardcoded "otto Specialità"/"26 carte"
aggiornati a nove/27).

Non toccare:

- il modello a cooldown singolo per chi non ha sbloccato questa Specialità
  (deve restare invariato);
- le otto Specialità esistenti e il catalogo ordinario;
- `AbilityRankSnapshot`/`AbilityDefinition`: la progressione per personaggio
  dell'abilità (danno, raggio, durata) resta un sistema separato da questo;
- generazione di icone: fuori ambito per contratto PS-090 (vedi Criteri).

## Verifica

- Smoke: `tests/unit/test_ps094_ability_charge_stacking.gd` → marker
  `ABILITY_CHARGE_STACKING_SMOKE_OK` — verifica: senza la Specialità il
  comportamento resta a cooldown singolo; con la Specialità equipaggiata a
  ciascun rango, `_max_charges` e la velocità di ricarica per carica
  corrispondono alla tabella; le cariche si ricaricano indipendentemente
  (usarne una non blocca l'accumulo delle altre); a cariche piene e rango 5
  sono possibili 4 attivazioni consecutive senza attesa; restart azzera le
  cariche accumulate e il tetto della Specialità.
- Eseguito: Focused 1/1 PASS (con `-RefreshEditor`), Relevant 82/82 PASS
  (script), nessun `SCRIPT ERROR`/`FATAL EXCEPTION` nei log.
- Profilo minimo prima della chiusura: `Relevant`. ✅

## Gate manuali

- [ ] **Aperto** — Runtime Windows: non eseguito in questa sessione (nessuna
      esecuzione interattiva).
- [ ] **Aperto** — Validazione statica APK: non eseguita in questa sessione
      (nessuna build APK).
- [ ] **Aperto** — Runtime fisico Pixel 9: sblocca la Specialità, verifica che
      il tap ripetuto sul pulsante abilità consumi le cariche in sequenza e
      che l'indicatore di cariche resti leggibile a dimensione reale. Nessun
      device collegato in questa sessione.
- [ ] **Aperto** — Controllo percettivo richiesto: sì — il numero di cariche
      disponibili è un elemento HUD nuovo (`TouchAbilityButton`, angolo in
      basso a destra), deve restare leggibile e non confondersi col
      countdown di cooldown centrale né col tetto massimo (che non va
      mostrato, solo il valore corrente). Non ispezionato a schermo in
      questa sessione (solo verificato via getter nello smoke).

## Decisioni

- **2026-09-04 — Idea proposta dal proprietario in conversazione**, mentre si
  discuteva [PS-093](./PS-093-nuovi-assi-scarto-base-personaggi.md): sistema
  distinto (Specialità di Barb, non scarto base per personaggio), aperto come
  card separata.
- **2026-09-04 — Corretta la progressione: cariche su ranghi 1/3/5, non su
  tre passi consecutivi.** Prima formulazione: "primo livello dà una carica,
  il secondo dimezza la ricarica, il terzo dà una carica e raddoppia la
  ricarica" (letta come 3 ranghi). Il proprietario ha corretto con i numeri
  cumulativi su 5 ranghi (rango 1 → +1, rango 3 → +2, rango 5 → +3,
  "4 volte di fila" a rango 5).
- **2026-09-04 — Confermato: il rango 4 è un malus deliberato ("scommessa
  bancata"), non un refuso.** Il proprietario ha confermato esplicitamente
  la logica: si prende il rango 4 (ricarica che peggiora) sapendo che il
  rango 5 la ripaga con la quarta carica; se la run va bene lo si prende,
  se va male si lascia l'offerta e si sceglie altro. Il completamento della
  tabella sui ranghi pari (2: dimezza, 4: raddoppia) è quindi confermato
  nella forma già scritta in Contesto, non più solo un'interpretazione di
  questa card.
- **2026-09-04 — Rango 3 e rango 4 si compongono (non si sostituiscono).**
  Confermato dal proprietario: il raddoppio di rango 4 si applica sopra il
  dimezzamento di rango 2, tornando alla ricarica base per carica invece di
  sostituirla con un valore fisso più lento.
- **2026-09-04 — `repeatable = false`, `max_rank = 5`.** La progressione è
  una sequenza fissa di passi distinti (non un effetto lineare che scala
  all'infinito): diverso dal pattern più comune nel catalogo
  (`X_per_rank * rank`), richiede un handler dedicato nel registro invece di
  riusare le formule esistenti.
- **2026-09-04 — Nona Specialità: interazione con PS-078.** PS-078 tematizza
  "le otto Specialità" — questa card ne aggiunge una nona. Se PS-078 non è
  ancora chiusa quando questa viene presa in carico, va aggiornata a nove;
  altrimenti questa card include la propria tematizzazione nome/icona
  all'handoff (vedi Criteri).
- **2026-09-07 — Implementazione.** `AbilityController` sostituisce lo
  scalare `_cooldown_remaining`/`_active_cooldown_total` con due array
  paralleli (`_charge_timer_remaining`/`_charge_timer_total`, uno per carica
  mancante) più `_available_charges`/`_max_charges`/`_charge_cooldown_multiplier`;
  `get_cooldown_remaining()`/`get_cooldown_total()` leggono il timer più
  vicino a scadere (`_index_of_soonest_charge()`), `is_cooldown_ready()`
  diventa `_available_charges > 0`. Nuovo
  `set_charge_configuration(max_charges, cooldown_multiplier)`/
  `reset_charge_configuration()`: se il personaggio era a cariche piene il
  nuovo tetto viene concesso subito pieno (rango 5 dopo essere stati pieni a
  rango 3/4 dà la quarta carica all'istante); se era a metà ricarica il
  tetto sale ma la carica in corso non viene accelerata né azzerata — scelta
  deliberata, coerente col fatto che il moltiplicatore di ricarica ordinario
  ("Ravviva la Brace!") già non retroagisce su un cooldown in corso.
  `UpgradeEffectRegistry` aggiunge il costante `ABILITY_CHARGE_STACKING`,
  un caso in `can_apply()` (tabella a 5 ranghi non decrescente, validata da
  `_is_valid_charge_stacking_table()`), un caso in `recalculate_effects()`
  (legge l'array all'indice `rank-1`) e la chiamata a
  `set_charge_configuration()`/`reset_charge_configuration()` in
  `_apply_signature_effects()`/`reset_effects()`. HUD: nuovo segnale
  `charges_changed` inoltrato a `TouchAbilityButton.set_charge_state()`.
- **2026-09-07 — Scoperta durante l'implementazione: due assert hardcoded su
  "otto Specialità" nel codice live, non solo in documentazione.**
  `movement_slice.gd::_validate_current_contract()` verificava
  `get_speciality_definitions().size() != 8` e
  `get_locked_speciality_definitions().size() != 8` — aggiornati a 9.
  `test_ps012_barb_specialities.gd` (riga 204) e
  `test_ps077_barb_speciality_pool_expansion.gd` (due funzioni sulla scena
  composta, non sulla fixture isolata a 8 carte B13/B41) asserivano lo stesso
  numero contro la scena reale — aggiornati a 9, con un nuovo
  `EXPECTED_LIVE_SPECIALITY_COUNT` separato da `EXPECTED_SPECIALITY_COUNT`
  (che resta 8, corretto per la fixture isolata di quel file).
  `test_b10_upgrade_service.gd` asseriva `registry.get_definitions().size()
  == 26` (dopo PS-108) sul catalogo composto — aggiornato a 27. Questi non
  erano nell'ambito dichiarato della card ma sono conseguenza diretta e
  necessaria dell'aggiunta della nona Specialità al catalogo di run reale;
  senza il fix, `_validate_current_contract()` avrebbe fallito silenziosamente
  a ogni avvio di run per il resto del progetto.
- **2026-09-07 — Verificato IN VERIFICA, gate manuali aperti.** Focused e
  Relevant verdi (vedi Verifica). Runtime Windows interattivo, validazione
  APK, runtime fisico Pixel 9 e controllo percettivo dell'indicatore restano
  da eseguire: nessun device collegato né sessione interattiva in questa
  sessione di lavoro.
- **2026-09-07 — Indicatore HUD cambiato da pallini a numero, su richiesta
  del proprietario.** Il disegno iniziale (`TouchAbilityButton`) mostrava
  `max_charges` pallini pieni/vuoti lungo il bordo interno inferiore del
  cerchio. Il proprietario ha chiesto un numero invece, e solo il valore
  corrente (mai il tetto massimo): mostrare "2/4" comunicherebbe
  un'informazione che l'HUD di questo gioco non dà per nessun'altra risorsa
  (il countdown di cooldown, per confronto, non mostra mai il cooldown
  totale). Sostituito `_draw_charge_pips()` con `_draw_charge_count()`:
  disegna solo `_available_charges` come cifra, in basso a destra
  (decentrato rispetto al countdown di cooldown centrale, per non
  sovrapporsi), con una piccola ombra scura per la leggibilità sopra
  un'icona di colore variabile. Stesso guard `max_charges > 1`: nessun
  disegno extra senza la Specialità.

## Documenti sincronizzati

- [ ] `docs/powerup-catalog.md`, se il proprietario vuole registrare qui
      anche le Specialità di Barb (oggi non lo fa esplicitamente per le
      otto esistenti).

## Note

Nome di lavoro provvisorio, non approvato: qualcosa come "Bis alla Griglia"
o "Doppia Cottura" — un pezzo di carne che torna sul fuoco una seconda (o
terza, quarta) volta, in tema con "più cariche = più utilizzi" e coerente
col registro "pezzo di carne" delle Specialità (PS-078). Il nome finale
resta una decisione del proprietario, non di questa card.
