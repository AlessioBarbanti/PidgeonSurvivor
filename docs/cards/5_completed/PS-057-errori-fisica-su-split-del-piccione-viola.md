---
id: PS-057
titolo: Eliminare gli errori di fisica quando il piccione viola si sdoppia
tipo: fix
area: gameplay
stato: COMPLETATO
priorita: media
dipende_da: []
origine: PS-044
creato: 2026-08-31
aggiornato: 2026-09-04
---

# PS-057 — Eliminare gli errori di fisica quando il piccione viola si sdoppia

## Contesto

Durante la cattura runtime di PS-044, alla prima ondata affollata con Boss in
campo, il log Windows si riempie di errori del motore:

```
ERROR: Can't change this state while flushing queries. Use call_deferred() or
set_deferred() to change monitoring state instead.
   at: body_set_shape_as_one_way_collision / area_set_shape_disabled
   [0] _make_collision_shapes_unique (res://scripts/actors/base_enemy.gd:647)
   [1] _ready (res://scripts/actors/base_enemy.gd:106)
   [2] _finalize_spawned_enemy (res://scripts/game/enemy_spawner.gd:409)
   [3] spawn_archetype_instance (res://scripts/game/enemy_spawner.gd:296)
   [4] _on_died (res://scripts/actors/splitter_enemy.gd:38)
   [5] take_damage (res://scripts/components/health_component.gd:67)
   [6] try_hit (res://scripts/combat/projectile.gd:182)
```

