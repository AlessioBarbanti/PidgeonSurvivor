extends GutGameplayTest

## PS-056 — Ducking e stinger nei momenti chiave: avvertimento Boss
## (countdown PS-005), level-up e ricompensa Barb abbassano la musica di run
## invece di fermarla, tornano esattamente al volume di partenza alla
## chiusura, non si sommano quando si sovrappongono e restano silenziosi con
## l'audio disattivato.

const DUCK_TOLERANCE := 0.01


func test_level_up_ducks_music_without_stopping_it() -> void:
	var built := await _build_fixture(56001)
	if built.is_empty():
		return
	var controller: RunController = built["controller"]
	var audio: GameAudio = built["audio"]

	var base_db := audio.get_background_music_player().volume_db
	assert_false(audio.is_music_ducked(), "Nessun momento chiave e' attivo appena avviata la run.")

	assert_true(controller.request_level_up(), "Il modal level-up deve essere accettato.")
	await wait_process_frames(2)
	assert_true(audio.is_music_ducked(), "LEVEL_UP deve abbassare la musica di run.")
	assert_true(
		audio.is_background_music_active(),
		"PS-056: LEVEL_UP non deve piu' fermare la musica di run, solo abbassarla."
	)
	assert_almost_eq(
		audio.get_background_music_player().volume_db,
		base_db + GameAudio.MUSIC_DUCK_OFFSET_DB,
		DUCK_TOLERANCE,
		"Il ducking deve applicare esattamente MUSIC_DUCK_OFFSET_DB rispetto al volume di base."
	)

	assert_true(controller.complete_level_up(), "Il modal level-up deve potersi chiudere.")
	await wait_process_frames(2)
	assert_false(audio.is_music_ducked(), "Alla chiusura di LEVEL_UP il ducking deve ritirarsi.")
	assert_almost_eq(
		audio.get_background_music_player().volume_db,
		base_db,
		DUCK_TOLERANCE,
		"La musica deve tornare esattamente al volume precedente."
	)

	_teardown_fixture(built)


func test_barb_reward_ducks_music_and_plays_a_stinger() -> void:
	var built := await _build_fixture(56002)
	if built.is_empty():
		return
	var controller: RunController = built["controller"]
	var audio: GameAudio = built["audio"]

	var base_db := audio.get_background_music_player().volume_db
	var cues_played: Array[StringName] = []
	audio.cue_played.connect(func(cue_id: StringName) -> void: cues_played.append(cue_id))

	assert_true(controller.request_barb_reward(), "Il modal ricompensa Barb deve essere accettato.")
	await wait_process_frames(2)
	assert_true(audio.is_music_ducked(), "BARB_REWARD deve abbassare la musica di run.")
	assert_true(
		GameAudio.LEVEL_UP in cues_played,
		"BARB_REWARD deve riprodurre uno stinger udibile (riuso del cue LEVEL_UP)."
	)

	assert_true(controller.complete_barb_reward(), "Il modal ricompensa Barb deve potersi chiudere.")
	await wait_process_frames(2)
	assert_false(audio.is_music_ducked(), "Alla chiusura di BARB_REWARD il ducking deve ritirarsi.")
	assert_almost_eq(
		audio.get_background_music_player().volume_db,
		base_db,
		DUCK_TOLERANCE,
		"La musica deve tornare esattamente al volume precedente dopo BARB_REWARD."
	)

	_teardown_fixture(built)


func test_boss_warning_countdown_ducks_only_on_countdown_phase() -> void:
	var built := await _build_fixture(56003)
	if built.is_empty():
		return
	var director: GameDirector = built["director"]
	var audio: GameAudio = built["audio"]

	var base_db := audio.get_background_music_player().volume_db
	var cues_played: Array[StringName] = []
	audio.cue_played.connect(func(cue_id: StringName) -> void: cues_played.append(cue_id))

	director.boss_warning_changed.emit(0, GameDirector.BossWarningPhase.APPROACHING, 8)
	await wait_process_frames(2)
	assert_false(audio.is_music_ducked(), "APPROACHING precede l'urgenza: non deve duckare.")

	director.boss_warning_changed.emit(0, GameDirector.BossWarningPhase.COUNTDOWN, 5)
	await wait_process_frames(2)
	assert_true(audio.is_music_ducked(), "COUNTDOWN deve abbassare la musica di run.")
	assert_true(GameAudio.BOSS_WARNING in cues_played, "COUNTDOWN deve riprodurre uno stinger BOSS_WARNING.")
	assert_almost_eq(
		audio.get_background_music_player().volume_db,
		base_db + GameAudio.MUSIC_DUCK_OFFSET_DB,
		DUCK_TOLERANCE,
		"Il ducking del countdown Boss deve usare lo stesso bersaglio degli altri momenti."
	)

	director.boss_warning_changed.emit(-1, GameDirector.BossWarningPhase.HIDDEN, 0)
	await wait_process_frames(2)
	assert_false(audio.is_music_ducked(), "L'uscita da COUNTDOWN (Boss arrivato) deve ritirare il ducking.")
	assert_almost_eq(
		audio.get_background_music_player().volume_db,
		base_db,
		DUCK_TOLERANCE,
		"La musica deve tornare esattamente al volume precedente dopo il countdown."
	)

	_teardown_fixture(built)


