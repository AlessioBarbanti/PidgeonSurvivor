extends GutGameplayTest

const EXPECTED_CAST := {
	&"magno": {
		"path": "res://assets/art/characters/magno/generated/sprite.png",
		"sha256": "6D38CF835DBA9ECDA91A46BF57BAA5F07D7EA3DB9D5B1E85705498DCF4634F92",
		"passive": &"magno_aerodynamic_flow",
		"ability": &"magno_earthquake_shockwave",
	},
	&"bea": {
		"path": "res://assets/art/characters/bea/generated/sprite.png",
		"sha256": "0268364C47C4F21983DB54DA0A18BBA2D97C957A6712041B2DE9B42A0D871D52",
		"passive": &"bea_sixth_sense",
		"ability": &"bea_fire_z_trail",
	},
	&"zat": {
		"path": "res://assets/art/characters/zat/generated/sprite.png",
		"sha256": "98BB6BFEA0E0144923D7A233AD96BC91695ACBD55D9352F79E04251214C5E1F0",
		"passive": &"zat_delayed_healing",
		"ability": &"zat_lightning_storm",
	},
	&"alea": {
		"path": "res://assets/art/characters/alea/generated/sprite.png",
		"sha256": "5E4A2CFED4B2DB4E749EF87F1801AB7D835F9C736405E7EEA9B4D5EDA0493F26",
		"passive": &"alea_two_fingers_and_go",
		"ability": &"alea_grand_spin",
	},
	&"aleo": {
		"path": "res://assets/art/characters/aleo/generated/sprite.png",
		"sha256": "DC7069EF10B070072337822386A14DE4CA52E7EB412464F08D70D5A32DCC438E",
		"passive": &"aleo_internal_thermostat",
		"ability": &"aleo_thermal_shock",
	},
	&"lollo": {
		"path": "res://assets/art/characters/lollo/generated/sprite.png",
		"sha256": "85CCFA620E98B9B4167C4F06B195228EDB0DCDE4EC91BC79E8834A04B8644872",
		"passive": &"lollo_hyperactivity",
		"ability": &"lollo_random_cosplay",
	},
	&"migi": {
		"path": "res://assets/art/characters/migi/generated/sprite.png",
		"sha256": "DACE18ACE1A38858B80EF2D4475B2A4ECB4E1EFEEB59D75EE6AF56ECE17DC56E",
		"passive": &"migi_turtle_shell",
		"ability": &"migi_zen_slowdown",
	},
	&"marghe": {
		"path": "res://assets/art/characters/marghe/generated/sprite.png",
		"sha256": "F6E8F39C8A815C5F292CDE57273E6BD030F1C8899B843DEC77E19D89368D59CA",
		"passive": &"marghe_contagious_smile",
		"ability": &"marghe_shadow_deception",
	},
}
const EXPECTED_HD := {
	&"magno": ["res://assets/art/characters/magno/hd/poses.png", "2EA717859B91B420B97F8D9975D67A3C827BA94CC4355739A4DB4FE370F836A5"],
	&"bea": ["res://assets/art/characters/bea/hd/poses.png", "3C6B26826B9A6B5708174AE6EDB42F1F652A120DE0B17C3405DCAB8CB756059D"],
	&"zat": ["res://assets/art/characters/zat/hd/poses.png", "DD1EB3F249F37426E9573DE02C2E0292F32A932A0C2059F82325D1F92919780B"],
	&"alea": ["res://assets/art/characters/alea/hd/poses.png", "61C760FA609852BA31F5C24CE43626EA41228AAC6DFC9371D78D83F65408FEA5"],
	&"aleo": ["res://assets/art/characters/aleo/hd/poses.png", "53999B4B51D97A918B5AC8F68444417E07B8B17EA4837C239173C5DEF4C787DE"],
	&"lollo": ["res://assets/art/characters/lollo/hd/poses.png", "CA66A174E501BEAB30CA3076F3682CCE955E488EC6EB8BBFC3C7734FDC1CF424"],
	&"migi": ["res://assets/art/characters/migi/hd/poses.png", "04EDEE8F99B5849384D268BD35CB4E498EA80BEA1FA961A67BD19B8D1DC75499"],
	&"marghe": ["res://assets/art/characters/marghe/hd/poses.png", "D20B2CBA8B5FEB9A70D62D5E5CBEDFAB96E0FC9BB4E1C954B9BDBEC782A1872C"],
}


