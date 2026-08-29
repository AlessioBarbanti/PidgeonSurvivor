extends GutGameplayTest

const TEST_SETTINGS_PATH := "user://b18p_touch_control_settings_gut.cfg"
const TOUCH_SETTINGS_FLOAT_TOLERANCE := 0.05
const LAYOUT_PROFILES := [
	Vector2i(1280, 720),
	Vector2i(1600, 720),
	Vector2i(960, 720),
]
const SUPPORTED_SCALE_PAIRS := [
	Vector2(1.0, 0.85),
	Vector2(1.25, 1.0),
	Vector2(1.5, 1.15),
]


func test_touch_control_settings() -> void:
	_remove_test_settings()
	_write_invalid_settings()
	ProjectSettings.set_setting("application/run/b18o_force_welcome_for_test", true)
	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	var settings := movement_slice.get_node("TouchControlSettings") as TouchControlSettings
	settings.settings_path = TEST_SETTINGS_PATH
	add_child_autofree(movement_slice)
	ProjectSettings.set_setting("application/run/b18o_force_welcome_for_test", false)
	await wait_process_frames(2)

	var controller := movement_slice.get_run_controller() as RunController
	var welcome := movement_slice.get_welcome_screen() as WelcomeScreen
	var pause_overlay := movement_slice.get_pause_overlay() as PauseOverlay
	var hud := movement_slice.get_hud() as GameHud
	var joystick := movement_slice.get_node("UI/SafeAreaRoot/TouchJoystick") as TouchJoystick
	var ability := movement_slice.get_ability_controller() as AbilityController
	assert_true(settings != null, "B18P richiede TouchControlSettings.")
	assert_true(welcome != null and pause_overlay != null, "B18P richiede impostazioni da welcome e pausa.")
	assert_true(hud != null and joystick != null and ability != null, "B18P richiede entrambi i controlli runtime.")
	if (
		settings == null
		or controller == null
		or welcome == null
		or pause_overlay == null
		or hud == null
		or joystick == null
		or ability == null
	):
		_remove_test_settings()
		return

	_assert_loaded_clamp(settings, hud, joystick)
	await _assert_welcome_preview(welcome, pause_overlay, settings, hud, joystick)
	await _assert_layout_profiles(movement_slice, welcome, hud, joystick, settings)

	assert_true(movement_slice.select_friend_for_next_run(&"magno"), "La fixture B18P deve selezionare Magno.")
	assert_true(movement_slice.start_selected_run(1816), "La fixture B18P deve avviare la run.")
	await wait_process_frames(2)
	controller.set_process(false)
	ability.set_process(false)
	var player := movement_slice.get_player() as Player
	if player != null:
		player.set_physics_process(false)
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	if spawner != null:
		spawner.set_process(false)
	var weapon := movement_slice.get_weapon_controller() as WeaponController
	if weapon != null:
		weapon.set_process(false)

	await _assert_supported_multitouch_scales(movement_slice, settings, hud, joystick, ability)
	await _assert_pause_preview(controller, pause_overlay, settings, hud, joystick)
	_assert_persistence(settings)

	if is_instance_valid(controller):
		controller.prepare_restart()
	_remove_test_settings()


func _assert_loaded_clamp(settings: TouchControlSettings, hud: GameHud, joystick: TouchJoystick) -> void:
	assert_almost_eq(
		TouchControlSettings.sanitize_ability_scale(1.11), TouchControlSettings.MIN_ABILITY_SCALE,
		TOUCH_SETTINGS_FLOAT_TOLERANCE, "Una scala abilita intermedia deve convergere a una taglia supportata."
	)
	assert_almost_eq(
		TouchControlSettings.sanitize_joystick_scale(0.93), TouchControlSettings.DEFAULT_JOYSTICK_SCALE,
		TOUCH_SETTINGS_FLOAT_TOLERANCE, "Una scala joystick intermedia deve convergere a una taglia supportata."
	)
	assert_almost_eq(
		settings.get_ability_scale(), TouchControlSettings.MAX_ABILITY_SCALE, TOUCH_SETTINGS_FLOAT_TOLERANCE,
		"Un valore abilita fuori range deve essere clampato al massimo."
	)
	assert_almost_eq(
		settings.get_joystick_scale(), TouchControlSettings.MIN_JOYSTICK_SCALE, TOUCH_SETTINGS_FLOAT_TOLERANCE,
		"Un valore joystick fuori range deve essere clampato al minimo."
	)
	var button := hud.get_active_ability_button()
	assert_almost_eq(
		button.size.x, TouchAbilityButton.BASE_TARGET_SIZE * TouchControlSettings.MAX_ABILITY_SCALE,
		TOUCH_SETTINGS_FLOAT_TOLERANCE, "Il clamp deve applicarsi subito al target abilita."
	)
	assert_true(
		button.get_icon_max_width() == roundi(TouchAbilityButton.BASE_ICON_WIDTH * TouchControlSettings.MAX_ABILITY_SCALE),
		"Icona e hit target devono crescere insieme."
	)
	_assert_joystick_geometry(joystick, TouchControlSettings.MIN_JOYSTICK_SCALE)


