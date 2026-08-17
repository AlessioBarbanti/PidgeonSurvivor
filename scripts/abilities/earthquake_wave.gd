class_name EarthquakeWave
extends Node2D

signal finished(wave: EarthquakeWave)

var _run_controller: RunController
var _radius := 0.0
var _duration := 0.25
var _elapsed := 0.0
var _finished := false


func initialize(
	origin: Vector2,
	radius: float,
	duration: float,
	run_controller: RunController
) -> bool:
	if (
		not is_instance_valid(run_controller)
		or not run_controller.is_running()
		or not is_finite(radius)
		or radius <= 0.0
		or not is_finite(duration)
		or duration <= 0.0
	):
		return false

	global_position = origin
	_radius = radius
	_duration = duration
	_run_controller = run_controller
	_elapsed = 0.0
	_finished = false
	queue_redraw()
	return true


func _process(delta: float) -> void:
	if _finished or not is_instance_valid(_run_controller):
		return
	if not _run_controller.is_running():
		return

	_elapsed = minf(_elapsed + maxf(delta, 0.0), _duration)
	queue_redraw()
	if _elapsed >= _duration:
		_finished = true
		finished.emit(self)
		queue_free()


func _draw() -> void:
	if _radius <= 0.0 or _duration <= 0.0:
		return
	var progress := clampf(_elapsed / _duration, 0.0, 1.0)
	var visible_radius := lerpf(_radius * 0.12, _radius, progress)
	var alpha := lerpf(0.9, 0.0, progress)
	draw_circle(Vector2.ZERO, visible_radius, Color(0.95, 0.58, 0.12, alpha * 0.12))
	draw_arc(
		Vector2.ZERO,
		visible_radius,
		0.0,
		TAU,
		64,
		Color(1.0, 0.82, 0.25, alpha),
		lerpf(10.0, 3.0, progress),
		true
	)
	for crack_index in 6:
		var direction := Vector2.RIGHT.rotated(TAU * float(crack_index) / 6.0 + 0.22)
		var tangent := direction.orthogonal()
		var start := direction * visible_radius * 0.38
		var middle := direction * visible_radius * 0.62 + tangent * visible_radius * 0.07
		var end := direction * visible_radius * 0.88
		draw_polyline(
			PackedVector2Array([start, middle, end]),
			Color(1.0, 0.94, 0.7, alpha * 0.72),
			2.5,
			true
		)


func get_radius() -> float:
	return _radius


func get_elapsed() -> float:
	return _elapsed