La catena è sempre la stessa: un proiettile uccide un piccione viola *dentro*
il flush delle query fisiche, `SplitterEnemy._on_died()` chiede subito lo spawn
dei frammenti ([scripts/actors/splitter_enemy.gd:38](../../../scripts/actors/splitter_enemy.gd#L38))
e il `_ready()` dei nuovi nemici sostituisce le `CollisionShape2D`
([scripts/actors/base_enemy.gd:643-661](../../../scripts/actors/base_enemy.gd#L643-L661))
mentre il server fisico non lo consente.

La rigenerazione completa del pacchetto di catture del 31 agosto 2026 (due
profili di viewport, `52` PNG) ha prodotto `48` righe `ERROR:` con **quattro**
firme distinte, non una sola: la radice non è solo la sostituzione delle shape,
ma tutto ciò che i frammenti fanno al server fisico nascendo dentro il flush.

| Occorrenze | Chiamata rifiutata | Frame `[0]` |
|---|---|---|
| 24 | `body_set_shape_as_one_way_collision` | `_finalize_spawned_enemy` ([enemy_spawner.gd:409](../../../scripts/game/enemy_spawner.gd#L409)), cioè l'`add_child` stesso |
| 16 | `area_set_shape_disabled` | `_make_collision_shapes_unique` ([base_enemy.gd:647](../../../scripts/actors/base_enemy.gd#L647), `654`, `661`) |
| 8 | `body_set_shape_disabled` | idem |
| 8 | `set_monitorable` | `_ready` di [contact_damage.gd:20](../../../scripts/components/contact_damage.gd#L20) e [hurtbox.gd:11](../../../scripts/components/hurtbox.gd#L11) |

L'ultima riga allarga l'ambito rispetto alla prima diagnosi: anche i componenti
`ContactDamage` e `Hurtbox` toccano il server fisico nel proprio `_ready()`.
Differire la sola sostituzione delle shape non basterebbe.

Non è un errore introdotto da PS-044: la cattura lo ha solo reso visibile,
perché ora arriva davvero a un incontro Boss con l'arena popolata. Il gioco non
crasha, ma per il contratto di onestà dei gate un log pieno di `ERROR` è un
fallimento anche con exit code `0`, e ogni nuova verifica runtime parte da un
log sporco in cui un errore vero passerebbe inosservato.

## Comportamento atteso

Uno split del piccione viola durante una collisione non produce alcun errore
del motore. I frammenti compaiono, si muovono e colpiscono esattamente come
oggi.

## Criteri di accettazione

- [x] Una run che uccide piccioni viola con proiettili non produce righe
      `Can't change this state while flushing queries` nel log. Verificato sia
      dallo smoke dedicato sia rieseguendo l'intera pipeline di catture UI di
      PS-044 (`tools/_capture_ui_screenshots.gd`, lo scenario che aveva
      originariamente rivelato il difetto): log pulito, zero occorrenze.
- [x] Il numero, la posizione e le statistiche dei frammenti generati restano
      identici a oggi: il fix rinvia solo il momento dell'`add_child`, non
      cambia parametri, conteggio o punto di spawn (`spawn_position` resta la
      posizione di morte del divisore, catturata prima di `super._on_died()`).
- [x] Le collisioni dei frammenti restano indipendenti da quelle del genitore:
      la duplicazione delle `CircleShape2D` non viene rimossa, solo spostata in
      un momento consentito. Verificato che i due frammenti non condividano la
      stessa risorsa `Shape2D` sulla propria Hurtbox.
- [x] La sequenza RNG di spawn resta invariata a parità di seed. Verificato
      con due cicli sequenziali (morte reale, `prepare_restart()`, stesso
      seed) sullo stesso fixture: il `pursuit_offset` campionato da `_rng` per
      i frammenti è identico. Il rinvio con `call_deferred()` non altera
      l'ordine relativo delle chiamate accodate nello stesso frame (coda
      FIFO di Godot) e nessun altro consumatore di `_rng` si inserisce nella
      finestra fra la morte del divisore e l'esecuzione dello spawn differito
      in questo scenario.
- [x] Nessun frammento resta senza collisione attiva per più di un frame:
      `_make_collision_shapes_unique()` e l'abilitazione di Hurtbox/
      ContactDamage avvengono dentro lo stesso `_ready()` del frammento,
      eseguito nel medesimo passaggio in cui `add_child()` viene finalmente
      applicato (un solo frame dopo la morte, mai più di due nei casi
      osservati).
- [x] Il log runtime di una cattura completa non contiene righe `ERROR:`
      originate da `base_enemy.gd` o `enemy_spawner.gd`. Verificato in sandbox
      Linux (nessun Windows disponibile in questa sessione): zero righe
      `ERROR:` da quei due file su tutta la pipeline di catture UI.
- [x] Nessuna delle quattro firme registrate nel Contesto compare più:
      `body_set_shape_as_one_way_collision`, `area_set_shape_disabled`,
      `body_set_shape_disabled`, `set_monitorable`. Confermato anche in
      negativo: disattivando temporaneamente il fix, lo smoke dedicato le
      riproduce tutte e quattro (12+8+4+4 occorrenze), provando che il test
      intercetta davvero il difetto e non solo il sintomo generico.

## Ambito

- `scripts/actors/base_enemy.gd`, `_make_collision_shapes_unique` e il punto in
  cui viene chiamata.
- `scripts/actors/splitter_enemy.gd`, `scripts/game/enemy_spawner.gd`, solo se
  lo spawn va differito.
- `scripts/components/contact_damage.gd` e `scripts/components/hurtbox.gd`,
  che nel proprio `_ready()` chiamano `set_monitorable` sullo stesso frame.

Non toccare:

- il numero di frammenti, le loro statistiche e il bilanciamento dello split;
- la sequenza RNG dello spawner;
- `RunController`, `GameDirector` e le curve di difficoltà.

## Verifica

- Smoke: `tests/unit/test_ps057_splitter_spawn_physics.gd` → marker
  `SPLITTER_SPAWN_PHYSICS_SMOKE_OK` — uccide un piccione viola durante una
  vera collisione fisica (proiettile fermo sovrapposto alla Hurtbox, non una
  chiamata diretta a `take_damage()`/`_on_died()`) e verifica che i frammenti
  nascano con collisioni proprie, entro un paio di frame, senza errori del
  motore; un secondo test verifica il determinismo RNG a parità di seed su
  due cicli sequenziali dello stesso fixture.
- Profilo minimo prima della chiusura: `Relevant`. Eseguito con Godot 4.7.1
  headless in sandbox Linux (nessun PowerShell disponibile in questa
  sessione): smoke dedicato (2 test, 28 assert) più l'intero set mappato su
  `scripts/actors/base_enemy.gd`/`enemy_spawner.gd`/`splitter_enemy.gd` e
  `scripts/combat/*` (14 script, 80 test) tutti verdi, zero righe `ERROR:`.
  Rieseguita anche l'intera pipeline `tools/_capture_ui_screenshots.gd` (lo
  scenario che aveva originariamente rivelato il difetto in PS-044): 26
  catture completate, log pulito.

## Gate manuali

- [x] Runtime Windows (percorso: run fino a un'ondata con piccioni viola,
      lettura del log alla ricerca di righe `ERROR:`). Confermato dal
      proprietario.
- [x] Validazione statica APK — non richiesta dal fix (nessun asset o preset
      export toccato).
- [x] Runtime fisico Pixel 9 (percorso: stessa ondata, log via `adb logcat`).
      Confermato dal proprietario.
- [x] Controllo percettivo richiesto: no.

## Decisioni

- **2026-08-31 — Card aperta da PS-044, non risolta al suo interno.** PS-044
  copre le catture UI; correggere lo spawn dei frammenti è codice di gameplay e
  merita una card e uno smoke propri.
- **2026-08-31 — L'ambito include i componenti, non solo le shape.** La
  rigenerazione completa del pacchetto ha mostrato quattro firme di errore
  distinte: `ContactDamage` e `Hurtbox` chiamano `set_monitorable` nel proprio
  `_ready()`, quindi differire la sola `_make_collision_shapes_unique` lascia
  il log sporco. La correzione deve coprire l'intero ingresso in scena del
  frammento.
- **2026-09-02 — Un'unica causa comune a tutte e quattro le firme: l'intero
  `add_child()`, non le singole proprietà.** Analizzando la tabella delle
  occorrenze del Contesto, il bucket più grande (24×
  `body_set_shape_as_one_way_collision`) ha `frame [0]` proprio dentro
  `_finalize_spawned_enemy` all'`add_child()` stesso: è la registrazione
  interna delle `CollisionShape2D` del motore quando un nodo entra
  nell'albero per la prima volta, non qualcosa che il nostro codice imposta
  esplicitamente. Nessuna quantità di `set_deferred()` sulle singole proprietà
  di `_make_collision_shapes_unique()` o di `contact_damage.gd`/`hurtbox.gd`
  può evitarla, perché avviene prima che quel codice giri. L'unico modo per
  eliminare tutte e quattro le firme in un colpo solo è differire l'intero
  `add_child()` (quindi l'intero `_ready()` del frammento, che le contiene
  tutte) fuori dal flush, esattamente come suggerito dalla Nota originale
  della card ("differendo lo spawn dei frammenti").
- **2026-09-02 — Rinvio nel punto di chiamata (`splitter_enemy.gd`), non in
  `enemy_spawner.gd`.** `spawn_archetype_instance()` ha un altro chiamante
  sincrono che dipende dal valore di ritorno immediato
  (`wave_event_scheduler.gd:250`, e lo stesso smoke `test_b40_enemy_archetypes.gd`).
  Farla sempre differire avrebbe rotto quel contratto. Il rinvio resta quindi
  isolato nel ciclo di spawn dei frammenti in `SplitterEnemy._on_died()`, via
  `spawner.call_deferred("spawn_archetype_instance", ...)`: `base_enemy.gd`,
  `enemy_spawner.gd`, `contact_damage.gd` e `hurtbox.gd` restano invariati.
- **2026-09-02 — Determinismo RNG verificato empiricamente, non solo per
  ragionamento.** La coda dei `call_deferred()` di Godot è FIFO, e in questo
  scenario nessun altro consumatore di `_rng` si inserisce fra la morte del
  divisore e l'esecuzione dello spawn differito, quindi il rinvio non doveva
  alterare la sequenza. Verificato con un test dedicato (due cicli
  sequenziali stesso seed sullo stesso fixture, non due fixture fisiche
  indipendenti sovrapposte: quella combinazione mescola gruppi globali e
  nemici ancora attivi fra le due istanze e si è rivelata instabile, un
  tentativo iniziale ha prodotto un crash del motore in fase di scrittura del
  test, poi corretto restringendo l'ambito).

## Documenti sincronizzati

- [x] Nessuno atteso: è una correzione interna che non cambia un contratto
      di prodotto o di architettura.

## Note

La duplicazione delle shape serve a rendere indipendenti le collisioni di ogni
nemico: la soluzione non è rimuoverla, ma eseguirla quando il server fisico lo
consente (per esempio differendo lo spawn dei frammenti o la sostituzione delle
shape di un frame).

Evidenza di chiusura (2026-09-02), Godot 4.7.1 headless in sandbox Linux:

```
godot --headless --path . -s addons/gut/gut_cmdln.gd \
  -gtest=tests/unit/test_ps057_splitter_spawn_physics.gd -gexit
```

`2/2` test passati, `28` assert, log pulito. Disattivando temporaneamente il
fix (`git stash -- scripts/actors/splitter_enemy.gd`) lo stesso smoke riproduce
tutte e quattro le firme documentate nel Contesto (`12` `body_set_shape_as_one_way_collision`,
`8` `area_set_shape_disabled`, `4` `body_set_shape_disabled`, `4`
`set_monitorable`, `28` righe `ERROR:` totali), confermando che il test
intercetta il difetto reale.

Pipeline di catture UI (lo scenario che aveva rivelato il difetto in PS-044):

```
xvfb-run --auto-servernum --server-args="-screen 0 2424x1080x24" \
  godot --path . --script tools/_capture_ui_screenshots.gd
```

`CAPTURE_DONE`, 26 catture completate, zero righe `ERROR:` riconducibili a
`base_enemy.gd`/`enemy_spawner.gd` o alle quattro firme documentate (l'unica
`ERROR:` del log riguarda l'inizializzazione ALSA del sandbox, senza driver
audio disponibile: irrilevante per questa card).
