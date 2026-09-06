class_name InputRouter
extends Node

signal movement_vector_changed(value: Vector2)
signal active_ability_requested()
signal manual_aim_changed(direction: Vector2, active: bool)

const TOUCH_ABILITY_SIGNAL := &"activation_requested"

@export var touch_joystick_path: NodePath
@export var active_ability_button_path: NodePath
@export var enabled: bool = true:
	set(value):
		enabled = value
		if is_inside_tree():
			if enabled:
				_refresh_movement()
				_refresh_aim()
			else:
				reset_input()

@export_group("Input Actions")
@export var move_left_action: StringName = &"move_left"
@export var move_right_action: StringName = &"move_right"
@export var move_up_action: StringName = &"move_up"
@export var move_down_action: StringName = &"move_down"
@export var active_ability_action: StringName = &"active_ability"

## PS-085: unifica la mira manuale (joystick touch dedicato, stick destro
## gamepad, mouse su desktop) nello stesso stile dell'intenzione di
## movimento — nessun autoload, solo un secondo binding equivalente.
@export_group("Manual Fire")
@export var aim_touch_joystick_path: NodePath
@export var aim_left_action: StringName = &"aim_left"
@export var aim_right_action: StringName = &"aim_right"
@export var aim_up_action: StringName = &"aim_up"
@export var aim_down_action: StringName = &"aim_down"
@export var manual_fire_hold_action: StringName = &"manual_fire_hold"

var movement_vector: Vector2:
	get:
		return _movement_vector

var manual_aim_direction: Vector2:
	get:
		return _manual_aim_direction

var is_manually_aiming: bool:
	get:
		return _is_manually_aiming

var _movement_vector := Vector2.ZERO
var _touch_vector := Vector2.ZERO
var _touch_joystick: TouchJoystick
var _active_ability_button: BaseButton
var _active_ability_action_held := false
var _application_has_focus := true
var _application_paused := false
var _resume_gate_open := true
var _neutral_rearm_requested := false
var _manual_aim_direction := Vector2.RIGHT
var _is_manually_aiming := false
var _aim_touch_vector := Vector2.ZERO
var _aim_touch_joystick: TouchJoystick
## Sorgente della posizione mondo per la mira da mouse (il Player): serve
## solo a calcolare la direzione verso il cursore via get_global_mouse_position(),
## nessun'altra dipendenza di gameplay entra in InputRouter.
var _aim_origin: Node2D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_bind_configured_touch_joystick()
	_bind_configured_aim_touch_joystick()
	_bind_configured_active_ability_button()
	_refresh_movement()
	_refresh_aim()
	_refresh_active_ability()


func _process(_delta: float) -> void:
	if get_tree().paused and _resume_gate_open:
		suspend_input()
	_refresh_movement()
	_refresh_aim()
	_refresh_active_ability()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			_application_has_focus = false
			suspend_input()
		NOTIFICATION_APPLICATION_FOCUS_IN, NOTIFICATION_WM_WINDOW_FOCUS_IN:
			_application_has_focus = true
			_refresh_movement()
			_refresh_aim()
		NOTIFICATION_APPLICATION_PAUSED:
			_application_paused = true
			suspend_input()
		NOTIFICATION_APPLICATION_RESUMED:
			_application_paused = false
			_refresh_movement()
			_refresh_aim()


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


func bind_aim_touch_joystick(joystick: TouchJoystick) -> void:
	if _aim_touch_joystick == joystick:
		return

	_unbind_aim_touch_joystick()
	_aim_touch_joystick = joystick
	if not is_instance_valid(_aim_touch_joystick):
		return

	_aim_touch_joystick.vector_changed.connect(_on_aim_touch_vector_changed)
	_aim_touch_joystick.activity_changed.connect(_on_aim_touch_activity_changed)
	_aim_touch_joystick.tree_exiting.connect(_on_aim_touch_joystick_tree_exiting)
	_aim_touch_vector = _aim_touch_joystick.movement_vector
	_refresh_aim()


## Unica dipendenza di InputRouter su un nodo di mondo: serve solo a
## proiettare il cursore mouse in coordinate globali (Node2D.get_global_mouse_position()),
## non ad altro.
func bind_aim_origin(origin: Node2D) -> void:
	_aim_origin = origin if is_instance_valid(origin) else null


func bind_active_ability_button(button: BaseButton) -> void:
	if _active_ability_button == button:
		return

	_unbind_active_ability_button()
	_active_ability_button = button
	if not is_instance_valid(_active_ability_button):
		return

	if _active_ability_button.has_signal(TOUCH_ABILITY_SIGNAL):
		_active_ability_button.connect(TOUCH_ABILITY_SIGNAL, request_active_ability)
	else:
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
	_aim_touch_vector = Vector2.ZERO
	_active_ability_action_held = _is_active_ability_action_pressed()
	if is_instance_valid(_touch_joystick):
		_touch_joystick.reset_input()
	if is_instance_valid(_aim_touch_joystick):
		_aim_touch_joystick.reset_input()
	_set_movement_vector(Vector2.ZERO)
	_set_manual_aim_state(_manual_aim_direction, false)


