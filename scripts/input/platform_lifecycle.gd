class_name PlatformLifecycle
extends Node

@export var pause_action: StringName = &"pause_game"

var _run_controller: RunController
var _input_router: InputRouter
var _pause_overlay: Control
var _application_has_focus := true
var _application_paused := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _exit_tree() -> void:
	_disconnect_sources()


func configure(
	run_controller: RunController,
	input_router: InputRouter,
	pause_overlay: Control
) -> bool:
	if (
		not is_instance_valid(run_controller)
		or not is_instance_valid(input_router)
		or not is_instance_valid(pause_overlay)
	):
		return false

	_disconnect_sources()
	_run_controller = run_controller
	_input_router = input_router
	_pause_overlay = pause_overlay
	_run_controller.state_changed.connect(_on_run_state_changed)
	_pause_overlay.resume_requested.connect(_on_resume_requested)
	_sync_to_run_state(_run_controller.get_state())
	return true


func request_manual_pause() -> bool:
	if not is_instance_valid(_run_controller) or not _run_controller.is_running():
		return false

	_suspend_input()
	return _run_controller.request_manual_pause()


func request_resume() -> bool:
	if (
		not is_instance_valid(_run_controller)
		or _run_controller.get_state() != RunController.RunState.MANUAL_PAUSE
		or not is_application_active()
	):
		return false

	if not _run_controller.resume_run():
		return false
	_resume_input()
	return true


func request_back() -> bool:
	if not is_instance_valid(_run_controller):
		return false

	match _run_controller.get_state():
		RunController.RunState.RUNNING:
			return request_manual_pause()
		RunController.RunState.MANUAL_PAUSE:
			return request_resume()
		_:
			_suspend_input()
			return false


func is_application_active() -> bool:
	return _application_has_focus and not _application_paused


func get_run_controller() -> RunController:
	return _run_controller if is_instance_valid(_run_controller) else null


func get_input_router() -> InputRouter:
	return _input_router if is_instance_valid(_input_router) else null


func get_pause_overlay() -> Control:
	return _pause_overlay if is_instance_valid(_pause_overlay) else null


func _notification(what: int) -> void:
	if not is_node_ready():
		return

	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			_application_has_focus = false
			_pause_for_interruption()
		NOTIFICATION_APPLICATION_FOCUS_IN, NOTIFICATION_WM_WINDOW_FOCUS_IN:
			_application_has_focus = true
		NOTIFICATION_APPLICATION_PAUSED:
			_application_paused = true
			_pause_for_interruption()
		NOTIFICATION_APPLICATION_RESUMED:
			_application_paused = false
		NOTIFICATION_WM_GO_BACK_REQUEST:
			request_back()


func _unhandled_input(event: InputEvent) -> void:
	if (
		event.is_echo()
		or pause_action.is_empty()
		or not event.is_action_pressed(pause_action)
	):
		return

	get_viewport().set_input_as_handled()
	request_back()


func _pause_for_interruption() -> void:
	_suspend_input()
	if is_instance_valid(_run_controller) and _run_controller.is_running():
		_run_controller.request_manual_pause()


func _on_run_state_changed(
	_previous_state: RunController.RunState,
	current_state: RunController.RunState
) -> void:
	_sync_to_run_state(current_state)


func _sync_to_run_state(current_state: RunController.RunState) -> void:
	if current_state == RunController.RunState.RUNNING:
		if not is_application_active():
			_pause_for_interruption()
			return
		if is_instance_valid(_pause_overlay):
			_pause_overlay.hide_pause()
		_resume_input()
		return

	_suspend_input()
	if not is_instance_valid(_pause_overlay):
		return
	if current_state == RunController.RunState.MANUAL_PAUSE:
		_pause_overlay.show_pause()
	else:
		_pause_overlay.hide_pause()


func _suspend_input() -> void:
	if is_instance_valid(_input_router):
		_input_router.suspend_input()


func _resume_input() -> void:
	if is_instance_valid(_input_router):
		_input_router.resume_input()


func _on_resume_requested() -> void:
	request_resume()


func _disconnect_sources() -> void:
	if is_instance_valid(_run_controller):
		if _run_controller.state_changed.is_connected(_on_run_state_changed):
			_run_controller.state_changed.disconnect(_on_run_state_changed)
	if is_instance_valid(_pause_overlay):
		if _pause_overlay.resume_requested.is_connected(_on_resume_requested):
			_pause_overlay.resume_requested.disconnect(_on_resume_requested)

	_run_controller = null
	_input_router = null
	_pause_overlay = null
