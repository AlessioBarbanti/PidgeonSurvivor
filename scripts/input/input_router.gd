class_name InputRouter
extends Node

signal movement_vector_changed(value: Vector2)
signal active_ability_requested()

@export var touch_joystick_path: NodePath
@export var active_ability_button_path: NodePath
@export var enabled: bool = true:
	set(value):
		enabled = value
		if is_inside_tree():
			if enabled:
				_refresh_movement()
			else:
				reset_input()

@export_group("Input Actions")
@export var move_left_action: StringName = &"move_left"
@export var move_right_action: StringName = &"move_right"
@export var move_up_action: StringName = &"move_up"
@export var move_down_action: StringName = &"move_down"
@export var active_ability_action: StringName = &"active_ability"

var movement_vector: Vector2:
	get:
		return _movement_vector

var _movement_vector := Vector2.ZERO
var _touch_vector := Vector2.ZERO
var _touch_joystick: TouchJoystick
var _active_ability_button: BaseButton
var _active_ability_action_held := false
var _application_has_focus := true
var _application_paused := false
var _resume_gate_open := true
var _neutral_rearm_requested := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_bind_configured_touch_joystick()
	_bind_configured_active_ability_button()
	_refresh_movement()
	_refresh_active_ability()


func _process(_delta: float) -> void:
	if get_tree().paused and _resume_gate_open:
		suspend_input()
	_refresh_movement()
	_refresh_active_ability()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			_application_has_focus = false
			suspend_input()
		NOTIFICATION_APPLICATION_FOCUS_IN, NOTIFICATION_WM_WINDOW_FOCUS_IN:
			_application_has_focus = true
			_refresh_movement()
		NOTIFICATION_APPLICATION_PAUSED:
			_application_paused = true
			suspend_input()
		NOTIFICATION_APPLICATION_RESUMED:
			_application_paused = false
			_refresh_movement()


func bind_touch_joystick(joystick: TouchJoystick) -> void:
	if _touch_joystick == joystick:
		return

	_unbind_touch_joystick()
	_touch_joystick = joystick
	if not is_instance_valid(_touch_joystick):
		return

	_touch_joystick.vector_changed.connect(_on_touch_vector_changed)
	_touch_joystick.activity_changed.connect(_on_touch_activity_changed)
	_touch_joystick.tree_exiting.connect(_on_touch_joystick_tree_exiting)
	_touch_vector = _touch_joystick.movement_vector
	_refresh_movement()


func bind_active_ability_button(button: BaseButton) -> void:
	if _active_ability_button == button:
		return

	_unbind_active_ability_button()
	_active_ability_button = button
	if not is_instance_valid(_active_ability_button):
		return

	_active_ability_button.pressed.connect(request_active_ability)
	_active_ability_button.tree_exiting.connect(
		_on_active_ability_button_tree_exiting
	)


func request_active_ability() -> bool:
	if not enabled or not _resume_gate_open or not can_resume_input():
		return false
	active_ability_requested.emit()
	return true


func get_active_ability_button() -> BaseButton:
	return _active_ability_button if is_instance_valid(_active_ability_button) else null


func suspend_input() -> void:
	_resume_gate_open = false
	_neutral_rearm_requested = false
	reset_input()


func resume_input() -> bool:
	if not can_resume_input():
		return false

	if not _resume_gate_open:
		_neutral_rearm_requested = true
	_refresh_movement()
	return true


func can_resume_input() -> bool:
	return (
		is_inside_tree()
		and _application_has_focus
		and not _application_paused
		and not get_tree().paused
	)


func is_input_suspended() -> bool:
	return not _resume_gate_open or not can_resume_input()


func reset_input() -> void:
	_touch_vector = Vector2.ZERO
	_active_ability_action_held = _is_active_ability_action_pressed()
	if is_instance_valid(_touch_joystick):
		_touch_joystick.reset_input()
	_set_movement_vector(Vector2.ZERO)


func _exit_tree() -> void:
	_unbind_touch_joystick()
	_unbind_active_ability_button()
	_touch_vector = Vector2.ZERO
	_set_movement_vector(Vector2.ZERO)


