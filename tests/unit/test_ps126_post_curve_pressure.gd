extends GutGameplayTest

## PS-126 — Pressione oltre il minuto 5: nessuna curva di EnemySpawnProfile
## continua a crescere dopo late_run_curve_full_seconds, mentre il Boss
## ricorrente non guadagna mai HP/danno con le ricorrenze. Verifica il
## moltiplicatore lato nemici ordinari, quello lato Boss e la monotonia
## della pressione complessiva risultante.

const BOSS_THRESHOLD_SECONDS := 120.01
const RECURRING_WINDOW_SECONDS := 240.01


func test_ordinary_pressure_multiplier_is_one_until_the_curve_is_full() -> void:
	var profile := load("res://data/spawn_profiles/default_enemy_spawn_profile.tres") as EnemySpawnProfile
	assert_not_null(profile, "Profilo di spawn di produzione mancante.")
	if profile == null:
		return

	assert_almost_eq(
		profile.get_post_curve_pressure_multiplier(0.0), 1.0, FLOAT_TOLERANCE,
		"Prima della curva late-run il moltiplicatore deve restare 1.0."
	)
	assert_almost_eq(
		profile.get_post_curve_pressure_multiplier(profile.late_run_curve_full_seconds), 1.0, FLOAT_TOLERANCE,
		"Esattamente a late_run_curve_full_seconds il moltiplicatore deve essere ancora 1.0."
	)
	assert_true(
		profile.get_post_curve_pressure_multiplier(profile.late_run_curve_full_seconds + 60.0) > 1.0,
		"Un minuto oltre la curva late-run il moltiplicatore deve essere cresciuto."
	)


func test_ordinary_pressure_multiplier_is_monotonic_past_the_curve() -> void:
	var profile := load("res://data/spawn_profiles/default_enemy_spawn_profile.tres") as EnemySpawnProfile
	assert_not_null(profile, "Profilo di spawn di produzione mancante.")
	if profile == null:
		return

	var sample_times: Array[float] = [300.0, 480.0, 900.0]
	var previous_multiplier := -INF
	for sample_time in sample_times:
		var multiplier := profile.get_post_curve_pressure_multiplier(sample_time)
		assert_true(
			multiplier >= previous_multiplier,
			"La pressione oltre i 5 minuti non deve mai calare (t=%.0f)." % sample_time
		)
		previous_multiplier = multiplier


func test_boss_recurrence_multiplier_is_one_at_first_occurrence_and_grows() -> void:
	var profile := load("res://data/director_profiles/default_game_director_profile.tres") as GameDirectorProfile
	assert_not_null(profile, "Profilo director di produzione mancante.")
	if profile == null:
		return

	assert_almost_eq(
		profile.get_boss_recurrence_multiplier(0), 1.0, FLOAT_TOLERANCE,
		"La prima occorrenza del Boss non deve essere scalata."
	)
	assert_true(
		profile.get_boss_recurrence_multiplier(1) > profile.get_boss_recurrence_multiplier(0),
		"La seconda occorrenza deve essere piu' dura della prima."
	)
	assert_true(
		profile.get_boss_recurrence_multiplier(2) > profile.get_boss_recurrence_multiplier(1),
		"La terza occorrenza deve essere piu' dura della seconda."
	)


func test_spawned_enemy_stats_scale_past_the_curve() -> void:
	var built := await _build_fixture(126001)
	if built.is_empty():
		return
	var controller: RunController = built["controller"]
	var spawner: EnemySpawner = built["spawner"]
	var director: GameDirector = built["director"]

	# Il salto di run_time con controller._process() fa scattare in modo
	# sincrono la soglia Boss reale (120s) tramite run_time_changed: questo
	# test misura solo la pressione degli spawn ordinari, non il Boss (stesso
	# accorgimento di test_ps008_wave_events.gd:_collect_event_sequence).
	var neutral_director_profile := director.profile.duplicate(true) as GameDirectorProfile
	neutral_director_profile.boss_thresholds_seconds = PackedFloat32Array()
	director.profile = neutral_director_profile
	director.configure(controller, spawner)

	controller._process(spawner.spawn_profile.late_run_curve_full_seconds + 120.0)
	var expected_multiplier := spawner.spawn_profile.get_post_curve_pressure_multiplier(
		controller.get_run_time()
	)
	assert_true(expected_multiplier > 1.0, "La fixture deve trovarsi oltre la curva late-run per essere significativa.")

	var base_archetype := load("res://data/enemies/enemy_archetype_armored.tres") as EnemyArchetypeDefinition
	assert_not_null(base_archetype, "Archetipo armored mancante.")
	if base_archetype == null:
		_teardown_fixture(built)
		return

	var playfield_rect := spawner.get_visible_reference_rect()
	var enemy := spawner.spawn_archetype_instance(base_archetype, playfield_rect.get_center())
	assert_not_null(enemy, "Lo spawn diretto dell'archetipo deve riuscire nella fixture di test.")
	if enemy != null:
		var health_component := enemy.get_health_component()
		var contact_damage := enemy.get_contact_damage()
		assert_almost_eq(
			health_component.health_max, base_archetype.health_max * expected_multiplier, 0.05,
			"L'HP del nemico spawnato oltre la curva deve essere scalato dal moltiplicatore di pressione."
		)
		assert_almost_eq(
			contact_damage.damage, base_archetype.contact_damage * expected_multiplier, 0.05,
			"Il danno da contatto del nemico spawnato oltre la curva deve essere scalato dal moltiplicatore di pressione."
		)

	var ranged_archetype := load("res://data/enemies/enemy_archetype_ranged.tres") as EnemyArchetypeDefinition
	assert_not_null(ranged_archetype, "Archetipo ranged mancante.")
	if ranged_archetype != null:
		var ranged_enemy := spawner.spawn_archetype_instance(ranged_archetype, playfield_rect.get_center())
		assert_not_null(ranged_enemy, "Lo spawn diretto del tiratore deve riuscire nella fixture di test.")
		if ranged_enemy != null:
			assert_true(
				ranged_enemy is RangedEnemy,
				"L'archetipo ranged deve produrre un'istanza RangedEnemy."
			)
			assert_almost_eq(
				ranged_enemy.pressure_multiplier, expected_multiplier, 0.0001,
				(
					"Il tiratore deve ricevere pressure_multiplier: senza, il suo danno a "
					+ "distanza (ranged_projectile_damage) resterebbe piatto per sempre "
					+ "mentre HP/danno da contatto degli altri nemici crescono (N2)."
				)
			)

	_teardown_fixture(built)


