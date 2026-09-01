extends GutGameplayTest

const EXPECTED_IDS: Array[StringName] = [
	&"magno", &"bea", &"zat", &"alea", &"aleo", &"lollo", &"migi", &"marghe",
]
const LAYOUT_PROFILES := [
	Vector2i(1280, 720),
	Vector2i(1600, 720),
	Vector2i(960, 720),
]


func test_character_carousel_contract() -> void:
	ProjectSettings.set_setting("application/run/b18o_force_welcome_for_test", true)
	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	add_child_autofree(movement_slice)
	ProjectSettings.set_setting("application/run/b18o_force_welcome_for_test", false)
	await wait_process_frames(2)

	var controller := movement_slice.get_run_controller() as RunController
	var welcome := movement_slice.get_welcome_screen() as WelcomeScreen
	var selector := movement_slice.get_character_select_overlay() as CharacterSelectOverlay
	var registry := movement_slice.get_friend_registry() as FriendRegistry
	var lifecycle := movement_slice.get_platform_lifecycle() as PlatformLifecycle
	var arena_layout := movement_slice.get_node("ArenaLayout") as ArenaLayout
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	var router := movement_slice.get_node("InputRouter") as InputRouter
	var hud := movement_slice.get_hud() as GameHud
	var pause_overlay := movement_slice.get_pause_overlay() as PauseOverlay
	var end_screen := movement_slice.get_end_screen() as EndScreen

	assert_true(
		controller != null and welcome != null and selector != null and registry != null,
		"Il frontend B18T deve essere composto."
	)
	if controller == null or welcome == null or selector == null or registry == null:
		return

	welcome.get_play_button().pressed.emit()
	await wait_process_frames(2)
	assert_true(selector.visible and not welcome.visible, "GIOCA deve aprire il carosello.")
	assert_eq(controller.get_state(), RunController.RunState.BOOT, "Il carosello deve restare in BOOT.")
	assert_true(
		controller.get_seed() == 0 and is_zero_approx(controller.get_run_time()),
		"Il carosello non deve creare seed o clock."
	)
	assert_true(
		spawner.get_alive_count() == 0 and router.is_input_suspended(),
		"Spawn e input gameplay devono restare inattivi."
	)
	assert_eq(
		selector.get_definition_ids(), EXPECTED_IDS, "Il carosello deve conservare l'ordine dichiarativo degli otto amici."
	)
	assert_eq(selector.get_roster_size(), 8, "Il carosello deve costruire otto card dati.")
	assert_eq(
		selector.get_visible_card_ids().size(), 3, "Solo centro e due anteprime devono essere visibili."
	)
	_assert_hd_portraits(registry, selector)

	selector.navigate_previous()
	assert_eq(
		selector.get_selected_definition().id, &"marghe", "PRECEDENTE da Magno deve fare wrap su Marghe."
	)
	selector.navigate_next()
	assert_eq(
		selector.get_selected_definition().id, &"magno", "SUCCESSIVO da Marghe deve fare wrap su Magno."
	)

	selector.get_next_button().pressed.emit()
	assert_eq(selector.get_selected_definition().id, &"bea", "La freccia mouse deve avanzare a Bea.")
	Input.parse_input_event(_action_event(&"ui_right"))
	await wait_process_frames(1)
	assert_eq(selector.get_selected_definition().id, &"zat", "La tastiera deve avanzare a Zat.")
	Input.parse_input_event(make_joy_button_event(JOY_BUTTON_DPAD_RIGHT, true))
	await wait_process_frames(1)
	assert_eq(selector.get_selected_definition().id, &"alea", "Il D-pad deve avanzare ad Alea.")
	Input.parse_input_event(_stick_event(1.0))
	await wait_process_frames(1)
	assert_eq(selector.get_selected_definition().id, &"aleo", "Lo stick deve avanzare ad Aleo una sola volta.")
	Input.parse_input_event(_stick_event(1.0))
	await wait_process_frames(1)
	assert_eq(
		selector.get_selected_definition().id, &"aleo", "Lo stick held non deve ripetere senza tornare al neutro."
	)
	Input.parse_input_event(_stick_event(0.0))
	await wait_process_frames(1)
	Input.parse_input_event(_stick_event(-1.0))
	await wait_process_frames(1)
	assert_eq(selector.get_selected_definition().id, &"alea", "Lo stick riarmato deve navigare indietro.")
	# Un asse fisico rimasto premuto persiste nel singleton Input ben oltre la
	# fine di questo test (a differenza di action_press/release): senza questo
	# rilascio esplicito, JOY_AXIS_LEFT_X resterebbe a -1.0 per l'intero
	# processo GUT e corromperebbe move_left/move_right nei test successivi.
	Input.parse_input_event(_stick_event(0.0))
	await wait_process_frames(1)
	var next_id := EXPECTED_IDS[posmod(selector.get_selected_index() + 1, EXPECTED_IDS.size())]
	selector.get_button(next_id).pressed.emit()
	assert_eq(
		selector.get_selected_definition().id, next_id, "Il click sull'anteprima deve usare lo stesso indice."
	)
	assert_true(
		controller.get_seed() == 0 and is_zero_approx(controller.get_run_time()),
		"La navigazione equivalente non deve avviare la run."
	)

	await _assert_touch_navigation(selector)
	selector.show_selection(&"magno")
	await wait_process_frames(1)
	for expected_index in EXPECTED_IDS.size():
		var definition := registry.resolve_definition(EXPECTED_IDS[expected_index])
		assert_eq(
			selector.get_selected_definition(), definition, "Ogni indice deve esporre il FriendDefinition corretto."
		)
		assert_eq(
			selector.get_selected_index(), expected_index, "L'indice centrale deve avanzare deterministicamente."
		)
		assert_eq(
			selector.get_visible_card_ids().size(), 3, "Ogni profilo deve conservare due anteprime."
		)
		var copy := selector.get_displayed_copy()
		assert_eq(
			copy.name, definition.get_public_display_name().to_upper(), "Il centro deve mostrare il nome dati in maiuscolo."
		)
		assert_true(
			String(copy.passive).contains(definition.get_public_passive_title().to_upper()),
			"Il centro deve mostrare la passiva dati."
		)
		assert_true(
			String(copy.ability).contains(definition.get_public_active_ability_title().to_upper()),
			"Il centro deve mostrare l'abilita dati."
		)
		selector.navigate_next()
	assert_eq(selector.get_selected_definition().id, &"magno", "Otto avanzamenti devono chiudere il ciclo.")
	await wait_seconds(0.2)
	assert_false(selector.has_active_transition(), "Le transizioni brevi non devono lasciare Tween attivi.")

	await _assert_layout_profiles(movement_slice, selector, arena_layout)
	selector.get_button(&"bea").pressed.emit()
	selector.get_confirm_button().pressed.emit()
	await wait_process_frames(2)
	assert_true(controller.is_running(), "Solo la conferma separata deve avviare la run.")
	assert_eq(
		movement_slice.get_player().get_friend_definition().id, &"bea", "La run deve usare il centro confermato."
	)

	assert_true(controller.request_defeat(), "La fixture deve poter raggiungere DEFEAT.")
	await wait_process_frames(2)
	end_screen.get_change_character_button().pressed.emit()
	await wait_process_frames(2)
	_assert_rebuilt_selector(selector, controller, &"bea", "DEFEAT")

	selector.get_confirm_button().pressed.emit()
	await wait_process_frames(2)
	assert_true(controller.request_victory(), "La fixture deve poter raggiungere VICTORY.")
	await wait_process_frames(2)
	end_screen.get_change_character_button().pressed.emit()
	await wait_process_frames(2)
	_assert_rebuilt_selector(selector, controller, &"bea", "VICTORY")

	selector.get_confirm_button().pressed.emit()
	await wait_process_frames(2)
	hud.get_pause_button().pressed.emit()
	await wait_process_frames(1)
	pause_overlay.get_change_character_button().pressed.emit()
	await wait_process_frames(1)
	pause_overlay.get_confirm_change_button().pressed.emit()
	await wait_process_frames(2)
	_assert_rebuilt_selector(selector, controller, &"bea", "PAUSA")
	controller._process(5.0)
	assert_true(
		is_zero_approx(controller.get_run_time()) and spawner.get_alive_count() == 0,
		"BOOT ricostruito non deve avanzare clock o spawn."
	)
	assert_true(lifecycle.request_back(), "Back dal carosello deve essere gestito.")
	await wait_process_frames(2)
	assert_true(welcome.visible and not selector.visible, "Back dal carosello deve tornare alla welcome.")

	if is_instance_valid(controller):
		controller.prepare_restart()