func test_cast_sprites_contract() -> void:
	var movement_slice := await instantiate_movement_slice()

	var player := movement_slice.get_player() as Player
	var registry := movement_slice.get_friend_registry() as FriendRegistry
	var controller := movement_slice.get_run_controller() as RunController
	assert_true(
		player != null and registry != null and controller != null,
		"B18U richiede Player, roster e RunController."
	)
	if player == null or registry == null or controller == null:
		return

	controller.set_process(false)
	player.set_physics_process(false)
	_assert_collision_contract(player)
	_assert_cast_resources(player, registry)
	await _assert_selection_and_restart(movement_slice, player, controller)


func _assert_cast_resources(player: Player, registry: FriendRegistry) -> void:
	assert_eq(registry.get_definitions().size(), 8, "B18U deve coprire esattamente otto profili.")
	for friend_id in EXPECTED_CAST.keys():
		assert_true(
			FileAccess.file_exists("res://assets/art/characters/%s/hd/.gdignore" % friend_id),
			"%s: le sorgenti HD B18U devono restare fuori dall'import runtime." % friend_id
		)
	var export_presets := FileAccess.get_file_as_string("res://export_presets.cfg")
	assert_eq(
		export_presets.count("assets/art/characters/*/hd/**"), 3,
		"Ogni preset deve escludere le sorgenti HD B18U."
	)
	for definition in registry.get_definitions():
		var expected: Dictionary = EXPECTED_CAST.get(definition.id, {})
		assert_false(expected.is_empty(), "Profilo B18U inatteso: %s." % definition.id)
		if expected.is_empty():
			continue
		var expected_path := String(expected["path"])
		assert_true(
			definition.passive_id == expected["passive"] and definition.active_ability_id == expected["ability"],
			"B18U non deve cambiare passiva o abilita di %s." % definition.id
		)
		_assert_file(expected_path, String(expected["sha256"]), definition.id)
		var expected_hd: Array = EXPECTED_HD.get(definition.id, [])
		assert_eq(expected_hd.size(), 2, "Sorgente HD non registrata per %s." % definition.id)
		if expected_hd.size() == 2:
			_assert_file(String(expected_hd[0]), String(expected_hd[1]), definition.id)

		var idle := definition.get_gameplay_idle_right()
		var walk := definition.get_gameplay_walk_right_frames()
		assert_true(
			idle != null and idle.get_size() == Vector2(64.0, 64.0), "%s deve avere idle 64x64 (PS-116)." % definition.id
		)
		assert_eq(walk.size(), 4, "%s deve conservare quattro fasi di camminata." % definition.id)
		if idle == null or walk.size() != 4:
			continue
		assert_eq(
			_atlas_path(idle), expected_path, "%s deve usare la striscia B18U per l'idle." % definition.id
		)
		for frame in walk:
			assert_true(
				frame != null and frame.get_size() == Vector2(64.0, 64.0) and _atlas_path(frame) == expected_path,
				"Ogni frame di %s deve provenire dalla propria striscia B18U." % definition.id
			)
		assert_true(
			walk[0] != idle and walk[2] != idle and walk[0] != walk[2],
			"%s deve avere due passi originali distinti dall'idle." % definition.id
		)

		assert_true(player.set_friend_definition(definition), "Il Player deve accettare %s." % definition.id)
		player.clear_movement_input()
		assert_eq(
			player.get_character_texture(), idle, "%s deve mostrare subito l'idle corretto." % definition.id
		)
		player.set_movement_input(Vector2.RIGHT)
		assert_eq(player.get_character_texture(), walk[0], "%s deve iniziare dal passo A." % definition.id)
		player._physics_process(1.0 / definition.gameplay_walk_fps + 0.001)
		assert_eq(
			player.get_character_texture(), walk[1], "%s deve avanzare al frame idle intermedio." % definition.id
		)
		player._physics_process(1.0 / definition.gameplay_walk_fps + 0.001)
		assert_eq(player.get_character_texture(), walk[2], "%s deve avanzare al passo B." % definition.id)
		player.set_movement_input(Vector2.LEFT)
		assert_true(
			player.is_character_flipped_horizontally(), "%s deve riusare il facing sinistro B18C." % definition.id
		)
		assert_eq(
			player.get_last_movement_direction(), Vector2.LEFT,
			"%s deve conservare l'ultima direzione vettoriale." % definition.id
		)
		player.clear_movement_input()
		assert_true(
			player.get_character_texture() == idle
			and player.get_character_visual_offset() == Vector2.ZERO
			and is_zero_approx(player.get_character_visual_rotation()),
			"%s deve tornare all'idle senza residui di gait." % definition.id
		)
		_assert_collision_contract(player)


