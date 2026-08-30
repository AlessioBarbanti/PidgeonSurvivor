extends GutGameplayTest

const ENEMY_SCENE: PackedScene = preload("res://scenes/actors/base_enemy.tscn")
const PLAYER_SCENE: PackedScene = preload("res://scenes/actors/player.tscn")
const DEFAULT_PROFILE: EnemySpawnProfile = preload(
	"res://data/spawn_profiles/default_enemy_spawn_profile.tres"
)
const SWARMER: EnemyArchetypeDefinition = preload(
	"res://data/enemies/enemy_archetype_swarmer.tres"
)
const ARMORED: EnemyArchetypeDefinition = preload(
	"res://data/enemies/enemy_archetype_armored.tres"
)
const SPLITTER: EnemyArchetypeDefinition = preload(
	"res://data/enemies/enemy_archetype_splitter.tres"
)
const RANGED: EnemyArchetypeDefinition = preload(
	"res://data/enemies/enemy_archetype_ranged.tres"
)
const ARCHETYPES: Array[EnemyArchetypeDefinition] = [
	SWARMER,
	ARMORED,
	SPLITTER,
	RANGED,
]


func test_late_curve_changes_composition_without_scaling_enemy_or_player_stats() -> void:
	var profile := DEFAULT_PROFILE.duplicate(true) as EnemySpawnProfile
	var initial_time := 30.0
	var reference_time := 180.0
	var full_time := 300.0
	var initial_health: Dictionary[StringName, float] = {}

	assert_almost_eq(
		profile.get_effective_base_archetype_weight(initial_time),
		profile.base_archetype_weight,
		FLOAT_TOLERANCE,
		"Prima della curva PS-007 il peso del piccione base deve restare invariato."
	)
	assert_true(
		profile.get_effective_base_archetype_weight(reference_time)
			> profile.get_effective_base_archetype_weight(full_time),
		"Fra 03:00 e 05:00 il peso relativo del nemico base deve continuare a calare."
	)
	assert_true(
		profile.get_effective_sector_multi_chance(reference_time)
			< profile.get_effective_sector_multi_chance(full_time),
		"Dopo 03:00 la probabilita' di pressione multisettore deve continuare a evolvere."
	)

	for archetype in ARCHETYPES:
		initial_health[archetype.id] = archetype.health_max
		assert_almost_eq(
			profile.get_effective_archetype_weight(
				archetype.spawn_weight,
				archetype.late_run_weight_multiplier,
				initial_time
			),
			archetype.spawn_weight,
			FLOAT_TOLERANCE,
			"La curva iniziale di %s deve restare invariata." % archetype.id
		)
		assert_true(
			profile.get_effective_archetype_weight(
				archetype.spawn_weight,
				archetype.late_run_weight_multiplier,
				full_time
			) >= archetype.spawn_weight,
			"La pressione qualitativa non deve rimuovere %s dal pool late-run." % archetype.id
		)
		assert_almost_eq(
			archetype.health_max,
			initial_health[archetype.id],
			FLOAT_TOLERANCE,
			"PS-007 non deve scalare gli HP di %s." % archetype.id
		)

	var neutral_damage := 10.0
	var strong_damage := 20.0
	var strict_advantage_found := false
	for archetype in ARCHETYPES:
		var neutral_hits := ceili(archetype.health_max / neutral_damage)
		var strong_hits := ceili(archetype.health_max / strong_damage)
		assert_true(
			strong_hits <= neutral_hits,
			"Aumentare il danno deve conservare il vantaggio contro %s." % archetype.id
		)
		strict_advantage_found = strict_advantage_found or strong_hits < neutral_hits
	assert_true(strict_advantage_found, "La build offensiva forte deve ottenere almeno un vantaggio netto di TTK.")


