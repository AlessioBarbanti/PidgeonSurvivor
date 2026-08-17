class_name EndScreen
extends Control

signal restart_requested()

@onready var _title_label: Label = %TitleLabel
@onready var _summary_label: Label = %SummaryLabel
@onready var _restart_button: Button = %RestartButton

var _accepting_restart := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_restart_button.pressed.connect(_on_restart_button_pressed)
	hide_end_screen()


func show_defeat(run_time: float) -> void:
	_title_label.text = "GAME OVER"
	_summary_label.text = "Hai resistito %s" % format_run_time(run_time)
	_accepting_restart = true
	visible = true
	_restart_button.disabled = false
	_restart_button.call_deferred("grab_focus")


func hide_end_screen() -> void:
	_accepting_restart = false
	visible = false
	if is_instance_valid(_restart_button):
		_restart_button.disabled = true


func is_accepting_restart() -> bool:
	return _accepting_restart and visible


func get_restart_button() -> Button:
	return _restart_button if is_instance_valid(_restart_button) else null


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


func _emit_restart_requested() -> void:
	if not is_accepting_restart():
		return
	_accepting_restart = false
	_restart_button.disabled = true
	restart_requested.emit()
