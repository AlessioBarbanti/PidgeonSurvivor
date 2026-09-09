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
const BACKGROUND_MUSIC_VOLUME_DB := -7.0
const MENU_MUSIC_VOLUME_DB := -9.0
## PS-073: leggermente sopra la musica di run cosi' il crossfade si legge come
## un'intensificazione, non come un cambio a parita' di energia.
const BOSS_MUSIC_VOLUME_DB := -5.0
const MUSIC_CROSSFADE_SILENCE_DB := -80.0
## PS-080: musica dedicata di fine run, un solo colpo, non in loop.
const END_RUN_MUSIC_VOLUME_DB := -4.0
## PS-056: quanto la musica di run scende sotto il proprio volume di base nei
## momenti chiave (countdown Boss, level-up, ricompensa Barb). Applicato come
## bersaglio assoluto, non cumulativo: più momenti sovrapposti restano allo
## stesso livello invece di sommarsi.
const MUSIC_DUCK_OFFSET_DB := -8.0
## PS-081: quanto più veloce (e quindi più acuta) suona la musica di run al
## culmine della curva late-run rispetto alla velocità normale (1.0). Tarabile
## dopo l'ascolto reale, come ogni altra costante di presentazione audio.
const MUSIC_LATE_RUN_MAX_PITCH_SCALE_OFFSET := 0.12

const SHOT := &"shot"
const HIT := &"hit"
const PLAYER_DAMAGE := &"player_damage"
const PICKUP := &"pickup"
const LEVEL_UP := &"level_up"
const ABILITY_ACTIVATE := &"ability_activate"
const ABILITY_READY := &"ability_ready"
const BOSS_WARNING := &"boss_warning"
const BOSS_ATTACK := &"boss_attack"
## PS-136: fanfara puntuale a ogni sconfitta di Boss, distinta da VICTORY
## (musica/cue di fine run) perche' un Boss puo' ricorrere nella stessa run.
const BOSS_VICTORY := &"boss_victory"
## Sesto Senso Equino di Bea (B45, asset integrato in PS-072).
const DODGE := &"dodge"
const UI_CONFIRM := &"ui_confirm"
const PAUSE := &"pause"
const RESUME := &"resume"
const VICTORY := &"victory"
const DEFEAT := &"defeat"
## PS-074: click generico dei bottoni UI senza un cue già dedicato (Gioca,
## Tutorial, Impostazioni, Precedente/Successivo, Indietro, Continua Boss,
## Riprova/Cambia personaggio...). Non sostituisce `UI_CONFIRM`/`PAUSE`/
## `RESUME`, che restano sui propri bottoni.
const UI_CLICK := &"ui_click"

## PS-056: chiavi dei momenti che chiedono un ducking della musica di run.
## Un Dictionary-as-set (`_music_duck_reasons`) permette a più momenti di
## sovrapporsi senza sommare l'abbassamento e senza ripristinare il volume
## finché anche solo uno resta attivo.
const DUCK_REASON_BOSS_WARNING := &"boss_warning"
const DUCK_REASON_LEVEL_UP := &"level_up"
const DUCK_REASON_BARB_REWARD := &"barb_reward"

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
@export var boss_victory_stream: AudioStream
@export var dodge_stream: AudioStream

@export_group("Interface")
@export var ui_confirm_stream: AudioStream
@export var ui_click_stream: AudioStream
@export var pause_stream: AudioStream
@export var resume_stream: AudioStream
@export var victory_stream: AudioStream
@export var defeat_stream: AudioStream

@export_group("Background music")
@export var background_music_stream: AudioStream
## Loop dei menu di BOOT (welcome, selezione personaggio, tutorial). Vive su un
## player separato da quello della run cosi' i due non si contendono lo stesso
## stato di riproduzione durante le transizioni.
@export var menu_music_stream: AudioStream
## Traccia Boss dedicata (PS-073): sostituisce la musica di run dall'intro
## (`boss_intro_started`) alla sconfitta (`boss_defeated`), con un crossfade
## fra le due tracce sul bus Music. Si ripete identica a ogni ricorrenza.
@export var boss_music_stream: AudioStream

