---
id: PS-013
titolo: Correggi il crash TypedArray alla seconda offerta upgrade
tipo: fix
area: ui
stato: IN VERIFICA
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

- [x] Una run che attraversa `LEVEL_UP` due o più volte non produce alcun
      `SCRIPT ERROR` proveniente da `upgrade_overlay.gd`.
- [x] `_release_card_focus()` gestisce correttamente un `focus_owner` che non
      è un'istanza di `UpgradeCard` (incluso `null`) senza sollevare errori
      sul tipo del `TypedArray`.
- [x] Il comportamento di rilascio del focus (nessuna carta preselezionata
      alla nuova offerta) resta invariato per l'utente finale.
- [x] Cinque run consecutive con più level-up ciascuna (rank multipli sullo
      stesso upgrade, upgrade diversi in sequenza) non producono l'errore.

## Ambito

- `scripts/ui/upgrade_overlay.gd`, in particolare `_release_card_focus()` e
  `_show_offer()`.

Non modificare:

- il flusso di selezione (tastiera, gamepad, mouse, touch) già verificato da
  `tests/unit/test_b11_upgrade_overlay.gd`;
- il lock di selezione iniziale o la logica di `_submit_selection()`.

## Verifica

- Test: `tests/unit/test_b11_upgrade_overlay.gd::test_second_offer_with_external_focus`
  (regressione mirata aggiunta da questa card),
  `tests/unit/test_b16_complete_run.gd` (cinque run complete, il caso
  più diretto per riprodurre più level-up nella stessa run),
  `tests/unit/test_b18j_summer_grill.gd`, `tests/unit/test_b22_evil_boss_variants.gd`,
  `tests/unit/test_b53_boss_horde_pause.gd` — tutti fallivano con lo
  stesso errore motore quando raggiungevano una seconda offerta.
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [ ] Runtime Windows — **aperto**: non eseguito, serve una partita reale
      fino ad almeno due level-up.
- [ ] Validazione statica APK — **aperto**: nessun export prodotto in questa
      sessione.
- [ ] Runtime fisico Pixel 9 (percorso: gioca fino ad almeno due level-up
      nella stessa run, verifica assenza di comportamenti anomali sul focus
      delle carte) — **aperto**: device non collegato.
- [x] Controllo percettivo richiesto: no

## Decisioni

- **2026-08-30 — Scoperto durante la migrazione GUT, non introdotto da
  essa.** Riprodotto rilanciando gli smoke legacy originali (non toccati)
  in isolamento prima che venissero cancellati: falliva identico.
- **2026-08-30 — Il focus viene ristretto a `UpgradeCard` prima della
  ricerca, invece di allargare il tipo di `_cards`.** `_cards` resta
  `Array[UpgradeCard]`: è il tipo che descrive davvero il contenuto e che
  regge il resto del file. A cambiare è il modo di interrogarlo, con un cast
  che restituisce `null` per qualunque Control esterno. Il comportamento
  osservabile non cambia: solo le carte perdono il focus, i Control esterni
  lo conservano come prima.
- **2026-08-30 — Corretta anche `get_focused_card_index()`, non solo
  `_release_card_focus()`.** L'ambito della card nominava la riga 277, ma
  `get_focused_card_index()` conteneva lo stesso `find()` non protetto sullo
  stesso TypedArray, alimentato dallo stesso `gui_get_focus_owner()`. Il
  primo criterio di accettazione parla di «alcun `SCRIPT ERROR` proveniente
  da `upgrade_overlay.gd`», quindi lasciarla fuori avrebbe chiuso la card
  con il difetto ancora vivo. La prova che serviva a entrambe: rimettendo il
  file com'era, il nuovo test fallisce citando **sia** la riga 131 sia la
  277.
- **2026-08-30 — Aggiunta una regressione mirata invece di affidarsi solo
  a b16.** La copertura esistente era indiretta (l'errore emergeva in mezzo a
  cinque run complete). `test_second_offer_with_external_focus` mette
  esplicitamente il focus su un Control esterno alle carte e forza la seconda
  offerta: è deterministica, dura pochi secondi e nomina il difetto.

## Documenti sincronizzati

- [x] Nessun contratto di prodotto cambia; solo un fix interno.

## Note

**Verifica eseguita (2026-08-30).**

```powershell
.	oolsun-milestone-checks.ps1 -Milestone PS-013 -Profile Focused -NoCache `
  -FocusedSmoke tests/unit/test_b11_upgrade_overlay.gd,tests/unit/test_b16_complete_run.gd,`
tests/unit/test_b18j_summer_grill.gd,tests/unit/test_b22_evil_boss_variants.gd,`
tests/unit/test_b53_boss_horde_pause.gd
```

→ `status=PASS`, 11 test, 12857 assert, log `20260830-135616-PS-013`: **zero**
occorrenze di `TypedArray` e nessun `ERROR:` nel log.

Profilo `Relevant` (log `20260830-133544-PS-013`): il calcolo delle path
modificate ha degenerato in suite completa, 65 script e 160 test, 159 verdi.
L'unico rosso è `test_b15_boss_encounter.gd`, che passa in isolamento e
falliva già il 2026-08-29 prima di questa modifica: spostato su
[PS-022](../to_do/PS-022-b15-target-registrati-in-piu-suite-completa.md).

**Prova che la regressione è davvero coperta.** Ripristinando
`scripts/ui/upgrade_overlay.gd` alla versione di HEAD e rilanciando il solo
`test_b11_upgrade_overlay.gd` (log `20260830-135503-PS-013`), il nuovo test
fallisce e il log cita entrambe le occorrenze:

```
[0] get_focused_card_index (res://scripts/ui/upgrade_overlay.gd:131)
[0] _release_card_focus     (res://scripts/ui/upgrade_overlay.gd:277)
```

Il file è stato poi riportato alla versione con il fix.

Errore osservato per intero:

```
Condition "!_p->typed.validate(value, "find")" is true. Returning: -1
Method/function failed. Returning: false
```

Ripetuto due volte per occorrenza (una per il tentativo, una per la stampa
dell'errore da parte del motore).
