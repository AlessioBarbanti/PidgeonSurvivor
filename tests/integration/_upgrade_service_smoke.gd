extends SceneTree

const MOVEMENT_SLICE_SCENE := preload("res://scenes/game/movement_slice.tscn")
const SWIFT_STEPS := preload("res://data/upgrades/swift_steps.tres")
const INITIAL_VIEWPORT_SIZE := Vector2i(1280, 720)

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	paused = false
	await process_frame
	_validate_definition_and_registry()
	await _validate_reproducible_draws()
	await _validate_fallback_and_reset()
	await _validate_composed_level_flow()
	await _finish()


func _validate_definition_and_registry() -> void:
	var data_definition := SWIFT_STEPS as UpgradeDefinition
	_expect(data_definition != null and data_definition.is_valid(), "Il Resource upgrade deve essere valido.")
	if data_definition != null:
		_expect(data_definition.id == &"swift_steps", "L'ID dati deve essere stabile.")
		_expect(data_definition.effect_id == &"player_move_speed_multiplier", "L'effetto deve essere dichiarativo.")
		_expect(data_definition.max_rank == 5 and not data_definition.repeatable, "Il rank massimo deve provenire dai dati.")

	var invalid_id := _make_definition(&"Invalid ID")
	_expect(not invalid_id.is_valid(), "Gli ID non snake_case devono essere respinti.")
	var invalid_fallback := _make_definition(&"invalid_fallback", true)
	invalid_fallback.repeatable = false
	_expect(not invalid_fallback.is_valid(), "Un fallback con cap deve essere respinto.")

	var duplicate_a := _make_definition(&"duplicate")
	var duplicate_b := _make_definition(&"duplicate")
	var duplicate_registry := UpgradeRegistry.new()
	duplicate_registry.definitions = [duplicate_a, duplicate_b]
	_expect(not duplicate_registry.rebuild_registry(), "Il registry deve respingere ID duplicati.")
	_expect(duplicate_registry.resolve_definition(&"duplicate") == null, "Un ID ambiguo non deve essere risolvibile.")

	var missing_prerequisite := _make_definition(&"advanced")
	missing_prerequisite.prerequisites = {&"base": 1}
	var missing_registry := UpgradeRegistry.new()
	missing_registry.definitions = [missing_prerequisite]
	_expect(not missing_registry.rebuild_registry(), "Un prerequisito non registrato deve invalidare il catalogo.")
	_expect(missing_registry.resolve_definition(&"advanced") == null, "Una definizione con prerequisito assente va esclusa.")

	var base := _make_definition(&"base")
	var advanced := _make_definition(&"advanced")
	advanced.prerequisites = {&"base": 1}
	var eligibility_registry := UpgradeRegistry.new()
	eligibility_registry.definitions = [base, advanced]
	_expect(eligibility_registry.rebuild_registry(), "Prerequisiti risolvibili devono produrre un catalogo valido.")
	_expect(
		_ids(eligibility_registry.get_eligible_definitions({})) == [&"base"],
		"Un prerequisito non acquisito deve filtrare la definizione."
	)
	_expect(
		_ids(eligibility_registry.get_eligible_definitions({&"base": 1})) == [&"advanced"],
		"Il rank massimo deve filtrare base e il prerequisito acquisito deve sbloccare advanced."
	)
	duplicate_registry.free()
	missing_registry.free()
	eligibility_registry.free()


func _validate_reproducible_draws() -> void:
	var first_sequence := await _collect_sequence(10101)
	var second_sequence := await _collect_sequence(10101)
	_expect(not first_sequence.is_empty(), "La fixture deterministica deve produrre offerte.")
	_expect(
		first_sequence == second_sequence,
		"Lo stesso seed e le stesse scelte devono riprodurre la stessa sequenza."
	)


