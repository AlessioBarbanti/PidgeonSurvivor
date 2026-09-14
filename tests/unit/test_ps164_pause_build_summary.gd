extends GutGameplayTest

## PS-164 — Il pannello pausa mostra un riepilogo read-only della build della
## run corrente: upgrade ordinari acquisiti (nome + rango) e Specialità di
## Barb effettivamente sbloccate, distinguibili dagli ordinari e aggiornate
## alla successiva apertura senza restart. Guida un run reale (level-up e
## sblocco Specialità tramite `UpgradeService`) invece di costruire le righe
## a mano, cosi' il test copre anche il cablaggio reale in `movement_slice.gd`.


func test_ps164_pause_shows_ordinary_upgrade_and_distinguishes_unlocked_speciality() -> void:
	var movement_slice := await instantiate_movement_slice()
	var controller := movement_slice.get_run_controller() as RunController
	var experience := movement_slice.get_experience_system() as ExperienceSystem
	var upgrade_service := movement_slice.get_upgrade_service() as UpgradeService
	var overlay := movement_slice.get_pause_overlay() as PauseOverlay
	assert_true(
		controller != null and experience != null and upgrade_service != null and overlay != null,
		"PS-164 richiede RunController/ExperienceSystem/UpgradeService/PauseOverlay dalla scena."
	)
	if controller == null or experience == null or upgrade_service == null or overlay == null:
		return

	controller.set_process(false)

	# Un solo level-up reale (ExperienceCurve: 10 XP bastano per il primo,
	# senza resto), come in test_ps053_run_summary.gd.
	assert_true(experience.add_experience(experience.get_experience_required()), "Serve un level-up reale.")
	var ordinary_offer := upgrade_service.get_current_offer()
	assert_true(not ordinary_offer.is_empty(), "Il primo livello deve produrre un'offerta.")
	if ordinary_offer.is_empty():
		return
	var ordinary_definition := ordinary_offer[0]
	assert_true(
		upgrade_service.select_upgrade(ordinary_definition.id), "La scelta unica deve poter essere acquisita."
	)

	# Sblocco reale di una Specialità di Barb (stesso percorso di
	# tools/_capture_ui_screenshots.gd): con tutte le Specialità ancora
	# bloccate, queue_barb_reward() apre la modalità SPECIALITY.
	assert_true(upgrade_service.get_locked_speciality_definitions().size() == 8, "Run fresca: 8 Specialità bloccate.")
	upgrade_service.queue_barb_reward()
	await wait_process_frames(1)
	assert_eq(
		controller.get_state(), RunController.RunState.BARB_REWARD, "queue_barb_reward deve aprire la ricompensa."
	)
	var speciality_offer := upgrade_service.get_current_barb_offer()
	assert_true(not speciality_offer.is_empty(), "La ricompensa Barb deve offrire almeno una Specialità.")
	if speciality_offer.is_empty():
		return
	var speciality_definition := speciality_offer[0]
	assert_true(
		upgrade_service.select_barb_speciality(speciality_definition.id), "La Specialità offerta deve sbloccarsi."
	)
	await wait_process_frames(1)
	assert_eq(
		controller.get_state(), RunController.RunState.RUNNING, "Sbloccare la Specialità deve tornare a RUNNING."
	)

	assert_true(controller.request_manual_pause(), "PS-164 richiede di poter aprire la pausa manuale.")
	await wait_process_frames(1)

	assert_true(overlay.is_build_summary_visible(), "Con upgrade posseduti il riepilogo build deve essere visibile.")
	assert_eq(
		overlay.get_build_summary_row_count(), 2, "Il riepilogo deve mostrare l'upgrade ordinario e la Specialità."
	)

	var ordinary_index := _find_row_by_title(overlay, ordinary_definition.title)
	var speciality_index := _find_row_by_title(overlay, speciality_definition.title)
	assert_true(ordinary_index != -1, "L'upgrade ordinario scelto deve comparire nel riepilogo.")
	assert_true(speciality_index != -1, "La Specialità sbloccata deve comparire nel riepilogo.")
	if ordinary_index == -1 or speciality_index == -1:
		return

	assert_eq(
		overlay.get_build_summary_row_rank_text(ordinary_index), "Rango 1", "L'upgrade ordinario deve mostrare il rango effettivo."
	)
	assert_eq(
		overlay.get_build_summary_row_rank_text(speciality_index), "Rango 1", "La Specialità sbloccata parte da rango 1."
	)
	assert_eq(
		overlay.get_build_summary_row_title_color(ordinary_index), PauseOverlay.BUILD_SUMMARY_TITLE_COLOR,
		"Un upgrade ordinario non deve usare l'oro riservato alle Specialità."
	)
	assert_eq(
		overlay.get_build_summary_row_title_color(speciality_index), PauseOverlay.BUILD_SUMMARY_SPECIALITY_TITLE_COLOR,
		"Una Specialità sbloccata deve distinguersi con l'oro del pannello."
	)

	# Le sette Specialità ancora bloccate non devono comparire.
	for locked_definition in upgrade_service.get_locked_speciality_definitions():
		assert_eq(
			_find_row_by_title(overlay, locked_definition.title), -1,
			"Una Specialità ancora bloccata non deve comparire nel riepilogo."
		)

	controller.request_defeat()
	print("PS164_PAUSE_BUILD_SUMMARY_SMOKE_OK")


