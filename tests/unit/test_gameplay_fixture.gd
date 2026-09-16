extends GutGameplayTest

var _previous_welcome_setting: Variant
var _previous_pause: bool


func before_each() -> void:
	_previous_welcome_setting = ProjectSettings.get_setting(FORCE_WELCOME_SETTING, null)
	_previous_pause = get_tree().paused


func after_each() -> void:
	ProjectSettings.set_setting(FORCE_WELCOME_SETTING, _previous_welcome_setting)
	get_tree().paused = _previous_pause


func test_ui_wait_expires_even_when_the_scene_tree_is_paused() -> void:
	get_tree().paused = true
	assert_false(await _wait_while_ui(func() -> bool: return true, 0.05))
	assert_true(await _wait_while_ui(func() -> bool: return false, 0.05))


func test_welcome_fixture_restores_setting_and_starts_with_requested_seed() -> void:
	for previous_value: Variant in [null, false, true]:
		ProjectSettings.set_setting(FORCE_WELCOME_SETTING, previous_value)
		var slice := await instantiate_movement_slice(Vector2i(960, 720), true, 187)
		assert_eq(ProjectSettings.get_setting(FORCE_WELCOME_SETTING, null), previous_value)
		assert_eq(ProjectSettings.has_setting(FORCE_WELCOME_SETTING), previous_value != null)
		assert_eq(get_tree().root.content_scale_size, Vector2i(960, 720))
		var controller := slice.get_run_controller() as RunController
		assert_eq(controller.get_state(), RunController.RunState.BOOT)
		slice.get_welcome_screen().get_play_button().pressed.emit()
		slice.get_character_select_overlay().get_confirm_button().pressed.emit()
		assert_true(controller.is_running(), "La fixture deve usare il normale flusso BOOT verso la run.")
		assert_eq(controller.get_seed(), 187, "Il seed richiesto deve raggiungere la run reale.")
		controller.prepare_restart()
		slice.queue_free()
		await wait_process_frames(2)
