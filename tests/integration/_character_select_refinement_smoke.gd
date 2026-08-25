extends SceneTree

const MOVEMENT_SLICE_SCENE := preload("res://scenes/game/movement_slice.tscn")
const INITIAL_VIEWPORT_SIZE := Vector2i(1280, 720)
const EXPECTED_IDS: Array[StringName] = [
	&"magno", &"bea", &"zat", &"alea", &"aleo", &"lollo", &"migi", &"marghe",
]
const EXPECTED_PASSIVE_ICON_PATHS := {
	&"magno": "res://assets/art/icons/passives/generated/magno_aerodynamic_flow.png",
	&"bea": "res://assets/art/icons/passives/generated/bea_sixth_sense.png",
	&"zat": "res://assets/art/icons/passives/generated/zat_delayed_healing.png",
	&"alea": "res://assets/art/icons/passives/generated/alea_eagle_never_misses.png",
	&"aleo": "res://assets/art/icons/passives/generated/aleo_solid_structure.png",
	&"lollo": "res://assets/art/icons/passives/generated/lollo_hyperactivity.png",
	&"migi": "res://assets/art/icons/passives/generated/migi_turtle_shell.png",
	&"marghe": "res://assets/art/icons/passives/generated/marghe_contagious_smile.png",
}
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
	await _validate_refined_selector()
	await _finish()


func _validate_refined_selector() -> void:
	ProjectSettings.set_setting("application/run/b18o_force_welcome_for_test", true)
	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	root.add_child(movement_slice)
	ProjectSettings.set_setting("application/run/b18o_force_welcome_for_test", false)
	await _wait_processed_frame()

	var controller := movement_slice.get_run_controller() as RunController
	var welcome := movement_slice.get_welcome_screen() as WelcomeScreen
	var selector := movement_slice.get_character_select_overlay() as CharacterSelectOverlay
	var friends := movement_slice.get_friend_registry() as FriendRegistry
	var abilities := movement_slice.get_ability_effect_registry() as AbilityEffectRegistry
	var arena_layout := movement_slice.get_node("ArenaLayout") as ArenaLayout
	_expect(
		controller != null and welcome != null and selector != null and friends != null and abilities != null,
		"Il frontend B18W deve essere composto con entrambi i registry dati."
	)
	if controller == null or welcome == null or selector == null or friends == null or abilities == null:
		await _dispose(movement_slice, controller)
		return

	welcome.get_play_button().pressed.emit()
	await _wait_processed_frame()
	_expect(selector.visible and controller.get_state() == RunController.RunState.BOOT, "B18W deve aprirsi in BOOT.")
	_validate_hierarchy(selector)
	_validate_focus_contract(selector)

	for expected_id in EXPECTED_IDS:
		var definition := friends.resolve_definition(expected_id)
		var ability := abilities.resolve_definition(definition.active_ability_id)
		var copy := selector.get_displayed_copy()
		_expect(selector.get_selected_definition() == definition, "%s deve essere il profilo centrale." % expected_id)
		_expect(copy.kit_title == "KIT DI %s" % definition.get_public_display_name().to_upper(), "%s deve collegare il kit al profilo centrale." % expected_id)
		_expect(copy.name == definition.get_public_display_name(), "%s deve mantenere la maiuscola naturale." % expected_id)
		_expect(copy.role == definition.get_public_role(), "%s deve aggiornare atomicamente il ruolo." % expected_id)
		_expect(copy.passive_title == definition.get_public_passive_title(), "%s deve aggiornare il nome passiva." % expected_id)
		_expect(copy.passive_description == definition.get_public_passive_description(), "%s deve aggiornare la descrizione passiva." % expected_id)
		_expect(copy.ability_title == definition.get_public_active_ability_title(), "%s deve aggiornare il nome abilita." % expected_id)
		_expect(copy.ability_description == definition.get_public_active_ability_description(), "%s deve aggiornare la descrizione abilita." % expected_id)
		_expect(selector.get_passive_icon() == definition.get_public_passive_icon(), "%s deve trattare la passiva con un'icona." % expected_id)
		_expect(
			definition.get_public_passive_icon() != null
			and definition.get_public_passive_icon().resource_path == EXPECTED_PASSIVE_ICON_PATHS[expected_id],
			"%s deve usare la propria icona passiva runtime elaborata." % expected_id
		)
		_expect(selector.get_ability_icon() == ability.icon, "%s deve mostrare l'icona B18M registrata." % expected_id)
		_expect(selector.get_confirm_button().text == "Gioca con %s" % definition.get_public_display_name(), "%s deve aggiornare il CTA naturale." % expected_id)
		selector.navigate_next()
	_expect(selector.get_selected_definition().id == &"magno", "Otto profili devono chiudere il ciclo B18W.")
	selector.navigate_previous()
	_expect(selector.get_displayed_copy().ability_title == "Reggeton time!", "Il nome approvato Reggeton time! non deve essere abbreviato.")
	selector.navigate_next()

	selector.get_next_button().pressed.emit()
	_expect(selector.get_selected_definition().id == &"bea", "La freccia integrata deve navigare senza confermare.")
	var start_index := selector.get_selected_index()
	var center := selector.get_carousel_rect().get_center()
	selector.handle_touch_event_for_test(_screen_touch(3, center, true))
	_expect(selector.handle_touch_event_for_test(_screen_drag(3, center + Vector2(-80.0, 1.0))), "Lo swipe B18W deve consumare il drag.")
	_expect(selector.handle_touch_event_for_test(_screen_touch(3, center + Vector2(-80.0, 1.0), false)), "Il rilascio dello swipe deve restare consumato.")
	_expect(selector.get_selected_index() == posmod(start_index + 1, EXPECTED_IDS.size()), "Lo swipe deve aggiornare lo stesso indice.")
	_expect(controller.get_seed() == 0 and is_zero_approx(controller.get_run_time()), "Frecce e swipe non devono avviare la run.")

	await create_timer(0.2).timeout
	_expect(not selector.has_active_transition(), "La transizione B18W deve chiudersi prima del layout stabile.")
	await _validate_layouts(selector, arena_layout)
	selector.show_selection(&"magno")
	await _wait_processed_frame()
	selector.get_back_button().pressed.emit()
	await _wait_processed_frame()
	_expect(welcome.visible and not selector.visible, "Back alto deve tornare alla welcome.")
	_expect(controller.get_state() == RunController.RunState.BOOT and controller.get_seed() == 0, "Back alto deve conservare BOOT senza seed.")

	welcome.get_play_button().pressed.emit()
	await _wait_processed_frame()
	selector.get_button(&"marghe").pressed.emit()
	selector.get_confirm_button().pressed.emit()
	await _wait_processed_frame()
	_expect(controller.is_running(), "Soltanto il CTA arancione deve avviare la run.")
	_expect(movement_slice.get_player().get_friend_definition().id == &"marghe", "Il CTA deve confermare il profilo centrale.")

	await _dispose(movement_slice, controller)


