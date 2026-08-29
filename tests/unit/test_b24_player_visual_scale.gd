extends GutGameplayTest

const BASE_SPRITE_SCALE := Vector2(1.65, 1.65)
const EXPECTED_VISUAL_MULTIPLIER := 1.25
const EXPECTED_COLLISION_RADIUS := 24.0
const LAYOUT_PROFILES: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1440, 720),
	Vector2i(1600, 720),
	Vector2i(960, 720),
]


func after_each() -> void:
	get_tree().root.content_scale_size = LAYOUT_PROFILES[0]
	get_tree().root.size = LAYOUT_PROFILES[0]


func test_player_visual_scale_contract() -> void:
	var movement_slice := await instantiate_movement_slice(LAYOUT_PROFILES[0])

	var player := movement_slice.get_player() as Player
	var registry := movement_slice.get_friend_registry() as FriendRegistry
	var arena := movement_slice.get_node_or_null("ArenaLayout") as ArenaLayout
	var controller := movement_slice.get_run_controller() as RunController
	assert_true(
		player != null and registry != null and arena != null and controller != null,
		"B24 richiede Player, roster, ArenaLayout e RunController composti."
	)
	if player == null or registry == null or arena == null or controller == null:
		return

	controller.set_process(false)
	player.set_physics_process(false)
	_assert_presentation_only_contract(player)
	_assert_all_profiles(player, registry)
	_assert_damage_feedback_composition(player)
	await _assert_layout_profiles(player, arena)
	_assert_configurable_multiplier(player)

	controller.prepare_restart()


func _assert_presentation_only_contract(player: Player) -> void:
	var collision := player.get_node_or_null("CollisionShape") as CollisionShape2D
	var circle := collision.shape as CircleShape2D if collision != null else null
	var sprite := player.get_node_or_null("CharacterSprite") as Sprite2D
	var weapon := player.get_node_or_null("WeaponController") as Node2D
	assert_true(
		is_equal_approx(player.visual_scale_multiplier, EXPECTED_VISUAL_MULTIPLIER),
		"B24 deve dichiarare la baseline candidata 1,25x."
	)
	assert_true(
		player.scale.is_equal_approx(Vector2.ONE)
		and collision != null
		and collision.scale.is_equal_approx(Vector2.ONE)
		and circle != null
		and is_equal_approx(circle.radius, EXPECTED_COLLISION_RADIUS)
		and is_equal_approx(player.collision_radius, EXPECTED_COLLISION_RADIUS)
		and player.collision_layer == 1
		and player.collision_mask == 4,
		"B24 non deve scalare il body o cambiare hitbox, layer e mask."
	)
	assert_true(
		sprite != null
		and player.get_character_base_scale().is_equal_approx(BASE_SPRITE_SCALE)
		and player.get_character_visual_scale().is_equal_approx(BASE_SPRITE_SCALE * EXPECTED_VISUAL_MULTIPLIER)
		and sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST,
		"B24 deve scalare solo lo sprite e preservare base e filtro pixel-art."
	)
	assert_true(
		weapon != null and weapon.position.is_equal_approx(Vector2.ZERO) and weapon.scale.is_equal_approx(Vector2.ONE),
		"B24 non deve spostare o scalare l'origine dei proiettili."
	)


func _assert_all_profiles(player: Player, registry: FriendRegistry) -> void:
	assert_eq(registry.get_definitions().size(), 8, "B24 deve coprire tutti gli otto Player.")
	for definition in registry.get_definitions():
		assert_true(player.set_friend_definition(definition), "B24 deve accettare %s." % definition.id)
		player.clear_movement_input()
		assert_true(
			player.get_character_texture() == definition.get_gameplay_idle_right()
			and player.get_character_visual_scale().is_equal_approx(BASE_SPRITE_SCALE * EXPECTED_VISUAL_MULTIPLIER),
			"%s deve usare la stessa scala visuale B24 in idle." % definition.id
		)
		player.set_movement_input(Vector2.LEFT)
		assert_true(
			player.get_character_visual_scale().is_equal_approx(BASE_SPRITE_SCALE * EXPECTED_VISUAL_MULTIPLIER),
			"%s deve conservare la scala B24 durante la camminata." % definition.id
		)
	player.clear_movement_input()