@export_group("End run music")
## PS-080: breve traccia trionfale riprodotta una sola volta alla VICTORY,
## distinta dal cue SFX `VICTORY` esistente.
@export var victory_music_stream: AudioStream
## PS-080: breve traccia dimessa riprodotta una sola volta alla DEFEAT,
## distinta dal cue SFX `DEFEAT` esistente.
@export var defeat_music_stream: AudioStream

@export_group("Diagnostics")
## Il driver headless non produce audio udibile e può trattenere playback OGG
## fino allo shutdown. Gli smoke verificano mapping e segnali senza allocarlo.
@export var signal_only_in_headless := true

var _effects_volume := 0.8
var _muted := false
var _players: Array[AudioStreamPlayer] = []
var _background_music_player: AudioStreamPlayer
var _menu_music_player: AudioStreamPlayer
var _boss_music_player: AudioStreamPlayer
var _end_run_music_player: AudioStreamPlayer
var _next_player_index := 0
var _last_cue_ticks: Dictionary = {}
var _ability_cooldown_armed := false
var _configured := false
var _background_music_active := false
var _background_music_resume_position := 0.0
var _menu_music_active := false
var _boss_music_active := false
var _end_run_music_active := false
var _music_crossfade_tween: Tween
var _music_duck_reasons: Dictionary = {}
var _music_duck_tween: Tween
var _last_boss_warning_phase: GameDirector.BossWarningPhase = GameDirector.BossWarningPhase.HIDDEN

var _run_controller: RunController
var _game_director: GameDirector
var _player: Player
var _weapon_controller: WeaponController
var _ability_controller: AbilityController
var _experience_system: ExperienceSystem
var _boss_encounter: BossEncounter
var _upgrade_overlay: UpgradeOverlay
var _barb_reward_overlay: BarbRewardOverlay
var _character_select_overlay: CharacterSelectOverlay
var _pause_overlay: PauseOverlay
var _welcome_screen: WelcomeScreen
var _tutorial_screen: TutorialScreen
var _end_screen: EndScreen
var _boss_ui: BossUI
## PS-137: sostituisce `_pause_overlay` come sorgente di `audio_volume_changed`/
## `audio_mute_toggled` — un solo overlay condiviso invece di due nodi.
var _settings_overlay: SettingsOverlay


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_sfx_bus()
	_ensure_music_bus()
	_build_player_pool()
	_build_background_music_player()
	_build_menu_music_player()
	_build_boss_music_player()
	_build_end_run_music_player()
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
	barb_reward_overlay: BarbRewardOverlay,
	character_select_overlay: CharacterSelectOverlay,
	pause_overlay: PauseOverlay,
	game_director: GameDirector,
	welcome_screen: WelcomeScreen,
	tutorial_screen: TutorialScreen,
	end_screen: EndScreen,
	boss_ui: BossUI,
	settings_overlay: SettingsOverlay
) -> bool:
	if (
		not is_instance_valid(run_controller)
		or not is_instance_valid(player)
		or not is_instance_valid(weapon_controller)
		or not is_instance_valid(ability_controller)
		or not is_instance_valid(experience_system)
		or not is_instance_valid(boss_encounter)
		or not is_instance_valid(upgrade_overlay)
		or not is_instance_valid(barb_reward_overlay)
		or not is_instance_valid(character_select_overlay)
		or not is_instance_valid(pause_overlay)
		or not is_instance_valid(game_director)
		or not is_instance_valid(welcome_screen)
		or not is_instance_valid(tutorial_screen)
		or not is_instance_valid(end_screen)
		or not is_instance_valid(boss_ui)
		or not is_instance_valid(settings_overlay)
	):
		return false

	_run_controller = run_controller
	_player = player
	_weapon_controller = weapon_controller
	_ability_controller = ability_controller
	_experience_system = experience_system
	_boss_encounter = boss_encounter
	_upgrade_overlay = upgrade_overlay
	_barb_reward_overlay = barb_reward_overlay
	_character_select_overlay = character_select_overlay
	_pause_overlay = pause_overlay
	_game_director = game_director
	_welcome_screen = welcome_screen
	_tutorial_screen = tutorial_screen
	_end_screen = end_screen
	_boss_ui = boss_ui
	_settings_overlay = settings_overlay

	_connect_once(_run_controller.state_changed, _on_run_state_changed)
	_connect_once(_game_director.boss_warning_changed, _on_boss_warning_changed)
	_connect_once(_run_controller.run_time_changed, _on_run_time_changed)
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
	_connect_once(_boss_encounter.boss_defeated, _on_boss_defeated)
	_connect_once(_upgrade_overlay.selection_submitted, _on_upgrade_submitted)
	_connect_once(_barb_reward_overlay.selection_submitted, _on_upgrade_submitted)
	_connect_once(_character_select_overlay.friend_confirmed, _on_friend_confirmed)
	_connect_once(_settings_overlay.audio_volume_changed, _on_audio_volume_changed)
	_connect_once(_settings_overlay.audio_mute_toggled, _on_audio_mute_toggled)
	_settings_overlay.set_audio_settings(_effects_volume, _muted)
	_connect_once(_pause_overlay.ui_click_requested, _on_ui_click_requested)
	_connect_once(_character_select_overlay.ui_click_requested, _on_ui_click_requested)
	_connect_once(_welcome_screen.ui_click_requested, _on_ui_click_requested)
	_connect_once(_tutorial_screen.ui_click_requested, _on_ui_click_requested)
	_connect_once(_end_screen.ui_click_requested, _on_ui_click_requested)
	_connect_once(_boss_ui.ui_click_requested, _on_ui_click_requested)
	_connect_once(_settings_overlay.ui_click_requested, _on_ui_click_requested)
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
	stop_boss_music()
	stop_menu_music()
	stop_end_run_music()


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
		BOSS_VICTORY,
		DODGE,
		UI_CONFIRM,
		UI_CLICK,
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


