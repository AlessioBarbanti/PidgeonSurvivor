class_name EarthquakeWave
extends Node2D

signal finished(wave: EarthquakeWave)

const VISUAL_FAMILY_ID := &"earthquake_rings_and_cracks"
const VISUAL_PARTICLE_COUNT := 0
const VISUAL_MATERIAL_COUNT := 0

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
	draw_circle(Vector2.ZERO, visible_radius, Color(0.42, 0.2, 0.08, alpha * 0.16))
	for ring_index in 3:
		var ring_scale := 1.0 - float(ring_index) * 0.16
		var ring_alpha := alpha * (1.0 - float(ring_index) * 0.22)
		draw_arc(
			Vector2.ZERO,
			visible_radius * ring_scale,
			0.0,
			TAU,
			64,
			Color(1.0, 0.78 + float(ring_index) * 0.06, 0.22, ring_alpha),
			lerpf(9.0 - float(ring_index) * 2.0, 2.5, progress),
			true
		)
	for crack_index in 8:
		var direction := Vector2.RIGHT.rotated(TAU * float(crack_index) / 8.0 + 0.22)
		var tangent := direction.orthogonal()
		var bend_sign := -1.0 if crack_index % 2 == 0 else 1.0
		var start := direction * visible_radius * 0.28
		var middle := direction * visible_radius * 0.57 + tangent * visible_radius * 0.06 * bend_sign
		var end := direction * visible_radius * 0.88
		draw_polyline(
			PackedVector2Array([start, middle, end]),
			Color(1.0, 0.92, 0.62, alpha * 0.8),
			2.5,
			true
		)


func get_radius() -> float:
	return _radius


func get_elapsed() -> float:
	return _elapsed


func get_visual_family_id() -> StringName:
	return VISUAL_FAMILY_ID


func get_visual_particle_count() -> int:
	return VISUAL_PARTICLE_COUNT


func get_visual_material_count() -> int:
	return VISUAL_MATERIAL_COUNT


func uses_fullscreen_overlay() -> bool:
	return false