func _assert_welcome_preview(
	welcome: WelcomeScreen, pause_overlay: PauseOverlay, settings: TouchControlSettings, hud: GameHud, joystick: TouchJoystick
) -> void:
	var settings_button := welcome.get_settings_button()
	assert_true(settings_button != null, "La welcome B18P deve esporre IMPOSTAZIONI.")
	if settings_button == null:
		return
	settings_button.pressed.emit()
	await wait_process_frames(2)
	var ability_slider := welcome.get_ability_size_slider()
	var joystick_slider := welcome.get_joystick_size_slider()
	assert_true(ability_slider != null and joystick_slider != null, "La welcome deve esporre due scale indipendenti.")
	if ability_slider == null or joystick_slider == null:
		return
	ability_slider.value = TouchControlSettings.MIN_ABILITY_SCALE
	joystick_slider.value = TouchControlSettings.MAX_JOYSTICK_SCALE
	await wait_process_frames(2)
	assert_almost_eq(
		settings.get_ability_scale(), 1.0, TOUCH_SETTINGS_FLOAT_TOLERANCE, "La welcome deve applicare subito la scala abilita."
	)
	assert_almost_eq(
		settings.get_joystick_scale(), 1.15, TOUCH_SETTINGS_FLOAT_TOLERANCE, "La welcome deve applicare subito la scala joystick."
	)
	assert_almost_eq(
		hud.get_active_ability_button_rect().size.x, TouchAbilityButton.BASE_TARGET_SIZE, TOUCH_SETTINGS_FLOAT_TOLERANCE,
		"La preview welcome deve aggiornare il target raddoppiato."
	)
	_assert_joystick_geometry(joystick, 1.15)
	assert_almost_eq(
		pause_overlay.get_ability_size_slider().value, 1.0, TOUCH_SETTINGS_FLOAT_TOLERANCE,
		"Welcome e pausa devono restare sincronizzate."
	)
	assert_almost_eq(
		pause_overlay.get_joystick_size_slider().value, 1.15, TOUCH_SETTINGS_FLOAT_TOLERANCE,
		"La scala joystick deve sincronizzarsi con la pausa."
	)


