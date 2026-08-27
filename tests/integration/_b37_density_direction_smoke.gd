extends SceneTree

const ENEMY_SCENE: PackedScene = preload("res://scenes/actors/base_enemy.tscn")
const FLOAT_TOLERANCE := 0.001

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	paused = false
	_validate_enemy_hp()
	await _validate_pursuit_offset()
	_validate_sector_restricted_sampling()
	_validate_sector_combination_picker()
	await _validate_spawner_sector_rotation()
	await _finish()


func _validate_enemy_hp() -> void:
	var enemy := ENEMY_SCENE.instantiate() as BaseEnemy
	# Il nemico non e' ancora entrato nel tree: le @onready var non sono
	# popolate, quindi la HealthComponent va letta via get_node diretto.
	var health := enemy.get_node("HealthComponent") as HealthComponent
	_expect(
		health != null and is_equal_approx(health.health_max, 18.0),
		"B37 deve ridurre la vita base del nemico comune a 18 (-25% da 24)."
	)
	enemy.free()


func _validate_pursuit_offset() -> void:
	var fixture := Node2D.new()
	var target := Node2D.new()
	var controller := RunController.new()
	controller.set_process(false)
	var enemy := ENEMY_SCENE.instantiate() as BaseEnemy
	fixture.add_child(target)
	fixture.add_child(controller)
	fixture.add_child(enemy)
	root.add_child(fixture)
	await process_frame
	enemy.set_physics_process(false)

	controller.start_run(3401)
	enemy.global_position = Vector2.ZERO
	target.global_position = Vector2(200.0, 0.0)
	enemy.set_target(target)
	enemy.set_run_controller(controller)

	enemy._physics_process(1.0 / 60.0)
	_expect_vector_near(
		enemy.velocity,
		Vector2.RIGHT * enemy.move_speed,
		FLOAT_TOLERANCE,
		"Senza offset il nemico deve puntare dritto al target come prima di B37."
	)

	enemy.set_pursuit_offset(Vector2(0.0, 40.0))
	_expect_vector_near(
		enemy.get_pursuit_offset(),
		Vector2(0.0, 40.0),
		FLOAT_TOLERANCE,
		"L'offset di inseguimento deve essere leggibile dopo l'assegnazione."
	)
	# Il primo _physics_process ha gia' spostato il nemico: si riparte da
	# un'origine pulita per isolare l'effetto dell'offset sulla direzione.
	enemy.global_position = Vector2.ZERO
	enemy._physics_process(1.0 / 60.0)
	_expect(
		enemy.velocity.y > 0.0,
		"L'offset di inseguimento deve deviare lateralmente la direzione di avvicinamento."
	)
	_expect_vector_near(
		enemy.velocity.normalized(),
		Vector2(200.0, 40.0).normalized(),
		0.01,
		"La direzione deve puntare al target sommato all'offset di dispersione."
	)

	enemy.clear_chase_dependencies()
	_expect_vector_near(
		enemy.get_pursuit_offset(),
		Vector2.ZERO,
		FLOAT_TOLERANCE,
		"Pulire le dipendenze deve azzerare anche l'offset di inseguimento."
	)

	controller.prepare_restart()
	paused = false
	fixture.queue_free()
	await process_frame


func _validate_sector_restricted_sampling() -> void:
	var viewport_rect := Rect2(Vector2(0.0, 0.0), Vector2(640.0, 360.0))
	var inner_margin := 20.0
	var outer_margin := 80.0
	var player_position := viewport_rect.get_center()

	for side in EnemySpawner.ALL_SECTORS:
		var rng := RandomNumberGenerator.new()
		rng.seed = 999 + side
		var restricted: Array[int] = [side]
		for _sample_index in range(6):
			var position := EnemySpawner.sample_spawn_position(
				viewport_rect, inner_margin, outer_margin, player_position, 0.0, 6, rng, restricted
			)
			_expect(
				position.is_finite()
				and _position_matches_side(viewport_rect, inner_margin, outer_margin, side, position),
				"Un settore ristretto a %d deve produrre solo spawn su quel lato." % side
			)

	var empty_sides: Array[int] = []
	var fallback_rng := RandomNumberGenerator.new()
	fallback_rng.seed = 42
	var fallback_position := EnemySpawner.sample_spawn_position(
		viewport_rect, inner_margin, outer_margin, player_position, 0.0, 4, fallback_rng, empty_sides
	)
	_expect(
		fallback_position.is_finite(),
		"Un elenco di settori vuoto deve ricadere su tutti i lati invece di fallire."
	)


