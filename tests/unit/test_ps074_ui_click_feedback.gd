extends GutGameplayTest

## PS-074 — Click generico dei bottoni UI oggi silenziosi: verifica che i
## bottoni elencati nella card riproducano `GameAudio.UI_CLICK`, che i
## bottoni già coperti da `UI_CONFIRM`/`PAUSE`/`RESUME` non raddoppino il
## suono sulla stessa pressione, che pressioni ravvicinate restino
## debounced e che con l'audio disattivato non ci sia riproduzione.
##
## Gioca/Tutorial (welcome) e "Successivo" sull'ultima pagina del tutorial
## (diventa "GIOCA") sono stati esclusi in fase di implementazione: già
## coperti da `UI_CONFIRM` in `movement_slice.gd` (scoperto rileggendo il
## codice, non nella ricognizione originale della card — vedi Decisioni).


func test_welcome_settings_and_tutorial_navigation_buttons() -> void:
	var built := await _build_boot_fixture(74001)
	if built.is_empty():
		return
	var welcome: WelcomeScreen = built["welcome"]
	var tutorial: TutorialScreen = built["tutorial"]
	var audio: GameAudio = built["audio"]
	var settings_overlay: SettingsOverlay = built["settings_overlay"]

	assert_true(audio.has_complete_cue_set(), "PS-074: il set di cue deve risultare completo con UI_CLICK integrato.")
	assert_not_null(
		audio.get_stream_for_cue(GameAudio.UI_CLICK), "PS-074: il cue UI_CLICK deve avere uno stream importato."
	)

	var cues: Array[StringName] = []
	audio.cue_played.connect(func(cue_id: StringName) -> void: cues.append(cue_id))

	var settings_button := welcome.get_settings_button()
	var tutorial_button := welcome.get_tutorial_button()
	assert_true(
		settings_button != null and tutorial_button != null,
		"La welcome deve esporre Impostazioni e Tutorial."
	)
	if settings_button == null or tutorial_button == null:
		return

	cues.clear()
	settings_button.pressed.emit()
	await wait_process_frames(1)
	assert_eq(cues, [GameAudio.UI_CLICK] as Array[StringName], "Impostazioni deve riprodurre solo UI_CLICK.")

	# PS-137: il bottone Chiudi ora vive nell'overlay condiviso, non più
	# nella welcome — stessa istanza aperta dal gear appena premuto.
	var close_settings_button := settings_overlay.get_close_button()
	assert_not_null(close_settings_button, "L'overlay impostazioni deve esporre CHIUDI.")
	if close_settings_button == null:
		return

	await _settle_debounce()
	cues.clear()
	close_settings_button.pressed.emit()
	await wait_process_frames(1)
	assert_eq(cues, [GameAudio.UI_CLICK] as Array[StringName], "Chiudi impostazioni deve riprodurre solo UI_CLICK.")

	await _settle_debounce()
	cues.clear()
	tutorial_button.pressed.emit()
	await wait_process_frames(1)
	assert_true(tutorial.visible, "Tutorial deve mostrarsi dopo la pressione.")
	assert_eq(
		cues, [GameAudio.UI_CONFIRM] as Array[StringName],
		"Tutorial deve restare sul solo UI_CONFIRM esistente, senza raddoppio UI_CLICK."
	)

	var next_button := tutorial.get_next_button()
	var previous_button := tutorial.get_previous_button()
	assert_true(next_button != null and previous_button != null, "Il tutorial deve esporre Precedente e Successivo.")
	if next_button == null or previous_button == null:
		return

	cues.clear()
	next_button.pressed.emit()
	await wait_process_frames(1)
	assert_eq(
		cues, [GameAudio.UI_CLICK] as Array[StringName], "Successivo (non ultima pagina) deve riprodurre UI_CLICK."
	)

	await _settle_debounce()
	cues.clear()
	previous_button.pressed.emit()
	await wait_process_frames(1)
	assert_eq(cues, [GameAudio.UI_CLICK] as Array[StringName], "Precedente deve riprodurre UI_CLICK.")

	while tutorial.get_current_page_index() < tutorial.pages.size() - 1:
		await _settle_debounce()
		next_button.pressed.emit()
		await wait_process_frames(1)
	await _settle_debounce()
	cues.clear()
	next_button.pressed.emit()
	await wait_process_frames(1)
	assert_eq(
		cues, [GameAudio.UI_CONFIRM] as Array[StringName],
		"GIOCA (Successivo sull'ultima pagina) deve restare sul solo UI_CONFIRM, senza raddoppio UI_CLICK."
	)

	_teardown_boot_fixture(built)


