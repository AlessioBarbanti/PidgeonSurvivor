extends GutGameplayTest

const BARB_OVERLAY_SCENE := preload("res://scenes/ui/barb_reward_overlay.tscn")
const TOUCH_JOYSTICK_SCENE := preload("res://scenes/ui/touch_joystick.tscn")
const BARB_PORTRAIT: Texture2D = preload(
	"res://assets/art/ui/barb_reward/generated/barb_portrait.png"
)
const GOSSIP := preload("res://data/upgrades/specialities/gossip_projectiles.tres")
const PIERCING_ROUNDS := preload("res://data/upgrades/specialities/piercing_rounds.tres")
const DOUBLE_BARREL := preload("res://data/upgrades/specialities/double_barrel.tres")
const DEATH_BURST := preload("res://data/upgrades/specialities/death_burst.tres")
const LAYOUT_TOLERANCE := 1.0


func test_speciality_mode_has_warm_identity_and_responsive_header() -> void:
	var profiles := [
		{"name": "16:9", "safe_rect": Rect2(20.0, 20.0, 1240.0, 680.0)},
		{"name": "20:9 cutout", "safe_rect": Rect2(64.0, 20.0, 1472.0, 680.0)},
		{"name": "4:3", "safe_rect": Rect2(20.0, 20.0, 920.0, 680.0)},
	]

	for profile in profiles:
		var safe_rect: Rect2 = profile.safe_rect
		var fixture := await _create_fixture(safe_rect, 3600 + int(safe_rect.size.x))
		var controller := fixture.controller as RunController
		var service := fixture.service as UpgradeService
		var overlay := fixture.overlay as BarbRewardOverlay
		var fixture_root := fixture.root as Control
		var profile_name := String(profile.name)

		service.queue_barb_reward()
		await wait_process_frames(2)
		assert_true(overlay.visible and not overlay.is_bonus_mode(), "%s: deve aprirsi lo sblocco." % profile_name)
		assert_eq(overlay.get_title_text(), "LE SPECIALITÀ DI BARB", "%s: titolo dedicato errato." % profile_name)
		assert_eq(overlay.get_mode_text(), "NUOVA SPECIALITÀ", "%s: badge modalita errato." % profile_name)
		assert_null(
			overlay.find_child("SubtitleLabel", true, false),
			"%s: l'header non deve mostrare un sottotitolo." % profile_name
		)
		assert_eq(overlay.get_portrait_texture(), BARB_PORTRAIT, "%s: ritratto Barb assente." % profile_name)
		assert_rect_near(
			overlay.get_global_rect(),
			safe_rect,
			"%s: l'overlay deve coincidere con la safe area." % profile_name,
			LAYOUT_TOLERANCE
		)

		var portrait := overlay.find_child("BarbPortrait", true, false) as TextureRect
		var header := overlay.find_child("HeaderPanel", true, false) as PanelContainer
		assert_true(portrait != null and portrait.texture == BARB_PORTRAIT, "%s: caricatura non composta." % profile_name)
		assert_true(header != null and header.size.y >= 148.0, "%s: header speciale troppo piccolo." % profile_name)
		var cards := overlay.get_cards()
		for card in cards:
			assert_true(card.is_speciality_treatment_enabled(), "%s: carta senza trattamento caldo." % profile_name)
			assert_true(
				not card.get_title_text().is_empty()
				and not card.get_description_text().is_empty()
				and card.get_rank_text().begins_with("RANGO "),
				"%s: nome, descrizione e rango devono restare leggibili." % profile_name
			)
			var normal_style := card.get_theme_stylebox(&"normal") as StyleBoxFlat
			assert_true(
				normal_style != null
				and normal_style.border_color.r > normal_style.border_color.b
				and normal_style.border_color.g > normal_style.border_color.b,
				"%s: il bordo Specialita deve essere oro/arancio, non blu." % profile_name
			)
			assert_rect_inside(
				card.get_global_rect(),
				safe_rect,
				"%s: carta fuori safe area." % profile_name,
				LAYOUT_TOLERANCE
			)
			if portrait != null:
				assert_false(
					portrait.get_global_rect().intersects(card.get_global_rect()),
					"%s: la caricatura non deve coprire le carte." % profile_name
				)
		if not cards.is_empty():
			var focus_style := cards[0].get_theme_stylebox(&"focus") as StyleBoxFlat
			assert_true(
				focus_style != null
				and focus_style.get_border_width(SIDE_LEFT) >= 6
				and focus_style.border_color.r > 0.9,
				"%s: il focus deve restare piu marcato del bordo normale." % profile_name
			)

		controller.prepare_restart()
		fixture_root.queue_free()
		await wait_process_frames(1)


