---
id: PS-013
titolo: Correggi il crash TypedArray alla seconda offerta upgrade
tipo: fix
area: ui
stato: PRONTO
priorita: alta
dipende_da: []
origine:
creato: 2026-08-30
aggiornato: 2026-08-30
---

# PS-013 — Correggi il crash TypedArray alla seconda offerta upgrade

## Contesto

`scripts/ui/upgrade_overlay.gd:277`, dentro `_release_card_focus()`, esegue
`if focus_owner in _cards:` dove `_cards` è tipizzato `Array[UpgradeCard]`.
Quando questa riga viene raggiunta con un `focus_owner` incompatibile con il
tipo dichiarato, il motore solleva "Attempted to find an object into a
TypedArray, that does not inherit from 'GDScript'" e la chiamata fallisce
silenziosamente (nessun crash del processo, ma un errore motore non gestito).

Il problema si manifesta ogni volta che una run genera una **seconda**
offerta di livello (`LEVEL_UP`) nella stessa run: qualunque percorso che
attraversi `LEVEL_UP` due volte lo riproduce. Scoperto durante la migrazione
dei test da smoke legacy a GUT: il vecchio gate a marker non lo intercettava
perché il testo dell'errore non contiene né `SCRIPT ERROR` né
`FATAL EXCEPTION`, i soli pattern cercati dal runner legacy — lo smoke
stampava comunque `..._SMOKE_OK` nonostante l'errore. GUT lo cattura sempre
correttamente perché traccia gli errori motore non gestiti durante il test a
prescindere dal testo.

## Comportamento atteso

Una run con più di un level-up nel corso della stessa partita non deve
produrre errori motore in `_release_card_focus()`, indipendentemente da quale
nodo detenga il focus della GUI nel momento in cui la seconda (o successiva)
offerta viene mostrata.

## Criteri di accettazione

- [ ] Una run che attraversa `LEVEL_UP` due o più volte non produce alcun
      `SCRIPT ERROR` proveniente da `upgrade_overlay.gd`.
- [ ] `_release_card_focus()` gestisce correttamente un `focus_owner` che non
      è un'istanza di `UpgradeCard` (incluso `null`) senza sollevare errori
      sul tipo del `TypedArray`.
- [ ] Il comportamento di rilascio del focus (nessuna carta preselezionata
      alla nuova offerta) resta invariato per l'utente finale.
- [ ] Cinque run consecutive con più level-up ciascuna (rank multipli sullo
      stesso upgrade, upgrade diversi in sequenza) non producono l'errore.

## Ambito

- `scripts/ui/upgrade_overlay.gd`, in particolare `_release_card_focus()` e
  `_show_offer()`.

Non modificare:

- il flusso di selezione (tastiera, gamepad, mouse, touch) già verificato da
  `tests/unit/test_b11_upgrade_overlay.gd`;
- il lock di selezione iniziale o la logica di `_submit_selection()`.

## Verifica

- Test: `tests/unit/test_b16_complete_run.gd` (cinque run complete, il caso
  più diretto per riprodurre più level-up nella stessa run),
  `tests/unit/test_b18j_summer_grill.gd`, `tests/unit/test_b22_evil_boss_variants.gd`,
  `tests/unit/test_b53_boss_horde_pause.gd` — tutti falliscono oggi con lo
  stesso errore motore quando raggiungono una seconda offerta.
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: gioca fino ad almeno due level-up
      nella stessa run, verifica assenza di comportamenti anomali sul focus
      delle carte)
- [ ] Controllo percettivo richiesto: no

## Decisioni

- **2026-08-30 — Scoperto durante la migrazione GUT, non introdotto da
  essa.** Riprodotto rilanciando gli smoke legacy originali (non toccati)
  in isolamento prima che venissero cancellati: falliva identico.

## Documenti sincronizzati

- [ ] Nessun contratto di prodotto cambia; solo un fix interno.

## Note

Errore osservato per intero:

```
Condition "!_p->typed.validate(value, "find")" is true. Returning: -1
Method/function failed. Returning: false
```

Ripetuto due volte per occorrenza (una per il tentativo, una per la stampa
dell'errore da parte del motore).
