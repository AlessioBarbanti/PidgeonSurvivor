class_name FireZTrail
extends Node2D

signal finished(effect: FireZTrail)
signal targets_affected(count: int)

var _definition: AbilityDefinition
var _run_controller: RunController
var _targeting_system: TargetingSystem
var _points: PackedVector2Array = []
var _trail_width := 36.0
var _duration_total := 0.0
var _duration_remaining := 0.0
var _tick_interval := 0.25
var _tick_remaining := 0.0
var _finished := false


func initialize(
	source: Player,
	definition: AbilityDefinition,
	run_controller: RunController,
	targeting_system: TargetingSystem,
	arena_layout: ArenaLayout
) -> bool:
	if (
		not is_instance_valid(source)
		or definition == null
		or not definition.is_valid()
		or not is_instance_valid(run_controller)
		or not run_controller.is_running()
		or not is_instance_valid(targeting_system)
	):
		return false
	_definition = definition
	_run_controller = run_controller
	_targeting_system = targeting_system
	_duration_total = definition.get_effect_float(
		&"trail_duration",
		definition.duration_seconds,
		AbilityDefinition.MINIMUM_POSITIVE_VALUE
	)
	_duration_remaining = _duration_total
	_tick_interval = definition.get_effect_float(
		&"trail_tick_interval",
		0.25,
		AbilityDefinition.MINIMUM_POSITIVE_VALUE
	)
	_trail_width = definition.get_effect_float(&"trail_width", 36.0, 1.0)
	var dash_distance := definition.get_effect_float(&"dash_distance", 320.0, 1.0)
	var zigzag_width := definition.get_effect_float(&"zigzag_width", 120.0, 0.0)
	var direction := source.movement_input.normalized()
	if direction.is_zero_approx():
		direction = Vector2.RIGHT
	var perpendicular := direction.orthogonal()
	var origin := source.global_position
	var desired_end := origin + direction * dash_distance
	var actual_end := desired_end
	if is_instance_valid(arena_layout):
		actual_end = arena_layout.clamp_circle_center(desired_end, source.collision_radius)
	var actual_forward := actual_end - origin
	_points = PackedVector2Array([
		origin,
		origin + actual_forward * 0.28 + perpendicular * zigzag_width * 0.5,
		origin + actual_forward * 0.72 - perpendicular * zigzag_width * 0.5,
		actual_end,
	])
	source.global_position = actual_end
	global_position = Vector2.ZERO
	_apply_damage_tick()
	_tick_remaining = _tick_interval
	queue_redraw()
	return true


func _process(delta: float) -> void:
	if _finished or not is_instance_valid(_run_controller) or not _run_controller.is_running():
		return
	var safe_delta := maxf(delta, 0.0) if is_finite(delta) else 0.0
	_tick_remaining -= safe_delta
	while _tick_remaining <= 0.0 and _duration_remaining > 0.0:
		_apply_damage_tick()
		_tick_remaining += _tick_interval
	_duration_remaining = maxf(_duration_remaining - safe_delta, 0.0)
	queue_redraw()
	if _duration_remaining <= 0.0:
		_finished = true
		finished.emit(self)
		queue_free()


func _draw() -> void:
	if _points.size() < 2 or _duration_total <= 0.0:
		return
	var alpha := clampf(_duration_remaining / _duration_total, 0.0, 1.0)
	draw_polyline(_points, Color(1.0, 0.15, 0.02, alpha * 0.35), _trail_width, true)
	draw_polyline(_points, Color(1.0, 0.74, 0.08, alpha), maxf(_trail_width * 0.24, 3.0), true)


func get_points() -> PackedVector2Array:
	return _points.duplicate()


func get_duration_remaining() -> float:
	return _duration_remaining


func _apply_damage_tick() -> void:
	var affected := 0
	for target in _targeting_system.get_alive_targets():
		if not _is_point_near_trail(target.global_position):
			continue
		if target.take_damage(_definition.damage):
			affected += 1
	targets_affected.emit(affected)


func _is_point_near_trail(point: Vector2) -> bool:
	for index in range(_points.size() - 1):
		if Geometry2D.get_closest_point_to_segment(
			point,
			_points[index],
			_points[index + 1]
		).distance_to(point) <= _trail_width * 0.5:
			return true
	return false
