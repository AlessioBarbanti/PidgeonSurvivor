class_name TouchJoystick
extends Control

const Palette = preload("res://scripts/ui/pixel_arcade_palette.gd")

signal vector_changed(value: Vector2)
signal activity_changed(active: bool)

const NO_POINTER := -1
const DEBUG_MOUSE_POINTER := -2
const BASE_CONTROL_SIZE := 224.0
const BASE_INPUT_RADIUS := 84.0
const BASE_VISUAL_RADIUS := 68.0
const BASE_KNOB_RADIUS := 27.0

@export_range(0.0, 0.95, 0.01) var deadzone_ratio := 0.18
## Raggio di acquisizione e normalizzazione: resta invariato per non cambiare
## il comportamento touch quando la grafica viene resa più compatta.
@export_range(16.0, 256.0, 1.0) var base_radius := 84.0:
	set(value):
		base_radius = maxf(value, 1.0)
		queue_redraw()
@export_range(16.0, 128.0, 1.0) var visual_radius := 68.0:
	set(value):
		visual_radius = maxf(value, 1.0)
		queue_redraw()
@export_range(8.0, 128.0, 1.0) var knob_radius := 27.0:
	set(value):
		knob_radius = maxf(value, 1.0)
		queue_redraw()

@export_group("Dynamic origin")
@export var dynamic_origin := false:
	set(value):
		dynamic_origin = value
		if is_node_ready():
			_update_mouse_filter()
			reset_input()

@export_group("Visibility")
@export var debug_mode_in_editor := false:
	set(value):
		debug_mode_in_editor = value
		if not debug_mode_in_editor and _active_pointer == DEBUG_MOUSE_POINTER:
			reset_input()
		if is_node_ready():
			_update_platform_visibility()

@export_group("Appearance")
@export_range(0.1, 1.0, 0.01) var idle_opacity := 0.38:
	set(value):
		idle_opacity = clampf(value, 0.1, 1.0)
		queue_redraw()
@export var base_color := Palette.JOYSTICK_BASE:
	set(value):
		base_color = value
		queue_redraw()
@export var outline_color := Palette.JOYSTICK_OUTLINE:
	set(value):
		outline_color = value
		queue_redraw()
@export var knob_color := Palette.JOYSTICK_KNOB:
	set(value):
		knob_color = value
		queue_redraw()

var movement_vector: Vector2:
	get:
		return _movement_vector

var active_finger_index: int:
	get:
		return _active_pointer if _active_pointer >= 0 else NO_POINTER

var _active_pointer := NO_POINTER
var _movement_vector := Vector2.ZERO
var _knob_offset := Vector2.ZERO
var _capture_enabled := false
var _capture_rect := Rect2()
var _origin_viewport_position := Vector2.ZERO
var _origin_validator := Callable()
var _control_scale := 1.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_update_mouse_filter()
	_update_platform_visibility()
	queue_redraw()


func _process(_delta: float) -> void:
	if is_active() and (get_tree().paused or not is_visible_in_tree()):
		reset_input()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, \
		NOTIFICATION_APPLICATION_PAUSED, \
		NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			reset_input()
		NOTIFICATION_VISIBILITY_CHANGED:
			if is_inside_tree() and not is_visible_in_tree():
				reset_input()


func _gui_input(event: InputEvent) -> void:
	if get_tree().paused or not is_visible_in_tree():
		return

	if event is InputEventScreenTouch:
		_handle_screen_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_handle_screen_drag(event as InputEventScreenDrag)
	elif _is_editor_debug_mode() and event is InputEventMouseButton:
		_handle_debug_mouse_button(event as InputEventMouseButton)
	elif _is_editor_debug_mode() and event is InputEventMouseMotion:
		_handle_debug_mouse_motion(event as InputEventMouseMotion)


func _input(event: InputEvent) -> void:
	if not dynamic_origin or not _capture_enabled:
		return
	if get_tree().paused or not is_visible_in_tree():
		return

	if event is InputEventScreenTouch:
		_handle_dynamic_screen_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_handle_dynamic_screen_drag(event as InputEventScreenDrag)


