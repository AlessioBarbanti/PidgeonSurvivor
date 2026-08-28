extends SceneTree

const MOVEMENT_SLICE_SCENE: PackedScene = preload("res://scenes/game/movement_slice.tscn")
const STATIC_OBSTACLE_SCENE: PackedScene = preload(
	"res://scenes/game/obstacles/static_obstacle.tscn"
)
const PLAYER_SCENE: PackedScene = preload("res://scenes/actors/player.tscn")
const ENEMY_SCENE: PackedScene = preload("res://scenes/actors/base_enemy.tscn")
const BOSS_SCENE: PackedScene = preload("res://scenes/actors/first_boss.tscn")
const OBSTACLE_LAYER_BIT := 4
const FLOAT_TOLERANCE := 0.001
const INITIAL_VIEWPORT_SIZE := Vector2i(1280, 720)

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	paused = false
	_validate_arena_world_math()
	_validate_static_obstacle()
	_validate_boundary_bands_math()
	await _validate_obstacle_blocks_movement()
	await _validate_obstacle_collision_segments_block_only_opaque_parts()
	await _validate_camera_relative_spawn_reference()
	await _validate_actor_obstacle_masks()
	await _validate_composed_scene()
	await _finish()


func _validate_arena_world_math() -> void:
	var world := ArenaWorld.new()
	world.world_size = Vector2(2400.0, 1500.0)
	world.world_origin = Vector2.ZERO
	var rect := world.get_world_rect()
	_expect(
		rect == Rect2(Vector2(-1200.0, -750.0), Vector2(2400.0, 1500.0)),
		"Il rettangolo del mondo deve essere centrato sull'origine dichiarata."
	)
	_expect_vector_near(
		world.get_world_center(), Vector2.ZERO, "Il centro del mondo deve coincidere con world_origin."
	)

	_expect_vector_near(
		ArenaWorld.clamp_circle_center_in_rect(rect, Vector2.ZERO, 20.0),
		Vector2.ZERO,
		"Un punto gia' interno non deve essere spostato."
	)
	_expect_vector_near(
		ArenaWorld.clamp_circle_center_in_rect(rect, Vector2(-5000.0, 0.0), 20.0),
		Vector2(rect.position.x + 20.0, 0.0),
		"Il clamp deve fermarsi al bordo minimo meno il raggio."
	)
	_expect_vector_near(
		ArenaWorld.clamp_circle_center_in_rect(rect, Vector2(5000.0, 5000.0), 20.0),
		rect.end - Vector2.ONE * 20.0,
		"Il clamp deve fermarsi al bordo massimo meno il raggio."
	)
	_expect_vector_near(
		ArenaWorld.clamp_circle_center_in_rect(Rect2(), Vector2(12.0, 34.0), 5.0),
		Vector2(12.0, 34.0),
		"Un rettangolo senza area non deve alterare il punto."
	)
	world.free()


func _validate_static_obstacle() -> void:
	var obstacle := STATIC_OBSTACLE_SCENE.instantiate() as StaticObstacle
	var fixture := Node2D.new()
	fixture.add_child(obstacle)
	root.add_child(fixture)
	await process_frame

	_expect(
		obstacle.collision_layer == OBSTACLE_LAYER_BIT and obstacle.collision_mask == 0,
		"Il segnaposto ostacolo deve occupare solo il layer Obstacle."
	)
	obstacle.footprint_size = Vector2(240.0, 96.0)
	obstacle.global_position = Vector2(50.0, -30.0)
	var shape := obstacle.get_node("CollisionShape") as CollisionShape2D
	_expect(
		shape.shape is RectangleShape2D
		and (shape.shape as RectangleShape2D).size == Vector2(240.0, 96.0),
		"Cambiare footprint_size deve ridimensionare la CollisionShape2D."
	)
	_expect(
		obstacle.get_footprint_rect() == Rect2(Vector2(-70.0, -78.0), Vector2(240.0, 96.0)),
		"get_footprint_rect deve riflettere posizione e dimensione correnti."
	)

	paused = false
	fixture.queue_free()
	await process_frame


