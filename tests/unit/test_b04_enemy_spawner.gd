extends GutGameplayTest

const ENEMY_SCENE: PackedScene = preload("res://scenes/actors/base_enemy.tscn")
const RESIZED_VIEWPORT_SIZE := Vector2i(960, 720)

var _removed_enemy_ids: Array[int] = []


func test_spawn_profile() -> void:
	var profile := EnemySpawnProfile.new()
	profile.base_spawn_interval = 2.0
	profile.min_spawn_interval = 0.5
	profile.spawn_acceleration = 0.1

	assert_almost_eq(
		profile.get_spawn_interval(-20.0), 2.0, FLOAT_TOLERANCE, "Il tempo run negativo deve essere sanitizzato a zero."
	)
	assert_almost_eq(
		profile.get_spawn_interval(5.0), 1.5, FLOAT_TOLERANCE, "La formula dello spawn interval deve usare il tempo della run."
	)
	assert_almost_eq(
		profile.get_spawn_interval(100.0), 0.5, FLOAT_TOLERANCE, "Lo spawn interval deve rispettare il minimo configurato."
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

	assert_almost_eq(
		profile.base_spawn_interval, EnemySpawnProfile.MINIMUM_INTERVAL_SECONDS, FLOAT_TOLERANCE,
		"Il base interval deve essere positivo."
	)
	assert_almost_eq(
		profile.min_spawn_interval, EnemySpawnProfile.MINIMUM_INTERVAL_SECONDS, FLOAT_TOLERANCE,
		"Il min interval deve essere positivo."
	)
	assert_true(profile.spawn_acceleration == 0.0, "L'accelerazione non puo essere negativa.")
	assert_true(profile.initial_spawn_delay == 0.0, "Il delay iniziale non puo essere negativo.")
	assert_true(profile.max_alive_enemies == 1, "Il cap deve consentire almeno un nemico.")
	assert_true(profile.inner_spawn_margin == 0.0, "Il margine interno non puo essere negativo.")
	assert_true(profile.outer_spawn_margin == 0.0, "Il margine esterno non puo essere negativo.")
	assert_true(profile.min_player_distance == 0.0, "La distanza dal Player non puo essere negativa.")
	assert_true(profile.spawn_sample_attempts == 1, "Il sampling deve eseguire almeno un tentativo.")
	assert_almost_eq(
		profile.get_effective_cleanup_interval(), EnemySpawnProfile.MINIMUM_INTERVAL_SECONDS, FLOAT_TOLERANCE,
		"L'intervallo di cleanup effettivo deve restare positivo."
	)

	profile.inner_spawn_margin = 70.0
	profile.outer_spawn_margin = 20.0
	profile.despawn_margin = 30.0
	assert_almost_eq(
		profile.get_effective_outer_spawn_margin(), 70.0, FLOAT_TOLERANCE,
		"Il margine esterno effettivo non deve entrare nell'anello interno."
	)
	assert_almost_eq(
		profile.get_effective_despawn_margin(), 70.0, FLOAT_TOLERANCE, "Il despawn non deve tagliare l'anello di spawn."
	)


func test_run_controller() -> void:
	var controller := RunController.new()
	controller.set_process(false)
	add_child_autofree(controller)
	await wait_process_frames(1)

	assert_true(controller.get_state() == RunController.RunState.BOOT, "RunController deve iniziare in BOOT.")
	assert_true(not get_tree().paused, "BOOT non deve lasciare SceneTree in pausa.")
	controller._process(3.0)
	assert_almost_eq(controller.get_run_time(), 0.0, FLOAT_TOLERANCE, "Il clock deve fermarsi in BOOT.")
	assert_true(
		not controller.request_state(RunController.RunState.BOOT),
		"BOOT non deve essere richiedibile come stato ordinario."
	)

	assert_true(controller.start_run(424242), "Una run deve partire da BOOT.")
	assert_true(controller.get_seed() == 424242, "Il seed della run deve essere conservato.")
	assert_true(controller.is_running() and not get_tree().paused, "RUNNING deve lasciare attivo SceneTree.")
	assert_true(not controller.start_run(9), "Una run gia avviata non deve ripartire.")
	controller._process(1.25)
	controller._process(-4.0)
	assert_almost_eq(
		controller.get_run_time(), 1.25, FLOAT_TOLERANCE, "Il clock deve avanzare solo con delta non negativo in RUNNING."
	)

	assert_true(controller.request_manual_pause(), "RUNNING deve accettare la pausa manuale.")
	assert_true(get_tree().paused, "MANUAL_PAUSE deve essere l'autorita sulla pausa del SceneTree.")
	controller._process(10.0)
	assert_almost_eq(controller.get_run_time(), 1.25, FLOAT_TOLERANCE, "Il clock deve fermarsi in pausa.")
	assert_true(controller.resume_run(), "La pausa manuale deve poter riprendere.")
	assert_true(controller.is_running() and not get_tree().paused, "Il resume deve tornare a RUNNING.")

	assert_true(controller.request_level_up(), "RUNNING deve accettare LEVEL_UP.")
	assert_true(get_tree().paused, "LEVEL_UP deve mettere in pausa SceneTree.")
	assert_true(controller.complete_level_up(), "LEVEL_UP deve poter essere completato.")
	assert_true(not get_tree().paused, "Completare LEVEL_UP deve riprendere la run.")
	assert_true(controller.request_boss_intro(), "RUNNING deve accettare BOSS_INTRO.")
	assert_true(get_tree().paused, "BOSS_INTRO deve mettere in pausa SceneTree.")
	assert_true(controller.complete_boss_intro(), "BOSS_INTRO deve poter essere completato.")
	controller._process(0.75)
	assert_almost_eq(controller.get_run_time(), 2.0, FLOAT_TOLERANCE, "Il clock deve riprendere dopo gli stati modali.")

	assert_true(controller.request_victory(), "RUNNING deve accettare uno stato terminale.")
	assert_true(controller.is_terminal() and get_tree().paused, "VICTORY deve bloccare e mettere in pausa la run.")
	assert_true(not controller.request_defeat(), "Uno stato terminale deve restare bloccato.")
	assert_true(not controller.resume_run(), "Un terminale non deve essere ripreso come pausa manuale.")
	controller._process(50.0)
	assert_almost_eq(controller.get_run_time(), 2.0, FLOAT_TOLERANCE, "Il clock deve fermarsi nel terminale.")

	assert_true(controller.prepare_restart(), "Il terminale deve poter preparare il restart.")
	assert_true(
		controller.get_state() == RunController.RunState.BOOT
		and controller.get_seed() == 0
		and is_zero_approx(controller.get_run_time()),
		"Il restart deve ripristinare stato, seed e clock."
	)
	assert_true(not get_tree().paused, "Il restart deve sempre rimuovere la pausa del SceneTree.")
	assert_true(controller.start_run(7), "Dopo il restart deve poter partire una nuova run.")
	assert_true(controller.request_defeat(), "La nuova run deve poter terminare in DEFEAT.")
	assert_true(controller.get_state() == RunController.RunState.DEFEAT, "DEFEAT deve essere terminale.")
	controller.prepare_restart()


func test_spawn_sampling() -> void:
	var viewport_a := Rect2(Vector2(80.0, 40.0), Vector2(640.0, 360.0))
	var viewport_b := Rect2(Vector2(-120.0, 75.0), Vector2(900.0, 500.0))
	var inner_margin := 32.0
	var outer_margin := 110.0
	var player_a := viewport_a.get_center()
	var player_b := viewport_b.get_center()

	var responsive_rng := RandomNumberGenerator.new()
	responsive_rng.seed = 13579
	var spawn_a := EnemySpawner.sample_spawn_position(viewport_a, inner_margin, outer_margin, player_a, 0.0, 8, responsive_rng)
	var spawn_b := EnemySpawner.sample_spawn_position(viewport_b, inner_margin, outer_margin, player_b, 0.0, 8, responsive_rng)
	_assert_spawn_ring(spawn_a, viewport_a, inner_margin, outer_margin, "viewport traslata A")
	_assert_spawn_ring(spawn_b, viewport_b, inner_margin, outer_margin, "viewport ridimensionata B")

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
		assert_vector_near(position_a, position_b, "Lo stesso seed deve riprodurre lo spawn %d." % sequence_index, 0.0)

	# I tentativi singoli espongono la stessa sequenza RNG usata dal batch.
	# Questo permette di verificare l'accettazione del primo candidato valido
	# senza duplicare l'algoritmo di sampling nel test.
	const SAMPLE_COUNT := 10
	const SAMPLE_SEED := 24680
	var candidates: Array[Vector2] = []
	var candidate_rng := RandomNumberGenerator.new()
	candidate_rng.seed = SAMPLE_SEED
	for _sample_index in range(SAMPLE_COUNT):
		candidates.append(
			EnemySpawner.sample_spawn_position(viewport_a, inner_margin, outer_margin, player_a, 0.0, 1, candidate_rng)
		)

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
		viewport_a, inner_margin, outer_margin, player_a, required_distance, SAMPLE_COUNT, distance_rng
	)
	assert_true(
		accepted.distance_to(player_a) + FLOAT_TOLERANCE >= required_distance,
		"Il sampling deve rispettare la distanza minima quando un candidato valido esiste."
	)
	assert_vector_near(
		accepted, expected_accepted, "Il sampling deve accettare il primo candidato abbastanza distante.", 0.0
	)

	var outer_rect := viewport_a.grow(outer_margin)
	var expected_farthest_corner := EnemySpawner.get_farthest_rect_corner(outer_rect, player_a)
	var first_candidate_distance := candidates[0].distance_to(player_a)
	var farthest_corner_distance := expected_farthest_corner.distance_to(player_a)
	var fallback_required_distance := lerpf(first_candidate_distance, farthest_corner_distance, 0.5)
	var geometric_fallback_rng := RandomNumberGenerator.new()
	geometric_fallback_rng.seed = SAMPLE_SEED
	var geometric_fallback := EnemySpawner.sample_spawn_position(
		viewport_a, inner_margin, outer_margin, player_a, fallback_required_distance, 1, geometric_fallback_rng
	)
	assert_vector_near(
		geometric_fallback, expected_farthest_corner,
		"Il fallback geometrico deve scegliere l'angolo esterno piu lontano.", 0.0
	)
	assert_true(
		geometric_fallback.distance_to(player_a) + FLOAT_TOLERANCE >= fallback_required_distance,
		"Il fallback deve garantire la distanza minima quando e geometricamente possibile."
	)

	var impossible_fallback_rng := RandomNumberGenerator.new()
	impossible_fallback_rng.seed = SAMPLE_SEED
	var impossible_fallback := EnemySpawner.sample_spawn_position(
		viewport_a, inner_margin, outer_margin, player_a, 1.0e20, SAMPLE_COUNT, impossible_fallback_rng
	)
	assert_vector_near(
		impossible_fallback, expected_farthest_corner,
		"Se la distanza e impossibile, il fallback deve usare il massimo geometrico.", 0.0
	)
	assert_true(
		not EnemySpawner.sample_spawn_position(Rect2(), 10.0, 20.0, Vector2.ZERO, 0.0, 1, impossible_fallback_rng).is_finite(),
		"Una viewport senza area non deve produrre uno spawn finito."
	)
	assert_true(
		not EnemySpawner.sample_spawn_position(viewport_a, 10.0, 20.0, Vector2.ZERO, 0.0, 1, null).is_finite(),
		"Un RNG assente non deve produrre uno spawn finito."
	)


