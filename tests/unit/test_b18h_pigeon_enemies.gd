extends GutGameplayTest

const ENEMY_SCENE: PackedScene = preload("res://scenes/actors/base_enemy.tscn")
const BASE_SHEET := "res://assets/art/enemies/pigeons/pigeon_base.png"
const SPECIAL_SHEET := "res://assets/art/enemies/pigeons/pigeon_special.png"
const EXPECTED_HASHES := {
	BASE_SHEET: "3e909e0fb6ac79c7b6d3eea3b96d0357f50a2711e6d743a1e28068ddf417ee81",
	SPECIAL_SHEET: "5a5c632c26c0c8484110c536feee569b45d623929776f85691768d0a1f523d28",
}


func after_each() -> void:
	get_tree().paused = false


func test_source_sheets_are_approved_and_transparent() -> void:
	for path: String in EXPECTED_HASHES:
		assert_true(FileAccess.file_exists(path), "Lo sprite B18H deve esistere: %s." % path)
		if not FileAccess.file_exists(path):
			continue
		assert_eq(
			FileAccess.get_sha256(path),
			EXPECTED_HASHES[path],
			"Lo sprite B18H deve conservare il file originale approvato: %s." % path
		)
		var texture := load(path) as Texture2D
		assert_not_null(texture, "Lo sprite B18H deve essere caricabile: %s." % path)
		if texture == null:
			continue
		var image := texture.get_image()
		assert_eq(image.get_size(), Vector2i(144, 48), "Lo sheet B18H deve contenere tre canvas 48x48: %s." % path)
		assert_ne(image.detect_alpha(), Image.ALPHA_NONE, "Lo sprite B18H deve avere trasparenza.")
		for corner in [
			Vector2i(0, 0),
			Vector2i(image.get_width() - 1, 0),
			Vector2i(0, image.get_height() - 1),
			Vector2i(image.get_width() - 1, image.get_height() - 1),
		]:
			assert_true(
				is_zero_approx(image.get_pixelv(corner).a),
				"Gli angoli dello sheet B18H devono restare trasparenti."
			)


func test_enemy_presentation_and_gameplay_contract() -> void:
	var fixture := Node2D.new()
	var target := Node2D.new()
	var controller := RunController.new()
	var enemy := ENEMY_SCENE.instantiate() as BaseEnemy
	fixture.add_child(target)
	fixture.add_child(controller)
	fixture.add_child(enemy)
	add_child_autofree(fixture)
	await wait_process_frames(1)
	enemy.set_physics_process(false)
	controller.set_process(false)

	var sprite := enemy.get_enemy_sprite()
	assert_not_null(sprite, "Il nemico ordinario deve mostrare AnimatedSprite2D.")
	if sprite == null:
		return
	assert_eq(
		sprite.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST, "I piccioni devono usare il filtro nearest della pixel art."
	)
	for animation_name in [&"base", &"special"]:
		assert_true(
			sprite.sprite_frames.has_animation(animation_name), "Deve esistere l'animazione %s." % animation_name
		)
		assert_eq(
			sprite.sprite_frames.get_frame_count(animation_name),
			3,
			"Ogni variante deve avere posa neutra e due fasi d'ala."
		)
		for frame_index in range(3):
			var texture := sprite.sprite_frames.get_frame_texture(animation_name, frame_index)
			assert_true(
				texture != null and texture.get_size() == Vector2(48.0, 48.0),
				"Ogni frame B18H deve usare un canvas 48x48."
			)

	assert_eq(enemy.get_visual_variant(), 0, "Lo spawn ordinario deve usare il piccione base.")
	assert_eq(sprite.animation, &"base", "La scena base deve selezionare l'animazione base.")
	_assert_gameplay_contract(enemy)
	enemy.set_visual_variant(1)
	assert_eq(sprite.animation, &"special", "La fixture deve poter selezionare la variante speciale.")
	_assert_gameplay_contract(enemy)
	enemy.set_visual_variant(0)

	controller.start_run(1818)
	enemy.global_position = Vector2(300.0, 300.0)
	target.global_position = Vector2(500.0, 300.0)
	enemy.set_target(target)
	enemy.set_run_controller(controller)
	enemy._physics_process(1.0 / 60.0)
	assert_true(sprite.is_playing(), "Le ali devono animarsi soltanto in RUNNING.")
	assert_false(sprite.flip_h, "Il piccione deve guardare a destra durante l'inseguimento a destra.")

	target.global_position = Vector2(100.0, 300.0)
	enemy._physics_process(1.0 / 60.0)
	assert_true(sprite.flip_h, "Il piccione deve ribaltarsi durante l'inseguimento a sinistra.")
	target.global_position = Vector2(enemy.global_position.x, 100.0)
	enemy._physics_process(1.0 / 60.0)
	assert_true(sprite.flip_h, "Il movimento verticale deve conservare il verso orizzontale.")

	controller.request_manual_pause()
	assert_false(sprite.is_playing(), "L'animazione deve fermarsi fuori da RUNNING.")
	assert_eq(enemy.velocity, Vector2.ZERO, "La pausa non deve cambiare il contratto di movimento.")
	controller.resume_run()
	assert_true(sprite.is_playing(), "Il resume deve riavviare l'animazione presentazionale.")
	controller.request_victory()
	assert_false(sprite.is_playing(), "Un terminale deve fermare le ali.")

	enemy.clear_chase_dependencies()
	controller.prepare_restart()


func _assert_gameplay_contract(enemy: BaseEnemy) -> void:
	assert_almost_eq(enemy.move_speed, 140.0, FLOAT_TOLERANCE, "B18H non deve cambiare la velocita.")
	assert_almost_eq(enemy.collision_radius, 20.0, FLOAT_TOLERANCE, "B18H non deve cambiare la collisione.")
	assert_eq(enemy.get_experience_amount(), 1, "B18H non deve cambiare il drop XP.")
	var health := enemy.get_health_component()
	assert_true(
		health != null and is_equal_approx(health.health_max, 10.0),
		"B18H deve conservare la baseline HP PS-076 del nemico base."
	)
	var contact := enemy.get_contact_damage()
	assert_true(
		contact != null and is_equal_approx(contact.damage, 12.0),
		"B18H deve conservare il danno da contatto PS-076 del nemico base."
	)
