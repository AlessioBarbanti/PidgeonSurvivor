extends GutGameplayTest

var _queued_levels: Array[int] = []
var _started_levels: Array[int] = []
var _completed_levels: Array[int] = []


func after_each() -> void:
	get_tree().paused = false


func test_experience_curve_is_linear_and_defensive() -> void:
	var curve := ExperienceCurve.new()
	curve.base_experience_required = 10
	curve.experience_growth_per_level = 5
	assert_true(
		curve.get_experience_required(0) == 10
		and curve.get_experience_required(1) == 10
		and curve.get_experience_required(2) == 15
		and curve.get_experience_required(5) == 30,
		"La curva XP lineare deve usare livello 1 come baseline."
	)

	curve.base_experience_required = 0
	curve.experience_growth_per_level = -5
	assert_true(
		curve.get_experience_required(1) == 1 and curve.get_experience_required(50) == 1,
		"La curva XP deve difendersi da valori runtime non validi."
	)


func test_level_queue_and_overflow() -> void:
	_queued_levels.clear()
	_started_levels.clear()
	_completed_levels.clear()

	var fixture := Node.new()
	fixture.name = "LevelProgressionFixture"
	var controller := RunController.new()
	controller.name = "RunController"
	controller.set_process(false)
	var experience := ExperienceSystem.new()
	experience.name = "ExperienceSystem"
	var curve := ExperienceCurve.new()
	curve.base_experience_required = 10
	curve.experience_growth_per_level = 5
	experience.experience_curve = curve
	fixture.add_child(controller)
	fixture.add_child(experience)
	add_child_autofree(fixture)
	experience.set_run_controller(controller)
	experience.level_up_queued.connect(_on_level_up_queued)
	experience.level_up_started.connect(_on_level_up_started)
	experience.level_up_completed.connect(_on_level_up_completed)
	await wait_process_frames(1)

	assert_true(controller.start_run(8001), "La fixture B08 deve avviare la run.")
	assert_true(
		experience.level == 1
		and experience.experience_current == 0
		and experience.experience_total == 0
		and experience.experience_required == 10
		and experience.pending_level_ups == 0,
		"Una run nuova deve partire dal livello 1 senza XP o scelte pendenti."
	)
	assert_true(experience.add_experience(9), "RUNNING deve accettare XP sotto soglia.")
	assert_true(
		experience.level == 1 and experience.experience_current == 9 and experience.experience_total == 9 and controller.is_running(),
		"Gli XP sotto soglia devono restare nella barra senza aprire LEVEL_UP."
	)

	assert_true(experience.add_experience(1), "La soglia esatta deve essere accettata.")
	assert_true(
		experience.level == 2
		and experience.experience_current == 0
		and experience.experience_total == 10
		and experience.experience_required == 15,
		"La soglia esatta deve avanzare di livello senza perdere XP."
	)
	assert_true(
		controller.get_state() == RunController.RunState.LEVEL_UP
		and get_tree().paused
		and experience.pending_level_ups == 1
		and experience.get_active_level_up_level() == 2
		and experience.get_pending_level_up_levels() == [2],
		"Il primo livello deve mettere in pausa e aprire una sola scelta."
	)
	assert_false(experience.add_experience(1), "LEVEL_UP deve bloccare accrediti XP concorrenti.")
	assert_true(experience.complete_level_up(), "La prima scelta deve poter essere completata.")
	assert_true(
		controller.is_running()
		and not get_tree().paused
		and experience.pending_level_ups == 0
		and experience.get_active_level_up_level() == 0,
		"Esaurita la coda, la run deve riprendere."
	)

	assert_true(experience.add_experience(40), "Un accredito grande deve poter attraversare più soglie.")
	assert_true(
		experience.level == 4
		and experience.experience_current == 5
		and experience.experience_total == 50
		and experience.experience_required == 25,
		"L'overflow multiplo deve essere conservato rispetto alla nuova soglia."
	)
	assert_true(
		experience.get_pending_level_up_levels() == [3, 4]
		and experience.get_active_level_up_level() == 3
		and controller.get_state() == RunController.RunState.LEVEL_UP,
		"Ogni livello saltato deve produrre una voce ordinata nella coda."
	)
	assert_true(experience.complete_level_up(), "La prima scelta multipla deve chiudersi.")
	assert_true(
		controller.get_state() == RunController.RunState.LEVEL_UP
		and get_tree().paused
		and experience.get_pending_level_up_levels() == [4]
		and experience.get_active_level_up_level() == 4,
		"La scelta successiva deve aprirsi senza un frame di gameplay intermedio."
	)
	assert_true(experience.complete_level_up(), "La seconda scelta multipla deve chiudersi.")
	assert_true(
		controller.is_running() and not get_tree().paused and experience.pending_level_ups == 0,
		"La run deve riprendere soltanto dopo l'ultima scelta."
	)
	assert_true(
		_queued_levels == [2, 3, 4] and _started_levels == [2, 3, 4] and _completed_levels == [2, 3, 4],
		"Ogni livello guadagnato deve accodare, presentare e completare una scelta."
	)

	assert_true(
		experience.add_experience(20) and experience.level == 5 and experience.experience_current == 0,
		"L'overflow precedente deve contribuire alla soglia successiva."
	)
	assert_true(controller.request_defeat(), "Un terminale deve poter interrompere LEVEL_UP con priorità.")
	assert_true(
		not experience.complete_level_up() and experience.pending_level_ups == 1,
		"Una scelta interrotta dal terminale non deve essere consumata."
	)
	assert_true(controller.restart_run(8002), "Il terminale deve accettare il restart.")
	assert_true(
		controller.is_running()
		and experience.level == 1
		and experience.experience_current == 0
		and experience.experience_total == 0
		and experience.pending_level_ups == 0
		and experience.get_active_level_up_level() == 0,
		"Il restart deve azzerare livelli, overflow e coda."
	)

	controller.prepare_restart()


