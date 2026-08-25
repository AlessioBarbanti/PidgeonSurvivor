extends SceneTree

const MOVEMENT_SLICE_SCENE := preload("res://scenes/game/movement_slice.tscn")
const INITIAL_VIEWPORT_SIZE := Vector2i(1280, 720)
const EXPECTED_IDS: Array[StringName] = [
	&"magno",
	&"bea",
	&"zat",
	&"alea",
	&"aleo",
	&"lollo",
	&"migi",
	&"marghe",
]
const LAYOUT_PROFILES := [
	Vector2i(1280, 720),
	Vector2i(1600, 720),
	Vector2i(960, 720),
]

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	paused = false
	root.content_scale_size = INITIAL_VIEWPORT_SIZE
	root.size = INITIAL_VIEWPORT_SIZE
	await _wait_processed_frame()
	await _validate_character_carousel()
	await _finish()


func _validate_character_carousel() -> void:
	ProjectSettings.set_setting("application/run/b18o_force_welcome_for_test", true)
	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	root.add_child(movement_slice)
	ProjectSettings.set_setting("application/run/b18o_force_welcome_for_test", false)
	await _wait_processed_frame()

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

	_expect(
		controller != null and welcome != null and selector != null and registry != null,
		"Il frontend B18T deve essere composto."
	)
	if controller == null or welcome == null or selector == null or registry == null:
		await _dispose(movement_slice, controller)
		return

	welcome.get_play_button().pressed.emit()
	await _wait_processed_frame()
	_expect(selector.visible and not welcome.visible, "GIOCA deve aprire il carosello.")
	_expect(controller.get_state() == RunController.RunState.BOOT, "Il carosello deve restare in BOOT.")
	_expect(controller.get_seed() == 0 and is_zero_approx(controller.get_run_time()), "Il carosello non deve creare seed o clock.")
	_expect(spawner.get_alive_count() == 0 and router.is_input_suspended(), "Spawn e input gameplay devono restare inattivi.")
	_expect(selector.get_definition_ids() == EXPECTED_IDS, "Il carosello deve conservare l'ordine dichiarativo degli otto amici.")
	_expect(selector.get_roster_size() == 8, "Il carosello deve costruire otto card dati.")
	_expect(selector.get_visible_card_ids().size() == 3, "Solo centro e due anteprime devono essere visibili.")
	_validate_hd_portraits(registry, selector)

	selector.navigate_previous()
	_expect(selector.get_selected_definition().id == &"marghe", "PRECEDENTE da Magno deve fare wrap su Marghe.")
	selector.navigate_next()
	_expect(selector.get_selected_definition().id == &"magno", "SUCCESSIVO da Marghe deve fare wrap su Magno.")

	selector.get_next_button().pressed.emit()
	_expect(selector.get_selected_definition().id == &"bea", "La freccia mouse deve avanzare a Bea.")
	Input.parse_input_event(_action(&"ui_right"))
	await process_frame
	_expect(selector.get_selected_definition().id == &"zat", "La tastiera deve avanzare a Zat.")
	Input.parse_input_event(_dpad(JOY_BUTTON_DPAD_RIGHT))
	await process_frame
	_expect(selector.get_selected_definition().id == &"alea", "Il D-pad deve avanzare ad Alea.")
	Input.parse_input_event(_stick(1.0))
	await process_frame
	_expect(selector.get_selected_definition().id == &"aleo", "Lo stick deve avanzare ad Aleo una sola volta.")
	Input.parse_input_event(_stick(1.0))
	await process_frame
	_expect(selector.get_selected_definition().id == &"aleo", "Lo stick held non deve ripetere senza tornare al neutro.")
	Input.parse_input_event(_stick(0.0))
	await process_frame
	Input.parse_input_event(_stick(-1.0))
	await process_frame
	_expect(selector.get_selected_definition().id == &"alea", "Lo stick riarmato deve navigare indietro.")
	var next_id := EXPECTED_IDS[posmod(selector.get_selected_index() + 1, EXPECTED_IDS.size())]
	selector.get_button(next_id).pressed.emit()
	_expect(selector.get_selected_definition().id == next_id, "Il click sull'anteprima deve usare lo stesso indice.")
	_expect(controller.get_seed() == 0 and is_zero_approx(controller.get_run_time()), "La navigazione equivalente non deve avviare la run.")

	await _validate_touch_navigation(selector)
	selector.show_selection(&"magno")
	await process_frame
	for expected_index in EXPECTED_IDS.size():
		var definition := registry.resolve_definition(EXPECTED_IDS[expected_index])
		_expect(selector.get_selected_definition() == definition, "Ogni indice deve esporre il FriendDefinition corretto.")
		_expect(selector.get_selected_index() == expected_index, "L'indice centrale deve avanzare deterministicamente.")
		_expect(selector.get_visible_card_ids().size() == 3, "Ogni profilo deve conservare due anteprime.")
		var copy := selector.get_displayed_copy()
		_expect(copy.name == definition.get_public_display_name(), "Il centro deve mostrare il nome dati con maiuscola naturale.")
		_expect(String(copy.passive).contains(definition.get_public_passive_title()), "Il centro deve mostrare la passiva dati.")
		_expect(String(copy.ability).contains(definition.get_public_active_ability_title()), "Il centro deve mostrare l'abilita dati.")
		selector.navigate_next()
	_expect(selector.get_selected_definition().id == &"magno", "Otto avanzamenti devono chiudere il ciclo.")
	await create_timer(0.2).timeout
	_expect(not selector.has_active_transition(), "Le transizioni brevi non devono lasciare Tween attivi.")

	await _validate_layout_profiles(movement_slice, selector, arena_layout)
	selector.get_button(&"bea").pressed.emit()
	selector.get_confirm_button().pressed.emit()
	await _wait_processed_frame()
	_expect(controller.is_running(), "Solo la conferma separata deve avviare la run.")
	_expect(movement_slice.get_player().get_friend_definition().id == &"bea", "La run deve usare il centro confermato.")

	_expect(controller.request_defeat(), "La fixture deve poter raggiungere DEFEAT.")
	await _wait_processed_frame()
	end_screen.get_change_character_button().pressed.emit()
	await _wait_processed_frame()
	_validate_rebuilt_selector(selector, controller, &"bea", "DEFEAT")

	selector.get_confirm_button().pressed.emit()
	await _wait_processed_frame()
	_expect(controller.request_victory(), "La fixture deve poter raggiungere VICTORY.")
	await _wait_processed_frame()
	end_screen.get_change_character_button().pressed.emit()
	await _wait_processed_frame()
	_validate_rebuilt_selector(selector, controller, &"bea", "VICTORY")

	selector.get_confirm_button().pressed.emit()
	await _wait_processed_frame()
	hud.get_pause_button().pressed.emit()
	await process_frame
	pause_overlay.get_change_character_button().pressed.emit()
	await process_frame
	pause_overlay.get_confirm_change_button().pressed.emit()
	await _wait_processed_frame()
	_validate_rebuilt_selector(selector, controller, &"bea", "PAUSA")
	controller._process(5.0)
	_expect(is_zero_approx(controller.get_run_time()) and spawner.get_alive_count() == 0, "BOOT ricostruito non deve avanzare clock o spawn.")
	_expect(lifecycle.request_back(), "Back dal carosello deve essere gestito.")
	await _wait_processed_frame()
	_expect(welcome.visible and not selector.visible, "Back dal carosello deve tornare alla welcome.")

	await _dispose(movement_slice, controller)


