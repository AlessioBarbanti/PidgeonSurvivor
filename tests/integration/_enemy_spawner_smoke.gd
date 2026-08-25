extends SceneTree

const ENEMY_SCENE: PackedScene = preload("res://scenes/actors/base_enemy.tscn")
const MOVEMENT_SLICE_SCENE: PackedScene = preload(
	"res://scenes/game/movement_slice.tscn"
)
const INITIAL_VIEWPORT_SIZE := Vector2i(1280, 720)
const RESIZED_VIEWPORT_SIZE := Vector2i(960, 720)
const FLOAT_TOLERANCE := 0.001

var _failures: Array[String] = []
var _removed_enemy_ids: Array[int] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	paused = false
	root.content_scale_size = INITIAL_VIEWPORT_SIZE
	root.size = INITIAL_VIEWPORT_SIZE
	await _wait_processed_frame()

	_validate_spawn_profile()
	await _validate_run_controller()
	_validate_spawn_sampling()
	await _validate_base_enemy()
	await _validate_enemy_spawner()
	await _validate_composed_scene()
	await _finish()


func _validate_spawn_profile() -> void:
	var profile := EnemySpawnProfile.new()
	profile.base_spawn_interval = 2.0
	profile.min_spawn_interval = 0.5
	profile.spawn_acceleration = 0.1

	_expect_float_near(
		profile.get_spawn_interval(-20.0),
		2.0,
		FLOAT_TOLERANCE,
		"Il tempo run negativo deve essere sanitizzato a zero."
	)
	_expect_float_near(
		profile.get_spawn_interval(5.0),
		1.5,
		FLOAT_TOLERANCE,
		"La formula dello spawn interval deve usare il tempo della run."
	)
	_expect_float_near(
		profile.get_spawn_interval(100.0),
		0.5,
		FLOAT_TOLERANCE,
		"Lo spawn interval deve rispettare il minimo configurato."
	)

	profile.base_spawn_interval = -4.0
	profile.min_spawn_interval = -3.0
	profile.spawn_acceleration = -2.0
	profile.initial_spawn_delay = -1.0
	profile.max_alive_enemies = 0
	profile.inner_spawn_margin = -8.0
	profile.outer_spawn_margin = -9.0
	profile.min_player_distance = -10.0
	profile.spawn_sample_attempts = 0
	profile.cleanup_interval = 0.0
	profile.despawn_margin = -11.0

	_expect_float_near(
		profile.base_spawn_interval,
		EnemySpawnProfile.MINIMUM_INTERVAL_SECONDS,
		FLOAT_TOLERANCE,
		"Il base interval deve essere positivo."
	)
	_expect_float_near(
		profile.min_spawn_interval,
		EnemySpawnProfile.MINIMUM_INTERVAL_SECONDS,
		FLOAT_TOLERANCE,
		"Il min interval deve essere positivo."
	)
	_expect(profile.spawn_acceleration == 0.0, "L'accelerazione non puo essere negativa.")
	_expect(profile.initial_spawn_delay == 0.0, "Il delay iniziale non puo essere negativo.")
	_expect(profile.max_alive_enemies == 1, "Il cap deve consentire almeno un nemico.")
	_expect(profile.inner_spawn_margin == 0.0, "Il margine interno non puo essere negativo.")
	_expect(profile.outer_spawn_margin == 0.0, "Il margine esterno non puo essere negativo.")
	_expect(profile.min_player_distance == 0.0, "La distanza dal Player non puo essere negativa.")
	_expect(profile.spawn_sample_attempts == 1, "Il sampling deve eseguire almeno un tentativo.")
	_expect_float_near(
		profile.get_effective_cleanup_interval(),
		EnemySpawnProfile.MINIMUM_INTERVAL_SECONDS,
		FLOAT_TOLERANCE,
		"L'intervallo di cleanup effettivo deve restare positivo."
	)

	profile.inner_spawn_margin = 70.0
	profile.outer_spawn_margin = 20.0
	profile.despawn_margin = 30.0
	_expect_float_near(
		profile.get_effective_outer_spawn_margin(),
		70.0,
		FLOAT_TOLERANCE,
		"Il margine esterno effettivo non deve entrare nell'anello interno."
	)
	_expect_float_near(
		profile.get_effective_despawn_margin(),
		70.0,
		FLOAT_TOLERANCE,
		"Il despawn non deve tagliare l'anello di spawn."
	)