func _draw() -> void:
	if dynamic_origin and not is_active():
		return
	var center := size * 0.5
	var opacity_multiplier := 1.0 if is_active() else idle_opacity
	var visible_base_color := _color_with_alpha_multiplier(base_color, opacity_multiplier)
	var visible_outline_color := _color_with_alpha_multiplier(outline_color, opacity_multiplier)
	var visible_knob_color := _color_with_alpha_multiplier(knob_color, opacity_multiplier)
	var visual_offset := _knob_offset * (visual_radius / maxf(base_radius, 1.0))
	draw_circle(center, visual_radius, visible_base_color)
	draw_arc(center, visual_radius, 0.0, TAU, 48, visible_outline_color, 2.0, true)
	draw_arc(
		center,
		maxf(visual_radius - 5.0, 1.0),
		0.0,
		TAU,
		48,
		_color_with_alpha_multiplier(Palette.METAL, opacity_multiplier),
		1.0,
		true
	)
	for direction in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
		draw_line(
			center + direction * (visual_radius - 7.0),
			center + direction * (visual_radius - 2.0),
			visible_outline_color,
			2.0,
			true
		)
	draw_circle(center + visual_offset, knob_radius, visible_knob_color)
	draw_circle(
		center + visual_offset,
		maxf(knob_radius - 5.0, 1.0),
		_color_with_alpha_multiplier(Palette.ORANGE_DEEP, opacity_multiplier * 0.72)
	)


## Sola per tools/_capture_ui_screenshots.gd: il joystick "floating" resta
## invisibile finché non viene toccato, ma il pacchetto Pixel deve documentare
## anche il suo aspetto in uso, non solo la sua assenza a riposo.
func preview_engaged_for_capture() -> void:
	if _active_pointer == NO_POINTER:
		_active_pointer = DEBUG_MOUSE_POINTER
	queue_redraw()


func reset_input() -> void:
	var was_active := is_active()
	_active_pointer = NO_POINTER
	_knob_offset = Vector2.ZERO
	_set_movement_vector(Vector2.ZERO)
	if was_active:
		activity_changed.emit(false)
	queue_redraw()


func configure_dynamic_capture(
	capture_rect: Rect2,
	origin_validator: Callable = Callable()
) -> void:
	_capture_rect = capture_rect
	_origin_validator = origin_validator
	if is_active():
		global_position = _origin_viewport_position - size * 0.5
	if is_active() and not _capture_enabled:
		reset_input()


func set_capture_enabled(enabled: bool) -> void:
	_capture_enabled = enabled
	if not _capture_enabled:
		reset_input()


func is_capture_enabled() -> bool:
	return _capture_enabled


func get_capture_rect() -> Rect2:
	return _capture_rect


func get_origin_viewport_position() -> Vector2:
	return _origin_viewport_position


func is_visual_visible() -> bool:
	return is_visible_in_tree() and (not dynamic_origin or is_active())


func accepts_origin(viewport_position: Vector2) -> bool:
	if not dynamic_origin or not _capture_enabled or not _capture_rect.has_area():
		return false
	if not _capture_rect.has_point(viewport_position):
		return false
	if _origin_validator.is_valid():
		return bool(_origin_validator.call(viewport_position))
	return true


func is_active() -> bool:
	return _active_pointer != NO_POINTER


func get_visual_radius() -> float:
	return visual_radius


func set_control_scale(value: float) -> void:
	var sanitized := TouchControlSettings.sanitize_joystick_scale(value)
	if is_equal_approx(_control_scale, sanitized):
		return
	_control_scale = sanitized
	reset_input()
	custom_minimum_size = Vector2.ONE * BASE_CONTROL_SIZE * _control_scale
	base_radius = BASE_INPUT_RADIUS * _control_scale
	visual_radius = BASE_VISUAL_RADIUS * _control_scale
	knob_radius = BASE_KNOB_RADIUS * _control_scale


func get_control_scale() -> float:
	return _control_scale


func get_deadzone_radius() -> float:
	return base_radius * deadzone_ratio


func get_acquisition_rect() -> Rect2:
	if dynamic_origin:
		return _capture_rect
	return Rect2(Vector2.ZERO, size)