func _validate_hd_portraits(registry: FriendRegistry, selector: CharacterSelectOverlay) -> void:
	var presets := FileAccess.get_file_as_string("res://export_presets.cfg")
	_expect(presets.contains("assets/art/characters/players/hd/**"), "Le sorgenti HD devono restare escluse dagli export.")
	_expect(FileAccess.file_exists("res://assets/art/characters/players/hd/.gdignore"), "Le sorgenti HD non devono essere importate da Godot.")
	for friend_id in EXPECTED_IDS:
		var definition := registry.resolve_definition(friend_id)
		var expected_runtime_path := "res://assets/art/characters/players/carousel/%s.png" % friend_id
		var expected_hd_path := "res://assets/art/characters/players/hd/%s_source.png" % friend_id
		_expect(FileAccess.file_exists(expected_hd_path), "%s deve conservare il master HD." % friend_id)
		_expect(definition.get_public_selection_portrait() != null, "%s deve avere il ritratto carosello." % friend_id)
		if definition.get_public_selection_portrait() != null:
			_expect(definition.get_public_selection_portrait().resource_path == expected_runtime_path, "%s deve derivare dal master HD dedicato." % friend_id)
			_expect(definition.get_public_selection_portrait().get_size() == Vector2(256.0, 256.0), "%s deve usare un derivato UI 256x256." % friend_id)
		_expect(selector.get_button(friend_id).icon == definition.get_public_selection_portrait(), "%s deve mostrare il ritratto dati nella card." % friend_id)


