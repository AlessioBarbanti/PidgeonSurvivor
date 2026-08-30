extends GutGameplayTest


func test_recurring_boss_schedule() -> void:
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_run_controller() as RunController
	var director := movement_slice.get_game_director() as GameDirector
	var encounter := movement_slice.get_boss_encounter() as BossEncounter
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	var experience := movement_slice.get_experience_system() as ExperienceSystem
	var service := movement_slice.get_upgrade_service() as UpgradeService
	assert_true(
		controller != null and director != null and encounter != null and spawner != null
		and experience != null and service != null,
		"B33 richiede RunController, GameDirector, BossEncounter, EnemySpawner e UpgradeService dalla scena."
	)
	if (
		controller == null
		or director == null
		or encounter == null
		or spawner == null
		or experience == null
		or service == null
	):
		return

	controller.set_process(false)
	spawner.set_process(false)

	# 1. PS-005 rende il primo Boss eleggibile a 02:00.
	controller._process(120.01)
	assert_true(
		controller.get_state() == RunController.RunState.BOSS_INTRO and get_tree().paused,
		"La soglia fissa deve aprire BOSS_INTRO per il primo Boss."
	)
	var boss_1 := encounter.get_active_boss()
	assert_not_null(boss_1, "BOSS_INTRO deve creare il primo Boss.")
	if boss_1 == null:
		controller.prepare_restart()
		return
	assert_eq(director.get_active_event_index(), 0, "Il primo Boss deve usare lo schedule_index 0.")
	_assert_single_active_boss(encounter, director, "Il primo Boss deve essere l'unico tracciato.")
	assert_true(encounter.complete_intro(), "L'intro del primo Boss deve poter essere confermata.")
	_resolve_pending_barb_reward(controller, service)

	# 2. Morte prima che la finestra ricorrente scada: nessuno spawn prematuro.
	_kill_active_boss(encounter, controller, experience, service)
	assert_true(
		controller.is_running() and not get_tree().paused, "La morte del primo Boss non deve chiudere la run."
	)
	assert_null(encounter.get_active_boss(), "Il primo Boss morto non deve restare attivo.")
	assert_false(director.has_blocking_boss_event(), "La morte deve rilasciare il lock del Director.")
	assert_eq(
		director.get_recurring_boss_count(), 0,
		"Nessun Boss ricorrente deve nascere prima che la finestra scada."
	)
	assert_false(
		director.is_boss_pending_after_active(),
		"Nessuna richiesta pendente deve restare dopo una morte anticipata."
	)

	# 3. La finestra del secondo Boss è relativa allo spawn effettivo del primo.
	var window := director.get_recurring_window_seconds()
	var first_spawn_time := director.get_last_boss_spawn_run_time()
	controller._process((first_spawn_time + window + 0.01) - controller.get_run_time())
	assert_eq(director.get_active_event_index(), 1, "Il secondo Boss deve usare lo schedule_index 1.")
	assert_eq(director.get_recurring_boss_count(), 1, "Deve nascere esattamente un Boss ricorrente.")
	var boss_2 := encounter.get_active_boss()
	assert_not_null(boss_2, "La finestra scaduta deve creare il secondo Boss.")
	_assert_single_active_boss(encounter, director, "Il secondo Boss deve essere l'unico tracciato.")
	if boss_2 == null:
		controller.prepare_restart()
		return
	assert_true(encounter.complete_intro(), "L'intro del secondo Boss deve poter essere confermata.")
	_resolve_pending_barb_reward(controller, service)

	# 4. Se il Boss resta vivo oltre la finestra, si imposta un'unica richiesta pendente.
	var second_spawn_time := director.get_last_boss_spawn_run_time()
	controller._process(300.0)
	assert_true(
		director.is_boss_pending_after_active(),
		"Una finestra scaduta con il Boss vivo deve impostare pending_boss."
	)
	assert_eq(encounter.get_active_boss(), boss_2, "Il secondo Boss deve restare l'unica istanza viva.")
	assert_eq(
		director.get_recurring_boss_count(), 1, "Nessun nuovo Boss deve nascere mentre quello attivo e' vivo."
	)

	# 5. Restare vivo oltre due finestre non deve accumulare richieste arretrate.
	controller._process(300.0)
	assert_true(
		director.is_boss_pending_after_active(),
		"pending_boss deve restare una singola richiesta anche oltre due finestre."
	)
	assert_eq(
		encounter.get_active_boss(), boss_2, "Nessuna seconda istanza deve comparire mentre il Boss e' vivo."
	)
	assert_eq(
		director.get_recurring_boss_count(), 1, "Il conteggio ricorrente non deve crescere senza una morte."
	)

	# 6. Alla morte, con pending_boss attivo, il prossimo Boss nasce subito e la
	# finestra seguente riparte dal suo spawn reale, non dalle finestre perse.
	var death_time_2 := controller.get_run_time()
	_kill_active_boss(encounter, controller, experience, service)
	assert_eq(
		director.get_recurring_boss_count(), 2, "La morte con pending_boss deve generare subito il terzo Boss."
	)
	assert_false(
		director.is_boss_pending_after_active(), "La richiesta pendente deve essere consumata dallo spawn."
	)
	assert_eq(director.get_active_event_index(), 2, "Il terzo Boss deve usare lo schedule_index 2.")
	var boss_3 := encounter.get_active_boss()
	assert_true(boss_3 != null and boss_3 != boss_2, "Il terzo Boss deve essere una nuova istanza.")
	_assert_single_active_boss(encounter, director, "Il terzo Boss deve essere l'unico tracciato.")
	assert_almost_eq(
		director.get_last_boss_spawn_run_time(), death_time_2, FLOAT_TOLERANCE,
		"La nuova finestra deve ripartire dallo spawn reale, non dalle finestre perse."
	)
	if boss_3 == null:
		controller.prepare_restart()
		return
	assert_true(encounter.complete_intro(), "L'intro del terzo Boss deve poter essere confermata.")
	_resolve_pending_barb_reward(controller, service)

	# 7. La pausa manuale ferma il clock della finestra ricorrente.
	var third_spawn_time := director.get_last_boss_spawn_run_time()
	controller._process((third_spawn_time + window - 5.0) - controller.get_run_time())
	var pre_pause_run_time := controller.get_run_time()
	assert_true(controller.request_manual_pause(), "Il test deve poter pausare prima della finestra.")
	controller._process(50.0)
	assert_almost_eq(
		controller.get_run_time(), pre_pause_run_time, FLOAT_TOLERANCE, "La pausa non deve avanzare il clock."
	)
	assert_false(director.is_boss_pending_after_active(), "La pausa non deve far scattare la finestra.")
	assert_true(controller.resume_run(), "Il test deve poter riprendere dopo la pausa.")

	# 8. Il level-up ferma allo stesso modo il clock della finestra ricorrente.
	assert_true(
		controller.request_level_up(), "Il test deve poter aprire il level-up prima della finestra."
	)
	controller._process(50.0)
	assert_almost_eq(
		controller.get_run_time(), pre_pause_run_time, FLOAT_TOLERANCE, "Il level-up non deve avanzare il clock."
	)
	assert_false(director.is_boss_pending_after_active(), "Il level-up non deve far scattare la finestra.")
	assert_true(controller.complete_level_up(), "Il test deve poter chiudere il level-up.")

	# 9. Superata la soglia dopo la ripresa, la richiesta pendente scatta normalmente.
	controller._process((third_spawn_time + window + 0.01) - controller.get_run_time())
	assert_true(
		director.is_boss_pending_after_active(),
		"La finestra deve scattare non appena il clock la raggiunge in RUNNING."
	)
	_kill_active_boss(encounter, controller, experience, service)
	assert_eq(director.get_active_event_index(), 3, "Il quarto Boss deve usare lo schedule_index 3.")
	assert_eq(director.get_recurring_boss_count(), 3, "Il quarto Boss deve essere il terzo ricorrente.")
	var boss_4 := encounter.get_active_boss()
	assert_true(boss_4 != null and boss_4 != boss_3, "Il quarto Boss deve essere una nuova istanza.")
	_assert_single_active_boss(encounter, director, "Il quarto Boss deve essere l'unico tracciato.")
	if boss_4 != null:
		assert_true(encounter.complete_intro(), "L'intro del quarto Boss deve poter essere confermata.")
		_resolve_pending_barb_reward(controller, service)

	# 10. Il restart azzera lo scheduler ricorrente.
	assert_true(
		controller.request_defeat(), "Il test deve poter chiudere la run in DEFEAT per il restart."
	)
	assert_true(movement_slice.restart_run(19001), "La run deve poter ripartire in-place dopo DEFEAT.")
	await wait_process_frames(2)
	assert_eq(director.get_recurring_boss_count(), 0, "Il restart deve azzerare il conteggio ricorrente.")
	assert_almost_eq(
		director.get_last_boss_spawn_run_time(), 0.0, FLOAT_TOLERANCE, "Il restart deve azzerare l'ultimo spawn."
	)
	assert_false(director.is_boss_pending_after_active(), "Il restart deve azzerare pending_boss.")
	assert_eq(director.get_triggered_count(), 0, "Il restart deve azzerare le soglie fisse consumate.")
	assert_false(director.has_blocking_boss_event(), "Il restart non deve lasciare un evento Boss attivo.")

	# 11. La nuova run riattiva il primo Boss esattamente a 02:00.
	controller._process(120.01)
	assert_eq(director.get_active_event_index(), 0, "La nuova run deve ripartire dallo schedule_index 0.")
	assert_not_null(encounter.get_active_boss(), "La nuova run deve creare di nuovo il primo Boss.")

	controller.prepare_restart()


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
	assert_not_null(health, "Il Boss attivo deve avere un HealthComponent.")
	if health == null:
		return
	boss.take_damage(health.health_current)
	# La ricompensa XP puo' legittimamente aprire LEVEL_UP: qui interessa solo
	# lo scheduler dei Boss, quindi si risolve subito per tornare in RUNNING.
	while controller.get_state() == RunController.RunState.LEVEL_UP:
		if not experience.complete_level_up():
			break
	_resolve_pending_barb_reward(controller, service)


# PS-012: quando pending_boss e' attivo, la morte riattiva subito il Boss
# successivo (vedi GameDirector._request_next_boss_event) prima che Barb
# riesca a reclamare RUNNING; in quel caso la ricompensa resta accodata e
# si presenta solo alla chiusura dell'intro del nuovo Boss. Qui interessa
# solo tornare in RUNNING, non quale Specialità/bonus venga scelto.
func _resolve_pending_barb_reward(controller: RunController, service: UpgradeService) -> void:
	while controller.get_state() == RunController.RunState.BARB_REWARD:
		var offer := service.get_current_barb_offer()
		if offer.is_empty():
			break
		var chosen_id := offer[0].id
		var resolved := (
			service.select_barb_bonus_upgrade(chosen_id)
			if service.is_barb_bonus_mode()
			else service.select_barb_speciality(chosen_id)
		)
		if not resolved:
			break


func _assert_single_active_boss(encounter: BossEncounter, director: GameDirector, text: String) -> void:
	assert_eq(encounter.get_active_boss(), director.get_active_boss(), text)