func has_menu_music() -> bool:
	return menu_music_stream != null


func is_menu_music_active() -> bool:
	return _menu_music_active


func is_menu_music_looping() -> bool:
	if not menu_music_stream is AudioStreamOggVorbis:
		return false
	var ogg_stream := menu_music_stream as AudioStreamOggVorbis
	return ogg_stream.loop


func get_menu_music_player() -> AudioStreamPlayer:
	return _menu_music_player


func has_boss_music() -> bool:
	return boss_music_stream != null


func is_boss_music_active() -> bool:
	return _boss_music_active


func is_boss_music_looping() -> bool:
	return _is_stream_looping(boss_music_stream)


func get_boss_music_player() -> AudioStreamPlayer:
	return _boss_music_player


func has_victory_music() -> bool:
	return victory_music_stream != null


func has_defeat_music() -> bool:
	return defeat_music_stream != null


func is_end_run_music_active() -> bool:
	return _end_run_music_active


func get_end_run_music_player() -> AudioStreamPlayer:
	return _end_run_music_player


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
		BOSS_VICTORY:
			return boss_victory_stream
		DODGE:
			return dodge_stream
		UI_CONFIRM:
			return ui_confirm_stream
		UI_CLICK:
			return ui_click_stream
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


func _build_menu_music_player() -> void:
	if is_instance_valid(_menu_music_player):
		return
	_menu_music_player = AudioStreamPlayer.new()
	_menu_music_player.name = "MenuMusicPlayer"
	_menu_music_player.bus = MUSIC_BUS_NAME
	_menu_music_player.volume_db = MENU_MUSIC_VOLUME_DB
	_menu_music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_menu_music_player)


func _build_boss_music_player() -> void:
	if is_instance_valid(_boss_music_player):
		return
	_boss_music_player = AudioStreamPlayer.new()
	_boss_music_player.name = "BossMusicPlayer"
	_boss_music_player.bus = MUSIC_BUS_NAME
	_boss_music_player.volume_db = MUSIC_CROSSFADE_SILENCE_DB
	_boss_music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_boss_music_player)


func _build_end_run_music_player() -> void:
	if is_instance_valid(_end_run_music_player):
		return
	_end_run_music_player = AudioStreamPlayer.new()
	_end_run_music_player.name = "EndRunMusicPlayer"
	_end_run_music_player.bus = MUSIC_BUS_NAME
	_end_run_music_player.volume_db = END_RUN_MUSIC_VOLUME_DB
	_end_run_music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_end_run_music_player)


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
	if is_instance_valid(_settings_overlay):
		_settings_overlay.set_audio_settings(_effects_volume, _muted)
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


