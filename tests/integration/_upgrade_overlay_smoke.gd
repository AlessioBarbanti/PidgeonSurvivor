extends SceneTree

const UPGRADE_OVERLAY_SCENE := preload("res://scenes/ui/upgrade_overlay.tscn")
const TOUCH_JOYSTICK_SCENE := preload("res://scenes/ui/touch_joystick.tscn")
const MOVEMENT_SLICE_SCENE := preload("res://scenes/game/movement_slice.tscn")
const SWIFT_STEPS := preload("res://data/upgrades/swift_steps.tres")
const RAPID_FIRE := preload("res://data/upgrades/rapid_fire.tres")
const WIDE_MAGNET := preload("res://data/upgrades/wide_magnet.tres")
const FALLBACK_POWER := preload("res://data/upgrades/fallback_power.tres")
const FALLBACK_HASTE := preload("res://data/upgrades/fallback_haste.tres")
const FALLBACK_REACH := preload("res://data/upgrades/fallback_reach.tres")
const INITIAL_VIEWPORT_SIZE := Vector2i(1280, 720)
const LAYOUT_TOLERANCE := 1.0

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	paused = false
	await process_frame
	_validate_navigation_mappings()
	await _validate_responsive_layouts()
	await _validate_composed_input_and_queue()
	await _finish()


func _validate_navigation_mappings() -> void:
	for action in [&"ui_left", &"ui_right", &"ui_accept"]:
		_expect(InputMap.has_action(action), "B11 richiede l'azione UI %s." % action)

	var keyboard_right := _key(KEY_RIGHT)
	var keyboard_accept := _key(KEY_ENTER)
	var controller_right := _joy_button(JOY_BUTTON_DPAD_RIGHT)
	var controller_accept := _joy_button(JOY_BUTTON_A)
	_expect(
		keyboard_right.is_action_pressed(&"ui_right"),
		"Freccia destra deve navigare le carte da tastiera."
	)
	_expect(
		keyboard_accept.is_action_pressed(&"ui_accept"),
		"Invio deve confermare la carta focalizzata."
	)
	_expect(
		controller_right.is_action_pressed(&"ui_right"),
		"Il D-pad destro deve navigare le carte."
	)
	_expect(
		controller_accept.is_action_pressed(&"ui_accept"),
		"Il pulsante A deve confermare la carta focalizzata."
	)


func _validate_responsive_layouts() -> void:
	var profiles := [
		{"name": "16:9", "safe_rect": Rect2(20.0, 20.0, 1240.0, 680.0)},
		{"name": "20:9 cutout", "safe_rect": Rect2(64.0, 20.0, 1472.0, 680.0)},
		{"name": "4:3", "safe_rect": Rect2(20.0, 20.0, 920.0, 680.0)},
	]

	for profile in profiles:
		var safe_rect: Rect2 = profile.safe_rect
		var fixture := await _create_overlay_fixture(safe_rect, 1100 + int(safe_rect.size.x))
		var controller := fixture.controller as RunController
		var overlay := fixture.overlay as UpgradeOverlay
		var joystick := fixture.joystick as TouchJoystick
		var cards := overlay.get_cards()
		var profile_name := String(profile.name)

		_expect(overlay.visible, "%s: l'offerta deve mostrare l'overlay." % profile_name)
		_expect(overlay.is_accepting_selection(), "%s: le carte devono essere attive." % profile_name)
		_expect(not joystick.visible, "%s: il joystick deve sparire durante LEVEL_UP." % profile_name)
		_expect_rect_near(
			overlay.get_global_rect(),
			safe_rect,
			"%s: l'overlay deve coincidere con la safe area." % profile_name
		)
		_expect(cards.size() == 3, "%s: devono essere visibili tre carte." % profile_name)
		for index in cards.size():
			var card := cards[index]
			_expect_rect_inside(
				card.get_global_rect(),
				safe_rect,
				"%s: carta %d fuori safe area." % [profile_name, index + 1]
			)
			_expect(
				card.size.x >= 250.0 - LAYOUT_TOLERANCE
				and card.size.y >= 360.0 - LAYOUT_TOLERANCE,
				"%s: carta %d non e' un target touch ampio." % [profile_name, index + 1]
			)
			_expect(
				card.get_title_text() == card.get_definition().title
				and card.get_description_text() == card.get_definition().description,
				"%s: carta %d deve mostrare titolo e descrizione dati." % [profile_name, index + 1]
			)
			_expect(
				card.get_rank_text() == "RANGO 0  >  1",
				"%s: la carta deve anticipare il nuovo rank." % profile_name
			)
		if cards.size() == 3:
			_expect(
				cards[0].get_global_rect().end.x < cards[1].get_global_rect().position.x
				and cards[1].get_global_rect().end.x < cards[2].get_global_rect().position.x,
				"%s: le carte non devono sovrapporsi." % profile_name
			)

		controller.prepare_restart()
		paused = false
		_expect(not overlay.visible, "%s: il reset deve chiudere l'overlay." % profile_name)
		_expect(joystick.visible, "%s: il reset deve ripristinare il joystick." % profile_name)
		fixture.root.queue_free()
		await process_frame