func _validate_touch_navigation(selector: CharacterSelectOverlay) -> void:
	var start_index := selector.get_selected_index()
	var carousel_center := selector.get_carousel_rect().get_center()
	var press := _screen_touch(7, carousel_center, true)
	var drag := _screen_drag(7, carousel_center + Vector2(-84.0, 2.0))
	var release := _screen_touch(7, drag.position, false)
	_expect(not selector.handle_touch_event_for_test(press), "Il touch-down sul carosello deve permettere un tap.")
	_expect(selector.handle_touch_event_for_test(drag), "Uno swipe orizzontale deve consumare il drag.")
	_expect(selector.handle_touch_event_for_test(release), "Il rilascio dello swipe deve restare consumato.")
	_expect(selector.get_selected_index() == posmod(start_index + 1, EXPECTED_IDS.size()), "Swipe a sinistra deve avanzare una sola card.")

	var tap_index := selector.get_selected_index()
	var tap_press := _screen_touch(8, carousel_center, true)
	var tap_release := _screen_touch(8, carousel_center + Vector2(3.0, 1.0), false)
	_expect(not selector.handle_touch_event_for_test(tap_press), "Un tap deve iniziare senza essere consumato.")
	_expect(not selector.handle_touch_event_for_test(tap_release), "Un tap breve non deve diventare swipe.")
	_expect(selector.get_selected_index() == tap_index, "Un tap sulla card centrale non deve cambiare indice.")
	await create_timer(0.7).timeout
	var preview_center := selector.get_preview_card_rect(1).intersection(selector.get_carousel_rect()).get_center()
	var preview_press := _screen_touch(10, preview_center, true)
	var preview_release := _screen_touch(10, preview_center, false)
	_expect(not selector.handle_touch_event_for_test(preview_press), "Il touch-down sull'anteprima deve restare un tap.")
	_expect(not selector.handle_touch_event_for_test(preview_release), "Il rilascio sull'anteprima deve raggiungere il Button nativo.")
	_expect(selector.get_selected_index() == tap_index, "Il touch grezzo non deve anticipare il click emulato del Button.")
	var preview_target := EXPECTED_IDS[posmod(tap_index + 1, EXPECTED_IDS.size())]
	selector.get_button(preview_target).pressed.emit()
	_expect(selector.get_selected_index() == posmod(tap_index + 1, EXPECTED_IDS.size()), "Il Button dell'anteprima destra deve avanzare una sola card.")
	var touch_selected_index := selector.get_selected_index()
	selector.get_button(preview_target).pressed.emit()
	_expect(selector.get_selected_index() == touch_selected_index, "Un duplicato sullo stesso Button non deve avanzare una seconda card.")

	var confirm_center := selector.get_confirm_button().get_global_rect().get_center()
	var drag_press := _screen_touch(9, confirm_center, true)
	var drag_move := _screen_drag(9, confirm_center + Vector2(0.0, 30.0))
	var drag_release := _screen_touch(9, drag_move.position, false)
	selector.handle_touch_event_for_test(drag_press)
	_expect(selector.handle_touch_event_for_test(drag_move), "Un drag su un'azione deve essere consumato.")
	_expect(selector.handle_touch_event_for_test(drag_release), "Il rilascio trascinato non deve diventare tap su conferma o Back.")


