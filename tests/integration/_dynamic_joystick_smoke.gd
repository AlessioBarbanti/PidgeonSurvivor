extends SceneTree

const MOVEMENT_SLICE_SCENE := preload("res://scenes/game/movement_slice.tscn")
const INITIAL_VIEWPORT_SIZE := Vector2i(1280, 720)
const FLOAT_TOLERANCE := 0.02

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.content_scale_size = INITIAL_VIEWPORT_SIZE
	root.size = INITIAL_VIEWPORT_SIZE
	await _wait_processed_frame()

	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	root.add_child(movement_slice)
	await _wait_processed_frame()

	var controller := movement_slice.get_run_controller() as RunController
	var lifecycle := movement_slice.get_platform_lifecycle() as PlatformLifecycle
	var joystick := (
		movement_slice.get_node_or_null("UI/SafeAreaRoot/TouchJoystick")
		as TouchJoystick
	)
	var router := movement_slice.get_node_or_null("InputRouter") as InputRouter
	var player := movement_slice.get_player() as Player
	var ability := movement_slice.get_ability_controller() as AbilityController
	var hud := movement_slice.get_hud() as GameHud

	_expect(controller != null, "B18L richiede RunController.")
	_expect(lifecycle != null, "B18L richiede PlatformLifecycle.")
	_expect(joystick != null, "B18L richiede TouchJoystick.")
	_expect(router != null, "B18L richiede InputRouter.")
	_expect(player != null, "B18L richiede Player.")
	_expect(ability != null, "B18L richiede AbilityController.")
	_expect(hud != null, "B18L richiede GameHud.")
	if (
		controller == null
		or lifecycle == null
		or joystick == null
		or router == null
		or player == null
		or ability == null
		or hud == null
	):
		await _finish(movement_slice, controller)
		return

	controller.set_process(false)
	player.set_physics_process(false)
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	if spawner != null:
		spawner.set_process(false)
	var weapon := movement_slice.get_weapon_controller() as WeaponController
	if weapon != null:
		weapon.set_process(false)

	_expect(joystick.dynamic_origin, "La scena B18L deve usare un'origine dinamica.")
	_expect(joystick.is_capture_enabled(), "RUNNING deve abilitare la cattura dinamica.")
	_expect(not joystick.is_visual_visible(), "Il joystick deve essere invisibile al neutro.")
	_expect(
		joystick.mouse_filter == Control.MOUSE_FILTER_IGNORE,
		"Il Control dinamico non deve intercettare il secondo dito."
	)
	var capture_rect: Rect2 = movement_slice.get_touch_joystick_capture_rect()
	_expect(capture_rect.has_area(), "La safe area deve produrre una zona touch valida.")
	_expect(
		capture_rect.size.x > joystick.size.x,
		"B18L deve acquisire il primo tocco oltre la vecchia zona fissa."
	)
	await _validate_layout_profiles(movement_slice, joystick, hud)
	capture_rect = movement_slice.get_touch_joystick_capture_rect()
	var edge_origin := capture_rect.position + Vector2(2.0, capture_rect.size.y - 2.0)
	joystick._input(_touch(42, true, edge_origin))
	_expect(
		joystick.active_finger_index == 42,
		"La fascia gameplay vicina al bordo deve creare il joystick."
	)
	joystick._input(_touch(42, false, edge_origin))

	var hud_position := hud.get_top_band_rect().get_center()
	joystick._input(_touch(40, true, hud_position))
	_expect(not joystick.is_active(), "Un tocco iniziato sopra l'HUD va ignorato.")
	var ability_position := hud.get_active_ability_button_rect().get_center()
	joystick._input(_touch(41, true, ability_position))
	_expect(not joystick.is_active(), "Il pulsante abilita non deve creare il joystick.")

	var first_origin: Vector2 = capture_rect.get_center() + Vector2(-150.0, 80.0)
	joystick._input(_touch(1, true, first_origin))
	_expect(joystick.active_finger_index == 1, "Il primo tocco valido deve possedere il joystick.")
	_expect(joystick.is_visual_visible(), "Il joystick deve comparire al primo tocco valido.")
	_expect_vector_near(
		joystick.get_origin_viewport_position(),
		first_origin,
		"L'origine visiva deve coincidere con il primo tocco."
	)
	_expect_vector_near(joystick.movement_vector, Vector2.ZERO, "Il tocco iniziale deve essere neutro.")

	var right_position: Vector2 = first_origin + Vector2.RIGHT * joystick.base_radius
	joystick._input(_drag(1, right_position))
	_expect_vector_near(joystick.movement_vector, Vector2.RIGHT, "Il drag deve usare l'origine fotografata.")
	_expect_vector_near(router.movement_vector, Vector2.RIGHT, "Il router deve ricevere il floating joystick.")
	_expect_vector_near(player.movement_input, Vector2.RIGHT, "Il Player deve ricevere il vettore B18L.")

	joystick._input(_touch(2, true, capture_rect.get_center()))
	joystick._input(_drag(2, first_origin + Vector2.UP * joystick.base_radius))
	_expect(joystick.active_finger_index == 1, "Il secondo dito non deve rubare l'ownership.")
	_expect_vector_near(joystick.movement_vector, Vector2.RIGHT, "Il secondo dito non deve cambiare direzione.")

	await _dispatch_touch_tap(2, ability_position)
	_expect(ability.get_cooldown_remaining() > 0.0, "Il secondo dito deve attivare l'abilita.")
	_expect(joystick.active_finger_index == 1, "L'abilita non deve liberare il joystick.")
	joystick._input(_touch(2, false, ability_position))
	_expect(joystick.is_active(), "Il rilascio di un dito estraneo va ignorato.")
	joystick._input(_touch(1, false, right_position))
	_expect(not joystick.is_active(), "Il rilascio del proprietario deve chiudere il joystick.")
	_expect(not joystick.is_visual_visible(), "Il joystick deve sparire al rilascio.")
	_expect_vector_near(router.movement_vector, Vector2.ZERO, "Il rilascio deve azzerare il router.")

	var second_origin: Vector2 = capture_rect.get_center() + Vector2(180.0, 40.0)
	joystick._input(_touch(3, true, second_origin))
	_expect_vector_near(
		joystick.get_origin_viewport_position(),
		second_origin,
		"Il tocco successivo deve ricreare il joystick nella nuova origine."
	)
	_expect(lifecycle.request_manual_pause(), "B18L deve entrare in pausa manuale.")
	_expect(not joystick.is_active(), "La pausa deve rilasciare l'ownership.")
	_expect(not joystick.is_capture_enabled(), "La pausa deve disabilitare la cattura.")
	joystick._input(_touch(4, true, first_origin))
	_expect(not joystick.is_active(), "L'overlay di pausa deve escludere nuovi tocchi.")
	_expect(lifecycle.request_resume(), "B18L deve riprendere solo esplicitamente.")
	_expect(joystick.is_capture_enabled(), "Il resume esplicito deve riabilitare la cattura.")

	joystick._input(_touch(5, true, first_origin))
	_expect(joystick.is_active(), "Il joystick deve riarmarsi da neutro dopo il resume.")
	lifecycle.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	_expect(not joystick.is_active(), "Il focus loss deve azzerare il joystick.")
	_expect(not joystick.is_capture_enabled(), "Il focus loss deve chiudere la cattura.")
	lifecycle.notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	_expect(lifecycle.request_resume(), "Dopo il focus serve una ripresa esplicita.")

	joystick._input(_touch(6, true, second_origin))
	var canceled := _touch(6, false, second_origin)
	canceled.canceled = true
	joystick._input(canceled)
	_expect(not joystick.is_active(), "Un touch cancellato deve liberare l'ownership.")

	joystick._input(_touch(7, true, first_origin))
	_expect(controller.request_defeat(), "La fixture B18L deve raggiungere un terminale.")
	_expect(not joystick.is_active(), "Il terminale deve pulire il joystick.")
	_expect(not joystick.is_capture_enabled(), "Il terminale deve bloccare la cattura.")
	_expect(movement_slice.restart_run(1812), "Il restart B18L deve riuscire.")
	_expect(joystick.is_capture_enabled(), "La nuova run deve riabilitare il joystick.")
	_expect(not joystick.is_visual_visible(), "Il restart deve ripartire senza residui visivi.")
	joystick._input(_touch(8, true, second_origin))
	_expect(joystick.active_finger_index == 8, "La nuova run deve accettare un nuovo proprietario.")
	joystick._input(_touch(8, false, second_origin))

	await _finish(movement_slice, controller)


