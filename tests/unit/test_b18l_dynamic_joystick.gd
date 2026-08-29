extends GutGameplayTest

const JOYSTICK_POSITION_TOLERANCE := 0.02
const LAYOUT_PROFILES: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 720),
	Vector2i(960, 720),
]


func test_dynamic_joystick_contract() -> void:
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_run_controller() as RunController
	var lifecycle := movement_slice.get_platform_lifecycle() as PlatformLifecycle
	var joystick := movement_slice.get_node_or_null("UI/SafeAreaRoot/TouchJoystick") as TouchJoystick
	var router := movement_slice.get_node_or_null("InputRouter") as InputRouter
	var player := movement_slice.get_player() as Player
	var ability := movement_slice.get_ability_controller() as AbilityController
	var hud := movement_slice.get_hud() as GameHud

	assert_not_null(controller, "B18L richiede RunController.")
	assert_not_null(lifecycle, "B18L richiede PlatformLifecycle.")
	assert_not_null(joystick, "B18L richiede TouchJoystick.")
	assert_not_null(router, "B18L richiede InputRouter.")
	assert_not_null(player, "B18L richiede Player.")
	assert_not_null(ability, "B18L richiede AbilityController.")
	assert_not_null(hud, "B18L richiede GameHud.")
	if (
		controller == null
		or lifecycle == null
		or joystick == null
		or router == null
		or player == null
		or ability == null
		or hud == null
	):
		if is_instance_valid(controller) and controller.is_running():
			controller.request_defeat()
		if is_instance_valid(controller):
			controller.prepare_restart()
		return

	controller.set_process(false)
	player.set_physics_process(false)
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	if spawner != null:
		spawner.set_process(false)
	var weapon := movement_slice.get_weapon_controller() as WeaponController
	if weapon != null:
		weapon.set_process(false)

	assert_true(joystick.dynamic_origin, "La scena B18L deve usare un'origine dinamica.")
	assert_true(joystick.is_capture_enabled(), "RUNNING deve abilitare la cattura dinamica.")
	assert_false(joystick.is_visual_visible(), "Il joystick deve essere invisibile al neutro.")
	assert_eq(
		joystick.mouse_filter, Control.MOUSE_FILTER_IGNORE,
		"Il Control dinamico non deve intercettare il secondo dito."
	)
	var capture_rect: Rect2 = movement_slice.get_touch_joystick_capture_rect()
	assert_true(capture_rect.has_area(), "La safe area deve produrre una zona touch valida.")
	assert_true(
		capture_rect.size.x > joystick.size.x,
		"B18L deve acquisire il primo tocco oltre la vecchia zona fissa."
	)
	await _validate_layout_profiles(movement_slice, joystick, hud)
	capture_rect = movement_slice.get_touch_joystick_capture_rect()
	var edge_origin := capture_rect.position + Vector2(2.0, capture_rect.size.y - 2.0)
	joystick._input(make_touch_event(42, true, edge_origin))
	assert_eq(
		joystick.active_finger_index, 42, "La fascia gameplay vicina al bordo deve creare il joystick."
	)
	joystick._input(make_touch_event(42, false, edge_origin))

	var hud_position := hud.get_top_band_rect().get_center()
	joystick._input(make_touch_event(40, true, hud_position))
	assert_false(joystick.is_active(), "Un tocco iniziato sopra l'HUD va ignorato.")
	var ability_position := hud.get_active_ability_button_rect().get_center()
	joystick._input(make_touch_event(41, true, ability_position))
	assert_false(joystick.is_active(), "Il pulsante abilita non deve creare il joystick.")

	var first_origin: Vector2 = capture_rect.get_center() + Vector2(-150.0, 80.0)
	joystick._input(make_touch_event(1, true, first_origin))
	assert_eq(joystick.active_finger_index, 1, "Il primo tocco valido deve possedere il joystick.")
	assert_true(joystick.is_visual_visible(), "Il joystick deve comparire al primo tocco valido.")
	assert_vector_near(
		joystick.get_origin_viewport_position(), first_origin,
		"L'origine visiva deve coincidere con il primo tocco.", JOYSTICK_POSITION_TOLERANCE
	)
	assert_vector_near(
		joystick.movement_vector, Vector2.ZERO, "Il tocco iniziale deve essere neutro.", JOYSTICK_POSITION_TOLERANCE
	)

	var right_position: Vector2 = first_origin + Vector2.RIGHT * joystick.base_radius
	joystick._input(make_drag_event(1, right_position, Vector2.ZERO))
	assert_vector_near(
		joystick.movement_vector, Vector2.RIGHT, "Il drag deve usare l'origine fotografata.",
		JOYSTICK_POSITION_TOLERANCE
	)
	assert_vector_near(
		router.movement_vector, Vector2.RIGHT, "Il router deve ricevere il floating joystick.",
		JOYSTICK_POSITION_TOLERANCE
	)
	assert_vector_near(
		player.movement_input, Vector2.RIGHT, "Il Player deve ricevere il vettore B18L.",
		JOYSTICK_POSITION_TOLERANCE
	)

	joystick._input(make_touch_event(2, true, capture_rect.get_center()))
	joystick._input(make_drag_event(2, first_origin + Vector2.UP * joystick.base_radius, Vector2.ZERO))
	assert_eq(joystick.active_finger_index, 1, "Il secondo dito non deve rubare l'ownership.")
	assert_vector_near(
		joystick.movement_vector, Vector2.RIGHT, "Il secondo dito non deve cambiare direzione.",
		JOYSTICK_POSITION_TOLERANCE
	)

	await _dispatch_touch_tap(2, ability_position)
	assert_true(ability.get_cooldown_remaining() > 0.0, "Il secondo dito deve attivare l'abilita.")
	assert_eq(joystick.active_finger_index, 1, "L'abilita non deve liberare il joystick.")
	joystick._input(make_touch_event(2, false, ability_position))
	assert_true(joystick.is_active(), "Il rilascio di un dito estraneo va ignorato.")
	joystick._input(make_touch_event(1, false, right_position))
	assert_false(joystick.is_active(), "Il rilascio del proprietario deve chiudere il joystick.")
	assert_false(joystick.is_visual_visible(), "Il joystick deve sparire al rilascio.")
	assert_vector_near(
		router.movement_vector, Vector2.ZERO, "Il rilascio deve azzerare il router.", JOYSTICK_POSITION_TOLERANCE
	)

	var second_origin: Vector2 = capture_rect.get_center() + Vector2(180.0, 40.0)
	joystick._input(make_touch_event(3, true, second_origin))
	assert_vector_near(
		joystick.get_origin_viewport_position(), second_origin,
		"Il tocco successivo deve ricreare il joystick nella nuova origine.", JOYSTICK_POSITION_TOLERANCE
	)
	assert_true(lifecycle.request_manual_pause(), "B18L deve entrare in pausa manuale.")
	assert_false(joystick.is_active(), "La pausa deve rilasciare l'ownership.")
	assert_false(joystick.is_capture_enabled(), "La pausa deve disabilitare la cattura.")
	joystick._input(make_touch_event(4, true, first_origin))
	assert_false(joystick.is_active(), "L'overlay di pausa deve escludere nuovi tocchi.")
	assert_true(lifecycle.request_resume(), "B18L deve riprendere solo esplicitamente.")
	assert_true(joystick.is_capture_enabled(), "Il resume esplicito deve riabilitare la cattura.")

	joystick._input(make_touch_event(5, true, first_origin))
	assert_true(joystick.is_active(), "Il joystick deve riarmarsi da neutro dopo il resume.")
	lifecycle.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_false(joystick.is_active(), "Il focus loss deve azzerare il joystick.")
	assert_false(joystick.is_capture_enabled(), "Il focus loss deve chiudere la cattura.")
	lifecycle.notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	assert_true(lifecycle.request_resume(), "Dopo il focus serve una ripresa esplicita.")

	joystick._input(make_touch_event(6, true, second_origin))
	var canceled := make_touch_event(6, false, second_origin)
	canceled.canceled = true
	joystick._input(canceled)
	assert_false(joystick.is_active(), "Un touch cancellato deve liberare l'ownership.")

	joystick._input(make_touch_event(7, true, first_origin))
	assert_true(controller.request_defeat(), "La fixture B18L deve raggiungere un terminale.")
	assert_false(joystick.is_active(), "Il terminale deve pulire il joystick.")
	assert_false(joystick.is_capture_enabled(), "Il terminale deve bloccare la cattura.")
	assert_true(movement_slice.restart_run(1812), "Il restart B18L deve riuscire.")
	assert_true(joystick.is_capture_enabled(), "La nuova run deve riabilitare il joystick.")
	assert_false(joystick.is_visual_visible(), "Il restart deve ripartire senza residui visivi.")
	joystick._input(make_touch_event(8, true, second_origin))
	assert_eq(joystick.active_finger_index, 8, "La nuova run deve accettare un nuovo proprietario.")
	joystick._input(make_touch_event(8, false, second_origin))

	if is_instance_valid(controller) and controller.is_running():
		controller.request_defeat()
	if is_instance_valid(controller):
		controller.prepare_restart()