func _assert_hd_portraits(registry: FriendRegistry, selector: CharacterSelectOverlay) -> void:
	var presets := FileAccess.get_file_as_string("res://export_presets.cfg")
	assert_true(
		presets.contains("assets/art/characters/*/hd/**"), "Le sorgenti HD devono restare escluse dagli export."
	)
	for friend_id in EXPECTED_IDS:
		var definition := registry.resolve_definition(friend_id)
		var expected_runtime_path := "res://assets/art/characters/%s/generated/carousel.png" % friend_id
		var expected_hd_path := "res://assets/art/characters/%s/hd/poses.png" % friend_id
		assert_true(
			FileAccess.file_exists("res://assets/art/characters/%s/hd/.gdignore" % friend_id),
			"%s: le sorgenti HD non devono essere importate da Godot." % friend_id
		)
		assert_true(FileAccess.file_exists(expected_hd_path), "%s deve conservare il master HD." % friend_id)
		assert_not_null(
			definition.get_public_selection_portrait(), "%s deve avere il ritratto carosello." % friend_id
		)
		if definition.get_public_selection_portrait() != null:
			assert_eq(
				definition.get_public_selection_portrait().resource_path, expected_runtime_path,
				"%s deve derivare dal master HD dedicato." % friend_id
			)
			assert_eq(
				definition.get_public_selection_portrait().get_size(), Vector2(256.0, 256.0),
				"%s deve usare un derivato UI 256x256." % friend_id
			)
		assert_eq(
			selector.get_button(friend_id).icon, definition.get_public_selection_portrait(),
			"%s deve mostrare il ritratto dati nella card." % friend_id
		)


