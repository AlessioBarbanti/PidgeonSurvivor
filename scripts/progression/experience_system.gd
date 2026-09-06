class_name ExperienceSystem
extends Node

signal experience_changed(experience_current: int)
signal experience_added(amount: int, experience_current: int)
signal progression_changed(
	level: int,
	experience_current: int,
	experience_required: int,
	experience_total: int
)
signal level_changed(level: int)
signal level_up_queued(level: int, pending_choices: int)
signal level_up_started(level: int, pending_choices: int)
signal level_up_completed(level: int, pending_choices: int)
signal pending_level_ups_changed(pending_choices: int)

@export var experience_curve: ExperienceCurve

var experience_current: int:
	get:
		return _experience_current

var experience_total: int:
	get:
		return _experience_total

var level: int:
	get:
		return _level

var experience_required: int:
	get:
		return get_experience_required()

var pending_level_ups: int:
	get:
		return _pending_level_up_levels.size()

var _experience_current := 0
var _experience_total := 0
var _level := 1
var _active_level_up_level := 0
var _pending_level_up_levels: Array[int] = []
var _run_controller: RunController
var _fallback_curve := ExperienceCurve.new()
var _upgrade_value_multiplier := 1.0
var _upgrade_value_credit := 0.0
## Avidità (PS-093): stadio "character", composto moltiplicativamente con
## quello "upgrade" sopra — stesso pattern a due stadi già in uso per
## cadenza/danno/raggio pickup. Non si azzera in `reset_for_run()`: il suo
## ciclo di vita è quello della passiva equipaggiata
## (`FriendPassiveController._apply_character_multipliers()`), non quello
## della run, esattamente come i moltiplicatori "character" di
## `WeaponController`.
var _character_value_multiplier := 1.0


func set_run_controller(value: RunController) -> void:
	if value == _run_controller:
		return

	_disconnect_run_controller()
	_run_controller = value
	if not is_instance_valid(_run_controller):
		return
	if not _run_controller.run_started.is_connected(_on_run_started):
		_run_controller.run_started.connect(_on_run_started)
	if not _run_controller.restart_prepared.is_connected(_on_restart_prepared):
		_run_controller.restart_prepared.connect(_on_restart_prepared)


func get_run_controller() -> RunController:
	return _run_controller if is_instance_valid(_run_controller) else null


func add_experience(amount: int) -> bool:
	if (
		amount <= 0
		or not is_instance_valid(_run_controller)
		or not _run_controller.is_running()
	):
		return false

	var awarded_amount := _resolve_upgrade_value(amount)
	if awarded_amount <= 0:
		return false
	_experience_total += awarded_amount
	_experience_current += awarded_amount
	_queue_reached_levels()
	experience_added.emit(awarded_amount, _experience_current)
	experience_changed.emit(_experience_current)
	_emit_progression_changed()
	_start_next_level_up()
	return true


func complete_level_up() -> bool:
	if (
		not is_instance_valid(_run_controller)
		or _run_controller.get_state() != RunController.RunState.LEVEL_UP
		or _active_level_up_level <= 0
		or _pending_level_up_levels.is_empty()
		or _pending_level_up_levels[0] != _active_level_up_level
	):
		return false

	var completed_level := _active_level_up_level
	_pending_level_up_levels.pop_front()
	_active_level_up_level = 0
	level_up_completed.emit(completed_level, _pending_level_up_levels.size())
	pending_level_ups_changed.emit(_pending_level_up_levels.size())

	if not _pending_level_up_levels.is_empty():
		_start_next_level_up()
		return true

	return _run_controller.complete_level_up()


func get_experience_required(for_level: int = -1) -> int:
	var queried_level := _level if for_level < 1 else for_level
	return _get_curve().get_experience_required(queried_level)


func get_pending_level_up_levels() -> Array[int]:
	return _pending_level_up_levels.duplicate()


