class_name AbilityEffectRegistry
extends Node

signal effect_executed(
	definition: AbilityDefinition,
	effect: Node2D,
	affected_count: int
)

const EARTHQUAKE_SHOCKWAVE := &"earthquake_shockwave"
const FIRE_Z_TRAIL := &"fire_z_trail"
const LIGHTNING_STORM := &"lightning_storm"
const GRAND_SPIN := &"grand_spin"
const CEMENT_POUR := &"cement_pour"
const RANDOM_COSPLAY := &"random_cosplay"
const ZEN_SLOWDOWN := &"zen_slowdown"
const SHADOW_DECEPTION := &"shadow_deception"

const COPY_COMPATIBLE := &"copy_compatible"
const DEFAULT_WAVE_DURATION := 0.35

@export var definitions: Array[AbilityDefinition] = []

var _definitions_by_id: Dictionary = {}
var _run_controller: RunController
var _targeting_system: TargetingSystem
var _effect_parent: Node2D
var _arena_layout: ArenaLayout
var _active_effects: Array[Node2D] = []
var _last_affected_count := 0
var _last_copied_ability_id: StringName
var _execution_serial := 0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rebuild_definition_index()


func _exit_tree() -> void:
	_disconnect_run_controller()
	clear_active_effects()


func configure(
	run_controller: RunController,
	targeting_system: TargetingSystem,
	effect_parent: Node2D,
	arena_layout: ArenaLayout = null
) -> bool:
	_disconnect_run_controller()
	_run_controller = run_controller
	_targeting_system = targeting_system
	_effect_parent = effect_parent
	_arena_layout = arena_layout
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


func get_definitions() -> Array[AbilityDefinition]:
	var valid_definitions: Array[AbilityDefinition] = []
	for definition in definitions:
		if definition != null and resolve_definition(definition.id) == definition:
			valid_definitions.append(definition)
	return valid_definitions


func get_compatible_definitions(
	required_tags: Array[StringName] = [],
	excluded_ids: Array[StringName] = []
) -> Array[AbilityDefinition]:
	var compatible: Array[AbilityDefinition] = []
	for definition in get_definitions():
		if definition.id in excluded_ids or not definition.has_all_tags(required_tags):
			continue
		compatible.append(definition)
	return compatible


func can_execute(definition: AbilityDefinition) -> bool:
	if not _can_execute_non_copy(definition):
		return false
	if definition.effect_id != RANDOM_COSPLAY:
		return true
	return not _get_cosplay_candidates(definition).is_empty()


func execute_effect(definition: AbilityDefinition, source: Node2D) -> Node2D:
	_last_affected_count = 0
	_last_copied_ability_id = &""
	if not can_execute(definition) or not is_instance_valid(source):
		return null
	return _execute_definition(definition, source, true)


func clear_active_effects() -> void:
	var effects_to_clear := _active_effects.duplicate()
	_active_effects.clear()
	for effect in effects_to_clear:
		if is_instance_valid(effect) and not effect.is_queued_for_deletion():
			effect.queue_free()
	_last_affected_count = 0
	_last_copied_ability_id = &""


func get_active_effect_count() -> int:
	_prune_active_effects()
	return _active_effects.size()


func get_active_effects() -> Array[Node2D]:
	_prune_active_effects()
	return _active_effects.duplicate()


func get_last_affected_count() -> int:
	return _last_affected_count


func get_last_copied_ability_id() -> StringName:
	return _last_copied_ability_id


func get_run_controller() -> RunController:
	return _run_controller if is_instance_valid(_run_controller) else null


func get_targeting_system() -> TargetingSystem:
	return _targeting_system if is_instance_valid(_targeting_system) else null


func get_effect_parent() -> Node2D:
	return _effect_parent if is_instance_valid(_effect_parent) else null


func get_arena_layout() -> ArenaLayout:
	return _arena_layout if is_instance_valid(_arena_layout) else null


func _execute_definition(
	definition: AbilityDefinition,
	source: Node2D,
	announce: bool
) -> Node2D:
	var effect: Node2D
	match definition.effect_id:
		EARTHQUAKE_SHOCKWAVE:
			effect = _execute_earthquake_shockwave(definition, source)
		FIRE_Z_TRAIL:
			effect = _execute_fire_z_trail(definition, source)
		LIGHTNING_STORM:
			effect = _execute_lightning_storm(definition, source)
		GRAND_SPIN:
			effect = _execute_area_effect(
				definition,
				source,
				AbilityAreaEffect.AreaMode.FOLLOWING_PULSE_DAMAGE,
				Color(1.0, 0.35, 0.72, 0.72)
			)
		CEMENT_POUR:
			effect = _execute_area_effect(
				definition,
				source,
				AbilityAreaEffect.AreaMode.GROUND_SLOW_DAMAGE,
				Color(0.55, 0.58, 0.62, 0.75)
			)
		RANDOM_COSPLAY:
			effect = _execute_random_cosplay(definition, source)
		ZEN_SLOWDOWN:
			effect = _execute_area_effect(
				definition,
				source,
				AbilityAreaEffect.AreaMode.FOLLOWING_SLOW,
				Color(0.2, 0.85, 0.72, 0.72)
			)
		SHADOW_DECEPTION:
			effect = _execute_shadow_deception(definition, source)
	if effect != null and announce:
		effect_executed.emit(definition, effect, _last_affected_count)
	return effect


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
	_track_effect(wave)
	_last_affected_count = _apply_earthquake_to_targets(definition, source.global_position)
	return wave


