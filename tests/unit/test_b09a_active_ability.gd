extends GutGameplayTest

const ABILITY_DEFINITION := preload("res://data/abilities/magno_earthquake_shockwave.tres")
const ACTIVE_ABILITY_FLOAT_TOLERANCE := 0.01

var _activation_count := 0
var _ready_true_count := 0
var _ready_false_count := 0


func test_definition_and_world_units() -> void:
	var definition := ABILITY_DEFINITION as AbilityDefinition
	assert_true(definition != null and definition.is_valid(), "La definizione di Magno deve essere valida.")
	if definition == null:
		return
	assert_eq(definition.id, &"magno_earthquake_shockwave", "L'ID abilita deve essere stabile.")
	assert_eq(
		definition.effect_id, AbilityEffectRegistry.EARTHQUAKE_SHOCKWAVE,
		"Il registry deve riconoscere l'effetto tellurico."
	)
	assert_almost_eq(
		definition.cooldown_seconds, 8.0, ACTIVE_ABILITY_FLOAT_TOLERANCE,
		"Il cooldown dati deve rispettare il PRD."
	)
	assert_almost_eq(
		definition.area_radius, 220.0, ACTIVE_ABILITY_FLOAT_TOLERANCE, "Il raggio dati deve rispettare il PRD."
	)
	assert_almost_eq(definition.damage, 20.0, ACTIVE_ABILITY_FLOAT_TOLERANCE, "Il danno dati deve rispettare il PRD.")
	assert_almost_eq(
		definition.get_effect_float(&"knockback_force"), 300.0, ACTIVE_ABILITY_FLOAT_TOLERANCE,
		"Il knockback deve provenire dai dati."
	)
	assert_almost_eq(
		definition.get_effect_float(&"stun_duration"), 0.2, ACTIVE_ABILITY_FLOAT_TOLERANCE,
		"La durata knockback deve provenire dai dati."
	)

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
		assert_true(
			AbilityEffectRegistry.is_point_within_radius(origin, origin + Vector2(219.0, 0.0), definition.area_radius),
			"Un bersaglio a 219 unita deve restare nel raggio su ogni layout."
		)
		assert_true(
			not AbilityEffectRegistry.is_point_within_radius(origin, origin + Vector2(221.0, 0.0), definition.area_radius),
			"Un bersaglio a 221 unita deve restare fuori dal raggio su ogni layout."
		)


func test_input_map() -> void:
	assert_true(InputMap.has_action(&"active_ability"), "InputMap deve contenere active_ability.")
	var keyboard_found := false
	var controller_found := false
	for event in InputMap.action_get_events(&"active_ability"):
		if event is InputEventKey:
			keyboard_found = (event as InputEventKey).physical_keycode == KEY_SPACE
		elif event is InputEventJoypadButton:
			controller_found = (event as InputEventJoypadButton).button_index == JOY_BUTTON_A
	assert_true(keyboard_found, "Space deve attivare l'abilita.")
	assert_true(controller_found, "Il face button sud deve attivare l'abilita.")


