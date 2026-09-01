extends GutGameplayTest

## PS-053 — La schermata finale mostra un riepilogo della run (personaggio,
## livello, Boss sconfitti, tempo e fino a tre upgrade con rango più alto),
## non solo il terminale essenziale di prima. Guida un run reale (level-up e
## uccisione di un Boss) invece di costruire il RunSummary a mano, cosi' il
## test copre anche il collegamento reale in MovementSlice, non solo
## EndScreen in isolamento.


func test_run_summary_reflects_character_level_boss_and_top_upgrades() -> void:
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_run_controller() as RunController
	var director := movement_slice.get_game_director() as GameDirector
	var encounter := movement_slice.get_boss_encounter() as BossEncounter
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	var experience := movement_slice.get_experience_system() as ExperienceSystem
	var upgrade_service := movement_slice.get_upgrade_service() as UpgradeService
	var end_screen := movement_slice.get_end_screen() as EndScreen
	var player := movement_slice.get_player() as Player
	assert_true(
		controller != null and director != null and encounter != null and spawner != null
		and experience != null and upgrade_service != null and end_screen != null and player != null,
		"PS-053 richiede l'intero frontend di run."
	)
	if (
		controller == null or director == null or encounter == null or spawner == null
		or experience == null or upgrade_service == null or end_screen == null or player == null
	):
		return

	var friend := player.get_friend_definition()
	assert_true(friend != null, "L'auto-avvio dei test deve equipaggiare un personaggio.")
	if friend == null:
		return

	controller.set_process(false)
	spawner.set_process(false)

	# Alcuni level-up reali mentre la run e' RUNNING: quanti upgrade e quali
	# dipendono dal registry e dal seed fisso di test, non serve conoscerli in
	# anticipo per verificare il contratto del riepilogo (tetto a tre, ordine
	# per rango non crescente).
	# La curva reale richiede 10 XP per il primo livello e +5 per ognuno dei
	# successivi (ExperienceCurve): 200 XP bastano abbondantemente per piu' di
	# tre livelli, senza dover conoscere in anticipo la curva esatta.
	assert_true(experience.add_experience(200), "Servono livelli reali da tradurre in upgrade acquisiti.")
	var picked_any_upgrade := false
	while experience.pending_level_ups > 0:
		var offer_ids := upgrade_service.get_current_offer_ids()
		if offer_ids.is_empty():
			break
		if upgrade_service.select_upgrade(offer_ids[0]):
			picked_any_upgrade = true
	assert_true(picked_any_upgrade, "Il test deve poter acquisire almeno un upgrade.")

	# Un Boss sconfitto dopo i level-up: la ricompensa Barb che ne segue
	# sposta la run fuori da RUNNING, quindi deve succedere per ultimo. Come
	# in test_b16_complete_run.gd, request_defeat() chiude comunque la run
	# senza dover prima risolvere l'offerta Barb.
	var threshold := director.get_thresholds()[0]
	spawner.try_spawn_enemy()
	controller._process(maxf(threshold - controller.get_run_time(), 0.0) + 0.01)
	var boss := encounter.get_active_boss()
	assert_true(boss != null, "La soglia deve creare un Boss da sconfiggere.")
	if boss == null:
		return
	assert_true(encounter.complete_intro(), "L'intro del Boss deve poter essere confermata.")
	var boss_health := boss.get_health_component()
	assert_true(boss.take_damage(boss_health.health_current), "Il Boss deve morire per il riepilogo.")
	await wait_process_frames(2)

	var expected_level := experience.level
	assert_true(controller.request_defeat(), "Il riepilogo va letto da un terminale reale.")
	assert_true(end_screen.visible, "DEFEAT deve mostrare il terminale.")

	assert_eq(
		end_screen.get_character_name_text(), friend.get_public_display_name(),
		"Il riepilogo deve mostrare il nome del personaggio della run."
	)
	assert_true(
		end_screen.get_character_portrait_texture() != null,
		"Il riepilogo deve mostrare il ritratto del personaggio della run."
	)
	var stats_text := end_screen.get_stats_text()
	assert_true(
		stats_text.contains("Livello %d" % expected_level), "Il riepilogo deve mostrare il livello raggiunto."
	)
	assert_true(stats_text.contains("1 Boss sconfitto"), "Il riepilogo deve contare il Boss appena sconfitto.")
	assert_true(
		end_screen.get_summary_text().contains(EndScreen.format_run_time(controller.get_run_time())),
		"Il tempo mostrato deve coincidere con lo snapshot passato al terminale."
	)

	var chip_count := end_screen.get_upgrade_chip_count()
	assert_true(
		chip_count >= 1 and chip_count <= 3, "Il riepilogo mostra fino a tre upgrade, mai zero se qualcuno e' stato scelto."
	)
	var ranks := _extract_ranks(end_screen.get_upgrade_chip_summaries())
	assert_eq(ranks.size(), chip_count, "Ogni chip deve dichiarare un rango leggibile.")
	for index in range(1, ranks.size()):
		assert_true(
			ranks[index] <= ranks[index - 1],
			"Gli upgrade devono comparire in ordine di rango non crescente."
		)

	print("RUN_SUMMARY_SMOKE_OK")


