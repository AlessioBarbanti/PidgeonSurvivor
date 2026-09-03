extends GutGameplayTest

## PS-073 — Musica Boss dedicata: crossfade dalla musica di run alla traccia
## Boss all'intro (`boss_intro_started`), ripristino dalla posizione lasciata
## alla sconfitta (`boss_defeated`), ripetibilita' su piu' ricorrenze dello
## stesso Boss, interruzione pulita di entrambe le tracce su restart e
## sconfitta del giocatore, e silenzio totale con audio disattivato.

const BOSS_THRESHOLD_SECONDS := 120.01
const RECURRING_WINDOW_SECONDS := 240.01


func test_boss_music_crossfade_and_recurrence() -> void:
	var built := await _build_fixture(73001)
	if built.is_empty():
		return
	var controller: RunController = built["controller"]
	var encounter: BossEncounter = built["encounter"]
	var experience: ExperienceSystem = built["experience"]
	var service: UpgradeService = built["service"]
	var audio: GameAudio = built["audio"]

	assert_true(audio.has_boss_music(), "PS-073 richiede la traccia Boss dedicata configurata.")
	assert_true(
		FileAccess.file_exists(
			"res://assets/audio/third_party/matthewpablo_vilified/ASSET-MANIFEST.md"
		),
		"PS-073 richiede il manifest di provenienza della traccia Boss."
	)
	assert_true(
		audio.get_boss_music_player() != null
			and audio.get_boss_music_player().bus == GameAudio.MUSIC_BUS_NAME,
		"Il player della traccia Boss deve vivere sul bus Music."
	)

	assert_true(audio.is_background_music_active(), "La musica di run deve essere attiva prima del Boss.")
	assert_false(audio.is_boss_music_active(), "La traccia Boss non deve essere attiva prima dell'incontro.")

	for occurrence in range(2):
		_advance_to_boss(controller, occurrence)
		assert_eq(
			controller.get_state(), RunController.RunState.BOSS_INTRO,
			"La soglia deve aprire BOSS_INTRO alla ricorrenza %d." % occurrence
		)
		assert_true(
			audio.is_boss_music_active(),
			"boss_intro_started deve avviare il crossfade verso la traccia Boss (ricorrenza %d)." % occurrence
		)
		assert_false(
			audio.is_background_music_active(),
			"La musica di run deve tacere durante l'intro del Boss (ricorrenza %d)." % occurrence
		)

		assert_true(encounter.complete_intro(), "L'intro del Boss deve potersi chiudere.")
		assert_true(controller.is_running(), "Dopo l'intro la run deve tornare RUNNING con il Boss vivo.")
		assert_true(
			audio.is_boss_music_active(),
			(
				"La traccia Boss deve restare attiva per l'intera durata del combattimento, "
				+ "non solo durante BOSS_INTRO (ricorrenza %d)." % occurrence
			)
		)
		assert_false(
			audio.is_background_music_active(),
			"La musica di run non deve rientrare mentre il Boss e' ancora vivo (ricorrenza %d)." % occurrence
		)

		_kill_active_boss(encounter, controller, experience, service)
		assert_false(
			audio.is_boss_music_active(),
			"La sconfitta del Boss deve sempre concludere la sessione della traccia Boss (ricorrenza %d)." % occurrence
		)
		assert_eq(
			controller.get_state(), RunController.RunState.RUNNING,
			"Dopo aver risolto level-up/ricompensa Barb la run deve tornare RUNNING (ricorrenza %d)." % occurrence
		)
		assert_true(
			audio.is_background_music_active(),
			"La musica di run deve riprendere dopo la sconfitta del Boss (ricorrenza %d)." % occurrence
		)

	_teardown_fixture(built)


func test_restart_and_defeat_during_boss_fight_clear_both_tracks() -> void:
	var built := await _build_fixture(73002)
	if built.is_empty():
		return
	var movement_slice: Control = built["movement_slice"]
	var controller: RunController = built["controller"]
	var encounter: BossEncounter = built["encounter"]
	var audio: GameAudio = built["audio"]

	_advance_to_boss(controller, 0)
	assert_true(encounter.complete_intro(), "La fixture di restart deve poter chiudere l'intro del Boss.")
	assert_true(audio.is_boss_music_active(), "La fixture di restart deve raggiungere il combattimento Boss.")

	assert_true(controller.request_defeat(), "Deve essere possibile forzare la sconfitta del giocatore.")
	assert_false(
		audio.is_background_music_active(), "La sconfitta del giocatore non deve lasciare la musica di run attiva."
	)
	assert_false(audio.is_boss_music_active(), "La sconfitta del giocatore non deve lasciare la traccia Boss attiva.")

	assert_true(movement_slice.restart_run(73003), "Il restart deve poter ripartire con il Boss ancora vivo.")
	await wait_process_frames(2)
	# La nuova run e' gia' RUNNING: la sua musica di run riparte normalmente
	# (come in B29). Cio' che conta e' che non resti traccia Boss residua.
	assert_true(audio.is_background_music_active(), "La nuova run dopo il restart deve avere la propria musica attiva.")
	assert_false(audio.is_boss_music_active(), "Il restart non deve ripartire con traccia Boss residua.")

	_advance_to_boss(controller, 0)
	assert_true(audio.is_boss_music_active(), "Dopo il restart il crossfade Boss deve tornare a funzionare identico.")

	_teardown_fixture(built)


