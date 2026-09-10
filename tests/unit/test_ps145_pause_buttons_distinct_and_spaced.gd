extends GutGameplayTest

## PS-145: RIPRENDI, CAMBIA PERSONAGGIO e IMPOSTAZIONI nel pannello pausa
## devono leggersi come elementi distinti e separati. Verifica la
## separazione allargata del VBox, che IMPOSTAZIONI usi oggetti stile propri
## (diversi da CAMBIA PERSONAGGIO) e che i due segmenti di catena
## focus_neighbor stabiliti da PS-143 (RIPRENDI<->CAMBIA PERSONAGGIO<->
## IMPOSTAZIONI) restino invariati. Non assume che la colonna abbia
## esattamente tre bottoni: PS-147 vi aggiunge ESCI in coda, con la propria
## catena verificata da tests/unit/test_ps147_pause_exit_button.gd.


func test_ps145_pause_buttons_distinct_and_spaced() -> void:
	var movement_slice := await instantiate_movement_slice()
	var controller := movement_slice.get_run_controller() as RunController
	var pause_overlay := movement_slice.get_pause_overlay() as PauseOverlay
	assert_true(
		controller != null and pause_overlay != null,
		"PS-145 richiede RunController/PauseOverlay dalla scena."
	)
	if controller == null or pause_overlay == null:
		return

	assert_true(controller.request_manual_pause(), "PS-145 richiede di poter aprire la pausa manuale.")
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

	var vbox := resume_button.get_parent() as VBoxContainer
	assert_not_null(vbox, "I tre bottoni devono stare in un VBoxContainer.")
	if vbox != null:
		assert_eq(
			vbox.get_theme_constant(&"separation"), 16,
			"PS-145 richiede separation=16 nel VBox della colonna pausa."
		)

	# IMPOSTAZIONI usa oggetti stile propri (tonalita' dedicata), diversi da
	# CAMBIA PERSONAGGIO pur condividendo sagoma/texture/altezza target.
	assert_ne(
		settings_button.get_theme_stylebox(&"normal"), change_button.get_theme_stylebox(&"normal"),
		"IMPOSTAZIONI deve avere uno StyleBoxTexture normal diverso da CAMBIA PERSONAGGIO."
	)
	assert_ne(
		settings_button.get_theme_stylebox(&"hover"), change_button.get_theme_stylebox(&"hover"),
		"IMPOSTAZIONI deve avere uno StyleBoxTexture hover diverso da CAMBIA PERSONAGGIO."
	)
	assert_ne(
		settings_button.get_theme_stylebox(&"pressed"), change_button.get_theme_stylebox(&"pressed"),
		"IMPOSTAZIONI deve avere uno StyleBoxTexture pressed diverso da CAMBIA PERSONAGGIO."
	)
	assert_eq(
		settings_button.custom_minimum_size.y, change_button.custom_minimum_size.y,
		"IMPOSTAZIONI deve mantenere la stessa altezza target touch (64px) di CAMBIA PERSONAGGIO."
	)

	# Segmenti di catena focus_neighbor stabiliti da PS-143, invarianti a
	# prescindere da cosa segue IMPOSTAZIONI in coda (oggi ESCI, per PS-147).
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

	controller.request_defeat()

	print("PS145_PAUSE_BUTTONS_DISTINCT_OK")
