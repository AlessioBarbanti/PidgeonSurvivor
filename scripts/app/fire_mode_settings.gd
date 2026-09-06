class_name FireModeSettings
extends Node

## PS-085: modalita' di sparo persistente (Automatico/Manuale), stesso
## pattern di TouchControlSettings — impostazione condivisa fra welcome e
## pausa (PS-050), non un toggle in-run ne' una scelta per personaggio.
signal settings_changed(manual_enabled: bool)

const DEFAULT_SETTINGS_PATH := "user://fire_mode_settings.cfg"
const SETTINGS_SECTION := "fire_mode"
const MANUAL_ENABLED_KEY := "manual_enabled"
const DEFAULT_MANUAL_ENABLED := false

@export_file("*.cfg") var settings_path := DEFAULT_SETTINGS_PATH

var _manual_enabled := DEFAULT_MANUAL_ENABLED
var _welcome_screen: WelcomeScreen
var _pause_overlay: PauseOverlay


func _ready() -> void:
	_load_settings()


func _exit_tree() -> void:
	_disconnect_controls()


func configure(
	welcome_screen: WelcomeScreen,
	pause_overlay: PauseOverlay
) -> bool:
	_disconnect_controls()
	_welcome_screen = welcome_screen
	_pause_overlay = pause_overlay
	if not is_instance_valid(_welcome_screen) or not is_instance_valid(_pause_overlay):
		_disconnect_controls()
		return false
	_welcome_screen.fire_mode_toggled.connect(_on_fire_mode_toggled)
	_pause_overlay.fire_mode_toggled.connect(_on_fire_mode_toggled)
	_sync_controls()
	return true


func set_manual_fire_enabled(value: bool, persist: bool = true) -> void:
	var changed := value != _manual_enabled
	_manual_enabled = value
	_sync_controls()
	if persist:
		_save_settings()
	if changed:
		settings_changed.emit(_manual_enabled)


func is_manual_fire_enabled() -> bool:
	return _manual_enabled


func reload() -> void:
	_load_settings()
	_sync_controls()
	settings_changed.emit(_manual_enabled)


func _load_settings() -> void:
	_manual_enabled = DEFAULT_MANUAL_ENABLED
	var config := ConfigFile.new()
	if config.load(settings_path) != OK:
		return
	var stored_value: Variant = config.get_value(
		SETTINGS_SECTION,
		MANUAL_ENABLED_KEY,
		DEFAULT_MANUAL_ENABLED
	)
	if stored_value is bool:
		_manual_enabled = stored_value
	_save_settings()


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value(SETTINGS_SECTION, MANUAL_ENABLED_KEY, _manual_enabled)
	var error := config.save(settings_path)
	if error != OK:
		push_warning(
			"FireModeSettings: impossibile salvare %s (errore %d)."
			% [settings_path, error]
		)


func _sync_controls() -> void:
	if is_instance_valid(_welcome_screen):
		_welcome_screen.set_manual_fire_mode(_manual_enabled)
	if is_instance_valid(_pause_overlay):
		_pause_overlay.set_manual_fire_mode(_manual_enabled)


func _disconnect_controls() -> void:
	if is_instance_valid(_welcome_screen):
		if _welcome_screen.fire_mode_toggled.is_connected(_on_fire_mode_toggled):
			_welcome_screen.fire_mode_toggled.disconnect(_on_fire_mode_toggled)
	if is_instance_valid(_pause_overlay):
		if _pause_overlay.fire_mode_toggled.is_connected(_on_fire_mode_toggled):
			_pause_overlay.fire_mode_toggled.disconnect(_on_fire_mode_toggled)
	_welcome_screen = null
	_pause_overlay = null


func _on_fire_mode_toggled(manual_enabled: bool) -> void:
	set_manual_fire_enabled(manual_enabled)
