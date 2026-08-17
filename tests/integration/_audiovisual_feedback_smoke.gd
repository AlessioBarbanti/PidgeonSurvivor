extends SceneTree

const MOVEMENT_SLICE_SCENE := preload("res://scenes/game/movement_slice.tscn")
const TEST_SETTINGS_PATH := "user://b18_audio_settings_smoke.cfg"
const FLOAT_TOLERANCE := 0.01
const MINIMUM_TEXT_CONTRAST := 4.5
const INITIAL_VIEWPORT_SIZE := Vector2i(1280, 720)

var _failures: Array[String] = []
var _cue_count := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	await _validate_composed_feedback()
	await _validate_settings_persistence()
	await _finish()


func _validate_composed_feedback() -> void:
	root.content_scale_size = INITIAL_VIEWPORT_SIZE
	root.size = INITIAL_VIEWPORT_SIZE
	await _wait_processed_frame()

	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	root.add_child(movement_slice)
	await _wait_processed_frame()

	var audio := movement_slice.get_game_audio() as GameAudio
	var pause_overlay := movement_slice.get_pause_overlay() as PauseOverlay
	var ability_registry := movement_slice.get_ability_effect_registry() as AbilityEffectRegistry
	var upgrade_registry := movement_slice.get_upgrade_registry() as UpgradeRegistry
	var effects := movement_slice.get_ability_effect_parent() as Node2D
	var enemies := movement_slice.get_node_or_null("World/Enemies") as Node2D
	var player := movement_slice.get_node_or_null("World/Player") as Player
	var projectiles := movement_slice.get_projectile_parent() as Node2D
	var boss_projectiles := movement_slice.get_boss_projectile_parent() as Node2D
	var hud := movement_slice.get_hud() as GameHud

	_expect(audio != null, "B18 richiede un GameAudio scene-local.")
	_expect(pause_overlay != null, "B18 richiede i controlli audio nella pausa.")
	_expect(ability_registry != null, "B18 richiede il catalogo abilita per le icone.")
	_expect(upgrade_registry != null, "B18 richiede il catalogo upgrade per le icone.")
	_expect(effects != null, "B18 richiede un layer VFX esplicito.")
	_expect(enemies != null and player != null, "B18 richiede attori con layer espliciti.")
	_expect(projectiles != null and boss_projectiles != null, "B18 richiede layer proiettili espliciti.")
	_expect(hud != null, "B18 richiede l'HUD ad alto contrasto.")
	if (
		audio == null
		or pause_overlay == null
		or ability_registry == null
		or upgrade_registry == null
		or effects == null
		or enemies == null
		or player == null
		or projectiles == null
		or boss_projectiles == null
		or hud == null
	):
		paused = false
		movement_slice.queue_free()
		await process_frame
		return

	_expect(audio.is_configured(), "GameAudio deve essere collegato agli eventi runtime.")
	_expect(audio.has_complete_cue_set(), "Tutti i cue B18 devono avere uno stream importato.")
	_expect(audio.get_player_pool_size() == GameAudio.PLAYER_POOL_SIZE, "Il pool audio deve supportare cue concorrenti.")
	_expect(AudioServer.get_bus_index(GameAudio.SFX_BUS_NAME) >= 0, "Il bus SFX deve essere disponibile.")
	for cue_id in [
		GameAudio.SHOT,
		GameAudio.HIT,
		GameAudio.PLAYER_DAMAGE,
		GameAudio.PICKUP,
		GameAudio.LEVEL_UP,
		GameAudio.ABILITY_ACTIVATE,
		GameAudio.ABILITY_READY,
		GameAudio.BOSS_WARNING,
		GameAudio.BOSS_ATTACK,
		GameAudio.UI_CONFIRM,
		GameAudio.PAUSE,
		GameAudio.RESUME,
		GameAudio.VICTORY,
		GameAudio.DEFEAT,
	]:
		var stream := audio.get_stream_for_cue(cue_id)
		_expect(stream != null, "Cue audio mancante: %s." % cue_id)
		if stream != null:
			_expect(
				stream.resource_path.begins_with("res://assets/audio/third_party/kenney_b18/"),
				"Il cue %s deve provenire dal set CC0 tracciato." % cue_id
			)

	var initial_volume := audio.get_effects_volume()
	var initial_muted := audio.is_muted()
	_expect(audio.set_effects_volume(0.35, false), "Il volume B18 deve accettare un valore valido.")
	_expect_float_near(audio.get_effects_volume(), 0.35, "GameAudio deve conservare il volume lineare.")
	_expect_float_near(pause_overlay.get_audio_volume(), 0.35, "Lo slider deve seguire GameAudio.")
	audio.set_muted(false, false)
	_expect(not pause_overlay.is_audio_muted(), "Il controllo mute deve seguire GameAudio.")
	if not audio.cue_played.is_connected(_on_cue_played):
		audio.cue_played.connect(_on_cue_played)
	_expect(audio.play_cue(GameAudio.UI_CONFIRM), "Un cue valido deve essere riproducibile.")
	_expect(_cue_count == 1, "La riproduzione deve emettere un solo evento diagnostico.")
	audio.stop_all()
	audio.set_muted(true, false)
	_expect(pause_overlay.is_audio_muted(), "Il mute deve aggiornare la UI.")
	_expect(not audio.play_cue(GameAudio.LEVEL_UP), "Il mute deve bloccare nuovi cue.")
	audio.set_effects_volume(initial_volume, false)
	audio.set_muted(initial_muted, false)

	var ability_icon_paths: Dictionary = {}
	for definition in ability_registry.get_definitions():
		_expect(definition.icon != null, "Ogni attiva deve avere un'icona B18.")
		if definition.icon != null:
			var icon_path := definition.icon.resource_path
			_expect(not icon_path.ends_with("/icon.svg"), "Le attive non devono usare il logo generico.")
			ability_icon_paths[icon_path] = true
	_expect(ability_icon_paths.size() == 8, "Le otto attive devono avere silhouette dedicate.")
	for definition in upgrade_registry.get_definitions():
		_expect(
			definition.icon != null and not definition.icon.resource_path.ends_with("/icon.svg"),
			"Ogni upgrade deve usare un pittogramma B18: %s." % definition.id
		)

	_expect(effects.z_index < enemies.z_index, "Le aree alleate devono restare sotto i nemici.")
	_expect(effects.z_index < player.z_index, "Le aree alleate devono restare sotto il Player.")
	_expect(effects.z_index < boss_projectiles.z_index, "Le aree alleate non devono coprire i colpi Boss.")
	_expect(boss_projectiles.z_index > projectiles.z_index, "I colpi Boss devono avere la priorita visiva massima.")

	var top_band := hud.get_node("SafeMargins/TopStack/TopBand") as PanelContainer
	var level_label := hud.get_node(
		"SafeMargins/TopStack/TopBand/Content/IdentityBlock/HealthPanel/Content/StatsRow/LevelLabel"
	) as Label
	var panel_style := top_band.get_theme_stylebox("panel") as StyleBoxFlat
	_expect(panel_style != null, "La fascia HUD deve avere un fondo opaco leggibile.")
	if panel_style != null:
		var contrast := _contrast_ratio(
			level_label.get_theme_color("font_color"),
			panel_style.bg_color
		)
		_expect(
			contrast >= MINIMUM_TEXT_CONTRAST,
			"Il testo primario HUD deve superare 4.5:1, ottenuto %.2f:1." % contrast
		)
	_expect(
		pause_overlay.get_volume_slider().custom_minimum_size.y >= 44.0,
		"Lo slider volume deve restare un target touch ampio."
	)
	_expect(
		pause_overlay.get_mute_check_button().custom_minimum_size.y >= 44.0,
		"Il mute deve restare un target touch ampio."
	)
	_expect(FileAccess.file_exists("res://assets/audio/third_party/kenney_b18/LICENSE-interface.txt"), "Licenza Interface Sounds mancante.")
	_expect(FileAccess.file_exists("res://assets/audio/third_party/kenney_b18/LICENSE-impact.txt"), "Licenza Impact Sounds mancante.")
	_expect(FileAccess.file_exists("res://assets/audio/third_party/kenney_b18/LICENSE-jingles.txt"), "Licenza Music Jingles mancante.")

	var controller := movement_slice.get_run_controller() as RunController
	if controller != null:
		controller.prepare_restart()
	paused = false
	movement_slice.queue_free()
	await process_frame