## PS-056: LEVEL_UP e BARB_REWARD non fermano piu' la musica di run come gli
## altri modal (MANUAL_PAUSE la ferma ancora, invariato) — la abbassano
## (ducking) lasciandola udibile sotto lo stinger, poi la restituiscono al
## volume di partenza alla chiusura.
func _on_run_state_changed(previous_state: RunController.RunState, current_state: RunController.RunState) -> void:
	if current_state == RunController.RunState.RUNNING:
		if not _boss_music_active and not _background_music_active:
			start_background_music()
		_clear_music_duck(DUCK_REASON_LEVEL_UP)
		_clear_music_duck(DUCK_REASON_BARB_REWARD)
	elif current_state == RunController.RunState.BOSS_INTRO and has_boss_music():
		# PS-073 possiede in esclusiva questa transizione: il crossfade verso
		# la traccia Boss parte da _on_boss_intro_started, non da qui.
		pass
	elif current_state == RunController.RunState.LEVEL_UP:
		_apply_music_duck(DUCK_REASON_LEVEL_UP)
	elif current_state == RunController.RunState.BARB_REWARD:
		_apply_music_duck(DUCK_REASON_BARB_REWARD)
		play_cue(LEVEL_UP, -1.0)
	elif previous_state == RunController.RunState.RUNNING:
		pause_background_music()
	elif current_state == RunController.RunState.BOOT or current_state in [
		RunController.RunState.VICTORY,
		RunController.RunState.DEFEAT,
	]:
		stop_background_music()
		stop_boss_music()

	if current_state == RunController.RunState.MANUAL_PAUSE:
		play_cue(PAUSE, -2.0)
	elif previous_state == RunController.RunState.MANUAL_PAUSE and current_state == RunController.RunState.RUNNING:
		play_cue(RESUME, -2.0)


## PS-081: accelera la musica di run (mai la traccia Boss dedicata, PS-073)
## fra le soglie late-run già dichiarate da `EnemySpawnProfile`, invece di un
## secondo layer sincronizzato. `run_time_changed` emette solo mentre
## `RunController.is_running()`, quindi la velocità resta ferma da sola
## durante LEVEL_UP/BARB_REWARD/BOSS_INTRO e riprende da dove era senza
## bisogno di uno stato salvato a parte.
func _on_run_time_changed(run_time: float) -> void:
	if not is_instance_valid(_background_music_player):
		return
	var spawner := _game_director.get_enemy_spawner() if is_instance_valid(_game_director) else null
	var profile: EnemySpawnProfile = spawner.spawn_profile if is_instance_valid(spawner) else null
	if profile == null:
		return
	var start_seconds := profile.late_run_curve_start_seconds
	var full_seconds := profile.late_run_curve_full_seconds
	var progress := 0.0
	if full_seconds > start_seconds:
		progress = clampf((run_time - start_seconds) / (full_seconds - start_seconds), 0.0, 1.0)
	elif run_time >= start_seconds:
		progress = 1.0
	_background_music_player.pitch_scale = 1.0 + MUSIC_LATE_RUN_MAX_PITCH_SCALE_OFFSET * progress


func _on_run_ended(final_state: RunController.RunState, _run_time: float) -> void:
	stop_background_music()
	stop_boss_music()
	stop_menu_music()
	if final_state == RunController.RunState.VICTORY:
		play_cue(VICTORY, -1.0)
	elif final_state == RunController.RunState.DEFEAT:
		play_cue(DEFEAT, -1.0)
	start_end_run_music(final_state)


func _on_restart_prepared() -> void:
	stop_background_music()
	stop_boss_music()
	stop_end_run_music()
	_ability_cooldown_armed = false
	_last_cue_ticks.clear()


func start_background_music() -> bool:
	if background_music_stream == null:
		return false
	if background_music_stream is AudioStreamOggVorbis:
		var ogg_stream := background_music_stream as AudioStreamOggVorbis
		ogg_stream.loop = true
	stop_menu_music()
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
	if is_instance_valid(_background_music_player):
		# Un crossfade PS-073 in corso puo' aver abbassato il volume verso il
		# silenzio: ripristinalo cosi' la prossima partenza riparte al livello
		# nominale invece che muta.
		_background_music_player.volume_db = BACKGROUND_MUSIC_VOLUME_DB
	_background_music_active = false


