class_name FriendPassiveController
extends Node

signal passive_equipped(definition: FriendDefinition)
signal damage_avoided(passive_id: StringName)
signal delayed_healing_changed(recoverable_health: float)
signal shield_changed(active: bool, remaining: float)
signal random_effect_started(positive: bool, stat_id: StringName, multiplier: float)

const MAGNO_AERODYNAMIC_FLOW := &"magno_aerodynamic_flow"
const BEA_SIXTH_SENSE := &"bea_sixth_sense"
const ZAT_DELAYED_HEALING := &"zat_delayed_healing"
const ALEA_EAGLE_NEVER_MISSES := &"alea_eagle_never_misses"
const ALEO_SOLID_STRUCTURE := &"aleo_solid_structure"
const LOLLO_HYPERACTIVITY := &"lollo_hyperactivity"
const MIGI_TURTLE_SHELL := &"migi_turtle_shell"
const MARGHE_CONTAGIOUS_SMILE := &"marghe_contagious_smile"

const MARGHE_HEALTH_META := &"b17a_marghe_health_profile"
const MINIMUM_MULTIPLIER := 0.001

var _run_controller: RunController
var _player: Player
var _weapon_controller: WeaponController
var _targeting_system: TargetingSystem
var _definition: FriendDefinition
var _rng := RandomNumberGenerator.new()

var _recoverable_health := 0.0
var _recovery_delay_remaining := 0.0
var _recovery_duration_remaining := 0.0
var _shield_remaining := 0.0
var _shield_cooldown_remaining := 0.0
var _shield_hits_remaining := 0
var _alea_interval_remaining := 0.0
var _alea_effect_remaining := 0.0
var _alea_move_multiplier := 1.0
var _alea_fire_multiplier := 1.0


func _process(delta: float) -> void:
	if (
		_definition == null
		or not is_instance_valid(_run_controller)
		or not _run_controller.is_running()
	):
		return
	var safe_delta := maxf(delta, 0.0) if is_finite(delta) else 0.0
	if safe_delta <= 0.0:
		return
	match _definition.passive_id:
		ZAT_DELAYED_HEALING:
			_advance_delayed_healing(safe_delta)
		ALEA_EAGLE_NEVER_MISSES:
			_advance_alea_effect(safe_delta)
		MIGI_TURTLE_SHELL:
			_advance_migi_shield(safe_delta)


func _exit_tree() -> void:
	_disconnect_dependencies()


func configure(
	run_controller: RunController,
	player: Player,
	weapon_controller: WeaponController,
	targeting_system: TargetingSystem
) -> bool:
	_disconnect_dependencies()
	_run_controller = run_controller
	_player = player
	_weapon_controller = weapon_controller
	_targeting_system = targeting_system
	if not _has_valid_dependencies():
		return false
	_player.set_passive_controller(self)
	_player.damaged.connect(_on_player_damaged)
	_targeting_system.target_registered.connect(_on_target_registered)
	_run_controller.run_started.connect(_on_run_started)
	_run_controller.restart_prepared.connect(_on_restart_prepared)
	return true


func equip_definition(definition: FriendDefinition) -> bool:
	if not _has_valid_dependencies() or not is_supported_definition(definition):
		return false
	_definition = definition
	_reset_runtime(_run_controller.get_seed())
	passive_equipped.emit(_definition)
	return true


func get_definition() -> FriendDefinition:
	return _definition


func get_passive_id() -> StringName:
	return _definition.passive_id if _definition != null else &""


func get_recoverable_health() -> float:
	return _recoverable_health


func is_shield_active() -> bool:
	return _shield_remaining > 0.0 and _shield_hits_remaining > 0


func get_shield_remaining() -> float:
	return _shield_remaining


func resolve_incoming_damage(amount: float) -> float:
	if (
		_definition == null
		or not is_finite(amount)
		or amount <= 0.0
		or not is_instance_valid(_run_controller)
		or not _run_controller.is_running()
	):
		return maxf(amount, 0.0) if is_finite(amount) else 0.0

	if _definition.passive_id == BEA_SIXTH_SENSE:
		var evasion_chance := _definition.get_passive_float(
			&"evasion_chance",
			0.0,
			0.0,
			1.0
		)
		if _rng.randf() < evasion_chance:
			damage_avoided.emit(_definition.passive_id)
			return 0.0

	if _definition.passive_id == MIGI_TURTLE_SHELL and is_shield_active():
		_shield_hits_remaining -= 1
		if _shield_hits_remaining <= 0:
			_shield_remaining = 0.0
			shield_changed.emit(false, 0.0)
		damage_avoided.emit(_definition.passive_id)
		return 0.0

	var reduction := 0.0
	if _definition.passive_id in [ALEO_SOLID_STRUCTURE, MIGI_TURTLE_SHELL]:
		reduction = _definition.get_passive_float(
			&"damage_reduction",
			0.0,
			0.0,
			0.95
		)
	return amount * (1.0 - reduction)


