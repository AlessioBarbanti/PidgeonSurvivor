extends GutGameplayTest

const UPGRADE_OVERLAY_SCENE := preload("res://scenes/ui/upgrade_overlay.tscn")
const TOUCH_JOYSTICK_SCENE := preload("res://scenes/ui/touch_joystick.tscn")
const SWIFT_STEPS := preload("res://data/upgrades/swift_steps.tres")
const RAPID_FIRE := preload("res://data/upgrades/rapid_fire.tres")
const WIDE_MAGNET := preload("res://data/upgrades/wide_magnet.tres")
const MEAT_FORK_DAMAGE := preload("res://data/upgrades/meat_fork_damage.tres")
const LAYOUT_TOLERANCE := 1.0


func test_navigation_mappings() -> void:
	for action in [&"ui_left", &"ui_right", &"ui_accept"]:
		assert_true(InputMap.has_action(action), "B11 richiede l'azione UI %s." % action)

	var keyboard_right := make_key_event(KEY_RIGHT, true)
	var keyboard_accept := make_key_event(KEY_ENTER, true)
	var controller_right := _joy_button(JOY_BUTTON_DPAD_RIGHT)
	var controller_accept := _joy_button(JOY_BUTTON_A)
	assert_true(keyboard_right.is_action_pressed(&"ui_right"), "Freccia destra deve navigare le carte da tastiera.")
	assert_true(keyboard_accept.is_action_pressed(&"ui_accept"), "Invio deve confermare la carta focalizzata.")
	assert_true(controller_right.is_action_pressed(&"ui_right"), "Il D-pad destro deve navigare le carte.")
	assert_true(controller_accept.is_action_pressed(&"ui_accept"), "Il pulsante A deve confermare la carta focalizzata.")


func test_responsive_layouts() -> void:
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

		assert_true(overlay.visible, "%s: l'offerta deve mostrare l'overlay." % profile_name)
		assert_true(overlay.is_accepting_selection(), "%s: le carte devono essere attive." % profile_name)
		assert_true(not joystick.visible, "%s: il joystick deve sparire durante LEVEL_UP." % profile_name)
		assert_rect_near(
			overlay.get_global_rect(), safe_rect, "%s: l'overlay deve coincidere con la safe area." % profile_name, LAYOUT_TOLERANCE
		)
		assert_eq(cards.size(), 3, "%s: devono essere visibili tre carte." % profile_name)
		for index in cards.size():
			var card := cards[index]
			var icon := card.get_node_or_null("Margins/Content/IconCenter/Icon") as TextureRect
			var icon_center := card.get_node_or_null("Margins/Content/IconCenter") as CenterContainer
			assert_rect_inside(
				card.get_global_rect(), safe_rect, "%s: carta %d fuori safe area." % [profile_name, index + 1], LAYOUT_TOLERANCE
			)
			assert_true(
				card.size.x >= 250.0 - LAYOUT_TOLERANCE and card.size.y >= 360.0 - LAYOUT_TOLERANCE,
				"%s: carta %d non e' un target touch ampio." % [profile_name, index + 1]
			)
			assert_true(
				card.get_title_text() == card.get_definition().title.to_upper()
				and card.get_description_text() == card.get_definition().description,
				"%s: carta %d deve mostrare titolo e descrizione dati." % [profile_name, index + 1]
			)
			assert_eq(card.get_rank_text(), "RANGO 0  >  1", "%s: la carta deve anticipare il nuovo rank." % profile_name)
			assert_true(
				icon != null and icon.custom_minimum_size == Vector2(192.0, 192.0)
				and icon_center != null and icon_center.custom_minimum_size.y >= 198.0,
				"%s: carta %d deve riservare un'area icona 192x192." % [profile_name, index + 1]
			)
		if cards.size() == 3:
			assert_true(
				cards[0].get_global_rect().end.x < cards[1].get_global_rect().position.x
				and cards[1].get_global_rect().end.x < cards[2].get_global_rect().position.x,
				"%s: le carte non devono sovrapporsi." % profile_name
			)

		controller.prepare_restart()
		assert_true(not overlay.visible, "%s: il reset deve chiudere l'overlay." % profile_name)
		assert_true(joystick.visible, "%s: il reset deve ripristinare il joystick." % profile_name)
		fixture.root.queue_free()
		await wait_process_frames(1)


