extends SceneTree

const MOVEMENT_SLICE_SCENE := preload("res://scenes/game/movement_slice.tscn")
const INITIAL_VIEWPORT_SIZE := Vector2i(1280, 720)
const FLOAT_TOLERANCE := 0.001

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	paused = false
	root.content_scale_size = INITIAL_VIEWPORT_SIZE
	root.size = INITIAL_VIEWPORT_SIZE
	await _wait_processed_frame()

	await _validate_recurring_schedule()
	await _finish()


func _validate_recurring_schedule() -> void:
	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	root.add_child(movement_slice)
	await _wait_processed_frame()

	var controller := movement_slice.get_run_controller() as RunController
	var director := movement_slice.get_game_director() as GameDirector
	var encounter := movement_slice.get_boss_encounter() as BossEncounter
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	var experience := movement_slice.get_experience_system() as ExperienceSystem
	if (
		controller == null
		or director == null
		or encounter == null
		or spawner == null
		or experience == null
	):
		_failures.append("B33 richiede RunController, GameDirector, BossEncounter ed EnemySpawner dalla scena.")
		movement_slice.queue_free()
		await process_frame
		return

	controller.set_process(false)
	spawner.set_process(false)

	# 1. Il primo Boss resta eleggibile a 04:00 tramite la soglia fissa esistente.
	controller._process(240.01)
	_expect(
		controller.get_state() == RunController.RunState.BOSS_INTRO and paused,
		"La soglia fissa deve aprire BOSS_INTRO per il primo Boss."
	)
	var boss_1 := encounter.get_active_boss()
	_expect(boss_1 != null, "BOSS_INTRO deve creare il primo Boss.")
	if boss_1 == null:
		controller.prepare_restart()
		paused = false
		movement_slice.queue_free()
		await process_frame
		return
	_expect(director.get_active_event_index() == 0, "Il primo Boss deve usare lo schedule_index 0.")
	_expect_single_active_boss(encounter, director, "Il primo Boss deve essere l'unico tracciato.")
	_expect(encounter.complete_intro(), "L'intro del primo Boss deve poter essere confermata.")

	# 2. Morte prima che la finestra ricorrente scada: nessuno spawn prematuro.
	_kill_active_boss(encounter, controller, experience)
	_expect(
		controller.is_running() and not paused,
		"La morte del primo Boss non deve chiudere la run."
	)
	_expect(encounter.get_active_boss() == null, "Il primo Boss morto non deve restare attivo.")
	_expect(not director.has_blocking_boss_event(), "La morte deve rilasciare il lock del Director.")
	_expect(
		director.get_recurring_boss_count() == 0,
		"Nessun Boss ricorrente deve nascere prima che la finestra scada."
	)
	_expect(
		not director.is_boss_pending_after_active(),
		"Nessuna richiesta pendente deve restare dopo una morte anticipata."
	)

	# 3. La finestra del secondo Boss è relativa allo spawn effettivo del primo.
	var window := director.get_recurring_window_seconds()
	var first_spawn_time := director.get_last_boss_spawn_run_time()
	controller._process((first_spawn_time + window + 0.01) - controller.get_run_time())
	_expect(director.get_active_event_index() == 1, "Il secondo Boss deve usare lo schedule_index 1.")
	_expect(director.get_recurring_boss_count() == 1, "Deve nascere esattamente un Boss ricorrente.")
	var boss_2 := encounter.get_active_boss()
	_expect(boss_2 != null, "La finestra scaduta deve creare il secondo Boss.")
	_expect_single_active_boss(encounter, director, "Il secondo Boss deve essere l'unico tracciato.")
	if boss_2 == null:
		controller.prepare_restart()
		paused = false
		movement_slice.queue_free()
		await process_frame
		return
	_expect(encounter.complete_intro(), "L'intro del secondo Boss deve poter essere confermata.")

	# 4. Se il Boss resta vivo oltre la finestra, si imposta un'unica richiesta pendente.
	var second_spawn_time := director.get_last_boss_spawn_run_time()
	controller._process(300.0)
	_expect(
		director.is_boss_pending_after_active(),
		"Una finestra scaduta con il Boss vivo deve impostare pending_boss."
	)
	_expect(encounter.get_active_boss() == boss_2, "Il secondo Boss deve restare l'unica istanza viva.")
	_expect(director.get_recurring_boss_count() == 1, "Nessun nuovo Boss deve nascere mentre quello attivo e' vivo.")

	# 5. Restare vivo oltre due finestre non deve accumulare richieste arretrate.
	controller._process(300.0)
	_expect(
		director.is_boss_pending_after_active(),
		"pending_boss deve restare una singola richiesta anche oltre due finestre."
	)
	_expect(encounter.get_active_boss() == boss_2, "Nessuna seconda istanza deve comparire mentre il Boss e' vivo.")
	_expect(director.get_recurring_boss_count() == 1, "Il conteggio ricorrente non deve crescere senza una morte.")

	# 6. Alla morte, con pending_boss attivo, il prossimo Boss nasce subito e la
	# finestra seguente riparte dal suo spawn reale, non dalle finestre perse.
	var death_time_2 := controller.get_run_time()
	_kill_active_boss(encounter, controller, experience)
	_expect(
		director.get_recurring_boss_count() == 2,
		"La morte con pending_boss deve generare subito il terzo Boss."
	)
	_expect(not director.is_boss_pending_after_active(), "La richiesta pendente deve essere consumata dallo spawn.")
	_expect(director.get_active_event_index() == 2, "Il terzo Boss deve usare lo schedule_index 2.")
	var boss_3 := encounter.get_active_boss()
	_expect(boss_3 != null and boss_3 != boss_2, "Il terzo Boss deve essere una nuova istanza.")
	_expect_single_active_boss(encounter, director, "Il terzo Boss deve essere l'unico tracciato.")
	_expect_float_near(
		director.get_last_boss_spawn_run_time(),
		death_time_2,
		"La nuova finestra deve ripartire dallo spawn reale, non dalle finestre perse."
	)
	if boss_3 == null:
		controller.prepare_restart()
		paused = false
		movement_slice.queue_free()
		await process_frame
		return
	_expect(encounter.complete_intro(), "L'intro del terzo Boss deve poter essere confermata.")

	# 7. La pausa manuale ferma il clock della finestra ricorrente.
	var third_spawn_time := director.get_last_boss_spawn_run_time()
	controller._process((third_spawn_time + window - 5.0) - controller.get_run_time())
	var pre_pause_run_time := controller.get_run_time()
	_expect(controller.request_manual_pause(), "Il test deve poter pausare prima della finestra.")
	controller._process(50.0)
	_expect_float_near(controller.get_run_time(), pre_pause_run_time, "La pausa non deve avanzare il clock.")
	_expect(not director.is_boss_pending_after_active(), "La pausa non deve far scattare la finestra.")
	_expect(controller.resume_run(), "Il test deve poter riprendere dopo la pausa.")

	# 8. Il level-up ferma allo stesso modo il clock della finestra ricorrente.
	_expect(controller.request_level_up(), "Il test deve poter aprire il level-up prima della finestra.")
	controller._process(50.0)
	_expect_float_near(controller.get_run_time(), pre_pause_run_time, "Il level-up non deve avanzare il clock.")
	_expect(not director.is_boss_pending_after_active(), "Il level-up non deve far scattare la finestra.")
	_expect(controller.complete_level_up(), "Il test deve poter chiudere il level-up.")

	# 9. Superata la soglia dopo la ripresa, la richiesta pendente scatta normalmente.
	controller._process((third_spawn_time + window + 0.01) - controller.get_run_time())
	_expect(
		director.is_boss_pending_after_active(),
		"La finestra deve scattare non appena il clock la raggiunge in RUNNING."
	)
	_kill_active_boss(encounter, controller, experience)
	_expect(director.get_active_event_index() == 3, "Il quarto Boss deve usare lo schedule_index 3.")
	_expect(director.get_recurring_boss_count() == 3, "Il quarto Boss deve essere il terzo ricorrente.")
	var boss_4 := encounter.get_active_boss()
	_expect(boss_4 != null and boss_4 != boss_3, "Il quarto Boss deve essere una nuova istanza.")
	_expect_single_active_boss(encounter, director, "Il quarto Boss deve essere l'unico tracciato.")
	if boss_4 != null:
		_expect(encounter.complete_intro(), "L'intro del quarto Boss deve poter essere confermata.")

	# 10. Il restart azzera lo scheduler ricorrente.
	_expect(controller.request_defeat(), "Il test deve poter chiudere la run in DEFEAT per il restart.")
	_expect(movement_slice.restart_run(19001), "La run deve poter ripartire in-place dopo DEFEAT.")
	await _wait_processed_frame()
	_expect(director.get_recurring_boss_count() == 0, "Il restart deve azzerare il conteggio ricorrente.")
	_expect_float_near(director.get_last_boss_spawn_run_time(), 0.0, "Il restart deve azzerare l'ultimo spawn.")
	_expect(not director.is_boss_pending_after_active(), "Il restart deve azzerare pending_boss.")
	_expect(director.get_triggered_count() == 0, "Il restart deve azzerare le soglie fisse consumate.")
	_expect(not director.has_blocking_boss_event(), "Il restart non deve lasciare un evento Boss attivo.")

	# 11. La nuova run riattiva il primo Boss esattamente a 04:00.
	controller._process(240.01)
	_expect(director.get_active_event_index() == 0, "La nuova run deve ripartire dallo schedule_index 0.")
	_expect(encounter.get_active_boss() != null, "La nuova run deve creare di nuovo il primo Boss.")

	controller.prepare_restart()
	paused = false
	movement_slice.queue_free()
	await process_frame