func test_recurring_boss_gets_tougher_than_the_first_occurrence() -> void:
	var built := await _build_fixture(126002)
	if built.is_empty():
		return
	var controller: RunController = built["controller"]
	var encounter: BossEncounter = built["encounter"]
	var experience: ExperienceSystem = built["experience"]
	var service: UpgradeService = built["service"]
	var director: GameDirector = built["director"]

	var base_health_max: float = load("res://data/bosses/first_boss.tres").health_max

	controller._process(BOSS_THRESHOLD_SECONDS)
	assert_eq(controller.get_state(), RunController.RunState.BOSS_INTRO, "La soglia deve aprire BOSS_INTRO.")
	var first_boss := encounter.get_active_boss()
	assert_not_null(first_boss, "Il primo Boss deve esistere per la verifica.")
	if first_boss != null:
		assert_almost_eq(
			first_boss.get_health_component().health_max, base_health_max, 0.05,
			"Il primo Boss (schedule_index 0) non deve essere scalato."
		)

	assert_true(encounter.complete_intro(), "L'intro del primo Boss deve potersi chiudere.")
	_kill_active_boss(encounter, controller, experience, service)

	controller._process(RECURRING_WINDOW_SECONDS)
	assert_eq(controller.get_state(), RunController.RunState.BOSS_INTRO, "La finestra ricorrente deve aprire BOSS_INTRO.")
	var second_boss := encounter.get_active_boss()
	assert_not_null(second_boss, "Il secondo Boss (ricorrente) deve esistere per la verifica.")
	if second_boss != null:
		var expected_multiplier := director.profile.get_boss_recurrence_multiplier(1)
		assert_true(expected_multiplier > 1.0, "La fixture deve avere una crescita di ricorrenza non nulla per essere significativa.")
		assert_almost_eq(
			second_boss.get_health_component().health_max, base_health_max * expected_multiplier, 0.05,
			"Il secondo Boss (schedule_index 1) deve essere scalato dal moltiplicatore di ricorrenza."
		)
		assert_almost_eq(
			second_boss.pressure_multiplier, expected_multiplier, 0.0001,
			(
				"Il secondo Boss deve ricevere pressure_multiplier: e' quello che first_boss.gd "
				+ "legge per scalare anche raffica radiale, colpo mirato e danno delle Signature, "
				+ "non solo HP/contatto."
			)
		)

	print("PS126_POST_CURVE_PRESSURE_SMOKE_OK")
	_teardown_fixture(built)


func _kill_active_boss(
	encounter: BossEncounter,
	controller: RunController,
	experience: ExperienceSystem,
	service: UpgradeService
) -> void:
	var boss := encounter.get_active_boss()
	assert_not_null(boss, "Impossibile uccidere un Boss assente.")
	if boss == null:
		return
	var health := boss.get_health_component()
	assert_not_null(health, "Il Boss attivo deve avere una HealthComponent.")
	if health == null:
		return
	boss.take_damage(health.health_current)
	while controller.get_state() == RunController.RunState.LEVEL_UP:
		if not experience.complete_level_up():
			break
	while controller.get_state() == RunController.RunState.BARB_REWARD:
		var offer := service.get_current_barb_offer()
		if offer.is_empty():
			break
		var chosen_id: StringName = offer[0].id
		var resolved := (
			service.select_barb_bonus_upgrade(chosen_id)
			if service.is_barb_bonus_mode()
			else service.select_barb_speciality(chosen_id)
		)
		if not resolved:
			break


func _build_fixture(seed_value: int) -> Dictionary:
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_run_controller() as RunController
	var encounter := movement_slice.get_boss_encounter() as BossEncounter
	var experience := movement_slice.get_experience_system() as ExperienceSystem
	var service := movement_slice.get_upgrade_service() as UpgradeService
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	var director := movement_slice.get_game_director() as GameDirector
	assert_true(
		controller != null and encounter != null and experience != null and service != null
		and spawner != null and director != null,
		"PS-126 richiede RunController, BossEncounter, ExperienceSystem, UpgradeService, EnemySpawner e GameDirector."
	)
	if (
		controller == null or encounter == null or experience == null or service == null
		or spawner == null or director == null
	):
		return {}

	if not controller.is_terminal():
		controller.request_defeat()
	assert_true(
		movement_slice.restart_run(seed_value), "La fixture PS-126 deve poter avviare la run con il seed richiesto."
	)
	await wait_process_frames(2)
	controller.set_process(false)

	return {
		"movement_slice": movement_slice,
		"controller": controller,
		"encounter": encounter,
		"experience": experience,
		"service": service,
		"spawner": spawner,
		"director": director,
	}


func _teardown_fixture(built: Dictionary) -> void:
	var controller: RunController = built.get("controller")
	if controller != null and not controller.is_terminal():
		controller.request_defeat()
	if controller != null:
		controller.prepare_restart()