func test_base_enemy() -> void:
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
	add_child_autofree(fixture)
	await wait_process_frames(1)
	enemy_a.set_physics_process(false)
	enemy_b.set_physics_process(false)

	var shape_a := (enemy_a.get_node("CollisionShape") as CollisionShape2D).shape
	var shape_b := (enemy_b.get_node("CollisionShape") as CollisionShape2D).shape
	assert_true(
		shape_a != null and shape_b != null and shape_a.get_instance_id() != shape_b.get_instance_id(),
		"Ogni BaseEnemy deve possedere una collision shape unica."
	)
	enemy_a.collision_radius = 31.0
	assert_almost_eq(
		(shape_a as CircleShape2D).radius, 31.0, FLOAT_TOLERANCE, "Cambiare il raggio deve aggiornare la shape del solo nemico."
	)
	assert_almost_eq(
		(shape_b as CircleShape2D).radius, 20.0, FLOAT_TOLERANCE, "Le shape delle altre istanze non devono essere mutate."
	)

	controller.start_run(101)
	enemy_a.global_position = Vector2(100.0, 120.0)
	target.global_position = Vector2(300.0, 120.0)
	enemy_a.set_target(target)
	enemy_a.set_run_controller(controller)
	enemy_a._physics_process(1.0 / 60.0)
	assert_vector_near(
		enemy_a.velocity, Vector2.RIGHT * enemy_a.move_speed, "BaseEnemy deve inseguire il target alla velocita configurata."
	)

	target.global_position = enemy_a.global_position
	enemy_a._physics_process(1.0 / 60.0)
	assert_vector_near(enemy_a.velocity, Vector2.ZERO, "Sul target il nemico deve fermarsi.")
	target.global_position = enemy_a.global_position + Vector2.UP * 200.0
	enemy_a._physics_process(1.0 / 60.0)
	assert_true(enemy_a.velocity.y < 0.0, "Il nemico deve aggiornare la direzione di inseguimento.")
	controller.request_manual_pause()
	assert_vector_near(enemy_a.velocity, Vector2.ZERO, "L'ingresso in pausa deve arrestare subito BaseEnemy.")
	enemy_a._physics_process(1.0 / 60.0)
	assert_vector_near(enemy_a.velocity, Vector2.ZERO, "BaseEnemy non deve inseguire fuori RUNNING.")
	controller.resume_run()
	enemy_a._physics_process(1.0 / 60.0)
	assert_true(enemy_a.velocity.y < 0.0, "BaseEnemy deve riprendere l'inseguimento con la run.")
	controller.request_victory()
	assert_vector_near(enemy_a.velocity, Vector2.ZERO, "Un terminale deve arrestare BaseEnemy.")
	enemy_a.clear_chase_dependencies()
	assert_true(
		enemy_a.get_target() == null and enemy_a.get_run_controller() == null and enemy_a.velocity == Vector2.ZERO,
		"La pulizia delle dipendenze deve arrestare e scollegare BaseEnemy."
	)

	controller.prepare_restart()


