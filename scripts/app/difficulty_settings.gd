class_name DifficultySettings
extends Node

## PS-170: registro dei quattro profili di difficolta' piu' persistenza
## dell'id scelto, sullo stesso pattern ConfigFile di FireModeSettings. Un
## solo nodo invece di registry e settings separati: i profili sono dati
## statici dichiarati nella scena e l'unico stato mutevole e' quale id e'
## selezionato.
##
## Non conosce ne' RunController ne' i sistemi di spawn: espone la scelta,
## chi la fotografa all'avvio della run e' MovementSlice.
signal selection_changed(profile: DifficultyProfile)

const DEFAULT_SETTINGS_PATH := "user://difficulty_settings.cfg"
const SETTINGS_SECTION := "difficulty"
const PROFILE_ID_KEY := "profile_id"
const DEFAULT_PROFILE_ID := &"normal"

@export var profiles: Array[DifficultyProfile] = []
@export_file("*.cfg") var settings_path := DEFAULT_SETTINGS_PATH

var _selected_id := DEFAULT_PROFILE_ID


func _ready() -> void:
	_load_settings()


## Profili validi in ordine di dichiarazione, id duplicati scartati dopo il
## primo: l'ordine e' il contratto osservabile del selettore.
func get_profiles() -> Array[DifficultyProfile]:
	var valid: Array[DifficultyProfile] = []
	var seen_ids: Dictionary = {}
	for profile in profiles:
		if profile == null or not profile.is_valid() or seen_ids.has(profile.id):
			continue
		seen_ids[profile.id] = true
		valid.append(profile)
	return valid


func resolve_profile(profile_id: StringName) -> DifficultyProfile:
	for profile in get_profiles():
		if profile.id == profile_id:
			return profile
	return null


## Non torna mai null se esiste almeno un profilo valido: un id mancante o
## corrotto nel file di configurazione ricade su NORMALE, e se manca anche
## quello sul primo profilo dichiarato.
func get_selected_profile() -> DifficultyProfile:
	var profile := resolve_profile(_selected_id)
	if profile != null:
		return profile
	profile = resolve_profile(DEFAULT_PROFILE_ID)
	if profile != null:
		return profile
	var valid := get_profiles()
	return valid[0] if not valid.is_empty() else null


func get_selected_profile_id() -> StringName:
	var profile := get_selected_profile()
	return profile.id if profile != null else DEFAULT_PROFILE_ID


func select_profile(profile_id: StringName, persist: bool = true) -> bool:
	var profile := resolve_profile(profile_id)
	if profile == null:
		return false
	var changed := profile.id != _selected_id
	_selected_id = profile.id
	if persist:
		_save_settings()
	if changed:
		selection_changed.emit(profile)
	return true


func reload() -> void:
	_load_settings()
	var profile := get_selected_profile()
	if profile != null:
		selection_changed.emit(profile)


func _load_settings() -> void:
	_selected_id = DEFAULT_PROFILE_ID
	var config := ConfigFile.new()
	if config.load(settings_path) != OK:
		return
	var stored_value: Variant = config.get_value(
		SETTINGS_SECTION,
		PROFILE_ID_KEY,
		String(DEFAULT_PROFILE_ID)
	)
	if stored_value is String or stored_value is StringName:
		var stored_id := StringName(stored_value)
		if resolve_profile(stored_id) != null:
			_selected_id = stored_id
	_save_settings()


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value(SETTINGS_SECTION, PROFILE_ID_KEY, String(_selected_id))
	var error := config.save(settings_path)
	if error != OK:
		push_warning(
			"DifficultySettings: impossibile salvare %s (errore %d)."
			% [settings_path, error]
		)
