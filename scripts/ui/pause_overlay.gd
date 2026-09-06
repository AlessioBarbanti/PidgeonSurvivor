class_name PauseOverlay
extends Control

signal resume_requested()
signal change_character_requested()
signal audio_volume_changed(value: float)
signal audio_mute_toggled(muted: bool)
signal reduced_flashes_toggled(enabled: bool)
signal touch_control_scale_changed(control_id: StringName, value: float)
signal fire_mode_toggled(manual_enabled: bool)

@onready var _resume_button: Button = %ResumeButton
@onready var _change_character_button: Button = %ChangeCharacterButton
@onready var _pause_center: CenterContainer = %PauseCenter
@onready var _confirmation_center: CenterContainer = %ConfirmationCenter
@onready var _cancel_change_button: Button = %CancelChangeButton
@onready var _confirm_change_button: Button = %ConfirmChangeButton
@onready var _volume_slider: HSlider = %VolumeSlider
@onready var _volume_value_label: Label = %VolumeValueLabel
@onready var _mute_check_button: CheckButton = %MuteCheckButton
@onready var _reduced_flashes_check_button: CheckButton = %ReducedFlashesCheckButton
@onready var _manual_fire_check_button: CheckButton = %ManualFireCheckButton
@onready var _ability_size_slider: HSlider = %AbilitySizeSlider
@onready var _ability_size_value_label: Label = %AbilitySizeValueLabel
@onready var _joystick_size_slider: HSlider = %JoystickSizeSlider
@onready var _joystick_size_value_label: Label = %JoystickSizeValueLabel
@onready var _pause_scroll: ScrollContainer = %PauseScroll
@onready var _pause_vbox: VBoxContainer = %VBox

## PS-085: margine di respiro fra lo scroll del pannello e i bordi del
## viewport, cosi' il contenuto non tocca mai esattamente il limite anche
## quando e' clampato al massimo consentito.
const PAUSE_SCROLL_SAFETY_MARGIN := 24.0

var _accepting_resume := false
var _syncing_audio_controls := false
var _syncing_accessibility_controls := false
var _syncing_touch_controls := false
var _syncing_fire_mode_controls := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_resume_button.pressed.connect(_on_resume_button_pressed)
	_change_character_button.pressed.connect(_on_change_character_button_pressed)
	_cancel_change_button.pressed.connect(_on_cancel_change_button_pressed)
	_confirm_change_button.pressed.connect(_on_confirm_change_button_pressed)
	_volume_slider.value_changed.connect(_on_volume_slider_value_changed)
	_mute_check_button.toggled.connect(_on_mute_check_button_toggled)
	_reduced_flashes_check_button.toggled.connect(_on_reduced_flashes_toggled)
	_manual_fire_check_button.toggled.connect(_on_manual_fire_toggled)
	_ability_size_slider.value_changed.connect(_on_ability_size_changed)
	_joystick_size_slider.value_changed.connect(_on_joystick_size_changed)
	_refresh_volume_label(_volume_slider.value)
	_refresh_scale_label(_ability_size_value_label, _ability_size_slider.value)
	_refresh_scale_label(_joystick_size_value_label, _joystick_size_slider.value)
	get_viewport().size_changed.connect(_clamp_pause_scroll_height)
	_clamp_pause_scroll_height()
	hide_pause()


func _unhandled_input(event: InputEvent) -> void:
	if (
		event.is_echo()
		or not is_change_confirmation_visible()
		or not event.is_action_pressed(&"ui_cancel")
	):
		return
	get_viewport().set_input_as_handled()
	_cancel_change_character()


func show_pause() -> void:
	_accepting_resume = true
	visible = true
	_clamp_pause_scroll_height()
	_show_pause_controls()
	_resume_button.call_deferred("grab_focus")


func hide_pause() -> void:
	_accepting_resume = false
	visible = false
	if is_instance_valid(_resume_button):
		_resume_button.disabled = true
	if is_instance_valid(_change_character_button):
		_change_character_button.disabled = true
	if is_instance_valid(_pause_center):
		_pause_center.visible = true
	if is_instance_valid(_confirmation_center):
		_confirmation_center.visible = false
	_set_confirmation_buttons_disabled(true)


func is_accepting_resume() -> bool:
	return _accepting_resume and visible


func get_resume_button() -> Button:
	return _resume_button if is_instance_valid(_resume_button) else null


func get_change_character_button() -> Button:
	return _change_character_button if is_instance_valid(_change_character_button) else null


func get_cancel_change_button() -> Button:
	return _cancel_change_button if is_instance_valid(_cancel_change_button) else null


func get_confirm_change_button() -> Button:
	return _confirm_change_button if is_instance_valid(_confirm_change_button) else null


func is_change_confirmation_visible() -> bool:
	return (
		is_accepting_resume()
		and is_instance_valid(_confirmation_center)
		and _confirmation_center.visible
	)


func handle_back_requested() -> bool:
	if not is_change_confirmation_visible():
		return false
	_cancel_change_character()
	return true


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


func set_manual_fire_mode(enabled: bool) -> void:
	_syncing_fire_mode_controls = true
	_manual_fire_check_button.button_pressed = enabled
	_syncing_fire_mode_controls = false


