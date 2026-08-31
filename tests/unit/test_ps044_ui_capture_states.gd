extends GutGameplayTest

## PS-044: le catture UI devono documentare solo stati che il RunController
## produce davvero. Il test verifica due cose distinte:
##   1. che ogni stato usato dallo script di cattura sia raggiungibile e apra
##      un solo modale, in particolare che la conferma di cambio personaggio
##      viva sopra MANUAL_PAUSE e mai sopra un level-up;
##   2. che lo script dichiari due profili di viewport e non inventi piu' il
##      tempo mostrato nella schermata terminale.

const CAPTURE_SCRIPT_PATH := "res://tools/_capture_ui_screenshots.gd"


func test_capture_script_declares_two_viewport_profiles() -> void:
	var source := _read_capture_script()
	assert_true(
		source.contains("LANDSCAPE_16X9 := Vector2i(1280, 720)"),
		"PS-044 deve conservare il profilo 16:9 storico."
	)
	assert_true(
		source.contains("LANDSCAPE_20X9 := Vector2i(2424, 1080)"),
		"PS-044 richiede un profilo 20:9 rappresentativo del Pixel 9."
	)
	assert_true(
		source.contains("PIXEL9_OUT_DIR") and source.contains("pixel9-20x9"),
		"I due pacchetti devono finire in percorsi distinti."
	)


func test_capture_script_does_not_invent_the_terminal_time() -> void:
	var source := _read_capture_script()
	assert_false(
		source.contains("show_defeat(187.0)"),
		"Il tempo della schermata terminale non deve piu' essere un valore inventato."
	)
	assert_true(
		source.contains("request_defeat()"),
		"La sconfitta va chiesta al RunController, che porta con se' il tempo di run."
	)
	assert_true(
		source.contains("_check_terminal_time_coherence"),
		"La cattura deve confrontare il tempo dell'HUD con quello del riepilogo."
	)


## Le chiamate a `_shot` possono essere spezzate su piu' righe e contenere
## parentesi negli argomenti: il controllo appiattisce il sorgente e bilancia
## le parentesi, altrimenti basterebbe un a capo o un `%` per aggirarlo.
func test_capture_script_guards_every_shot_with_a_state() -> void:
	var calls := _shot_call_arguments(_read_capture_script())
	assert_true(calls.size() > 0, "Lo script di cattura deve produrre almeno uno scatto.")
	var unguarded: Array[String] = []
	for arguments in calls:
		if not arguments.contains("RunController.RunState."):
			unguarded.append(arguments)
	var expected: Array[String] = []
	assert_eq(
		unguarded, expected,
		"Ogni scatto deve dichiarare lo stato atteso del RunController."
	)


func _shot_call_arguments(source: String) -> Array[String]:
	var flattened := source.replace("\n", " ").replace("\t", " ")
	var marker := "await _shot("
	var calls: Array[String] = []
	var cursor := flattened.find(marker)
	while cursor >= 0:
		var start := cursor + marker.length()
		var depth := 1
		var index := start
		while index < flattened.length() and depth > 0:
			var character := flattened[index]
			if character == "(":
				depth += 1
			elif character == ")":
				depth -= 1
			index += 1
		calls.append(flattened.substr(start, index - start - 1).strip_edges())
		cursor = flattened.find(marker, index)
	return calls


