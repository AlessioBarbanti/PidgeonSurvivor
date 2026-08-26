extends SceneTree

const MOVEMENT_SLICE_SCENE := preload("res://scenes/game/movement_slice.tscn")
const INITIAL_VIEWPORT_SIZE := Vector2i(1280, 720)

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.content_scale_size = INITIAL_VIEWPORT_SIZE
	root.size = INITIAL_VIEWPORT_SIZE
	await _wait_processed_frame()

	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	root.add_child(movement_slice)
	await _wait_processed_frame()

	var audio := movement_slice.get_game_audio() as GameAudio
	var controller := movement_slice.get_run_controller() as RunController
	_expect(audio != null, "B29 richiede il mixer scene-local.")
	_expect(controller != null, "B29 richiede il RunController.")
	if audio == null or controller == null:
		await _cleanup(movement_slice)
		await _finish()
		return

	_expect(audio.has_background_music(), "B29 richiede uno stream musicale configurato.")
	_expect(
		AudioServer.get_bus_index(GameAudio.MUSIC_BUS_NAME) >= 0,
		"B29 richiede un bus Music dedicato."
	)
	_expect(
		audio.get_background_music_player() != null
			and audio.get_background_music_player().bus == GameAudio.MUSIC_BUS_NAME,
		"Il player B29 deve restare separato dal pool SFX."
	)
	_expect(
		audio.get_background_music_player() != null
			and audio.get_background_music_player().volume_db < 0.0,
		"La musica B29 deve restare sotto gli SFX nel mix di default."
	)
	var music_bus_index := AudioServer.get_bus_index(GameAudio.MUSIC_BUS_NAME)
	var initial_volume := audio.get_effects_volume()
	var initial_muted := audio.is_muted()
	_expect(audio.set_effects_volume(0.35, false), "Il volume condiviso deve accettare valori validi.")
	_expect(
		is_equal_approx(AudioServer.get_bus_volume_db(music_bus_index), linear_to_db(0.35)),
		"Il volume persistente deve governare anche il bus Music."
	)
	audio.set_muted(true, false)
	_expect(AudioServer.is_bus_mute(music_bus_index), "Il mute persistente deve governare anche il bus Music.")
	audio.set_effects_volume(initial_volume, false)
	audio.set_muted(initial_muted, false)
	_expect(
		FileAccess.file_exists("res://assets/audio/third_party/LICENSE-CC0-1.0.txt"),
		"B29 richiede la copia della licenza CC0."
	)
	_expect(
		FileAccess.file_exists("res://assets/audio/third_party/super_wreck_roadway_loop.MANIFEST.md"),
		"B29 richiede il manifest di provenienza."
	)

	controller.prepare_restart()
	await _wait_processed_frame()
	_expect(not audio.is_background_music_active(), "BOOT non deve lasciare musica della run attiva.")
	_expect(controller.start_run(2901), "La prima run B29 deve avviarsi.")
	await _wait_processed_frame()
	_expect(audio.is_background_music_active(), "La musica deve partire in RUNNING.")
	_expect(audio.is_background_music_looping(), "Il brano B29 deve essere impostato in loop.")

	_expect(controller.request_manual_pause(), "La pausa manuale deve essere accettata.")
	await _wait_processed_frame()
	_expect(not audio.is_background_music_active(), "La musica deve fermarsi in pausa.")
	_expect(controller.resume_run(), "La run deve riprendere dalla pausa manuale.")
	await _wait_processed_frame()
	_expect(audio.is_background_music_active(), "La musica deve riprendere con la run.")

	_expect(controller.request_level_up(), "Il modal level-up deve essere accettato.")
	await _wait_processed_frame()
	_expect(not audio.is_background_music_active(), "La musica deve fermarsi nei modal della run.")
	_expect(controller.complete_level_up(), "Il modal level-up deve chiudersi.")
	await _wait_processed_frame()
	_expect(audio.is_background_music_active(), "La musica deve riprendere dopo il modal.")

	audio.set_muted(true, false)
	_expect(audio.is_background_music_active(), "Il mute deve silenziare il bus senza perdere lo stato del loop.")
	audio.set_muted(false, false)
	_expect(controller.request_defeat(), "La prima run deve poter terminare.")
	await _wait_processed_frame()
	_expect(not audio.is_background_music_active(), "Il terminale deve pulire la musica della prima run.")

	_expect(controller.restart_run(2902), "La seconda run B29 deve avviarsi senza player residui.")
	await _wait_processed_frame()
	_expect(audio.is_background_music_active(), "La seconda run deve avere esattamente il proprio loop attivo.")
	_expect(controller.request_victory(), "La seconda run deve poter terminare.")
	await _wait_processed_frame()
	_expect(not audio.is_background_music_active(), "Il cleanup finale non deve lasciare musica attiva.")

	await _cleanup(movement_slice)
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
		print("B29_BACKGROUND_MUSIC_SMOKE_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	printerr("B29_BACKGROUND_MUSIC_SMOKE_FAIL count=%d" % _failures.size())
	quit(1)