func _validate_sector_combination_picker() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 555
	for count in range(1, 6):
		var picked := EnemySpawner.pick_sector_combination(count, rng)
		var expected_size := clampi(count, 1, 4)
		_expect(
			picked.size() == expected_size,
			"pick_sector_combination deve restituire %d settori per richiesta %d." % [expected_size, count]
		)
		var unique := {}
		for sector in picked:
			_expect(sector >= 0 and sector <= 3, "Ogni settore scelto deve essere tra 0 e 3.")
			unique[sector] = true
		_expect(
			unique.size() == picked.size(),
			"pick_sector_combination non deve ripetere lo stesso settore nella stessa finestra."
		)

	var deterministic_a := RandomNumberGenerator.new()
	var deterministic_b := RandomNumberGenerator.new()
	deterministic_a.seed = 24680
	deterministic_b.seed = 24680
	var combo_a := EnemySpawner.pick_sector_combination(2, deterministic_a)
	var combo_b := EnemySpawner.pick_sector_combination(2, deterministic_b)
	_expect(
		combo_a == combo_b,
		"Lo stesso seed deve riprodurre la stessa combinazione di settori."
	)

	var null_rng_result := EnemySpawner.pick_sector_combination(2, null)
	_expect(
		null_rng_result.is_empty(),
		"Senza RNG la combinazione deve restare vuota invece di generare errori."
	)


func _validate_spawner_sector_rotation() -> void:
	var fixture := Node2D.new()
	var arena := ArenaLayout.new()
	arena.respect_display_safe_area = false
	var controller := RunController.new()
	controller.set_process(false)
	var target := Node2D.new()
	var enemy_parent := Node2D.new()
	var spawner := EnemySpawner.new()
	spawner.set_process(false)
	var profile := EnemySpawnProfile.new()
	profile.base_spawn_interval = 0.05
	profile.min_spawn_interval = 0.05
	profile.spawn_acceleration = 0.0
	profile.initial_spawn_delay = 0.0
	profile.max_alive_enemies = 60
	profile.inner_spawn_margin = 24.0
	profile.outer_spawn_margin = 64.0
	profile.min_player_distance = 0.0
	profile.spawn_sample_attempts = 6
	profile.cleanup_interval = 5.0
	profile.despawn_margin = 200.0
	profile.sector_hold_duration_min = 1.0
	profile.sector_hold_duration_max = 1.0
	profile.sector_multi_chance = 0.0
	profile.sector_spike_chance = 0.0
	spawner.enemy_scene = ENEMY_SCENE
	spawner.spawn_profile = profile
	spawner.configure(controller, arena, target, enemy_parent)
	spawner.enemy_spawned.connect(_freeze_spawned_enemy)
	fixture.add_child(arena)
	fixture.add_child(controller)
	fixture.add_child(target)
	fixture.add_child(enemy_parent)
	fixture.add_child(spawner)
	root.add_child(fixture)
	await process_frame
	await process_frame
	spawner.set_process(false)
	controller.set_process(false)
	var viewport_rect := arena.get_playfield_rect()
	target.global_position = viewport_rect.get_center()

	controller.start_run(9001)
	var first_sectors := spawner.get_active_sectors()
	_expect(
		first_sectors.size() == 1,
		"Con probabilita multi/picco azzerate la rotazione deve restare a un solo settore."
	)

	for _tick in range(4):
		var enemy := spawner.try_spawn_enemy()
		_expect(enemy != null, "Lo spawner deve produrre nemici durante la finestra del settore.")
		if enemy != null:
			var active_side: int = spawner.get_active_sectors()[0]
			_expect(
				_position_matches_side(
					viewport_rect,
					profile.inner_spawn_margin,
					profile.get_effective_outer_spawn_margin(),
					active_side,
					enemy.global_position
				),
				"Ogni spawn durante la finestra deve restare nel settore attivo."
			)

	spawner._process(1.5)
	var second_sectors := spawner.get_active_sectors()
	_expect(
		second_sectors.size() == 1,
		"La rotazione deve ricalcolare un nuovo insieme valido dopo la scadenza della finestra."
	)

	controller.prepare_restart()
	paused = false
	fixture.queue_free()
	await process_frame


## Verifica che `position` rispetti esattamente la fascia geometrica del lato
## indicato (0=Nord, 1=Est, 2=Sud, 3=Ovest), evitando l'inferenza ambigua
## dalla sola posizione quando gli intervalli dei lati si sovrappongono.
func _position_matches_side(
	rect: Rect2,
	inner_margin: float,
	outer_margin: float,
	side: int,
	position: Vector2
) -> bool:
	match side:
		0:
			return (
				position.y <= rect.position.y - inner_margin + FLOAT_TOLERANCE
				and position.y >= rect.position.y - outer_margin - FLOAT_TOLERANCE
			)
		1:
			return (
				position.x >= rect.end.x + inner_margin - FLOAT_TOLERANCE
				and position.x <= rect.end.x + outer_margin + FLOAT_TOLERANCE
			)
		2:
			return (
				position.y >= rect.end.y + inner_margin - FLOAT_TOLERANCE
				and position.y <= rect.end.y + outer_margin + FLOAT_TOLERANCE
			)
		_:
			return (
				position.x <= rect.position.x - inner_margin + FLOAT_TOLERANCE
				and position.x >= rect.position.x - outer_margin - FLOAT_TOLERANCE
			)


func _freeze_spawned_enemy(enemy: BaseEnemy) -> void:
	if is_instance_valid(enemy):
		enemy.set_physics_process(false)


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
		print("B37_DENSITY_DIRECTION_SMOKE_OK")
		quit(0)
		return
	for failure in _failures:
		printerr(failure)
	printerr("B37_DENSITY_DIRECTION_SMOKE_FAIL count=%d" % _failures.size())
	quit(1)