func _validate_run_controller() -> void:
	var controller := RunController.new()
	controller.set_process(false)
	root.add_child(controller)
	await process_frame

	_expect(
		controller.get_state() == RunController.RunState.BOOT,
		"RunController deve iniziare in BOOT."
	)
	_expect(not paused, "BOOT non deve lasciare SceneTree in pausa.")
	controller._process(3.0)
	_expect_float_near(controller.get_run_time(), 0.0, FLOAT_TOLERANCE, "Il clock deve fermarsi in BOOT.")
	_expect(not controller.request_state(RunController.RunState.BOOT), "BOOT non deve essere richiedibile come stato ordinario.")

	_expect(controller.start_run(424242), "Una run deve partire da BOOT.")
	_expect(controller.get_seed() == 424242, "Il seed della run deve essere conservato.")
	_expect(controller.is_running() and not paused, "RUNNING deve lasciare attivo SceneTree.")
	_expect(not controller.start_run(9), "Una run gia avviata non deve ripartire.")
	controller._process(1.25)
	controller._process(-4.0)
	_expect_float_near(
		controller.get_run_time(),
		1.25,
		FLOAT_TOLERANCE,
		"Il clock deve avanzare solo con delta non negativo in RUNNING."
	)

	_expect(controller.request_manual_pause(), "RUNNING deve accettare la pausa manuale.")
	_expect(paused, "MANUAL_PAUSE deve essere l'autorita sulla pausa del SceneTree.")
	controller._process(10.0)
	_expect_float_near(controller.get_run_time(), 1.25, FLOAT_TOLERANCE, "Il clock deve fermarsi in pausa.")
	_expect(controller.resume_run(), "La pausa manuale deve poter riprendere.")
	_expect(controller.is_running() and not paused, "Il resume deve tornare a RUNNING.")

	_expect(controller.request_level_up(), "RUNNING deve accettare LEVEL_UP.")
	_expect(paused, "LEVEL_UP deve mettere in pausa SceneTree.")
	_expect(controller.complete_level_up(), "LEVEL_UP deve poter essere completato.")
	_expect(not paused, "Completare LEVEL_UP deve riprendere la run.")
	_expect(controller.request_boss_intro(), "RUNNING deve accettare BOSS_INTRO.")
	_expect(paused, "BOSS_INTRO deve mettere in pausa SceneTree.")
	_expect(controller.complete_boss_intro(), "BOSS_INTRO deve poter essere completato.")
	controller._process(0.75)
	_expect_float_near(controller.get_run_time(), 2.0, FLOAT_TOLERANCE, "Il clock deve riprendere dopo gli stati modali.")

	_expect(controller.request_victory(), "RUNNING deve accettare uno stato terminale.")
	_expect(controller.is_terminal() and paused, "VICTORY deve bloccare e mettere in pausa la run.")
	_expect(not controller.request_defeat(), "Uno stato terminale deve restare bloccato.")
	_expect(not controller.resume_run(), "Un terminale non deve essere ripreso come pausa manuale.")
	controller._process(50.0)
	_expect_float_near(controller.get_run_time(), 2.0, FLOAT_TOLERANCE, "Il clock deve fermarsi nel terminale.")

	_expect(controller.prepare_restart(), "Il terminale deve poter preparare il restart.")
	_expect(
		controller.get_state() == RunController.RunState.BOOT
		and controller.get_seed() == 0
		and is_zero_approx(controller.get_run_time()),
		"Il restart deve ripristinare stato, seed e clock."
	)
	_expect(not paused, "Il restart deve sempre rimuovere la pausa del SceneTree.")
	_expect(controller.start_run(7), "Dopo il restart deve poter partire una nuova run.")
	_expect(controller.request_defeat(), "La nuova run deve poter terminare in DEFEAT.")
	_expect(controller.get_state() == RunController.RunState.DEFEAT, "DEFEAT deve essere terminale.")
	controller.prepare_restart()
	paused = false
	controller.queue_free()
	await process_frame


