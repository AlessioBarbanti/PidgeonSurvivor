extends GutGameplayTest

## PS-051: la Boss Intro deve distinguere il Piccione Malvagio (nessuna
## Signature, nessuno slot icona) dagli Evil (ritratto del FriendDefinition,
## icona della Signature attiva, tinta personale dell'accent_color) senza
## rompersi quando ritratto, icona o Signature mancano.

const BOSS_UI_SCENE := preload("res://scenes/ui/boss_ui.tscn")
const REFERENCE_SIGNATURE := preload("res://data/bosses/signatures/evil_alea_grand_spin.tres")
const ASPECT_PROFILES := [
	{"name": "16:9", "viewport": Vector2i(1280, 720), "safe_rect": Rect2(20.0, 20.0, 1240.0, 680.0)},
	{"name": "20:9", "viewport": Vector2i(1600, 720), "safe_rect": Rect2(64.0, 20.0, 1472.0, 680.0)},
	{"name": "4:3", "viewport": Vector2i(960, 720), "safe_rect": Rect2(20.0, 20.0, 920.0, 680.0)},
]


func test_baseline_intro_shows_pigeon_without_signature_slot() -> void:
	var slice := await instantiate_movement_slice()
	var controller := slice.get_run_controller() as RunController
	var encounter := slice.get_boss_encounter() as BossEncounter
	var boss_ui := slice.get_boss_ui() as BossUI
	assert_true(controller != null and encounter != null and boss_ui != null, "PS-051 richiede le dipendenze Boss della scena.")
	if controller == null or encounter == null or boss_ui == null:
		return

	controller.set_process(false)
	encounter.evil_boss_chance = 0.0
	controller._process(120.01)

	var definition := encounter.get_active_definition()
	assert_true(definition != null and not definition.is_evil_variant(), "evil_boss_chance=0 deve aprire il Piccione Malvagio.")
	if definition == null:
		return

	assert_true(boss_ui.is_intro_portrait_visible(), "Il Piccione Malvagio deve mostrare il proprio ritratto.")
	assert_eq(
		boss_ui.get_intro_portrait_texture(), definition.get_safe_portrait(),
		"Il ritratto mostrato deve essere quello risolto dal Boss baseline."
	)
	assert_false(
		boss_ui.is_intro_signature_icon_visible(),
		"Il Piccione Malvagio non deve mostrare uno slot Signature, vuoto o valorizzato."
	)
	assert_null(boss_ui.get_intro_signature_icon_texture(), "Nessuna icona deve essere assegnata al baseline.")
	assert_true(
		boss_ui.get_intro_title_color().is_equal_approx(BossUI.DEFAULT_TITLE_COLOR),
		"Senza Signature il titolo deve restare sul colore neutro."
	)
	assert_true(
		boss_ui.get_intro_frame_modulate().is_equal_approx(BossUI.DEFAULT_PANEL_MODULATE),
		"Senza Signature la cornice non deve ricevere alcuna tinta."
	)

	encounter.complete_intro()
	controller.prepare_restart()


func test_evil_intro_shows_friend_portrait_signature_icon_and_accent_tint() -> void:
	var slice := await instantiate_movement_slice()
	var controller := slice.get_run_controller() as RunController
	var encounter := slice.get_boss_encounter() as BossEncounter
	var boss_ui := slice.get_boss_ui() as BossUI
	assert_true(controller != null and encounter != null and boss_ui != null, "PS-051 richiede le dipendenze Boss della scena.")
	if controller == null or encounter == null or boss_ui == null:
		return

	controller.set_process(false)
	encounter.evil_boss_chance = 1.0
	controller._process(120.01)

	var definition := encounter.get_active_definition()
	assert_true(definition != null and definition.is_evil_variant(), "evil_boss_chance=1 deve aprire un Evil.")
	if definition == null:
		return
	var friend := definition.friend_profile
	assert_true(definition.has_signature() and friend != null, "Ogni Evil in catalogo deve avere Signature e profilo.")
	if not definition.has_signature() or friend == null:
		return
	var signature := definition.signature

	assert_true(boss_ui.is_intro_portrait_visible(), "L'intro Evil deve mostrare un ritratto.")
	assert_eq(
		boss_ui.get_intro_portrait_texture(), friend.get_public_evil_portrait(),
		"Il ritratto mostrato deve provenire dal FriendDefinition dell'Evil attivo."
	)
	assert_true(boss_ui.is_intro_signature_icon_visible(), "L'intro Evil deve mostrare l'icona della Signature.")
	assert_not_null(signature.icon, "Ogni Signature del catalogo deve avere un'icona valorizzata.")
	assert_eq(
		boss_ui.get_intro_signature_icon_texture(), signature.icon,
		"L'icona mostrata deve essere quella della Signature attiva."
	)

	var expected_title_color := BossUI.DEFAULT_TITLE_COLOR.lerp(signature.accent_color, BossUI.ACCENT_TITLE_MIX)
	expected_title_color.a = 1.0
	assert_true(
		boss_ui.get_intro_title_color().is_equal_approx(expected_title_color),
		"Il titolo deve riprendere l'accent_color della Signature restando leggibile."
	)
	var expected_frame_modulate := BossUI.DEFAULT_PANEL_MODULATE.lerp(signature.accent_color, BossUI.ACCENT_FRAME_MIX)
	expected_frame_modulate.a = 1.0
	assert_true(
		boss_ui.get_intro_frame_modulate().is_equal_approx(expected_frame_modulate),
		"La cornice deve mostrare almeno un dettaglio tinto dell'accent_color."
	)

	var cta_style := boss_ui.get_continue_button_style(&"normal") as StyleBoxTexture
	assert_true(
		cta_style != null and cta_style.modulate_color.is_equal_approx(Color(1, 1, 1, 1)),
		"La CTA non deve cambiare colore in base al Boss."
	)

	encounter.complete_intro()
	controller.prepare_restart()