func test_bonus_mode_keeps_barb_but_restores_normal_cards_and_input_contract() -> void:
	var fixture := await _create_fixture(Rect2(20.0, 20.0, 1240.0, 680.0), 3636)
	var controller := fixture.controller as RunController
	var service := fixture.service as UpgradeService
	var overlay := fixture.overlay as BarbRewardOverlay
	var fixture_root := fixture.root as Control

	await _unlock_all_specialities(service)
	service.queue_barb_reward()
	await wait_process_frames(2)

	assert_true(overlay.visible and overlay.is_bonus_mode(), "Il catalogo esaurito deve aprire il premio bonus.")
	assert_eq(overlay.get_title_text(), "IL PREMIO DI BARB", "Il fallback non deve fingere un nuovo sblocco.")
	assert_eq(overlay.get_mode_text(), "RICOMPENSA BONUS", "Il badge deve distinguere il fallback.")
	assert_null(overlay.find_child("SubtitleLabel", true, false), "Il premio bonus non deve mostrare un sottotitolo.")
	assert_eq(overlay.get_portrait_texture(), BARB_PORTRAIT, "La caricatura deve restare anche nel premio bonus.")
	var bonus_portrait := overlay.find_child("BarbPortrait", true, false) as TextureRect
	assert_true(
		bonus_portrait != null and bonus_portrait.is_visible_in_tree(),
		"La caricatura deve ridisegnarsi quando la scena passa da sblocco a bonus."
	)
	assert_true(overlay.is_selection_locked(), "PS-036 non deve rimuovere il lock anti-tap di PS-012.")
	assert_false(overlay.submit_card(0), "Un tap nel lock iniziale deve restare rifiutato.")
	for card in overlay.get_cards():
		assert_false(card.is_speciality_treatment_enabled(), "Le carte bonus devono tornare allo stile level-up.")
		var normal_style := card.get_theme_stylebox(&"normal") as StyleBoxFlat
		assert_true(
			normal_style != null and normal_style.border_color.b > normal_style.border_color.r,
			"La carta bonus deve conservare il bordo freddo del level-up."
		)

	await _wait_selection_unlock(overlay)
	assert_true(overlay.submit_card(0), "La prima selezione bonus deve restare inoltrabile dalla UI.")
	await wait_process_frames(2)
	assert_true(overlay.visible and overlay.is_bonus_mode(), "La seconda offerta bonus deve restare nella scena Barb.")
	await _wait_selection_unlock(overlay)
	assert_true(overlay.submit_card(0), "La seconda selezione bonus deve chiudere il premio.")
	assert_true(controller.is_running() and not overlay.visible, "Dopo il premio la run deve riprendere.")

	controller.prepare_restart()
	fixture_root.queue_free()
	await wait_process_frames(1)
	print("BARB_REWARD_VISUAL_IDENTITY_SMOKE_OK")


func test_barb_portrait_is_a_compact_runtime_alpha_asset() -> void:
	var image := BARB_PORTRAIT.get_image()
	assert_true(image != null, "Il derivato runtime di Barb deve essere leggibile.")
	if image == null:
		return
	assert_true(image.get_width() <= 384 and image.get_height() <= 384, "Il runtime non deve importare il master HD.")
	assert_true(image.detect_alpha() != Image.ALPHA_NONE, "La caricatura deve avere trasparenza reale.")
	assert_eq(image.get_pixel(0, 0).a, 0.0, "L'angolo del ritratto deve restare trasparente.")
	var export_presets := FileAccess.get_file_as_string("res://export_presets.cfg")
	assert_eq(
		export_presets.count("assets/art/ui/barb_reward/hd/**"),
		3,
		"Windows, APK e AAB devono escludere i master HD di Barb."
	)


func _create_fixture(safe_rect: Rect2, seed_value: int) -> Dictionary:
	var fixture_root := Control.new()
	fixture_root.name = "BarbVisualFixture"
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
	var definitions: Array[UpgradeDefinition] = [GOSSIP, PIERCING_ROUNDS, DOUBLE_BARREL, DEATH_BURST]
	definitions.append_array([_make_filler(&"barb_visual_a"), _make_filler(&"barb_visual_b"), _make_filler(&"barb_visual_c")])
	registry.definitions = definitions
	var service := UpgradeService.new()
	service.name = "UpgradeService"
	var joystick := TOUCH_JOYSTICK_SCENE.instantiate() as TouchJoystick
	joystick.name = "TouchJoystick"
	joystick.debug_mode_in_editor = true
	var overlay := BARB_OVERLAY_SCENE.instantiate() as BarbRewardOverlay
	overlay.name = "BarbRewardOverlay"

	fixture_root.add_child(controller)
	fixture_root.add_child(experience)
	fixture_root.add_child(registry)
	fixture_root.add_child(service)
	fixture_root.add_child(joystick)
	fixture_root.add_child(overlay)
	add_child_autofree(fixture_root)
	await wait_process_frames(2)

	experience.set_run_controller(controller)
	assert_true(registry.rebuild_registry(), "La fixture PS-036 deve avere un catalogo valido.")
	assert_true(service.configure(registry, controller, experience), "La fixture PS-036 deve configurare il service.")
	assert_true(overlay.configure(service, joystick), "La fixture PS-036 deve configurare l'overlay.")
	assert_true(controller.start_run(seed_value), "La fixture PS-036 deve avviare la run.")
	return {
		"root": fixture_root,
		"controller": controller,
		"service": service,
		"overlay": overlay,
	}


func _unlock_all_specialities(service: UpgradeService) -> void:
	while not service.get_locked_speciality_definitions().is_empty():
		service.queue_barb_reward()
		var offer := service.get_current_barb_offer()
		assert_false(offer.is_empty(), "Ogni sblocco preparatorio deve avere un'offerta.")
		if offer.is_empty():
			return
		assert_true(service.select_barb_speciality(offer[0].id), "La Specialita preparatoria deve sbloccarsi.")
		await wait_process_frames(1)


func _make_filler(upgrade_id: StringName) -> UpgradeDefinition:
	var definition := UpgradeDefinition.new()
	definition.id = upgrade_id
	definition.title = String(upgrade_id)
	definition.description = "Potenziamento bonus per la verifica PS-036."
	definition.effect_id = &"smoke_effect"
	definition.weight = 1.0
	definition.max_rank = 5
	definition.repeatable = true
	definition.tags = [&"test"]
	return definition


func _wait_selection_unlock(overlay: BarbRewardOverlay) -> void:
	while overlay.is_selection_locked():
		await get_tree().create_timer(overlay.get_selection_lock_remaining() + 0.05, true, false, true).timeout
	await wait_process_frames(2)
