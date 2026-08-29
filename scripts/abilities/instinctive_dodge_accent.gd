class_name InstinctiveDodgeAccent
extends Node2D

## Tell one-shot del Sesto Senso Equino di Bea (B45): sagoma a ferro di
## cavallo davanti al Player e scia viola lungo la direzione dello scarto.
## Stesso schema di CosplayAccent/AbilityIconBurst: nodo autosufficiente,
## procedurale, si distrugge da solo a fine durata.

const VISUAL_FAMILY_ID := &"bea_instinctive_dodge_horseshoe_and_trail"
const VISUAL_PARTICLE_COUNT := 6
const VISUAL_MATERIAL_COUNT := 0
const DEFAULT_DURATION_SECONDS := PresentationTimings.INSTINCTIVE_DODGE_ACCENT_SECONDS
const TRAIL_COLOR := Color(0.62, 0.32, 0.98, 1.0)
const HORSESHOE_COLOR := Color(0.8, 0.6, 1.0, 1.0)

var _run_controller: RunController
var _direction := Vector2.RIGHT
var _duration_total := DEFAULT_DURATION_SECONDS
var _duration_remaining := DEFAULT_DURATION_SECONDS


func initialize(
	origin: Vector2,
	direction: Vector2,
	run_controller: RunController,
	duration_seconds: float = DEFAULT_DURATION_SECONDS
) -> bool:
	if (
		not origin.is_finite()
		or not is_instance_valid(run_controller)
		or not run_controller.is_running()
		or not is_finite(duration_seconds)
		or duration_seconds <= 0.0
	):
		return false
	_run_controller = run_controller
	_direction = (
		direction.normalized()
		if direction.is_finite() and not direction.is_zero_approx()
		else Vector2.RIGHT
	)
	_duration_total = duration_seconds
	_duration_remaining = duration_seconds
	top_level = true
	global_position = origin
	rotation = _direction.angle()
	queue_redraw()
	return true


func _process(delta: float) -> void:
	if not is_instance_valid(_run_controller) or not _run_controller.is_running():
		return
	_duration_remaining = maxf(
		_duration_remaining - (maxf(delta, 0.0) if is_finite(delta) else 0.0),
		0.0
	)
	queue_redraw()
	if _duration_remaining <= 0.0:
		queue_free()


func _draw() -> void:
	var elapsed := _duration_total - _duration_remaining
	var alpha := PresentationTimings.one_shot_opacity(
		elapsed,
		_duration_total,
		minf(PresentationTimings.ONE_SHOT_ENTRY_SECONDS, _duration_total * 0.2),
		minf(PresentationTimings.ONE_SHOT_EXIT_SECONDS, _duration_total * 0.5)
	)
	var progress := 1.0 - clampf(_duration_remaining / _duration_total, 0.0, 1.0)
	# Rotation allinea l'asse -X locale alla direzione dello scarto: la scia
	# resta dietro al punto di origine per costruzione.
	var trail_length := lerpf(10.0, 62.0, progress)
	draw_line(
		Vector2.ZERO,
		Vector2(-trail_length, 0.0),
		Color(TRAIL_COLOR, alpha * 0.7),
		6.0,
		true
	)
	for spark_index in VISUAL_PARTICLE_COUNT:
		var spark_offset := -trail_length * float(spark_index) / float(VISUAL_PARTICLE_COUNT)
		var spark_spread := sin(float(spark_index) * 2.1 + progress * TAU) * 5.0
		draw_circle(
			Vector2(spark_offset, spark_spread),
			2.5,
			Color(TRAIL_COLOR.lightened(0.2), alpha * 0.6)
		)
	var horseshoe_center := Vector2(18.0, 0.0)
	draw_arc(horseshoe_center, 12.0, PI * 0.25, PI * 1.75, 20, Color(HORSESHOE_COLOR, alpha), 4.0, true)


func get_duration_remaining() -> float:
	return _duration_remaining


func get_duration_total() -> float:
	return _duration_total


func is_non_interactive_tail() -> bool:
	return true


func get_direction() -> Vector2:
	return _direction


func get_visual_family_id() -> StringName:
	return VISUAL_FAMILY_ID


func get_visual_particle_count() -> int:
	return VISUAL_PARTICLE_COUNT


func get_visual_material_count() -> int:
	return VISUAL_MATERIAL_COUNT


func uses_fullscreen_overlay() -> bool:
	return false