func test_boss_music_respects_mute_and_zero_volume() -> void:
	var built := await _build_fixture(73004)
	if built.is_empty():
		return
	var controller: RunController = built["controller"]
	var encounter: BossEncounter = built["encounter"]
	var audio: GameAudio = built["audio"]

	var initial_volume := audio.get_effects_volume()
	var initial_muted := audio.is_muted()
	var music_bus_index := AudioServer.get_bus_index(GameAudio.MUSIC_BUS_NAME)

	audio.set_muted(true, false)
	_advance_to_boss(controller, 0)
	assert_true(encounter.complete_intro(), "L'intro del Boss deve chiudersi anche con l'audio disattivato.")
	assert_true(audio.is_boss_music_active(), "Il crossfade deve avvenire anche con l'audio disattivato.")
	assert_true(
		AudioServer.is_bus_mute(music_bus_index),
		"Il mute deve silenziare il bus Music indipendentemente da quale traccia sia attiva."
	)

	audio.set_muted(false, false)
	audio.set_effects_volume(0.0, false)
	assert_true(
		is_equal_approx(
			AudioServer.get_bus_volume_db(music_bus_index), linear_to_db(GameAudio.MINIMUM_LINEAR_VOLUME)
		),
		"Il volume a zero deve azzerare il bus Music indipendentemente da quale traccia sia attiva."
	)

	audio.set_effects_volume(initial_volume, false)
	audio.set_muted(initial_muted, false)
	_teardown_fixture(built)

	print("BOSS_MUSIC_SMOKE_OK")


func _advance_to_boss(controller: RunController, occurrence: int) -> void:
	if occurrence == 0:
		controller._process(BOSS_THRESHOLD_SECONDS)
	else:
		controller._process(RECURRING_WINDOW_SECONDS)


func _kill_active_boss(
	encounter: BossEncounter,
	controller: RunController,
	experience: ExperienceSystem,
	service: UpgradeService
) -> void:
	var boss := encounter.get_active_boss()
	assert_not_null(boss, "Impossibile uccidere un Boss assente.")
	if boss == null:
		return
	var health := boss.get_health_component()
	assert_not_null(health, "Il Boss attivo deve avere una HealthComponent.")
	if health == null:
		return
	boss.take_damage(health.health_current)
	while controller.get_state() == RunController.RunState.LEVEL_UP:
		if not experience.complete_level_up():
			break
	# PS-012: la morte del Boss apre sempre una scelta di Barb; qui interessa
	# solo tornare in RUNNING, non quale Specialita'/bonus venga scelto.
	while controller.get_state() == RunController.RunState.BARB_REWARD:
		var offer := service.get_current_barb_offer()
		if offer.is_empty():
			break
		var chosen_id := offer[0].id
		var resolved := (
			service.select_barb_bonus_upgrade(chosen_id)
			if service.is_barb_bonus_mode()
			else service.select_barb_speciality(chosen_id)
		)
		if not resolved:
			break


func _build_fixture(seed_value: int) -> Dictionary:
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_run_controller() as RunController
	var encounter := movement_slice.get_boss_encounter() as BossEncounter
	var experience := movement_slice.get_experience_system() as ExperienceSystem
	var service := movement_slice.get_upgrade_service() as UpgradeService
	var audio := movement_slice.get_game_audio() as GameAudio
	assert_true(
		controller != null and encounter != null and experience != null and service != null and audio != null,
		"PS-073 richiede RunController, BossEncounter, ExperienceSystem, UpgradeService e GameAudio dalla scena."
	)
	if controller == null or encounter == null or experience == null or service == null or audio == null:
		return {}

	# L'avvio automatico della scena usa il seed fisso di test (PS-032), non
	# quello richiesto dal chiamante: serve forzare il seed passando da un
	# terminale, come fa il flusso reale di restart (vedi B53).
	if not controller.is_terminal():
		controller.request_defeat()
	assert_true(
		movement_slice.restart_run(seed_value), "La fixture PS-073 deve poter avviare la run con il seed richiesto."
	)
	await wait_process_frames(2)
	controller.set_process(false)

	return {
		"movement_slice": movement_slice,
		"controller": controller,
		"encounter": encounter,
		"experience": experience,
		"service": service,
		"audio": audio,
	}


func _teardown_fixture(built: Dictionary) -> void:
	var controller: RunController = built.get("controller")
	if controller != null and not controller.is_terminal():
		controller.request_defeat()
	if controller != null:
		controller.prepare_restart()