func _kill_active_boss(
	encounter: BossEncounter,
	controller: RunController,
	experience: ExperienceSystem
) -> void:
	var boss := encounter.get_active_boss()
	if boss == null:
		_failures.append("Impossibile uccidere un Boss assente.")
		return
	var health := boss.get_health_component()
	if health == null:
		_failures.append("Il Boss attivo deve avere un HealthComponent.")
		return
	boss.take_damage(health.health_current)
	# La ricompensa XP puo' legittimamente aprire LEVEL_UP: qui interessa solo
	# lo scheduler dei Boss, quindi si risolve subito per tornare in RUNNING.
	while controller.get_state() == RunController.RunState.LEVEL_UP:
		if not experience.complete_level_up():
			break


func _expect_single_active_boss(encounter: BossEncounter, director: GameDirector, message: String) -> void:
	_expect(encounter.get_active_boss() == director.get_active_boss(), message)


func _expect_float_near(actual: float, expected: float, message: String) -> void:
	_expect(
		absf(actual - expected) <= FLOAT_TOLERANCE,
		"%s Atteso %.5f, ottenuto %.5f." % [message, expected, actual]
	)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _wait_processed_frame() -> void:
	await process_frame
	await process_frame


func _finish() -> void:
	paused = false
	await process_frame
	if _failures.is_empty():
		print("B33_RECURRING_BOSS_SMOKE_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	printerr("B33_RECURRING_BOSS_SMOKE_FAIL count=%d" % _failures.size())
	quit(1)
