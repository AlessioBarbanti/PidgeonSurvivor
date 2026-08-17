extends SceneTree

var _failures: Array[String] = []
var _active_ability_request_count := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_validate_input_map()

	var joystick := TouchJoystick.new()
	joystick.debug_mode_in_editor = true
	joystick.size = Vector2(224.0, 224.0)
	root.add_child(joystick)
	await process_frame
	_expect(joystick.visible, "Il debug editor deve rendere visibile il joystick.")

	var first_press := _touch(7, true, Vector2(196.0, 112.0))
	joystick._gui_input(first_press)
	_expect(joystick.active_finger_index == 7, "Il primo dito deve essere catturato.")
	_expect(joystick.movement_vector.x > 0.99, "La corsa destra deve produrre +X.")

	joystick._gui_input(_touch(8, true, Vector2(28.0, 112.0)))
	_expect(joystick.active_finger_index == 7, "Un secondo dito non deve rubare il joystick.")
	_expect(joystick.movement_vector.x > 0.99, "Il secondo dito non deve cambiare il vettore.")

	var foreign_drag := InputEventScreenDrag.new()
	foreign_drag.index = 8
	foreign_drag.position = Vector2(112.0, 28.0)
	joystick._gui_input(foreign_drag)
	_expect(joystick.movement_vector.x > 0.99, "Il drag di un altro dito va ignorato.")

	joystick._gui_input(_touch(7, false, Vector2(196.0, 112.0)))
	_expect(not joystick.is_active(), "Il rilascio del dito catturato deve liberare il joystick.")
	_expect(joystick.movement_vector == Vector2.ZERO, "Il rilascio deve azzerare il vettore.")

	joystick._gui_input(_touch(3, true, Vector2(112.0, 112.0)))
	_expect(joystick.movement_vector == Vector2.ZERO, "Il centro deve rispettare la deadzone.")
	var canceled := _touch(3, false, Vector2(112.0, 112.0))
	canceled.canceled = true
	joystick._gui_input(canceled)
	_expect(not joystick.is_active(), "Un touch cancellato deve resettare il finger index.")

	joystick._gui_input(_touch(4, true, Vector2(196.0, 112.0)))
	paused = true
	joystick._process(0.0)
	paused = false
	_expect(joystick.movement_vector == Vector2.ZERO, "La pausa deve azzerare il joystick.")
	_expect(not joystick.is_active(), "La pausa deve rilasciare il dito catturato.")

	joystick._gui_input(_touch(5, true, Vector2(196.0, 112.0)))
	joystick.hide()
	_expect(joystick.movement_vector == Vector2.ZERO, "Nascondere il joystick deve azzerarlo.")
	_expect(not joystick.is_active(), "Nascondere il joystick deve rilasciare il dito.")
	joystick.show()

	var router := InputRouter.new()
	root.add_child(router)
	router.bind_touch_joystick(joystick)
	router.active_ability_requested.connect(_on_active_ability_requested)

	Input.action_press(&"active_ability")
	router._process(0.0)
	router._process(0.0)
	_expect(
		_active_ability_request_count == 1,
		"Una pressione held deve produrre una sola intenzione active_ability."
	)
	Input.action_release(&"active_ability")
	router._process(0.0)

	var ability_button := Button.new()
	root.add_child(ability_button)
	router.bind_active_ability_button(ability_button)
	ability_button.pressed.emit()
	_expect(
		_active_ability_request_count == 2,
		"Il pulsante touch deve produrre la stessa intenzione active_ability."
	)

	# Un dito catturato ha priorita completa, senza sommare InputMap e touch.
	Input.action_press(&"move_up", 1.0)
	joystick._gui_input(_touch(9, true, Vector2(196.0, 112.0)))
	router._process(0.0)
	_expect(
		router.movement_vector.x > 0.99 and is_zero_approx(router.movement_vector.y),
		"Touch attivo deve avere priorita su InputMap, senza produrre una diagonale."
	)
	joystick._gui_input(_touch(9, false, Vector2(196.0, 112.0)))
	router._process(0.0)
	_expect(
		router.movement_vector.y < -0.99 and is_zero_approx(router.movement_vector.x),
		"InputMap deve tornare attivo quando il joystick rilascia il dito."
	)
	Input.action_release(&"move_up")
	router.reset_input()
	_expect(router.movement_vector == Vector2.ZERO, "reset_input deve azzerare il router.")

	Input.action_press(&"move_right", 1.0)
	joystick._gui_input(_touch(10, true, Vector2(112.0, 112.0)))
	_expect(
		router.movement_vector == Vector2.ZERO,
		"Un touch catturato nella deadzone deve sopprimere InputMap immediatamente."
	)
	joystick._gui_input(_drag(10, Vector2(28.0, 112.0)))
	_expect(
		router.movement_vector.x < -0.99,
		"Sorgenti opposte non devono annullarsi: il touch catturato resta prioritario."
	)
	joystick._gui_input(_touch(10, false, Vector2(28.0, 112.0)))
	router._process(0.0)
	_expect(router.movement_vector.x > 0.99, "InputMap deve riprendere dopo il touch.")
	Input.action_release(&"move_right")
	router.reset_input()

	# Un input tastiera held non deve attraversare il focus gate automaticamente.
	Input.action_press(&"move_right", 1.0)
	router._process(0.0)
	_expect(router.movement_vector.x > 0.99, "Il test tastiera held deve partire attivo.")
	router.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	_expect(router.is_input_suspended(), "Focus loss deve chiudere il gate input.")
	_expect(router.movement_vector == Vector2.ZERO, "Focus loss deve azzerare il router.")
	router._process(0.0)
	_expect(
		router.movement_vector == Vector2.ZERO,
		"Input.get_vector non deve ripopolare il movimento senza focus."
	)
	_expect(not router.resume_input(), "Il gate non puo riaprirsi mentre manca il focus.")
	router.notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	router._process(0.0)
	_expect(
		router.movement_vector == Vector2.ZERO,
		"Il focus in non deve riavviare automaticamente un input held."
	)
	_expect(router.resume_input(), "Il focus valido deve consentire un resume esplicito.")
	_expect(
		router.movement_vector == Vector2.ZERO and router.is_input_suspended(),
		"Il resume esplicito deve attendere che l'input held torni neutrale."
	)
	Input.action_release(&"move_right")
	router._process(0.0)
	_expect(not router.is_input_suspended(), "Il neutro deve completare il rearm.")
	_expect(router.movement_vector == Vector2.ZERO, "Il rearm neutrale non deve muovere.")
	Input.action_press(&"move_right", 1.0)
	router._process(0.0)
	_expect(
		router.movement_vector.x > 0.99,
		"Solo un nuovo input dopo il neutro deve attraversare il gate."
	)
	Input.action_release(&"move_right")
	router.reset_input()

	# Un asse analogico held resta bloccato durante app pause e dal controller esterno.
	Input.action_press(&"move_down", 0.7)
	router._process(0.0)
	_expect(router.movement_vector.y > 0.0, "Il test gamepad held deve partire attivo.")
	router.notification(NOTIFICATION_APPLICATION_PAUSED)
	_expect(router.movement_vector == Vector2.ZERO, "App pause deve azzerare il router.")
	router._process(0.0)
	_expect(
		router.movement_vector == Vector2.ZERO,
		"Un asse held non deve attraversare il gate durante app pause."
	)
	_expect(not router.resume_input(), "Il resume deve fallire mentre l'app e in pausa.")
	router.notification(NOTIFICATION_APPLICATION_RESUMED)
	router._process(0.0)
	_expect(
		router.movement_vector == Vector2.ZERO,
		"Application resumed non deve riaprire automaticamente il gate."
	)
	router.enabled = false
	_expect(router.resume_input(), "Un'app valida deve accettare il resume esplicito.")
	router._process(0.0)
	_expect(
		router.movement_vector == Vector2.ZERO,
		"Il controller deve poter mantenere il gameplay bloccato con enabled=false."
	)
	_expect(
		router.is_input_suspended(),
		"Un asse held deve mantenere il gate in attesa del neutro."
	)
	Input.action_release(&"move_down")
	router._process(0.0)
	_expect(
		not router.is_input_suspended() and router.movement_vector == Vector2.ZERO,
		"Il neutro deve riarmare il gate senza bypassare enabled=false."
	)
	Input.action_press(&"move_down", 0.7)
	router._process(0.0)
	_expect(router.movement_vector == Vector2.ZERO, "enabled=false deve restare autorevole.")
	router.enabled = true
	router._process(0.0)
	_expect(router.movement_vector.y > 0.0, "Il controller deve riabilitare esplicitamente.")
	Input.action_release(&"move_down")
	router.reset_input()

	# Un'abilita held durante una sospensione richiede neutro e nuova pressione.
	Input.action_press(&"active_ability")
	router.suspend_input()
	_expect(
		not router.request_active_ability(),
		"Il touch abilita non deve attraversare un gate sospeso."
	)
	_expect(router.resume_input(), "Il resume valido deve attendere il neutro abilita.")
	router._process(0.0)
	_expect(router.is_input_suspended(), "Un'abilita held deve impedire il rearm.")
	Input.action_release(&"active_ability")
	router._process(0.0)
	_expect(not router.is_input_suspended(), "Il rilascio abilita deve completare il rearm.")
	Input.action_press(&"active_ability")
	router._process(0.0)
	_expect(
		_active_ability_request_count == 3,
		"Solo una nuova pressione dopo il rearm deve attivare l'abilita."
	)
	Input.action_release(&"active_ability")
	router._process(0.0)

	joystick._gui_input(_touch(11, true, Vector2(196.0, 112.0)))
	router._process(0.0)
	_expect(router.movement_vector.x > 0.99, "Il router deve ricevere il touch collegato.")
	joystick.queue_free()
	await process_frame
	_expect(
		router.movement_vector == Vector2.ZERO,
		"Rimuovere il joystick dalla scena deve azzerare il router."
	)

	router.queue_free()
	ability_button.queue_free()
	await process_frame

	if _failures.is_empty():
		print("INPUT_SUBSYSTEM_SMOKE_OK")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _validate_input_map() -> void:
	_expect(
		bool(ProjectSettings.get_setting(
			"input_devices/joypads/ignore_joypad_on_unfocused_application",
			false
		)),
		"Il joypad deve essere ignorato quando l'applicazione non ha focus."
	)
	_validate_action(&"move_left", KEY_A, KEY_LEFT, JOY_AXIS_LEFT_X, -1.0)
	_validate_action(&"move_right", KEY_D, KEY_RIGHT, JOY_AXIS_LEFT_X, 1.0)
	_validate_action(&"move_up", KEY_W, KEY_UP, JOY_AXIS_LEFT_Y, -1.0)
	_validate_action(&"move_down", KEY_S, KEY_DOWN, JOY_AXIS_LEFT_Y, 1.0)
	_validate_active_ability_action()


