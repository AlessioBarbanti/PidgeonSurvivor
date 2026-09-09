extends GutGameplayTest

## PS-081 — Accelerazione late-run della musica di run: `pitch_scale` sale
## gradualmente fra le soglie già dichiarate da `EnemySpawnProfile`, resta al
## massimo oltre la soglia finale, non tocca mai la traccia Boss dedicata,
## resta compatibile col ducking di PS-056 e si azzera al restart.
##
## Le soglie usate a runtime (`late_run_curve_start_seconds`/`_full_seconds`)
## sono ridotte su un profilo duplicato per restare ben sotto la prima soglia
## Boss di default (120s, `GameDirectorProfile.boss_thresholds_seconds`):
## altrimenti avanzare il clock di run con `controller._process()` farebbe
## scattare sincronamente `BOSS_INTRO`, bloccando l'avanzamento del tempo che
## questo smoke deve controllare — competenza di altri smoke (b15/b33), non
## di questo.

const PITCH_TOLERANCE := 0.001
const TEST_START_SECONDS := 10.0
const TEST_FULL_SECONDS := 40.0


func test_pitch_is_normal_before_the_late_run_threshold() -> void:
	var built := await _build_fixture(81001)
	if built.is_empty():
		return
	var audio: GameAudio = built["audio"]

	assert_almost_eq(
		audio.get_background_music_player().pitch_scale,
		1.0,
		PITCH_TOLERANCE,
		"Prima della soglia iniziale la musica di run deve suonare a velocità normale."
	)

	_teardown_fixture(built)


func test_pitch_rises_gradually_and_caps_past_the_full_threshold() -> void:
	var built := await _build_fixture(81002)
	if built.is_empty():
		return
	var controller: RunController = built["controller"]
	var audio: GameAudio = built["audio"]

	controller._process(TEST_START_SECONDS)
	assert_almost_eq(
		audio.get_background_music_player().pitch_scale,
		1.0,
		PITCH_TOLERANCE,
		"All'ingresso esatto nella soglia iniziale la velocità deve essere ancora quella normale."
	)

	var midpoint_delta := (TEST_FULL_SECONDS - TEST_START_SECONDS) * 0.5
	controller._process(midpoint_delta)
	var midpoint_pitch := audio.get_background_music_player().pitch_scale
	assert_almost_eq(
		midpoint_pitch,
		1.0 + GameAudio.MUSIC_LATE_RUN_MAX_PITCH_SCALE_OFFSET * 0.5,
		0.01,
		"A metà curva la velocità deve essere a metà del massimo, crescita graduale."
	)
	assert_true(midpoint_pitch > 1.0, "A metà curva la velocità deve già essere sopra il normale.")

	controller._process(midpoint_delta + 5.0)
	var max_pitch := audio.get_background_music_player().pitch_scale
	assert_almost_eq(
		max_pitch,
		1.0 + GameAudio.MUSIC_LATE_RUN_MAX_PITCH_SCALE_OFFSET,
		PITCH_TOLERANCE,
		"Oltre la soglia finale la velocità deve aver raggiunto il massimo dichiarato."
	)

	controller._process(20.0)
	assert_almost_eq(
		audio.get_background_music_player().pitch_scale,
		max_pitch,
		PITCH_TOLERANCE,
		"Oltre la soglia finale la velocità non deve continuare a salire."
	)

	_teardown_fixture(built)


func test_boss_music_player_is_never_accelerated() -> void:
	var built := await _build_fixture(81003)
	if built.is_empty():
		return
	var controller: RunController = built["controller"]
	var audio: GameAudio = built["audio"]

	controller._process(TEST_FULL_SECONDS + 20.0)
	assert_almost_eq(
		audio.get_background_music_player().pitch_scale,
		1.0 + GameAudio.MUSIC_LATE_RUN_MAX_PITCH_SCALE_OFFSET,
		PITCH_TOLERANCE,
		"La musica di run deve essere accelerata al massimo a questo punto."
	)
	assert_almost_eq(
		audio.get_boss_music_player().pitch_scale,
		1.0,
		PITCH_TOLERANCE,
		"PS-081 non deve mai toccare la velocità della traccia Boss dedicata (PS-073)."
	)

	_teardown_fixture(built)


