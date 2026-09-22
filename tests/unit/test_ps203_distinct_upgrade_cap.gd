extends GutTest


const ORDINARY_IDS: Array[StringName] = [&"o1", &"o2", &"o3", &"o4", &"o5", &"o6", &"o7", &"o8"]
const SPECIALITY_IDS: Array[StringName] = [&"s1", &"s2", &"s3"]
const ABILITY_ID := &"ability_rank_test"


class SaturationRegistry extends UpgradeEffectRegistry:
	var saturated_ids: Array[StringName] = []

	func is_rank_saturated(definition: UpgradeDefinition, _current_rank: int) -> bool:
		return definition.id in saturated_ids


func test_below_cap_offers_match_an_uncapped_service() -> void:
	var capped := _create_service(20301)
	var uncapped := _create_service(20301)
	uncapped.distinct_upgrade_cap = 99
	while capped.get_distinct_upgrade_ids().size() < UpgradeService.DEFAULT_DISTINCT_UPGRADE_CAP:
		var picked := _acquire_preferring_new(capped)
		assert_eq(
			_level_up(uncapped), picked.offer,
			"PS-203: sotto il tetto offerte e RNG restano quelli di prima."
		)
		assert_true(uncapped.select_upgrade(picked.id))
	_restart(capped)
	_restart(uncapped)


func test_full_cap_offers_only_owned_upgrades_and_specialities() -> void:
	var service := _create_service(20302)
	_unlock_speciality(service)
	_fill_cap(service)
	var owned := service.get_distinct_upgrade_ids()
	assert_eq(owned.size(), 6)
	var seen_speciality := false
	for level in range(2, 40):
		for definition in service.generate_offer(level):
			if definition.is_speciality:
				seen_speciality = true
				assert_true(service.is_speciality_unlocked(definition.id))
			else:
				assert_true(owned.has(definition.id), "PS-203: %s non occupa un posto." % definition.id)
	assert_true(seen_speciality, "PS-203: la Specialità sbloccata resta nelle offerte.")
	_restart(service)


func test_specialities_do_not_occupy_slots() -> void:
	var service := _create_service(20303)
	for _index in SPECIALITY_IDS.size():
		_unlock_speciality(service)
	assert_eq(service.get_unlocked_specialities().size(), 3)
	while service.get_distinct_upgrade_ids().size() < 5:
		_acquire_preferring_new(service)
	var owned := service.get_distinct_upgrade_ids()
	var offered_new := false
	for level in range(2, 40):
		for definition in service.generate_offer(level):
			if not definition.is_speciality and not owned.has(definition.id):
				offered_new = true
	assert_true(offered_new, "PS-203: con 5 posti e 3 Specialità il level-up offre carte nuove.")
	_restart(service)


func test_barb_bonus_respects_the_cap() -> void:
	var service := _create_service(20304)
	for _index in SPECIALITY_IDS.size():
		_unlock_speciality(service)
	_fill_cap(service)
	var owned := service.get_distinct_upgrade_ids()
	service.queue_barb_reward()
	assert_true(service.is_barb_bonus_mode())
	for _selection in UpgradeService.BARB_BONUS_SELECTIONS:
		var offer := service.get_current_barb_offer()
		assert_false(offer.is_empty())
		for definition in offer:
			assert_true(definition.is_speciality or owned.has(definition.id))
		assert_true(service.select_barb_bonus_upgrade(offer[0].id))
	_restart(service)


func test_saturated_full_cap_never_empties_nor_leaks() -> void:
	var service := _create_service(20305)
	var saturation := SaturationRegistry.new()
	add_child_autofree(saturation)
	service.set_effect_registry(saturation)
	_fill_cap(service)
	var owned := service.get_distinct_upgrade_ids()
	saturation.saturated_ids = owned.duplicate()
	for level in range(2, 20):
		var offer := service.generate_offer(level)
		assert_false(offer.is_empty(), "PS-203/PS-120: l'offerta non è mai vuota.")
		for definition in offer:
			assert_true(owned.has(definition.id))
	_restart(service)


