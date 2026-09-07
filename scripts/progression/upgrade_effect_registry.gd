class_name UpgradeEffectRegistry
extends Node

signal effects_recalculated(effective_multipliers: Dictionary)
signal effect_applied(
	definition: UpgradeDefinition,
	new_rank: int,
	effective_multipliers: Dictionary
)
signal effects_reset()
signal slow_pulse_started(duration: float, affected_count: int)
signal slow_pulse_ended()
signal damage_shockwave_emitted(affected_count: int)

const PLAYER_MOVE_SPEED_MULTIPLIER := &"player_move_speed_multiplier"
const PLAYER_PICKUP_RADIUS_MULTIPLIER := &"player_pickup_radius_multiplier"
const PLAYER_HEALTH_MAX_MULTIPLIER := &"player_health_max_multiplier"
const WEAPON_FIRE_RATE_MULTIPLIER := &"weapon_fire_rate_multiplier"
const WEAPON_DAMAGE_MULTIPLIER := &"weapon_damage_multiplier"
const WEAPON_PROJECTILE_SPEED_MULTIPLIER := &"weapon_projectile_speed_multiplier"
const PLAYER_DAMAGE_TAKEN_MULTIPLIER := &"player_damage_taken_multiplier"
const XP_VALUE_MULTIPLIER := &"xp_value_multiplier"
const ACTIVE_ABILITY_COOLDOWN_MULTIPLIER := &"active_ability_cooldown_multiplier"

const GOSSIP_PROJECTILES := &"gossip_projectiles"
const CHRONIC_DELAY := &"chronic_delay"
const BEER_SIGNATURE := &"beer_signature"
const DAMAGE_SHOCKWAVE := &"damage_shockwave"
const ABILITY_RANK := &"ability_rank"
const SUMMER_GRILL := &"summer_grill"
const CHRONIC_DELAY_MODIFIER := &"upgrade_chronic_delay"
const WEAPON_PIERCE := &"weapon_pierce"
const WEAPON_MULTISHOT := &"weapon_multishot"
const WEAPON_DEATH_BURST := &"weapon_death_burst"
## Salamoia Bolognese (PS-093): probabilità critica additiva per rango +
## moltiplicatore di danno fisso. Il cap totale (scarto base personaggio +
## carta) vive in `WeaponController.MAXIMUM_CRITICAL_CHANCE`, non qui: questo
## registry passa solo il contributo grezzo della carta.
const WEAPON_CRITICAL_STRIKE := &"weapon_critical_chance"
## PS-094: cariche multiple sull'abilità attiva, universale come Ravviva la
## Brace!. Sequenza fissa di 5 ranghi (array indicizzati per rango), non una
## formula lineare: max_charges/cooldown_multiplier vanno letti dal rango
## corrente, non moltiplicati per esso.
const ABILITY_CHARGE_STACKING := &"ability_charge_stacking"

const MINIMUM_MULTIPLIER := 0.001

@export_group("Multiplier Caps")
@export_range(1.0, 10.0, 0.05, "or_greater") var max_move_speed_multiplier := 2.0
@export_range(1.0, 10.0, 0.05, "or_greater") var max_pickup_radius_multiplier := 3.0
@export_range(1.0, 10.0, 0.05, "or_greater") var max_health_max_multiplier := 3.0
@export_range(0.01, 1.0, 0.01) var min_health_max_multiplier := 0.1
@export_range(1.0, 20.0, 0.05, "or_greater") var max_fire_rate_multiplier := 3.0
@export_range(1.0, 20.0, 0.05, "or_greater") var max_damage_multiplier := 5.0
@export_range(1.0, 20.0, 0.05, "or_greater") var max_projectile_speed_multiplier := 3.0
@export_range(0.01, 1.0, 0.01) var min_damage_taken_multiplier := 0.7
@export_range(1.0, 10.0, 0.05, "or_greater") var max_xp_value_multiplier := 2.0
@export_range(0.01, 1.0, 0.01) var min_active_ability_cooldown_multiplier := 0.65
@export_range(1, 20, 1, "or_greater") var max_weapon_pierce_count := 4
@export_range(1, 20, 1, "or_greater") var max_weapon_multishot_count := 3
@export_range(0.01, 1.0, 0.01) var max_weapon_death_burst_damage_multiplier := 0.6
@export_range(1, 20, 1, "or_greater") var max_gossip_chain_jumps := 6

var _upgrade_service: UpgradeService
var _upgrade_registry: UpgradeRegistry
var _player: Player
var _weapon_controller: WeaponController
var _run_controller: RunController
var _targeting_system: TargetingSystem
var _vignette_effect: VignetteEffect
var _effect_parent: Node2D
var _ability_controller: AbilityController
var _experience_system: ExperienceSystem
var _effective_multipliers: Dictionary = {}
var _signature_parameters: Dictionary = {}

var _slow_interval_seconds := 0.0
var _slow_interval_remaining := 0.0
var _slow_duration_remaining := 0.0
var _slow_factor := 1.0
var _active_shockwaves: Array[DamageShockwave] = []


func _ready() -> void:
	_reset_multiplier_cache()


func _process(delta: float) -> void:
	if (
		not has_signature_effect(CHRONIC_DELAY)
		or not is_instance_valid(_run_controller)
		or not _run_controller.is_running()
	):
		return
	var safe_delta := maxf(delta, 0.0) if is_finite(delta) else 0.0
	if safe_delta <= 0.0:
		return

	if _slow_duration_remaining > 0.0:
		_slow_duration_remaining = maxf(_slow_duration_remaining - safe_delta, 0.0)
		if _slow_duration_remaining <= 0.0:
			_clear_slow_from_targets()
			slow_pulse_ended.emit()

	_slow_interval_remaining -= safe_delta
	if _slow_interval_remaining <= 0.0:
		_slow_interval_remaining = _slow_interval_seconds
		_activate_slow_pulse()