func _assert_layout_profiles(
	movement_slice: Control, welcome: WelcomeScreen, hud: GameHud, joystick: TouchJoystick, settings: TouchControlSettings
) -> void:
	settings.set_ability_scale(TouchControlSettings.MAX_ABILITY_SCALE, false)
	settings.set_joystick_scale(TouchControlSettings.MAX_JOYSTICK_SCALE, false)
	var reference_capture_rect: Rect2 = movement_slice.get_touch_joystick_capture_rect()
	for profile in LAYOUT_PROFILES:
		get_tree().root.content_scale_size = profile
		get_tree().root.size = profile
		await wait_process_frames(2)
		var arena := movement_slice.get_node("ArenaLayout") as ArenaLayout
		arena.refresh_layout()
		await wait_process_frames(2)
		var safe_area := arena.get_safe_area_rect()
		var ability_rect := hud.get_active_ability_button_rect()
		var capture_rect: Rect2 = movement_slice.get_touch_joystick_capture_rect()
		assert_true(safe_area.encloses(ability_rect), "%s: l'abilita massima deve restare nella safe area." % profile)
		assert_true(
			safe_area.end.x - ability_rect.end.x >= (
				movement_slice.hud_control_edge_padding.x + movement_slice.gesture_navigation_padding.x
				- TOUCH_SETTINGS_FLOAT_TOLERANCE
			)
			and safe_area.end.y - ability_rect.end.y >= (
				movement_slice.hud_control_edge_padding.y + movement_slice.gesture_navigation_padding.y
				- TOUCH_SETTINGS_FLOAT_TOLERANCE
			),
			"%s: l'abilita deve sommare inset esterno B31 e margine anti-gesture." % profile
		)
		var pause_rect := hud.get_pause_button_rect()
		assert_true(
			pause_rect.size.x >= 48.0 - TOUCH_SETTINGS_FLOAT_TOLERANCE and pause_rect.size.y >= 48.0 - TOUCH_SETTINGS_FLOAT_TOLERANCE,
			"%s: B31 non deve ridurre il target pausa." % profile
		)
		assert_true(
			safe_area.end.x - pause_rect.end.x >= movement_slice.hud_control_edge_padding.x - TOUCH_SETTINGS_FLOAT_TOLERANCE
			and pause_rect.position.y - safe_area.position.y
			>= movement_slice.hud_control_edge_padding.y - TOUCH_SETTINGS_FLOAT_TOLERANCE,
			"%s: la pausa deve usare l'inset esterno B31." % profile
		)
		assert_true(
			not ability_rect.intersects(hud.get_top_band_rect()), "%s: l'abilita non deve sovrapporre l'HUD alto." % profile
		)
		assert_true(safe_area.encloses(capture_rect), "%s: l'acquisizione joystick deve restare nella safe area." % profile)
		settings.set_joystick_scale(TouchControlSettings.MIN_JOYSTICK_SCALE, false)
		await wait_process_frames(2)
		var compact_capture_rect: Rect2 = movement_slice.get_touch_joystick_capture_rect()
		assert_true(
			compact_capture_rect.position.distance_to(capture_rect.position) <= TOUCH_SETTINGS_FLOAT_TOLERANCE
			and compact_capture_rect.size.distance_to(capture_rect.size) <= TOUCH_SETTINGS_FLOAT_TOLERANCE,
			"%s: la scala non deve restringere l'acquisizione dinamica." % profile
		)
		settings.set_joystick_scale(TouchControlSettings.MAX_JOYSTICK_SCALE, false)
		await wait_process_frames(2)
		assert_true(
			safe_area.encloses(welcome.get_actions_frame_rect()),
			"%s: le impostazioni welcome devono restare nella safe area." % profile
		)
	get_tree().root.content_scale_size = INITIAL_VIEWPORT_SIZE
	get_tree().root.size = INITIAL_VIEWPORT_SIZE
	await wait_process_frames(2)
	assert_true(reference_capture_rect.has_area(), "La matrice B18P deve partire da una zona dinamica valida.")


func _assert_supported_multitouch_scales(
	movement_slice: Control, settings: TouchControlSettings, hud: GameHud, joystick: TouchJoystick, ability: AbilityController
) -> void:
	for scale_pair in SUPPORTED_SCALE_PAIRS:
		settings.set_ability_scale(scale_pair.x, false)
		settings.set_joystick_scale(scale_pair.y, false)
		await wait_process_frames(2)
		_assert_joystick_geometry(joystick, scale_pair.y)
		var capture_rect: Rect2 = movement_slice.get_touch_joystick_capture_rect()
		var joystick_origin: Vector2 = capture_rect.get_center() + Vector2(-150.0, 80.0)
		joystick._input(make_touch_event(0, true, joystick_origin))
		joystick._input(make_drag_event(0, joystick_origin + Vector2.RIGHT * joystick.base_radius, Vector2.ZERO))
		assert_true(joystick.active_finger_index == 0, "%s: il primo dito deve possedere il joystick." % scale_pair)
		assert_vector_near(
			joystick.movement_vector, Vector2.RIGHT, "%s: il raggio scalato deve normalizzare il drag." % scale_pair,
			TOUCH_SETTINGS_FLOAT_TOLERANCE
		)
		var ability_rect := hud.get_active_ability_button_rect()
		await _dispatch_touch_tap(1, ability_rect.get_center())
		assert_true(ability.get_cooldown_remaining() > 0.0, "%s: il secondo dito deve attivare l'abilita." % scale_pair)
		assert_true(joystick.active_finger_index == 0, "%s: il tap abilita non deve rubare il joystick." % scale_pair)
		joystick._input(make_touch_event(0, false, joystick_origin))
		ability._process(ability.get_cooldown_remaining())
		assert_true(ability.is_cooldown_ready(), "%s: la fixture deve riarmare l'abilita." % scale_pair)