func _validate_layout_profiles(movement_slice: Control, selector: CharacterSelectOverlay, arena_layout: ArenaLayout) -> void:
	for profile in LAYOUT_PROFILES:
		root.content_scale_size = profile
		root.size = profile
		arena_layout.refresh_layout()
		await _wait_processed_frame()
		var safe_area := arena_layout.get_safe_area_rect()
		var panel_rect := selector.get_selection_panel_rect()
		var carousel_rect := selector.get_carousel_rect()
		var center_rect := selector.get_center_card_rect()
		var previous_visible := selector.get_preview_card_rect(-1).intersection(carousel_rect)
		var next_visible := selector.get_preview_card_rect(1).intersection(carousel_rect)
		var confirm_rect := selector.get_confirm_button().get_global_rect()
		var back_rect := selector.get_back_button().get_global_rect()
		_expect(safe_area.encloses(panel_rect), "%s: il pannello deve restare nella safe area." % profile)
		_expect(carousel_rect.encloses(center_rect), "%s: il profilo centrale deve restare leggibile." % profile)
		_expect(previous_visible.size.x >= 44.0 and next_visible.size.x >= 44.0, "%s: le anteprime parziali devono restare cliccabili." % profile)
		_expect(not center_rect.intersects(selector.get_preview_card_rect(-1)), "%s: centro e anteprima sinistra non devono sovrapporsi." % profile)
		_expect(not center_rect.intersects(selector.get_preview_card_rect(1)), "%s: centro e anteprima destra non devono sovrapporsi." % profile)
		_expect(safe_area.encloses(confirm_rect) and safe_area.encloses(back_rect), "%s: conferma e Back devono restare nella safe area." % profile)
		_expect(confirm_rect.size.x >= 44.0 and confirm_rect.size.y >= 44.0, "%s: la conferma deve mantenere il target minimo 44x44." % profile)
		_expect(not confirm_rect.intersects(carousel_rect) and not back_rect.intersects(carousel_rect), "%s: carosello e azioni non devono sovrapporsi." % profile)
		_expect(not confirm_rect.intersects(back_rect), "%s: conferma e Back devono restare separati." % profile)
	root.content_scale_size = INITIAL_VIEWPORT_SIZE
	root.size = INITIAL_VIEWPORT_SIZE
	arena_layout.refresh_layout()
	await _wait_processed_frame()


func _validate_rebuilt_selector(selector: CharacterSelectOverlay, controller: RunController, expected_id: StringName, source: String) -> void:
	_expect(controller.get_state() == RunController.RunState.BOOT, "%s deve ricostruire il selettore in BOOT." % source)
	_expect(selector.visible and selector.get_selected_definition().id == expected_id, "%s deve ricostruire il profilo centrale corrente." % source)
	_expect(selector.get_visible_card_ids().size() == 3, "%s deve ricostruire centro e anteprime." % source)
	_expect(not selector.has_active_transition(), "%s non deve lasciare Tween residui." % source)


func _dispose(movement_slice: Node, controller: RunController) -> void:
	if is_instance_valid(controller):
		controller.prepare_restart()
	paused = false
	if is_instance_valid(movement_slice):
		movement_slice.queue_free()
	await process_frame


func _wait_processed_frame() -> void:
	await process_frame
	await process_frame


func _action(action: StringName) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	return event


func _dpad(button_index: JoyButton) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = button_index
	event.pressed = true
	return event


func _stick(value: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.axis = JOY_AXIS_LEFT_X
	event.axis_value = value
	return event


func _screen_touch(index: int, position: Vector2, pressed: bool) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = pressed
	return event


func _screen_drag(index: int, position: Vector2) -> InputEventScreenDrag:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = position
	return event


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	paused = false
	await process_frame
	if _failures.is_empty():
		print("B18T_CHARACTER_CAROUSEL_SMOKE_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	printerr("B18T_CHARACTER_CAROUSEL_SMOKE_FAIL count=%d" % _failures.size())
	quit(1)