func _exit_tree() -> void:
	_disconnect_dependencies()


func configure(
	upgrade_service: UpgradeService,
	upgrade_registry: UpgradeRegistry,
	player: Player,
	weapon_controller: WeaponController,
	vignette_effect: VignetteEffect = null,
	effect_parent: Node2D = null,
	ability_controller: AbilityController = null
) -> bool:
	_disconnect_dependencies()
	_upgrade_service = upgrade_service
	_upgrade_registry = upgrade_registry
	_player = player
	_weapon_controller = weapon_controller
	_run_controller = (
		_upgrade_service.get_run_controller()
		if is_instance_valid(_upgrade_service)
		else null
	)
	_targeting_system = (
		_weapon_controller.get_targeting_system()
		if is_instance_valid(_weapon_controller)
		else null
	)
	_vignette_effect = vignette_effect
	_effect_parent = effect_parent
	_ability_controller = ability_controller
	_experience_system = (
		_upgrade_service.get_experience_system()
		if is_instance_valid(_upgrade_service)
		else null
	)
	_connect_dependencies()
	if not has_valid_configuration():
		return false
	return recalculate_effects()


func has_valid_configuration() -> bool:
	if (
		not is_instance_valid(_upgrade_service)
		or not is_instance_valid(_upgrade_registry)
		or not _upgrade_registry.is_catalog_valid()
		or _upgrade_service.get_registry() != _upgrade_registry
		or not is_instance_valid(_player)
		or not is_instance_valid(_weapon_controller)
		or not is_instance_valid(_run_controller)
		or not is_instance_valid(_ability_controller)
		or not is_instance_valid(_experience_system)
		or _upgrade_service.get_run_controller() != _run_controller
		or _upgrade_service.get_experience_system() != _experience_system
		or not _has_valid_caps()
	):
		return false
	for definition in _upgrade_registry.get_definitions():
		if not can_apply(definition):
			return false
	return _has_required_signature_dependencies()


func can_apply(definition: UpgradeDefinition) -> bool:
	if definition == null or not definition.is_valid():
		return false
	match definition.effect_id:
		PLAYER_MOVE_SPEED_MULTIPLIER, \
		PLAYER_PICKUP_RADIUS_MULTIPLIER, \
		PLAYER_HEALTH_MAX_MULTIPLIER, \
		WEAPON_FIRE_RATE_MULTIPLIER, \
		WEAPON_DAMAGE_MULTIPLIER, \
		WEAPON_PROJECTILE_SPEED_MULTIPLIER, \
		PLAYER_DAMAGE_TAKEN_MULTIPLIER, \
		XP_VALUE_MULTIPLIER, \
		ACTIVE_ABILITY_COOLDOWN_MULTIPLIER:
			return _get_positive_number(definition.effect_parameters, "multiplier") > 0.0
		GOSSIP_PROJECTILES:
			return (
				definition.repeatable
				and _get_positive_integer(
					definition.effect_parameters,
					"chain_jumps_per_rank"
				) > 0
				and _get_positive_number(
					definition.effect_parameters,
					"chain_radius"
				) > 0.0
				and _get_unit_number(
					definition.effect_parameters,
					"damage_falloff"
				) > 0.0
			)
		WEAPON_PIERCE:
			return (
				definition.repeatable
				and _get_positive_integer(
					definition.effect_parameters,
					"pierce_count_per_rank"
				) > 0
				and _get_unit_number(
					definition.effect_parameters,
					"damage_falloff"
				) > 0.0
			)
		WEAPON_MULTISHOT:
			return (
				definition.repeatable
				and _get_positive_integer(
					definition.effect_parameters,
					"projectiles_per_rank"
				) > 0
				and _get_positive_number(
					definition.effect_parameters,
					"spread_degrees_per_projectile"
				) > 0.0
			)
		WEAPON_DEATH_BURST:
			return (
				definition.repeatable
				and _get_positive_number(definition.effect_parameters, "radius") > 0.0
				and _get_positive_number(
					definition.effect_parameters,
					"damage_multiplier_per_rank"
				) > 0.0
			)
		WEAPON_CRITICAL_STRIKE:
			return (
				definition.repeatable
				and _get_unit_number(
					definition.effect_parameters,
					"chance_bonus_per_rank"
				) > 0.0
				and _get_positive_number(
					definition.effect_parameters,
					"critical_damage_multiplier"
				) > 1.0
			)
		CHRONIC_DELAY:
			var slow_factor := _get_positive_number(
				definition.effect_parameters,
				"slow_factor"
			)
			return (
				_is_single_rank_signature(definition)
				and _get_positive_number(
					definition.effect_parameters,
					"interval_seconds"
				) > 0.0
				and _get_positive_number(
					definition.effect_parameters,
					"duration_seconds"
				) > 0.0
				and slow_factor > 0.0
				and slow_factor <= 1.0
			)
		BEER_SIGNATURE:
			return (
				_is_single_rank_signature(definition)
				and _get_positive_number(
					definition.effect_parameters,
					"fire_rate_multiplier"
				) > 0.0
				and _get_positive_number(
					definition.effect_parameters,
					"aim_spread_degrees"
				) > 0.0
				and _get_positive_number(
					definition.effect_parameters,
					"aim_spread_degrees"
				) < 90.0
			)
		DAMAGE_SHOCKWAVE:
			return (
				_is_single_rank_signature(definition)
				and _get_positive_number(definition.effect_parameters, "radius") > 0.0
				and _get_positive_number(
					definition.effect_parameters,
					"knockback_speed"
				) > 0.0
				and _get_positive_number(
					definition.effect_parameters,
					"knockback_duration"
				) > 0.0
				and _get_positive_number(
					definition.effect_parameters,
					"visual_duration"
				) > 0.0
			)
		ABILITY_RANK:
			if not definition.is_ability_rank_definition():
				return false
			var ability_id := StringName(str(definition.effect_parameters.get("ability_id", "")))
			var ability_registry := _ability_controller.get_effect_registry()
			var ability_definition := (
				ability_registry.resolve_definition(ability_id)
				if is_instance_valid(ability_registry)
				else null
			)
			return (
				ability_definition != null
				and ability_definition.is_valid()
				and ability_definition.rank_snapshots.size() == 5
			)
		SUMMER_GRILL:
			var multiplier := _get_positive_number(
				definition.effect_parameters,
				"multiplier"
			)
			var contribution_cap := _get_positive_number(
				definition.effect_parameters,
				"cap"
			)
			return (
				definition.max_rank == 5
				and definition.initial_rank == 0
				and not definition.repeatable
				and multiplier > 1.0
				and contribution_cap >= multiplier
			)
		ABILITY_CHARGE_STACKING:
			return (
				definition.max_rank == 5
				and definition.initial_rank == 0
				and not definition.repeatable
				and _is_valid_charge_stacking_table(definition.effect_parameters)
			)
		_:
			return false