func _validate_spawn_sampling() -> void:
	var viewport_a := Rect2(Vector2(80.0, 40.0), Vector2(640.0, 360.0))
	var viewport_b := Rect2(Vector2(-120.0, 75.0), Vector2(900.0, 500.0))
	var inner_margin := 32.0
	var outer_margin := 110.0
	var player_a := viewport_a.get_center()
	var player_b := viewport_b.get_center()

	var responsive_rng := RandomNumberGenerator.new()
	responsive_rng.seed = 13579
	var spawn_a := EnemySpawner.sample_spawn_position(
		viewport_a, inner_margin, outer_margin, player_a, 0.0, 8, responsive_rng
	)
	var spawn_b := EnemySpawner.sample_spawn_position(
		viewport_b, inner_margin, outer_margin, player_b, 0.0, 8, responsive_rng
	)
	_expect_spawn_ring(spawn_a, viewport_a, inner_margin, outer_margin, "viewport traslata A")
	_expect_spawn_ring(spawn_b, viewport_b, inner_margin, outer_margin, "viewport ridimensionata B")

	var deterministic_a := RandomNumberGenerator.new()
	var deterministic_b := RandomNumberGenerator.new()
	deterministic_a.seed = 8675309
	deterministic_b.seed = 8675309
	for sequence_index in range(8):
		var position_a := EnemySpawner.sample_spawn_position(
			viewport_a, inner_margin, outer_margin, player_a, 180.0, 12, deterministic_a
		)
		var position_b := EnemySpawner.sample_spawn_position(
			viewport_a, inner_margin, outer_margin, player_a, 180.0, 12, deterministic_b
		)
		_expect_vector_near(
			position_a,
			position_b,
			0.0,
			"Lo stesso seed deve riprodurre lo spawn %d." % sequence_index
		)

	# I tentativi singoli espongono la stessa sequenza RNG usata dal batch.
	# Questo permette di verificare l'accettazione del primo candidato valido
	# senza duplicare l'algoritmo di sampling nel test.
	const SAMPLE_COUNT := 10
	const SAMPLE_SEED := 24680
	var candidates: Array[Vector2] = []
	var candidate_rng := RandomNumberGenerator.new()
	candidate_rng.seed = SAMPLE_SEED
	for _sample_index in range(SAMPLE_COUNT):
		candidates.append(EnemySpawner.sample_spawn_position(
			viewport_a,
			inner_margin,
			outer_margin,
			player_a,
			0.0,
			1,
			candidate_rng
		))

	var minimum_distance := INF
	var maximum_distance := -INF
	var farthest_candidate := candidates[0]
	for candidate in candidates:
		var distance := candidate.distance_to(player_a)
		minimum_distance = minf(minimum_distance, distance)
		if distance > maximum_distance:
			maximum_distance = distance
			farthest_candidate = candidate

	var required_distance := lerpf(minimum_distance, maximum_distance, 0.65)
	var expected_accepted := farthest_candidate
	for candidate in candidates:
		if candidate.distance_to(player_a) >= required_distance:
			expected_accepted = candidate
			break
	var distance_rng := RandomNumberGenerator.new()
	distance_rng.seed = SAMPLE_SEED
	var accepted := EnemySpawner.sample_spawn_position(
		viewport_a,
		inner_margin,
		outer_margin,
		player_a,
		required_distance,
		SAMPLE_COUNT,
		distance_rng
	)
	_expect(
		accepted.distance_to(player_a) + FLOAT_TOLERANCE >= required_distance,
		"Il sampling deve rispettare la distanza minima quando un candidato valido esiste."
	)
	_expect_vector_near(
		accepted,
		expected_accepted,
		0.0,
		"Il sampling deve accettare il primo candidato abbastanza distante."
	)

	var outer_rect := viewport_a.grow(outer_margin)
	var expected_farthest_corner := EnemySpawner.get_farthest_rect_corner(
		outer_rect,
		player_a
	)
	var first_candidate_distance := candidates[0].distance_to(player_a)
	var farthest_corner_distance := expected_farthest_corner.distance_to(player_a)
	var fallback_required_distance := lerpf(
		first_candidate_distance,
		farthest_corner_distance,
		0.5
	)
	var geometric_fallback_rng := RandomNumberGenerator.new()
	geometric_fallback_rng.seed = SAMPLE_SEED
	var geometric_fallback := EnemySpawner.sample_spawn_position(
		viewport_a,
		inner_margin,
		outer_margin,
		player_a,
		fallback_required_distance,
		1,
		geometric_fallback_rng
	)
	_expect_vector_near(
		geometric_fallback,
		expected_farthest_corner,
		0.0,
		"Il fallback geometrico deve scegliere l'angolo esterno piu lontano."
	)
	_expect(
		geometric_fallback.distance_to(player_a) + FLOAT_TOLERANCE
		>= fallback_required_distance,
		"Il fallback deve garantire la distanza minima quando e geometricamente possibile."
	)

	var impossible_fallback_rng := RandomNumberGenerator.new()
	impossible_fallback_rng.seed = SAMPLE_SEED
	var impossible_fallback := EnemySpawner.sample_spawn_position(
		viewport_a,
		inner_margin,
		outer_margin,
		player_a,
		1.0e20,
		SAMPLE_COUNT,
		impossible_fallback_rng
	)
	_expect_vector_near(
		impossible_fallback,
		expected_farthest_corner,
		0.0,
		"Se la distanza e impossibile, il fallback deve usare il massimo geometrico."
	)
	_expect(
		not EnemySpawner.sample_spawn_position(
			Rect2(), 10.0, 20.0, Vector2.ZERO, 0.0, 1, impossible_fallback_rng
		).is_finite(),
		"Una viewport senza area non deve produrre uno spawn finito."
	)
	_expect(
		not EnemySpawner.sample_spawn_position(
			viewport_a, 10.0, 20.0, Vector2.ZERO, 0.0, 1, null
		).is_finite(),
		"Un RNG assente non deve produrre uno spawn finito."
	)


