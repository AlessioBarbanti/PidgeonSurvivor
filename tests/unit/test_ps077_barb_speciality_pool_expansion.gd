extends GutGameplayTest

## PS-077: le quattro carte signature B13 completano il pool delle Specialità
## di Barb aperto da PS-012. Il pool va misurato sulla scena composta e non su
## una fixture isolata: il punto della card e' proprio che le otto carte
## convivano nello stesso catalogo di run.

const BEER := preload("res://data/upgrades/specialities/beer_signature.tres")
const CHRONIC_DELAY := preload("res://data/upgrades/specialities/chronic_delay.tres")
const DAMAGE_SHOCKWAVE := preload("res://data/upgrades/specialities/damage_shockwave.tres")
const GOSSIP := preload("res://data/upgrades/specialities/gossip_projectiles.tres")
const PIERCING_ROUNDS := preload("res://data/upgrades/specialities/piercing_rounds.tres")
const DOUBLE_BARREL := preload("res://data/upgrades/specialities/double_barrel.tres")
const DEATH_BURST := preload("res://data/upgrades/specialities/death_burst.tres")

## PS-100 ha rimosso L'Ansia (`anxiety_signature`) dal gioco: le fixture
## isolate di questo file (che ricostruivano il roster con le carte reali
## dell'epoca PS-077) contano ora sette Specialità, non più otto.
const EXPECTED_SPECIALITY_COUNT := 7
## PS-094 aggiunge una nona Specialità reale (Bis alla Griglia) al catalogo di
## run cablato in movement_slice.tscn; PS-100 ne rimuove una (L'Ansia): la
## scena composta reale conta otto Specialità, di nuovo, per coincidenza
## numerica con l'epoca pre-PS-094.
const EXPECTED_LIVE_SPECIALITY_COUNT := 8
const BARB_OFFER_SIZE := 3

## Valori B13 congelati a mano.
##
## La card vieta ogni modifica meccanica alle carte migrate rimaste (PS-100 ha
## rimosso `anxiety_signature` da questo elenco): rileggere il `.tres` che si
## vuole proteggere non proverebbe niente, quindi il confronto avviene contro
## i numeri scritti qui.
const FROZEN_B13_MECHANICS := {
	&"beer_signature": {
		"effect_id": &"beer_signature",
		"weight": 1.0,
		"max_rank": 1,
		"repeatable": false,
		"parameters": {
			"fire_rate_multiplier": 1.25,
			"aim_spread_degrees": 24.0,
		},
	},
	&"chronic_delay": {
		"effect_id": &"chronic_delay",
		"weight": 1.0,
		"max_rank": 1,
		"repeatable": false,
		"parameters": {
			"duration_seconds": 3.0,
			"interval_seconds": 12.0,
			"slow_factor": 0.5,
		},
	},
	&"damage_shockwave": {
		"effect_id": &"damage_shockwave",
		"weight": 1.0,
		"max_rank": 1,
		"repeatable": false,
		"parameters": {
			"knockback_duration": 0.2,
			"knockback_speed": 420.0,
			"radius": 220.0,
			"visual_duration": 0.28,
		},
	},
}


func test_migrated_cards_declare_speciality_without_touching_mechanics() -> void:
	for migrated_id: Variant in FROZEN_B13_MECHANICS:
		var upgrade_id := migrated_id as StringName
		var definition := _resolve_migrated(upgrade_id)
		assert_true(definition != null, "PS-077 deve conservare la carta %s." % upgrade_id)
		if definition == null:
			continue
		assert_eq(
			definition.resource_path,
			"res://data/upgrades/specialities/%s.tres" % upgrade_id,
			"%s deve vivere insieme alle altre Specialità." % upgrade_id
		)
		assert_true(
			definition.is_valid() and definition.is_speciality,
			"%s deve restare valida e dichiararsi Specialità di Barb." % upgrade_id
		)

		var frozen: Dictionary = FROZEN_B13_MECHANICS[upgrade_id]
		assert_eq(definition.effect_id, frozen["effect_id"], "%s deve conservare l'effect_id B13." % upgrade_id)
		assert_almost_eq(definition.weight, float(frozen["weight"]), FLOAT_TOLERANCE, "%s deve conservare il peso B13." % upgrade_id)
		assert_eq(definition.max_rank, int(frozen["max_rank"]), "%s deve conservare il max_rank B13." % upgrade_id)
		assert_eq(definition.repeatable, bool(frozen["repeatable"]), "%s deve conservare la ripetibilità B13." % upgrade_id)

		var frozen_parameters: Dictionary = frozen["parameters"]
		assert_eq(
			definition.effect_parameters.size(), frozen_parameters.size(),
			"%s non deve guadagnare né perdere parametri." % upgrade_id
		)
		for parameter_key: Variant in frozen_parameters:
			assert_almost_eq(
				float(definition.effect_parameters.get(parameter_key, NAN)),
				float(frozen_parameters[parameter_key]),
				FLOAT_TOLERANCE,
				"%s deve conservare il parametro %s." % [upgrade_id, parameter_key]
			)
		assert_true(
			&"signature" in definition.tags,
			"%s deve conservare il tag signature che la identifica come carta B13." % upgrade_id
		)


