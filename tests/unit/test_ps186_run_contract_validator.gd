extends GutGameplayTest


func test_validation_is_repeatable_and_does_not_change_run_state() -> void:
	var scene := await _create_boot_scene()
	var controller: RunController = scene.get_run_controller()
	var upgrades: UpgradeService = scene.get_upgrade_service()
	var node_count := get_tree().get_node_count()
	watch_signals(controller)
	watch_signals(upgrades)
	assert_eq(controller.get_state(), RunController.RunState.BOOT)
	for _iteration in 2:
		assert_eq(RunContractValidator.collect_failures(scene), [])
		assert_eq(get_tree().get_node_count(), node_count, "Le scene di prova vengono liberate.")
	assert_eq(controller.get_state(), RunController.RunState.BOOT)
	assert_eq(controller.get_seed(), 0)
	assert_eq(controller.get_run_time(), 0.0)
	assert_true(upgrades.get_ranks().is_empty())
	assert_eq(upgrades.get_draw_count(), 0)
	assert_signal_not_emitted(controller, "state_changed")
	assert_signal_not_emitted(controller, "run_started")
	assert_signal_not_emitted(controller, "run_time_changed")
	assert_signal_not_emitted(upgrades, "offer_generated")
	assert_signal_not_emitted(upgrades, "ranks_reset")


func test_independent_faults_are_reported_in_order_and_recover_after_restore() -> void:
	var scene := await _create_boot_scene()
	var joystick: TouchJoystick = scene.get_touch_joystick()
	var weapon: WeaponController = scene.get_weapon_controller()
	var end_screen: EndScreen = scene.get_end_screen()
	var projectile_scene := weapon.projectile_scene
	joystick.dynamic_origin = false
	weapon.projectile_scene = null
	end_screen.show()
	var failures := RunContractValidator.collect_failures(scene)
	joystick.dynamic_origin = true
	weapon.projectile_scene = projectile_scene
	end_screen.hide()
	assert_eq(failures, [
		"B18L richiede il joystick dinamico.",
		"WeaponController privo della scena proiettile.",
		"EndScreen deve essere nascosto durante la run.",
	], "PS-186: i guasti di input, combattimento e UI restano tutti diagnosticati.")
	assert_eq(RunContractValidator.collect_failures(scene), [])


func test_validation_remains_available_after_restart() -> void:
	var scene := await _create_boot_scene()
	var controller: RunController = scene.get_run_controller()
	controller.set_process(false)
	assert_true(scene.start_selected_run(18601))
	assert_true(controller.request_manual_pause())
	assert_true(controller.prepare_restart())
	assert_eq(RunContractValidator.collect_failures(scene), [])
	assert_eq(controller.get_state(), RunController.RunState.BOOT)
	assert_eq(controller.get_seed(), 0)
	assert_false(get_tree().paused)


func _create_boot_scene() -> Control:
	const FORCE_WELCOME := "application/run/b18o_force_welcome_for_test"
	var previous: Variant = ProjectSettings.get_setting(FORCE_WELCOME, null)
	ProjectSettings.set_setting(FORCE_WELCOME, true)
	var scene := await instantiate_movement_slice()
	ProjectSettings.set_setting(FORCE_WELCOME, previous)
	return scene
