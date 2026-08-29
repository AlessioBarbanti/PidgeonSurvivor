extends GutGameplayTest


func test_pause_change_character_flow() -> void:
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_run_controller() as RunController
	var lifecycle := movement_slice.get_platform_lifecycle() as PlatformLifecycle
	var overlay := movement_slice.get_pause_overlay() as PauseOverlay
	var selector := movement_slice.get_character_select_overlay() as CharacterSelectOverlay
	var hud := movement_slice.get_hud() as GameHud
	var player := movement_slice.get_player() as Player
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	var director := movement_slice.get_game_director() as GameDirector
	var encounter := movement_slice.get_boss_encounter() as BossEncounter
	var weapon := movement_slice.get_weapon_controller() as WeaponController
	var ability := movement_slice.get_ability_controller() as AbilityController
	var effects := movement_slice.get_ability_effect_registry() as AbilityEffectRegistry
	var experience := movement_slice.get_experience_system() as ExperienceSystem
	var dropper := movement_slice.get_experience_dropper() as ExperienceDropper
	var upgrades := movement_slice.get_upgrade_service() as UpgradeService
	var projectiles := movement_slice.get_projectile_parent() as Node2D
	var boss_projectiles := movement_slice.get_boss_projectile_parent() as Node2D
	var pickups := movement_slice.get_pickup_parent() as Node2D
	var effect_parent := movement_slice.get_ability_effect_parent() as Node2D
	var router := movement_slice.get_node("InputRouter") as InputRouter
	var joystick := movement_slice.get_node("UI/SafeAreaRoot/TouchJoystick") as TouchJoystick

	assert_true(controller != null and controller.is_running(), "B18N richiede una run attiva.")
	assert_true(
		lifecycle != null and overlay != null and selector != null,
		"Il flusso pausa/selezione B18N deve essere composto."
	)
	if controller == null or lifecycle == null or overlay == null or selector == null:
		return

	controller.set_process(false)
	spawner.set_process(false)
	player.set_physics_process(false)
	weapon.set_process(false)
	ability.set_process(false)

	var resume_button := overlay.get_resume_button()
	var change_button := overlay.get_change_character_button()
	var cancel_button := overlay.get_cancel_change_button()
	var confirm_button := overlay.get_confirm_change_button()
	assert_true(
		resume_button != null and change_button != null,
		"La pausa deve esporre RIPRENDI e CAMBIA PERSONAGGIO."
	)
	assert_true(
		cancel_button != null and confirm_button != null,
		"La conferma deve esporre ANNULLA e CONFERMA."
	)
	if resume_button == null or change_button == null or cancel_button == null or confirm_button == null:
		return
	for button in [resume_button, change_button, cancel_button, confirm_button]:
		assert_true(
			button.custom_minimum_size.y >= 64.0,
			"Ogni azione B18N deve conservare un target touch alto almeno 64 unita."
		)

	assert_true(
		not overlay.visible and change_button.disabled,
		"CAMBIA PERSONAGGIO deve esistere soltanto nella pausa manuale."
	)
	var initial_seed := controller.get_seed()
	var pause_button := hud.get_pause_button()
	pause_button.pressed.emit()
	await wait_process_frames(1)
	assert_eq(
		controller.get_state(), RunController.RunState.MANUAL_PAUSE, "PAUSA deve aprire il menu manuale."
	)
	assert_true(
		overlay.is_accepting_resume() and not change_button.disabled,
		"La pausa manuale deve rendere attiva l'azione B18N."
	)
	var paused_time := controller.get_run_time()

	change_button.pressed.emit()
	await wait_process_frames(1)
	assert_true(overlay.is_change_confirmation_visible(), "CAMBIA PERSONAGGIO deve chiedere conferma.")
	assert_eq(
		controller.get_state(), RunController.RunState.MANUAL_PAUSE,
		"Aprire la conferma deve conservare MANUAL_PAUSE."
	)
	assert_true(resume_button.disabled, "La conferma non deve permettere una ripresa implicita.")
	cancel_button.pressed.emit()
	await wait_process_frames(1)
	assert_false(overlay.is_change_confirmation_visible(), "ANNULLA deve chiudere soltanto la conferma.")
	assert_eq(
		controller.get_state(), RunController.RunState.MANUAL_PAUSE, "ANNULLA deve lasciare la run in pausa."
	)
	assert_eq(controller.get_seed(), initial_seed, "ANNULLA non deve alterare il seed della run.")
	assert_almost_eq(
		controller.get_run_time(), paused_time, FLOAT_TOLERANCE, "ANNULLA non deve far avanzare il clock."
	)
	change_button.pressed.emit()
	overlay._unhandled_input(_action_event(&"ui_cancel"))
	await wait_process_frames(1)
	assert_false(
		overlay.is_change_confirmation_visible(), "ui_cancel deve chiudere la conferma con tastiera/controller."
	)
	assert_eq(
		controller.get_state(), RunController.RunState.MANUAL_PAUSE, "ui_cancel non deve riprendere la run."
	)
	resume_button.pressed.emit()
	await wait_process_frames(1)
	assert_true(controller.is_running() and not get_tree().paused, "RIPRENDI deve funzionare dopo ANNULLA.")

	_populate_run_state(movement_slice, player, spawner, weapon, ability, experience, dropper, upgrades)
	await wait_process_frames(1)
	controller._process(240.0)
	await wait_process_frames(1)
	if controller.get_state() == RunController.RunState.BOSS_INTRO:
		encounter.complete_intro()
	await wait_process_frames(1)
	assert_true(spawner.get_alive_count() > 0, "La fixture deve contenere nemici prima dell'abbandono.")
	assert_not_null(encounter.get_active_boss(), "La fixture deve contenere un Boss prima dell'abbandono.")
	assert_true(projectiles.get_child_count() > 0, "La fixture deve contenere proiettili prima dell'abbandono.")
	assert_true(dropper.get_active_count() > 0, "La fixture deve contenere XP prima dell'abbandono.")
	assert_false(upgrades.get_ranks().is_empty(), "La fixture deve contenere rank prima dell'abbandono.")
	assert_false(ability.is_cooldown_ready(), "La fixture deve contenere un cooldown prima dell'abbandono.")
	assert_true(
		effects.get_active_effect_count() > 0, "La fixture deve contenere VFX/effetti prima dell'abbandono."
	)

	pause_button.pressed.emit()
	await wait_process_frames(1)
	change_button.pressed.emit()
	await wait_process_frames(1)
	assert_true(lifecycle.request_back(), "Back deve essere gestito mentre la conferma e aperta.")
	await wait_process_frames(1)
	assert_false(overlay.is_change_confirmation_visible(), "Back deve chiudere la conferma B18N.")
	assert_eq(
		controller.get_state(), RunController.RunState.MANUAL_PAUSE,
		"Back sulla conferma non deve riprendere la run."
	)

	change_button.pressed.emit()
	await wait_process_frames(1)
	confirm_button.pressed.emit()
	await wait_process_frames(2)
	assert_eq(controller.get_state(), RunController.RunState.BOOT, "CONFERMA deve tornare in BOOT.")
	assert_true(
		controller.get_seed() == 0 and is_zero_approx(controller.get_run_time()),
		"BOOT deve azzerare seed e clock."
	)
	assert_false(get_tree().paused, "Il selettore in BOOT non deve lasciare il SceneTree in pausa.")
	assert_true(
		selector.visible and not overlay.visible, "CONFERMA deve mostrare il selettore e chiudere la pausa."
	)
	assert_true(
		router.is_input_suspended() and router.movement_vector == Vector2.ZERO,
		"Il selettore deve bloccare e azzerare l'input gameplay."
	)
	assert_true(
		not joystick.visible and not joystick.is_active(), "Il joystick non deve sopravvivere dietro il selettore."
	)
	assert_eq(spawner.get_alive_count(), 0, "Il cleanup B18N deve rimuovere i nemici.")
	assert_true(
		director.get_active_boss() == null and encounter.get_active_boss() == null,
		"Il cleanup B18N deve rimuovere il Boss."
	)
	assert_true(
		projectiles.get_child_count() == 0 and boss_projectiles.get_child_count() == 0,
		"Il cleanup B18N deve rimuovere i proiettili."
	)
	assert_true(
		dropper.get_active_count() == 0 and pickups.get_child_count() == 0,
		"Il cleanup B18N deve rimuovere i pickup XP."
	)
	assert_true(
		experience.level == 1 and experience.experience_total == 0,
		"Il cleanup B18N deve azzerare la progressione XP."
	)
	assert_true(
		upgrades.get_ranks().is_empty() and upgrades.get_current_offer().is_empty(),
		"Il cleanup B18N deve azzerare offerte e rank."
	)
	assert_true(
		ability.get_ability_rank() == 1 and ability.is_cooldown_ready(),
		"Il cleanup B18N deve azzerare rank e cooldown abilita."
	)
	assert_true(
		effects.get_active_effect_count() == 0 and effect_parent.get_child_count() == 0,
		"Il cleanup B18N deve rimuovere effetti e VFX."
	)

	var bea_button := selector.get_button(&"bea")
	assert_not_null(bea_button, "Il selettore B18N deve permettere una nuova scelta.")
	if bea_button != null:
		bea_button.pressed.emit()
		selector.get_confirm_button().pressed.emit()
		await wait_process_frames(2)
		assert_true(controller.is_running(), "La selezione successiva deve avviare una nuova run.")
		assert_eq(player.get_friend_definition().id, &"bea", "La nuova run deve usare il nuovo personaggio.")
		assert_true(
			not selector.visible and not overlay.visible, "La nuova run deve chiudere tutti gli overlay B18N."
		)
		assert_ne(controller.get_seed(), 0, "La nuova run deve ricevere un nuovo seed.")
		assert_true(
			upgrades.get_ranks().is_empty() and ability.get_ability_rank() == 1,
			"La nuova run non deve ereditare rank."
		)
		assert_true(
			ability.is_cooldown_ready() and effects.get_active_effect_count() == 0,
			"La nuova run non deve ereditare cooldown o effetti."
		)

	if is_instance_valid(controller):
		controller.prepare_restart()


func _action_event(action: StringName) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	return event


func _populate_run_state(
	_movement_slice: Control,
	player: Player,
	spawner: EnemySpawner,
	weapon: WeaponController,
	ability: AbilityController,
	experience: ExperienceSystem,
	dropper: ExperienceDropper,
	upgrades: UpgradeService
) -> void:
	var enemy := spawner.try_spawn_enemy()
	if enemy == null:
		return
	enemy.set_physics_process(false)
	enemy.global_position = player.global_position + Vector2(350.0, 0.0)
	enemy.experience_reward_scale = 1.0
	dropper.try_spawn_drop(enemy)
	weapon.try_fire()
	ability.try_activate()
	if experience.add_experience(experience.get_experience_required()):
		var offer := upgrades.get_current_offer()
		if not offer.is_empty():
			upgrades.select_upgrade(offer[0].id)