func test_character_select_navigation_buttons_play_click() -> void:
	var built := await _build_boot_fixture(74002)
	if built.is_empty():
		return
	var welcome: WelcomeScreen = built["welcome"]
	var selector: CharacterSelectOverlay = built["selector"]
	var audio: GameAudio = built["audio"]

	var cues: Array[StringName] = []
	audio.cue_played.connect(func(cue_id: StringName) -> void: cues.append(cue_id))

	var play_button := welcome.get_play_button()
	assert_not_null(play_button, "La welcome deve esporre GIOCA.")
	if play_button == null:
		return

	cues.clear()
	play_button.pressed.emit()
	await wait_process_frames(2)
	assert_true(selector.visible, "GIOCA deve mostrare il selettore personaggi.")
	assert_eq(
		cues, [GameAudio.UI_CONFIRM] as Array[StringName], "GIOCA deve restare sul solo UI_CONFIRM esistente."
	)

	var previous_button := selector.get_previous_button()
	var next_button := selector.get_next_button()
	var back_button := selector.get_back_button()
	assert_true(
		previous_button != null and next_button != null and back_button != null,
		"Il selettore deve esporre Precedente, Successivo e Indietro."
	)
	if previous_button == null or next_button == null or back_button == null:
		return

	cues.clear()
	next_button.pressed.emit()
	await wait_process_frames(1)
	assert_eq(cues, [GameAudio.UI_CLICK] as Array[StringName], "Successivo del selettore deve riprodurre UI_CLICK.")

	await _settle_debounce()
	cues.clear()
	previous_button.pressed.emit()
	await wait_process_frames(1)
	assert_eq(cues, [GameAudio.UI_CLICK] as Array[StringName], "Precedente del selettore deve riprodurre UI_CLICK.")

	await _settle_debounce()
	cues.clear()
	back_button.pressed.emit()
	await wait_process_frames(1)
	assert_eq(cues, [GameAudio.UI_CLICK] as Array[StringName], "Indietro del selettore deve riprodurre UI_CLICK.")
	assert_true(welcome.visible, "Indietro dal selettore deve tornare alla welcome.")

	_teardown_boot_fixture(built)


func test_rapid_clicks_are_debounced() -> void:
	var built := await _build_boot_fixture(74003)
	if built.is_empty():
		return
	var welcome: WelcomeScreen = built["welcome"]
	var audio: GameAudio = built["audio"]

	var cues: Array[StringName] = []
	audio.cue_played.connect(func(cue_id: StringName) -> void: cues.append(cue_id))

	welcome.ui_click_requested.emit()
	welcome.ui_click_requested.emit()
	welcome.ui_click_requested.emit()
	await wait_process_frames(1)
	assert_eq(
		cues.count(GameAudio.UI_CLICK), 1,
		"Pressioni ravvicinate sotto la soglia di debounce non devono accumulare riproduzioni."
	)

	_teardown_boot_fixture(built)


func test_ui_click_respects_mute() -> void:
	var built := await _build_boot_fixture(74004)
	if built.is_empty():
		return
	var welcome: WelcomeScreen = built["welcome"]
	var audio: GameAudio = built["audio"]

	var initial_muted := audio.is_muted()
	audio.set_muted(true, false)

	var cues: Array[StringName] = []
	audio.cue_played.connect(func(cue_id: StringName) -> void: cues.append(cue_id))
	var settings_button := welcome.get_settings_button()
	assert_not_null(settings_button)
	if settings_button == null:
		return
	settings_button.pressed.emit()
	await wait_process_frames(1)
	assert_true(cues.is_empty(), "Con audio disattivato non deve essere udibile alcun cue.")

	audio.set_muted(initial_muted, false)
	_teardown_boot_fixture(built)


