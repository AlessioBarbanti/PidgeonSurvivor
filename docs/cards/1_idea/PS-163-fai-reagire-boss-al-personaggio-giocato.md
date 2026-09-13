---
id: PS-163
titolo: Fai reagire il Boss al personaggio giocato
tipo: feat
area: gameplay
stato: DA DEFINIRE
priorita: bassa
dipende_da: []
origine: playtest esterno 2026-09-11 — feedback Lollo/Magno
creato: 2026-09-11
aggiornato: 2026-09-11
---

# PS-163 — Fai reagire il Boss al personaggio giocato

## Contesto

Il playtest propone che il Boss «reagisca» al personaggio attivo. Il runtime corrente assegna già a ogni Evil una Signature identitaria e scala la pressione per ricorrenza, ma non contiene una matrice personaggio↔Boss né legge il personaggio giocato durante `resolve_variant()`.

La richiesta non chiarisce però se la reazione debba essere meccanica, narrativa o soltanto presentazionale. La prima stesura consentiva indifferentemente pattern, priorità o modificatori: un implementatore avrebbe potuto soddisfarla con soluzioni incompatibili fra loro. La card non è quindi pronta per l'esecuzione.

## Domande da porre al proprietario (per uscire da DA DEFINIRE)

1. «Reagire» significa cambiare il combattimento (pattern/targeting/parametri), mostrare un testo dedicato nella Boss Intro, oppure entrambe le cose?
2. Se è meccanico, si vuole una regola per ruoli/archetipi o una matrice specifica per tutte le combinazioni degli otto personaggi e degli otto Evil?
3. La reazione deve compensare punti di forza/debolezza del Player, creare matchup deliberati o limitarsi a variare l'incontro senza alterarne la difficoltà media?
4. Quale confronto minimo deve essere approvato prima di estendere la regola all'intero roster?

## Vincoli già accertati

- La Signature dell'Evil deve restare riconoscibile e non essere sostituita.
- Ogni eventuale variazione meccanica deve restare deterministica a parità di personaggio, seed e `schedule_index`.
- La regola risultante deve vivere nei dati/cataloghi o in un'autorità scene-local, non in eccezioni sparse nella UI.
- PS-162 riguarda la varietà della sequenza Boss e non è un prerequisito funzionale di questa decisione.

## Ambito

- Nessuna implementazione finché il proprietario non sceglie la natura della reazione.
- Dopo la decisione, rifinire Comportamento atteso, criteri, dati coinvolti e verifica senza modificare la policy di varietà di PS-162 o la crescita di PS-126.

## Verifica

- Da definire dopo la scelta meccanica/narrativa. Se cambia il runtime, servirà un GUT `tests/unit/test_ps163_*.gd` e profilo minimo `Relevant`.

## Decisioni

- **2026-09-11 — Riclassificata `DA DEFINIRE`.** Il feedback non prescrive quale leva usare e la prima stesura non fissava un risultato osservabile univoco.
- **2026-09-11 — Rimossa la falsa dipendenza da PS-162.** Varietà della sequenza e reazione al Player possono condividere un file, ma nessuna delle due definisce semanticamente l'altra.

## Documenti sincronizzati

- [ ] Da stabilire dopo la decisione; probabili `docs/enemies-bosses.md` e `docs/characters.md` per una soluzione meccanica, `docs/ui-ux-flow.md` per una soluzione solo narrativa.

## Note

Feedback originario raccolto il 2026-09-11 da trascrizioni audio di playtest esterno. I valori o gli esempi citati nel feedback sono trattati come evidenza percettiva e non come specifica numerica, salvo dove la card lo dichiara esplicitamente.
