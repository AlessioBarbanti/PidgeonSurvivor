---
id: PS-127
titolo: Rendi il Piccione Malvagio un boss raro e più difficile di ogni Evil
tipo: feat
area: gameplay
stato: IN VERIFICA
priorita: alta
dipende_da: []
origine:
creato: 2026-09-07
aggiornato: 2026-09-07
---

# PS-127 — Rendi il Piccione Malvagio un boss raro e più difficile di ogni Evil

## Contesto

Durante la sessione di raccolta telemetria su Pixel 9 per validare
[PS-126](../4_to_test/PS-126-nessuna-scala-difficolta-oltre-5-minuti.md), il
proprietario ha giocato oltre gli 11 minuti e riportato che il secondo Boss
(la prima ricorrenza, avvenuta a `t≈361s`) è risultato **più facile** del
primo, nonostante `BossEncounter._apply_recurrence_scaling` avesse applicato
un moltiplicatore di `2.2×` a HP e danno (`schedule_index=1`,
`boss_recurrence_growth_per_occurrence=1.2`), confermato esatto dalla
telemetria stessa.

La causa non era un difetto di PS-126: `BossEncounter.evil_boss_chance = 0.5`
([boss_encounter.gd:22](../../../scripts/bosses/boss_encounter.gd#L22)) fa
estrarre indipendentemente a ogni soglia — comprese le ricorrenze — se il
Boss è il **Piccione Malvagio** (baseline: ciclo di 2 pattern, nessuna
Signature) o un **Evil \<Nome\>** (ciclo di 3 pattern, gli stessi due più una
Signature). Anche pesantemente scalato in HP/danno da PS-126, il baseline
resta strutturalmente più povero di contenuto di un Evil alla stessa soglia.

Invece di limitarsi a colmare il divario per parità, il proprietario ha
deciso di ribaltarlo: il Piccione Malvagio diventa un incontro **raro**
(~10% invece del 50% attuale) e **deliberatamente più duro** di qualunque
Evil, così il confronto "baseline vs Evil" smette di essere il problema.

## Comportamento atteso

Quando il baseline viene estratto (raramente, ~1 volta su 10, a qualunque
soglia Boss inclusa la prima), il giocatore deve percepirlo come il Boss più
pericoloso della run — non più come la variante "leggera". Gli otto Evil
restano esattamente come sono oggi: pattern, Signature, cadenza e identità
visiva non cambiano.

## Criteri di accettazione

- [x] `BossEncounter.evil_boss_chance` passa da `0.5` a un valore intorno a
      `0.10` (10% baseline / 90% Evil), applicato a ogni soglia Boss inclusa
      la prima (`schedule_index = 0`), non solo alle ricorrenze.
- [x] Il baseline (nessuna Signature, `is_evil_variant() == false`) cicla su
      tre pattern invece di due: Raffica Radiale, Area Mirata, e il nuovo
      pattern **Scia di Piume** — senza aggiungere nulla al ciclo a tre già
      esistente degli Evil (Raffica Radiale, Area Mirata, Signature), che
      resta invariato.
- [x] Scia di Piume: un ventaglio di 6-7 linee oblique (mai allineate agli
      assi dell'arena) attraversa il campo, tutte telegrafate insieme (linee
      disegnate in anticipo, durata coerente con gli altri telegraph del
      Boss) e poi eseguite insieme come una sequenza continua di circa 20
      "battiti" (una piuma per linea per battito) lanciati in rapida
      successione, riusando `BossProjectile` (lo stesso oggetto già
      condiviso con `RangedEnemy`) invece di un nuovo tipo di proiettile.
- [x] Il cooldown fra i pattern del baseline (equivalente a `pattern_interval`)
      è più basso di quello ereditato dagli Evil, così il baseline attacca
      più spesso a parità di soglia — il valore letto dagli Evil resta quello
      attuale.
- [x] A metà vita (50% HP residua), il baseline "si sdoppia" **una sola
      volta** per incontro, raddoppiando di fatto la quantità di attacchi
      "normali" (Raffica Radiale, Area Mirata, Scia di Piume) subiti dal
      giocatore nella seconda metà dell'incontro — via specchio a doppio
      attacco (vedi Decisioni), non due istanze reali indipendenti.
- [x] Gli otto Evil non ricevono nessuna delle modifiche sopra (terzo pattern
      aggiuntivo, cooldown ridotto, split a metà vita): il loro contratto
      resta quello descritto in `docs/enemies-bosses.md`.
- [x] Il moltiplicatore di ricorrenza di PS-126
      (`GameDirectorProfile.get_boss_recurrence_multiplier`) continua ad
      applicarsi sopra queste modifiche senza alcun tetto o eccezione
      dedicata per il baseline: un baseline estratto a una ricorrenza tarda
      può risultare molto più duro di un Evil alla stessa soglia, ed è il
      risultato voluto (nessun codice tocca la composizione dei due
      moltiplicatori).

## Ambito

- `scripts/bosses/boss_encounter.gd`: `evil_boss_chance` da `0.5` a `~0.10`.
- `scripts/bosses/first_boss.gd`: nuovo pattern Scia di Piume (telegraph +
  esecuzione), branch del ciclo pattern e del cooldown per
  `not is_evil_variant()`, meccanica di split a metà vita HP.
- `scripts/bosses/boss_definition.gd` / `data/bosses/first_boss.tres`: nuovi
  campi dati per Scia di Piume (numero di piume, intervallo di lancio,
  danno, geometria della linea), per il cooldown baseline ridotto e per la
  soglia/geometria dello specchio a doppio attacco.
- `scripts/game/movement_slice.gd`: il contratto runtime
  `_validate_current_contract()` che verificava `evil_boss_chance = 0.5`
  (PS-037) ora verifica `0.9` (PS-127).
- `tests/unit/test_ps127_piccione_malvagio_hard_rare.gd` (nuovo) e
  `tools/milestone-test-map.json` (registrazione).

Non toccare in ogni caso:

- il meccanismo di scaling per ricorrenza introdotto da PS-126
  (`GameDirectorProfile.get_boss_recurrence_multiplier`,
  `BossEncounter._apply_recurrence_scaling`) — questa card lo lascia intatto
  e si compone sopra di esso;
- l'identità visiva, i pattern e la Signature esistenti degli otto Evil;
- il ritratto del Piccione Malvagio (oggetto di
  [PS-128](../5_completed/PS-128-genera-ritratto-definitivo-piccione-malvagio.md), card
  indipendente).

## Verifica

- Nuovo test GUT deterministico, es.
  `tests/unit/test_ps127_piccione_malvagio_hard_rare.gd`: verifica il ciclo a
  3 pattern del baseline (incluso Scia di Piume), il cooldown ridotto
  rispetto a un Evil a parità di soglia, lo split a metà vita (una sola
  volta, entrambe le istanze vive e attive) e che
  `BossEncounter.resolve_variant` risolva il baseline in una frazione vicina
  al 10% su un campione seedato ampio.
- Profilo minimo prima della chiusura: `Full` (la card tocca il ciclo di
  pattern condiviso e l'estrazione baseline/Evil, superficie ampia).
- **Eseguito**: `Full` verde — `focused=1/1`, `regression=123/123`,
  `toolchain=1/1`, nessun `SCRIPT ERROR`/`FATAL EXCEPTION` nei log. Include
  il fix adiacente PS-101 (vedi Decisioni), necessario perché senza di esso
  `test_b15_boss_encounter.gd` falliva quasi sempre col nuovo
  `evil_boss_chance = 0.9`. Ripetuto (`Full` ancora `123/123` + `1/1`, log
  puliti) dopo la correzione della geometria della Scia di Piume da linea
  singola a ventaglio.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9: forzare `evil_boss_chance = 0` per validare
      Scia di Piume, cooldown e split; poi ripristinare `~0.10` per
      confermare la rarità percepita
- [ ] Controllo percettivo richiesto: sì — leggibilità della Scia di Piume
      (telegraph e sequenza di piume), chiarezza dello split a metà vita, e
      percezione di "boss più duro del gioco" quando viene estratto

## Decisioni

- **2026-09-07 — Aperta da un'osservazione diretta del proprietario** durante
  una run reale, non da un'analisi statica: il secondo Boss "è stato più
  semplice" del primo. La telemetria di sessione ha confermato che il
  moltiplicatore numerico di PS-126 era applicato correttamente, isolando la
  causa nel divario strutturale baseline/Evil descritto sopra.
- **2026-09-07 — Decisione del proprietario** (sostituisce le quattro
  direzioni alternative elencate all'apertura): le idee proposte in
  brainstorming non sono alternative ma vanno implementate **tutte assieme**
  sul baseline — più frequenza d'attacco, nuovo pattern Scia di Piume (linee
  telegrafate attraversate da ~20 piume consecutive, stile Tiratore), split a
  metà vita che raddoppia gli attacchi normali. In cambio `evil_boss_chance`
  scende da `0.5` a `~0.10`, applicata a ogni soglia Boss inclusa la prima —
  non solo alle ricorrenze.
- **2026-09-07 — Corretta la geometria della Scia di Piume dopo la prima
  implementazione.** Prima versione: una sola linea verso il Player, come
  un'Area Mirata "a distanza". Il proprietario ha corretto: voleva un
  ventaglio di 6-7 linee oblique rispetto all'arena (non una sola linea
  puntata), tutte telegrafate e sparate insieme (non in sequenza, per non
  allungare il turno del Boss oltre un solo slot del ciclo pattern).
  Implementato come `feather_line_count = 6` linee, ciascuna una coppia di
  raggi opposti con orientamento seedato (run + soglia + utilizzo) così non
  è mai la stessa due volte ma resta deterministica a parità di seed.
- **2026-09-07 — Compounding con PS-126 accettato come intenzionale**: se il
  baseline (10% di probabilità) viene estratto a una ricorrenza tarda, il
  moltiplicatore di ricorrenza si somma alle modifiche sopra senza alcun
  tetto dedicato. Il proprietario ha confermato esplicitamente che un picco
  di difficoltà molto alto in quel caso è voluto, non un difetto da
  correggere.
- **Collegata**: [PS-128](../5_completed/PS-128-genera-ritratto-definitivo-piccione-malvagio.md)
  (ritratto) resta indipendente, come già stabilito all'apertura.
- **2026-09-07 — Lo split è uno specchio a doppio attacco, non due entità
  reali.** Confermato esplicitamente dal proprietario dopo aver confrontato
  due opzioni: (1) un solo `FirstBoss`, un solo `HealthComponent`, che da
  metà vita ripete ogni pattern normale anche da una seconda origine
  "fantasma" orbitante (raddoppia la densità di proiettili/aree, non gli HP
  totali); (2) un secondo `FirstBoss` reale e indipendente da abbattere
  separatamente. La (1) è stata scelta perché non tocca l'invariante "un
  solo Boss attivo" assunta da `BossEncounter`/`GameDirector` e da una decina
  di test esistenti (es. `test_b22_evil_boss_variants.gd`), e non raddoppia
  l'HP effettivo dell'incontro — solo la pressione degli attacchi, come
  richiesto dal criterio.
- **2026-09-07 — Fix adiacente necessario per la suite di regressione**:
  `BossEncounter.resolve_variant()` forzava `quote_approved = false` su ogni
  Evil (residuo di BOSS-001, prima che PS-101 approvasse la citazione
  condivisa). Con `evil_boss_chance` al 90% invece del 50%, il seed fisso di
  `tests/unit/test_b15_boss_encounter.gd` estrae ora quasi sempre un Evil,
  rendendo sistematico un fallimento che prima si manifestava solo su alcuni
  seed. Rimossa la riga: il contratto PS-101 (citazione condivisa e
  approvata fra baseline ed Evil) era già documentato e testato tramite un
  duplicato costruito a mano, ma non dal percorso di produzione reale. Non è
  un ampliamento dell'ambito di questa card, è la condizione per lasciare
  verde la suite che questa card stessa esercita molto più spesso.

## Documenti sincronizzati

- [x] `docs/enemies-bosses.md`: il baseline non è più "più leggero" degli
      Evil, cambiano numero di pattern, cooldown, specchio a doppio attacco e
      `evil_boss_chance`.
- [x] `docs/systems-difficulty.md`: la sezione `pressure_multiplier` di
      PS-126 menziona ora anche il danno della Scia di Piume.

## Note

Nessuno smoke esistente copre questa card. La scoperta iniziale è emersa da
una sessione di telemetria manuale (marker `PS_BALANCE_TELEMETRY`,
temporaneo e non committato in `scripts/game/movement_slice.gd`);
l'implementazione risultante da questa card, però, è guidata da una
decisione esplicita del proprietario, non più da un'osservazione da
confermare.
