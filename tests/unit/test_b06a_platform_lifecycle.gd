extends GutGameplayTest

const PAUSE_OVERLAY_SCENE := preload("res://scenes/ui/pause_overlay.tscn")
const PLATFORM_LIFECYCLE_SCRIPT := preload("res://scripts/input/platform_lifecycle.gd")
const PAUSE_CLOCK_TOLERANCE := 0.0001


func test_project_contract() -> void:
	assert_false(
		bool(ProjectSettings.get_setting("application/config/quit_on_go_back", true)),
		"Android Back non deve chiudere direttamente l'applicazione."
	)
	assert_true(InputMap.has_action(&"pause_game"), "InputMap deve dichiarare pause_game.")
	var has_escape := false
	var has_start := false
	for event in InputMap.action_get_events(&"pause_game"):
		if event is InputEventKey:
			has_escape = (event as InputEventKey).physical_keycode == KEY_ESCAPE
		elif event is InputEventJoypadButton:
			has_start = (event as InputEventJoypadButton).button_index == JOY_BUTTON_START
	assert_true(has_escape, "pause_game deve includere Escape fisico.")
	assert_true(has_start, "pause_game deve includere Start del controller.")


func test_lifecycle_fixture() -> void:
	var fixture := Node.new()
	fixture.name = "LifecycleFixture"
	add_child_autofree(fixture)
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
	await wait_process_frames(1)

	assert_true(
		lifecycle.configure(controller, router, overlay), "PlatformLifecycle deve accettare sorgenti valide."
	)
	assert_eq(lifecycle.get_run_controller(), controller, "Lifecycle deve osservare RunController.")
	assert_eq(lifecycle.get_input_router(), router, "Lifecycle deve controllare InputRouter.")
	assert_eq(lifecycle.get_pause_overlay(), overlay, "Lifecycle deve controllare PauseOverlay.")
	assert_true(controller.start_run(60101), "La fixture lifecycle deve avviare la run.")
	assert_true(controller.is_running() and not get_tree().paused, "La fixture deve partire in RUNNING.")
	assert_false(overlay.visible, "L'overlay pausa deve partire nascosto.")

	controller._process(1.25)
	var time_before_pause := controller.get_run_time()
	Input.action_press(&"move_right", 1.0)
	router._process(0.0)
	assert_true(router.movement_vector.x > 0.99, "Il movimento held deve partire attivo.")
	lifecycle._unhandled_input(_action_event(&"pause_game"))
	assert_true(
		controller.get_state() == RunController.RunState.MANUAL_PAUSE and get_tree().paused,
		"Escape/Start deve richiedere MANUAL_PAUSE."
	)
	assert_true(overlay.is_accepting_resume(), "La pausa manuale deve mostrare un overlay interattivo.")
	assert_eq(router.movement_vector, Vector2.ZERO, "La pausa manuale deve azzerare l'input.")
	controller._process(5.0)
	assert_almost_eq(
		controller.get_run_time(), time_before_pause, PAUSE_CLOCK_TOLERANCE,
		"Il clock non deve avanzare in MANUAL_PAUSE."
	)

	# Una seconda pressione e una scelta esplicita, ma l'input held resta chiuso
	# finche tutte le sorgenti non tornano neutrali.
	lifecycle._unhandled_input(_action_event(&"pause_game"))
	assert_true(
		controller.is_running() and not get_tree().paused, "Una seconda pressione deve riprendere esplicitamente."
	)
	assert_true(router.is_input_suspended(), "Un input held non deve attraversare il resume.")
	assert_eq(router.movement_vector, Vector2.ZERO, "Il resume held non deve muovere il Player.")
	Input.action_release(&"move_right")
	router._process(0.0)
	assert_false(router.is_input_suspended(), "Il neutro deve riarmare il router dopo la pausa.")

	# Home/lock può soltanto sospendere. Il ritorno dell'app non cambia lo stato.
	router.notification(NOTIFICATION_APPLICATION_PAUSED)
	lifecycle.notification(NOTIFICATION_APPLICATION_PAUSED)
	assert_eq(
		controller.get_state(), RunController.RunState.MANUAL_PAUSE,
		"Application paused deve convertire RUNNING in MANUAL_PAUSE."
	)
	var resume_button := overlay.get_resume_button() as Button
	assert_true(resume_button != null and not resume_button.disabled, "RIPRENDI deve essere attivo in pausa.")
	if resume_button != null:
		resume_button.emit_signal(&"pressed")
	assert_eq(
		controller.get_state(), RunController.RunState.MANUAL_PAUSE,
		"RIPRENDI deve essere rifiutato mentre l'app e sospesa."
	)
	lifecycle.notification(NOTIFICATION_APPLICATION_RESUMED)
	router.notification(NOTIFICATION_APPLICATION_RESUMED)
	assert_true(
		controller.get_state() == RunController.RunState.MANUAL_PAUSE and get_tree().paused,
		"Application resumed non deve riprendere automaticamente la run."
	)
	if resume_button != null:
		resume_button.emit_signal(&"pressed")
	assert_true(controller.is_running() and not get_tree().paused, "RIPRENDI deve funzionare dopo il resume OS.")

	# La perdita di focus segue lo stesso contratto e non duplica le transizioni.
	router.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	lifecycle.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_false(lifecycle.is_application_active(), "Focus out deve marcare l'app non attiva.")
	assert_eq(
		controller.get_state(), RunController.RunState.MANUAL_PAUSE, "Focus out deve mettere in pausa."
	)
	lifecycle.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	assert_eq(
		controller.get_state(), RunController.RunState.MANUAL_PAUSE, "Focus out duplicato deve essere idempotente."
	)
	lifecycle.notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	router.notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	assert_eq(
		controller.get_state(), RunController.RunState.MANUAL_PAUSE, "Focus in non deve riprendere la run."
	)
	assert_true(lifecycle.request_resume(), "Una conferma esplicita con focus deve riprendere.")

	# Back apre e chiude l'overlay di pausa senza terminare il processo.
	lifecycle.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	assert_eq(controller.get_state(), RunController.RunState.MANUAL_PAUSE, "Back deve aprire la pausa.")
	lifecycle.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	assert_true(controller.is_running(), "Back nell'overlay pausa deve agire da cancel esplicito.")

	# Gli overlay con priorita propria non vengono sostituiti dalla pausa manuale.
	assert_true(controller.request_level_up(), "La fixture deve entrare in LEVEL_UP.")
	assert_false(lifecycle.request_back(), "Back in LEVEL_UP non deve cambiare modalita.")
	assert_eq(controller.get_state(), RunController.RunState.LEVEL_UP, "LEVEL_UP deve restare autorevole.")
	assert_false(overlay.visible, "PauseOverlay non deve coprire un altro stato modale.")
	assert_true(controller.complete_level_up(), "La fixture deve completare LEVEL_UP.")

	controller.prepare_restart()
	Input.action_release(&"move_right")


