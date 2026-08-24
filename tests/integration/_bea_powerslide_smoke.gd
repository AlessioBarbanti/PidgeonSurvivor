extends SceneTree

const MOVEMENT_SLICE_SCENE := preload("res://scenes/game/movement_slice.tscn")
const TEST_VIEWPORT_SIZE := Vector2i(1280, 720)
const POSITION_TOLERANCE := 0.01
const FLOAT_TOLERANCE := 0.001

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	paused = false
	root.content_scale_size = TEST_VIEWPORT_SIZE
	root.size = TEST_VIEWPORT_SIZE
	await _wait_processed_frame()

	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	root.add_child(movement_slice)
	await _wait_processed_frame()

	var controller := movement_slice.get_run_controller() as RunController
	var player := movement_slice.get_player() as Player
	var ability := movement_slice.get_ability_controller() as AbilityController
	var effects := movement_slice.get_ability_effect_registry() as AbilityEffectRegistry
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	var weapon := movement_slice.get_weapon_controller() as WeaponController
	_expect(controller != null, "B18D richiede RunController.")
	_expect(player != null, "B18D richiede Player.")
	_expect(ability != null, "B18D richiede AbilityController.")
	_expect(effects != null, "B18D richiede AbilityEffectRegistry.")
	_expect(spawner != null, "B18D richiede EnemySpawner.")
	if controller == null or player == null or ability == null or effects == null or spawner == null:
		await _finish(movement_slice)
		return

	controller.set_process(false)
	player.set_physics_process(false)
	ability.set_process(false)
	spawner.set_process(false)
	if weapon != null:
		weapon.set_process(false)

	_expect(controller.request_defeat(), "La fixture deve chiudere la run iniziale.")
	controller.prepare_restart()
	_expect(movement_slice.select_friend_for_next_run(&"bea"), "La fixture deve selezionare Bea.")
	_expect(movement_slice.start_selected_run(1804289383), "La fixture deve avviare Bea.")

	var definition := ability.get_definition()
	_expect(definition != null and definition.title == "Powerslide", "Il nome runtime deve essere Powerslide.")
	_expect(definition != null and definition.duration_seconds == 4.0, "La scia deve durare 4 secondi.")
	_expect(
		definition != null and not definition.effect_parameters.has(&"slide_speed"),
		"Powerslide non deve richiedere un parametro di velocita progressiva."
	)
	_expect(
		definition != null
		and definition.icon != null
		and definition.icon.resource_path == "res://assets/art/icons/abilities/generated/powerslide.png",
		"Powerslide deve usare l'icona inline-skate dedicata."
	)
	if definition == null:
		await _finish(movement_slice)
		return

	var arena := movement_slice.get_node("ArenaLayout") as ArenaLayout
	player.global_position = arena.get_playfield_center()
	player.set_movement_input(Vector2(-0.6, -0.8))
	player.clear_movement_input()
	_expect_vector(player.get_facing_direction(), Vector2.LEFT, "Il neutro deve conservare il lato sinistro.")
	_expect_vector(player.get_last_movement_direction(), Vector2(-0.6, -0.8), "Il neutro deve conservare la direzione vettoriale.")
	var first_origin := player.global_position

	var enemy := spawner.try_spawn_enemy()
	_expect(enemy != null, "Powerslide richiede un bersaglio fixture.")
	var health_before := 0.0
	if enemy != null:
		enemy.set_physics_process(false)
		enemy.global_position = first_origin
		health_before = enemy.get_health_component().health_current

	_expect(ability.try_activate(), "Powerslide deve attivarsi da neutro.")
	var first_effect := _get_latest_powerslide(effects)
	_expect(first_effect != null, "Powerslide deve creare FireZTrail scene-local.")
	if first_effect == null:
		await _finish(movement_slice)
		return
	first_effect.set_process(false)
	var first_endpoint := first_effect.get_path_points()[-1]
	_expect(first_effect.get_path_points().size() == 2, "La scia deve essere una linea retta.")
	_expect(first_endpoint.x < first_origin.x, "La traiettoria deve usare l'ultima direzione sinistra.")
	_expect(first_endpoint.y < first_origin.y, "La traiettoria deve usare anche la componente verticale.")
	_expect_vector(player.global_position, first_endpoint, "Powerslide deve teletrasportare il Player al termine della linea.")
	_expect(enemy == null or enemy.get_health_component().health_current < health_before, "La scia deve applicare il tick iniziale.")

	var teleported_position := player.global_position
	var initial_duration := first_effect.get_duration_remaining()
	first_effect._process(0.1)
	_expect_vector(player.global_position, teleported_position, "La posizione teletrasportata non deve avanzare durante la scia.")
	_expect(first_effect.get_duration_remaining() < initial_duration, "La durata della scia deve avanzare.")
	player.set_movement_input(Vector2.RIGHT)
	first_effect._process(0.1)
	_expect_vector(player.global_position, teleported_position, "Il joystick dopo il teletrasporto non deve spostare il Player nella scia.")

	var paused_duration := first_effect.get_duration_remaining()
	_expect(controller.request_manual_pause(), "La fixture deve mettere in pausa Powerslide.")
	first_effect._process(1.0)
	_expect_float(first_effect.get_duration_remaining(), paused_duration, "La pausa deve fermare la durata.")
	_expect(controller.resume_run(), "La fixture deve riprendere esplicitamente.")

	first_effect._process(1.0)
	_expect(first_effect.get_trail_duration_remaining() < 4.0, "Il delta residuo deve consumare la scia.")

	player.clear_movement_input()
	_expect(controller.request_defeat(), "La prima run deve raggiungere il terminale.")
	_expect(movement_slice.restart_run(846930886), "Il restart deve avviare una seconda run.")
	await _wait_processed_frame()
	_expect(effects.get_active_effect_count() == 0, "Il restart deve rimuovere la scia precedente.")
	_expect(ability.is_cooldown_ready(), "La seconda run deve ripartire con Powerslide pronta.")

	player.global_position = arena.get_playfield_center()
	player.set_movement_input(Vector2(0.6, 0.8))
	player.clear_movement_input()
	var second_origin := player.global_position
	_expect(ability.try_activate(), "Powerslide deve riattivarsi nella seconda run.")
	var second_effect := _get_latest_powerslide(effects)
	_expect(second_effect != null, "La seconda run deve creare un nuovo effetto.")
	if second_effect != null:
		second_effect.set_process(false)
		_expect(player.global_position.x > second_origin.x, "La seconda run deve usare la nuova direzione destra.")
		_expect(player.global_position.y > second_origin.y, "La seconda run deve usare la componente verticale.")
		_expect_vector(player.global_position, second_effect.get_path_points()[-1], "La seconda run deve teletrasportare al termine della linea.")

	await _finish(movement_slice)


func _get_latest_powerslide(effects: AbilityEffectRegistry) -> FireZTrail:
	for index in range(effects.get_active_effects().size() - 1, -1, -1):
		var effect := effects.get_active_effects()[index]
		if effect is FireZTrail:
			return effect as FireZTrail
	return null


func _wait_processed_frame() -> void:
	await process_frame
	await process_frame


func _expect_vector(actual: Vector2, expected: Vector2, message: String) -> void:
	_expect(
		actual.distance_to(expected) <= POSITION_TOLERANCE,
		"%s Atteso %s, ottenuto %s." % [message, expected, actual]
	)


func _expect_float(actual: float, expected: float, message: String) -> void:
	_expect(
		absf(actual - expected) <= FLOAT_TOLERANCE,
		"%s Atteso %.3f, ottenuto %.3f." % [message, expected, actual]
	)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish(movement_slice: Control) -> void:
	paused = false
	if is_instance_valid(movement_slice):
		movement_slice.queue_free()
	await process_frame
	if _failures.is_empty():
		print("B18D_BEA_POWERSLIDE_SMOKE_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	printerr("B18D_BEA_POWERSLIDE_SMOKE_FAIL count=%d" % _failures.size())
	quit(1)
