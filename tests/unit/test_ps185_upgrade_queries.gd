extends GutTest


class SaturationRegistry extends UpgradeEffectRegistry:
	var saturated_ids: Array[StringName] = []

	func is_rank_saturated(definition: UpgradeDefinition, _current_rank: int) -> bool:
		return definition.id in saturated_ids


func test_acquired_snapshots_exclude_implicit_ranks_and_sort_ties_by_id() -> void:
	var service := _create_service(18500)
	assert_eq(service.get_rank(&"ability_rank_test"), 1)
	assert_true(service.get_acquired_upgrades().is_empty())
	_acquire(service, &"zeta")
	_acquire(service, &"alpha")
	_acquire(service, &"ability_rank_test")
	var entries := service.get_acquired_upgrades()
	assert_eq(entries.size(), 3)
	assert_eq(entries[0].definition.id, &"ability_rank_test")
	assert_eq(entries[0].rank, 2)
	assert_eq(entries[1].definition.id, &"alpha")
	assert_eq(entries[2].definition.id, &"zeta")
	service.get_run_controller().prepare_restart()
	assert_true(service.get_acquired_upgrades().is_empty())
	assert_eq(entries.size(), 3, "Il restart non modifica uno snapshot già consegnato.")
	assert_eq(entries[0].rank, 2)


func test_returned_entries_cannot_modify_the_service_or_later_snapshots() -> void:
	var service := _create_service(18500)
	_acquire(service, &"alpha")
	var first := service.get_acquired_upgrades()
	var second := service.get_acquired_upgrades()
	first[0].rank = 99
	first[0].definition = null
	first.clear()
	assert_eq(service.get_rank(&"alpha"), 1)
	assert_eq(second[0].rank, 1)
	assert_eq(second[0].definition.id, &"alpha")
	assert_eq(service.get_acquired_upgrades()[0].rank, 1)
	service.get_run_controller().prepare_restart()


func test_unconfigured_service_has_no_acquired_upgrades() -> void:
	var service := UpgradeService.new()
	add_child_autofree(service)
	assert_true(service.get_acquired_upgrades().is_empty())


func test_saturation_filters_normal_and_bonus_offers_without_emptying_the_pool() -> void:
	var service := _create_service(18504)
	var saturation := SaturationRegistry.new()
	add_child_autofree(saturation)
	service.set_effect_registry(saturation)
	saturation.saturated_ids = [&"alpha"]
	assert_eq(service.generate_offer(2).size(), 2)
	assert_false(service.get_current_offer_ids().has(&"alpha"))
	service.queue_barb_reward()
	assert_true(service.is_barb_bonus_mode())
	assert_eq(service.get_current_barb_offer().size(), 2)
	assert_false(service.get_current_barb_offer_ids().has(&"alpha"))
	service.get_run_controller().prepare_restart()
	assert_true(service.get_run_controller().start_run(18504))
	assert_true(service.set_equipped_ability_id(&"other"))
	saturation.saturated_ids = [&"alpha", &"zeta"]
	# L'abilità esclusa non deve impedire il fallback dei due candidati saturi.
	assert_eq(service.generate_offer(2).size(), 2)
	assert_false(service.get_current_offer_ids().has(&"ability_rank_test"))
	service.queue_barb_reward()
	assert_eq(service.get_current_barb_offer().size(), 2)
	assert_false(service.get_current_barb_offer_ids().has(&"ability_rank_test"))
	service.get_run_controller().prepare_restart()


func test_bonus_draws_do_not_advance_the_normal_rng_stream() -> void:
	var first := _create_service(18501)
	var second := _create_service(18501)
	first.queue_barb_reward()
	assert_true(first.is_barb_bonus_mode())
	for index in UpgradeService.BARB_BONUS_SELECTIONS:
		assert_eq(first.get_barb_bonus_index(), index + 1)
		assert_true(first.select_barb_bonus_upgrade(&"alpha"))
	for level in range(2, 8):
		assert_eq(
			_ids(first.generate_offer(level)), _ids(second.generate_offer(level)),
			"PS-185: le scelte bonus non consumano il RNG dei level-up."
		)
	(first.get_run_controller() as RunController).prepare_restart()
	(second.get_run_controller() as RunController).prepare_restart()