func _validate_base_enemy() -> void:
	var fixture := Node2D.new()
	fixture.name = "BaseEnemyFixture"
	var target := Node2D.new()
	target.name = "Target"
	var controller := RunController.new()
	controller.name = "RunController"
	controller.set_process(false)
	var enemy_a := ENEMY_SCENE.instantiate() as BaseEnemy
	var enemy_b := ENEMY_SCENE.instantiate() as BaseEnemy
	fixture.add_child(target)
	fixture.add_child(controller)
	fixture.add_child(enemy_a)
	fixture.add_child(enemy_b)
	root.add_child(fixture)
	await process_frame
	enemy_a.set_physics_process(false)
	enemy_b.set_physics_process(false)

	var shape_a := (enemy_a.get_node("CollisionShape") as CollisionShape2D).shape
	var shape_b := (enemy_b.get_node("CollisionShape") as CollisionShape2D).shape
	_expect(
		shape_a != null and shape_b != null
		and shape_a.get_instance_id() != shape_b.get_instance_id(),
		"Ogni BaseEnemy deve possedere una collision shape unica."
	)
	enemy_a.collision_radius = 31.0
	_expect_float_near(
		(shape_a as CircleShape2D).radius,
		31.0,
		FLOAT_TOLERANCE,
		"Cambiare il raggio deve aggiornare la shape del solo nemico."
	)
	_expect_float_near(
		(shape_b as CircleShape2D).radius,
		20.0,
		FLOAT_TOLERANCE,
		"Le shape delle altre istanze non devono essere mutate."
	)

	controller.start_run(101)
	enemy_a.global_position = Vector2(100.0, 120.0)
	target.global_position = Vector2(300.0, 120.0)
	enemy_a.set_target(target)
	enemy_a.set_run_controller(controller)
	enemy_a._physics_process(1.0 / 60.0)
	_expect_vector_near(
		enemy_a.velocity,
		Vector2.RIGHT * enemy_a.move_speed,
		FLOAT_TOLERANCE,
		"BaseEnemy deve inseguire il target alla velocita configurata."
	)

	target.global_position = enemy_a.global_position
	enemy_a._physics_process(1.0 / 60.0)
	_expect_vector_near(enemy_a.velocity, Vector2.ZERO, FLOAT_TOLERANCE, "Sul target il nemico deve fermarsi.")
	target.global_position = enemy_a.global_position + Vector2.UP * 200.0
	enemy_a._physics_process(1.0 / 60.0)
	_expect(enemy_a.velocity.y < 0.0, "Il nemico deve aggiornare la direzione di inseguimento.")
	controller.request_manual_pause()
	_expect_vector_near(
		enemy_a.velocity,
		Vector2.ZERO,
		FLOAT_TOLERANCE,
		"L'ingresso in pausa deve arrestare subito BaseEnemy."
	)
	enemy_a._physics_process(1.0 / 60.0)
	_expect_vector_near(enemy_a.velocity, Vector2.ZERO, FLOAT_TOLERANCE, "BaseEnemy non deve inseguire fuori RUNNING.")
	controller.resume_run()
	enemy_a._physics_process(1.0 / 60.0)
	_expect(enemy_a.velocity.y < 0.0, "BaseEnemy deve riprendere l'inseguimento con la run.")
	controller.request_victory()
	_expect_vector_near(enemy_a.velocity, Vector2.ZERO, FLOAT_TOLERANCE, "Un terminale deve arrestare BaseEnemy.")
	enemy_a.clear_chase_dependencies()
	_expect(
		enemy_a.get_target() == null
		and enemy_a.get_run_controller() == null
		and enemy_a.velocity == Vector2.ZERO,
		"La pulizia delle dipendenze deve arrestare e scollegare BaseEnemy."
	)

	controller.prepare_restart()
	paused = false
	fixture.queue_free()
	await process_frame