func test_pitch_stays_correct_while_ducked_by_ps056() -> void:
	var built := await _build_fixture(81004)
	if built.is_empty():
		return
	var controller: RunController = built["controller"]
	var audio: GameAudio = built["audio"]

	controller._process(TEST_START_SECONDS + (TEST_FULL_SECONDS - TEST_START_SECONDS) * 0.5)
	var expected_pitch := audio.get_background_music_player().pitch_scale
	var base_db := audio.get_background_music_player().volume_db

	controller.set_process(true)
	assert_true(controller.request_level_up(), "Il level-up deve poter scattare a metà curva late-run.")
	await wait_process_frames(2)
	controller.set_process(false)

	assert_true(audio.is_music_ducked(), "Il ducking di PS-056 deve restare attivo indipendentemente da PS-081.")
	assert_almost_eq(
		audio.get_background_music_player().pitch_scale,
		expected_pitch,
		PITCH_TOLERANCE,
		"Il ducking (volume) non deve alterare la velocità stabilita da PS-081."
	)
	assert_almost_eq(
		audio.get_background_music_player().volume_db,
		base_db + GameAudio.MUSIC_DUCK_OFFSET_DB,
		0.01,
		"Il ducking deve continuare a funzionare invariato con PS-081 attivo."
	)

	assert_true(controller.complete_level_up())
	_teardown_fixture(built)


func test_restart_resets_the_acceleration() -> void:
	var built := await _build_fixture(81005)
	if built.is_empty():
		return
	var controller: RunController = built["controller"]
	var audio: GameAudio = built["audio"]

	controller._process(TEST_FULL_SECONDS + 10.0)
	assert_true(
		audio.get_background_music_player().pitch_scale > 1.0,
		"La run deve essere accelerata prima del restart, altrimenti il test non prova nulla."
	)

	controller.set_process(true)
	assert_true(controller.request_defeat(), "La run deve poter terminare mentre e' accelerata.")
	await wait_process_frames(2)
	assert_almost_eq(
		audio.get_background_music_player().pitch_scale,
		1.0,
		PITCH_TOLERANCE,
		"La sconfitta deve azzerare l'accelerazione residua."
	)

	assert_true(controller.restart_run(81006), "Il restart deve avviarsi senza accelerazione residua.")
	await wait_process_frames(2)
	assert_almost_eq(
		audio.get_background_music_player().pitch_scale,
		1.0,
		PITCH_TOLERANCE,
		"Una nuova run non deve ereditare l'accelerazione dalla precedente."
	)
	controller.set_process(false)

	_teardown_fixture(built)

	print("LATE_RUN_MUSIC_INTENSITY_SMOKE_OK")


func _build_fixture(seed_value: int) -> Dictionary:
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_run_controller() as RunController
	var audio := movement_slice.get_game_audio() as GameAudio
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	assert_true(
		controller != null and audio != null and spawner != null and spawner.spawn_profile != null,
		"PS-081 richiede RunController, GameAudio ed EnemySpawner (con profilo) dalla scena."
	)
	if controller == null or audio == null or spawner == null or spawner.spawn_profile == null:
		return {}

	var original_profile := spawner.spawn_profile
	var test_profile := original_profile.duplicate(true) as EnemySpawnProfile
	test_profile.late_run_curve_start_seconds = TEST_START_SECONDS
	test_profile.late_run_curve_full_seconds = TEST_FULL_SECONDS
	spawner.spawn_profile = test_profile

	if not controller.is_terminal():
		controller.request_defeat()
	assert_true(
		movement_slice.restart_run(seed_value), "La fixture PS-081 deve poter avviare la run con il seed richiesto."
	)
	await wait_process_frames(2)
	controller.set_process(false)

	return {
		"movement_slice": movement_slice,
		"controller": controller,
		"audio": audio,
		"spawner": spawner,
		"original_profile": original_profile,
	}


func _teardown_fixture(built: Dictionary) -> void:
	var controller: RunController = built.get("controller")
	if controller != null:
		controller.set_process(true)
		if not controller.is_terminal():
			controller.request_defeat()
		controller.prepare_restart()
	var spawner: EnemySpawner = built.get("spawner")
	var original_profile: EnemySpawnProfile = built.get("original_profile")
	if spawner != null and original_profile != null:
		spawner.spawn_profile = original_profile
