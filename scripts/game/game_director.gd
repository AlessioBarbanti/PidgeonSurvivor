class_name GameDirector
extends Node

signal boss_event_queued(schedule_index: int, threshold_seconds: float)
signal boss_event_requested(schedule_index: int, threshold_seconds: float)
signal boss_event_completed(schedule_index: int)
signal boss_warning_changed(
	schedule_index: int,
	phase: BossWarningPhase,
	seconds_remaining: int
)

enum BossWarningPhase {
	HIDDEN,
	APPROACHING,
	COUNTDOWN,
}

@export var profile: GameDirectorProfile

var _run_controller: RunController
var _enemy_spawner: EnemySpawner
var _thresholds := PackedFloat32Array()
var _triggered_events: Dictionary[int, bool] = {}
var _pending_event_indices: Array[int] = []
var _active_event_index := -1
var _boss_request_in_flight := false
var _active_boss: Node
var _requested_count := 0
var _recurring_window_seconds := 0.0
var _last_boss_spawn_run_time := 0.0
var _recurring_pending := false
var _recurring_count := 0
var _boss_warning_lead_seconds := 0.0
var _boss_countdown_seconds := 0.0
var _boss_warning_schedule_index := -1
var _boss_warning_phase := BossWarningPhase.HIDDEN
var _boss_warning_seconds_remaining := 0


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func configure(
	run_controller: RunController,
	enemy_spawner: EnemySpawner
) -> bool:
	set_run_controller(run_controller)
	_enemy_spawner = enemy_spawner
	_apply_profile_to_spawner()
	reset_for_run()
	if is_instance_valid(_run_controller) and _run_controller.is_running():
		_evaluate_run_time(_run_controller.get_run_time())
	return has_valid_configuration()


func set_run_controller(value: RunController) -> void:
	if value == _run_controller:
		return

	_disconnect_run_controller()
	_run_controller = value
	if not is_instance_valid(_run_controller):
		return

	if not _run_controller.run_started.is_connected(_on_run_started):
		_run_controller.run_started.connect(_on_run_started)
	if not _run_controller.run_time_changed.is_connected(_on_run_time_changed):
		_run_controller.run_time_changed.connect(_on_run_time_changed)
	if not _run_controller.state_changed.is_connected(_on_run_state_changed):
		_run_controller.state_changed.connect(_on_run_state_changed)
	if not _run_controller.restart_prepared.is_connected(_on_restart_prepared):
		_run_controller.restart_prepared.connect(_on_restart_prepared)


func get_run_controller() -> RunController:
	return _run_controller if is_instance_valid(_run_controller) else null


func get_enemy_spawner() -> EnemySpawner:
	return _enemy_spawner if is_instance_valid(_enemy_spawner) else null


func has_valid_configuration() -> bool:
	return (
		profile != null
		and profile.is_valid()
		and is_instance_valid(_run_controller)
		and is_instance_valid(_enemy_spawner)
		and _enemy_spawner.spawn_profile == profile.enemy_spawn_profile
	)


func apply_profile() -> bool:
	_apply_profile_to_spawner()
	return has_valid_configuration()


func reset_for_run(clear_tracked_boss: bool = true) -> void:
	_clear_active_event(clear_tracked_boss)
	_clear_boss_warning()
	_thresholds = (
		profile.get_effective_boss_thresholds()
		if profile != null
		else PackedFloat32Array()
	)
	_recurring_window_seconds = (
		profile.get_effective_recurring_boss_window()
		if profile != null
		else 0.0
	)
	_boss_warning_lead_seconds = (
		profile.get_effective_boss_warning_lead()
		if profile != null
		else 0.0
	)
	_boss_countdown_seconds = (
		profile.get_effective_boss_countdown()
		if profile != null
		else 0.0
	)
	_triggered_events.clear()
	_pending_event_indices.clear()
	_requested_count = 0
	_recurring_pending = false
	_recurring_count = 0
	_last_boss_spawn_run_time = 0.0


func register_active_boss(boss: Node, schedule_index: int = -1) -> bool:
	if (
		_active_event_index < 0
		or not _boss_request_in_flight
		or not is_instance_valid(boss)
	):
		return false
	if schedule_index >= 0 and schedule_index != _active_event_index:
		return false

	_active_boss = boss
	_boss_request_in_flight = false
	if not _active_boss.tree_exiting.is_connected(_on_active_boss_tree_exiting):
		_active_boss.tree_exiting.connect(
			_on_active_boss_tree_exiting,
			CONNECT_ONE_SHOT
		)
	return true