func test_composed_level_flow_across_multiple_choices() -> void:
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_node_or_null("RunController") as RunController
	var experience := movement_slice.get_node_or_null("ExperienceSystem") as ExperienceSystem
	var spawner := movement_slice.get_node_or_null("EnemySpawner") as EnemySpawner
	var player := movement_slice.get_node_or_null("World/Player") as Player
	var weapon: WeaponController
	if player != null:
		weapon = player.get_weapon_controller()

	assert_not_null(controller, "La scena B08 deve contenere RunController.")
	assert_not_null(experience, "La scena B08 deve contenere ExperienceSystem.")
	if controller == null or experience == null:
		return

	controller.set_process(false)
	if spawner != null:
		spawner.set_process(false)
	if player != null:
		player.set_physics_process(false)
	if weapon != null:
		weapon.set_process(false)

	assert_not_null(experience.experience_curve, "La scena B08 deve caricare la curva XP dati.")
	assert_true(
		experience.add_experience(45)
		and experience.level == 4
		and experience.experience_current == 0
		and experience.experience_total == 45
		and experience.get_pending_level_up_levels() == [2, 3, 4],
		"La scena composta deve preservare tre soglie e tre scelte."
	)
	assert_true(experience.complete_level_up(), "La scena deve consumare la scelta livello 2.")
	assert_true(experience.complete_level_up(), "La scena deve consumare la scelta livello 3.")
	assert_true(experience.complete_level_up(), "La scena deve consumare la scelta livello 4.")
	assert_true(
		controller.is_running() and experience.pending_level_ups == 0, "La scena composta deve riprendere dopo tutte le scelte."
	)

	controller.prepare_restart()


func _on_level_up_queued(level: int, _pending_choices: int) -> void:
	_queued_levels.append(level)


func _on_level_up_started(level: int, _pending_choices: int) -> void:
	_started_levels.append(level)


func _on_level_up_completed(level: int, _pending_choices: int) -> void:
	_completed_levels.append(level)
