---
id: PS-053
titolo: Trasformare la schermata finale in un riepilogo della run
tipo: feat
area: ui
stato: PRONTO
priorita: media
dipende_da: []
origine:
creato: 2026-08-31
aggiornato: 2026-08-31
---

# PS-053 — Trasformare la schermata finale in un riepilogo della run

## Contesto

La nuova
[08_end_screen.png](../../../exports/ui-screenshots/pixel9-20x9/08_end_screen.png)
mostra un terminale pulito e coerente: il tempo `02:02` coincide con quello
dell'HUD, quindi il vecchio sospetto di discrepanza non è più valido. La
schermata resta però molto essenziale e perde tutto ciò che ha caratterizzato
la run: personaggio, livello, Boss e build.

Questa card arricchisce il momento finale senza introdurre record persistenti,
meta-progressione o nuove regole di vittoria.

## Comportamento atteso

Alla conclusione il giocatore vede un riepilogo compatto di ciò che ha appena
fatto: personaggio, livello, Boss sconfitti, tempo e upgrade dominanti. Il
restart resta l'azione principale e la schermata conserva la chiarezza del
terminale attuale.

## Criteri di accettazione

- [ ] La schermata mostra nome e ritratto del personaggio usato nella run.
- [ ] Mostra livello raggiunto, numero di Boss sconfitti e tempo sopravvissuto.
- [ ] Il tempo usa lo stesso snapshot del `RunController` passato al terminale
      e coincide con l'ultimo valore dell'HUD, salvo il normale arrotondamento
      al secondo.
- [ ] Mostra fino a tre upgrade con rango più alto, ciascuno con icona, nome e
      rango.
- [ ] Con meno di tre upgrade mostra solo quelli disponibili, senza slot vuoti
      o placeholder testuali.
- [ ] A parità di rango l'ordinamento è deterministico e non cambia riaprendo
      la stessa schermata.
- [ ] Il riepilogo funziona sia per `DEFEAT` sia per `VICTORY`, senza decidere
      se o quando Survival possa essere vinta.
- [ ] Titolo, dati e due CTA restano leggibili e dentro la safe area su 16:9,
      20:9 e 4:3; il pannello non si espande in una dashboard a schermo intero.
- [ ] `RIPROVA`/`NUOVA RUN` conserva focus iniziale e priorità rispetto a
      `CAMBIA PERSONAGGIO`.
- [ ] Nessun record persistente, sblocco o potenziamento fra run viene
      introdotto da questa card.
- [ ] Il `RunController` resta l'unica autorità su stati terminali e restart;
      la schermata riceve uno snapshot e invia intenzioni.

## Ambito

- `scripts/ui/end_screen.gd`, `scenes/ui/end_screen.tscn`.
- `scripts/game/movement_slice.gd`, solo per costruire e passare lo snapshot
  da dati già posseduti da run, esperienza, Boss e servizio upgrade.
- Un piccolo valore/oggetto di snapshot locale alla run, se evita dipendenze
  dirette della UI dai sistemi di gameplay.

Non toccare:

- macchina a stati e condizioni di vittoria/sconfitta;
- bilanciamento e curva di difficoltà;
- persistenza in `user://`, record o meta-progressione;
- registry degli effetti.

## Verifica

- Smoke: `tests/unit/test_ps053_run_summary.gd` → marker
  `RUN_SUMMARY_SMOKE_OK` — verifica snapshot di personaggio, livello, Boss,
  tempo e top tre upgrade, ordinamento deterministico, casi con meno di tre
  upgrade e invarianti delle CTA.
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9: run con almeno un Boss e tre upgrade, sconfitta,
      lettura del riepilogo e restart
- [ ] Controllo percettivo richiesto: sì — il riepilogo deve restare rapido da
      leggere e lasciare dominante la CTA di restart

## Decisioni

- **2026-08-31 — Il tempo corrente è coerente.** PS-053 non è più formulata
  come correzione di un bug non riprodotto; conserva comunque il contratto di
  uno snapshot unico.
- **2026-08-31 — Record fuori ambito.** La persistenza per modalità richiede
  decisioni di prodotto non dimostrate dalla nuova cattura e non è necessaria
  per validare il riepilogo.
- **2026-08-31 — Nessuna meta-progressione.** La card racconta la run appena
  conclusa e non assegna ricompense permanenti.

## Documenti sincronizzati

- [ ] `docs/ui-ux-flow.md`: contenuto del terminale di fine run.
- [ ] `docs/prd.md`, se il riepilogo diventa contratto di prodotto.

## Note

La filosofia della vittoria resta nella card separata
[PS-055](../1_idea/PS-055-filosofia-della-vittoria.md).