func _validate_hierarchy(selector: CharacterSelectOverlay) -> void:
	var backdrop := selector.get_backdrop()
	var panel_rect := selector.get_selection_panel_rect()
	var back_rect := selector.get_back_button().get_global_rect()
	var title_rect := selector.get_title_rect()
	var carousel_rect := selector.get_carousel_rect()
	var center_rect := selector.get_center_card_rect()
	var ability_rect := selector.get_ability_panel_rect()
	var name_rect := selector.get_name_rect()
	var role_rect := selector.get_role_rect()
	var confirm_rect := selector.get_confirm_button().get_global_rect()
	_expect(
		backdrop != null
		and backdrop.texture != null
		and backdrop.texture.resource_path == "res://assets/art/ui/character_select/character_select_backdrop.png",
		"B18W deve usare il fondale pixel-art tracciato."
	)
	_expect(
		FileAccess.file_exists("res://assets/art/ui/character_select/ASSET-MANIFEST.md"),
		"Il fondale B18W deve avere prompt, licenza e hash nel manifest."
	)
	_expect(
		FileAccess.file_exists("res://assets/art/icons/passives/ASSET-MANIFEST.md"),
		"L'icona passiva B18W deve avere prompt, licenza e hash nel manifest."
	)
	_expect(EXPECTED_PASSIVE_ICON_PATHS.size() == EXPECTED_IDS.size(), "Ogni profilo B18W deve avere una mappa icona passiva dedicata.")
	for passive_icon_path in EXPECTED_PASSIVE_ICON_PATHS.values():
		_expect(FileAccess.file_exists(passive_icon_path), "L'icona passiva runtime deve esistere: %s." % passive_icon_path)
	_expect(back_rect.position.x < title_rect.get_center().x, "Back deve essere separato in alto a sinistra.")
	_expect(back_rect.end.y <= title_rect.position.y, "Back non deve restare come azione inferiore.")
	_expect(back_rect.size.x <= 140.0 and back_rect.size.y <= 44.0, "Back deve restare piccolo e discreto.")
	_expect(not selector.has_node("Center/SelectionPanel/Content/Subtitle"), "Il sottotitolo istruttivo superfluo deve essere rimosso.")
	_expect(center_rect.size.x > selector.get_preview_card_rect(1).size.x, "La card centrale deve predominare sulle anteprime.")
	_expect(carousel_rect.encloses(selector.get_preview_card_rect(-1)) and carousel_rect.encloses(selector.get_preview_card_rect(1)), "Le anteprime devono essere mini-card complete, non tagliate.")
	_expect(ability_rect.position.x > carousel_rect.end.x, "Il pannello abilita deve essere laterale al carosello.")
	_expect(ability_rect.position.x - carousel_rect.end.x <= 70.0, "Personaggio e kit devono dialogare senza una frattura eccessiva.")
	_expect(ability_rect.size.x >= 370.0 and ability_rect.size.x <= 390.0, "Il pannello kit deve bilanciare il peso del carosello.")
	_expect(ability_rect.size.y <= 400.0, "Il pannello kit non deve tornare a essere una scheda tecnica vuota.")
	_expect(role_rect.position.y - name_rect.end.y >= 6.0 and role_rect.position.y - name_rect.end.y <= 12.0, "Nome e ruolo devono formare un unico blocco compatto.")
	_expect(confirm_rect.position.y - role_rect.end.y <= 34.0, "Il CTA deve seguire il blocco identità senza una terra di nessuno.")
	_expect(confirm_rect.position.y >= ability_rect.end.y, "Il CTA deve chiudere la gerarchia in basso.")
	_expect(panel_rect.encloses(back_rect) and panel_rect.encloses(confirm_rect), "Back e CTA devono restare nel pannello.")
	_expect(confirm_rect.size.x <= panel_rect.size.x * 0.55, "Il CTA deve essere più corto senza perdere dominanza.")
	_expect(panel_rect.end.y - confirm_rect.end.y >= 30.0, "Il CTA deve lasciare visibile la cornice inferiore.")
	_expect(selector.get_back_button().text == "← Indietro", "Back deve avere copy e icona distinti dalle frecce.")
	var center_style := selector.get_button(&"magno").get_theme_stylebox("normal") as StyleBoxFlat
	_expect(center_style != null and center_style.get_corner_radius(CORNER_TOP_LEFT) <= 2 and center_style.get_border_width(SIDE_LEFT) <= 2, "La card centrale deve usare un bordo pixelato sottile.")
	var arrow_style := selector.get_next_button().get_theme_stylebox("normal") as StyleBoxFlat
	_expect(arrow_style != null and arrow_style.get_corner_radius(CORNER_TOP_LEFT) <= 2, "Le frecce non devono usare il cerchio cyan moderno.")
	_expect(selector.get_next_button().size.x <= 46.0, "Le frecce pixel-fantasy devono restare compatte.")
	var cta_style := selector.get_confirm_button().get_theme_stylebox("normal") as StyleBoxTexture
	_expect(cta_style != null and cta_style.texture != null, "Il CTA dominante deve usare la placca ImageGen tracciata.")
	_expect(FileAccess.file_exists("res://assets/art/ui/character_select/character_select_cta_base.png"), "La placca CTA runtime deve esistere.")
	var cta_count := 0
	for node in selector.find_children("*", "Button", true, false):
		var button := node as Button
		if button.text.begins_with("Gioca con "):
			cta_count += 1
	_expect(cta_count == 1, "Il selettore deve esporre un solo CTA dominante.")