func test_pause_overlay_buttons_play_click() -> void:
	var movement_slice := await instantiate_movement_slice()
	var controller := movement_slice.get_run_controller() as RunController
	var overlay := movement_slice.get_pause_overlay() as PauseOverlay
	var hud := movement_slice.get_hud() as GameHud
	var audio := movement_slice.get_game_audio() as GameAudio
	assert_true(
		controller != null and overlay != null and hud != null and audio != null,
		"PS-074 richiede RunController, PauseOverlay, HUD e GameAudio dalla scena."
	)
	if controller == null or overlay == null or hud == null or audio == null:
		return

	var cues: Array[StringName] = []
	audio.cue_played.connect(func(cue_id: StringName) -> void: cues.append(cue_id))

	var pause_button := hud.get_pause_button()
	assert_not_null(pause_button, "La HUD deve esporre il bottone pausa.")
	if pause_button == null:
		return
	pause_button.pressed.emit()
	await wait_process_frames(1)
	assert_eq(controller.get_state(), RunController.RunState.MANUAL_PAUSE, "PAUSA deve aprire il menu manuale.")

	var change_button := overlay.get_change_character_button()
	var cancel_button := overlay.get_cancel_change_button()
	var confirm_button := overlay.get_confirm_change_button()
	assert_true(
		change_button != null and cancel_button != null and confirm_button != null,
		"La pausa deve esporre Cambia personaggio, Annulla e Conferma."
	)
	if change_button == null or cancel_button == null or confirm_button == null:
		return

	cues.clear()
	change_button.pressed.emit()
	await wait_process_frames(1)
	assert_eq(cues, [GameAudio.UI_CLICK] as Array[StringName], "Cambia personaggio deve riprodurre UI_CLICK.")

	await _settle_debounce()
	cues.clear()
	cancel_button.pressed.emit()
	await wait_process_frames(1)
	assert_eq(cues, [GameAudio.UI_CLICK] as Array[StringName], "Annulla deve riprodurre UI_CLICK.")

	await _settle_debounce()
	change_button.pressed.emit()
	await wait_process_frames(1)
	await _settle_debounce()
	cues.clear()
	confirm_button.pressed.emit()
	await wait_process_frames(1)
	assert_true(GameAudio.UI_CLICK in cues, "Conferma cambio personaggio deve riprodurre UI_CLICK.")

	if not controller.is_terminal():
		controller.request_defeat()
	controller.prepare_restart()


func test_boss_ui_continue_button_plays_click() -> void:
	var movement_slice := await instantiate_movement_slice()
	var controller := movement_slice.get_run_controller() as RunController
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	var boss_ui := movement_slice.get_boss_ui() as BossUI
	var audio := movement_slice.get_game_audio() as GameAudio
	assert_true(
		controller != null and spawner != null and boss_ui != null and audio != null,
		"PS-074 richiede RunController, EnemySpawner, BossUI e GameAudio dalla scena."
	)
	if controller == null or spawner == null or boss_ui == null or audio == null:
		return

	controller.set_process(false)
	spawner.set_process(false)
	controller._process(120.01)
	# `show_intro()` (boss_ui.gd) accoda `_defer_reflow_intro_panel_position()`,
	# due `await get_tree().process_frame` prima di ritoccare il layout: senza
	# lasciarli risolvere prima della teardown del fixture, la scena viene
	# liberata a metà await ("Resumed function... but class instance is gone").
	await wait_process_frames(3)
	assert_true(
		controller.get_state() == RunController.RunState.BOSS_INTRO and boss_ui.is_intro_visible(),
		"La fixture deve raggiungere BOSS_INTRO con l'intro visibile."
	)

	var continue_button := boss_ui.get_continue_button()
	assert_not_null(continue_button, "BossUI deve esporre il bottone Continua.")
	if continue_button == null:
		return

	var cues: Array[StringName] = []
	audio.cue_played.connect(func(cue_id: StringName) -> void: cues.append(cue_id))
	continue_button.pressed.emit()
	await wait_process_frames(1)
	assert_true(GameAudio.UI_CLICK in cues, "Continua deve riprodurre UI_CLICK.")
	assert_eq(controller.get_state(), RunController.RunState.RUNNING, "Continua deve chiudere l'intro Boss.")

	controller.set_process(true)
	if not controller.is_terminal():
		controller.request_defeat()
	controller.prepare_restart()


func test_end_screen_restart_button_plays_click() -> void:
	var movement_slice := await instantiate_movement_slice()
	var controller := movement_slice.get_run_controller() as RunController
	var end_screen := movement_slice.get_end_screen() as EndScreen
	var audio := movement_slice.get_game_audio() as GameAudio
	assert_true(
		controller != null and end_screen != null and audio != null,
		"PS-074 richiede RunController, EndScreen e GameAudio dalla scena."
	)
	if controller == null or end_screen == null or audio == null:
		return

	assert_true(controller.request_defeat(), "La run deve poter terminare.")
	await wait_process_frames(1)
	assert_true(end_screen.is_accepting_restart(), "La schermata finale deve accettare RIPROVA.")

	var restart_button := end_screen.get_restart_button()
	assert_not_null(restart_button, "EndScreen deve esporre RIPROVA.")
	if restart_button == null:
		return

	var cues: Array[StringName] = []
	audio.cue_played.connect(func(cue_id: StringName) -> void: cues.append(cue_id))
	restart_button.pressed.emit()
	await wait_process_frames(1)
	assert_true(GameAudio.UI_CLICK in cues, "RIPROVA deve riprodurre UI_CLICK.")

	if not controller.is_terminal():
		controller.request_defeat()
	controller.prepare_restart()