func test_composed_run_locks_every_speciality_and_keeps_them_out_of_level_up() -> void:
	var movement_slice := await instantiate_movement_slice()
	var controller := movement_slice.get_run_controller() as RunController
	var registry := movement_slice.get_upgrade_registry() as UpgradeRegistry
	var service := movement_slice.get_upgrade_service() as UpgradeService
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	assert_true(
		controller != null and registry != null and service != null,
		"La scena composta deve esporre catalogo, service e run."
	)
	if controller == null or registry == null or service == null:
		return

	controller.set_process(false)
	if spawner != null:
		spawner.set_process(false)

	assert_eq(
		registry.get_speciality_definitions().size(), EXPECTED_LIVE_SPECIALITY_COUNT,
		"Il catalogo di run deve registrare le nove Specialità di Barb (PS-094)."
	)
	assert_eq(
		service.get_locked_speciality_definitions().size(), EXPECTED_LIVE_SPECIALITY_COUNT,
		"Ogni run deve iniziare con tutte e nove le Specialità bloccate."
	)

	# Una singola pesca non proverebbe l'esclusione: il pool normale e' pesato
	# e con abbastanza carte statistiche potrebbe non mostrarne una comunque.
	for draw_index in 24:
		for offered in service.generate_offer(draw_index + 1):
			assert_false(
				offered.is_speciality,
				"Il level-up normale non deve mai offrire una Specialità bloccata (pesca %d)." % (draw_index + 1)
			)

	controller.prepare_restart()


func test_barb_offers_every_speciality_once_without_repeating_an_unlocked_one() -> void:
	var fixture := await _create_fixture(78701)
	var service := fixture.get_node("UpgradeService") as UpgradeService
	var controller := fixture.get_node("RunController") as RunController

	var seen_ids: Dictionary = {}
	for reward_index in EXPECTED_SPECIALITY_COUNT:
		var locked_before := service.get_locked_speciality_definitions().size()
		service.queue_barb_reward()
		assert_eq(
			controller.get_state(), RunController.RunState.BARB_REWARD,
			"La ricompensa %d deve aprire lo stato dedicato a Barb." % (reward_index + 1)
		)
		var offer := service.get_current_barb_offer()
		assert_eq(
			offer.size(), mini(BARB_OFFER_SIZE, locked_before),
			"Barb deve offrire fino a tre Specialità ancora bloccate."
		)
		var offer_ids: Dictionary = {}
		for definition in offer:
			assert_false(
				seen_ids.has(definition.id),
				"Barb non deve riproporre %s dopo averla già assegnata." % definition.id
			)
			assert_false(offer_ids.has(definition.id), "La stessa offerta non deve contenere duplicati.")
			offer_ids[definition.id] = true

		var chosen_id := offer[0].id
		assert_true(service.select_barb_speciality(chosen_id), "La Specialità offerta deve poter essere scelta.")
		assert_eq(service.get_rank(chosen_id), 1, "Barb deve assegnare il rank 1 alla Specialità scelta.")
		seen_ids[chosen_id] = true

	assert_eq(
		seen_ids.size(), EXPECTED_SPECIALITY_COUNT,
		"Sette ricompense Boss devono coprire tutte e sette le Specialità, senza ripetizioni."
	)
	assert_true(
		service.get_locked_speciality_definitions().is_empty(),
		"Dopo sette scelte non deve restare nessuna Specialità bloccata."
	)

	# Le carte migrate rimaste hanno max_rank = 1: una volta sbloccate escono
	# anche dal pool normale, senza bisogno di una regola dedicata.
	for draw_index in 24:
		for offered in service.generate_offer(draw_index + 1):
			assert_false(
				FROZEN_B13_MECHANICS.has(offered.id),
				"Una Specialità max_rank 1 già sbloccata non deve tornare nel level-up normale."
			)

	controller.prepare_restart()