func is_supported_definition(definition: FriendDefinition) -> bool:
	if definition == null or not definition.is_valid():
		return false
	return definition.passive_id in [
		MAGNO_AERODYNAMIC_FLOW,
		BEA_SIXTH_SENSE,
		ZAT_DELAYED_HEALING,
		ALEA_EAGLE_NEVER_MISSES,
		ALEO_SOLID_STRUCTURE,
		LOLLO_HYPERACTIVITY,
		MIGI_TURTLE_SHELL,
		MARGHE_CONTAGIOUS_SMILE,
	]


func _advance_delayed_healing(delta: float) -> void:
	if _recoverable_health <= 0.0:
		return
	if _recovery_delay_remaining > 0.0:
		_recovery_delay_remaining = maxf(_recovery_delay_remaining - delta, 0.0)
		return
	if _recovery_duration_remaining <= 0.0:
		_recovery_duration_remaining = _definition.get_passive_float(
			&"recovery_duration",
			1.0,
			AbilityDefinition.MINIMUM_POSITIVE_VALUE
		)
	var healing_request := minf(
		_recoverable_health,
		_recoverable_health * delta / _recovery_duration_remaining
	)
	var health := _player.get_health_component()
	var applied := health.heal(healing_request) if health != null else 0.0
	if applied <= 0.0:
		_recoverable_health = 0.0
	else:
		_recoverable_health = maxf(_recoverable_health - applied, 0.0)
	_recovery_duration_remaining = maxf(_recovery_duration_remaining - delta, 0.0)
	delayed_healing_changed.emit(_recoverable_health)


func _advance_alea_effect(delta: float) -> void:
	if _alea_effect_remaining > 0.0:
		_alea_effect_remaining = maxf(_alea_effect_remaining - delta, 0.0)
		if _alea_effect_remaining <= 0.0:
			_alea_move_multiplier = 1.0
			_alea_fire_multiplier = 1.0
			_apply_character_multipliers()
	_alea_interval_remaining -= delta
	if _alea_interval_remaining > 0.0:
		return
	_alea_interval_remaining = _definition.get_passive_float(
		&"trigger_interval",
		12.0,
		AbilityDefinition.MINIMUM_POSITIVE_VALUE
	)
	_activate_alea_effect()


func _activate_alea_effect() -> void:
	var positive := _rng.randf() < _definition.get_passive_float(
		&"positive_chance",
		0.75,
		0.0,
		1.0
	)
	var multiplier := _definition.get_passive_float(
		&"positive_multiplier" if positive else &"negative_multiplier",
		1.2 if positive else 0.9,
		MINIMUM_MULTIPLIER
	)
	var stat_id := &"move_speed" if _rng.randi_range(0, 1) == 0 else &"fire_rate"
	_alea_move_multiplier = multiplier if stat_id == &"move_speed" else 1.0
	_alea_fire_multiplier = multiplier if stat_id == &"fire_rate" else 1.0
	_alea_effect_remaining = _definition.get_passive_float(
		&"effect_duration",
		5.0,
		AbilityDefinition.MINIMUM_POSITIVE_VALUE
	)
	_apply_character_multipliers()
	random_effect_started.emit(positive, stat_id, multiplier)


func _advance_migi_shield(delta: float) -> void:
	_shield_cooldown_remaining = maxf(_shield_cooldown_remaining - delta, 0.0)
	if _shield_remaining <= 0.0:
		return
	_shield_remaining = maxf(_shield_remaining - delta, 0.0)
	if _shield_remaining <= 0.0:
		_shield_hits_remaining = 0
		shield_changed.emit(false, 0.0)


func _activate_migi_shield() -> void:
	_shield_remaining = _definition.get_passive_float(
		&"shield_duration",
		4.0,
		AbilityDefinition.MINIMUM_POSITIVE_VALUE
	)
	_shield_hits_remaining = _definition.get_passive_int(&"shield_hits", 1, 1)
	_shield_cooldown_remaining = _definition.get_passive_float(
		&"shield_cooldown",
		20.0,
		AbilityDefinition.MINIMUM_POSITIVE_VALUE
	)
	shield_changed.emit(true, _shield_remaining)


func _apply_character_multipliers() -> void:
	if not _has_valid_dependencies():
		return
	var move_multiplier := 1.0
	var fire_multiplier := 1.0
	if _definition != null:
		match _definition.passive_id:
			MAGNO_AERODYNAMIC_FLOW:
				move_multiplier = _definition.get_passive_float(
					&"move_speed_multiplier",
					1.0,
					MINIMUM_MULTIPLIER
				)
			LOLLO_HYPERACTIVITY:
				move_multiplier = _definition.get_passive_float(
					&"move_speed_multiplier",
					1.0,
					MINIMUM_MULTIPLIER
				)
				fire_multiplier = _definition.get_passive_float(
					&"fire_rate_multiplier",
					1.0,
					MINIMUM_MULTIPLIER
				)
			ALEA_EAGLE_NEVER_MISSES:
				move_multiplier = _alea_move_multiplier
				fire_multiplier = _alea_fire_multiplier
	_player.set_character_stat_multipliers(move_multiplier)
	_weapon_controller.set_character_stat_multipliers(fire_multiplier)


