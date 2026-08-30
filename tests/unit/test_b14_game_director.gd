extends GutGameplayTest

var _queued_indices: Array[int] = []
var _requested_indices: Array[int] = []
var _completed_indices: Array[int] = []


func test_director_profile_validation() -> void:
	var profile := GameDirectorProfile.new()
	profile.enemy_spawn_profile = EnemySpawnProfile.new()
	profile.boss_thresholds_seconds = PackedFloat32Array([30.0, 10.0, 30.0, -4.0, INF])
	var thresholds := profile.get_effective_boss_thresholds()
	assert_true(profile.is_valid(), "Un profilo con spawn e soglie valide deve essere accettato.")
	assert_eq(thresholds.size(), 2, "Soglie duplicate o non valide devono essere escluse.")
	if thresholds.size() == 2:
		assert_almost_eq(thresholds[0], 10.0, FLOAT_TOLERANCE, "Le soglie devono essere ordinate.")
		assert_almost_eq(thresholds[1], 30.0, FLOAT_TOLERANCE, "La seconda soglia deve restare disponibile.")

	profile.boss_thresholds_seconds = PackedFloat32Array([0.0, -1.0, INF])
	assert_false(profile.is_valid(), "Un profilo senza soglie positive finite deve essere rifiutato.")
	profile.boss_thresholds_seconds = PackedFloat32Array([10.0])
	profile.enemy_spawn_profile = null
	assert_false(profile.is_valid(), "Il profilo Director deve dichiarare lo spawn profile.")


func test_scheduler_lifecycle() -> void:
	_queued_indices.clear()
	_requested_indices.clear()
	_completed_indices.clear()

	var fixture := Node.new()
	fixture.name = "GameDirectorFixture"
	add_child_autofree(fixture)
	var controller := RunController.new()
	controller.name = "RunController"
	controller.set_process(false)
	var spawner := EnemySpawner.new()
	spawner.name = "EnemySpawner"
	spawner.set_process(false)
	var director := GameDirector.new()
	director.name = "GameDirector"
	var profile := GameDirectorProfile.new()
	profile.enemy_spawn_profile = EnemySpawnProfile.new()
	profile.boss_thresholds_seconds = PackedFloat32Array([10.0, 30.0])
	director.profile = profile

	fixture.add_child(controller)
	fixture.add_child(spawner)
	fixture.add_child(director)
	await wait_process_frames(1)

	director.boss_event_queued.connect(_on_boss_event_queued)
	director.boss_event_requested.connect(_on_boss_event_requested)
	director.boss_event_completed.connect(_on_boss_event_completed)
	assert_true(
		director.configure(controller, spawner), "GameDirector deve configurare lo spawn profile sullo spawner."
	)
	assert_eq(
		spawner.spawn_profile, profile.enemy_spawn_profile,
		"EnemySpawner deve usare il profilo assegnato dal Director."
	)

	controller._process(100.0)
	assert_true(_requested_indices.is_empty(), "BOOT non deve consumare soglie Boss.")
	assert_true(controller.start_run(14001), "La fixture Director deve avviare la run.")
	controller._process(9.75)
	assert_true(_requested_indices.is_empty(), "Il Boss non deve essere richiesto prima della soglia.")

	assert_true(controller.request_manual_pause(), "La fixture deve entrare in pausa manuale.")
	controller._process(100.0)
	assert_almost_eq(
		controller.get_run_time(), 9.75, FLOAT_TOLERANCE, "La pausa non deve avanzare il clock Boss."
	)
	assert_true(_requested_indices.is_empty(), "La pausa non deve attivare lo scheduler Boss.")
	assert_true(controller.resume_run(), "La fixture deve riprendere dopo la pausa.")
	controller._process(0.25)
	assert_eq(_queued_indices, [0], "La prima soglia deve essere accodata una sola volta.")
	assert_eq(_requested_indices, [0], "La prima soglia deve richiedere un solo evento Boss.")
	assert_true(director.is_boss_request_in_flight(), "La richiesta deve restare in volo fino al Boss.")

	# Un salto di clock attraversa la seconda soglia, ma il primo evento ancora
	# attivo la conserva in coda senza creare un secondo Boss.
	controller._process(25.0)
	assert_eq(_queued_indices, [0, 1], "Un salto di soglia deve accodare tutti gli eventi attraversati.")
	assert_eq(_requested_indices, [0], "Il Boss precedente deve bloccare la richiesta successiva.")
	assert_eq(director.get_pending_count(), 1, "La seconda soglia deve restare pendente.")

	var first_boss := Node2D.new()
	first_boss.name = "FirstBoss"
	fixture.add_child(first_boss)
	assert_false(
		director.register_active_boss(first_boss, 1), "Un Boss non deve registrarsi per la soglia sbagliata."
	)
	assert_true(
		director.register_active_boss(first_boss, 0), "Il Boss richiesto deve diventare l'unico Boss attivo."
	)
	assert_eq(director.get_active_boss(), first_boss, "Il Director deve tracciare il Boss vivo.")

	# Anche la conclusione del Boss durante una pausa conserva l'evento seguente
	# fino al ritorno esplicito in RUNNING.
	assert_true(controller.request_manual_pause(), "La fixture deve poter pausare con un Boss attivo.")
	assert_true(director.complete_active_boss_event(), "Il primo evento Boss deve potersi concludere.")
	assert_eq(_completed_indices, [0], "Il completamento deve essere emesso una sola volta.")
	assert_eq(_requested_indices, [0], "In pausa non deve partire il Boss successivo.")
	first_boss.queue_free()
	assert_true(controller.resume_run(), "Il resume deve riattivare lo scheduler pendente.")
	assert_eq(_requested_indices, [0, 1], "Il secondo evento deve partire al ritorno in RUNNING.")

	var second_boss := Node2D.new()
	second_boss.name = "SecondBoss"
	fixture.add_child(second_boss)
	assert_true(director.register_active_boss(second_boss, 1), "Il secondo Boss deve registrarsi.")
	second_boss.queue_free()
	await wait_process_frames(1)
	assert_eq(_completed_indices, [0, 1], "L'uscita del Boss deve completare automaticamente l'evento.")
	assert_false(director.has_blocking_boss_event(), "Dopo la morte non deve restare un lock Boss.")
	controller._process(100.0)
	assert_eq(_requested_indices, [0, 1], "Le soglie consumate non devono riattivarsi nella stessa run.")

	# Il restart azzera soglie, coda e Boss della run precedente. La stessa soglia
	# deve poter scattare esattamente una volta nella nuova run.
	assert_true(controller.request_defeat(), "La prima run della fixture deve terminare.")
	assert_true(controller.restart_run(14002), "RunController deve avviare una seconda run pulita.")
	assert_eq(director.get_triggered_count(), 0, "Il restart deve azzerare le soglie consumate.")
	assert_eq(director.get_pending_count(), 0, "Il restart deve svuotare la coda Boss.")
	assert_eq(director.get_requested_count(), 0, "Il conteggio richieste deve essere per-run.")
	controller._process(10.0)
	assert_eq(_requested_indices, [0, 1, 0], "La prima soglia deve riattivarsi una volta nella nuova run.")

	var restart_boss := Node2D.new()
	restart_boss.name = "RestartBoss"
	fixture.add_child(restart_boss)
	assert_true(director.register_active_boss(restart_boss, 0), "La seconda run deve registrare il Boss.")
	assert_true(controller.request_defeat(), "La seconda run deve poter terminare con il Boss vivo.")
	controller.prepare_restart()
	await wait_process_frames(1)
	assert_false(is_instance_valid(restart_boss), "Il restart deve eliminare il Boss tracciato.")
	assert_false(director.has_blocking_boss_event(), "Il restart non deve lasciare un evento Boss attivo.")