func is_manual_fire_mode_enabled() -> bool:
	return (
		_manual_fire_check_button.button_pressed
		if is_instance_valid(_manual_fire_check_button)
		else false
	)


func get_manual_fire_check_button() -> CheckButton:
	return (
		_manual_fire_check_button
		if is_instance_valid(_manual_fire_check_button)
		else null
	)


func set_touch_control_scales(ability_scale: float, joystick_scale: float) -> void:
	_syncing_touch_controls = true
	_ability_size_slider.value = TouchControlSettings.sanitize_ability_scale(ability_scale)
	_joystick_size_slider.value = TouchControlSettings.sanitize_joystick_scale(joystick_scale)
	_syncing_touch_controls = false
	_refresh_scale_label(_ability_size_value_label, _ability_size_slider.value)
	_refresh_scale_label(_joystick_size_value_label, _joystick_size_slider.value)


func get_ability_size_slider() -> HSlider:
	return _ability_size_slider if is_instance_valid(_ability_size_slider) else null


func get_joystick_size_slider() -> HSlider:
	return _joystick_size_slider if is_instance_valid(_joystick_size_slider) else null


func get_pause_panel_rect() -> Rect2:
	if not is_instance_valid(_pause_center) or _pause_center.get_child_count() == 0:
		return Rect2()
	var panel := _pause_center.get_child(0) as Control
	return panel.get_global_rect() if is_instance_valid(panel) else Rect2()


## PS-085: come WelcomeScreen._clamp_settings_scroll_height(), la riga SPARO
## MANUALE ha eroso l'ultimo margine libero del pannello pausa nel viewport
## 16:9. PauseCenter (CenterContainer) non clippa ne' scorre da solo: senza
## questo clamp il pannello sforerebbe semplicemente il viewport invece di
## restare centrato. Sui profili con margine sufficiente il risultato resta
## identico a prima (nessuno scroll).
func _clamp_pause_scroll_height() -> void:
	if (
		not is_instance_valid(_pause_scroll)
		or not is_instance_valid(_pause_vbox)
		or not is_instance_valid(_pause_center)
		or _pause_center.get_child_count() == 0
		or not is_inside_tree()
	):
		return
	var panel := _pause_center.get_child(0) as PanelContainer
	if panel == null:
		return
	var natural_height := _pause_vbox.get_combined_minimum_size().y
	var style := panel.get_theme_stylebox(&"panel")
	var chrome := (style.content_margin_top + style.content_margin_bottom) if style != null else 0.0
	var viewport_height := get_viewport().get_visible_rect().size.y
	var available_height := maxf(viewport_height - chrome - PAUSE_SCROLL_SAFETY_MARGIN, 0.0)
	_pause_scroll.custom_minimum_size.y = minf(natural_height, available_height)


func _on_resume_button_pressed() -> void:
	if not is_accepting_resume() or is_change_confirmation_visible():
		return
	resume_requested.emit()


func _on_change_character_button_pressed() -> void:
	if not is_accepting_resume() or is_change_confirmation_visible():
		return
	_pause_center.visible = false
	_confirmation_center.visible = true
	_resume_button.disabled = true
	_change_character_button.disabled = true
	_set_confirmation_buttons_disabled(false)
	_cancel_change_button.call_deferred("grab_focus")


func _on_cancel_change_button_pressed() -> void:
	if not is_change_confirmation_visible():
		return
	_cancel_change_character()


func _on_confirm_change_button_pressed() -> void:
	if not is_change_confirmation_visible() or _confirm_change_button.disabled:
		return
	_accepting_resume = false
	_set_confirmation_buttons_disabled(true)
	change_character_requested.emit()


func _cancel_change_character() -> void:
	_show_pause_controls()
	_change_character_button.call_deferred("grab_focus")


func _show_pause_controls() -> void:
	_pause_center.visible = true
	_confirmation_center.visible = false
	_resume_button.disabled = false
	_change_character_button.disabled = false
	_set_confirmation_buttons_disabled(true)


func _set_confirmation_buttons_disabled(disabled: bool) -> void:
	if is_instance_valid(_cancel_change_button):
		_cancel_change_button.disabled = disabled
	if is_instance_valid(_confirm_change_button):
		_confirm_change_button.disabled = disabled


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


func _on_manual_fire_toggled(enabled: bool) -> void:
	if not _syncing_fire_mode_controls:
		fire_mode_toggled.emit(enabled)


func _on_ability_size_changed(value: float) -> void:
	_refresh_scale_label(_ability_size_value_label, value)
	if not _syncing_touch_controls:
		touch_control_scale_changed.emit(&"ability", value)


func _on_joystick_size_changed(value: float) -> void:
	_refresh_scale_label(_joystick_size_value_label, value)
	if not _syncing_touch_controls:
		touch_control_scale_changed.emit(&"joystick", value)


func _refresh_volume_label(value: float) -> void:
	if is_instance_valid(_volume_value_label):
		_volume_value_label.text = "%d%%" % roundi(clampf(value, 0.0, 1.0) * 100.0)


func _refresh_scale_label(label: Label, value: float) -> void:
	if is_instance_valid(label):
		label.text = "%d%%" % roundi(value * 100.0)