func _assert_selection_and_restart(
	movement_slice: Control, player: Player, controller: RunController
) -> void:
	controller.prepare_restart()
	movement_slice._show_character_selection()
	var selector := movement_slice.get_character_select_overlay() as CharacterSelectOverlay
	assert_true(selector != null and selector.visible, "B18U deve ricomporsi nel selettore in BOOT.")
	if selector == null:
		return
	var bea_button := selector.get_button(&"bea")
	assert_not_null(bea_button, "Il selettore deve esporre Bea.")
	if bea_button == null:
		return
	bea_button.pressed.emit()
	selector.get_confirm_button().pressed.emit()
	await wait_process_frames(2)
	assert_true(controller.is_running(), "La conferma deve avviare una nuova run B18U.")
	assert_eq(player.get_friend_definition().id, &"bea", "La nuova run deve sostituire il profilo Player.")
	assert_eq(
		_atlas_path(player.get_character_texture()), EXPECTED_CAST[&"bea"]["path"],
		"La sostituzione dal selettore deve usare subito lo sprite di Bea."
	)
	_assert_collision_contract(player)

	assert_true(controller.request_defeat(), "La fixture B18U deve entrare in stato terminale.")
	assert_true(movement_slice.restart_run(982451653), "Il restart B18U deve avviare una seconda run.")
	await wait_process_frames(2)
	assert_eq(player.get_friend_definition().id, &"bea", "Il restart deve conservare il profilo scelto.")
	assert_true(
		_atlas_path(player.get_character_texture()) == EXPECTED_CAST[&"bea"]["path"]
		and player.get_facing_direction() == Vector2.RIGHT
		and not player.is_character_walking(),
		"Il restart deve ripristinare idle e facing senza frame residui."
	)
	_assert_collision_contract(player)


func _assert_collision_contract(player: Player) -> void:
	var collision := player.get_node_or_null("CollisionShape") as CollisionShape2D
	var sprite := player.get_node_or_null("CharacterSprite") as Sprite2D
	var circle := collision.shape as CircleShape2D if collision != null else null
	assert_true(
		collision != null
		and circle != null
		and is_equal_approx(circle.radius, 24.0)
		and is_equal_approx(player.collision_radius, 24.0)
		and player.collision_layer == 1
		and player.collision_mask == 4,
		"B18U non deve cambiare hitbox, layer o mask del Player."
	)
	assert_true(
		sprite != null
		and player.get_character_base_scale().is_equal_approx(Vector2(0.825, 0.825))
		and sprite.scale.is_equal_approx(Vector2(1.03125, 1.03125))
		and sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST,
		"B18U deve conservare la scala base 0,825 (PS-116, texture 64x64) e accettare il moltiplicatore visuale B24 con filtro nearest."
	)


func _atlas_path(texture: Texture2D) -> String:
	var atlas_texture := texture as AtlasTexture
	if atlas_texture == null or atlas_texture.atlas == null:
		return ""
	return atlas_texture.atlas.resource_path


func _assert_file(path: String, expected_sha256: String, friend_id: StringName) -> void:
	var bytes := FileAccess.get_file_as_bytes(path)
	assert_false(bytes.is_empty(), "Asset B18U mancante per %s." % friend_id)
	if bytes.is_empty():
		return
	var hashing := HashingContext.new()
	assert_eq(hashing.start(HashingContext.HASH_SHA256), OK, "SHA-256 non inizializzabile per %s." % friend_id)
	assert_eq(hashing.update(bytes), OK, "SHA-256 non aggiornabile per %s." % friend_id)
	assert_eq(
		hashing.finish().hex_encode().to_upper(), expected_sha256, "Hash B18U inatteso per %s." % friend_id
	)