func _exit_tree() -> void:
	_unbind_touch_joystick()
	_unbind_aim_touch_joystick()
	_unbind_active_ability_button()
	_aim_origin = null
	_touch_vector = Vector2.ZERO
	_aim_touch_vector = Vector2.ZERO
	_set_movement_vector(Vector2.ZERO)
	_set_manual_aim_state(_manual_aim_direction, false)


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


func _bind_configured_aim_touch_joystick() -> void:
	if aim_touch_joystick_path.is_empty():
		return

	var candidate := get_node_or_null(aim_touch_joystick_path)
	if candidate is TouchJoystick:
		bind_aim_touch_joystick(candidate as TouchJoystick)
	else:
		push_warning(
			"InputRouter: aim_touch_joystick_path non punta a un TouchJoystick valido."
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


func _unbind_aim_touch_joystick() -> void:
	if not is_instance_valid(_aim_touch_joystick):
		_aim_touch_joystick = null
		return

	if _aim_touch_joystick.vector_changed.is_connected(_on_aim_touch_vector_changed):
		_aim_touch_joystick.vector_changed.disconnect(_on_aim_touch_vector_changed)
	if _aim_touch_joystick.activity_changed.is_connected(_on_aim_touch_activity_changed):
		_aim_touch_joystick.activity_changed.disconnect(_on_aim_touch_activity_changed)
	if _aim_touch_joystick.tree_exiting.is_connected(_on_aim_touch_joystick_tree_exiting):
		_aim_touch_joystick.tree_exiting.disconnect(_on_aim_touch_joystick_tree_exiting)
	_aim_touch_joystick = null


func _unbind_active_ability_button() -> void:
	if not is_instance_valid(_active_ability_button):
		_active_ability_button = null
		return
	if (
		_active_ability_button.has_signal(TOUCH_ABILITY_SIGNAL)
		and _active_ability_button.is_connected(
			TOUCH_ABILITY_SIGNAL,
			request_active_ability
		)
	):
		_active_ability_button.disconnect(
			TOUCH_ABILITY_SIGNAL,
			request_active_ability
		)
	elif _active_ability_button.pressed.is_connected(request_active_ability):
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


func _on_aim_touch_vector_changed(value: Vector2) -> void:
	_aim_touch_vector = value.limit_length(1.0)
	_refresh_aim()


func _on_aim_touch_activity_changed(_active: bool) -> void:
	_refresh_aim()


func _on_aim_touch_joystick_tree_exiting() -> void:
	_aim_touch_joystick = null
	_aim_touch_vector = Vector2.ZERO
	_refresh_aim()


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


## Ordine di priorita' della mira manuale: joystick touch dedicato (mentre
## tenuto), poi stick destro gamepad, infine il mouse su desktop (direzione
## verso il cursore, attiva solo mentre manual_fire_hold_action e' premuto).
## Nessuna sorgente attiva riporta semplicemente "non sto mirando" senza
## azzerare l'ultima direzione, cosi' WeaponController puo' trattarla come
## _last_aim_direction dell'automatico.
func _refresh_aim() -> void:
	if not _resume_gate_open or not enabled or not can_resume_input():
		_set_manual_aim_state(_manual_aim_direction, false)
		return

	if is_instance_valid(_aim_touch_joystick) and _aim_touch_joystick.is_active():
		if _aim_touch_vector.is_zero_approx():
			_set_manual_aim_state(_manual_aim_direction, false)
		else:
			_set_manual_aim_state(_aim_touch_vector, true)
		return

	var stick_vector := _read_mapped_aim_vector()
	if not stick_vector.is_zero_approx():
		_set_manual_aim_state(stick_vector, true)
		return

	if _is_manual_fire_hold_pressed() and is_instance_valid(_aim_origin):
		var mouse_offset := _aim_origin.get_global_mouse_position() - _aim_origin.global_position
		if not mouse_offset.is_zero_approx():
			_set_manual_aim_state(mouse_offset.normalized(), true)
			return

	_set_manual_aim_state(_manual_aim_direction, false)


func _read_mapped_aim_vector() -> Vector2:
	if (
		not InputMap.has_action(aim_left_action)
		or not InputMap.has_action(aim_right_action)
		or not InputMap.has_action(aim_up_action)
		or not InputMap.has_action(aim_down_action)
	):
		return Vector2.ZERO
	return Input.get_vector(
		aim_left_action,
		aim_right_action,
		aim_up_action,
		aim_down_action
	).limit_length(1.0)


func _is_manual_fire_hold_pressed() -> bool:
	return (
		InputMap.has_action(manual_fire_hold_action)
		and Input.is_action_pressed(manual_fire_hold_action)
	)


func _set_manual_aim_state(direction: Vector2, active: bool) -> void:
	var normalized_direction := direction.limit_length(1.0)
	var direction_changed := (
		active and not normalized_direction.is_equal_approx(_manual_aim_direction)
	)
	var active_changed := active != _is_manually_aiming
	if not direction_changed and not active_changed:
		return
	if direction_changed:
		_manual_aim_direction = normalized_direction
	_is_manually_aiming = active
	manual_aim_changed.emit(_manual_aim_direction, _is_manually_aiming)


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
