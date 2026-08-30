extends GutGameplayTest

const GOSSIP := preload("res://data/upgrades/specialities/gossip_projectiles.tres")
const PIERCING_ROUNDS := preload("res://data/upgrades/specialities/piercing_rounds.tres")
const DOUBLE_BARREL := preload("res://data/upgrades/specialities/double_barrel.tres")
const DEATH_BURST := preload("res://data/upgrades/specialities/death_burst.tres")


func test_speciality_definitions_are_relocated_and_flagged() -> void:
	for definition in [GOSSIP, PIERCING_ROUNDS, DOUBLE_BARREL, DEATH_BURST]:
		assert_true(
			definition.is_valid() and definition.is_speciality,
			"Le quattro carte strutturali devono restare valide e dichiararsi Specialità di Barb."
		)
		assert_true(
			definition.repeatable and definition.max_rank >= 1 and definition.max_rank <= 5,
			"PS-012 non deve alterare rank o ripetibilità già implementati."
		)
	assert_eq(GOSSIP.effect_id, &"gossip_projectiles", "Gossip deve conservare il proprio effect_id.")
	assert_eq(PIERCING_ROUNDS.effect_id, &"weapon_pierce", "Colpo Perforante deve conservare il proprio effect_id.")
	assert_eq(DOUBLE_BARREL.effect_id, &"weapon_multishot", "Raffica Doppia deve conservare il proprio effect_id.")
	assert_eq(DEATH_BURST.effect_id, &"weapon_death_burst", "Esplosione Finale deve conservare il proprio effect_id.")


func test_locked_specialities_excluded_and_unlock_reenters_pool() -> void:
	var filler_a := _make_filler(&"barb_filler_a")
	var filler_b := _make_filler(&"barb_filler_b")
	var fixture := await _create_fixture(_speciality_definitions_with([filler_a, filler_b]), 30301)
	var controller := fixture.get_node("RunController") as RunController
	var service := fixture.get_node("UpgradeService") as UpgradeService

	assert_eq(
		service.get_locked_speciality_definitions().size(), 4,
		"Ogni run deve iniziare con tutte le Specialità di Barb bloccate."
	)
	var normal_offer := service.generate_offer(2)
	assert_eq(
		normal_offer.size(), 2,
		"Con sole due carte normali eleggibili l'offerta non deve inventare Specialità bloccate."
	)
	for definition in normal_offer:
		assert_false(definition.is_speciality, "Il level-up normale non deve mai offrire una Specialità bloccata.")

	service.queue_barb_reward()
	assert_eq(
		controller.get_state(), RunController.RunState.BARB_REWARD,
		"La morte di un Boss deve aprire lo stato dedicato alla scelta di Barb."
	)
	var barb_offer := service.get_current_barb_offer()
	assert_eq(barb_offer.size(), 3, "Barb deve offrire fino a tre Specialità ancora bloccate.")
	assert_eq(
		_unique_ids(barb_offer).size(), barb_offer.size(),
		"L'offerta di Barb non deve contenere duplicati."
	)

	var chosen_id := barb_offer[0].id
	assert_true(
		service.select_barb_speciality(chosen_id), "La scelta di una Specialità offerta deve essere accettata."
	)
	assert_eq(service.get_rank(chosen_id), 1, "La Specialità scelta deve essere assegnata immediatamente al rank 1.")
	assert_true(service.is_speciality_unlocked(chosen_id), "La Specialità scelta deve restare sbloccata per la run.")
	assert_eq(
		controller.get_state(), RunController.RunState.RUNNING, "La scelta deve far riprendere subito la run."
	)
	assert_eq(
		service.get_locked_speciality_definitions().size(), 3,
		"Le Specialità offerte ma non scelte devono restare bloccate."
	)

	var reentry_offer := service.generate_offer(3)
	assert_eq(
		reentry_offer.size(), 3, "Con la Specialità sbloccata il pool normale deve tornare a tre carte eleggibili."
	)
	assert_true(
		_ids(reentry_offer).has(chosen_id), "La Specialità sbloccata deve rientrare nel normale pool di level-up."
	)

	controller.prepare_restart()


func test_boss_reward_rng_is_deterministic_for_same_seed_and_choices() -> void:
	var fixture_a := await _create_fixture(_speciality_definitions_with([]), 40404)
	var fixture_b := await _create_fixture(_speciality_definitions_with([]), 40404)
	var service_a := fixture_a.get_node("UpgradeService") as UpgradeService
	var service_b := fixture_b.get_node("UpgradeService") as UpgradeService

	for _iteration in 3:
		service_a.queue_barb_reward()
		service_b.queue_barb_reward()
		var ids_a := service_a.get_current_barb_offer_ids()
		var ids_b := service_b.get_current_barb_offer_ids()
		assert_false(ids_a.is_empty(), "L'offerta di Barb non deve essere vuota mentre restano Specialità bloccate.")
		assert_eq(ids_a, ids_b, "Lo stesso seed e le stesse scelte devono riprodurre la stessa offerta di Barb.")
		assert_true(service_a.select_barb_speciality(ids_a[0]), "La fixture A deve poter scegliere la prima carta offerta.")
		assert_true(service_b.select_barb_speciality(ids_b[0]), "La fixture B deve poter scegliere la prima carta offerta.")

	(fixture_a.get_node("RunController") as RunController).prepare_restart()
	(fixture_b.get_node("RunController") as RunController).prepare_restart()


