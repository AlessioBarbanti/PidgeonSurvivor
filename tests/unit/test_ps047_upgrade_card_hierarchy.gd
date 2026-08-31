extends GutGameplayTest

## PS-047: verifica la gerarchia visiva delle carte upgrade — gruppi coerenti
## (identità in alto, descrizione al centro, effetto/rango raccolti in un
## unico blocco in fondo), contenimento di un testo lungo reale ("Pinza
## Lunga"), dimensioni invarianti durante il focus e riuso identico fra
## offerta normale, BARB_SPECIALITY e BARB_BONUS. Densità e leggibilità
## percepite restano un gate manuale (vedi card).

const UPGRADE_OVERLAY_SCENE := preload("res://scenes/ui/upgrade_overlay.tscn")
const BARB_OVERLAY_SCENE := preload("res://scenes/ui/barb_reward_overlay.tscn")
const TOUCH_JOYSTICK_SCENE := preload("res://scenes/ui/touch_joystick.tscn")
# "Pinza Lunga": il testo lungo reale citato esplicitamente dalla card.
const WIDE_MAGNET := preload("res://data/upgrades/wide_magnet.tres")
const SWIFT_STEPS := preload("res://data/upgrades/swift_steps.tres")
const RAPID_FIRE := preload("res://data/upgrades/rapid_fire.tres")
const GOSSIP := preload("res://data/upgrades/specialities/gossip_projectiles.tres")
const PIERCING_ROUNDS := preload("res://data/upgrades/specialities/piercing_rounds.tres")
const DOUBLE_BARREL := preload("res://data/upgrades/specialities/double_barrel.tres")
const DEATH_BURST := preload("res://data/upgrades/specialities/death_burst.tres")
const SAFE_RECT := Rect2(20.0, 20.0, 1240.0, 680.0)


func test_ps047_normal_offer_card_hierarchy() -> void:
	# Pool di esattamente tre definizioni, "Pinza Lunga" inclusa: l'offerta di
	# tre carte le mostra sempre tutte, senza dipendere dall'RNG.
	var fixture := await _create_overlay_fixture(
		[WIDE_MAGNET, SWIFT_STEPS, RAPID_FIRE], SAFE_RECT, 4701
	)
	var overlay := fixture.overlay as UpgradeOverlay
	var cards := overlay.get_cards()
	assert_eq(cards.size(), 3, "L'offerta normale deve mostrare tre carte.")

	var wide_magnet_found := false
	for card in cards:
		if card.get_upgrade_id() == WIDE_MAGNET.id:
			wide_magnet_found = true
	assert_true(wide_magnet_found, "\"Pinza Lunga\" deve comparire fra le tre carte del pool completo.")

	_assert_card_group_hierarchy(cards, SAFE_RECT, "offerta normale")
	await _wait_selection_unlock(overlay)
	_assert_card_size_invariant_on_focus(cards[0], "offerta normale")

	# Le carte non devono allungarsi solo per riempire l'altezza disponibile:
	# in un modal molto più alto restano alla stessa dimensione naturale.
	var tall_rect := Rect2(20.0, 20.0, 1240.0, 1400.0)
	var tall_fixture := await _create_overlay_fixture(
		[WIDE_MAGNET, SWIFT_STEPS, RAPID_FIRE], tall_rect, 4703
	)
	var tall_overlay := tall_fixture.overlay as UpgradeOverlay
	var tall_cards := tall_overlay.get_cards()
	assert_eq(
		tall_cards[0].size.y, cards[0].size.y,
		"La carta non deve crescere solo perché il modal ha più spazio verticale disponibile."
	)


func test_ps047_barb_speciality_and_bonus_card_hierarchy() -> void:
	var fixture := await _create_barb_fixture(SAFE_RECT, 4702)
	var service := fixture.service as UpgradeService
	var overlay := fixture.overlay as BarbRewardOverlay

	service.queue_barb_reward()
	await wait_process_frames(2)
	assert_true(
		overlay.visible and not overlay.is_bonus_mode(),
		"Il catalogo Barb non ancora esaurito deve aprirsi in modalità sblocco."
	)
	_assert_card_group_hierarchy(overlay.get_cards(), SAFE_RECT, "BARB_SPECIALITY")
	await _wait_selection_unlock(overlay)
	_assert_card_size_invariant_on_focus(overlay.get_cards()[0], "BARB_SPECIALITY")

	await _unlock_all_specialities(service)
	service.queue_barb_reward()
	await wait_process_frames(2)
	assert_true(overlay.visible and overlay.is_bonus_mode(), "Il catalogo esaurito deve aprire il premio bonus.")
	_assert_card_group_hierarchy(overlay.get_cards(), SAFE_RECT, "BARB_BONUS")

	print("UPGRADE_CARD_HIERARCHY_SMOKE_OK")