func _validate_composed_input_and_queue() -> void:
	root.content_scale_size = INITIAL_VIEWPORT_SIZE
	root.size = INITIAL_VIEWPORT_SIZE
	await _wait_processed_frame()
	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	root.add_child(movement_slice)
	await _wait_processed_frame()

	var controller := movement_slice.get_run_controller() as RunController
	var experience := movement_slice.get_experience_system() as ExperienceSystem
	var service := movement_slice.get_upgrade_service() as UpgradeService
	var overlay := movement_slice.get_upgrade_overlay() as UpgradeOverlay
	var joystick := movement_slice.get_node_or_null("UI/SafeAreaRoot/TouchJoystick") as TouchJoystick
	var input_router := movement_slice.get_node_or_null("InputRouter") as InputRouter
	var player := movement_slice.get_node_or_null("World/Player") as Player
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner

	_expect(controller != null and experience != null, "La scena B11 deve conservare il loop XP.")
	_expect(service != null and overlay != null, "La scena B11 deve comporre service e overlay.")
	_expect(joystick != null and input_router != null, "La scena B11 deve comporre i controlli touch.")
	if (
		controller == null
		or experience == null
		or service == null
		or overlay == null
		or joystick == null
		or input_router == null
	):
		paused = false
		movement_slice.queue_free()
		await process_frame
		return

	controller.set_process(false)
	if spawner != null:
		spawner.set_process(false)
	if player != null:
		player.set_physics_process(false)
		var weapon := player.get_weapon_controller()
		if weapon != null:
			weapon.set_process(false)
		var ability := player.get_ability_controller()
		if ability != null:
			ability.set_process(false)

	var selected_ids: Array[StringName] = []
	service.upgrade_selected.connect(
		func(definition: UpgradeDefinition, _rank: int, _level: int) -> void:
			selected_ids.append(definition.id)
	)
	_expect(experience.add_experience(70), "La fixture deve accodare quattro level-up.")
	await _wait_processed_frame()
	_expect(controller.get_state() == RunController.RunState.LEVEL_UP, "Le carte devono mettere in pausa il gameplay.")
	_expect(paused, "LEVEL_UP deve sospendere il SceneTree.")
	_expect(overlay.visible and overlay.get_displayed_level() == 2, "La prima offerta deve essere visibile per il livello 2.")
	_expect("4 scelte in coda" in overlay.get_queue_text(), "L'overlay deve rendere visibile la coda multipla.")
	_expect(not joystick.visible, "Il joystick composto deve essere nascosto.")
	_expect(input_router.is_input_suspended(), "L'input gameplay deve restare sospeso.")

	# Tastiera: il tasto numerico sceglie direttamente la seconda carta.
	_dispatch_event(_key(KEY_2))
	_dispatch_event(_key(KEY_2, false))
	await _wait_processed_frame()
	_expect(selected_ids.size() == 1, "Un input tastiera deve applicare una sola scelta.")
	_expect(overlay.get_displayed_level() == 3, "La coda deve mostrare subito l'offerta successiva.")

	# Controller: D-pad sposta il focus, A conferma la carta focalizzata.
	_expect(overlay.focus_card(0), "La fixture deve poter focalizzare la prima carta.")
	_dispatch_event(_joy_button(JOY_BUTTON_DPAD_RIGHT))
	_dispatch_event(_joy_button(JOY_BUTTON_DPAD_RIGHT, false))
	await process_frame
	_expect(overlay.get_focused_card_index() == 1, "Il D-pad deve spostare il focus alla seconda carta.")
	_dispatch_event(_joy_button(JOY_BUTTON_A))
	_dispatch_event(_joy_button(JOY_BUTTON_A, false))
	await _wait_processed_frame()
	_expect(selected_ids.size() == 2, "Un input controller deve applicare una sola scelta.")
	_expect(overlay.get_displayed_level() == 4, "La terza offerta deve seguire senza frame RUNNING.")

	# Mouse: l'intero riquadro Button e' selezionabile.
	var mouse_card := overlay.get_cards()[0]
	await _dispatch_mouse_click(mouse_card.get_global_rect().get_center())
	await _wait_processed_frame()
	_expect(selected_ids.size() == 3, "Un click mouse deve applicare una sola scelta.")
	_expect(overlay.get_displayed_level() == 5, "La quarta offerta deve restare nello stesso LEVEL_UP.")

	# Touch: un tap sul terzo riquadro percorre lo stesso segnale del Button.
	var touch_card := overlay.get_cards()[2]
	await _dispatch_touch_tap(7, touch_card.get_global_rect().get_center())
	await _wait_processed_frame()
	_expect(selected_ids.size() == 4, "Un tap touch deve applicare una sola scelta.")
	_expect(
		controller.is_running()
		and experience.pending_level_ups == 0
		and service.get_current_offer().is_empty(),
		"Dopo quattro conferme la run deve riprendere con coda e offerta vuote."
	)
	_expect(not overlay.visible, "L'ultima conferma deve nascondere l'overlay.")
	_expect(joystick.visible, "L'ultima conferma deve ripristinare il joystick.")
	var acquired_rank_total := 0
	for rank_value: Variant in service.get_ranks().values():
		acquired_rank_total += int(rank_value)
	_expect(acquired_rank_total == 4, "Quattro eventi distinti devono produrre esattamente quattro rank.")

	# Senza offerta attiva, click ripetuti e submit diretti non applicano altro.
	mouse_card.emit_signal(&"pressed")
	_expect(not overlay.submit_card(0), "Un overlay chiuso deve rifiutare submit residui.")
	_expect(selected_ids.size() == 4, "Gli eventi residui non devono duplicare la scelta.")

	controller.prepare_restart()
	paused = false
	movement_slice.queue_free()
	await process_frame


