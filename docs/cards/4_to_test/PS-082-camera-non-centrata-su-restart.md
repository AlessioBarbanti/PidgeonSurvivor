---
id: PS-082
titolo: Ricentra davvero la camera sul personaggio al restart
tipo: fix
area: gameplay
stato: IN VERIFICA
priorita: media
dipende_da: []
origine:
creato: 2026-09-02
aggiornato: 2026-09-05
---

# PS-082 — Ricentra davvero la camera sul personaggio al restart

## Contesto

Segnalato dal proprietario: al restart di una partita la camera non appare
centrata sul personaggio, come se mantenesse l'inquadratura (posizione o
scia di drag) della run precedente invece di ripartire centrata.

Ricognizione preliminare in
[scripts/game/movement_slice.gd](../../../scripts/game/movement_slice.gd):
`restart_run()` (righe 673-696) già riposiziona il player al centro
dell'arena (`_player.global_position = _arena_world.get_world_center()`) e
chiama `_camera.reset_smoothing()` subito dopo, stessa sequenza usata in
`_ready()` (righe 131-132) e in un terzo punto (righe 905-906, probabilmente
`_on_change_character_requested`/nuova run). La `Camera2D` è figlia diretta
del `Player` in
[scenes/game/movement_slice.tscn:300](../../../scenes/game/movement_slice.tscn)
con `position_smoothing_enabled = true` e drag margin attivi su tutti e
quattro i lati (`drag_*_margin = 0.35`).

Il drag margin è il sospetto principale: con `drag_horizontal/vertical_enabled`
attivi, la Camera2D non segue 1:1 il nodo padre ma mantiene una posizione di
scorrimento interna che si muove solo quando il target esce dal margine.
`reset_smoothing()` azzera la sola interpolazione di smoothing, non è
garantito che riallinei anche questo scorrimento interno alla nuova posizione
del player: è verosimile che la camera al restart resti quindi ancorata
all'ultimo punto di scorrimento della run precedente invece di centrarsi sul
player appena riposizionato. Da confermare in fase di risoluzione, non è
un'ipotesi validata da un test.

## Comportamento atteso

Subito dopo un restart (dalla schermata finale o da qualunque altro percorso
che richiami `restart_run()`), il personaggio deve apparire esattamente al
centro dell'area di gioco visibile, senza alcun offset residuo o frame
intermedio in cui la camera è ancora spostata rispetto al player.

## Criteri di accettazione

