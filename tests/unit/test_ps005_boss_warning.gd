extends GutGameplayTest

const FIRST_BOSS_SECONDS := 120.0
const WARNING_START_SECONDS := 105.0
const COUNTDOWN_START_SECONDS := 115.0

var _warning_events: Array[Dictionary] = []


func test_warning_profile_keeps_configurable_safe_timings() -> void:
	var profile := GameDirectorProfile.new()
	profile.boss_warning_lead_seconds = 18.5
	profile.boss_countdown_seconds = 7.0
	assert_almost_eq(
		profile.get_effective_boss_warning_lead(), 18.5, FLOAT_TOLERANCE,
		"PS-005 deve mantenere configurabile il preavviso generale."
	)
	assert_almost_eq(
		profile.get_effective_boss_countdown(), 7.0, FLOAT_TOLERANCE,
		"PS-005 deve mantenere configurabile la finestra numerica."
	)
	profile.boss_warning_lead_seconds = 4.0
	assert_almost_eq(
		profile.get_effective_boss_countdown(), 4.0, FLOAT_TOLERANCE,
		"Il countdown non deve iniziare prima del warning generale."
	)
	profile.boss_warning_lead_seconds = INF
	profile.boss_countdown_seconds = -5.0
	assert_almost_eq(
		profile.get_effective_boss_warning_lead(), 0.0, FLOAT_TOLERANCE,
		"Un timing non finito deve disabilitare il warning in sicurezza."
	)
	assert_almost_eq(
		profile.get_effective_boss_countdown(), 0.0, FLOAT_TOLERANCE,
		"Un countdown negativo deve essere normalizzato a zero."
	)


func test_warning_uses_running_clock_and_hands_off_to_boss_intro() -> void:
	_warning_events.clear()
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_run_controller() as RunController
	var director := movement_slice.get_game_director() as GameDirector
	var encounter := movement_slice.get_boss_encounter() as BossEncounter
	var hud := movement_slice.get_hud() as GameHud
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	var player := movement_slice.get_node_or_null("World/Player") as Player
	var input_router := movement_slice.get_node_or_null("InputRouter") as InputRouter
	var weapon := movement_slice.get_weapon_controller() as WeaponController
	assert_true(
		controller != null
		and director != null
		and encounter != null
		and hud != null
		and spawner != null
		and player != null
		and input_router != null
		and weapon != null,
		"PS-005 richiede scheduler, HUD e controlli gameplay dalla scena composta."
	)
	if (
		controller == null
		or director == null
		or encounter == null
		or hud == null
		or spawner == null
		or player == null
		or input_router == null
		or weapon == null
	):
		return

	controller.set_process(false)
	spawner.set_process(false)
	director.boss_warning_changed.connect(_on_boss_warning_changed)
	var thresholds := director.get_thresholds()
	assert_eq(thresholds.size(), 1, "PS-005 deve conservare una sola soglia Boss fissa.")
	if thresholds.size() != 1:
		controller.prepare_restart()
		return
	assert_almost_eq(
		thresholds[0], FIRST_BOSS_SECONDS, FLOAT_TOLERANCE,
		"PS-005 deve rendere il primo Boss eleggibile a 02:00 di clock RUNNING."
	)
	assert_eq(hud.get_game_director(), director, "L'HUD PS-005 deve osservare il Director autorevole.")
	assert_false(hud.is_boss_warning_visible(), "Il warning PS-005 deve partire nascosto.")

	_advance_to(controller, WARNING_START_SECONDS - 0.01)
	assert_false(hud.is_boss_warning_visible(), "Prima di 01:45 il warning non deve comparire.")
	_advance_to(controller, WARNING_START_SECONDS)
	assert_true(hud.is_boss_warning_visible(), "A 01:45 il warning PS-005 deve comparire.")
	assert_eq(hud.get_boss_warning_text(), "BOSS IN ARRIVO", "Il preavviso generale deve usare il copy approvato.")
	assert_eq(
		director.get_boss_warning_phase(), GameDirector.BossWarningPhase.APPROACHING,
		"Il Director deve esporre la fase generale una sola volta."
	)
	assert_true(controller.is_running() and not get_tree().paused, "Il warning non deve interrompere la run.")
	assert_false(input_router.is_input_suspended(), "Il warning non deve sospendere l'input.")
	assert_true(input_router.request_active_ability(), "Il warning non deve bloccare la richiesta di abilita attiva.")

	var position_before := player.global_position
	player.set_movement_input(Vector2.RIGHT)
	player._physics_process(0.1)
	player.clear_movement_input()
	assert_true(
		player.global_position.x > position_before.x,
		"Il Player deve continuare a muoversi mentre il warning e' visibile."
	)
	var ordinary_enemy := spawner.try_spawn_enemy()
	assert_not_null(ordinary_enemy, "La fixture PS-005 deve creare un bersaglio per il fuoco automatico.")
	if ordinary_enemy != null:
		assert_not_null(weapon.try_fire(), "Il warning non deve bloccare il fuoco automatico.")

	_assert_warning_layout(hud, movement_slice)
	var warning_event_count := _warning_events.size()
	var paused_time := controller.get_run_time()
	assert_true(controller.request_manual_pause(), "PS-005 deve poter congelare il warning in pausa.")
	controller._process(20.0)
	assert_almost_eq(controller.get_run_time(), paused_time, FLOAT_TOLERANCE, "La pausa deve congelare il clock PS-005.")
	assert_eq(hud.get_boss_warning_text(), "BOSS IN ARRIVO", "La pausa deve congelare anche il copy del warning.")
	assert_eq(_warning_events.size(), warning_event_count, "La pausa non deve duplicare il warning della stessa soglia.")
	assert_true(controller.resume_run(), "La fixture PS-005 deve riprendere dalla pausa.")
	assert_eq(_warning_events.size(), warning_event_count, "Il resume allo stesso istante non deve riemettere il warning.")

	_advance_to(controller, COUNTDOWN_START_SECONDS)
	assert_eq(hud.get_boss_warning_text(), "BOSS IN 5", "A 01:55 deve iniziare il countdown da 5.")
	var level_up_time := controller.get_run_time()
	assert_true(controller.request_level_up(), "PS-005 deve poter congelare il countdown durante LEVEL_UP.")
	controller._process(20.0)
	assert_almost_eq(controller.get_run_time(), level_up_time, FLOAT_TOLERANCE, "LEVEL_UP deve congelare il clock PS-005.")
	assert_eq(hud.get_boss_warning_text(), "BOSS IN 5", "LEVEL_UP deve conservare il secondo corretto.")
	assert_true(controller.complete_level_up(), "La fixture PS-005 deve chiudere LEVEL_UP.")

	for expected_second in [4, 3, 2, 1]:
		controller._process(1.0)
		assert_eq(
			hud.get_boss_warning_text(), "BOSS IN %d" % expected_second,
			"Il countdown PS-005 deve seguire il clock RUNNING senza saltare secondi."
		)

	assert_eq(
		_count_warning_phase(GameDirector.BossWarningPhase.APPROACHING), 1,
		"La stessa soglia Boss deve emettere un solo ingresso nel preavviso generale."
	)
	assert_eq(
		_count_warning_phase(GameDirector.BossWarningPhase.COUNTDOWN), 5,
		"La stessa soglia Boss deve emettere una sola volta ciascun valore 5-1."
	)
	controller._process(1.0)
	assert_almost_eq(controller.get_run_time(), FIRST_BOSS_SECONDS, FLOAT_TOLERANCE, "Lo spawn deve avvenire a 02:00.")
	assert_eq(controller.get_state(), RunController.RunState.BOSS_INTRO, "A 02:00 deve partire il normale BOSS_INTRO.")
	assert_not_null(encounter.get_active_boss(), "BOSS_INTRO deve creare il Boss PS-005.")
	assert_false(hud.is_boss_warning_visible(), "Il warning deve sparire contestualmente a BOSS_INTRO.")
	assert_false(director.is_boss_warning_active(), "Il Director non deve lasciare warning attivo durante il Boss.")
	assert_eq(_count_warning_phase(GameDirector.BossWarningPhase.HIDDEN), 1, "L'handoff deve nascondere il warning una sola volta.")

	controller._process(30.0)
	assert_eq(director.get_requested_count(), 1, "La soglia consumata non deve richiedere un secondo Boss.")
	assert_true(encounter.complete_intro(), "La fixture PS-005 deve poter entrare nello scontro.")
	assert_false(hud.is_boss_warning_visible(), "Il warning non deve riapparire durante lo scontro.")

	assert_true(controller.request_defeat(), "La fixture PS-005 deve poter preparare il restart.")
	assert_true(movement_slice.restart_run(5005), "Il restart PS-005 deve ripartire in-place.")
	await wait_process_frames(2)
	assert_false(hud.is_boss_warning_visible(), "Il restart deve eliminare il warning dall'HUD.")
	assert_false(director.is_boss_warning_active(), "Il restart deve eliminare lo stato warning dal Director.")
	assert_eq(director.get_triggered_count(), 0, "Il restart deve azzerare la soglia Boss consumata.")

	controller.prepare_restart()