func test_boss_intro_panel_stays_in_safe_area_across_aspect_ratios() -> void:
	var slice := await instantiate_movement_slice()
	var controller := slice.get_run_controller() as RunController
	var encounter := slice.get_boss_encounter() as BossEncounter
	var boss_ui := slice.get_boss_ui() as BossUI
	assert_true(controller != null and encounter != null and boss_ui != null, "PS-051 richiede le dipendenze Boss della scena.")
	if controller == null or encounter == null or boss_ui == null:
		return

	controller.set_process(false)
	encounter.evil_boss_chance = 1.0
	controller._process(120.01)
	assert_eq(
		controller.get_state(), RunController.RunState.BOSS_INTRO,
		"La fixture PS-051 deve aprire la Boss Intro con identita' Evil al completo (caso di contenuto piu' alto)."
	)

	for profile in ASPECT_PROFILES:
		var viewport_size: Vector2i = profile.viewport
		var safe_rect: Rect2 = profile.safe_rect
		get_tree().root.content_scale_size = viewport_size
		get_tree().root.size = viewport_size
		await wait_process_frames(2)
		assert_rect_inside(
			boss_ui.get_intro_panel_rect(), safe_rect,
			"%s: il pannello della Boss Intro deve restare nella safe area." % profile.name
		)

	encounter.complete_intro()
	controller.prepare_restart()


func test_boss_intro_recomposes_gracefully_when_portrait_or_icon_are_missing() -> void:
	var boss_ui := BOSS_UI_SCENE.instantiate() as BossUI
	add_child_autofree(boss_ui)
	await wait_process_frames(1)

	var missing_portrait := BossDefinition.new()
	missing_portrait.id = &"ps051_missing_portrait"
	missing_portrait.title = "SENZA RITRATTO"
	missing_portrait.quote_approved = true
	missing_portrait.quote = "La intro deve reggere anche senza ritratto."
	missing_portrait.portrait = null
	assert_true(
		missing_portrait.is_valid(),
		"Un Boss baseline resta valido anche senza portrait: e' il caso di fallback da coprire."
	)
	assert_true(boss_ui.show_intro(missing_portrait), "La intro deve potersi aprire senza portrait.")
	assert_false(
		boss_ui.is_intro_portrait_visible(),
		"Senza portrait lo slot deve restare nascosto invece di mostrare una texture nulla."
	)
	assert_false(boss_ui.is_intro_signature_icon_visible(), "Senza Signature l'icona non deve comparire.")
	assert_eq(boss_ui.get_intro_title_text(), "SENZA RITRATTO", "Titolo e citazione restano dai dati del Boss.")

	var signature_without_icon := BossSignatureDefinition.new()
	signature_without_icon.id = &"ps051_signature_no_icon"
	signature_without_icon.friend_id = &"alea"
	signature_without_icon.title = "Prova Senza Icona"
	signature_without_icon.effect_id = REFERENCE_SIGNATURE.effect_id
	signature_without_icon.effect_parameters = REFERENCE_SIGNATURE.effect_parameters.duplicate()
	signature_without_icon.telegraph_duration = 1.0
	signature_without_icon.duration_seconds = 1.0
	signature_without_icon.area_radius = 10.0
	signature_without_icon.damage = 1.0
	signature_without_icon.accent_color = REFERENCE_SIGNATURE.accent_color
	signature_without_icon.icon = null
	assert_true(signature_without_icon.is_valid(), "Una Signature senza icona deve restare valida per il fallback.")

	var friend_definition := load("res://data/friends/alea.tres") as FriendDefinition
	var evil_without_icon := BossDefinition.new()
	evil_without_icon.id = &"ps051_evil_no_icon"
	evil_without_icon.visual_kind = BossDefinition.VisualKind.EVIL_FRIEND
	evil_without_icon.friend_profile = friend_definition
	evil_without_icon.signature = signature_without_icon
	assert_true(evil_without_icon.is_valid(), "L'Evil di prova deve restare valido pur senza icona Signature.")

	assert_true(boss_ui.show_intro(evil_without_icon), "La intro deve potersi aprire senza icona Signature.")
	assert_true(boss_ui.is_intro_portrait_visible(), "Il ritratto Evil deve comunque comparire.")
	assert_eq(
		boss_ui.get_intro_portrait_texture(), friend_definition.get_public_evil_portrait(),
		"Il ritratto deve restare quello del FriendDefinition anche senza icona."
	)
	assert_false(
		boss_ui.is_intro_signature_icon_visible(),
		"Senza icona lo slot deve restare nascosto invece di una texture nulla visibile."
	)
	assert_null(boss_ui.get_intro_signature_icon_texture())
	var expected_title_color := BossUI.DEFAULT_TITLE_COLOR.lerp(
		signature_without_icon.accent_color, BossUI.ACCENT_TITLE_MIX
	)
	expected_title_color.a = 1.0
	assert_true(
		boss_ui.get_intro_title_color().is_equal_approx(expected_title_color),
		"La tinta personale deve applicarsi anche quando manca soltanto l'icona."
	)

	print("BOSS_INTRO_IDENTITY_SMOKE_OK")
