extends GutGameplayTest


func test_baseline_title_resource() -> void:
	var definition := load("res://data/bosses/first_boss.tres") as BossDefinition
	assert_true(definition != null, "PS-026 richiede la risorsa del Boss baseline.")
	if definition == null:
		return
	assert_eq(definition.id, &"special_pigeon", "PS-026 non deve rinominare l'ID tecnico del Boss baseline.")
	assert_eq(
		definition.get_safe_title(), "PICCIONE MALVAGIO",
		"Il nome pubblico del Boss baseline deve essere Piccione Malvagio."
	)


func test_boss_intro_and_evil_variants() -> void:
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_run_controller() as RunController
	var encounter := movement_slice.get_boss_encounter() as BossEncounter
	var boss_ui := movement_slice.get_boss_ui() as BossUI
	assert_true(controller != null and encounter != null and boss_ui != null, "PS-026 richiede le dipendenze Boss della scena.")
	if controller == null or encounter == null or boss_ui == null:
		return

	controller.set_process(false)

	encounter.evil_boss_chance = 0.0
	controller._process(120.01)
	assert_eq(
		boss_ui.get_intro_title_text(), "PICCIONE MALVAGIO",
		"La Boss Intro deve mostrare Piccione Malvagio per il Boss baseline."
	)
	assert_true(encounter.complete_intro(), "L'intro del Boss baseline deve poter terminare.")
	assert_true(controller.request_defeat(), "Il test deve poter chiudere la run per il restart.")
	assert_true(movement_slice.restart_run(26001), "PS-026 deve poter avviare una seconda run.")
	await wait_process_frames(2)
	controller.set_process(false)

	encounter.evil_boss_chance = 1.0
	controller._process(120.01)
	var evil_title := boss_ui.get_intro_title_text()
	assert_true(
		evil_title != "PICCIONE MALVAGIO" and evil_title.begins_with("EVIL "),
		"Le varianti Evil devono conservare il proprio nome, non quello del Boss baseline."
	)

	controller.prepare_restart()
