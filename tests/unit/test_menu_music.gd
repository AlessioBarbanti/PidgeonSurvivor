extends GutGameplayTest

## Copre il loop musicale dei menu di BOOT: deve partire con la welcome, restare
## continuo attraverso selezione personaggio e tutorial, e lasciare il posto al
## loop della run senza mai sovrapporsi.


func test_menu_music_stays_continuous_through_boot_flow() -> void:
	get_tree().root.content_scale_size = INITIAL_VIEWPORT_SIZE
	get_tree().root.size = INITIAL_VIEWPORT_SIZE
	await wait_process_frames(2)

	ProjectSettings.set_setting("application/run/b18o_force_welcome_for_test", true)
	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	add_child_autofree(movement_slice)
	ProjectSettings.set_setting("application/run/b18o_force_welcome_for_test", false)
	await wait_process_frames(2)

	var audio := movement_slice.get_game_audio() as GameAudio
	var controller := movement_slice.get_run_controller() as RunController
	var welcome := movement_slice.get_welcome_screen() as WelcomeScreen
	var selector := movement_slice.get_character_select_overlay() as CharacterSelectOverlay
	var tutorial := movement_slice.get_tutorial_screen() as TutorialScreen
	assert_not_null(audio, "Il mixer scene-local deve esistere.")
	assert_not_null(controller, "Il RunController deve esistere.")
	assert_true(
		welcome != null and selector != null and tutorial != null, "Le schermate di BOOT devono esistere."
	)
	if audio == null or controller == null or welcome == null or selector == null or tutorial == null:
		return

	assert_true(audio.has_menu_music(), "I menu richiedono uno stream musicale configurato.")
	assert_true(
		audio.get_menu_music_player() != null
			and audio.get_menu_music_player().bus == GameAudio.MUSIC_BUS_NAME,
		"Il player dei menu deve stare sul bus Music, separato dal pool SFX."
	)
	assert_true(
		audio.get_menu_music_player() != null
			and audio.get_menu_music_player() != audio.get_background_music_player(),
		"Menu e run devono avere player distinti."
	)
	assert_true(
		audio.get_menu_music_player() != null
			and audio.get_menu_music_player().volume_db < 0.0,
		"La musica dei menu deve restare sotto gli SFX nel mix di default."
	)
	assert_true(
		FileAccess.file_exists("res://assets/audio/third_party/menu_music_wipics/ASSET-MANIFEST.md"),
		"L'asset dei menu richiede il manifest di provenienza."
	)
	assert_true(
		FileAccess.file_exists("res://assets/audio/third_party/LICENSE-CC0-1.0.txt"),
		"L'asset dei menu richiede la copia della licenza CC0."
	)

	assert_true(welcome.visible, "Il test deve partire dalla welcome screen.")
	assert_true(audio.is_menu_music_active(), "La welcome deve avviare la musica dei menu.")
	assert_true(audio.is_menu_music_looping(), "Il brano dei menu deve essere impostato in loop.")
	assert_false(audio.is_background_music_active(), "In BOOT il loop della run deve restare fermo.")

	welcome.play_requested.emit()
	await wait_process_frames(2)
	assert_true(selector.visible, "La welcome deve portare alla selezione personaggio.")
	assert_true(audio.is_menu_music_active(), "La selezione personaggio deve mantenere la musica dei menu.")

	selector.back_requested.emit()
	await wait_process_frames(2)
	assert_true(welcome.visible, "Il ritorno deve riportare alla welcome.")
	assert_true(audio.is_menu_music_active(), "Il ritorno alla welcome non deve spegnere la musica.")

	welcome.tutorial_requested.emit()
	await wait_process_frames(2)
	assert_true(tutorial.visible, "La welcome deve portare al tutorial.")
	assert_true(audio.is_menu_music_active(), "Il tutorial deve mantenere la musica dei menu.")

	assert_true(audio.start_menu_music(), "Riavviare la musica gia' attiva deve essere un no-op accettato.")
	assert_true(audio.is_menu_music_active(), "Il no-op non deve spegnere la musica dei menu.")

	var initial_volume := audio.get_effects_volume()
	var initial_muted := audio.is_muted()
	var music_bus_index := AudioServer.get_bus_index(GameAudio.MUSIC_BUS_NAME)
	audio.set_muted(true, false)
	assert_true(AudioServer.is_bus_mute(music_bus_index), "Il mute deve silenziare il bus Music anche nei menu.")
	assert_true(
		audio.is_menu_music_active(), "Il mute deve silenziare il bus senza perdere lo stato del loop dei menu."
	)
	audio.set_muted(initial_muted, false)
	audio.set_effects_volume(initial_volume, false)

	assert_true(
		movement_slice.select_friend_for_next_run(&"magno"), "La selezione del personaggio di default deve riuscire."
	)
	assert_true(movement_slice.start_selected_run(4201), "La run deve avviarsi dalla selezione.")
	await wait_process_frames(2)
	assert_false(audio.is_menu_music_active(), "L'avvio della run deve spegnere la musica dei menu.")
	assert_true(audio.is_background_music_active(), "La run deve avere il proprio loop attivo.")

	assert_true(controller.request_defeat(), "La run deve poter terminare.")
	await wait_process_frames(2)
	assert_false(audio.is_background_music_active(), "Il terminale deve pulire il loop della run.")
	assert_false(audio.is_menu_music_active(), "Il terminale non deve riaccendere la musica dei menu da solo.")

	var end_screen := movement_slice.get_end_screen() as EndScreen
	assert_not_null(end_screen, "Il terminale deve esporre la end screen.")
	if end_screen != null:
		end_screen.change_character_requested.emit()
	await wait_process_frames(2)
	assert_true(
		audio.is_menu_music_active(), "Il rientro nella selezione dal terminale deve riaccendere la musica dei menu."
	)
	assert_false(
		audio.is_background_music_active(), "Il rientro nei menu non deve lasciare attivo il loop della run."
	)

	var menu_player := audio.get_menu_music_player()
	movement_slice.queue_free()
	await wait_process_frames(1)
	assert_true(
		not is_instance_valid(menu_player) or not menu_player.playing,
		"Il teardown non deve lasciare musica dei menu attiva."
	)
