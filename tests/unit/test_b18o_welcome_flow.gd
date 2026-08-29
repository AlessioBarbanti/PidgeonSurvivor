extends GutGameplayTest

const WELCOME_BACKGROUND_PATH := "res://assets/art/ui/welcome/welcome_ability_cast_background.png"
const WELCOME_LOGO_PATH := "res://assets/art/ui/welcome/welcome_logo.png"
const WELCOME_MANIFEST_PATH := "res://assets/art/ui/welcome/ASSET-MANIFEST.md"
const CHARACTER_SELECT_CTA_PATH := "res://assets/art/ui/character_select/character_select_cta_base.png"
const WELCOME_BACKGROUND_SHA256 := "fe721f5a98048fb8db4093700af50b0ac9a070b1af92582b4b16059d9d8f1ba9"
const WELCOME_LOGO_SHA256 := "c2a63add4753ece374cf673d636d12cce55e55cd43624aed645bf8f5c347fa9f"
const LAYOUT_PROFILES := [
	Vector2i(1280, 720),
	Vector2i(1600, 720),
	Vector2i(960, 720),
]


func test_welcome_flow_contract() -> void:
	get_tree().root.content_scale_size = INITIAL_VIEWPORT_SIZE
	get_tree().root.size = INITIAL_VIEWPORT_SIZE
	await wait_process_frames(2)

	assert_eq(
		ProjectSettings.get_setting("application/config/name", ""), "Pidgeon Survivor",
		"Il nome pubblico del progetto deve essere Pidgeon Survivor."
	)
	assert_eq(
		ProjectSettings.get_setting("application/config/description", ""), "It's grilling time!",
		"Il sottotitolo pubblico del progetto deve essere esatto."
	)
	ProjectSettings.set_setting("application/run/b18o_force_welcome_for_test", true)
	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	add_child_autofree(movement_slice)
	ProjectSettings.set_setting("application/run/b18o_force_welcome_for_test", false)
	await wait_process_frames(2)

	var controller := movement_slice.get_run_controller() as RunController
	var welcome := movement_slice.get_welcome_screen() as WelcomeScreen
	var selector := movement_slice.get_character_select_overlay() as CharacterSelectOverlay
	var lifecycle := movement_slice.get_platform_lifecycle() as PlatformLifecycle
	var audio := movement_slice.get_game_audio() as GameAudio
	var visual_settings := movement_slice.get_visual_accessibility_settings() as VisualAccessibilitySettings
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	var router := movement_slice.get_node("InputRouter") as InputRouter
	var joystick := movement_slice.get_node("UI/SafeAreaRoot/TouchJoystick") as TouchJoystick
	var hud := movement_slice.get_hud() as GameHud
	var player := movement_slice.get_player() as Player

	assert_true(
		controller != null and welcome != null and selector != null, "Il frontend B18O deve essere composto."
	)
	if controller == null or welcome == null or selector == null:
		return

	assert_eq(controller.get_state(), RunController.RunState.BOOT, "Il cold launch B18O deve restare in BOOT.")
	assert_eq(controller.get_seed(), 0, "La welcome non deve inizializzare il seed della run.")
	assert_true(is_zero_approx(controller.get_run_time()), "La welcome non deve inizializzare il clock.")
	controller._process(5.0)
	assert_true(is_zero_approx(controller.get_run_time()), "Il clock non deve avanzare dietro la welcome.")
	assert_eq(spawner.get_alive_count(), 0, "Lo spawn deve restare vuoto dietro la welcome.")
	assert_true(router.is_input_suspended(), "L'input gameplay deve restare sospeso dietro la welcome.")
	assert_true(welcome.visible and not selector.visible, "Il cold launch deve mostrare solo la welcome.")
	assert_true(
		not hud.visible and not joystick.visible, "HUD e joystick non devono apparire dietro la welcome."
	)
	assert_false(joystick.is_active(), "Il joystick non deve possedere un dito in BOOT.")
	_assert_visual_asset(welcome)

	var play_button := welcome.get_play_button()
	var settings_button := welcome.get_settings_button()
	var close_settings_button := welcome.get_close_settings_button()
	assert_true(
		play_button != null and settings_button != null,
		"La welcome deve esporre GIOCA e l'ingranaggio impostazioni."
	)
	assert_not_null(close_settings_button, "Le impostazioni devono esporre INDIETRO.")
	if play_button == null or settings_button == null or close_settings_button == null:
		return
	for button in [play_button, settings_button, close_settings_button]:
		assert_true(
			button.custom_minimum_size.y >= 44.0, "Le azioni B18O devono conservare target touch validi."
		)
	assert_eq(
		settings_button.tooltip_text, "Impostazioni", "L'ingranaggio B32 deve conservare un nome accessibile."
	)
	for button in [play_button, settings_button, close_settings_button]:
		assert_true(
			button.get_theme_stylebox("focus") is StyleBoxEmpty and button.get_theme_stylebox("pressed") != null,
			"I pulsanti B32 non devono disegnare un riquadro focus e devono conservare pressed."
		)
	var cta_style := play_button.get_theme_stylebox("normal") as StyleBoxTexture
	var cta_atlas := cta_style.texture as AtlasTexture if cta_style != null else null
	assert_true(
		cta_atlas != null and cta_atlas.atlas != null and cta_atlas.atlas.resource_path == CHARACTER_SELECT_CTA_PATH,
		"GIOCA B32 deve riusare la placca pixel-fantasy del CTA B18W."
	)
	var actions_frame := welcome.get_actions_frame()
	assert_true(
		actions_frame != null and actions_frame.get_theme_stylebox("panel") is StyleBoxEmpty,
		"Il CTA B32 deve restare flottante, senza un riquadro esterno."
	)
	await wait_process_frames(1)
	assert_eq(
		get_tree().root.gui_get_focus_owner(), play_button, "GIOCA deve ricevere il focus iniziale."
	)

	await _assert_layout_profiles(movement_slice, welcome)

	settings_button.pressed.emit()
	await wait_process_frames(2)
	assert_true(welcome.is_settings_visible(), "IMPOSTAZIONI deve aprire i controlli persistenti.")
	assert_false(
		welcome.is_title_plaque_visible(),
		"Le impostazioni devono liberare lo spazio dell'insegna per non coprire il cast."
	)
	assert_true(lifecycle.request_back(), "Back deve chiudere le impostazioni della welcome.")
	await wait_process_frames(2)
	assert_true(
		not welcome.is_settings_visible() and welcome.visible, "Back dalle impostazioni deve tornare alla welcome."
	)
	assert_true(
		welcome.is_title_plaque_visible(), "Back dalle impostazioni deve ripristinare l'insegna principale."
	)
	assert_eq(
		get_tree().root.gui_get_focus_owner(), settings_button, "Back deve restituire il focus a IMPOSTAZIONI."
	)

	var original_volume := audio.get_effects_volume()
	var original_muted := audio.is_muted()
	var original_reduced_flashes := visual_settings.is_reduced_flashes_enabled()
	settings_button.pressed.emit()
	await wait_process_frames(1)
	welcome.get_volume_slider().value = 0.35
	welcome.get_mute_check_button().button_pressed = true
	welcome.get_reduced_flashes_check_button().button_pressed = true
	await wait_process_frames(1)
	assert_true(is_equal_approx(audio.get_effects_volume(), 0.35), "Il volume welcome deve usare GameAudio.")
	assert_true(audio.is_muted(), "Il mute welcome deve usare GameAudio.")
	assert_true(
		visual_settings.is_reduced_flashes_enabled(), "Flash ridotti deve usare l'autorita persistente."
	)
	assert_true(
		is_equal_approx(movement_slice.get_pause_overlay().get_audio_volume(), 0.35),
		"Welcome e pausa devono restare sincronizzate."
	)
	assert_true(
		movement_slice.get_pause_overlay().is_reduced_flashes_enabled(),
		"L'accessibilita deve restare sincronizzata con la pausa."
	)
	audio.set_effects_volume(original_volume)
	audio.set_muted(original_muted)
	visual_settings.set_reduced_flashes(original_reduced_flashes)
	close_settings_button.pressed.emit()
	await wait_process_frames(2)

	play_button.pressed.emit()
	await wait_process_frames(2)
	assert_eq(
		controller.get_state(), RunController.RunState.BOOT, "GIOCA deve aprire il selettore senza creare la run."
	)
	assert_true(selector.visible and not welcome.visible, "GIOCA deve sostituire la welcome con il selettore.")
	assert_true(
		controller.get_seed() == 0 and is_zero_approx(controller.get_run_time()),
		"Il selettore non deve creare clock o seed."
	)
	assert_true(
		spawner.get_alive_count() == 0 and router.is_input_suspended(),
		"Il gameplay deve restare inattivo nel selettore."
	)

	var back_button := selector.get_back_button()
	assert_true(
		back_button != null and back_button.custom_minimum_size.y >= 44.0,
		"Il selettore deve esporre INDIETRO touch."
	)
	if back_button != null:
		back_button.pressed.emit()
		await wait_process_frames(2)
		assert_true(welcome.visible and not selector.visible, "INDIETRO dal selettore deve riaprire la welcome.")
		assert_eq(
			controller.get_state(), RunController.RunState.BOOT, "Il ritorno alla welcome deve conservare BOOT."
		)

	play_button.pressed.emit()
	await wait_process_frames(2)
	assert_true(lifecycle.request_back(), "Android Back deve tornare dal selettore alla welcome.")
	await wait_process_frames(2)
	assert_true(welcome.visible and not selector.visible, "Back di piattaforma deve riaprire la welcome.")

	play_button.pressed.emit()
	await wait_process_frames(2)
	var bea_button := selector.get_button(&"bea")
	assert_not_null(bea_button, "Il selettore B18O deve contenere Bea.")
	if bea_button != null:
		bea_button.pressed.emit()
		selector.get_confirm_button().pressed.emit()
		await wait_process_frames(2)
		assert_true(controller.is_running(), "Solo la conferma del personaggio deve avviare la run.")
		assert_ne(controller.get_seed(), 0, "La run confermata deve ricevere un seed.")
		assert_eq(
			player.get_friend_definition().id, &"bea", "La run deve usare il personaggio confermato."
		)
		assert_true(not welcome.visible and not selector.visible, "La run deve chiudere il frontend B18O.")
		assert_true(hud.visible and joystick.visible, "La run confermata deve mostrare HUD e joystick.")
		assert_false(router.is_input_suspended(), "La conferma deve riattivare l'input gameplay.")

	if is_instance_valid(controller):
		controller.prepare_restart()


