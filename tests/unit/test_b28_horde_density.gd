extends GutGameplayTest

const BASE_ENEMY_SCENE := preload("res://scenes/actors/base_enemy.tscn")
const BOSS_DEFINITION := preload("res://data/bosses/first_boss.tres")
const SPAWN_PROFILE := preload("res://data/spawn_profiles/default_enemy_spawn_profile.tres")
const WINDOWS_PERFORMANCE_PROFILE := preload("res://data/performance/windows_performance_profile.tres")
const MOBILE_PERFORMANCE_PROFILE := preload("res://data/performance/mobile_performance_profile.tres")
const HORDE_FLOAT_TOLERANCE := 0.0001


func test_baseline_density_and_xp_budget_declarations() -> void:
	var profile := SPAWN_PROFILE as EnemySpawnProfile
	var base_enemy := BASE_ENEMY_SCENE.instantiate() as BaseEnemy
	var base_health := base_enemy.get_node("HealthComponent") as HealthComponent
	var boss := BOSS_DEFINITION as BossDefinition
	var windows_profile := WINDOWS_PERFORMANCE_PROFILE as PerformanceProfile
	var mobile_profile := MOBILE_PERFORMANCE_PROFILE as PerformanceProfile

	assert_not_null(profile, "B28 richiede lo SpawnProfile ordinario.")
	assert_not_null(base_health, "B28 richiede la vita del nemico base dichiarata.")
	assert_not_null(boss, "B28 richiede la definizione Boss dichiarativa.")
	assert_true(windows_profile != null and mobile_profile != null, "B28 richiede entrambi i profili 60 FPS.")
	if profile == null or base_health == null or boss == null or windows_profile == null or mobile_profile == null:
		base_enemy.free()
		return

	assert_eq(profile.max_alive_enemies, 140, "B28 deve alzare il cap vivo a 140 unita.")
	assert_almost_eq(profile.base_spawn_interval, 0.6, HORDE_FLOAT_TOLERANCE, "B28 deve partire da una cadenza piu fitta.")
	assert_almost_eq(profile.min_spawn_interval, 0.12, HORDE_FLOAT_TOLERANCE, "B28 deve raggiungere la cadenza bullet-hell.")
	assert_almost_eq(
		profile.progression_experience_multiplier, 1.5, HORDE_FLOAT_TOLERANCE, "B28 deve aumentare il budget XP del 50%."
	)
	assert_almost_eq(base_health.health_max, 18.0, HORDE_FLOAT_TOLERANCE, "B37 deve ridurre la vita base da 24 a 18.")
	assert_true(
		boss.health_max >= base_health.health_max * 50.0
		and boss.radial_projectile_count > 0
		and boss.radial_telegraph_duration > 0.0
		and boss.targeted_telegraph_duration > 0.0,
		"Il Boss deve restare molto piu resistente e conservare telegraph leggibili."
	)
	assert_true(
		windows_profile.target_fps == 60
		and mobile_profile.target_fps == 60
		and windows_profile.stress_enemy_count >= profile.max_alive_enemies
		and mobile_profile.stress_enemy_count >= profile.max_alive_enemies,
		"I profili B18V devono stressare almeno la nuova densita reale a 60 FPS."
	)

	for run_time in [0.0, 60.0, 120.0, 160.0, 240.0]:
		var xp_per_second := profile.get_experience_reward_scale(run_time) / profile.get_spawn_interval(run_time)
		var target_xp_per_second := (
			profile.progression_experience_multiplier / profile.get_progression_reference_spawn_interval(run_time)
		)
		assert_almost_eq(
			xp_per_second,
			target_xp_per_second,
			HORDE_FLOAT_TOLERANCE,
			"Il budget XP a %.0f s deve rispettare il bonus B28 dichiarato." % run_time
		)

	base_enemy.free()


func test_fractional_xp_budget_compensates_across_kills() -> void:
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_run_controller() as RunController
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	var dropper := movement_slice.get_experience_dropper() as ExperienceDropper
	assert_true(
		controller != null and spawner != null and dropper != null, "B28 richiede la composizione spawn e XP."
	)
	if controller == null or spawner == null or dropper == null:
		return
	if not controller.is_running():
		assert_true(controller.start_run(2828), "La fixture B28 deve avviare una run.")
	spawner.set_process(false)
	spawner.reset_for_run(2828)

	var expected_credit := 0.0
	for kill_index in 5:
		var enemy := spawner.try_spawn_enemy()
		assert_not_null(enemy, "La kill B28 %d deve creare un nemico base." % (kill_index + 1))
		if enemy == null:
			continue
		expected_credit += enemy.get_experience_reward_value()
		var health := enemy.get_health_component()
		assert_not_null(health, "Il nemico B28 deve avere HealthComponent.")
		if health != null:
			assert_true(enemy.take_damage(health.health_current), "La kill B28 deve essere letale.")
		await wait_process_frames(1)

	var expected_xp := floori(expected_credit + 0.00001)
	var granted_xp := 0
	for pickup in dropper.get_active_pickups():
		granted_xp += pickup.experience_amount
	assert_eq(
		granted_xp, expected_xp, "Cinque kill base devono produrre %d XP compensati, ottenuti %d." % [expected_xp, granted_xp]
	)
	assert_true(granted_xp >= 4, "Cinque kill base iniziali devono ora produrre almeno 4 XP.")

	controller.prepare_restart()
