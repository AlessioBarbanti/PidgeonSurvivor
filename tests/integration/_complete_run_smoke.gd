extends SceneTree

const MOVEMENT_SLICE_SCENE := preload("res://scenes/game/movement_slice.tscn")
const INITIAL_VIEWPORT_SIZE := Vector2i(1280, 720)
const RUN_COUNT := 5
const FLOAT_TOLERANCE := 0.001

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	paused = false
	root.content_scale_size = INITIAL_VIEWPORT_SIZE
	root.size = INITIAL_VIEWPORT_SIZE
	await _wait_processed_frame()
	await _validate_five_complete_runs()
	await _finish()


func _validate_five_complete_runs() -> void:
	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	root.add_child(movement_slice)
	await _wait_processed_frame()

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
	_expect(controller != null, "B16 richiede RunController.")
	_expect(encounter != null, "B16 richiede BossEncounter.")
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
		paused = false
		movement_slice.queue_free()
		await process_frame
		return

	controller.set_process(false)
	spawner.set_process(false)
	var threshold := director.get_thresholds()[0]
	for run_index in RUN_COUNT:
		_expect(controller.is_running(), "Ogni run deve iniziare in RUNNING.")
		_expect(
			ability_controller.try_activate(),
			"L'abilita deve potersi attivare nella run %d." % (run_index + 1)
		)
		_expect(
			ability_controller.get_cooldown_remaining() > 0.0,
			"L'abilita deve avere cooldown attivo prima della vittoria."
		)
		_expect(
			ability_registry.get_active_effect_count() == 1,
			"La run deve contenere un effetto abilita da ripulire."
		)

		var ordinary_enemy := spawner.try_spawn_enemy()
		_expect(ordinary_enemy != null, "La run completa deve includere nemici base.")
		controller._process(maxf(threshold - controller.get_run_time(), 0.0) + 0.01)
		var boss := encounter.get_active_boss()
		_expect(boss != null, "La soglia deve creare un Boss nella run %d." % (run_index + 1))
		if boss == null:
			break
		_expect(
			controller.get_state() == RunController.RunState.BOSS_INTRO,
			"Ogni Boss deve iniziare dal modal BOSS_INTRO."
		)
		_expect(encounter.complete_intro(), "L'intro deve poter essere confermata.")

		var definition := encounter.boss_definition
		boss._physics_process(definition.initial_attack_delay + 0.01)
		boss._physics_process(definition.radial_telegraph_duration + 0.01)
		_expect(
			movement_slice.get_boss_projectile_parent().get_child_count()
			== definition.radial_projectile_count,
			"La run deve contenere proiettili Boss da ripulire."
		)
		var boss_health := boss.get_health_component()
		_expect(
			boss.take_damage(boss_health.health_current),
			"Il Boss deve morire nella run %d." % (run_index + 1)
		)
		_expect(
			controller.get_state() == RunController.RunState.VICTORY and paused,
			"La run %d deve terminare in VICTORY." % (run_index + 1)
		)
		var terminal_time := controller.get_run_time()
		controller._process(30.0)
		_expect_float_near(
			controller.get_run_time(),
			terminal_time,
			"VICTORY deve bloccare definitivamente il clock."
		)
		_expect(
			experience.experience_total == definition.experience_reward,
			"La ricompensa Boss deve essere atomica in ogni run."
		)
		_expect(experience.pending_level_ups > 0, "La ricompensa deve conservare i level-up maturati.")
		_expect(upgrade_service.get_current_offer().is_empty(), "VICTORY deve chiudere l'offerta upgrade.")
		_expect(not upgrade_overlay.visible, "VICTORY deve nascondere l'overlay upgrade.")
		_expect(end_screen.get_title_text() == "VITTORIA", "Il terminale deve mostrare VITTORIA.")

		await _wait_processed_frame()
		_expect(encounter.get_active_boss() == null, "Il Boss morto non deve sopravvivere al terminale.")
		_expect(not director.has_blocking_boss_event(), "Il Director non deve restare bloccato.")
		_expect(
			movement_slice.get_boss_projectile_parent().get_child_count() == 0,
			"I proiettili Boss devono sparire alla sua morte."
		)

		var next_seed := 16002 + run_index
		_expect(
			movement_slice.restart_run(next_seed),
			"La run %d deve poter ripartire in-place." % (run_index + 1)
		)
		await _wait_processed_frame()
		_expect(controller.is_running() and not paused, "Il restart deve riaprire RUNNING.")
		_expect(controller.get_seed() == next_seed, "Ogni nuova run deve usare il seed richiesto.")
		_expect_float_near(controller.get_run_time(), 0.0, "Il restart deve azzerare il clock.")
		_expect(experience.experience_total == 0, "Il restart deve azzerare gli XP.")
		_expect(experience.pending_level_ups == 0, "Il restart deve azzerare la coda level-up.")
		_expect(upgrade_service.get_ranks().is_empty(), "Il restart deve azzerare i rank upgrade.")
		_expect(upgrade_service.get_current_offer().is_empty(), "Il restart non deve conservare offerte.")
		_expect(ability_controller.is_cooldown_ready(), "Il restart deve azzerare il cooldown abilita.")
		_expect(
			ability_registry.get_active_effect_count() == 0,
			"Il restart deve eliminare gli effetti dell'abilita."
		)
		_expect(weapon_controller.is_ready_to_fire(), "Il restart deve azzerare il cooldown arma.")
		_expect(spawner.get_alive_count() == 0, "Il restart deve eliminare i nemici base.")
		_expect(targeting.get_registered_count() == 0, "Il restart deve svuotare il targeting.")
		_expect(movement_slice.get_projectile_parent().get_child_count() == 0, "Nessun proiettile Player deve restare.")
		_expect(movement_slice.get_boss_projectile_parent().get_child_count() == 0, "Nessun proiettile Boss deve restare.")
		_expect(movement_slice.get_pickup_parent().get_child_count() == 0, "Nessun pickup deve restare.")
		_expect(encounter.get_active_boss() == null, "Nessun Boss deve restare dopo il restart.")
		_expect(not boss_ui.is_intro_visible(), "Il restart deve nascondere l'intro.")
		_expect(not boss_ui.is_boss_health_visible(), "Il restart deve nascondere gli HP Boss.")
		_expect(not end_screen.visible, "Il restart deve nascondere EndScreen.")

	controller.prepare_restart()
	paused = false
	movement_slice.queue_free()
	await process_frame


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
		print("B16_COMPLETE_RUN_SMOKE_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	printerr("B16_COMPLETE_RUN_SMOKE_FAIL count=%d" % _failures.size())
	quit(1)
