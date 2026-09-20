extends GutTest

## PS-189: da quando posizione e raggio dei vicini vivono negli array paralleli
## della fotografia di separazione, la posizione va riscritta a OGNI movimento.
## PS-178 copre gia' il movimento che cambia cella; qui si copre il caso nuovo,
## cioe' lo spostamento che resta dentro la stessa cella e che prima non
## richiedeva alcun aggiornamento, piu' il riuso della fotografia dopo un
## restart (gli slot del run precedente non devono sopravvivere).

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
	_target.position = Vector2(10000.0, 0.0)
	_fixture.add_child(_controller)
	_fixture.add_child(_target)
	add_child_autofree(_fixture)
	_controller.start_run(189)
	_enemies.clear()


func after_each() -> void:
	_controller.prepare_restart()


func test_movement_inside_the_same_cell_refreshes_neighbor_lookup() -> void:
	# Entrambi nella cella x = [0, 64): il movimento non cambia cella, quindi
	# la sola riassegnazione di cella non basterebbe a rendere visibile la
	# nuova posizione di `moving`.
	var moving := _spawn(Vector2(8.0, 0.0), 20.0)
	var observer := _spawn(Vector2(56.0, 0.0), 20.0)
	moving.move_speed = 900.0
	await get_tree().physics_frame

	assert_eq(observer._compute_separation_velocity(), Vector2.ZERO,
		"A 48 px di distanza i cerchi da 20 px non si toccano.")
	var before_cell := _cell_of(moving)
	moving._physics_process(1.0 / 60.0)
	assert_eq(_cell_of(moving), before_cell, "Il movimento deve restare nella stessa cella.")
	assert_gt(moving.global_position.x, 8.0, "Il nemico deve essersi mosso.")
	assert_gt(_all_pairs_push(observer).length(), 0.0, "Ora i cerchi devono sovrapporsi.")
	_assert_matches_all_pairs(observer)


func test_snapshot_is_rebuilt_after_restart_without_stale_slots() -> void:
	var survivor := _spawn(Vector2.ZERO, 20.0)
	_spawn(Vector2(10.0, 0.0), 20.0)
	await get_tree().physics_frame
	assert_gt(survivor._compute_separation_velocity().length(), 0.0)

	_controller.prepare_restart()
	_controller.start_run(1890)
	# Il nuovo run rinumera gli slot: un residuo del run precedente
	# scriverebbe la posizione di un nemico nello slot di un altro.
	var newcomer := _spawn(Vector2(-6.0, 0.0), 20.0)
	newcomer.move_speed = 900.0
	await get_tree().physics_frame
	_assert_matches_all_pairs(survivor)
	newcomer._physics_process(1.0 / 60.0)
	_assert_matches_all_pairs(survivor)


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


func _cell_of(enemy: BaseEnemy) -> Vector2i:
	return Vector2i(
		floori(enemy.global_position.x / BaseEnemy.SEPARATION_CELL_SIZE),
		floori(enemy.global_position.y / BaseEnemy.SEPARATION_CELL_SIZE)
	)


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
