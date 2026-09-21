extends GutGameplayTest

## PS-160 — "Dai che si fredda!" (movimento) e "Via dalla Griglia!" (proiettili)
## restavano a rango zero nel playtest esterno: +10%/rank non creava un costo
## percepibile rispetto a danno/cadenza/perforazione. Questo file verifica solo
## le parti oggettivamente misurabili del contratto: il valore dichiarato nei
## dati, l'assenza di danno nascosto, e che l'aumento di velocita' proiettile si
## traduca in un aumento misurabile della distanza percorsa a lifetime invariata
## (arma condivisa da tutto il roster, non una variante per personaggio). Il
## resto del contratto (situazione ricorrente osservata in run, scelta
## volontaria in un mini-playtest a scelta forzata) richiede un playtest reale
## e resta esplicitamente fuori da questo smoke: vedi Gate manuali della card.

const SWIFT_STEPS := preload("res://data/upgrades/swift_steps.tres")
const PROJECTILE_SPEED := preload("res://data/upgrades/projectile_speed.tres")
const RAPID_FIRE := preload("res://data/upgrades/rapid_fire.tres")
const WIDE_MAGNET := preload("res://data/upgrades/wide_magnet.tres")
const RANK_GUARD_LIMIT := 40


func test_declared_values_match_effect_summary() -> void:
	assert_almost_eq(
		float(SWIFT_STEPS.effect_parameters.get("multiplier", 0.0)), 1.15, FLOAT_TOLERANCE,
		"PS-160: Dai che si fredda! deve dichiarare +15%/rank, non piu' il +10% pre-playtest."
	)
	assert_eq(
		SWIFT_STEPS.effect_summary, "+15% VELOCITÀ MOVIMENTO",
		"La descrizione a schermo deve restare coerente col nuovo valore runtime."
	)
	assert_almost_eq(
		float(PROJECTILE_SPEED.effect_parameters.get("multiplier", 0.0)), 1.2, FLOAT_TOLERANCE,
		"PS-160: Via dalla Griglia! deve dichiarare +20%/rank, non piu' il +10% pre-playtest."
	)
	assert_eq(
		PROJECTILE_SPEED.effect_summary, "+20% VELOCITÀ PROIETTILI",
		"La descrizione a schermo deve restare coerente col nuovo valore runtime."
	)


func test_swift_steps_single_pick_moves_player_without_hidden_damage() -> void:
	var context := await _build_context()
	if context.is_empty():
		return
	var catalog: UpgradeRegistry = context["catalog"]
	var service: UpgradeService = context["service"]
	var effects: UpgradeEffectRegistry = context["effects"]
	var experience: ExperienceSystem = context["experience"]
	var player: Player = context["player"]
	var weapon: WeaponController = context["weapon"]
	var controller: RunController = context["controller"]

	var base_move_speed := player.get_base_move_speed()
	var base_damage := weapon.get_effective_damage()

	assert_true(
		await _select_single_pick(catalog, service, effects, experience, SWIFT_STEPS),
		"Dai che si fredda! deve essere selezionabile dalla prima offerta."
	)
	assert_almost_eq(
		player.move_speed, base_move_speed * 1.15, FLOAT_TOLERANCE,
		"PS-160: un solo rango deve applicare per intero il nuovo +15%."
	)
	assert_almost_eq(
		weapon.get_effective_damage(), base_damage, FLOAT_TOLERANCE,
		"PS-160: la velocita' di movimento non deve introdurre danno nascosto."
	)

	controller.prepare_restart()


func test_projectile_speed_single_pick_increases_measurable_travel_distance() -> void:
	var context := await _build_context()
	if context.is_empty():
		return
	var catalog: UpgradeRegistry = context["catalog"]
	var service: UpgradeService = context["service"]
	var effects: UpgradeEffectRegistry = context["effects"]
	var experience: ExperienceSystem = context["experience"]
	var weapon: WeaponController = context["weapon"]
	var controller: RunController = context["controller"]

	var base_speed := weapon.weapon_profile.projectile_speed
	var base_lifetime := weapon.weapon_profile.projectile_lifetime
	var base_range := base_speed * base_lifetime

	assert_true(
		await _select_single_pick(catalog, service, effects, experience, PROJECTILE_SPEED),
		"Via dalla Griglia! deve essere selezionabile dalla prima offerta."
	)
	assert_almost_eq(
		weapon.get_effective_projectile_speed(), base_speed * 1.2, FLOAT_TOLERANCE,
		"PS-160: un solo rango deve applicare per intero il nuovo +20%."
	)
	assert_almost_eq(
		weapon.weapon_profile.projectile_lifetime, base_lifetime, FLOAT_TOLERANCE,
		"La lifetime del proiettile deve restare invariata: solo la velocita' cambia."
	)

	var new_range := weapon.get_effective_projectile_speed() * weapon.weapon_profile.projectile_lifetime
	assert_true(
		new_range >= base_range * 1.15,
		(
			"PS-160: la distanza percorsa entro la lifetime invariata deve crescere in modo misurabile (base %.1f, nuova %.1f)."
			% [base_range, new_range]
		)
	)
	assert_almost_eq(
		weapon.get_effective_damage(), weapon.get_base_damage(), FLOAT_TOLERANCE,
		"PS-160: la velocita' del proiettile non deve introdurre danno nascosto."
	)
	# PS-198: dopo le armi per personaggio l'ancora non e' piu' l'arma
	# condivisa del roster ma quella che il personaggio sotto misura
	# dichiara. Il controllo resta lo stesso nella sostanza: la misura non
	# deve avvenire su un'arma finita li' per sbaglio.
	var measured_friend := (context["player"] as Player).get_friend_definition()
	assert_eq(
		weapon.get_weapon_definition().id, measured_friend.weapon_id,
		"La misura deve avvenire sull'arma dichiarata dal personaggio equipaggiato."
	)

	controller.prepare_restart()