func _validate_enemy_spawner() -> void:
	_removed_enemy_ids.clear()
	var fixture := Node2D.new()
	fixture.name = "EnemySpawnerFixture"
	var arena := ArenaLayout.new()
	arena.name = "ArenaLayout"
	arena.respect_display_safe_area = false
	var controller := RunController.new()
	controller.name = "RunController"
	controller.set_process(false)
	var target := Node2D.new()
	target.name = "Target"
	var enemy_parent := Node2D.new()
	enemy_parent.name = "Enemies"
	var spawner := EnemySpawner.new()
	spawner.name = "EnemySpawner"
	spawner.set_process(false)
	var profile := EnemySpawnProfile.new()
	profile.base_spawn_interval = 0.25
	profile.min_spawn_interval = 0.25
	profile.spawn_acceleration = 0.0
	profile.initial_spawn_delay = 0.5
	profile.max_alive_enemies = 3
	profile.inner_spawn_margin = 24.0
	profile.outer_spawn_margin = 64.0
	profile.min_player_distance = 0.0
	profile.spawn_sample_attempts = 4
	profile.cleanup_interval = 0.5
	profile.despawn_margin = 96.0
	spawner.enemy_scene = ENEMY_SCENE
	spawner.spawn_profile = profile
	spawner.configure(controller, arena, target, enemy_parent)
	spawner.enemy_spawned.connect(_freeze_spawned_enemy)
	spawner.enemy_removed.connect(_on_enemy_removed)
	fixture.add_child(arena)
	fixture.add_child(controller)
	fixture.add_child(target)
	fixture.add_child(enemy_parent)
	fixture.add_child(spawner)
	root.add_child(fixture)
	await _wait_processed_frame()
	spawner.set_process(false)
	controller.set_process(false)
	target.global_position = arena.get_viewport_rect().get_center()

	spawner._process(100.0)
	_expect(spawner.get_alive_count() == 0, "Lo scheduler non deve spawnare in BOOT.")
	_expect_float_near(spawner.get_spawn_elapsed(), 0.0, FLOAT_TOLERANCE, "BOOT non deve accumulare credito di spawn.")
	_expect(controller.start_run(777), "La fixture dello spawner deve avviare la run.")
	_expect(spawner.is_waiting_for_initial_spawn(), "Una nuova run deve attendere il delay iniziale.")

	spawner._process(0.49)
	_expect(spawner.get_alive_count() == 0, "Non deve esserci spawn prima del delay iniziale.")
	spawner._process(0.02)
	_expect(spawner.get_alive_count() == 1, "Il primo spawn deve avvenire al superamento del delay.")
	_expect(not spawner.is_waiting_for_initial_spawn(), "Dopo il primo spawn deve iniziare la cadenza ordinaria.")
	_validate_spawned_enemy(spawner.get_spawned_enemies()[0], target, controller, arena.get_playfield_rect(), profile)

	spawner._process(10.0)
	_expect(spawner.get_alive_count() == 2, "Un delta grande deve produrre al massimo uno spawn per tick.")
	_expect_float_near(spawner.get_spawn_elapsed(), 0.0, FLOAT_TOLERANCE, "Uno spawn riuscito deve consumare il credito.")
	spawner._process(0.0)
	_expect(spawner.get_alive_count() == 2, "Lo scheduler non deve generare un burst nello stesso credito.")
	spawner._process(0.25)
	_expect(spawner.get_alive_count() == 3, "Lo scheduler deve raggiungere il cap configurato.")
	spawner._process(4.0)
	_expect(spawner.get_alive_count() == 3, "Il cap deve impedire ulteriori spawn.")
	_expect_float_near(
		spawner.get_spawn_elapsed(),
		0.25,
		FLOAT_TOLERANCE,
		"Al cap il credito deve essere limitato a un solo intervallo."
	)

	var removed_for_slot := spawner.get_spawned_enemies()[0]
	var removed_for_slot_id := removed_for_slot.get_instance_id()
	removed_for_slot.queue_free()
	await process_frame
	_expect(spawner.get_alive_count() == 2, "Liberare un nemico deve aprire uno slot nel cap.")
	_expect(removed_for_slot_id in _removed_enemy_ids, "La rimozione deve aggiornare il registro dello spawner.")
	spawner._process(0.0)
	_expect(spawner.get_alive_count() == 3, "Uno slot libero deve usare il singolo credito conservato.")
	spawner._process(0.0)
	_expect(spawner.get_alive_count() == 3, "Lo slot libero non deve causare spawn multipli."
	)

	var cleanup_enemies := spawner.get_spawned_enemies()
	var viewport_rect := arena.get_viewport_rect()
	var despawn_rect := viewport_rect.grow(profile.get_effective_despawn_margin())
	cleanup_enemies[0].global_position = Vector2(despawn_rect.end.x, viewport_rect.get_center().y)
	cleanup_enemies[1].global_position = Vector2(despawn_rect.end.x + 1.0, viewport_rect.get_center().y)
	var cleanup_count := spawner.cleanup_outside_despawn_rect()
	_expect(cleanup_count == 1, "Il cleanup deve rimuovere soltanto i nemici oltre il despawn rect.")
	_expect(
		not cleanup_enemies[0].is_queued_for_deletion(),
		"Il bordo inclusivo del despawn rect deve essere conservato."
	)
	_expect(cleanup_enemies[1].is_queued_for_deletion(), "Un nemico oltre il margine deve essere accodato alla rimozione.")
	await process_frame
	_expect(spawner.get_alive_count() == 2, "Il registro deve riflettere il cleanup completato.")

	var elapsed_before_pause := spawner.get_spawn_elapsed()
	controller.request_manual_pause()
	var count_before_pause := spawner.get_alive_count()
	spawner._process(100.0)
	_expect(spawner.get_alive_count() == count_before_pause, "MANUAL_PAUSE deve chiudere il gate dello spawn.")
	_expect_float_near(
		spawner.get_spawn_elapsed(),
		elapsed_before_pause,
		FLOAT_TOLERANCE,
		"La pausa non deve accumulare tempo nello scheduler."
	)
	controller.resume_run()
	spawner._process(0.25)
	_expect(spawner.get_alive_count() == 3, "Lo scheduler deve riprendere dopo MANUAL_PAUSE.")

	var removed_before_terminal := spawner.get_spawned_enemies()[0]
	removed_before_terminal.queue_free()
	await process_frame
	var terminal_count := spawner.get_alive_count()
	controller.request_victory()
	var elapsed_before_terminal := spawner.get_spawn_elapsed()
	spawner._process(100.0)
	_expect(spawner.get_alive_count() == terminal_count, "Uno stato terminale deve chiudere il gate dello spawn.")
	_expect_float_near(
		spawner.get_spawn_elapsed(),
		elapsed_before_terminal,
		FLOAT_TOLERANCE,
		"Il terminale non deve accumulare credito di spawn."
	)
	controller.prepare_restart()
	paused = false
	_expect(
		spawner.get_alive_count() == 0
		and spawner.is_waiting_for_initial_spawn()
		and is_zero_approx(spawner.get_spawn_elapsed()),
		"Preparare il restart deve pulire immediatamente registro e scheduler."
	)
	_expect(
		enemy_parent.get_child_count() > 0,
		"I nodi accodati al free possono restare nel tree fino alla fine del frame."
	)
	await process_frame
	_expect(
		enemy_parent.get_child_count() == 0,
		"Il restart deve liberare tutti i nodi nemico entro la fine del frame."
	)

	fixture.queue_free()
	await process_frame
	paused = false


