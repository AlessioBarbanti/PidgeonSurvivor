extends GutGameplayTest

const STATIC_OBSTACLE_SCENE: PackedScene = preload("res://scenes/game/obstacles/static_obstacle.tscn")
const PLAYER_SCENE: PackedScene = preload("res://scenes/actors/player.tscn")
const ENEMY_SCENE: PackedScene = preload("res://scenes/actors/base_enemy.tscn")
const BOSS_SCENE: PackedScene = preload("res://scenes/actors/first_boss.tscn")
const OBSTACLE_LAYER_BIT := 4


func test_arena_world_math() -> void:
	var world := ArenaWorld.new()
	world.world_size = Vector2(2400.0, 1500.0)
	world.world_origin = Vector2.ZERO
	var rect := world.get_world_rect()
	assert_true(
		rect == Rect2(Vector2(-1200.0, -750.0), Vector2(2400.0, 1500.0)),
		"Il rettangolo del mondo deve essere centrato sull'origine dichiarata."
	)
	assert_vector_near(world.get_world_center(), Vector2.ZERO, "Il centro del mondo deve coincidere con world_origin.")

	assert_vector_near(
		ArenaWorld.clamp_circle_center_in_rect(rect, Vector2.ZERO, 20.0), Vector2.ZERO,
		"Un punto gia' interno non deve essere spostato."
	)
	assert_vector_near(
		ArenaWorld.clamp_circle_center_in_rect(rect, Vector2(-5000.0, 0.0), 20.0),
		Vector2(rect.position.x + 20.0, 0.0),
		"Il clamp deve fermarsi al bordo minimo meno il raggio."
	)
	assert_vector_near(
		ArenaWorld.clamp_circle_center_in_rect(rect, Vector2(5000.0, 5000.0), 20.0),
		rect.end - Vector2.ONE * 20.0,
		"Il clamp deve fermarsi al bordo massimo meno il raggio."
	)
	assert_vector_near(
		ArenaWorld.clamp_circle_center_in_rect(Rect2(), Vector2(12.0, 34.0), 5.0),
		Vector2(12.0, 34.0),
		"Un rettangolo senza area non deve alterare il punto."
	)
	world.free()


func test_static_obstacle() -> void:
	var obstacle := STATIC_OBSTACLE_SCENE.instantiate() as StaticObstacle
	var fixture := Node2D.new()
	fixture.add_child(obstacle)
	add_child_autofree(fixture)
	await wait_process_frames(1)

	assert_true(
		obstacle.collision_layer == OBSTACLE_LAYER_BIT and obstacle.collision_mask == 0,
		"Il segnaposto ostacolo deve occupare solo il layer Obstacle."
	)
	obstacle.footprint_size = Vector2(240.0, 96.0)
	obstacle.global_position = Vector2(50.0, -30.0)
	var shape := obstacle.get_node("CollisionShape") as CollisionShape2D
	assert_true(
		shape.shape is RectangleShape2D and (shape.shape as RectangleShape2D).size == Vector2(240.0, 96.0),
		"Cambiare footprint_size deve ridimensionare la CollisionShape2D."
	)
	assert_true(
		obstacle.get_footprint_rect() == Rect2(Vector2(-70.0, -78.0), Vector2(240.0, 96.0)),
		"get_footprint_rect deve riflettere posizione e dimensione correnti."
	)


func test_boundary_bands_math() -> void:
	var rect := Rect2(Vector2(-1200.0, -750.0), Vector2(2400.0, 1500.0))
	var bands := ArenaView.calculate_boundary_bands(rect, 28.0)
	assert_true(
		bands.size() == 4, "calculate_boundary_bands deve produrre quattro bande (alto, basso, sinistra, destra)."
	)
	for band in bands:
		assert_true(rect.encloses(band), "B50: ogni banda del delimitatore deve restare contenuta nel playfield.")
	assert_true(
		ArenaView.calculate_boundary_bands(rect, 0.0).is_empty(), "Uno spessore nullo non deve produrre bande."
	)
	assert_true(
		ArenaView.calculate_boundary_bands(Rect2(), 28.0).is_empty(),
		"Un rettangolo senza area non deve produrre bande."
	)
	var oversized := ArenaView.calculate_boundary_bands(Rect2(Vector2.ZERO, Vector2(40.0, 20.0)), 100.0)
	for band in oversized:
		assert_true(
			Rect2(Vector2.ZERO, Vector2(40.0, 20.0)).encloses(band),
			"Uno spessore piu' grande del playfield deve restare comunque contenuto (clamp)."
		)