func _bind_configured_touch_joystick() -> void:
	if touch_joystick_path.is_empty():
		return

	var candidate := get_node_or_null(touch_joystick_path)
	if candidate is TouchJoystick:
		bind_touch_joystick(candidate as TouchJoystick)
	else:
		push_warning(
			"InputRouter: touch_joystick_path non punta a un TouchJoystick valido."
		)


func _bind_configured_active_ability_button() -> void:
	if active_ability_button_path.is_empty():
		return

	var candidate := get_node_or_null(active_ability_button_path)
	if candidate is BaseButton:
		bind_active_ability_button(candidate as BaseButton)
	else:
		push_warning(
			"InputRouter: active_ability_button_path non punta a un BaseButton valido."
		)


func _unbind_touch_joystick() -> void:
	if not is_instance_valid(_touch_joystick):
		_touch_joystick = null
		return

	if _touch_joystick.vector_changed.is_connected(_on_touch_vector_changed):
		_touch_joystick.vector_changed.disconnect(_on_touch_vector_changed)
	if _touch_joystick.activity_changed.is_connected(_on_touch_activity_changed):
		_touch_joystick.activity_changed.disconnect(_on_touch_activity_changed)
	if _touch_joystick.tree_exiting.is_connected(_on_touch_joystick_tree_exiting):
		_touch_joystick.tree_exiting.disconnect(_on_touch_joystick_tree_exiting)
	_touch_joystick = null


func _unbind_active_ability_button() -> void:
	if not is_instance_valid(_active_ability_button):
		_active_ability_button = null
		return
	if _active_ability_button.pressed.is_connected(request_active_ability):
		_active_ability_button.pressed.disconnect(request_active_ability)
	if _active_ability_button.tree_exiting.is_connected(
		_on_active_ability_button_tree_exiting
	):
		_active_ability_button.tree_exiting.disconnect(
			_on_active_ability_button_tree_exiting
		)
	_active_ability_button = null


func _on_touch_vector_changed(value: Vector2) -> void:
	_touch_vector = value.limit_length(1.0)
	_refresh_movement()


func _on_touch_activity_changed(_active: bool) -> void:
	_refresh_movement()


func _on_touch_joystick_tree_exiting() -> void:
	_touch_joystick = null
	_touch_vector = Vector2.ZERO
	_refresh_movement()


func _on_active_ability_button_tree_exiting() -> void:
	_active_ability_button = null


func _refresh_movement() -> void:
	if not _resume_gate_open:
		_try_neutral_rearm()
		if not _resume_gate_open:
			_set_movement_vector(Vector2.ZERO)
			return

	if not enabled or not can_resume_input():
		_set_movement_vector(Vector2.ZERO)
		return

	if is_instance_valid(_touch_joystick) and _touch_joystick.is_active():
		_set_movement_vector(_touch_vector)
		return

	_set_movement_vector(_read_mapped_vector())


func _try_neutral_rearm() -> void:
	if not _neutral_rearm_requested or not can_resume_input():
		return
	if is_instance_valid(_touch_joystick) and _touch_joystick.is_active():
		return
	if not _read_mapped_vector().is_zero_approx():
		return
	if _is_active_ability_action_pressed():
		return

	_neutral_rearm_requested = false
	_resume_gate_open = true


func _refresh_active_ability() -> void:
	var pressed := _is_active_ability_action_pressed()
	if not enabled or not _resume_gate_open or not can_resume_input():
		_active_ability_action_held = pressed
		return
	if pressed and not _active_ability_action_held:
		request_active_ability()
	_active_ability_action_held = pressed


func _is_active_ability_action_pressed() -> bool:
	return (
		InputMap.has_action(active_ability_action)
		and Input.is_action_pressed(active_ability_action)
	)


func _read_mapped_vector() -> Vector2:
	return Input.get_vector(
		move_left_action,
		move_right_action,
		move_up_action,
		move_down_action
	).limit_length(1.0)


func _set_movement_vector(value: Vector2) -> void:
	var normalized_value := value.limit_length(1.0)
	if _movement_vector.is_equal_approx(normalized_value):
		return

	_movement_vector = normalized_value
	movement_vector_changed.emit(_movement_vector)
