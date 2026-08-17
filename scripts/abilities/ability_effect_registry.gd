class_name AbilityEffectRegistry
extends Node

signal effect_executed(
	definition: AbilityDefinition,
	effect: Node2D,
	affected_count: int
)

const EARTHQUAKE_SHOCKWAVE := &"earthquake_shockwave"
const DEFAULT_WAVE_DURATION := 0.35

@export var definitions: Array[AbilityDefinition] = []

var _definitions_by_id: Dictionary = {}
var _run_controller: RunController
var _targeting_system: TargetingSystem
var _effect_parent: Node2D
var _active_effects: Array[Node2D] = []
var _last_affected_count := 0


func _ready() -> void:
	_rebuild_definition_index()


func _exit_tree() -> void:
	_disconnect_run_controller()
	clear_active_effects()


func configure(
	run_controller: RunController,
	targeting_system: TargetingSystem,
	effect_parent: Node2D
) -> bool:
	_disconnect_run_controller()
	_run_controller = run_controller
	_targeting_system = targeting_system
	_effect_parent = effect_parent
	_rebuild_definition_index()
	_connect_run_controller()
	return _has_valid_dependencies()


func register_definition(definition: AbilityDefinition) -> bool:
	if definition == null or not definition.is_valid():
		return false
	if _definitions_by_id.has(definition.id):
		return _definitions_by_id[definition.id] == definition
	_definitions_by_id[definition.id] = definition
	if not definitions.has(definition):
		definitions.append(definition)
	return true


func resolve_definition(ability_id: StringName) -> AbilityDefinition:
	var definition: Variant = _definitions_by_id.get(ability_id)
	return definition as AbilityDefinition


func get_compatible_definitions(
	required_tags: Array[StringName] = [],
	excluded_ids: Array[StringName] = []
) -> Array[AbilityDefinition]:
	var compatible: Array[AbilityDefinition] = []
	for definition in definitions:
		if definition == null or not definition.is_valid():
			continue
		if definition.id in excluded_ids or not definition.has_all_tags(required_tags):
			continue
		compatible.append(definition)
	return compatible


func can_execute(definition: AbilityDefinition) -> bool:
	return (
		definition != null
		and definition.is_valid()
		and definition.effect_id == EARTHQUAKE_SHOCKWAVE
		and definition.area_radius > 0.0
		and _has_valid_dependencies()
		and _run_controller.is_running()
	)


func execute_effect(definition: AbilityDefinition, source: Node2D) -> Node2D:
	_last_affected_count = 0
	if not can_execute(definition) or not is_instance_valid(source):
		return null

	match definition.effect_id:
		EARTHQUAKE_SHOCKWAVE:
			return _execute_earthquake_shockwave(definition, source)
		_:
			return null


func clear_active_effects() -> void:
	var effects_to_clear := _active_effects.duplicate()
	_active_effects.clear()
	for effect in effects_to_clear:
		if is_instance_valid(effect) and not effect.is_queued_for_deletion():
			effect.queue_free()
	_last_affected_count = 0


func get_active_effect_count() -> int:
	_prune_active_effects()
	return _active_effects.size()


func get_last_affected_count() -> int:
	return _last_affected_count


func get_run_controller() -> RunController:
	return _run_controller if is_instance_valid(_run_controller) else null


func get_targeting_system() -> TargetingSystem:
	return _targeting_system if is_instance_valid(_targeting_system) else null


func get_effect_parent() -> Node2D:
	return _effect_parent if is_instance_valid(_effect_parent) else null


func _execute_earthquake_shockwave(
	definition: AbilityDefinition,
	source: Node2D
) -> Node2D:
	var wave := EarthquakeWave.new()
	wave.name = "EarthquakeWave"
	_effect_parent.add_child(wave)
	var visual_duration := definition.get_effect_float(
		&"visual_duration",
		DEFAULT_WAVE_DURATION,
		AbilityDefinition.MINIMUM_POSITIVE_VALUE
	)
	if not wave.initialize(
		source.global_position,
		definition.area_radius,
		visual_duration,
		_run_controller
	):
		wave.queue_free()
		return null

	_active_effects.append(wave)
	wave.tree_exiting.connect(_on_effect_tree_exiting.bind(wave), CONNECT_ONE_SHOT)
	_last_affected_count = _apply_earthquake_to_targets(definition, source.global_position)
	effect_executed.emit(definition, wave, _last_affected_count)
	return wave


func _apply_earthquake_to_targets(
	definition: AbilityDefinition,
	origin: Vector2
) -> int:
	var affected_count := 0
	var knockback_force := definition.get_effect_float(&"knockback_force", 0.0, 0.0)
	var stun_duration := definition.get_effect_float(&"stun_duration", 0.0, 0.0)
	for target in _targeting_system.get_alive_targets():
		var offset := target.global_position - origin
		if not is_point_within_radius(origin, target.global_position, definition.area_radius):
			continue
		var direction := offset.normalized() if not offset.is_zero_approx() else Vector2.RIGHT
		if knockback_force > 0.0 and stun_duration > 0.0:
			target.apply_knockback(direction * knockback_force, stun_duration)
		if definition.damage > 0.0:
			target.take_damage(definition.damage)
		affected_count += 1
	return affected_count


static func is_point_within_radius(
	origin: Vector2,
	target_position: Vector2,
	radius: float
) -> bool:
	if (
		not origin.is_finite()
		or not target_position.is_finite()
		or not is_finite(radius)
		or radius < 0.0
	):
		return false
	return origin.distance_squared_to(target_position) <= radius * radius


func _rebuild_definition_index() -> void:
	_definitions_by_id.clear()
	for definition in definitions:
		if definition == null or not definition.is_valid():
			continue
		if _definitions_by_id.has(definition.id):
			push_warning("AbilityEffectRegistry: ID duplicato %s." % definition.id)
			continue
		_definitions_by_id[definition.id] = definition


func _has_valid_dependencies() -> bool:
	return (
		is_instance_valid(_run_controller)
		and is_instance_valid(_targeting_system)
		and is_instance_valid(_effect_parent)
		and _effect_parent.is_inside_tree()
	)


func _prune_active_effects() -> void:
	for index in range(_active_effects.size() - 1, -1, -1):
		if not is_instance_valid(_active_effects[index]):
			_active_effects.remove_at(index)


func _connect_run_controller() -> void:
	if not is_instance_valid(_run_controller):
		return
	if not _run_controller.restart_prepared.is_connected(_on_restart_prepared):
		_run_controller.restart_prepared.connect(_on_restart_prepared)


func _disconnect_run_controller() -> void:
	if not is_instance_valid(_run_controller):
		_run_controller = null
		return
	if _run_controller.restart_prepared.is_connected(_on_restart_prepared):
		_run_controller.restart_prepared.disconnect(_on_restart_prepared)
	_run_controller = null


func _on_restart_prepared() -> void:
	clear_active_effects()


func _on_effect_tree_exiting(effect: Node2D) -> void:
	_active_effects.erase(effect)
