---
id: PS-055
titolo: Decidere la filosofia della vittoria fra Survival e Difesa Grigliata
tipo: chore
area: gameplay
stato: DA DEFINIRE
priorita: media
dipende_da: []
origine:
creato: 2026-08-31
aggiornato: 2026-08-31
---

# PS-055 — Decidere la filosofia della vittoria fra Survival e Difesa Grigliata

## Contesto

Il `RunController` dichiara uno stato `VICTORY`
([scripts/game/run_controller.gd:14](../../../scripts/game/run_controller.gd#L14)),
ma la modalità Survival è realmente endless e da PS-033 la morte di un Boss non
chiude più la run: lo stato resta dormiente, come registrato in
[ui-ux-flow.md](../../ui-ux-flow.md).

Finché la domanda non ha una risposta esplicita, la schermata terminale, il
riepilogo finale di [PS-053](../5_completed/PS-053-riepilogo-finale-della-run.md), i
record e la futura Difesa Grigliata restano ambigui: non si sa
se Survival possa essere "vinta" o solo sopravvissuta.

## Domanda aperta per il proprietario

**Survival deve poter essere vinta, o resta una caccia al record senza fine?**

La review consiglia esplicitamente: tenere Survival come caccia al record e
riservare una vittoria formale alla Difesa Grigliata. Le opzioni sono:

1. **Survival endless, vittoria solo in Difesa Grigliata** (raccomandata dalla
   review). `VICTORY` resta dormiente in Survival; Survival si chiude solo con
   `DEFEAT` e il valore della run è il record.
2. **Survival con una condizione di vittoria** (per esempio una soglia di tempo
   o un numero di Boss). `VICTORY` si attiva anche in Survival e il gioco deve
   dichiarare quale traguardo la determina.
3. **`VICTORY` rimosso finché non serve.** Lo stato viene eliminato dalla
   macchina e reintrodotto quando Difesa Grigliata lo richiederà davvero.

Serve una risposta del proprietario prima che questa card diventi `PRONTO`.

## Comportamento atteso

Una volta scelta l'opzione, il contratto viene scritto una sola volta nel
documento durevole pertinente e il runtime vi si allinea: nessuno stato
dichiarato ma irraggiungibile, nessuna schermata che promette una vittoria che
non può accadere.

## Criteri di accettazione

- [ ] La filosofia della vittoria è dichiarata esplicitamente in
      `docs/ui-ux-flow.md` e, se è un contratto di prodotto, in `docs/prd.md`.
- [ ] Lo stato `VICTORY` è coerente con la decisione: raggiungibile e
      documentato, oppure esplicitamente dichiarato dormiente con la modalità
      che lo attiverà.
- [ ] Nessuna schermata terminale annuncia una vittoria che la modalità
      corrente non può produrre.
- [ ] Se la scelta introduce una condizione di vittoria, esiste uno smoke
      deterministico che la raggiunge.
- [ ] La decisione è registrata in questa card con data e motivazione.

## Ambito

- `docs/ui-ux-flow.md`, `docs/prd.md`.
- `scripts/game/run_controller.gd`, solo se la decisione cambia la macchina a
  stati.
- `scripts/ui/end_screen.gd`, solo per la copia della schermata terminale.

Non toccare:

- il bilanciamento e la curva di difficoltà;
- l'implementazione della Difesa Grigliata, che questa card non avvia;
- l'autorità del `RunController` su vittoria e sconfitta.

## Verifica

- Smoke: da definire con la decisione. Se viene introdotta una condizione di
  vittoria, `tests/unit/test_ps055_victory_philosophy.gd` → marker
  `VICTORY_PHILOSOPHY_SMOKE_OK`.
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 — pertinente solo se la decisione tocca il
      runtime.
- [ ] Controllo percettivo richiesto: no

## Decisioni

- **2026-08-31 — Card aperta come `DA DEFINIRE`.** Manca una scelta del
  proprietario, non un'implementazione: la domanda è nella sezione dedicata.
- **Raccomandazione della review, non ancora decisione:** Survival come caccia
  al record, vittoria formale riservata a Difesa Grigliata.

## Documenti sincronizzati

- [ ] `docs/ui-ux-flow.md`.
- [ ] `docs/prd.md`, se la vittoria diventa un contratto di prodotto.

## Note

La review raccomanda anche di non aggiungere altri sistemi di pressione prima
dei playtest reali di PS-007 e PS-008: la struttura già comprende archetipi,
eventi, Boss ricorrenti e Specialità di Barb. Quella verifica di ritmo non è
oggetto di questa card, ma ne condiziona il momento giusto.