## Idempotente per scelta: welcome, selezione personaggio e tutorial si
## alternano continuamente in BOOT e il loop deve restare continuo invece di
## ripartire da capo a ogni navigazione.
func start_menu_music() -> bool:
	if menu_music_stream == null:
		return false
	if _menu_music_active:
		return true
	if menu_music_stream is AudioStreamOggVorbis:
		var ogg_stream := menu_music_stream as AudioStreamOggVorbis
		ogg_stream.loop = true
	_menu_music_active = true
	if signal_only_in_headless and DisplayServer.get_name() == "headless":
		return true
	if not is_instance_valid(_menu_music_player):
		return false
	_menu_music_player.stream = menu_music_stream
	_menu_music_player.play()
	return true


func stop_menu_music() -> void:
	if is_instance_valid(_menu_music_player):
		_menu_music_player.stop()
		_menu_music_player.stream = null
	_menu_music_active = false


func stop_background_music() -> void:
	_kill_music_crossfade_tween()
	_reset_music_duck_state()
	if is_instance_valid(_background_music_player):
		_background_music_player.stop()
		_background_music_player.stream = null
		_background_music_player.volume_db = BACKGROUND_MUSIC_VOLUME_DB
		_background_music_player.pitch_scale = 1.0
	_background_music_active = false
	_background_music_resume_position = 0.0


## PS-073: crossfade dalla musica di run alla traccia Boss dedicata,
## innescato da `boss_intro_started`. Idempotente: una seconda chiamata
## mentre la sessione Boss e' gia' attiva non fa nulla.
func start_boss_music() -> bool:
	if _boss_music_active:
		return true
	if not has_boss_music():
		return false
	_boss_music_active = true
	_reset_music_duck_state()
	_enable_stream_loop(boss_music_stream)
	if signal_only_in_headless and DisplayServer.get_name() == "headless":
		if _background_music_active:
			pause_background_music()
		return true
	if not is_instance_valid(_boss_music_player):
		return false
	_kill_music_crossfade_tween()
	var background_was_playing := (
		is_instance_valid(_background_music_player) and _background_music_player.playing
	)
	_boss_music_player.stream = boss_music_stream
	_boss_music_player.volume_db = MUSIC_CROSSFADE_SILENCE_DB
	_boss_music_player.play()
	_music_crossfade_tween = create_tween()
	_music_crossfade_tween.set_parallel(true)
	_music_crossfade_tween.tween_property(
		_boss_music_player,
		"volume_db",
		BOSS_MUSIC_VOLUME_DB,
		PresentationTimings.BOSS_MUSIC_CROSSFADE_SECONDS
	)
	if background_was_playing:
		_music_crossfade_tween.tween_property(
			_background_music_player,
			"volume_db",
			MUSIC_CROSSFADE_SILENCE_DB,
			PresentationTimings.BOSS_MUSIC_CROSSFADE_SECONDS
		)
		_music_crossfade_tween.finished.connect(pause_background_music, CONNECT_ONE_SHOT)
	elif _background_music_active:
		pause_background_music()
	return true


## PS-073: crossfade dalla traccia Boss alla musica di run, innescato da
## `boss_defeated`. La musica di run riprende da
## `_background_music_resume_position`, non da capo — ma solo se lo stato e'
## ancora RUNNING quando questa funzione gira: `boss_defeated` puo' far
## scattare sincronamente la ricompensa Barb (BARB_REWARD) prima che questo
## handler venga eseguito (movement_slice.gd si connette allo stesso segnale
## prima di GameAudio.configure()). In quel caso la traccia Boss sfuma e basta
## silenziosamente: la musica di run riparte da sola, senza salto, quando lo
## stato torna RUNNING alla chiusura del modal (vedi _on_run_state_changed).
func end_boss_music() -> void:
	if not _boss_music_active:
		return
	_boss_music_active = false
	_reset_music_duck_state()
	var can_resume_run_music := (
		is_instance_valid(_run_controller)
		and _run_controller.get_state() == RunController.RunState.RUNNING
	)
	if signal_only_in_headless and DisplayServer.get_name() == "headless":
		if is_instance_valid(_boss_music_player):
			_boss_music_player.stream = null
		if can_resume_run_music:
			start_background_music()
		return
	if not can_resume_run_music or background_music_stream == null or not is_instance_valid(_background_music_player):
		_fade_out_boss_music_only()
		return
	_kill_music_crossfade_tween()
	var boss_was_playing := is_instance_valid(_boss_music_player) and _boss_music_player.playing
	_enable_stream_loop(background_music_stream)
	_background_music_player.stream = background_music_stream
	_background_music_player.volume_db = MUSIC_CROSSFADE_SILENCE_DB
	_background_music_player.play(_background_music_resume_position)
	_background_music_active = true
	_music_crossfade_tween = create_tween()
	_music_crossfade_tween.set_parallel(true)
	_music_crossfade_tween.tween_property(
		_background_music_player,
		"volume_db",
		BACKGROUND_MUSIC_VOLUME_DB,
		PresentationTimings.BOSS_MUSIC_CROSSFADE_SECONDS
	)
	if boss_was_playing:
		_music_crossfade_tween.tween_property(
			_boss_music_player,
			"volume_db",
			MUSIC_CROSSFADE_SILENCE_DB,
			PresentationTimings.BOSS_MUSIC_CROSSFADE_SECONDS
		)
	_music_crossfade_tween.finished.connect(stop_boss_music, CONNECT_ONE_SHOT)


