extends GutGameplayTest

var _active_ability_request_count := 0


func after_each() -> void:
	get_tree().paused = false


func test_input_map_contract() -> void:
	assert_true(
		bool(ProjectSettings.get_setting(
			"input_devices/joypads/ignore_joypad_on_unfocused_application", false
		)),
		"Il joypad deve essere ignorato quando l'applicazione non ha focus."
	)
	_assert_action(&"move_left", KEY_A, KEY_LEFT, JOY_AXIS_LEFT_X, -1.0)
	_assert_action(&"move_right", KEY_D, KEY_RIGHT, JOY_AXIS_LEFT_X, 1.0)
	_assert_action(&"move_up", KEY_W, KEY_UP, JOY_AXIS_LEFT_Y, -1.0)
	_assert_action(&"move_down", KEY_S, KEY_DOWN, JOY_AXIS_LEFT_Y, 1.0)
	_assert_active_ability_action()


func _assert_active_ability_action() -> void:
	var action := &"active_ability"
	assert_true(InputMap.has_action(action), "InputMap privo di active_ability.")
	var events := InputMap.action_get_events(action)
	var space_found := false
	var joypad_found := false
	for event in events:
		if event is InputEventKey:
			space_found = (event as InputEventKey).physical_keycode == KEY_SPACE
		elif event is InputEventJoypadButton:
			joypad_found = (event as InputEventJoypadButton).button_index == JOY_BUTTON_A
	assert_true(space_found, "active_ability deve avere Space come binding tastiera.")
	assert_true(joypad_found, "active_ability deve avere il face button sud del controller.")


func _assert_action(
	action: StringName,
	primary_key: Key,
	arrow_key: Key,
	axis: JoyAxis,
	axis_value: float
) -> void:
	assert_true(InputMap.has_action(action), "InputMap privo dell'azione %s." % action)
	var events := InputMap.action_get_events(action)
	assert_eq(events.size(), 3, "L'azione %s deve avere esattamente tre binding." % action)

	var physical_keys: Array[Key] = []
	var axis_found := false
	for event in events:
		if event is InputEventKey:
			physical_keys.append((event as InputEventKey).physical_keycode)
		elif event is InputEventJoypadMotion:
			var motion := event as InputEventJoypadMotion
			axis_found = motion.axis == axis and is_equal_approx(motion.axis_value, axis_value)

	assert_true(primary_key in physical_keys, "Binding primario errato per %s." % action)
	assert_true(arrow_key in physical_keys, "Binding freccia errato per %s." % action)
	assert_true(axis_found, "Asse gamepad errato per %s." % action)


