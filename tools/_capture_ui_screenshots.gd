extends SceneTree

## Utility di sviluppo (non un test): cattura le superfici UI principali per le
## revisioni visive. Guida la welcome, il selettore, la run, il level-up, il boss,
## la pausa e il terminale, salvando un PNG per stato.

const MOVEMENT_SLICE_SCENE := preload("res://scenes/game/movement_slice.tscn")
const BOSS_DEFINITION := preload("res://data/bosses/first_boss.tres")
## `exports/` è ignorato da git: le catture restano artefatti locali.
const OUT_DIR := "res://exports/ui-screenshots"
const VIEWPORT_SIZE := Vector2i(1280, 720)

var _slice: Control


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	paused = false
	root.content_scale_size = VIEWPORT_SIZE
	root.size = VIEWPORT_SIZE
	DisplayServer.window_set_size(VIEWPORT_SIZE)
	await _frames(4)

	ProjectSettings.set_setting("application/run/b18o_force_welcome_for_test", true)
	_slice = MOVEMENT_SLICE_SCENE.instantiate() as Control
	root.add_child(_slice)
	ProjectSettings.set_setting("application/run/b18o_force_welcome_for_test", false)
	await _frames(20)

	var welcome := _slice.get_welcome_screen() as WelcomeScreen
	var selector := _slice.get_character_select_overlay() as CharacterSelectOverlay
	var hud := _slice.get_hud() as GameHud
	var pause_overlay := _slice.get_pause_overlay() as PauseOverlay
	var end_screen := _slice.get_end_screen() as EndScreen
	var boss_ui := _slice.get_boss_ui() as BossUI
	var upgrade_overlay := _slice.get_upgrade_overlay() as UpgradeOverlay
	var experience := _slice.get_experience_system() as ExperienceSystem
	var controller := _slice.get_run_controller() as RunController

	await _shot("01_welcome")

	if welcome != null and welcome.get_settings_button() != null:
		welcome.get_settings_button().emit_signal("pressed")
		await _frames(12)
		await _shot("02_welcome_settings")
		if welcome.get_close_settings_button() != null:
			welcome.get_close_settings_button().emit_signal("pressed")
			await _frames(12)

	if welcome != null and welcome.get_play_button() != null:
		welcome.get_play_button().emit_signal("pressed")
		await _frames(30)
		await _shot("03_character_select")

	if selector != null and selector.get_confirm_button() != null:
		selector.get_confirm_button().emit_signal("pressed")
		await _frames(10)
		await _timeout(4.0)
		await _shot("04_gameplay_hud")

	if experience != null:
		experience.add_experience(40)
		await _frames(24)
		await _shot("05_upgrade_overlay")
		if upgrade_overlay != null and upgrade_overlay.is_accepting_selection():
			upgrade_overlay.submit_card(0)
			await _frames(20)

	if boss_ui != null:
		boss_ui.show_intro(BOSS_DEFINITION)
		await _frames(24)
		await _shot("06_boss_intro")
		boss_ui.hide_intro()
		await _frames(10)

	if pause_overlay != null:
		pause_overlay.show_pause()
		await _frames(20)
		await _shot("07_pause_overlay")
		pause_overlay.hide_pause()
		await _frames(10)

	if end_screen != null:
		if controller != null:
			paused = false
		end_screen.show_defeat(187.0)
		await _frames(24)
		await _shot("08_end_screen")

	print("CAPTURE_DONE")
	quit(0)


func _shot(shot_name: String) -> void:
	await _frames(3)
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	var image := root.get_texture().get_image()
	if image == null:
		printerr("Nessuna immagine per %s" % shot_name)
		return
	var path := "%s/%s.png" % [OUT_DIR, shot_name]
	var error := image.save_png(path)
	print("SHOT %s -> %s (err %d)" % [shot_name, path, error])


func _frames(count: int) -> void:
	for _index in count:
		await process_frame


func _timeout(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout
