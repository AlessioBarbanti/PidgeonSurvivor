extends SceneTree

const MOVEMENT_SLICE_SCENE := preload("res://scenes/game/movement_slice.tscn")
const INITIAL_VIEWPORT_SIZE := Vector2i(1280, 720)
const TEST_SETTINGS_PATH := "user://b18p_touch_control_settings_smoke.cfg"
const FLOAT_TOLERANCE := 0.05
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

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	paused = false
	root.content_scale_size = INITIAL_VIEWPORT_SIZE
	root.size = INITIAL_VIEWPORT_SIZE
	_remove_test_settings()
	_write_invalid_settings()
	ProjectSettings.set_setting("application/run/b18o_force_welcome_for_test", true)
	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	var settings := movement_slice.get_node("TouchControlSettings") as TouchControlSettings
	settings.settings_path = TEST_SETTINGS_PATH
	root.add_child(movement_slice)
	ProjectSettings.set_setting("application/run/b18o_force_welcome_for_test", false)
	await _wait_processed_frame()

	var controller := movement_slice.get_run_controller() as RunController
	var welcome := movement_slice.get_welcome_screen() as WelcomeScreen
	var pause_overlay := movement_slice.get_pause_overlay() as PauseOverlay
	var hud := movement_slice.get_hud() as GameHud
	var joystick := movement_slice.get_node("UI/SafeAreaRoot/TouchJoystick") as TouchJoystick
	var ability := movement_slice.get_ability_controller() as AbilityController
	_expect(settings != null, "B18P richiede TouchControlSettings.")
	_expect(welcome != null and pause_overlay != null, "B18P richiede impostazioni da welcome e pausa.")
	_expect(hud != null and joystick != null and ability != null, "B18P richiede entrambi i controlli runtime.")
	if (
		settings == null
		or controller == null
		or welcome == null
		or pause_overlay == null
		or hud == null
		or joystick == null
		or ability == null
	):
		await _finish(movement_slice, controller)
		return

	_validate_loaded_clamp(settings, hud, joystick)
	await _validate_welcome_preview(welcome, pause_overlay, settings, hud, joystick)
	await _validate_layout_profiles(movement_slice, welcome, hud, joystick, settings)

	_expect(movement_slice.select_friend_for_next_run(&"magno"), "La fixture B18P deve selezionare Magno.")
	_expect(movement_slice.start_selected_run(1816), "La fixture B18P deve avviare la run.")
	await _wait_processed_frame()
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

	await _validate_supported_multitouch_scales(
		movement_slice,
		settings,
		hud,
		joystick,
		ability
	)
	await _validate_pause_preview(controller, pause_overlay, settings, hud, joystick)
	_validate_persistence(settings)

	await _finish(movement_slice, controller)


func _validate_loaded_clamp(
	settings: TouchControlSettings,
	hud: GameHud,
	joystick: TouchJoystick
) -> void:
	_expect_float_near(
		TouchControlSettings.sanitize_ability_scale(1.11),
		TouchControlSettings.MIN_ABILITY_SCALE,
		"Una scala abilita intermedia deve convergere a una taglia supportata."
	)
	_expect_float_near(
		TouchControlSettings.sanitize_joystick_scale(0.93),
		TouchControlSettings.DEFAULT_JOYSTICK_SCALE,
		"Una scala joystick intermedia deve convergere a una taglia supportata."
	)
	_expect_float_near(
		settings.get_ability_scale(),
		TouchControlSettings.MAX_ABILITY_SCALE,
		"Un valore abilita fuori range deve essere clampato al massimo."
	)
	_expect_float_near(
		settings.get_joystick_scale(),
		TouchControlSettings.MIN_JOYSTICK_SCALE,
		"Un valore joystick fuori range deve essere clampato al minimo."
	)
	var button := hud.get_active_ability_button()
	_expect_float_near(
		button.size.x,
		TouchAbilityButton.BASE_TARGET_SIZE * TouchControlSettings.MAX_ABILITY_SCALE,
		"Il clamp deve applicarsi subito al target abilita."
	)
	_expect(
		button.get_icon_max_width() == roundi(
			TouchAbilityButton.BASE_ICON_WIDTH * TouchControlSettings.MAX_ABILITY_SCALE
		),
		"Icona e hit target devono crescere insieme."
	)
	_validate_joystick_geometry(joystick, TouchControlSettings.MIN_JOYSTICK_SCALE)


