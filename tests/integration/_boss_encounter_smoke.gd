extends SceneTree

const MOVEMENT_SLICE_SCENE := preload("res://scenes/game/movement_slice.tscn")
const INITIAL_VIEWPORT_SIZE := Vector2i(1280, 720)
const FLOAT_TOLERANCE := 0.001

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	paused = false
	root.content_scale_size = INITIAL_VIEWPORT_SIZE
	root.size = INITIAL_VIEWPORT_SIZE
	await _wait_processed_frame()

	_validate_boss_definition()
	await _validate_composed_encounter()
	await _finish()


func _validate_boss_definition() -> void:
	var definition := BossDefinition.new()
	_expect(definition.is_valid(), "La definizione Boss di default deve essere valida.")
	_expect(
		definition.get_safe_quote() == definition.safe_quote_placeholder,
		"Una citazione non approvata deve risolversi nel placeholder sicuro."
	)
	definition.quote_approved = true
	definition.quote = "Citazione approvata"
	_expect(
		definition.get_safe_quote() == "Citazione approvata",
		"Una citazione approvata deve poter essere mostrata."
	)
	definition.radial_projectile_count = 3
	_expect(not definition.is_valid(), "Il pattern radiale deve richiedere almeno quattro direzioni.")

	var bounds := Rect2(Vector2(20.0, 20.0), Vector2(1240.0, 680.0))
	var spawn := BossEncounter.calculate_spawn_position(
		bounds,
		bounds.position,
		46.0
	)
	_expect(spawn.is_finite(), "Lo spawn Boss deve essere finito con un playfield valido.")
	_expect(
		bounds.has_point(spawn),
		"Lo spawn Boss deve restare dentro il playfield logico."
	)


