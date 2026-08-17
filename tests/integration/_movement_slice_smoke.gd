extends SceneTree

const MOVEMENT_SLICE_SCENE := preload(
	"res://scenes/game/movement_slice.tscn"
)
const MOVEMENT_SLICE_SCRIPT := preload(
	"res://scripts/game/movement_slice.gd"
)
const TEST_VIEWPORT_SIZE := Vector2i(1280, 720)

const MOVE_ACTIONS: Array[StringName] = [
	&"move_left",
	&"move_right",
	&"move_up",
	&"move_down",
]

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_release_actions()
	paused = false
	# Il display server headless non applica sempre --resolution alla Window root.
	root.content_scale_size = TEST_VIEWPORT_SIZE
	root.size = TEST_VIEWPORT_SIZE
	await _wait_processed_frame()
	_validate_layout_math()

	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	root.add_child(movement_slice)
	await _wait_processed_frame()

	var arena := movement_slice.get_node_or_null("ArenaLayout") as ArenaLayout
	var controller := movement_slice.get_node_or_null("RunController") as RunController
	var player := movement_slice.get_node_or_null("World/Player") as Player
	var router := movement_slice.get_node_or_null("InputRouter") as InputRouter
	var lifecycle = movement_slice.get_node_or_null("PlatformLifecycle")
	var joystick := (
		movement_slice.get_node_or_null("UI/SafeAreaRoot/TouchJoystick")
		as TouchJoystick
	)

	_expect(
		root.get_visible_rect().size == Vector2(TEST_VIEWPORT_SIZE),
		"Il test deve esercitare una viewport landscape 1280x720."
	)
	_expect(arena != null, "ArenaLayout deve essere presente nel vertical slice.")
	_expect(controller != null, "RunController deve essere presente nel vertical slice.")
	_expect(player != null, "Player deve essere presente nel vertical slice.")
	_expect(router != null, "InputRouter deve essere presente nel vertical slice.")
	_expect(lifecycle != null, "PlatformLifecycle deve essere presente nel vertical slice.")
	_expect(joystick != null, "TouchJoystick deve essere presente nel vertical slice.")
	if (
		arena == null
		or controller == null
		or player == null
		or router == null
		or lifecycle == null
		or joystick == null
	):
		await _finish(movement_slice)
		return

	_expect(
		player.get_arena_layout() == arena,
		"Player deve essere collegato all'ArenaLayout della scena."
	)
	_expect(
		arena.get_playfield_rect().has_area(),
		"ArenaLayout deve produrre un playfield valido."
	)
	_expect(
		movement_slice.get_touch_joystick_viewport_rect().has_area(),
		"Il joystick deve ricevere un rettangolo valido nella safe area."
	)

	# Input cardinal: il router deve guidare il Player tramite la connessione di scena.
	var start_position := player.global_position
	Input.action_press(&"move_right", 1.0)
	await _wait_processed_frame()
	_expect_vector_near(
		router.movement_vector,
		Vector2.RIGHT,
		0.01,
		"L'input cardinale destro deve restare unitario."
	)
	_expect_vector_near(
		player.movement_input,
		Vector2.RIGHT,
		0.01,
		"Il segnale del router deve raggiungere il Player."
	)
	await _wait_physics_step()
	_expect(
		player.global_position.x > start_position.x,
		"Il Player deve spostarsi a destra durante i frame fisici."
	)
	_expect(
		is_equal_approx(player.global_position.y, start_position.y),
		"Un input cardinale destro non deve introdurre deriva verticale."
	)
	Input.action_release(&"move_right")
	await _wait_processed_frame()

	# Diagonale piena normalizzata e diagonale analogica graduata.
	Input.action_press(&"move_right", 1.0)
	Input.action_press(&"move_down", 1.0)
	await _wait_processed_frame()
	var full_diagonal := router.movement_vector
	_expect(
		is_equal_approx(full_diagonal.length(), 1.0),
		"La diagonale piena deve essere normalizzata al cerchio unitario."
	)
	_expect(
		full_diagonal.x > 0.0 and full_diagonal.y > 0.0,
		"La diagonale destra/basso deve conservare entrambi gli assi."
	)
	Input.action_release(&"move_right")
	Input.action_release(&"move_down")
	await _wait_processed_frame()

	Input.action_press(&"move_right", 0.65)
	Input.action_press(&"move_down", 0.35)
	await _wait_processed_frame()
	var graded_diagonal := router.movement_vector
	_expect(
		graded_diagonal.x > graded_diagonal.y and graded_diagonal.y > 0.0,
		"La diagonale graduata deve conservare il rapporto tra gli assi."
	)
	_expect(
		graded_diagonal.length() > 0.0 and graded_diagonal.length() < 1.0,
		"La diagonale graduata non deve essere forzata a piena intensita."
	)
	Input.action_release(&"move_right")
	Input.action_release(&"move_down")
	await _wait_processed_frame()

	# Clamp su entrambi gli estremi, includendo il raggio di collisione.
	var playfield := arena.get_playfield_rect()
	var outside_minimum := playfield.position - Vector2(500.0, 500.0)
	player.global_position = outside_minimum
	await _wait_physics_step()
	_expect_vector_near(
		player.global_position,
		arena.clamp_circle_center(outside_minimum, player.collision_radius),
		0.01,
		"Il Player deve essere confinato all'estremo minimo del playfield."
	)

	var outside_maximum := playfield.end + Vector2(500.0, 500.0)
	player.global_position = outside_maximum
	await _wait_physics_step()
	_expect_vector_near(
		player.global_position,
		arena.clamp_circle_center(outside_maximum, player.collision_radius),
		0.01,
		"Il Player deve essere confinato all'estremo massimo del playfield."
	)
	player.global_position = arena.get_playfield_center()

	# Dispatch diretto: testa ownership senza dipendere dall'hit-testing headless.
	joystick.show()
	var joystick_center := joystick.size * 0.5
	var right_edge := joystick_center + Vector2.RIGHT * joystick.base_radius
	var left_edge := joystick_center + Vector2.LEFT * joystick.base_radius
	joystick._gui_input(_touch(21, true, right_edge))
	_expect(joystick.active_finger_index == 21, "Il primo dito deve possedere il joystick.")
	_expect(
		router.movement_vector.x > 0.99,
		"Il touch destro deve attraversare il router della scena."
	)
	_expect(
		player.movement_input.x > 0.99,
		"Il touch deve raggiungere il Player tramite il wiring del vertical slice."
	)

	joystick._gui_input(_touch(22, true, left_edge))
	_expect(
		joystick.active_finger_index == 21,
		"Un secondo dito non deve sottrarre l'ownership del joystick."
	)
	_expect(
		router.movement_vector.x > 0.99,
		"Il secondo dito non deve alterare il vettore del proprietario."
	)
	joystick._gui_input(_touch(22, false, left_edge))
	_expect(joystick.is_active(), "Il rilascio di un dito estraneo va ignorato.")
	joystick._gui_input(_touch(21, false, right_edge))
	_expect(not joystick.is_active(), "Il rilascio del proprietario deve liberare il joystick.")
	_expect_vector_near(
		router.movement_vector,
		Vector2.ZERO,
		0.001,
		"Il rilascio touch senza altre sorgenti deve azzerare il router."
	)

	# La pausa deve resettare ownership e movimento anche con nodi always-process.
	joystick._gui_input(_touch(31, true, right_edge))
	paused = true
	await _wait_processed_frame()
	_expect(not joystick.is_active(), "La pausa deve rilasciare il dito catturato.")
	_expect_vector_near(
		router.movement_vector,
		Vector2.ZERO,
		0.001,
		"La pausa deve sospendere il router."
	)
	_expect_vector_near(
		player.movement_input,
		Vector2.ZERO,
		0.001,
		"La sospensione del router deve azzerare il Player."
	)
	paused = false
	_expect(router.resume_input(), "Fuori pausa il router deve accettare il rearm.")
	await _wait_processed_frame()
	_expect(not router.is_input_suspended(), "Il neutro deve completare il rearm post-pausa.")

	# Focus gate: un input held resta bloccato fino al ritorno esplicito al neutro.
	Input.action_press(&"move_left", 1.0)
	await _wait_processed_frame()
	_expect(router.movement_vector.x < -0.99, "Il precondition focus deve essere attivo.")
	router.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	_expect(router.is_input_suspended(), "Focus out deve chiudere il gate input.")
	_expect_vector_near(
		player.movement_input,
		Vector2.ZERO,
		0.001,
		"Focus out deve azzerare il Player tramite il router."
	)
	_expect(
		not router.resume_input(),
		"Il router non deve riarmarsi finche l'app non ha focus."
	)
	router.notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	_expect(router.resume_input(), "Focus in deve consentire una richiesta di rearm.")
	await _wait_processed_frame()
	_expect(
		router.is_input_suspended() and router.movement_vector == Vector2.ZERO,
		"Un input held non deve attraversare il focus gate dopo il resume."
	)
	Input.action_release(&"move_left")
	await _wait_processed_frame()
	_expect(
		not router.is_input_suspended(),
		"Il ritorno al neutro deve completare il rearm del focus gate."
	)
	Input.action_press(&"move_left", 1.0)
	await _wait_processed_frame()
	_expect(
		router.movement_vector.x < -0.99,
		"Solo un nuovo input dopo il neutro deve superare il focus gate."
	)
	Input.action_release(&"move_left")
	await _wait_processed_frame()

	# L'ordine parent-before-child non deve riaprire la run al focus-in.
	router.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	lifecycle.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	movement_slice.notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	lifecycle.notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	router.notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	await _wait_processed_frame()
	_expect(
		controller.get_state() == RunController.RunState.MANUAL_PAUSE
		and router.is_input_suspended(),
		"Il focus-in parent-before-child deve lasciare run e input sospesi."
	)
	_expect(
		lifecycle.request_resume(),
		"Una conferma esplicita deve riprendere dopo tutte le notifiche di focus."
	)
	await _wait_processed_frame()
	_expect(not router.is_input_suspended(), "Il neutro deve completare il resume esplicito.")
	Input.action_press(&"move_right", 1.0)
	await _wait_processed_frame()
	_expect(
		router.movement_vector.x > 0.99,
		"Un nuovo input deve funzionare dopo il resume esplicito della scena."
	)
	Input.action_release(&"move_right")
	await _wait_processed_frame()

	await _finish(movement_slice)