func test_touch_joystick_and_input_router_contract() -> void:
	var joystick := TouchJoystick.new()
	joystick.debug_mode_in_editor = true
	joystick.size = Vector2(224.0, 224.0)
	add_child_autofree(joystick)
	await wait_process_frames(1)
	assert_true(joystick.visible, "Il debug editor deve rendere visibile il joystick.")

	var first_press := make_touch_event(7, true, Vector2(196.0, 112.0))
	joystick._gui_input(first_press)
	assert_eq(joystick.active_finger_index, 7, "Il primo dito deve essere catturato.")
	assert_true(joystick.movement_vector.x > 0.99, "La corsa destra deve produrre +X.")

	joystick._gui_input(make_touch_event(8, true, Vector2(28.0, 112.0)))
	assert_eq(joystick.active_finger_index, 7, "Un secondo dito non deve rubare il joystick.")
	assert_true(joystick.movement_vector.x > 0.99, "Il secondo dito non deve cambiare il vettore.")

	var foreign_drag := InputEventScreenDrag.new()
	foreign_drag.index = 8
	foreign_drag.position = Vector2(112.0, 28.0)
	joystick._gui_input(foreign_drag)
	assert_true(joystick.movement_vector.x > 0.99, "Il drag di un altro dito va ignorato.")

	joystick._gui_input(make_touch_event(7, false, Vector2(196.0, 112.0)))
	assert_false(joystick.is_active(), "Il rilascio del dito catturato deve liberare il joystick.")
	assert_eq(joystick.movement_vector, Vector2.ZERO, "Il rilascio deve azzerare il vettore.")

	joystick._gui_input(make_touch_event(3, true, Vector2(112.0, 112.0)))
	assert_eq(joystick.movement_vector, Vector2.ZERO, "Il centro deve rispettare la deadzone.")
	var canceled := make_touch_event(3, false, Vector2(112.0, 112.0))
	canceled.canceled = true
	joystick._gui_input(canceled)
	assert_false(joystick.is_active(), "Un touch cancellato deve resettare il finger index.")

	joystick._gui_input(make_touch_event(4, true, Vector2(196.0, 112.0)))
	get_tree().paused = true
	joystick._process(0.0)
	get_tree().paused = false
	assert_eq(joystick.movement_vector, Vector2.ZERO, "La pausa deve azzerare il joystick.")
	assert_false(joystick.is_active(), "La pausa deve rilasciare il dito catturato.")

	joystick._gui_input(make_touch_event(5, true, Vector2(196.0, 112.0)))
	joystick.hide()
	assert_eq(joystick.movement_vector, Vector2.ZERO, "Nascondere il joystick deve azzerarlo.")
	assert_false(joystick.is_active(), "Nascondere il joystick deve rilasciare il dito.")
	joystick.show()

	var router := InputRouter.new()
	add_child_autofree(router)
	router.bind_touch_joystick(joystick)
	router.active_ability_requested.connect(_on_active_ability_requested)

	Input.action_press(&"active_ability")
	router._process(0.0)
	router._process(0.0)
	assert_eq(
		_active_ability_request_count, 1, "Una pressione held deve produrre una sola intenzione active_ability."
	)
	Input.action_release(&"active_ability")
	router._process(0.0)

	var ability_button := Button.new()
	add_child_autofree(ability_button)
	router.bind_active_ability_button(ability_button)
	ability_button.pressed.emit()
	assert_eq(
		_active_ability_request_count, 2, "Il pulsante touch deve produrre la stessa intenzione active_ability."
	)

	# Un dito catturato ha priorita completa, senza sommare InputMap e touch.
	Input.action_press(&"move_up", 1.0)
	joystick._gui_input(make_touch_event(9, true, Vector2(196.0, 112.0)))
	router._process(0.0)
	assert_true(
		router.movement_vector.x > 0.99 and is_zero_approx(router.movement_vector.y),
		"Touch attivo deve avere priorita su InputMap, senza produrre una diagonale."
	)
	joystick._gui_input(make_touch_event(9, false, Vector2(196.0, 112.0)))
	router._process(0.0)
	assert_true(
		router.movement_vector.y < -0.99 and is_zero_approx(router.movement_vector.x),
		"InputMap deve tornare attivo quando il joystick rilascia il dito."
	)
	Input.action_release(&"move_up")
	router.reset_input()
	assert_eq(router.movement_vector, Vector2.ZERO, "reset_input deve azzerare il router.")

	Input.action_press(&"move_right", 1.0)
	joystick._gui_input(make_touch_event(10, true, Vector2(112.0, 112.0)))
	assert_eq(
		router.movement_vector,
		Vector2.ZERO,
		"Un touch catturato nella deadzone deve sopprimere InputMap immediatamente."
	)
	joystick._gui_input(make_drag_event(10, Vector2(28.0, 112.0), Vector2.ZERO))
	assert_true(
		router.movement_vector.x < -0.99,
		"Sorgenti opposte non devono annullarsi: il touch catturato resta prioritario."
	)
	joystick._gui_input(make_touch_event(10, false, Vector2(28.0, 112.0)))
	router._process(0.0)
	assert_true(router.movement_vector.x > 0.99, "InputMap deve riprendere dopo il touch.")
	Input.action_release(&"move_right")
	router.reset_input()

	# Un input tastiera held non deve attraversare il focus gate automaticamente.
	Input.action_press(&"move_right", 1.0)
	router._process(0.0)
	assert_true(router.movement_vector.x > 0.99, "Il test tastiera held deve partire attivo.")
	router.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_true(router.is_input_suspended(), "Focus loss deve chiudere il gate input.")
	assert_eq(router.movement_vector, Vector2.ZERO, "Focus loss deve azzerare il router.")
	router._process(0.0)
	assert_eq(
		router.movement_vector, Vector2.ZERO, "Input.get_vector non deve ripopolare il movimento senza focus."
	)
	assert_false(router.resume_input(), "Il gate non puo riaprirsi mentre manca il focus.")
	router.notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	router._process(0.0)
	assert_eq(
		router.movement_vector, Vector2.ZERO, "Il focus in non deve riavviare automaticamente un input held."
	)
	assert_true(router.resume_input(), "Il focus valido deve consentire un resume esplicito.")
	assert_true(
		router.movement_vector == Vector2.ZERO and router.is_input_suspended(),
		"Il resume esplicito deve attendere che l'input held torni neutrale."
	)
	Input.action_release(&"move_right")
	router._process(0.0)
	assert_false(router.is_input_suspended(), "Il neutro deve completare il rearm.")
	assert_eq(router.movement_vector, Vector2.ZERO, "Il rearm neutrale non deve muovere.")
	Input.action_press(&"move_right", 1.0)
	router._process(0.0)
	assert_true(router.movement_vector.x > 0.99, "Solo un nuovo input dopo il neutro deve attraversare il gate.")
	Input.action_release(&"move_right")
	router.reset_input()

	# Un asse analogico held resta bloccato durante app pause e dal controller esterno.
	Input.action_press(&"move_down", 0.7)
	router._process(0.0)
	assert_true(router.movement_vector.y > 0.0, "Il test gamepad held deve partire attivo.")
	router.notification(NOTIFICATION_APPLICATION_PAUSED)
	assert_eq(router.movement_vector, Vector2.ZERO, "App pause deve azzerare il router.")
	router._process(0.0)
	assert_eq(
		router.movement_vector, Vector2.ZERO, "Un asse held non deve attraversare il gate durante app pause."
	)
	assert_false(router.resume_input(), "Il resume deve fallire mentre l'app e in pausa.")
	router.notification(NOTIFICATION_APPLICATION_RESUMED)
	router._process(0.0)
	assert_eq(
		router.movement_vector, Vector2.ZERO, "Application resumed non deve riaprire automaticamente il gate."
	)
	router.enabled = false
	assert_true(router.resume_input(), "Un'app valida deve accettare il resume esplicito.")
	router._process(0.0)
	assert_eq(
		router.movement_vector,
		Vector2.ZERO,
		"Il controller deve poter mantenere il gameplay bloccato con enabled=false."
	)
	assert_true(router.is_input_suspended(), "Un asse held deve mantenere il gate in attesa del neutro.")
	Input.action_release(&"move_down")
	router._process(0.0)
	assert_true(
		not router.is_input_suspended() and router.movement_vector == Vector2.ZERO,
		"Il neutro deve riarmare il gate senza bypassare enabled=false."
	)
	Input.action_press(&"move_down", 0.7)
	router._process(0.0)
	assert_eq(router.movement_vector, Vector2.ZERO, "enabled=false deve restare autorevole.")
	router.enabled = true
	router._process(0.0)
	assert_true(router.movement_vector.y > 0.0, "Il controller deve riabilitare esplicitamente.")
	Input.action_release(&"move_down")
	router.reset_input()

	# Un'abilita held durante una sospensione richiede neutro e nuova pressione.
	Input.action_press(&"active_ability")
	router.suspend_input()
	assert_false(router.request_active_ability(), "Il touch abilita non deve attraversare un gate sospeso.")
	assert_true(router.resume_input(), "Il resume valido deve attendere il neutro abilita.")
	router._process(0.0)
	assert_true(router.is_input_suspended(), "Un'abilita held deve impedire il rearm.")
	Input.action_release(&"active_ability")
	router._process(0.0)
	assert_false(router.is_input_suspended(), "Il rilascio abilita deve completare il rearm.")
	Input.action_press(&"active_ability")
	router._process(0.0)
	assert_eq(
		_active_ability_request_count, 3, "Solo una nuova pressione dopo il rearm deve attivare l'abilita."
	)
	Input.action_release(&"active_ability")
	router._process(0.0)

	joystick._gui_input(make_touch_event(11, true, Vector2(196.0, 112.0)))
	router._process(0.0)
	assert_true(router.movement_vector.x > 0.99, "Il router deve ricevere il touch collegato.")
	joystick.queue_free()
	await wait_process_frames(1)
	assert_eq(router.movement_vector, Vector2.ZERO, "Rimuovere il joystick dalla scena deve azzerare il router.")


func _on_active_ability_requested() -> void:
	_active_ability_request_count += 1