func _validate_composed_encounter() -> void:
	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	root.add_child(movement_slice)
	await _wait_processed_frame()

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
	_expect(controller != null, "La scena B15 deve esporre RunController.")
	_expect(director != null, "La scena B15 deve esporre GameDirector.")
	_expect(encounter != null, "La scena B15 deve esporre BossEncounter.")
	_expect(boss_ui != null, "La scena B15 deve esporre BossUI.")
	_expect(player != null, "La scena B15 deve conservare il Player.")
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
		paused = false
		movement_slice.queue_free()
		await process_frame
		return

	controller.set_process(false)
	spawner.set_process(false)
	var definition := encounter.boss_definition
	_expect(definition != null and definition.is_valid(), "Il profilo Boss composto deve essere valido.")
	controller._process(240.01)
	var boss := encounter.get_active_boss()
	_expect(
		controller.get_state() == RunController.RunState.BOSS_INTRO and paused,
		"La soglia deve aprire BOSS_INTRO e fermare il gameplay."
	)
	_expect(boss != null, "BOSS_INTRO deve creare il primo Boss.")
	if boss == null:
		controller.prepare_restart()
		paused = false
		movement_slice.queue_free()
		await process_frame
		return

	_expect(director.get_active_boss() == boss, "Il Director deve tracciare il Boss creato.")
	_expect(targeting.has_target(boss), "Il Boss deve essere un bersaglio vivo dell'arma.")
	_expect(boss_ui.get_boss() == boss, "La barra Boss deve osservare l'istanza attiva.")
	_expect(boss_ui.is_intro_visible(), "La citazione deve apparire durante BOSS_INTRO.")
	_expect(boss_ui.is_boss_health_visible(), "Gli HP Boss devono essere visibili dall'introduzione.")
	_expect(
		definition.quote not in boss_ui.get_intro_quote_text()
		and definition.get_safe_quote() in boss_ui.get_intro_quote_text(),
		"La UI non deve mostrare una citazione non approvata."
	)
	_expect_rect_inside(
		boss_ui.get_intro_panel_rect(),
		arena_layout.get_safe_area_rect(),
		"Il pannello intro Boss deve restare nella safe area."
	)
	_expect_rect_inside(
		boss_ui.get_boss_health_panel_rect(),
		arena_layout.get_safe_area_rect(),
		"La barra HP Boss deve restare nella safe area."
	)
	var boss_health := boss.get_health_component()
	_expect_float_near(
		boss_health.health_max,
		definition.health_max,
		"Gli HP Boss devono provenire dal Resource."
	)

	var intro_cooldown := boss.get_attack_cooldown_remaining()
	boss._physics_process(definition.initial_attack_delay + 1.0)
	_expect(
		boss.get_active_pattern_id().is_empty(),
		"BOSS_INTRO non deve avviare un pattern."
	)
	_expect_float_near(
		boss.get_attack_cooldown_remaining(),
		intro_cooldown,
		"BOSS_INTRO non deve consumare il cooldown dei pattern."
	)

	_expect(encounter.complete_intro(), "AFFRONTA deve chiudere l'introduzione.")
	_expect(controller.is_running() and not paused, "Dopo l'intro la run deve riprendere.")

	var ordinary_enemy := spawner.try_spawn_enemy()
	_expect(ordinary_enemy != null, "Il Boss deve poter convivere con un nemico base.")
	_expect(targeting.get_registered_count() == 2, "Targeting deve contenere Boss e nemico base.")

	boss._physics_process(definition.initial_attack_delay + 0.01)
	_expect(
		boss.get_active_pattern_id() == FirstBoss.RADIAL_VOLLEY
		and boss.is_telegraph_active(),
		"Il primo pattern deve telegrafare la raffica radiale."
	)
	var radial_remaining := boss.get_telegraph_remaining()
	_expect(controller.request_manual_pause(), "Il test deve poter pausare durante il telegraph.")
	boss._physics_process(radial_remaining + 1.0)
	_expect_float_near(
		boss.get_telegraph_remaining(),
		radial_remaining,
		"La pausa non deve consumare il telegraph radiale."
	)
	_expect(controller.resume_run(), "Il test deve poter riprendere il telegraph.")
	boss._physics_process(radial_remaining + 0.01)
	_expect(boss.get_radial_volley_count() == 1, "La raffica radiale deve essere eseguita una volta.")
	_expect(
		boss.get_active_projectile_count() == definition.radial_projectile_count,
		"La raffica deve creare il numero di proiettili dichiarato dai dati."
	)

	boss._physics_process(definition.pattern_interval + 0.01)
	_expect(
		boss.get_active_pattern_id() == FirstBoss.TARGETED_BLAST
		and boss.is_telegraph_active(),
		"Il secondo pattern deve telegrafare l'area mirata."
	)
	player.global_position = boss.get_targeted_position()
	player.get_health_component().clear_invulnerability()
	var health_before_blast := player.get_health_component().health_current
	boss._physics_process(definition.targeted_telegraph_duration + 0.01)
	_expect(boss.get_targeted_blast_count() == 1, "L'area mirata deve essere eseguita una volta.")
	_expect(
		player.get_health_component().health_current < health_before_blast,
		"Restare nell'area telegrafata deve infliggere danno al Player."
	)

	var health_before_hit := boss_health.health_current
	_expect(boss.take_damage(100.0), "Il Boss deve ricevere danno dai sistemi condivisi.")
	_expect_float_near(
		boss_ui.get_boss_health_value(),
		health_before_hit - 100.0,
		"La barra HP Boss deve aggiornarsi via segnale."
	)
	_expect(
		boss.take_damage(boss_health.health_current),
		"Il danno letale deve concludere il Boss una sola volta."
	)
	_expect(
		controller.get_state() == RunController.RunState.VICTORY and paused,
		"La morte del Boss deve chiudere la run in VICTORY."
	)
	_expect(
		experience.experience_total == definition.experience_reward,
		"La morte del Boss deve assegnare la ricompensa XP una sola volta."
	)
	_expect(end_screen.visible, "La vittoria deve mostrare EndScreen.")
	_expect(end_screen.get_title_text() == "VITTORIA", "EndScreen deve distinguere la vittoria.")
	_expect(
		"+%d XP" % definition.experience_reward in end_screen.get_summary_text(),
		"Il riepilogo vittoria deve mostrare la ricompensa."
	)

	await _wait_processed_frame()
	_expect(encounter.get_active_boss() == null, "Il Boss morto non deve restare attivo.")
	_expect(not director.has_blocking_boss_event(), "La morte deve rilasciare il lock del Director.")
	_expect(
		movement_slice.get_boss_projectile_parent().get_child_count() == 0,
		"La morte del Boss deve rimuovere i suoi proiettili."
	)
	_expect(targeting.get_registered_count() == 1, "Il nemico base deve restare registrato fino al restart.")

	_expect(movement_slice.restart_run(15002), "La vittoria deve consentire una nuova run.")
	await _wait_processed_frame()
	_expect(controller.is_running() and not paused, "Il restart da VICTORY deve tornare in RUNNING.")
	_expect(experience.experience_total == 0, "Il restart deve azzerare la ricompensa XP.")
	_expect(spawner.get_alive_count() == 0, "Il restart deve eliminare i nemici della run precedente.")
	_expect(targeting.get_registered_count() == 0, "Il restart deve svuotare il targeting.")
	_expect(not boss_ui.is_intro_visible(), "Il restart deve chiudere l'intro Boss.")
	_expect(not boss_ui.is_boss_health_visible(), "Il restart deve nascondere gli HP Boss.")

	controller.prepare_restart()
	paused = false
	movement_slice.queue_free()
	await process_frame


func _expect_rect_inside(inner: Rect2, outer: Rect2, message: String) -> void:
	_expect(
		inner.has_area()
		and outer.has_area()
		and inner.position.x >= outer.position.x - FLOAT_TOLERANCE
		and inner.position.y >= outer.position.y - FLOAT_TOLERANCE
		and inner.end.x <= outer.end.x + FLOAT_TOLERANCE
		and inner.end.y <= outer.end.y + FLOAT_TOLERANCE,
		"%s Interno %s, esterno %s." % [message, inner, outer]
	)


func _expect_float_near(actual: float, expected: float, message: String) -> void:
	_expect(
		absf(actual - expected) <= FLOAT_TOLERANCE,
		"%s Atteso %.5f, ottenuto %.5f." % [message, expected, actual]
	)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _wait_processed_frame() -> void:
	await process_frame
	await process_frame


func _finish() -> void:
	paused = false
	await process_frame
	if _failures.is_empty():
		print("B15_BOSS_ENCOUNTER_SMOKE_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	printerr("B15_BOSS_ENCOUNTER_SMOKE_FAIL count=%d" % _failures.size())
	quit(1)
