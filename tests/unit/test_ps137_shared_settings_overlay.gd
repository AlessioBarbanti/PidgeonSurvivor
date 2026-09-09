extends GutGameplayTest

## PS-137 — Overlay impostazioni condiviso, più grande e paginato per
## categoria: un solo nodo `SettingsOverlay`, apribile dal tasto ingranaggio
## sia della welcome sia della pausa, sempre la stessa istanza. Copre: istanza
## unica, apertura da entrambi i tasti, sincronizzazione dello stato, la tab
## che riparte sempre da AUDIO, Back che chiude solo l'overlay, la catena
## `focus_neighbor` dell'icona ingranaggio in pausa e la safe area su
## 16:9/20:9/4:3. Le impostazioni stesse (audio/touch/sparo) sono già coperte
## nel dettaglio da test_b18_audiovisual_feedback.gd, test_b18p_touch_control_settings.gd
## e test_ps085_manual_fire_mode.gd: qui si verifica solo il contratto a
## istanza unica introdotto da questa card.

const LAYOUT_PROFILES := [
	Vector2i(1280, 720),
	Vector2i(1600, 720),
	Vector2i(960, 720),
]


func test_welcome_and_pause_open_the_same_instance() -> void:
	var built := await _build_fixture(137001)
	if built.is_empty():
		return
	var welcome: WelcomeScreen = built["welcome"]
	var pause_overlay: PauseOverlay = built["pause_overlay"]
	var settings_overlay: SettingsOverlay = built["settings_overlay"]
	var movement_slice: Control = built["movement_slice"]

	assert_eq(
		movement_slice.get_settings_overlay(), settings_overlay,
		"Un solo overlay impostazioni deve esistere nella scena di run."
	)

	welcome.get_settings_button().pressed.emit()
	await wait_process_frames(1)
	assert_true(settings_overlay.is_open(), "Il tasto ingranaggio della welcome deve aprire l'overlay condiviso.")
	settings_overlay.get_close_button().pressed.emit()
	await wait_process_frames(1)
	assert_false(settings_overlay.is_open())

	welcome.hide_welcome()
	pause_overlay.show_pause()
	await wait_process_frames(1)
	pause_overlay.get_settings_button().pressed.emit()
	await wait_process_frames(1)
	assert_true(
		settings_overlay.is_open(), "Il tasto ingranaggio della pausa deve aprire la stessa istanza dell'overlay."
	)

	_teardown_fixture(built)

	print("SHARED_SETTINGS_OVERLAY_SMOKE_OK")


func test_state_is_shared_regardless_of_entry_point() -> void:
	var built := await _build_fixture(137002)
	if built.is_empty():
		return
	var welcome: WelcomeScreen = built["welcome"]
	var pause_overlay: PauseOverlay = built["pause_overlay"]
	var settings_overlay: SettingsOverlay = built["settings_overlay"]

	welcome.get_settings_button().pressed.emit()
	await wait_process_frames(1)
	settings_overlay.get_volume_slider().value = 0.4
	await wait_process_frames(1)
	var value_from_welcome := settings_overlay.get_volume_slider().value
	settings_overlay.get_close_button().pressed.emit()
	await wait_process_frames(1)

	welcome.hide_welcome()
	pause_overlay.show_pause()
	await wait_process_frames(1)
	pause_overlay.get_settings_button().pressed.emit()
	await wait_process_frames(1)
	assert_almost_eq(
		settings_overlay.get_volume_slider().value, value_from_welcome, 0.001,
		"Un valore cambiato aprendo dalla welcome deve leggersi identico aprendo dalla pausa: stessa istanza."
	)

	_teardown_fixture(built)