func test_enemy_spawner() -> void:
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
	add_child_autofree(fixture)
	await wait_process_frames(2)
	spawner.set_process(false)
	controller.set_process(false)
	target.global_position = arena.get_viewport_rect().get_center()

	spawner._process(100.0)
	assert_eq(spawner.get_alive_count(), 0, "Lo scheduler non deve spawnare in BOOT.")
	assert_almost_eq(
		spawner.get_spawn_elapsed(), 0.0, FLOAT_TOLERANCE, "BOOT non deve accumulare credito di spawn."
	)
	assert_true(controller.start_run(777), "La fixture dello spawner deve avviare la run.")
	assert_true(spawner.is_waiting_for_initial_spawn(), "Una nuova run deve attendere il delay iniziale.")

	spawner._process(0.49)
	assert_eq(spawner.get_alive_count(), 0, "Non deve esserci spawn prima del delay iniziale.")
	spawner._process(0.02)
	assert_eq(spawner.get_alive_count(), 1, "Il primo spawn deve avvenire al superamento del delay.")
	assert_true(not spawner.is_waiting_for_initial_spawn(), "Dopo il primo spawn deve iniziare la cadenza ordinaria.")
	_assert_spawned_enemy(spawner.get_spawned_enemies()[0], target, controller, arena.get_playfield_rect(), profile)

	spawner._process(10.0)
	assert_eq(spawner.get_alive_count(), 2, "Un delta grande deve produrre al massimo uno spawn per tick.")
	assert_almost_eq(
		spawner.get_spawn_elapsed(), 0.0, FLOAT_TOLERANCE, "Uno spawn riuscito deve consumare il credito."
	)
	spawner._process(0.0)
	assert_eq(spawner.get_alive_count(), 2, "Lo scheduler non deve generare un burst nello stesso credito.")
	spawner._process(0.25)
	assert_eq(spawner.get_alive_count(), 3, "Lo scheduler deve raggiungere il cap configurato.")
	spawner._process(4.0)
	assert_eq(spawner.get_alive_count(), 3, "Il cap deve impedire ulteriori spawn.")
	assert_almost_eq(
		spawner.get_spawn_elapsed(), 0.25, FLOAT_TOLERANCE, "Al cap il credito deve essere limitato a un solo intervallo."
	)

	var removed_for_slot := spawner.get_spawned_enemies()[0]
	var removed_for_slot_id := removed_for_slot.get_instance_id()
	removed_for_slot.queue_free()
	await wait_process_frames(1)
	assert_eq(spawner.get_alive_count(), 2, "Liberare un nemico deve aprire uno slot nel cap.")
	assert_true(removed_for_slot_id in _removed_enemy_ids, "La rimozione deve aggiornare il registro dello spawner.")
	spawner._process(0.0)
	assert_eq(spawner.get_alive_count(), 3, "Uno slot libero deve usare il singolo credito conservato.")
	spawner._process(0.0)
	assert_eq(spawner.get_alive_count(), 3, "Lo slot libero non deve causare spawn multipli.")

	var cleanup_enemies := spawner.get_spawned_enemies()
	var viewport_rect := arena.get_viewport_rect()
	var despawn_rect := viewport_rect.grow(profile.get_effective_despawn_margin())
	cleanup_enemies[0].global_position = Vector2(despawn_rect.end.x, viewport_rect.get_center().y)
	cleanup_enemies[1].global_position = Vector2(despawn_rect.end.x + 1.0, viewport_rect.get_center().y)
	var cleanup_count := spawner.cleanup_outside_despawn_rect()
	assert_eq(cleanup_count, 1, "Il cleanup deve rimuovere soltanto i nemici oltre il despawn rect.")
	assert_true(
		not cleanup_enemies[0].is_queued_for_deletion(), "Il bordo inclusivo del despawn rect deve essere conservato."
	)
	assert_true(
		cleanup_enemies[1].is_queued_for_deletion(), "Un nemico oltre il margine deve essere accodato alla rimozione."
	)
	await wait_process_frames(1)
	assert_eq(spawner.get_alive_count(), 2, "Il registro deve riflettere il cleanup completato.")

	var elapsed_before_pause := spawner.get_spawn_elapsed()
	controller.request_manual_pause()
	var count_before_pause := spawner.get_alive_count()
	spawner._process(100.0)
	assert_eq(spawner.get_alive_count(), count_before_pause, "MANUAL_PAUSE deve chiudere il gate dello spawn.")
	assert_almost_eq(
		spawner.get_spawn_elapsed(), elapsed_before_pause, FLOAT_TOLERANCE, "La pausa non deve accumulare tempo nello scheduler."
	)
	controller.resume_run()
	spawner._process(0.25)
	assert_eq(spawner.get_alive_count(), 3, "Lo scheduler deve riprendere dopo MANUAL_PAUSE.")

	var removed_before_terminal := spawner.get_spawned_enemies()[0]
	removed_before_terminal.queue_free()
	await wait_process_frames(1)
	var terminal_count := spawner.get_alive_count()
	controller.request_victory()
	var elapsed_before_terminal := spawner.get_spawn_elapsed()
	spawner._process(100.0)
	assert_eq(spawner.get_alive_count(), terminal_count, "Uno stato terminale deve chiudere il gate dello spawn.")
	assert_almost_eq(
		spawner.get_spawn_elapsed(), elapsed_before_terminal, FLOAT_TOLERANCE,
		"Il terminale non deve accumulare credito di spawn."
	)
	controller.prepare_restart()
	assert_true(
		spawner.get_alive_count() == 0 and spawner.is_waiting_for_initial_spawn() and is_zero_approx(spawner.get_spawn_elapsed()),
		"Preparare il restart deve pulire immediatamente registro e scheduler."
	)
	assert_true(
		enemy_parent.get_child_count() > 0, "I nodi accodati al free possono restare nel tree fino alla fine del frame."
	)
	await wait_process_frames(1)
	assert_eq(enemy_parent.get_child_count(), 0, "Il restart deve liberare tutti i nodi nemico entro la fine del frame.")