## PS-120: vero se salire di un altro rango non cambierebbe l'effetto
## applicato in gioco (il contributo ha già raggiunto il tetto/pavimento
## runtime). Solo le carte `repeatable` possono restare nel pool oltre il
## proprio `max_rank` (`UpgradeDefinition.is_eligible()`), quindi solo per
## loro serve un secondo controllo qui: senza, una carta ripetibile continua
## a essere proposta all'infinito anche quando un rango in più non farebbe
## più nulla, sprecando la scelta del giocatore (segnalato dal proprietario
## su "Tagliata").
func is_rank_saturated(definition: UpgradeDefinition, current_rank: int) -> bool:
	if not definition.repeatable or current_rank < 1:
		return false
	var current_contribution: Variant = _resolve_capped_contribution(definition, current_rank)
	var next_contribution: Variant = _resolve_capped_contribution(definition, current_rank + 1)
	if current_contribution == null or next_contribution == null:
		return false
	return current_contribution == next_contribution


## Ogni effect_id qui sotto appartiene a una sola carta del catalogo (nessuna
## composizione fra più carte sullo stesso effetto): il contributo isolato
## della carta coincide quindi con l'effettivo già applicato in gioco, con
## l'eccezione del critico, che si somma allo scarto base del personaggio e
## va perciò letto dal `WeaponController` corrente. `null` significa "non
## calcolabile qui": `is_rank_saturated()` lo tratta come "non saturo", mai
## come "saturo per errore".
func _resolve_capped_contribution(definition: UpgradeDefinition, rank: int) -> Variant:
	match definition.effect_id:
		WEAPON_MULTISHOT:
			return mini(
				1 + _get_positive_integer(definition.effect_parameters, "projectiles_per_rank") * rank,
				max_weapon_multishot_count
			)
		WEAPON_PIERCE:
			return mini(
				1 + _get_positive_integer(definition.effect_parameters, "pierce_count_per_rank") * rank,
				max_weapon_pierce_count
			)
		WEAPON_DEATH_BURST:
			return minf(
				_get_positive_number(definition.effect_parameters, "damage_multiplier_per_rank") * float(rank),
				max_weapon_death_burst_damage_multiplier
			)
		GOSSIP_PROJECTILES:
			return mini(
				_get_positive_integer(definition.effect_parameters, "chain_jumps_per_rank") * rank,
				max_gossip_chain_jumps
			)
		WEAPON_CRITICAL_STRIKE:
			if not is_instance_valid(_weapon_controller):
				return null
			var character_bonus := _weapon_controller.get_character_critical_chance_bonus()
			var card_bonus := _get_unit_number(
				definition.effect_parameters, "chance_bonus_per_rank"
			) * float(rank)
			return clampf(character_bonus + card_bonus, 0.0, WeaponController.MAXIMUM_CRITICAL_CHANCE)
		_:
			# Ramo generico "moltiplicatore composto" (Ravviva la Brace! e le
			# carte statistiche ordinarie ripetibili): stessa formula di
			# recalculate_effects(), un solo contributore per effect_id.
			var multiplier := _get_positive_number(definition.effect_parameters, "multiplier")
			if multiplier <= 0.0:
				return null
			return clampf(
				pow(multiplier, rank), _get_minimum(definition.effect_id), _get_cap(definition.effect_id)
			)


