---
id: PS-117
titolo: Sposta il mondo di gioco in un SubViewport dedicato per abilitare render_scale
tipo: perf
area: piattaforma
stato: PRONTO
priorita: media
dipende_da: []
origine:
creato: 2026-09-07
aggiornato: 2026-09-07
---

# PS-117 — Sposta il mondo di gioco in un SubViewport dedicato per abilitare render_scale

## Contesto

[PS-114](../1_idea/PS-114-cabla-render-scale-risoluzione-interna.md) doveva
cablare `PerformanceProfile.render_scale` alla risoluzione interna di
rendering "senza toccare `ArenaLayout`". Tentativo reale (non solo previsto):
`Window.content_scale_mode = CONTENT_SCALE_MODE_VIEWPORT` con
`content_scale_size` ridotto. Risultato: `get_viewport().get_visible_rect()`
— ciò che `ArenaLayout`, la HUD e la validazione dei margini leggono come
"viewport corrente" — scende insieme alla risoluzione di rendering, perché in
quella modalità il viewport radice **è** la superficie interna ridotta. Un
test reale lo ha confermato: a `render_scale = 0.75` i margini HUD
diventavano asimmetrici e `_validate_current_contract()` falliva. PS-114 è
stata riportata `DA DEFINIRE` e resta storica.

Non esiste in Godot 4 (renderer Compatibility, 2D) una proprietà nativa che
riduca la sola risoluzione di rasterizzazione lasciando invariata la
risoluzione logica letta dal resto della scena. L'unica via che soddisfa
entrambi i vincoli (fill-rate ridotto sul mondo di gioco, `ArenaLayout`/HUD
invariati) è isolare il mondo di gioco in un `SubViewport` proprio, con la
UI e la logica di layout che restano sul viewport radice.

Struttura attuale rilevante in
[scenes/game/movement_slice.tscn](../../../scenes/game/movement_slice.tscn):
`ArenaView` (Node2D, pavimento/arena), `World` (Node2D: `Enemies`,
`Projectiles`, `BossProjectiles`, `Pickups`, `HealthPickups`,
`AbilityEffects`, `CombatFeedback`, `Player` con `Camera2D` figlio,
`Obstacles`) sono nodi separati direttamente sotto la radice `MovementSlice`,
mentre `ArenaLayout`/`ArenaWorld` sono nodi logici (`Node`, non `Node2D`) che
derivano rettangoli ma non renderizzano nulla. La UI vive in un
`CanvasLayer` (`UI`) indipendente.

## Comportamento atteso

`ArenaView` e `World` (con tutti i loro figli, incluso `Player`/`Camera2D`)
vengono spostati dentro un nuovo `SubViewport` (via `SubViewportContainer`
che occupa lo stesso rettangolo che oggi occupano a schermo). Il
`SubViewport` viene dimensionato in base a `render_scale` del
`PerformanceProfile` attivo (a `render_scale = 1.0`, valore corrente di
entrambi i profili dati, il `SubViewport` ha la stessa risoluzione della
finestra: nessuna differenza percepibile rispetto a oggi). `ArenaLayout`,
`ArenaWorld`, la HUD e tutta la UI restano sul viewport radice, invariati:
continuano a derivare rettangoli dalla stessa risoluzione logica di sempre.
L'input (touch, mouse, joystick) continua a raggiungere `Player` e il resto
del mondo tramite il normale inoltro di Godot da `SubViewportContainer` a
`SubViewport` — nessuna riscrittura di `InputRouter`.

## Criteri di accettazione

- [ ] `ArenaView` e `World` (con tutti i figli attuali) sono nodi di un
      `SubViewport` dedicato, non più diretti figli di `MovementSlice`.
- [ ] A `render_scale = 1.0` il comportamento visivo, di collisione e di
      input è indistinguibile da prima della modifica: stesso smoke esistente
      (`test_b03_movement_slice.gd`, `test_b24_player_visual_scale.gd`,
      `test_ps095_enemy_spawn_off_screen.gd`, ecc.) verde senza modifiche al
      loro contratto.
- [ ] `ArenaLayout.get_viewport_rect()` e le derivazioni di playfield/safe
      rect restano identiche a prima, indipendentemente dal `render_scale`
      del profilo attivo (verificato iniettando un profilo di test con
      `render_scale = 0.75`: il rettangolo logico non cambia, solo la
      risoluzione interna del `SubViewport`).
