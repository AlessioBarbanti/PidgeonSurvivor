class_name DamageShockwave
extends Node2D

signal finished(pulse: DamageShockwave)

@export var ring_color := Color(1.0, 0.72, 0.18, 0.78)
@export var inner_ring_color := Color(0.25, 0.85, 1.0, 0.52)

var _run_controller: RunController
var _radius := 0.0
var _duration := 0.0
var _elapsed := 0.0
var _finished := false


func initialize(
	world_position: Vector2,
	radius: float,
	duration: float,
	run_controller: RunController
) -> bool:
	if (
		not world_position.is_finite()
		or not is_finite(radius)
		or radius <= 0.0
		or not is_finite(duration)
		or duration <= 0.0
		or not is_instance_valid(run_controller)
	):
		return false
	global_position = world_position
	_radius = radius
	_duration = duration
	_run_controller = run_controller
	_elapsed = 0.0
	_finished = false
	queue_redraw()
	return true


func _process(delta: float) -> void:
	if (
		_finished
		or not is_instance_valid(_run_controller)
		or not _run_controller.is_running()
	):
		return
	_elapsed = minf(_elapsed + maxf(delta, 0.0), _duration)
	queue_redraw()
	if _elapsed >= _duration:
		finish()


func _draw() -> void:
	if _duration <= 0.0:
		return
	var progress := clampf(_elapsed / _duration, 0.0, 1.0)
	var visible_radius := _radius * ease(progress, -1.8)
	var alpha := 1.0 - progress
	draw_arc(
		Vector2.ZERO,
		maxf(visible_radius, 1.0),
		0.0,
		TAU,
		72,
		Color(ring_color, ring_color.a * alpha),
		maxf(8.0 * alpha, 2.0),
		true
	)
	draw_arc(
		Vector2.ZERO,
		maxf(visible_radius * 0.72, 1.0),
		0.0,
		TAU,
		72,
		Color(inner_ring_color, inner_ring_color.a * alpha),
		maxf(4.0 * alpha, 1.0),
		true
	)


func finish() -> void:
	if _finished:
		return
	_finished = true
	set_process(false)
	visible = false
	finished.emit(self)
	queue_free()


func get_progress() -> float:
	return clampf(_elapsed / _duration, 0.0, 1.0) if _duration > 0.0 else 0.0


func is_finished() -> bool:
	return _finished
