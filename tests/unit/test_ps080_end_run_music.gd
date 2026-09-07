extends GutGameplayTest

## PS-080 — Musica dedicata di fine run: `VICTORY`/`DEFEAT` avviano una breve
## traccia musicale distinta dal cue SFX esistente, qualunque musica
## precedente (run, Boss, menu) si interrompe senza sovrapposizione, il
## restart la interrompe e con audio disattivato non suona nulla.


func test_victory_starts_dedicated_music_and_stops_run_music() -> void:
	var built := await _build_fixture(80001)
	if built.is_empty():
		return
	var controller: RunController = built["controller"]
	var audio: GameAudio = built["audio"]

	assert_true(audio.has_victory_music(), "PS-080 richiede la traccia musicale di vittoria configurata.")
	assert_true(audio.has_defeat_music(), "PS-080 richiede la traccia musicale di sconfitta configurata.")
	assert_true(
		audio.get_end_run_music_player() != null
			and audio.get_end_run_music_player().bus == GameAudio.MUSIC_BUS_NAME,
		"Il player della musica di fine run deve vivere sul bus Music."
	)
	assert_true(audio.is_background_music_active(), "La musica di run deve essere attiva prima della fine della run.")
	assert_false(audio.is_end_run_music_active(), "La musica di fine run non deve essere attiva durante la run.")

	assert_true(controller.request_victory(), "Deve essere possibile forzare la vittoria per la verifica.")

	assert_false(audio.is_background_music_active(), "La vittoria deve interrompere la musica di run.")
	assert_false(audio.is_boss_music_active(), "La vittoria deve interrompere la traccia Boss se attiva.")
	assert_true(audio.is_end_run_music_active(), "La vittoria deve avviare la musica dedicata di fine run.")

	_teardown_fixture(built)


func test_defeat_starts_dedicated_music() -> void:
	var built := await _build_fixture(80002)
	if built.is_empty():
		return
	var controller: RunController = built["controller"]
	var audio: GameAudio = built["audio"]

	assert_true(controller.request_defeat(), "Deve essere possibile forzare la sconfitta per la verifica.")
	assert_false(audio.is_background_music_active(), "La sconfitta deve interrompere la musica di run.")
	assert_true(audio.is_end_run_music_active(), "La sconfitta deve avviare la musica dedicata di fine run.")

	_teardown_fixture(built)


func test_restart_after_end_run_music_stops_it_without_overlap() -> void:
	var built := await _build_fixture(80003)
	if built.is_empty():
		return
	var movement_slice: Control = built["movement_slice"]
	var controller: RunController = built["controller"]
	var audio: GameAudio = built["audio"]

	assert_true(controller.request_defeat(), "La fixture di restart deve poter forzare la sconfitta.")
	assert_true(audio.is_end_run_music_active(), "La sconfitta deve avviare la musica di fine run prima del restart.")

	assert_true(movement_slice.restart_run(80004), "Il restart deve poter ripartire dopo la musica di fine run.")
	await wait_process_frames(2)

	assert_false(audio.is_end_run_music_active(), "Il restart deve interrompere la musica di fine run residua.")
	assert_true(audio.is_background_music_active(), "La nuova run deve avere la propria musica di run attiva.")

	_teardown_fixture(built)


func test_end_run_music_respects_mute_and_zero_volume() -> void:
	var built := await _build_fixture(80005)
	if built.is_empty():
		return
	var controller: RunController = built["controller"]
	var audio: GameAudio = built["audio"]

	var initial_volume := audio.get_effects_volume()
	var initial_muted := audio.is_muted()
	var music_bus_index := AudioServer.get_bus_index(GameAudio.MUSIC_BUS_NAME)

	audio.set_muted(true, false)
	assert_true(controller.request_defeat(), "La sconfitta deve potersi forzare anche con l'audio disattivato.")
	assert_true(audio.is_end_run_music_active(), "La traccia di fine run deve attivarsi anche con l'audio disattivato.")
	assert_true(
		AudioServer.is_bus_mute(music_bus_index),
		"Il mute deve silenziare il bus Music indipendentemente dalla traccia attiva."
	)

	audio.set_muted(false, false)
	audio.set_effects_volume(0.0, false)
	assert_true(
		is_equal_approx(
			AudioServer.get_bus_volume_db(music_bus_index), linear_to_db(GameAudio.MINIMUM_LINEAR_VOLUME)
		),
		"Il volume a zero deve azzerare il bus Music indipendentemente dalla traccia attiva."
	)

	audio.set_effects_volume(initial_volume, false)
	audio.set_muted(initial_muted, false)
	_teardown_fixture(built)

	print("END_RUN_MUSIC_SMOKE_OK")


func _build_fixture(seed_value: int) -> Dictionary:
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_run_controller() as RunController
	var audio := movement_slice.get_game_audio() as GameAudio
	assert_true(
		controller != null and audio != null,
		"PS-080 richiede RunController e GameAudio dalla scena."
	)
	if controller == null or audio == null:
		return {}

	# L'avvio automatico della scena usa il seed fisso di test (PS-032), non
	# quello richiesto dal chiamante: serve forzare il seed passando da un
	# terminale, come fa il flusso reale di restart (vedi B53, PS-073).
	if not controller.is_terminal():
		controller.request_defeat()
	assert_true(
		movement_slice.restart_run(seed_value), "La fixture PS-080 deve poter avviare la run con il seed richiesto."
	)
	await wait_process_frames(2)
	controller.set_process(false)

	return {
		"movement_slice": movement_slice,
		"controller": controller,
		"audio": audio,
	}


func _teardown_fixture(built: Dictionary) -> void:
	var controller: RunController = built.get("controller")
	if controller != null and not controller.is_terminal():
		controller.request_defeat()
	if controller != null:
		controller.prepare_restart()