func _validate_boundary_bands_math() -> void:
	var rect := Rect2(Vector2(-1200.0, -750.0), Vector2(2400.0, 1500.0))
	var bands := ArenaView.calculate_boundary_bands(rect, 28.0)
	_expect(
		bands.size() == 4,
		"calculate_boundary_bands deve produrre quattro bande (alto, basso, sinistra, destra)."
	)
	for band in bands:
		_expect(
			rect.encloses(band),
			"B50: ogni banda del delimitatore deve restare contenuta nel playfield."
		)
	_expect(
		ArenaView.calculate_boundary_bands(rect, 0.0).is_empty(),
		"Uno spessore nullo non deve produrre bande."
	)
	_expect(
		ArenaView.calculate_boundary_bands(Rect2(), 28.0).is_empty(),
		"Un rettangolo senza area non deve produrre bande."
	)
	var oversized := ArenaView.calculate_boundary_bands(Rect2(Vector2.ZERO, Vector2(40.0, 20.0)), 100.0)
	for band in oversized:
		_expect(
			Rect2(Vector2.ZERO, Vector2(40.0, 20.0)).encloses(band),
			"Uno spessore piu' grande del playfield deve restare comunque contenuto (clamp)."
		)


func _validate_obstacle_blocks_movement() -> void:
	var fixture := Node2D.new()
	var obstacle := STATIC_OBSTACLE_SCENE.instantiate() as StaticObstacle
	obstacle.footprint_size = Vector2(200.0, 100.0)
	obstacle.global_position = Vector2(300.0, 0.0)

	var body := CharacterBody2D.new()
	body.collision_layer = 1
	body.collision_mask = OBSTACLE_LAYER_BIT
	body.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var body_shape := CollisionShape2D.new()
	var body_circle := CircleShape2D.new()
	body_circle.radius = 24.0
	body_shape.shape = body_circle
	body.add_child(body_shape)
	body.global_position = Vector2(150.0, 0.0)

	fixture.add_child(obstacle)
	fixture.add_child(body)
	root.add_child(fixture)
	await process_frame
	await physics_frame

	for _attempt in range(60):
		body.velocity = Vector2.RIGHT * 400.0
		body.move_and_slide()
		await physics_frame

	_expect(
		body.global_position.x < 195.0,
		(
			"Un corpo con maschera Obstacle non deve attraversare uno StaticObstacle (x=%s)."
			% body.global_position.x
		)
	)

	paused = false
	fixture.queue_free()
	await process_frame


func _validate_obstacle_collision_segments_block_only_opaque_parts() -> void:
	var fixture := Node2D.new()
	var obstacle := STATIC_OBSTACLE_SCENE.instantiate() as StaticObstacle
	obstacle.footprint_size = Vector2(150.0, 250.0)
	obstacle.collision_segments = [
		Rect2(-0.5, -0.5, 0.18, 1.0),
		Rect2(0.32, -0.5, 0.18, 1.0),
	]
	obstacle.global_position = Vector2(300.0, 0.0)
	fixture.add_child(obstacle)
	root.add_child(fixture)
	await process_frame
	await physics_frame

	var main_shape := obstacle.get_node("CollisionShape") as CollisionShape2D
	_expect(
		main_shape.disabled,
		"B50: la CollisionShape2D piena deve disattivarsi quando collision_segments non e' vuoto."
	)
	var segment_shapes: Array[CollisionShape2D] = []
	for child in obstacle.get_children():
		if child is CollisionShape2D and child != main_shape:
			segment_shapes.append(child)
	_expect(
		segment_shapes.size() == obstacle.collision_segments.size(),
		"B50: ogni voce di collision_segments deve produrre una CollisionShape2D dedicata."
	)

	# Zona trasparente (il vano centrale del filo, tra i due pali): un corpo
	# deve poterla attraversare senza essere bloccato.
	var through_gap := _make_probe_body(obstacle.global_position + Vector2(0.0, -200.0))
	fixture.add_child(through_gap)

	# Palo sinistro (parte opaca): un corpo allineato con esso deve restare bloccato.
	var into_post := _make_probe_body(obstacle.global_position + Vector2(-61.5, -200.0))
	fixture.add_child(into_post)

	await process_frame
	await physics_frame
	for _attempt in range(60):
		through_gap.velocity = Vector2.DOWN * 400.0
		through_gap.move_and_slide()
		into_post.velocity = Vector2.DOWN * 400.0
		into_post.move_and_slide()
		await physics_frame

	_expect(
		through_gap.global_position.y > obstacle.global_position.y + 100.0,
		(
			"B50: un corpo deve attraversare la zona trasparente al centro del filo dei panni (y=%s)."
			% through_gap.global_position.y
		)
	)
	_expect(
		into_post.global_position.y < obstacle.global_position.y - 100.0,
		(
			"B50: un corpo non deve attraversare il palo opaco del filo dei panni (y=%s)."
			% into_post.global_position.y
		)
	)

	paused = false
	fixture.queue_free()
	await process_frame