func _validate_focus_contract(selector: CharacterSelectOverlay) -> void:
	var current := selector.get_button(selector.get_selected_definition().id)
	var back := selector.get_back_button()
	var confirm := selector.get_confirm_button()
	_expect(back.focus_neighbor_bottom == back.get_path_to(current), "Focus da Back deve scendere al profilo centrale.")
	_expect(current.focus_neighbor_top == current.get_path_to(back), "Focus dal profilo deve risalire a Back.")
	_expect(current.focus_neighbor_bottom == current.get_path_to(confirm), "Focus dal profilo deve scendere al CTA.")
	_expect(confirm.focus_neighbor_top == confirm.get_path_to(current), "Focus dal CTA deve tornare al profilo.")


func _validate_layouts(selector: CharacterSelectOverlay, arena_layout: ArenaLayout) -> void:
	for profile in LAYOUT_PROFILES:
		root.content_scale_size = profile
		root.size = profile
		arena_layout.refresh_layout()
		await _wait_processed_frame()
		var safe_area := arena_layout.get_safe_area_rect()
		var panel_rect := selector.get_selection_panel_rect()
		var back_rect := selector.get_back_button().get_global_rect()
		var carousel_rect := selector.get_carousel_rect()
		var center_rect := selector.get_center_card_rect()
		var ability_rect := selector.get_ability_panel_rect()
		var confirm_rect := selector.get_confirm_button().get_global_rect()
		_expect(safe_area.encloses(panel_rect), "%s: il pannello B18W deve restare nella safe area." % profile)
		_expect(carousel_rect.encloses(center_rect), "%s: il profilo centrale deve restare intero." % profile)
		_expect(not center_rect.intersects(ability_rect), "%s: profilo e pannello abilita non devono sovrapporsi." % profile)
		_expect(not ability_rect.intersects(confirm_rect), "%s: pannello abilita e CTA non devono sovrapporsi." % profile)
		_expect(safe_area.encloses(back_rect) and safe_area.encloses(confirm_rect), "%s: Back e CTA devono restare nella safe area." % profile)
		_expect(confirm_rect.size.x >= 44.0 and confirm_rect.size.y >= 44.0, "%s: il CTA deve conservare il target 44x44." % profile)
	root.content_scale_size = INITIAL_VIEWPORT_SIZE
	root.size = INITIAL_VIEWPORT_SIZE
	arena_layout.refresh_layout()
	await _wait_processed_frame()


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


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	paused = false
	await process_frame
	if _failures.is_empty():
		print("B18W_CHARACTER_SELECT_REFINEMENT_SMOKE_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	printerr("B18W_CHARACTER_SELECT_REFINEMENT_SMOKE_FAIL count=%d" % _failures.size())
	quit(1)
