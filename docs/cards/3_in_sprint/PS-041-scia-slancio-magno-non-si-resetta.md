---
id: PS-041
titolo: La scia di slancio di Magno non si azzera all'avvio di una nuova partita
tipo: fix
area: gameplay
stato: IN CORSO
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

- [x] Dopo `run_started` (prima partita) la scia di Magno da una run
      precedente non è mai visibile. `reset_for_run()` è collegata a
      `run_started` (`_on_run_started`, invariato) e ora chiede un
      ridisegno quando svuota la scia.
- [x] Dopo `restart_prepared` (restart della stessa run) la scia residua
      dalla run precedente non è mai visibile, nemmeno per un singolo
      frame. Stessa funzione `reset_for_run()`, collegata anche a
      `restart_prepared` (`_on_restart_prepared`, invariato).
- [x] Il comportamento della scia durante il gameplay normale (comparsa,
      dissolvenza con lo slancio, disattivazione quando Magno non è il
      personaggio attivo) resta invariato. Nessuna riga toccata in
      `_advance_momentum_trail()` o `set_momentum_trail_enabled()`.
- [x] Nessuna regressione sul contratto di `reset_for_run()` per gli altri
      stati azzerati (vita, input, direzione, i-frame, moltiplicatori).
      Aggiunte solo due righe (`if` + `queue_redraw()`) attorno alla riga
      di `clear()` già esistente; nessun'altra riga della funzione toccata.

## Ambito

- `Player.reset_for_run()` in `scripts/actors/player.gd`.

Non modificare:

- la logica di accumulo/decadimento dello slancio (`_advance_momentum`);
- `set_momentum_trail_enabled()` e il suo criterio di attivazione
  (solo quando `passive_id == MAGNO_AERODYNAMIC_FLOW`);
- qualunque altro stato azzerato da `reset_for_run()`.

## Verifica

- Test: `tests/unit/test_ps041_magno_trail_reset_redraw.gd`
  (`extends GutGameplayTest`). Un test headless non può osservare
  direttamente la richiesta di ridisegno di `CanvasItem` (nessuna API
  pubblica la espone), quindi il fix è pinnato in due modi: per lettura del
  sorgente (`reset_for_run()` deve contenere sia
  `_momentum_trail_points.clear()` sia `queue_redraw()`) e per
  comportamento (`reset_for_run()` azzera davvero `_momentum_ratio` e
  svuota `_momentum_trail_points` dopo che Magno ha accumulato slancio e
  punti scia).
- Registrato in `tools/milestone-test-map.json` sotto la regola
  `scripts/actors/player.gd`.
- Profilo minimo prima della chiusura: `Relevant` con
  `-FocusedSmoke tests/unit/test_ps041_magno_trail_reset_redraw.gd`
  (non ancora eseguito, vedi Note).

## Gate manuali

- [ ] Runtime Windows — necessario prima di `COMPLETATO`: nessun Godot
      disponibile in questa sessione per eseguirlo.
- [ ] Validazione statica APK — non pertinente.
- [ ] Runtime fisico Pixel 9 — non richiesto, nessuna superficie touch
      specifica coinvolta.
- [ ] Controllo percettivo richiesto: sì — percorso: equipaggia Magno,
      accumula slancio, muori o premi restart, verifica che la scia non sia
      visibile in nessun frame della nuova run prima che Magno riacceleri.
      Non eseguito in questa sessione.

## Decisioni

- **2026-08-31 — Aperta dal proprietario.**
- **2026-08-31 — Causa confermata: `queue_redraw()` mancante in
  `reset_for_run()`.** L'ipotesi della prima stesura della card era
  corretta: aggiunto un `queue_redraw()` subito dopo aver svuotato
  `_momentum_trail_points`, con lo stesso guard `if not ... is_empty()` già
  usato da `_advance_momentum_trail()` per lo stesso scopo (evitare
  ridisegni superflui quando non c'era nulla da pulire).

## Documenti sincronizzati

- [ ] Nessuno atteso: comportamento non documentato esplicitamente altrove.

## Note

**Verifica non eseguita.** Il fix è stato implementato e controllato per
lettura (due righe aggiunte, stesso pattern già in uso altrove nello stesso
file) più un nuovo test, ma non è stato lanciato
`run-milestone-checks.ps1`: nessun Godot/PowerShell disponibile in questo
ambiente. Il profilo `Relevant` su Windows e il controllo percettivo su
device restano i gate aperti prima di poter chiudere la card `COMPLETATO`.
