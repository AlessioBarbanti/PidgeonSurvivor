extends SceneTree

const ENEMY_SCENE: PackedScene = preload("res://scenes/actors/base_enemy.tscn")
const BASE_SHEET := "res://assets/art/enemies/pigeons/pigeon_base.png"
const SPECIAL_SHEET := "res://assets/art/enemies/pigeons/pigeon_special.png"
const EXPECTED_HASHES := {
	BASE_SHEET: "3e909e0fb6ac79c7b6d3eea3b96d0357f50a2711e6d743a1e28068ddf417ee81",
	SPECIAL_SHEET: "5a5c632c26c0c8484110c536feee569b45d623929776f85691768d0a1f523d28",
}
const FLOAT_TOLERANCE := 0.001

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	paused = false
	_validate_source_sheets()
	await _validate_enemy_presentation_and_gameplay()
	await _finish()


func _validate_source_sheets() -> void:
	for path: String in EXPECTED_HASHES:
		_expect(FileAccess.file_exists(path), "Lo sprite B18H deve esistere: %s." % path)
		if not FileAccess.file_exists(path):
			continue
		_expect(
			FileAccess.get_sha256(path) == EXPECTED_HASHES[path],
			"Lo sprite B18H deve conservare il file originale approvato: %s." % path
		)
		var texture := load(path) as Texture2D
		_expect(texture != null, "Lo sprite B18H deve essere caricabile: %s." % path)
		if texture == null:
			continue
		var image := texture.get_image()
		_expect(
			image.get_size() == Vector2i(144, 48),
			"Lo sheet B18H deve contenere tre canvas 48x48: %s." % path
		)
		_expect(image.detect_alpha() != Image.ALPHA_NONE, "Lo sprite B18H deve avere trasparenza.")
		for corner in [
			Vector2i(0, 0),
			Vector2i(image.get_width() - 1, 0),
			Vector2i(0, image.get_height() - 1),
			Vector2i(image.get_width() - 1, image.get_height() - 1),
		]:
			_expect(
				is_zero_approx(image.get_pixelv(corner).a),
				"Gli angoli dello sheet B18H devono restare trasparenti."
			)


func _validate_enemy_presentation_and_gameplay() -> void:
	var fixture := Node2D.new()
	var target := Node2D.new()
	var controller := RunController.new()
	var enemy := ENEMY_SCENE.instantiate() as BaseEnemy
	fixture.add_child(target)
	fixture.add_child(controller)
	fixture.add_child(enemy)
	root.add_child(fixture)
	await process_frame
	enemy.set_physics_process(false)
	controller.set_process(false)

	var sprite := enemy.get_enemy_sprite()
	_expect(sprite != null, "Il nemico ordinario deve mostrare AnimatedSprite2D.")
	if sprite == null:
		fixture.queue_free()
		await process_frame
		return
	_expect(
		sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST,
		"I piccioni devono usare il filtro nearest della pixel art."
	)
	for animation_name in [&"base", &"special"]:
		_expect(
			sprite.sprite_frames.has_animation(animation_name),
			"Deve esistere l'animazione %s." % animation_name
		)
		_expect(
			sprite.sprite_frames.get_frame_count(animation_name) == 3,
			"Ogni variante deve avere posa neutra e due fasi d'ala."
		)
		for frame_index in range(3):
			var texture := sprite.sprite_frames.get_frame_texture(animation_name, frame_index)
			_expect(
				texture != null and texture.get_size() == Vector2(48.0, 48.0),
				"Ogni frame B18H deve usare un canvas 48x48."
			)

	_expect(enemy.get_visual_variant() == 0, "Lo spawn ordinario deve usare il piccione base.")
	_expect(sprite.animation == &"base", "La scena base deve selezionare l'animazione base.")
	_validate_gameplay_contract(enemy)
	enemy.set_visual_variant(1)
	_expect(sprite.animation == &"special", "La fixture deve poter selezionare la variante speciale.")
	_validate_gameplay_contract(enemy)
	enemy.set_visual_variant(0)

	controller.start_run(1818)
	enemy.global_position = Vector2(300.0, 300.0)
	target.global_position = Vector2(500.0, 300.0)
	enemy.set_target(target)
	enemy.set_run_controller(controller)
	enemy._physics_process(1.0 / 60.0)
	_expect(sprite.is_playing(), "Le ali devono animarsi soltanto in RUNNING.")
	_expect(not sprite.flip_h, "Il piccione deve guardare a destra durante l'inseguimento a destra.")

	target.global_position = Vector2(100.0, 300.0)
	enemy._physics_process(1.0 / 60.0)
	_expect(sprite.flip_h, "Il piccione deve ribaltarsi durante l'inseguimento a sinistra.")
	target.global_position = Vector2(enemy.global_position.x, 100.0)
	enemy._physics_process(1.0 / 60.0)
	_expect(sprite.flip_h, "Il movimento verticale deve conservare il verso orizzontale.")

	controller.request_manual_pause()
	_expect(not sprite.is_playing(), "L'animazione deve fermarsi fuori da RUNNING.")
	_expect(enemy.velocity == Vector2.ZERO, "La pausa non deve cambiare il contratto di movimento.")
	controller.resume_run()
	_expect(sprite.is_playing(), "Il resume deve riavviare l'animazione presentazionale.")
	controller.request_victory()
	_expect(not sprite.is_playing(), "Un terminale deve fermare le ali.")

	enemy.clear_chase_dependencies()
	controller.prepare_restart()
	fixture.queue_free()
	await process_frame


func _validate_gameplay_contract(enemy: BaseEnemy) -> void:
	_expect_float_near(enemy.move_speed, 140.0, "B18H non deve cambiare la velocita.")
	_expect_float_near(enemy.collision_radius, 20.0, "B18H non deve cambiare la collisione.")
	_expect(enemy.get_experience_amount() == 1, "B18H non deve cambiare il drop XP.")
	var health := enemy.get_health_component()
	_expect(
		health != null and is_equal_approx(health.health_max, 24.0),
		"B18H deve conservare la baseline HP B28 del nemico base."
	)
	var contact := enemy.get_contact_damage()
	_expect(
		contact != null and is_equal_approx(contact.damage, 20.0),
		"B18H non deve cambiare il danno da contatto."
	)


func _expect_float_near(actual: float, expected: float, message: String) -> void:
	_expect(absf(actual - expected) <= FLOAT_TOLERANCE, message)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	paused = false
	await process_frame
	if _failures.is_empty():
		print("B18H_PIGEON_ENEMIES_SMOKE_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	printerr("B18H_PIGEON_ENEMIES_SMOKE_FAIL count=%d" % _failures.size())
	quit(1)