func _assert_card_group_hierarchy(cards: Array[UpgradeCard], safe_rect: Rect2, profile_name: String) -> void:
	for index in cards.size():
		var card := cards[index]
		if not card.visible or card.get_definition() == null:
			continue
		assert_rect_inside(
			card.get_global_rect(), safe_rect, "%s: carta %d fuori safe area." % [profile_name, index + 1]
		)

		var icon_center := card.get_node_or_null("Margins/Content/IconCenter") as CenterContainer
		var title := card.get_node_or_null("Margins/Content/TitleLabel") as Label
		var description := card.get_node_or_null("Margins/Content/DescriptionLabel") as Label
		var meta_panel := card.get_node_or_null("Margins/Content/MetaPanel") as PanelContainer
		var effect := card.get_node_or_null("Margins/Content/MetaPanel/MetaLayout/EffectSummaryLabel") as Label
		var rank := card.get_node_or_null("Margins/Content/MetaPanel/MetaLayout/RankLabel") as Label
		assert_true(
			(
				icon_center != null and title != null and description != null
				and meta_panel != null and effect != null and rank != null
			),
			"%s: carta %d deve avere icona, titolo, descrizione e il gruppo effetto/rango." % [profile_name, index + 1]
		)
		if icon_center == null or title == null or description == null or meta_panel == null:
			continue

		# Ordine verticale dei gruppi: identità (icona/titolo), poi
		# descrizione, poi il gruppo effetto/rango raccolto in fondo.
		assert_true(
			(
				icon_center.get_global_rect().position.y < title.get_global_rect().position.y
				and title.get_global_rect().position.y < description.get_global_rect().position.y
				and description.get_global_rect().position.y < meta_panel.get_global_rect().position.y
			),
			"%s: carta %d deve ordinare i gruppi identità > descrizione > effetto/rango." % [profile_name, index + 1]
		)
		# Riepilogo effetto e rango restano raccolti nello stesso gruppo visivo.
		assert_true(
			(
				meta_panel.get_global_rect().encloses(effect.get_global_rect())
				and meta_panel.get_global_rect().encloses(rank.get_global_rect())
			),
			"%s: carta %d deve raccogliere riepilogo effetto e rango nello stesso gruppo." % [profile_name, index + 1]
		)

		# Nessun testo reale deve essere troncato: l'altezza disponibile deve
		# restare almeno quella richiesta dal wrapping alla larghezza corrente.
		var description_min := description.get_minimum_size()
		assert_true(
			description.size.y >= description_min.y - 1.0,
			(
				"%s: carta %d tronca la descrizione (%.1f disponibili, %.1f richiesti)."
				% [profile_name, index + 1, description.size.y, description_min.y]
			)
		)


func _assert_card_size_invariant_on_focus(card: UpgradeCard, profile_name: String) -> void:
	if card.get_definition() == null:
		return
	var size_before := card.size
	card.grab_focus()
	assert_eq(
		card.size, size_before,
		"%s: la carta non deve cambiare dimensione quando riceve il focus." % profile_name
	)
	card.release_focus()


func _create_overlay_fixture(
	definitions: Array[UpgradeDefinition], safe_rect: Rect2, seed_value: int
) -> Dictionary:
	var fixture_root := Control.new()
	fixture_root.name = "UpgradeCardHierarchyFixture"
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
	assert_true(registry.rebuild_registry(), "La fixture PS-047 deve avere un catalogo valido.")
	assert_true(service.configure(registry, controller, experience), "La fixture PS-047 deve configurare UpgradeService.")
	assert_true(overlay.configure(service, joystick), "La fixture PS-047 deve configurare UpgradeOverlay.")
	assert_true(controller.start_run(seed_value), "La fixture PS-047 deve avviare la run.")
	assert_true(experience.add_experience(1), "La fixture PS-047 deve generare un'offerta.")
	await wait_process_frames(2)
	return {
		"root": fixture_root,
		"controller": controller,
		"overlay": overlay,
	}


func _create_barb_fixture(safe_rect: Rect2, seed_value: int) -> Dictionary:
	var fixture_root := Control.new()
	fixture_root.name = "BarbCardHierarchyFixture"
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
	assert_true(registry.rebuild_registry(), "La fixture PS-047 deve avere un catalogo Barb valido.")
	assert_true(service.configure(registry, controller, experience), "La fixture PS-047 deve configurare il service Barb.")
	assert_true(overlay.configure(service, joystick), "La fixture PS-047 deve configurare BarbRewardOverlay.")
	assert_true(controller.start_run(seed_value), "La fixture PS-047 deve avviare la run Barb.")
	return {
		"root": fixture_root,
		"controller": controller,
		"service": service,
		"overlay": overlay,
	}


func _unlock_all_specialities(service: UpgradeService) -> void:
	while service.get_locked_speciality_definitions().size() > 0:
		service.queue_barb_reward()
		var offer := service.get_current_barb_offer()
		assert_true(not offer.is_empty(), "Deve restare disponibile un'offerta per sbloccare le Specialità.")
		if offer.is_empty():
			return
		assert_true(service.select_barb_speciality(offer[0].id), "La Specialità preparatoria deve sbloccarsi.")


func _wait_selection_unlock(overlay: Node) -> void:
	while overlay.is_selection_locked():
		await get_tree().create_timer(overlay.get_selection_lock_remaining() + 0.05, true, false, true).timeout
	await wait_process_frames(2)