func _collect_sequence(seed_value: int) -> Array[String]:
	var definitions: Array[UpgradeDefinition] = []
	for index in 4:
		var definition := _make_definition(StringName("choice_%d" % index))
		definition.max_rank = 10
		definition.weight = float(index + 1)
		definitions.append(definition)
	definitions.append_array(_make_fallbacks())

	var fixture := await _create_fixture(definitions, seed_value)
	var controller := fixture.get_node("RunController") as RunController
	var experience := fixture.get_node("ExperienceSystem") as ExperienceSystem
	var service := fixture.get_node("UpgradeService") as UpgradeService
	var sequence: Array[String] = []

	_expect(experience.add_experience(3), "La fixture seed deve accodare tre livelli.")
	while experience.pending_level_ups > 0:
		var offer_ids := service.get_current_offer_ids()
		_expect(_has_three_unique_ids(offer_ids), "Ogni pesca seed deve avere tre ID unici.")
		sequence.append("|".join(PackedStringArray(offer_ids)))
		if offer_ids.is_empty() or not service.select_upgrade(offer_ids[0]):
			_expect(false, "La fixture seed deve poter consumare ogni offerta.")
			break

	_expect(controller.is_running(), "La sequenza deve chiudere tutti i level-up senza frame intermedio.")
	controller.prepare_restart()
	paused = false
	fixture.queue_free()
	await process_frame
	return sequence


func _validate_fallback_and_reset() -> void:
	var primary := _make_definition(&"limited_primary")
	var definitions: Array[UpgradeDefinition] = [primary]
	definitions.append_array(_make_fallbacks())
	var fixture := await _create_fixture(definitions, 20202)
	var controller := fixture.get_node("RunController") as RunController
	var experience := fixture.get_node("ExperienceSystem") as ExperienceSystem
	var service := fixture.get_node("UpgradeService") as UpgradeService

	_expect(experience.add_experience(3), "La fixture fallback deve accodare tre livelli.")
	var first_offer := service.get_current_offer()
	_expect(_has_three_unique_ids(_ids(first_offer)), "Primaria e fallback devono restare distinti.")
	_expect(_ids(first_offer).has(&"limited_primary"), "La primaria eleggibile deve essere proposta prima del fallback completo.")
	_expect(not service.select_upgrade(&"not_offered"), "Un ID fuori offerta deve essere rifiutato senza consumare il livello.")
	_expect(service.select_upgrade(&"limited_primary"), "La primaria proposta deve poter essere acquisita.")

	var second_offer := service.get_current_offer()
	_expect(_has_three_unique_ids(_ids(second_offer)), "Il fallback completo deve avere tre ID distinti.")
	_expect(_all_fallback(second_offer), "Con la primaria al cap, l'offerta deve usare solo fallback.")
	var repeatable_id := second_offer[0].id if not second_offer.is_empty() else &""
	_expect(service.select_upgrade(repeatable_id), "Il primo fallback deve essere selezionabile.")

	var third_offer := service.get_current_offer()
	_expect(_all_fallback(third_offer), "I fallback devono restare eleggibili nei livelli successivi.")
	_expect(_ids(third_offer).has(repeatable_id), "Il fallback acquisito deve poter ricomparire in un'altra offerta.")
	_expect(service.select_upgrade(repeatable_id), "Lo stesso fallback deve poter superare max_rank perché ripetibile.")
	_expect(service.get_rank(repeatable_id) == 2, "Il rank del fallback ripetibile deve avanzare due volte.")
	_expect(controller.is_running() and service.get_draw_count() == 3, "Tre livelli devono generare e consumare tre offerte.")

	_expect(controller.request_defeat(), "La fixture fallback deve raggiungere un terminale.")
	_expect(controller.restart_run(20203), "Il restart deve avviare una run con un nuovo seed.")
	_expect(
		service.get_ranks().is_empty()
		and service.get_current_offer().is_empty()
		and service.get_draw_count() == 0
		and service.get_run_seed() == 20203,
		"Il restart deve azzerare rank, offerta e stream RNG."
	)

	controller.prepare_restart()
	paused = false
	fixture.queue_free()
	await process_frame


