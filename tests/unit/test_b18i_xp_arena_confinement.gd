extends GutGameplayTest

const VIEWPORT_CASES: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 720),
	Vector2i(960, 720),
]
const OUTSIDE_OFFSET := 120.0
const KILL_RETRY_LIMIT := 40


func test_xp_arena_confinement_across_viewports() -> void:
	for viewport_size in VIEWPORT_CASES:
		await _validate_viewport_case(viewport_size)


func _validate_viewport_case(viewport_size: Vector2i) -> void:
	var movement_slice := await instantiate_movement_slice(viewport_size)

	var controller := movement_slice.get_node_or_null("RunController") as RunController
	var arena := movement_slice.get_node_or_null("ArenaLayout") as ArenaLayout
	var spawner := movement_slice.get_node_or_null("EnemySpawner") as EnemySpawner
	var dropper := movement_slice.get_node_or_null("ExperienceDropper") as ExperienceDropper
	var player := movement_slice.get_node_or_null("World/Player") as Player
	var weapon: WeaponController
	if player != null:
		weapon = player.get_weapon_controller()

	assert_not_null(controller, "La fixture B18I deve contenere RunController.")
	assert_not_null(arena, "La fixture B18I deve contenere ArenaLayout.")
	assert_not_null(spawner, "La fixture B18I deve contenere EnemySpawner.")
	assert_not_null(dropper, "La fixture B18I deve contenere ExperienceDropper.")
	assert_not_null(player, "La fixture B18I deve contenere il Player.")
	if (
		controller == null
		or arena == null
		or spawner == null
		or dropper == null
		or player == null
		or weapon == null
	):
		return

	controller.set_process(false)
	spawner.set_process(false)
	player.set_physics_process(false)
	weapon.set_process(false)
	assert_true(controller.is_running(), "La fixture B18I deve partire in RUNNING.")
	assert_eq(dropper.get_arena_layout(), arena, "ExperienceDropper deve usare l'ArenaLayout della scena.")

	var arena_world := movement_slice.get_arena_world() as ArenaWorld
	assert_not_null(arena_world, "La fixture B18I deve contenere ArenaWorld.")
	if arena_world == null:
		return
	# Da B38 i pickup restano confinati nel mondo fisso di ArenaWorld, non
	# piu' nel playfield ritagliato sul viewport di ArenaLayout.
	var playfield := arena_world.get_world_rect()
	assert_true(playfield.has_area(), "Il mondo B18I deve essere valido.")
	var center := playfield.get_center()
	var death_positions: Array[Vector2] = [
		center,
		Vector2(playfield.position.x - OUTSIDE_OFFSET, center.y),
		Vector2(playfield.end.x + OUTSIDE_OFFSET, center.y),
		Vector2(center.x, playfield.position.y - OUTSIDE_OFFSET),
		Vector2(center.x, playfield.end.y + OUTSIDE_OFFSET),
		playfield.position - Vector2.ONE * OUTSIDE_OFFSET,
		Vector2(playfield.end.x, playfield.position.y) + Vector2(OUTSIDE_OFFSET, -OUTSIDE_OFFSET),
		Vector2(playfield.position.x, playfield.end.y) + Vector2(-OUTSIDE_OFFSET, OUTSIDE_OFFSET),
		playfield.end + Vector2.ONE * OUTSIDE_OFFSET,
	]

	for death_position in death_positions:
		var pickup := _kill_enemy_at(spawner, dropper, death_position)
		assert_not_null(pickup, "Ogni morte B18I deve produrre un pickup a %s." % death_position)
		if pickup == null:
			continue
		pickup.set_physics_process(false)
		var radius := pickup.get_confinement_radius()
		var expected_position := ArenaWorld.clamp_circle_center_in_rect(playfield, death_position, radius)
		assert_vector_near(
			pickup.global_position, expected_position, "Il drop deve usare il clamp circolare di ArenaWorld."
		)
		_assert_circle_inside(
			pickup.global_position, radius, playfield,
			"Il pickup deve restare interamente nel mondo (viewport %s)." % viewport_size
		)
		if death_position == center:
			assert_vector_near(
				pickup.global_position, death_position, "Una morte gia interna non deve essere spostata."
			)

	assert_eq(
		dropper.get_active_count(), death_positions.size(), "B18I deve registrare un solo pickup per ogni morte."
	)
	assert_true(controller.request_victory(), "La fixture B18I deve entrare in VICTORY.")
	assert_true(
		movement_slice.restart_run(18000 + viewport_size.x), "La fixture B18I deve accettare il restart."
	)
	assert_eq(dropper.get_active_count(), 0, "Il restart deve svuotare subito il registro pickup B18I.")
	await wait_process_frames(1)
	assert_eq(
		movement_slice.get_pickup_parent().get_child_count(), 0,
		"Il restart deve liberare tutti i pickup confinati entro fine frame."
	)

	controller.prepare_restart()


func _kill_enemy_at(
	spawner: EnemySpawner, dropper: ExperienceDropper, death_position: Vector2
) -> ExperiencePickup:
	# B28 assegna a ogni kill un credito XP frazionario: il pickup compare solo
	# quando il credito accumulato raggiunge un'unita'. B18I verifica dove atterra
	# il drop, non che ogni morte ne produca uno, quindi la kill viene ripetuta
	# nello stesso punto finche' il budget non emette il pickup.
	var active_before := dropper.get_active_count()
	for _attempt in range(KILL_RETRY_LIMIT):
		var enemy := spawner.try_spawn_enemy()
		if enemy == null:
			return null
		enemy.set_physics_process(false)
		enemy.get_contact_damage().set_physics_process(false)
		enemy.global_position = death_position
		var health := enemy.get_health_component()
		if health == null or not enemy.take_damage(health.health_current):
			return null
		var pickups := dropper.get_active_pickups()
		if pickups.size() == active_before + 1:
			return pickups.back()
		if pickups.size() != active_before:
			return null
	return null


func _assert_circle_inside(center: Vector2, radius: float, bounds: Rect2, text: String) -> void:
	assert_true(
		center.x - radius >= bounds.position.x - FLOAT_TOLERANCE
		and center.y - radius >= bounds.position.y - FLOAT_TOLERANCE
		and center.x + radius <= bounds.end.x + FLOAT_TOLERANCE
		and center.y + radius <= bounds.end.y + FLOAT_TOLERANCE,
		text
	)
