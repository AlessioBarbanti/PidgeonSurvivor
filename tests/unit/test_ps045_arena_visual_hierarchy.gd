extends GutGameplayTest

## PS-045: verifica che gli ostacoli dell'arena restino contenuti nel
## playfield, lascino spazio di manovra al centro, non formino coppie
## specchiate e usino piu' famiglie di prop, restando stabili in 16:9, 20:9 e
## 4:3. La qualita' percettiva della composizione resta un gate manuale.

const CENTER_CLEARANCE_HALF_SIZE := Vector2(200.0, 200.0)
const ASPECT_PROFILES: Dictionary = {
	"16:9": Vector2i(1280, 720),
	"20:9": Vector2i(1600, 720),
	"4:3": Vector2i(960, 720),
}


func test_ps045_arena_visual_hierarchy() -> void:
	var slice := await instantiate_movement_slice()
	var arena_world := slice.get_arena_world() as ArenaWorld
	var arena_layout := slice.get_arena_layout() as ArenaLayout
	var obstacles := slice.get_node_or_null("World/Obstacles") as Node2D
	assert_true(
		arena_world != null and arena_layout != null and obstacles != null,
		"La scena composta deve esporre ArenaWorld, ArenaLayout e Obstacles."
	)
	if arena_world == null or arena_layout == null or obstacles == null:
		return

	var world_rect := arena_world.get_world_rect()
	var center_clearance := Rect2(
		arena_world.get_world_center() - CENTER_CLEARANCE_HALF_SIZE,
		CENTER_CLEARANCE_HALF_SIZE * 2.0
	)

	var static_obstacles: Array[StaticObstacle] = []
	for child in obstacles.get_children():
		var obstacle := child as StaticObstacle
		assert_true(obstacle != null, "Ogni figlio di Obstacles deve essere uno StaticObstacle.")
		if obstacle == null:
			continue
		static_obstacles.append(obstacle)
		assert_true(
			world_rect.grow(2.0).encloses(obstacle.get_footprint_rect()),
			"%s deve restare contenuto nel playfield." % obstacle.name
		)
		assert_true(
			not obstacle.get_footprint_rect().intersects(center_clearance),
			"%s invade lo spazio minimo di manovra al centro dell'arena." % obstacle.name
		)

	# Nessuna coppia di prop della stessa famiglia deve restare l'immagine
	# speculare di un'altra: la composizione deve leggersi come irregolare.
	for i in static_obstacles.size():
		for j in range(i + 1, static_obstacles.size()):
			var a := static_obstacles[i]
			var b := static_obstacles[j]
			if a.footprint_size != b.footprint_size:
				continue
			var mirrored_horizontally := (
				is_equal_approx(a.position.x, -b.position.x)
				and is_equal_approx(a.position.y, b.position.y)
			)
			assert_false(
				mirrored_horizontally,
				(
					"%s e %s formano una coppia specchiata: la composizione deve restare irregolare."
					% [a.name, b.name]
				)
			)

	var families: Dictionary = {}
	for obstacle in static_obstacles:
		if obstacle.texture != null:
			families[obstacle.texture.resource_path] = true
		else:
			families[obstacle.name] = true
	assert_true(
		families.size() >= 3,
		"L'arena deve raccogliere prop di almeno tre famiglie diverse, trovate %d." % families.size()
	)

	for aspect_name in ASPECT_PROFILES:
		var viewport_size: Vector2i = ASPECT_PROFILES[aspect_name]
		get_tree().root.content_scale_size = viewport_size
		get_tree().root.size = viewport_size
		await wait_process_frames(2)
		arena_layout.refresh_layout()
		await wait_process_frames(1)
		assert_true(
			arena_layout.get_playfield_rect().has_area(),
			"Il playfield deve restare valido in %s." % aspect_name
		)
		for obstacle in static_obstacles:
			assert_true(
				world_rect.grow(2.0).encloses(obstacle.get_footprint_rect()),
				"%s deve restare dentro l'arena anche in %s." % [obstacle.name, aspect_name]
			)

	print("ARENA_VISUAL_HIERARCHY_SMOKE_OK")
