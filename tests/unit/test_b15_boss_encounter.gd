extends GutGameplayTest

func test_boss_definition() -> void:
	var definition := BossDefinition.new()
	assert_true(definition.is_valid(), "La definizione Boss di default deve essere valida.")
	assert_true(
		definition.get_safe_quote() == definition.safe_quote_placeholder,
		"Una citazione non approvata deve risolversi nel placeholder sicuro."
	)
	definition.quote_approved = true
	definition.quote = "Citazione approvata"
	assert_true(definition.get_safe_quote() == "Citazione approvata", "Una citazione approvata deve poter essere mostrata.")
	definition.radial_projectile_count = 3
	assert_true(not definition.is_valid(), "Il pattern radiale deve richiedere almeno quattro direzioni.")

	var bounds := Rect2(Vector2(20.0, 20.0), Vector2(1240.0, 680.0))
	var spawn := BossEncounter.calculate_spawn_position(bounds, bounds.position, 46.0)
	assert_true(spawn.is_finite(), "Lo spawn Boss deve essere finito con un playfield valido.")
	assert_true(bounds.has_point(spawn), "Lo spawn Boss deve restare dentro il playfield logico.")


func test_composed_encounter() -> void:
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_run_controller() as RunController
	var director := movement_slice.get_game_director() as GameDirector
	var encounter := movement_slice.get_boss_encounter() as BossEncounter
	var boss_ui := movement_slice.get_boss_ui() as BossUI
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	var targeting := movement_slice.get_targeting_system() as TargetingSystem
	var experience := movement_slice.get_experience_system() as ExperienceSystem
	var player := movement_slice.get_node_or_null("World/Player") as Player
	var arena_layout := movement_slice.get_node_or_null("ArenaLayout") as ArenaLayout
	var end_screen := movement_slice.get_end_screen() as EndScreen
	assert_true(controller != null, "La scena B15 deve esporre RunController.")
	assert_true(director != null, "La scena B15 deve esporre GameDirector.")
	assert_true(encounter != null, "La scena B15 deve esporre BossEncounter.")
	assert_true(boss_ui != null, "La scena B15 deve esporre BossUI.")
	assert_true(player != null, "La scena B15 deve conservare il Player.")
	if (
		controller == null
		or director == null
		or encounter == null
		or boss_ui == null
		or spawner == null
		or targeting == null
		or experience == null
		or player == null
		or arena_layout == null
		or end_screen == null
	):
		return

	controller.set_process(false)
	spawner.set_process(false)
	var definition := encounter.boss_definition
	assert_true(definition != null and definition.is_valid(), "Il profilo Boss composto deve essere valido.")
	controller._process(240.01)
	var boss := encounter.get_active_boss()
	assert_true(
		controller.get_state() == RunController.RunState.BOSS_INTRO and get_tree().paused,
		"La soglia deve aprire BOSS_INTRO e fermare il gameplay."
	)
	assert_true(boss != null, "BOSS_INTRO deve creare il primo Boss.")
	if boss == null:
		controller.prepare_restart()
		return

	assert_true(director.get_active_boss() == boss, "Il Director deve tracciare il Boss creato.")
	assert_true(targeting.has_target(boss), "Il Boss deve essere un bersaglio vivo dell'arma.")
	assert_true(boss_ui.get_boss() == boss, "La barra Boss deve osservare l'istanza attiva.")
	assert_true(boss_ui.is_intro_visible(), "La citazione deve apparire durante BOSS_INTRO.")
	assert_true(boss_ui.is_boss_health_visible(), "Gli HP Boss devono essere visibili dall'introduzione.")
	var continue_button := boss_ui.get_node_or_null("IntroLayer/Center/IntroPanel/VBox/ContinueButton") as Button
	var continue_style := continue_button.get_theme_stylebox("normal") as StyleBoxTexture if continue_button != null else null
	assert_true(
		continue_style != null
		and continue_style.texture != null
		and FileAccess.file_exists("res://assets/art/ui/boss/boss_continue_cta_base.png"),
		"AFFRONTA deve usare la plancia Boss pixel-art dedicata."
	)
	assert_true(
		definition.quote not in boss_ui.get_intro_quote_text() and definition.get_safe_quote() in boss_ui.get_intro_quote_text(),
		"La UI non deve mostrare una citazione non approvata."
	)
	assert_rect_inside(
		boss_ui.get_intro_panel_rect(), arena_layout.get_safe_area_rect(), "Il pannello intro Boss deve restare nella safe area."
	)
	assert_rect_inside(
		boss_ui.get_boss_health_panel_rect(), arena_layout.get_safe_area_rect(), "La barra HP Boss deve restare nella safe area."
	)
	var boss_health := boss.get_health_component()
	assert_almost_eq(boss_health.health_max, definition.health_max, FLOAT_TOLERANCE, "Gli HP Boss devono provenire dal Resource.")

	var intro_cooldown := boss.get_attack_cooldown_remaining()
	boss._physics_process(definition.initial_attack_delay + 1.0)
	assert_true(boss.get_active_pattern_id().is_empty(), "BOSS_INTRO non deve avviare un pattern.")
	assert_almost_eq(
		boss.get_attack_cooldown_remaining(), intro_cooldown, FLOAT_TOLERANCE, "BOSS_INTRO non deve consumare il cooldown dei pattern."
	)

	assert_true(encounter.complete_intro(), "AFFRONTA deve chiudere l'introduzione.")
	assert_true(controller.is_running() and not get_tree().paused, "Dopo l'intro la run deve riprendere.")

	var ordinary_enemy := spawner.try_spawn_enemy()
	assert_true(ordinary_enemy != null, "Il Boss deve poter convivere con un nemico base.")
	assert_eq(targeting.get_registered_count(), 2, "Targeting deve contenere Boss e nemico base.")

	boss._physics_process(definition.initial_attack_delay + 0.01)
	assert_true(
		boss.get_active_pattern_id() == FirstBoss.RADIAL_VOLLEY and boss.is_telegraph_active(),
		"Il primo pattern deve telegrafare la raffica radiale."
	)
	var radial_remaining := boss.get_telegraph_remaining()
	assert_true(controller.request_manual_pause(), "Il test deve poter pausare durante il telegraph.")
	boss._physics_process(radial_remaining + 1.0)
	assert_almost_eq(
		boss.get_telegraph_remaining(), radial_remaining, FLOAT_TOLERANCE, "La pausa non deve consumare il telegraph radiale."
	)
	assert_true(controller.resume_run(), "Il test deve poter riprendere il telegraph.")
	boss._physics_process(radial_remaining + 0.01)
	assert_eq(boss.get_radial_volley_count(), 1, "La raffica radiale deve essere eseguita una volta.")
	assert_eq(
		boss.get_active_projectile_count(), definition.radial_projectile_count,
		"La raffica deve creare il numero di proiettili dichiarato dai dati."
	)

	boss._physics_process(definition.pattern_interval + 0.01)
	assert_true(
		boss.get_active_pattern_id() == FirstBoss.TARGETED_BLAST and boss.is_telegraph_active(),
		"Il secondo pattern deve telegrafare l'area mirata."
	)
	player.global_position = boss.get_targeted_position()
	player.get_health_component().clear_invulnerability()
	var health_before_blast := player.get_health_component().health_current
	boss._physics_process(definition.targeted_telegraph_duration + 0.01)
	assert_eq(boss.get_targeted_blast_count(), 1, "L'area mirata deve essere eseguita una volta.")
	assert_true(
		player.get_health_component().health_current < health_before_blast, "Restare nell'area telegrafata deve infliggere danno al Player."
	)

	var health_before_hit := boss_health.health_current
	assert_true(boss.take_damage(100.0), "Il Boss deve ricevere danno dai sistemi condivisi.")
	assert_almost_eq(
		boss_ui.get_boss_health_value(), health_before_hit - 100.0, FLOAT_TOLERANCE, "La barra HP Boss deve aggiornarsi via segnale."
	)
	assert_true(boss.take_damage(boss_health.health_current), "Il danno letale deve concludere il Boss una sola volta.")
	assert_true(not controller.is_terminal(), "La morte del primo Boss non deve piu' chiudere la run (B33).")
	assert_true(
		experience.experience_total == definition.experience_reward, "La morte del Boss deve assegnare la ricompensa XP una sola volta."
	)
	assert_true(not end_screen.visible, "La morte del Boss non deve mostrare EndScreen (B33).")

	await wait_process_frames(1)
	assert_true(encounter.get_active_boss() == null, "Il Boss morto non deve restare attivo.")
	assert_true(not director.has_blocking_boss_event(), "La morte deve rilasciare il lock del Director.")
	assert_eq(
		movement_slice.get_boss_projectile_parent().get_child_count(), 0, "La morte del Boss deve rimuovere i suoi proiettili."
	)
	assert_eq(targeting.get_registered_count(), 1, "Il nemico base deve restare registrato fino al restart.")

	assert_true(controller.request_defeat(), "Il test deve poter chiudere la run in DEFEAT per il restart.")
	assert_true(
		controller.get_state() == RunController.RunState.DEFEAT and get_tree().paused, "DEFEAT deve fermare il gameplay."
	)
	assert_true(end_screen.visible, "DEFEAT deve mostrare EndScreen.")
	assert_eq(end_screen.get_title_text(), "GAME OVER", "EndScreen deve distinguere la sconfitta.")

	assert_true(movement_slice.restart_run(15002), "DEFEAT deve consentire una nuova run.")
	await wait_process_frames(2)
	assert_true(controller.is_running() and not get_tree().paused, "Il restart da DEFEAT deve tornare in RUNNING.")
	assert_eq(experience.experience_total, 0, "Il restart deve azzerare la ricompensa XP.")
	assert_eq(spawner.get_alive_count(), 0, "Il restart deve eliminare i nemici della run precedente.")
	assert_eq(targeting.get_registered_count(), 0, "Il restart deve svuotare il targeting.")
	assert_true(not boss_ui.is_intro_visible(), "Il restart deve chiudere l'intro Boss.")
	assert_true(not boss_ui.is_boss_health_visible(), "Il restart deve nascondere gli HP Boss.")

	controller.prepare_restart()
