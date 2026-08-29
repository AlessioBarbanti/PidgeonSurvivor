extends GutGameplayTest

const EXPECTED_IDS: Array[StringName] = [
	&"magno", &"bea", &"zat", &"alea", &"aleo", &"lollo", &"migi", &"marghe",
]
const EXPECTED_PASSIVE_ICON_PATHS := {
	&"magno": "res://assets/art/icons/passives/generated/magno_aerodynamic_flow.png",
	&"bea": "res://assets/art/icons/passives/generated/bea_sixth_sense.png",
	&"zat": "res://assets/art/icons/passives/generated/zat_delayed_healing.png",
	&"alea": "res://assets/art/icons/passives/generated/alea_eagle_never_misses.png",
	&"aleo": "res://assets/art/icons/passives/generated/aleo_internal_thermostat.png",
	&"lollo": "res://assets/art/icons/passives/generated/lollo_hyperactivity.png",
	&"migi": "res://assets/art/icons/passives/generated/migi_turtle_shell.png",
	&"marghe": "res://assets/art/icons/passives/generated/marghe_contagious_smile.png",
}
const LAYOUT_PROFILES := [
	Vector2i(1280, 720),
	Vector2i(1600, 720),
	Vector2i(960, 720),
]


func test_refined_selector_contract() -> void:
	ProjectSettings.set_setting("application/run/b18o_force_welcome_for_test", true)
	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	add_child_autofree(movement_slice)
	ProjectSettings.set_setting("application/run/b18o_force_welcome_for_test", false)
	await wait_process_frames(2)

	var controller := movement_slice.get_run_controller() as RunController
	var welcome := movement_slice.get_welcome_screen() as WelcomeScreen
	var selector := movement_slice.get_character_select_overlay() as CharacterSelectOverlay
	var friends := movement_slice.get_friend_registry() as FriendRegistry
	var abilities := movement_slice.get_ability_effect_registry() as AbilityEffectRegistry
	var arena_layout := movement_slice.get_node("ArenaLayout") as ArenaLayout
	assert_true(
		controller != null and welcome != null and selector != null and friends != null and abilities != null,
		"Il frontend B18W deve essere composto con entrambi i registry dati."
	)
	if controller == null or welcome == null or selector == null or friends == null or abilities == null:
		return

	welcome.get_play_button().pressed.emit()
	await wait_process_frames(2)
	assert_true(
		selector.visible and controller.get_state() == RunController.RunState.BOOT, "B18W deve aprirsi in BOOT."
	)
	_assert_hierarchy(selector)
	_assert_focus_contract(selector)

	for expected_id in EXPECTED_IDS:
		var definition := friends.resolve_definition(expected_id)
		var ability := abilities.resolve_definition(definition.active_ability_id)
		var copy := selector.get_displayed_copy()
		assert_eq(selector.get_selected_definition(), definition, "%s deve essere il profilo centrale." % expected_id)
		assert_eq(
			copy.name, definition.get_public_display_name().to_upper(), "%s deve mostrare il nome in maiuscolo." % expected_id
		)
		assert_eq(copy.role, definition.get_public_role(), "%s deve aggiornare atomicamente il ruolo." % expected_id)
		assert_eq(
			copy.passive_title, definition.get_public_passive_title().to_upper(),
			"%s deve aggiornare il nome passiva." % expected_id
		)
		assert_eq(
			copy.passive_description, definition.get_public_passive_description(),
			"%s deve aggiornare la descrizione passiva." % expected_id
		)
		assert_eq(
			copy.ability_title, definition.get_public_active_ability_title().to_upper(),
			"%s deve aggiornare il nome abilita." % expected_id
		)
		assert_eq(
			copy.ability_description, definition.get_public_active_ability_description(),
			"%s deve aggiornare la descrizione abilita." % expected_id
		)
		assert_eq(
			selector.get_passive_icon(), definition.get_public_passive_icon(),
			"%s deve trattare la passiva con un'icona." % expected_id
		)
		assert_true(
			definition.get_public_passive_icon() != null
			and definition.get_public_passive_icon().resource_path == EXPECTED_PASSIVE_ICON_PATHS[expected_id],
			"%s deve usare la propria icona passiva runtime elaborata." % expected_id
		)
		assert_eq(
			selector.get_ability_icon(), ability.icon, "%s deve mostrare l'icona B18M registrata." % expected_id
		)
		assert_eq(
			selector.get_confirm_button().text, "GIOCA CON %s" % definition.get_public_display_name().to_upper(),
			"%s deve aggiornare il CTA naturale." % expected_id
		)
		selector.navigate_next()
	assert_eq(
		selector.get_selected_definition().id, &"magno", "Otto profili devono chiudere il ciclo B18W."
	)
	selector.navigate_previous()
	assert_eq(
		selector.get_displayed_copy().ability_title, "REGGAETON TIME!",
		"Il nome approvato Reggaeton time! non deve essere abbreviato."
	)
	selector.navigate_next()

	selector.get_next_button().pressed.emit()
	assert_eq(
		selector.get_selected_definition().id, &"bea", "La freccia integrata deve navigare senza confermare."
	)
	var start_index := selector.get_selected_index()
	var center := selector.get_carousel_rect().get_center()
	selector.handle_touch_event_for_test(make_touch_event(3, true, center))
	assert_true(
		selector.handle_touch_event_for_test(make_drag_event(3, center + Vector2(-80.0, 1.0), Vector2.ZERO)),
		"Lo swipe B18W deve consumare il drag."
	)
	assert_true(
		selector.handle_touch_event_for_test(make_touch_event(3, false, center + Vector2(-80.0, 1.0))),
		"Il rilascio dello swipe deve restare consumato."
	)
	assert_eq(
		selector.get_selected_index(), posmod(start_index + 1, EXPECTED_IDS.size()),
		"Lo swipe deve aggiornare lo stesso indice."
	)
	assert_true(
		controller.get_seed() == 0 and is_zero_approx(controller.get_run_time()),
		"Frecce e swipe non devono avviare la run."
	)

	await wait_seconds(0.2)
	assert_false(
		selector.has_active_transition(), "La transizione B18W deve chiudersi prima del layout stabile."
	)
	await _assert_layouts(selector, arena_layout)
	selector.show_selection(&"magno")
	await wait_process_frames(2)
	selector.get_back_button().pressed.emit()
	await wait_process_frames(2)
	assert_true(welcome.visible and not selector.visible, "Back alto deve tornare alla welcome.")
	assert_true(
		controller.get_state() == RunController.RunState.BOOT and controller.get_seed() == 0,
		"Back alto deve conservare BOOT senza seed."
	)

	welcome.get_play_button().pressed.emit()
	await wait_process_frames(2)
	selector.get_button(&"marghe").pressed.emit()
	selector.get_confirm_button().pressed.emit()
	await wait_process_frames(2)
	assert_true(controller.is_running(), "Soltanto il CTA arancione deve avviare la run.")
	assert_eq(
		movement_slice.get_player().get_friend_definition().id, &"marghe",
		"Il CTA deve confermare il profilo centrale."
	)

	if is_instance_valid(controller):
		controller.prepare_restart()