func _advance_to(controller: RunController, target_time: float) -> void:
	controller._process(maxf(target_time - controller.get_run_time(), 0.0))


func _assert_warning_layout(hud: GameHud, movement_slice: Control) -> void:
	var arena_layout := movement_slice.get_node_or_null("ArenaLayout") as ArenaLayout
	assert_not_null(arena_layout, "PS-005 richiede la safe area autorevole.")
	if arena_layout == null:
		return
	var warning_rect := hud.get_boss_warning_rect()
	assert_rect_inside(
		warning_rect, arena_layout.get_safe_area_rect(),
		"Il warning PS-005 deve restare nella safe area."
	)
	for occupied_rect in [
		hud.get_experience_panel_rect(),
		hud.get_health_panel_rect(),
		hud.get_timer_slot_rect(),
		hud.get_pause_button_rect(),
		hud.get_ability_panel_rect(),
	]:
		assert_false(
			warning_rect.intersects(occupied_rect),
			"Il warning PS-005 non deve coprire XP, HP, timer, pausa o abilita."
		)
	var warning_slot := hud.get_node_or_null("TopBand/BossWarningSlot") as Control
	var warning_label := hud.get_node_or_null("TopBand/BossWarningSlot/BossWarningLabel") as Label
	assert_true(
		warning_slot != null
		and warning_label != null
		and warning_slot.mouse_filter == Control.MOUSE_FILTER_IGNORE
		and warning_label.mouse_filter == Control.MOUSE_FILTER_IGNORE,
		"Il warning PS-005 deve essere non interattivo e lasciare passare l'input."
	)


func _count_warning_phase(phase: GameDirector.BossWarningPhase) -> int:
	var count := 0
	for event in _warning_events:
		if event.get("phase") == phase:
			count += 1
	return count


func _on_boss_warning_changed(
	schedule_index: int,
	phase: GameDirector.BossWarningPhase,
	seconds_remaining: int
) -> void:
	_warning_events.append({
		"schedule_index": schedule_index,
		"phase": phase,
		"seconds_remaining": seconds_remaining,
	})