func test_seeded_late_sequence_is_deterministic_and_guarantees_ranged_pressure() -> void:
	var run_a := await _build_spawner(7007)
	var run_b := await _build_spawner(7007)
	var controller_a: RunController = run_a["controller"]
	var controller_b: RunController = run_b["controller"]
	var spawner_a: EnemySpawner = run_a["spawner"]
	var spawner_b: EnemySpawner = run_b["spawner"]
	controller_a._process(180.0)
	controller_b._process(180.0)

	var sequence_a: Array[StringName] = []
	var sequence_b: Array[StringName] = []
	var ranged_times: Array[float] = []
	for _spawn_index in range(32):
		var enemy_a := spawner_a.try_spawn_enemy()
		var enemy_b := spawner_b.try_spawn_enemy()
		sequence_a.append(_enemy_signature(enemy_a))
		sequence_b.append(_enemy_signature(enemy_b))
		if enemy_a is RangedEnemy:
			ranged_times.append(controller_a.get_run_time())
		controller_a._process(0.5)
		controller_b._process(0.5)

	assert_eq(sequence_a, sequence_b, "Lo stesso seed deve riprodurre la composizione late-run.")
	assert_eq(sequence_a[0], &"ranged", "A 03:00 la prima scadenza deve garantire un tiratore.")
	assert_true(
		sequence_a.has(&"swarmer") or sequence_a.has(&"armored") or sequence_a.has(&"splitter"),
		"La pressione late-run deve combinare il tiratore con almeno un altro archetipo."
	)
	for index in range(1, ranged_times.size()):
		assert_true(
			ranged_times[index] - ranged_times[index - 1]
				<= DEFAULT_PROFILE.late_run_ranged_max_gap_seconds + 0.5,
			"Il tiratore non deve sparire dalla composizione oltre la finestra dichiarata."
		)

	var count_before_pause := spawner_a.get_alive_count()
	var time_before_pause := controller_a.get_run_time()
	assert_true(controller_a.request_manual_pause(), "La fixture deve poter entrare in pausa.")
	spawner_a._process(20.0)
	controller_a._process(20.0)
	assert_eq(spawner_a.get_alive_count(), count_before_pause, "La pausa non deve avanzare lo spawner.")
	assert_almost_eq(
		controller_a.get_run_time(),
		time_before_pause,
		FLOAT_TOLERANCE,
		"La pausa non deve avanzare la curva PS-007."
	)

	assert_true(controller_a.resume_run(), "La fixture deve poter riprendere la run.")
	var time_before_level_up := controller_a.get_run_time()
	var count_before_level_up := spawner_a.get_alive_count()
	assert_true(controller_a.request_level_up(), "La fixture deve poter aprire il level-up.")
	spawner_a._process(20.0)
	controller_a._process(20.0)
	assert_almost_eq(
		controller_a.get_run_time(),
		time_before_level_up,
		FLOAT_TOLERANCE,
		"LEVEL_UP non deve avanzare la curva PS-007."
	)
	assert_eq(spawner_a.get_alive_count(), count_before_level_up, "LEVEL_UP non deve generare nemici.")
	assert_true(controller_a.complete_level_up(), "La fixture deve poter chiudere il level-up.")

	var time_before_boss_intro := controller_a.get_run_time()
	var count_before_boss_intro := spawner_a.get_alive_count()
	assert_true(controller_a.request_boss_intro(), "La fixture deve poter aprire la Boss intro.")
	spawner_a._process(20.0)
	controller_a._process(20.0)
	assert_almost_eq(
		controller_a.get_run_time(),
		time_before_boss_intro,
		FLOAT_TOLERANCE,
		"BOSS_INTRO non deve avanzare la curva PS-007."
	)
	assert_eq(spawner_a.get_alive_count(), count_before_boss_intro, "BOSS_INTRO non deve generare nemici.")
	assert_true(controller_a.complete_boss_intro(), "La fixture deve poter chiudere la Boss intro.")

	assert_true(controller_a.request_defeat(), "La fixture deve poter preparare il restart.")
	controller_a.prepare_restart()
	assert_eq(spawner_a.get_alive_count(), 0, "Il restart deve eliminare i nemici late-run.")
	var reset_ranged_time := spawner_a.get_last_archetype_spawn_time(&"ranged")
	assert_true(
		is_inf(reset_ranged_time) and reset_ranged_time < 0.0,
		"Il restart deve azzerare la memoria della garanzia tiratore."
	)

	_teardown_fixture(run_a)
	_teardown_fixture(run_b)