func _make_probe_body(start_position: Vector2) -> CharacterBody2D:
	var body := CharacterBody2D.new()
	body.collision_layer = 1
	body.collision_mask = OBSTACLE_LAYER_BIT
	body.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var body_shape := CollisionShape2D.new()
	var body_circle := CircleShape2D.new()
	body_circle.radius = 10.0
	body_shape.shape = body_circle
	body.add_child(body_shape)
	body.global_position = start_position
	return body


func _validate_camera_relative_spawn_reference() -> void:
	var fixture := Node2D.new()
	var arena := ArenaLayout.new()
	arena.respect_display_safe_area = false
	var camera := Camera2D.new()
	var spawner := EnemySpawner.new()
	fixture.add_child(arena)
	fixture.add_child(camera)
	fixture.add_child(spawner)
	root.add_child(fixture)
	await process_frame
	await process_frame

	spawner.configure(null, arena, null, null)
	var reference_without_camera := spawner.get_visible_reference_rect()
	_expect(
		reference_without_camera == arena.get_playfield_rect(),
		"Senza camera assegnata il riferimento deve restare il playfield di ArenaLayout."
	)

	camera.global_position = Vector2(500.0, -300.0)
	camera.reset_smoothing()
	await process_frame
	await process_frame
	spawner.configure(null, arena, null, null, camera)
	var reference_with_camera := spawner.get_visible_reference_rect()
	_expect_vector_near(
		reference_with_camera.get_center(),
		camera.global_position,
		"Con una camera assegnata il riferimento deve seguire la sua vista corrente."
	)
	_expect_vector_near(
		reference_with_camera.size,
		reference_without_camera.size,
		"La dimensione del riferimento deve restare quella dello schermo di ArenaLayout."
	)

	paused = false
	fixture.queue_free()
	await process_frame


func _validate_actor_obstacle_masks() -> void:
	for entry in [
		["Player", PLAYER_SCENE],
		["BaseEnemy", ENEMY_SCENE],
		["FirstBoss", BOSS_SCENE],
	]:
		var label: String = entry[0]
		var scene: PackedScene = entry[1]
		var instance := scene.instantiate() as CollisionObject2D
		_expect(
			instance != null and (instance.collision_mask & OBSTACLE_LAYER_BIT) != 0,
			"%s deve includere il layer Obstacle nella collision_mask." % label
		)
		if instance != null:
			# queue_free (non free diretto) libera anche l'intero sottoalbero
			# di figli della scena istanziata, evitando leak di ObjectDB.
			instance.queue_free()
	await process_frame