func test_composed_pause_flow() -> void:
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_node_or_null("RunController") as RunController
	var router := movement_slice.get_node_or_null("InputRouter") as InputRouter
	var lifecycle = movement_slice.get_node_or_null("PlatformLifecycle")
	var joystick := movement_slice.get_node_or_null("UI/SafeAreaRoot/TouchJoystick") as TouchJoystick
	var hud := movement_slice.get_node_or_null("UI/SafeAreaRoot/HUD") as GameHud
	var overlay = movement_slice.get_node_or_null("UI/PauseOverlay")
	var player := movement_slice.get_node_or_null("World/Player") as Player
	var arena := movement_slice.get_node_or_null("ArenaLayout") as ArenaLayout
	assert_not_null(controller, "La scena B06A deve contenere RunController.")
	assert_not_null(router, "La scena B06A deve contenere InputRouter.")
	assert_not_null(lifecycle, "La scena B06A deve contenere PlatformLifecycle.")
	assert_not_null(joystick, "La scena B06A deve contenere TouchJoystick.")
	assert_not_null(hud, "La scena B06A deve contenere HUD.")
	assert_not_null(overlay, "La scena B06A deve contenere PauseOverlay.")
	assert_not_null(player, "La scena B06A deve contenere Player.")
	assert_not_null(arena, "La scena B06A deve contenere ArenaLayout.")
	if (
		controller == null
		or router == null
		or lifecycle == null
		or joystick == null
		or hud == null
		or overlay == null
		or player == null
		or arena == null
	):
		return

	controller.set_process(false)
	assert_true(controller.is_running(), "La scena B06A deve partire in RUNNING.")
	var pause_button := hud.get_pause_button()
	assert_true(pause_button != null and not pause_button.disabled, "Il pulsante PAUSA deve essere attivo.")
	assert_true(hud.get_pause_button_rect().has_area(), "Il pulsante PAUSA deve avere un rect valido.")

	joystick._gui_input(make_touch_event(31, true, joystick.size * Vector2(0.9, 0.5)))
	router._process(0.0)
	assert_true(joystick.is_active(), "Il test composto deve catturare un dito sul joystick.")
	assert_false(router.movement_vector.is_zero_approx(), "Il touch composto deve raggiungere InputRouter.")
	if pause_button != null:
		pause_button.emit_signal(&"pressed")
	assert_eq(
		controller.get_state(), RunController.RunState.MANUAL_PAUSE, "Il tap PAUSA deve fermare la run."
	)
	assert_true(overlay.is_accepting_resume(), "Il tap PAUSA deve mostrare RIPRENDI.")
	assert_false(joystick.is_active(), "La pausa touch deve liberare il dito catturato.")
	assert_eq(router.movement_vector, Vector2.ZERO, "La pausa touch deve azzerare il movimento.")
	assert_true(pause_button.disabled, "PAUSA deve essere disabilitato fuori da RUNNING.")

	var position_before_layout_transition := Vector2(1100.0, 360.0)
	player.global_position = position_before_layout_transition
	var stable_playfield := arena.get_playfield_rect()
	var transient_playfield := Rect2(Vector2(500.0, 0.0), Vector2(280.0, 720.0))
	arena._playfield_rect = transient_playfield
	arena.playfield_changed.emit(transient_playfield)
	assert_eq(
		player.global_position, position_before_layout_transition,
		"Un layout portrait transitorio durante pausa/lock non deve spostare il Player."
	)
	arena._playfield_rect = stable_playfield
	arena.playfield_changed.emit(stable_playfield)
	assert_eq(
		player.global_position, position_before_layout_transition,
		"Il ripristino landscape prima del resume deve conservare la posizione del Player."
	)

	var resume_button := overlay.get_resume_button() as Button
	if resume_button != null:
		resume_button.emit_signal(&"pressed")
	assert_true(controller.is_running() and not get_tree().paused, "Il tap RIPRENDI deve tornare a RUNNING.")
	assert_false(overlay.visible, "RIPRENDI deve nascondere l'overlay.")
	assert_false(pause_button.disabled, "PAUSA deve riattivarsi al resume.")

	# Tre cicli consecutivi verificano che non si accumulino callback UI.
	for _index in range(3):
		pause_button.emit_signal(&"pressed")
		assert_eq(
			controller.get_state(), RunController.RunState.MANUAL_PAUSE, "Ogni tap deve produrre una sola pausa."
		)
		resume_button.emit_signal(&"pressed")
		assert_true(controller.is_running(), "Ogni conferma deve produrre un solo resume.")

	controller.prepare_restart()


func _action_event(action: StringName) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	return event
