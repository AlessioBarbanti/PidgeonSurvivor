---
id: PS-162
titolo: Evita ripetizioni ravvicinate nella selezione dei Boss
tipo: fix
area: gameplay
stato: IN VERIFICA
priorita: media
dipende_da: [PS-127]
origine: playtest esterno 2026-09-11 — feedback Lollo/Magno
creato: 2026-09-11
aggiornato: 2026-09-13
---

# PS-162 — Evita ripetizioni ravvicinate nella selezione dei Boss

## Contesto

In una singola run di playtest sono comparsi più volte gli stessi Evil (tre occorrenze dello stesso profilo e due di un altro), riducendo rapidamente la sensazione di varietà. La selezione corrente estrae un `FriendDefinition` valido in modo uniforme e indipendente per ogni `schedule_index`; con PS-127 il Piccione Malvagio è raro e gli Evil costituiscono la grande maggioranza degli incontri.

## Comportamento atteso

Una run con Boss ricorrenti deve esplorare il roster prima di ripetere frequentemente la stessa identità. La selezione resta deterministica rispetto a seed e schedule, ma tiene conto degli Evil già incontrati nella run.

## Criteri di accettazione

- [x] Quando esistono almeno tre Evil eleggibili, lo stesso Evil non può
      apparire in due incontri consecutivi. Verificato su 8 incontri
      consecutivi con seed fisso: nessuna coppia adiacente uguale.
- [x] Nei primi quattro incontri Evil di una run compaiono almeno tre
      identità diverse, salvo roster eleggibile inferiore. Verificato sia con
      il roster reale (8 profili: i primi 4 incontri sono 4 identità
      distinte) sia con un roster ridotto a 3 profili (i primi 3 incontri
      coprono tutti e 3, quindi ≥3 diverse nei primi 4).
- [x] A parità di seed e sequenza di `schedule_index`, la successione dei
      Boss resta deterministica. Verificato risolvendo due volte lo stesso
      `schedule_index` dopo aver costruito la stessa cronologia: risultato
      identico (idempotenza, non solo determinismo "a freddo").
- [x] Restart e nuova run azzerano la memoria degli incontri; ripetendo lo
      stesso seed si ottiene di nuovo la stessa sequenza iniziale. Verificato
      chiamando `reset_for_run()` dopo aver accumulato cronologia e
      ririsolvendo lo `schedule_index` 0 con lo stesso seed.
- [x] La probabilità del Piccione Malvagio definita da PS-127 non viene
      trasformata in una quota rigida per run. `evil_boss_chance` non toccato;
      la cronologia anti-ripetizione agisce solo DOPO che il tiro
      baseline/Evil ha già deciso "Evil", mai sulla probabilità stessa.
- [x] Non viene introdotta alcuna quota per genere: l'osservazione del
      playtest sulla prevalenza femminile è trattata come campione
      insufficiente, mentre il difetto verificato è la ripetizione delle
      identità. Nessuna quota di genere introdotta: l'esclusione è per
      identità già incontrata, indipendente da qualunque attributo del
      personaggio.

## Ambito

- `scripts/bosses/boss_encounter.gd`: risoluzione della variante e memoria scene-local delle identità già incontrate, azzerata con la run.
- `scripts/game/game_director.gd` solo se serve trasportare stato di scheduling già disponibile.
- `tests/` con sequenze seedate su più ricorrenze.
- Non cambiare Signature, statistiche o probabilità baseline/Evil di PS-127.

## Verifica

- Smoke: `tests/unit/test_ps162_boss_variety_sequence.gd` → marker
  `PS162_BOSS_VARIETY_SEQUENCE_SMOKE_OK`, 4 test: sequenza di 8 incontri sul
  roster reale (nessuna coppia consecutiva uguale, 4 identità distinte nei
  primi 4, tutti e 8 i profili esplorati prima di ripetere), idempotenza a
  parità di `schedule_index`, azzeramento della memoria al restart, roster
  ridotto a 3 profili (invocando `BossEncounter.resolve_variant()` in modo
  statico/puro con una cronologia costruita a mano).
