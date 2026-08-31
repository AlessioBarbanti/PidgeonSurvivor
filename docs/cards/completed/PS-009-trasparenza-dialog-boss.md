---
id: PS-009
titolo: Rendi trasparente la Boss UI sotto il Player
tipo: ux
area: ui
stato: COMPLETATO
priorita: media
dipende_da: []
origine:
creato: 2026-08-30
aggiornato: 2026-08-31
---

# PS-009 — Rendi trasparente la Boss UI sotto il Player

## Contesto

Il riquadro HUD con nome e vita del Boss può sovrapporsi visivamente al personaggio quando il Player passa nella zona occupata dalla Boss UI.

Il pulsante dell'abilità utilizza già un comportamento equivalente: quando il personaggio passa sotto il controllo, questo diventa parzialmente trasparente per non nascondere il gameplay.

La Boss UI deve adottare lo stesso principio.

## Comportamento atteso

Quando il Player entra visivamente sotto il riquadro della vita del Boss, l'intero blocco Boss UI diventa parzialmente trasparente.

Quando il Player esce dalla zona occupata dal riquadro, la Boss UI torna automaticamente alla propria opacità normale.

La trasparenza:

* riguarda l'intero riquadro Boss rilevante, inclusi barra HP, nome, bordo e sfondo;
* è esclusivamente presentazionale;
* non modifica posizione, dimensioni o comportamento del Boss;
* non modifica il playfield;
* non modifica collisioni o movimento del Player;
* non rende la Boss UI completamente invisibile;
* deve usare una transizione visiva breve e non un cambio brusco.

La logica deve seguire lo stesso principio già utilizzato dal controllo dell'abilità quando il Player gli passa sotto.

Il valore di opacità ridotta deve restare configurabile.

## Criteri di accettazione

* [x] Con un Boss attivo, la Boss UI resta normalmente alla propria opacità standard.
* [x] Quando il Player entra sotto il riquadro Boss, l'intero blocco diventa parzialmente trasparente.
* [x] Quando il Player esce dalla zona, il blocco torna all'opacità standard.
* [x] La transizione tra i due stati non avviene tramite uno stacco visivo brusco.
* [ ] La Boss UI resta leggibile anche nello stato trasparente. — non
      verificabile: il pannello è stato rimosso da PS-033 prima del gate
      percettivo (vedi Decisioni, 2026-08-31).
* [ ] Il Player resta chiaramente visibile sotto il riquadro trasparente. —
      stesso motivo: oggetto rimosso, non verificabile.
* [x] Il comportamento si basa sulla sovrapposizione visiva effettiva con il Player e non su coordinate fisse per una singola risoluzione.
* [x] Il comportamento funziona con aspect ratio differenti.
* [x] La trasparenza non modifica hitbox, movimento, targeting o statistiche. —
      l'implementazione tocca solo `modulate.a` del pannello; nessun altro
      sistema viene toccato (verificato a revisione codice).
* [ ] Boss Intro, pausa e altri overlay non producono stati di opacità
      residui. — non verificabile: oggetto rimosso da PS-033 prima di questo
      secondo passaggio.
* [x] Alla scomparsa del Boss la UI viene ripulita senza mantenere stato locale.
* [x] Restart ripristina sempre l'opacità standard.

## Ambito

* Boss HUD / riquadro vita Boss.
* Rilevamento della sovrapposizione visuale Player ↔ Boss UI.
* Stato di opacità della Boss UI.
* Transizione tra opacità normale e ridotta.
* Cleanup alla morte del Boss e al restart.

Riutilizzare, dove possibile, lo stesso criterio già adottato per la trasparenza del pulsante abilità.

Non modificare:

* posizione della Boss UI;
* dimensioni della barra Boss;
* HP o statistiche del Boss;
* layout del playfield;
* collisioni del Player;
* comportamento del pulsante abilità.

## Verifica

* Il contratto a smoke `SceneTree` con marker (`tests/integration/_*_smoke.gd`,
  `..._SMOKE_OK`) descritto qui in origine non esiste più: da
  [docs/verification-workflow.md](../../verification-workflow.md) i test
  vivono in `tests/unit/` (GUT, `extends GutTest`/`GutGameplayTest`) e i
  fallimenti si leggono dal report JUnit, non da un marker testuale.
* Test: `tests/unit/test_ps009_boss_ui_transparency.gd`
* Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