func _validate_welcome_preview(
	welcome: WelcomeScreen,
	pause_overlay: PauseOverlay,
	settings: TouchControlSettings,
	hud: GameHud,
	joystick: TouchJoystick
) -> void:
	var settings_button := welcome.get_settings_button()
	_expect(settings_button != null, "La welcome B18P deve esporre IMPOSTAZIONI.")
	if settings_button == null:
		return
	settings_button.pressed.emit()
	await _wait_processed_frame()
	var ability_slider := welcome.get_ability_size_slider()
	var joystick_slider := welcome.get_joystick_size_slider()
	_expect(ability_slider != null and joystick_slider != null, "La welcome deve esporre due scale indipendenti.")
	if ability_slider == null or joystick_slider == null:
		return
	ability_slider.value = TouchControlSettings.MIN_ABILITY_SCALE
	joystick_slider.value = TouchControlSettings.MAX_JOYSTICK_SCALE
	await _wait_processed_frame()
	_expect_float_near(settings.get_ability_scale(), 1.0, "La welcome deve applicare subito la scala abilita.")
	_expect_float_near(settings.get_joystick_scale(), 1.15, "La welcome deve applicare subito la scala joystick.")
	_expect_float_near(hud.get_active_ability_button_rect().size.x, 64.0, "La preview welcome deve aggiornare il target.")
	_validate_joystick_geometry(joystick, 1.15)
	_expect_float_near(pause_overlay.get_ability_size_slider().value, 1.0, "Welcome e pausa devono restare sincronizzate.")
	_expect_float_near(pause_overlay.get_joystick_size_slider().value, 1.15, "La scala joystick deve sincronizzarsi con la pausa.")
	if OS.get_cmdline_user_args().has("--capture-b18p"):
		await _capture_viewport("res://exports/screenshots/b18p_welcome_settings.png")


func _validate_layout_profiles(
	movement_slice: Control,
	welcome: WelcomeScreen,
	hud: GameHud,
	joystick: TouchJoystick,
	settings: TouchControlSettings
) -> void:
	settings.set_ability_scale(TouchControlSettings.MAX_ABILITY_SCALE, false)
	settings.set_joystick_scale(TouchControlSettings.MAX_JOYSTICK_SCALE, false)
	var reference_capture_rect: Rect2 = movement_slice.get_touch_joystick_capture_rect()
	for profile in LAYOUT_PROFILES:
		root.content_scale_size = profile
		root.size = profile
		await _wait_processed_frame()
		var arena := movement_slice.get_node("ArenaLayout") as ArenaLayout
		arena.refresh_layout()
		await _wait_processed_frame()
		var safe_area := arena.get_safe_area_rect()
		var ability_rect := hud.get_active_ability_button_rect()
		var capture_rect: Rect2 = movement_slice.get_touch_joystick_capture_rect()
		_expect(safe_area.encloses(ability_rect), "%s: l'abilita massima deve restare nella safe area." % profile)
		_expect(
			safe_area.end.x - ability_rect.end.x >= 15.0
			and safe_area.end.y - ability_rect.end.y >= 31.0,
			"%s: l'abilita deve rispettare il margine anti-gesture." % profile
		)
		_expect(not ability_rect.intersects(hud.get_top_band_rect()), "%s: l'abilita non deve sovrapporre l'HUD alto." % profile)
		_expect(safe_area.encloses(capture_rect), "%s: l'acquisizione joystick deve restare nella safe area." % profile)
		settings.set_joystick_scale(TouchControlSettings.MIN_JOYSTICK_SCALE, false)
		await _wait_processed_frame()
		var compact_capture_rect: Rect2 = movement_slice.get_touch_joystick_capture_rect()
		_expect(
			compact_capture_rect.position.distance_to(capture_rect.position) <= FLOAT_TOLERANCE
			and compact_capture_rect.size.distance_to(capture_rect.size) <= FLOAT_TOLERANCE,
			"%s: la scala non deve restringere l'acquisizione dinamica." % profile
		)
		settings.set_joystick_scale(TouchControlSettings.MAX_JOYSTICK_SCALE, false)
		await _wait_processed_frame()
		_expect(
			safe_area.encloses(welcome.get_actions_frame_rect()),
			"%s: le impostazioni welcome devono restare nella safe area." % profile
		)
	root.content_scale_size = INITIAL_VIEWPORT_SIZE
	root.size = INITIAL_VIEWPORT_SIZE
	await _wait_processed_frame()
	_expect(reference_capture_rect.has_area(), "La matrice B18P deve partire da una zona dinamica valida.")


