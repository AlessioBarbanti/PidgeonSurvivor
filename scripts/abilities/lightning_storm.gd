class_name LightningStorm
extends Node2D

signal finished(effect: LightningStorm)
signal targets_affected(count: int)

var _definition: AbilityDefinition
var _run_controller: RunController
var _targeting_system: TargetingSystem
var _origin := Vector2.ZERO
var _rng := RandomNumberGenerator.new()
var _strikes_remaining := 0
var _strike_interval := 0.08
var _strike_remaining := 0.0
var _visual_remaining := 0.0
var _last_target_positions: PackedVector2Array = []
var _finished := false


func initialize(
	origin: Vector2,
	definition: AbilityDefinition,
	run_controller: RunController,
	targeting_system: TargetingSystem,
	seed_value: int
) -> bool:
	if (
		definition == null
		or not definition.is_valid()
		or not is_instance_valid(run_controller)
		or not run_controller.is_running()
		or not is_instance_valid(targeting_system)
	):
		return false
	_definition = definition
	_run_controller = run_controller
	_targeting_system = targeting_system
	_origin = origin
	global_position = Vector2.ZERO
	_rng.seed = seed_value if seed_value != 0 else 1
	_strikes_remaining = maxi(int(definition.effect_parameters.get(&"strikes", 6)), 1)
	_strike_interval = definition.get_effect_float(
		&"strike_interval",
		0.08,
		AbilityDefinition.MINIMUM_POSITIVE_VALUE
	)
	_execute_strike()
	_strike_remaining = _strike_interval
	return true


func _process(delta: float) -> void:
	if _finished or not is_instance_valid(_run_controller) or not _run_controller.is_running():
		return
	var safe_delta := maxf(delta, 0.0) if is_finite(delta) else 0.0
	_visual_remaining = maxf(_visual_remaining - safe_delta, 0.0)
	if _strikes_remaining > 0:
		_strike_remaining -= safe_delta
		while _strike_remaining <= 0.0 and _strikes_remaining > 0:
			_execute_strike()
			_strike_remaining += _strike_interval
	queue_redraw()
	if _strikes_remaining <= 0 and _visual_remaining <= 0.0:
		_finished = true
		finished.emit(self)
		queue_free()


func _draw() -> void:
	if _visual_remaining <= 0.0:
		return
	for target_position in _last_target_positions:
		_draw_bolt(_origin, target_position)
		draw_circle(target_position, 15.0, Color(0.85, 0.95, 1.0, 0.55))
		draw_arc(target_position, 22.0, 0.0, TAU, 24, Color(1.0, 0.92, 0.3, 0.8), 3.0, true)


func _draw_bolt(start: Vector2, end: Vector2) -> void:
	var offset := end - start
	if offset.is_zero_approx():
		return
	var normal := offset.normalized().orthogonal()
	var points := PackedVector2Array([start])
	for point_index in range(1, 6):
		var ratio := float(point_index) / 6.0
		var zigzag := (1.0 if point_index % 2 == 0 else -1.0) * 11.0
		points.append(start + offset * ratio + normal * zigzag)
	points.append(end)
	draw_polyline(points, Color(0.15, 0.55, 0.95, 0.72), 8.0, true)
	draw_polyline(points, Color(0.92, 0.98, 1.0, 1.0), 3.0, true)


func get_strikes_remaining() -> int:
	return _strikes_remaining


func _execute_strike() -> void:
	if _strikes_remaining <= 0:
		return
	_strikes_remaining -= 1
	var radius := _definition.get_effect_float(&"targeting_radius", 800.0, 0.0)
	var candidates: Array[BaseEnemy] = []
	for target in _targeting_system.get_alive_targets():
		if AbilityEffectRegistry.is_point_within_radius(
			_origin,
			target.global_position,
			radius
		):
			candidates.append(target)
	if candidates.is_empty():
		targets_affected.emit(0)
		return
	var target := candidates[_rng.randi_range(0, candidates.size() - 1)]
	var affected := 1 if target.take_damage(_definition.damage) else 0
	_last_target_positions = PackedVector2Array([target.global_position])
	_visual_remaining = 0.16
	queue_redraw()
	targets_affected.emit(affected)