func recalculate_effects(preserve_health_ratio: bool = true) -> bool:
	if not has_valid_configuration():
		return false

	var next_multipliers := _make_identity_multipliers()
	var next_signatures: Dictionary = {}
	var ranks := _upgrade_service.get_ranks()
	for upgrade_id_value: Variant in ranks:
		var upgrade_id := StringName(str(upgrade_id_value))
		var rank := maxi(int(ranks[upgrade_id_value]), 0)
		if rank == 0:
			continue
		var definition := _upgrade_registry.resolve_definition(upgrade_id)
		if not can_apply(definition):
			return false
		match definition.effect_id:
			ABILITY_RANK:
				continue
			SUMMER_GRILL:
				var contribution := minf(
					pow(
						_get_positive_number(
							definition.effect_parameters,
							"multiplier"
						),
						rank
					),
					_get_positive_number(definition.effect_parameters, "cap")
				)
				next_multipliers[PLAYER_HEALTH_MAX_MULTIPLIER] = (
					float(next_multipliers[PLAYER_HEALTH_MAX_MULTIPLIER])
					* contribution
				)
			BEER_SIGNATURE:
				_multiply_effect(
					next_multipliers,
					WEAPON_FIRE_RATE_MULTIPLIER,
					_get_positive_number(
						definition.effect_parameters,
						"fire_rate_multiplier"
					),
					rank
				)
				next_signatures[definition.effect_id] = (
					definition.effect_parameters.duplicate(true)
				)
			GOSSIP_PROJECTILES:
				var chain_jumps_per_rank := _get_positive_integer(
					definition.effect_parameters,
					"chain_jumps_per_rank"
				)
				next_signatures[definition.effect_id] = {
					"chain_jumps": mini(chain_jumps_per_rank * rank, max_gossip_chain_jumps),
					"chain_radius": _get_positive_number(
						definition.effect_parameters,
						"chain_radius"
					),
					"damage_falloff": _get_unit_number(
						definition.effect_parameters,
						"damage_falloff"
					),
				}
			CHRONIC_DELAY, DAMAGE_SHOCKWAVE:
				next_signatures[definition.effect_id] = (
					definition.effect_parameters.duplicate(true)
				)
			WEAPON_PIERCE:
				var pierce_count_per_rank := _get_positive_integer(
					definition.effect_parameters,
					"pierce_count_per_rank"
				)
				next_signatures[definition.effect_id] = {
					"pierce_count": mini(1 + pierce_count_per_rank * rank, max_weapon_pierce_count),
					"damage_falloff": _get_unit_number(
						definition.effect_parameters,
						"damage_falloff"
					),
				}
			WEAPON_MULTISHOT:
				var projectiles_per_rank := _get_positive_integer(
					definition.effect_parameters,
					"projectiles_per_rank"
				)
				var multishot_count := mini(
					1 + projectiles_per_rank * rank,
					max_weapon_multishot_count
				)
				next_signatures[definition.effect_id] = {
					"multishot_count": multishot_count,
					"spread_degrees": _get_positive_number(
						definition.effect_parameters,
						"spread_degrees_per_projectile"
					) * float(multishot_count - 1),
				}
			WEAPON_DEATH_BURST:
				var damage_multiplier_per_rank := _get_positive_number(
					definition.effect_parameters,
					"damage_multiplier_per_rank"
				)
				next_signatures[definition.effect_id] = {
					"radius": _get_positive_number(definition.effect_parameters, "radius"),
					"damage_multiplier": minf(
						damage_multiplier_per_rank * float(rank),
						max_weapon_death_burst_damage_multiplier
					),
				}
			WEAPON_CRITICAL_STRIKE:
				next_signatures[definition.effect_id] = {
					"chance_bonus": _get_unit_number(
						definition.effect_parameters,
						"chance_bonus_per_rank"
					) * float(rank),
					"damage_multiplier": _get_positive_number(
						definition.effect_parameters,
						"critical_damage_multiplier"
					),
				}
			ABILITY_CHARGE_STACKING:
				var charges_by_rank: Array = definition.effect_parameters["charges_by_rank"]
				var cooldown_multiplier_by_rank: Array = (
					definition.effect_parameters["cooldown_multiplier_by_rank"]
				)
				var rank_index := clampi(rank - 1, 0, charges_by_rank.size() - 1)
				next_signatures[definition.effect_id] = {
					"max_charges": int(charges_by_rank[rank_index]),
					"cooldown_multiplier": float(cooldown_multiplier_by_rank[rank_index]),
				}
			_:
				_multiply_effect(
					next_multipliers,
					definition.effect_id,
					_get_positive_number(
						definition.effect_parameters,
						"multiplier"
					),
					rank
				)

	for effect_id in _supported_stat_effect_ids():
		next_multipliers[effect_id] = clampf(
			float(next_multipliers[effect_id]),
			_get_minimum(effect_id),
			_get_cap(effect_id)
		)

	if not _apply_multipliers(next_multipliers, preserve_health_ratio):
		return false
	if not _apply_signature_effects(next_signatures):
		return false
	_effective_multipliers = next_multipliers
	effects_recalculated.emit(get_effective_multipliers())
	return true


func reset_effects() -> void:
	_clear_signature_runtime()
	_reset_multiplier_cache()
	if is_instance_valid(_player):
		_player.reset_upgrade_stat_multipliers()
	if is_instance_valid(_weapon_controller):
		_weapon_controller.reset_upgrade_stat_multipliers()
	if is_instance_valid(_experience_system):
		_experience_system.reset_upgrade_value_multiplier()
	if is_instance_valid(_ability_controller):
		_ability_controller.reset_upgrade_cooldown_multiplier()
		_ability_controller.reset_charge_configuration()
	effects_reset.emit()
	effects_recalculated.emit(get_effective_multipliers())


func get_effective_multiplier(effect_id: StringName) -> float:
	return float(_effective_multipliers.get(effect_id, 1.0))


func get_effective_multipliers() -> Dictionary:
	return _effective_multipliers.duplicate()


func has_signature_effect(effect_id: StringName) -> bool:
	return _signature_parameters.has(effect_id)


