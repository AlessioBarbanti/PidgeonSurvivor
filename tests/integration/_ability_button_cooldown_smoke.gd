extends SceneTree

const MOVEMENT_SLICE_SCENE := preload("res://scenes/game/movement_slice.tscn")
const INITIAL_VIEWPORT_SIZE := Vector2i(1280, 720)
const FLOAT_TOLERANCE := 0.02

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.content_scale_size = INITIAL_VIEWPORT_SIZE
	root.size = INITIAL_VIEWPORT_SIZE
	await _wait_processed_frame()

	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	root.add_child(movement_slice)
	await _wait_processed_frame()

	var controller := movement_slice.get_run_controller() as RunController
	var ability := movement_slice.get_ability_controller() as AbilityController
	var hud := movement_slice.get_hud() as GameHud
	var button: TouchAbilityButton
	if hud != null:
		button = hud.get_active_ability_button()

	_expect(controller != null, "B18K richiede RunController.")
	_expect(ability != null, "B18K richiede AbilityController.")
	_expect(hud != null, "B18K richiede GameHud.")
	_expect(button != null, "B18K richiede TouchAbilityButton.")
	if controller == null or ability == null or hud == null or button == null:
		await _finish(movement_slice, controller)
		return

	controller.set_process(false)
	ability.set_process(false)
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	if spawner != null:
		spawner.set_process(false)
	var player := movement_slice.get_node_or_null("World/Player") as Player
	if player != null:
		player.set_physics_process(false)
	var weapon := movement_slice.get_weapon_controller() as WeaponController
	if weapon != null:
		weapon.set_process(false)

	var definition := ability.get_definition()
	_expect(definition != null, "Il pulsante B18K richiede una definizione equipaggiata.")
	if definition != null:
		_expect(
			button.get_ability_icon() == definition.icon,
			"L'icona equipaggiata deve essere la superficie del pulsante."
		)
	_expect(
		button.size.x >= 64.0 and button.size.y >= 64.0,
		"Il target touch B18K deve misurare almeno 64 unita logiche."
	)
	var ability_rect := hud.get_ability_panel_rect()
	var button_rect := hud.get_active_ability_button_rect()
	_expect(
		ability_rect.position.distance_to(button_rect.position) <= FLOAT_TOLERANCE
		and ability_rect.size.distance_to(button_rect.size) <= FLOAT_TOLERANCE,
		"B18K deve lasciare soltanto l'icona senza card esterna."
	)
	_expect(button.text.is_empty(), "Il pulsante icona non deve mostrare un nome o una label.")
	_expect(
		button.get_theme_stylebox("normal") is StyleBoxEmpty,
		"Il pulsante icona non deve avere un rettangolo di sfondo."
	)
	_expect(
		hud.find_child("AbilityNameLabel", true, false) == null,
		"Il nome dell'abilita non deve esistere nel layout HUD."
	)
	_expect(not button.disabled, "Il pulsante deve partire attivabile in RUNNING.")
	_expect(button.is_ready_visual(), "Lo stato pronto deve mostrare l'anello attivabile.")
	_expect(not button.has_circular_cooldown(), "Da pronta la maschera circolare deve sparire.")
	_expect(button.get_cooldown_seconds_text().is_empty(), "Da pronta il timer centrale deve sparire.")

	button.pressed.emit()
	_expect(ability.get_cooldown_remaining() > 0.0, "Il pulsante icona deve attivare l'abilita.")
	_expect(button.disabled, "Durante il cooldown il pulsante deve essere disabilitato.")
	_expect(button.has_circular_cooldown(), "Il cooldown deve mostrare la maschera circolare.")
	_expect(
		button.get_cooldown_seconds_text() == str(int(ceil(ability.get_cooldown_total()))),
		"Il centro deve mostrare i secondi residui arrotondati per eccesso."
	)
	_expect_float_near(
		button.get_cooldown_fraction(),
		1.0,
		"La maschera deve partire piena."
	)

	var half_cooldown := ability.get_cooldown_total() * 0.5
	ability._process(half_cooldown)
	_expect_float_near(
		button.get_cooldown_fraction(),
		0.5,
		"La maschera circolare deve seguire il tempo gameplay."
	)
	if OS.get_cmdline_user_args().has("--capture-b18k"):
		await _capture_viewport("res://exports/screenshots/b18k_cooldown.png")
	var paused_remaining := ability.get_cooldown_remaining()
	_expect(controller.request_manual_pause(), "La fixture B18K deve entrare in pausa.")
	ability._process(2.0)
	_expect_float_near(
		ability.get_cooldown_remaining(),
		paused_remaining,
		"La pausa deve congelare cooldown e maschera."
	)
	_expect(button.disabled, "La pausa deve mantenere il pulsante disabilitato.")
	_expect(controller.resume_run(), "La fixture B18K deve riprendere la run.")
	ability._process(paused_remaining)
	_expect(ability.is_cooldown_ready(), "Il cooldown deve tornare pronto.")
	_expect(not button.disabled, "A cooldown concluso il pulsante deve riattivarsi.")
	_expect(button.is_ready_visual(), "La prontezza deve tornare visibile.")
	_expect(not button.has_circular_cooldown(), "La maschera deve sparire a cooldown concluso.")
	_expect(button.get_cooldown_seconds_text().is_empty(), "Il timer centrale deve sparire a zero.")

	button.pressed.emit()
	_expect(button.has_circular_cooldown(), "La seconda attivazione deve riaprire il cooldown.")
	_expect(controller.request_defeat(), "La fixture B18K deve raggiungere un terminale.")
	_expect(movement_slice.restart_run(1811), "Il restart B18K deve riuscire.")
	_expect(not button.has_circular_cooldown(), "Il restart deve eliminare la maschera residua.")
	_expect(button.get_cooldown_seconds_text().is_empty(), "Il restart deve eliminare il timer residuo.")
	_expect(button.is_ready_visual(), "La nuova run deve ripartire pronta.")

	await _finish(movement_slice, controller)


func _expect_float_near(actual: float, expected: float, message: String) -> void:
	_expect(absf(actual - expected) <= FLOAT_TOLERANCE, "%s Atteso %s, ottenuto %s." % [message, expected, actual])


func _wait_processed_frame() -> void:
	await process_frame
	await process_frame


func _capture_viewport(path: String) -> void:
	await process_frame
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var capture := root.get_texture().get_image()
	var result := capture.save_png(path)
	_expect(result == OK, "La cattura visiva B18K deve essere salvata.")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish(movement_slice: Node, controller: RunController) -> void:
	if is_instance_valid(controller) and controller.is_running():
		controller.request_defeat()
	if is_instance_valid(controller):
		controller.prepare_restart()
	paused = false
	if is_instance_valid(movement_slice):
		movement_slice.queue_free()
	await process_frame
	if _failures.is_empty():
		print("B18K_ABILITY_BUTTON_COOLDOWN_SMOKE_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	printerr("B18K_ABILITY_BUTTON_COOLDOWN_SMOKE_FAIL count=%d" % _failures.size())
	quit(1)