func _validate_active_ability_action() -> void:
	var action := &"active_ability"
	_expect(InputMap.has_action(action), "InputMap privo di active_ability.")
	var events := InputMap.action_get_events(action)
	var space_found := false
	var joypad_found := false
	for event in events:
		if event is InputEventKey:
			space_found = (event as InputEventKey).physical_keycode == KEY_SPACE
		elif event is InputEventJoypadButton:
			joypad_found = (event as InputEventJoypadButton).button_index == JOY_BUTTON_A
	_expect(space_found, "active_ability deve avere Space come binding tastiera.")
	_expect(joypad_found, "active_ability deve avere il face button sud del controller.")


func _validate_action(
	action: StringName,
	primary_key: Key,
	arrow_key: Key,
	axis: JoyAxis,
	axis_value: float
) -> void:
	_expect(InputMap.has_action(action), "InputMap privo dell'azione %s." % action)
	var events := InputMap.action_get_events(action)
	_expect(events.size() == 3, "L'azione %s deve avere esattamente tre binding." % action)

	var physical_keys: Array[Key] = []
	var axis_found := false
	for event in events:
		if event is InputEventKey:
			physical_keys.append((event as InputEventKey).physical_keycode)
		elif event is InputEventJoypadMotion:
			var motion := event as InputEventJoypadMotion
			axis_found = motion.axis == axis and is_equal_approx(motion.axis_value, axis_value)

	_expect(primary_key in physical_keys, "Binding primario errato per %s." % action)
	_expect(arrow_key in physical_keys, "Binding freccia errato per %s." % action)
	_expect(axis_found, "Asse gamepad errato per %s." % action)


func _touch(index: int, pressed: bool, position: Vector2) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.pressed = pressed
	event.position = position
	return event


func _drag(index: int, position: Vector2) -> InputEventScreenDrag:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = position
	return event


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _on_active_ability_requested() -> void:
	_active_ability_request_count += 1