func get_signature_parameters(effect_id: StringName) -> Dictionary:
	var parameters: Variant = _signature_parameters.get(effect_id, {})
	return parameters.duplicate(true) if parameters is Dictionary else {}


func get_slow_interval_remaining() -> float:
	return _slow_interval_remaining


func get_slow_duration_remaining() -> float:
	return _slow_duration_remaining


func is_slow_pulse_active() -> bool:
	return _slow_duration_remaining > 0.0


func get_active_shockwave_count() -> int:
	_prune_shockwaves()
	return _active_shockwaves.size()


func get_upgrade_service() -> UpgradeService:
	return _upgrade_service if is_instance_valid(_upgrade_service) else null


func get_upgrade_registry() -> UpgradeRegistry:
	return _upgrade_registry if is_instance_valid(_upgrade_registry) else null


func get_player() -> Player:
	return _player if is_instance_valid(_player) else null


func get_weapon_controller() -> WeaponController:
	return _weapon_controller if is_instance_valid(_weapon_controller) else null


func get_run_controller() -> RunController:
	return _run_controller if is_instance_valid(_run_controller) else null


func get_experience_system() -> ExperienceSystem:
	return _experience_system if is_instance_valid(_experience_system) else null


func get_targeting_system() -> TargetingSystem:
	return _targeting_system if is_instance_valid(_targeting_system) else null


func get_vignette_effect() -> VignetteEffect:
	return _vignette_effect if is_instance_valid(_vignette_effect) else null


func get_effect_parent() -> Node2D:
	return _effect_parent if is_instance_valid(_effect_parent) else null


func _apply_multipliers(
	multipliers: Dictionary,
	preserve_health_ratio: bool = true
) -> bool:
	return (
		_player.set_upgrade_stat_multipliers(
			float(multipliers[PLAYER_MOVE_SPEED_MULTIPLIER]),
			float(multipliers[PLAYER_PICKUP_RADIUS_MULTIPLIER]),
			float(multipliers[PLAYER_HEALTH_MAX_MULTIPLIER]),
			preserve_health_ratio,
			float(multipliers[PLAYER_DAMAGE_TAKEN_MULTIPLIER])
		)
		and _weapon_controller.set_upgrade_stat_multipliers(
			float(multipliers[WEAPON_FIRE_RATE_MULTIPLIER]),
			float(multipliers[WEAPON_DAMAGE_MULTIPLIER]),
			float(multipliers[WEAPON_PROJECTILE_SPEED_MULTIPLIER])
		)
		and _experience_system.set_upgrade_value_multiplier(
			float(multipliers[XP_VALUE_MULTIPLIER])
		)
		and _ability_controller.set_upgrade_cooldown_multiplier(
			float(multipliers[ACTIVE_ABILITY_COOLDOWN_MULTIPLIER])
		)
	)


func _apply_signature_effects(next_signatures: Dictionary) -> bool:
	# PS-100: nessuna Specialità pilota più la vignetta da quando L'Ansia è
	# stata rimossa dal gioco. Il nodo resta cablato come infrastruttura
	# riusabile (vedi get_vignette_effect()), ma non ha più un contributo
	# dati da leggere: resta sempre a riposo qui.
	if is_instance_valid(_vignette_effect) and not _vignette_effect.set_intensity(0.0):
		return false

	var gossip_parameters := _parameters_from(
		next_signatures,
		GOSSIP_PROJECTILES
	)
	var beer_parameters := _parameters_from(next_signatures, BEER_SIGNATURE)
	var chain_enabled := false
	var chain_jumps := 0
	var chain_damage_falloff := 1.0
	var chain_radius := 0.0
	if not gossip_parameters.is_empty():
		chain_enabled = true
		chain_jumps = int(gossip_parameters["chain_jumps"])
		chain_damage_falloff = float(gossip_parameters["damage_falloff"])
		chain_radius = float(gossip_parameters["chain_radius"])
	var aim_spread_degrees := 0.0
	if not beer_parameters.is_empty():
		aim_spread_degrees = float(beer_parameters["aim_spread_degrees"])
	if not _weapon_controller.set_projectile_upgrade_modifiers(
		chain_enabled,
		chain_jumps,
		chain_damage_falloff,
		chain_radius,
		aim_spread_degrees
	):
		return false

	var pierce_parameters := _parameters_from(next_signatures, WEAPON_PIERCE)
	var multishot_parameters := _parameters_from(next_signatures, WEAPON_MULTISHOT)
	var death_burst_parameters := _parameters_from(next_signatures, WEAPON_DEATH_BURST)
	var pierce_count := 1
	var pierce_damage_falloff := 1.0
	if not pierce_parameters.is_empty():
		pierce_count = int(pierce_parameters["pierce_count"])
		pierce_damage_falloff = float(pierce_parameters["damage_falloff"])
	var multishot_count := 1
	var multishot_spread_degrees := 0.0
	if not multishot_parameters.is_empty():
		multishot_count = int(multishot_parameters["multishot_count"])
		multishot_spread_degrees = float(multishot_parameters["spread_degrees"])
	var death_burst_enabled := false
	var death_burst_radius := 0.0
	var death_burst_damage_multiplier := 0.0
	if not death_burst_parameters.is_empty():
		death_burst_enabled = true
		death_burst_radius = float(death_burst_parameters["radius"])
		death_burst_damage_multiplier = float(death_burst_parameters["damage_multiplier"])
	if not _weapon_controller.set_projectile_shape_modifiers(
		pierce_count,
		pierce_damage_falloff,
		multishot_count,
		multishot_spread_degrees,
		death_burst_enabled,
		death_burst_radius,
		death_burst_damage_multiplier
	):
		return false

	var critical_parameters := _parameters_from(next_signatures, WEAPON_CRITICAL_STRIKE)
	var critical_chance_bonus := 0.0
	var critical_damage_multiplier := 1.0
	if not critical_parameters.is_empty():
		critical_chance_bonus = float(critical_parameters["chance_bonus"])
		critical_damage_multiplier = float(critical_parameters["damage_multiplier"])
	if not _weapon_controller.set_critical_strike_modifiers(
		critical_chance_bonus,
		critical_damage_multiplier
	):
		return false

	_apply_chronic_delay_configuration(
		_parameters_from(next_signatures, CHRONIC_DELAY)
	)

	var charge_stacking_parameters := _parameters_from(next_signatures, ABILITY_CHARGE_STACKING)
	if charge_stacking_parameters.is_empty():
		_ability_controller.reset_charge_configuration()
	elif not _ability_controller.set_charge_configuration(
		int(charge_stacking_parameters["max_charges"]),
		float(charge_stacking_parameters["cooldown_multiplier"])
	):
		return false

	_signature_parameters = next_signatures.duplicate(true)
	return true


