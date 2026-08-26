extends SceneTree

const MOVEMENT_SLICE_SCENE := preload("res://scenes/game/movement_slice.tscn")
const ABILITY_DEFINITION := preload("res://data/abilities/magno_earthquake_shockwave.tres")
const INITIAL_VIEWPORT_SIZE := Vector2i(1280, 720)
const FLOAT_TOLERANCE := 0.01

var _failures: Array[String] = []
var _activation_count := 0
var _ready_true_count := 0
var _ready_false_count := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	_validate_definition_and_world_units()
	_validate_input_map()
	await _validate_composed_ability()
	await _finish()


func _validate_definition_and_world_units() -> void:
	var definition := ABILITY_DEFINITION as AbilityDefinition
	_expect(definition != null and definition.is_valid(), "La definizione di Magno deve essere valida.")
	if definition == null:
		return
	_expect(definition.id == &"magno_earthquake_shockwave", "L'ID abilita deve essere stabile.")
	_expect(definition.effect_id == AbilityEffectRegistry.EARTHQUAKE_SHOCKWAVE, "Il registry deve riconoscere l'effetto tellurico.")
	_expect_float_near(definition.cooldown_seconds, 8.0, "Il cooldown dati deve rispettare il PRD.")
	_expect_float_near(definition.area_radius, 220.0, "Il raggio dati deve rispettare il PRD.")
	_expect_float_near(definition.damage, 20.0, "Il danno dati deve rispettare il PRD.")
	_expect_float_near(definition.get_effect_float(&"knockback_force"), 300.0, "Il knockback deve provenire dai dati.")
	_expect_float_near(definition.get_effect_float(&"stun_duration"), 0.2, "La durata knockback deve provenire dai dati.")

	# Il raggio e una distanza nel mondo logico: cambia il centro del playfield,
	# non la soglia, anche quando safe area e aspect ratio sono diversi.
	var safe_areas := [
		Rect2(20.0, 20.0, 1240.0, 680.0),
		Rect2(64.0, 20.0, 1472.0, 680.0),
		Rect2(20.0, 20.0, 920.0, 680.0),
	]
	for safe_area in safe_areas:
		var playfield := ArenaLayout.calculate_playfield_rect(safe_area, 16.0 / 9.0)
		var origin := playfield.get_center()
		_expect(
			AbilityEffectRegistry.is_point_within_radius(
				origin,
				origin + Vector2(219.0, 0.0),
				definition.area_radius
			),
			"Un bersaglio a 219 unita deve restare nel raggio su ogni layout."
		)
		_expect(
			not AbilityEffectRegistry.is_point_within_radius(
				origin,
				origin + Vector2(221.0, 0.0),
				definition.area_radius
			),
			"Un bersaglio a 221 unita deve restare fuori dal raggio su ogni layout."
		)


func _validate_input_map() -> void:
	_expect(InputMap.has_action(&"active_ability"), "InputMap deve contenere active_ability.")
	var keyboard_found := false
	var controller_found := false
	for event in InputMap.action_get_events(&"active_ability"):
		if event is InputEventKey:
			keyboard_found = (event as InputEventKey).physical_keycode == KEY_SPACE
		elif event is InputEventJoypadButton:
			controller_found = (event as InputEventJoypadButton).button_index == JOY_BUTTON_A
	_expect(keyboard_found, "Space deve attivare l'abilita.")
	_expect(controller_found, "Il face button sud deve attivare l'abilita.")


