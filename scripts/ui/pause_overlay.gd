class_name PauseOverlay
extends Control

signal resume_requested()
signal audio_volume_changed(value: float)
signal audio_mute_toggled(muted: bool)
signal reduced_flashes_toggled(enabled: bool)

@onready var _resume_button: Button = %ResumeButton
@onready var _volume_slider: HSlider = %VolumeSlider
@onready var _volume_value_label: Label = %VolumeValueLabel
@onready var _mute_check_button: CheckButton = %MuteCheckButton
@onready var _reduced_flashes_check_button: CheckButton = %ReducedFlashesCheckButton

var _accepting_resume := false
var _syncing_audio_controls := false
var _syncing_accessibility_controls := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_resume_button.pressed.connect(_on_resume_button_pressed)
	_volume_slider.value_changed.connect(_on_volume_slider_value_changed)
	_mute_check_button.toggled.connect(_on_mute_check_button_toggled)
	_reduced_flashes_check_button.toggled.connect(_on_reduced_flashes_toggled)
	_refresh_volume_label(_volume_slider.value)
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


func set_audio_settings(volume: float, muted: bool) -> void:
	_syncing_audio_controls = true
	_volume_slider.value = clampf(volume, 0.0, 1.0)
	_mute_check_button.button_pressed = muted
	_syncing_audio_controls = false
	_refresh_volume_label(_volume_slider.value)


func get_audio_volume() -> float:
	return float(_volume_slider.value) if is_instance_valid(_volume_slider) else 0.0


func is_audio_muted() -> bool:
	return _mute_check_button.button_pressed if is_instance_valid(_mute_check_button) else false


func get_volume_slider() -> HSlider:
	return _volume_slider if is_instance_valid(_volume_slider) else null


func get_mute_check_button() -> CheckButton:
	return _mute_check_button if is_instance_valid(_mute_check_button) else null


func set_reduced_flashes(enabled: bool) -> void:
	_syncing_accessibility_controls = true
	_reduced_flashes_check_button.button_pressed = enabled
	_syncing_accessibility_controls = false


func is_reduced_flashes_enabled() -> bool:
	return (
		_reduced_flashes_check_button.button_pressed
		if is_instance_valid(_reduced_flashes_check_button)
		else false
	)


func get_reduced_flashes_check_button() -> CheckButton:
	return (
		_reduced_flashes_check_button
		if is_instance_valid(_reduced_flashes_check_button)
		else null
	)


func _on_resume_button_pressed() -> void:
	if not is_accepting_resume():
		return
	resume_requested.emit()


func _on_volume_slider_value_changed(value: float) -> void:
	_refresh_volume_label(value)
	if not _syncing_audio_controls:
		audio_volume_changed.emit(clampf(value, 0.0, 1.0))


func _on_mute_check_button_toggled(muted: bool) -> void:
	if not _syncing_audio_controls:
		audio_mute_toggled.emit(muted)


func _on_reduced_flashes_toggled(enabled: bool) -> void:
	if not _syncing_accessibility_controls:
		reduced_flashes_toggled.emit(enabled)


func _refresh_volume_label(value: float) -> void:
	if is_instance_valid(_volume_value_label):
		_volume_value_label.text = "%d%%" % roundi(clampf(value, 0.0, 1.0) * 100.0)