func test_composed_input_and_queue() -> void:
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_run_controller() as RunController
	var experience := movement_slice.get_experience_system() as ExperienceSystem
	var service := movement_slice.get_upgrade_service() as UpgradeService
	var overlay := movement_slice.get_upgrade_overlay() as UpgradeOverlay
	var joystick := movement_slice.get_node_or_null("UI/SafeAreaRoot/TouchJoystick") as TouchJoystick
	var input_router := movement_slice.get_node_or_null("InputRouter") as InputRouter
	var player := movement_slice.get_node_or_null("World/Player") as Player
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner

	assert_true(controller != null and experience != null, "La scena B11 deve conservare il loop XP.")
	assert_true(service != null and overlay != null, "La scena B11 deve comporre service e overlay.")
	assert_true(joystick != null and input_router != null, "La scena B11 deve comporre i controlli touch.")
	if controller == null or experience == null or service == null or overlay == null or joystick == null or input_router == null:
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

	# Il pannello risultati di GUT copre la meta' destra dello schermo con
	# mouse_filter STOP: senza questo, un click/tap reale sulla carta piu' a
	# destra (x>~640 su 1280) verrebbe assorbito dal pannello invece di
	# raggiungere il Button, un artefatto del solo harness di test.
	var gut_panel := get_tree().root.find_child("GutScene", true, false)
	if gut_panel != null:
		for control in gut_panel.find_children("*", "Control", true, false):
			(control as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE

	var selected_ids: Array[StringName] = []
	service.upgrade_selected.connect(
		func(definition: UpgradeDefinition, _rank: int, _level: int) -> void:
			selected_ids.append(definition.id)
	)
	assert_true(experience.add_experience(70), "La fixture deve accodare quattro level-up.")
	await wait_process_frames(2)
	assert_true(controller.get_state() == RunController.RunState.LEVEL_UP, "Le carte devono mettere in pausa il gameplay.")
	assert_true(get_tree().paused, "LEVEL_UP deve sospendere il SceneTree.")
	assert_true(overlay.visible and overlay.get_displayed_level() == 2, "La prima offerta deve essere visibile per il livello 2.")
	assert_true(overlay.get_queue_text().is_empty(), "L'overlay compatto non deve mostrare testo della coda.")
	assert_true(not joystick.visible, "Il joystick composto deve essere nascosto.")
	assert_true(input_router.is_input_suspended(), "L'input gameplay deve restare sospeso.")

	# Il lock iniziale scarta i tap partiti mentre il pollice era sul joystick.
	assert_true(overlay.is_selection_locked(), "L'offerta deve aprirsi con la selezione bloccata.")
	assert_true(overlay.get_focused_card_index() < 0, "L'offerta non deve preselezionare nessuna carta.")
	Input.parse_input_event(make_key_event(KEY_1, true))
	Input.parse_input_event(make_key_event(KEY_1, false))
	await wait_process_frames(2)
	assert_true(selected_ids.is_empty(), "Un input dentro il lock non deve applicare scelte.")
	await _wait_selection_unlock(overlay)

	# Tastiera: il tasto numerico sceglie direttamente la seconda carta.
	Input.parse_input_event(make_key_event(KEY_2, true))
	Input.parse_input_event(make_key_event(KEY_2, false))
	await wait_process_frames(2)
	assert_eq(selected_ids.size(), 1, "Un input tastiera deve applicare una sola scelta.")
	assert_eq(overlay.get_displayed_level(), 3, "La coda deve mostrare subito l'offerta successiva.")

	await _wait_selection_unlock(overlay)

	# Controller: D-pad sposta il focus, A conferma la carta focalizzata.
	assert_true(overlay.focus_card(0), "La fixture deve poter focalizzare la prima carta.")
	Input.parse_input_event(_joy_button(JOY_BUTTON_DPAD_RIGHT, true))
	Input.parse_input_event(_joy_button(JOY_BUTTON_DPAD_RIGHT, false))
	await wait_process_frames(1)
	assert_eq(overlay.get_focused_card_index(), 1, "Il D-pad deve spostare il focus alla seconda carta.")
	Input.parse_input_event(_joy_button(JOY_BUTTON_A, true))
	Input.parse_input_event(_joy_button(JOY_BUTTON_A, false))
	await wait_process_frames(2)
	assert_eq(selected_ids.size(), 2, "Un input controller deve applicare una sola scelta.")
	assert_eq(overlay.get_displayed_level(), 4, "La terza offerta deve seguire senza frame RUNNING.")

	await _wait_selection_unlock(overlay)

	# Mouse: l'intero riquadro Button e' selezionabile.
	var mouse_card := overlay.get_cards()[0]
	await _dispatch_mouse_click(mouse_card.get_global_rect().get_center())
	await wait_process_frames(2)
	assert_eq(selected_ids.size(), 3, "Un click mouse deve applicare una sola scelta.")
	assert_eq(overlay.get_displayed_level(), 5, "La quarta offerta deve restare nello stesso LEVEL_UP.")

	await _wait_selection_unlock(overlay)

	# Touch: un tap sul terzo riquadro percorre lo stesso segnale del Button.
	var touch_card := overlay.get_cards()[2]
	await _dispatch_touch_tap(7, touch_card.get_global_rect().get_center())
	await wait_process_frames(2)
	assert_eq(selected_ids.size(), 4, "Un tap touch deve applicare una sola scelta.")
	assert_true(
		controller.is_running() and experience.pending_level_ups == 0 and service.get_current_offer().is_empty(),
		"Dopo quattro conferme la run deve riprendere con coda e offerta vuote."
	)
	assert_true(not overlay.visible, "L'ultima conferma deve nascondere l'overlay.")
	assert_true(joystick.visible, "L'ultima conferma deve ripristinare il joystick.")
	var acquired_rank_total := 0
	for upgrade_id_value: Variant in service.get_ranks():
		var definition := service.get_registry().resolve_definition(StringName(str(upgrade_id_value)))
		var initial_rank := definition.initial_rank if definition != null else 0
		acquired_rank_total += int(service.get_ranks()[upgrade_id_value]) - initial_rank
	assert_eq(acquired_rank_total, 4, "Quattro eventi distinti devono produrre esattamente quattro rank.")

	# Senza offerta attiva, click ripetuti e submit diretti non applicano altro.
	mouse_card.emit_signal(&"pressed")
	assert_true(not overlay.submit_card(0), "Un overlay chiuso deve rifiutare submit residui.")
	assert_eq(selected_ids.size(), 4, "Gli eventi residui non devono duplicare la scelta.")

	controller.prepare_restart()


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
	var definitions: Array[UpgradeDefinition] = [SWIFT_STEPS, RAPID_FIRE, WIDE_MAGNET, MEAT_FORK_DAMAGE]
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
	add_child_autofree(fixture_root)
	await wait_process_frames(2)

	experience.set_run_controller(controller)
	assert_true(registry.rebuild_registry(), "La fixture B11 deve avere un catalogo valido.")
	assert_true(service.configure(registry, controller, experience), "La fixture B11 deve configurare UpgradeService.")
	assert_true(overlay.configure(service, joystick), "La fixture B11 deve configurare UpgradeOverlay.")
	assert_true(controller.start_run(seed_value), "La fixture B11 deve avviare la run.")
	assert_true(experience.add_experience(1), "La fixture B11 deve generare un'offerta.")
	await wait_process_frames(2)
	assert_true(overlay.get_focused_card_index() < 0, "L'offerta non deve preselezionare nessuna carta.")
	await _wait_selection_unlock(overlay)
	return {
		"root": fixture_root,
		"controller": controller,
		"overlay": overlay,
		"joystick": joystick,
	}


func _dispatch_mouse_click(position: Vector2) -> void:
	var pressed_event := InputEventMouseButton.new()
	pressed_event.button_index = MOUSE_BUTTON_LEFT
	pressed_event.pressed = true
	pressed_event.position = position
	pressed_event.global_position = position
	Input.parse_input_event(pressed_event)
	await wait_process_frames(1)
	var released_event := InputEventMouseButton.new()
	released_event.button_index = MOUSE_BUTTON_LEFT
	released_event.pressed = false
	released_event.position = position
	released_event.global_position = position
	Input.parse_input_event(released_event)
	await wait_process_frames(1)


func _dispatch_touch_tap(index: int, position: Vector2) -> void:
	Input.parse_input_event(make_touch_event(index, true, position))
	await wait_process_frames(1)
	Input.parse_input_event(make_touch_event(index, false, position))
	await wait_process_frames(1)


func _joy_button(button: JoyButton, pressed_value: bool = true) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = pressed_value
	event.pressure = 1.0 if pressed_value else 0.0
	return event


func _wait_selection_unlock(overlay: UpgradeOverlay) -> void:
	while overlay.is_selection_locked():
		await get_tree().create_timer(overlay.get_selection_lock_remaining() + 0.05, true, false, true).timeout
	await wait_process_frames(2)