func _validate_composed_ability() -> void:
	root.content_scale_size = INITIAL_VIEWPORT_SIZE
	root.size = INITIAL_VIEWPORT_SIZE
	await _wait_processed_frame()

	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	root.add_child(movement_slice)
	await _wait_processed_frame()

	var controller := movement_slice.get_run_controller() as RunController
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	var targeting := movement_slice.get_targeting_system() as TargetingSystem
	var player := movement_slice.get_node_or_null("World/Player") as Player
	var input_router := movement_slice.get_node_or_null("InputRouter") as InputRouter
	var lifecycle: PlatformLifecycle = movement_slice.get_platform_lifecycle()
	var ability := movement_slice.get_ability_controller() as AbilityController
	var registry := movement_slice.get_ability_effect_registry() as AbilityEffectRegistry
	var effect_parent := movement_slice.get_ability_effect_parent() as Node2D
	var hud := movement_slice.get_hud() as GameHud
	var weapon := movement_slice.get_weapon_controller() as WeaponController

	_expect(controller != null, "B09A richiede RunController.")
	_expect(spawner != null, "B09A richiede EnemySpawner.")
	_expect(targeting != null, "B09A richiede TargetingSystem.")
	_expect(player != null, "B09A richiede Player.")
	_expect(input_router != null, "B09A richiede InputRouter.")
	_expect(lifecycle != null, "B09A richiede PlatformLifecycle.")
	_expect(ability != null, "B09A richiede AbilityController.")
	_expect(registry != null, "B09A richiede AbilityEffectRegistry.")
	_expect(effect_parent != null, "B09A richiede un contenitore effetti scene-local.")
	_expect(hud != null, "B09A richiede il feedback HUD.")
	if (
		controller == null
		or spawner == null
		or targeting == null
		or player == null
		or input_router == null
		or lifecycle == null
		or ability == null
		or registry == null
		or effect_parent == null
		or hud == null
	):
		paused = false
		movement_slice.queue_free()
		await process_frame
		return

	controller.set_process(false)
	spawner.set_process(false)
	player.set_physics_process(false)
	ability.set_process(false)
	if weapon != null:
		weapon.set_process(false)

	ability.ability_activated.connect(_on_ability_activated)
	ability.readiness_changed.connect(_on_readiness_changed)
	var definition := ability.get_definition()
	_expect(definition == ABILITY_DEFINITION, "Player e registry devono usare il Resource di Magno.")
	_expect(registry.resolve_definition(definition.id) == definition, "Il registry deve risolvere l'ID assegnato.")
	_expect(registry.get_compatible_definitions([&"radial"]).has(definition), "Il filtro tag deve includere l'onda radiale.")
	_expect(hud.get_ability_controller() == ability, "L'HUD deve osservare AbilityController.")
	_expect(hud.get_ability_name_text() == "ONDA D'URTO TELLURICA", "L'HUD deve mostrare il nome dati.")
	_expect(hud.get_ability_cooldown_text() == "PRONTA", "L'abilita deve partire pronta.")
	_expect(not hud.get_active_ability_button().disabled, "Il pulsante touch deve partire disponibile.")
	_expect(
		_rect_inside(hud.get_ability_panel_rect(), movement_slice.get_node("ArenaLayout").get_safe_area_rect()),
		"Il pannello abilita deve restare nella safe area."
	)
	_expect(
		not hud.get_active_ability_button_rect().intersects(
			movement_slice.get_touch_joystick_viewport_rect()
		),
		"Pulsante abilita e joystick devono essere separati per il multitouch."
	)

	var inside_enemy := spawner.try_spawn_enemy()
	var outside_enemy := spawner.try_spawn_enemy()
	_expect(inside_enemy != null and outside_enemy != null, "La fixture deve creare due nemici registrati.")
	if inside_enemy == null or outside_enemy == null:
		controller.prepare_restart()
		paused = false
		movement_slice.queue_free()
		await process_frame
		return
	inside_enemy.set_physics_process(false)
	outside_enemy.set_physics_process(false)
	inside_enemy.global_position = player.global_position + Vector2(100.0, 0.0)
	outside_enemy.global_position = player.global_position + Vector2(260.0, 0.0)
	var inside_health := inside_enemy.get_health_component()
	var outside_health := outside_enemy.get_health_component()

	Input.action_release(&"active_ability")
	input_router._process(0.0)
	Input.action_press(&"active_ability")
	input_router._process(0.0)
	input_router._process(0.0)
	Input.action_release(&"active_ability")
	input_router._process(0.0)
	_expect(_activation_count == 1, "Una pressione tastiera deve produrre una sola attivazione.")
	_expect_float_near(
		inside_health.health_current,
		maxf(inside_health.health_max - 20.0, 0.0),
		"Il nemico nel raggio deve subire 20 danni."
	)
	_expect_float_near(
		outside_health.health_current,
		outside_health.health_max,
		"Il nemico fuori raggio non deve subire danno."
	)
	_expect_float_near(inside_enemy.get_knockback_remaining(), 0.2, "Il bersaglio interno deve ricevere knockback.")
	_expect_float_near(outside_enemy.get_knockback_remaining(), 0.0, "Il bersaglio esterno non deve ricevere knockback.")
	_expect(registry.get_last_affected_count() == 1, "Il registry deve contare un solo bersaglio.")
	_expect(registry.get_active_effect_count() == 1, "L'attivazione deve creare un solo effetto leggibile.")
	_expect_float_near(ability.get_cooldown_remaining(), 8.0, "L'attivazione accettata deve avviare il cooldown.")
	_expect(not ability.try_activate(), "Una richiesta durante cooldown deve essere rifiutata.")
	_expect_float_near(ability.get_cooldown_remaining(), 8.0, "Una richiesta rifiutata non deve consumare o riavviare il cooldown.")

	var position_before_knockback := inside_enemy.global_position
	inside_enemy._physics_process(0.1)
	_expect(
		inside_enemy.global_position.x > position_before_knockback.x,
		"Il knockback deve spostare il nemico radialmente lontano dal Player."
	)
	_expect_float_near(inside_enemy.get_knockback_remaining(), 0.1, "Il knockback deve consumare tempo solo in RUNNING.")

	input_router.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	lifecycle.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	_expect(
		controller.get_state() == RunController.RunState.MANUAL_PAUSE,
		"Il focus loss deve tradursi in pausa lifecycle."
	)
	var paused_cooldown := ability.get_cooldown_remaining()
	var paused_knockback := inside_enemy.get_knockback_remaining()
	var paused_position := inside_enemy.global_position
	ability._process(4.0)
	inside_enemy._physics_process(1.0)
	_expect_float_near(ability.get_cooldown_remaining(), paused_cooldown, "Il cooldown deve fermarsi in pausa.")
	_expect_float_near(inside_enemy.get_knockback_remaining(), paused_knockback, "Il knockback deve fermarsi in pausa.")
	_expect(inside_enemy.global_position.is_equal_approx(paused_position), "Il nemico non deve avanzare in pausa.")
	_expect(not input_router.request_active_ability(), "Il touch non deve attraversare la pausa.")
	_expect(hud.get_active_ability_button().disabled, "L'HUD deve disabilitare ATTIVA in pausa.")

	lifecycle.notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	input_router.notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	_expect(lifecycle.request_resume(), "Il lifecycle deve richiedere una ripresa esplicita.")
	input_router._process(0.0)
	ability._process(3.0)
	_expect(controller.request_level_up(), "La fixture deve entrare in LEVEL_UP.")
	var level_up_cooldown := ability.get_cooldown_remaining()
	ability._process(2.0)
	_expect_float_near(ability.get_cooldown_remaining(), level_up_cooldown, "LEVEL_UP deve fermare il cooldown.")
	_expect(controller.complete_level_up(), "La fixture deve chiudere LEVEL_UP.")
	ability._process(level_up_cooldown)
	_expect(ability.is_cooldown_ready(), "Il cooldown deve tornare pronto una volta sola.")
	_expect(_ready_false_count == 1 and _ready_true_count == 1, "La disponibilita deve emettere una transizione per stato.")
	_expect(hud.get_ability_cooldown_text() == "PRONTA", "L'HUD deve sincronizzarsi alla fine del cooldown.")

	var touch_button := hud.get_active_ability_button()
	_expect(
		touch_button.has_signal(&"activation_requested"),
		"Il pulsante gameplay deve usare il percorso touch stateless."
	)
	var joystick := movement_slice.get_node_or_null("UI/SafeAreaRoot/TouchJoystick") as TouchJoystick
	joystick.show()
	var joystick_position := joystick.size * 0.5 + Vector2.RIGHT * joystick.base_radius
	var ability_position := touch_button.get_global_rect().get_center()
	joystick._gui_input(_touch_event(0, true, joystick_position))
	await process_frame
	_expect(joystick.active_finger_index == 0, "Il primo dito deve mantenere il joystick durante l'abilita.")
	await _dispatch_touch_tap(1, ability_position)
	_expect(_activation_count == 2, "Il primo tap multitouch deve attivare l'abilita.")
	_expect_float_near(ability.get_cooldown_remaining(), 8.0, "Il touch deve avviare lo stesso cooldown.")
	ability._process(ability.get_cooldown_remaining())
	_expect(ability.is_cooldown_ready(), "Il cooldown touch deve terminare con il joystick mantenuto.")
	await _dispatch_touch_tap(1, ability_position)
	_expect(_activation_count == 3, "Il secondo tap multitouch deve riattivare l'abilita.")
	_expect(joystick.active_finger_index == 0, "I tap abilita non devono liberare il joystick.")
	joystick._gui_input(_touch_event(0, false, joystick_position))
	await process_frame
	_expect(not joystick.is_active(), "Il rilascio finale deve liberare il joystick.")
	_expect(registry.get_active_effect_count() >= 1, "Un effetto attivo deve esistere prima del restart.")

	_expect(controller.request_defeat(), "La fixture deve raggiungere un terminale.")
	_expect(movement_slice.restart_run(9092), "Il restart composto deve riuscire.")
	await process_frame
	_expect_float_near(ability.get_cooldown_remaining(), 0.0, "Il restart deve azzerare il cooldown.")
	_expect(ability.is_cooldown_ready(), "La seconda run deve partire pronta.")
	_expect(registry.get_active_effect_count() == 0, "Il restart deve svuotare il registry effetti.")
	_expect(effect_parent.get_child_count() == 0, "Nessuna entita abilita deve sopravvivere al restart.")
	_expect(spawner.get_alive_count() == 0, "Il restart deve eliminare i nemici della prima run.")
	_expect(hud.get_ability_cooldown_text() == "PRONTA", "L'HUD deve azzerarsi nella seconda run.")

	var second_run_enemy := spawner.try_spawn_enemy()
	_expect(second_run_enemy != null, "La seconda run deve poter creare un nuovo bersaglio.")
	if second_run_enemy != null:
		second_run_enemy.set_physics_process(false)
		second_run_enemy.global_position = player.global_position + Vector2(80.0, 0.0)
		Input.action_press(&"active_ability")
		input_router._process(0.0)
		input_router._process(0.0)
		Input.action_release(&"active_ability")
		input_router._process(0.0)
		_expect(_activation_count == 4, "La seconda run deve avere una sola connessione input.")
		var second_run_health := second_run_enemy.get_health_component()
		_expect_float_near(
			second_run_health.health_current,
			maxf(second_run_health.health_max - 20.0, 0.0),
			"L'abilita deve funzionare nella seconda run."
		)

	controller.prepare_restart()
	paused = false
	movement_slice.queue_free()
	await process_frame