func _assert_hierarchy(selector: CharacterSelectOverlay) -> void:
	var backdrop := selector.get_backdrop()
	var panel_rect := selector.get_selection_panel_rect()
	var back_rect := selector.get_back_button().get_global_rect()
	var title_rect := selector.get_title_rect()
	var carousel_rect := selector.get_carousel_rect()
	var center_rect := selector.get_center_card_rect()
	var ability_rect := selector.get_ability_panel_rect()
	var ability_icon_rect := selector.get_ability_icon_rect()
	var passive_card := selector.get_node_or_null(
		"Center/SelectionPanel/Content/MainRow/AbilityCards/PassiveCard"
	) as PanelContainer
	var ability_card := selector.get_node_or_null(
		"Center/SelectionPanel/Content/MainRow/AbilityCards/AbilityCard"
	) as PanelContainer
	var passive_icon_slot := selector.get_node_or_null(
		"Center/SelectionPanel/Content/MainRow/AbilityCards/PassiveCard/PassiveContent/PassiveIconSlot"
	) as CenterContainer
	var passive_text := selector.get_node_or_null(
		"Center/SelectionPanel/Content/MainRow/AbilityCards/PassiveCard/PassiveContent/PassiveText"
	) as VBoxContainer
	var ability_icon_slot := selector.get_node_or_null(
		"Center/SelectionPanel/Content/MainRow/AbilityCards/AbilityCard/AbilityContent/AbilityIconSlot"
	) as CenterContainer
	var ability_text := selector.get_node_or_null(
		"Center/SelectionPanel/Content/MainRow/AbilityCards/AbilityCard/AbilityContent/AbilityText"
	) as VBoxContainer
	var name_rect := selector.get_name_rect()
	var role_rect := selector.get_role_rect()
	var confirm_rect := selector.get_confirm_button().get_global_rect()
	assert_true(
		backdrop != null
		and backdrop.texture != null
		and backdrop.texture.resource_path == "res://assets/art/ui/character_select/character_select_backdrop.png",
		"B18W deve usare il fondale pixel-art tracciato."
	)
	assert_true(
		FileAccess.file_exists("res://assets/art/ui/character_select/ASSET-MANIFEST.md"),
		"Il fondale B18W deve avere prompt, licenza e hash nel manifest."
	)
	assert_true(
		FileAccess.file_exists("res://assets/art/icons/passives/ASSET-MANIFEST.md"),
		"L'icona passiva B18W deve avere prompt, licenza e hash nel manifest."
	)
	assert_eq(
		EXPECTED_PASSIVE_ICON_PATHS.size(), EXPECTED_IDS.size(),
		"Ogni profilo B18W deve avere una mappa icona passiva dedicata."
	)
	for passive_icon_path in EXPECTED_PASSIVE_ICON_PATHS.values():
		assert_true(
			FileAccess.file_exists(passive_icon_path), "L'icona passiva runtime deve esistere: %s." % passive_icon_path
		)
	assert_true(back_rect.end.x <= title_rect.position.x, "Back deve restare in alto a sinistra, fuori dal titolo.")
	assert_true(back_rect.end.y <= carousel_rect.position.y, "Back non deve restare come azione inferiore.")
	assert_true(
		absf(back_rect.get_center().y - title_rect.get_center().y) <= 6.0,
		"Back deve condividere la fascia del titolo per non sprecare spazio verticale."
	)
	assert_true(back_rect.size.x <= 140.0 and back_rect.size.y <= 44.0, "Back deve restare piccolo e discreto.")
	assert_false(
		selector.has_node("Center/SelectionPanel/Content/Subtitle"),
		"Il sottotitolo istruttivo superfluo deve essere rimosso."
	)
	assert_false(
		selector.has_node("Center/SelectionPanel/Content/MainRow/AbilityCards/KitLabel"),
		"L'intestazione KIT DI <NOME> deve essere rimossa."
	)
	assert_true(
		center_rect.size.x > selector.get_preview_card_rect(1).size.x,
		"La card centrale deve predominare sulle anteprime."
	)
	assert_true(
		carousel_rect.encloses(selector.get_preview_card_rect(-1))
		and carousel_rect.encloses(selector.get_preview_card_rect(1)),
		"Le anteprime devono essere mini-card complete, non tagliate."
	)
	assert_true(ability_rect.position.x > carousel_rect.end.x, "Le card abilita devono essere laterali al carosello.")
	assert_true(
		ability_rect.position.x - carousel_rect.end.x <= 70.0,
		"Personaggio e kit devono dialogare senza una frattura eccessiva."
	)
	assert_true(
		ability_rect.size.x >= 400.0 and ability_rect.size.x <= 420.0,
		"Le card abilita devono bilanciare il peso del carosello."
	)
	assert_true(ability_rect.size.y <= 440.0, "Le due card abilita devono restare compatte.")
	assert_true(passive_card != null and ability_card != null, "Passiva e abilita devono usare due riquadri separati.")
	if passive_card != null and ability_card != null:
		assert_true(
			passive_card.get_global_rect().size.distance_to(ability_card.get_global_rect().size) <= 1.0,
			"Le due card devono avere la stessa dimensione."
		)
		assert_true(
			passive_card.get_global_rect().end.y < ability_card.get_global_rect().position.y,
			"Le card devono essere separate senza divisore interno."
		)
	assert_true(
		passive_icon_slot != null and passive_text != null and ability_icon_slot != null and ability_text != null,
		"Ogni card deve avere una corsia icona e un blocco testo."
	)
	if passive_icon_slot != null and passive_text != null:
		assert_true(
			absf(passive_icon_slot.get_global_rect().get_center().y - passive_text.get_global_rect().get_center().y)
			<= 1.0,
			"L'icona passiva deve essere centrata rispetto al testo."
		)
	if ability_icon_slot != null and ability_text != null:
		assert_true(
			absf(ability_icon_slot.get_global_rect().get_center().y - ability_text.get_global_rect().get_center().y)
			<= 1.0,
			"L'icona attiva deve essere centrata rispetto al testo."
		)
	for title_path in [
		"Center/SelectionPanel/Content/MainRow/AbilityCards/PassiveCard/PassiveContent/PassiveText/PassiveTitleLabel",
		"Center/SelectionPanel/Content/MainRow/AbilityCards/AbilityCard/AbilityContent/AbilityText/AbilityTitleLabel",
	]:
		var title_label := selector.get_node_or_null(title_path) as Label
		assert_not_null(title_label, "Il titolo abilita deve esistere: %s." % title_path)
		if title_label != null:
			assert_true(
				title_label.get_theme_constant("line_spacing") <= -8,
				"I titoli abilita su piu righe devono usare un'interlinea stretta."
			)
	for description_path in [
		"Center/SelectionPanel/Content/MainRow/AbilityCards/PassiveCard/PassiveContent/PassiveText/PassiveDescriptionLabel",
		"Center/SelectionPanel/Content/MainRow/AbilityCards/AbilityCard/AbilityContent/AbilityText/AbilityDescriptionLabel",
	]:
		var description_label := selector.get_node_or_null(description_path) as Label
		assert_not_null(description_label, "La descrizione abilita deve esistere: %s." % description_path)
		if description_label != null:
			assert_true(
				description_label.get_theme_font_size("font_size") >= 15,
				"Le descrizioni abilita devono restare leggibili."
			)
	assert_false(
		selector.has_node("Center/SelectionPanel/Content/MainRow/AbilityCards/Divider"),
		"Le card non devono usare un separatore orizzontale interno."
	)
	assert_eq(
		ability_icon_rect.size, Vector2(136.0, 136.0),
		"L'icona abilita deve essere 136x136 e non dominare il kit."
	)
	assert_true(
		role_rect.position.y - name_rect.end.y >= 0.0 and role_rect.position.y - name_rect.end.y <= 12.0,
		"Nome e ruolo devono formare un unico blocco compatto."
	)
	assert_true(
		confirm_rect.position.y - role_rect.end.y <= 34.0,
		"Il CTA deve seguire il blocco identità senza una terra di nessuno."
	)
	assert_true(confirm_rect.position.y >= ability_rect.end.y, "Il CTA deve chiudere la gerarchia in basso.")
	assert_true(
		panel_rect.encloses(back_rect) and panel_rect.encloses(confirm_rect), "Back e CTA devono restare nel pannello."
	)
	assert_true(
		confirm_rect.size.x <= panel_rect.size.x * 0.55, "Il CTA deve essere più corto senza perdere dominanza."
	)
	assert_true(
		panel_rect.end.y - confirm_rect.end.y >= 30.0, "Il CTA deve lasciare visibile la cornice inferiore."
	)
	assert_eq(
		selector.get_back_button().text, "INDIETRO", "Back deve avere copy e icona distinti dalle frecce."
	)
	var center_style := selector.get_button(&"magno").get_theme_stylebox("normal") as StyleBoxFlat
	assert_true(
		center_style != null
		and center_style.get_corner_radius(CORNER_TOP_LEFT) <= 2
		and center_style.get_border_width(SIDE_LEFT) <= 2,
		"La card centrale deve usare un bordo pixelato sottile."
	)
	var arrow_style := selector.get_next_button().get_theme_stylebox("normal") as StyleBoxFlat
	assert_true(
		arrow_style != null and arrow_style.get_corner_radius(CORNER_TOP_LEFT) <= 2,
		"Le frecce non devono usare il cerchio cyan moderno."
	)
	assert_true(
		selector.get_next_button().size.x <= 48.0, "Le frecce pixel-fantasy devono restare compatte."
	)
	var cta_style := selector.get_confirm_button().get_theme_stylebox("normal") as StyleBoxTexture
	assert_true(
		cta_style != null and cta_style.texture != null, "Il CTA dominante deve usare la placca ImageGen tracciata."
	)
	assert_true(
		FileAccess.file_exists("res://assets/art/ui/character_select/character_select_cta_base.png"),
		"La placca CTA runtime deve esistere."
	)
	var cta_count := 0
	for node in selector.find_children("*", "Button", true, false):
		var button := node as Button
		if button.text.begins_with("GIOCA CON "):
			cta_count += 1
	assert_eq(cta_count, 1, "Il selettore deve esporre un solo CTA dominante.")


