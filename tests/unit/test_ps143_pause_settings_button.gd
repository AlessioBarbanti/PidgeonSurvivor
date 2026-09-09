extends GutGameplayTest

## PS-143: l'icona ingranaggio fluttuante della pausa (introdotta da PS-137)
## è sostituita da un terzo bottone testuale "IMPOSTAZIONI" nella stessa
## colonna di RIPRENDI/CAMBIA PERSONAGGIO. Verifica assenza dell'icona
## fluttuante, presenza del bottone nella colonna con lo stile secondario,
## apertura della stessa istanza dell'overlay condiviso e catena
## `focus_neighbor` corretta fra i tre bottoni.


func test_ps143_pause_settings_button_replaces_floating_gear_icon() -> void:
	var movement_slice := await instantiate_movement_slice()
	var controller := movement_slice.get_run_controller() as RunController
	var pause_overlay := movement_slice.get_pause_overlay() as PauseOverlay
	var settings_overlay := movement_slice.get_settings_overlay() as SettingsOverlay
	assert_true(
		controller != null and pause_overlay != null and settings_overlay != null,
		"PS-143 richiede RunController/PauseOverlay/SettingsOverlay dalla scena."
	)
	if controller == null or pause_overlay == null or settings_overlay == null:
		return

	assert_true(controller.request_manual_pause(), "PS-143 richiede di poter aprire la pausa manuale.")
	await wait_process_frames(1)

	var resume_button := pause_overlay.get_resume_button()
	var change_button := pause_overlay.get_change_character_button()
	var settings_button := pause_overlay.get_settings_button()
	assert_true(
		resume_button != null and change_button != null and settings_button != null,
		"La pausa deve esporre RIPRENDI, CAMBIA PERSONAGGIO e IMPOSTAZIONI."
	)
	if resume_button == null or change_button == null or settings_button == null:
		return

	# Nessuna icona fluttuante fuori colonna: IMPOSTAZIONI e' un fratello di
	# RIPRENDI/CAMBIA PERSONAGGIO nello stesso VBox, non un figlio diretto di
	# PauseOverlay come l'icona rimossa.
	assert_eq(
		settings_button.get_parent(), resume_button.get_parent(),
		"IMPOSTAZIONI deve stare nella stessa colonna (VBox) di RIPRENDI/CAMBIA PERSONAGGIO."
	)
	assert_eq(
		settings_button.get_parent(), change_button.get_parent(),
		"IMPOSTAZIONI deve stare nella stessa colonna (VBox) di CAMBIA PERSONAGGIO."
	)
	assert_eq(settings_button.text, "IMPOSTAZIONI", "Il bottone deve mostrare testo, non un glifo icona.")

	# Stile secondario come CAMBIA PERSONAGGIO, non primario come RIPRENDI.
	assert_eq(
		settings_button.get_theme_stylebox(&"normal"), change_button.get_theme_stylebox(&"normal"),
		"IMPOSTAZIONI deve condividere lo stile secondario di CAMBIA PERSONAGGIO."
	)
	assert_ne(
		settings_button.get_theme_stylebox(&"normal"), resume_button.get_theme_stylebox(&"normal"),
		"IMPOSTAZIONI non deve usare lo stile primario di RIPRENDI."
	)

	# Preme IMPOSTAZIONI: deve apparire la stessa istanza dell'overlay già
	# usata dalla welcome (PS-137), nessun comportamento nuovo lato overlay.
	settings_button.pressed.emit()
	await wait_process_frames(1)
	assert_true(settings_overlay.is_open(), "IMPOSTAZIONI deve apriere l'overlay condiviso esistente.")
	settings_overlay.close()
	await wait_process_frames(1)

	# Catena focus_neighbor a tre elementi (RIPRENDI <-> CAMBIA PERSONAGGIO <-> IMPOSTAZIONI).
	assert_eq(
		resume_button.get_node(resume_button.focus_neighbor_bottom), change_button,
		"Da RIPRENDI, in giù, si deve raggiungere CAMBIA PERSONAGGIO."
	)
	assert_eq(
		change_button.get_node(change_button.focus_neighbor_top), resume_button,
		"Da CAMBIA PERSONAGGIO, in su, si deve raggiungere RIPRENDI."
	)
	assert_eq(
		change_button.get_node(change_button.focus_neighbor_bottom), settings_button,
		"Da CAMBIA PERSONAGGIO, in giù, si deve raggiungere IMPOSTAZIONI."
	)
	assert_eq(
		settings_button.get_node(settings_button.focus_neighbor_top), change_button,
		"Da IMPOSTAZIONI, in su, si deve raggiungere CAMBIA PERSONAGGIO."
	)
	assert_eq(
		settings_button.get_node(settings_button.focus_neighbor_bottom), resume_button,
		"Da IMPOSTAZIONI, in giù, si deve tornare a RIPRENDI (catena chiusa a tre elementi)."
	)
	assert_eq(
		resume_button.get_node(resume_button.focus_neighbor_top), settings_button,
		"Da RIPRENDI, in su, si deve raggiungere IMPOSTAZIONI."
	)

	controller.request_defeat()

	print("PS143_PAUSE_SETTINGS_BUTTON_OK")


func test_ps143_welcome_gear_icon_is_unchanged() -> void:
	var movement_slice := await instantiate_movement_slice()
	var welcome := movement_slice.get_welcome_screen() as WelcomeScreen
	assert_not_null(welcome, "PS-143 richiede la WelcomeScreen dalla scena.")
	if welcome == null:
		return

	var welcome_settings_button := welcome.get_settings_button()
	assert_not_null(welcome_settings_button, "La welcome deve conservare il proprio bottone impostazioni.")
	if welcome_settings_button == null:
		return
	assert_eq(
		welcome_settings_button.text, "⚙",
		"PS-143 limita lo scope alla pausa: la welcome conserva la propria icona ingranaggio invariata."
	)