func test_same_seed_reproduces_the_same_sequence_over_every_speciality() -> void:
	var fixture_a := await _create_fixture(78702)
	var fixture_b := await _create_fixture(78702)
	var service_a := fixture_a.get_node("UpgradeService") as UpgradeService
	var service_b := fixture_b.get_node("UpgradeService") as UpgradeService

	for _reward_index in EXPECTED_SPECIALITY_COUNT:
		service_a.queue_barb_reward()
		service_b.queue_barb_reward()
		var ids_a := service_a.get_current_barb_offer_ids()
		var ids_b := service_b.get_current_barb_offer_ids()
		assert_false(ids_a.is_empty(), "L'offerta di Barb non deve essere vuota finché restano Specialità bloccate.")
		assert_eq(ids_a, ids_b, "Lo stesso seed e le stesse scelte devono riprodurre la stessa offerta di Barb.")
		assert_true(service_a.select_barb_speciality(ids_a[0]), "La fixture A deve poter scegliere la prima carta.")
		assert_true(service_b.select_barb_speciality(ids_b[0]), "La fixture B deve poter scegliere la prima carta.")

	(fixture_a.get_node("RunController") as RunController).prepare_restart()
	(fixture_b.get_node("RunController") as RunController).prepare_restart()


func test_restart_and_character_change_relock_every_speciality() -> void:
	var movement_slice := await instantiate_movement_slice()
	var controller := movement_slice.get_run_controller() as RunController
	var service := movement_slice.get_upgrade_service() as UpgradeService
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	assert_true(controller != null and service != null, "La scena composta deve esporre service e run.")
	if controller == null or service == null:
		return

	controller.set_process(false)
	if spawner != null:
		spawner.set_process(false)

	service.queue_barb_reward()
	var offer_ids := service.get_current_barb_offer_ids()
	assert_false(offer_ids.is_empty(), "La prima ricompensa Boss deve offrire Specialità bloccate.")
	if offer_ids.is_empty():
		controller.prepare_restart()
		return
	assert_true(service.select_barb_speciality(offer_ids[0]), "La fixture deve poter sbloccare una Specialità.")
	assert_eq(
		service.get_locked_speciality_definitions().size(), EXPECTED_LIVE_SPECIALITY_COUNT - 1,
		"Una sola Specialità deve risultare sbloccata prima del restart."
	)

	assert_true(controller.request_defeat(), "La fixture deve poter raggiungere un terminale.")
	assert_true(movement_slice.restart_run(77002), "Il restart deve poter avviare una nuova run.")
	await wait_process_frames(2)
	assert_eq(
		service.get_locked_speciality_definitions().size(), EXPECTED_LIVE_SPECIALITY_COUNT,
		"Il restart deve ribloccare tutte e nove le Specialità."
	)
	assert_true(service.get_ranks().is_empty(), "Il restart deve azzerare anche i rank assegnati da Barb.")

	service.queue_barb_reward()
	var second_offer_ids := service.get_current_barb_offer_ids()
	assert_false(second_offer_ids.is_empty(), "La nuova run deve poter riaprire una ricompensa Barb.")
	if not second_offer_ids.is_empty():
		assert_true(
			service.select_barb_speciality(second_offer_ids[0]),
			"La nuova run deve poter sbloccare di nuovo una Specialità."
		)

	assert_true(
		movement_slice.run_b18v_restart_profile_cycle(&"bea", 77003),
		"Il cambio personaggio deve poter avviare una run con un altro amico."
	)
	await wait_process_frames(2)
	assert_eq(
		service.get_locked_speciality_definitions().size(), EXPECTED_LIVE_SPECIALITY_COUNT,
		"Il cambio personaggio deve ribloccare tutte e nove le Specialità."
	)
	assert_true(service.get_ranks().is_empty(), "Il cambio personaggio deve azzerare i rank della run precedente.")

	controller.prepare_restart()
	print("BARB_SPECIALITY_POOL_EXPANSION_SMOKE_OK")


func _resolve_migrated(upgrade_id: StringName) -> UpgradeDefinition:
	match upgrade_id:
		&"beer_signature":
			return BEER
		&"chronic_delay":
			return CHRONIC_DELAY
		&"damage_shockwave":
			return DAMAGE_SHOCKWAVE
	return null


## Fixture minima con le sole sette Specialità reali rimaste (PS-100 ha
## rimosso `anxiety_signature`) più due carte statistiche fittizie: isola il
## pool di Barb dal bilanciamento del catalogo completo, che cambia a ogni
## card e renderebbe instabile un'asserzione sulle pesche.
func _create_fixture(seed_value: int) -> Node:
	var definitions: Array[UpgradeDefinition] = [
		BEER, CHRONIC_DELAY, DAMAGE_SHOCKWAVE,
		GOSSIP, PIERCING_ROUNDS, DOUBLE_BARREL, DEATH_BURST,
		_make_filler(&"ps077_filler_a"), _make_filler(&"ps077_filler_b"),
	]
	var fixture := Node.new()
	fixture.name = "Ps077BarbFixture"
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
	assert_true(registry.rebuild_registry(), "La fixture PS-077 deve avere un catalogo valido.")
	assert_true(service.configure(registry, controller, experience), "La fixture PS-077 deve configurare il service.")
	assert_true(controller.start_run(seed_value), "La fixture PS-077 deve avviare la run.")
	return fixture


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