## PS-073: interruzione immediata della sola traccia Boss, senza crossfade.
## Usata da restart e fine run (vittoria/sconfitta), dove nessuna delle due
## tracce deve restare attiva in sottofondo.
func stop_boss_music() -> void:
	_kill_music_crossfade_tween()
	_reset_music_duck_state()
	if is_instance_valid(_boss_music_player):
		_boss_music_player.stop()
		_boss_music_player.stream = null
		_boss_music_player.volume_db = MUSIC_CROSSFADE_SILENCE_DB
	_boss_music_active = false


## PS-080: avvia la musica dedicata di fine run (vittoria o sconfitta), un
## solo colpo non in loop. Il chiamante deve aver gia' interrotto qualunque
## altra musica (run, Boss, menu) prima di invocarla, cosi' le due non si
## sovrappongono mai.
func start_end_run_music(final_state: RunController.RunState) -> bool:
	var stream: AudioStream
	if final_state == RunController.RunState.VICTORY:
		stream = victory_music_stream
	elif final_state == RunController.RunState.DEFEAT:
		stream = defeat_music_stream
	if stream == null:
		return false
	_end_run_music_active = true
	if signal_only_in_headless and DisplayServer.get_name() == "headless":
		return true
	if not is_instance_valid(_end_run_music_player):
		return false
	_end_run_music_player.stream = stream
	_end_run_music_player.play()
	return true


## PS-080: interrompe la musica di fine run, usata da restart e shutdown.
func stop_end_run_music() -> void:
	if is_instance_valid(_end_run_music_player):
		_end_run_music_player.stop()
		_end_run_music_player.stream = null
	_end_run_music_active = false


## PS-073: sfuma solo la traccia Boss senza toccare quella di run, per il caso
## in cui `boss_defeated` trova la run gia' uscita da RUNNING (es. ricompensa
## Barb sincrona). La musica di run resta silenziosa fino al normale rientro
## in RUNNING gestito da _on_run_state_changed.
func _fade_out_boss_music_only() -> void:
	_kill_music_crossfade_tween()
	if not is_instance_valid(_boss_music_player) or not _boss_music_player.playing:
		stop_boss_music()
		return
	_music_crossfade_tween = create_tween()
	_music_crossfade_tween.tween_property(
		_boss_music_player,
		"volume_db",
		MUSIC_CROSSFADE_SILENCE_DB,
		PresentationTimings.BOSS_MUSIC_CROSSFADE_SECONDS
	)
	_music_crossfade_tween.finished.connect(stop_boss_music, CONNECT_ONE_SHOT)


func _kill_music_crossfade_tween() -> void:
	if is_instance_valid(_music_crossfade_tween):
		_music_crossfade_tween.kill()
	_music_crossfade_tween = null


## PS-056: vero se almeno un momento chiave sta abbassando la musica di run.
func is_music_ducked() -> bool:
	return not _music_duck_reasons.is_empty()


## PS-056: aggiunge `reason` all'insieme dei momenti attivi e riporta la
## musica di run al bersaglio ducked (idempotente: un secondo momento che si
## sovrappone non abbassa ulteriormente).
func _apply_music_duck(reason: StringName) -> void:
	_music_duck_reasons[reason] = true
	_update_music_duck(PresentationTimings.MUSIC_DUCK_DOWN_SECONDS)


