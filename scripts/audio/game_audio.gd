class_name GameAudio
extends Node

signal settings_changed(effects_volume: float, muted: bool)
signal cue_played(cue_id: StringName)

const DEFAULT_SETTINGS_PATH := "user://audio_settings.cfg"
const SETTINGS_SECTION := "audio"
const SFX_BUS_NAME := "SFX"
const MUSIC_BUS_NAME := "Music"
const PLAYER_POOL_SIZE := 12
const MINIMUM_LINEAR_VOLUME := 0.0001
const BACKGROUND_MUSIC_VOLUME_DB := -18.0

const SHOT := &"shot"
const HIT := &"hit"
const PLAYER_DAMAGE := &"player_damage"
const PICKUP := &"pickup"
const LEVEL_UP := &"level_up"
const ABILITY_ACTIVATE := &"ability_activate"
const ABILITY_READY := &"ability_ready"
const BOSS_WARNING := &"boss_warning"
const BOSS_ATTACK := &"boss_attack"
const UI_CONFIRM := &"ui_confirm"
const PAUSE := &"pause"
const RESUME := &"resume"
const VICTORY := &"victory"
const DEFEAT := &"defeat"

@export_range(0.0, 1.0, 0.05) var default_effects_volume := 0.8
@export_file("*.cfg") var settings_path := DEFAULT_SETTINGS_PATH

@export_group("Combat")
@export var shot_stream: AudioStream
@export var hit_stream: AudioStream
@export var player_damage_stream: AudioStream
@export var pickup_stream: AudioStream
@export var level_up_stream: AudioStream
@export var ability_activate_stream: AudioStream
@export var ability_ready_stream: AudioStream
@export var boss_warning_stream: AudioStream
@export var boss_attack_stream: AudioStream

@export_group("Interface")
@export var ui_confirm_stream: AudioStream
@export var pause_stream: AudioStream
@export var resume_stream: AudioStream
@export var victory_stream: AudioStream
@export var defeat_stream: AudioStream

@export_group("Background music")
@export var background_music_stream: AudioStream

@export_group("Diagnostics")
## Il driver headless non produce audio udibile e può trattenere playback OGG
## fino allo shutdown. Gli smoke verificano mapping e segnali senza allocarlo.
@export var signal_only_in_headless := true

var _effects_volume := 0.8
var _muted := false
var _players: Array[AudioStreamPlayer] = []
var _background_music_player: AudioStreamPlayer
var _next_player_index := 0
var _last_cue_ticks: Dictionary = {}
var _ability_cooldown_armed := false
var _configured := false
var _background_music_active := false
var _background_music_resume_position := 0.0

var _run_controller: RunController
var _player: Player
var _weapon_controller: WeaponController
var _ability_controller: AbilityController
var _experience_system: ExperienceSystem
var _boss_encounter: BossEncounter
var _upgrade_overlay: UpgradeOverlay
var _character_select_overlay: CharacterSelectOverlay
var _pause_overlay: PauseOverlay


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_sfx_bus()
	_ensure_music_bus()
	_build_player_pool()
	_build_background_music_player()
	_load_settings()
	_apply_settings()


func _exit_tree() -> void:
	stop_all()