func test_boss_reward_falls_back_to_bonus_selection_when_all_specialities_unlocked() -> void:
	var filler_a := _make_filler(&"barb_filler_a")
	var filler_b := _make_filler(&"barb_filler_b")
	var fixture := await _create_fixture(_speciality_definitions_with([filler_a, filler_b]), 50505)
	var controller := fixture.get_node("RunController") as RunController
	var experience := fixture.get_node("ExperienceSystem") as ExperienceSystem
	var service := fixture.get_node("UpgradeService") as UpgradeService

	for _boss_index in 4:
		var locked_before := service.get_locked_speciality_definitions().size()
		service.queue_barb_reward()
		var offer := service.get_current_barb_offer()
		assert_false(offer.is_empty(), "Finché restano Specialità bloccate Barb deve sempre poterle offrire.")
		assert_eq(
			offer.size(), mini(3, locked_before),
			"Con meno di tre Specialità bloccate l'offerta deve mostrare soltanto quelle disponibili."
		)
		assert_true(service.select_barb_speciality(offer[0].id), "Ogni Specialità offerta deve poter essere scelta.")

	assert_eq(
		service.get_locked_speciality_definitions().size(), 0, "Dopo quattro scelte tutte le Specialità devono risultare sbloccate."
	)
	var level_before := experience.level
	var xp_before := experience.experience_total

	service.queue_barb_reward()
	assert_eq(
		controller.get_state(), RunController.RunState.BARB_REWARD,
		"A catalogo Specialità esaurito la morte del Boss deve comunque aprire una ricompensa."
	)
	assert_true(
		service.is_barb_bonus_mode(), "Senza Specialità bloccate la ricompensa deve ricadere sul bonus upgrade."
	)
	var first_bonus_offer := service.get_current_barb_offer()
	assert_eq(
		first_bonus_offer.size(), 3,
		"Il fallback deve usare le stesse regole di offerta a tre carte del level-up normale."
	)
	assert_true(
		service.select_barb_bonus_upgrade(first_bonus_offer[0].id), "La prima selezione bonus deve essere accettata."
	)
	assert_true(service.is_barb_reward_active(), "Il fallback richiede due selezioni bonus consecutive.")

	var second_bonus_offer := service.get_current_barb_offer()
	assert_false(second_bonus_offer.is_empty(), "La seconda selezione bonus deve proporre un'offerta.")
	assert_true(
		service.select_barb_bonus_upgrade(second_bonus_offer[0].id), "La seconda selezione bonus deve essere accettata."
	)

	assert_eq(
		controller.get_state(), RunController.RunState.RUNNING,
		"Il fallback esaurito non deve mai bloccare la progressione della run."
	)
	assert_false(service.is_barb_reward_active(), "La sessione Barb deve chiudersi dopo le due selezioni bonus.")
	assert_eq(experience.level, level_before, "Le selezioni bonus non devono alzare il livello del Player.")
	assert_eq(experience.experience_total, xp_before, "Le selezioni bonus non devono modificare l'XP della run.")

	controller.prepare_restart()


func test_restart_relocks_every_speciality() -> void:
	var filler := _make_filler(&"barb_filler_only")
	var fixture := await _create_fixture(_speciality_definitions_with([filler]), 60606)
	var controller := fixture.get_node("RunController") as RunController
	var service := fixture.get_node("UpgradeService") as UpgradeService

	service.queue_barb_reward()
	var offer := service.get_current_barb_offer()
	assert_true(service.select_barb_speciality(offer[0].id), "La fixture di restart deve poter sbloccare una Specialità.")
	assert_eq(
		service.get_locked_speciality_definitions().size(), 3,
		"Prima del restart deve restare esattamente una Specialità sbloccata."
	)

	assert_true(controller.request_defeat(), "La fixture di restart deve poter raggiungere un terminale.")
	assert_true(controller.restart_run(60607), "Il restart deve poter avviare una nuova run con un nuovo seed.")
	assert_eq(
		service.get_locked_speciality_definitions().size(), 4,
		"Il restart deve ribloccare tutte le Specialità (lo stesso percorso usato dal cambio personaggio)."
	)
	assert_true(service.get_ranks().is_empty(), "Il restart deve azzerare anche i rank acquisiti in run.")

	controller.prepare_restart()


