extends GutGameplayTest

const RUN_COUNT := 5


func test_five_complete_runs() -> void:
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_run_controller() as RunController
	var director := movement_slice.get_game_director() as GameDirector
	var encounter := movement_slice.get_boss_encounter() as BossEncounter
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	var targeting := movement_slice.get_targeting_system() as TargetingSystem
	var experience := movement_slice.get_experience_system() as ExperienceSystem
	var upgrade_service := movement_slice.get_upgrade_service() as UpgradeService
	var upgrade_overlay := movement_slice.get_upgrade_overlay() as UpgradeOverlay
	var ability_controller := movement_slice.get_ability_controller() as AbilityController
	var ability_registry := movement_slice.get_ability_effect_registry() as AbilityEffectRegistry
	var weapon_controller := movement_slice.get_weapon_controller() as WeaponController
	var boss_ui := movement_slice.get_boss_ui() as BossUI
	var end_screen := movement_slice.get_end_screen() as EndScreen
	assert_not_null(controller, "B16 richiede RunController.")
	assert_not_null(encounter, "B16 richiede BossEncounter.")
	if (
		controller == null
		or director == null
		or encounter == null
		or spawner == null
		or targeting == null
		or experience == null
		or upgrade_service == null
		or upgrade_overlay == null
		or ability_controller == null
		or ability_registry == null
		or weapon_controller == null
		or boss_ui == null
		or end_screen == null
	):
		return

	controller.set_process(false)
	spawner.set_process(false)
	var threshold := director.get_thresholds()[0]
	for run_index in RUN_COUNT:
		await _run_one_cycle(
			movement_slice, controller, director, encounter, spawner, targeting, experience,
			upgrade_service, upgrade_overlay, ability_controller, ability_registry,
			weapon_controller, boss_ui, end_screen, threshold, run_index
		)

	controller.prepare_restart()