func _assert_visual_asset(welcome: WelcomeScreen) -> void:
	var background := welcome.get_background_texture()
	assert_not_null(background, "La welcome deve usare il fondale ImageGen approvato.")
	if background != null:
		var size := background.get_size()
		assert_eq(size, Vector2(1664.0, 936.0), "Il fondale welcome deve conservare le dimensioni registrate.")
		assert_true(
			absf(size.aspect() - (16.0 / 9.0)) < 0.01, "Il fondale welcome deve conservare il rapporto 16:9."
		)
	assert_true(FileAccess.file_exists(WELCOME_BACKGROUND_PATH), "Il PNG welcome deve esistere nel repository.")
	assert_eq(
		FileAccess.get_sha256(WELCOME_BACKGROUND_PATH), WELCOME_BACKGROUND_SHA256,
		"L'hash del fondale welcome deve corrispondere al manifest."
	)
	var logo := welcome.get_logo_texture()
	assert_not_null(logo, "La welcome deve usare il logo fornito dal proprietario.")
	if logo != null:
		assert_eq(
			logo.get_size(), Vector2(1536.0, 1024.0), "Il logo welcome deve conservare le dimensioni sorgente."
		)
	assert_true(FileAccess.file_exists(WELCOME_LOGO_PATH), "Il PNG del logo deve esistere nel repository.")
	assert_eq(
		FileAccess.get_sha256(WELCOME_LOGO_PATH), WELCOME_LOGO_SHA256,
		"L'hash del logo welcome deve corrispondere al manifest."
	)
	assert_true(FileAccess.file_exists(WELCOME_MANIFEST_PATH), "Il fondale welcome deve avere un manifest.")
	var manifest := FileAccess.get_file_as_string(WELCOME_MANIFEST_PATH)
	assert_true(manifest.contains("OpenAI ImageGen built-in"), "Il manifest deve registrare il generatore.")
	assert_true(manifest.contains(WELCOME_BACKGROUND_SHA256), "Il manifest deve registrare lo SHA-256 del PNG.")
	assert_true(manifest.contains(WELCOME_LOGO_SHA256), "Il manifest deve registrare lo SHA-256 del logo.")


