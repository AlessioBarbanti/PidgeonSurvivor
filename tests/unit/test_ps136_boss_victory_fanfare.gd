extends GutGameplayTest

## PS-136 — Fanfara di vittoria alla sconfitta del Boss: `boss_defeated` deve
## riprodurre il cue `GameAudio.BOSS_VICTORY`, distinto da `VICTORY`/`DEFEAT`
## di fine run, a ogni sconfitta (incluse le ricorrenze), rispettando mute e
## volume a zero come ogni altro cue.

const BOSS_THRESHOLD_SECONDS := 120.01
const RECURRING_WINDOW_SECONDS := 240.01


func test_boss_defeated_plays_the_boss_victory_cue_on_every_recurrence() -> void:
	var built := await _build_fixture(136001)
	if built.is_empty():
		return
	var controller: RunController = built["controller"]
	var encounter: BossEncounter = built["encounter"]
	var experience: ExperienceSystem = built["experience"]
	var service: UpgradeService = built["service"]
	var audio: GameAudio = built["audio"]

	assert_true(audio.has_complete_cue_set(), "PS-136: il set di cue deve risultare completo con BOSS_VICTORY integrato.")
	assert_not_null(
		audio.get_stream_for_cue(GameAudio.BOSS_VICTORY),
		"PS-136: il cue BOSS_VICTORY deve avere uno stream importato."
	)

	for occurrence in range(2):
		_advance_to_boss(controller, occurrence)
		assert_true(encounter.complete_intro(), "L'intro del Boss deve potersi chiudere (ricorrenza %d)." % occurrence)

		var cues_played: Array[StringName] = []
		audio.cue_played.connect(func(cue_id: StringName) -> void: cues_played.append(cue_id))
		_kill_active_boss(encounter, controller, experience, service)
		assert_true(
			GameAudio.BOSS_VICTORY in cues_played,
			"La sconfitta del Boss deve riprodurre BOSS_VICTORY (ricorrenza %d)." % occurrence
		)

	_teardown_fixture(built)


func test_boss_victory_cue_is_distinct_from_end_run_cues() -> void:
	var built := await _build_fixture(136002)
	if built.is_empty():
		return
	var controller: RunController = built["controller"]
	var encounter: BossEncounter = built["encounter"]
	var experience: ExperienceSystem = built["experience"]
	var service: UpgradeService = built["service"]
	var audio: GameAudio = built["audio"]

	_advance_to_boss(controller, 0)
	assert_true(encounter.complete_intro(), "L'intro del Boss deve potersi chiudere.")

	var cues_played: Array[StringName] = []
	audio.cue_played.connect(func(cue_id: StringName) -> void: cues_played.append(cue_id))
	_kill_active_boss(encounter, controller, experience, service)

	assert_true(GameAudio.BOSS_VICTORY in cues_played, "La sconfitta del Boss deve riprodurre BOSS_VICTORY.")
	assert_false(GameAudio.VICTORY in cues_played, "BOSS_VICTORY non deve riusare o duplicare il cue VICTORY di fine run.")
	assert_false(GameAudio.DEFEAT in cues_played, "BOSS_VICTORY non deve riusare o duplicare il cue DEFEAT di fine run.")

	_teardown_fixture(built)


func test_boss_victory_cue_respects_mute_and_zero_volume() -> void:
	var built := await _build_fixture(136003)
	if built.is_empty():
		return
	var controller: RunController = built["controller"]
	var encounter: BossEncounter = built["encounter"]
	var experience: ExperienceSystem = built["experience"]
	var service: UpgradeService = built["service"]
	var audio: GameAudio = built["audio"]

	var initial_volume := audio.get_effects_volume()
	var initial_muted := audio.is_muted()

	audio.set_muted(true, false)
	_advance_to_boss(controller, 0)
	assert_true(encounter.complete_intro(), "L'intro del Boss deve potersi chiudere anche con l'audio disattivato.")
	var cues_muted: Array[StringName] = []
	audio.cue_played.connect(func(cue_id: StringName) -> void: cues_muted.append(cue_id))
	_kill_active_boss(encounter, controller, experience, service)
	assert_true(cues_muted.is_empty(), "Con audio disattivato non deve essere udibile alcun cue alla sconfitta del Boss.")

	audio.set_muted(false, false)
	audio.set_effects_volume(initial_volume, false)
	_teardown_fixture(built)

	print("BOSS_VICTORY_FANFARE_SMOKE_OK")


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
		"PS-136 richiede RunController, BossEncounter, ExperienceSystem, UpgradeService e GameAudio dalla scena."
	)
	if controller == null or encounter == null or experience == null or service == null or audio == null:
		return {}

	if not controller.is_terminal():
		controller.request_defeat()
	assert_true(
		movement_slice.restart_run(seed_value), "La fixture PS-136 deve poter avviare la run con il seed richiesto."
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