func _validate_composed_scene() -> void:
	root.content_scale_size = INITIAL_VIEWPORT_SIZE
	root.size = INITIAL_VIEWPORT_SIZE
	await _wait_processed_frame()
	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	root.add_child(movement_slice)
	await _wait_processed_frame()

	var arena := movement_slice.get_node_or_null("ArenaLayout") as ArenaLayout
	var controller := movement_slice.get_node_or_null("RunController") as RunController
	var spawner := movement_slice.get_node_or_null("EnemySpawner") as EnemySpawner
	var target := movement_slice.get_node_or_null("World/Player") as Player
	var enemy_parent := movement_slice.get_node_or_null("World/Enemies") as Node2D
	_expect(arena != null, "La scena composta deve contenere ArenaLayout.")
	_expect(controller != null, "La scena composta deve contenere RunController.")
	_expect(spawner != null, "La scena composta deve contenere EnemySpawner.")
	_expect(target != null, "La scena composta deve contenere Player.")
	_expect(enemy_parent != null, "La scena composta deve contenere il parent Enemies.")
	if arena == null or controller == null or spawner == null or target == null or enemy_parent == null:
		paused = false
		movement_slice.queue_free()
		await process_frame
		return

	spawner.set_process(false)
	controller.set_process(false)
	spawner.enemy_spawned.connect(_freeze_spawned_enemy)
	_expect(controller.is_running(), "La scena composta deve avviare RunController.")
	_expect(spawner.enemy_scene != null and spawner.spawn_profile != null, "La scena deve assegnare scena nemico e profilo.")
	_expect(
		spawner.get_run_controller() == controller
		and spawner.get_arena_layout() == arena
		and spawner.get_target() == target
		and spawner.get_enemy_parent() == enemy_parent,
		"EnemySpawner deve essere collegato ai nodi della scena composta."
	)

	spawner.reset_for_run(314159)
	await process_frame
	spawner._process(spawner.spawn_profile.initial_spawn_delay)
	_expect(spawner.get_alive_count() == 1, "La scena composta deve produrre il primo spawn schedulato.")
	if spawner.get_alive_count() == 1:
		_validate_spawned_enemy(
			spawner.get_spawned_enemies()[0],
			target,
			controller,
			arena.get_playfield_rect(),
			spawner.spawn_profile
		)

	root.content_scale_size = RESIZED_VIEWPORT_SIZE
	root.size = RESIZED_VIEWPORT_SIZE
	await _wait_processed_frame()
	await _wait_processed_frame()
	var resized_viewport := arena.get_viewport_rect()
	_expect_vector_near(
		resized_viewport.size,
		Vector2(RESIZED_VIEWPORT_SIZE),
		FLOAT_TOLERANCE,
		"ArenaLayout deve leggere la viewport dopo il resize."
	)
	_expect(arena.get_playfield_rect().has_area(), "Il playfield deve restare valido dopo il resize.")
	_expect_vector_near(
		target.global_position,
		arena.clamp_circle_center(target.global_position, target.collision_radius),
		FLOAT_TOLERANCE,
		"Il Player deve restare confinato dopo il resize."
	)

	spawner.reset_for_run(314159)
	await process_frame
	spawner._process(spawner.spawn_profile.initial_spawn_delay)
	_expect(spawner.get_alive_count() == 1, "Lo scheduler deve continuare a spawnare dopo il resize.")
	if spawner.get_alive_count() == 1:
		_validate_spawned_enemy(
			spawner.get_spawned_enemies()[0],
			target,
			controller,
			arena.get_playfield_rect(),
			spawner.spawn_profile
		)

	paused = false
	movement_slice.queue_free()
	await process_frame
	root.content_scale_size = INITIAL_VIEWPORT_SIZE
	root.size = INITIAL_VIEWPORT_SIZE
	await process_frame


