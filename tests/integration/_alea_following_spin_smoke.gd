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
	_expect(controller != null, "B18F richiede RunController.")
	_expect(player != null, "B18F richiede Player.")
	_expect(ability != null, "B18F richiede AbilityController.")
	_expect(effects != null, "B18F richiede AbilityEffectRegistry.")
	_expect(spawner != null, "B18F richiede EnemySpawner.")
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
	_expect(movement_slice.select_friend_for_next_run(&"alea"), "La fixture deve selezionare Alea.")
	_expect(movement_slice.start_selected_run(1804289383), "La fixture deve avviare Alea.")

	var definition := ability.get_definition()
	_expect(definition != null and definition.id == &"alea_grand_spin", "Alea deve equipaggiare Gran Piroetta.")
	var arena := movement_slice.get_node("ArenaLayout") as ArenaLayout
	player.global_position = arena.get_playfield_center()

	var enemy := spawner.try_spawn_enemy()
	_expect(enemy != null, "Gran Piroetta richiede un bersaglio fixture.")
	if enemy != null:
		enemy.set_physics_process(false)
		enemy.global_position = player.global_position

	_expect(ability.try_activate(), "Gran Piroetta deve attivarsi.")
	var first_effect := _get_latest_area_effect(effects)
	_expect(first_effect != null, "Gran Piroetta deve creare AbilityAreaEffect.")
	if first_effect == null:
		await _finish(movement_slice)
		return
	first_effect.set_process(false)
	_expect(
		first_effect.get_mode() == AbilityAreaEffect.AreaMode.FOLLOWING_PULSE_DAMAGE,
		"Gran Piroetta deve usare la modalita di danno inseguitrice."
	)
	_expect(first_effect.is_following_source(), "Gran Piroetta deve dichiarare il follow del Player.")
	_expect_vector(first_effect.global_position, player.global_position, "L'effetto deve partire centrato sul Player.")

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
	_expect_vector(first_effect.global_position, moved_position, "L'effetto deve seguire il Player durante la durata.")
	_expect(
		enemy == null or enemy.get_health_component().health_current < health_before_follow,
		"Il tick successivo deve colpire attorno alla nuova posizione."
	)

	var paused_duration := first_effect.get_duration_remaining()
	var paused_effect_position := first_effect.global_position
	_expect(controller.request_manual_pause(), "La fixture deve mettere in pausa Gran Piroetta.")
	player.global_position += Vector2(-180.0, 110.0)
	first_effect._process(0.5)
	_expect_vector(first_effect.global_position, paused_effect_position, "La pausa deve congelare la posizione dell'effetto.")
	_expect_float(first_effect.get_duration_remaining(), paused_duration, "La pausa deve congelare la durata.")
	_expect(controller.resume_run(), "La fixture deve riprendere Gran Piroetta.")
	first_effect._process(0.05)
	_expect_vector(first_effect.global_position, player.global_position, "Alla ripresa l'effetto deve ricentrarsi sul Player.")

	first_effect._process(first_effect.get_duration_remaining() + 0.01)
	await process_frame
	_expect(effects.get_active_effect_count() == 0, "La fine della durata deve rimuovere Gran Piroetta.")

	ability._process(ability.get_cooldown_remaining())
	_expect(ability.try_activate(), "Gran Piroetta deve riattivarsi per il test restart.")
	_expect(effects.get_active_effect_count() == 1, "Il secondo effetto deve essere attivo prima del restart.")
	_expect(controller.request_defeat(), "La run deve raggiungere il terminale per il restart.")
	_expect(movement_slice.restart_run(846930886), "Il restart deve avviare una seconda run.")
	await _wait_processed_frame()
	_expect(effects.get_active_effect_count() == 0, "Il restart deve rimuovere Gran Piroetta attiva.")
	_expect(ability.is_cooldown_ready(), "Il restart deve azzerare il cooldown di Alea.")

	_expect(ability.try_activate(), "Gran Piroetta deve attivarsi prima del cambio profilo.")
	_expect(controller.request_defeat(), "La seconda run deve raggiungere il terminale.")
	await process_frame
	var change_button: Button = movement_slice.get_end_screen().get_change_character_button()
	_expect(change_button != null and not change_button.disabled, "Il terminale deve offrire Cambia personaggio.")
	if change_button != null:
		change_button.pressed.emit()
		await process_frame
	_expect(effects.get_active_effect_count() == 0, "Il cambio profilo deve rimuovere Gran Piroetta attiva.")
	_expect(movement_slice.select_friend_for_next_run(&"magno"), "Il selettore deve poter equipaggiare un altro profilo.")

	await _finish(movement_slice)


func _get_latest_area_effect(effects: AbilityEffectRegistry) -> AbilityAreaEffect:
	for index in range(effects.get_active_effects().size() - 1, -1, -1):
		var effect := effects.get_active_effects()[index]
		if effect is AbilityAreaEffect:
			return effect as AbilityAreaEffect
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
		print("B18F_ALEA_FOLLOWING_SPIN_SMOKE_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	printerr("B18F_ALEA_FOLLOWING_SPIN_SMOKE_FAIL count=%d" % _failures.size())
	quit(1)
