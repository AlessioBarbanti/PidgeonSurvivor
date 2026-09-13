extends GutGameplayTest

const SEED_VALUE := 220162


func test_ps162_full_roster_sequence_avoids_repeats() -> void:
	var movement_slice := await instantiate_movement_slice()
	var encounter := movement_slice.get_boss_encounter() as BossEncounter
	var registry := movement_slice.get_friend_registry() as FriendRegistry
	var controller := movement_slice.get_run_controller() as RunController
	assert_not_null(encounter, "PS-162 richiede BossEncounter.")
	assert_true(
		registry != null and registry.get_definitions().size() == 8,
		"PS-162 richiede gli otto profili Evil del roster."
	)
	if encounter == null or registry == null:
		return

	controller.set_process(false)
	encounter.evil_boss_chance = 1.0

	var resolved_ids: Array[StringName] = []
	for schedule_index in range(8):
		var definition := encounter.resolve_definition_for_event(SEED_VALUE, schedule_index)
		assert_true(
			definition != null and definition.is_evil_variant() and definition.friend_profile != null,
			"evil_boss_chance=1 deve sempre risolvere un Evil (indice %d)." % schedule_index
		)
		if definition == null or definition.friend_profile == null:
			return
		resolved_ids.append(definition.friend_profile.id)

	for index in range(1, resolved_ids.size()):
		assert_true(
			resolved_ids[index] != resolved_ids[index - 1],
			(
				"PS-162: lo stesso Evil non puo' apparire in due incontri consecutivi "
				+ "(indici %d e %d, entrambi %s)."
			) % [index - 1, index, resolved_ids[index]]
		)

	var first_four: Dictionary = {}
	for index in range(4):
		first_four[resolved_ids[index]] = true
	assert_true(
		first_four.size() >= 3,
		"PS-162: i primi quattro incontri devono mostrare almeno tre identità diverse (trovate %d)."
			% first_four.size()
	)

	var all_eight: Dictionary = {}
	for id in resolved_ids:
		all_eight[id] = true
	assert_eq(
		all_eight.size(), 8,
		"PS-162: con un roster di otto profili, otto incontri consecutivi devono esplorarli tutti prima di ripetere."
	)

	controller.prepare_restart()


func test_ps162_repeated_resolution_is_idempotent() -> void:
	var movement_slice := await instantiate_movement_slice()
	var encounter := movement_slice.get_boss_encounter() as BossEncounter
	var controller := movement_slice.get_run_controller() as RunController
	assert_not_null(encounter, "PS-162 richiede BossEncounter.")
	if encounter == null:
		return

	controller.set_process(false)
	encounter.evil_boss_chance = 1.0

	encounter.resolve_definition_for_event(SEED_VALUE, 0)
	encounter.resolve_definition_for_event(SEED_VALUE, 1)
	var first := encounter.resolve_definition_for_event(SEED_VALUE, 2)
	var second := encounter.resolve_definition_for_event(SEED_VALUE, 2)
	assert_true(
		first != null and second != null and first.id == second.id,
		"PS-162: risolvere due volte lo stesso schedule_index deve restare deterministico anche con la cronologia anti-ripetizione attiva."
	)

	controller.prepare_restart()


func test_ps162_restart_clears_memory() -> void:
	var movement_slice := await instantiate_movement_slice()
	var encounter := movement_slice.get_boss_encounter() as BossEncounter
	var controller := movement_slice.get_run_controller() as RunController
	assert_not_null(encounter, "PS-162 richiede BossEncounter.")
	if encounter == null:
		return

	controller.set_process(false)
	encounter.evil_boss_chance = 1.0

	var original_first := encounter.resolve_definition_for_event(SEED_VALUE, 0)
	encounter.resolve_definition_for_event(SEED_VALUE, 1)
	encounter.resolve_definition_for_event(SEED_VALUE, 2)
	assert_not_null(original_first, "PS-162 richiede una prima risoluzione valida.")
	if original_first == null:
		return

	encounter.reset_for_run()
	var first_after_reset := encounter.resolve_definition_for_event(SEED_VALUE, 0)
	assert_true(
		first_after_reset != null and first_after_reset.id == original_first.id,
		"PS-162: un restart deve azzerare la cronologia e ripetere la stessa sequenza a parità di seed."
	)

	controller.prepare_restart()


func test_ps162_small_roster_still_reaches_three_distinct_in_four() -> void:
	var movement_slice := await instantiate_movement_slice()
	var encounter := movement_slice.get_boss_encounter() as BossEncounter
	var registry := movement_slice.get_friend_registry() as FriendRegistry
	var controller := movement_slice.get_run_controller() as RunController
	assert_not_null(encounter, "PS-162 richiede BossEncounter.")
	if encounter == null or registry == null:
		return
	if registry.get_definitions().size() < 3:
		return

	controller.set_process(false)
	var baseline := encounter.boss_definition
	var full_profiles := registry.get_definitions()
	var small_profiles: Array[FriendDefinition] = [
		full_profiles[0], full_profiles[1], full_profiles[2]
	]

	var history: Array[StringName] = []
	var resolved_ids: Array[StringName] = []
	for schedule_index in range(4):
		var definition := BossEncounter.resolve_variant(
			baseline, small_profiles, SEED_VALUE, schedule_index, 1.0, null, history
		)
		assert_true(
			definition != null and definition.friend_profile != null,
			"PS-162: un roster di tre profili deve comunque risolvere un Evil (indice %d)." % schedule_index
		)
		if definition == null or definition.friend_profile == null:
			return
		resolved_ids.append(definition.friend_profile.id)
		history.append(definition.friend_profile.id)

	assert_true(
		resolved_ids[0] != resolved_ids[1] and resolved_ids[1] != resolved_ids[2] and resolved_ids[0] != resolved_ids[2],
		"PS-162: con esattamente tre Evil eleggibili, i primi tre incontri devono coprirli tutti e tre."
	)
	var distinct_in_four: Dictionary = {}
	for id in resolved_ids:
		distinct_in_four[id] = true
	assert_true(
		distinct_in_four.size() >= 3,
		"PS-162: anche con un roster minimo di tre, i primi quattro incontri devono mostrare almeno tre identità diverse."
	)

	controller.prepare_restart()
	print("PS162_BOSS_VARIETY_SEQUENCE_SMOKE_OK")
