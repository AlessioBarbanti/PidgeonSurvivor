class_name CosplayAccent
extends Node2D

const VISUAL_FAMILY_ID := &"cosplay_confetti_and_copied_palette"
const VISUAL_PARTICLE_COUNT := 18
const VISUAL_MATERIAL_COUNT := 0
const DEFAULT_DURATION_SECONDS := PresentationTimings.COSPLAY_ACCENT_SECONDS
const COSPLAY_REVEAL_TEXTURE := preload(
	"res://assets/art/vfx/abilities/generated/cosplay_reveal.png"
)

var _run_controller: RunController
var _palette := Color(0.95, 0.3, 0.72, 1.0)
var _duration_total := DEFAULT_DURATION_SECONDS
var _duration_remaining := DEFAULT_DURATION_SECONDS


func initialize(
	origin: Vector2,
	run_controller: RunController,
	palette: Color,
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
	_palette = palette
	_duration_total = duration_seconds
	_duration_remaining = duration_seconds
	top_level = true
	global_position = origin
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
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
	var progress := 1.0 - clampf(_duration_remaining / _duration_total, 0.0, 1.0)
	var elapsed := _duration_total - _duration_remaining
	var alpha := PresentationTimings.one_shot_opacity(
		elapsed,
		_duration_total,
		minf(PresentationTimings.ONE_SHOT_ENTRY_SECONDS, _duration_total * 0.25),
		minf(PresentationTimings.ONE_SHOT_EXIT_SECONDS, _duration_total * 0.4)
	)
	var burst_radius := lerpf(20.0, 82.0, progress)
	var decal_size := Vector2.ONE * burst_radius * 2.0
	draw_set_transform(Vector2.ZERO, progress * 0.42, Vector2.ONE)
	draw_texture_rect(
		COSPLAY_REVEAL_TEXTURE,
		Rect2(-decal_size * 0.5, decal_size),
		false,
		Color(1.0, 1.0, 1.0, alpha * 0.9)
	)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_arc(
		Vector2.ZERO,
		burst_radius * 0.72,
		0.0,
		TAU,
		40,
		Color(_palette, alpha * 0.54),
		4.0,
		true
	)
	for confetti_index in VISUAL_PARTICLE_COUNT:
		var angle := TAU * float(confetti_index) / float(VISUAL_PARTICLE_COUNT)
		angle += sin(float(confetti_index) * 1.73) * 0.18
		var distance := burst_radius * (0.62 + 0.34 * float((confetti_index % 4) + 1) / 4.0)
		var center := Vector2.RIGHT.rotated(angle) * distance
		center.y += progress * progress * 24.0
		var tangent := Vector2.RIGHT.rotated(angle + PI * 0.5 + progress * 5.0)
		var confetti_color := _palette.lightened(0.18) if confetti_index % 2 == 0 else Color(1.0, 0.84, 0.28, 1.0)
		draw_line(center - tangent * 4.0, center + tangent * 4.0, Color(confetti_color, alpha), 3.0, true)


func get_duration_remaining() -> float:
	return _duration_remaining


func get_duration_total() -> float:
	return _duration_total


func is_non_interactive_tail() -> bool:
	return true


func get_palette() -> Color:
	return _palette


func get_visual_family_id() -> StringName:
	return VISUAL_FAMILY_ID


func get_visual_particle_count() -> int:
	return VISUAL_PARTICLE_COUNT


func get_visual_material_count() -> int:
	return VISUAL_MATERIAL_COUNT


func get_visual_texture_path() -> String:
	return COSPLAY_REVEAL_TEXTURE.resource_path


func uses_fullscreen_overlay() -> bool:
	return false
