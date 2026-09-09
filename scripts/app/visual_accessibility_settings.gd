class_name VisualAccessibilitySettings
extends Node

signal settings_changed(reduced_flashes: bool)

const DEFAULT_SETTINGS_PATH := "user://visual_accessibility_settings.cfg"
const SETTINGS_SECTION := "accessibility"
const REDUCED_FLASHES_KEY := "reduced_flashes"

@export_file("*.cfg") var settings_path := DEFAULT_SETTINGS_PATH

var _reduced_flashes := false
var _settings_overlay: SettingsOverlay


func _ready() -> void:
	_load_settings()


func _exit_tree() -> void:
	_disconnect_settings_overlay()


## PS-137: un solo overlay condiviso (era `PauseOverlay`, unico target da
## PS-050 in avanti; la welcome aveva sempre avuto un percorso diretto
## separato in `movement_slice.gd`, ora consolidato anche lì).
func configure(settings_overlay: SettingsOverlay) -> bool:
	_disconnect_settings_overlay()
	_settings_overlay = settings_overlay
	if not is_instance_valid(_settings_overlay):
		return false
	if not _settings_overlay.reduced_flashes_toggled.is_connected(_on_reduced_flashes_toggled):
		_settings_overlay.reduced_flashes_toggled.connect(_on_reduced_flashes_toggled)
	_settings_overlay.set_reduced_flashes(_reduced_flashes)
	return true


func set_reduced_flashes(value: bool, persist: bool = true) -> void:
	var changed := _reduced_flashes != value
	_reduced_flashes = value
	if is_instance_valid(_settings_overlay):
		_settings_overlay.set_reduced_flashes(_reduced_flashes)
	if persist:
		_save_settings()
	if changed:
		settings_changed.emit(_reduced_flashes)


func is_reduced_flashes_enabled() -> bool:
	return _reduced_flashes


func reload() -> void:
	_load_settings()
	if is_instance_valid(_settings_overlay):
		_settings_overlay.set_reduced_flashes(_reduced_flashes)
	settings_changed.emit(_reduced_flashes)


func _load_settings() -> void:
	_reduced_flashes = false
	var config := ConfigFile.new()
	if config.load(settings_path) != OK:
		return
	_reduced_flashes = bool(config.get_value(
		SETTINGS_SECTION,
		REDUCED_FLASHES_KEY,
		false
	))


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value(SETTINGS_SECTION, REDUCED_FLASHES_KEY, _reduced_flashes)
	var error := config.save(settings_path)
	if error != OK:
		push_warning(
			"VisualAccessibilitySettings: impossibile salvare %s (errore %d)."
			% [settings_path, error]
		)


func _disconnect_settings_overlay() -> void:
	if not is_instance_valid(_settings_overlay):
		_settings_overlay = null
		return
	if _settings_overlay.reduced_flashes_toggled.is_connected(_on_reduced_flashes_toggled):
		_settings_overlay.reduced_flashes_toggled.disconnect(_on_reduced_flashes_toggled)
	_settings_overlay = null


func _on_reduced_flashes_toggled(value: bool) -> void:
	set_reduced_flashes(value)