func test_normal_draws_do_not_advance_the_barb_rng_stream() -> void:
	var first := _create_service(18502)
	var second := _create_service(18502)
	for level in range(2, 8):
		first.generate_offer(level)
	first.queue_barb_reward()
	second.queue_barb_reward()
	for index in UpgradeService.BARB_BONUS_SELECTIONS:
		assert_eq(first.get_current_barb_offer_ids(), second.get_current_barb_offer_ids())
		assert_true(first.select_barb_bonus_upgrade(&"alpha"))
		assert_true(second.select_barb_bonus_upgrade(&"alpha"))
	(first.get_run_controller() as RunController).prepare_restart()
	(second.get_run_controller() as RunController).prepare_restart()


func test_offer_sequence_characterization() -> void:
	var service := _create_service(18503)
	var sequence: Array[String] = []
	for level in range(2, 6):
		sequence.append("|".join(PackedStringArray(_ids(service.generate_offer(level)))))
	service.queue_barb_reward()
	sequence.append("|".join(PackedStringArray(service.get_current_barb_offer_ids())))
	assert_true(service.select_barb_bonus_upgrade(&"alpha"))
	sequence.append("|".join(PackedStringArray(service.get_current_barb_offer_ids())))
	assert_true(service.select_barb_bonus_upgrade(&"alpha"))
	assert_eq(sequence, [
		"alpha|ability_rank_test|zeta",
		"ability_rank_test|zeta|alpha",
		"alpha|zeta|ability_rank_test",
		"ability_rank_test|zeta|alpha",
		"zeta|ability_rank_test|alpha",
		"zeta|ability_rank_test|alpha",
	], "Sequenza registrata prima del refactoring, seed 18503.")
	service.get_run_controller().prepare_restart()


func _acquire(service: UpgradeService, upgrade_id: StringName) -> void:
	assert_true(service.get_experience_system().add_experience(1))
	assert_true(service.select_upgrade(upgrade_id))


func _create_service(seed_value: int) -> UpgradeService:
	var fixture := Node.new()
	var controller := RunController.new()
	var experience := ExperienceSystem.new()
	var curve := ExperienceCurve.new()
	curve.base_experience_required = 1
	curve.experience_growth_per_level = 0
	experience.experience_curve = curve
	var registry := UpgradeRegistry.new()
	var alpha := _make_definition(&"alpha")
	var zeta := _make_definition(&"zeta")
	zeta.weight = 2.0
	var ability := _make_definition(&"ability_rank_test")
	ability.effect_id = &"ability_rank"
	ability.effect_parameters = {"ability_id": &"test"}
	ability.initial_rank = 1
	ability.max_rank = 5
	ability.weight = 3.0
	registry.definitions = [zeta, ability, alpha]
	var service := UpgradeService.new()
	fixture.add_child(controller)
	fixture.add_child(experience)
	fixture.add_child(registry)
	fixture.add_child(service)
	add_child_autofree(fixture)
	controller.set_process(false)
	experience.set_run_controller(controller)
	assert_true(service.configure(registry, controller, experience))
	assert_true(service.set_equipped_ability_id(&"test"))
	assert_true(controller.start_run(seed_value))
	return service


func _make_definition(id: StringName) -> UpgradeDefinition:
	var definition := UpgradeDefinition.new()
	definition.id = id
	definition.title = String(id)
	definition.description = "Fixture PS-185."
	definition.effect_id = &"test_effect"
	definition.repeatable = true
	return definition


func _ids(definitions: Array[UpgradeDefinition]) -> Array[StringName]:
	var ids: Array[StringName] = []
	for definition in definitions:
		ids.append(definition.id)
	return ids
