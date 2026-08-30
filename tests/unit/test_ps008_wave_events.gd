extends GutGameplayTest

## PS-008 — Eventi d'ondata: scheduler, formazioni e integrazione Boss/pausa.

const LATERAL_STEP := 0.5


func test_no_event_before_min_start_seconds() -> void:
	var built := await _build_fixture(80001)
	var scheduler: WaveEventScheduler = built.get("scheduler")
	var controller: RunController = built.get("controller")
	if scheduler == null:
		return

	var profile := _make_profile(
		[_make_formation_definition(&"pre_soglia", WaveEventDefinition.EFFECT_LATERAL_SWARM)],
		101.0,
		1.0,
		1.0
	)
	_apply_profile(built, profile)

	for _tick in range(20):
		controller._process(5.0)
		scheduler._process(5.0)
	assert_eq(
		scheduler.get_phase(), WaveEventScheduler.Phase.IDLE,
		"Nessun evento puo' iniziare prima della soglia configurata, anche con cooldown gia' maturo."
	)

	_teardown_fixture(built)


func test_surround_uses_all_sectors_with_telegraph_and_restores_ordinary_spawn() -> void:
	var built := await _build_fixture(80002)
	var scheduler: WaveEventScheduler = built.get("scheduler")
	var spawner: EnemySpawner = built.get("spawner")
	var controller: RunController = built.get("controller")
	if scheduler == null:
		return

	var surround := _make_formation_definition(&"accerchiamento_test", WaveEventDefinition.EFFECT_SURROUND)
	surround.requires_telegraph = true
	surround.telegraph_duration_seconds = 1.0
	surround.duration_seconds = 3.0
	surround.formation_spawn_interval_seconds = 0.4
	surround.formation_enemy_count = 4
	surround.ordinary_spawn_mode = WaveEventDefinition.ORDINARY_MODE_REPLACED
	_apply_profile(built, _make_profile([surround], 0.0, 1.0, 1.0))

	controller._process(1.0)
	scheduler._process(1.0)
	assert_true(scheduler.is_telegraph_active(), "Accerchiamento deve aprirsi con un telegraph.")
	assert_false(
		spawner.is_sector_override_active(),
		"L'override dei settori non deve applicarsi prima che il telegraph finisca."
	)

	scheduler._process(1.0)
	assert_true(scheduler.is_event_active(), "Il telegraph deve risolversi nella formazione attiva.")
	assert_true(spawner.is_sector_override_active(), "Accerchiamento deve forzare i settori.")
	assert_eq(
		spawner.get_active_sectors().size(), EnemySpawner.ALL_SECTORS.size(),
		"Accerchiamento deve usare tutti i settori contemporaneamente."
	)
	assert_true(
		spawner.is_ordinary_spawn_suspended(),
		"Accerchiamento e' configurato per sostituire lo spawn ordinario."
	)

	for _tick in range(6):
		scheduler._process(0.4)
	assert_eq(
		spawner.get_spawned_enemies().size(), surround.formation_enemy_count,
		"La formazione deve generare esattamente il numero di nemici dichiarato, senza sforare."
	)

	scheduler._process(2.0)
	assert_eq(scheduler.get_phase(), WaveEventScheduler.Phase.IDLE, "L'evento deve terminare dopo la durata dichiarata.")
	assert_false(spawner.is_sector_override_active(), "Fine evento deve liberare l'override dei settori.")
	assert_false(spawner.is_ordinary_spawn_suspended(), "Fine evento deve far riprendere lo spawn ordinario.")

	_teardown_fixture(built)


func test_lateral_swarm_starts_without_telegraph_on_a_single_sector() -> void:
	var built := await _build_fixture(80003)
	var scheduler: WaveEventScheduler = built.get("scheduler")
	var spawner: EnemySpawner = built.get("spawner")
	var controller: RunController = built.get("controller")
	if scheduler == null:
		return

	var lateral := _make_formation_definition(&"stormo_test", WaveEventDefinition.EFFECT_LATERAL_SWARM)
	lateral.requires_telegraph = false
	lateral.duration_seconds = 3.0
	_apply_profile(built, _make_profile([lateral], 0.0, 1.0, 1.0))

	controller._process(1.0)
	scheduler._process(1.0)
	assert_true(
		scheduler.is_event_active(),
		"Stormo laterale non richiede telegraph: deve entrare subito in fase attiva."
	)
	assert_eq(
		spawner.get_active_sectors().size(), 1,
		"Stormo laterale deve forzare un solo lato."
	)

	_teardown_fixture(built)