func _assert_damage_feedback_composition(player: Player) -> void:
	var collision := player.get_node_or_null("CollisionShape") as CollisionShape2D
	var circle := collision.shape as CircleShape2D if collision != null else null
	assert_true(player.take_contact_damage(1.0), "La fixture B24 deve attivare il feedback danno esistente.")
	assert_true(
		player.get_character_visual_scale().is_equal_approx(
			BASE_SPRITE_SCALE * EXPECTED_VISUAL_MULTIPLIER * player.get_visual_damage_scale()
		),
		"La scala B24 deve comporsi con lo squash di danno senza sostituirlo."
	)
	assert_true(
		circle != null and is_equal_approx(circle.radius, EXPECTED_COLLISION_RADIUS),
		"Il feedback danno B24 non deve scalare l'hitbox."
	)
	player.reset_for_run()


func _assert_layout_profiles(player: Player, arena: ArenaLayout) -> void:
	var sprite := player.get_node_or_null("CharacterSprite") as Sprite2D
	if sprite == null:
		return
	for profile in LAYOUT_PROFILES:
		get_tree().root.content_scale_size = profile
		get_tree().root.size = profile
		await wait_process_frames(2)
		arena.refresh_layout()
		await wait_process_frames(2)
		var context := "%dx%d" % [profile.x, profile.y]
		var playfield := arena.get_playfield_rect()
		var viewport_rect := arena.get_viewport_rect()
		var radius := player.collision_radius
		var requested_positions: Array[Vector2] = [
			playfield.get_center(),
			playfield.position - Vector2.ONE * 500.0,
			Vector2(playfield.end.x + 500.0, playfield.position.y - 500.0),
			playfield.end + Vector2.ONE * 500.0,
			Vector2(playfield.position.x - 500.0, playfield.end.y + 500.0),
		]
		for requested in requested_positions:
			var clamped := arena.clamp_circle_center(requested, radius)
			player.global_position = clamped
			var visual_rect := _get_canvas_rect(sprite)
			_assert_circle_inside(clamped, radius, playfield, "%s: B24 deve conservare il clamp gameplay." % context)
			assert_true(
				viewport_rect.encloses(visual_rect),
				"%s: lo sprite B24 non deve essere tagliato vicino ai bordi. Visuale %s, viewport %s."
				% [context, visual_rect, viewport_rect]
			)


func _assert_configurable_multiplier(player: Player) -> void:
	var collision := player.get_node_or_null("CollisionShape") as CollisionShape2D
	var circle := collision.shape as CircleShape2D if collision != null else null
	var weapon := player.get_node_or_null("WeaponController") as Node2D
	var original_weapon_position := weapon.position if weapon != null else Vector2.ZERO
	for multiplier in [1.2, 1.3]:
		player.visual_scale_multiplier = multiplier
		assert_true(
			player.get_character_visual_scale().is_equal_approx(BASE_SPRITE_SCALE * multiplier),
			"Il moltiplicatore B24 %.2f deve aggiornare immediatamente solo lo sprite." % multiplier
		)
		assert_true(
			circle != null
			and is_equal_approx(circle.radius, EXPECTED_COLLISION_RADIUS)
			and weapon != null
			and weapon.position.is_equal_approx(original_weapon_position)
			and weapon.scale.is_equal_approx(Vector2.ONE),
			"La configurazione B24 non deve propagarsi a collisione o origine di fuoco."
		)
	player.visual_scale_multiplier = EXPECTED_VISUAL_MULTIPLIER


func _get_canvas_rect(sprite: Sprite2D) -> Rect2:
	var local_rect := sprite.get_rect()
	var transform := sprite.get_global_transform()
	var corners: Array[Vector2] = [
		transform * local_rect.position,
		transform * Vector2(local_rect.end.x, local_rect.position.y),
		transform * local_rect.end,
		transform * Vector2(local_rect.position.x, local_rect.end.y),
	]
	var minimum := corners[0]
	var maximum := corners[0]
	for corner in corners:
		minimum = minimum.min(corner)
		maximum = maximum.max(corner)
	return Rect2(minimum, maximum - minimum)


func _assert_circle_inside(center: Vector2, radius: float, bounds: Rect2, text: String) -> void:
	assert_true(
		center.x - radius >= bounds.position.x - FLOAT_TOLERANCE
		and center.y - radius >= bounds.position.y - FLOAT_TOLERANCE
		and center.x + radius <= bounds.end.x + FLOAT_TOLERANCE
		and center.y + radius <= bounds.end.y + FLOAT_TOLERANCE,
		"%s Centro %s, raggio %.2f, bounds %s." % [text, center, radius, bounds]
	)