func test_every_opening_starts_on_the_audio_tab() -> void:
	var built := await _build_fixture(137003)
	if built.is_empty():
		return
	var welcome: WelcomeScreen = built["welcome"]
	var settings_overlay: SettingsOverlay = built["settings_overlay"]

	welcome.get_settings_button().pressed.emit()
	await wait_process_frames(1)
	assert_eq(settings_overlay.get_active_tab(), SettingsOverlay.Tab.AUDIO, "L'apertura deve mostrare AUDIO per prima.")
	settings_overlay.get_controls_tab_button().pressed.emit()
	await wait_process_frames(1)
	assert_eq(settings_overlay.get_active_tab(), SettingsOverlay.Tab.CONTROLS, "Il cambio tab deve funzionare.")
	settings_overlay.get_close_button().pressed.emit()
	await wait_process_frames(1)

	welcome.get_settings_button().pressed.emit()
	await wait_process_frames(1)
	assert_eq(
		settings_overlay.get_active_tab(), SettingsOverlay.Tab.AUDIO,
		"Ogni nuova apertura deve ripartire da AUDIO, non ricordare l'ultima tab vista."
	)

	_teardown_fixture(built)


func test_back_closes_only_the_overlay() -> void:
	var built := await _build_fixture(137004)
	if built.is_empty():
		return
	var welcome: WelcomeScreen = built["welcome"]
	var settings_overlay: SettingsOverlay = built["settings_overlay"]
	var lifecycle: PlatformLifecycle = built["lifecycle"]

	welcome.get_settings_button().pressed.emit()
	await wait_process_frames(1)
	assert_true(settings_overlay.is_open())

	assert_true(lifecycle.request_back(), "Back deve chiudere l'overlay quando è aperto.")
	await wait_process_frames(1)
	assert_false(settings_overlay.is_open(), "Back deve chiudere solo l'overlay.")
	assert_true(welcome.visible, "Back non deve chiudere la welcome sottostante.")

	# Con l'overlay chiuso, Back torna al comportamento di sempre sulla
	# welcome "nuda": nessun sotto-modal da chiudere, resta inerte.
	assert_false(
		lifecycle.request_back(), "Senza overlay aperto Back non deve avere nulla da chiudere sulla welcome."
	)

	_teardown_fixture(built)


func test_back_closes_only_the_overlay_from_pause() -> void:
	var built := await _build_running_fixture()
	if built.is_empty():
		return
	var controller: RunController = built["controller"]
	var pause_overlay: PauseOverlay = built["pause_overlay"]
	var settings_overlay: SettingsOverlay = built["settings_overlay"]
	var lifecycle: PlatformLifecycle = built["lifecycle"]

	assert_true(controller.request_manual_pause(), "La fixture deve poter aprire la pausa.")
	await wait_process_frames(1)
	pause_overlay.get_settings_button().pressed.emit()
	await wait_process_frames(1)
	assert_true(settings_overlay.is_open())

	assert_true(lifecycle.request_back(), "Back deve chiudere l'overlay aperto dalla pausa.")
	await wait_process_frames(1)
	assert_false(settings_overlay.is_open(), "Back deve chiudere solo l'overlay.")
	assert_eq(
		controller.get_state(), RunController.RunState.MANUAL_PAUSE, "Back non deve riprendere la run sottostante."
	)
	assert_true(pause_overlay.visible, "Back non deve chiudere il pannello di pausa sottostante.")

	controller.resume_run()
	_teardown_fixture(built)


func test_pause_gear_focus_chain() -> void:
	var built := await _build_fixture(137006)
	if built.is_empty():
		return
	var pause_overlay: PauseOverlay = built["pause_overlay"]

	var resume_button := pause_overlay.get_resume_button()
	var change_button := pause_overlay.get_change_character_button()
	var gear_button := pause_overlay.get_settings_button()
	assert_true(
		resume_button != null and change_button != null and gear_button != null,
		"La pausa deve esporre Riprendi, Cambia personaggio e l'ingranaggio."
	)
	if resume_button == null or change_button == null or gear_button == null:
		return

	assert_eq(
		gear_button.get_node(gear_button.focus_neighbor_top), change_button,
		"Da Cambia personaggio l'ingranaggio deve essere raggiungibile in giù."
	)
	assert_eq(
		gear_button.get_node(gear_button.focus_neighbor_bottom), resume_button,
		"Dall'ingranaggio deve tornarsi a Riprendi proseguendo in giù."
	)
	assert_eq(
		change_button.get_node(change_button.focus_neighbor_bottom), gear_button,
		"Da Cambia personaggio, in giù, si deve raggiungere l'ingranaggio."
	)
	assert_eq(
		resume_button.get_node(resume_button.focus_neighbor_top), gear_button,
		"Da Riprendi, in su, si deve raggiungere l'ingranaggio (catena a tre elementi)."
	)

	_teardown_fixture(built)


