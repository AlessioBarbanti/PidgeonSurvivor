extends GutGameplayTest

## PS-095 — Audit: lo spawn nemici deve restare fuori dall'area
## effettivamente visibile, con ArenaLayout e Camera2D reali (non rettangoli
## sintetici come in test_b04_enemy_spawner.gd).
##
## Causa radice individuata: EnemySpawner.get_visible_reference_rect()
## trattava le dimensioni del *playfield* di ArenaLayout (il crop a
## target_aspect_ratio, default 16:9) come "lo schermo", ricentrandole sulla
## vista camera corrente. Ma project.godot usa
## window/stretch/aspect="expand": mondo, Camera2D e nemici riempiono
## l'intero viewport reale qualunque sia il suo aspect ratio, senza
## letterbox. Su un dispositivo piu' largo del target_aspect_ratio (es. un
## Android landscape 20:9, uno dei due target co-primari del progetto) il
## playfield e' quindi PIU' STRETTO dello schermo davvero visibile: un
## nemico piazzato "appena fuori" dal playfield puo' cadere ben dentro la
## fascia che lo schermo mostra comunque. Lo stesso rettangolo di
## ArenaLayout viene inoltre aggiornato in modo differito (call_deferred) su
## resize/cambio orientamento: nel frame fra il resize e quel refresh resta
## quello vecchio, mentre il viewport reale (Viewport.size) e' gia' quello
## nuovo.
##
## Percorsi coinvolti, tutti con la stessa causa e correzione perche'
## condividono lo stesso rettangolo di riferimento:
## - spawn ordinario (EnemySpawner.try_spawn_enemy -> _sample_position);
## - spawn a grappolo (stesso try_spawn_enemy, spawn_cluster_size > 1);
## - formazione evento (WaveEventScheduler._spawn_formation_unit, che legge
##   get_visible_reference_rect() dallo stesso EnemySpawner);
## - fallback geometrico (EnemySpawner.get_farthest_rect_corner): riceve in
##   ingresso lo stesso outer_rect derivato da get_visible_reference_rect(),
##   quindi e' corretto automaticamente quando quel rettangolo lo e' (un
##   angolo di viewport_rect.grow(outer_margin) resta per costruzione fuori
##   da viewport_rect quando outer_margin > 0, verificato staticamente sotto).

const ENEMY_SCENE: PackedScene = preload("res://scenes/actors/base_enemy.tscn")
const CONFIGURABLE_ENEMY_SCENE: PackedScene = preload("res://scenes/actors/configurable_enemy.tscn")
const WIDE_VIEWPORT_SIZE := Vector2i(2400, 1080)
const RESIZED_VIEWPORT_SIZE := Vector2i(2560, 1080)


func after_each() -> void:
	get_tree().root.content_scale_size = INITIAL_VIEWPORT_SIZE
	get_tree().root.size = INITIAL_VIEWPORT_SIZE
	await wait_process_frames(1)


## Riproduce la segnalazione del proprietario: su un'aspect ratio piu' larga
## del target 16:9 del playfield (20:9, come i device Android landscape
## co-primari), spawn ordinario e a grappolo restano nel rettangolo del
## playfield mentre lo schermo reale (senza letterbox) mostra molto di piu'.
func test_ordinary_and_cluster_spawn_stay_outside_real_viewport_on_wide_aspect() -> void:
	get_tree().root.content_scale_size = WIDE_VIEWPORT_SIZE
	get_tree().root.size = WIDE_VIEWPORT_SIZE
	await wait_process_frames(2)

	var built := await _build_fixture(950111)
	var arena: ArenaLayout = built["arena"]
	var camera: Camera2D = built["camera"]
	var spawner: EnemySpawner = built["spawner"]

	assert_true(
		arena.get_playfield_rect().size.x < arena.get_viewport_rect().size.x - 1.0,
		"Precondizione del test: su 20:9 il playfield deve restare piu' stretto del viewport reale."
	)

	for _spawn_index in range(5):
		assert_true(is_instance_valid(spawner.try_spawn_enemy()), "Ogni tentativo di spawn deve produrre un nemico.")

	assert_true(spawner.get_alive_count() >= 5, "Il grappolo (spawn_cluster_size=3) deve produrre piu' nemici di quanti try_spawn_enemy() sono stati chiamati.")

	var real_rect := _real_visible_rect(arena, camera)
	for enemy in spawner.get_spawned_enemies():
		assert_false(
			EnemySpawner.is_point_in_rect_inclusive(real_rect, enemy.global_position),
			"Un nemico e' comparso dentro l'area effettivamente visibile a 20:9: %s in %s" % [enemy.global_position, real_rect]
		)