func _execute_fire_z_trail(definition: AbilityDefinition, source: Node2D) -> Node2D:
	if not source is Player:
		return null
	var trail := FireZTrail.new()
	trail.name = "FireZTrail"
	_effect_parent.add_child(trail)
	trail.targets_affected.connect(_on_targets_affected)
	if not trail.initialize(
		source as Player,
		definition,
		_run_controller,
		_targeting_system,
		_arena_layout
	):
		trail.queue_free()
		return null
	_track_effect(trail)
	return trail


func _execute_lightning_storm(definition: AbilityDefinition, source: Node2D) -> Node2D:
	var storm := LightningStorm.new()
	storm.name = "LightningStorm"
	_effect_parent.add_child(storm)
	storm.targets_affected.connect(_on_targets_affected)
	_execution_serial += 1
	var effect_seed := _run_controller.get_seed() + _execution_serial * 7919
	if not storm.initialize(
		source.global_position,
		definition,
		_run_controller,
		_targeting_system,
		effect_seed
	):
		storm.queue_free()
		return null
	_track_effect(storm)
	return storm


func _execute_area_effect(
	definition: AbilityDefinition,
	source: Node2D,
	mode: AbilityAreaEffect.AreaMode,
	effect_color: Color
) -> Node2D:
	var area := AbilityAreaEffect.new()
	area.name = "AbilityArea_%s" % definition.id
	_effect_parent.add_child(area)
	area.targets_affected.connect(_on_targets_affected)
	_execution_serial += 1
	var modifier_id := StringName("ability_%s_%d" % [definition.id, _execution_serial])
	if not area.initialize(
		mode,
		source.global_position,
		source,
		definition,
		_run_controller,
		_targeting_system,
		modifier_id,
		effect_color
	):
		area.queue_free()
		return null
	_track_effect(area)
	return area


func _execute_random_cosplay(
	definition: AbilityDefinition,
	source: Node2D
) -> Node2D:
	var candidates := _get_cosplay_candidates(definition)
	if candidates.is_empty():
		return null
	var selected := candidates[_rng.randi_range(0, candidates.size() - 1)]
	_last_copied_ability_id = selected.id
	return _execute_definition(selected, source, false)


func _execute_shadow_deception(
	definition: AbilityDefinition,
	source: Node2D
) -> Node2D:
	var illusion := IllusionDecoy.new()
	illusion.name = "IllusionDecoy"
	_effect_parent.add_child(illusion)
	illusion.targets_affected.connect(_on_targets_affected)
	if not illusion.initialize(
		source,
		definition,
		_run_controller,
		_targeting_system
	):
		illusion.queue_free()
		return null
	_track_effect(illusion)
	return illusion


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


func _get_cosplay_candidates(definition: AbilityDefinition) -> Array[AbilityDefinition]:
	var candidates: Array[AbilityDefinition] = []
	for candidate in get_compatible_definitions([COPY_COMPATIBLE], [definition.id]):
		if candidate.effect_id == RANDOM_COSPLAY or not _can_execute_non_copy(candidate):
			continue
		candidates.append(candidate)
	return candidates


func _can_execute_non_copy(definition: AbilityDefinition) -> bool:
	if definition == null or not definition.is_valid() or not _has_valid_dependencies():
		return false
	if not _run_controller.is_running():
		return false
	match definition.effect_id:
		EARTHQUAKE_SHOCKWAVE:
			return definition.area_radius > 0.0
		FIRE_Z_TRAIL:
			return (
				definition.duration_seconds > 0.0
				and definition.damage > 0.0
				and definition.get_effect_float(&"dash_distance", 0.0, 0.0) > 0.0
			)
		LIGHTNING_STORM:
			return (
				definition.damage > 0.0
				and int(definition.effect_parameters.get(&"strikes", 0)) > 0
			)
		GRAND_SPIN, CEMENT_POUR:
			return (
				definition.area_radius > 0.0
				and definition.duration_seconds > 0.0
				and definition.damage > 0.0
			)
		RANDOM_COSPLAY:
			return true
		ZEN_SLOWDOWN:
			return definition.area_radius > 0.0 and definition.duration_seconds > 0.0
		SHADOW_DECEPTION:
			return definition.duration_seconds > 0.0
	return false


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


func _track_effect(effect: Node2D) -> void:
	_active_effects.append(effect)
	effect.tree_exiting.connect(_on_effect_tree_exiting.bind(effect), CONNECT_ONE_SHOT)


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
	if not _run_controller.run_started.is_connected(_on_run_started):
		_run_controller.run_started.connect(_on_run_started)
	if not _run_controller.restart_prepared.is_connected(_on_restart_prepared):
		_run_controller.restart_prepared.connect(_on_restart_prepared)


func _disconnect_run_controller() -> void:
	if not is_instance_valid(_run_controller):
		_run_controller = null
		return
	if _run_controller.run_started.is_connected(_on_run_started):
		_run_controller.run_started.disconnect(_on_run_started)
	if _run_controller.restart_prepared.is_connected(_on_restart_prepared):
		_run_controller.restart_prepared.disconnect(_on_restart_prepared)
	_run_controller = null


func _on_run_started(seed_value: int) -> void:
	_rng.seed = seed_value if seed_value != 0 else 1
	_execution_serial = 0


func _on_restart_prepared() -> void:
	clear_active_effects()
	_execution_serial = 0


func _on_targets_affected(count: int) -> void:
	_last_affected_count = maxi(count, 0)


func _on_effect_tree_exiting(effect: Node2D) -> void:
	_active_effects.erase(effect)