- Focused: 4/4 verdi (`-RefreshEditor`, file nuovo), nessun
  `SCRIPT ERROR`/`FATAL EXCEPTION`.
- Relevant: 16/16 (1 focused + 15 regressione mappate su
  `scripts/bosses/*`), nessun `SCRIPT ERROR`/`FATAL EXCEPTION`.
- Full: 145/145 (144 regressione + toolchain PASS), nessun
  `SCRIPT ERROR`/`FATAL EXCEPTION`.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: run con almeno quattro Evil; annotare ordine delle identità)
- [ ] Controllo percettivo richiesto: sì

## Decisioni

- **2026-09-11 — Si corregge la ripetizione ravvicinata, non si impone una distribuzione uomo/donna sulla base di una sola run.**
- **2026-09-11 — La selezione deve restare seed-deterministica per non rompere il contratto dei test di run.**
- **2026-09-13 — Meccanismo scelto: finestra di esclusione scorrevole
  `min(profili_eleggibili - 1, cronologia_disponibile)`, non un semplice
  "escludi l'ultimo".** Escludere solo l'ultimo incontro basterebbe per il
  primo criterio (mai due consecutivi) ma non garantirebbe da solo "almeno
  tre identità diverse nei primi quattro incontri" in modo affidabile (un
  'escludi solo l'ultimo' permette comunque A,B,A,B). Con la finestra
  scalata, il roster viene esplorato per intero (nessuna ripetizione)
  prima che una identità possa ricomparire: con 8 profili gli 8 incontri
  successivi sono garantiti tutti distinti, non solo i primi 4.
- **2026-09-13 — Cronologia indicizzata per `schedule_index`
  (`Dictionary[int, StringName]`), non un semplice array in ordine di
  chiamata.** `resolve_definition_for_event` deve restare idempotente se
  richiamato due volte per lo stesso indice (già garantito dal contratto
  esistente in `test_b22_evil_boss_variants.gd`): l'esclusione per l'indice N
  guarda solo gli indici già registrati `< N`, mai l'esito che si sta
  calcolando nella chiamata corrente. Un array "in ordine di chiamata"
  avrebbe rischiato di contare due volte la stessa risoluzione o di variare
  in base a quante volte un chiamante ha richiesto lo stesso indice.
- **2026-09-13 — `resolve_variant()` resta una funzione statica pura**, con
  la cronologia passata come parametro (`recent_evil_profile_ids`, default
  vuoto) invece di leggere stato d'istanza: preserva la testabilità diretta
  già sfruttata da `test_b22_evil_boss_variants.gd` e permette al nuovo test
  di validare il caso limite "roster di 3" senza dover simulare
  un'istanza `BossEncounter` completa.
- **2026-09-13 — Verificato che i test esistenti non venissero contaminati.**
  `test_b22_evil_boss_variants.gd` chiama ripetutamente
  `resolve_definition_for_event` con `schedule_index=0` fisso su centinaia di
  seed diversi (per misurare la distribuzione, non una sequenza di
  ricorrenze reali): con la cronologia ancorata a "indici < N", `schedule_index=0`
  non ha mai storia precedente da escludere, quindi quel test resta
  bit-per-bit invariato. Confermato dall'esecuzione verde immutata di quel
  file nella Relevant/Full di questa card.

## Documenti sincronizzati

- [x] `docs/enemies-bosses.md`: aggiunta la sezione "Varietà delle identità
      Evil (PS-162)" sotto "Baseline vs `Evil <Nome>`".
- [ ] `docs/systems-difficulty.md`: nessuna policy di selezione Boss descritta
      lì (solo un riferimento incidentale a `resolve_variant()` in una nota
      PS-126 su cosa NON tocca), nulla da aggiornare.
- [ ] Nota `*-verification.md`, se viene salvata una sequenza seedata di evidenza.

## Note

Feedback originario raccolto il 2026-09-11 da trascrizioni audio di playtest esterno. I valori o gli esempi citati nel feedback sono trattati come evidenza percettiva e non come specifica numerica, salvo dove la card lo dichiara esplicitamente.