func complete_active_boss_event() -> bool:
	if _active_event_index < 0:
		return false
	var completed_index := _active_event_index
	_clear_active_event(false)
	boss_event_completed.emit(completed_index)
	_request_next_boss_event()
	return true


func get_thresholds() -> PackedFloat32Array:
	return _thresholds.duplicate()


func get_triggered_count() -> int:
	return _triggered_events.size()


func get_pending_count() -> int:
	return _pending_event_indices.size()


func get_requested_count() -> int:
	return _requested_count


func get_active_event_index() -> int:
	return _active_event_index


func is_boss_request_in_flight() -> bool:
	return _boss_request_in_flight


func get_active_boss() -> Node:
	return _active_boss if is_instance_valid(_active_boss) else null


func has_blocking_boss_event() -> bool:
	return _active_event_index >= 0


func get_recurring_window_seconds() -> float:
	return _recurring_window_seconds


func get_last_boss_spawn_run_time() -> float:
	return _last_boss_spawn_run_time


func is_boss_pending_after_active() -> bool:
	return _recurring_pending


func get_recurring_boss_count() -> int:
	return _recurring_count


func get_boss_warning_schedule_index() -> int:
	return _boss_warning_schedule_index


func get_boss_warning_phase() -> BossWarningPhase:
	return _boss_warning_phase


func get_boss_warning_seconds_remaining() -> int:
	return _boss_warning_seconds_remaining


func is_boss_warning_active() -> bool:
	return _boss_warning_phase != BossWarningPhase.HIDDEN


func _exit_tree() -> void:
	_disconnect_run_controller()
	_clear_active_event(false)
	_enemy_spawner = null


func _apply_profile_to_spawner() -> void:
	if (
		profile == null
		or not is_instance_valid(_enemy_spawner)
		or profile.enemy_spawn_profile == null
	):
		return
	_enemy_spawner.spawn_profile = profile.enemy_spawn_profile


func _evaluate_run_time(run_time: float) -> void:
	if not is_instance_valid(_run_controller) or not _run_controller.is_running():
		return
	var safe_run_time := maxf(run_time, 0.0) if is_finite(run_time) else 0.0
	for schedule_index in range(_thresholds.size()):
		if _triggered_events.has(schedule_index):
			continue
		var threshold_seconds := _thresholds[schedule_index]
		if safe_run_time < threshold_seconds:
			break
		_triggered_events[schedule_index] = true
		_pending_event_indices.append(schedule_index)
		boss_event_queued.emit(schedule_index, threshold_seconds)
	_request_next_boss_event()
	_evaluate_recurring_schedule(safe_run_time)
	_request_next_boss_event()
	_update_boss_warning(safe_run_time)


func _update_boss_warning(run_time: float) -> void:
	if (
		_boss_warning_lead_seconds <= 0.0
		or _active_event_index >= 0
		or not _pending_event_indices.is_empty()
	):
		_clear_boss_warning()
		return

	var next_schedule_index := -1
	var next_boss_run_time := 0.0
	for schedule_index in range(_thresholds.size()):
		if not _triggered_events.has(schedule_index):
			next_schedule_index = schedule_index
			next_boss_run_time = _thresholds[schedule_index]
			break
	if next_schedule_index < 0:
		if _recurring_window_seconds <= 0.0 or _last_boss_spawn_run_time <= 0.0:
			_clear_boss_warning()
			return
		next_schedule_index = _thresholds.size() + _recurring_count
		next_boss_run_time = _last_boss_spawn_run_time + _recurring_window_seconds

	var seconds_until_boss := next_boss_run_time - run_time
	if seconds_until_boss <= 0.0 or seconds_until_boss > _boss_warning_lead_seconds:
		_clear_boss_warning()
		return

	var next_phase := BossWarningPhase.APPROACHING
	var displayed_seconds := 0
	if _boss_countdown_seconds > 0.0 and seconds_until_boss <= _boss_countdown_seconds:
		next_phase = BossWarningPhase.COUNTDOWN
		displayed_seconds = maxi(ceili(seconds_until_boss), 1)
	_set_boss_warning(next_schedule_index, next_phase, displayed_seconds)


