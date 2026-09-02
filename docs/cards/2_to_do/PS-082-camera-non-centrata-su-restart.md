---
id: PS-082
titolo: Ricentra davvero la camera sul personaggio al restart
tipo: fix
area: gameplay
stato: PRONTO
priorita: media
dipende_da: []
origine:
creato: 2026-09-02
aggiornato: 2026-09-02
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

- [ ] Dopo un restart, la posizione sullo schermo del player coincide con il
      centro del viewport di gioco (entro l'arrotondamento in pixel), sia se
      il restart avviene subito dopo l'avvio sia dopo che la camera si è
      spostata per effetto del drag durante la run precedente.
- [ ] Nessun frame visibile mostra la camera ancora spostata rispetto al
      player prima dello snap (non un'interpolazione che si conclude dopo
      il restart, uno snap immediato).
- [ ] Il comportamento di drag/smoothing della camera durante il gameplay
      normale (fuori dal restart) resta invariato.

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
  (`extends GutGameplayTest`), marker `PS082_CAMERA_RECENTER_OK`. Deve
  spostare la camera dal centro (facendo muovere il player abbastanza da
  attivare il drag), invocare il restart e verificare che
  `_camera.get_screen_center_position()` (o equivalente) coincida con la
  nuova posizione del player entro una tolleranza minima.
- Registrare la regola in
  [tools/milestone-test-map.json](../../../tools/milestone-test-map.json)
  sotto `scripts/game/movement_slice.gd`.
- Profilo minimo prima della chiusura: `Relevant` con
  `-FocusedSmoke tests/unit/test_ps082_camera_recenter_on_restart.gd`.

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

## Documenti sincronizzati

- [ ] Nessuno atteso: comportamento non documentato esplicitamente altrove.

## Note

Nessuna.
