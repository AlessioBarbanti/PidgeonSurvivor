extends SceneTree

const MOVEMENT_SLICE_SCENE := preload("res://scenes/game/movement_slice.tscn")
const PAUSE_OVERLAY_SCENE := preload("res://scenes/ui/pause_overlay.tscn")
const PLATFORM_LIFECYCLE_SCRIPT := preload("res://scripts/input/platform_lifecycle.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_validate_project_contract()
	await _validate_lifecycle_fixture()
	await _validate_composed_pause_flow()
	await _finish()


func _validate_project_contract() -> void:
	_expect(
		not bool(ProjectSettings.get_setting("application/config/quit_on_go_back", true)),
		"Android Back non deve chiudere direttamente l'applicazione."
	)
	_expect(InputMap.has_action(&"pause_game"), "InputMap deve dichiarare pause_game.")
	var has_escape := false
	var has_start := false
	for event in InputMap.action_get_events(&"pause_game"):
		if event is InputEventKey:
			has_escape = (event as InputEventKey).physical_keycode == KEY_ESCAPE
		elif event is InputEventJoypadButton:
			has_start = (event as InputEventJoypadButton).button_index == JOY_BUTTON_START
	_expect(has_escape, "pause_game deve includere Escape fisico.")
	_expect(has_start, "pause_game deve includere Start del controller.")


func _validate_lifecycle_fixture() -> void:
	paused = false
	var fixture := Node.new()
	fixture.name = "LifecycleFixture"
	var controller := RunController.new()
	controller.name = "RunController"
	controller.set_process(false)
	var router := InputRouter.new()
	router.name = "InputRouter"
	var lifecycle = PLATFORM_LIFECYCLE_SCRIPT.new()
	lifecycle.name = "PlatformLifecycle"
	var overlay = PAUSE_OVERLAY_SCENE.instantiate()
	fixture.add_child(controller)
	fixture.add_child(router)
	fixture.add_child(lifecycle)
	fixture.add_child(overlay)
	root.add_child(fixture)
	await process_frame

	_expect(
		lifecycle.configure(controller, router, overlay),
		"PlatformLifecycle deve accettare sorgenti valide."
	)
	_expect(lifecycle.get_run_controller() == controller, "Lifecycle deve osservare RunController.")
	_expect(lifecycle.get_input_router() == router, "Lifecycle deve controllare InputRouter.")
	_expect(lifecycle.get_pause_overlay() == overlay, "Lifecycle deve controllare PauseOverlay.")
	_expect(controller.start_run(60101), "La fixture lifecycle deve avviare la run.")
	_expect(controller.is_running() and not paused, "La fixture deve partire in RUNNING.")
	_expect(not overlay.visible, "L'overlay pausa deve partire nascosto.")

	controller._process(1.25)
	var time_before_pause := controller.get_run_time()
	Input.action_press(&"move_right", 1.0)
	router._process(0.0)
	_expect(router.movement_vector.x > 0.99, "Il movimento held deve partire attivo.")
	lifecycle._unhandled_input(_action(&"pause_game"))
	_expect(
		controller.get_state() == RunController.RunState.MANUAL_PAUSE and paused,
		"Escape/Start deve richiedere MANUAL_PAUSE."
	)
	_expect(overlay.is_accepting_resume(), "La pausa manuale deve mostrare un overlay interattivo.")
	_expect(router.movement_vector == Vector2.ZERO, "La pausa manuale deve azzerare l'input.")
	controller._process(5.0)
	_expect_float_near(
		controller.get_run_time(),
		time_before_pause,
		"Il clock non deve avanzare in MANUAL_PAUSE."
	)

	# Una seconda pressione e una scelta esplicita, ma l'input held resta chiuso
	# finche tutte le sorgenti non tornano neutrali.
	lifecycle._unhandled_input(_action(&"pause_game"))
	_expect(controller.is_running() and not paused, "Una seconda pressione deve riprendere esplicitamente.")
	_expect(router.is_input_suspended(), "Un input held non deve attraversare il resume.")
	_expect(router.movement_vector == Vector2.ZERO, "Il resume held non deve muovere il Player.")
	Input.action_release(&"move_right")
	router._process(0.0)
	_expect(not router.is_input_suspended(), "Il neutro deve riarmare il router dopo la pausa.")

	# Home/lock può soltanto sospendere. Il ritorno dell'app non cambia lo stato.
	router.notification(NOTIFICATION_APPLICATION_PAUSED)
	lifecycle.notification(NOTIFICATION_APPLICATION_PAUSED)
	_expect(
		controller.get_state() == RunController.RunState.MANUAL_PAUSE,
		"Application paused deve convertire RUNNING in MANUAL_PAUSE."
	)
	var resume_button := overlay.get_resume_button() as Button
	_expect(resume_button != null and not resume_button.disabled, "RIPRENDI deve essere attivo in pausa.")
	if resume_button != null:
		resume_button.emit_signal(&"pressed")
	_expect(
		controller.get_state() == RunController.RunState.MANUAL_PAUSE,
		"RIPRENDI deve essere rifiutato mentre l'app e sospesa."
	)
	lifecycle.notification(NOTIFICATION_APPLICATION_RESUMED)
	router.notification(NOTIFICATION_APPLICATION_RESUMED)
	_expect(
		controller.get_state() == RunController.RunState.MANUAL_PAUSE and paused,
		"Application resumed non deve riprendere automaticamente la run."
	)
	if resume_button != null:
		resume_button.emit_signal(&"pressed")
	_expect(controller.is_running() and not paused, "RIPRENDI deve funzionare dopo il resume OS.")

	# La perdita di focus segue lo stesso contratto e non duplica le transizioni.
	router.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	lifecycle.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	_expect(not lifecycle.is_application_active(), "Focus out deve marcare l'app non attiva.")
	_expect(controller.get_state() == RunController.RunState.MANUAL_PAUSE, "Focus out deve mettere in pausa.")
	lifecycle.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	_expect(controller.get_state() == RunController.RunState.MANUAL_PAUSE, "Focus out duplicato deve essere idempotente.")
	lifecycle.notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	router.notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	_expect(controller.get_state() == RunController.RunState.MANUAL_PAUSE, "Focus in non deve riprendere la run.")
	_expect(lifecycle.request_resume(), "Una conferma esplicita con focus deve riprendere.")

	# Back apre e chiude l'overlay di pausa senza terminare il processo.
	lifecycle.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	_expect(controller.get_state() == RunController.RunState.MANUAL_PAUSE, "Back deve aprire la pausa.")
	lifecycle.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	_expect(controller.is_running(), "Back nell'overlay pausa deve agire da cancel esplicito.")

	# Gli overlay con priorita propria non vengono sostituiti dalla pausa manuale.
	_expect(controller.request_level_up(), "La fixture deve entrare in LEVEL_UP.")
	_expect(not lifecycle.request_back(), "Back in LEVEL_UP non deve cambiare modalita.")
	_expect(controller.get_state() == RunController.RunState.LEVEL_UP, "LEVEL_UP deve restare autorevole.")
	_expect(not overlay.visible, "PauseOverlay non deve coprire un altro stato modale.")
	_expect(controller.complete_level_up(), "La fixture deve completare LEVEL_UP.")

	controller.prepare_restart()
	paused = false
	Input.action_release(&"move_right")
	fixture.queue_free()
	await process_frame


func _validate_composed_pause_flow() -> void:
	paused = false
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	var movement_slice = MOVEMENT_SLICE_SCENE.instantiate()
	root.add_child(movement_slice)
	await _wait_processed_frame()

	var controller := movement_slice.get_node_or_null("RunController") as RunController
	var router := movement_slice.get_node_or_null("InputRouter") as InputRouter
	var lifecycle = movement_slice.get_node_or_null("PlatformLifecycle")
	var joystick := movement_slice.get_node_or_null("UI/SafeAreaRoot/TouchJoystick") as TouchJoystick
	var hud := movement_slice.get_node_or_null("UI/SafeAreaRoot/HUD") as GameHud
	var overlay = movement_slice.get_node_or_null("UI/PauseOverlay")
	_expect(controller != null, "La scena B06A deve contenere RunController.")
	_expect(router != null, "La scena B06A deve contenere InputRouter.")
	_expect(lifecycle != null, "La scena B06A deve contenere PlatformLifecycle.")
	_expect(joystick != null, "La scena B06A deve contenere TouchJoystick.")
	_expect(hud != null, "La scena B06A deve contenere HUD.")
	_expect(overlay != null, "La scena B06A deve contenere PauseOverlay.")
	if (
		controller == null
		or router == null
		or lifecycle == null
		or joystick == null
		or hud == null
		or overlay == null
	):
		paused = false
		movement_slice.queue_free()
		await process_frame
		return

	controller.set_process(false)
	_expect(controller.is_running(), "La scena B06A deve partire in RUNNING.")
	var pause_button := hud.get_pause_button()
	_expect(pause_button != null and not pause_button.disabled, "Il pulsante PAUSA deve essere attivo.")
	_expect(hud.get_pause_button_rect().has_area(), "Il pulsante PAUSA deve avere un rect valido.")

	joystick._gui_input(_touch(31, true, joystick.size * Vector2(0.9, 0.5)))
	router._process(0.0)
	_expect(joystick.is_active(), "Il test composto deve catturare un dito sul joystick.")
	_expect(not router.movement_vector.is_zero_approx(), "Il touch composto deve raggiungere InputRouter.")
	if pause_button != null:
		pause_button.emit_signal(&"pressed")
	_expect(controller.get_state() == RunController.RunState.MANUAL_PAUSE, "Il tap PAUSA deve fermare la run.")
	_expect(overlay.is_accepting_resume(), "Il tap PAUSA deve mostrare RIPRENDI.")
	_expect(not joystick.is_active(), "La pausa touch deve liberare il dito catturato.")
	_expect(router.movement_vector == Vector2.ZERO, "La pausa touch deve azzerare il movimento.")
	_expect(pause_button.disabled, "PAUSA deve essere disabilitato fuori da RUNNING.")

	var resume_button := overlay.get_resume_button() as Button
	if resume_button != null:
		resume_button.emit_signal(&"pressed")
	_expect(controller.is_running() and not paused, "Il tap RIPRENDI deve tornare a RUNNING.")
	_expect(not overlay.visible, "RIPRENDI deve nascondere l'overlay.")
	_expect(not pause_button.disabled, "PAUSA deve riattivarsi al resume.")

	# Tre cicli consecutivi verificano che non si accumulino callback UI.
	for _index in range(3):
		pause_button.emit_signal(&"pressed")
		_expect(controller.get_state() == RunController.RunState.MANUAL_PAUSE, "Ogni tap deve produrre una sola pausa.")
		resume_button.emit_signal(&"pressed")
		_expect(controller.is_running(), "Ogni conferma deve produrre un solo resume.")

	controller.prepare_restart()
	paused = false
	movement_slice.queue_free()
	await process_frame


func _action(action: StringName) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	return event


func _touch(index: int, pressed: bool, position: Vector2) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.pressed = pressed
	event.position = position
	return event


func _wait_processed_frame() -> void:
	await process_frame
	await process_frame


func _expect_float_near(actual: float, expected: float, message: String) -> void:
	_expect(
		absf(actual - expected) <= 0.0001,
		"%s Atteso %s, ottenuto %s." % [message, expected, actual]
	)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	paused = false
	await process_frame
	if _failures.is_empty():
		print("B06A_PLATFORM_LIFECYCLE_SMOKE_OK")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	printerr("B06A_PLATFORM_LIFECYCLE_SMOKE_FAIL count=%d" % _failures.size())
	quit(1)