func _validate_composed_level_flow() -> void:
	root.content_scale_size = INITIAL_VIEWPORT_SIZE
	root.size = INITIAL_VIEWPORT_SIZE
	await process_frame
	await process_frame
	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	root.add_child(movement_slice)
	await process_frame
	await process_frame

	var controller := movement_slice.get_run_controller() as RunController
	var experience := movement_slice.get_experience_system() as ExperienceSystem
	var registry := movement_slice.get_upgrade_registry() as UpgradeRegistry
	var service := movement_slice.get_upgrade_service() as UpgradeService
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	var player := movement_slice.get_node_or_null("World/Player") as Player
	_expect(controller != null and experience != null, "La scena B10 deve conservare il loop XP.")
	_expect(registry != null and registry.is_catalog_valid(), "La scena B10 deve contenere un registry valido.")
	_expect(service != null and service.has_valid_configuration(), "La scena B10 deve contenere il service configurato.")
	if controller == null or experience == null or registry == null or service == null:
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

	_expect(
		registry.get_definitions().size() == 11,
		"Il catalogo composto deve avere otto primarie e tre fallback."
	)
	_expect(service.get_current_offer().is_empty(), "Una run senza level-up non deve anticipare carte.")
	_expect(experience.add_experience(45), "La scena composta deve attraversare tre soglie.")
	for expected_level in [2, 3, 4]:
		var offer := service.get_current_offer()
		_expect(service.get_active_offer_level() == expected_level, "Ogni livello accodato deve avere la propria offerta.")
		_expect(_has_three_unique_ids(_ids(offer)), "La scena composta deve offrire tre ID unici.")
		_expect(not _all_fallback(offer), "Le primarie eleggibili devono precedere i fallback.")
		if offer.is_empty() or not service.select_upgrade(offer[0].id):
			_expect(false, "La scena composta deve poter registrare la scelta.")
			break

	var acquired_rank_total := 0
	for rank_value: Variant in service.get_ranks().values():
		acquired_rank_total += int(rank_value)
	_expect(
		controller.is_running()
		and experience.pending_level_ups == 0
		and service.get_current_offer().is_empty()
		and service.get_draw_count() == 3
		and acquired_rank_total == 3,
		"Tre level-up consecutivi devono produrre tre scelte e poi riprendere la run."
	)

	controller.prepare_restart()
	paused = false
	movement_slice.queue_free()
	await process_frame


func _create_fixture(
	definitions: Array[UpgradeDefinition],
	seed_value: int
) -> Node:
	var fixture := Node.new()
	fixture.name = "UpgradeFixture"
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
	fixture.add_child(controller)
	fixture.add_child(experience)
	fixture.add_child(registry)
	fixture.add_child(service)
	root.add_child(fixture)
	await process_frame
	experience.set_run_controller(controller)
	_expect(registry.rebuild_registry(), "La fixture upgrade deve avere un catalogo valido.")
	_expect(service.configure(registry, controller, experience), "La fixture upgrade deve configurare il service.")
	_expect(controller.start_run(seed_value), "La fixture upgrade deve avviare la run.")
	return fixture


func _make_definition(upgrade_id: StringName, is_fallback: bool = false) -> UpgradeDefinition:
	var definition := UpgradeDefinition.new()
	definition.id = upgrade_id
	definition.title = String(upgrade_id)
	definition.description = "Definizione smoke %s." % upgrade_id
	definition.effect_id = &"smoke_effect"
	definition.weight = 1.0
	definition.max_rank = 1
	definition.repeatable = is_fallback
	definition.fallback = is_fallback
	var definition_tags: Array[StringName] = []
	definition_tags.append(&"fallback" if is_fallback else &"test")
	definition.tags = definition_tags
	return definition


func _make_fallbacks() -> Array[UpgradeDefinition]:
	return [
		_make_definition(&"fallback_alpha", true),
		_make_definition(&"fallback_beta", true),
		_make_definition(&"fallback_gamma", true),
	]


func _ids(definitions: Array[UpgradeDefinition]) -> Array[StringName]:
	var ids: Array[StringName] = []
	for definition in definitions:
		ids.append(definition.id)
	return ids


func _has_three_unique_ids(ids: Array[StringName]) -> bool:
	var unique_ids: Dictionary = {}
	for upgrade_id in ids:
		unique_ids[upgrade_id] = true
	return ids.size() == UpgradeService.DEFAULT_OFFER_SIZE and unique_ids.size() == ids.size()


func _all_fallback(definitions: Array[UpgradeDefinition]) -> bool:
	if definitions.is_empty():
		return false
	for definition in definitions:
		if not definition.fallback:
			return false
	return true


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	paused = false
	await process_frame
	if _failures.is_empty():
		print("B10_UPGRADE_SERVICE_SMOKE_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	printerr("B10_UPGRADE_SERVICE_SMOKE_FAIL count=%d" % _failures.size())
	quit(1)