func _on_ability_activated(_definition: AbilityDefinition) -> void:
	_activation_count += 1


func _on_readiness_changed(is_ready: bool) -> void:
	if is_ready:
		_ready_true_count += 1
	else:
		_ready_false_count += 1


func _rect_inside(rect: Rect2, bounds: Rect2, tolerance: float = 1.0) -> bool:
	return (
		rect.position.x >= bounds.position.x - tolerance
		and rect.position.y >= bounds.position.y - tolerance
		and rect.end.x <= bounds.end.x + tolerance
		and rect.end.y <= bounds.end.y + tolerance
	)


func _expect_float_near(actual: float, expected: float, message: String) -> void:
	_expect(
		absf(actual - expected) <= FLOAT_TOLERANCE,
		"%s Atteso %s, ottenuto %s." % [message, expected, actual]
	)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _wait_processed_frame() -> void:
	await process_frame
	await process_frame


func _dispatch_touch(index: int, pressed: bool, position: Vector2) -> void:
	Input.parse_input_event(_touch_event(index, pressed, position))


func _touch_event(index: int, pressed: bool, position: Vector2) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.pressed = pressed
	event.position = position
	return event


func _dispatch_touch_tap(index: int, position: Vector2) -> void:
	_dispatch_touch(index, true, position)
	await process_frame
	_dispatch_touch(index, false, position)
	await process_frame


func _finish() -> void:
	Input.action_release(&"active_ability")
	paused = false
	await process_frame
	if _failures.is_empty():
		print("B09A_ACTIVE_ABILITY_SMOKE_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	printerr("B09A_ACTIVE_ABILITY_SMOKE_FAIL count=%d" % _failures.size())
	quit(1)