func _validate_composed_scene() -> void:
	root.content_scale_size = INITIAL_VIEWPORT_SIZE
	root.size = INITIAL_VIEWPORT_SIZE
	await process_frame
	await process_frame
	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	root.add_child(movement_slice)
	await process_frame
	await process_frame

	var arena_world := movement_slice.get_arena_world() as ArenaWorld
	var camera := movement_slice.get_camera() as Camera2D
	var arena_view := movement_slice.get_arena_view() as ArenaView
	var obstacles := movement_slice.get_node_or_null("World/Obstacles") as Node2D
	_expect(arena_world != null, "La scena composta deve contenere ArenaWorld.")
	_expect(camera != null, "La scena composta deve contenere la Camera2D del Player.")
	_expect(obstacles != null, "La scena composta deve contenere il contenitore Obstacles.")
	if arena_world == null or camera == null or obstacles == null or arena_view == null:
		paused = false
		movement_slice.queue_free()
		await process_frame
		return

	var world_rect := arena_world.get_world_rect()
	_expect(
		camera.limit_left == int(world_rect.position.x)
		and camera.limit_top == int(world_rect.position.y)
		and camera.limit_right == int(world_rect.end.x)
		and camera.limit_bottom == int(world_rect.end.y),
		"I limiti della camera devono coincidere con il rettangolo del mondo."
	)
	_expect(
		camera.drag_horizontal_enabled and camera.drag_vertical_enabled,
		"La camera deve restare stabile al centro e scorrere solo vicino ai bordi."
	)

	var expected_obstacle_count := 13
	_expect(
		obstacles.get_child_count() == expected_obstacle_count,
		"L'arena deve contenere %d ostacoli piazzati, trovati %d." % [
			expected_obstacle_count, obstacles.get_child_count()
		]
	)
	for child in obstacles.get_children():
		var obstacle := child as StaticObstacle
		_expect(obstacle != null, "Ogni figlio di Obstacles deve essere uno StaticObstacle.")
		if obstacle == null:
			continue
		_expect(
			not obstacle.name.begins_with("Fence"),
			"B50: le reti metalliche devono essere rimosse dall'arena, trovato %s." % obstacle.name
		)
		_expect(
			world_rect.grow(2.0).encloses(obstacle.get_footprint_rect()),
			"%s deve restare dentro l'arena." % obstacle.name
		)
		_expect(
			obstacle.texture != null,
			"%s deve avere gia' una texture assegnata invece del solo segnaposto." % obstacle.name
		)
		if obstacle.name.begins_with("Clothesline"):
			_expect(
				not obstacle.collision_segments.is_empty(),
				(
					"B50: %s deve collidere solo sulle parti opache tramite collision_segments."
					% obstacle.name
				)
			)

	_expect(
		arena_view.has_raster_background() and not arena_view.uses_procedural_fallback(),
		"Il pavimento della grigliata deve usare la texture ghiaia raster."
	)

	_expect(
		arena_view.boundary_thickness > 0.0,
		"B50: ArenaView deve dichiarare un delimitatore d'arena con spessore positivo."
	)
	for band in ArenaView.calculate_boundary_bands(world_rect, arena_view.boundary_thickness):
		_expect(
			world_rect.encloses(band),
			"B50: il delimitatore d'arena deve restare contenuto nel playfield, non essere un ostacolo."
		)

	paused = false
	movement_slice.queue_free()
	await process_frame
	root.content_scale_size = INITIAL_VIEWPORT_SIZE
	root.size = INITIAL_VIEWPORT_SIZE
	await process_frame


func _expect_vector_near(actual: Vector2, expected: Vector2, message: String) -> void:
	_expect(
		actual.distance_to(expected) <= FLOAT_TOLERANCE,
		"%s Atteso %s, ottenuto %s." % [message, expected, actual]
	)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	paused = false
	await process_frame
	if _failures.is_empty():
		print("B38_ARENA_WORLD_SMOKE_OK")
		quit(0)
		return
	for failure in _failures:
		printerr(failure)
	printerr("B38_ARENA_WORLD_SMOKE_FAIL count=%d" % _failures.size())
	quit(1)