func _apply_chronic_delay_configuration(parameters: Dictionary) -> void:
	var was_enabled := has_signature_effect(CHRONIC_DELAY)
	if parameters.is_empty():
		_clear_slow_from_targets()
		_slow_interval_seconds = 0.0
		_slow_interval_remaining = 0.0
		_slow_duration_remaining = 0.0
		_slow_factor = 1.0
		return

	var next_interval := float(parameters["interval_seconds"])
	_slow_factor = float(parameters["slow_factor"])
	if not was_enabled:
		_slow_interval_remaining = next_interval
		_slow_duration_remaining = 0.0
	else:
		_slow_interval_remaining = minf(_slow_interval_remaining, next_interval)
	_slow_interval_seconds = next_interval


func _activate_slow_pulse() -> void:
	var parameters := get_signature_parameters(CHRONIC_DELAY)
	if parameters.is_empty():
		return
	_slow_duration_remaining = float(parameters["duration_seconds"])
	var affected_count := 0
	if is_instance_valid(_targeting_system):
		for enemy in _targeting_system.get_alive_targets():
			if enemy.set_speed_modifier(CHRONIC_DELAY_MODIFIER, _slow_factor):
				affected_count += 1
	slow_pulse_started.emit(_slow_duration_remaining, affected_count)


func _clear_slow_from_targets() -> void:
	if not is_instance_valid(_targeting_system):
		return
	for enemy in _targeting_system.get_alive_targets():
		enemy.remove_speed_modifier(CHRONIC_DELAY_MODIFIER)


func _create_damage_shockwave(parameters: Dictionary) -> void:
	if not is_instance_valid(_effect_parent) or not is_instance_valid(_player):
		return
	var pulse := DamageShockwave.new()
	_effect_parent.add_child(pulse)
	if not pulse.initialize(
		_player.global_position,
		float(parameters["radius"]),
		float(parameters["visual_duration"]),
		_run_controller
	):
		pulse.queue_free()
		return
	_active_shockwaves.append(pulse)
	pulse.finished.connect(_on_shockwave_finished, CONNECT_ONE_SHOT)


func _clear_signature_runtime() -> void:
	_clear_slow_from_targets()
	_slow_interval_seconds = 0.0
	_slow_interval_remaining = 0.0
	_slow_duration_remaining = 0.0
	_slow_factor = 1.0
	_signature_parameters.clear()
	if is_instance_valid(_vignette_effect):
		_vignette_effect.reset_effect()
	if is_instance_valid(_weapon_controller):
		_weapon_controller.reset_projectile_upgrade_modifiers()
		_weapon_controller.reset_projectile_shape_modifiers()
		_weapon_controller.reset_critical_strike_modifiers()
	for pulse in _active_shockwaves.duplicate():
		if is_instance_valid(pulse):
			pulse.finish()
	_active_shockwaves.clear()


func _multiply_effect(
	multipliers: Dictionary,
	effect_id: StringName,
	multiplier: float,
	rank: int
) -> void:
	multipliers[effect_id] = float(multipliers[effect_id]) * pow(multiplier, rank)


func _get_cap(effect_id: StringName) -> float:
	match effect_id:
		PLAYER_MOVE_SPEED_MULTIPLIER:
			return max_move_speed_multiplier
		PLAYER_PICKUP_RADIUS_MULTIPLIER:
			return max_pickup_radius_multiplier
		PLAYER_HEALTH_MAX_MULTIPLIER:
			return max_health_max_multiplier
		WEAPON_FIRE_RATE_MULTIPLIER:
			return max_fire_rate_multiplier
		WEAPON_DAMAGE_MULTIPLIER:
			return max_damage_multiplier
		WEAPON_PROJECTILE_SPEED_MULTIPLIER:
			return max_projectile_speed_multiplier
		PLAYER_DAMAGE_TAKEN_MULTIPLIER, ACTIVE_ABILITY_COOLDOWN_MULTIPLIER:
			return 1.0
		XP_VALUE_MULTIPLIER:
			return max_xp_value_multiplier
		_:
			return 1.0


