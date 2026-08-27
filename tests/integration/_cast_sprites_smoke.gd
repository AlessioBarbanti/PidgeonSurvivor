extends SceneTree

const MOVEMENT_SLICE_SCENE := preload("res://scenes/game/movement_slice.tscn")
const TEST_VIEWPORT_SIZE := Vector2i(1280, 720)
const EXPECTED_CAST := {
	&"magno": {
		"path": "res://assets/art/characters/players/magno.png",
		"sha256": "1964FE0E1329BCFF44355EC1D940E84BFE434A3F4669F0188321B96B68F4D4FE",
		"passive": &"magno_aerodynamic_flow",
		"ability": &"magno_earthquake_shockwave",
	},
	&"bea": {
		"path": "res://assets/art/characters/players/bea.png",
		"sha256": "AC1ADF45DE9B303E9778BDFF1B916B3C210D031864709C182BDB30B1A1F1FDC2",
		"passive": &"bea_sixth_sense",
		"ability": &"bea_fire_z_trail",
	},
	&"zat": {
		"path": "res://assets/art/characters/players/zat.png",
		"sha256": "7CEC69B264AE522501DADDCDF471C0EF5DA037B2E3AB46FA1DF4A07592267EC6",
		"passive": &"zat_delayed_healing",
		"ability": &"zat_lightning_storm",
	},
	&"alea": {
		"path": "res://assets/art/characters/players/alea.png",
		"sha256": "B5DF2382A8231C826C6B447D91E22CA2E1ECCE9C0B0AD9E19EE8971D283D08E2",
		"passive": &"alea_eagle_never_misses",
		"ability": &"alea_grand_spin",
	},
	&"aleo": {
		"path": "res://assets/art/characters/players/aleo.png",
		"sha256": "0430029F910D1988E194F9216C03F1A54B59D8C859BC08AA9867DCDB70E34870",
		"passive": &"aleo_solid_structure",
		"ability": &"aleo_cement_pour",
	},
	&"lollo": {
		"path": "res://assets/art/characters/players/lollo.png",
		"sha256": "11990611A90F250497EF9F910C598A8DD36465B3407F70B98171C156534FF7B7",
		"passive": &"lollo_hyperactivity",
		"ability": &"lollo_random_cosplay",
	},
	&"migi": {
		"path": "res://assets/art/characters/players/migi.png",
		"sha256": "929331699DDF23E70B30B99E1557AC53E15CBB914D9BF18E1F9C3EFBB1FD32F3",
		"passive": &"migi_turtle_shell",
		"ability": &"migi_zen_slowdown",
	},
	&"marghe": {
		"path": "res://assets/art/characters/players/marghe.png",
		"sha256": "BC6ED19334215AD9E7F549A9DA0D98AF94674E2674753F0A926D3EB7E43E0BD7",
		"passive": &"marghe_contagious_smile",
		"ability": &"marghe_shadow_deception",
	},
}
const EXPECTED_HD := {
	&"magno": ["res://assets/art/characters/players/hd/magno_source.png", "07619CD1DA79DC81685814C0F159F0A6FD7B234BA4C129C84F29FF08B41E82F0"],
	&"bea": ["res://assets/art/characters/players/hd/bea_source.png", "9ACBBFB7A3B81E1F4A47FFFBEF47D2384A67DCD88C2815D22536AF66199243B8"],
	&"zat": ["res://assets/art/characters/players/hd/zat_source.png", "3DBD1945CE4765BA2B8605121675F1BA57425A2C0FE797FCB9D801594C6DE2D6"],
	&"alea": ["res://assets/art/characters/players/hd/alea_source.png", "636FE1DC8B03676E467FA510659B638F6719526067435FF404F37CAD862071D0"],
	&"aleo": ["res://assets/art/characters/players/hd/aleo_source.png", "5FF2A5B140F2E5334AE34110D366C1AD164D0C1366D96D7B9AE05108986C76F4"],
	&"lollo": ["res://assets/art/characters/players/hd/lollo_source.png", "597CF0546BBBD7176F61A931595DD0490727C77D5452E0044D8838E82072AEBE"],
	&"migi": ["res://assets/art/characters/players/hd/migi_source.png", "0922837FF4633230EFA8A79915872CF4D00EE0EC75B6F5CA65BAF096DFA1CAE8"],
	&"marghe": ["res://assets/art/characters/players/hd/marghe_source.png", "E6E107A6BFB7ED6898A8EE84160FACB8900A615A673A5A7A10E64009A1FF56F8"],
}

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	paused = false
	root.content_scale_size = TEST_VIEWPORT_SIZE
	root.size = TEST_VIEWPORT_SIZE
	await _wait_processed_frame()

	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	root.add_child(movement_slice)
	await _wait_processed_frame()

	var player := movement_slice.get_player() as Player
	var registry := movement_slice.get_friend_registry() as FriendRegistry
	var controller := movement_slice.get_run_controller() as RunController
	_expect(player != null and registry != null and controller != null, "B18U richiede Player, roster e RunController.")
	if player == null or registry == null or controller == null:
		await _dispose(movement_slice, controller)
		return

	controller.set_process(false)
	player.set_physics_process(false)
	_validate_collision_contract(player)
	_validate_cast_resources(player, registry)
	await _validate_selection_and_restart(movement_slice, player, controller)
	await _dispose(movement_slice, controller)
	await _finish()


