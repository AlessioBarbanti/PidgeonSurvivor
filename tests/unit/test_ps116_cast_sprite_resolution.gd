extends GutGameplayTest

## PS-116: lo sprite di gameplay del cast era nativo 32x32 (contro i 48x48 dei
## piccioni) e veniva ingrandito ~2x a schermo, apparendo "poco definito" a
## confronto. Qui si rigenera il derivato a 64x64 dallo stesso master gia'
## approvato, compensando la scala del nodo cosi' il footprint a schermo
## resta invariato. Il corpo Evil (Boss) riusa la stessa texture, quindi
## beneficia automaticamente di meno ingrandimento residuo.

const EXPECTED_FRAME_SIZE := Vector2(64.0, 64.0)
const EXPECTED_SHEET_SIZE := Vector2(192.0, 64.0)
const EXPECTED_FOOTPRINT_PX := 66.0
const FOOTPRINT_TOLERANCE := 0.01
const CAST_IDS: Array[StringName] = [
	&"zat", &"bea", &"aleo", &"alea", &"lollo", &"migi", &"marghe", &"magno"
]


func test_cast_sprite_derivatives_are_64x64() -> void:
	for friend_id in CAST_IDS:
		var path := "res://assets/art/characters/%s/generated/sprite.png" % friend_id
		var texture := load(path) as Texture2D
		assert_not_null(texture, "PS-116 richiede il derivato rigenerato per %s." % friend_id)
		if texture == null:
			continue
		assert_eq(
			texture.get_size(), EXPECTED_SHEET_SIZE,
			"PS-116: %s deve essere una striscia 192x64 (3 frame da 64x64)." % friend_id
		)


func test_player_footprint_preserved_after_resolution_bump() -> void:
	var movement_slice := await instantiate_movement_slice()

	var player := movement_slice.get_player() as Player
	var registry := movement_slice.get_friend_registry() as FriendRegistry
	var controller := movement_slice.get_run_controller() as RunController
	assert_true(
		player != null and registry != null and controller != null,
		"PS-116 richiede Player, roster e RunController composti."
	)
	if player == null or registry == null or controller == null:
		return
	controller.set_process(false)

	assert_true(
		player.get_character_base_scale().is_equal_approx(Vector2(0.825, 0.825)),
		"PS-116: la scala base deve dimezzarsi a 0.825 per compensare il raddoppio del canvas nativo."
	)

	for definition in registry.get_definitions():
		assert_true(player.set_friend_definition(definition), "PS-116 deve accettare %s." % definition.id)
		var idle := definition.get_gameplay_idle_right()
		assert_true(
			idle != null and idle.get_size() == EXPECTED_FRAME_SIZE,
			"PS-116: l'idle di %s deve essere 64x64." % definition.id
		)
		if idle == null:
			continue
		var visual_scale := player.get_character_visual_scale()
		var footprint := idle.get_size().x * visual_scale.x
		assert_true(
			absf(footprint - EXPECTED_FOOTPRINT_PX) <= FOOTPRINT_TOLERANCE,
			(
				"PS-116: il footprint a schermo di %s deve restare ~%.1fpx (invariato), ottenuto %.4fpx."
				% [definition.id, EXPECTED_FOOTPRINT_PX, footprint]
			)
		)

	controller.prepare_restart()


func test_evil_boss_body_resolution_improves() -> void:
	var movement_slice := await instantiate_movement_slice()

	var encounter := movement_slice.get_boss_encounter() as BossEncounter
	var controller := movement_slice.get_run_controller() as RunController
	assert_true(encounter != null and controller != null, "PS-116 richiede BossEncounter e RunController.")
	if encounter == null or controller == null:
		return
	controller.set_process(false)

	encounter.evil_boss_chance = 1.0
	controller._process(120.01)
	var boss := encounter.get_active_boss()
	var definition := encounter.get_active_definition()
	assert_true(
		boss != null and definition != null and definition.is_evil_variant(),
		"PS-116 richiede un incontro Evil risolto per verificare il corpo Boss."
	)
	if boss == null or definition == null:
		controller.prepare_restart()
		return

	var boss_sprite := boss.get_node_or_null("BossSprite") as Sprite2D
	assert_true(
		boss_sprite != null and boss_sprite.texture != null and boss_sprite.texture.get_size() == EXPECTED_FRAME_SIZE,
		"PS-116: il corpo Evil deve riusare la stessa texture 64x64 del Player, non un asset separato."
	)
	if boss_sprite == null:
		encounter.complete_intro()
		controller.prepare_restart()
		return

	var target_diameter := definition.collision_radius * 1.9
	var expected_scale_factor := clampf(target_diameter / EXPECTED_FRAME_SIZE.x, 1.0, 4.0)
	assert_true(
		boss_sprite.scale.is_equal_approx(Vector2.ONE * expected_scale_factor),
		(
			"PS-116: il fattore di ingrandimento del corpo Evil deve seguire target_diameter/64 (atteso %.4f, ottenuto %s) — "
			+ "a testo 32x32 sarebbe stato il doppio, meno definito."
		) % [expected_scale_factor, boss_sprite.scale]
	)
	assert_true(
		expected_scale_factor < target_diameter / 32.0,
		"PS-116: il fattore atteso a 64x64 deve essere inferiore a quello che si sarebbe avuto a 32x32."
	)

	encounter.complete_intro()
	var health := boss.get_health_component()
	if health != null:
		boss.take_damage(health.health_current)
	await wait_process_frames(2)
	controller.prepare_restart()

	print("PS116_CAST_SPRITE_RESOLUTION_OK")
