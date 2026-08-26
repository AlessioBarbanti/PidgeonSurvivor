class_name EnemySpawner
extends Node

signal enemy_spawned(enemy: BaseEnemy)
signal enemy_removed(enemy_instance_id: int)

@export var enemy_scene: PackedScene
@export var spawn_profile: EnemySpawnProfile

var _run_controller: RunController
var _arena_layout: ArenaLayout
var _target: Node2D
var _enemy_parent: Node
var _spawned_enemies: Array[BaseEnemy] = []
var _rng := RandomNumberGenerator.new()
var _spawn_elapsed := 0.0
var _cleanup_elapsed := 0.0
var _awaiting_initial_spawn := true
var _invalid_scene_warning_emitted := false


func _ready() -> void:
	_rng.seed = 1


func _process(delta: float) -> void:
	if not _can_run_scheduler():
		return

	var safe_delta := maxf(delta, 0.0)
	_spawn_elapsed += safe_delta
	_cleanup_elapsed += safe_delta

	var cleanup_interval := spawn_profile.get_effective_cleanup_interval()
	if _cleanup_elapsed >= cleanup_interval:
		_cleanup_elapsed = 0.0
		cleanup_outside_despawn_rect()

	var interval := spawn_profile.initial_spawn_delay
	if not _awaiting_initial_spawn:
		interval = spawn_profile.get_spawn_interval(
			_run_controller.get_run_time()
		)
	if _spawn_elapsed < interval:
		return

	if get_alive_count() >= spawn_profile.max_alive_enemies:
		_spawn_elapsed = minf(_spawn_elapsed, interval)
		return

	var enemy := try_spawn_enemy()
	if enemy == null:
		_spawn_elapsed = minf(_spawn_elapsed, interval)
		return

	_spawn_elapsed = 0.0
	_awaiting_initial_spawn = false


func configure(
	run_controller: RunController,
	arena_layout: ArenaLayout,
	target: Node2D,
	enemy_parent: Node
) -> void:
	set_run_controller(run_controller)
	_arena_layout = arena_layout
	_target = target
	_enemy_parent = enemy_parent


func set_run_controller(value: RunController) -> void:
	if value == _run_controller:
		return

	_disconnect_run_controller()
	_run_controller = value
	if not is_instance_valid(_run_controller):
		return

	if not _run_controller.run_started.is_connected(_on_run_started):
		_run_controller.run_started.connect(_on_run_started)
	if not _run_controller.restart_prepared.is_connected(_on_restart_prepared):
		_run_controller.restart_prepared.connect(_on_restart_prepared)


func get_run_controller() -> RunController:
	return _run_controller


func get_arena_layout() -> ArenaLayout:
	return _arena_layout


func get_target() -> Node2D:
	return _target


func get_enemy_parent() -> Node:
	return _enemy_parent


func reset_for_run(seed_value: int, clear_existing: bool = true) -> void:
	_rng.seed = seed_value
	_spawn_elapsed = 0.0
	_cleanup_elapsed = 0.0
	_awaiting_initial_spawn = true
	_invalid_scene_warning_emitted = false
	if clear_existing:
		clear_spawned_enemies()


func try_spawn_enemy() -> BaseEnemy:
	if not _has_valid_spawn_dependencies():
		return null
	if get_alive_count() >= spawn_profile.max_alive_enemies:
		return null

	var playfield_rect := _arena_layout.get_playfield_rect()
	if not playfield_rect.has_area():
		return null

	var spawn_position := sample_spawn_position(
		playfield_rect,
		spawn_profile.inner_spawn_margin,
		spawn_profile.get_effective_outer_spawn_margin(),
		_target.global_position,
		spawn_profile.min_player_distance,
		spawn_profile.spawn_sample_attempts,
		_rng
	)
	if not spawn_position.is_finite():
		return null

	var instance := enemy_scene.instantiate()
	if not instance is BaseEnemy:
		if is_instance_valid(instance):
			instance.free()
		if not _invalid_scene_warning_emitted:
			_invalid_scene_warning_emitted = true
			push_warning(
				"EnemySpawner: enemy_scene deve avere BaseEnemy come nodo root."
			)
		return null

	var enemy := instance as BaseEnemy
	enemy.set_target(_target)
	enemy.set_run_controller(_run_controller)
	enemy.experience_reward_scale = spawn_profile.get_experience_reward_scale(
		_run_controller.get_run_time()
	)
	_enemy_parent.add_child(enemy)
	enemy.global_position = spawn_position
	if not enemy.is_in_group(&"enemies"):
		enemy.add_to_group(&"enemies")

	_spawned_enemies.append(enemy)
	enemy.tree_exiting.connect(
		_on_enemy_tree_exiting.bind(enemy),
		CONNECT_ONE_SHOT
	)
	enemy_spawned.emit(enemy)
	return enemy


func cleanup_outside_despawn_rect() -> int:
	if not is_instance_valid(_arena_layout) or spawn_profile == null:
		return 0

	var despawn_rect := _arena_layout.get_despawn_rect(
		spawn_profile.get_effective_despawn_margin()
	)
	if not despawn_rect.has_area():
		return 0
	var removed_count := 0
	for enemy in _spawned_enemies.duplicate():
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			continue
		if not is_point_in_rect_inclusive(despawn_rect, enemy.global_position):
			enemy.queue_free()
			removed_count += 1
	return removed_count


func clear_spawned_enemies() -> void:
	var enemies_to_clear := _spawned_enemies.duplicate()
	_spawned_enemies.clear()
	for enemy in enemies_to_clear:
		if not is_instance_valid(enemy):
			continue
		var instance_id: int = enemy.get_instance_id()
		enemy.clear_chase_dependencies()
		if not enemy.is_queued_for_deletion():
			enemy.queue_free()
		enemy_removed.emit(instance_id)


