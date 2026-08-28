class_name EndScreen
extends Control

signal restart_requested()
signal change_character_requested()

@onready var _title_label: Label = %TitleLabel
@onready var _summary_label: Label = %SummaryLabel
@onready var _restart_button: Button = %RestartButton
@onready var _change_character_button: Button = %ChangeCharacterButton

var _accepting_restart := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_restart_button.pressed.connect(_on_restart_button_pressed)
	_change_character_button.pressed.connect(_on_change_character_button_pressed)
	hide_end_screen()


func show_defeat(run_time: float) -> void:
	_title_label.text = "GAME OVER"
	_summary_label.text = "Hai resistito per %s" % format_run_time(run_time)
	_restart_button.text = "RIPROVA"
	_show_terminal_screen()


func show_victory(
	run_time: float,
	boss_title: String,
	experience_reward: int
) -> void:
	var safe_boss_title := boss_title.strip_edges()
	if safe_boss_title.is_empty():
		safe_boss_title = "BOSS"
	_title_label.text = "VITTORIA"
	_summary_label.text = "%s sconfitto in %s  \u2022  +%d XP" % [
		safe_boss_title,
		format_run_time(run_time),
		maxi(experience_reward, 0),
	]
	_restart_button.text = "NUOVA RUN"
	_show_terminal_screen()


func _show_terminal_screen() -> void:
	_accepting_restart = true
	visible = true
	_restart_button.disabled = false
	_change_character_button.disabled = false
	_restart_button.call_deferred("grab_focus")


func hide_end_screen() -> void:
	_accepting_restart = false
	visible = false
	if is_instance_valid(_restart_button):
		_restart_button.disabled = true
	if is_instance_valid(_change_character_button):
		_change_character_button.disabled = true


func is_accepting_restart() -> bool:
	return _accepting_restart and visible


func get_restart_button() -> Button:
	return _restart_button if is_instance_valid(_restart_button) else null


func get_change_character_button() -> Button:
	return _change_character_button if is_instance_valid(_change_character_button) else null


func get_title_text() -> String:
	return _title_label.text if is_instance_valid(_title_label) else ""


func get_summary_text() -> String:
	return _summary_label.text if is_instance_valid(_summary_label) else ""


static func format_run_time(run_time: float) -> String:
	var safe_time := maxf(run_time, 0.0) if is_finite(run_time) else 0.0
	var total_seconds := int(floor(safe_time))
	return "%02d:%02d" % [total_seconds / 60, total_seconds % 60]


func _unhandled_input(event: InputEvent) -> void:
	if (
		not is_accepting_restart()
		or not event.is_action_pressed(&"ui_accept")
	):
		return
	get_viewport().set_input_as_handled()
	_emit_restart_requested()


func _on_restart_button_pressed() -> void:
	_emit_restart_requested()


func _on_change_character_button_pressed() -> void:
	if not is_accepting_restart():
		return
	_accepting_restart = false
	_restart_button.disabled = true
	_change_character_button.disabled = true
	change_character_requested.emit()


func _emit_restart_requested() -> void:
	if not is_accepting_restart():
		return
	_accepting_restart = false
	_restart_button.disabled = true
	_change_character_button.disabled = true
	restart_requested.emit()
