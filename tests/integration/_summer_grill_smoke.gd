extends SceneTree

const MOVEMENT_SLICE_SCENE := preload("res://scenes/game/movement_slice.tscn")
const SUMMER_GRILL := preload("res://data/upgrades/summer_grill.tres")
const ANXIETY := preload("res://data/upgrades/anxiety_signature.tres")
const FALLBACK_POWER := preload("res://data/upgrades/fallback_power.tres")
const FALLBACK_HASTE := preload("res://data/upgrades/fallback_haste.tres")
const FALLBACK_REACH := preload("res://data/upgrades/fallback_reach.tres")

const INITIAL_VIEWPORT_SIZE := Vector2i(1280, 720)
const FLOAT_TOLERANCE := 0.001
const RANK_MULTIPLIER := 1.15
const CONTRIBUTION_CAP := 2.05

var _failures: Array[String] = []
var _applied_ranks: Array[int] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	paused = false
	root.content_scale_size = INITIAL_VIEWPORT_SIZE
	root.size = INITIAL_VIEWPORT_SIZE
	await _wait_processed_frame()
	await _validate_summer_grill_contract()
	await _finish()


func _validate_summer_grill_contract() -> void:
	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	root.add_child(movement_slice)
	await _wait_processed_frame()

	var controller := movement_slice.get_run_controller() as RunController
	var experience := movement_slice.get_experience_system() as ExperienceSystem
	var service := movement_slice.get_upgrade_service() as UpgradeService
	var catalog := movement_slice.get_upgrade_registry() as UpgradeRegistry
	var effects := movement_slice.get_upgrade_effect_registry() as UpgradeEffectRegistry
	var player := movement_slice.get_player() as Player
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	var weapon := movement_slice.get_weapon_controller() as WeaponController

	_expect(controller != null and experience != null, "B18J deve conservare run e progressione.")
	_expect(service != null and catalog != null and effects != null, "B18J richiede i tre servizi upgrade.")
	_expect(player != null and spawner != null and weapon != null, "B18J richiede la scena gameplay composta.")
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
		movement_slice.queue_free()
		await process_frame
		return

	controller.set_process(false)
	spawner.set_process(false)
	player.set_physics_process(false)
	weapon.set_process(false)
	effects.set_process(false)
	var ability := player.get_ability_controller()
	if ability != null:
		ability.set_process(false)

	catalog.definitions = [
		SUMMER_GRILL,
		ANXIETY,
		FALLBACK_POWER,
		FALLBACK_HASTE,
		FALLBACK_REACH,
	]
	_expect(catalog.rebuild_registry(), "La fixture B18J deve avere un catalogo valido.")
	service.reset_for_run(controller.get_seed())
	_expect(effects.recalculate_effects(), "Il registry deve accettare Grigliata estiva.")
	_expect(effects.has_valid_configuration(), "La configurazione B18J deve essere completa.")
	effects.effect_applied.connect(_on_effect_applied)
	_validate_definition(effects)

	var health := player.get_health_component()
	var base_health_max := player.get_base_health_max()
	_expect(health != null, "Il Player B18J deve avere salute.")
	if health == null:
		controller.prepare_restart()
		movement_slice.queue_free()
		await process_frame
		return

	_expect(player.take_contact_damage(40.0), "La fixture deve poter ferire il Player.")
	_expect_float_near(health.health_current, base_health_max - 40.0, "Il danno iniziale deve essere applicato.")

	for rank in range(1, 6):
		var previous_max := health.health_max
		var previous_current := health.health_current
		_expect(
			_grant_and_select(experience, service, SUMMER_GRILL.id),
			"Grigliata estiva deve essere selezionabile al rank %d." % rank
		)
		var contribution := minf(pow(RANK_MULTIPLIER, rank), CONTRIBUTION_CAP)
		var expected_max := base_health_max * contribution
		var gained_max := maxf(expected_max - previous_max, 0.0)
		_expect(service.get_rank(SUMMER_GRILL.id) == rank, "Il rank B18J deve avanzare una sola volta.")
		_expect_float_near(health.health_max, expected_max, "Il massimo deve usare il contributo dati del rank %d." % rank)
		_expect_float_near(
			health.health_current,
			previous_current + gained_max,
			"Il rank %d deve curare esattamente il delta del massimo." % rank
		)
		_expect_float_near(
			effects.get_effective_multiplier(UpgradeEffectRegistry.PLAYER_HEALTH_MAX_MULTIPLIER),
			contribution,
			"Il moltiplicatore effettivo deve corrispondere al rank %d." % rank
		)

	_expect(_applied_ranks == [1, 2, 3, 4, 5], "Ogni rank deve emettere un solo effetto atomico.")
	var capped_health_max := health.health_max
	var capped_health_current := health.health_current
	_expect(controller.request_manual_pause(), "La run deve poter entrare in pausa.")
	effects._process(10.0)
	_expect_float_near(health.health_max, capped_health_max, "La pausa non deve riapplicare il massimo.")
	_expect_float_near(health.health_current, capped_health_current, "La pausa non deve riapplicare la cura.")
	_expect(controller.resume_run(), "La run deve poter riprendere.")
	_expect(experience.add_experience(experience.experience_required), "Il cap deve poter generare una nuova offerta.")
	_expect(SUMMER_GRILL.id not in service.get_current_offer_ids(), "La carta deve sparire al rank 5.")
	_expect(not service.select_upgrade(SUMMER_GRILL.id), "Un sesto rank deve essere rifiutato.")
	var cap_offer := service.get_current_offer_ids()
	if not cap_offer.is_empty():
		_expect(service.select_upgrade(cap_offer[0]), "La fixture deve chiudere l'offerta dopo il test del cap.")

	_expect(controller.request_defeat(), "La prima run deve poter terminare.")
	_expect(movement_slice.restart_run(18019), "B18J deve supportare una seconda run.")
	await _wait_processed_frame()
	_expect(service.get_ranks().is_empty(), "Il restart deve azzerare tutti i rank B18J.")
	_expect_float_near(player.get_health_max_multiplier(), 1.0, "Il restart deve azzerare il moltiplicatore B18J.")
	_expect_float_near(health.health_max, base_health_max, "Il restart deve ripristinare il massimo base.")
	_expect_float_near(health.health_current, base_health_max, "Il restart deve ripristinare la vita base.")

	_expect(player.take_contact_damage(base_health_max * 0.5), "La seconda run deve poter testare la composizione.")
	_expect(_grant_and_select(experience, service, ANXIETY.id), "L'Ansia deve essere selezionabile prima di Grigliata.")
	_expect_float_near(health.health_max, base_health_max * 0.8, "L'Ansia deve applicare il proprio massimo.")
	_expect_float_near(health.health_current, base_health_max * 0.4, "L'Ansia deve conservare la percentuale.")
	var before_grill_max := health.health_max
	var before_grill_current := health.health_current
	_expect(_grant_and_select(experience, service, SUMMER_GRILL.id), "Grigliata deve comporsi con L'Ansia.")
	var composed_max := base_health_max * 0.8 * RANK_MULTIPLIER
	_expect_float_near(health.health_max, composed_max, "I contributi salute devono comporsi moltiplicativamente.")
	_expect_float_near(
		health.health_current,
		before_grill_current + composed_max - before_grill_max,
		"La composizione deve curare soltanto il delta prodotto da Grigliata."
	)

	_expect(controller.request_defeat(), "La seconda run deve poter terminare.")
	_expect(movement_slice.restart_run(18020), "B18J deve supportare una terza run.")
	await _wait_processed_frame()
	_expect(player.take_contact_damage(health.health_current), "La fixture deve poter uccidere il Player.")
	_expect(not health.is_alive(), "Il Player deve essere morto prima della prova anti-resurrezione.")
	service._ranks[SUMMER_GRILL.id] = 1
	effects._on_upgrade_selected(SUMMER_GRILL, 1, 1)
	_expect_float_near(health.health_max, base_health_max * RANK_MULTIPLIER, "Il ricalcolo dati deve restare valido da morto.")
	_expect_float_near(health.health_current, 0.0, "Grigliata non deve resuscitare un Player morto.")
	_expect(not health.is_alive(), "Lo stato morto deve restare autorevole.")

	controller.prepare_restart()
	paused = false
	movement_slice.queue_free()
	await process_frame


