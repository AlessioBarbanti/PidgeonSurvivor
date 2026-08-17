extends SceneTree

const MOVEMENT_SLICE_SCENE := preload("res://scenes/game/movement_slice.tscn")
const INITIAL_VIEWPORT_SIZE := Vector2i(1280, 720)
const FLOAT_TOLERANCE := 0.001

var _failures: Array[String] = []
var _queued_indices: Array[int] = []
var _requested_indices: Array[int] = []
var _completed_indices: Array[int] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	paused = false
	root.content_scale_size = INITIAL_VIEWPORT_SIZE
	root.size = INITIAL_VIEWPORT_SIZE
	await _wait_processed_frame()

	_validate_director_profile()
	await _validate_scheduler_lifecycle()
	await _validate_composed_scene()
	await _finish()


func _validate_director_profile() -> void:
	var profile := GameDirectorProfile.new()
	profile.enemy_spawn_profile = EnemySpawnProfile.new()
	profile.boss_thresholds_seconds = PackedFloat32Array([
		30.0,
		10.0,
		30.0,
		-4.0,
		INF,
	])
	var thresholds := profile.get_effective_boss_thresholds()
	_expect(profile.is_valid(), "Un profilo con spawn e soglie valide deve essere accettato.")
	_expect(thresholds.size() == 2, "Soglie duplicate o non valide devono essere escluse.")
	if thresholds.size() == 2:
		_expect_float_near(thresholds[0], 10.0, "Le soglie devono essere ordinate.")
		_expect_float_near(thresholds[1], 30.0, "La seconda soglia deve restare disponibile.")

	profile.boss_thresholds_seconds = PackedFloat32Array([0.0, -1.0, INF])
	_expect(not profile.is_valid(), "Un profilo senza soglie positive finite deve essere rifiutato.")
	profile.boss_thresholds_seconds = PackedFloat32Array([10.0])
	profile.enemy_spawn_profile = null
	_expect(not profile.is_valid(), "Il profilo Director deve dichiarare lo spawn profile.")


func _validate_scheduler_lifecycle() -> void:
	_queued_indices.clear()
	_requested_indices.clear()
	_completed_indices.clear()

	var fixture := Node.new()
	fixture.name = "GameDirectorFixture"
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
	root.add_child(fixture)
	await process_frame

	director.boss_event_queued.connect(_on_boss_event_queued)
	director.boss_event_requested.connect(_on_boss_event_requested)
	director.boss_event_completed.connect(_on_boss_event_completed)
	_expect(
		director.configure(controller, spawner),
		"GameDirector deve configurare lo spawn profile sullo spawner."
	)
	_expect(
		spawner.spawn_profile == profile.enemy_spawn_profile,
		"EnemySpawner deve usare il profilo assegnato dal Director."
	)

	controller._process(100.0)
	_expect(_requested_indices.is_empty(), "BOOT non deve consumare soglie Boss.")
	_expect(controller.start_run(14001), "La fixture Director deve avviare la run.")
	controller._process(9.75)
	_expect(_requested_indices.is_empty(), "Il Boss non deve essere richiesto prima della soglia.")

	_expect(controller.request_manual_pause(), "La fixture deve entrare in pausa manuale.")
	controller._process(100.0)
	_expect_float_near(controller.get_run_time(), 9.75, "La pausa non deve avanzare il clock Boss.")
	_expect(_requested_indices.is_empty(), "La pausa non deve attivare lo scheduler Boss.")
	_expect(controller.resume_run(), "La fixture deve riprendere dopo la pausa.")
	controller._process(0.25)
	_expect(_queued_indices == [0], "La prima soglia deve essere accodata una sola volta.")
	_expect(_requested_indices == [0], "La prima soglia deve richiedere un solo evento Boss.")
	_expect(director.is_boss_request_in_flight(), "La richiesta deve restare in volo fino al Boss.")

	# Un salto di clock attraversa la seconda soglia, ma il primo evento ancora
	# attivo la conserva in coda senza creare un secondo Boss.
	controller._process(25.0)
	_expect(_queued_indices == [0, 1], "Un salto di soglia deve accodare tutti gli eventi attraversati.")
	_expect(_requested_indices == [0], "Il Boss precedente deve bloccare la richiesta successiva.")
	_expect(director.get_pending_count() == 1, "La seconda soglia deve restare pendente.")

	var first_boss := Node2D.new()
	first_boss.name = "FirstBoss"
	fixture.add_child(first_boss)
	_expect(
		not director.register_active_boss(first_boss, 1),
		"Un Boss non deve registrarsi per la soglia sbagliata."
	)
	_expect(
		director.register_active_boss(first_boss, 0),
		"Il Boss richiesto deve diventare l'unico Boss attivo."
	)
	_expect(director.get_active_boss() == first_boss, "Il Director deve tracciare il Boss vivo.")

	# Anche la conclusione del Boss durante una pausa conserva l'evento seguente
	# fino al ritorno esplicito in RUNNING.
	_expect(controller.request_manual_pause(), "La fixture deve poter pausare con un Boss attivo.")
	_expect(director.complete_active_boss_event(), "Il primo evento Boss deve potersi concludere.")
	_expect(_completed_indices == [0], "Il completamento deve essere emesso una sola volta.")
	_expect(_requested_indices == [0], "In pausa non deve partire il Boss successivo.")
	first_boss.queue_free()
	_expect(controller.resume_run(), "Il resume deve riattivare lo scheduler pendente.")
	_expect(_requested_indices == [0, 1], "Il secondo evento deve partire al ritorno in RUNNING.")

	var second_boss := Node2D.new()
	second_boss.name = "SecondBoss"
	fixture.add_child(second_boss)
	_expect(director.register_active_boss(second_boss, 1), "Il secondo Boss deve registrarsi.")
	second_boss.queue_free()
	await process_frame
	_expect(_completed_indices == [0, 1], "L'uscita del Boss deve completare automaticamente l'evento.")
	_expect(not director.has_blocking_boss_event(), "Dopo la morte non deve restare un lock Boss.")
	controller._process(100.0)
	_expect(_requested_indices == [0, 1], "Le soglie consumate non devono riattivarsi nella stessa run.")

	# Il restart azzera soglie, coda e Boss della run precedente. La stessa soglia
	# deve poter scattare esattamente una volta nella nuova run.
	_expect(controller.request_defeat(), "La prima run della fixture deve terminare.")
	_expect(controller.restart_run(14002), "RunController deve avviare una seconda run pulita.")
	_expect(director.get_triggered_count() == 0, "Il restart deve azzerare le soglie consumate.")
	_expect(director.get_pending_count() == 0, "Il restart deve svuotare la coda Boss.")
	_expect(director.get_requested_count() == 0, "Il conteggio richieste deve essere per-run.")
	controller._process(10.0)
	_expect(_requested_indices == [0, 1, 0], "La prima soglia deve riattivarsi una volta nella nuova run.")

	var restart_boss := Node2D.new()
	restart_boss.name = "RestartBoss"
	fixture.add_child(restart_boss)
	_expect(director.register_active_boss(restart_boss, 0), "La seconda run deve registrare il Boss.")
	_expect(controller.request_defeat(), "La seconda run deve poter terminare con il Boss vivo.")
	controller.prepare_restart()
	await process_frame
	_expect(not is_instance_valid(restart_boss), "Il restart deve eliminare il Boss tracciato.")
	_expect(not director.has_blocking_boss_event(), "Il restart non deve lasciare un evento Boss attivo.")

	paused = false
	fixture.queue_free()
	await process_frame