func _handle_screen_touch(event: InputEventScreenTouch) -> void:
	if event.canceled:
		if event.index == _active_pointer:
			reset_input()
			accept_event()
		return

	if event.pressed:
		if _active_pointer == NO_POINTER:
			_active_pointer = event.index
			activity_changed.emit(true)
			_update_pointer(event.position)
			accept_event()
	elif event.index == _active_pointer:
		reset_input()
		accept_event()


func _handle_screen_drag(event: InputEventScreenDrag) -> void:
	if event.index != _active_pointer:
		return

	_update_pointer(event.position)
	accept_event()


func _handle_dynamic_screen_touch(event: InputEventScreenTouch) -> void:
	if event.canceled:
		if event.index == _active_pointer:
			reset_input()
			_mark_viewport_input_handled()
		return

	if event.pressed:
		if _active_pointer != NO_POINTER or not accepts_origin(event.position):
			return
		_active_pointer = event.index
		_origin_viewport_position = event.position
		global_position = _origin_viewport_position - size * 0.5
		activity_changed.emit(true)
		_update_dynamic_pointer(event.position)
		_mark_viewport_input_handled()
	elif event.index == _active_pointer:
		reset_input()
		_mark_viewport_input_handled()


func _handle_dynamic_screen_drag(event: InputEventScreenDrag) -> void:
	if event.index != _active_pointer:
		return
	_update_dynamic_pointer(event.position)
	_mark_viewport_input_handled()


func _update_dynamic_pointer(viewport_position: Vector2) -> void:
	_update_offset(viewport_position - _origin_viewport_position)


func _handle_debug_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index != MOUSE_BUTTON_LEFT:
		return

	if event.pressed:
		if _active_pointer == NO_POINTER:
			_active_pointer = DEBUG_MOUSE_POINTER
			activity_changed.emit(true)
			_update_pointer(event.position)
			accept_event()
	elif _active_pointer == DEBUG_MOUSE_POINTER:
		reset_input()
		accept_event()


func _handle_debug_mouse_motion(event: InputEventMouseMotion) -> void:
	if _active_pointer != DEBUG_MOUSE_POINTER:
		return

	_update_pointer(event.position)
	accept_event()


func _update_pointer(local_position: Vector2) -> void:
	_update_offset(local_position - size * 0.5)


func _update_offset(raw_offset: Vector2) -> void:
	_knob_offset = raw_offset.limit_length(base_radius)

	var normalized_distance := minf(_knob_offset.length() / base_radius, 1.0)
	if normalized_distance <= deadzone_ratio:
		_set_movement_vector(Vector2.ZERO)
	else:
		var scaled_distance := inverse_lerp(
			deadzone_ratio,
			1.0,
			normalized_distance
		)
		_set_movement_vector(_knob_offset.normalized() * scaled_distance)

	queue_redraw()


func _set_movement_vector(value: Vector2) -> void:
	var normalized_value := value.limit_length(1.0)
	if _movement_vector.is_equal_approx(normalized_value):
		return

	_movement_vector = normalized_value
	vector_changed.emit(_movement_vector)


func _update_platform_visibility() -> void:
	var should_be_visible := (
		OS.has_feature("android")
		or DisplayServer.is_touchscreen_available()
		or _is_editor_debug_mode()
	)
	visible = should_be_visible
	if not should_be_visible:
		reset_input()


func _update_mouse_filter() -> void:
	# Il floating joystick usa _input per osservare l'intero viewport. Lasciare il
	# Control in STOP intercetterebbe il secondo dito destinato all'abilita.
	mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
		if dynamic_origin
		else Control.MOUSE_FILTER_STOP
	)


func _mark_viewport_input_handled() -> void:
	if is_inside_tree():
		get_viewport().set_input_as_handled()


func _is_editor_debug_mode() -> bool:
	return debug_mode_in_editor and OS.has_feature("editor")


static func _color_with_alpha_multiplier(color: Color, multiplier: float) -> Color:
	var result := color
	result.a *= clampf(multiplier, 0.0, 1.0)
	return result