func test_composed_boss_defeat_opens_barb_reward_end_to_end() -> void:
	var movement_slice := await instantiate_movement_slice()
	var controller := movement_slice.get_run_controller() as RunController
	var encounter := movement_slice.get_boss_encounter() as BossEncounter
	var service := movement_slice.get_upgrade_service() as UpgradeService
	var overlay := movement_slice.get_barb_reward_overlay() as BarbRewardOverlay
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	assert_true(
		controller != null and encounter != null and service != null and overlay != null,
		"La scena composta deve esporre tutte le dipendenze PS-012."
	)
	if controller == null or encounter == null or service == null or overlay == null:
		return

	controller.set_process(false)
	if spawner != null:
		spawner.set_process(false)
	assert_eq(
		service.get_locked_speciality_definitions().size(), 4,
		"La scena composta deve iniziare con tutte le Specialità bloccate."
	)

	controller._process(120.01)
	var boss := encounter.get_active_boss()
	assert_true(boss != null, "La soglia deve generare il primo Boss.")
	if boss == null:
		controller.prepare_restart()
		return
	assert_true(encounter.complete_intro(), "AFFRONTA deve chiudere l'introduzione prima del combattimento.")

	var boss_health := boss.get_health_component()
	assert_true(boss.take_damage(boss_health.health_max), "Il danno letale deve concludere il Boss.")

	# La ricompensa XP del Boss può innescare un level-up nello stesso frame:
	# Barb resta in coda finché quel level-up non si chiude (vedi
	# UpgradeService._on_run_state_changed_for_barb_reward).
	var guard := 0
	while controller.get_state() == RunController.RunState.LEVEL_UP and guard < 10:
		var pending_offer := service.get_current_offer()
		assert_false(pending_offer.is_empty(), "Un level-up aperto deve avere un'offerta da consumare.")
		assert_true(service.select_upgrade(pending_offer[0].id), "Il level-up in coda deve poter essere risolto.")
		guard += 1

	assert_eq(
		controller.get_state(), RunController.RunState.BARB_REWARD,
		"Dopo eventuali level-up in coda la morte del Boss deve aprire la ricompensa di Barb."
	)
	assert_true(overlay.visible and overlay.is_accepting_selection(), "L'overlay di Barb deve mostrare l'offerta.")
	assert_eq(
		overlay.get_title_text(), "LE SPECIALITÀ DI BARB",
		"Il titolo della ricompensa Boss deve restare ben visibile nella selezione."
	)
	var offered_ids := service.get_current_barb_offer_ids()
	assert_true(offered_ids.size() >= 1 and offered_ids.size() <= 3, "Barb deve offrire da una a tre Specialità.")

	await _wait_barb_selection_unlock(overlay)
	assert_true(overlay.submit_card(0), "La UI deve poter inoltrare la prima carta offerta.")
	assert_eq(controller.get_state(), RunController.RunState.RUNNING, "La scelta deve far riprendere la run.")
	assert_true(
		service.is_speciality_unlocked(offered_ids[0]), "La carta scelta nella UI deve risultare sbloccata nel service."
	)
	assert_false(overlay.visible, "L'overlay deve nascondersi subito dopo la scelta.")

	controller.prepare_restart()
	print("BARB_SPECIALITIES_SMOKE_OK")


func _speciality_definitions_with(extra: Array[UpgradeDefinition]) -> Array[UpgradeDefinition]:
	var definitions: Array[UpgradeDefinition] = [GOSSIP, PIERCING_ROUNDS, DOUBLE_BARREL, DEATH_BURST]
	definitions.append_array(extra)
	return definitions


func _make_filler(upgrade_id: StringName) -> UpgradeDefinition:
	var definition := UpgradeDefinition.new()
	definition.id = upgrade_id
	definition.title = String(upgrade_id)
	definition.description = "Potenziamento smoke %s." % upgrade_id
	definition.effect_id = &"smoke_effect"
	definition.weight = 1.0
	definition.max_rank = 5
	definition.repeatable = true
	definition.tags = [&"test"]
	return definition


func _ids(definitions: Array[UpgradeDefinition]) -> Array[StringName]:
	var ids: Array[StringName] = []
	for definition in definitions:
		ids.append(definition.id)
	return ids


func _unique_ids(definitions: Array[UpgradeDefinition]) -> Dictionary:
	var seen: Dictionary = {}
	for definition in definitions:
		seen[definition.id] = true
	return seen


func _wait_barb_selection_unlock(overlay: BarbRewardOverlay) -> void:
	while overlay.is_selection_locked():
		await get_tree().create_timer(overlay.get_selection_lock_remaining() + 0.05, true, false, true).timeout
	await wait_process_frames(2)


func _create_fixture(definitions: Array[UpgradeDefinition], seed_value: int) -> Node:
	var fixture := Node.new()
	fixture.name = "BarbFixture"
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
	add_child_autofree(fixture)
	await wait_process_frames(1)
	experience.set_run_controller(controller)
	assert_true(registry.rebuild_registry(), "La fixture PS-012 deve avere un catalogo valido.")
	assert_true(service.configure(registry, controller, experience), "La fixture PS-012 deve configurare il service.")
	assert_true(controller.start_run(seed_value), "La fixture PS-012 deve avviare la run.")
	return fixture