func test_composed_scene() -> void:
	var movement_slice := await instantiate_movement_slice()

	var arena := movement_slice.get_node_or_null("ArenaLayout") as ArenaLayout
	var arena_world := movement_slice.get_node_or_null("ArenaWorld") as ArenaWorld
	var controller := movement_slice.get_node_or_null("RunController") as RunController
	var spawner := movement_slice.get_node_or_null("EnemySpawner") as EnemySpawner
	var target := movement_slice.get_node_or_null("World/Player") as Player
	var enemy_parent := movement_slice.get_node_or_null("World/Enemies") as Node2D
	assert_true(arena != null, "La scena composta deve contenere ArenaLayout.")
	assert_true(arena_world != null, "La scena composta deve contenere ArenaWorld.")
	assert_true(controller != null, "La scena composta deve contenere RunController.")
	assert_true(spawner != null, "La scena composta deve contenere EnemySpawner.")
	assert_true(target != null, "La scena composta deve contenere Player.")
	assert_true(enemy_parent != null, "La scena composta deve contenere il parent Enemies.")
	if arena == null or arena_world == null or controller == null or spawner == null or target == null or enemy_parent == null:
		return

	spawner.set_process(false)
	controller.set_process(false)
	spawner.enemy_spawned.connect(_freeze_spawned_enemy)
	assert_true(controller.is_running(), "La scena composta deve avviare RunController.")
	assert_true(
		spawner.enemy_scene != null and spawner.spawn_profile != null, "La scena deve assegnare scena nemico e profilo."
	)
	assert_true(
		spawner.get_run_controller() == controller
		and spawner.get_arena_layout() == arena
		and spawner.get_target() == target
		and spawner.get_enemy_parent() == enemy_parent,
		"EnemySpawner deve essere collegato ai nodi della scena composta."
	)

	spawner.reset_for_run(314159)
	await wait_process_frames(1)
	spawner._process(spawner.spawn_profile.initial_spawn_delay)
	assert_eq(spawner.get_alive_count(), 1, "La scena composta deve produrre il primo spawn schedulato.")
	if spawner.get_alive_count() == 1:
		_assert_spawned_enemy(
			spawner.get_spawned_enemies()[0], target, controller, spawner.get_visible_reference_rect(), spawner.spawn_profile
		)

	get_tree().root.content_scale_size = RESIZED_VIEWPORT_SIZE
	get_tree().root.size = RESIZED_VIEWPORT_SIZE
	await wait_process_frames(2)
	var resized_viewport := arena.get_viewport_rect()
	assert_vector_near(
		resized_viewport.size, Vector2(RESIZED_VIEWPORT_SIZE), "ArenaLayout deve leggere la viewport dopo il resize."
	)
	assert_true(arena.get_playfield_rect().has_area(), "Il playfield deve restare valido dopo il resize.")
	assert_vector_near(
		target.global_position,
		ArenaWorld.clamp_circle_center_in_rect(arena_world.get_world_rect(), target.global_position, target.collision_radius),
		"Il Player deve restare confinato dopo il resize."
	)

	spawner.reset_for_run(314159)
	await wait_process_frames(1)
	spawner._process(spawner.spawn_profile.initial_spawn_delay)
	assert_eq(spawner.get_alive_count(), 1, "Lo scheduler deve continuare a spawnare dopo il resize.")
	if spawner.get_alive_count() == 1:
		_assert_spawned_enemy(
			spawner.get_spawned_enemies()[0], target, controller, spawner.get_visible_reference_rect(), spawner.spawn_profile
		)


