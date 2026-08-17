class_name TouchJoystick
extends Control

signal vector_changed(value: Vector2)
signal activity_changed(active: bool)

const NO_POINTER := -1
const DEBUG_MOUSE_POINTER := -2

@export_range(0.0, 0.95, 0.01) var deadzone_ratio := 0.18
@export_range(16.0, 256.0, 1.0) var base_radius := 84.0:
	set(value):
		base_radius = maxf(value, 1.0)
		queue_redraw()
@export_range(8.0, 128.0, 1.0) var knob_radius := 32.0:
	set(value):
		knob_radius = maxf(value, 1.0)
		queue_redraw()

@export_group("Visibility")
@export var debug_mode_in_editor := false:
	set(value):
		debug_mode_in_editor = value
		if not debug_mode_in_editor and _active_pointer == DEBUG_MOUSE_POINTER:
			reset_input()
		if is_node_ready():
			_update_platform_visibility()

@export_group("Appearance")
@export var base_color := Color(0.06, 0.1, 0.17, 0.62):
	set(value):
		base_color = value
		queue_redraw()
@export var outline_color := Color(0.38, 0.76, 1.0, 0.82):
	set(value):
		outline_color = value
		queue_redraw()
@export var knob_color := Color(0.56, 0.86, 1.0, 0.9):
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


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
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


func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, base_radius, base_color)
	draw_arc(center, base_radius, 0.0, TAU, 64, outline_color, 3.0, true)
	draw_circle(center + _knob_offset, knob_radius, knob_color)


func reset_input() -> void:
	var was_active := is_active()
	_active_pointer = NO_POINTER
	_knob_offset = Vector2.ZERO
	_set_movement_vector(Vector2.ZERO)
	if was_active:
		activity_changed.emit(false)
	queue_redraw()


func is_active() -> bool:
	return _active_pointer != NO_POINTER


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
	var raw_offset := local_position - size * 0.5
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


func _is_editor_debug_mode() -> bool:
	return debug_mode_in_editor and OS.has_feature("editor")