func _set_boss_warning(
	schedule_index: int,
	phase: BossWarningPhase,
	seconds_remaining: int
) -> void:
	if (
		_boss_warning_schedule_index == schedule_index
		and _boss_warning_phase == phase
		and _boss_warning_seconds_remaining == seconds_remaining
	):
		return
	_boss_warning_schedule_index = schedule_index
	_boss_warning_phase = phase
	_boss_warning_seconds_remaining = seconds_remaining
	boss_warning_changed.emit(schedule_index, phase, seconds_remaining)


func _clear_boss_warning() -> void:
	if _boss_warning_phase == BossWarningPhase.HIDDEN:
		_boss_warning_schedule_index = -1
		_boss_warning_seconds_remaining = 0
		return
	_set_boss_warning(-1, BossWarningPhase.HIDDEN, 0)


func _evaluate_recurring_schedule(run_time: float) -> void:
	if (
		_thresholds.is_empty()
		or _triggered_events.size() < _thresholds.size()
		or _recurring_pending
		or _recurring_window_seconds <= 0.0
	):
		return
	if run_time >= _last_boss_spawn_run_time + _recurring_window_seconds:
		_recurring_pending = true


func _request_next_boss_event() -> void:
	if (
		_active_event_index >= 0
		or not is_instance_valid(_run_controller)
		or not _run_controller.is_running()
	):
		return

	if not _pending_event_indices.is_empty():
		_active_event_index = _pending_event_indices.pop_front()
	elif _recurring_pending:
		_recurring_pending = false
		_active_event_index = _thresholds.size() + _recurring_count
		_recurring_count += 1
	else:
		return

	_boss_request_in_flight = true
	_requested_count += 1
	_last_boss_spawn_run_time = _run_controller.get_run_time()
	var threshold_for_signal := (
		_thresholds[_active_event_index]
		if _active_event_index < _thresholds.size()
		else _last_boss_spawn_run_time
	)
	boss_event_requested.emit(_active_event_index, threshold_for_signal)


func _clear_active_event(clear_tracked_boss: bool) -> void:
	var boss_to_clear := _active_boss
	if is_instance_valid(boss_to_clear):
		if boss_to_clear.tree_exiting.is_connected(_on_active_boss_tree_exiting):
			boss_to_clear.tree_exiting.disconnect(_on_active_boss_tree_exiting)
	_active_boss = null
	_active_event_index = -1
	_boss_request_in_flight = false
	if (
		clear_tracked_boss
		and is_instance_valid(boss_to_clear)
		and not boss_to_clear.is_queued_for_deletion()
	):
		boss_to_clear.queue_free()


func _disconnect_run_controller() -> void:
	if not is_instance_valid(_run_controller):
		_run_controller = null
		return
	if _run_controller.run_started.is_connected(_on_run_started):
		_run_controller.run_started.disconnect(_on_run_started)
	if _run_controller.run_time_changed.is_connected(_on_run_time_changed):
		_run_controller.run_time_changed.disconnect(_on_run_time_changed)
	if _run_controller.state_changed.is_connected(_on_run_state_changed):
		_run_controller.state_changed.disconnect(_on_run_state_changed)
	if _run_controller.restart_prepared.is_connected(_on_restart_prepared):
		_run_controller.restart_prepared.disconnect(_on_restart_prepared)
	_run_controller = null


func _on_run_started(_seed_value: int) -> void:
	reset_for_run()


func _on_run_time_changed(run_time: float) -> void:
	_evaluate_run_time(run_time)


func _on_run_state_changed(
	_previous_state: RunController.RunState,
	current_state: RunController.RunState
) -> void:
	if current_state != RunController.RunState.RUNNING:
		if current_state in [
			RunController.RunState.BOOT,
			RunController.RunState.BOSS_INTRO,
			RunController.RunState.VICTORY,
			RunController.RunState.DEFEAT,
		]:
			_clear_boss_warning()
		return
	_evaluate_run_time(_run_controller.get_run_time())
	_request_next_boss_event()


func _on_restart_prepared() -> void:
	reset_for_run()


func _on_active_boss_tree_exiting() -> void:
	complete_active_boss_event()