func test_ranged_nest_boosts_weight_without_sector_override() -> void:
	var built := await _build_fixture(80004)
	var scheduler: WaveEventScheduler = built.get("scheduler")
	var spawner: EnemySpawner = built.get("spawner")
	var controller: RunController = built.get("controller")
	if scheduler == null:
		return

	var nest := WaveEventDefinition.new()
	nest.event_id = &"nido_test"
	nest.effect_id = WaveEventDefinition.EFFECT_RANGED_NEST
	nest.requires_telegraph = false
	nest.duration_seconds = 3.0
	nest.ordinary_spawn_mode = WaveEventDefinition.ORDINARY_MODE_UNCHANGED
	nest.ranged_archetype_id = &"ranged"
	nest.ranged_weight_multiplier = 4.5
	_apply_profile(built, _make_profile([nest], 0.0, 1.0, 1.0))

	controller._process(1.0)
	scheduler._process(1.0)
	assert_true(scheduler.is_event_active(), "Nido di tiratori non richiede telegraph globale.")
	assert_false(
		spawner.is_sector_override_active(),
		"Nido di tiratori non deve toccare i settori di spawn."
	)
	assert_false(
		spawner.is_ordinary_spawn_suspended(),
		"Nido di tiratori e' configurato come 'unchanged': lo spawn ordinario prosegue."
	)
	assert_almost_eq(
		spawner.get_archetype_weight_override(&"ranged"), 4.5, FLOAT_TOLERANCE,
		"Il peso del tiratore deve risultare aumentato del moltiplicatore dichiarato."
	)

	scheduler._process(3.0)
	assert_almost_eq(
		spawner.get_archetype_weight_override(&"ranged"), 1.0, FLOAT_TOLERANCE,
		"Fine evento deve azzerare l'override di peso."
	)

	_teardown_fixture(built)


func test_boss_active_postpones_matured_event_without_queueing() -> void:
	var built := await _build_fixture(80005)
	var scheduler: WaveEventScheduler = built.get("scheduler")
	var spawner: EnemySpawner = built.get("spawner")
	var controller: RunController = built.get("controller")
	if scheduler == null:
		return

	var surround := _make_formation_definition(&"accerchiamento_boss", WaveEventDefinition.EFFECT_SURROUND)
	surround.requires_telegraph = true
	surround.telegraph_duration_seconds = 5.0
	var profile := _make_profile([surround], 0.0, 1.0, 1.0)
	profile.boss_maturation_policy = WaveEventSchedulerProfile.POLICY_POSTPONE
	_apply_profile(built, profile)

	controller._process(1.0)
	scheduler._process(1.0)
	assert_true(scheduler.is_telegraph_active(), "Serve un evento in corso per simulare l'interruzione da Boss.")

	scheduler._handle_boss_active()
	assert_eq(
		scheduler.get_phase(), WaveEventScheduler.Phase.IDLE,
		"Un Boss attivo deve interrompere subito l'evento maturato."
	)
	assert_false(spawner.is_sector_override_active(), "L'interruzione deve liberare ogni override residuo.")

	scheduler._process(0.001)
	assert_true(
		scheduler.get_phase() != WaveEventScheduler.Phase.IDLE,
		"La regola 'postpone' deve far ritentare l'evento non appena il Boss non blocca piu' lo scheduler."
	)

	_teardown_fixture(built)


