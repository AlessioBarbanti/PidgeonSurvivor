extends GutGameplayTest

const TEST_SETTINGS_PATH := "user://b18_audio_settings_smoke.cfg"
const AUDIO_FLOAT_TOLERANCE := 0.01
const MINIMUM_TEXT_CONTRAST := 4.5

var _cue_count := 0


func test_composed_feedback_contract() -> void:
	var movement_slice := await instantiate_movement_slice()

	var audio := movement_slice.get_game_audio() as GameAudio
	var pause_overlay := movement_slice.get_pause_overlay() as PauseOverlay
	var settings_overlay := movement_slice.get_settings_overlay() as SettingsOverlay
	var ability_registry := movement_slice.get_ability_effect_registry() as AbilityEffectRegistry
	var upgrade_registry := movement_slice.get_upgrade_registry() as UpgradeRegistry
	var effects := movement_slice.get_ability_effect_parent() as Node2D
	var enemies := movement_slice.get_node_or_null("World/Enemies") as Node2D
	var player := movement_slice.get_node_or_null("World/Player") as Player
	var projectiles := movement_slice.get_projectile_parent() as Node2D
	var boss_projectiles := movement_slice.get_boss_projectile_parent() as Node2D
	var hud := movement_slice.get_hud() as GameHud

	assert_not_null(audio, "B18 richiede un GameAudio scene-local.")
	assert_not_null(pause_overlay, "B18 richiede la pausa.")
	assert_not_null(settings_overlay, "B18/PS-137 richiede l'overlay impostazioni condiviso.")
	assert_not_null(ability_registry, "B18 richiede il catalogo abilita per le icone.")
	assert_not_null(upgrade_registry, "B18 richiede il catalogo upgrade per le icone.")
	assert_not_null(effects, "B18 richiede un layer VFX esplicito.")
	assert_true(enemies != null and player != null, "B18 richiede attori con layer espliciti.")
	assert_true(
		projectiles != null and boss_projectiles != null, "B18 richiede layer proiettili espliciti."
	)
	assert_not_null(hud, "B18 richiede l'HUD ad alto contrasto.")
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
		or settings_overlay == null
	):
		return

	assert_true(audio.is_configured(), "GameAudio deve essere collegato agli eventi runtime.")
	assert_true(audio.has_complete_cue_set(), "Tutti i cue B18 devono avere uno stream importato.")
	assert_eq(
		audio.get_player_pool_size(), GameAudio.PLAYER_POOL_SIZE,
		"Il pool audio deve supportare cue concorrenti."
	)
	assert_true(
		AudioServer.get_bus_index(GameAudio.SFX_BUS_NAME) >= 0, "Il bus SFX deve essere disponibile."
	)
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
		assert_not_null(stream, "Cue audio mancante: %s." % cue_id)
		if stream != null:
			assert_true(
				stream.resource_path.begins_with("res://assets/audio/third_party/kenney_b18/"),
				"Il cue %s deve provenire dal set CC0 tracciato." % cue_id
			)

	var initial_volume := audio.get_effects_volume()
	var initial_muted := audio.is_muted()
	assert_true(audio.set_effects_volume(0.35, false), "Il volume B18 deve accettare un valore valido.")
	assert_almost_eq(
		audio.get_effects_volume(), 0.35, AUDIO_FLOAT_TOLERANCE, "GameAudio deve conservare il volume lineare."
	)
	assert_almost_eq(
		settings_overlay.get_audio_volume(), 0.35, AUDIO_FLOAT_TOLERANCE, "Lo slider deve seguire GameAudio."
	)
	audio.set_muted(false, false)
	assert_false(settings_overlay.is_audio_muted(), "Il controllo mute deve seguire GameAudio.")
	if not audio.cue_played.is_connected(_on_cue_played):
		audio.cue_played.connect(_on_cue_played)
	assert_true(audio.play_cue(GameAudio.UI_CONFIRM), "Un cue valido deve essere riproducibile.")
	assert_eq(_cue_count, 1, "La riproduzione deve emettere un solo evento diagnostico.")
	audio.stop_all()
	audio.set_muted(true, false)
	assert_true(settings_overlay.is_audio_muted(), "Il mute deve aggiornare la UI.")
	assert_false(audio.play_cue(GameAudio.LEVEL_UP), "Il mute deve bloccare nuovi cue.")
	audio.set_effects_volume(initial_volume, false)
	audio.set_muted(initial_muted, false)

	var ability_icon_paths: Dictionary = {}
	for definition in ability_registry.get_definitions():
		assert_not_null(definition.icon, "Ogni attiva deve avere un'icona B18.")
		if definition.icon != null:
			var icon_path := definition.icon.resource_path
			assert_false(icon_path.ends_with("/icon.svg"), "Le attive non devono usare il logo generico.")
			ability_icon_paths[icon_path] = true
	assert_eq(ability_icon_paths.size(), 8, "Le otto attive devono avere silhouette dedicate.")
	for definition in upgrade_registry.get_definitions():
		assert_true(
			definition.icon != null and not definition.icon.resource_path.ends_with("/icon.svg"),
			"Ogni upgrade deve usare un pittogramma B18: %s." % definition.id
		)

	assert_true(effects.z_index < enemies.z_index, "Le aree alleate devono restare sotto i nemici.")
	assert_true(effects.z_index < player.z_index, "Le aree alleate devono restare sotto il Player.")
	assert_true(
		effects.z_index < boss_projectiles.z_index, "Le aree alleate non devono coprire i colpi Boss."
	)
	assert_true(
		boss_projectiles.z_index > projectiles.z_index, "I colpi Boss devono avere la priorita visiva massima."
	)

	var time_label := hud.get_node("TopBand/TimerSlot/TimeLabel") as Label
	assert_null(hud.find_child("TimerPanel", true, false), "Il timer B18Q deve restare senza card.")
	var timer_contrast := _contrast_ratio(
		time_label.get_theme_color("font_color"), Color(0.02, 0.027, 0.047, 1.0)
	)
	assert_true(
		timer_contrast >= MINIMUM_TEXT_CONTRAST,
		"Il cronometro HUD deve superare 4.5:1, ottenuto %.2f:1." % timer_contrast
	)
	assert_true(
		settings_overlay.get_volume_slider().custom_minimum_size.y >= 44.0,
		"Lo slider volume deve restare un target touch ampio."
	)
	assert_true(
		settings_overlay.get_mute_check_button().custom_minimum_size.y >= 44.0,
		"Il mute deve restare un target touch ampio."
	)
	assert_true(
		FileAccess.file_exists("res://assets/audio/third_party/kenney_b18/LICENSE-interface.txt"),
		"Licenza Interface Sounds mancante."
	)
	assert_true(
		FileAccess.file_exists("res://assets/audio/third_party/kenney_b18/LICENSE-impact.txt"),
		"Licenza Impact Sounds mancante."
	)
	assert_true(
		FileAccess.file_exists("res://assets/audio/third_party/kenney_b18/LICENSE-jingles.txt"),
		"Licenza Music Jingles mancante."
	)

	var controller := movement_slice.get_run_controller() as RunController
	if controller != null:
		controller.prepare_restart()