func _get_minimum(effect_id: StringName) -> float:
	match effect_id:
		PLAYER_HEALTH_MAX_MULTIPLIER:
			return min_health_max_multiplier
		PLAYER_DAMAGE_TAKEN_MULTIPLIER:
			return min_damage_taken_multiplier
		ACTIVE_ABILITY_COOLDOWN_MULTIPLIER:
			return min_active_ability_cooldown_multiplier
		_:
			return MINIMUM_MULTIPLIER


func _has_valid_caps() -> bool:
	for cap in [
		max_move_speed_multiplier,
		max_pickup_radius_multiplier,
		max_health_max_multiplier,
		max_fire_rate_multiplier,
		max_damage_multiplier,
		max_projectile_speed_multiplier,
		max_xp_value_multiplier,
	]:
		if not is_finite(cap) or cap < 1.0:
			return false
	for count_cap in [max_weapon_pierce_count, max_weapon_multishot_count, max_gossip_chain_jumps]:
		if count_cap < 1:
			return false
	return (
		is_finite(min_health_max_multiplier)
		and min_health_max_multiplier > 0.0
		and min_health_max_multiplier <= 1.0
		and is_finite(min_damage_taken_multiplier)
		and min_damage_taken_multiplier > 0.0
		and min_damage_taken_multiplier <= 1.0
		and is_finite(min_active_ability_cooldown_multiplier)
		and min_active_ability_cooldown_multiplier > 0.0
		and min_active_ability_cooldown_multiplier <= 1.0
		and is_finite(max_weapon_death_burst_damage_multiplier)
		and max_weapon_death_burst_damage_multiplier > 0.0
		and max_weapon_death_burst_damage_multiplier <= 1.0
	)


func _supported_stat_effect_ids() -> Array[StringName]:
	return [
		PLAYER_MOVE_SPEED_MULTIPLIER,
		PLAYER_PICKUP_RADIUS_MULTIPLIER,
		PLAYER_HEALTH_MAX_MULTIPLIER,
		WEAPON_FIRE_RATE_MULTIPLIER,
		WEAPON_DAMAGE_MULTIPLIER,
		WEAPON_PROJECTILE_SPEED_MULTIPLIER,
		PLAYER_DAMAGE_TAKEN_MULTIPLIER,
		XP_VALUE_MULTIPLIER,
		ACTIVE_ABILITY_COOLDOWN_MULTIPLIER,
	]


func _make_identity_multipliers() -> Dictionary:
	var multipliers: Dictionary = {}
	for effect_id in _supported_stat_effect_ids():
		multipliers[effect_id] = 1.0
	return multipliers


func _reset_multiplier_cache() -> void:
	_effective_multipliers = _make_identity_multipliers()


func _has_required_signature_dependencies() -> bool:
	for definition in _upgrade_registry.get_definitions():
		match definition.effect_id:
			GOSSIP_PROJECTILES:
				if not is_instance_valid(_targeting_system):
					return false
			CHRONIC_DELAY:
				if not is_instance_valid(_targeting_system):
					return false
			DAMAGE_SHOCKWAVE:
				if (
					not is_instance_valid(_targeting_system)
					or not is_instance_valid(_effect_parent)
				):
					return false
	return true


func _is_single_rank_signature(definition: UpgradeDefinition) -> bool:
	return definition.max_rank == 1 and not definition.repeatable


## PS-094: la tabella a 5 ranghi deve avere cariche non decrescenti (il
## rango 4 abbassa solo la velocità di ricarica, mai il tetto di cariche) e
## un moltiplicatore finito e positivo per ognuno dei 5 ranghi.
func _is_valid_charge_stacking_table(parameters: Dictionary) -> bool:
	var charges_by_rank: Variant = parameters.get("charges_by_rank")
	var cooldown_multiplier_by_rank: Variant = parameters.get("cooldown_multiplier_by_rank")
	if not (charges_by_rank is Array) or not (cooldown_multiplier_by_rank is Array):
		return false
	if charges_by_rank.size() != 5 or cooldown_multiplier_by_rank.size() != 5:
		return false
	var previous_charges := 0
	for index in 5:
		var charges := int(charges_by_rank[index])
		var multiplier := float(cooldown_multiplier_by_rank[index])
		if charges < previous_charges or charges < 1 or not is_finite(multiplier) or multiplier <= 0.0:
			return false
		previous_charges = charges
	return true


func _get_positive_number(parameters: Dictionary, key: String) -> float:
	if not parameters.has(key):
		return -1.0
	var value: Variant = parameters[key]
	if typeof(value) not in [TYPE_INT, TYPE_FLOAT]:
		return -1.0
	var number := float(value)
	return number if is_finite(number) and number > 0.0 else -1.0


func _get_unit_number(parameters: Dictionary, key: String) -> float:
	if not parameters.has(key):
		return -1.0
	var value: Variant = parameters[key]
	if typeof(value) not in [TYPE_INT, TYPE_FLOAT]:
		return -1.0
	var number := float(value)
	return number if is_finite(number) and number >= 0.0 and number <= 1.0 else -1.0


func _get_positive_integer(parameters: Dictionary, key: String) -> int:
	if not parameters.has(key) or typeof(parameters[key]) != TYPE_INT:
		return -1
	return int(parameters[key]) if int(parameters[key]) > 0 else -1


func _parameters_from(source: Dictionary, effect_id: StringName) -> Dictionary:
	var parameters: Variant = source.get(effect_id, {})
	return parameters.duplicate(true) if parameters is Dictionary else {}