func _validate_cast_resources(player: Player, registry: FriendRegistry) -> void:
	_expect(registry.get_definitions().size() == 8, "B18U deve coprire esattamente otto profili.")
	_expect(
		FileAccess.file_exists("res://assets/art/characters/players/hd/.gdignore"),
		"Le sorgenti HD B18U devono restare fuori dall'import runtime."
	)
	var export_presets := FileAccess.get_file_as_string("res://export_presets.cfg")
	_expect(
		export_presets.count("assets/art/characters/players/hd/**") == 3,
		"Ogni preset deve escludere le sorgenti HD B18U."
	)
	for definition in registry.get_definitions():
		var expected: Dictionary = EXPECTED_CAST.get(definition.id, {})
		_expect(not expected.is_empty(), "Profilo B18U inatteso: %s." % definition.id)
		if expected.is_empty():
			continue
		var expected_path := String(expected["path"])
		_expect(
			definition.passive_id == expected["passive"]
			and definition.active_ability_id == expected["ability"],
			"B18U non deve cambiare passiva o abilita di %s." % definition.id
		)
		_validate_file(expected_path, String(expected["sha256"]), definition.id)
		var expected_hd: Array = EXPECTED_HD.get(definition.id, [])
		_expect(expected_hd.size() == 2, "Sorgente HD non registrata per %s." % definition.id)
		if expected_hd.size() == 2:
			_validate_file(String(expected_hd[0]), String(expected_hd[1]), definition.id)

		var idle := definition.get_gameplay_idle_right()
		var walk := definition.get_gameplay_walk_right_frames()
		_expect(idle != null and idle.get_size() == Vector2(32.0, 32.0), "%s deve avere idle 32x32." % definition.id)
		_expect(walk.size() == 4, "%s deve conservare quattro fasi di camminata." % definition.id)
		if idle == null or walk.size() != 4:
			continue
		_expect(_atlas_path(idle) == expected_path, "%s deve usare la striscia B18U per l'idle." % definition.id)
		for frame in walk:
			_expect(
				frame != null
				and frame.get_size() == Vector2(32.0, 32.0)
				and _atlas_path(frame) == expected_path,
				"Ogni frame di %s deve provenire dalla propria striscia B18U." % definition.id
			)
		_expect(
			walk[0] != idle and walk[2] != idle and walk[0] != walk[2],
			"%s deve avere due passi originali distinti dall'idle." % definition.id
		)

		_expect(player.set_friend_definition(definition), "Il Player deve accettare %s." % definition.id)
		player.clear_movement_input()
		_expect(player.get_character_texture() == idle, "%s deve mostrare subito l'idle corretto." % definition.id)
		player.set_movement_input(Vector2.RIGHT)
		_expect(player.get_character_texture() == walk[0], "%s deve iniziare dal passo A." % definition.id)
		player._physics_process(1.0 / definition.gameplay_walk_fps + 0.001)
		_expect(player.get_character_texture() == walk[1], "%s deve avanzare al frame idle intermedio." % definition.id)
		player._physics_process(1.0 / definition.gameplay_walk_fps + 0.001)
		_expect(player.get_character_texture() == walk[2], "%s deve avanzare al passo B." % definition.id)
		player.set_movement_input(Vector2.LEFT)
		_expect(player.is_character_flipped_horizontally(), "%s deve riusare il facing sinistro B18C." % definition.id)
		_expect(player.get_last_movement_direction() == Vector2.LEFT, "%s deve conservare l'ultima direzione vettoriale." % definition.id)
		player.clear_movement_input()
		_expect(
			player.get_character_texture() == idle
			and player.get_character_visual_offset() == Vector2.ZERO
			and is_zero_approx(player.get_character_visual_rotation()),
			"%s deve tornare all'idle senza residui di gait." % definition.id
		)
		_validate_collision_contract(player)