func _validate_composed_scene() -> void:
	_requested_indices.clear()
	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	root.add_child(movement_slice)
	await _wait_processed_frame()

	var controller := movement_slice.get_run_controller() as RunController
	var director := movement_slice.get_game_director() as GameDirector
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	_expect(controller != null, "La scena composta deve esporre RunController.")
	_expect(director != null, "La scena composta deve esporre GameDirector.")
	_expect(spawner != null, "La scena composta deve conservare EnemySpawner.")
	if controller == null or director == null or spawner == null:
		paused = false
		movement_slice.queue_free()
		await process_frame
		return

	controller.set_process(false)
	spawner.set_process(false)
	director.boss_event_requested.connect(_on_boss_event_requested)
	_expect(director.has_valid_configuration(), "Il GameDirector composto deve essere configurato.")
	_expect(
		director.profile.enemy_spawn_profile == spawner.spawn_profile,
		"Il profilo Director deve essere l'autorita sui parametri di spawn."
	)
	var thresholds := director.get_thresholds()
	_expect(thresholds.size() == 1, "L'MVP deve avere una sola soglia Boss.")
	if thresholds.size() == 1:
		_expect_float_near(thresholds[0], 240.0, "La soglia MVP deve usare 240 secondi di clock logico.")

	var delta_to_threshold := 240.0 - controller.get_run_time()
	controller._process(maxf(delta_to_threshold, 0.0) + 0.01)
	_expect(_requested_indices == [0], "La scena composta deve richiedere il Boss una volta a 04:00.")
	controller._process(30.0)
	_expect(_requested_indices == [0], "La scena composta non deve duplicare la soglia consumata.")

	_expect(controller.request_defeat(), "La scena composta deve poter terminare per il restart.")
	_expect(movement_slice.restart_run(14003), "La scena composta deve ripartire in-place.")
	_expect(director.get_triggered_count() == 0, "Il restart composto deve azzerare lo scheduler.")
	_expect(not director.has_blocking_boss_event(), "Il restart composto deve rimuovere la richiesta in volo.")
	controller._process(240.01)
	_expect(_requested_indices == [0, 0], "La nuova run composta deve emettere una sola nuova richiesta.")

	controller.prepare_restart()
	paused = false
	movement_slice.queue_free()
	await process_frame


func _on_boss_event_queued(schedule_index: int, _threshold_seconds: float) -> void:
	_queued_indices.append(schedule_index)


func _on_boss_event_requested(schedule_index: int, _threshold_seconds: float) -> void:
	_requested_indices.append(schedule_index)


func _on_boss_event_completed(schedule_index: int) -> void:
	_completed_indices.append(schedule_index)


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
		print("B14_GAME_DIRECTOR_SMOKE_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	printerr("B14_GAME_DIRECTOR_SMOKE_FAIL count=%d" % _failures.size())
	quit(1)