func test_boss_active_can_discard_matured_event() -> void:
	var built := await _build_fixture(80006)
	var scheduler: WaveEventScheduler = built.get("scheduler")
	var controller: RunController = built.get("controller")
	if scheduler == null:
		return

	var lateral := _make_formation_definition(&"stormo_boss", WaveEventDefinition.EFFECT_LATERAL_SWARM)
	lateral.duration_seconds = 5.0
	var profile := _make_profile([lateral], 0.0, 1.0, 1.0)
	profile.boss_maturation_policy = WaveEventSchedulerProfile.POLICY_DISCARD
	_apply_profile(built, profile)

	controller._process(1.0)
	scheduler._process(1.0)
	assert_true(scheduler.is_event_active(), "Serve un evento attivo per simulare lo scarto da Boss.")

	scheduler._handle_boss_active()
	scheduler._process(0.001)
	assert_eq(
		scheduler.get_phase(), WaveEventScheduler.Phase.IDLE,
		"La regola 'discard' non deve far ripartire l'evento subito dopo l'interruzione."
	)

	_teardown_fixture(built)


func test_pause_and_level_up_freeze_scheduler_and_telegraph() -> void:
	var built := await _build_fixture(80007)
	var scheduler: WaveEventScheduler = built.get("scheduler")
	var controller: RunController = built.get("controller")
	if scheduler == null:
		return

	var surround := _make_formation_definition(&"accerchiamento_pausa", WaveEventDefinition.EFFECT_SURROUND)
	surround.requires_telegraph = true
	surround.telegraph_duration_seconds = 10.0
	_apply_profile(built, _make_profile([surround], 0.0, 1.0, 1.0))

	controller._process(1.0)
	scheduler._process(1.0)
	assert_true(scheduler.is_telegraph_active(), "Serve un telegraph in corso per verificare il congelamento.")
	var remaining_before := scheduler.get_telegraph_remaining()

	assert_true(controller.request_manual_pause(), "La fixture deve poter entrare in pausa.")
	scheduler._process(5.0)
	assert_almost_eq(
		scheduler.get_telegraph_remaining(), remaining_before, FLOAT_TOLERANCE,
		"La pausa manuale deve congelare il telegraph in corso."
	)

	assert_true(controller.resume_run(), "La fixture deve poter riprendere la run.")
	scheduler._process(1.0)
	assert_true(
		scheduler.get_telegraph_remaining() < remaining_before,
		"Dopo la ripresa il telegraph deve tornare ad avanzare."
	)

	_teardown_fixture(built)


func test_restart_clears_scheduler_and_spawner_overrides() -> void:
	var built := await _build_fixture(80008)
	var movement_slice: Control = built.get("movement_slice")
	var scheduler: WaveEventScheduler = built.get("scheduler")
	var spawner: EnemySpawner = built.get("spawner")
	var controller: RunController = built.get("controller")
	if scheduler == null:
		return

	var surround := _make_formation_definition(&"accerchiamento_restart", WaveEventDefinition.EFFECT_SURROUND)
	surround.requires_telegraph = false
	surround.duration_seconds = 30.0
	_apply_profile(built, _make_profile([surround], 0.0, 1.0, 1.0))

	controller._process(1.0)
	scheduler._process(1.0)
	assert_true(scheduler.is_event_active(), "Serve un evento attivo prima del restart.")
	assert_true(spawner.is_sector_override_active(), "L'evento deve aver applicato un override prima del restart.")

	assert_true(controller.request_defeat(), "Il test deve poter forzare DEFEAT.")
	assert_true(
		movement_slice.restart_run(80009), "Il restart deve poter ripartire in-place."
	)
	await wait_process_frames(2)

	assert_eq(
		scheduler.get_phase(), WaveEventScheduler.Phase.IDLE,
		"Il restart deve eliminare completamente evento e telegraph residui."
	)
	assert_false(
		spawner.is_sector_override_active(), "Il restart deve liberare l'override dei settori."
	)
	assert_false(
		spawner.is_ordinary_spawn_suspended(), "Il restart deve liberare la sospensione dello spawn ordinario."
	)

	_teardown_fixture(built)


