class_name UpgradeEffectRegistry
extends Node

signal effects_recalculated(effective_multipliers: Dictionary)
signal effect_applied(
	definition: UpgradeDefinition,
	new_rank: int,
	effective_multipliers: Dictionary
)
signal effects_reset()

const PLAYER_MOVE_SPEED_MULTIPLIER := &"player_move_speed_multiplier"
const PLAYER_PICKUP_RADIUS_MULTIPLIER := &"player_pickup_radius_multiplier"
const WEAPON_FIRE_RATE_MULTIPLIER := &"weapon_fire_rate_multiplier"
const WEAPON_DAMAGE_MULTIPLIER := &"weapon_damage_multiplier"
const MINIMUM_MULTIPLIER := 0.001

@export_group("Multiplier Caps")
@export_range(1.0, 10.0, 0.05, "or_greater") var max_move_speed_multiplier := 2.0
@export_range(1.0, 10.0, 0.05, "or_greater") var max_pickup_radius_multiplier := 3.0
@export_range(1.0, 20.0, 0.05, "or_greater") var max_fire_rate_multiplier := 3.0
@export_range(1.0, 20.0, 0.05, "or_greater") var max_damage_multiplier := 5.0

var _upgrade_service: UpgradeService
var _upgrade_registry: UpgradeRegistry
var _player: Player
var _weapon_controller: WeaponController
var _effective_multipliers: Dictionary = {}


func _ready() -> void:
	_reset_multiplier_cache()


func _exit_tree() -> void:
	_disconnect_upgrade_service()


func configure(
	upgrade_service: UpgradeService,
	upgrade_registry: UpgradeRegistry,
	player: Player,
	weapon_controller: WeaponController
) -> bool:
	_disconnect_upgrade_service()
	_upgrade_service = upgrade_service
	_upgrade_registry = upgrade_registry
	_player = player
	_weapon_controller = weapon_controller
	_connect_upgrade_service()
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
		or not _has_valid_caps()
	):
		return false
	for definition in _upgrade_registry.get_definitions():
		if not can_apply(definition):
			return false
	return true


func can_apply(definition: UpgradeDefinition) -> bool:
	if definition == null or not definition.is_valid():
		return false
	if definition.effect_id not in _supported_effect_ids():
		return false
	return _get_definition_multiplier(definition) > 0.0


func recalculate_effects() -> bool:
	if not has_valid_configuration():
		return false

	var next_multipliers := _make_identity_multipliers()
	var ranks := _upgrade_service.get_ranks()
	for upgrade_id_value: Variant in ranks:
		var upgrade_id := StringName(str(upgrade_id_value))
		var rank := maxi(int(ranks[upgrade_id_value]), 0)
		if rank == 0:
			continue
		var definition := _upgrade_registry.resolve_definition(upgrade_id)
		if not can_apply(definition):
			return false
		var current := float(next_multipliers[definition.effect_id])
		var multiplier := _get_definition_multiplier(definition)
		next_multipliers[definition.effect_id] = current * pow(multiplier, rank)

	for effect_id in _supported_effect_ids():
		next_multipliers[effect_id] = clampf(
			float(next_multipliers[effect_id]),
			MINIMUM_MULTIPLIER,
			_get_cap(effect_id)
		)

	if not _apply_multipliers(next_multipliers):
		return false
	_effective_multipliers = next_multipliers
	effects_recalculated.emit(get_effective_multipliers())
	return true


func reset_effects() -> void:
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


func get_upgrade_service() -> UpgradeService:
	return _upgrade_service if is_instance_valid(_upgrade_service) else null


func get_upgrade_registry() -> UpgradeRegistry:
	return _upgrade_registry if is_instance_valid(_upgrade_registry) else null


func get_player() -> Player:
	return _player if is_instance_valid(_player) else null


func get_weapon_controller() -> WeaponController:
	return _weapon_controller if is_instance_valid(_weapon_controller) else null