func _create_overlay_fixture(safe_rect: Rect2, seed_value: int) -> Dictionary:
	var fixture_root := Control.new()
	fixture_root.name = "UpgradeOverlayFixture"
	fixture_root.process_mode = Node.PROCESS_MODE_ALWAYS
	fixture_root.position = safe_rect.position
	fixture_root.size = safe_rect.size

	var controller := RunController.new()
	controller.name = "RunController"
	controller.set_process(false)
	var experience := ExperienceSystem.new()
	experience.name = "ExperienceSystem"
	var curve := ExperienceCurve.new()
	curve.base_experience_required = 1
	curve.experience_growth_per_level = 0
	experience.experience_curve = curve
	var registry := UpgradeRegistry.new()
	registry.name = "UpgradeRegistry"
	var definitions: Array[UpgradeDefinition] = [
		SWIFT_STEPS,
		RAPID_FIRE,
		WIDE_MAGNET,
		FALLBACK_POWER,
		FALLBACK_HASTE,
		FALLBACK_REACH,
	]
	registry.definitions = definitions
	var service := UpgradeService.new()
	service.name = "UpgradeService"
	var joystick := TOUCH_JOYSTICK_SCENE.instantiate() as TouchJoystick
	joystick.name = "TouchJoystick"
	joystick.debug_mode_in_editor = true
	var overlay := UPGRADE_OVERLAY_SCENE.instantiate() as UpgradeOverlay
	overlay.name = "UpgradeOverlay"

	fixture_root.add_child(controller)
	fixture_root.add_child(experience)
	fixture_root.add_child(registry)
	fixture_root.add_child(service)
	fixture_root.add_child(joystick)
	fixture_root.add_child(overlay)
	root.add_child(fixture_root)
	await _wait_processed_frame()

	experience.set_run_controller(controller)
	_expect(registry.rebuild_registry(), "La fixture B11 deve avere un catalogo valido.")
	_expect(service.configure(registry, controller, experience), "La fixture B11 deve configurare UpgradeService.")
	_expect(overlay.configure(service, joystick), "La fixture B11 deve configurare UpgradeOverlay.")
	_expect(controller.start_run(seed_value), "La fixture B11 deve avviare la run.")
	_expect(experience.add_experience(1), "La fixture B11 deve generare un'offerta.")
	await _wait_processed_frame()
	return {
		"root": fixture_root,
		"controller": controller,
		"overlay": overlay,
		"joystick": joystick,
	}


