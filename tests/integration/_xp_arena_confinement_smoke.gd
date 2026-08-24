extends SceneTree

const MOVEMENT_SLICE_SCENE: PackedScene = preload(
	"res://scenes/game/movement_slice.tscn"
)
const VIEWPORT_CASES: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 720),
	Vector2i(960, 720),
]
const OUTSIDE_OFFSET := 120.0
const FLOAT_TOLERANCE := 0.001

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	paused = false
	await process_frame
	for viewport_size in VIEWPORT_CASES:
		await _validate_viewport_case(viewport_size)
	await _finish()


func _validate_viewport_case(viewport_size: Vector2i) -> void:
	root.content_scale_size = viewport_size
	root.size = viewport_size
	await _wait_processed_frame()

	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	root.add_child(movement_slice)
	await _wait_processed_frame()

	var controller := movement_slice.get_node_or_null("RunController") as RunController
	var arena := movement_slice.get_node_or_null("ArenaLayout") as ArenaLayout
	var spawner := movement_slice.get_node_or_null("EnemySpawner") as EnemySpawner
	var dropper := movement_slice.get_node_or_null(
		"ExperienceDropper"
	) as ExperienceDropper
	var player := movement_slice.get_node_or_null("World/Player") as Player
	var weapon: WeaponController
	if player != null:
		weapon = player.get_weapon_controller()

	_expect(controller != null, "La fixture B18I deve contenere RunController.")
	_expect(arena != null, "La fixture B18I deve contenere ArenaLayout.")
	_expect(spawner != null, "La fixture B18I deve contenere EnemySpawner.")
	_expect(dropper != null, "La fixture B18I deve contenere ExperienceDropper.")
	_expect(player != null, "La fixture B18I deve contenere il Player.")
	if (
		controller == null
		or arena == null
		or spawner == null
		or dropper == null
		or player == null
		or weapon == null
	):
		await _release_fixture(movement_slice)
		return

	controller.set_process(false)
	spawner.set_process(false)
	player.set_physics_process(false)
	weapon.set_process(false)
	_expect(controller.is_running(), "La fixture B18I deve partire in RUNNING.")
	_expect(
		dropper.get_arena_layout() == arena,
		"ExperienceDropper deve usare l'ArenaLayout della scena."
	)

	var playfield := arena.get_playfield_rect()
	_expect(playfield.has_area(), "Il playfield B18I deve essere valido.")
	var center := playfield.get_center()
	var death_positions: Array[Vector2] = [
		center,
		Vector2(playfield.position.x - OUTSIDE_OFFSET, center.y),
		Vector2(playfield.end.x + OUTSIDE_OFFSET, center.y),
		Vector2(center.x, playfield.position.y - OUTSIDE_OFFSET),
		Vector2(center.x, playfield.end.y + OUTSIDE_OFFSET),
		playfield.position - Vector2.ONE * OUTSIDE_OFFSET,
		Vector2(playfield.end.x, playfield.position.y)
			+ Vector2(OUTSIDE_OFFSET, -OUTSIDE_OFFSET),
		Vector2(playfield.position.x, playfield.end.y)
			+ Vector2(-OUTSIDE_OFFSET, OUTSIDE_OFFSET),
		playfield.end + Vector2.ONE * OUTSIDE_OFFSET,
	]

	for death_position in death_positions:
		var pickup := _kill_enemy_at(spawner, dropper, death_position)
		_expect(
			pickup != null,
			"Ogni morte B18I deve produrre un pickup a %s." % death_position
		)
		if pickup == null:
			continue
		pickup.set_physics_process(false)
		var radius := pickup.get_confinement_radius()
		var expected_position := arena.clamp_circle_center(death_position, radius)
		_expect_vector_near(
			pickup.global_position,
			expected_position,
			"Il drop deve usare il clamp circolare di ArenaLayout."
		)
		_expect_circle_inside(
			pickup.global_position,
			radius,
			playfield,
			"Il pickup deve restare interamente nel playfield %s." % viewport_size
		)
		if death_position == center:
			_expect_vector_near(
				pickup.global_position,
				death_position,
				"Una morte gia interna non deve essere spostata."
			)

	_expect(
		dropper.get_active_count() == death_positions.size(),
		"B18I deve registrare un solo pickup per ogni morte."
	)
	_expect(controller.request_victory(), "La fixture B18I deve entrare in VICTORY.")
	_expect(
		movement_slice.restart_run(18000 + viewport_size.x),
		"La fixture B18I deve accettare il restart."
	)
	_expect(
		dropper.get_active_count() == 0,
		"Il restart deve svuotare subito il registro pickup B18I."
	)
	await process_frame
	_expect(
		movement_slice.get_pickup_parent().get_child_count() == 0,
		"Il restart deve liberare tutti i pickup confinati entro fine frame."
	)

	controller.prepare_restart()
	await _release_fixture(movement_slice)


func _kill_enemy_at(
	spawner: EnemySpawner,
	dropper: ExperienceDropper,
	death_position: Vector2
) -> ExperiencePickup:
	var active_before := dropper.get_active_count()
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
	if pickups.size() != active_before + 1:
		return null
	return pickups.back()


func _expect_circle_inside(
	center: Vector2,
	radius: float,
	bounds: Rect2,
	message: String
) -> void:
	_expect(
		center.x - radius >= bounds.position.x - FLOAT_TOLERANCE
		and center.y - radius >= bounds.position.y - FLOAT_TOLERANCE
		and center.x + radius <= bounds.end.x + FLOAT_TOLERANCE
		and center.y + radius <= bounds.end.y + FLOAT_TOLERANCE,
		message
	)


func _release_fixture(movement_slice: Control) -> void:
	paused = false
	movement_slice.queue_free()
	await process_frame


func _wait_processed_frame() -> void:
	await process_frame
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
		print("B18I_XP_ARENA_CONFINEMENT_SMOKE_OK")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	printerr("B18I_XP_ARENA_CONFINEMENT_SMOKE_FAIL count=%d" % _failures.size())
	quit(1)
