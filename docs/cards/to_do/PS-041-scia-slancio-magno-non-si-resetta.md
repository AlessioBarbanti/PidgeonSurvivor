---
id: PS-041
titolo: La scia di slancio di Magno non si azzera all'avvio di una nuova partita
tipo: fix
area: gameplay
stato: PRONTO
priorita: media
dipende_da: []
origine:
creato: 2026-08-31
aggiornato: 2026-08-31
---

# PS-041 — La scia di slancio di Magno non si azzera all'avvio di una nuova partita

## Contesto

Segnalato dal proprietario: all'avvio di una nuova partita, la scia di
slancio di Magno (il "momentum trail", `Player._momentum_trail_points` in
[scripts/actors/player.gd](../../../scripts/actors/player.gd)) resta
visibile invece di sparire.

Ricognizione preliminare: `Player.reset_for_run()` (righe 283-300) azzera
correttamente lo stato — `_momentum_ratio = 0.0`,
`_momentum_reference_direction = Vector2.ZERO`,
`_momentum_trail_points.clear()` — ed è collegata sia a
`RunController.run_started` sia a `RunController.restart_prepared`
(`_on_run_started`/`_on_restart_prepared`, righe 981-986), quindi i *dati*
della scia vengono davvero svuotati a ogni nuova partita o restart.

Quello che manca è la parte visiva: `reset_for_run()` non chiama mai
`queue_redraw()`. In Godot un `CanvasItem` non ridisegna da solo quando i
suoi dati cambiano: l'unico modo per far sparire dallo schermo l'ultimo
frame disegnato (con la scia ancora piena, dall'ultimo istante della run
precedente) è chiedere esplicitamente un nuovo `_draw()`. Il ridisegno
avviene comunque, ma solo indirettamente: `_advance_momentum_trail()` (righe
799-812) chiama `queue_redraw()` al primo tick utile in cui torna a girare
(quando lo stato è di nuovo `RUNNING` e il Player ha `physics_process`
attivo). Nell'intervallo fra `reset_for_run()` e quel primo tick — la
schermata di restart/selezione personaggio, l'eventuale frame iniziale della
nuova run prima che il Player si muova — la scia vecchia resta quindi
visibile sullo schermo, disegnata ma non più vera nei dati.

## Comportamento atteso

La scia di slancio di Magno non deve essere visibile in nessun momento dopo
`reset_for_run()` (avvio di una nuova run o restart), finché una nuova run
di gioco non ne ha effettivamente ridisegnata una propria.

## Criteri di accettazione

- [ ] Dopo `run_started` (prima partita) la scia di Magno da una run
      precedente (se presente, es. dopo un cambio personaggio) non è mai
      visibile.
- [ ] Dopo `restart_prepared` (restart della stessa run) la scia residua
      dalla run precedente non è mai visibile, nemmeno per un singolo frame.
- [ ] Il comportamento della scia durante il gameplay normale (comparsa,
      dissolvenza con lo slancio, disattivazione quando Magno non è il
      personaggio attivo) resta invariato.
- [ ] Nessuna regressione sul contratto di `reset_for_run()` per gli altri
      stati azzerati (vita, input, direzione, i-frame, moltiplicatori).

## Ambito

- `Player.reset_for_run()` in `scripts/actors/player.gd`.

Non modificare:

- la logica di accumulo/decadimento dello slancio (`_advance_momentum`);
- `set_momentum_trail_enabled()` e il suo criterio di attivazione
  (solo quando `passive_id == MAGNO_AERODYNAMIC_FLOW`);
- qualunque altro stato azzerato da `reset_for_run()`.

## Verifica

- Test: nuovo `tests/unit/test_ps041_magno_trail_reset_redraw.gd`
  (`extends GutGameplayTest`), che verifica che `reset_for_run()` (diretto o
  via segnale) svuoti `_momentum_trail_points` **e** richieda un ridisegno
  (es. tramite lo stato interno di `CanvasItem` o un aggancio equivalente
  già in uso nel progetto per verificare `queue_redraw()`).
- Profilo minimo prima della chiusura: `Relevant`.

## Gate manuali

- [ ] Runtime Windows.
- [ ] Validazione statica APK — non pertinente.
- [ ] Runtime fisico Pixel 9 — non richiesto, nessuna superficie touch
      specifica coinvolta.
- [ ] Controllo percettivo richiesto: sì — percorso: equipaggia Magno,
      accumula slancio, muori o premi restart, verifica che la scia non sia
      visibile in nessun frame della nuova run prima che Magno riacceleri.

## Decisioni

- **2026-08-31 — Aperta dal proprietario, non ancora implementata.**

## Documenti sincronizzati

- [ ] Nessuno atteso: comportamento non documentato esplicitamente altrove.

## Note

Ipotesi di causa (da confermare implementando): manca un `queue_redraw()` in
`reset_for_run()` subito dopo `_momentum_trail_points.clear()`.