func _validate_layout_math() -> void:
	var wide_playfield := ArenaLayout.calculate_playfield_rect(
		Rect2(Vector2.ZERO, Vector2(2000.0, 900.0)),
		16.0 / 9.0
	)
	_expect_rect_near(
		wide_playfield,
		Rect2(Vector2(200.0, 0.0), Vector2(1600.0, 900.0)),
		0.01,
		"Il playfield 20:9 deve restare centrato a 16:9."
	)

	var tablet_playfield := ArenaLayout.calculate_playfield_rect(
		Rect2(Vector2.ZERO, Vector2(960.0, 720.0)),
		16.0 / 9.0
	)
	_expect_rect_near(
		tablet_playfield,
		Rect2(Vector2(0.0, 90.0), Vector2(960.0, 540.0)),
		0.01,
		"Il playfield 4:3 deve restare centrato a 16:9."
	)

	var landscape_viewport := Rect2(Vector2.ZERO, Vector2(1600.0, 720.0))
	var display_cutout_safe := Rect2i(96, 0, 2208, 1080)
	var screen_transform := Transform2D.IDENTITY.scaled(Vector2(1.5, 1.5))
	var expected_safe := Rect2(Vector2(64.0, 0.0), Vector2(1472.0, 720.0))
	var transformed_safe := ArenaLayout.map_display_safe_area_with_screen_transform(
		landscape_viewport,
		display_cutout_safe,
		Vector2i.ZERO,
		Vector2i(2400, 1080),
		screen_transform
	)
	_expect_rect_near(
		transformed_safe,
		expected_safe,
		0.01,
		"Il cutout fisico deve essere mappato tramite screen transform."
	)

	var fallback_safe := ArenaLayout.map_display_safe_area_to_viewport(
		landscape_viewport,
		display_cutout_safe,
		Vector2i.ZERO,
		Vector2i(2400, 1080)
	)
	_expect_rect_near(
		fallback_safe,
		expected_safe,
		0.01,
		"Il fallback lineare deve preservare la stessa safe area."
	)
	var invalid_transform := Transform2D(Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)
	_expect(
		not ArenaLayout.map_display_safe_area_with_screen_transform(
			landscape_viewport,
			display_cutout_safe,
			Vector2i.ZERO,
			Vector2i(2400, 1080),
			invalid_transform
		).has_area(),
		"Una screen transform non invertibile deve richiedere il fallback."
	)

	var joystick_rect: Rect2 = (
		MOVEMENT_SLICE_SCRIPT.calculate_bottom_left_control_rect(
			expected_safe,
			Vector2(224.0, 224.0),
			Vector2(24.0, 24.0),
			Vector2(16.0, 32.0)
		)
	)
	_expect_rect_near(
		joystick_rect,
		Rect2(Vector2(104.0, 440.0), Vector2(224.0, 224.0)),
		0.01,
		"Il joystick deve rispettare safe area e padding anti-gesture."
	)


