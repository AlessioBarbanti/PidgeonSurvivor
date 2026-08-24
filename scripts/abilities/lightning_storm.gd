class_name ThunderStorm
extends Node2D

signal finished(effect: ThunderStorm)
signal targets_affected(count: int)
signal impact_started()

enum Phase {
	WARNING,
	FLASH_RISE,
	FLASH_HOLD,
	FLASH_FADE,
	FINISHED,
}

const DEFAULT_WARNING_SECONDS := 0.45
const DEFAULT_FLASH_RISE_SECONDS := 0.06
const DEFAULT_FLASH_HOLD_SECONDS := 0.06
const DEFAULT_FLASH_FADE_SECONDS := 0.18
const DEFAULT_WINDOWS_ALPHA := 0.55
const DEFAULT_ANDROID_ALPHA := 0.40
const DEFAULT_REDUCED_ALPHA := 0.15

var _definition: AbilityDefinition
var _run_controller: RunController
var _targeting_system: TargetingSystem
var _visual_settings: VisualAccessibilitySettings
var _origin := Vector2.ZERO
var _phase := Phase.WARNING
var _phase_remaining := 0.0
var _phase_duration := 0.0
var _flash_alpha := 0.0
var _flash_max_alpha := 0.0
var _flash_rise_seconds := DEFAULT_FLASH_RISE_SECONDS
var _flash_hold_seconds := DEFAULT_FLASH_HOLD_SECONDS
var _flash_fade_seconds := DEFAULT_FLASH_FADE_SECONDS
var _affected_count := 0
var _impact_executed := false
var _impacted_target_ids: Array[int] = []
var _impact_positions := PackedVector2Array()
var _flash_layer: CanvasLayer
var _flash_rect: ColorRect