func _apply_marghe_health_modifier(target: BaseEnemy) -> void:
	if (
		_definition == null
		or _definition.passive_id != MARGHE_CONTAGIOUS_SMILE
		or not is_instance_valid(target)
		or target.is_queued_for_deletion()
		or (
			target.is_in_group(&"bosses")
			and not _definition.get_passive_bool(&"affects_bosses", false)
		)
	):
		return
	var profile_marker := String(_definition.id)
	if String(target.get_meta(MARGHE_HEALTH_META, "")) == profile_marker:
		return
	var health := target.get_health_component()
	if health == null:
		return
	var health_multiplier := _definition.get_passive_float(
		&"enemy_health_multiplier",
		1.0,
		MINIMUM_MULTIPLIER,
		1.0
	)
	health.set_health_max(health.health_max * health_multiplier, true)
	target.set_meta(MARGHE_HEALTH_META, profile_marker)


func _reset_runtime(seed_value: int) -> void:
	_rng.seed = seed_value if seed_value != 0 else 1
	_recoverable_health = 0.0
	_recovery_delay_remaining = 0.0
	_recovery_duration_remaining = 0.0
	_shield_remaining = 0.0
	_shield_cooldown_remaining = 0.0
	_shield_hits_remaining = 0
	_alea_effect_remaining = 0.0
	_alea_move_multiplier = 1.0
	_alea_fire_multiplier = 1.0
	_alea_interval_remaining = (
		_definition.get_passive_float(
			&"trigger_interval",
			12.0,
			AbilityDefinition.MINIMUM_POSITIVE_VALUE
		)
		if _definition != null and _definition.passive_id == ALEA_EAGLE_NEVER_MISSES
		else 0.0
	)
	_apply_character_multipliers()
	if _definition != null and _definition.passive_id == MARGHE_CONTAGIOUS_SMILE:
		for target in _targeting_system.get_alive_targets():
			_apply_marghe_health_modifier(target)
	delayed_healing_changed.emit(0.0)
	shield_changed.emit(false, 0.0)


func _has_valid_dependencies() -> bool:
	return (
		is_instance_valid(_run_controller)
		and is_instance_valid(_player)
		and is_instance_valid(_weapon_controller)
		and is_instance_valid(_targeting_system)
	)


func _disconnect_dependencies() -> void:
	if is_instance_valid(_player):
		if _player.damaged.is_connected(_on_player_damaged):
			_player.damaged.disconnect(_on_player_damaged)
		if _player.get_passive_controller() == self:
			_player.set_passive_controller(null)
	if (
		is_instance_valid(_targeting_system)
		and _targeting_system.target_registered.is_connected(_on_target_registered)
	):
		_targeting_system.target_registered.disconnect(_on_target_registered)
	if is_instance_valid(_run_controller):
		if _run_controller.run_started.is_connected(_on_run_started):
			_run_controller.run_started.disconnect(_on_run_started)
		if _run_controller.restart_prepared.is_connected(_on_restart_prepared):
			_run_controller.restart_prepared.disconnect(_on_restart_prepared)
	_run_controller = null
	_player = null
	_weapon_controller = null
	_targeting_system = null


func _on_player_damaged(_player_value: Player, amount: float, _health_current: float) -> void:
	if _definition == null:
		return
	if _definition.passive_id == ZAT_DELAYED_HEALING:
		_recoverable_health += amount * _definition.get_passive_float(
			&"recoverable_fraction",
			0.0,
			0.0,
			1.0
		)
		_recovery_delay_remaining = _definition.get_passive_float(
			&"recovery_delay",
			3.0,
			0.0
		)
		_recovery_duration_remaining = _definition.get_passive_float(
			&"recovery_duration",
			4.0,
			AbilityDefinition.MINIMUM_POSITIVE_VALUE
		)
		delayed_healing_changed.emit(_recoverable_health)
	elif (
		_definition.passive_id == MIGI_TURTLE_SHELL
		and _shield_cooldown_remaining <= 0.0
		and not is_shield_active()
	):
		var health := _player.get_health_component()
		var threshold := _definition.get_passive_float(
			&"shield_health_threshold",
			0.35,
			0.0,
			1.0
		)
		if health != null and health.health_current / health.health_max <= threshold:
			_activate_migi_shield()


func _on_target_registered(target: BaseEnemy) -> void:
	_apply_marghe_health_modifier(target)


func _on_run_started(seed_value: int) -> void:
	_reset_runtime(seed_value)


func _on_restart_prepared() -> void:
	_reset_runtime(1)