func test_cap_is_a_single_service_value() -> void:
	var service := _create_service(20306)
	assert_eq(service.get_distinct_upgrade_cap(), 6)
	service.distinct_upgrade_cap = 2
	while service.get_distinct_upgrade_ids().size() < 2:
		_acquire_preferring_new(service)
	var owned := service.get_distinct_upgrade_ids()
	for level in range(2, 20):
		for definition in service.generate_offer(level):
			assert_true(owned.has(definition.id))
	service.distinct_upgrade_cap = 0
	assert_eq(service.distinct_upgrade_cap, 1, "Il setter non ammette un tetto nullo.")
	_restart(service)


func test_restart_frees_every_slot_in_acquisition_order() -> void:
	var service := _create_service(20307)
	_fill_cap(service)
	assert_eq(service.get_distinct_upgrade_ids().size(), 6)
	_restart(service)
	assert_true(service.get_distinct_upgrade_ids().is_empty())
	assert_true(service.get_run_controller().start_run(20307))
	var first := _acquire_preferring_new(service)
	var second := _acquire_preferring_new(service)
	var expected: Array[StringName] = [first.id]
	if second.id != first.id:
		expected.append(second.id)
	assert_eq(service.get_distinct_upgrade_ids(), expected, "Ordine di acquisizione.")
	_restart(service)


func _fill_cap(service: UpgradeService) -> void:
	var guard := 0
	while service.get_distinct_upgrade_ids().size() < service.distinct_upgrade_cap and guard < 200:
		_acquire_preferring_new(service)
		guard += 1
	assert_eq(service.get_distinct_upgrade_ids().size(), service.distinct_upgrade_cap)


## Level-up reale: sceglie la prima carta non ancora posseduta, se offerta.
func _acquire_preferring_new(service: UpgradeService) -> Dictionary:
	var offer := _level_up(service)
	var owned := service.get_distinct_upgrade_ids()
	var picked: StringName = offer[0]
	for upgrade_id in offer:
		if not owned.has(upgrade_id) and not service.is_speciality_unlocked(upgrade_id):
			picked = upgrade_id
			break
	assert_true(service.select_upgrade(picked))
	return {"id": picked, "offer": offer}


func _level_up(service: UpgradeService) -> Array[StringName]:
	assert_true(service.get_experience_system().add_experience(1))
	return service.get_current_offer_ids()


func _unlock_speciality(service: UpgradeService) -> void:
	service.queue_barb_reward()
	var offer := service.get_current_barb_offer_ids()
	assert_false(offer.is_empty())
	assert_true(service.select_barb_speciality(offer[0]))


func _restart(service: UpgradeService) -> void:
	assert_true(service.get_run_controller().prepare_restart())


func _create_service(seed_value: int) -> UpgradeService:
	var fixture := Node.new()
	var controller := RunController.new()
	var experience := ExperienceSystem.new()
	var curve := ExperienceCurve.new()
	curve.base_experience_required = 1
	curve.experience_growth_per_level = 0
	experience.experience_curve = curve
	var registry := UpgradeRegistry.new()
	var definitions: Array[UpgradeDefinition] = []
	for upgrade_id in ORDINARY_IDS:
		definitions.append(_make_definition(upgrade_id))
	for upgrade_id in SPECIALITY_IDS:
		var speciality := _make_definition(upgrade_id)
		speciality.is_speciality = true
		definitions.append(speciality)
	var ability := _make_definition(ABILITY_ID)
	ability.effect_id = &"ability_rank"
	ability.effect_parameters = {"ability_id": &"test"}
	ability.initial_rank = 1
	ability.max_rank = 5
	ability.repeatable = false
	definitions.append(ability)
	registry.definitions = definitions
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
	definition.description = "Fixture PS-203."
	definition.effect_id = &"test_effect"
	definition.repeatable = true
	return definition