func test_composed_ability() -> void:
	_activation_count = 0
	_ready_true_count = 0
	_ready_false_count = 0

	var movement_slice := await instantiate_movement_slice()

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

	assert_true(controller != null, "B09A richiede RunController.")
	assert_true(spawner != null, "B09A richiede EnemySpawner.")
	assert_true(targeting != null, "B09A richiede TargetingSystem.")
	assert_true(player != null, "B09A richiede Player.")
	assert_true(input_router != null, "B09A richiede InputRouter.")
	assert_true(lifecycle != null, "B09A richiede PlatformLifecycle.")
	assert_true(ability != null, "B09A richiede AbilityController.")
	assert_true(registry != null, "B09A richiede AbilityEffectRegistry.")
	assert_true(effect_parent != null, "B09A richiede un contenitore effetti scene-local.")
	assert_true(hud != null, "B09A richiede il feedback HUD.")
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
	assert_true(definition == ABILITY_DEFINITION, "Player e registry devono usare il Resource di Magno.")
	assert_true(
		registry.resolve_definition(definition.id) == definition, "Il registry deve risolvere l'ID assegnato."
	)
	assert_true(
		registry.get_compatible_definitions([&"radial"]).has(definition),
		"Il filtro tag deve includere l'onda radiale."
	)
	assert_true(hud.get_ability_controller() == ability, "L'HUD deve osservare AbilityController.")
	assert_eq(hud.get_ability_name_text(), "ONDA D'URTO TELLURICA", "L'HUD deve mostrare il nome dati.")
	assert_eq(hud.get_ability_cooldown_text(), "PRONTA", "L'abilita deve partire pronta.")
	assert_true(not hud.get_active_ability_button().disabled, "Il pulsante touch deve partire disponibile.")
	assert_rect_inside(
		hud.get_ability_panel_rect(),
		movement_slice.get_node("ArenaLayout").get_safe_area_rect(),
		"Il pannello abilita deve restare nella safe area.",
		1.0
	)
	assert_true(
		not hud.get_active_ability_button_rect().intersects(movement_slice.get_touch_joystick_viewport_rect()),
		"Pulsante abilita e joystick devono essere separati per il multitouch."
	)

	var inside_enemy := spawner.try_spawn_enemy()
	var outside_enemy := spawner.try_spawn_enemy()
	assert_true(inside_enemy != null and outside_enemy != null, "La fixture deve creare due nemici registrati.")
	if inside_enemy == null or outside_enemy == null:
		controller.prepare_restart()
		return
	inside_enemy.set_physics_process(false)
	outside_enemy.set_physics_process(false)
	inside_enemy.global_position = player.global_position + Vector2(100.0, 0.0)
	outside_enemy.global_position = player.global_position + Vector2(260.0, 0.0)
	var inside_health := inside_enemy.get_health_component()
	var outside_health := outside_enemy.get_health_component()
	# La fixture isola l'effetto knockback dal bilanciamento B37 della vita
	# base: senza margine, i 20 danni fissi dell'abilita' ucciderebbero il
	# nemico prima che il test possa osservare knockback e pausa.
	inside_health.health_max = 100.0
	inside_health.reset_to_max()

	Input.action_release(&"active_ability")
	input_router._process(0.0)
	Input.action_press(&"active_ability")
	input_router._process(0.0)
	input_router._process(0.0)
	Input.action_release(&"active_ability")
	input_router._process(0.0)
	assert_eq(_activation_count, 1, "Una pressione tastiera deve produrre una sola attivazione.")
	assert_almost_eq(
		inside_health.health_current, maxf(inside_health.health_max - 20.0, 0.0), ACTIVE_ABILITY_FLOAT_TOLERANCE,
		"Il nemico nel raggio deve subire 20 danni."
	)
	assert_almost_eq(
		outside_health.health_current, outside_health.health_max, ACTIVE_ABILITY_FLOAT_TOLERANCE,
		"Il nemico fuori raggio non deve subire danno."
	)
	assert_almost_eq(
		inside_enemy.get_knockback_remaining(), 0.2, ACTIVE_ABILITY_FLOAT_TOLERANCE,
		"Il bersaglio interno deve ricevere knockback."
	)
	assert_almost_eq(
		outside_enemy.get_knockback_remaining(), 0.0, ACTIVE_ABILITY_FLOAT_TOLERANCE,
		"Il bersaglio esterno non deve ricevere knockback."
	)
	assert_eq(registry.get_last_affected_count(), 1, "Il registry deve contare un solo bersaglio.")
	assert_eq(registry.get_active_effect_count(), 1, "L'attivazione deve creare un solo effetto leggibile.")
	assert_almost_eq(
		ability.get_cooldown_remaining(), 8.0, ACTIVE_ABILITY_FLOAT_TOLERANCE,
		"L'attivazione accettata deve avviare il cooldown."
	)
	assert_true(not ability.try_activate(), "Una richiesta durante cooldown deve essere rifiutata.")
	assert_almost_eq(
		ability.get_cooldown_remaining(), 8.0, ACTIVE_ABILITY_FLOAT_TOLERANCE,
		"Una richiesta rifiutata non deve consumare o riavviare il cooldown."
	)

	var position_before_knockback := inside_enemy.global_position
	inside_enemy._physics_process(0.1)
	assert_true(
		inside_enemy.global_position.x > position_before_knockback.x,
		"Il knockback deve spostare il nemico radialmente lontano dal Player."
	)
	assert_almost_eq(
		inside_enemy.get_knockback_remaining(), 0.1, ACTIVE_ABILITY_FLOAT_TOLERANCE,
		"Il knockback deve consumare tempo solo in RUNNING."
	)

	input_router.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	lifecycle.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_eq(
		controller.get_state(), RunController.RunState.MANUAL_PAUSE,
		"Il focus loss deve tradursi in pausa lifecycle."
	)
	var paused_cooldown := ability.get_cooldown_remaining()
	var paused_knockback := inside_enemy.get_knockback_remaining()
	var paused_position := inside_enemy.global_position
	ability._process(4.0)
	inside_enemy._physics_process(1.0)
	assert_almost_eq(
		ability.get_cooldown_remaining(), paused_cooldown, ACTIVE_ABILITY_FLOAT_TOLERANCE,
		"Il cooldown deve fermarsi in pausa."
	)
	assert_almost_eq(
		inside_enemy.get_knockback_remaining(), paused_knockback, ACTIVE_ABILITY_FLOAT_TOLERANCE,
		"Il knockback deve fermarsi in pausa."
	)
	assert_true(inside_enemy.global_position.is_equal_approx(paused_position), "Il nemico non deve avanzare in pausa.")
	assert_true(not input_router.request_active_ability(), "Il touch non deve attraversare la pausa.")
	assert_true(hud.get_active_ability_button().disabled, "L'HUD deve disabilitare ATTIVA in pausa.")

	lifecycle.notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	input_router.notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	assert_true(lifecycle.request_resume(), "Il lifecycle deve richiedere una ripresa esplicita.")
	input_router._process(0.0)
	ability._process(3.0)
	assert_true(controller.request_level_up(), "La fixture deve entrare in LEVEL_UP.")
	var level_up_cooldown := ability.get_cooldown_remaining()
	ability._process(2.0)
	assert_almost_eq(
		ability.get_cooldown_remaining(), level_up_cooldown, ACTIVE_ABILITY_FLOAT_TOLERANCE,
		"LEVEL_UP deve fermare il cooldown."
	)
	assert_true(controller.complete_level_up(), "La fixture deve chiudere LEVEL_UP.")
	ability._process(level_up_cooldown)
	assert_true(ability.is_cooldown_ready(), "Il cooldown deve tornare pronto una volta sola.")
	assert_true(
		_ready_false_count == 1 and _ready_true_count == 1,
		"La disponibilita deve emettere una transizione per stato."
	)
	assert_eq(hud.get_ability_cooldown_text(), "PRONTA", "L'HUD deve sincronizzarsi alla fine del cooldown.")

	var touch_button := hud.get_active_ability_button()
	assert_true(
		touch_button.has_signal(&"activation_requested"), "Il pulsante gameplay deve usare il percorso touch stateless."
	)
	var joystick := movement_slice.get_node_or_null("UI/SafeAreaRoot/TouchJoystick") as TouchJoystick
	joystick.show()
	var joystick_position := joystick.size * 0.5 + Vector2.RIGHT * joystick.base_radius
	var ability_position := touch_button.get_global_rect().get_center()
	joystick._gui_input(make_touch_event(0, true, joystick_position))
	await wait_process_frames(1)
	assert_eq(joystick.active_finger_index, 0, "Il primo dito deve mantenere il joystick durante l'abilita.")
	await _dispatch_touch_tap(1, ability_position)
	assert_eq(_activation_count, 2, "Il primo tap multitouch deve attivare l'abilita.")
	assert_almost_eq(
		ability.get_cooldown_remaining(), 8.0, ACTIVE_ABILITY_FLOAT_TOLERANCE, "Il touch deve avviare lo stesso cooldown."
	)
	ability._process(ability.get_cooldown_remaining())
	assert_true(ability.is_cooldown_ready(), "Il cooldown touch deve terminare con il joystick mantenuto.")
	await _dispatch_touch_tap(1, ability_position)
	assert_eq(_activation_count, 3, "Il secondo tap multitouch deve riattivare l'abilita.")
	assert_eq(joystick.active_finger_index, 0, "I tap abilita non devono liberare il joystick.")
	joystick._gui_input(make_touch_event(0, false, joystick_position))
	await wait_process_frames(1)
	assert_true(not joystick.is_active(), "Il rilascio finale deve liberare il joystick.")
	assert_true(registry.get_active_effect_count() >= 1, "Un effetto attivo deve esistere prima del restart.")

	assert_true(controller.request_defeat(), "La fixture deve raggiungere un terminale.")
	assert_true(movement_slice.restart_run(9092), "Il restart composto deve riuscire.")
	await wait_process_frames(1)
	assert_almost_eq(
		ability.get_cooldown_remaining(), 0.0, ACTIVE_ABILITY_FLOAT_TOLERANCE, "Il restart deve azzerare il cooldown."
	)
	assert_true(ability.is_cooldown_ready(), "La seconda run deve partire pronta.")
	assert_eq(registry.get_active_effect_count(), 0, "Il restart deve svuotare il registry effetti.")
	assert_eq(effect_parent.get_child_count(), 0, "Nessuna entita abilita deve sopravvivere al restart.")
	assert_eq(spawner.get_alive_count(), 0, "Il restart deve eliminare i nemici della prima run.")
	assert_eq(hud.get_ability_cooldown_text(), "PRONTA", "L'HUD deve azzerarsi nella seconda run.")

	var second_run_enemy := spawner.try_spawn_enemy()
	assert_true(second_run_enemy != null, "La seconda run deve poter creare un nuovo bersaglio.")
	if second_run_enemy != null:
		second_run_enemy.set_physics_process(false)
		second_run_enemy.global_position = player.global_position + Vector2(80.0, 0.0)
		Input.action_press(&"active_ability")
		input_router._process(0.0)
		input_router._process(0.0)
		Input.action_release(&"active_ability")
		input_router._process(0.0)
		assert_eq(_activation_count, 4, "La seconda run deve avere una sola connessione input.")
		var second_run_health := second_run_enemy.get_health_component()
		assert_almost_eq(
			second_run_health.health_current, maxf(second_run_health.health_max - 20.0, 0.0),
			ACTIVE_ABILITY_FLOAT_TOLERANCE, "L'abilita deve funzionare nella seconda run."
		)

	controller.prepare_restart()
	Input.action_release(&"active_ability")


func _on_ability_activated(_definition: AbilityDefinition) -> void:
	_activation_count += 1


func _on_readiness_changed(is_ready: bool) -> void:
	if is_ready:
		_ready_true_count += 1
	else:
		_ready_false_count += 1


func _dispatch_touch_tap(index: int, position: Vector2) -> void:
	Input.parse_input_event(make_touch_event(index, true, position))
	await wait_process_frames(1)
	Input.parse_input_event(make_touch_event(index, false, position))
	await wait_process_frames(1)
