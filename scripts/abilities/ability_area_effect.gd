class_name AbilityAreaEffect
extends Node2D

signal finished(effect: AbilityAreaEffect)
signal targets_affected(count: int)

enum AreaMode {
	PULSE_DAMAGE,
	GROUND_SLOW_DAMAGE,
	FOLLOWING_SLOW,
}

var _mode := AreaMode.PULSE_DAMAGE
var _definition: AbilityDefinition
var _run_controller: RunController
var _targeting_system: TargetingSystem
var _source: Node2D
var _duration_remaining := 0.0
var _duration_total := 0.0
var _tick_interval := INF
var _tick_remaining := 0.0
var _tick_damage := 0.0
var _slow_factor := 1.0
var _modifier_id: StringName
var _slowed_targets: Array[BaseEnemy] = []
var _effect_color := Color(1.0, 0.7, 0.2, 0.7)
var _finished := false


func initialize(
	mode: AreaMode,
	origin: Vector2,
	source: Node2D,
	definition: AbilityDefinition,
	run_controller: RunController,
	targeting_system: TargetingSystem,
	modifier_id: StringName,
	effect_color: Color
) -> bool:
	if (
		definition == null
		or not definition.is_valid()
		or definition.area_radius <= 0.0
		or definition.duration_seconds <= 0.0
		or not is_instance_valid(run_controller)
		or not run_controller.is_running()
		or not is_instance_valid(targeting_system)
	):
		return false
	_mode = mode
	_definition = definition
	_run_controller = run_controller
	_targeting_system = targeting_system
	_source = source
	global_position = origin
	_duration_total = definition.duration_seconds
	_duration_remaining = _duration_total
	_modifier_id = modifier_id
	_effect_color = effect_color
	_tick_damage = definition.damage
	match _mode:
		AreaMode.PULSE_DAMAGE:
			var hits_per_second := definition.get_effect_float(
				&"hits_per_second",
				1.0,
				AbilityDefinition.MINIMUM_POSITIVE_VALUE
			)
			_tick_interval = 1.0 / hits_per_second
		AreaMode.GROUND_SLOW_DAMAGE:
			_tick_interval = definition.get_effect_float(
				&"dot_tick",
				0.5,
				AbilityDefinition.MINIMUM_POSITIVE_VALUE
			)
			_slow_factor = definition.get_effect_float(
				&"slow_factor",
				1.0,
				AbilityDefinition.MINIMUM_POSITIVE_VALUE
			)
		AreaMode.FOLLOWING_SLOW:
			_tick_interval = INF
			_tick_damage = 0.0
			_slow_factor = definition.get_effect_float(
				&"slow_factor",
				1.0,
				AbilityDefinition.MINIMUM_POSITIVE_VALUE
			)
	_refresh_slow_targets()
	if _tick_damage > 0.0:
		_apply_damage_tick()
	_tick_remaining = _tick_interval
	queue_redraw()
	return true


func _process(delta: float) -> void:
	if _finished or not is_instance_valid(_run_controller) or not _run_controller.is_running():
		return
	var safe_delta := maxf(delta, 0.0) if is_finite(delta) else 0.0
	if _mode == AreaMode.FOLLOWING_SLOW and is_instance_valid(_source):
		global_position = _source.global_position
	if _mode in [AreaMode.GROUND_SLOW_DAMAGE, AreaMode.FOLLOWING_SLOW]:
		_refresh_slow_targets()
	if is_finite(_tick_interval) and _tick_damage > 0.0:
		_tick_remaining -= safe_delta
		while _tick_remaining <= 0.0 and _duration_remaining > 0.0:
			_apply_damage_tick()
			_tick_remaining += _tick_interval
	_duration_remaining = maxf(_duration_remaining - safe_delta, 0.0)
	queue_redraw()
	if _duration_remaining <= 0.0:
		_finish()


func _draw() -> void:
	if _definition == null:
		return
	var progress := 1.0 - clampf(_duration_remaining / _duration_total, 0.0, 1.0)
	var fill := _effect_color
	fill.a *= 0.1 + sin(progress * PI) * 0.05
	draw_circle(Vector2.ZERO, _definition.area_radius, fill)
	draw_arc(
		Vector2.ZERO,
		_definition.area_radius,
		0.0,
		TAU,
		64,
		Color(_effect_color, 0.82),
		4.0,
		true
	)
	_draw_mode_pattern(progress)


func _draw_mode_pattern(progress: float) -> void:
	var radius := _definition.area_radius
	var pattern_color := Color(_effect_color, 0.32)
	match _mode:
		AreaMode.PULSE_DAMAGE:
			for spoke_index in 8:
				var direction := Vector2.RIGHT.rotated(TAU * float(spoke_index) / 8.0 + progress)
				draw_line(
					direction * radius * 0.34,
					direction * radius * 0.86,
					pattern_color,
					3.0,
					true
				)
		AreaMode.GROUND_SLOW_DAMAGE:
			for band_index in range(-3, 4):
				var y := float(band_index) * radius * 0.22
				var half_width := sqrt(maxf(radius * radius - y * y, 0.0)) * 0.82
				draw_line(
					Vector2(-half_width, y - radius * 0.08),
					Vector2(half_width, y + radius * 0.08),
					pattern_color,
					4.0,
					true
				)
		AreaMode.FOLLOWING_SLOW:
			for ring_scale in [0.34, 0.62, 0.88]:
				for segment_index in 12:
					if segment_index % 2 == 0:
						continue
					var start_angle := TAU * float(segment_index) / 12.0 - progress
					draw_arc(
						Vector2.ZERO,
						radius * float(ring_scale),
						start_angle,
						start_angle + TAU / 24.0,
						4,
						pattern_color,
						3.0,
						true
					)


func get_duration_remaining() -> float:
	return _duration_remaining


func get_mode() -> AreaMode:
	return _mode


func _apply_damage_tick() -> void:
	var affected := 0
	for target in _targeting_system.get_alive_targets():
		if not AbilityEffectRegistry.is_point_within_radius(
			global_position,
			target.global_position,
			_definition.area_radius
		):
			continue
		if target.take_damage(_tick_damage):
			affected += 1
	targets_affected.emit(affected)


func _refresh_slow_targets() -> void:
	if _slow_factor >= 1.0 or _modifier_id.is_empty():
		return
	var inside: Array[BaseEnemy] = []
	for target in _targeting_system.get_alive_targets():
		if AbilityEffectRegistry.is_point_within_radius(
			global_position,
			target.global_position,
			_definition.area_radius
		):
			target.set_speed_modifier(_modifier_id, _slow_factor)
			inside.append(target)
	for target in _slowed_targets:
		if is_instance_valid(target) and not target in inside:
			target.remove_speed_modifier(_modifier_id)
	_slowed_targets = inside
	targets_affected.emit(_slowed_targets.size())


func _clear_slow_targets() -> void:
	for target in _slowed_targets:
		if is_instance_valid(target):
			target.remove_speed_modifier(_modifier_id)
	_slowed_targets.clear()


func _finish() -> void:
	if _finished:
		return
	_finished = true
	_clear_slow_targets()
	finished.emit(self)
	queue_free()


func _exit_tree() -> void:
	_clear_slow_targets()
