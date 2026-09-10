extends GutGameplayTest


func test_background_music_follows_run_state_transitions() -> void:
	var movement_slice := await instantiate_movement_slice()

	var audio := movement_slice.get_game_audio() as GameAudio
	var controller := movement_slice.get_run_controller() as RunController
	assert_not_null(audio, "B29 richiede il mixer scene-local.")
	assert_not_null(controller, "B29 richiede il RunController.")
	if audio == null or controller == null:
		return

	assert_true(audio.has_background_music(), "B29 richiede uno stream musicale configurato.")
	assert_true(
		AudioServer.get_bus_index(GameAudio.MUSIC_BUS_NAME) >= 0, "B29 richiede un bus Music dedicato."
	)
	assert_true(
		audio.get_background_music_player() != null
			and audio.get_background_music_player().bus == GameAudio.MUSIC_BUS_NAME,
		"Il player B29 deve restare separato dal pool SFX."
	)
	assert_true(
		audio.get_background_music_player() != null
			and audio.get_background_music_player().volume_db < 0.0,
		"La musica B29 deve restare sotto gli SFX nel mix di default."
	)
	var music_bus_index := AudioServer.get_bus_index(GameAudio.MUSIC_BUS_NAME)
	var initial_volume := audio.get_effects_volume()
	var initial_muted := audio.is_muted()
	assert_true(audio.set_effects_volume(0.35, false), "Il volume condiviso deve accettare valori validi.")
	assert_true(
		is_equal_approx(AudioServer.get_bus_volume_db(music_bus_index), linear_to_db(0.35)),
		"Il volume persistente deve governare anche il bus Music."
	)
	audio.set_muted(true, false)
	assert_true(AudioServer.is_bus_mute(music_bus_index), "Il mute persistente deve governare anche il bus Music.")
	audio.set_effects_volume(initial_volume, false)
	audio.set_muted(initial_muted, false)
	assert_true(
		FileAccess.file_exists("res://assets/audio/third_party/LICENSE-CC0-1.0.txt"),
		"B29 richiede la copia della licenza CC0."
	)
	assert_true(
		FileAccess.file_exists("res://assets/audio/third_party/super_wreck_roadway_loop/ASSET-MANIFEST.md"),
		"B29 richiede il manifest di provenienza."
	)

	controller.prepare_restart()
	await wait_process_frames(2)
	assert_false(audio.is_background_music_active(), "BOOT non deve lasciare musica della run attiva.")
	assert_true(controller.start_run(2901), "La prima run B29 deve avviarsi.")
	await wait_process_frames(2)
	assert_true(audio.is_background_music_active(), "La musica deve partire in RUNNING.")
	assert_true(audio.is_background_music_looping(), "Il brano B29 deve essere impostato in loop.")

	assert_true(controller.request_manual_pause(), "La pausa manuale deve essere accettata.")
	await wait_process_frames(2)
	assert_false(audio.is_background_music_active(), "La musica deve fermarsi in pausa.")
	assert_true(controller.resume_run(), "La run deve riprendere dalla pausa manuale.")
	await wait_process_frames(2)
	assert_true(audio.is_background_music_active(), "La musica deve riprendere con la run.")

	assert_true(controller.request_level_up(), "Il modal level-up deve essere accettato.")
	await wait_process_frames(2)
	assert_true(
		audio.is_background_music_active(),
		"PS-056: il modal level-up abbassa la musica (ducking), non la ferma piu'."
	)
	assert_true(audio.is_music_ducked(), "PS-056: il modal level-up deve attivare il ducking.")
	assert_true(controller.complete_level_up(), "Il modal level-up deve chiudersi.")
	await wait_process_frames(2)
	assert_true(audio.is_background_music_active(), "La musica deve restare attiva dopo il modal.")
	assert_false(audio.is_music_ducked(), "PS-056: il ducking deve ritirarsi alla chiusura del modal.")

	audio.set_muted(true, false)
	assert_true(audio.is_background_music_active(), "Il mute deve silenziare il bus senza perdere lo stato del loop.")
	audio.set_muted(false, false)
	assert_true(controller.request_defeat(), "La prima run deve poter terminare.")
	await wait_process_frames(2)
	assert_false(audio.is_background_music_active(), "Il terminale deve pulire la musica della prima run.")

	assert_true(controller.restart_run(2902), "La seconda run B29 deve avviarsi senza player residui.")
	await wait_process_frames(2)
	assert_true(audio.is_background_music_active(), "La seconda run deve avere esattamente il proprio loop attivo.")
	assert_true(controller.request_victory(), "La seconda run deve poter terminare.")
	await wait_process_frames(2)
	assert_false(audio.is_background_music_active(), "Il cleanup finale non deve lasciare musica attiva.")