func _validate_layout_profiles(movement_slice: Control, joystick: TouchJoystick, hud: GameHud) -> void:
	for profile in LAYOUT_PROFILES:
		get_tree().root.content_scale_size = profile
		get_tree().root.size = profile
		await wait_process_frames(2)
		var capture_rect: Rect2 = movement_slice.get_touch_joystick_capture_rect()
		var arena := movement_slice.get_node_or_null("ArenaLayout") as ArenaLayout
		var safe_area := arena.get_safe_area_rect() if arena != null else Rect2()
		assert_true(capture_rect.has_area(), "%s deve conservare una zona dinamica valida." % profile)
		assert_true(
			safe_area.encloses(capture_rect), "%s deve mantenere l'origine nella safe area." % profile
		)
		assert_true(
			joystick.accepts_origin(capture_rect.get_center()),
			"%s deve accettare un tocco gameplay centrale." % profile
		)
		assert_false(
			joystick.accepts_origin(hud.get_top_band_rect().get_center()),
			"%s deve escludere la fascia HUD." % profile
		)
		assert_false(
			joystick.accepts_origin(hud.get_active_ability_button_rect().get_center()),
			"%s deve lasciare libero il pulsante abilita." % profile
		)
	get_tree().root.content_scale_size = LAYOUT_PROFILES[0]
	get_tree().root.size = LAYOUT_PROFILES[0]
	await wait_process_frames(2)


func _dispatch_touch_tap(index: int, position: Vector2) -> void:
	Input.parse_input_event(make_touch_event(index, true, position))
	await wait_process_frames(1)
	Input.parse_input_event(make_touch_event(index, false, position))
	await wait_process_frames(1)