func test_telegraph_reaches_hud_and_hides_on_transitions() -> void:
	var built := await _build_fixture(80010)
	var scheduler: WaveEventScheduler = built.get("scheduler")
	var controller: RunController = built.get("controller")
	var hud: GameHud = built.get("hud")
	if scheduler == null:
		return

	var surround := _make_formation_definition(&"accerchiamento_hud", WaveEventDefinition.EFFECT_SURROUND)
	surround.requires_telegraph = true
	surround.telegraph_duration_seconds = 1.0
	surround.telegraph_display_text = "ACCERCHIAMENTO IN ARRIVO"
	_apply_profile(built, _make_profile([surround], 0.0, 1.0, 1.0))

	assert_false(
		hud.is_wave_event_telegraph_visible(), "La HUD non deve mostrare telegraph prima che uno scada."
	)

	controller._process(1.0)
	scheduler._process(1.0)
	assert_true(scheduler.is_telegraph_active(), "Serve un telegraph aperto per verificare l'inoltro alla HUD.")
	assert_true(
		hud.is_wave_event_telegraph_visible(),
		"La HUD deve reagire al segnale wave_event_telegraph_changed dello scheduler."
	)

	scheduler._process(1.0)
	assert_true(scheduler.is_event_active(), "Il telegraph deve risolversi nella formazione attiva.")
	assert_false(
		hud.is_wave_event_telegraph_visible(),
		"La HUD deve nascondere il telegraph non appena la formazione diventa attiva."
	)

	_teardown_fixture(built)


func test_real_boss_lifecycle_interrupts_matured_event_and_postpones() -> void:
	var built := await _build_fixture(80011)
	var scheduler: WaveEventScheduler = built.get("scheduler")
	var controller: RunController = built.get("controller")
	var director: GameDirector = built.get("director")
	var spawner: EnemySpawner = built.get("spawner")
	var encounter: BossEncounter = built.get("encounter")
	var experience: ExperienceSystem = built.get("experience")
	var service: UpgradeService = built.get("service")
	if scheduler == null:
		return

	var lateral := _make_formation_definition(&"stormo_boss_reale", WaveEventDefinition.EFFECT_LATERAL_SWARM)
	lateral.duration_seconds = 600.0
	_apply_profile(built, _make_profile([lateral], 0.0, 1.0, 1.0))

	controller._process(1.0)
	scheduler._process(1.0)
	assert_true(scheduler.is_event_active(), "Serve un evento gia' attivo prima che il Boss dati maturi.")

	# La soglia Boss del profilo director predefinito e' 02:00: qui deve
	# aprire subito BOSS_INTRO, che congela lo scheduler senza annullare
	# l'evento (lo fara' il combattimento, non l'ingresso).
	controller._process(130.0)
	scheduler._process(130.0)
	spawner._process(130.0)
	assert_eq(
		controller.get_state(), RunController.RunState.BOSS_INTRO,
		"La soglia Boss dati deve aprire BOSS_INTRO anche con un evento d'ondata gia' in corso."
	)
	assert_true(
		scheduler.is_event_active(),
		"BOSS_INTRO deve congelare l'evento in corso, non annullarlo."
	)

	assert_true(encounter.complete_intro(), "L'intro del Boss deve poter essere confermata.")
	scheduler._process(0.1)
	assert_eq(
		scheduler.get_phase(), WaveEventScheduler.Phase.IDLE,
		"Il combattimento Boss in RUNNING deve interrompere l'evento rimasto congelato durante l'intro."
	)
	assert_false(spawner.is_sector_override_active(), "L'interruzione da Boss deve liberare l'override dei settori.")

	var boss := encounter.get_active_boss()
	assert_not_null(boss, "Il test richiede un Boss attivo da sconfiggere.")
	if boss != null:
		var health := boss.get_health_component()
		if health != null:
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

	assert_false(
		director.has_blocking_boss_event(), "Il Boss sconfitto non deve restare bloccante per lo scheduler."
	)
	scheduler._process(0.001)
	assert_true(
		scheduler.get_phase() != WaveEventScheduler.Phase.IDLE,
		"La regola 'postpone' di default deve far ritentare l'evento non appena il Boss libera lo scheduler."
	)

	_teardown_fixture(built)


func test_deterministic_event_sequence_for_seed() -> void:
	var sequence_a := await _collect_event_sequence(90001)
	var sequence_b := await _collect_event_sequence(90001)
	assert_true(
		sequence_a.size() > 0 and sequence_a == sequence_b,
		"Lo stesso seed deve produrre la stessa sequenza di eventi e formazioni."
	)