func _wait_processed_frame() -> void:
	# process_frame precede _process: due emissioni garantiscono un frame completato.
	await process_frame
	await process_frame


func _wait_physics_step() -> void:
	# physics_frame precede _physics_process: due emissioni garantiscono uno step.
	await physics_frame
	await physics_frame


func _touch(
	index: int,
	pressed: bool,
	position: Vector2
) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.pressed = pressed
	event.position = position
	return event


func _expect_vector_near(
	actual: Vector2,
	expected: Vector2,
	tolerance: float,
	message: String
) -> void:
	_expect(
		actual.distance_to(expected) <= tolerance,
		"%s Atteso %s, ottenuto %s." % [message, expected, actual]
	)


func _expect_rect_near(
	actual: Rect2,
	expected: Rect2,
	tolerance: float,
	message: String
) -> void:
	_expect(
		actual.position.distance_to(expected.position) <= tolerance
		and actual.size.distance_to(expected.size) <= tolerance,
		"%s Atteso %s, ottenuto %s." % [message, expected, actual]
	)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _release_actions() -> void:
	for action in MOVE_ACTIONS:
		Input.action_release(action)


func _finish(movement_slice: Control) -> void:
	paused = false
	_release_actions()
	if is_instance_valid(movement_slice):
		movement_slice.queue_free()
	await process_frame

	if _failures.is_empty():
		print("B03_MOVEMENT_SLICE_SMOKE_OK")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	printerr("B03_MOVEMENT_SLICE_SMOKE_FAIL count=%d" % _failures.size())
	quit(1)
