extends SceneTree

const MOVEMENT_SLICE_SCENE := preload("res://scenes/game/movement_slice.tscn")
const INITIAL_VIEWPORT_SIZE := Vector2i(1280, 720)
const WELCOME_BACKGROUND_PATH := "res://assets/art/ui/welcome/welcome_ability_cast_background.png"
const WELCOME_LOGO_PATH := "res://assets/art/ui/welcome/welcome_logo.png"
const WELCOME_MANIFEST_PATH := "res://assets/art/ui/welcome/ASSET-MANIFEST.md"
const WELCOME_BACKGROUND_SHA256 := "93f85fd7f2a76f889a56961ed17dde667e0c8621ee085fe402aa0349f17c24d0"
const WELCOME_LOGO_SHA256 := "c2a63add4753ece374cf673d636d12cce55e55cd43624aed645bf8f5c347fa9f"
const LAYOUT_PROFILES := [
	Vector2i(1280, 720),
	Vector2i(1600, 720),
	Vector2i(960, 720),
]

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	paused = false
	root.content_scale_size = INITIAL_VIEWPORT_SIZE
	root.size = INITIAL_VIEWPORT_SIZE
	await _wait_processed_frame()
	await _validate_welcome_flow()
	await _finish()


func _validate_welcome_flow() -> void:
	_expect(
		ProjectSettings.get_setting("application/config/name", "") == "Pidgeon Survivor",
		"Il nome pubblico del progetto deve essere Pidgeon Survivor."
	)
	_expect(
		ProjectSettings.get_setting("application/config/description", "") == "It's grilling time!",
		"Il sottotitolo pubblico del progetto deve essere esatto."
	)
	ProjectSettings.set_setting(
		"application/run/b18o_force_welcome_for_test",
		true
	)
	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	root.add_child(movement_slice)
	ProjectSettings.set_setting(
		"application/run/b18o_force_welcome_for_test",
		false
	)
	await _wait_processed_frame()

	var controller := movement_slice.get_run_controller() as RunController
	var welcome := movement_slice.get_welcome_screen() as WelcomeScreen
	var selector := movement_slice.get_character_select_overlay() as CharacterSelectOverlay
	var lifecycle := movement_slice.get_platform_lifecycle() as PlatformLifecycle
	var audio := movement_slice.get_game_audio() as GameAudio
	var visual_settings := (
		movement_slice.get_visual_accessibility_settings()
		as VisualAccessibilitySettings
	)
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	var router := movement_slice.get_node("InputRouter") as InputRouter
	var joystick := movement_slice.get_node("UI/SafeAreaRoot/TouchJoystick") as TouchJoystick
	var hud := movement_slice.get_hud() as GameHud
	var player := movement_slice.get_player() as Player

	_expect(controller != null and welcome != null and selector != null, "Il frontend B18O deve essere composto.")
	if controller == null or welcome == null or selector == null:
		await _dispose(movement_slice, controller)
		return

	_expect(controller.get_state() == RunController.RunState.BOOT, "Il cold launch B18O deve restare in BOOT.")
	_expect(controller.get_seed() == 0, "La welcome non deve inizializzare il seed della run.")
	_expect(is_zero_approx(controller.get_run_time()), "La welcome non deve inizializzare il clock.")
	controller._process(5.0)
	_expect(is_zero_approx(controller.get_run_time()), "Il clock non deve avanzare dietro la welcome.")
	_expect(spawner.get_alive_count() == 0, "Lo spawn deve restare vuoto dietro la welcome.")
	_expect(router.is_input_suspended(), "L'input gameplay deve restare sospeso dietro la welcome.")
	_expect(welcome.visible and not selector.visible, "Il cold launch deve mostrare solo la welcome.")
	_expect(not hud.visible and not joystick.visible, "HUD e joystick non devono apparire dietro la welcome.")
	_expect(not joystick.is_active(), "Il joystick non deve possedere un dito in BOOT.")
	_validate_visual_asset(welcome)

	var play_button := welcome.get_play_button()
	var settings_button := welcome.get_settings_button()
	var close_settings_button := welcome.get_close_settings_button()
	_expect(play_button != null and settings_button != null, "La welcome deve esporre GIOCA e IMPOSTAZIONI.")
	_expect(close_settings_button != null, "Le impostazioni devono esporre INDIETRO.")
	if play_button == null or settings_button == null or close_settings_button == null:
		await _dispose(movement_slice, controller)
		return
	for button in [play_button, settings_button, close_settings_button]:
		_expect(button.custom_minimum_size.y >= 44.0, "Le azioni B18O devono conservare target touch validi.")
	await process_frame
	_expect(root.gui_get_focus_owner() == play_button, "GIOCA deve ricevere il focus iniziale.")

	await _validate_layout_profiles(movement_slice, welcome)

	settings_button.pressed.emit()
	await _wait_processed_frame()
	_expect(welcome.is_settings_visible(), "IMPOSTAZIONI deve aprire i controlli persistenti.")
	_expect(not welcome.is_title_plaque_visible(), "Le impostazioni devono liberare lo spazio dell'insegna per non coprire il cast.")
	_expect(lifecycle.request_back(), "Back deve chiudere le impostazioni della welcome.")
	await _wait_processed_frame()
	_expect(not welcome.is_settings_visible() and welcome.visible, "Back dalle impostazioni deve tornare alla welcome.")
	_expect(welcome.is_title_plaque_visible(), "Back dalle impostazioni deve ripristinare l'insegna principale.")
	_expect(root.gui_get_focus_owner() == settings_button, "Back deve restituire il focus a IMPOSTAZIONI.")

	var original_volume := audio.get_effects_volume()
	var original_muted := audio.is_muted()
	var original_reduced_flashes := visual_settings.is_reduced_flashes_enabled()
	settings_button.pressed.emit()
	await process_frame
	welcome.get_volume_slider().value = 0.35
	welcome.get_mute_check_button().button_pressed = true
	welcome.get_reduced_flashes_check_button().button_pressed = true
	await process_frame
	_expect(is_equal_approx(audio.get_effects_volume(), 0.35), "Il volume welcome deve usare GameAudio.")
	_expect(audio.is_muted(), "Il mute welcome deve usare GameAudio.")
	_expect(visual_settings.is_reduced_flashes_enabled(), "Flash ridotti deve usare l'autorita persistente.")
	_expect(is_equal_approx(movement_slice.get_pause_overlay().get_audio_volume(), 0.35), "Welcome e pausa devono restare sincronizzate.")
	_expect(movement_slice.get_pause_overlay().is_reduced_flashes_enabled(), "L'accessibilita deve restare sincronizzata con la pausa.")
	audio.set_effects_volume(original_volume)
	audio.set_muted(original_muted)
	visual_settings.set_reduced_flashes(original_reduced_flashes)
	close_settings_button.pressed.emit()
	await _wait_processed_frame()

	play_button.pressed.emit()
	await _wait_processed_frame()
	_expect(controller.get_state() == RunController.RunState.BOOT, "GIOCA deve aprire il selettore senza creare la run.")
	_expect(selector.visible and not welcome.visible, "GIOCA deve sostituire la welcome con il selettore.")
	_expect(controller.get_seed() == 0 and is_zero_approx(controller.get_run_time()), "Il selettore non deve creare clock o seed.")
	_expect(spawner.get_alive_count() == 0 and router.is_input_suspended(), "Il gameplay deve restare inattivo nel selettore.")

	var back_button := selector.get_back_button()
	_expect(back_button != null and back_button.custom_minimum_size.y >= 44.0, "Il selettore deve esporre INDIETRO touch.")
	if back_button != null:
		back_button.pressed.emit()
		await _wait_processed_frame()
		_expect(welcome.visible and not selector.visible, "INDIETRO dal selettore deve riaprire la welcome.")
		_expect(controller.get_state() == RunController.RunState.BOOT, "Il ritorno alla welcome deve conservare BOOT.")

	play_button.pressed.emit()
	await _wait_processed_frame()
	_expect(lifecycle.request_back(), "Android Back deve tornare dal selettore alla welcome.")
	await _wait_processed_frame()
	_expect(welcome.visible and not selector.visible, "Back di piattaforma deve riaprire la welcome.")

	play_button.pressed.emit()
	await _wait_processed_frame()
	var bea_button := selector.get_button(&"bea")
	_expect(bea_button != null, "Il selettore B18O deve contenere Bea.")
	if bea_button != null:
		bea_button.pressed.emit()
		selector.get_confirm_button().pressed.emit()
		await _wait_processed_frame()
		_expect(controller.is_running(), "Solo la conferma del personaggio deve avviare la run.")
		_expect(controller.get_seed() != 0, "La run confermata deve ricevere un seed.")
		_expect(player.get_friend_definition().id == &"bea", "La run deve usare il personaggio confermato.")
		_expect(not welcome.visible and not selector.visible, "La run deve chiudere il frontend B18O.")
		_expect(hud.visible and joystick.visible, "La run confermata deve mostrare HUD e joystick.")
		_expect(not router.is_input_suspended(), "La conferma deve riattivare l'input gameplay.")

	await _dispose(movement_slice, controller)


