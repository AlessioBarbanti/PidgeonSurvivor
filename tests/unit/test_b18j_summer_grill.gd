extends GutGameplayTest

const SUMMER_GRILL := preload("res://data/upgrades/summer_grill.tres")
const ANXIETY := preload("res://data/upgrades/anxiety_signature.tres")
const SWIFT_STEPS := preload("res://data/upgrades/swift_steps.tres")
const RAPID_FIRE := preload("res://data/upgrades/rapid_fire.tres")
const WIDE_MAGNET := preload("res://data/upgrades/wide_magnet.tres")
const MEAT_FORK_DAMAGE := preload("res://data/upgrades/meat_fork_damage.tres")

const RANK_MULTIPLIER := 1.15
const CONTRIBUTION_CAP := 2.05

var _applied_ranks: Array[int] = []


func test_summer_grill_contract() -> void:
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_run_controller() as RunController
	var experience := movement_slice.get_experience_system() as ExperienceSystem
	var service := movement_slice.get_upgrade_service() as UpgradeService
	var catalog := movement_slice.get_upgrade_registry() as UpgradeRegistry
	var effects := movement_slice.get_upgrade_effect_registry() as UpgradeEffectRegistry
	var player := movement_slice.get_player() as Player
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	var weapon := movement_slice.get_weapon_controller() as WeaponController

	assert_true(controller != null and experience != null, "B18J deve conservare run e progressione.")
	assert_true(
		service != null and catalog != null and effects != null, "B18J richiede i tre servizi upgrade."
	)
	assert_true(
		player != null and spawner != null and weapon != null, "B18J richiede la scena gameplay composta."
	)
	if (
		controller == null
		or experience == null
		or service == null
		or catalog == null
		or effects == null
		or player == null
		or spawner == null
		or weapon == null
	):
		return

	controller.set_process(false)
	spawner.set_process(false)
	player.set_physics_process(false)
	weapon.set_process(false)
	effects.set_process(false)
	var ability := player.get_ability_controller()
	if ability != null:
		ability.set_process(false)

	catalog.definitions = [SUMMER_GRILL, ANXIETY, SWIFT_STEPS, RAPID_FIRE, WIDE_MAGNET, MEAT_FORK_DAMAGE]
	assert_true(catalog.rebuild_registry(), "La fixture B18J deve avere un catalogo valido.")
	service.reset_for_run(controller.get_seed())
	assert_true(effects.recalculate_effects(), "Il registry deve accettare Grigliata estiva.")
	assert_true(effects.has_valid_configuration(), "La configurazione B18J deve essere completa.")
	effects.effect_applied.connect(_on_effect_applied)
	_assert_definition(effects)

	var health := player.get_health_component()
	var base_health_max := player.get_base_health_max()
	assert_not_null(health, "Il Player B18J deve avere salute.")
	if health == null:
		controller.prepare_restart()
		return

	assert_true(player.take_contact_damage(40.0), "La fixture deve poter ferire il Player.")
	assert_almost_eq(
		health.health_current, base_health_max - 40.0, FLOAT_TOLERANCE, "Il danno iniziale deve essere applicato."
	)

	for rank in range(1, 6):
		var previous_max := health.health_max
		var previous_current := health.health_current
		assert_true(
			_grant_and_select(experience, service, SUMMER_GRILL.id),
			"Grigliata estiva deve essere selezionabile al rank %d." % rank
		)
		var contribution := minf(pow(RANK_MULTIPLIER, rank), CONTRIBUTION_CAP)
		var expected_max := base_health_max * contribution
		var gained_max := maxf(expected_max - previous_max, 0.0)
		assert_eq(service.get_rank(SUMMER_GRILL.id), rank, "Il rank B18J deve avanzare una sola volta.")
		assert_almost_eq(
			health.health_max, expected_max, FLOAT_TOLERANCE,
			"Il massimo deve usare il contributo dati del rank %d." % rank
		)
		assert_almost_eq(
			health.health_current, previous_current + gained_max, FLOAT_TOLERANCE,
			"Il rank %d deve curare esattamente il delta del massimo." % rank
		)
		assert_almost_eq(
			effects.get_effective_multiplier(UpgradeEffectRegistry.PLAYER_HEALTH_MAX_MULTIPLIER),
			contribution, FLOAT_TOLERANCE,
			"Il moltiplicatore effettivo deve corrispondere al rank %d." % rank
		)

	assert_eq(_applied_ranks, [1, 2, 3, 4, 5], "Ogni rank deve emettere un solo effetto atomico.")
	var capped_health_max := health.health_max
	var capped_health_current := health.health_current
	assert_true(controller.request_manual_pause(), "La run deve poter entrare in pausa.")
	effects._process(10.0)
	assert_almost_eq(
		health.health_max, capped_health_max, FLOAT_TOLERANCE, "La pausa non deve riapplicare il massimo."
	)
	assert_almost_eq(
		health.health_current, capped_health_current, FLOAT_TOLERANCE, "La pausa non deve riapplicare la cura."
	)
	assert_true(controller.resume_run(), "La run deve poter riprendere.")
	assert_true(
		experience.add_experience(experience.experience_required),
		"Il cap deve poter generare una nuova offerta."
	)
	assert_true(
		SUMMER_GRILL.id not in service.get_current_offer_ids(), "La carta deve sparire al rank 5."
	)
	assert_false(service.select_upgrade(SUMMER_GRILL.id), "Un sesto rank deve essere rifiutato.")
	var cap_offer := service.get_current_offer_ids()
	if not cap_offer.is_empty():
		assert_true(
			service.select_upgrade(cap_offer[0]), "La fixture deve chiudere l'offerta dopo il test del cap."
		)

	assert_true(controller.request_defeat(), "La prima run deve poter terminare.")
	assert_true(movement_slice.restart_run(18019), "B18J deve supportare una seconda run.")
	await wait_process_frames(2)
	assert_true(service.get_ranks().is_empty(), "Il restart deve azzerare tutti i rank B18J.")
	assert_almost_eq(
		player.get_health_max_multiplier(), 1.0, FLOAT_TOLERANCE, "Il restart deve azzerare il moltiplicatore B18J."
	)
	assert_almost_eq(
		health.health_max, base_health_max, FLOAT_TOLERANCE, "Il restart deve ripristinare il massimo base."
	)
	assert_almost_eq(
		health.health_current, base_health_max, FLOAT_TOLERANCE, "Il restart deve ripristinare la vita base."
	)

	assert_true(
		player.take_contact_damage(base_health_max * 0.5), "La seconda run deve poter testare la composizione."
	)
	assert_true(
		_grant_and_select(experience, service, ANXIETY.id), "L'Ansia deve essere selezionabile prima di Grigliata."
	)
	assert_almost_eq(
		health.health_max, base_health_max * 0.8, FLOAT_TOLERANCE, "L'Ansia deve applicare il proprio massimo."
	)
	assert_almost_eq(
		health.health_current, base_health_max * 0.4, FLOAT_TOLERANCE, "L'Ansia deve conservare la percentuale."
	)
	var before_grill_max := health.health_max
	var before_grill_current := health.health_current
	assert_true(
		_grant_and_select(experience, service, SUMMER_GRILL.id), "Grigliata deve comporsi con L'Ansia."
	)
	var composed_max := base_health_max * 0.8 * RANK_MULTIPLIER
	assert_almost_eq(
		health.health_max, composed_max, FLOAT_TOLERANCE, "I contributi salute devono comporsi moltiplicativamente."
	)
	assert_almost_eq(
		health.health_current, before_grill_current + composed_max - before_grill_max, FLOAT_TOLERANCE,
		"La composizione deve curare soltanto il delta prodotto da Grigliata."
	)

	assert_true(controller.request_defeat(), "La seconda run deve poter terminare.")
	assert_true(movement_slice.restart_run(18020), "B18J deve supportare una terza run.")
	await wait_process_frames(2)
	assert_true(
		player.take_contact_damage(health.health_current), "La fixture deve poter uccidere il Player."
	)
	assert_false(health.is_alive(), "Il Player deve essere morto prima della prova anti-resurrezione.")
	service._ranks[SUMMER_GRILL.id] = 1
	effects._on_upgrade_selected(SUMMER_GRILL, 1, 1)
	assert_almost_eq(
		health.health_max, base_health_max * RANK_MULTIPLIER, FLOAT_TOLERANCE,
		"Il ricalcolo dati deve restare valido da morto."
	)
	assert_almost_eq(
		health.health_current, 0.0, FLOAT_TOLERANCE, "Grigliata non deve resuscitare un Player morto."
	)
	assert_false(health.is_alive(), "Lo stato morto deve restare autorevole.")

	controller.prepare_restart()


func _assert_definition(effects: UpgradeEffectRegistry) -> void:
	assert_eq(SUMMER_GRILL.id, &"summer_grill", "L'ID dati B18J deve restare stabile.")
	assert_eq(SUMMER_GRILL.title, "Grigliata estiva", "Il titolo pubblico deve essere esatto.")
	assert_true(
		SUMMER_GRILL.max_rank == 5 and not SUMMER_GRILL.repeatable, "Grigliata deve avere cinque rank finiti."
	)
	assert_almost_eq(
		float(SUMMER_GRILL.effect_parameters.get("multiplier", 0.0)), RANK_MULTIPLIER, FLOAT_TOLERANCE,
		"Il moltiplicatore dati deve essere x1,15."
	)
	assert_almost_eq(
		float(SUMMER_GRILL.effect_parameters.get("cap", 0.0)), CONTRIBUTION_CAP, FLOAT_TOLERANCE,
		"Il cap dati deve essere x2,05."
	)
	assert_true(effects.can_apply(SUMMER_GRILL), "Il registry deve accettare la definizione autorevole.")
	var invalid_cap := (SUMMER_GRILL as UpgradeDefinition).duplicate(true) as UpgradeDefinition
	invalid_cap.id = &"summer_grill_invalid_cap"
	invalid_cap.effect_parameters = {"multiplier": RANK_MULTIPLIER, "cap": 1.0}
	assert_false(effects.can_apply(invalid_cap), "Un cap inferiore al singolo rank deve essere rifiutato.")


func _grant_and_select(
	experience: ExperienceSystem, service: UpgradeService, upgrade_id: StringName
) -> bool:
	for _attempt in 20:
		if not experience.add_experience(experience.experience_required):
			return false
		var offered_ids := service.get_current_offer_ids()
		if offered_ids.is_empty():
			return false
		var selected_id := upgrade_id
		if selected_id not in offered_ids:
			for offered_id in offered_ids:
				if offered_id in [SWIFT_STEPS.id, RAPID_FIRE.id, WIDE_MAGNET.id, MEAT_FORK_DAMAGE.id]:
					selected_id = offered_id
					break
		if selected_id not in offered_ids or not service.select_upgrade(selected_id):
			return false
		if selected_id == upgrade_id:
			return true
	return false


func _on_effect_applied(
	definition: UpgradeDefinition, new_rank: int, _effective_multipliers: Dictionary
) -> void:
	if definition.id == SUMMER_GRILL.id:
		_applied_ranks.append(new_rank)
