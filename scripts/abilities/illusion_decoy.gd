class_name IllusionDecoy
extends Node2D

signal finished(effect: IllusionDecoy)
signal targets_affected(count: int)

const VISUAL_FAMILY_ID := &"reggeton_clone_speaker_and_notes"
const VISUAL_PARTICLE_COUNT := 6
const VISUAL_MATERIAL_COUNT := 0

var _definition: AbilityDefinition
var _run_controller: RunController
var _targeting_system: TargetingSystem
var _source: Node2D
var _duration_total := 0.0
var _duration_remaining := 0.0
var _previous_targets: Dictionary = {}
var _finished := false


func initialize(
	source: Node2D,
	definition: AbilityDefinition,
	run_controller: RunController,
	targeting_system: TargetingSystem
) -> bool:
	if (
		not is_instance_valid(source)
		or definition == null
		or not definition.is_valid()
		or definition.duration_seconds <= 0.0
		or not is_instance_valid(run_controller)
		or not run_controller.is_running()
		or not is_instance_valid(targeting_system)
	):
		return false
	_source = source
	_definition = definition
	_run_controller = run_controller
	_targeting_system = targeting_system
	global_position = source.global_position
	_duration_total = definition.duration_seconds
	_duration_remaining = _duration_total
	_redirect_targets()
	queue_redraw()
	return true


func _process(delta: float) -> void:
	if _finished or not is_instance_valid(_run_controller) or not _run_controller.is_running():
		return
	_redirect_targets()
	_duration_remaining = maxf(
		_duration_remaining - (maxf(delta, 0.0) if is_finite(delta) else 0.0),
		0.0
	)
	queue_redraw()
	if _duration_remaining <= 0.0:
		_finish()


func _draw() -> void:
	var alpha := clampf(_duration_remaining / _duration_total, 0.0, 1.0)
	var elapsed := maxf(_duration_total - _duration_remaining, 0.0)
	var beat := (sin(elapsed * TAU * 2.0) + 1.0) * 0.5
	var sway := sin(elapsed * TAU * 1.5) * 3.0
	var glow_color := Color(0.95, 0.18, 0.72, alpha * (0.18 + beat * 0.12))
	var line_color := Color(1.0, 0.78, 0.25, alpha)
	draw_circle(Vector2.ZERO, 27.0 + beat * 4.0, glow_color)
	draw_arc(
		Vector2.ZERO,
		23.0 + beat * 3.0,
		0.0,
		TAU,
		32,
		Color(0.3, 0.9, 1.0, alpha),
		3.0,
		true
	)
	# Clone ballerino e cassa pulsante: solo presentazione, l'aggro resta invariato.
	var dancer_origin := Vector2(-7.0 + sway, 1.0)
	draw_circle(dancer_origin + Vector2(0.0, -12.0), 4.5, line_color)
	draw_line(dancer_origin + Vector2(0.0, -7.0), dancer_origin + Vector2(0.0, 7.0), line_color, 3.0, true)
	draw_line(dancer_origin + Vector2(0.0, -3.0), dancer_origin + Vector2(-8.0, 2.0 - sway), line_color, 3.0, true)
	draw_line(dancer_origin + Vector2(0.0, -3.0), dancer_origin + Vector2(8.0, -7.0 + sway), line_color, 3.0, true)
	draw_line(dancer_origin + Vector2(0.0, 7.0), dancer_origin + Vector2(-6.0, 15.0), line_color, 3.0, true)
	draw_line(dancer_origin + Vector2(0.0, 7.0), dancer_origin + Vector2(7.0, 13.0), line_color, 3.0, true)
	var speaker_rect := Rect2(Vector2(12.0, -10.0), Vector2(12.0, 22.0))
	draw_rect(speaker_rect, Color(0.12, 0.07, 0.2, alpha), true)
	draw_rect(speaker_rect, Color(0.95, 0.18, 0.72, alpha), false, 2.0, true)
	draw_circle(Vector2(18.0, -4.0), 2.5 + beat, Color(0.3, 0.9, 1.0, alpha))
	draw_circle(Vector2(18.0, 6.0), 3.5 + beat, line_color)
	for note_index in VISUAL_PARTICLE_COUNT:
		var lane := float(note_index % 3) - 1.0
		var rise := fmod(elapsed * 18.0 + float(note_index) * 9.0, 44.0)
		var note_origin := Vector2(18.0 + lane * 12.0 + sin(elapsed * 2.0 + note_index) * 3.0, -14.0 - rise)
		var note_alpha := alpha * (1.0 - rise / 52.0)
		var note_color := Color(0.35, 0.92, 1.0, note_alpha)
		draw_circle(note_origin, 2.8, note_color)
		draw_line(note_origin + Vector2(2.5, 0.0), note_origin + Vector2(2.5, -10.0), note_color, 2.0, true)
		if note_index % 2 == 0:
			draw_line(note_origin + Vector2(2.5, -10.0), note_origin + Vector2(8.0, -7.0), note_color, 2.0, true)


func get_duration_remaining() -> float:
	return _duration_remaining


func get_visual_family_id() -> StringName:
	return VISUAL_FAMILY_ID


func get_visual_particle_count() -> int:
	return VISUAL_PARTICLE_COUNT


func get_visual_material_count() -> int:
	return VISUAL_MATERIAL_COUNT


func uses_fullscreen_overlay() -> bool:
	return false


func _redirect_targets() -> void:
	var affected := 0
	for target in _targeting_system.get_alive_targets():
		var instance_id := target.get_instance_id()
		if not _previous_targets.has(instance_id):
			_previous_targets[instance_id] = target.get_target()
		if target.get_target() != self:
			target.set_target(self)
		affected += 1
	targets_affected.emit(affected)


func _restore_targets() -> void:
	if not is_instance_valid(_targeting_system):
		_previous_targets.clear()
		return
	for target in _targeting_system.get_alive_targets():
		if target.get_target() != self:
			continue
		var previous: Variant = _previous_targets.get(target.get_instance_id())
		if is_instance_valid(previous):
			target.set_target(previous as Node2D)
		elif is_instance_valid(_source):
			target.set_target(_source)
	_previous_targets.clear()


func _finish() -> void:
	if _finished:
		return
	_finished = true
	_restore_targets()
	finished.emit(self)
	queue_free()


func _exit_tree() -> void:
	_restore_targets()
