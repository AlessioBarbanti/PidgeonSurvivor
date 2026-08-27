class_name TouchAbilityButton
extends Button

signal activation_requested()

const RADIAL_SEGMENTS := 48
const COOLDOWN_OVERLAY_COLOR := Color(0.015, 0.022, 0.04, 0.82)
const COOLDOWN_RING_COLOR := Color(1.0, 0.67, 0.24, 0.96)
const READY_RING_COLOR := Color(1.0, 0.87, 0.42, 1.0)
const COOLDOWN_TEXT_COLOR := Color(1.0, 0.96, 0.82, 1.0)
const COOLDOWN_FONT_SIZE := 36
const BASE_TARGET_SIZE := 128.0
const BASE_ICON_WIDTH := 84.0

var _direct_touch_sequence_active := false
var _cooldown_remaining := 0.0
var _cooldown_total := 1.0
var _action_available := false
var _control_scale := 1.0


func _ready() -> void:
	text = ""
	expand_icon = true
	icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	_apply_control_scale()
	pressed.connect(_on_native_pressed)
	queue_redraw()


func set_ability_visual(
	ability_icon: Texture2D,
	cooldown_remaining: float,
	cooldown_total: float,
	action_available: bool
) -> void:
	icon = ability_icon
	_cooldown_total = maxf(cooldown_total, 0.001)
	_cooldown_remaining = clampf(cooldown_remaining, 0.0, _cooldown_total)
	_action_available = action_available
	disabled = not _action_available
	queue_redraw()


func get_ability_icon() -> Texture2D:
	return icon


func set_control_scale(value: float) -> void:
	_control_scale = TouchControlSettings.sanitize_ability_scale(value)
	_apply_control_scale()


func get_control_scale() -> float:
	return _control_scale


func get_icon_max_width() -> int:
	return get_theme_constant("icon_max_width")


func get_cooldown_fraction() -> float:
	return clampf(_cooldown_remaining / _cooldown_total, 0.0, 1.0)


func get_cooldown_remaining() -> float:
	return _cooldown_remaining


func get_cooldown_total() -> float:
	return _cooldown_total


func get_cooldown_seconds_text() -> String:
	if _cooldown_remaining <= 0.0:
		return ""
	return str(maxi(int(ceil(_cooldown_remaining)), 1))


func has_circular_cooldown() -> bool:
	return _cooldown_remaining > 0.0


func is_ready_visual() -> bool:
	return _action_available and not has_circular_cooldown()


func _draw() -> void:
	var radius := maxf(minf(size.x, size.y) * 0.5 - 4.0, 0.0)
	if radius <= 0.0:
		return
	var center := size * 0.5
	var cooldown_fraction := get_cooldown_fraction()
	if cooldown_fraction > 0.0:
		_draw_cooldown_sector(center, radius, cooldown_fraction)
		draw_arc(
			center,
			radius,
			-PI * 0.5,
			PI * 1.5,
			RADIAL_SEGMENTS,
			COOLDOWN_RING_COLOR,
			2.0,
			true
		)
		_draw_cooldown_text(center)
	elif _action_available:
		draw_arc(
			center,
			radius,
			-PI * 0.5,
			PI * 1.5,
			RADIAL_SEGMENTS,
			READY_RING_COLOR,
			3.0,
			true
		)


func _draw_cooldown_sector(center: Vector2, radius: float, fraction: float) -> void:
	if fraction >= 0.999:
		draw_circle(center, radius, COOLDOWN_OVERLAY_COLOR)
		return
	var point_count := maxi(int(ceil(RADIAL_SEGMENTS * fraction)), 1)
	var points := PackedVector2Array([center])
	for point_index in range(point_count + 1):
		var progress := float(point_index) / float(point_count)
		var angle := -PI * 0.5 + TAU * fraction * progress
		points.append(center + Vector2.from_angle(angle) * radius)
	draw_colored_polygon(points, COOLDOWN_OVERLAY_COLOR)


func _draw_cooldown_text(center: Vector2) -> void:
	var seconds_text := get_cooldown_seconds_text()
	if seconds_text.is_empty():
		return
	draw_string(
		ThemeDB.fallback_font,
		Vector2(0.0, center.y + _get_cooldown_font_size() * 0.35),
		seconds_text,
		HORIZONTAL_ALIGNMENT_CENTER,
		size.x,
		_get_cooldown_font_size(),
		COOLDOWN_TEXT_COLOR
	)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if not touch_event.pressed or touch_event.canceled:
			call_deferred("_finish_direct_touch_sequence")
			return
		if disabled or not is_visible_in_tree():
			return
		if (
			get_global_rect().has_point(touch_event.position)
		):
			_direct_touch_sequence_active = true
			activation_requested.emit()


func _on_native_pressed() -> void:
	if not _direct_touch_sequence_active:
		activation_requested.emit()


func _finish_direct_touch_sequence() -> void:
	_direct_touch_sequence_active = false


func _apply_control_scale() -> void:
	custom_minimum_size = Vector2.ONE * BASE_TARGET_SIZE * _control_scale
	add_theme_constant_override(
		"icon_max_width",
		roundi(BASE_ICON_WIDTH * _control_scale)
	)
	queue_redraw()


func _get_cooldown_font_size() -> int:
	return maxi(roundi(COOLDOWN_FONT_SIZE * _control_scale), COOLDOWN_FONT_SIZE)