func test_settings_persistence() -> void:
	var absolute_test_path := ProjectSettings.globalize_path(TEST_SETTINGS_PATH)
	if FileAccess.file_exists(TEST_SETTINGS_PATH):
		DirAccess.remove_absolute(absolute_test_path)

	var writer := GameAudio.new()
	writer.settings_path = TEST_SETTINGS_PATH
	add_child_autofree(writer)
	await wait_process_frames(1)
	assert_true(writer.set_effects_volume(0.42), "Il mixer deve salvare il volume.")
	writer.set_muted(true)
	writer.queue_free()
	await wait_process_frames(1)

	var reader := GameAudio.new()
	reader.settings_path = TEST_SETTINGS_PATH
	add_child_autofree(reader)
	await wait_process_frames(1)
	assert_almost_eq(
		reader.get_effects_volume(), 0.42, AUDIO_FLOAT_TOLERANCE, "Il volume deve sopravvivere a una nuova istanza."
	)
	assert_true(reader.is_muted(), "Il mute deve sopravvivere a una nuova istanza.")
	reader.queue_free()
	await wait_process_frames(1)
	if FileAccess.file_exists(TEST_SETTINGS_PATH):
		var remove_error := DirAccess.remove_absolute(absolute_test_path)
		assert_eq(remove_error, OK, "La fixture deve ripulire il file impostazioni temporaneo.")


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