func _validate_definition(effects: UpgradeEffectRegistry) -> void:
	_expect(SUMMER_GRILL.id == &"summer_grill", "L'ID dati B18J deve restare stabile.")
	_expect(SUMMER_GRILL.title == "Grigliata estiva", "Il titolo pubblico deve essere esatto.")
	_expect(SUMMER_GRILL.max_rank == 5 and not SUMMER_GRILL.repeatable, "Grigliata deve avere cinque rank finiti.")
	_expect_float_near(float(SUMMER_GRILL.effect_parameters.get("multiplier", 0.0)), RANK_MULTIPLIER, "Il moltiplicatore dati deve essere x1,15.")
	_expect_float_near(float(SUMMER_GRILL.effect_parameters.get("cap", 0.0)), CONTRIBUTION_CAP, "Il cap dati deve essere x2,05.")
	_expect(effects.can_apply(SUMMER_GRILL), "Il registry deve accettare la definizione autorevole.")
	var invalid_cap := (SUMMER_GRILL as UpgradeDefinition).duplicate(true) as UpgradeDefinition
	invalid_cap.id = &"summer_grill_invalid_cap"
	invalid_cap.effect_parameters = {"multiplier": RANK_MULTIPLIER, "cap": 1.0}
	_expect(not effects.can_apply(invalid_cap), "Un cap inferiore al singolo rank deve essere rifiutato.")


func _grant_and_select(
	experience: ExperienceSystem,
	service: UpgradeService,
	upgrade_id: StringName
) -> bool:
	if not experience.add_experience(experience.experience_required):
		return false
	if upgrade_id not in service.get_current_offer_ids():
		return false
	return service.select_upgrade(upgrade_id)


func _on_effect_applied(
	definition: UpgradeDefinition,
	new_rank: int,
	_effective_multipliers: Dictionary
) -> void:
	if definition.id == SUMMER_GRILL.id:
		_applied_ranks.append(new_rank)


func _expect_float_near(actual: float, expected: float, message: String) -> void:
	_expect(
		absf(actual - expected) <= FLOAT_TOLERANCE,
		"%s Atteso %.6f, ottenuto %.6f." % [message, expected, actual]
	)


func _wait_processed_frame() -> void:
	await process_frame
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	paused = false
	await process_frame
	if _failures.is_empty():
		print("B18J_SUMMER_GRILL_SMOKE_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	printerr("B18J_SUMMER_GRILL_SMOKE_FAIL count=%d" % _failures.size())
	quit(1)