## Riproduce la finestra di razza fra un resize/cambio orientamento e il
## refresh differito di ArenaLayout: lo spawner non deve usare un
## playfield_rect ancora vecchio quando il viewport e' gia' cambiato.
func test_ordinary_spawn_stays_outside_real_viewport_immediately_after_resize() -> void:
	get_tree().root.content_scale_size = INITIAL_VIEWPORT_SIZE
	get_tree().root.size = INITIAL_VIEWPORT_SIZE
	await wait_process_frames(2)

	var built := await _build_fixture(950112)
	var arena: ArenaLayout = built["arena"]
	var camera: Camera2D = built["camera"]
	var spawner: EnemySpawner = built["spawner"]

	assert_true(is_instance_valid(spawner.try_spawn_enemy()), "Baseline pre-resize.")

	# Un ingrandimento live del viewport puo' legittimamente rendere visibile
	# un nemico gia' piazzato correttamente fuori dalla vista PIU' STRETTA di
	# prima: non e' un bug dello spawner (non puo' prevedere un resize
	# futuro). Il contratto di questa card riguarda solo i nemici spawnati
	# DOPO il resize: la baseline pre-resize va quindi scartata prima di
	# ridimensionare, cosicche' il controllo below isoli solo il caso reale.
	spawner.clear_spawned_enemies()

	# Resize "live", senza attendere alcun frame: ArenaLayout.refresh_layout()
	# e' schedulato con call_deferred e non ha ancora aggiornato
	# _playfield_rect quando lo spawner campiona la posizione successiva.
	get_tree().root.content_scale_size = RESIZED_VIEWPORT_SIZE
	get_tree().root.size = RESIZED_VIEWPORT_SIZE

	assert_true(
		arena.get_viewport_rect().size.x > arena.get_playfield_rect().size.x + 1.0,
		"Precondizione del test: il viewport deve gia' riflettere il resize prima del refresh differito di ArenaLayout."
	)

	assert_true(is_instance_valid(spawner.try_spawn_enemy()), "Lo spawn subito dopo un resize deve comunque produrre un nemico.")

	var real_rect := _real_visible_rect(arena, camera)
	for enemy in spawner.get_spawned_enemies():
		assert_false(
			EnemySpawner.is_point_in_rect_inclusive(real_rect, enemy.global_position),
			"Un nemico e' comparso dentro l'area visibile subito dopo un resize: %s in %s" % [enemy.global_position, real_rect]
		)

	print("PS095_ENEMY_SPAWN_OFF_SCREEN_OK")


## Le formazioni evento (WaveEventScheduler) riusano get_visible_reference_rect()
## dello stesso EnemySpawner: stessa causa, stessa correzione.
func test_formation_event_spawn_stays_outside_real_viewport() -> void:
	get_tree().root.content_scale_size = WIDE_VIEWPORT_SIZE
	get_tree().root.size = WIDE_VIEWPORT_SIZE
	await wait_process_frames(2)

	var built := await _build_fixture(950113)
	var arena: ArenaLayout = built["arena"]
	var camera: Camera2D = built["camera"]
	var spawner: EnemySpawner = built["spawner"]

	var scheduler := WaveEventScheduler.new()
	add_child_autofree(scheduler)
	scheduler._rng.seed = 950113
	var definition := WaveEventDefinition.new()
	definition.event_id = &"ps095_formation_test"
	definition.formation_archetype_id = &"ps095_wide_cluster"
	definition.formation_enemy_count = 16
	definition.formation_spawn_interval_seconds = 0.05
	scheduler._enemy_spawner = spawner
	scheduler._active_definition = definition

	# 16 tentativi rendono statisticamente certo campionare almeno un lato
	# est/ovest (dove l'aspect ratio 20:9 apre il divario col playfield).
	for _formation_index in range(16):
		assert_true(scheduler._spawn_formation_unit(), "Ogni unita' della formazione deve spawnare correttamente.")

	var real_rect := _real_visible_rect(arena, camera)
	for enemy in spawner.get_spawned_enemies():
		assert_false(
			EnemySpawner.is_point_in_rect_inclusive(real_rect, enemy.global_position),
			"Un nemico da formazione evento e' comparso dentro l'area visibile: %s in %s" % [enemy.global_position, real_rect]
		)


