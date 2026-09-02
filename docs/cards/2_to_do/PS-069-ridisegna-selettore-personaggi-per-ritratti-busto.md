---
id: PS-069
titolo: Ridisegnare il selettore personaggi per ospitare i ritratti busto
tipo: ux
area: ui
stato: PRONTO
priorita: media
dipende_da: [PS-068]
origine:
creato: 2026-09-02
aggiornato: 2026-09-03
---

# PS-069 — Ridisegnare il selettore personaggi per ospitare i ritratti busto

## Contesto

[PS-068](../4_to_test/PS-068-genera-ritratti-busto-cast-giocabile.md) produce un ritratto
busto definitivo per ciascuno degli otto Friend, analogo ai ritratti Evil già
usati nella Boss intro. Il selettore personaggi attuale
(`scenes/ui/character_select_overlay.tscn`,
`scripts/ui/character_select_overlay.gd`) mostra solo `selection_portrait`,
l'arte a figura intera del carosello: non esiste oggi alcun punto della UI che
mostri il busto ravvicinato di un Friend, a differenza della Boss intro che lo
fa già per gli Evil.

[PS-054](./PS-054-presenza-del-personaggio-nel-selettore.md), ancora aperta,
adatta il layout esistente al 20:9 riusando solo asset già presenti e esclude
esplicitamente nuovi asset grafici. Questa card ha uno scopo diverso e più
ampio: integrare un nuovo asset e, se utile, ripensare la composizione della
schermata per dargli spazio. Le due card toccano lo stesso albero di scena;
vanno coordinate in fase di pianificazione dello sprint per evitare rilavoro,
ma nessuna delle due blocca formalmente l'altra.

## Comportamento atteso

La schermata di selezione personaggio espone in modo evidente il ritratto
busto del Friend, oltre (o al posto di) l'arte a figura intera attuale, con un
layout — evoluto dall'attuale o ridisegnato da zero — pensato per dargli
risalto senza perdere le informazioni oggi disponibili (nome, ruolo, passiva,
abilità attiva, anteprime laterali, navigazione del carosello).

## Criteri di accettazione

- [ ] Il ritratto busto del Friend selezionato è visibile nella schermata di
      selezione, in una posizione con presenza visiva paragonabile a quella
      del busto Evil nella Boss intro.
- [ ] Il cambio di personaggio nel carosello aggiorna il busto mostrato in
      sincronia con le altre informazioni del pannello.
- [ ] Nome, ruolo, passiva e abilità attiva restano leggibili per tutti e otto
      i personaggi, senza troncamenti né sovrapposizioni.
- [ ] Le anteprime laterali e la navigazione avanti/indietro del carosello
      restano riconoscibili e utilizzabili; il comportamento circolare non
      cambia.
- [ ] Focus, conferma, touch e Back restano quelli attuali; Back torna alla
      welcome senza alterare la run.
- [ ] Il layout si ricompone nella safe area su 16:9, 20:9 e 4:3 senza tagli.
- [ ] Nessuno degli otto personaggi produce un busto deformato, ricampionato
      male o fuori dal proprio contenitore.
- [ ] La card dichiara esplicitamente, nelle Decisioni, se il risultato
      sostituisce interamente PS-054 o se le due convivono; lo stato di
      PS-054 viene aggiornato di conseguenza a fine lavoro.

## Ambito

- `scenes/ui/character_select_overlay.tscn` e sottoalberi del pannello
  informativo, del carosello e del busto.
- `scripts/ui/character_select_overlay.gd`.
- `scripts/content/friend_definition.gd`, solo se serve un nuovo accessor
  tipizzato per il busto (per esempio accanto a `get_public_portrait()`), non
  per cambiare i contratti di gameplay.

Non toccare:

- flusso `welcome → tutorial → selezione → run`;
- `RunController` e avvio della run;
- testi e dati di gameplay dei personaggi;
- asset prodotti da PS-068: questa card li integra, non li rigenera.

## Verifica

- Smoke: `tests/unit/test_ps069_character_select_bust_portrait.gd` → marker
  `CHARACTER_SELECT_BUST_PORTRAIT_SMOKE_OK` — verifica che il busto del
  personaggio selezionato sia esposto e sincronizzato per tutti e otto i
  profili, e che il layout resti contenuto su 16:9, 20:9 e 4:3.
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9: scorri gli otto personaggi, verifica il busto,
      le anteprime e i pannelli, torna indietro e conferma una scelta
- [ ] Controllo percettivo richiesto: sì — accettazione del proprietario sulla
      nuova composizione e sull'uso del busto
- [ ] A fine sviluppo, prima della chiusura, chiedere esplicitamente al
      proprietario se vuole far girare `revisore-design-ux` sulla nuova
      composizione (invocazione manuale, non automatica).

## Decisioni

- **2026-09-02 — Ambito aperto tra evoluzione e redesign da zero.** Il
  proprietario ha indicato entrambe le strade come accettabili; la scelta
  finale va presa e motivata in questa card al momento della risoluzione, non
  prima.
- **2026-09-02 — Coordinamento con PS-054, non blocco formale.** Le due card
  toccano lo stesso albero di scena ma non sono in `dipende_da` reciproco;
  chi risolve per prima aggiorna l'altra se lo scopo cambia.

## Documenti sincronizzati

- [ ] `docs/ui-ux-flow.md`: composizione aggiornata del selettore personaggi.

## Note

Se in fase di risoluzione risulta più semplice assorbire lo scopo di PS-054
in questa card, aggiornare PS-054 indicando questa card come sostituzione
invece di risolverle in parallelo sullo stesso file di scena.