func _validate_spawned_enemy(
	enemy: BaseEnemy,
	target: Node2D,
	controller: RunController,
	viewport_rect: Rect2,
	profile: EnemySpawnProfile
) -> void:
	_expect(is_instance_valid(enemy), "Lo spawn deve restituire un BaseEnemy valido.")
	if not is_instance_valid(enemy):
		return
	_expect(enemy.get_target() == target, "Il nemico deve ricevere il target configurato.")
	_expect(enemy.get_run_controller() == controller, "Il nemico deve ricevere RunController.")
	_expect(enemy.is_in_group(&"enemies"), "Il nemico deve appartenere al gruppo enemies.")
	_expect_spawn_ring(
		enemy.global_position,
		viewport_rect,
		profile.inner_spawn_margin,
		profile.get_effective_outer_spawn_margin(),
		"nemico istanziato"
	)


func _expect_spawn_ring(
	position: Vector2,
	viewport_rect: Rect2,
	inner_margin: float,
	outer_margin: float,
	context: String
) -> void:
	_expect(position.is_finite(), "Lo spawn %s deve essere finito." % context)
	if not position.is_finite():
		return
	_expect(
		not EnemySpawner.is_point_in_rect_inclusive(viewport_rect, position),
		"Lo spawn %s deve essere fuori dalla viewport." % context
	)
	_expect(
		EnemySpawner.is_point_in_rect_inclusive(viewport_rect.grow(outer_margin), position),
		"Lo spawn %s deve restare entro il margine esterno." % context
	)
	var outside_depth := _get_outside_depth(viewport_rect, position)
	_expect(
		outside_depth + FLOAT_TOLERANCE >= inner_margin
		and outside_depth <= outer_margin + FLOAT_TOLERANCE,
		"Lo spawn %s deve rispettare l'anello interno/esterno." % context
	)