func test_end_screen_change_character_button_plays_click() -> void:
	var movement_slice := await instantiate_movement_slice()
	var controller := movement_slice.get_run_controller() as RunController
	var end_screen := movement_slice.get_end_screen() as EndScreen
	var audio := movement_slice.get_game_audio() as GameAudio
	assert_true(
		controller != null and end_screen != null and audio != null,
		"PS-074 richiede RunController, EndScreen e GameAudio dalla scena."
	)
	if controller == null or end_screen == null or audio == null:
		return

	assert_true(controller.request_defeat(), "La run deve poter terminare.")
	await wait_process_frames(1)
	assert_true(end_screen.is_accepting_restart(), "La schermata finale deve accettare CAMBIA PERSONAGGIO.")

	var change_button := end_screen.get_change_character_button()
	assert_not_null(change_button, "EndScreen deve esporre CAMBIA PERSONAGGIO.")
	if change_button == null:
		return

	var cues: Array[StringName] = []
	audio.cue_played.connect(func(cue_id: StringName) -> void: cues.append(cue_id))
	change_button.pressed.emit()
	await wait_process_frames(1)
	assert_true(GameAudio.UI_CLICK in cues, "CAMBIA PERSONAGGIO deve riprodurre UI_CLICK.")

	if not controller.is_terminal():
		controller.request_defeat()
	controller.prepare_restart()

	print("UI_CLICK_FEEDBACK_SMOKE_OK")


func _build_boot_fixture(seed_value: int) -> Dictionary:
	get_tree().root.content_scale_size = INITIAL_VIEWPORT_SIZE
	get_tree().root.size = INITIAL_VIEWPORT_SIZE
	await wait_process_frames(2)

	ProjectSettings.set_setting("application/run/b18o_force_welcome_for_test", true)
	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	movement_slice.set("gut_test_run_seed_override", seed_value)
	add_child_autofree(movement_slice)
	ProjectSettings.set_setting("application/run/b18o_force_welcome_for_test", false)
	await wait_process_frames(2)

	var controller := movement_slice.get_run_controller() as RunController
	var welcome := movement_slice.get_welcome_screen() as WelcomeScreen
	var tutorial := movement_slice.get_tutorial_screen() as TutorialScreen
	var selector := movement_slice.get_character_select_overlay() as CharacterSelectOverlay
	var audio := movement_slice.get_game_audio() as GameAudio
	var settings_overlay := movement_slice.get_settings_overlay() as SettingsOverlay
	assert_true(
		controller != null and welcome != null and tutorial != null and selector != null and audio != null
		and settings_overlay != null,
		"PS-074 richiede welcome/tutorial/selettore/GameAudio/SettingsOverlay dalla scena."
	)
	if (
		controller == null or welcome == null or tutorial == null or selector == null or audio == null
		or settings_overlay == null
	):
		return {}
	assert_true(welcome.visible, "Il fixture BOOT di PS-074 deve avviarsi sulla welcome.")

	return {
		"movement_slice": movement_slice,
		"controller": controller,
		"welcome": welcome,
		"tutorial": tutorial,
		"selector": selector,
		"audio": audio,
		"settings_overlay": settings_overlay,
	}


func _teardown_boot_fixture(built: Dictionary) -> void:
	var controller: RunController = built.get("controller")
	if controller != null and not controller.is_terminal():
		controller.request_defeat()


## PS-074: `_on_ui_click_requested()` applica un debounce di 80ms condiviso
## da tutti i bottoni mappati su UI_CLICK (per cue_id, non per bottone). I
## test che premono più bottoni UI_CLICK in sequenza devono superare quella
## soglia in tempo reale fra una pressione e l'altra, altrimenti la seconda
## risulterebbe (correttamente) soppressa come se fosse la stessa pressione
## ravvicinata coperta da `test_rapid_clicks_are_debounced`.
func _settle_debounce() -> void:
	await get_tree().create_timer(0.1).timeout