func _assert_spawned_enemy(
	enemy: BaseEnemy, target: Node2D, controller: RunController, viewport_rect: Rect2, profile: EnemySpawnProfile
) -> void:
	assert_true(is_instance_valid(enemy), "Lo spawn deve restituire un BaseEnemy valido.")
	if not is_instance_valid(enemy):
		return
	assert_true(enemy.get_target() == target, "Il nemico deve ricevere il target configurato.")
	assert_true(enemy.get_run_controller() == controller, "Il nemico deve ricevere RunController.")
	assert_true(enemy.is_in_group(&"enemies"), "Il nemico deve appartenere al gruppo enemies.")
	_assert_spawn_ring(
		enemy.global_position, viewport_rect, profile.inner_spawn_margin, profile.get_effective_outer_spawn_margin(),
		"nemico istanziato"
	)


func _assert_spawn_ring(
	position: Vector2, viewport_rect: Rect2, inner_margin: float, outer_margin: float, context: String
) -> void:
	assert_true(position.is_finite(), "Lo spawn %s deve essere finito." % context)
	if not position.is_finite():
		return
	assert_true(
		not EnemySpawner.is_point_in_rect_inclusive(viewport_rect, position), "Lo spawn %s deve essere fuori dalla viewport." % context
	)
	assert_true(
		EnemySpawner.is_point_in_rect_inclusive(viewport_rect.grow(outer_margin), position),
		"Lo spawn %s deve restare entro il margine esterno." % context
	)
	var outside_depth := _get_outside_depth(viewport_rect, position)
	assert_true(
		outside_depth + FLOAT_TOLERANCE >= inner_margin and outside_depth <= outer_margin + FLOAT_TOLERANCE,
		"Lo spawn %s deve rispettare l'anello interno/esterno." % context
	)


func _get_outside_depth(bounds: Rect2, point: Vector2) -> float:
	return maxf(
		maxf(bounds.position.x - point.x, point.x - bounds.end.x), maxf(bounds.position.y - point.y, point.y - bounds.end.y)
	)


func _freeze_spawned_enemy(enemy: BaseEnemy) -> void:
	if is_instance_valid(enemy):
		enemy.set_physics_process(false)


func _on_enemy_removed(enemy_instance_id: int) -> void:
	_removed_enemy_ids.append(enemy_instance_id)