func _apply_multipliers(multipliers: Dictionary) -> bool:
	return (
		_player.set_upgrade_stat_multipliers(
			float(multipliers[PLAYER_MOVE_SPEED_MULTIPLIER]),
			float(multipliers[PLAYER_PICKUP_RADIUS_MULTIPLIER])
		)
		and _weapon_controller.set_upgrade_stat_multipliers(
			float(multipliers[WEAPON_FIRE_RATE_MULTIPLIER]),
			float(multipliers[WEAPON_DAMAGE_MULTIPLIER])
		)
	)


func _get_definition_multiplier(definition: UpgradeDefinition) -> float:
	if definition == null or not definition.effect_parameters.has("multiplier"):
		return -1.0
	var value: Variant = definition.effect_parameters["multiplier"]
	if typeof(value) not in [TYPE_INT, TYPE_FLOAT]:
		return -1.0
	var multiplier := float(value)
	return multiplier if is_finite(multiplier) and multiplier > 0.0 else -1.0


func _get_cap(effect_id: StringName) -> float:
	match effect_id:
		PLAYER_MOVE_SPEED_MULTIPLIER:
			return max_move_speed_multiplier
		PLAYER_PICKUP_RADIUS_MULTIPLIER:
			return max_pickup_radius_multiplier
		WEAPON_FIRE_RATE_MULTIPLIER:
			return max_fire_rate_multiplier
		WEAPON_DAMAGE_MULTIPLIER:
			return max_damage_multiplier
		_:
			return 1.0


func _has_valid_caps() -> bool:
	for cap in [
		max_move_speed_multiplier,
		max_pickup_radius_multiplier,
		max_fire_rate_multiplier,
		max_damage_multiplier,
	]:
		if not is_finite(cap) or cap < 1.0:
			return false
	return true


func _supported_effect_ids() -> Array[StringName]:
	return [
		PLAYER_MOVE_SPEED_MULTIPLIER,
		PLAYER_PICKUP_RADIUS_MULTIPLIER,
		WEAPON_FIRE_RATE_MULTIPLIER,
		WEAPON_DAMAGE_MULTIPLIER,
	]


func _make_identity_multipliers() -> Dictionary:
	var multipliers: Dictionary = {}
	for effect_id in _supported_effect_ids():
		multipliers[effect_id] = 1.0
	return multipliers


func _reset_multiplier_cache() -> void:
	_effective_multipliers = _make_identity_multipliers()


func _connect_upgrade_service() -> void:
	if not is_instance_valid(_upgrade_service):
		return
	if not _upgrade_service.upgrade_selected.is_connected(_on_upgrade_selected):
		_upgrade_service.upgrade_selected.connect(_on_upgrade_selected)
	if not _upgrade_service.ranks_reset.is_connected(_on_ranks_reset):
		_upgrade_service.ranks_reset.connect(_on_ranks_reset)


func _disconnect_upgrade_service() -> void:
	if is_instance_valid(_upgrade_service):
		if _upgrade_service.upgrade_selected.is_connected(_on_upgrade_selected):
			_upgrade_service.upgrade_selected.disconnect(_on_upgrade_selected)
		if _upgrade_service.ranks_reset.is_connected(_on_ranks_reset):
			_upgrade_service.ranks_reset.disconnect(_on_ranks_reset)
	_upgrade_service = null
	_upgrade_registry = null
	_player = null
	_weapon_controller = null


func _on_upgrade_selected(
	definition: UpgradeDefinition,
	new_rank: int,
	_level: int
) -> void:
	if not recalculate_effects():
		push_error("UpgradeEffectRegistry: impossibile applicare %s." % definition.id)
		return
	print(
		"B12_EFFECT id=%s rank=%d move=%.4f pickup=%.4f fire=%.4f damage=%.4f"
		% [
			definition.id,
			new_rank,
			get_effective_multiplier(PLAYER_MOVE_SPEED_MULTIPLIER),
			get_effective_multiplier(PLAYER_PICKUP_RADIUS_MULTIPLIER),
			get_effective_multiplier(WEAPON_FIRE_RATE_MULTIPLIER),
			get_effective_multiplier(WEAPON_DAMAGE_MULTIPLIER),
		]
	)
	effect_applied.emit(definition, new_rank, get_effective_multipliers())


func _on_ranks_reset() -> void:
	reset_effects()