func test_composed_scene_schedule() -> void:
	_requested_indices.clear()
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_run_controller() as RunController
	var director := movement_slice.get_game_director() as GameDirector
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	assert_not_null(controller, "La scena composta deve esporre RunController.")
	assert_not_null(director, "La scena composta deve esporre GameDirector.")
	assert_not_null(spawner, "La scena composta deve conservare EnemySpawner.")
	if controller == null or director == null or spawner == null:
		return

	controller.set_process(false)
	spawner.set_process(false)
	director.boss_event_requested.connect(_on_boss_event_requested)
	assert_true(director.has_valid_configuration(), "Il GameDirector composto deve essere configurato.")
	assert_eq(
		director.profile.enemy_spawn_profile, spawner.spawn_profile,
		"Il profilo Director deve essere l'autorita sui parametri di spawn."
	)
	var thresholds := director.get_thresholds()
	assert_eq(thresholds.size(), 1, "L'MVP deve avere una sola soglia Boss.")
	if thresholds.size() == 1:
		assert_almost_eq(
			thresholds[0], 120.0, FLOAT_TOLERANCE, "PS-005 deve usare 120 secondi di clock logico."
		)

	var delta_to_threshold := 120.0 - controller.get_run_time()
	controller._process(maxf(delta_to_threshold, 0.0) + 0.01)
	assert_eq(_requested_indices, [0], "La scena composta deve richiedere il Boss una volta a 02:00.")
	controller._process(30.0)
	assert_eq(_requested_indices, [0], "La scena composta non deve duplicare la soglia consumata.")

	assert_true(controller.request_defeat(), "La scena composta deve poter terminare per il restart.")
	assert_true(movement_slice.restart_run(14003), "La scena composta deve ripartire in-place.")
	assert_eq(director.get_triggered_count(), 0, "Il restart composto deve azzerare lo scheduler.")
	assert_false(director.has_blocking_boss_event(), "Il restart composto deve rimuovere la richiesta in volo.")
	controller._process(120.01)
	assert_eq(_requested_indices, [0, 0], "La nuova run composta deve emettere una sola nuova richiesta.")

	controller.prepare_restart()


func _on_boss_event_queued(schedule_index: int, _threshold_seconds: float) -> void:
	_queued_indices.append(schedule_index)


func _on_boss_event_requested(schedule_index: int, _threshold_seconds: float) -> void:
	_requested_indices.append(schedule_index)


func _on_boss_event_completed(schedule_index: int) -> void:
	_completed_indices.append(schedule_index)
