extends GutGameplayTest

## PS-101: gli Evil <Nome> diventano malvagi per fame, non per cattiveria — una
## sola citazione condivisa fra Piccione Malvagio e tutti gli Evil (il
## proprietario ha scartato otto citazioni distinte per profilo: "mettiamone
## una generica per tutti") — e la Specialità di Barb li redime. Copre che
## `BossDefinition.get_safe_quote()` non faccia branch sul `friend_profile`
## (la variante Evil eredita la citazione del Boss ospite via
## `duplicate(true)`, come da meccanismo originale) e la riga di redenzione
## mostrata da `BarbRewardOverlay`, sempre positiva verso Barb.

const BARB_OVERLAY_SCENE := preload("res://scenes/ui/barb_reward_overlay.tscn")
const TOUCH_JOYSTICK_SCENE := preload("res://scenes/ui/touch_joystick.tscn")


func test_evil_variant_shares_the_single_boss_quote_with_no_per_friend_branch() -> void:
	var magno := load("res://data/friends/magno.tres") as FriendDefinition
	assert_true(magno != null, "Il profilo di prova deve caricarsi.")
	if magno == null:
		return

	var baseline := BossDefinition.new()
	baseline.id = &"ps101_baseline"
	baseline.quote = "Citazione di prova condivisa per PS-101."
	baseline.quote_approved = true

	var evil_magno := baseline.duplicate(true) as BossDefinition
	evil_magno.visual_kind = BossDefinition.VisualKind.EVIL_FRIEND
	evil_magno.friend_profile = magno
	assert_eq(
		evil_magno.get_safe_quote(), baseline.get_safe_quote(),
		"Un Evil deve mostrare la stessa citazione del Boss baseline da cui e' duplicato, non una propria."
	)

	baseline.quote_approved = false
	assert_eq(
		baseline.get_safe_quote(), baseline.safe_quote_placeholder.strip_edges(),
		"Senza approvazione, sia baseline sia Evil restano sul fallback sicuro condiviso."
	)


func test_baseline_pigeon_quote_is_approved_and_live_for_baseline_and_evil() -> void:
	var baseline := load("res://data/bosses/first_boss.tres") as BossDefinition
	assert_true(baseline != null, "Il Boss baseline deve caricarsi.")
	if baseline == null:
		return
	assert_false(
		baseline.quote.strip_edges().is_empty()
		or baseline.quote.begins_with("Citazione personale in attesa"),
		"PS-101 deve sostituire il placeholder generico con una citazione a tema fame."
	)
	assert_true(
		baseline.quote_approved,
		"Il proprietario ha approvato esplicitamente il testo (vedi Decisioni PS-101): deve andare live."
	)
	assert_eq(
		baseline.get_safe_quote(), baseline.quote.strip_edges(),
		"Una volta approvata, la Boss Intro deve mostrare la citazione vera, non il fallback."
	)

	var magno := load("res://data/friends/magno.tres") as FriendDefinition
	assert_true(magno != null, "Il profilo di prova deve caricarsi.")
	if magno == null:
		return
	var evil_magno := baseline.duplicate(true) as BossDefinition
	evil_magno.visual_kind = BossDefinition.VisualKind.EVIL_FRIEND
	evil_magno.friend_profile = magno
	assert_eq(
		evil_magno.get_safe_quote(), baseline.get_safe_quote(),
		"L'Evil eredita la stessa citazione approvata del Boss baseline, senza bisogno di una propria."
	)


func test_barb_reward_stays_positive_naming_the_redeemed_friend_or_not() -> void:
	var fixture := await _create_overlay_fixture(4242)
	var controller := fixture.controller as RunController
	var service := fixture.service as UpgradeService
	var overlay := fixture.overlay as BarbRewardOverlay
	var fixture_root := fixture.root as Control

	overlay.set_redeemed_friend_name("Magno")
	service.queue_barb_reward()
	await wait_process_frames(2)
	assert_true(overlay.visible, "L'offerta deve aprirsi.")
	assert_true(
		overlay.get_redemption_text().contains("Magno"),
		"Il testo di redenzione deve nominare l'amico appena salvato."
	)
	assert_true(
		overlay.get_redemption_text().contains("Barb"),
		"Il testo deve restare centrato su Barb come figura positiva, non su un ammonimento."
	)
	assert_false(
		overlay.get_redemption_text().to_lower().contains("fame")
		or overlay.get_redemption_text().to_lower().contains("orribil"),
		"Barb non deve mai avere un tono negativo o ammonitore (feedback esplicito del proprietario)."
	)

	controller.prepare_restart()
	fixture_root.queue_free()
	await wait_process_frames(1)

	# Il Piccione Malvagio non ha un friend_profile da redimere: nessun nome,
	# ma la riga generica positiva su Barb resta comunque presente.
	var second_fixture := await _create_overlay_fixture(4243)
	var second_controller := second_fixture.controller as RunController
	var second_service := second_fixture.service as UpgradeService
	var second_overlay := second_fixture.overlay as BarbRewardOverlay
	var second_root := second_fixture.root as Control

	second_overlay.set_redeemed_friend_name("")
	second_service.queue_barb_reward()
	await wait_process_frames(2)
	assert_true(second_overlay.visible, "L'offerta deve aprirsi anche senza amico redento.")
	assert_eq(
		second_overlay.get_redemption_text(), BarbRewardOverlay.BARB_GENERIC_REWARD_LINE,
		"Senza amico redento il testo deve restare la riga generica positiva su Barb."
	)
	assert_false(
		second_overlay.get_redemption_text().to_lower().contains("fame")
		or second_overlay.get_redemption_text().to_lower().contains("orribil"),
		"Anche il fallback generico non deve mai avere un tono negativo."
	)

	second_controller.prepare_restart()
	second_root.queue_free()
	await wait_process_frames(1)


