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

const ANXIETY_SIGNATURE := &"anxiety_signature"
const GOSSIP_PROJECTILES := &"gossip_projectiles"
const CHRONIC_DELAY := &"chronic_delay"
const BEER_SIGNATURE := &"beer_signature"
const DAMAGE_SHOCKWAVE := &"damage_shockwave"
const CHRONIC_DELAY_MODIFIER := &"upgrade_chronic_delay"

const MINIMUM_MULTIPLIER := 0.001

@export_group("Multiplier Caps")
@export_range(1.0, 10.0, 0.05, "or_greater") var max_move_speed_multiplier := 2.0
@export_range(1.0, 10.0, 0.05, "or_greater") var max_pickup_radius_multiplier := 3.0
@export_range(1.0, 10.0, 0.05, "or_greater") var max_health_max_multiplier := 3.0
@export_range(0.01, 1.0, 0.01) var min_health_max_multiplier := 0.1
@export_range(1.0, 20.0, 0.05, "or_greater") var max_fire_rate_multiplier := 3.0
@export_range(1.0, 20.0, 0.05, "or_greater") var max_damage_multiplier := 5.0

var _upgrade_service: UpgradeService
var _upgrade_registry: UpgradeRegistry
var _player: Player
var _weapon_controller: WeaponController
var _run_controller: RunController
var _targeting_system: TargetingSystem
var _vignette_effect: VignetteEffect
var _effect_parent: Node2D
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
	effect_parent: Node2D = null
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
		or _upgrade_service.get_run_controller() != _run_controller
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
		WEAPON_DAMAGE_MULTIPLIER:
			return _get_positive_number(definition.effect_parameters, "multiplier") > 0.0
		ANXIETY_SIGNATURE:
			return (
				_is_single_rank_signature(definition)
				and _get_positive_number(
					definition.effect_parameters,
					"move_speed_multiplier"
				) > 0.0
				and _get_positive_number(
					definition.effect_parameters,
					"health_max_multiplier"
				) > 0.0
				and _get_unit_number(
					definition.effect_parameters,
					"vignette_intensity"
				) >= 0.0
			)
		GOSSIP_PROJECTILES:
			return (
				_is_single_rank_signature(definition)
				and _get_positive_integer(
					definition.effect_parameters,
					"chain_jumps"
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
					"oscillation_amplitude"
				) > 0.0
				and _get_positive_number(
					definition.effect_parameters,
					"oscillation_frequency_hz"
				) > 0.0
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
		_:
			return false


func recalculate_effects() -> bool:
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
			ANXIETY_SIGNATURE:
				_multiply_effect(
					next_multipliers,
					PLAYER_MOVE_SPEED_MULTIPLIER,
					_get_positive_number(
						definition.effect_parameters,
						"move_speed_multiplier"
					),
					rank
				)
				_multiply_effect(
					next_multipliers,
					PLAYER_HEALTH_MAX_MULTIPLIER,
					_get_positive_number(
						definition.effect_parameters,
						"health_max_multiplier"
					),
					rank
				)
				next_signatures[definition.effect_id] = (
					definition.effect_parameters.duplicate(true)
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
			GOSSIP_PROJECTILES, CHRONIC_DELAY, DAMAGE_SHOCKWAVE:
				next_signatures[definition.effect_id] = (
					definition.effect_parameters.duplicate(true)
				)
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

	if not _apply_multipliers(next_multipliers):
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


func get_targeting_system() -> TargetingSystem:
	return _targeting_system if is_instance_valid(_targeting_system) else null


func get_vignette_effect() -> VignetteEffect:
	return _vignette_effect if is_instance_valid(_vignette_effect) else null


func get_effect_parent() -> Node2D:
	return _effect_parent if is_instance_valid(_effect_parent) else null


func _apply_multipliers(multipliers: Dictionary) -> bool:
	return (
		_player.set_upgrade_stat_multipliers(
			float(multipliers[PLAYER_MOVE_SPEED_MULTIPLIER]),
			float(multipliers[PLAYER_PICKUP_RADIUS_MULTIPLIER]),
			float(multipliers[PLAYER_HEALTH_MAX_MULTIPLIER])
		)
		and _weapon_controller.set_upgrade_stat_multipliers(
			float(multipliers[WEAPON_FIRE_RATE_MULTIPLIER]),
			float(multipliers[WEAPON_DAMAGE_MULTIPLIER])
		)
	)


func _apply_signature_effects(next_signatures: Dictionary) -> bool:
	var anxiety_parameters := _parameters_from(next_signatures, ANXIETY_SIGNATURE)
	var vignette_intensity := 0.0
	if not anxiety_parameters.is_empty():
		vignette_intensity = float(anxiety_parameters["vignette_intensity"])
	if is_instance_valid(_vignette_effect):
		if not _vignette_effect.set_intensity(vignette_intensity):
			return false
	elif vignette_intensity > 0.0:
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
	var oscillation_amplitude := 0.0
	var oscillation_frequency_hz := 0.0
	if not beer_parameters.is_empty():
		oscillation_amplitude = float(beer_parameters["oscillation_amplitude"])
		oscillation_frequency_hz = float(
			beer_parameters["oscillation_frequency_hz"]
		)
	if not _weapon_controller.set_projectile_upgrade_modifiers(
		chain_enabled,
		chain_jumps,
		chain_damage_falloff,
		chain_radius,
		oscillation_amplitude,
		oscillation_frequency_hz
	):
		return false

	_apply_chronic_delay_configuration(
		_parameters_from(next_signatures, CHRONIC_DELAY)
	)
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
		_:
			return 1.0


func _get_minimum(effect_id: StringName) -> float:
	return min_health_max_multiplier if effect_id == PLAYER_HEALTH_MAX_MULTIPLIER else MINIMUM_MULTIPLIER


func _has_valid_caps() -> bool:
	for cap in [
		max_move_speed_multiplier,
		max_pickup_radius_multiplier,
		max_health_max_multiplier,
		max_fire_rate_multiplier,
		max_damage_multiplier,
	]:
		if not is_finite(cap) or cap < 1.0:
			return false
	return (
		is_finite(min_health_max_multiplier)
		and min_health_max_multiplier > 0.0
		and min_health_max_multiplier <= 1.0
	)


func _supported_stat_effect_ids() -> Array[StringName]:
	return [
		PLAYER_MOVE_SPEED_MULTIPLIER,
		PLAYER_PICKUP_RADIUS_MULTIPLIER,
		PLAYER_HEALTH_MAX_MULTIPLIER,
		WEAPON_FIRE_RATE_MULTIPLIER,
		WEAPON_DAMAGE_MULTIPLIER,
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
			ANXIETY_SIGNATURE:
				if not is_instance_valid(_vignette_effect):
					return false
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
	_targeting_system = null
	_vignette_effect = null
	_effect_parent = null


func _on_upgrade_selected(
	definition: UpgradeDefinition,
	new_rank: int,
	_level: int
) -> void:
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