func _dispatch_event(event: InputEvent) -> void:
	Input.parse_input_event(event)


func _dispatch_mouse_click(position: Vector2) -> void:
	var pressed_event := InputEventMouseButton.new()
	pressed_event.button_index = MOUSE_BUTTON_LEFT
	pressed_event.pressed = true
	pressed_event.position = position
	pressed_event.global_position = position
	_dispatch_event(pressed_event)
	await process_frame
	var released_event := InputEventMouseButton.new()
	released_event.button_index = MOUSE_BUTTON_LEFT
	released_event.pressed = false
	released_event.position = position
	released_event.global_position = position
	_dispatch_event(released_event)
	await process_frame


func _dispatch_touch_tap(index: int, position: Vector2) -> void:
	var pressed_event := InputEventScreenTouch.new()
	pressed_event.index = index
	pressed_event.pressed = true
	pressed_event.position = position
	_dispatch_event(pressed_event)
	await process_frame
	var released_event := InputEventScreenTouch.new()
	released_event.index = index
	released_event.pressed = false
	released_event.position = position
	_dispatch_event(released_event)
	await process_frame


func _key(keycode: Key, pressed_value: bool = true) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	event.keycode = keycode
	event.pressed = pressed_value
	return event


func _joy_button(button: JoyButton, pressed_value: bool = true) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = pressed_value
	event.pressure = 1.0 if pressed_value else 0.0
	return event


func _expect_rect_inside(rect: Rect2, bounds: Rect2, message: String) -> void:
	_expect(
		rect.position.x >= bounds.position.x - LAYOUT_TOLERANCE
		and rect.position.y >= bounds.position.y - LAYOUT_TOLERANCE
		and rect.end.x <= bounds.end.x + LAYOUT_TOLERANCE
		and rect.end.y <= bounds.end.y + LAYOUT_TOLERANCE,
		"%s Rect %s, bounds %s." % [message, rect, bounds]
	)


func _expect_rect_near(actual: Rect2, expected: Rect2, message: String) -> void:
	_expect(
		actual.position.distance_to(expected.position) <= LAYOUT_TOLERANCE
		and actual.size.distance_to(expected.size) <= LAYOUT_TOLERANCE,
		"%s Atteso %s, ottenuto %s." % [message, expected, actual]
	)


func _wait_processed_frame() -> void:
	await process_frame
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	paused = false
	await process_frame
	if _failures.is_empty():
		print("B11_UPGRADE_OVERLAY_SMOKE_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	printerr("B11_UPGRADE_OVERLAY_SMOKE_FAIL count=%d" % _failures.size())
	quit(1)
