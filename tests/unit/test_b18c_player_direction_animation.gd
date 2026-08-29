extends GutGameplayTest


func test_player_direction_and_animation_contract() -> void:
	var movement_slice := await instantiate_movement_slice()

	var player := movement_slice.get_node_or_null("World/Player") as Player
	var controller := movement_slice.get_node_or_null("RunController") as RunController
	var friend_registry := movement_slice.get_node_or_null("FriendRegistry") as FriendRegistry
	assert_not_null(player, "Il vertical slice deve contenere il Player.")
	assert_not_null(controller, "Il vertical slice deve contenere RunController.")
	assert_not_null(friend_registry, "Il vertical slice deve contenere FriendRegistry.")
	if player == null or controller == null or friend_registry == null:
		return

	_assert_roster_animation_data(friend_registry)
	player.set_physics_process(false)
	var definition := player.get_friend_definition()
	var idle_texture := definition.get_gameplay_idle_right()
	var walk_frames := definition.get_gameplay_walk_right_frames()

	assert_vector_near(player.get_facing_direction(), Vector2.RIGHT, "La run deve partire rivolta a destra.")
	assert_false(player.is_character_walking(), "Il Player neutro deve mostrare la posa ferma.")
	assert_eq(player.get_character_texture(), idle_texture, "La posa ferma deve usare lo sprite idle laterale.")
	assert_false(player.is_character_flipped_horizontally(), "Lo sprite destro non deve essere ribaltato.")

	player.set_movement_input(Vector2.LEFT)
	assert_vector_near(
		player.get_facing_direction(), Vector2.LEFT, "Un movimento a sinistra deve aggiornare l'ultima direzione."
	)
	assert_true(player.is_character_walking(), "Un input non nullo deve avviare la camminata.")
	assert_true(player.is_character_flipped_horizontally(), "La direzione sinistra deve ribaltare lo sprite laterale.")
	assert_eq(player.get_character_texture(), walk_frames[0], "La camminata deve partire dal primo frame dati.")
	player._physics_process(1.0 / definition.gameplay_walk_fps + 0.001)
	assert_eq(player.get_character_walk_frame_index(), 1, "La camminata deve avanzare al frame successivo.")
	assert_eq(player.get_character_texture(), walk_frames[1], "Il cambio frame deve aggiornare la texture visibile.")
	assert_eq(player.get_character_visual_offset(), Vector2(0.0, -2.0), "Il passo deve applicare un bob visibile.")

	player.clear_movement_input()
	assert_vector_near(player.get_facing_direction(), Vector2.LEFT, "Il neutro deve conservare l'ultima direzione valida.")
	assert_false(player.is_character_walking(), "Il neutro deve fermare l'animazione.")
	assert_eq(player.get_character_texture(), idle_texture, "Il neutro deve ripristinare la posa ferma.")
	assert_true(player.is_character_flipped_horizontally(), "La posa ferma deve restare rivolta a sinistra.")
	assert_eq(player.get_character_visual_offset(), Vector2.ZERO, "La posa ferma non deve conservare il bob.")
	assert_true(is_zero_approx(player.get_character_visual_rotation()), "La posa ferma non deve restare inclinata.")

	player.set_movement_input(Vector2.UP)
	assert_vector_near(
		player.get_facing_direction(), Vector2.LEFT, "Il movimento verticale non deve inventare una nuova direzione laterale."
	)
	assert_true(player.is_character_walking(), "Il movimento verticale deve comunque animare la camminata.")
	player.set_movement_input(Vector2(0.7, -0.7))
	assert_vector_near(
		player.get_facing_direction(), Vector2.RIGHT, "Una diagonale deve usare il segno della componente orizzontale."
	)
	assert_false(player.is_character_flipped_horizontally(), "Il ritorno a destra deve rimuovere il flip.")

	player.clear_movement_input()
	assert_true(controller.request_manual_pause(), "La fixture deve entrare in pausa manuale.")
	assert_vector_near(
		player.get_facing_direction(), Vector2.RIGHT, "La pausa con input neutro deve conservare l'ultima direzione."
	)
	assert_true(controller.resume_run(), "La fixture deve riprendere esplicitamente.")
	player.set_movement_input(Vector2.LEFT)
	player.clear_movement_input()
	assert_true(controller.request_defeat(), "La fixture deve raggiungere uno stato terminale.")
	assert_true(controller.restart_run(982451653), "Il restart deve avviare una nuova run.")
	assert_vector_near(
		player.get_facing_direction(), Vector2.RIGHT, "Una nuova run deve ripartire dalla direzione di default."
	)
	assert_false(player.is_character_walking(), "Il restart non deve lasciare un'animazione in corso.")
	assert_eq(player.get_character_texture(), idle_texture, "Il restart deve ripristinare la posa ferma.")

	_assert_lollo_full_animation(player, friend_registry)


func _assert_roster_animation_data(friend_registry: FriendRegistry) -> void:
	assert_eq(friend_registry.get_definitions().size(), 8, "Il catalogo deve contenere otto profili.")
	for definition in friend_registry.get_definitions():
		assert_true(
			definition.has_directional_gameplay_animation(), "%s deve dichiarare idle e camminata laterale." % definition.id
		)
		assert_eq(
			definition.get_gameplay_idle_right().get_size(), Vector2(32.0, 32.0), "%s deve usare una posa idle 32x32." % definition.id
		)
		assert_eq(
			definition.get_gameplay_walk_right_frames().size(), 4, "%s deve alternare quattro fasi di camminata." % definition.id
		)


func _assert_lollo_full_animation(player: Player, friend_registry: FriendRegistry) -> void:
	var lollo := friend_registry.resolve_definition(&"lollo")
	assert_not_null(lollo, "Il catalogo deve contenere Lollo.")
	if lollo == null:
		return
	assert_true(player.set_friend_definition(lollo), "Il Player deve accettare il profilo di Lollo.")
	player.clear_movement_input()
	var idle_texture := lollo.get_gameplay_idle_right()
	var walk_frames := lollo.get_gameplay_walk_right_frames()
	player.set_movement_input(Vector2.RIGHT)
	assert_true(
		player.get_character_texture() == walk_frames[0] and walk_frames[0] != idle_texture,
		"Lollo deve usare il nuovo passo laterale A B18U."
	)
	player._physics_process(1.0 / lollo.gameplay_walk_fps + 0.001)
	assert_eq(player.get_character_texture(), walk_frames[1], "Il gait di Lollo deve avanzare al frame intermedio.")
	player._physics_process(1.0 / lollo.gameplay_walk_fps + 0.001)
	assert_true(
		player.get_character_texture() == walk_frames[2]
		and walk_frames[2] != idle_texture
		and walk_frames[2] != walk_frames[0],
		"Il gait di Lollo deve raggiungere il nuovo passo laterale B B18U."
	)
	player.clear_movement_input()
	assert_eq(player.get_character_texture(), idle_texture, "Lollo deve tornare all'idle B18U.")
