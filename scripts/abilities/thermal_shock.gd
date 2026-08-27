class_name ThermalShock
extends Node2D

signal finished(effect: ThermalShock)
signal targets_affected(count: int)
signal detonated(frosted_count: int)

enum Phase {
	FROST,
	BLOOM,
	FINISHED,
}

const DEFAULT_SLOW_FACTOR := 0.45
const DEFAULT_SHOCK_MULTIPLIER := 2.0
const DEFAULT_BLOOM_SECONDS := 0.35
const VISUAL_FAMILY_ID := &"thermal_shock_frost_ring_and_bloom"
const VISUAL_PARTICLE_COUNT := 12
const VISUAL_MATERIAL_COUNT := 0
const FROST_COLOR := Color(0.55, 0.86, 1.0, 0.72)
const FROST_CORE_COLOR := Color(0.82, 0.95, 1.0, 0.34)
const BLOOM_COLOR := Color(1.0, 0.52, 0.18, 0.82)

var _definition: AbilityDefinition
var _run_controller: RunController
var _targeting_system: TargetingSystem
var _modifier_id: StringName
var _phase := Phase.FROST
var _phase_remaining := 0.0
var _phase_duration := 0.0
var _slow_factor := DEFAULT_SLOW_FACTOR
var _shock_multiplier := DEFAULT_SHOCK_MULTIPLIER
var _bloom_seconds := DEFAULT_BLOOM_SECONDS
var _frosted_targets: Array[BaseEnemy] = []
var _affected_count := 0
var _frosted_on_detonation := 0
var _detonated := false


func initialize(
	origin: Vector2,
	definition: AbilityDefinition,
	run_controller: RunController,
	targeting_system: TargetingSystem,
	modifier_id: StringName
) -> bool:
	if (
		definition == null
		or not definition.is_valid()
		or definition.area_radius <= 0.0
		or definition.duration_seconds <= 0.0
		or definition.damage <= 0.0
		or String(modifier_id).is_empty()
		or not is_instance_valid(run_controller)
		or not run_controller.is_running()
		or not is_instance_valid(targeting_system)
	):
		return false
	_definition = definition
	_run_controller = run_controller
	_targeting_system = targeting_system
	_modifier_id = modifier_id
	global_position = origin
	_slow_factor = definition.get_effect_float(
		&"slow_factor",
		DEFAULT_SLOW_FACTOR,
		AbilityDefinition.MINIMUM_POSITIVE_VALUE
	)
	_shock_multiplier = definition.get_effect_float(
		&"shock_multiplier",
		DEFAULT_SHOCK_MULTIPLIER,
		1.0
	)
	_bloom_seconds = definition.get_effect_float(
		&"bloom_seconds",
		DEFAULT_BLOOM_SECONDS,
		AbilityDefinition.MINIMUM_POSITIVE_VALUE
	)
	_set_phase(Phase.FROST, definition.duration_seconds)
	_refresh_frost_targets()
	queue_redraw()
	return true


func _process(delta: float) -> void:
	if (
		_phase == Phase.FINISHED
		or not is_instance_valid(_run_controller)
		or not _run_controller.is_running()
	):
		return
	var remaining_delta := maxf(delta, 0.0) if is_finite(delta) else 0.0
	while remaining_delta > 0.0 and _phase != Phase.FINISHED:
		if _phase == Phase.FROST:
			_refresh_frost_targets()
		if _phase_remaining > remaining_delta:
			_phase_remaining -= remaining_delta
			remaining_delta = 0.0
		else:
			remaining_delta -= _phase_remaining
			_phase_remaining = 0.0
			_advance_phase()
	queue_redraw()


func _exit_tree() -> void:
	_clear_frost_targets()


func _draw() -> void:
	match _phase:
		Phase.FROST:
			_draw_frost_field()
		Phase.BLOOM:
			_draw_heat_bloom()


func get_phase() -> Phase:
	return _phase


func get_phase_remaining() -> float:
	return _phase_remaining


func get_frost_remaining() -> float:
	return _phase_remaining if _phase == Phase.FROST else 0.0


func get_frosted_count() -> int:
	return _frosted_targets.size()


func get_frosted_on_detonation() -> int:
	return _frosted_on_detonation


func get_affected_count() -> int:
	return _affected_count


func has_detonated() -> bool:
	return _detonated


func get_visual_family_id() -> StringName:
	return VISUAL_FAMILY_ID


func get_visual_particle_count() -> int:
	return VISUAL_PARTICLE_COUNT