func test_ps164_pause_summary_updates_on_next_open_without_restart() -> void:
	var movement_slice := await instantiate_movement_slice()
	var controller := movement_slice.get_run_controller() as RunController
	var experience := movement_slice.get_experience_system() as ExperienceSystem
	var upgrade_service := movement_slice.get_upgrade_service() as UpgradeService
	var overlay := movement_slice.get_pause_overlay() as PauseOverlay
	assert_true(
		controller != null and experience != null and upgrade_service != null and overlay != null,
		"PS-164 richiede RunController/ExperienceSystem/UpgradeService/PauseOverlay dalla scena."
	)
	if controller == null or experience == null or upgrade_service == null or overlay == null:
		return

	controller.set_process(false)

	assert_true(controller.request_manual_pause(), "PS-164 richiede di poter aprire la pausa manuale.")
	await wait_process_frames(1)
	assert_false(
		overlay.is_build_summary_visible(), "Senza upgrade il riepilogo non deve mostrare un'intestazione vuota."
	)
	assert_eq(overlay.get_build_summary_row_count(), 0, "Senza upgrade il riepilogo non deve avere righe.")

	assert_true(controller.resume_run(), "RIPRENDI deve funzionare prima del level-up.")
	await wait_process_frames(1)

	assert_true(experience.add_experience(experience.get_experience_required()), "Serve un level-up reale.")
	var offer := upgrade_service.get_current_offer()
	assert_true(not offer.is_empty(), "Il primo livello deve produrre un'offerta.")
	if offer.is_empty():
		return
	var chosen_definition := offer[0]
	assert_true(upgrade_service.select_upgrade(chosen_definition.id), "La scelta unica deve poter essere acquisita.")

	assert_true(controller.request_manual_pause(), "La pausa deve poter riaprirsi dopo il level-up.")
	await wait_process_frames(1)
	assert_true(
		overlay.is_build_summary_visible(), "L'upgrade appena scelto deve comparire alla successiva apertura."
	)
	assert_eq(overlay.get_build_summary_row_count(), 1, "Deve comparire esattamente l'upgrade appena scelto.")
	assert_eq(
		overlay.get_build_summary_row_title_text(0), chosen_definition.title,
		"La riga deve riportare il titolo dell'upgrade appena scelto, senza restart o refresh manuale."
	)

	controller.request_defeat()


func test_ps164_pause_summary_clears_on_restart() -> void:
	var movement_slice := await instantiate_movement_slice()
	var controller := movement_slice.get_run_controller() as RunController
	var experience := movement_slice.get_experience_system() as ExperienceSystem
	var upgrade_service := movement_slice.get_upgrade_service() as UpgradeService
	var overlay := movement_slice.get_pause_overlay() as PauseOverlay
	assert_true(
		controller != null and experience != null and upgrade_service != null and overlay != null,
		"PS-164 richiede RunController/ExperienceSystem/UpgradeService/PauseOverlay dalla scena."
	)
	if controller == null or experience == null or upgrade_service == null or overlay == null:
		return

	controller.set_process(false)

	assert_true(experience.add_experience(experience.get_experience_required()), "Serve un level-up reale.")
	var offer := upgrade_service.get_current_offer()
	assert_true(not offer.is_empty(), "Il primo livello deve produrre un'offerta.")
	if offer.is_empty():
		return
	assert_true(upgrade_service.select_upgrade(offer[0].id), "La scelta unica deve poter essere acquisita.")

	assert_true(controller.request_manual_pause(), "PS-164 richiede di poter aprire la pausa manuale.")
	await wait_process_frames(1)
	assert_eq(
		overlay.get_build_summary_row_count(), 1, "Prima del restart il riepilogo deve mostrare l'upgrade scelto."
	)
	assert_true(controller.resume_run(), "RIPRENDI deve funzionare prima del restart.")
	await wait_process_frames(1)

	assert_true(controller.request_defeat(), "Il restart reale parte da un terminale.")
	assert_true(controller.restart_run(4242), "restart_run deve avviare una nuova run dal terminale.")
	await wait_process_frames(2)
	assert_true(upgrade_service.get_ranks().is_empty(), "La nuova run non deve ereditare ranghi.")

	assert_true(controller.request_manual_pause(), "La pausa deve poter riaprirsi dopo il restart.")
	await wait_process_frames(1)
	assert_false(
		overlay.is_build_summary_visible(), "Dopo il restart il riepilogo non deve ereditare la build precedente."
	)
	assert_eq(overlay.get_build_summary_row_count(), 0, "Dopo il restart il riepilogo deve azzerarsi completamente.")

	controller.request_defeat()


func _find_row_by_title(overlay: PauseOverlay, title: String) -> int:
	for index in overlay.get_build_summary_row_count():
		if overlay.get_build_summary_row_title_text(index) == title:
			return index
	return -1