func _validate_selection_and_restart(
	movement_slice: Control,
	player: Player,
	controller: RunController
) -> void:
	controller.prepare_restart()
	movement_slice._show_character_selection()
	var selector := movement_slice.get_character_select_overlay() as CharacterSelectOverlay
	_expect(selector != null and selector.visible, "B18U deve ricomporsi nel selettore in BOOT.")
	if selector == null:
		return
	var bea_button := selector.get_button(&"bea")
	_expect(bea_button != null, "Il selettore deve esporre Bea.")
	if bea_button == null:
		return
	bea_button.pressed.emit()
	selector.get_confirm_button().pressed.emit()
	await _wait_processed_frame()
	_expect(controller.is_running(), "La conferma deve avviare una nuova run B18U.")
	_expect(player.get_friend_definition().id == &"bea", "La nuova run deve sostituire il profilo Player.")
	_expect(
		_atlas_path(player.get_character_texture()) == EXPECTED_CAST[&"bea"]["path"],
		"La sostituzione dal selettore deve usare subito lo sprite di Bea."
	)
	_validate_collision_contract(player)

	_expect(controller.request_defeat(), "La fixture B18U deve entrare in stato terminale.")
	_expect(movement_slice.restart_run(982451653), "Il restart B18U deve avviare una seconda run.")
	await _wait_processed_frame()
	_expect(player.get_friend_definition().id == &"bea", "Il restart deve conservare il profilo scelto.")
	_expect(
		_atlas_path(player.get_character_texture()) == EXPECTED_CAST[&"bea"]["path"]
		and player.get_facing_direction() == Vector2.RIGHT
		and not player.is_character_walking(),
		"Il restart deve ripristinare idle e facing senza frame residui."
	)
	_validate_collision_contract(player)


func _validate_collision_contract(player: Player) -> void:
	var collision := player.get_node_or_null("CollisionShape") as CollisionShape2D
	var sprite := player.get_node_or_null("CharacterSprite") as Sprite2D
	var circle := collision.shape as CircleShape2D if collision != null else null
	_expect(
		collision != null
		and circle != null
		and is_equal_approx(circle.radius, 24.0)
		and is_equal_approx(player.collision_radius, 24.0)
		and player.collision_layer == 1
		and player.collision_mask == 4,
		"B18U non deve cambiare hitbox, layer o mask del Player."
	)
	_expect(
		sprite != null
		and player.get_character_base_scale().is_equal_approx(Vector2(1.65, 1.65))
		and sprite.scale.is_equal_approx(Vector2(2.0625, 2.0625))
		and sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST,
		"B18U deve conservare la scala base B18C e accettare il moltiplicatore visuale B24 con filtro nearest."
	)


func _atlas_path(texture: Texture2D) -> String:
	var atlas_texture := texture as AtlasTexture
	if atlas_texture == null or atlas_texture.atlas == null:
		return ""
	return atlas_texture.atlas.resource_path


func _validate_file(path: String, expected_sha256: String, friend_id: StringName) -> void:
	var bytes := FileAccess.get_file_as_bytes(path)
	_expect(not bytes.is_empty(), "Asset B18U mancante per %s." % friend_id)
	if bytes.is_empty():
		return
	var hashing := HashingContext.new()
	_expect(hashing.start(HashingContext.HASH_SHA256) == OK, "SHA-256 non inizializzabile per %s." % friend_id)
	_expect(hashing.update(bytes) == OK, "SHA-256 non aggiornabile per %s." % friend_id)
	_expect(
		hashing.finish().hex_encode().to_upper() == expected_sha256,
		"Hash B18U inatteso per %s." % friend_id
	)


func _wait_processed_frame() -> void:
	await process_frame
	await process_frame


func _dispose(movement_slice: Node, controller: RunController) -> void:
	if is_instance_valid(controller):
		controller.prepare_restart()
	paused = false
	if is_instance_valid(movement_slice):
		movement_slice.queue_free()
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	paused = false
	await process_frame
	if _failures.is_empty():
		print("B18U_CAST_SPRITES_SMOKE_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	printerr("B18U_CAST_SPRITES_SMOKE_FAIL count=%d" % _failures.size())
	quit(1)