func get_visual_material_count() -> int:
	return VISUAL_MATERIAL_COUNT


func get_visual_extent() -> float:
	return _definition.area_radius if _definition != null else 0.0


func uses_fullscreen_overlay() -> bool:
	return false


func _advance_phase() -> void:
	match _phase:
		Phase.FROST:
			_detonate()
			_set_phase(Phase.BLOOM, _bloom_seconds)
		Phase.BLOOM:
			_finish()


func _refresh_frost_targets() -> void:
	if _slow_factor >= 1.0:
		return
	var inside: Array[BaseEnemy] = []
	for target in _targeting_system.get_alive_targets():
		if not AbilityEffectRegistry.is_point_within_radius(
			global_position,
			target.global_position,
			_definition.area_radius
		):
			continue
		target.set_speed_modifier(_modifier_id, _slow_factor)
		inside.append(target)
	for target in _frosted_targets:
		if is_instance_valid(target) and not target in inside:
			target.remove_speed_modifier(_modifier_id)
	_frosted_targets = inside
	targets_affected.emit(_frosted_targets.size())


func _detonate() -> void:
	if _detonated:
		return
	_detonated = true
	_refresh_frost_targets()
	var frosted_ids: Dictionary = {}
	for target in _frosted_targets:
		if is_instance_valid(target):
			frosted_ids[target.get_instance_id()] = true
	_frosted_on_detonation = frosted_ids.size()
	_affected_count = 0
	for target in _targeting_system.get_alive_targets():
		if not AbilityEffectRegistry.is_point_within_radius(
			global_position,
			target.global_position,
			_definition.area_radius
		):
			continue
		var damage := _definition.damage
		if frosted_ids.has(target.get_instance_id()):
			damage *= _shock_multiplier
		if target.take_damage(damage):
			_affected_count += 1
	_clear_frost_targets()
	detonated.emit(_frosted_on_detonation)
	targets_affected.emit(_affected_count)


func _set_phase(next_phase: Phase, duration: float) -> void:
	_phase = next_phase
	_phase_duration = maxf(duration, 0.0)
	_phase_remaining = _phase_duration


func _safe_phase_ratio() -> float:
	if _phase_duration <= 0.0:
		return 0.0
	return clampf(_phase_remaining / _phase_duration, 0.0, 1.0)


func _draw_frost_field() -> void:
	var radius := _definition.area_radius
	var progress := 1.0 - _safe_phase_ratio()
	draw_circle(Vector2.ZERO, radius, FROST_CORE_COLOR)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, FROST_COLOR, 4.0, true)
	# La corona si contrae verso il centro: telegrafa l'istante della detonazione.
	draw_arc(
		Vector2.ZERO,
		radius * lerpf(0.92, 0.24, progress),
		0.0,
		TAU,
		36,
		Color(FROST_COLOR, 0.5 + progress * 0.4),
		3.0,
		true
	)
	for shard_index in VISUAL_PARTICLE_COUNT:
		var angle := TAU * float(shard_index) / float(VISUAL_PARTICLE_COUNT)
		var direction := Vector2.RIGHT.rotated(angle)
		var shard_distance := radius * lerpf(0.86, 0.34, progress)
		var shard_center := direction * shard_distance
		var shard_length := 9.0 + progress * 5.0
		draw_line(
			shard_center - direction * shard_length,
			shard_center + direction * shard_length,
			Color(0.9, 0.98, 1.0, 0.5 + progress * 0.35),
			2.0,
			true
		)


func _draw_heat_bloom() -> void:
	var radius := _definition.area_radius
	var fade := _safe_phase_ratio()
	draw_circle(Vector2.ZERO, radius * (1.0 - fade * 0.18), Color(BLOOM_COLOR, 0.28 * fade))
	for ring_index in range(3):
		draw_arc(
			Vector2.ZERO,
			radius * (0.45 + float(ring_index) * 0.27),
			0.0,
			TAU,
			40,
			Color(BLOOM_COLOR, fade * (0.85 - float(ring_index) * 0.22)),
			4.0,
			true
		)


func _clear_frost_targets() -> void:
	for target in _frosted_targets:
		if is_instance_valid(target):
			target.remove_speed_modifier(_modifier_id)
	_frosted_targets.clear()


func _finish() -> void:
	if _phase == Phase.FINISHED:
		return
	_set_phase(Phase.FINISHED, 0.0)
	_clear_frost_targets()
	queue_redraw()
	finished.emit(self)
	queue_free()