func _connect_dependencies() -> void:
	if is_instance_valid(_upgrade_service):
		if not _upgrade_service.upgrade_selected.is_connected(_on_upgrade_selected):
			_upgrade_service.upgrade_selected.connect(_on_upgrade_selected)
		if not _upgrade_service.ranks_reset.is_connected(_on_ranks_reset):
			_upgrade_service.ranks_reset.connect(_on_ranks_reset)
	if is_instance_valid(_player) and not _player.damaged.is_connected(_on_player_damaged):
		_player.damaged.connect(_on_player_damaged)
	if (
		is_instance_valid(_targeting_system)
		and not _targeting_system.target_registered.is_connected(_on_target_registered)
	):
		_targeting_system.target_registered.connect(_on_target_registered)


func _disconnect_dependencies() -> void:
	_clear_signature_runtime()
	if is_instance_valid(_upgrade_service):
		if _upgrade_service.upgrade_selected.is_connected(_on_upgrade_selected):
			_upgrade_service.upgrade_selected.disconnect(_on_upgrade_selected)
		if _upgrade_service.ranks_reset.is_connected(_on_ranks_reset):
			_upgrade_service.ranks_reset.disconnect(_on_ranks_reset)
	if is_instance_valid(_player) and _player.damaged.is_connected(_on_player_damaged):
		_player.damaged.disconnect(_on_player_damaged)
	if (
		is_instance_valid(_targeting_system)
		and _targeting_system.target_registered.is_connected(_on_target_registered)
	):
		_targeting_system.target_registered.disconnect(_on_target_registered)
	_upgrade_service = null
	_upgrade_registry = null
	_player = null
	_weapon_controller = null
	_run_controller = null
	_experience_system = null
	_targeting_system = null
	_vignette_effect = null
	_effect_parent = null
	_ability_controller = null


func _on_upgrade_selected(
	definition: UpgradeDefinition,
	new_rank: int,
	_level: int
) -> void:
	if definition.effect_id == ABILITY_RANK:
		var ability_id := StringName(str(definition.effect_parameters.get("ability_id", "")))
		if (
			ability_id != _upgrade_service.get_equipped_ability_id()
			or ability_id != _ability_controller.get_definition().id
			or not _ability_controller.apply_rank(new_rank)
		):
			push_error("UpgradeEffectRegistry: impossibile applicare %s." % definition.id)
			return
		effect_applied.emit(definition, new_rank, get_effective_multipliers())
		return
	if definition.effect_id == SUMMER_GRILL:
		var health := _player.get_health_component()
		if health == null:
			push_error("UpgradeEffectRegistry: salute Player assente per %s." % definition.id)
			return
		var previous_health_max := health.health_max
		var player_was_alive := health.is_alive()
		if not recalculate_effects(false):
			push_error("UpgradeEffectRegistry: impossibile applicare %s." % definition.id)
			return
		var gained_health_max := maxf(health.health_max - previous_health_max, 0.0)
		if player_was_alive and gained_health_max > 0.0:
			health.heal(gained_health_max)
		effect_applied.emit(definition, new_rank, get_effective_multipliers())
		return
	if not recalculate_effects():
		push_error("UpgradeEffectRegistry: impossibile applicare %s." % definition.id)
		return
	print(
		"B13_EFFECT id=%s rank=%d move=%.4f health=%.4f pickup=%.4f fire=%.4f damage=%.4f signatures=%s"
		% [
			definition.id,
			new_rank,
			get_effective_multiplier(PLAYER_MOVE_SPEED_MULTIPLIER),
			get_effective_multiplier(PLAYER_HEALTH_MAX_MULTIPLIER),
			get_effective_multiplier(PLAYER_PICKUP_RADIUS_MULTIPLIER),
			get_effective_multiplier(WEAPON_FIRE_RATE_MULTIPLIER),
			get_effective_multiplier(WEAPON_DAMAGE_MULTIPLIER),
			_signature_parameters.keys(),
		]
	)
	effect_applied.emit(definition, new_rank, get_effective_multipliers())


func _on_ranks_reset() -> void:
	reset_effects()


func _on_target_registered(target: BaseEnemy) -> void:
	if is_slow_pulse_active() and is_instance_valid(target):
		target.set_speed_modifier(CHRONIC_DELAY_MODIFIER, _slow_factor)


func _on_player_damaged(
	player: Player,
	_amount: float,
	_health_current: float
) -> void:
	if (
		player != _player
		or not has_signature_effect(DAMAGE_SHOCKWAVE)
		or not is_instance_valid(_run_controller)
		or not _run_controller.is_running()
		or not is_instance_valid(_targeting_system)
	):
		return
	var parameters := get_signature_parameters(DAMAGE_SHOCKWAVE)
	var radius := float(parameters["radius"])
	var radius_squared := radius * radius
	var knockback_speed := float(parameters["knockback_speed"])
	var knockback_duration := float(parameters["knockback_duration"])
	var affected_count := 0
	for enemy in _targeting_system.get_alive_targets():
		var offset := enemy.global_position - _player.global_position
		if offset.length_squared() > radius_squared:
			continue
		var direction := offset.normalized() if not offset.is_zero_approx() else Vector2.RIGHT
		if enemy.apply_knockback(direction * knockback_speed, knockback_duration):
			affected_count += 1
	_create_damage_shockwave(parameters)
	damage_shockwave_emitted.emit(affected_count)


func _on_shockwave_finished(pulse: DamageShockwave) -> void:
	_active_shockwaves.erase(pulse)


func _prune_shockwaves() -> void:
	for index in range(_active_shockwaves.size() - 1, -1, -1):
		var pulse := _active_shockwaves[index]
		if not is_instance_valid(pulse) or pulse.is_queued_for_deletion():
			_active_shockwaves.remove_at(index)