func _assert_touch_navigation(selector: CharacterSelectOverlay) -> void:
	var start_index := selector.get_selected_index()
	var carousel_center := selector.get_carousel_rect().get_center()
	var press := make_touch_event(7, true, carousel_center)
	var drag := make_drag_event(7, carousel_center + Vector2(-84.0, 2.0), Vector2.ZERO)
	var release := make_touch_event(7, false, drag.position)
	assert_false(
		selector.handle_touch_event_for_test(press), "Il touch-down sul carosello deve permettere un tap."
	)
	assert_true(
		selector.handle_touch_event_for_test(drag), "Uno swipe orizzontale deve consumare il drag."
	)
	assert_true(
		selector.handle_touch_event_for_test(release), "Il rilascio dello swipe deve restare consumato."
	)
	assert_eq(
		selector.get_selected_index(), posmod(start_index + 1, EXPECTED_IDS.size()),
		"Swipe a sinistra deve avanzare una sola card."
	)

	var tap_index := selector.get_selected_index()
	var tap_press := make_touch_event(8, true, carousel_center)
	var tap_release := make_touch_event(8, false, carousel_center + Vector2(3.0, 1.0))
	assert_false(
		selector.handle_touch_event_for_test(tap_press), "Un tap deve iniziare senza essere consumato."
	)
	assert_false(
		selector.handle_touch_event_for_test(tap_release), "Un tap breve non deve diventare swipe."
	)
	assert_eq(
		selector.get_selected_index(), tap_index, "Un tap sulla card centrale non deve cambiare indice."
	)
	await wait_seconds(0.7)
	var preview_center := (
		selector.get_preview_card_rect(1).intersection(selector.get_carousel_rect()).get_center()
	)
	var preview_press := make_touch_event(10, true, preview_center)
	var preview_release := make_touch_event(10, false, preview_center)
	assert_false(
		selector.handle_touch_event_for_test(preview_press), "Il touch-down sull'anteprima deve restare un tap."
	)
	assert_false(
		selector.handle_touch_event_for_test(preview_release),
		"Il rilascio sull'anteprima deve raggiungere il Button nativo."
	)
	assert_eq(
		selector.get_selected_index(), tap_index, "Il touch grezzo non deve anticipare il click emulato del Button."
	)
	var preview_target := EXPECTED_IDS[posmod(tap_index + 1, EXPECTED_IDS.size())]
	selector.get_button(preview_target).pressed.emit()
	assert_eq(
		selector.get_selected_index(), posmod(tap_index + 1, EXPECTED_IDS.size()),
		"Il Button dell'anteprima destra deve avanzare una sola card."
	)
	var touch_selected_index := selector.get_selected_index()
	selector.get_button(preview_target).pressed.emit()
	assert_eq(
		selector.get_selected_index(), touch_selected_index,
		"Un duplicato sullo stesso Button non deve avanzare una seconda card."
	)

	var confirm_center := selector.get_confirm_button().get_global_rect().get_center()
	var drag_press := make_touch_event(9, true, confirm_center)
	var drag_move := make_drag_event(9, confirm_center + Vector2(0.0, 30.0), Vector2.ZERO)
	var drag_release := make_touch_event(9, false, drag_move.position)
	selector.handle_touch_event_for_test(drag_press)
	assert_true(
		selector.handle_touch_event_for_test(drag_move), "Un drag su un'azione deve essere consumato."
	)
	assert_true(
		selector.handle_touch_event_for_test(drag_release),
		"Il rilascio trascinato non deve diventare tap su conferma o Back."
	)