func _validate_settings_persistence() -> void:
	var absolute_test_path := ProjectSettings.globalize_path(TEST_SETTINGS_PATH)
	if FileAccess.file_exists(TEST_SETTINGS_PATH):
		DirAccess.remove_absolute(absolute_test_path)

	var writer := GameAudio.new()
	writer.settings_path = TEST_SETTINGS_PATH
	root.add_child(writer)
	await process_frame
	_expect(writer.set_effects_volume(0.42), "Il mixer deve salvare il volume.")
	writer.set_muted(true)
	writer.queue_free()
	await process_frame

	var reader := GameAudio.new()
	reader.settings_path = TEST_SETTINGS_PATH
	root.add_child(reader)
	await process_frame
	_expect_float_near(reader.get_effects_volume(), 0.42, "Il volume deve sopravvivere a una nuova istanza.")
	_expect(reader.is_muted(), "Il mute deve sopravvivere a una nuova istanza.")
	reader.queue_free()
	await process_frame
	if FileAccess.file_exists(TEST_SETTINGS_PATH):
		var remove_error := DirAccess.remove_absolute(absolute_test_path)
		_expect(remove_error == OK, "La fixture deve ripulire il file impostazioni temporaneo.")


func _contrast_ratio(foreground: Color, background: Color) -> float:
	var foreground_luminance := _relative_luminance(foreground)
	var background_luminance := _relative_luminance(background)
	var lighter := maxf(foreground_luminance, background_luminance)
	var darker := minf(foreground_luminance, background_luminance)
	return (lighter + 0.05) / (darker + 0.05)


func _relative_luminance(color: Color) -> float:
	return (
		0.2126 * _linear_channel(color.r)
		+ 0.7152 * _linear_channel(color.g)
		+ 0.0722 * _linear_channel(color.b)
	)


func _linear_channel(value: float) -> float:
	return value / 12.92 if value <= 0.04045 else pow((value + 0.055) / 1.055, 2.4)


func _on_cue_played(_cue_id: StringName) -> void:
	_cue_count += 1


func _expect_float_near(actual: float, expected: float, message: String) -> void:
	_expect(
		absf(actual - expected) <= FLOAT_TOLERANCE,
		"%s Atteso %.2f, ottenuto %.2f." % [message, expected, actual]
	)


func _wait_processed_frame() -> void:
	await process_frame
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	paused = false
	await process_frame
	if _failures.is_empty():
		print("B18_AUDIOVISUAL_SMOKE_OK")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	printerr("B18_AUDIOVISUAL_SMOKE_FAIL count=%d" % _failures.size())
	quit(1)