func _validate_supported_multitouch_scales(
	movement_slice: Control,
	settings: TouchControlSettings,
	hud: GameHud,
	joystick: TouchJoystick,
	ability: AbilityController
) -> void:
	for scale_pair in SUPPORTED_SCALE_PAIRS:
		settings.set_ability_scale(scale_pair.x, false)
		settings.set_joystick_scale(scale_pair.y, false)
		await _wait_processed_frame()
		_validate_joystick_geometry(joystick, scale_pair.y)
		var capture_rect: Rect2 = movement_slice.get_touch_joystick_capture_rect()
		var joystick_origin: Vector2 = capture_rect.get_center() + Vector2(-150.0, 80.0)
		joystick._input(_touch(0, true, joystick_origin))
		joystick._input(_drag(0, joystick_origin + Vector2.RIGHT * joystick.base_radius))
		_expect(joystick.active_finger_index == 0, "%s: il primo dito deve possedere il joystick." % scale_pair)
		_expect_vector_near(joystick.movement_vector, Vector2.RIGHT, "%s: il raggio scalato deve normalizzare il drag." % scale_pair)
		var ability_rect := hud.get_active_ability_button_rect()
		await _dispatch_touch_tap(1, ability_rect.get_center())
		_expect(ability.get_cooldown_remaining() > 0.0, "%s: il secondo dito deve attivare l'abilita." % scale_pair)
		_expect(joystick.active_finger_index == 0, "%s: il tap abilita non deve rubare il joystick." % scale_pair)
		if (
			OS.get_cmdline_user_args().has("--capture-b18p")
			and is_equal_approx(scale_pair.x, TouchControlSettings.DEFAULT_ABILITY_SCALE)
		):
			await _capture_viewport("res://exports/screenshots/b18p_touch_controls.png")
		joystick._input(_touch(0, false, joystick_origin))
		ability._process(ability.get_cooldown_remaining())
		_expect(ability.is_cooldown_ready(), "%s: la fixture deve riarmare l'abilita." % scale_pair)


func _validate_pause_preview(
	controller: RunController,
	pause_overlay: PauseOverlay,
	settings: TouchControlSettings,
	hud: GameHud,
	joystick: TouchJoystick
) -> void:
	_expect(controller.request_manual_pause(), "B18P deve aprire la pausa manuale.")
	await _wait_processed_frame()
	_expect(pause_overlay.visible, "Le impostazioni B18P devono essere raggiungibili dalla pausa.")
	pause_overlay.get_ability_size_slider().value = TouchControlSettings.DEFAULT_ABILITY_SCALE
	pause_overlay.get_joystick_size_slider().value = TouchControlSettings.DEFAULT_JOYSTICK_SCALE
	await _wait_processed_frame()
	_expect(controller.get_state() == RunController.RunState.MANUAL_PAUSE, "Cambiare scala non deve riprendere la run.")
	_expect_float_near(hud.get_active_ability_button_rect().size.x, 80.0, "La pausa deve applicare il nuovo default senza riavvio.")
	_validate_joystick_geometry(joystick, 1.0)
	_expect_float_near(settings.get_ability_scale(), 1.25, "La pausa deve aggiornare l'autorita persistente.")
	_expect_float_near(settings.get_joystick_scale(), 1.0, "La pausa deve aggiornare la scala joystick.")
	var viewport_rect := Rect2(Vector2.ZERO, Vector2(root.size))
	_expect(viewport_rect.encloses(pause_overlay.get_pause_panel_rect()), "Il pannello pausa B18P deve restare nel viewport 16:9.")
	if OS.get_cmdline_user_args().has("--capture-b18p"):
		await _capture_viewport("res://exports/screenshots/b18p_pause_settings.png")
	_expect(controller.resume_run(), "La fixture B18P deve riprendere esplicitamente.")


