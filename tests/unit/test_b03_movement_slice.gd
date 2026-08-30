extends GutGameplayTest

const MOVEMENT_SLICE_SCRIPT := preload("res://scripts/game/movement_slice.gd")

const MOVE_ACTIONS: Array[StringName] = [
	&"move_left", &"move_right", &"move_up", &"move_down",
]


func test_layout_math() -> void:
	assert_true(
		ArenaLayout.is_transient_portrait_window(Vector2i(1080, 2424), DisplayServer.SCREEN_LANDSCAPE, true),
		"Il passaggio portrait transitorio del lock Android deve conservare il layout landscape stabile."
	)
	assert_true(
		not ArenaLayout.is_transient_portrait_window(Vector2i(2424, 1080), DisplayServer.SCREEN_LANDSCAPE, true),
		"La finestra landscape finale deve aggiornare il layout."
	)
	assert_true(
		not ArenaLayout.is_transient_portrait_window(Vector2i(1080, 2424), DisplayServer.SCREEN_LANDSCAPE, false),
		"Il primo layout non deve restare vuoto anche se Android parte temporaneamente in portrait."
	)

	var wide_playfield := ArenaLayout.calculate_playfield_rect(Rect2(Vector2.ZERO, Vector2(2000.0, 900.0)), 16.0 / 9.0)
	assert_rect_near(
		wide_playfield, Rect2(Vector2(200.0, 0.0), Vector2(1600.0, 900.0)), "Il playfield 20:9 deve restare centrato a 16:9.", 0.01
	)

	var tablet_playfield := ArenaLayout.calculate_playfield_rect(Rect2(Vector2.ZERO, Vector2(960.0, 720.0)), 16.0 / 9.0)
	assert_rect_near(
		tablet_playfield, Rect2(Vector2(0.0, 90.0), Vector2(960.0, 540.0)), "Il playfield 4:3 deve restare centrato a 16:9.", 0.01
	)

	var landscape_viewport := Rect2(Vector2.ZERO, Vector2(1600.0, 720.0))
	var display_cutout_safe := Rect2i(96, 0, 2208, 1080)
	var screen_transform := Transform2D.IDENTITY.scaled(Vector2(1.5, 1.5))
	var expected_safe := Rect2(Vector2(64.0, 0.0), Vector2(1472.0, 720.0))
	var transformed_safe := ArenaLayout.map_display_safe_area_with_screen_transform(
		landscape_viewport, display_cutout_safe, Vector2i.ZERO, Vector2i(2400, 1080), screen_transform
	)
	assert_rect_near(
		transformed_safe, expected_safe, "Il cutout fisico deve essere mappato tramite screen transform.", 0.01
	)

	var fallback_safe := ArenaLayout.map_display_safe_area_to_viewport(
		landscape_viewport, display_cutout_safe, Vector2i.ZERO, Vector2i(2400, 1080)
	)
	assert_rect_near(fallback_safe, expected_safe, "Il fallback lineare deve preservare la stessa safe area.", 0.01)
	var invalid_transform := Transform2D(Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)
	assert_true(
		not ArenaLayout.map_display_safe_area_with_screen_transform(
			landscape_viewport, display_cutout_safe, Vector2i.ZERO, Vector2i(2400, 1080), invalid_transform
		).has_area(),
		"Una screen transform non invertibile deve richiedere il fallback."
	)

	var joystick_rect: Rect2 = MOVEMENT_SLICE_SCRIPT.calculate_bottom_left_control_rect(
		expected_safe, Vector2(224.0, 224.0), Vector2(24.0, 24.0), Vector2(16.0, 32.0)
	)
	assert_rect_near(
		joystick_rect, Rect2(Vector2(104.0, 440.0), Vector2(224.0, 224.0)), "Il joystick deve rispettare safe area e padding anti-gesture.",
		0.01
	)


func test_composed_movement() -> void:
	for action in MOVE_ACTIONS:
		Input.action_release(action)

	var movement_slice := await instantiate_movement_slice()

	var arena := movement_slice.get_node_or_null("ArenaLayout") as ArenaLayout
	var controller := movement_slice.get_node_or_null("RunController") as RunController
	var player := movement_slice.get_node_or_null("World/Player") as Player
	var router := movement_slice.get_node_or_null("InputRouter") as InputRouter
	var lifecycle = movement_slice.get_platform_lifecycle()
	var joystick := movement_slice.get_node_or_null("UI/SafeAreaRoot/TouchJoystick") as TouchJoystick

	assert_true(
		get_tree().root.get_visible_rect().size == Vector2(INITIAL_VIEWPORT_SIZE),
		"Il test deve esercitare una viewport landscape 1280x720."
	)
	assert_true(arena != null, "ArenaLayout deve essere presente nel vertical slice.")
	assert_true(controller != null, "RunController deve essere presente nel vertical slice.")
	assert_true(player != null, "Player deve essere presente nel vertical slice.")
	assert_true(router != null, "InputRouter deve essere presente nel vertical slice.")
	assert_true(lifecycle != null, "PlatformLifecycle deve essere presente nel vertical slice.")
	assert_true(joystick != null, "TouchJoystick deve essere presente nel vertical slice.")
	if arena == null or controller == null or player == null or router == null or lifecycle == null or joystick == null:
		for action in MOVE_ACTIONS:
			Input.action_release(action)
		return

	assert_true(player.get_arena_layout() == arena, "Player deve essere collegato all'ArenaLayout della scena.")
	assert_true(arena.get_playfield_rect().has_area(), "ArenaLayout deve produrre un playfield valido.")
	assert_true(
		movement_slice.get_touch_joystick_viewport_rect().has_area(), "Il joystick deve ricevere un rettangolo valido nella safe area."
	)

	# Input cardinal: il router deve guidare il Player tramite la connessione di scena.
	var start_position := player.global_position
	Input.action_press(&"move_right", 1.0)
	await wait_process_frames(2)
	assert_vector_near(
		router.movement_vector, Vector2.RIGHT, "L'input cardinale destro deve restare unitario.", 0.01
	)
	assert_vector_near(player.movement_input, Vector2.RIGHT, "Il segnale del router deve raggiungere il Player.", 0.01)
	await wait_physics_frames(2)
	assert_true(player.global_position.x > start_position.x, "Il Player deve spostarsi a destra durante i frame fisici.")
	assert_true(
		is_equal_approx(player.global_position.y, start_position.y), "Un input cardinale destro non deve introdurre deriva verticale."
	)
	Input.action_release(&"move_right")
	await wait_process_frames(2)

	# Diagonale piena normalizzata e diagonale analogica graduata.
	Input.action_press(&"move_right", 1.0)
	Input.action_press(&"move_down", 1.0)
	await wait_process_frames(2)
	var full_diagonal := router.movement_vector
	assert_true(is_equal_approx(full_diagonal.length(), 1.0), "La diagonale piena deve essere normalizzata al cerchio unitario.")
	assert_true(
		full_diagonal.x > 0.0 and full_diagonal.y > 0.0, "La diagonale destra/basso deve conservare entrambi gli assi."
	)
	Input.action_release(&"move_right")
	Input.action_release(&"move_down")
	await wait_process_frames(2)

	Input.action_press(&"move_right", 0.65)
	Input.action_press(&"move_down", 0.35)
	await wait_process_frames(2)
	var graded_diagonal := router.movement_vector
	assert_true(
		graded_diagonal.x > graded_diagonal.y and graded_diagonal.y > 0.0, "La diagonale graduata deve conservare il rapporto tra gli assi."
	)
	assert_true(
		graded_diagonal.length() > 0.0 and graded_diagonal.length() < 1.0, "La diagonale graduata non deve essere forzata a piena intensita."
	)
	Input.action_release(&"move_right")
	Input.action_release(&"move_down")
	await wait_process_frames(2)

	# Clamp su entrambi gli estremi, includendo il raggio di collisione. Da
	# B38 il Player e' confinato nel mondo fisso di ArenaWorld, non piu' nel
	# playfield ritagliato sul viewport di ArenaLayout.
	var arena_world := movement_slice.get_arena_world() as ArenaWorld
	assert_true(arena_world != null, "La scena composta deve contenere ArenaWorld.")
	var world_rect := arena_world.get_world_rect() if arena_world != null else Rect2()
	var outside_minimum := world_rect.position - Vector2(500.0, 500.0)
	player.global_position = outside_minimum
	await wait_physics_frames(2)
	assert_vector_near(
		player.global_position,
		ArenaWorld.clamp_circle_center_in_rect(world_rect, outside_minimum, player.collision_radius),
		"Il Player deve essere confinato all'estremo minimo dell'arena.", 0.01
	)

	var outside_maximum := world_rect.end + Vector2(500.0, 500.0)
	player.global_position = outside_maximum
	await wait_physics_frames(2)
	assert_vector_near(
		player.global_position,
		ArenaWorld.clamp_circle_center_in_rect(world_rect, outside_maximum, player.collision_radius),
		"Il Player deve essere confinato all'estremo massimo dell'arena.", 0.01
	)
	player.global_position = arena_world.get_world_center()

	# Dispatch diretto: testa ownership senza dipendere dall'hit-testing headless.
	joystick.show()
	var joystick_center := joystick.size * 0.5
	var right_edge := joystick_center + Vector2.RIGHT * joystick.base_radius
	var left_edge := joystick_center + Vector2.LEFT * joystick.base_radius
	joystick._gui_input(make_touch_event(21, true, right_edge))
	assert_eq(joystick.active_finger_index, 21, "Il primo dito deve possedere il joystick.")
	assert_true(router.movement_vector.x > 0.99, "Il touch destro deve attraversare il router della scena.")
	assert_true(player.movement_input.x > 0.99, "Il touch deve raggiungere il Player tramite il wiring del vertical slice.")

	joystick._gui_input(make_touch_event(22, true, left_edge))
	assert_eq(joystick.active_finger_index, 21, "Un secondo dito non deve sottrarre l'ownership del joystick.")
	assert_true(router.movement_vector.x > 0.99, "Il secondo dito non deve alterare il vettore del proprietario.")
	joystick._gui_input(make_touch_event(22, false, left_edge))
	assert_true(joystick.is_active(), "Il rilascio di un dito estraneo va ignorato.")
	joystick._gui_input(make_touch_event(21, false, right_edge))
	assert_true(not joystick.is_active(), "Il rilascio del proprietario deve liberare il joystick.")
	assert_vector_near(
		router.movement_vector, Vector2.ZERO, "Il rilascio touch senza altre sorgenti deve azzerare il router.", 0.001
	)

	# La pausa deve resettare ownership e movimento anche con nodi always-process.
	joystick._gui_input(make_touch_event(31, true, right_edge))
	get_tree().paused = true
	await wait_process_frames(2)
	assert_true(not joystick.is_active(), "La pausa deve rilasciare il dito catturato.")
	assert_vector_near(router.movement_vector, Vector2.ZERO, "La pausa deve sospendere il router.", 0.001)
	assert_vector_near(player.movement_input, Vector2.ZERO, "La sospensione del router deve azzerare il Player.", 0.001)
	get_tree().paused = false
	assert_true(router.resume_input(), "Fuori pausa il router deve accettare il rearm.")
	await wait_process_frames(2)
	assert_true(not router.is_input_suspended(), "Il neutro deve completare il rearm post-pausa.")

	# Focus gate: un input held resta bloccato fino al ritorno esplicito al neutro.
	Input.action_press(&"move_left", 1.0)
	await wait_process_frames(2)
	assert_true(router.movement_vector.x < -0.99, "Il precondition focus deve essere attivo.")
	router.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_true(router.is_input_suspended(), "Focus out deve chiudere il gate input.")
	assert_vector_near(player.movement_input, Vector2.ZERO, "Focus out deve azzerare il Player tramite il router.", 0.001)
	assert_true(not router.resume_input(), "Il router non deve riarmarsi finche l'app non ha focus.")
	router.notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	assert_true(router.resume_input(), "Focus in deve consentire una richiesta di rearm.")
	await wait_process_frames(2)
	assert_true(
		router.is_input_suspended() and router.movement_vector == Vector2.ZERO,
		"Un input held non deve attraversare il focus gate dopo il resume."
	)
	Input.action_release(&"move_left")
	await wait_process_frames(2)
	assert_true(not router.is_input_suspended(), "Il ritorno al neutro deve completare il rearm del focus gate.")
	Input.action_press(&"move_left", 1.0)
	await wait_process_frames(2)
	assert_true(router.movement_vector.x < -0.99, "Solo un nuovo input dopo il neutro deve superare il focus gate.")
	Input.action_release(&"move_left")
	await wait_process_frames(2)

	# L'ordine parent-before-child non deve riaprire la run al focus-in.
	router.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	lifecycle.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	movement_slice.notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	lifecycle.notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	router.notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	await wait_process_frames(2)
	assert_true(
		controller.get_state() == RunController.RunState.MANUAL_PAUSE and router.is_input_suspended(),
		"Il focus-in parent-before-child deve lasciare run e input sospesi."
	)
	assert_true(lifecycle.request_resume(), "Una conferma esplicita deve riprendere dopo tutte le notifiche di focus.")
	await wait_process_frames(2)
	assert_true(not router.is_input_suspended(), "Il neutro deve completare il resume esplicito.")
	Input.action_press(&"move_right", 1.0)
	await wait_process_frames(2)
	assert_true(router.movement_vector.x > 0.99, "Un nuovo input deve funzionare dopo il resume esplicito della scena.")
	Input.action_release(&"move_right")
	await wait_process_frames(2)

	for action in MOVE_ACTIONS:
		Input.action_release(action)
