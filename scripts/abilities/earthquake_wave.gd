class_name EarthquakeWave
extends Node2D

signal finished(wave: EarthquakeWave)

const VISUAL_FAMILY_ID := &"earthquake_rings_and_cracks"
const VISUAL_PARTICLE_COUNT := 0
const VISUAL_MATERIAL_COUNT := 0
const EARTHQUAKE_WAVE_TEXTURE := preload(
	"res://assets/art/vfx/abilities/generated/earthquake_wave.png"
)
## Frazione della durata visiva entro cui il fronte raggiunge il raggio pieno.
const EXPANSION_PROGRESS := 0.15
## Frazione oltre la quale la coda comincia a dissolversi.
const FADE_START_PROGRESS := 0.22
## Il decal e' pittorico e pieno al centro: tetto di opacita' sul Player.
const MAX_DECAL_ALPHA := 0.62
## Il bordo resta piu' leggibile del decal perche' e' il telegraph autorevole.
const BORDER_ALPHA := 0.85

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
	# Il master tellurico e' pittorico, non pixel-art: con nearest un rescale
	# non intero (raggio*2/512) produce aliasing durante l'espansione.
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
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
	# L'onda raggiunge il raggio pieno entro EXPANSION_PROGRESS: danno,
	# knockback e stun sono applicati all'istante zero, quindi l'espansione
	# visiva deve chiudersi subito e non far volare i nemici prima del fronte.
	var expansion := smoothstep(0.0, EXPANSION_PROGRESS, progress)
	var visible_radius := lerpf(_radius * 0.12, _radius, expansion)
	var fade_progress := clampf(
		(progress - FADE_START_PROGRESS) / (1.0 - FADE_START_PROGRESS),
		0.0,
		1.0
	)
	var fade := 1.0 - fade_progress
	var decal_size := Vector2.ONE * visible_radius * 2.0
	# Il decal tellurico non ha centro aperto: resta sotto MAX_DECAL_ALPHA per
	# non coprire il Player, che deve continuare a schivare durante la coda.
	draw_texture_rect(
		EARTHQUAKE_WAVE_TEXTURE,
		Rect2(-decal_size * 0.5, decal_size),
		false,
		Color(1.0, 1.0, 1.0, fade * MAX_DECAL_ALPHA)
	)
	# Il bordo procedurale resta il telegraph geometrico autorevole: il decal
	# migliora la resa senza suggerire una collisione piu' ampia del raggio.
	draw_arc(
		Vector2.ZERO,
		visible_radius,
		0.0,
		TAU,
		64,
		Color(1.0, 0.86, 0.42, fade * BORDER_ALPHA),
		lerpf(5.0, 2.0, progress),
		true
	)


func get_radius() -> float:
	return _radius


func get_elapsed() -> float:
	return _elapsed


func get_duration_total() -> float:
	return _duration


func get_duration_remaining() -> float:
	return maxf(_duration - _elapsed, 0.0)


func is_non_interactive_tail() -> bool:
	return true


func get_visual_family_id() -> StringName:
	return VISUAL_FAMILY_ID


func get_visual_particle_count() -> int:
	return VISUAL_PARTICLE_COUNT


func get_visual_material_count() -> int:
	return VISUAL_MATERIAL_COUNT


func get_visual_texture_path() -> String:
	return EARTHQUAKE_WAVE_TEXTURE.resource_path


func uses_fullscreen_overlay() -> bool:
	return false