func configure(
	run_controller: RunController,
	player: Player,
	weapon_controller: WeaponController,
	ability_controller: AbilityController,
	experience_system: ExperienceSystem,
	boss_encounter: BossEncounter,
	upgrade_overlay: UpgradeOverlay,
	character_select_overlay: CharacterSelectOverlay,
	pause_overlay: PauseOverlay
) -> bool:
	if (
		not is_instance_valid(run_controller)
		or not is_instance_valid(player)
		or not is_instance_valid(weapon_controller)
		or not is_instance_valid(ability_controller)
		or not is_instance_valid(experience_system)
		or not is_instance_valid(boss_encounter)
		or not is_instance_valid(upgrade_overlay)
		or not is_instance_valid(character_select_overlay)
		or not is_instance_valid(pause_overlay)
	):
		return false

	_run_controller = run_controller
	_player = player
	_weapon_controller = weapon_controller
	_ability_controller = ability_controller
	_experience_system = experience_system
	_boss_encounter = boss_encounter
	_upgrade_overlay = upgrade_overlay
	_character_select_overlay = character_select_overlay
	_pause_overlay = pause_overlay

	_connect_once(_run_controller.state_changed, _on_run_state_changed)
	_connect_once(_run_controller.run_ended, _on_run_ended)
	_connect_once(_run_controller.restart_prepared, _on_restart_prepared)
	_connect_once(_player.damaged, _on_player_damaged)
	_connect_once(_weapon_controller.projectile_fired, _on_projectile_fired)
	_connect_once(_ability_controller.ability_activated, _on_ability_activated)
	_connect_once(_ability_controller.readiness_changed, _on_ability_readiness_changed)
	_connect_once(_experience_system.experience_added, _on_experience_added)
	_connect_once(_experience_system.level_up_started, _on_level_up_started)
	_connect_once(_boss_encounter.boss_spawned, _on_boss_spawned)
	_connect_once(_boss_encounter.boss_intro_started, _on_boss_intro_started)
	_connect_once(_upgrade_overlay.selection_submitted, _on_upgrade_submitted)
	_connect_once(_character_select_overlay.friend_confirmed, _on_friend_confirmed)
	_connect_once(_pause_overlay.audio_volume_changed, _on_audio_volume_changed)
	_connect_once(_pause_overlay.audio_mute_toggled, _on_audio_mute_toggled)
	_pause_overlay.set_audio_settings(_effects_volume, _muted)
	_configured = true
	return true


func set_effects_volume(value: float, persist: bool = true) -> bool:
	if not is_finite(value):
		return false
	_effects_volume = clampf(value, 0.0, 1.0)
	_apply_settings()
	if persist:
		_save_settings()
	return true


func set_muted(value: bool, persist: bool = true) -> void:
	_muted = value
	_apply_settings()
	if persist:
		_save_settings()


func get_effects_volume() -> float:
	return _effects_volume


func is_muted() -> bool:
	return _muted


func is_configured() -> bool:
	return _configured


func get_player_pool_size() -> int:
	return _players.size()


func stop_all() -> void:
	for audio_player in _players:
		if not is_instance_valid(audio_player):
			continue
		audio_player.stop()
		audio_player.stream = null
	stop_background_music()


func has_complete_cue_set() -> bool:
	for cue_id in [
		SHOT,
		HIT,
		PLAYER_DAMAGE,
		PICKUP,
		LEVEL_UP,
		ABILITY_ACTIVATE,
		ABILITY_READY,
		BOSS_WARNING,
		BOSS_ATTACK,
		UI_CONFIRM,
		PAUSE,
		RESUME,
		VICTORY,
		DEFEAT,
	]:
		if get_stream_for_cue(cue_id) == null:
			return false
	return true


func has_background_music() -> bool:
	return background_music_stream != null


func is_background_music_active() -> bool:
	return _background_music_active


func is_background_music_looping() -> bool:
	if not background_music_stream is AudioStreamOggVorbis:
		return false
	var ogg_stream := background_music_stream as AudioStreamOggVorbis
	return ogg_stream.loop


func get_background_music_player() -> AudioStreamPlayer:
	return _background_music_player


func get_stream_for_cue(cue_id: StringName) -> AudioStream:
	match cue_id:
		SHOT:
			return shot_stream
		HIT:
			return hit_stream
		PLAYER_DAMAGE:
			return player_damage_stream
		PICKUP:
			return pickup_stream
		LEVEL_UP:
			return level_up_stream
		ABILITY_ACTIVATE:
			return ability_activate_stream
		ABILITY_READY:
			return ability_ready_stream
		BOSS_WARNING:
			return boss_warning_stream
		BOSS_ATTACK:
			return boss_attack_stream
		UI_CONFIRM:
			return ui_confirm_stream
		PAUSE:
			return pause_stream
		RESUME:
			return resume_stream
		VICTORY:
			return victory_stream
		DEFEAT:
			return defeat_stream
	return null


func get_active_voice_count() -> int:
	var active_count := 0
	for audio_player in _players:
		if is_instance_valid(audio_player) and audio_player.playing:
			active_count += 1
	return active_count


func get_voice_pool_size() -> int:
	return _players.size()