func get_active_level_up_level() -> int:
	return _active_level_up_level


func set_upgrade_value_multiplier(multiplier: float) -> bool:
	if not is_finite(multiplier) or multiplier <= 0.0:
		return false
	_upgrade_value_multiplier = multiplier
	return true


func reset_upgrade_value_multiplier() -> void:
	_upgrade_value_multiplier = 1.0
	_upgrade_value_credit = 0.0


func get_upgrade_value_multiplier() -> float:
	return _upgrade_value_multiplier


func set_character_value_multiplier(multiplier: float) -> bool:
	if not is_finite(multiplier) or multiplier <= 0.0:
		return false
	_character_value_multiplier = multiplier
	return true


func reset_character_value_multiplier() -> void:
	_character_value_multiplier = 1.0


func get_character_value_multiplier() -> float:
	return _character_value_multiplier


func reset_for_run() -> void:
	reset_upgrade_value_multiplier()
	var experience_was_changed := _experience_current != 0
	var level_was_changed := _level != 1
	var pending_was_changed := (
		_active_level_up_level != 0
		or not _pending_level_up_levels.is_empty()
	)
	if (
		not experience_was_changed
		and _experience_total == 0
		and not level_was_changed
		and not pending_was_changed
	):
		return

	_experience_current = 0
	_experience_total = 0
	_level = 1
	_active_level_up_level = 0
	_pending_level_up_levels.clear()
	if experience_was_changed:
		experience_changed.emit(_experience_current)
	if level_was_changed:
		level_changed.emit(_level)
	if pending_was_changed:
		pending_level_ups_changed.emit(0)
	_emit_progression_changed()


func _exit_tree() -> void:
	_disconnect_run_controller()


func _disconnect_run_controller() -> void:
	if not is_instance_valid(_run_controller):
		_run_controller = null
		return
	if _run_controller.run_started.is_connected(_on_run_started):
		_run_controller.run_started.disconnect(_on_run_started)
	if _run_controller.restart_prepared.is_connected(_on_restart_prepared):
		_run_controller.restart_prepared.disconnect(_on_restart_prepared)
	_run_controller = null


func _get_curve() -> ExperienceCurve:
	return experience_curve if experience_curve != null else _fallback_curve


func _resolve_upgrade_value(amount: int) -> int:
	var total_value := (
		float(amount) * _upgrade_value_multiplier * _character_value_multiplier
		+ _upgrade_value_credit
	)
	var whole_amount := floori(total_value + 0.00001)
	_upgrade_value_credit = maxf(total_value - float(whole_amount), 0.0)
	return whole_amount


func _queue_reached_levels() -> void:
	var pending_count_before := _pending_level_up_levels.size()
	while _experience_current >= get_experience_required():
		_experience_current -= get_experience_required()
		_level += 1
		_pending_level_up_levels.append(_level)
		level_changed.emit(_level)
		level_up_queued.emit(_level, _pending_level_up_levels.size())

	if _pending_level_up_levels.size() != pending_count_before:
		pending_level_ups_changed.emit(_pending_level_up_levels.size())


func _start_next_level_up() -> void:
	if (
		_pending_level_up_levels.is_empty()
		or _active_level_up_level > 0
		or not is_instance_valid(_run_controller)
	):
		return

	if _run_controller.is_running():
		if not _run_controller.request_level_up():
			return
	elif _run_controller.get_state() != RunController.RunState.LEVEL_UP:
		return

	_active_level_up_level = _pending_level_up_levels[0]
	level_up_started.emit(
		_active_level_up_level,
		_pending_level_up_levels.size()
	)


func _emit_progression_changed() -> void:
	progression_changed.emit(
		_level,
		_experience_current,
		get_experience_required(),
		_experience_total
	)


func _on_run_started(_seed_value: int) -> void:
	reset_for_run()


func _on_restart_prepared() -> void:
	reset_for_run()
