extends SceneTree

const MOVEMENT_SLICE_SCENE := preload("res://scenes/game/movement_slice.tscn")
const TEST_VIEWPORT_SIZE := Vector2i(1280, 720)

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

	var player := movement_slice.get_node_or_null("World/Player") as Player
	var controller := movement_slice.get_node_or_null("RunController") as RunController
	var friend_registry := movement_slice.get_node_or_null("FriendRegistry") as FriendRegistry
	_expect(player != null, "Il vertical slice deve contenere il Player.")
	_expect(controller != null, "Il vertical slice deve contenere RunController.")
	_expect(friend_registry != null, "Il vertical slice deve contenere FriendRegistry.")
	if player == null or controller == null or friend_registry == null:
		await _finish(movement_slice)
		return

	_validate_roster_animation_data(friend_registry)
	player.set_physics_process(false)
	var definition := player.get_friend_definition()
	var idle_texture := definition.get_gameplay_idle_right()
	var walk_frames := definition.get_gameplay_walk_right_frames()

	_expect_vector(player.get_facing_direction(), Vector2.RIGHT, "La run deve partire rivolta a destra.")
	_expect(not player.is_character_walking(), "Il Player neutro deve mostrare la posa ferma.")
	_expect(player.get_character_texture() == idle_texture, "La posa ferma deve usare lo sprite idle laterale.")
	_expect(not player.is_character_flipped_horizontally(), "Lo sprite destro non deve essere ribaltato.")

	player.set_movement_input(Vector2.LEFT)
	_expect_vector(player.get_facing_direction(), Vector2.LEFT, "Un movimento a sinistra deve aggiornare l'ultima direzione.")
	_expect(player.is_character_walking(), "Un input non nullo deve avviare la camminata.")
	_expect(player.is_character_flipped_horizontally(), "La direzione sinistra deve ribaltare lo sprite laterale.")
	_expect(player.get_character_texture() == walk_frames[0], "La camminata deve partire dal primo frame dati.")
	player._physics_process(1.0 / definition.gameplay_walk_fps + 0.001)
	_expect(player.get_character_walk_frame_index() == 1, "La camminata deve avanzare al frame successivo.")
	_expect(player.get_character_texture() == walk_frames[1], "Il cambio frame deve aggiornare la texture visibile.")
	_expect(player.get_character_visual_offset() == Vector2(0.0, -2.0), "Il passo deve applicare un bob visibile.")

	player.clear_movement_input()
	_expect_vector(player.get_facing_direction(), Vector2.LEFT, "Il neutro deve conservare l'ultima direzione valida.")
	_expect(not player.is_character_walking(), "Il neutro deve fermare l'animazione.")
	_expect(player.get_character_texture() == idle_texture, "Il neutro deve ripristinare la posa ferma.")
	_expect(player.is_character_flipped_horizontally(), "La posa ferma deve restare rivolta a sinistra.")
	_expect(player.get_character_visual_offset() == Vector2.ZERO, "La posa ferma non deve conservare il bob.")
	_expect(is_zero_approx(player.get_character_visual_rotation()), "La posa ferma non deve restare inclinata.")

	player.set_movement_input(Vector2.UP)
	_expect_vector(player.get_facing_direction(), Vector2.LEFT, "Il movimento verticale non deve inventare una nuova direzione laterale.")
	_expect(player.is_character_walking(), "Il movimento verticale deve comunque animare la camminata.")
	player.set_movement_input(Vector2(0.7, -0.7))
	_expect_vector(player.get_facing_direction(), Vector2.RIGHT, "Una diagonale deve usare il segno della componente orizzontale.")
	_expect(not player.is_character_flipped_horizontally(), "Il ritorno a destra deve rimuovere il flip.")

	player.clear_movement_input()
	_expect(controller.request_manual_pause(), "La fixture deve entrare in pausa manuale.")
	_expect_vector(player.get_facing_direction(), Vector2.RIGHT, "La pausa con input neutro deve conservare l'ultima direzione.")
	_expect(controller.resume_run(), "La fixture deve riprendere esplicitamente.")
	player.set_movement_input(Vector2.LEFT)
	player.clear_movement_input()
	_expect(controller.request_defeat(), "La fixture deve raggiungere uno stato terminale.")
	_expect(controller.restart_run(982451653), "Il restart deve avviare una nuova run.")
	_expect_vector(player.get_facing_direction(), Vector2.RIGHT, "Una nuova run deve ripartire dalla direzione di default.")
	_expect(not player.is_character_walking(), "Il restart non deve lasciare un'animazione in corso.")
	_expect(player.get_character_texture() == idle_texture, "Il restart deve ripristinare la posa ferma.")

	_validate_lollo_full_animation(player, friend_registry)

	await _finish(movement_slice)


func _validate_roster_animation_data(friend_registry: FriendRegistry) -> void:
	_expect(friend_registry.get_definitions().size() == 8, "Il catalogo deve contenere otto profili.")
	for definition in friend_registry.get_definitions():
		_expect(
			definition.has_directional_gameplay_animation(),
			"%s deve dichiarare idle e camminata laterale." % definition.id
		)
		_expect(
			definition.get_gameplay_idle_right().get_size() == Vector2(32.0, 32.0),
			"%s deve usare una posa idle 32x32." % definition.id
		)
		_expect(
			definition.get_gameplay_walk_right_frames().size() == 4,
			"%s deve alternare quattro fasi di camminata." % definition.id
		)


func _validate_lollo_full_animation(
	player: Player,
	friend_registry: FriendRegistry
) -> void:
	var lollo := friend_registry.resolve_definition(&"lollo")
	_expect(lollo != null, "Il catalogo deve contenere Lollo.")
	if lollo == null:
		return
	_expect(player.set_friend_definition(lollo), "Il Player deve accettare il profilo di Lollo.")
	player.clear_movement_input()
	var idle_texture := lollo.get_gameplay_idle_right()
	var walk_frames := lollo.get_gameplay_walk_right_frames()
	player.set_movement_input(Vector2.RIGHT)
	_expect(
		player.get_character_texture() == walk_frames[0]
		and walk_frames[0] != idle_texture,
		"Lollo deve usare il nuovo passo laterale A B18U."
	)
	player._physics_process(1.0 / lollo.gameplay_walk_fps + 0.001)
	_expect(player.get_character_texture() == walk_frames[1], "Il gait di Lollo deve avanzare al frame intermedio.")
	player._physics_process(1.0 / lollo.gameplay_walk_fps + 0.001)
	_expect(
		player.get_character_texture() == walk_frames[2]
		and walk_frames[2] != idle_texture
		and walk_frames[2] != walk_frames[0],
		"Il gait di Lollo deve raggiungere il nuovo passo laterale B B18U."
	)
	player.clear_movement_input()
	_expect(player.get_character_texture() == idle_texture, "Lollo deve tornare all'idle B18U.")


func _wait_processed_frame() -> void:
	await process_frame
	await process_frame


func _expect_vector(actual: Vector2, expected: Vector2, message: String) -> void:
	_expect(actual.is_equal_approx(expected), "%s Atteso %s, ottenuto %s." % [message, expected, actual])


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish(movement_slice: Control) -> void:
	paused = false
	if is_instance_valid(movement_slice):
		movement_slice.queue_free()
	await process_frame
	if _failures.is_empty():
		print("B18C_PLAYER_DIRECTION_ANIMATION_SMOKE_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	printerr("B18C_PLAYER_DIRECTION_ANIMATION_SMOKE_FAIL count=%d" % _failures.size())
	quit(1)
