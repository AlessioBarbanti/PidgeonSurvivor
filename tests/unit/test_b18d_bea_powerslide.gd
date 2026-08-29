extends GutGameplayTest

const POWERSLIDE_POSITION_TOLERANCE := 0.01


func test_bea_powerslide_teleports_and_restarts() -> void:
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_run_controller() as RunController
	var player := movement_slice.get_player() as Player
	var ability := movement_slice.get_ability_controller() as AbilityController
	var effects := movement_slice.get_ability_effect_registry() as AbilityEffectRegistry
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	var weapon := movement_slice.get_weapon_controller() as WeaponController
	assert_not_null(controller, "B18D richiede RunController.")
	assert_not_null(player, "B18D richiede Player.")
	assert_not_null(ability, "B18D richiede AbilityController.")
	assert_not_null(effects, "B18D richiede AbilityEffectRegistry.")
	assert_not_null(spawner, "B18D richiede EnemySpawner.")
	if controller == null or player == null or ability == null or effects == null or spawner == null:
		return

	controller.set_process(false)
	player.set_physics_process(false)
	ability.set_process(false)
	spawner.set_process(false)
	if weapon != null:
		weapon.set_process(false)

	assert_true(controller.request_defeat(), "La fixture deve chiudere la run iniziale.")
	controller.prepare_restart()
	assert_true(movement_slice.select_friend_for_next_run(&"bea"), "La fixture deve selezionare Bea.")
	assert_true(movement_slice.start_selected_run(1804289383), "La fixture deve avviare Bea.")

	var definition := ability.get_definition()
	assert_true(definition != null and definition.title == "Powerslide", "Il nome runtime deve essere Powerslide.")
	assert_true(definition != null and definition.duration_seconds == 4.0, "La scia deve durare 4 secondi.")
	assert_true(
		definition != null and not definition.effect_parameters.has(&"slide_speed"),
		"Powerslide non deve richiedere un parametro di velocita progressiva."
	)
	assert_true(
		definition != null
		and definition.icon != null
		and definition.icon.resource_path == "res://assets/art/icons/abilities/generated/powerslide.png",
		"Powerslide deve usare l'icona inline-skate dedicata."
	)
	if definition == null:
		return

	var arena := movement_slice.get_node("ArenaLayout") as ArenaLayout
	player.global_position = arena.get_playfield_center()
	player.set_movement_input(Vector2(-0.6, -0.8))
	player.clear_movement_input()
	assert_vector_near(
		player.get_facing_direction(), Vector2.LEFT, "Il neutro deve conservare il lato sinistro.", POWERSLIDE_POSITION_TOLERANCE
	)
	assert_vector_near(
		player.get_last_movement_direction(),
		Vector2(-0.6, -0.8),
		"Il neutro deve conservare la direzione vettoriale.",
		POWERSLIDE_POSITION_TOLERANCE
	)
	var first_origin := player.global_position

	var enemy := spawner.try_spawn_enemy()
	assert_not_null(enemy, "Powerslide richiede un bersaglio fixture.")
	var health_before := 0.0
	if enemy != null:
		enemy.set_physics_process(false)
		enemy.global_position = first_origin
		health_before = enemy.get_health_component().health_current

	assert_true(ability.try_activate(), "Powerslide deve attivarsi da neutro.")
	var first_effect := _get_latest_powerslide(effects)
	assert_not_null(first_effect, "Powerslide deve creare FireZTrail scene-local.")
	if first_effect == null:
		return
	first_effect.set_process(false)
	var first_endpoint := first_effect.get_path_points()[-1]
	assert_eq(first_effect.get_path_points().size(), 2, "La scia deve essere una linea retta.")
	assert_true(first_endpoint.x < first_origin.x, "La traiettoria deve usare l'ultima direzione sinistra.")
	assert_true(first_endpoint.y < first_origin.y, "La traiettoria deve usare anche la componente verticale.")
	assert_vector_near(
		player.global_position,
		first_endpoint,
		"Powerslide deve teletrasportare il Player al termine della linea.",
		POWERSLIDE_POSITION_TOLERANCE
	)
	assert_true(
		enemy == null or enemy.get_health_component().health_current < health_before, "La scia deve applicare il tick iniziale."
	)

	var teleported_position := player.global_position
	var initial_duration := first_effect.get_duration_remaining()
	first_effect._process(0.1)
	assert_vector_near(
		player.global_position,
		teleported_position,
		"La posizione teletrasportata non deve avanzare durante la scia.",
		POWERSLIDE_POSITION_TOLERANCE
	)
	assert_true(first_effect.get_duration_remaining() < initial_duration, "La durata della scia deve avanzare.")
	player.set_movement_input(Vector2.RIGHT)
	first_effect._process(0.1)
	assert_vector_near(
		player.global_position,
		teleported_position,
		"Il joystick dopo il teletrasporto non deve spostare il Player nella scia.",
		POWERSLIDE_POSITION_TOLERANCE
	)

	var paused_duration := first_effect.get_duration_remaining()
	assert_true(controller.request_manual_pause(), "La fixture deve mettere in pausa Powerslide.")
	first_effect._process(1.0)
	assert_almost_eq(first_effect.get_duration_remaining(), paused_duration, FLOAT_TOLERANCE, "La pausa deve fermare la durata.")
	assert_true(controller.resume_run(), "La fixture deve riprendere esplicitamente.")

	first_effect._process(1.0)
	assert_true(first_effect.get_trail_duration_remaining() < 4.0, "Il delta residuo deve consumare la scia.")

	player.clear_movement_input()
	assert_true(controller.request_defeat(), "La prima run deve raggiungere il terminale.")
	assert_true(movement_slice.restart_run(846930886), "Il restart deve avviare una seconda run.")
	await wait_process_frames(2)
	assert_eq(effects.get_active_effect_count(), 0, "Il restart deve rimuovere la scia precedente.")
	assert_true(ability.is_cooldown_ready(), "La seconda run deve ripartire con Powerslide pronta.")

	player.global_position = arena.get_playfield_center()
	player.set_movement_input(Vector2(0.6, 0.8))
	player.clear_movement_input()
	var second_origin := player.global_position
	assert_true(ability.try_activate(), "Powerslide deve riattivarsi nella seconda run.")
	var second_effect := _get_latest_powerslide(effects)
	assert_not_null(second_effect, "La seconda run deve creare un nuovo effetto.")
	if second_effect != null:
		second_effect.set_process(false)
		assert_true(player.global_position.x > second_origin.x, "La seconda run deve usare la nuova direzione destra.")
		assert_true(player.global_position.y > second_origin.y, "La seconda run deve usare la componente verticale.")
		assert_vector_near(
			player.global_position,
			second_effect.get_path_points()[-1],
			"La seconda run deve teletrasportare al termine della linea.",
			POWERSLIDE_POSITION_TOLERANCE
		)


func _get_latest_powerslide(effects: AbilityEffectRegistry) -> FireZTrail:
	for index in range(effects.get_active_effects().size() - 1, -1, -1):
		var effect := effects.get_active_effects()[index]
		if effect is FireZTrail:
			return effect as FireZTrail
	return null