func _get_outside_depth(bounds: Rect2, point: Vector2) -> float:
	return maxf(
		maxf(bounds.position.x - point.x, point.x - bounds.end.x),
		maxf(bounds.position.y - point.y, point.y - bounds.end.y)
	)


func _freeze_spawned_enemy(enemy: BaseEnemy) -> void:
	if is_instance_valid(enemy):
		enemy.set_physics_process(false)


func _on_enemy_removed(enemy_instance_id: int) -> void:
	_removed_enemy_ids.append(enemy_instance_id)


func _wait_processed_frame() -> void:
	# process_frame precede _process: due emissioni garantiscono un frame completato.
	await process_frame
	await process_frame


func _expect_float_near(
	actual: float,
	expected: float,
	tolerance: float,
	message: String
) -> void:
	_expect(
		absf(actual - expected) <= tolerance,
		"%s Atteso %s, ottenuto %s." % [message, expected, actual]
	)


func _expect_vector_near(
	actual: Vector2,
	expected: Vector2,
	tolerance: float,
	message: String
) -> void:
	_expect(
		actual.distance_to(expected) <= tolerance,
		"%s Atteso %s, ottenuto %s." % [message, expected, actual]
	)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	paused = false
	await process_frame
	if _failures.is_empty():
		print("B04_ENEMY_SPAWNER_SMOKE_OK")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	printerr("B04_ENEMY_SPAWNER_SMOKE_FAIL count=%d" % _failures.size())
	quit(1)