## A rango massimo (5) Dai che si fredda! ora supera il cap dichiarato
## (pow(1.15, 5) ~= 2.011 contro max_move_speed_multiplier = 2.0): il nuovo
## valore per-rango non deve rompere il tetto esistente, deve solo saturarlo.
func test_swift_steps_max_rank_saturates_existing_cap() -> void:
	var context := await _build_context()
	if context.is_empty():
		return
	var catalog: UpgradeRegistry = context["catalog"]
	var service: UpgradeService = context["service"]
	var effects: UpgradeEffectRegistry = context["effects"]
	var experience: ExperienceSystem = context["experience"]
	var player: Player = context["player"]
	var controller: RunController = context["controller"]

	catalog.definitions = [SWIFT_STEPS, RAPID_FIRE, WIDE_MAGNET]
	assert_true(catalog.rebuild_registry(), "Il catalogo ristretto deve restare valido.")
	service.reset_for_run(4321)
	assert_true(effects.recalculate_effects(), "Il registry deve accettare il catalogo ristretto.")

	var base_move_speed := player.get_base_move_speed()
	var rank_guard := 0
	while service.get_rank(&"swift_steps") < 5 and rank_guard < RANK_GUARD_LIMIT:
		assert_true(
			await _grant_one_level(experience, service, &"swift_steps"),
			"Dai che si fredda! deve restare selezionabile fino al rango massimo."
		)
		rank_guard += 1
	assert_true(rank_guard < RANK_GUARD_LIMIT, "Il rango massimo deve arrivare entro il guard.")

	assert_almost_eq(
		player.move_speed, base_move_speed * effects.max_move_speed_multiplier, FLOAT_TOLERANCE,
		"PS-160: a rango 5 il nuovo +15%%/rank deve saturare il cap esistente (%.2fx), non superarlo."
		% effects.max_move_speed_multiplier
	)

	controller.prepare_restart()
	print("PS160_SPEED_UPGRADE_VALUE_SMOKE_OK")


func _build_context() -> Dictionary:
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_run_controller() as RunController
	var experience := movement_slice.get_experience_system() as ExperienceSystem
	var catalog := movement_slice.get_upgrade_registry() as UpgradeRegistry
	var service := movement_slice.get_upgrade_service() as UpgradeService
	var effects := movement_slice.get_upgrade_effect_registry() as UpgradeEffectRegistry
	var player := movement_slice.get_node_or_null("World/Player") as Player
	var weapon := movement_slice.get_weapon_controller() as WeaponController
	if (
		controller == null
		or experience == null
		or catalog == null
		or service == null
		or effects == null
		or player == null
		or weapon == null
	):
		assert_true(false, "PS-160 richiede tutti i servizi runtime di progressione/arma.")
		return {}

	controller.set_process(false)
	player.set_physics_process(false)
	weapon.set_process(false)
	# Soglia altissima: le add_experience() di supporto non devono far scattare
	# un secondo level-up a meta' asserzione (stesso accorgimento di
	# test_powerup_first_wave.gd/test_ps093_extended_base_stats.gd).
	var curve := ExperienceCurve.new()
	curve.base_experience_required = 999999
	curve.experience_growth_per_level = 0
	experience.experience_curve = curve

	return {
		"controller": controller,
		"experience": experience,
		"catalog": catalog,
		"service": service,
		"effects": effects,
		"player": player,
		"weapon": weapon,
	}


## Cataloga esattamente la carta bersaglio piu' due riempitivi: con
## offer_size = 3 e tre sole definizioni idonee l'offerta le include sempre
## tutte, quindi il bersaglio compare con certezza alla prima offerta.
func _select_single_pick(
	catalog: UpgradeRegistry,
	service: UpgradeService,
	effects: UpgradeEffectRegistry,
	experience: ExperienceSystem,
	target: UpgradeDefinition
) -> bool:
	catalog.definitions = [target, RAPID_FIRE, WIDE_MAGNET]
	if not catalog.rebuild_registry():
		return false
	service.reset_for_run(4242)
	if not effects.recalculate_effects():
		return false
	return await _grant_one_level(experience, service, target.id)


func _grant_one_level(experience: ExperienceSystem, service: UpgradeService, upgrade_id: StringName) -> bool:
	if not experience.add_experience(experience.experience_required):
		return false
	if upgrade_id not in service.get_current_offer_ids():
		return false
	return service.select_upgrade(upgrade_id)