func _validate_persistence(settings: TouchControlSettings) -> void:
	settings.set_ability_scale(TouchControlSettings.DEFAULT_ABILITY_SCALE)
	settings.set_joystick_scale(TouchControlSettings.DEFAULT_JOYSTICK_SCALE)
	var reloaded := TouchControlSettings.new()
	reloaded.settings_path = TEST_SETTINGS_PATH
	root.add_child(reloaded)
	_expect_float_near(reloaded.get_ability_scale(), 1.25, "La scala abilita deve sopravvivere a una nuova istanza.")
	_expect_float_near(reloaded.get_joystick_scale(), 1.0, "La scala joystick deve sopravvivere a una nuova istanza.")
	reloaded.queue_free()


func _validate_joystick_geometry(joystick: TouchJoystick, scale_value: float) -> void:
	_expect_float_near(joystick.custom_minimum_size.x, TouchJoystick.BASE_CONTROL_SIZE * scale_value, "La base joystick deve scalare.")
	_expect_float_near(joystick.base_radius, TouchJoystick.BASE_INPUT_RADIUS * scale_value, "Il raggio di trascinamento deve scalare.")
	_expect_float_near(joystick.visual_radius, TouchJoystick.BASE_VISUAL_RADIUS * scale_value, "Il raggio visivo deve scalare.")
	_expect_float_near(joystick.knob_radius, TouchJoystick.BASE_KNOB_RADIUS * scale_value, "La manopola deve scalare.")
	_expect_float_near(
		joystick.get_deadzone_radius(),
		TouchJoystick.BASE_INPUT_RADIUS * scale_value * joystick.deadzone_ratio,
		"La deadzone assoluta deve scalare."
	)


func _write_invalid_settings() -> void:
	var config := ConfigFile.new()
	config.set_value(TouchControlSettings.SETTINGS_SECTION, TouchControlSettings.ABILITY_SCALE_KEY, 99.0)
	config.set_value(TouchControlSettings.SETTINGS_SECTION, TouchControlSettings.JOYSTICK_SCALE_KEY, -7.0)
	var error := config.save(TEST_SETTINGS_PATH)
	_expect(error == OK, "La fixture B18P deve creare il file impostazioni isolato.")


func _remove_test_settings() -> void:
	var absolute_path := ProjectSettings.globalize_path(TEST_SETTINGS_PATH)
	if FileAccess.file_exists(absolute_path):
		DirAccess.remove_absolute(absolute_path)


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


func _expect_float_near(actual: float, expected: float, message: String) -> void:
	_expect(absf(actual - expected) <= FLOAT_TOLERANCE, "%s Atteso %s, ottenuto %s." % [message, expected, actual])


func _expect_vector_near(actual: Vector2, expected: Vector2, message: String) -> void:
	_expect(actual.distance_to(expected) <= FLOAT_TOLERANCE, "%s Atteso %s, ottenuto %s." % [message, expected, actual])


func _wait_processed_frame() -> void:
	await process_frame
	await process_frame


func _capture_viewport(path: String) -> void:
	await process_frame
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var viewport_texture := root.get_texture()
	if viewport_texture == null:
		_expect(false, "La cattura visiva B18P richiede un display renderer.")
		return
	var capture := viewport_texture.get_image()
	if capture == null:
		_expect(false, "La cattura visiva B18P non ha prodotto un'immagine.")
		return
	var result := capture.save_png(path)
	_expect(result == OK, "La cattura visiva B18P deve essere salvata.")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish(movement_slice: Node, controller: RunController) -> void:
	if is_instance_valid(controller):
		controller.prepare_restart()
	paused = false
	if is_instance_valid(movement_slice):
		movement_slice.queue_free()
	await process_frame
	_remove_test_settings()
	if _failures.is_empty():
		print("B18P_TOUCH_CONTROL_SETTINGS_SMOKE_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	printerr("B18P_TOUCH_CONTROL_SETTINGS_SMOKE_FAIL count=%d" % _failures.size())
	quit(1)
