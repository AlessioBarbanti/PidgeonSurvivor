---
id: PS-094
titolo: Introduci una Specialità di Barb per cariche multiple dell'abilità attiva
tipo: feat
area: gameplay
stato: PRONTO
priorita: media
dipende_da: []
origine: conversazione del proprietario 2026-09-04
creato: 2026-09-04
aggiornato: 2026-09-04
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

- [ ] `AbilityController` guadagna un modello a cariche multiple:
      `_available_charges: int`, `_max_charges: int` (default `1`, il
      comportamento odierno), un timer di ricarica indipendente per carica
      mancante. `try_activate()` consuma una carica invece di richiedere
      `_cooldown_remaining <= 0.0`; quando `_available_charges < _max_charges`
      il timer di ricarica avanza e restituisce una carica al termine,
      ripetendo finché non si raggiunge `_max_charges`.
- [ ] Il comportamento odierno (`_max_charges = 1`, un solo utilizzo poi
      cooldown pieno) resta identico bit-per-bit quando questa Specialità
      non è equipaggiata: nessuna regressione sul modello a cooldown singolo
      per chi non la sblocca.
- [ ] I segnali pubblici (`cooldown_changed`, `readiness_changed`) restano
      coerenti col nuovo modello (es. `readiness_changed` riflette
      `_available_charges > 0`) oppure vengono affiancati da un nuovo
      segnale dedicato alle cariche (es. `charges_changed(available: int,
      max_charges: int)`) se il significato dei segnali esistenti non basta
      a rappresentare "più cariche disponibili".
- [ ] L'HUD (`scripts/ui/hud.gd`, consumatore odierno dei due segnali) mostra
      le cariche disponibili in modo leggibile (es. indicatori/pallini oltre
      al riempimento radiale di cooldown) quando `_max_charges > 1`; senza
      questa Specialità l'aspetto dell'HUD resta identico a oggi.
- [ ] Nuova `UpgradeDefinition` in `data/upgrades/specialities/` con
      `is_speciality = true`, `max_rank = 5`, `repeatable = false` (la
      progressione è una sequenza fissa di 5 passi distinti, non un effetto
      che si ripete all'infinito).
- [ ] I cinque ranghi sono dati (array indicizzati per rango in
      `effect_parameters`, es. `charges_by_rank`/
      `cooldown_multiplier_by_rank`), letti da un nuovo handler generico nel
      registro (`UpgradeEffectRegistry`), non da valori incisi nello script:
      stesso principio già dichiarato in `CLAUDE.md` ("i dati dichiarano
      `effect_id` + parametri; la logica vive nel registro").
- [ ] `effect_id`/`effect_parameters`/`weight`/`max_rank` di ogni altra carta
      del catalogo (ordinario o Specialità) restano bit-per-bit identici:
      questa card aggiunge una nona Specialità, non modifica le otto
      esistenti.
- [ ] Icona e titolo definitivo **non** sono prodotti da questa card (PS-090):
      il titolo di lavoro resta un placeholder testuale coerente col registro
      "pezzo di carne" già stabilito da [PS-078](../3_in_sprint/PS-078-tematizza-catalogo-specialita-barb.md)
      (es. "Bis alla Griglia" o simile, da confermare col proprietario), e la
      generazione dell'icona è materia di una card `tipo: art` collegata,
      aperta all'handoff di questa.
- [ ] [PS-078](../3_in_sprint/PS-078-tematizza-catalogo-specialita-barb.md),
      se non ancora `COMPLETATO`/`IN VERIFICA` quando questa card viene presa
      in carico, viene aggiornata da "otto Specialità" a "nove Specialità"
      per includere anche questa; se PS-078 è già chiusa, questa card apre
      la propria tematizzazione (nome + icona) come parte del proprio
      handoff invece di riaprire PS-078.

## Ambito

- `scripts/abilities/ability_controller.gd`: modello a cariche multiple,
  timer di ricarica per carica, segnali.
- `scripts/ui/hud.gd`: visualizzazione delle cariche disponibili.
- `scripts/progression/upgrade_effect_registry.gd`: nuovo handler per
  l'effetto a cariche, letto da `effect_parameters` per rango.
- `data/upgrades/specialities/`: nuova `UpgradeDefinition`.
- `docs/powerup-catalog.md` o documento equivalente per le Specialità, se il
  proprietario vuole registrare qui la nuova carta.

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
  sono possibili 4 attivazioni consecutive senza attesa; restart e cambio
  personaggio azzerano le cariche accumulate.
- Profilo minimo prima della chiusura: `Relevant`.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9: sblocca la Specialità, verifica che il tap
      ripetuto sul pulsante abilità consumi le cariche in sequenza e che
      l'indicatore di cariche resti leggibile a dimensione reale
- [ ] Controllo percettivo richiesto: sì — l'indicatore di cariche multiple
      è un elemento HUD nuovo, deve restare leggibile e non confondersi col
      riempimento di cooldown esistente

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