func test_obstacle_blocks_movement() -> void:
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
	add_child_autofree(fixture)
	await wait_process_frames(1)
	await wait_physics_frames(1)

	for _attempt in range(60):
		body.velocity = Vector2.RIGHT * 400.0
		body.move_and_slide()
		await wait_physics_frames(1)

	assert_true(
		body.global_position.x < 195.0,
		"Un corpo con maschera Obstacle non deve attraversare uno StaticObstacle (x=%s)." % body.global_position.x
	)


func test_obstacle_collision_segments_block_only_opaque_parts() -> void:
	var fixture := Node2D.new()
	var obstacle := STATIC_OBSTACLE_SCENE.instantiate() as StaticObstacle
	obstacle.footprint_size = Vector2(150.0, 250.0)
	obstacle.collision_segments = [
		Rect2(-0.5, -0.5, 0.18, 1.0),
		Rect2(0.32, -0.5, 0.18, 1.0),
	]
	obstacle.global_position = Vector2(300.0, 0.0)
	fixture.add_child(obstacle)
	add_child_autofree(fixture)
	await wait_process_frames(1)
	await wait_physics_frames(1)

	var main_shape := obstacle.get_node("CollisionShape") as CollisionShape2D
	assert_true(
		main_shape.disabled,
		"B50: la CollisionShape2D piena deve disattivarsi quando collision_segments non e' vuoto."
	)
	var segment_shapes: Array[CollisionShape2D] = []
	for child in obstacle.get_children():
		if child is CollisionShape2D and child != main_shape:
			segment_shapes.append(child)
	assert_true(
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

	await wait_process_frames(1)
	await wait_physics_frames(1)
	for _attempt in range(60):
		through_gap.velocity = Vector2.DOWN * 400.0
		through_gap.move_and_slide()
		into_post.velocity = Vector2.DOWN * 400.0
		into_post.move_and_slide()
		await wait_physics_frames(1)

	assert_true(
		through_gap.global_position.y > obstacle.global_position.y + 100.0,
		(
			"B50: un corpo deve attraversare la zona trasparente al centro del filo dei panni (y=%s)."
			% through_gap.global_position.y
		)
	)
	assert_true(
		into_post.global_position.y < obstacle.global_position.y - 100.0,
		(
			"B50: un corpo non deve attraversare il palo opaco del filo dei panni (y=%s)."
			% into_post.global_position.y
		)
	)


func _make_probe_body(start_position: Vector2, radius: float = 10.0) -> CharacterBody2D:
	var body := CharacterBody2D.new()
	body.collision_layer = 1
	body.collision_mask = OBSTACLE_LAYER_BIT
	body.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var body_shape := CollisionShape2D.new()
	var body_circle := CircleShape2D.new()
	body_circle.radius = radius
	body_shape.shape = body_circle
	body.add_child(body_shape)
	body.global_position = start_position
	return body


func test_ps165_clothesline_collision_matches_visual_poles() -> void:
	# PS-165: l'artwork del filo dei panni disegna i due pali in prospettiva
	# diagonale (palo sinistro solo nella meta' inferiore del footprint, palo
	# destro solo nella meta' superiore). I segmenti di produzione correnti
	# (stessi valori usati in movement_slice.tscn) devono lasciare attraversabile
	# il "cielo" vuoto sopra il palo sinistro e sotto il palo destro, restando
	# comunque bloccanti sul legno reale di ciascun palo.
	var fixture := Node2D.new()
	var obstacle := STATIC_OBSTACLE_SCENE.instantiate() as StaticObstacle
	obstacle.footprint_size = Vector2(150.0, 250.0)
	obstacle.collision_segments = [
		Rect2(-0.43, 0.03, 0.19, 0.47),
		Rect2(0.27, -0.5, 0.19, 0.45),
	]
	obstacle.global_position = Vector2(300.0, 0.0)
	fixture.add_child(obstacle)

	# Scende lungo la colonna del palo sinistro: con i vecchi segmenti a tutta
	# altezza si fermava subito sotto y=-125 (bordo superiore del footprint).
	var down_left_column := _make_probe_body(obstacle.global_position + Vector2(-50.0, -200.0))
	# Sale lungo la colonna del palo destro: con i vecchi segmenti a tutta
	# altezza si fermava subito sopra y=125 (bordo inferiore del footprint).
	var up_right_column := _make_probe_body(obstacle.global_position + Vector2(55.0, 200.0))
	fixture.add_child(down_left_column)
	fixture.add_child(up_right_column)
	add_child_autofree(fixture)
	await wait_process_frames(1)
	await wait_physics_frames(1)

	for _attempt in range(60):
		down_left_column.velocity = Vector2.DOWN * 400.0
		down_left_column.move_and_slide()
		up_right_column.velocity = Vector2.UP * 400.0
		up_right_column.move_and_slide()
		await wait_physics_frames(1)

	assert_true(
		down_left_column.global_position.y > obstacle.global_position.y - 50.0,
		(
			"PS-165: sopra il palo sinistro l'artwork e' vuoto, un corpo deve poter "
			+ "avanzare oltre il vecchio bordo pieno a y=-125 (y=%s)."
		) % down_left_column.global_position.y
	)
	assert_true(
		down_left_column.global_position.y < obstacle.global_position.y + 50.0,
		"PS-165: il legno reale del palo sinistro deve restare bloccante (y=%s)."
			% down_left_column.global_position.y
	)
	assert_true(
		up_right_column.global_position.y < obstacle.global_position.y + 50.0,
		(
			"PS-165: sotto il palo destro l'artwork e' vuoto, un corpo deve poter "
			+ "avanzare oltre il vecchio bordo pieno a y=125 (y=%s)."
		) % up_right_column.global_position.y
	)
	assert_true(
		up_right_column.global_position.y > obstacle.global_position.y - 50.0,
		"PS-165: il legno reale del palo destro deve restare bloccante (y=%s)."
			% up_right_column.global_position.y
	)


func test_ps165_diagonal_movement_slides_along_obstacle_edge() -> void:
	# PS-165: un urto obliquo contro un bordo dritto non deve azzerare la
	# componente di movimento tangenziale (il corpo deve scorrere lungo il
	# bordo invece di inchiodarsi).
	var fixture := Node2D.new()
	var obstacle := STATIC_OBSTACLE_SCENE.instantiate() as StaticObstacle
	obstacle.footprint_size = Vector2(200.0, 400.0)
	obstacle.global_position = Vector2(300.0, 0.0)
	fixture.add_child(obstacle)

	# Muro alto (400px) per restare sulla faccia piatta per tutta la finestra di
	# misura: con 60 tentativi a 300px/s la componente Y libera percorre circa
	# 212px, ben dentro il muro (bordo inferiore a y=200) e lontana dall'angolo,
	# cosi' la prova osserva solo lo scorrimento e non l'aggiramento dello spigolo.
	var probe := _make_probe_body(Vector2(100.0, -150.0), 24.0)
	fixture.add_child(probe)
	add_child_autofree(fixture)
	await wait_process_frames(1)
	await wait_physics_frames(1)

	for _attempt in range(60):
		probe.velocity = Vector2(1.0, 1.0).normalized() * 300.0
		probe.move_and_slide()
		await wait_physics_frames(1)

	assert_true(
		probe.global_position.x < 190.0,
		"PS-165: il corpo non deve attraversare il nucleo solido del muro (x=%s)."
			% probe.global_position.x
	)
	assert_true(
		probe.global_position.y > 0.0,
		(
			"PS-165: la componente tangenziale deve restare viva e far scorrere il "
			+ "corpo lungo il bordo invece di inchiodarlo (y=%s)."
		) % probe.global_position.y
	)


func test_ps165_corridor_as_wide_as_player_diameter_is_crossable() -> void:
	# PS-165: un corridoio poco piu' largo del diametro del collider Player
	# (56px contro un diametro di 48px, collision_radius 24) deve restare
	# davvero attraversabile. Il gap piu' stretto fra prop reali dell'arena
	# misura 92px (Clothesline-BenchD), quindi questa tolleranza minima resta
	# comunque piu' severa di qualunque corridoio oggi presente in gioco.
	# Nota: un gap esattamente pari al diametro (zero clearance) produce un
	# doppio contatto d'angolo simultaneo alla bocca del corridoio che puo'
	# incastrare move_and_slide() indipendentemente dalla geometria del prop
	# (verificato empiricamente) - non e' il caso rappresentato da nessun prop
	# reale, quindi non e' nello scopo di questa card introdurre una
	# mitigazione motore per quel caso degenere.
	var fixture := Node2D.new()
	var wall_left := STATIC_OBSTACLE_SCENE.instantiate() as StaticObstacle
	wall_left.footprint_size = Vector2(100.0, 300.0)
	wall_left.global_position = Vector2(-78.0, 0.0)
	var wall_right := STATIC_OBSTACLE_SCENE.instantiate() as StaticObstacle
	wall_right.footprint_size = Vector2(100.0, 300.0)
	wall_right.global_position = Vector2(78.0, 0.0)
	fixture.add_child(wall_left)
	fixture.add_child(wall_right)

	var probe := _make_probe_body(Vector2(0.0, -300.0), 24.0)
	fixture.add_child(probe)
	add_child_autofree(fixture)
	await wait_process_frames(1)
	await wait_physics_frames(1)

	for _attempt in range(90):
		probe.velocity = Vector2.DOWN * 400.0
		probe.move_and_slide()
		await wait_physics_frames(1)

	assert_true(
		probe.global_position.y > 200.0,
		(
			"PS-165: un corridoio largo quanto il diametro del Player deve restare "
			+ "attraversabile (y=%s)."
		) % probe.global_position.y
	)
	print("PS165_PROP_COLLISION_SLIDE_SMOKE_OK")


func test_camera_relative_spawn_reference() -> void:
	# PS-165: senza forzare esplicitamente la dimensione del viewport (come
	# fanno gia' altri test dipendenti dallo schermo, es. test_b18o_welcome_flow.gd),
	# get_tree().root.size puo' non essersi ancora assestato su
	# INITIAL_VIEWPORT_SIZE quando questo e' fra i primi test eseguiti in un
	# processo Godot appena avviato, facendo leggere a get_viewport_rect() una
	# dimensione transitoria diversa da quella richiesta con --resolution.
	get_tree().root.content_scale_size = INITIAL_VIEWPORT_SIZE
	get_tree().root.size = INITIAL_VIEWPORT_SIZE
	await wait_process_frames(2)

	var fixture := Node2D.new()
	var arena := ArenaLayout.new()
	arena.respect_display_safe_area = false
	var camera := Camera2D.new()
	var spawner := EnemySpawner.new()
	fixture.add_child(arena)
	fixture.add_child(camera)
	fixture.add_child(spawner)
	add_child_autofree(fixture)
	await wait_process_frames(2)

	spawner.configure(null, arena, null, null)
	var reference_without_camera := spawner.get_visible_reference_rect()
	assert_true(
		reference_without_camera == arena.get_playfield_rect(),
		"Senza camera assegnata il riferimento deve restare il playfield di ArenaLayout."
	)

	camera.global_position = Vector2(500.0, -300.0)
	camera.reset_smoothing()
	await wait_process_frames(2)
	spawner.configure(null, arena, null, null, camera)
	var reference_with_camera := spawner.get_visible_reference_rect()
	assert_vector_near(
		reference_with_camera.get_center(), camera.global_position,
		"Con una camera assegnata il riferimento deve seguire la sua vista corrente."
	)
	assert_vector_near(
		reference_with_camera.size, reference_without_camera.size,
		"La dimensione del riferimento deve restare quella dello schermo di ArenaLayout."
	)


func test_actor_obstacle_masks() -> void:
	for entry in [
		["Player", PLAYER_SCENE],
		["BaseEnemy", ENEMY_SCENE],
		["FirstBoss", BOSS_SCENE],
	]:
		var label: String = entry[0]
		var scene: PackedScene = entry[1]
		var instance := scene.instantiate() as CollisionObject2D
		assert_true(
			instance != null and (instance.collision_mask & OBSTACLE_LAYER_BIT) != 0,
			"%s deve includere il layer Obstacle nella collision_mask." % label
		)
		if instance != null:
			instance.free()


func test_composed_scene() -> void:
	var movement_slice := await instantiate_movement_slice()

	var arena_world := movement_slice.get_arena_world() as ArenaWorld
	var camera := movement_slice.get_camera() as Camera2D
	var arena_view := movement_slice.get_arena_view() as ArenaView
	var obstacles := movement_slice.get_node_or_null("World/Obstacles") as Node2D
	assert_true(arena_world != null, "La scena composta deve contenere ArenaWorld.")
	assert_true(camera != null, "La scena composta deve contenere la Camera2D del Player.")
	assert_true(obstacles != null, "La scena composta deve contenere il contenitore Obstacles.")
	if arena_world == null or camera == null or obstacles == null or arena_view == null:
		return

	var world_rect := arena_world.get_world_rect()
	assert_true(
		camera.limit_left == int(world_rect.position.x)
		and camera.limit_top == int(world_rect.position.y)
		and camera.limit_right == int(world_rect.end.x)
		and camera.limit_bottom == int(world_rect.end.y),
		"I limiti della camera devono coincidere con il rettangolo del mondo."
	)
	assert_true(
		camera.drag_horizontal_enabled and camera.drag_vertical_enabled,
		"La camera deve restare stabile al centro e scorrere solo vicino ai bordi."
	)

	var expected_obstacle_count := 15
	assert_true(
		obstacles.get_child_count() == expected_obstacle_count,
		"L'arena deve contenere %d ostacoli piazzati, trovati %d." % [expected_obstacle_count, obstacles.get_child_count()]
	)
	for child in obstacles.get_children():
		var obstacle := child as StaticObstacle
		assert_true(obstacle != null, "Ogni figlio di Obstacles deve essere uno StaticObstacle.")
		if obstacle == null:
			continue
		assert_true(
			not obstacle.name.begins_with("Fence"),
			"B50: le reti metalliche devono essere rimosse dall'arena, trovato %s." % obstacle.name
		)
		assert_true(
			world_rect.grow(2.0).encloses(obstacle.get_footprint_rect()), "%s deve restare dentro l'arena." % obstacle.name
		)
		assert_true(
			obstacle.texture != null,
			"%s deve avere una texture assegnata invece del solo segnaposto." % obstacle.name
		)
		if obstacle.name.begins_with("Clothesline"):
			assert_true(
				not obstacle.collision_segments.is_empty(),
				"B50: %s deve collidere solo sulle parti opache tramite collision_segments." % obstacle.name
			)

	assert_true(
		arena_view.has_raster_background() and not arena_view.uses_procedural_fallback(),
		"Il pavimento della grigliata deve usare la texture ghiaia raster."
	)

	assert_true(
		arena_view.boundary_thickness > 0.0,
		"B50: ArenaView deve dichiarare un delimitatore d'arena con spessore positivo."
	)
	for band in ArenaView.calculate_boundary_bands(world_rect, arena_view.boundary_thickness):
		assert_true(
			world_rect.encloses(band),
			"B50: il delimitatore d'arena deve restare contenuto nel playfield, non essere un ostacolo."
		)