func _validate_visual_asset(welcome: WelcomeScreen) -> void:
	var background := welcome.get_background_texture()
	_expect(background != null, "La welcome deve usare il fondale ImageGen approvato.")
	if background != null:
		var size := background.get_size()
		_expect(size == Vector2(1634.0, 919.0), "Il fondale welcome deve conservare le dimensioni registrate.")
		_expect(absf(size.aspect() - (16.0 / 9.0)) < 0.01, "Il fondale welcome deve conservare il rapporto 16:9.")
	_expect(FileAccess.file_exists(WELCOME_BACKGROUND_PATH), "Il PNG welcome deve esistere nel repository.")
	_expect(
		FileAccess.get_sha256(WELCOME_BACKGROUND_PATH) == WELCOME_BACKGROUND_SHA256,
		"L'hash del fondale welcome deve corrispondere al manifest."
	)
	var logo := welcome.get_logo_texture()
	_expect(logo != null, "La welcome deve usare il logo fornito dal proprietario.")
	if logo != null:
		_expect(logo.get_size() == Vector2(1536.0, 1024.0), "Il logo welcome deve conservare le dimensioni sorgente.")
	_expect(FileAccess.file_exists(WELCOME_LOGO_PATH), "Il PNG del logo deve esistere nel repository.")
	_expect(
		FileAccess.get_sha256(WELCOME_LOGO_PATH) == WELCOME_LOGO_SHA256,
		"L'hash del logo welcome deve corrispondere al manifest."
	)
	_expect(FileAccess.file_exists(WELCOME_MANIFEST_PATH), "Il fondale welcome deve avere un manifest.")
	var manifest := FileAccess.get_file_as_string(WELCOME_MANIFEST_PATH)
	_expect(manifest.contains("OpenAI ImageGen built-in"), "Il manifest deve registrare il generatore.")
	_expect(manifest.contains(WELCOME_BACKGROUND_SHA256), "Il manifest deve registrare lo SHA-256 del PNG.")
	_expect(manifest.contains(WELCOME_LOGO_SHA256), "Il manifest deve registrare lo SHA-256 del logo.")


