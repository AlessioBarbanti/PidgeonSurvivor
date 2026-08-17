class_name PauseOverlay
extends Control

signal resume_requested()

@onready var _resume_button: Button = %ResumeButton

var _accepting_resume := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_resume_button.pressed.connect(_on_resume_button_pressed)
	hide_pause()


func show_pause() -> void:
	_accepting_resume = true
	visible = true
	_resume_button.disabled = false
	_resume_button.call_deferred("grab_focus")


func hide_pause() -> void:
	_accepting_resume = false
	visible = false
	if is_instance_valid(_resume_button):
		_resume_button.disabled = true


func is_accepting_resume() -> bool:
	return _accepting_resume and visible


func get_resume_button() -> Button:
	return _resume_button if is_instance_valid(_resume_button) else null


func _on_resume_button_pressed() -> void:
	if not is_accepting_resume():
		return
	resume_requested.emit()