func _assert_layout_profiles(
	movement_slice: Control, selector: CharacterSelectOverlay, arena_layout: ArenaLayout
) -> void:
	for profile in LAYOUT_PROFILES:
		get_tree().root.content_scale_size = profile
		get_tree().root.size = profile
		arena_layout.refresh_layout()
		await wait_process_frames(2)
		var safe_area := arena_layout.get_safe_area_rect()
		var panel_rect := selector.get_selection_panel_rect()
		var carousel_rect := selector.get_carousel_rect()
		var center_rect := selector.get_center_card_rect()
		var previous_visible := selector.get_preview_card_rect(-1).intersection(carousel_rect)
		var next_visible := selector.get_preview_card_rect(1).intersection(carousel_rect)
		var confirm_rect := selector.get_confirm_button().get_global_rect()
		var back_rect := selector.get_back_button().get_global_rect()
		assert_true(safe_area.encloses(panel_rect), "%s: il pannello deve restare nella safe area." % profile)
		assert_true(carousel_rect.encloses(center_rect), "%s: il profilo centrale deve restare leggibile." % profile)
		assert_true(
			previous_visible.size.x >= 44.0 and next_visible.size.x >= 44.0,
			"%s: le anteprime parziali devono restare cliccabili." % profile
		)
		assert_false(
			center_rect.intersects(selector.get_preview_card_rect(-1)),
			"%s: centro e anteprima sinistra non devono sovrapporsi." % profile
		)
		assert_false(
			center_rect.intersects(selector.get_preview_card_rect(1)),
			"%s: centro e anteprima destra non devono sovrapporsi." % profile
		)
		assert_true(
			safe_area.encloses(confirm_rect) and safe_area.encloses(back_rect),
			"%s: conferma e Back devono restare nella safe area." % profile
		)
		assert_true(
			confirm_rect.size.x >= 44.0 and confirm_rect.size.y >= 44.0,
			"%s: la conferma deve mantenere il target minimo 44x44." % profile
		)
		assert_true(
			not confirm_rect.intersects(carousel_rect) and not back_rect.intersects(carousel_rect),
			"%s: carosello e azioni non devono sovrapporsi." % profile
		)
		assert_false(
			confirm_rect.intersects(back_rect), "%s: conferma e Back devono restare separati." % profile
		)
	get_tree().root.content_scale_size = LAYOUT_PROFILES[0]
	get_tree().root.size = LAYOUT_PROFILES[0]
	arena_layout.refresh_layout()
	await wait_process_frames(2)


func _assert_rebuilt_selector(
	selector: CharacterSelectOverlay, controller: RunController, expected_id: StringName, source: String
) -> void:
	assert_eq(
		controller.get_state(), RunController.RunState.BOOT, "%s deve ricostruire il selettore in BOOT." % source
	)
	assert_true(
		selector.visible and selector.get_selected_definition().id == expected_id,
		"%s deve ricostruire il profilo centrale corrente." % source
	)
	assert_eq(
		selector.get_visible_card_ids().size(), 3, "%s deve ricostruire centro e anteprime." % source
	)
	assert_false(selector.has_active_transition(), "%s non deve lasciare Tween residui." % source)


func _action_event(action: StringName) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	return event


func _stick_event(value: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.axis = JOY_AXIS_LEFT_X
	event.axis_value = value
	return event
