class_name TouchControlSettings
extends Node

signal settings_changed(ability_scale: float, joystick_scale: float)

const DEFAULT_SETTINGS_PATH := "user://touch_control_settings.cfg"
const SETTINGS_SECTION := "touch_controls"
const ABILITY_SCALE_KEY := "ability_scale"
const JOYSTICK_SCALE_KEY := "joystick_scale"

const MIN_ABILITY_SCALE := 1.0
const DEFAULT_ABILITY_SCALE := 1.25
const MAX_ABILITY_SCALE := 1.5
const ABILITY_SCALE_STEP := 0.25

const MIN_JOYSTICK_SCALE := 0.85
const DEFAULT_JOYSTICK_SCALE := 1.0
const MAX_JOYSTICK_SCALE := 1.15
const JOYSTICK_SCALE_STEP := 0.15

@export_file("*.cfg") var settings_path := DEFAULT_SETTINGS_PATH

var _ability_scale := DEFAULT_ABILITY_SCALE
var _joystick_scale := DEFAULT_JOYSTICK_SCALE
var _settings_overlay: SettingsOverlay


func _ready() -> void:
	_load_settings()


func _exit_tree() -> void:
	_disconnect_controls()


## PS-137: un solo overlay condiviso al posto dei due nodi (welcome + pausa)
## sincronizzati a mano da PS-050 in avanti.
func configure(settings_overlay: SettingsOverlay) -> bool:
	_disconnect_controls()
	_settings_overlay = settings_overlay
	if not is_instance_valid(_settings_overlay):
		_disconnect_controls()
		return false
	_settings_overlay.touch_control_scale_changed.connect(
		_on_touch_control_scale_changed
	)
	_sync_controls()
	return true


func set_ability_scale(value: float, persist: bool = true) -> void:
	var sanitized := sanitize_ability_scale(value)
	var changed := not is_equal_approx(_ability_scale, sanitized)
	_ability_scale = sanitized
	_sync_controls()
	if persist:
		_save_settings()
	if changed:
		settings_changed.emit(_ability_scale, _joystick_scale)


func set_joystick_scale(value: float, persist: bool = true) -> void:
	var sanitized := sanitize_joystick_scale(value)
	var changed := not is_equal_approx(_joystick_scale, sanitized)
	_joystick_scale = sanitized
	_sync_controls()
	if persist:
		_save_settings()
	if changed:
		settings_changed.emit(_ability_scale, _joystick_scale)


func get_ability_scale() -> float:
	return _ability_scale


func get_joystick_scale() -> float:
	return _joystick_scale


func reload() -> void:
	_load_settings()
	_sync_controls()
	settings_changed.emit(_ability_scale, _joystick_scale)


static func sanitize_ability_scale(value: float) -> float:
	if not is_finite(value):
		return DEFAULT_ABILITY_SCALE
	return _snap_scale(
		value,
		MIN_ABILITY_SCALE,
		MAX_ABILITY_SCALE,
		ABILITY_SCALE_STEP
	)


static func sanitize_joystick_scale(value: float) -> float:
	if not is_finite(value):
		return DEFAULT_JOYSTICK_SCALE
	return _snap_scale(
		value,
		MIN_JOYSTICK_SCALE,
		MAX_JOYSTICK_SCALE,
		JOYSTICK_SCALE_STEP
	)


func _load_settings() -> void:
	_ability_scale = DEFAULT_ABILITY_SCALE
	_joystick_scale = DEFAULT_JOYSTICK_SCALE
	var config := ConfigFile.new()
	if config.load(settings_path) != OK:
		return
	_ability_scale = sanitize_ability_scale(_read_numeric_scale(
		config.get_value(SETTINGS_SECTION, ABILITY_SCALE_KEY, DEFAULT_ABILITY_SCALE),
		DEFAULT_ABILITY_SCALE,
		MIN_ABILITY_SCALE,
		MAX_ABILITY_SCALE
	))
	_joystick_scale = sanitize_joystick_scale(_read_numeric_scale(
		config.get_value(SETTINGS_SECTION, JOYSTICK_SCALE_KEY, DEFAULT_JOYSTICK_SCALE),
		DEFAULT_JOYSTICK_SCALE,
		MIN_JOYSTICK_SCALE,
		MAX_JOYSTICK_SCALE
	))
	_save_settings()


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value(SETTINGS_SECTION, ABILITY_SCALE_KEY, _ability_scale)
	config.set_value(SETTINGS_SECTION, JOYSTICK_SCALE_KEY, _joystick_scale)
	var error := config.save(settings_path)
	if error != OK:
		push_warning(
			"TouchControlSettings: impossibile salvare %s (errore %d)."
			% [settings_path, error]
		)


func _sync_controls() -> void:
	if is_instance_valid(_settings_overlay):
		_settings_overlay.set_touch_control_scales(_ability_scale, _joystick_scale)


func _disconnect_controls() -> void:
	if is_instance_valid(_settings_overlay):
		if _settings_overlay.touch_control_scale_changed.is_connected(
			_on_touch_control_scale_changed
		):
			_settings_overlay.touch_control_scale_changed.disconnect(
				_on_touch_control_scale_changed
			)
	_settings_overlay = null


func _on_touch_control_scale_changed(control_id: StringName, value: float) -> void:
	match control_id:
		&"ability":
			set_ability_scale(value)
		&"joystick":
			set_joystick_scale(value)


static func _read_numeric_scale(
	value: Variant,
	fallback: float,
	minimum: float,
	maximum: float
) -> float:
	if typeof(value) != TYPE_FLOAT and typeof(value) != TYPE_INT:
		return fallback
	var numeric_value := float(value)
	if not is_finite(numeric_value):
		return fallback
	return clampf(numeric_value, minimum, maximum)


static func _snap_scale(
	value: float,
	minimum: float,
	maximum: float,
	step: float
) -> float:
	var clamped_value := clampf(value, minimum, maximum)
	var step_index := roundf((clamped_value - minimum) / step)
	return clampf(minimum + step_index * step, minimum, maximum)