func test_modal_states_are_reachable_and_mutually_exclusive() -> void:
	var movement_slice := await instantiate_movement_slice()
	var controller := movement_slice.get_run_controller() as RunController
	var experience := movement_slice.get_experience_system() as ExperienceSystem
	var upgrade_service := movement_slice.get_upgrade_service() as UpgradeService
	var upgrade_overlay := movement_slice.get_upgrade_overlay() as UpgradeOverlay
	var barb_overlay := movement_slice.get_barb_reward_overlay() as BarbRewardOverlay
	var boss_ui := movement_slice.get_boss_ui() as BossUI
	var pause_overlay := movement_slice.get_pause_overlay() as PauseOverlay
	var end_screen := movement_slice.get_end_screen() as EndScreen
	var lifecycle := movement_slice.get_platform_lifecycle() as PlatformLifecycle
	assert_true(
		controller != null
		and experience != null
		and upgrade_service != null
		and upgrade_overlay != null
		and barb_overlay != null
		and boss_ui != null
		and pause_overlay != null
		and end_screen != null
		and lifecycle != null,
		"PS-044 richiede tutte le superfici catturate dallo script."
	)
	if controller == null or lifecycle == null:
		return

	controller.set_process(false)
	var modals := {
		"upgrade": upgrade_overlay,
		"barb": barb_overlay,
		"pause": pause_overlay,
		"end_screen": end_screen,
	}

	assert_true(controller.is_running(), "La fixture deve partire da una run in corso.")
	_assert_only_modal(modals, boss_ui, "", "In RUNNING nessun modale deve essere visibile.")

	experience.add_experience(40)
	await wait_process_frames(2)
	assert_eq(
		controller.get_state(), RunController.RunState.LEVEL_UP,
		"L'XP sufficiente deve aprire il level-up."
	)
	_assert_only_modal(modals, boss_ui, "upgrade", "Il level-up deve essere l'unico modale aperto.")
	await _drain_level_ups(controller, upgrade_service)

	upgrade_service.queue_barb_reward()
	await wait_process_frames(2)
	assert_eq(
		controller.get_state(), RunController.RunState.BARB_REWARD,
		"La ricompensa Barb deve essere raggiungibile dal percorso reale."
	)
	_assert_only_modal(modals, boss_ui, "barb", "La ricompensa Barb deve essere l'unico modale aperto.")
	var barb_offer := upgrade_service.get_current_barb_offer()
	assert_true(not barb_offer.is_empty(), "La ricompensa Barb deve offrire almeno una carta.")
	if not barb_offer.is_empty():
		assert_true(
			upgrade_service.select_barb_speciality(barb_offer[0].id),
			"La ricompensa Barb deve poter essere chiusa."
		)
	await wait_process_frames(2)
	assert_true(controller.is_running(), "Dopo la ricompensa Barb la run deve riprendere.")

	assert_true(controller.request_boss_intro(), "La Boss intro deve essere raggiungibile.")
	boss_ui.show_intro(load("res://data/bosses/first_boss.tres") as BossDefinition)
	await wait_process_frames(2)
	_assert_only_modal(modals, boss_ui, "boss_intro", "La Boss intro deve essere l'unico modale aperto.")
	boss_ui.hide_intro()
	assert_true(controller.complete_boss_intro(), "La Boss intro deve poter terminare.")
	await wait_process_frames(2)

	assert_true(lifecycle.request_manual_pause(), "La pausa manuale deve essere raggiungibile.")
	await wait_process_frames(2)
	assert_eq(
		controller.get_state(), RunController.RunState.MANUAL_PAUSE,
		"La pausa manuale deve portare il RunController in MANUAL_PAUSE."
	)
	_assert_only_modal(modals, boss_ui, "pause", "La pausa deve essere l'unico modale aperto.")

	var change_button := pause_overlay.get_change_character_button()
	assert_true(change_button != null, "La pausa deve offrire il cambio personaggio.")
	if change_button != null:
		change_button.emit_signal("pressed")
		await wait_process_frames(2)
		assert_true(
			pause_overlay.is_change_confirmation_visible(),
			"La conferma di cambio personaggio deve nascere dalla pausa."
		)
		assert_eq(
			controller.get_state(), RunController.RunState.MANUAL_PAUSE,
			"La conferma di cambio personaggio vive solo sopra MANUAL_PAUSE."
		)
		assert_false(
			upgrade_overlay.visible,
			"La conferma di cambio personaggio non puo' comporsi con un level-up."
		)
		_assert_only_modal(
			modals,
			boss_ui,
			"pause",
			"Nemmeno la conferma deve aggiungere un secondo modale."
		)
		var cancel_button := pause_overlay.get_cancel_change_button()
		assert_true(cancel_button != null, "La conferma deve poter essere annullata.")
		if cancel_button != null:
			cancel_button.emit_signal("pressed")
			await wait_process_frames(2)

	# Se la finestra ha perso il focus il lifecycle rifiuta il resume: la ripresa
	# resta comunque una richiesta al RunController, che e' l'autorita'.
	if not lifecycle.request_resume():
		controller.resume_run()
	await wait_process_frames(2)
	assert_true(controller.is_running(), "La run deve poter riprendere dalla pausa.")

	var run_time := controller.get_run_time()
	assert_true(controller.request_defeat(), "La sconfitta deve essere raggiungibile.")
	await wait_process_frames(2)
	_assert_only_modal(modals, boss_ui, "end_screen", "Il terminale deve essere l'unico modale aperto.")
	var expected_time := EndScreen.format_run_time(run_time)
	assert_true(
		end_screen.get_summary_text().contains(expected_time),
		"Il riepilogo deve riportare il tempo di run %s, non un valore inventato." % expected_time
	)

	controller.prepare_restart()
	await wait_process_frames(1)
	print("UI_CAPTURE_STATES_SMOKE_OK")


func _assert_only_modal(
	modals: Dictionary,
	boss_ui: BossUI,
	allowed: String,
	text: String
) -> void:
	var visible_modals: Array[String] = []
	for key in modals:
		var control := modals[key] as Control
		if control != null and control.visible:
			visible_modals.append(String(key))
	if boss_ui != null and boss_ui.is_intro_visible():
		visible_modals.append("boss_intro")
	var expected: Array[String] = []
	if not allowed.is_empty():
		expected.append(allowed)
	assert_eq(
		visible_modals, expected,
		"%s Visibili: %s." % [text, visible_modals]
	)


## Passa dal servizio invece che dal tap sulla carta: in LEVEL_UP l'albero e'
## in pausa e un'attesa a tempo non avanzerebbe mai, mentre il lock anti-tap
## della UI non e' l'oggetto di questa card.
func _drain_level_ups(
	controller: RunController,
	upgrade_service: UpgradeService
) -> void:
	var guard := 0
	while controller.get_state() == RunController.RunState.LEVEL_UP and guard < 8:
		guard += 1
		var offer := upgrade_service.get_current_offer()
		if offer.is_empty():
			break
		if not upgrade_service.select_upgrade(offer[0].id):
			break
		await wait_process_frames(2)
	assert_true(
		controller.is_running(),
		"Svuotata la coda dei level-up la run deve tornare RUNNING."
	)


func _read_capture_script() -> String:
	var file := FileAccess.open(CAPTURE_SCRIPT_PATH, FileAccess.READ)
	assert_true(file != null, "PS-044 richiede lo script di cattura in %s." % CAPTURE_SCRIPT_PATH)
	if file == null:
		return ""
	var source := file.get_as_text()
	file.close()
	return source