func test_run_summary_shows_fewer_than_three_without_placeholders() -> void:
	var movement_slice := await instantiate_movement_slice()
	var controller := movement_slice.get_run_controller() as RunController
	var experience := movement_slice.get_experience_system() as ExperienceSystem
	var upgrade_service := movement_slice.get_upgrade_service() as UpgradeService
	var end_screen := movement_slice.get_end_screen() as EndScreen
	assert_true(
		controller != null and experience != null and upgrade_service != null and end_screen != null,
		"PS-053 richiede l'intero frontend di run."
	)
	if controller == null or experience == null or upgrade_service == null or end_screen == null:
		return

	controller.set_process(false)
	# Esattamente il fabbisogno del primo livello (ExperienceCurve:
	# base_experience_required = 10): un solo level-up, senza resto.
	assert_true(experience.add_experience(10), "Serve un solo livello per la carta di scelta.")
	var offer_ids := upgrade_service.get_current_offer_ids()
	assert_true(not offer_ids.is_empty(), "Il primo livello deve produrre un'offerta.")
	if offer_ids.is_empty():
		return
	assert_true(upgrade_service.select_upgrade(offer_ids[0]), "La scelta unica deve poter essere acquisita.")

	assert_true(controller.request_defeat(), "Il riepilogo va letto da un terminale reale.")
	assert_eq(
		end_screen.get_upgrade_chip_count(), 1,
		"Con un solo upgrade posseduto il riepilogo non deve avere slot vuoti o segnaposto."
	)


func test_run_summary_also_works_for_victory() -> void:
	var movement_slice := await instantiate_movement_slice()
	var controller := movement_slice.get_run_controller() as RunController
	var end_screen := movement_slice.get_end_screen() as EndScreen
	var player := movement_slice.get_player() as Player
	assert_true(
		controller != null and end_screen != null and player != null, "PS-053 richiede l'intero frontend di run."
	)
	if controller == null or end_screen == null or player == null:
		return

	controller.set_process(false)
	assert_true(controller.request_victory(), "Il riepilogo deve funzionare anche per VICTORY.")
	assert_true(end_screen.visible, "VICTORY deve mostrare il terminale.")
	assert_eq(end_screen.get_title_text(), "VITTORIA", "VICTORY deve mostrare il titolo di vittoria.")
	assert_eq(
		end_screen.get_character_name_text(), player.get_friend_definition().get_public_display_name(),
		"Il riepilogo di vittoria deve mostrare comunque il personaggio della run."
	)
	assert_true(
		end_screen.get_stats_text().contains("Livello"),
		"Il riepilogo di vittoria deve mostrare comunque livello e Boss sconfitti."
	)


func _extract_ranks(summaries: Array[String]) -> Array[int]:
	var ranks: Array[int] = []
	var regex := RegEx.new()
	regex.compile("Rango (\\d+)")
	for summary in summaries:
		var result := regex.search(summary)
		if result == null:
			continue
		ranks.append(int(result.get_string(1)))
	return ranks
