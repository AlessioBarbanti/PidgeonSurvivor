extends GutGameplayTest

## PS-147: aggiunge un quarto bottone "ESCI" alla colonna pausa. Verifica
## stile/font_color dedicati (piu' scuro di CAMBIA PERSONAGGIO/IMPOSTAZIONI),
## che la conferma riusata mostri il testo corretto per ESCI (non quello di
## CAMBIA PERSONAGGIO), che confermare abbandoni la run verso la welcome, che
## annullare non tocchi lo stato, e la catena focus_neighbor a quattro
## elementi.


func test_ps147_pause_exit_button_style_and_confirmation() -> void:
	var movement_slice := await instantiate_movement_slice()
	var controller := movement_slice.get_run_controller() as RunController
	var overlay := movement_slice.get_pause_overlay() as PauseOverlay
	var welcome := movement_slice.get_welcome_screen() as WelcomeScreen
	assert_true(
		controller != null and overlay != null and welcome != null,
		"PS-147 richiede RunController/PauseOverlay/WelcomeScreen dalla scena."
	)
	if controller == null or overlay == null or welcome == null:
		return

	assert_true(controller.request_manual_pause(), "PS-147 richiede di poter aprire la pausa manuale.")
	await wait_process_frames(1)

	var resume_button := overlay.get_resume_button()
	var change_button := overlay.get_change_character_button()
	var settings_button := overlay.get_settings_button()
	var exit_button := overlay.get_exit_button()
	var cancel_button := overlay.get_cancel_change_button()
	var confirm_button := overlay.get_confirm_change_button()
	assert_true(
		resume_button != null and change_button != null and settings_button != null and exit_button != null,
		"La pausa deve esporre RIPRENDI, CAMBIA PERSONAGGIO, IMPOSTAZIONI ed ESCI."
	)
	if resume_button == null or change_button == null or settings_button == null or exit_button == null:
		return
	assert_true(
		cancel_button != null and confirm_button != null, "La conferma deve esporre ANNULLA e CONFERMA."
	)
	if cancel_button == null or confirm_button == null:
		return

	assert_eq(exit_button.text, "ESCI", "ESCI deve mostrare testo, non un glifo icona.")
	assert_eq(
		exit_button.get_parent(), resume_button.get_parent(), "ESCI deve stare nella stessa colonna (VBox)."
	)
	assert_true(
		exit_button.custom_minimum_size.y >= 64.0, "ESCI deve conservare l'altezza target touch (64px)."
	)

	# Stile dedicato, piu' scuro di CAMBIA PERSONAGGIO/IMPOSTAZIONI in ogni stato.
	for state_name in [&"normal", &"hover", &"pressed"]:
		assert_ne(
			exit_button.get_theme_stylebox(state_name), change_button.get_theme_stylebox(state_name),
			"ESCI deve avere uno StyleBoxTexture %s diverso da CAMBIA PERSONAGGIO." % state_name
		)
		assert_ne(
			exit_button.get_theme_stylebox(state_name), settings_button.get_theme_stylebox(state_name),
			"ESCI deve avere uno StyleBoxTexture %s diverso da IMPOSTAZIONI." % state_name
		)

	# font_color corallo (accento di allerta), non condiviso dagli altri bottoni secondari.
	assert_eq(
		exit_button.get_theme_color(&"font_color"), Color(0.98, 0.55, 0.5, 1),
		"ESCI deve usare il font_color corallo (accento di allerta)."
	)
	assert_ne(
		exit_button.get_theme_color(&"font_color"), change_button.get_theme_color(&"font_color"),
		"CAMBIA PERSONAGGIO non deve condividere il font_color di ESCI."
	)
	assert_ne(
		exit_button.get_theme_color(&"font_color"), settings_button.get_theme_color(&"font_color"),
		"IMPOSTAZIONI non deve condividere il font_color di ESCI."
	)

	# Premere ESCI mostra la conferma riusata, con testo dedicato all'abbandono.
	exit_button.pressed.emit()
	await wait_process_frames(1)
	assert_true(overlay.is_change_confirmation_visible(), "ESCI deve chiedere conferma.")
	assert_eq(
		controller.get_state(), RunController.RunState.MANUAL_PAUSE, "Aprire la conferma deve conservare MANUAL_PAUSE."
	)
	var confirmation_title := overlay.get_node("%ConfirmationTitleLabel") as Label
	assert_not_null(confirmation_title, "La conferma deve esporre un titolo indirizzabile.")
	if confirmation_title != null:
		assert_eq(
			confirmation_title.text, "USCIRE DALLA PARTITA?",
			"La conferma di ESCI non deve mostrare il testo di CAMBIA PERSONAGGIO."
		)

	# Annullare non deve toccare lo stato ne' il seed/clock della run.
	var initial_seed := controller.get_seed()
	var paused_time := controller.get_run_time()
	cancel_button.pressed.emit()
	await wait_process_frames(1)
	assert_false(overlay.is_change_confirmation_visible(), "ANNULLA deve chiudere soltanto la conferma.")
	assert_eq(controller.get_state(), RunController.RunState.MANUAL_PAUSE, "ANNULLA deve lasciare la run in pausa.")
	assert_eq(controller.get_seed(), initial_seed, "ANNULLA non deve alterare il seed della run.")
	assert_almost_eq(
		controller.get_run_time(), paused_time, FLOAT_TOLERANCE, "ANNULLA non deve far avanzare il clock."
	)
	assert_true(
		not resume_button.disabled and not change_button.disabled and not settings_button.disabled
		and not exit_button.disabled,
		"ANNULLA deve riabilitare tutti e quattro i bottoni della pausa."
	)

	# Confermare l'abbandono: prepare_restart() + welcome, non selezione/end screen.
	exit_button.pressed.emit()
	await wait_process_frames(1)
	confirm_button.pressed.emit()
	await wait_process_frames(2)
	assert_eq(controller.get_state(), RunController.RunState.BOOT, "CONFERMA ESCI deve tornare in BOOT.")
	assert_true(
		controller.get_seed() == 0 and is_zero_approx(controller.get_run_time()),
		"CONFERMA ESCI deve azzerare seed e clock."
	)
	assert_true(
		welcome.visible and not overlay.visible, "CONFERMA ESCI deve mostrare la welcome e chiudere la pausa."
	)

	if is_instance_valid(controller):
		controller.prepare_restart()

	print("PS147_PAUSE_EXIT_OK")