func initialize(
	origin: Vector2,
	definition: AbilityDefinition,
	run_controller: RunController,
	targeting_system: TargetingSystem,
	visual_settings: VisualAccessibilitySettings = null
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
	_visual_settings = visual_settings
	if (
		is_instance_valid(_visual_settings)
		and not _visual_settings.settings_changed.is_connected(_on_visual_settings_changed)
	):
		_visual_settings.settings_changed.connect(_on_visual_settings_changed)
	_origin = origin
	global_position = Vector2.ZERO
	_flash_rise_seconds = _definition.get_effect_float(
		&"flash_rise_seconds",
		DEFAULT_FLASH_RISE_SECONDS,
		AbilityDefinition.MINIMUM_POSITIVE_VALUE
	)
	_flash_hold_seconds = _definition.get_effect_float(
		&"flash_hold_seconds",
		DEFAULT_FLASH_HOLD_SECONDS,
		0.0
	)
	_flash_fade_seconds = _definition.get_effect_float(
		&"flash_fade_seconds",
		DEFAULT_FLASH_FADE_SECONDS,
		AbilityDefinition.MINIMUM_POSITIVE_VALUE
	)
	_set_phase(
		Phase.WARNING,
		_definition.get_effect_float(
			&"warning_seconds",
			DEFAULT_WARNING_SECONDS,
			0.0
		)
	)
	_create_flash_overlay()
	queue_redraw()
	return true


func _process(delta: float) -> void:
	if (
		_phase == Phase.FINISHED
		or not is_instance_valid(_run_controller)
		or not _run_controller.is_running()
	):
		return
	var remaining_delta := maxf(delta, 0.0) if is_finite(delta) else 0.0
	while remaining_delta > 0.0 and _phase != Phase.FINISHED:
		if _phase_remaining > remaining_delta:
			_phase_remaining -= remaining_delta
			remaining_delta = 0.0
		else:
			remaining_delta -= _phase_remaining
			_phase_remaining = 0.0
			_advance_phase()
		_update_flash_alpha()
	_sync_flash_overlay()
	queue_redraw()


func _exit_tree() -> void:
	if (
		is_instance_valid(_visual_settings)
		and _visual_settings.settings_changed.is_connected(_on_visual_settings_changed)
	):
		_visual_settings.settings_changed.disconnect(_on_visual_settings_changed)


func _draw() -> void:
	if _phase == Phase.WARNING:
		_draw_thunder_warning()
	elif _phase != Phase.FINISHED:
		_draw_thunder_impact()


func get_phase() -> Phase:
	return _phase


func get_phase_remaining() -> float:
	return _phase_remaining


func get_warning_remaining() -> float:
	return _phase_remaining if _phase == Phase.WARNING else 0.0


func get_flash_alpha() -> float:
	return _flash_alpha


func get_flash_max_alpha() -> float:
	return _flash_max_alpha


func get_flash_rect() -> Rect2:
	return _flash_rect.get_global_rect() if is_instance_valid(_flash_rect) else Rect2()


func get_affected_count() -> int:
	return _affected_count


func has_impacted() -> bool:
	return _impact_executed


func get_impacted_target_ids() -> Array[int]:
	return _impacted_target_ids.duplicate()


static func resolve_flash_max_alpha(
	reduced_flashes: bool,
	is_android: bool,
	windows_alpha: float = DEFAULT_WINDOWS_ALPHA,
	android_alpha: float = DEFAULT_ANDROID_ALPHA,
	reduced_alpha: float = DEFAULT_REDUCED_ALPHA
) -> float:
	if reduced_flashes:
		return clampf(reduced_alpha, 0.0, 1.0)
	return clampf(android_alpha if is_android else windows_alpha, 0.0, 1.0)


func _advance_phase() -> void:
	match _phase:
		Phase.WARNING:
			_execute_impact()
			_begin_flash()
		Phase.FLASH_RISE:
			if _flash_hold_seconds > 0.0:
				_set_phase(Phase.FLASH_HOLD, _flash_hold_seconds)
			else:
				_set_phase(Phase.FLASH_FADE, _flash_fade_seconds)
		Phase.FLASH_HOLD:
			_set_phase(Phase.FLASH_FADE, _flash_fade_seconds)
		Phase.FLASH_FADE:
			_finish()


func _begin_flash() -> void:
	var reduced_flashes := (
		is_instance_valid(_visual_settings)
		and _visual_settings.is_reduced_flashes_enabled()
	)
	_flash_max_alpha = resolve_flash_max_alpha(
		reduced_flashes,
		OS.has_feature("android"),
		_definition.get_effect_float(&"windows_flash_alpha", DEFAULT_WINDOWS_ALPHA, 0.0),
		_definition.get_effect_float(&"android_flash_alpha", DEFAULT_ANDROID_ALPHA, 0.0),
		_definition.get_effect_float(&"reduced_flash_alpha", DEFAULT_REDUCED_ALPHA, 0.0)
	)
	if reduced_flashes:
		_flash_hold_seconds = 0.0
	_set_phase(Phase.FLASH_RISE, _flash_rise_seconds)


func _execute_impact() -> void:
	if _impact_executed:
		return
	_impact_executed = true
	impact_started.emit()
	var normal_ratio := _definition.get_effect_float(
		&"normal_max_health_damage_ratio",
		0.5,
		0.0
	)
	var boss_ratio := _definition.get_effect_float(
		&"boss_max_health_damage_ratio",
		0.2,
		0.0
	)
	var targets := _targeting_system.get_alive_targets()
	for target in targets:
		if not is_instance_valid(target) or not target.is_alive():
			continue
		var health := target.get_health_component()
		if health == null or not health.is_alive():
			continue
		_impacted_target_ids.append(target.get_instance_id())
		_impact_positions.append(target.global_position)
		var damage_ratio := boss_ratio if target is FirstBoss or target.is_in_group(&"bosses") else normal_ratio
		if target.take_damage(health.health_max * damage_ratio):
			_affected_count += 1
	targets_affected.emit(_affected_count)


func _set_phase(next_phase: Phase, duration: float) -> void:
	_phase = next_phase
	_phase_duration = maxf(duration, 0.0)
	_phase_remaining = _phase_duration


func _update_flash_alpha() -> void:
	match _phase:
		Phase.FLASH_RISE:
			var rise_progress := 1.0 - _safe_phase_ratio()
			_flash_alpha = _flash_max_alpha * rise_progress
		Phase.FLASH_HOLD:
			_flash_alpha = _flash_max_alpha
		Phase.FLASH_FADE:
			_flash_alpha = _flash_max_alpha * _safe_phase_ratio()
		_:
			_flash_alpha = 0.0


func _safe_phase_ratio() -> float:
	if _phase_duration <= 0.0:
		return 0.0
	return clampf(_phase_remaining / _phase_duration, 0.0, 1.0)


func _create_flash_overlay() -> void:
	_flash_layer = CanvasLayer.new()
	_flash_layer.name = "ThunderFlashLayer"
	_flash_layer.layer = 20
	add_child(_flash_layer)
	_flash_rect = ColorRect.new()
	_flash_rect.name = "ThunderFlash"
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash_rect.color = Color(1.0, 1.0, 1.0, 0.0)
	_flash_layer.add_child(_flash_rect)
	_sync_flash_overlay()
	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_sync_flash_overlay):
		viewport.size_changed.connect(_sync_flash_overlay)