func _validate_layout_profiles(movement_slice: Control, welcome: WelcomeScreen) -> void:
	for profile in LAYOUT_PROFILES:
		root.content_scale_size = profile
		root.size = profile
		await _wait_processed_frame()
		var arena := movement_slice.get_node("ArenaLayout") as ArenaLayout
		arena.refresh_layout()
		await _wait_processed_frame()
		var safe_area := arena.get_safe_area_rect()
		var panel_rect := welcome.get_content_panel_rect()
		var title_rect := welcome.get_title_plaque_rect()
		var logo_rect := welcome.get_logo_rect()
		var actions_rect := welcome.get_actions_frame_rect()
		_expect(panel_rect.has_area(), "%s: il pannello welcome deve avere area." % profile)
		_expect(title_rect.has_area(), "%s: l'insegna titolo deve avere area." % profile)
		_expect(logo_rect.has_area(), "%s: il logo deve avere area." % profile)
		_expect(actions_rect.has_area(), "%s: il pannello azioni deve avere area." % profile)
		_expect(safe_area.encloses(panel_rect), "%s: la welcome deve restare nella safe area." % profile)
		_expect(safe_area.encloses(title_rect), "%s: l'insegna deve restare nella safe area." % profile)
		_expect(safe_area.encloses(logo_rect), "%s: il logo deve restare nella safe area." % profile)
		_expect(safe_area.encloses(actions_rect), "%s: le azioni devono restare nella safe area." % profile)
		_expect(panel_rect.size.x <= safe_area.size.x, "%s: la welcome non deve debordare in larghezza." % profile)
		_expect(panel_rect.size.y <= safe_area.size.y, "%s: la welcome non deve debordare in altezza." % profile)
		_expect(panel_rect.size.y <= safe_area.size.y * 0.72, "%s: la UI deve lasciare leggibile il cast inferiore." % profile)
		_expect(title_rect.end.y <= actions_rect.position.y, "%s: insegna e azioni devono restare due blocchi distinti." % profile)
		_expect(logo_rect.end.y <= actions_rect.position.y, "%s: il logo non deve sovrapporsi alle azioni." % profile)
	root.content_scale_size = INITIAL_VIEWPORT_SIZE
	root.size = INITIAL_VIEWPORT_SIZE
	await _wait_processed_frame()


func _dispose(movement_slice: Node, controller: RunController) -> void:
	if is_instance_valid(controller):
		controller.prepare_restart()
	paused = false
	if is_instance_valid(movement_slice):
		movement_slice.queue_free()
	await process_frame


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
		print("B18O_WELCOME_FLOW_SMOKE_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	printerr("B18O_WELCOME_FLOW_SMOKE_FAIL count=%d" % _failures.size())
	quit(1)