func _validate_layout_profiles(
	movement_slice: Control,
	joystick: TouchJoystick,
	hud: GameHud
) -> void:
	for profile in [Vector2i(1280, 720), Vector2i(1600, 720), Vector2i(960, 720)]:
		root.content_scale_size = profile
		root.size = profile
		await _wait_processed_frame()
		var capture_rect: Rect2 = movement_slice.get_touch_joystick_capture_rect()
		var arena := movement_slice.get_node_or_null("ArenaLayout") as ArenaLayout
		var safe_area := arena.get_safe_area_rect() if arena != null else Rect2()
		_expect(capture_rect.has_area(), "%s deve conservare una zona dinamica valida." % profile)
		_expect(
			safe_area.encloses(capture_rect),
			"%s deve mantenere l'origine nella safe area." % profile
		)
		_expect(
			joystick.accepts_origin(capture_rect.get_center()),
			"%s deve accettare un tocco gameplay centrale." % profile
		)
		_expect(
			not joystick.accepts_origin(hud.get_top_band_rect().get_center()),
			"%s deve escludere la fascia HUD." % profile
		)
		_expect(
			not joystick.accepts_origin(hud.get_active_ability_button_rect().get_center()),
			"%s deve lasciare libero il pulsante abilita." % profile
		)
	root.content_scale_size = INITIAL_VIEWPORT_SIZE
	root.size = INITIAL_VIEWPORT_SIZE
	await _wait_processed_frame()


func _dispatch_touch_tap(index: int, position: Vector2) -> void:
	Input.parse_input_event(_touch(index, true, position))
	await process_frame
	Input.parse_input_event(_touch(index, false, position))
	await process_frame


func _touch(index: int, pressed: bool, position: Vector2) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.pressed = pressed
	event.position = position
	return event


func _drag(index: int, position: Vector2) -> InputEventScreenDrag:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = position
	return event


func _expect_vector_near(actual: Vector2, expected: Vector2, message: String) -> void:
	_expect(
		actual.distance_to(expected) <= FLOAT_TOLERANCE,
		"%s Atteso %s, ottenuto %s." % [message, expected, actual]
	)


func _wait_processed_frame() -> void:
	await process_frame
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish(movement_slice: Node, controller: RunController) -> void:
	if is_instance_valid(controller) and controller.is_running():
		controller.request_defeat()
	if is_instance_valid(controller):
		controller.prepare_restart()
	paused = false
	if is_instance_valid(movement_slice):
		movement_slice.queue_free()
	await process_frame
	if _failures.is_empty():
		print("B18L_DYNAMIC_JOYSTICK_SMOKE_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	printerr("B18L_DYNAMIC_JOYSTICK_SMOKE_FAIL count=%d" % _failures.size())
	quit(1)