func test_ps147_pause_focus_chain_four_elements() -> void:
	var movement_slice := await instantiate_movement_slice()
	var controller := movement_slice.get_run_controller() as RunController
	var overlay := movement_slice.get_pause_overlay() as PauseOverlay
	assert_true(controller != null and overlay != null, "PS-147 richiede RunController/PauseOverlay dalla scena.")
	if controller == null or overlay == null:
		return

	assert_true(controller.request_manual_pause(), "PS-147 richiede di poter aprire la pausa manuale.")
	await wait_process_frames(1)

	var resume_button := overlay.get_resume_button()
	var change_button := overlay.get_change_character_button()
	var settings_button := overlay.get_settings_button()
	var exit_button := overlay.get_exit_button()
	assert_true(
		resume_button != null and change_button != null and settings_button != null and exit_button != null,
		"La pausa deve esporre i quattro bottoni della colonna."
	)
	if resume_button == null or change_button == null or settings_button == null or exit_button == null:
		return

	assert_eq(
		settings_button.get_node(settings_button.focus_neighbor_bottom), exit_button,
		"Da IMPOSTAZIONI, in giù, si deve raggiungere ESCI."
	)
	assert_eq(
		exit_button.get_node(exit_button.focus_neighbor_top), settings_button,
		"Da ESCI, in su, si deve raggiungere IMPOSTAZIONI."
	)
	assert_eq(
		exit_button.get_node(exit_button.focus_neighbor_bottom), resume_button,
		"Da ESCI, in giù, si deve tornare a RIPRENDI (catena chiusa a quattro elementi)."
	)
	assert_eq(
		resume_button.get_node(resume_button.focus_neighbor_top), exit_button,
		"Da RIPRENDI, in su, si deve raggiungere ESCI."
	)

	controller.request_defeat()