func play_cue(
	cue_id: StringName,
	volume_db: float = 0.0,
	minimum_interval_msec: int = 0
) -> bool:
	var stream := get_stream_for_cue(cue_id)
	if stream == null or _muted or _effects_volume <= 0.0 or _players.is_empty():
		return false
	var now := Time.get_ticks_msec()
	var last_played := int(_last_cue_ticks.get(cue_id, -minimum_interval_msec - 1))
	if minimum_interval_msec > 0 and now - last_played < minimum_interval_msec:
		return false
	_last_cue_ticks[cue_id] = now
	if signal_only_in_headless and DisplayServer.get_name() == "headless":
		cue_played.emit(cue_id)
		return true

	var audio_player := _acquire_player()
	audio_player.stream = stream
	audio_player.volume_db = volume_db
	audio_player.pitch_scale = 1.0
	audio_player.play()
	cue_played.emit(cue_id)
	return true


func _ensure_sfx_bus() -> void:
	var bus_index := AudioServer.get_bus_index(SFX_BUS_NAME)
	if bus_index < 0:
		AudioServer.add_bus()
		bus_index = AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus_index, SFX_BUS_NAME)
		AudioServer.set_bus_send(bus_index, "Master")


func _ensure_music_bus() -> void:
	var bus_index := AudioServer.get_bus_index(MUSIC_BUS_NAME)
	if bus_index < 0:
		AudioServer.add_bus()
		bus_index = AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus_index, MUSIC_BUS_NAME)
		AudioServer.set_bus_send(bus_index, "Master")


func _build_player_pool() -> void:
	if not _players.is_empty():
		return
	for index in PLAYER_POOL_SIZE:
		var audio_player := AudioStreamPlayer.new()
		audio_player.name = "SfxPlayer%02d" % index
		audio_player.bus = SFX_BUS_NAME
		audio_player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(audio_player)
		_players.append(audio_player)


func _build_background_music_player() -> void:
	if is_instance_valid(_background_music_player):
		return
	_background_music_player = AudioStreamPlayer.new()
	_background_music_player.name = "BackgroundMusicPlayer"
	_background_music_player.bus = MUSIC_BUS_NAME
	_background_music_player.volume_db = BACKGROUND_MUSIC_VOLUME_DB
	_background_music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_background_music_player)


func _acquire_player() -> AudioStreamPlayer:
	for offset in _players.size():
		var index := (_next_player_index + offset) % _players.size()
		if not _players[index].playing:
			_next_player_index = (index + 1) % _players.size()
			return _players[index]
	var fallback := _players[_next_player_index]
	_next_player_index = (_next_player_index + 1) % _players.size()
	return fallback


func _apply_settings() -> void:
	for bus_name in [SFX_BUS_NAME, MUSIC_BUS_NAME]:
		var bus_index := AudioServer.get_bus_index(bus_name)
		if bus_index < 0:
			continue
		AudioServer.set_bus_volume_db(
			bus_index,
			linear_to_db(maxf(_effects_volume, MINIMUM_LINEAR_VOLUME))
		)
		AudioServer.set_bus_mute(bus_index, _muted or _effects_volume <= 0.0)
	if is_instance_valid(_pause_overlay):
		_pause_overlay.set_audio_settings(_effects_volume, _muted)
	settings_changed.emit(_effects_volume, _muted)


func _load_settings() -> void:
	_effects_volume = clampf(default_effects_volume, 0.0, 1.0)
	_muted = false
	var config := ConfigFile.new()
	if config.load(settings_path) != OK:
		return
	var stored_volume: Variant = config.get_value(
		SETTINGS_SECTION,
		"effects_volume",
		_effects_volume
	)
	if stored_volume is float or stored_volume is int:
		var numeric_volume := float(stored_volume)
		if is_finite(numeric_volume):
			_effects_volume = clampf(numeric_volume, 0.0, 1.0)
	_muted = bool(config.get_value(SETTINGS_SECTION, "muted", false))


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value(SETTINGS_SECTION, "effects_volume", _effects_volume)
	config.set_value(SETTINGS_SECTION, "muted", _muted)
	var error := config.save(settings_path)
	if error != OK:
		push_warning("GameAudio: impossibile salvare le impostazioni audio (%d)." % error)


func _connect_once(source_signal: Signal, callable: Callable) -> void:
	if not source_signal.is_connected(callable):
		source_signal.connect(callable)