func _assert_layout_profiles(movement_slice: Control, welcome: WelcomeScreen) -> void:
	for profile in LAYOUT_PROFILES:
		get_tree().root.content_scale_size = profile
		get_tree().root.size = profile
		await wait_process_frames(2)
		var arena := movement_slice.get_node("ArenaLayout") as ArenaLayout
		arena.refresh_layout()
		await wait_process_frames(2)
		var viewport_rect := get_tree().root.get_visible_rect()
		var safe_area := arena.get_safe_area_rect()
		var panel_rect := welcome.get_content_panel_rect()
		var title_rect := welcome.get_title_plaque_rect()
		var logo_rect := welcome.get_logo_rect()
		var actions_rect := welcome.get_actions_frame_rect()
		var gear_rect := welcome.get_settings_button_rect()
		assert_true(panel_rect.has_area(), "%s: il pannello welcome deve avere area." % profile)
		assert_true(title_rect.has_area(), "%s: l'insegna titolo deve avere area." % profile)
		assert_true(logo_rect.has_area(), "%s: il logo deve avere area." % profile)
		assert_true(actions_rect.has_area(), "%s: il pannello azioni deve avere area." % profile)
		assert_true(gear_rect.has_area(), "%s: l'ingranaggio deve avere area." % profile)
		assert_true(safe_area.encloses(panel_rect), "%s: la welcome deve restare nella safe area." % profile)
		assert_true(safe_area.encloses(title_rect), "%s: l'insegna deve restare nella safe area." % profile)
		assert_true(
			viewport_rect.encloses(logo_rect), "%s: il logo decorativo deve restare nel viewport." % profile
		)
		assert_true(safe_area.encloses(actions_rect), "%s: le azioni devono restare nella safe area." % profile)
		assert_true(safe_area.encloses(gear_rect), "%s: l'ingranaggio deve restare nella safe area." % profile)
		assert_true(
			panel_rect.size.x <= safe_area.size.x, "%s: la welcome non deve debordare in larghezza." % profile
		)
		assert_true(
			panel_rect.size.y <= safe_area.size.y, "%s: la welcome non deve debordare in altezza." % profile
		)
		assert_true(
			title_rect.end.y <= actions_rect.position.y,
			"%s: insegna e azioni devono restare due blocchi distinti." % profile
		)
		assert_true(
			logo_rect.end.y <= actions_rect.position.y, "%s: il logo non deve sovrapporsi alle azioni." % profile
		)
		assert_true(
			not gear_rect.intersects(title_rect)
			and not gear_rect.intersects(logo_rect)
			and not gear_rect.intersects(actions_rect),
			"%s: logo, CTA e ingranaggio B32 non devono sovrapporsi." % profile
		)
	get_tree().root.content_scale_size = LAYOUT_PROFILES[0]
	get_tree().root.size = LAYOUT_PROFILES[0]
	await wait_process_frames(2)