- [ ] `Camera2D` (figlio di `Player`, dentro il `SubViewport`) continua a
      seguire il player e a rispettare drag margin/smoothing come oggi
      (nessuna regressione su PS-082).
- [ ] Input touch/mouse (joystick, mira manuale PS-085,
      `get_global_mouse_position()` in `input_router.gd:410`) continuano a
      funzionare senza modifiche a `InputRouter`.
- [ ] Un test GUT verifica che, iniettando `render_scale` diverso da `1.0`,
      il `SubViewport` renderizza effettivamente a una risoluzione interna
      ridotta (`SubViewport.size`), mentre il viewport radice e
      `ArenaLayout` restano alla risoluzione logica piena.
- [ ] `windows_performance_profile.tres` e `mobile_performance_profile.tres`
      non cambiano valore in questa card (restano `render_scale = 1.0`): è
      plumbing, non tuning — stessa scelta già presa per PS-114.

## Ambito

- File: [scenes/game/movement_slice.tscn](../../../scenes/game/movement_slice.tscn)
  (reparenting di `ArenaView`/`World` dentro un nuovo `SubViewport`/
  `SubViewportContainer`), [scripts/game/movement_slice.gd](../../../scripts/game/movement_slice.gd)
  (dimensionamento del `SubViewport` da `render_scale`, getter aggiornati se
  i percorsi `%World`/`%ArenaView` cambiano).
- Non toccare: `ArenaLayout`/`ArenaWorld` (restano nodi logici sul viewport
  radice, derivano gli stessi rettangoli di oggi), `InputRouter`
  (l'inoltro input verso il `SubViewport` è automatico in Godot, non va
  riscritto), `RunController`, la UI (`CanvasLayer` resta sul viewport
  radice), i valori di `render_scale` nei due `.tres` (restano `1.0`).
- Punto da verificare in implementazione, non assunto qui: se
  `Camera2D.zoom`/i calcoli di `ArenaWorld` che convertono fra coordinate
  mondo e schermo (es. per il posizionamento di HUD ancorata a elementi di
  gioco, se esiste) richiedono un fattore di conversione esplicito fra lo
  spazio del `SubViewport` e quello del viewport radice quando
  `render_scale != 1.0`.

## Verifica

- Smoke: `tests/unit/test_ps117_world_subviewport.gd` → marker
  `PS117_WORLD_SUBVIEWPORT_OK`
- Rieseguire senza modifiche attese: `test_b03_movement_slice.gd`,
  `test_b24_player_visual_scale.gd`, `test_ps082_camera_recenter_on_restart.gd`,
  `test_ps095_enemy_spawn_off_screen.gd`, `test_input_subsystem.gd`
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [ ] Runtime Windows: verificare percettivamente che a `render_scale = 1.0`
      nulla sia cambiato (nitidezza, hitbox, camera, input)
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9: verificare che il touch (joystick, mira
      manuale) raggiunga ancora correttamente il mondo di gioco dopo il
      reparenting nel `SubViewport`
- [ ] Controllo percettivo richiesto: sì — è il gate primario per questa
      card, dato il rischio di regressioni su input/camera non colte dai test

## Decisioni

- **2026-09-07 — Sostituisce PS-114.** PS-114 aveva sottostimato la
  superficie del problema (pensava bastasse una riga in
  `movement_slice.gd`); il tentativo reale ha dimostrato che serve isolare il
  mondo di gioco in un `SubViewport`. Il proprietario ha scelto di aprire
  questa card dedicata piuttosto che accantonare `render_scale`.
- **Aperto:** la scelta del valore `render_scale` per il profilo mobile resta
  fuori da questa card, come già deciso per PS-114 — qui si cabla solo il
  meccanismo, i due `.tres` restano a `1.0`.

## Documenti sincronizzati

- [ ] [docs/visual-audio-identity.md](../../../docs/visual-audio-identity.md):
      aggiornare la sezione `PerformanceProfile` con il consumer reale di
      `render_scale` (il `SubViewport` dedicato, non `Window.content_scale_mode`).

## Note

Card storica collegata: [PS-114](../1_idea/PS-114-cabla-render-scale-risoluzione-interna.md)
(tentativo insufficiente, dettagli tecnici del fallimento nelle sue
Decisioni). [PS-115](../2_to_do/PS-115-modalita-risparmio-energetico-profilo-mobile-low.md)
va aggiornata per dipendere da questa card invece che da PS-114.