func _on_run_state_changed(previous_state: RunController.RunState, current_state: RunController.RunState) -> void:
	if current_state == RunController.RunState.RUNNING:
		start_background_music()
	elif previous_state == RunController.RunState.RUNNING:
		pause_background_music()
	elif current_state == RunController.RunState.BOOT or current_state in [
		RunController.RunState.VICTORY,
		RunController.RunState.DEFEAT,
	]:
		stop_background_music()

	if current_state == RunController.RunState.MANUAL_PAUSE:
		play_cue(PAUSE, -2.0)
	elif previous_state == RunController.RunState.MANUAL_PAUSE and current_state == RunController.RunState.RUNNING:
		play_cue(RESUME, -2.0)


func _on_run_ended(final_state: RunController.RunState, _run_time: float) -> void:
	stop_background_music()
	if final_state == RunController.RunState.VICTORY:
		play_cue(VICTORY, -1.0)
	elif final_state == RunController.RunState.DEFEAT:
		play_cue(DEFEAT, -1.0)


func _on_restart_prepared() -> void:
	stop_background_music()
	_ability_cooldown_armed = false
	_last_cue_ticks.clear()


func start_background_music() -> bool:
	if background_music_stream == null:
		return false
	if background_music_stream is AudioStreamOggVorbis:
		var ogg_stream := background_music_stream as AudioStreamOggVorbis
		ogg_stream.loop = true
	_background_music_active = true
	if signal_only_in_headless and DisplayServer.get_name() == "headless":
		return true
	if not is_instance_valid(_background_music_player):
		return false
	_background_music_player.stream = background_music_stream
	_background_music_player.play(_background_music_resume_position)
	return true


func pause_background_music() -> void:
	if not _background_music_active:
		return
	if is_instance_valid(_background_music_player) and _background_music_player.playing:
		_background_music_resume_position = _background_music_player.get_playback_position()
		_background_music_player.stop()
	_background_music_active = false


func stop_background_music() -> void:
	if is_instance_valid(_background_music_player):
		_background_music_player.stop()
		_background_music_player.stream = null
	_background_music_active = false
	_background_music_resume_position = 0.0


func _on_player_damaged(_player_value: Player, _amount: float, _health_current: float) -> void:
	play_cue(PLAYER_DAMAGE, -2.0, 100)


func _on_projectile_fired(projectile: Projectile, _target: BaseEnemy) -> void:
	play_cue(SHOT, -13.0, 65)
	if is_instance_valid(projectile):
		_connect_once(projectile.hit_processed, _on_projectile_hit)


func _on_projectile_hit(_target: BaseEnemy, _damage: float) -> void:
	play_cue(HIT, -8.0, 45)


func _on_experience_added(_amount: int, _experience_current: int) -> void:
	play_cue(PICKUP, -6.0, 55)


func _on_level_up_started(_level: int, _pending_choices: int) -> void:
	play_cue(LEVEL_UP, -1.0)


func _on_ability_activated(_definition: AbilityDefinition) -> void:
	_ability_cooldown_armed = true
	play_cue(ABILITY_ACTIVATE, -1.0)


func _on_ability_readiness_changed(is_ready: bool) -> void:
	if not is_ready:
		_ability_cooldown_armed = true
	elif _ability_cooldown_armed:
		_ability_cooldown_armed = false
		play_cue(ABILITY_READY, -2.0)


func _on_boss_spawned(boss: FirstBoss, _schedule_index: int) -> void:
	if not is_instance_valid(boss):
		return
	_connect_once(boss.attack_telegraphed, _on_boss_attack_telegraphed)
	_connect_once(boss.attack_executed, _on_boss_attack_executed)


func _on_boss_intro_started(_boss: FirstBoss, _schedule_index: int) -> void:
	play_cue(BOSS_WARNING, -1.0, 250)


func _on_boss_attack_telegraphed(
	_boss: FirstBoss,
	_pattern_id: StringName,
	_duration: float
) -> void:
	play_cue(BOSS_WARNING, -4.0, 250)


func _on_boss_attack_executed(
	_boss: FirstBoss,
	_pattern_id: StringName,
	_affected_count: int
) -> void:
	play_cue(BOSS_ATTACK, -3.0, 100)


func _on_upgrade_submitted(_upgrade_id: StringName) -> void:
	play_cue(UI_CONFIRM, -3.0)


func _on_friend_confirmed(_friend_id: StringName) -> void:
	play_cue(UI_CONFIRM, -3.0)


func _on_audio_volume_changed(value: float) -> void:
	set_effects_volume(value)


func _on_audio_mute_toggled(value: bool) -> void:
	set_muted(value)
