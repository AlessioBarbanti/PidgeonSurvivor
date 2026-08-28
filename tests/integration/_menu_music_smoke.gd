extends SceneTree

## Copre il loop musicale dei menu di BOOT: deve partire con la welcome, restare
## continuo attraverso selezione personaggio e tutorial, e lasciare il posto al
## loop della run senza mai sovrapporsi.

const MOVEMENT_SLICE_SCENE := preload("res://scenes/game/movement_slice.tscn")
const INITIAL_VIEWPORT_SIZE := Vector2i(1280, 720)

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.content_scale_size = INITIAL_VIEWPORT_SIZE
	root.size = INITIAL_VIEWPORT_SIZE
	await _wait_processed_frame()

	ProjectSettings.set_setting("application/run/b18o_force_welcome_for_test", true)
	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	root.add_child(movement_slice)
	ProjectSettings.set_setting("application/run/b18o_force_welcome_for_test", false)
	await _wait_processed_frame()

	var audio := movement_slice.get_game_audio() as GameAudio
	var controller := movement_slice.get_run_controller() as RunController
	var welcome := movement_slice.get_welcome_screen() as WelcomeScreen
	var selector := movement_slice.get_character_select_overlay() as CharacterSelectOverlay
	var tutorial := movement_slice.get_tutorial_screen() as TutorialScreen
	_expect(audio != null, "Il mixer scene-local deve esistere.")
	_expect(controller != null, "Il RunController deve esistere.")
	_expect(
		welcome != null and selector != null and tutorial != null,
		"Le schermate di BOOT devono esistere."
	)
	if audio == null or controller == null or welcome == null or selector == null or tutorial == null:
		await _cleanup(movement_slice)
		await _finish()
		return

	_expect(audio.has_menu_music(), "I menu richiedono uno stream musicale configurato.")
	_expect(
		audio.get_menu_music_player() != null
			and audio.get_menu_music_player().bus == GameAudio.MUSIC_BUS_NAME,
		"Il player dei menu deve stare sul bus Music, separato dal pool SFX."
	)
	_expect(
		audio.get_menu_music_player() != null
			and audio.get_menu_music_player() != audio.get_background_music_player(),
		"Menu e run devono avere player distinti."
	)
	_expect(
		audio.get_menu_music_player() != null
			and audio.get_menu_music_player().volume_db < 0.0,
		"La musica dei menu deve restare sotto gli SFX nel mix di default."
	)
	_expect(
		FileAccess.file_exists(
			"res://assets/audio/third_party/menu_music_wipics/ASSET-MANIFEST.md"
		),
		"L'asset dei menu richiede il manifest di provenienza."
	)
	_expect(
		FileAccess.file_exists("res://assets/audio/third_party/LICENSE-CC0-1.0.txt"),
		"L'asset dei menu richiede la copia della licenza CC0."
	)

	_expect(welcome.visible, "Il test deve partire dalla welcome screen.")
	_expect(audio.is_menu_music_active(), "La welcome deve avviare la musica dei menu.")
	_expect(audio.is_menu_music_looping(), "Il brano dei menu deve essere impostato in loop.")
	_expect(not audio.is_background_music_active(), "In BOOT il loop della run deve restare fermo.")

	welcome.play_requested.emit()
	await _wait_processed_frame()
	_expect(selector.visible, "La welcome deve portare alla selezione personaggio.")
	_expect(
		audio.is_menu_music_active(),
		"La selezione personaggio deve mantenere la musica dei menu."
	)

	selector.back_requested.emit()
	await _wait_processed_frame()
	_expect(welcome.visible, "Il ritorno deve riportare alla welcome.")
	_expect(audio.is_menu_music_active(), "Il ritorno alla welcome non deve spegnere la musica.")

	welcome.tutorial_requested.emit()
	await _wait_processed_frame()
	_expect(tutorial.visible, "La welcome deve portare al tutorial.")
	_expect(audio.is_menu_music_active(), "Il tutorial deve mantenere la musica dei menu.")

	_expect(audio.start_menu_music(), "Riavviare la musica gia' attiva deve essere un no-op accettato.")
	_expect(audio.is_menu_music_active(), "Il no-op non deve spegnere la musica dei menu.")

	var initial_volume := audio.get_effects_volume()
	var initial_muted := audio.is_muted()
	var music_bus_index := AudioServer.get_bus_index(GameAudio.MUSIC_BUS_NAME)
	audio.set_muted(true, false)
	_expect(
		AudioServer.is_bus_mute(music_bus_index),
		"Il mute deve silenziare il bus Music anche nei menu."
	)
	_expect(
		audio.is_menu_music_active(),
		"Il mute deve silenziare il bus senza perdere lo stato del loop dei menu."
	)
	audio.set_muted(initial_muted, false)
	audio.set_effects_volume(initial_volume, false)

	_expect(
		movement_slice.select_friend_for_next_run(&"magno"),
		"La selezione del personaggio di default deve riuscire."
	)
	_expect(movement_slice.start_selected_run(4201), "La run deve avviarsi dalla selezione.")
	await _wait_processed_frame()
	_expect(
		not audio.is_menu_music_active(),
		"L'avvio della run deve spegnere la musica dei menu."
	)
	_expect(audio.is_background_music_active(), "La run deve avere il proprio loop attivo.")

	_expect(controller.request_defeat(), "La run deve poter terminare.")
	await _wait_processed_frame()
	_expect(not audio.is_background_music_active(), "Il terminale deve pulire il loop della run.")
	_expect(
		not audio.is_menu_music_active(),
		"Il terminale non deve riaccendere la musica dei menu da solo."
	)

	var end_screen := movement_slice.get_end_screen() as EndScreen
	_expect(end_screen != null, "Il terminale deve esporre la end screen.")
	if end_screen != null:
		end_screen.change_character_requested.emit()
	await _wait_processed_frame()
	_expect(
		audio.is_menu_music_active(),
		"Il rientro nella selezione dal terminale deve riaccendere la musica dei menu."
	)
	_expect(
		not audio.is_background_music_active(),
		"Il rientro nei menu non deve lasciare attivo il loop della run."
	)

	var menu_player := audio.get_menu_music_player()
	await _cleanup(movement_slice)
	_expect(
		not is_instance_valid(menu_player) or not menu_player.playing,
		"Il teardown non deve lasciare musica dei menu attiva."
	)
	await _finish()


func _cleanup(movement_slice: Control) -> void:
	paused = false
	movement_slice.queue_free()
	await process_frame


func _wait_processed_frame() -> void:
	await process_frame
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	paused = false
	await process_frame
	if _failures.is_empty():
		print("MENU_MUSIC_SMOKE_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	printerr("MENU_MUSIC_SMOKE_FAIL count=%d" % _failures.size())
	quit(1)
