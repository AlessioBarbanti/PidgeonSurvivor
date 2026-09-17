extends GutTest

const ENEMY_SCENE: PackedScene = preload("res://scenes/actors/base_enemy.tscn")
const TOLERANCE := 0.001

var _fixture: Node2D
var _controller: RunController
var _target: Node2D
var _enemies: Array[BaseEnemy] = []


func before_each() -> void:
	_fixture = Node2D.new()
	_controller = RunController.new()
	_controller.set_process(false)
	_target = Node2D.new()
	_target.position = Vector2(1000.0, 0.0)
	_fixture.add_child(_controller)
	_fixture.add_child(_target)
	add_child_autofree(_fixture)
	_controller.start_run(178)
	_enemies.clear()


func after_each() -> void:
	_controller.prepare_restart()


func test_query_matches_all_pairs_across_cells_and_large_radii() -> void:
	var radii: Array[float] = [13.0, 20.0, 28.0, 128.0, 190.0]
	for index in 60:
		_spawn(Vector2(float(index % 10) * 61.0 - 250.0,
			float(index / 10) * 63.0 - 180.0), radii[index % radii.size()])
	# Include centri coincidenti e il confine esatto fra celle negative/positive.
	_spawn(Vector2.ZERO, 20.0)
	_spawn(Vector2.ZERO, 20.0)
	_spawn(Vector2(-0.01, -64.01), 28.0)
	_spawn(Vector2(0.01, -63.99), 13.0)
	await get_tree().physics_frame
	for enemy in _enemies:
		_assert_matches_all_pairs(enemy)


func test_radius_growth_refreshes_query_reach_in_same_frame() -> void:
	var observer := _spawn(Vector2.ZERO, 20.0)
	var growing := _spawn(Vector2(150.0, 0.0), 20.0)
	await get_tree().physics_frame
	assert_eq(observer._compute_separation_velocity(), Vector2.ZERO)
	growing.collision_radius = 160.0
	assert_gt(_all_pairs_push(observer).length(), 0.0)
	_assert_matches_all_pairs(observer)


func test_movement_updates_neighbor_lookup_in_same_physics_frame() -> void:
	var moving := _spawn(Vector2(63.0, 0.0), 20.0)
	var observer := _spawn(Vector2(125.0, 0.0), 20.0)
	moving.move_speed = 1800.0
	await get_tree().physics_frame
	assert_eq(observer._compute_separation_velocity(), Vector2.ZERO)
	moving._physics_process(1.0 / 60.0)
	assert_gt(moving.global_position.x, 64.0, "Il movimento deve attraversare la cella.")
	assert_gt(_all_pairs_push(observer).length(), 0.0, "Ora i cerchi devono sovrapporsi.")
	_assert_matches_all_pairs(observer)


func test_knockback_updates_neighbor_lookup_in_same_physics_frame() -> void:
	var moving := _spawn(Vector2(63.0, 0.0), 20.0)
	var observer := _spawn(Vector2(125.0, 0.0), 20.0)
	await get_tree().physics_frame
	assert_eq(observer._compute_separation_velocity(), Vector2.ZERO)
	assert_true(moving.apply_knockback(Vector2(1800.0, 0.0), 1.0))
	moving._physics_process(1.0 / 60.0)
	assert_gt(moving.global_position.x, 64.0)
	assert_gt(_all_pairs_push(observer).length(), 0.0)
	_assert_matches_all_pairs(observer)


func test_dead_and_foreign_controller_neighbors_do_not_push() -> void:
	var observer := _spawn(Vector2.ZERO, 20.0)
	var dying := _spawn(Vector2(10.0, 0.0), 20.0)
	var foreign := _spawn(Vector2(-10.0, 0.0), 20.0)
	var other_controller := RunController.new()
	other_controller.set_process(false)
	_fixture.add_child(other_controller)
	other_controller.start_run(179)
	foreign.set_run_controller(other_controller)
	await get_tree().physics_frame
	_assert_matches_all_pairs(observer)
	assert_gt(observer._compute_separation_velocity().length(), 0.0)
	assert_true(dying.take_damage(100000.0))
	_assert_matches_all_pairs(observer)
	assert_eq(observer._compute_separation_velocity(), Vector2.ZERO)
	other_controller.prepare_restart()


func _spawn(position_value: Vector2, radius: float) -> BaseEnemy:
	var enemy := ENEMY_SCENE.instantiate() as BaseEnemy
	enemy.position = position_value
	enemy.collision_radius = radius
	_fixture.add_child(enemy)
	enemy.set_physics_process(false)
	enemy.set_run_controller(_controller)
	enemy.set_target(_target)
	_enemies.append(enemy)
	return enemy


## Oracolo senza griglia: visita l'intera popolazione e calcola la geometria.
func _all_pairs_push(enemy: BaseEnemy) -> Vector2:
	var push := Vector2.ZERO
	for other in _enemies:
		if not is_instance_valid(other) or other == enemy or not other.is_alive():
			continue
		if other.get_run_controller() != enemy.get_run_controller():
			continue
		var offset := enemy.global_position - other.global_position
		var distance := offset.length()
		var overlap := enemy.collision_radius + other.collision_radius - distance
		if overlap <= 0.0:
			continue
		var direction := offset / distance if distance > 0.0001 else Vector2.RIGHT
		push += direction * overlap * 4.0
	return push.limit_length(enemy.get_effective_move_speed() * 2.0)


func _assert_matches_all_pairs(enemy: BaseEnemy) -> void:
	var expected := _all_pairs_push(enemy)
	var actual := enemy._compute_separation_velocity()
	assert_almost_eq(actual.x, expected.x, TOLERANCE, "Spinta X uguale alla ricerca completa.")
	assert_almost_eq(actual.y, expected.y, TOLERANCE, "Spinta Y uguale alla ricerca completa.")