## PS-056: rimuove `reason`; la musica risale al volume di base solo quando
## nessun altro momento resta attivo.
func _clear_music_duck(reason: StringName) -> void:
	if not _music_duck_reasons.erase(reason):
		return
	_update_music_duck(PresentationTimings.MUSIC_DUCK_UP_SECONDS)


## PS-056: azzera l'insieme dei momenti attivi senza animare il ritorno —
## usata dalle transizioni della traccia Boss e di fine run, che governano
## già loro stesse il volume del player e non devono contendersi il tween.
func _reset_music_duck_state() -> void:
	_music_duck_reasons.clear()
	_kill_music_duck_tween()


func _update_music_duck(duration_seconds: float) -> void:
	var player := _get_active_run_music_player()
	if not is_instance_valid(player):
		return
	var base_db := _get_base_volume_db_for_player(player)
	var target_db := base_db
	if not _music_duck_reasons.is_empty():
		target_db += MUSIC_DUCK_OFFSET_DB
	_kill_music_duck_tween()
	if signal_only_in_headless and DisplayServer.get_name() == "headless":
		player.volume_db = target_db
		return
	_music_duck_tween = create_tween()
	_music_duck_tween.tween_property(player, "volume_db", target_db, duration_seconds)


func _kill_music_duck_tween() -> void:
	if is_instance_valid(_music_duck_tween):
		_music_duck_tween.kill()
	_music_duck_tween = null


func _get_active_run_music_player() -> AudioStreamPlayer:
	if _boss_music_active and is_instance_valid(_boss_music_player):
		return _boss_music_player
	if _background_music_active and is_instance_valid(_background_music_player):
		return _background_music_player
	return null


func _get_base_volume_db_for_player(player: AudioStreamPlayer) -> float:
	if player == _boss_music_player:
		return BOSS_MUSIC_VOLUME_DB
	return BACKGROUND_MUSIC_VOLUME_DB


func _enable_stream_loop(stream: AudioStream) -> void:
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true


func _is_stream_looping(stream: AudioStream) -> bool:
	if stream is AudioStreamOggVorbis:
		return (stream as AudioStreamOggVorbis).loop
	if stream is AudioStreamMP3:
		return (stream as AudioStreamMP3).loop
	return false


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


## PS-056: `boss_warning_changed` copre l'avvertimento HUD (PS-005) che
## precede `BOSS_INTRO` a run ancora RUNNING — distinto dal cue BOSS_WARNING
## già suonato da `_on_boss_intro_started`/`_on_boss_attack_telegraphed`, che
## restano di competenza di PS-073 e non di questa card. Il ducking scatta
## solo all'ingresso in COUNTDOWN (non su APPROACHING, troppo anticipato per
## uno stinger) e si ritira quando la fase lascia COUNTDOWN.
func _on_boss_warning_changed(
	_schedule_index: int,
	phase: GameDirector.BossWarningPhase,
	_seconds_remaining: int
) -> void:
	if phase == _last_boss_warning_phase:
		return
	var was_countdown := _last_boss_warning_phase == GameDirector.BossWarningPhase.COUNTDOWN
	_last_boss_warning_phase = phase
	if phase == GameDirector.BossWarningPhase.COUNTDOWN:
		play_cue(BOSS_WARNING, -4.0, 250)
		_apply_music_duck(DUCK_REASON_BOSS_WARNING)
	elif was_countdown:
		_clear_music_duck(DUCK_REASON_BOSS_WARNING)


func _on_boss_intro_started(_boss: FirstBoss, _schedule_index: int) -> void:
	play_cue(BOSS_WARNING, -1.0, 250)
	start_boss_music()


func _on_boss_defeated(_boss: FirstBoss) -> void:
	play_cue(BOSS_VICTORY, -1.0)
	end_boss_music()


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


## PS-074: emesso da `ui_click_requested` di ciascun overlay/schermata, un
## solo handler condiviso. Il debounce (`minimum_interval_msec`) copre
## pressioni ravvicinate sullo stesso bottone (es. Precedente/Successivo
## tenuti premuti) senza introdurre logica specifica per overlay.
func _on_ui_click_requested() -> void:
	play_cue(UI_CLICK, -5.0, 80)


func _on_audio_volume_changed(value: float) -> void:
	set_effects_volume(value)


func _on_audio_mute_toggled(value: bool) -> void:
	set_muted(value)
