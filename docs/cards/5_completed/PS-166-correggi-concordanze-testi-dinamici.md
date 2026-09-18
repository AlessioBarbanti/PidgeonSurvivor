---
id: PS-166
titolo: Correggi le concordanze nei testi dinamici
tipo: fix
area: ui
stato: COMPLETATO
priorita: media
dipende_da: [PS-101]
origine: playtest esterno 2026-09-11 — feedback Lollo/Magno
creato: 2026-09-11
aggiornato: 2026-09-19
---

# PS-166 — Correggi le concordanze nei testi dinamici

## Contesto

Il playtest segnala testi al maschile anche quando il nome dinamico è femminile. L'audit del runtime ha individuato due occorrenze reali: la riga PS-101 del Barb Reward (`"<Nome> è tornato tra noi"`) e il riepilogo del ramo vittoria dell'End Screen (`"<Boss> sconfitto in ..."`). Boss Intro e HUD non costruiscono invece concordanze sul genere del personaggio: includerli nella prima stesura avrebbe allargato la card senza un difetto verificato.

## Comportamento atteso

I testi che interpolano il nome di un Friend/Evil devono restare grammaticalmente corretti per tutto il roster. Il copy viene reso neutro quando possibile, senza introdurre un metadato di genere che oggi non serve ad alcun altro sistema.

## Criteri di accettazione

- [x] La riga di redenzione del Barb Reward è neutra e corretta inserendo
      almeno un nome maschile e uno femminile; conserva nome del Friend e
      tono positivo approvato da PS-101. `"<Nome> è tornato tra noi"` →
      `"<Nome> è di nuovo tra noi, grazie a Barb!"` (nessun participio
      concordato al genere). Verificato con "Magno" e "Marghe".
- [x] Il riepilogo `EndScreen.show_victory()` non applica una forma maschile
      fissa al titolo dinamico di un Evil femminile.
      `"<Titolo> sconfitto in <tempo>"` → `"Hai sconfitto <Titolo> in
      <tempo>"`: con l'ausiliare "avere" il participio non concorda con
      l'oggetto, resta invariato per qualunque genere. Verificato con
      "Piccione Malvagio", "Evil Magno", "Evil Marghe".
- [x] Le stringhe statiche che si riferiscono al sostantivo generico «Boss»
      (`1 Boss sconfitto`, conteggi plurali) restano invariate: non
      dipendono dal genere del personaggio. `_format_boss_count()` non
      toccato, verificato esplicitamente nel nuovo test.
- [x] Boss Intro, HUD, fallback della citazione condivisa e altri copy senza
      interpolazione problematica non vengono modificati. Nessun altro file
      toccato.
- [x] Nessun genere viene inferito dal nome e non viene aggiunto un campo a
      `FriendDefinition`: il copy neutro risolve le occorrenze accertate.
      Nessuna modifica a `FriendDefinition` o ad altri dati di personaggio.

## Ambito

- `scripts/ui/barb_reward_overlay.gd` e `scripts/ui/end_screen.gd` per le due stringhe accertate.
- Test PS-101 e PS-053/PS-166 per verificare nomi maschili e femminili.
- Non modificare `FriendDefinition`, citazioni approvate, Boss Intro, HUD o conteggi che parlano del «Boss» generico.

## Verifica

- GUT: `tests/unit/test_ps166_character_copy_agreement.gd` → marker
  `PS166_CHARACTER_COPY_AGREEMENT_SMOKE_OK`, 3 test: riga di redenzione con
  nome maschile e femminile, riepilogo di vittoria con titolo neutro/
  maschile/femminile, conteggio generico «Boss» invariato.
  `test_ps101_evil_hunger_narrative.gd` e `test_ps053_run_summary.gd`
  restano verdi (verificato in Relevant).
- Focused: 3/3 verdi (`-RefreshEditor`, file nuovo), nessun
  `SCRIPT ERROR`/`FATAL EXCEPTION`.
- Relevant: 37/37 (1 focused + 36 regressione mappate su `scripts/ui/*`),
  nessun `SCRIPT ERROR`/`FATAL EXCEPTION`. `Full` non eseguito: modifica di
  sole due stringhe letterali, nessuna logica condivisa toccata.

## Gate manuali

- [x] Runtime Windows
- [x] Validazione statica APK
- [x] Runtime fisico Pixel 9 (percorso: sconfiggere almeno un Evil con nome femminile e verificare la riga Barb; il ramo `VICTORY`, oggi non raggiungibile nel gameplay di Sopravvivenza, resta coperto automaticamente)
- [x] Controllo percettivo richiesto: sì

## Decisioni

- **2026-09-11 — Audit ristretto alle due occorrenze reali.** Si preferisce copy neutro e non si aggiunge un metadato di genere per risolvere due frasi; PS-101 è prerequisito perché possiede il contratto della riga di redenzione.
- **2026-09-13 — Riformulazioni scelte per restare il più vicino possibile al
  copy approvato da PS-101/PS-053, non per introdurre un tono nuovo.**
  "è tornato" → "è di nuovo" (avverbio, nessuna concordanza) mantiene identico
  il significato e il calore verso Barb. "`<Titolo>` sconfitto" →
  "Hai sconfitto `<Titolo>`" sposta il soggetto grammaticale dal Boss (la cui
  concordanza dipende dal suo genere) al giocatore stesso ("hai", invariante):
  con l'ausiliare "avere" e un oggetto diretto pieno dopo il verbo, il
  participio passato in italiano non concorda in genere/numero, quindi resta
  corretto per qualunque titolo.
- **2026-09-13 — Trovata e corretta una terza occorrenza letterale del vecchio
  copy in `docs/enemies-bosses.md`** (non elencata nell'ambito originale, che
  citava solo `docs/ui-ux-flow.md`): la sezione sulla redenzione degli Evil
  riportava la frase testuale pre-fix. Aggiornata per restare sincronizzata
  col codice.
- 2026-09-19: chiusa dal proprietario con il passaggio in blocco di tutte le card `IN VERIFICA` a `COMPLETATO`.

## Documenti sincronizzati

- [x] `docs/enemies-bosses.md`: aggiornata la citazione letterale della riga
      di redenzione nella sezione "Alla morte di un `Evil <Nome>`...".
- [x] `docs/ui-ux-flow.md`: nessuna citazione letterale dei due copy trovata,
      nulla da aggiornare.

## Note

Feedback originario raccolto il 2026-09-11 da trascrizioni audio di playtest esterno. I valori o gli esempi citati nel feedback sono trattati come evidenza percettiva e non come specifica numerica, salvo dove la card lo dichiara esplicitamente.