func test_overlay_stays_within_the_safe_area_on_every_profile() -> void:
	var built := await _build_fixture(137007)
	if built.is_empty():
		return
	var movement_slice: Control = built["movement_slice"]
	var welcome: WelcomeScreen = built["welcome"]
	var settings_overlay: SettingsOverlay = built["settings_overlay"]

	welcome.get_settings_button().pressed.emit()
	await wait_process_frames(1)
	assert_true(settings_overlay.is_open())

	var arena := movement_slice.get_node("ArenaLayout") as ArenaLayout
	for profile in LAYOUT_PROFILES:
		get_tree().root.content_scale_size = profile
		get_tree().root.size = profile
		await wait_process_frames(2)
		arena.refresh_layout()
		await wait_process_frames(2)
		var viewport_rect := get_tree().root.get_visible_rect()
		var panel_rect := settings_overlay.get_panel_rect()
		assert_true(panel_rect.has_area(), "%s: il pannello impostazioni deve avere area." % profile)
		assert_true(
			viewport_rect.encloses(panel_rect), "%s: l'overlay impostazioni deve restare nel viewport." % profile
		)

	get_tree().root.content_scale_size = INITIAL_VIEWPORT_SIZE
	get_tree().root.size = INITIAL_VIEWPORT_SIZE
	await wait_process_frames(2)

	_teardown_fixture(built)


func _build_fixture(seed_value: int) -> Dictionary:
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_run_controller() as RunController
	var welcome := movement_slice.get_welcome_screen() as WelcomeScreen
	var pause_overlay := movement_slice.get_pause_overlay() as PauseOverlay
	var settings_overlay := movement_slice.get_settings_overlay() as SettingsOverlay
	var lifecycle := movement_slice.get_platform_lifecycle() as PlatformLifecycle
	assert_true(
		controller != null and welcome != null and pause_overlay != null and settings_overlay != null
		and lifecycle != null,
		"PS-137 richiede RunController/WelcomeScreen/PauseOverlay/SettingsOverlay/PlatformLifecycle dalla scena."
	)
	if (
		controller == null or welcome == null or pause_overlay == null or settings_overlay == null
		or lifecycle == null
	):
		return {}

	if not controller.is_terminal():
		controller.request_defeat()
	controller.prepare_restart()
	await wait_process_frames(2)
	welcome.show_welcome()
	await wait_process_frames(1)

	return {
		"movement_slice": movement_slice,
		"controller": controller,
		"welcome": welcome,
		"pause_overlay": pause_overlay,
		"settings_overlay": settings_overlay,
		"lifecycle": lifecycle,
	}


## Variante che lascia la run avviata (RUNNING, dall'auto-start di
## `instantiate_movement_slice()`), per i test che devono davvero raggiungere
## MANUAL_PAUSE tramite `request_manual_pause()` invece di limitarsi a
## chiamare `PauseOverlay.show_pause()` a mano.
func _build_running_fixture() -> Dictionary:
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_run_controller() as RunController
	var pause_overlay := movement_slice.get_pause_overlay() as PauseOverlay
	var settings_overlay := movement_slice.get_settings_overlay() as SettingsOverlay
	var lifecycle := movement_slice.get_platform_lifecycle() as PlatformLifecycle
	assert_true(
		controller != null and pause_overlay != null and settings_overlay != null and lifecycle != null
		and controller.is_running(),
		"PS-137 richiede una run già avviata (RUNNING) per i test lato pausa."
	)
	if (
		controller == null or pause_overlay == null or settings_overlay == null or lifecycle == null
		or not controller.is_running()
	):
		return {}

	return {
		"movement_slice": movement_slice,
		"controller": controller,
		"pause_overlay": pause_overlay,
		"settings_overlay": settings_overlay,
		"lifecycle": lifecycle,
	}


func _teardown_fixture(built: Dictionary) -> void:
	var settings_overlay: SettingsOverlay = built.get("settings_overlay")
	if settings_overlay != null and settings_overlay.is_open():
		settings_overlay.close()
	var controller: RunController = built.get("controller")
	if controller != null and not controller.is_terminal():
		controller.request_defeat()