## Documenta perche' il fallback geometrico resta corretto per costruzione
## una volta che il rettangolo di riferimento in ingresso e' quello giusto:
## qualunque angolo di outer_rect (= viewport_rect cresciuto di outer_margin)
## e' sempre fuori da viewport_rect quando outer_margin > 0.
func test_fallback_corner_is_always_outside_reference_rect() -> void:
	var viewport_rect := Rect2(Vector2(100.0, 50.0), Vector2(800.0, 400.0))
	var outer_rect := viewport_rect.grow(160.0)
	var corner := EnemySpawner.get_farthest_rect_corner(outer_rect, viewport_rect.get_center())
	assert_false(
		EnemySpawner.is_point_in_rect_inclusive(viewport_rect, corner),
		"Il fallback geometrico deve restare fuori dal rettangolo di riferimento quando questo e' corretto."
	)


## Rettangolo effettivamente visibile calcolato in modo indipendente dalla
## funzione sotto test (get_visible_reference_rect): viewport reale corrente,
## centrato sulla vista camera corrente.
func _real_visible_rect(arena: ArenaLayout, camera: Camera2D) -> Rect2:
	var viewport_size := arena.get_viewport_rect().size
	var center := camera.get_screen_center_position()
	return Rect2(center - viewport_size * 0.5, viewport_size)


func _build_fixture(seed_value: int) -> Dictionary:
	var fixture := Node2D.new()
	var arena := ArenaLayout.new()
	arena.respect_display_safe_area = false
	var controller := RunController.new()
	controller.set_process(false)
	var target := Node2D.new()
	var camera := Camera2D.new()
	target.add_child(camera)
	var enemy_parent := Node2D.new()
	var spawner := EnemySpawner.new()
	spawner.set_process(false)

	var profile := EnemySpawnProfile.new()
	profile.base_spawn_interval = 0.05
	profile.min_spawn_interval = 0.05
	profile.spawn_acceleration = 0.0
	profile.initial_spawn_delay = 0.0
	profile.max_alive_enemies = 64
	profile.inner_spawn_margin = 48.0
	profile.outer_spawn_margin = 160.0
	profile.min_player_distance = 0.0
	profile.spawn_sample_attempts = 8
	profile.cleanup_interval = 30.0
	profile.despawn_margin = 320.0
	profile.base_archetype_weight = 0.0

	var wide_cluster := EnemyArchetypeDefinition.new()
	wide_cluster.id = &"ps095_wide_cluster"
	wide_cluster.scene = CONFIGURABLE_ENEMY_SCENE
	wide_cluster.spawn_weight = 1.0
	wide_cluster.eligible_time_start = 0.0
	wide_cluster.eligible_time_end = 3600.0
	wide_cluster.spawn_cluster_size = 3
	wide_cluster.health_max = 9.0
	wide_cluster.move_speed = 200.0
	wide_cluster.collision_radius = 14.0
	wide_cluster.contact_damage = 10.0
	wide_cluster.experience_amount = 1

	spawner.enemy_scene = ENEMY_SCENE
	spawner.spawn_profile = profile
	spawner.archetypes = [wide_cluster]

	fixture.add_child(arena)
	fixture.add_child(controller)
	fixture.add_child(target)
	fixture.add_child(enemy_parent)
	fixture.add_child(spawner)
	add_child_autofree(fixture)
	await wait_process_frames(1)

	spawner.configure(controller, arena, target, enemy_parent, camera)
	camera.make_current()
	target.global_position = arena.get_viewport_rect().get_center()
	camera.global_position = target.global_position

	controller.start_run(seed_value)
	# Il roll periodico dei settori attivi (EnemySpawner._roll_active_sectors)
	# lascia di norma un solo lato attivo: forzare tutti i lati rende questo
	# fixture deterministico rispetto al seed invece di dipendere dalla
	# fortuna di ripescare est/ovest, dove il divario 20:9 si manifesta.
	spawner.set_active_sector_override(EnemySpawner.ALL_SECTORS.duplicate())
	return {
		"fixture": fixture,
		"arena": arena,
		"controller": controller,
		"target": target,
		"camera": camera,
		"enemy_parent": enemy_parent,
		"spawner": spawner,
	}