func _run_one_cycle(
	movement_slice: Control,
	controller: RunController,
	director: GameDirector,
	encounter: BossEncounter,
	spawner: EnemySpawner,
	targeting: TargetingSystem,
	experience: ExperienceSystem,
	upgrade_service: UpgradeService,
	upgrade_overlay: UpgradeOverlay,
	ability_controller: AbilityController,
	ability_registry: AbilityEffectRegistry,
	weapon_controller: WeaponController,
	boss_ui: BossUI,
	end_screen: EndScreen,
	threshold: float,
	run_index: int
) -> void:
	assert_true(controller.is_running(), "Ogni run deve iniziare in RUNNING.")
	assert_true(
		ability_controller.try_activate(), "L'abilita deve potersi attivare nella run %d." % (run_index + 1)
	)
	assert_true(
		ability_controller.get_cooldown_remaining() > 0.0,
		"L'abilita deve avere cooldown attivo prima della vittoria."
	)
	assert_eq(
		ability_registry.get_active_effect_count(), 1, "La run deve contenere un effetto abilita da ripulire."
	)

	var ordinary_enemy := spawner.try_spawn_enemy()
	assert_not_null(ordinary_enemy, "La run completa deve includere nemici base.")
	controller._process(maxf(threshold - controller.get_run_time(), 0.0) + 0.01)
	var boss := encounter.get_active_boss()
	assert_not_null(boss, "La soglia deve creare un Boss nella run %d." % (run_index + 1))
	if boss == null:
		return
	assert_eq(
		controller.get_state(), RunController.RunState.BOSS_INTRO,
		"Ogni Boss deve iniziare dal modal BOSS_INTRO."
	)
	assert_true(encounter.complete_intro(), "L'intro deve poter essere confermata.")

	var definition := encounter.boss_definition
	boss._physics_process(definition.initial_attack_delay + 0.01)
	boss._physics_process(definition.radial_telegraph_duration + 0.01)
	assert_eq(
		movement_slice.get_boss_projectile_parent().get_child_count(),
		definition.radial_projectile_count,
		"La run deve contenere proiettili Boss da ripulire."
	)
	var boss_health := boss.get_health_component()
	assert_true(
		boss.take_damage(boss_health.health_current), "Il Boss deve morire nella run %d." % (run_index + 1)
	)
	assert_false(
		controller.is_terminal(), "La morte del Boss non deve piu' chiudere la run %d (B33)." % (run_index + 1)
	)
	assert_eq(
		experience.experience_total, definition.experience_reward,
		"La ricompensa Boss deve essere atomica in ogni run."
	)
	assert_true(experience.pending_level_ups > 0, "La ricompensa deve conservare i level-up maturati.")
	assert_false(end_screen.visible, "La morte del Boss non deve mostrare EndScreen (B33).")

	await wait_process_frames(2)
	assert_null(encounter.get_active_boss(), "Il Boss morto non deve sopravvivere al terminale.")
	assert_false(director.has_blocking_boss_event(), "Il Director non deve restare bloccato.")
	assert_eq(
		movement_slice.get_boss_projectile_parent().get_child_count(), 0,
		"I proiettili Boss devono sparire alla sua morte."
	)

	assert_true(
		controller.request_defeat(),
		"Il test deve poter chiudere la run %d in DEFEAT per il restart." % (run_index + 1)
	)
	assert_true(
		controller.get_state() == RunController.RunState.DEFEAT and get_tree().paused,
		"La run %d deve terminare in DEFEAT su richiesta." % (run_index + 1)
	)
	var terminal_time := controller.get_run_time()
	controller._process(30.0)
	assert_almost_eq(
		controller.get_run_time(), terminal_time, FLOAT_TOLERANCE, "DEFEAT deve bloccare definitivamente il clock."
	)
	assert_true(upgrade_service.get_current_offer().is_empty(), "DEFEAT deve chiudere l'offerta upgrade.")
	assert_false(upgrade_overlay.visible, "DEFEAT deve nascondere l'overlay upgrade.")
	assert_eq(end_screen.get_title_text(), "GAME OVER", "Il terminale deve mostrare GAME OVER.")

	var next_seed := 16002 + run_index
	assert_true(
		movement_slice.restart_run(next_seed), "La run %d deve poter ripartire in-place." % (run_index + 1)
	)
	await wait_process_frames(2)
	assert_true(controller.is_running() and not get_tree().paused, "Il restart deve riaprire RUNNING.")
	assert_eq(controller.get_seed(), next_seed, "Ogni nuova run deve usare il seed richiesto.")
	assert_almost_eq(controller.get_run_time(), 0.0, FLOAT_TOLERANCE, "Il restart deve azzerare il clock.")
	assert_eq(experience.experience_total, 0, "Il restart deve azzerare gli XP.")
	assert_eq(experience.pending_level_ups, 0, "Il restart deve azzerare la coda level-up.")
	assert_true(upgrade_service.get_ranks().is_empty(), "Il restart deve azzerare i rank upgrade.")
	assert_true(upgrade_service.get_current_offer().is_empty(), "Il restart non deve conservare offerte.")
	assert_true(ability_controller.is_cooldown_ready(), "Il restart deve azzerare il cooldown abilita.")
	assert_eq(
		ability_registry.get_active_effect_count(), 0, "Il restart deve eliminare gli effetti dell'abilita."
	)
	assert_true(weapon_controller.is_ready_to_fire(), "Il restart deve azzerare il cooldown arma.")
	assert_eq(spawner.get_alive_count(), 0, "Il restart deve eliminare i nemici base.")
	assert_eq(targeting.get_registered_count(), 0, "Il restart deve svuotare il targeting.")
	assert_eq(
		movement_slice.get_projectile_parent().get_child_count(), 0, "Nessun proiettile Player deve restare."
	)
	assert_eq(
		movement_slice.get_boss_projectile_parent().get_child_count(), 0, "Nessun proiettile Boss deve restare."
	)
	assert_eq(movement_slice.get_pickup_parent().get_child_count(), 0, "Nessun pickup deve restare.")
	assert_null(encounter.get_active_boss(), "Nessun Boss deve restare dopo il restart.")
	assert_false(boss_ui.is_intro_visible(), "Il restart deve nascondere l'intro.")
	assert_false(boss_ui.is_boss_health_visible(), "Il restart deve nascondere gli HP Boss.")
	assert_false(end_screen.visible, "Il restart deve nascondere EndScreen.")