func test_static_player_position_is_reached_by_a_telegraphed_threat_within_ten_seconds() -> void:
	var built := await _build_spawner(1707)
	var controller: RunController = built["controller"]
	var spawner: EnemySpawner = built["spawner"]
	var target: Player = built["target"]
	controller._process(180.0)
	var enemy := spawner.try_spawn_enemy() as RangedEnemy
	assert_not_null(enemy, "Lo scenario AFK a 03:00 deve generare il tiratore garantito.")
	if enemy == null:
		_teardown_fixture(built)
		return

	enemy.set_physics_process(false)
	target.global_position = Vector2(640.0, 360.0)
	enemy.global_position = target.global_position + Vector2(-320.0, 0.0)
	var threat_time := RANGED.ranged_attack_interval + RANGED.ranged_telegraph_duration
	enemy._advance_attack_cycle(RANGED.ranged_attack_interval)
	assert_true(enemy.is_telegraph_active(), "La minaccia deve essere leggibile prima del colpo.")
	enemy._advance_attack_cycle(RANGED.ranged_telegraph_duration + 0.001)
	assert_eq(enemy.get_active_projectile_count(), 1, "Il tiratore deve produrre una minaccia concreta.")

	var projectiles: Node = built["projectile_parent"]
	var projectile := projectiles.get_child(0) as BossProjectile
	assert_not_null(projectile, "Lo scenario AFK deve contenere un proiettile ostile.")
	if projectile != null:
		projectile.set_physics_process(false)
		var travel_time := enemy.global_position.distance_to(target.global_position) / RANGED.ranged_projectile_speed
		threat_time += travel_time
		projectile._physics_process(travel_time)
		assert_true(
			projectile.global_position.distance_to(target.global_position)
				<= RANGED.ranged_projectile_radius + FLOAT_TOLERANCE,
			"Il proiettile deve raggiungere la posizione del Player fermo."
		)
	assert_true(threat_time <= 10.0, "La minaccia AFK deve raggiungere il Player entro 10 secondi.")
	print("LATE_RUN_PRESSURE_SMOKE_OK")
	_teardown_fixture(built)


func _build_spawner(seed_value: int) -> Dictionary:
	var fixture := Node2D.new()
	var arena := ArenaLayout.new()
	arena.respect_display_safe_area = false
	var controller := RunController.new()
	controller.set_process(false)
	var target := PLAYER_SCENE.instantiate() as Player
	var enemy_parent := Node2D.new()
	var projectile_parent := Node2D.new()
	var spawner := EnemySpawner.new()
	spawner.set_process(false)
	spawner.enemy_scene = ENEMY_SCENE
	spawner.spawn_profile = DEFAULT_PROFILE.duplicate(true) as EnemySpawnProfile
	spawner.archetypes = ARCHETYPES.duplicate()
	spawner.configure(controller, arena, target, enemy_parent, null, projectile_parent)
	fixture.add_child(arena)
	fixture.add_child(controller)
	fixture.add_child(target)
	fixture.add_child(enemy_parent)
	fixture.add_child(projectile_parent)
	fixture.add_child(spawner)
	add_child_autofree(fixture)
	await wait_process_frames(1)
	spawner.set_process(false)
	controller.set_process(false)
	target.global_position = arena.get_playfield_rect().get_center()
	controller.start_run(seed_value)
	return {
		"fixture": fixture,
		"spawner": spawner,
		"controller": controller,
		"target": target,
		"enemy_parent": enemy_parent,
		"projectile_parent": projectile_parent,
	}


func _enemy_signature(enemy: BaseEnemy) -> StringName:
	if enemy is RangedEnemy:
		return &"ranged"
	if enemy is SplitterEnemy:
		return &"splitter"
	if enemy == null:
		return &"none"
	match enemy.silhouette_kind:
		1:
			return &"swarmer"
		2:
			return &"armored"
		_:
			return &"base"


func _teardown_fixture(built: Dictionary) -> void:
	var controller: RunController = built["controller"]
	if controller.get_state() != RunController.RunState.BOOT:
		controller.prepare_restart()