func test_overlapping_moments_do_not_stack_and_stay_ducked_until_all_close() -> void:
	var built := await _build_fixture(56004)
	if built.is_empty():
		return
	var controller: RunController = built["controller"]
	var director: GameDirector = built["director"]
	var audio: GameAudio = built["audio"]

	var base_db := audio.get_background_music_player().volume_db

	director.boss_warning_changed.emit(0, GameDirector.BossWarningPhase.COUNTDOWN, 5)
	await wait_process_frames(2)
	assert_true(controller.request_level_up(), "Il level-up deve poter sovrapporsi al countdown Boss.")
	await wait_process_frames(2)
	assert_almost_eq(
		audio.get_background_music_player().volume_db,
		base_db + GameAudio.MUSIC_DUCK_OFFSET_DB,
		DUCK_TOLERANCE,
		"Due momenti sovrapposti non devono sommare l'abbassamento."
	)

	assert_true(controller.complete_level_up(), "Il level-up deve potersi chiudere mentre il countdown resta attivo.")
	await wait_process_frames(2)
	assert_true(
		audio.is_music_ducked(),
		"La musica deve restare abbassata finche' il countdown Boss e' ancora attivo."
	)

	director.boss_warning_changed.emit(-1, GameDirector.BossWarningPhase.HIDDEN, 0)
	await wait_process_frames(2)
	assert_false(audio.is_music_ducked(), "Solo la chiusura dell'ultimo momento deve ripristinare il volume.")
	assert_almost_eq(audio.get_background_music_player().volume_db, base_db, DUCK_TOLERANCE)

	_teardown_fixture(built)


func test_ducking_stingers_respect_mute() -> void:
	var built := await _build_fixture(56005)
	if built.is_empty():
		return
	var controller: RunController = built["controller"]
	var audio: GameAudio = built["audio"]

	var initial_volume := audio.get_effects_volume()
	var initial_muted := audio.is_muted()

	audio.set_muted(true, false)
	var cues_muted: Array[StringName] = []
	audio.cue_played.connect(func(cue_id: StringName) -> void: cues_muted.append(cue_id))
	assert_true(controller.request_barb_reward(), "BARB_REWARD deve essere accettato anche con l'audio disattivato.")
	await wait_process_frames(2)
	assert_true(cues_muted.is_empty(), "Con audio disattivato lo stinger non deve essere udibile.")
	assert_true(controller.complete_barb_reward())
	await wait_process_frames(2)

	audio.set_muted(initial_muted, false)
	audio.set_effects_volume(initial_volume, false)
	_teardown_fixture(built)


func test_restart_and_defeat_reset_ducking_state() -> void:
	var built := await _build_fixture(56006)
	if built.is_empty():
		return
	var controller: RunController = built["controller"]
	var audio: GameAudio = built["audio"]

	assert_true(controller.request_level_up(), "Il level-up deve essere accettato prima della sconfitta.")
	await wait_process_frames(2)
	assert_true(audio.is_music_ducked(), "Il ducking deve essere attivo prima della sconfitta.")

	controller.set_process(true)
	assert_true(controller.request_defeat(), "La run deve poter terminare mentre un momento chiave e' ducked.")
	await wait_process_frames(2)
	assert_false(audio.is_music_ducked(), "La sconfitta deve azzerare il ducking residuo.")

	assert_true(controller.restart_run(56007), "Il restart deve avviarsi senza ducking residuo.")
	await wait_process_frames(2)
	controller.set_process(false)
	assert_false(audio.is_music_ducked(), "Una nuova run non deve ereditare un ducking dalla precedente.")

	_teardown_fixture(built)

	print("AUDIO_DUCKING_SMOKE_OK")


func _build_fixture(seed_value: int) -> Dictionary:
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_run_controller() as RunController
	var director := movement_slice.get_game_director() as GameDirector
	var audio := movement_slice.get_game_audio() as GameAudio
	assert_true(
		controller != null and director != null and audio != null,
		"PS-056 richiede RunController, GameDirector e GameAudio dalla scena."
	)
	if controller == null or director == null or audio == null:
		return {}

	if not controller.is_terminal():
		controller.request_defeat()
	assert_true(
		movement_slice.restart_run(seed_value), "La fixture PS-056 deve poter avviare la run con il seed richiesto."
	)
	await wait_process_frames(2)
	controller.set_process(false)

	return {
		"movement_slice": movement_slice,
		"controller": controller,
		"director": director,
		"audio": audio,
	}


func _teardown_fixture(built: Dictionary) -> void:
	var controller: RunController = built.get("controller")
	if controller != null:
		controller.set_process(true)
		if not controller.is_terminal():
			controller.request_defeat()
		controller.prepare_restart()
