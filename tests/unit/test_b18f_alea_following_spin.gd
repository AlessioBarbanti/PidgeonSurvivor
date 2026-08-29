extends GutGameplayTest

const POSITION_TOLERANCE := 0.01
const SPIN_FLOAT_TOLERANCE := 0.001


func test_alea_grand_spin_follows_player_through_pause_and_restart() -> void:
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_run_controller() as RunController
	var player := movement_slice.get_player() as Player
	var ability := movement_slice.get_ability_controller() as AbilityController
	var effects := movement_slice.get_ability_effect_registry() as AbilityEffectRegistry
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	var weapon := movement_slice.get_weapon_controller() as WeaponController
	assert_not_null(controller, "B18F richiede RunController.")
	assert_not_null(player, "B18F richiede Player.")
	assert_not_null(ability, "B18F richiede AbilityController.")
	assert_not_null(effects, "B18F richiede AbilityEffectRegistry.")
	assert_not_null(spawner, "B18F richiede EnemySpawner.")
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
	assert_true(movement_slice.select_friend_for_next_run(&"alea"), "La fixture deve selezionare Alea.")
	assert_true(movement_slice.start_selected_run(1804289383), "La fixture deve avviare Alea.")

	var definition := ability.get_definition()
	assert_true(
		definition != null and definition.id == &"alea_grand_spin", "Alea deve equipaggiare Gran Piroetta."
	)
	var arena := movement_slice.get_node("ArenaLayout") as ArenaLayout
	player.global_position = arena.get_playfield_center()

	var enemy := spawner.try_spawn_enemy()
	assert_not_null(enemy, "Gran Piroetta richiede un bersaglio fixture.")
	if enemy != null:
		enemy.set_physics_process(false)
		enemy.global_position = player.global_position

	assert_true(ability.try_activate(), "Gran Piroetta deve attivarsi.")
	var first_effect := _get_latest_area_effect(effects)
	assert_not_null(first_effect, "Gran Piroetta deve creare AbilityAreaEffect.")
	if first_effect == null:
		return
	first_effect.set_process(false)
	assert_eq(
		first_effect.get_mode(),
		AbilityAreaEffect.AreaMode.FOLLOWING_PULSE_DAMAGE,
		"Gran Piroetta deve usare la modalita di danno inseguitrice."
	)
	assert_true(first_effect.is_following_source(), "Gran Piroetta deve dichiarare il follow del Player.")
	assert_vector_near(
		first_effect.global_position, player.global_position, "L'effetto deve partire centrato sul Player.", POSITION_TOLERANCE
	)

	var moved_position := player.global_position + Vector2(120.0, -70.0)
	player.global_position = moved_position
	var health_before_follow := (
		enemy.get_health_component().health_current
		if enemy != null
		else 0.0
	)
	if enemy != null:
		enemy.global_position = moved_position
	first_effect._process(0.1)
	assert_vector_near(
		first_effect.global_position, moved_position, "L'effetto deve seguire il Player durante la durata.", POSITION_TOLERANCE
	)
	assert_true(
		enemy == null or enemy.get_health_component().health_current < health_before_follow,
		"Il tick successivo deve colpire attorno alla nuova posizione."
	)

	var paused_duration := first_effect.get_duration_remaining()
	var paused_effect_position := first_effect.global_position
	assert_true(controller.request_manual_pause(), "La fixture deve mettere in pausa Gran Piroetta.")
	player.global_position += Vector2(-180.0, 110.0)
	first_effect._process(0.5)
	assert_vector_near(
		first_effect.global_position, paused_effect_position, "La pausa deve congelare la posizione dell'effetto.", POSITION_TOLERANCE
	)
	assert_almost_eq(
		first_effect.get_duration_remaining(), paused_duration, SPIN_FLOAT_TOLERANCE, "La pausa deve congelare la durata."
	)
	assert_true(controller.resume_run(), "La fixture deve riprendere Gran Piroetta.")
	first_effect._process(0.05)
	assert_vector_near(
		first_effect.global_position, player.global_position, "Alla ripresa l'effetto deve ricentrarsi sul Player.", POSITION_TOLERANCE
	)

	first_effect._process(first_effect.get_duration_remaining() + 0.01)
	await wait_process_frames(1)
	assert_eq(effects.get_active_effect_count(), 0, "La fine della durata deve rimuovere Gran Piroetta.")

	ability._process(ability.get_cooldown_remaining())
	assert_true(ability.try_activate(), "Gran Piroetta deve riattivarsi per il test restart.")
	assert_eq(effects.get_active_effect_count(), 1, "Il secondo effetto deve essere attivo prima del restart.")
	assert_true(controller.request_defeat(), "La run deve raggiungere il terminale per il restart.")
	assert_true(movement_slice.restart_run(846930886), "Il restart deve avviare una seconda run.")
	await wait_process_frames(2)
	assert_eq(effects.get_active_effect_count(), 0, "Il restart deve rimuovere Gran Piroetta attiva.")
	assert_true(ability.is_cooldown_ready(), "Il restart deve azzerare il cooldown di Alea.")

	assert_true(ability.try_activate(), "Gran Piroetta deve attivarsi prima del cambio profilo.")
	assert_true(controller.request_defeat(), "La seconda run deve raggiungere il terminale.")
	await wait_process_frames(1)
	var change_button: Button = movement_slice.get_end_screen().get_change_character_button()
	assert_true(
		change_button != null and not change_button.disabled, "Il terminale deve offrire Cambia personaggio."
	)
	if change_button != null:
		change_button.pressed.emit()
		await wait_process_frames(1)
	assert_eq(effects.get_active_effect_count(), 0, "Il cambio profilo deve rimuovere Gran Piroetta attiva.")
	assert_true(
		movement_slice.select_friend_for_next_run(&"magno"), "Il selettore deve poter equipaggiare un altro profilo."
	)


func _get_latest_area_effect(effects: AbilityEffectRegistry) -> AbilityAreaEffect:
	for index in range(effects.get_active_effects().size() - 1, -1, -1):
		var effect := effects.get_active_effects()[index]
		if effect is AbilityAreaEffect:
			return effect as AbilityAreaEffect
	return null