* [ ] Runtime Windows — non eseguito: oggetto rimosso da PS-033 prima del gate.
* [ ] Validazione statica APK — non pertinente, stesso motivo.
* [ ] Runtime fisico Pixel 9 — non pertinente, stesso motivo.
* [ ] Controllo percettivo richiesto: sì — non eseguito, oggetto rimosso.
* [ ] La Boss UI diventa abbastanza trasparente da non nascondere il Player. — non verificabile.
* [ ] HP e nome del Boss restano comunque leggibili. — non verificabile.
* [ ] La transizione di entrata e uscita risulta fluida. — non verificabile.
* [ ] Non si osserva flickering quando il Player si muove vicino al bordo del riquadro. — non verificabile.
* [ ] Il comportamento risulta coerente con quello del pulsante abilità. — non verificabile.

## Decisioni

- **2026-08-30 — La Boss UI sfuma, non si sposta.** Il comportamento è
  esclusivamente presentazionale e segue il principio già usato dal controllo
  abilità.
- **Baseline percettiva — alpha e transizione configurabili.** I valori finali
  vengono scelti nel gate visivo senza rendere il riquadro invisibile.
- **2026-08-30 — Implementazione: stesso pattern di B52, applicato al
  `%BossHealthPanel`.** `BossUI` espone `set_player_fade_target(camera,
  target, target_radius)`, `is_player_occluding_boss_ui()` e
  `get_boss_ui_alpha()`, rispecchiando `GameHud.set_ability_fade_target` /
  `is_ability_occluded` / `get_ability_alpha`
  ([scripts/ui/hud.gd](../../../scripts/ui/hud.gd)). `movement_slice.gd`
  collega camera e Player nello stesso punto in cui lo fa per l'HUD.
  Costanti scelte: `PLAYER_FADED_ALPHA = 0.35`, `PLAYER_FADE_MARGIN = 24.0`
  (locali a `boss_ui.gd`, come per l'HUD); durata dissolvenza
  `PresentationTimings.BOSS_UI_FADE_SECONDS = 0.18`, stesso valore di
  `HUD_ABILITY_FADE_SECONDS` ma costante propria perché è un timing di
  presentazione (vive in `presentation_timings.gd`, non in `boss_ui.gd`).
  Il cleanup si aggancia ai punti già esistenti: `clear_boss()`,
  `_on_boss_tree_exiting()` e `reset_presentation()` azzerano l'alpha, quindi
  morte del Boss e restart (che già chiamano `reset_presentation()` da
  `boss_encounter.gd`) non lasciano stato residuo senza bisogno di nuovo
  wiring.
- **2026-08-30 — Correzione allo scope della card: lo smoke `SceneTree`
  indicato in origine non è più il contratto valido.** La sezione Verifica
  citava `tests/integration/_boss_ui_player_overlap_smoke.gd` con marker
  `BOSS_UI_PLAYER_OVERLAP_SMOKE_OK`, ma
  [docs/verification-workflow.md](../../verification-workflow.md) dichiara
  esplicitamente superato quel contratto: i test vivono ora in `tests/unit/`
  come script GUT letti dal report JUnit. Scritto invece
  `tests/unit/test_ps009_boss_ui_transparency.gd` e aggiornata la sezione
  Verifica di conseguenza.
- **2026-08-31 — Chiusura per superamento: il pannello a cui si applicava
  questa card non esiste più.** Il proprietario ha chiesto di eliminare del
  tutto `%BossHealthPanel` (vedi [PS-033](../to_test/PS-033-riquadro-vita-boss-minimale-floating.md)),
  sostituendolo con la sola barra vita overhead già disegnata sopra ogni
  nemico. Senza un pannello da far sparire, l'intera logica di dissolvenza di
  questa card (`set_player_fade_target`, `is_player_occluding_boss_ui`,
  `get_boss_ui_alpha`, le costanti `PLAYER_FADED_ALPHA`/`PLAYER_FADE_MARGIN` e
  `PresentationTimings.BOSS_UI_FADE_SECONDS`) è stata rimossa da PS-033
  insieme al pannello. I criteri percettivi lasciati aperti sopra (leggibilità
  in trasparenza, comportamento con intro/pausa) non verranno mai verificati:
  non per fallimento, ma perché il loro oggetto è stato rimosso a monte. Card
  chiusa come storica; il comportamento attuale della vita del Boss è
  descritto in PS-033.

## Documenti sincronizzati

- [ ] `prd.md`: regola di leggibilità della Boss UI, se diventa contratto
      generale. — non propagato: è un dettaglio presentazionale locale a
      `BossUI`, come il precedente equivalente per il controllo abilità (B52),
      mai anch'esso entrato in `prd.md`.
- [ ] Nota di verifica percettiva Windows/Pixel 9.

## Note

Principio di riferimento:

**la UI può sovrapporsi al gameplay, ma non deve nascondere il Player.**

La Boss UI non deve spostarsi quando il Player le passa sotto: cambia soltanto la propria opacità.

Il valore esatto dell'alpha ridotto e la durata della transizione restano configurabili e devono essere scelti tramite controllo percettivo.