func get_alive_count() -> int:
	_prune_invalid_enemies()
	return _spawned_enemies.size()


func get_spawned_enemies() -> Array[BaseEnemy]:
	_prune_invalid_enemies()
	return _spawned_enemies.duplicate()


func get_spawn_elapsed() -> float:
	return _spawn_elapsed


func is_waiting_for_initial_spawn() -> bool:
	return _awaiting_initial_spawn


static func sample_spawn_position(
	viewport_rect: Rect2,
	inner_margin: float,
	outer_margin: float,
	player_position: Vector2,
	minimum_player_distance: float,
	sample_attempts: int,
	rng: RandomNumberGenerator
) -> Vector2:
	if not viewport_rect.has_area() or rng == null:
		return Vector2(INF, INF)

	var safe_inner := maxf(inner_margin, 0.0)
	var safe_outer := maxf(outer_margin, safe_inner)
	var safe_minimum_distance := maxf(minimum_player_distance, 0.0)
	var attempts := maxi(sample_attempts, 1)
	var outer_rect := viewport_rect.grow(safe_outer)
	var required_distance_squared := safe_minimum_distance * safe_minimum_distance

	for _attempt in range(attempts):
		var side := rng.randi_range(0, 3)
		var depth := rng.randf_range(safe_inner, safe_outer)
		var candidate := Vector2.ZERO
		match side:
			0:
				candidate = Vector2(
					rng.randf_range(outer_rect.position.x, outer_rect.end.x),
					viewport_rect.position.y - depth
				)
			1:
				candidate = Vector2(
					viewport_rect.end.x + depth,
					rng.randf_range(outer_rect.position.y, outer_rect.end.y)
				)
			2:
				candidate = Vector2(
					rng.randf_range(outer_rect.position.x, outer_rect.end.x),
					viewport_rect.end.y + depth
				)
			_:
				candidate = Vector2(
					viewport_rect.position.x - depth,
					rng.randf_range(outer_rect.position.y, outer_rect.end.y)
				)

		if candidate.distance_squared_to(player_position) >= required_distance_squared:
			return candidate

	# Se i tentativi casuali non trovano un punto valido, l'angolo esterno piu
	# lontano e il massimo geometrico dell'anello rettangolare. Rispetta quindi
	# la distanza minima ogni volta che questa e realizzabile; se non lo e,
	# restituisce comunque il miglior fallback possibile.
	return get_farthest_rect_corner(outer_rect, player_position)


static func get_farthest_rect_corner(
	bounds: Rect2,
	point: Vector2
) -> Vector2:
	if not bounds.has_area():
		return Vector2(INF, INF)

	var farthest_corner := bounds.position
	var farthest_distance_squared := -1.0
	var corners: Array[Vector2] = [
		bounds.position,
		Vector2(bounds.end.x, bounds.position.y),
		bounds.end,
		Vector2(bounds.position.x, bounds.end.y),
	]
	for corner in corners:
		var distance_squared: float = corner.distance_squared_to(point)
		if distance_squared > farthest_distance_squared:
			farthest_corner = corner
			farthest_distance_squared = distance_squared
	return farthest_corner


static func is_point_in_rect_inclusive(
	bounds: Rect2,
	point: Vector2,
	tolerance: float = 0.001
) -> bool:
	var safe_tolerance := maxf(tolerance, 0.0)
	return (
		point.x >= bounds.position.x - safe_tolerance
		and point.y >= bounds.position.y - safe_tolerance
		and point.x <= bounds.end.x + safe_tolerance
		and point.y <= bounds.end.y + safe_tolerance
	)


func _exit_tree() -> void:
	_disconnect_run_controller()


func _can_run_scheduler() -> bool:
	return (
		is_instance_valid(_run_controller)
		and _run_controller.is_running()
		and _has_valid_spawn_dependencies()
	)


func _has_valid_spawn_dependencies() -> bool:
	return (
		spawn_profile != null
		and spawn_profile.max_alive_enemies > 0
		and enemy_scene != null
		and is_instance_valid(_run_controller)
		and is_instance_valid(_arena_layout)
		and is_instance_valid(_target)
		and is_instance_valid(_enemy_parent)
		and _enemy_parent.is_inside_tree()
	)


func _prune_invalid_enemies() -> void:
	for index in range(_spawned_enemies.size() - 1, -1, -1):
		if not is_instance_valid(_spawned_enemies[index]):
			_spawned_enemies.remove_at(index)


func _disconnect_run_controller() -> void:
	if not is_instance_valid(_run_controller):
		_run_controller = null
		return
	if _run_controller.run_started.is_connected(_on_run_started):
		_run_controller.run_started.disconnect(_on_run_started)
	if _run_controller.restart_prepared.is_connected(_on_restart_prepared):
		_run_controller.restart_prepared.disconnect(_on_restart_prepared)
	_run_controller = null


func _on_run_started(seed_value: int) -> void:
	reset_for_run(seed_value)


func _on_restart_prepared() -> void:
	_spawn_elapsed = 0.0
	_cleanup_elapsed = 0.0
	_awaiting_initial_spawn = true
	clear_spawned_enemies()


func _on_enemy_tree_exiting(enemy: BaseEnemy) -> void:
	var index := _spawned_enemies.find(enemy)
	if index < 0:
		return
	var instance_id := enemy.get_instance_id()
	_spawned_enemies.remove_at(index)
	enemy_removed.emit(instance_id)