func _sync_flash_overlay() -> void:
	if not is_instance_valid(_flash_rect):
		return
	_flash_rect.position = Vector2.ZERO
	_flash_rect.size = get_viewport_rect().size
	_flash_rect.color = Color(1.0, 1.0, 1.0, _flash_alpha)


func _draw_thunder_warning() -> void:
	var viewport_size := get_viewport_rect().size
	var center := _origin if _origin.is_finite() else viewport_size * 0.5
	var progress := 1.0 - _safe_phase_ratio()
	var warning_color := Color(0.78, 0.9, 1.0, 0.25 + progress * 0.45)
	for ring_index in range(3):
		var radius := 40.0 + float(ring_index) * 34.0 + progress * 24.0
		draw_arc(center, radius, -2.55, -0.58, 24, warning_color, 4.0, true)
		draw_arc(center, radius, 0.58, 2.55, 24, warning_color, 4.0, true)
	draw_circle(center, 13.0 + progress * 5.0, Color(1.0, 0.9, 0.35, 0.78), false, 4.0, true)


func _draw_thunder_impact() -> void:
	for target_position in _impact_positions:
		draw_circle(target_position, 18.0, Color(0.85, 0.95, 1.0, 0.32))
		for ring_index in range(3):
			draw_arc(
				target_position,
				24.0 + float(ring_index) * 12.0,
				0.0,
				TAU,
				24,
				Color(1.0, 0.9, 0.35, 0.78 - float(ring_index) * 0.16),
				3.0,
				true
			)


func _finish() -> void:
	if _phase == Phase.FINISHED:
		return
	_set_phase(Phase.FINISHED, 0.0)
	_flash_alpha = 0.0
	_sync_flash_overlay()
	queue_redraw()
	finished.emit(self)
	queue_free()


func _on_visual_settings_changed(reduced_flashes: bool) -> void:
	if _phase == Phase.WARNING or _phase == Phase.FINISHED:
		return
	_flash_max_alpha = resolve_flash_max_alpha(
		reduced_flashes,
		OS.has_feature("android"),
		_definition.get_effect_float(&"windows_flash_alpha", DEFAULT_WINDOWS_ALPHA, 0.0),
		_definition.get_effect_float(&"android_flash_alpha", DEFAULT_ANDROID_ALPHA, 0.0),
		_definition.get_effect_float(&"reduced_flash_alpha", DEFAULT_REDUCED_ALPHA, 0.0)
	)
	_flash_hold_seconds = (
		0.0
		if reduced_flashes
		else _definition.get_effect_float(
			&"flash_hold_seconds",
			DEFAULT_FLASH_HOLD_SECONDS,
			0.0
		)
	)
	if reduced_flashes:
		if _phase == Phase.FLASH_HOLD:
			_set_phase(Phase.FLASH_FADE, _flash_fade_seconds)
	_update_flash_alpha()
	_sync_flash_overlay()
	queue_redraw()