- [x] Dopo un restart, la posizione sullo schermo del player coincide con il
      centro del viewport di gioco (entro l'arrotondamento in pixel), sia se
      il restart avviene subito dopo l'avvio sia dopo che la camera si è
      spostata per effetto del drag durante la run precedente. Verificato in
      automatico; resta aperto il controllo percettivo su device/Windows
      reale (vedi Gate manuali).
- [x] Nessun frame visibile mostra la camera ancora spostata rispetto al
      player prima dello snap (non un'interpolazione che si conclude dopo
      il restart, uno snap immediato). Confermato: lo scarto scende a zero
      al primo frame dopo il restart e resta stabile nei frame successivi
      (nessuna convergenza graduale).
- [x] Il comportamento di drag/smoothing della camera durante il gameplay
      normale (fuori dal restart) resta invariato: la correzione tocca solo
      i tre punti di riposizionamento (`_ready()`, `restart_run()`,
      `_start_selected_run()`), non la logica di drag per-frame della
      `Camera2D`.

## Ambito

- `restart_run()` in
  [scripts/game/movement_slice.gd](../../../scripts/game/movement_slice.gd)
  (righe 673-696) e gli altri due punti che ripetono la stessa sequenza
  (righe 131-132, 905-906) — verificare se serve la stessa correzione in
  tutti e tre o se solo il restart è realmente affetto.
- Configurazione `Camera2D` in
  [scenes/game/movement_slice.tscn](../../../scenes/game/movement_slice.tscn)
  (drag margin, smoothing), solo se la causa è lì confermata.

Non toccare:

- `RunController` e il suo arbitraggio di stato/restart (`restart_run`,
  `restart_prepared`);
- il comportamento di drag/smoothing della camera durante la run normale;
- `ArenaWorld`/`ArenaLayout` e il calcolo del centro/limiti dell'arena.

## Verifica

- Test: `tests/unit/test_ps082_camera_recenter_on_restart.gd`
  (`extends GutGameplayTest`), marker `PS082_CAMERA_RECENTER_OK`. Trascina la
  camera muovendo il player verso un punto lontano per 40 frame (dead zone
  del drag margin realmente attivata, non un salto istantaneo), forza lo
  stato terminale (`request_defeat()`), invoca `restart_run()` e verifica che
  `get_screen_center_position()` coincida con la nuova posizione del player
  entro 1px al primo frame dopo il restart e resti stabile 5 frame dopo.
- Regola aggiunta in
  [tools/milestone-test-map.json](../../../tools/milestone-test-map.json)
  sotto la voce `scripts/game/movement_slice.gd` / `run_controller.gd`.
- Eseguito in sandbox Linux (headless, Godot 4.7.1): focalizzato
  `tests/unit/test_ps082_camera_recenter_on_restart.gd` (1/1, 7 assert) e
  profilo `Relevant` (i 21 smoke della regola, 71/71 test, 1932 assert);
  eseguita anche la suite `Full` per sicurezza vista la centralità del file
  toccato (321/321, 23908 assert). Nessun `SCRIPT ERROR`/`FATAL EXCEPTION`
  nei log.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK — non pertinente, nessuna superficie
      Android-specifica.
- [ ] Runtime fisico Pixel 9 — non richiesto, comportamento non touch-specifico.
- [ ] Controllo percettivo richiesto: sì — muovi il personaggio fino a far
      scorrere la camera, muori o premi restart, verifica che il personaggio
      riappaia esattamente al centro fin dal primo frame.

## Decisioni

- **2026-09-02 — Aperta dal proprietario.** Causa non ancora confermata: il
  sospetto (drag margin della `Camera2D` non riallineato da
  `reset_smoothing()`) va verificato in fase di risoluzione prima di
  scrivere il fix.
- **2026-09-05 — Causa confermata: `reset_smoothing()` da solo non basta.**
  Verificato con un probe headless dedicato (poi eliminato) e con la
  sorgente `Camera2D` upstream (Godot 4.7.1-stable): `reset_smoothing()`
  sincronizza solo `smoothed_camera_pos` con `camera_pos`, ma non ricalcola
  `camera_pos` stesso — quello resta l'ultima ancora del drag margin della
  run precedente. Sul frame successivo al teletrasporto, la dead zone del
  drag riaggancia `camera_pos` al **bordo** del margine rispetto al nuovo
  target, non al centro: con `drag_*_margin = 0.35` l'offset visibile è
  circa il 35% dello schermo, esattamente il sintomo segnalato dal
  proprietario.
- **2026-09-05 — Fix: `Camera2D.align()` prima di `reset_smoothing()`.**
  `align()` (metodo nativo Godot pensato per questo caso) ricalcola subito
  `camera_pos` esattamente sulla posizione del target quando
  `drag_horizontal_offset`/`drag_vertical_offset` sono 0 (default e invariati
  in questa scena); `reset_smoothing()` chiamato subito dopo azzera anche il
  ritardo di smoothing visivo. I tre punti che riposizionano il player
  (`_ready()`, `restart_run()`, `_start_selected_run()`) condividono ora il
  nuovo helper privato `_recenter_camera_on_player()` invece di ripetere la
  sequenza tre volte.
- **2026-09-05 — Lo snap effettivo si legge al frame successivo, non nello
  stesso frame-script.** `get_screen_center_position()` riflette l'ultimo
  aggiornamento di `_update_scroll()`; `reset_smoothing()` lo richiama prima
  di sincronizzare lo smoothing, quindi chi legge la posizione nello stesso
  frame-script di `restart_run()` vede ancora il valore pre-fix. Non è un
  ritardo visibile al giocatore: il rendering della run avviene dopo il
  passo di processo automatico della `Camera2D`, che nello stesso frame
  applica già lo stato corretto. Il test misura quindi dopo un frame
  (`wait_process_frames(1)`), lo stesso confine naturale di rendering, non
  a zero frame.

## Documenti sincronizzati

- [ ] Nessuno atteso: comportamento non documentato esplicitamente altrove.

## Note

Nessuna.