func _collect_event_sequence(seed_value: int) -> Array[StringName]:
	var built := await _build_fixture(seed_value)
	var scheduler: WaveEventScheduler = built.get("scheduler")
	var controller: RunController = built.get("controller")
	var director: GameDirector = built.get("director")
	var spawner: EnemySpawner = built.get("spawner")
	var sequence: Array[StringName] = []
	if scheduler == null:
		return sequence

	# Il default_game_director_profile pianifica un Boss a 02:00, prima della
	# soglia minima 02:30 degli eventi d'ondata: qui interessa solo la
	# determinismo della sequenza PS-008, cosi' si neutralizza il Boss invece
	# di dover pilotare anche il suo intero ciclo di vita.
	var neutral_director_profile := director.profile.duplicate(true) as GameDirectorProfile
	neutral_director_profile.boss_thresholds_seconds = PackedFloat32Array()
	director.profile = neutral_director_profile
	director.configure(controller, spawner)

	var recorder := func(event_id: StringName) -> void:
		sequence.append(event_id)
	scheduler.wave_event_started.connect(recorder)

	for _tick in range(80):
		controller._process(5.0)
		scheduler._process(5.0)

	scheduler.wave_event_started.disconnect(recorder)
	_teardown_fixture(built)
	return sequence


func _make_formation_definition(event_id: StringName, effect_id: int) -> WaveEventDefinition:
	var definition := WaveEventDefinition.new()
	definition.event_id = event_id
	definition.effect_id = effect_id
	definition.duration_seconds = 4.0
	definition.formation_archetype_id = &"swarmer"
	definition.formation_enemy_count = 3
	definition.formation_spawn_interval_seconds = 0.3
	return definition


func _make_profile(
	events: Array[WaveEventDefinition],
	min_start_seconds: float,
	cooldown_min_seconds: float,
	cooldown_max_seconds: float
) -> WaveEventSchedulerProfile:
	var profile := WaveEventSchedulerProfile.new()
	profile.events = events
	profile.min_start_seconds = min_start_seconds
	profile.cooldown_min_seconds = cooldown_min_seconds
	profile.cooldown_max_seconds = cooldown_max_seconds
	return profile


func _apply_profile(built: Dictionary, profile: WaveEventSchedulerProfile) -> void:
	var scheduler: WaveEventScheduler = built.get("scheduler")
	scheduler.profile = profile
	scheduler.configure(
		scheduler.get_run_controller(),
		scheduler.get_game_director(),
		scheduler.get_enemy_spawner()
	)


func _build_fixture(seed_value: int) -> Dictionary:
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_run_controller() as RunController
	var scheduler := movement_slice.get_wave_event_scheduler() as WaveEventScheduler
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	var director := movement_slice.get_game_director() as GameDirector
	var hud := movement_slice.get_hud() as GameHud
	var encounter := movement_slice.get_boss_encounter() as BossEncounter
	var experience := movement_slice.get_experience_system() as ExperienceSystem
	var service := movement_slice.get_upgrade_service() as UpgradeService
	assert_true(
		controller != null and scheduler != null and spawner != null and director != null
		and hud != null and encounter != null and experience != null and service != null,
		"PS-008 richiede RunController, WaveEventScheduler, EnemySpawner, GameDirector, HUD, "
		+ "BossEncounter, ExperienceSystem e UpgradeService dalla scena."
	)
	if (
		controller == null or scheduler == null or spawner == null or director == null
		or hud == null or encounter == null or experience == null or service == null
	):
		return {}

	if not controller.is_terminal():
		controller.request_defeat()
	assert_true(
		movement_slice.restart_run(seed_value),
		"La fixture PS-008 deve poter avviare la run con il seed richiesto."
	)
	await wait_process_frames(2)
	controller.set_process(false)
	spawner.set_process(false)
	scheduler.set_process(false)

	return {
		"movement_slice": movement_slice,
		"controller": controller,
		"scheduler": scheduler,
		"spawner": spawner,
		"director": director,
		"hud": hud,
		"encounter": encounter,
		"experience": experience,
		"service": service,
	}


func _teardown_fixture(built: Dictionary) -> void:
	var controller: RunController = built.get("controller")
	if controller == null:
		return
	if not controller.is_terminal():
		controller.request_defeat()
	controller.prepare_restart()