func _assert_pause_preview(
	controller: RunController, pause_overlay: PauseOverlay, settings: TouchControlSettings, hud: GameHud, joystick: TouchJoystick
) -> void:
	assert_true(controller.request_manual_pause(), "B18P deve aprire la pausa manuale.")
	await wait_process_frames(2)
	assert_true(pause_overlay.visible, "Le impostazioni B18P devono essere raggiungibili dalla pausa.")
	pause_overlay.get_ability_size_slider().value = TouchControlSettings.DEFAULT_ABILITY_SCALE
	pause_overlay.get_joystick_size_slider().value = TouchControlSettings.DEFAULT_JOYSTICK_SCALE
	await wait_process_frames(2)
	assert_true(controller.get_state() == RunController.RunState.MANUAL_PAUSE, "Cambiare scala non deve riprendere la run.")
	assert_almost_eq(
		hud.get_active_ability_button_rect().size.x, TouchAbilityButton.BASE_TARGET_SIZE * TouchControlSettings.DEFAULT_ABILITY_SCALE,
		TOUCH_SETTINGS_FLOAT_TOLERANCE, "La pausa deve applicare il nuovo default raddoppiato senza riavvio."
	)
	_assert_joystick_geometry(joystick, 1.0)
	assert_almost_eq(
		settings.get_ability_scale(), 1.25, TOUCH_SETTINGS_FLOAT_TOLERANCE, "La pausa deve aggiornare l'autorita persistente."
	)
	assert_almost_eq(
		settings.get_joystick_scale(), 1.0, TOUCH_SETTINGS_FLOAT_TOLERANCE, "La pausa deve aggiornare la scala joystick."
	)
	var viewport_rect := Rect2(Vector2.ZERO, Vector2(get_tree().root.size))
	assert_true(
		viewport_rect.encloses(pause_overlay.get_pause_panel_rect()), "Il pannello pausa B18P deve restare nel viewport 16:9."
	)
	assert_true(controller.resume_run(), "La fixture B18P deve riprendere esplicitamente.")


func _assert_persistence(settings: TouchControlSettings) -> void:
	settings.set_ability_scale(TouchControlSettings.DEFAULT_ABILITY_SCALE)
	settings.set_joystick_scale(TouchControlSettings.DEFAULT_JOYSTICK_SCALE)
	var reloaded := TouchControlSettings.new()
	reloaded.settings_path = TEST_SETTINGS_PATH
	add_child_autofree(reloaded)
	assert_almost_eq(
		reloaded.get_ability_scale(), 1.25, TOUCH_SETTINGS_FLOAT_TOLERANCE, "La scala abilita deve sopravvivere a una nuova istanza."
	)
	assert_almost_eq(
		reloaded.get_joystick_scale(), 1.0, TOUCH_SETTINGS_FLOAT_TOLERANCE, "La scala joystick deve sopravvivere a una nuova istanza."
	)


func _assert_joystick_geometry(joystick: TouchJoystick, scale_value: float) -> void:
	assert_almost_eq(
		joystick.custom_minimum_size.x, TouchJoystick.BASE_CONTROL_SIZE * scale_value, TOUCH_SETTINGS_FLOAT_TOLERANCE,
		"La base joystick deve scalare."
	)
	assert_almost_eq(
		joystick.base_radius, TouchJoystick.BASE_INPUT_RADIUS * scale_value, TOUCH_SETTINGS_FLOAT_TOLERANCE,
		"Il raggio di trascinamento deve scalare."
	)
	assert_almost_eq(
		joystick.visual_radius, TouchJoystick.BASE_VISUAL_RADIUS * scale_value, TOUCH_SETTINGS_FLOAT_TOLERANCE,
		"Il raggio visivo deve scalare."
	)
	assert_almost_eq(
		joystick.knob_radius, TouchJoystick.BASE_KNOB_RADIUS * scale_value, TOUCH_SETTINGS_FLOAT_TOLERANCE,
		"La manopola deve scalare."
	)
	assert_almost_eq(
		joystick.get_deadzone_radius(), TouchJoystick.BASE_INPUT_RADIUS * scale_value * joystick.deadzone_ratio,
		TOUCH_SETTINGS_FLOAT_TOLERANCE, "La deadzone assoluta deve scalare."
	)


func _write_invalid_settings() -> void:
	var config := ConfigFile.new()
	config.set_value(TouchControlSettings.SETTINGS_SECTION, TouchControlSettings.ABILITY_SCALE_KEY, 99.0)
	config.set_value(TouchControlSettings.SETTINGS_SECTION, TouchControlSettings.JOYSTICK_SCALE_KEY, -7.0)
	var error := config.save(TEST_SETTINGS_PATH)
	assert_true(error == OK, "La fixture B18P deve creare il file impostazioni isolato.")


func _remove_test_settings() -> void:
	var absolute_path := ProjectSettings.globalize_path(TEST_SETTINGS_PATH)
	if FileAccess.file_exists(absolute_path):
		DirAccess.remove_absolute(absolute_path)


func _dispatch_touch_tap(index: int, position: Vector2) -> void:
	Input.parse_input_event(make_touch_event(index, true, position))
	await wait_process_frames(1)
	Input.parse_input_event(make_touch_event(index, false, position))
	await wait_process_frames(1)
