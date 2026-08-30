class_name RunController
extends Node

signal state_changed(previous_state: RunState, current_state: RunState)
signal run_started(seed: int)
signal run_time_changed(run_time: float)
signal run_ended(final_state: RunState, run_time: float)
signal restart_prepared()

enum RunState {
	BOOT,
	RUNNING,
	MANUAL_PAUSE,
	LEVEL_UP,
	BOSS_INTRO,
	BARB_REWARD,
	VICTORY,
	DEFEAT,
}

var _state: RunState = RunState.BOOT
var _run_time := 0.0
var _seed := 0
var _terminal_locked := false


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	_apply_tree_pause_for_state()


func _exit_tree() -> void:
	# A paused SceneTree would otherwise survive a scene replacement or teardown.
	var scene_tree := get_tree()
	if scene_tree != null:
		scene_tree.paused = false


func _process(delta: float) -> void:
	if not is_running():
		return

	_run_time += maxf(delta, 0.0)
	run_time_changed.emit(_run_time)


func start_run(seed: int) -> bool:
	if _state != RunState.BOOT or _terminal_locked:
		return false

	_seed = seed
	_run_time = 0.0
	run_time_changed.emit(_run_time)
	_set_state(RunState.RUNNING)
	run_started.emit(_seed)
	return true


func request_state(next_state: RunState) -> bool:
	if next_state == RunState.BOOT:
		return false
	if _state == RunState.BOOT or _terminal_locked:
		return false
	return _set_state(next_state)


func request_manual_pause() -> bool:
	if not is_running():
		return false
	return _set_state(RunState.MANUAL_PAUSE)


func resume_run() -> bool:
	if _state != RunState.MANUAL_PAUSE or _terminal_locked:
		return false
	return _set_state(RunState.RUNNING)


func request_level_up() -> bool:
	if not is_running():
		return false
	return _set_state(RunState.LEVEL_UP)


func complete_level_up() -> bool:
	if _state != RunState.LEVEL_UP or _terminal_locked:
		return false
	return _set_state(RunState.RUNNING)


func request_boss_intro() -> bool:
	if not is_running():
		return false
	return _set_state(RunState.BOSS_INTRO)


func complete_boss_intro() -> bool:
	if _state != RunState.BOSS_INTRO or _terminal_locked:
		return false
	return _set_state(RunState.RUNNING)


func request_barb_reward() -> bool:
	if not is_running():
		return false
	return _set_state(RunState.BARB_REWARD)


func complete_barb_reward() -> bool:
	if _state != RunState.BARB_REWARD or _terminal_locked:
		return false
	return _set_state(RunState.RUNNING)


func request_victory() -> bool:
	return _request_terminal_state(RunState.VICTORY)


func request_defeat() -> bool:
	return _request_terminal_state(RunState.DEFEAT)


func prepare_restart() -> bool:
	_terminal_locked = false
	_seed = 0
	_run_time = 0.0
	run_time_changed.emit(_run_time)
	_set_state(RunState.BOOT, true)
	restart_prepared.emit()
	return true


func restart_run(seed: int) -> bool:
	if not is_terminal():
		return false
	prepare_restart()
	return start_run(seed)


func get_state() -> RunState:
	return _state


func get_run_time() -> float:
	return _run_time


func get_seed() -> int:
	return _seed


func is_running() -> bool:
	return _state == RunState.RUNNING


func is_terminal() -> bool:
	return _is_terminal_state(_state)


func _request_terminal_state(next_state: RunState) -> bool:
	if _state == RunState.BOOT or _terminal_locked:
		return false
	return _set_state(next_state)


func _set_state(next_state: RunState, allow_boot: bool = false) -> bool:
	if next_state == _state:
		_apply_tree_pause_for_state()
		return false
	if _terminal_locked:
		return false
	if next_state == RunState.BOOT and not allow_boot:
		return false

	var previous_state := _state
	_state = next_state
	_terminal_locked = _is_terminal_state(_state)
	_apply_tree_pause_for_state()
	state_changed.emit(previous_state, _state)

	if _terminal_locked:
		run_ended.emit(_state, _run_time)
	return true


func _apply_tree_pause_for_state() -> void:
	if not is_inside_tree():
		return

	var scene_tree := get_tree()
	scene_tree.paused = _state_pauses_tree(_state)


static func _state_pauses_tree(value: RunState) -> bool:
	return value not in [RunState.BOOT, RunState.RUNNING]


static func _is_terminal_state(value: RunState) -> bool:
	return value in [RunState.VICTORY, RunState.DEFEAT]
