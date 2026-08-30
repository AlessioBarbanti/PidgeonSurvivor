---
id: PS-020
titolo: Diagnostica il fallimento intermittente sul backdrop del selettore
tipo: chore
area: tooling
stato: PRONTO
priorita: bassa
dipende_da: []
origine:
creato: 2026-08-30
aggiornato: 2026-08-30
---

# PS-020 — Diagnostica il fallimento intermittente sul backdrop del selettore

## Contesto

`tests/unit/test_b18b_visual_identity.gd` fallisce in modo intermittente e
non deterministico su un controllo del fondale pixel-art tracciato del
selettore personaggi (contratto B18W in `movement_slice.gd`), con lo stesso
identico worktree fra un'esecuzione e l'altra. Scoperto durante la
migrazione dei test da smoke legacy a GUT; il comportamento intermittente
era già presente nello smoke legacy equivalente. Ipotesi più probabile:
effetto collaterale del restyle asset in corso da parte dell'utente
sull'area proiettili/personaggi (non tracciato da questa card), che può
introdurre una dipendenza da timing o da uno stato di caricamento asset non
ancora completamente deterministico nel test.

## Comportamento atteso

Il test relativo al backdrop pixel-art del selettore produce lo stesso
esito (verde o rosso) a ogni esecuzione, a parità di codice e asset, senza
dipendere dall'ordine di caricamento o da tempistiche non controllate.

## Criteri di accettazione

- [ ] Causa radice dell'intermittenza identificata e documentata in questa
      card (dipendenza da frame non atteso, asset caricato in modo
      asincrono, stato condiviso non resettato, o altro).
- [ ] Il test produce lo stesso esito per almeno 10 esecuzioni consecutive
      in isolamento (`-gtest=` sul solo file).
- [ ] Se la causa è nel test (attesa di frame insufficiente, seed non
      fissato), il test viene reso deterministico senza allargare
      tolleranze per farlo passare artificialmente.
- [ ] Se la causa è nel codice di gioco (es. un ordine di inizializzazione
      non garantito), il problema reale viene descritto qui e, se richiede
      una modifica al codice di gioco, viene aperta una card separata per
      quella modifica.

## Ambito

- `tests/unit/test_b18b_visual_identity.gd` e, se la causa risultasse nel
  codice di gioco, il contratto B18W del fondale pixel-art in
  `scripts/game/movement_slice.gd` (solo diagnosi in questa card; l'eventuale
  fix del codice di gioco va in una card dedicata).

Non modificare come soluzione di comodo:

- non allargare tolleranze numeriche o temporali solo per far passare il
  test senza capire la causa.

## Verifica

- Test: `tests/unit/test_b18b_visual_identity.gd`.
- Profilo minimo prima della chiusura: `Focused` ripetuto più volte per
  confermare la scomparsa dell'intermittenza.

## Gate manuali

- [ ] Runtime Windows: non richiesto per la sola diagnosi.
- [ ] Validazione statica APK: non richiesta.
- [ ] Runtime fisico Pixel 9: non richiesto.
- [ ] Controllo percettivo richiesto: no.

## Decisioni

- **2026-08-30 — Scoperto durante la migrazione GUT, non introdotto da
  essa.** L'intermittenza era già presente nello smoke legacy equivalente
  con lo stesso identico worktree.

## Documenti sincronizzati

- [ ] Nessuno previsto per la sola diagnosi.

## Note

Se al momento di riprendere questa card il restyle asset dell'utente
(proiettili/personaggi) risulta committato, riverificare prima se
l'intermittenza persiste: potrebbe essersi già risolta come effetto
collaterale di quel lavoro.
