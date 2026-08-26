extends SceneTree

const BASE_ENEMY_SCENE := preload("res://scenes/actors/base_enemy.tscn")
const BOSS_DEFINITION := preload("res://data/bosses/first_boss.tres")
const MOVEMENT_SLICE_SCENE := preload("res://scenes/game/movement_slice.tscn")
const SPAWN_PROFILE := preload("res://data/spawn_profiles/default_enemy_spawn_profile.tres")
const WINDOWS_PERFORMANCE_PROFILE := preload("res://data/performance/windows_performance_profile.tres")
const MOBILE_PERFORMANCE_PROFILE := preload("res://data/performance/mobile_performance_profile.tres")
const FLOAT_TOLERANCE := 0.0001

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	paused = false
	await _validate_baseline()
	await _validate_fractional_xp_budget()
	await _finish()


func _validate_baseline() -> void:
	var profile := SPAWN_PROFILE as EnemySpawnProfile
	var base_enemy := BASE_ENEMY_SCENE.instantiate() as BaseEnemy
	var base_health := base_enemy.get_node("HealthComponent") as HealthComponent
	var boss := BOSS_DEFINITION as BossDefinition
	var windows_profile := WINDOWS_PERFORMANCE_PROFILE as PerformanceProfile
	var mobile_profile := MOBILE_PERFORMANCE_PROFILE as PerformanceProfile

	_expect(profile != null, "B28 richiede lo SpawnProfile ordinario.")
	_expect(base_health != null, "B28 richiede la vita del nemico base dichiarata.")
	_expect(boss != null, "B28 richiede la definizione Boss dichiarativa.")
	_expect(windows_profile != null and mobile_profile != null, "B28 richiede entrambi i profili 60 FPS.")
	if profile == null or base_health == null or boss == null or windows_profile == null or mobile_profile == null:
		base_enemy.free()
		return

	_expect(profile.max_alive_enemies == 140, "B28 deve alzare il cap vivo a 140 unita.")
	_expect_float_near(profile.base_spawn_interval, 0.6, "B28 deve partire da una cadenza piu fitta.")
	_expect_float_near(profile.min_spawn_interval, 0.12, "B28 deve raggiungere la cadenza bullet-hell.")
	_expect_float_near(profile.progression_experience_multiplier, 1.5, "B28 deve aumentare il budget XP del 50%.")
	_expect_float_near(base_health.health_max, 24.0, "B28 deve ridurre la vita base da 40 a 24.")
	_expect(
		boss.health_max >= base_health.health_max * 50.0
		and boss.radial_projectile_count > 0
		and boss.radial_telegraph_duration > 0.0
		and boss.targeted_telegraph_duration > 0.0,
		"Il Boss deve restare molto piu resistente e conservare telegraph leggibili."
	)
	_expect(
		windows_profile.target_fps == 60
		and mobile_profile.target_fps == 60
		and windows_profile.stress_enemy_count >= profile.max_alive_enemies
		and mobile_profile.stress_enemy_count >= profile.max_alive_enemies,
		"I profili B18V devono stressare almeno la nuova densita reale a 60 FPS."
	)

	for run_time in [0.0, 60.0, 120.0, 160.0, 240.0]:
		var xp_per_second := profile.get_experience_reward_scale(run_time) / profile.get_spawn_interval(run_time)
		var target_xp_per_second := profile.progression_experience_multiplier / profile.get_progression_reference_spawn_interval(run_time)
		_expect_float_near(
			xp_per_second,
			target_xp_per_second,
			"Il budget XP a %.0f s deve rispettare il bonus B28 dichiarato." % run_time
		)

	base_enemy.free()


func _validate_fractional_xp_budget() -> void:
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	root.add_child(movement_slice)
	await process_frame
	await physics_frame

	var controller := movement_slice.get_run_controller() as RunController
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	var dropper := movement_slice.get_experience_dropper() as ExperienceDropper
	_expect(controller != null and spawner != null and dropper != null, "B28 richiede la composizione spawn e XP.")
	if controller == null or spawner == null or dropper == null:
		movement_slice.queue_free()
		await process_frame
		return
	if not controller.is_running():
		_expect(controller.start_run(2828), "La fixture B28 deve avviare una run.")
	spawner.set_process(false)
	spawner.reset_for_run(2828)

	var expected_credit := 0.0
	for kill_index in 5:
		var enemy := spawner.try_spawn_enemy()
		_expect(enemy != null, "La kill B28 %d deve creare un nemico base." % (kill_index + 1))
		if enemy == null:
			continue
		expected_credit += enemy.get_experience_reward_value()
		var health := enemy.get_health_component()
		_expect(health != null, "Il nemico B28 deve avere HealthComponent.")
		if health != null:
			_expect(enemy.take_damage(health.health_current), "La kill B28 deve essere letale.")
		await process_frame

	var expected_xp := floori(expected_credit + 0.00001)
	var granted_xp := 0
	for pickup in dropper.get_active_pickups():
		granted_xp += pickup.experience_amount
	_expect(
		granted_xp == expected_xp,
		"Cinque kill base devono produrre %d XP compensati, ottenuti %d." % [expected_xp, granted_xp]
	)
	_expect(granted_xp >= 4, "Cinque kill base iniziali devono ora produrre almeno 4 XP.")

	controller.prepare_restart()
	paused = false
	movement_slice.queue_free()
	await process_frame


func _expect_float_near(actual: float, expected: float, message: String) -> void:
	_expect(
		absf(actual - expected) <= FLOAT_TOLERANCE,
		"%s Atteso %.5f, ottenuto %.5f." % [message, expected, actual]
	)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	paused = false
	await process_frame
	if _failures.is_empty():
		print("B28_HORDE_DENSITY_SMOKE_OK")
		quit(0)
		return
	for failure in _failures:
		printerr(failure)
	printerr("B28_HORDE_DENSITY_SMOKE_FAIL count=%d" % _failures.size())
	quit(1)