func _assert_focus_contract(selector: CharacterSelectOverlay) -> void:
	var current := selector.get_button(selector.get_selected_definition().id)
	var back := selector.get_back_button()
	var confirm := selector.get_confirm_button()
	assert_eq(
		back.focus_neighbor_bottom, back.get_path_to(current), "Focus da Back deve scendere al profilo centrale."
	)
	assert_eq(
		current.focus_neighbor_top, current.get_path_to(back), "Focus dal profilo deve risalire a Back."
	)
	assert_eq(
		current.focus_neighbor_bottom, current.get_path_to(confirm), "Focus dal profilo deve scendere al CTA."
	)
	assert_eq(
		confirm.focus_neighbor_top, confirm.get_path_to(current), "Focus dal CTA deve tornare al profilo."
	)


func _assert_layouts(selector: CharacterSelectOverlay, arena_layout: ArenaLayout) -> void:
	for profile in LAYOUT_PROFILES:
		get_tree().root.content_scale_size = profile
		get_tree().root.size = profile
		arena_layout.refresh_layout()
		await wait_process_frames(2)
		var safe_area := arena_layout.get_safe_area_rect()
		var panel_rect := selector.get_selection_panel_rect()
		var back_rect := selector.get_back_button().get_global_rect()
		var carousel_rect := selector.get_carousel_rect()
		var center_rect := selector.get_center_card_rect()
		var ability_rect := selector.get_ability_panel_rect()
		var ability_icon_rect := selector.get_ability_icon_rect()
		var confirm_rect := selector.get_confirm_button().get_global_rect()
		assert_true(safe_area.encloses(panel_rect), "%s: il pannello B18W deve restare nella safe area." % profile)
		assert_true(carousel_rect.encloses(center_rect), "%s: il profilo centrale deve restare intero." % profile)
		assert_false(
			center_rect.intersects(ability_rect), "%s: profilo e pannello abilita non devono sovrapporsi." % profile
		)
		assert_false(
			ability_rect.intersects(confirm_rect), "%s: pannello abilita e CTA non devono sovrapporsi." % profile
		)
		assert_eq(
			ability_icon_rect.size, Vector2(136.0, 136.0),
			"%s: icona abilita 136x136 deve restare leggibile." % profile
		)
		assert_true(
			safe_area.encloses(back_rect) and safe_area.encloses(confirm_rect),
			"%s: Back e CTA devono restare nella safe area." % profile
		)
		assert_true(
			confirm_rect.size.x >= 44.0 and confirm_rect.size.y >= 44.0,
			"%s: il CTA deve conservare il target 44x44." % profile
		)
	get_tree().root.content_scale_size = LAYOUT_PROFILES[0]
	get_tree().root.size = LAYOUT_PROFILES[0]
	arena_layout.refresh_layout()
	await wait_process_frames(2)