func test_evil_boss_defeat_reports_the_redeemed_friend_name() -> void:
	var slice := await instantiate_movement_slice()
	var controller := slice.get_run_controller() as RunController
	var encounter := slice.get_boss_encounter() as BossEncounter
	assert_true(controller != null and encounter != null, "PS-101 richiede le dipendenze Boss della scena.")
	if controller == null or encounter == null:
		return

	controller.set_process(false)
	encounter.evil_boss_chance = 1.0
	controller._process(120.01)
	var definition := encounter.get_active_definition()
	assert_true(definition != null and definition.is_evil_variant(), "evil_boss_chance=1 deve aprire un Evil.")
	if definition == null or definition.friend_profile == null:
		controller.prepare_restart()
		return
	var expected_name := definition.friend_profile.get_public_display_name()

	encounter.complete_intro()
	var boss := encounter.get_active_boss()
	assert_true(boss != null, "Il Boss deve restare attivo dopo l'intro.")
	if boss == null:
		controller.prepare_restart()
		return
	var boss_health := boss.get_health_component()
	assert_true(boss.take_damage(boss_health.health_current), "Il danno letale deve chiudere il Boss.")
	assert_eq(
		encounter.get_last_defeated_friend_name(), expected_name,
		"Sconfiggere un Evil deve riportare il nome buono dell'amico appena redento."
	)

	controller.prepare_restart()
	print("EVIL_HUNGER_NARRATIVE_SMOKE_OK")


func test_baseline_pigeon_defeat_reports_no_friend_to_redeem() -> void:
	var slice := await instantiate_movement_slice()
	var controller := slice.get_run_controller() as RunController
	var encounter := slice.get_boss_encounter() as BossEncounter
	assert_true(controller != null and encounter != null, "PS-101 richiede le dipendenze Boss della scena.")
	if controller == null or encounter == null:
		return

	controller.set_process(false)
	encounter.evil_boss_chance = 0.0
	controller._process(120.01)
	var baseline_definition := encounter.get_active_definition()
	assert_true(
		baseline_definition != null and not baseline_definition.is_evil_variant(),
		"evil_boss_chance=0 deve aprire il Piccione Malvagio."
	)
	if baseline_definition == null:
		controller.prepare_restart()
		return
	encounter.complete_intro()
	var baseline_boss := encounter.get_active_boss()
	assert_true(baseline_boss != null, "Il Boss baseline deve restare attivo dopo l'intro.")
	if baseline_boss == null:
		controller.prepare_restart()
		return
	var baseline_health := baseline_boss.get_health_component()
	assert_true(baseline_boss.take_damage(baseline_health.health_current), "Il danno letale deve chiudere anche il baseline.")
	assert_eq(
		encounter.get_last_defeated_friend_name(), "",
		"Il Piccione Malvagio non ha nessun amico da redimere: il nome deve restare vuoto."
	)

	controller.prepare_restart()


func _create_overlay_fixture(seed_value: int) -> Dictionary:
	var fixture_root := Control.new()
	fixture_root.name = "Ps101BarbFixture"
	fixture_root.process_mode = Node.PROCESS_MODE_ALWAYS
	fixture_root.position = Vector2(20.0, 20.0)
	fixture_root.size = Vector2(1240.0, 680.0)

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
	registry.definitions = [
		_make_filler(&"ps101_filler_a"),
		_make_filler(&"ps101_filler_b"),
		_make_filler(&"ps101_filler_c"),
	]
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
	assert_true(registry.rebuild_registry(), "La fixture PS-101 deve avere un catalogo valido.")
	assert_true(service.configure(registry, controller, experience), "La fixture PS-101 deve configurare il service.")
	assert_true(overlay.configure(service, joystick), "La fixture PS-101 deve configurare l'overlay.")
	assert_true(controller.start_run(seed_value), "La fixture PS-101 deve avviare la run.")
	return {
		"root": fixture_root,
		"controller": controller,
		"service": service,
		"overlay": overlay,
	}


func _make_filler(upgrade_id: StringName) -> UpgradeDefinition:
	var definition := UpgradeDefinition.new()
	definition.id = upgrade_id
	definition.title = String(upgrade_id)
	definition.description = "Potenziamento bonus per la verifica PS-101."
	definition.effect_id = &"smoke_effect"
	definition.weight = 1.0
	definition.max_rank = 5
	definition.repeatable = true
	definition.tags = [&"test"]
	return definition
