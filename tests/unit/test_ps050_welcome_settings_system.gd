extends GutGameplayTest

## PS-050 — Le impostazioni della welcome devono leggere come la stessa
## schermata della pausa: componenti condivisi (PixelArcadeSlider /
## PixelArcadeToggle), pannello con cornice, sezioni nello stesso ordine e
## sincronizzazione dei valori con la persistenza condivisa. Il layout della
## pausa resta il riferimento e non viene toccato da questa card.

const PAUSE_PANEL_FRAME_PATH := "res://assets/art/ui/pause/pause_panel_frame.png"
const EXPECTED_SECTION_TITLES := ["AUDIO", "ACCESSIBILITÀ", "CONTROLLI TOUCH"]


func test_welcome_settings_system_contract() -> void:
	ProjectSettings.set_setting("application/run/b18o_force_welcome_for_test", true)
	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	add_child_autofree(movement_slice)
	ProjectSettings.set_setting("application/run/b18o_force_welcome_for_test", false)
	await wait_process_frames(2)

	var welcome := movement_slice.get_welcome_screen() as WelcomeScreen
	var pause_overlay := movement_slice.get_pause_overlay() as PauseOverlay
	var audio := movement_slice.get_game_audio() as GameAudio
	var visual_settings := movement_slice.get_visual_accessibility_settings() as VisualAccessibilitySettings
	var lifecycle := movement_slice.get_platform_lifecycle() as PlatformLifecycle
	assert_true(
		welcome != null and pause_overlay != null and audio != null and visual_settings != null,
		"Il frontend deve esporre welcome, pausa, audio e accessibilita'."
	)
	if welcome == null or pause_overlay == null or audio == null or visual_settings == null:
		return

	welcome.show_welcome()
	await wait_process_frames(2)
	welcome.get_settings_button().pressed.emit()
	await wait_process_frames(2)
	assert_true(welcome.is_settings_visible(), "IMPOSTAZIONI deve aprire il pannello.")

	_assert_shared_component(welcome.get_volume_slider(), "res://scripts/ui/pixel_arcade_slider.gd", "Volume")
	_assert_shared_component(
		welcome.get_ability_size_slider(), "res://scripts/ui/pixel_arcade_slider.gd", "Icona abilità"
	)
	_assert_shared_component(welcome.get_joystick_size_slider(), "res://scripts/ui/pixel_arcade_slider.gd", "Joystick")
	_assert_shared_component(welcome.get_mute_check_button(), "res://scripts/ui/pixel_arcade_toggle.gd", "Mute")
	_assert_shared_component(
		welcome.get_reduced_flashes_check_button(), "res://scripts/ui/pixel_arcade_toggle.gd", "Flash ridotti"
	)

	var panel := welcome.get_settings_panel()
	assert_true(panel != null, "Le impostazioni devono stare in un pannello, non sospese sullo sfondo.")
	if panel != null:
		var panel_style := panel.get_theme_stylebox(&"panel")
		assert_true(
			panel_style is StyleBoxTexture, "Il pannello deve avere una cornice texture, non uno stile vuoto."
		)
		if panel_style is StyleBoxTexture:
			assert_eq(
				(panel_style as StyleBoxTexture).texture.resource_path, PAUSE_PANEL_FRAME_PATH,
				"La cornice deve essere la stessa della pausa."
			)
		assert_true(
			(panel.size_flags_horizontal & Control.SIZE_EXPAND) == 0,
			"Il pannello deve restare una colonna compatta, non espandersi a riempire lo schermo."
		)

		var section_titles: Array[String] = []
		for label in panel.find_children("*Title", "Label", true, false):
			if (label as Label).text in EXPECTED_SECTION_TITLES:
				section_titles.append((label as Label).text)
		assert_eq(
			section_titles, EXPECTED_SECTION_TITLES,
			"Le sezioni devono chiamarsi ed essere ordinate come nella pausa: %s." % [EXPECTED_SECTION_TITLES]
		)

	var original_volume := audio.get_effects_volume()
	var original_muted := audio.is_muted()
	var original_reduced_flashes := visual_settings.is_reduced_flashes_enabled()

	# Multiplo esatto dello step (0.05) del PixelArcadeSlider: Range applica
	# stepify() sull'assegnazione, un valore non allineato farebbe fallire il
	# confronto anche a sincronizzazione corretta.
	welcome.get_volume_slider().value = 0.4
	welcome.get_mute_check_button().button_pressed = true
	welcome.get_reduced_flashes_check_button().button_pressed = true
	await wait_process_frames(1)
	assert_true(
		is_equal_approx(pause_overlay.get_audio_volume(), 0.4),
		"Un valore cambiato nella welcome deve leggersi identico in pausa."
	)
	assert_true(pause_overlay.is_audio_muted(), "Il mute deve restare sincronizzato con la pausa.")
	assert_true(
		pause_overlay.is_reduced_flashes_enabled(), "I flash ridotti devono restare sincronizzati con la pausa."
	)

	audio.set_effects_volume(original_volume)
	audio.set_muted(original_muted)
	visual_settings.set_reduced_flashes(original_reduced_flashes)
	await wait_process_frames(1)
	assert_true(
		is_equal_approx(welcome.get_volume_slider().value, original_volume),
		"Ripristinare il dato condiviso deve aggiornare anche lo slider della welcome."
	)

	assert_true(lifecycle.request_back(), "Back deve chiudere solo il pannello impostazioni.")
	await wait_process_frames(2)
	assert_true(
		not welcome.is_settings_visible() and welcome.visible,
		"Back dalle impostazioni deve tornare alla welcome, non chiudere la run."
	)
	assert_eq(
		get_tree().root.gui_get_focus_owner(), welcome.get_settings_button(),
		"Back deve restituire il focus a IMPOSTAZIONI."
	)

	print("WELCOME_SETTINGS_SYSTEM_SMOKE_OK")


func _assert_shared_component(control: Control, expected_script_path: String, label: String) -> void:
	assert_true(control != null, "%s deve esistere nel pannello impostazioni." % label)
	if control == null:
		return
	var script := control.get_script() as Script
	assert_true(
		script != null and script.resource_path == expected_script_path,
		"%s deve usare %s come la pausa." % [label, expected_script_path]
	)
