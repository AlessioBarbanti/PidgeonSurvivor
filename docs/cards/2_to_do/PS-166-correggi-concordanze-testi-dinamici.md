---
id: PS-166
titolo: Correggi le concordanze nei testi dinamici
tipo: fix
area: ui
stato: PRONTO
priorita: media
dipende_da: [PS-101]
origine: playtest esterno 2026-09-11 — feedback Lollo/Magno
creato: 2026-09-11
aggiornato: 2026-09-11
---

# PS-166 — Correggi le concordanze nei testi dinamici

## Contesto

Il playtest segnala testi al maschile anche quando il nome dinamico è femminile. L'audit del runtime ha individuato due occorrenze reali: la riga PS-101 del Barb Reward (`"<Nome> è tornato tra noi"`) e il riepilogo del ramo vittoria dell'End Screen (`"<Boss> sconfitto in ..."`). Boss Intro e HUD non costruiscono invece concordanze sul genere del personaggio: includerli nella prima stesura avrebbe allargato la card senza un difetto verificato.

## Comportamento atteso

I testi che interpolano il nome di un Friend/Evil devono restare grammaticalmente corretti per tutto il roster. Il copy viene reso neutro quando possibile, senza introdurre un metadato di genere che oggi non serve ad alcun altro sistema.

## Criteri di accettazione

- [ ] La riga di redenzione del Barb Reward è neutra e corretta inserendo almeno un nome maschile e uno femminile; conserva nome del Friend e tono positivo approvato da PS-101.
- [ ] Il riepilogo `EndScreen.show_victory()` non applica una forma maschile fissa al titolo dinamico di un Evil femminile.
- [ ] Le stringhe statiche che si riferiscono al sostantivo generico «Boss» (`1 Boss sconfitto`, conteggi plurali) restano invariate: non dipendono dal genere del personaggio.
- [ ] Boss Intro, HUD, fallback della citazione condivisa e altri copy senza interpolazione problematica non vengono modificati.
- [ ] Nessun genere viene inferito dal nome e non viene aggiunto un campo a `FriendDefinition`: il copy neutro risolve le occorrenze accertate.

## Ambito

- `scripts/ui/barb_reward_overlay.gd` e `scripts/ui/end_screen.gd` per le due stringhe accertate.
- Test PS-101 e PS-053/PS-166 per verificare nomi maschili e femminili.
- Non modificare `FriendDefinition`, citazioni approvate, Boss Intro, HUD o conteggi che parlano del «Boss» generico.

## Verifica

- GUT: `tests/unit/test_ps166_character_copy_agreement.gd` → marker `PS166_CHARACTER_COPY_AGREEMENT_SMOKE_OK`, mantenendo verdi `test_ps101_evil_hunger_narrative.gd` e `test_ps053_run_summary.gd`.
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: sconfiggere almeno un Evil con nome femminile e verificare la riga Barb; il ramo `VICTORY`, oggi non raggiungibile nel gameplay di Sopravvivenza, resta coperto automaticamente)
- [ ] Controllo percettivo richiesto: sì

## Decisioni

- **2026-09-11 — Audit ristretto alle due occorrenze reali.** Si preferisce copy neutro e non si aggiunge un metadato di genere per risolvere due frasi; PS-101 è prerequisito perché possiede il contratto della riga di redenzione.

## Documenti sincronizzati

- [ ] `docs/ui-ux-flow.md` solo se riporta letteralmente uno dei due copy corretti.

## Note

Feedback originario raccolto il 2026-09-11 da trascrizioni audio di playtest esterno. I valori o gli esempi citati nel feedback sono trattati come evidenza percettiva e non come specifica numerica, salvo dove la card lo dichiara esplicitamente.
