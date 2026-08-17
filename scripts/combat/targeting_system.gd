class_name TargetingSystem
extends Node

signal target_registered(target: BaseEnemy)
signal target_unregistered(target_instance_id: int)

var _enemy_spawner: EnemySpawner
var _targets: Array[BaseEnemy] = []


func _exit_tree() -> void:
	unbind_enemy_spawner()
	clear()


func bind_enemy_spawner(value: EnemySpawner) -> void:
	if value == _enemy_spawner:
		return

	unbind_enemy_spawner()
	clear()
	_enemy_spawner = value
	if not is_instance_valid(_enemy_spawner):
		return

	if not _enemy_spawner.enemy_spawned.is_connected(register_target):
		_enemy_spawner.enemy_spawned.connect(register_target)
	if not _enemy_spawner.enemy_removed.is_connected(unregister_target_by_instance_id):
		_enemy_spawner.enemy_removed.connect(unregister_target_by_instance_id)
	for enemy in _enemy_spawner.get_spawned_enemies():
		register_target(enemy)


func unbind_enemy_spawner() -> void:
	if not is_instance_valid(_enemy_spawner):
		_enemy_spawner = null
		return
	if _enemy_spawner.enemy_spawned.is_connected(register_target):
		_enemy_spawner.enemy_spawned.disconnect(register_target)
	if _enemy_spawner.enemy_removed.is_connected(unregister_target_by_instance_id):
		_enemy_spawner.enemy_removed.disconnect(unregister_target_by_instance_id)
	_enemy_spawner = null


func register_target(target: BaseEnemy) -> bool:
	if not _is_target_alive(target) or _targets.has(target):
		return false

	_targets.append(target)
	if not target.died.is_connected(_on_target_died):
		target.died.connect(_on_target_died)
	var exit_callback := _on_target_tree_exiting.bind(target)
	if not target.tree_exiting.is_connected(exit_callback):
		target.tree_exiting.connect(exit_callback, CONNECT_ONE_SHOT)
	target_registered.emit(target)
	return true


func unregister_target(target: BaseEnemy) -> bool:
	var index := _targets.find(target)
	if index < 0:
		return false

	var instance_id := target.get_instance_id() if is_instance_valid(target) else 0
	_targets.remove_at(index)
	_disconnect_target(target)
	target_unregistered.emit(instance_id)
	return true


func unregister_target_by_instance_id(target_instance_id: int) -> bool:
	for target in _targets.duplicate():
		if is_instance_valid(target) and target.get_instance_id() == target_instance_id:
			return unregister_target(target)
	_prune_invalid_targets()
	return false


func get_nearest_alive(origin: Vector2) -> BaseEnemy:
	_prune_invalid_targets()
	var nearest: BaseEnemy
	var nearest_distance_squared := INF
	for target in _targets:
		if not _is_target_alive(target):
			continue
		var distance_squared := origin.distance_squared_to(target.global_position)
		if distance_squared < nearest_distance_squared:
			nearest = target
			nearest_distance_squared = distance_squared
	return nearest


func has_target(target: BaseEnemy) -> bool:
	_prune_invalid_targets()
	return _targets.has(target) and _is_target_alive(target)


func get_registered_count() -> int:
	_prune_invalid_targets()
	return _targets.size()


func get_alive_targets() -> Array[BaseEnemy]:
	_prune_invalid_targets()
	return _targets.duplicate()


func get_enemy_spawner() -> EnemySpawner:
	return _enemy_spawner if is_instance_valid(_enemy_spawner) else null


func clear() -> void:
	var targets_to_clear := _targets.duplicate()
	_targets.clear()
	for target in targets_to_clear:
		var instance_id: int = target.get_instance_id() if is_instance_valid(target) else 0
		_disconnect_target(target)
		target_unregistered.emit(instance_id)


func _prune_invalid_targets() -> void:
	for index in range(_targets.size() - 1, -1, -1):
		var target := _targets[index]
		if _is_target_alive(target):
			continue
		_targets.remove_at(index)
		_disconnect_target(target)


func _disconnect_target(target: BaseEnemy) -> void:
	if not is_instance_valid(target):
		return
	if target.died.is_connected(_on_target_died):
		target.died.disconnect(_on_target_died)
	var exit_callback := _on_target_tree_exiting.bind(target)
	if target.tree_exiting.is_connected(exit_callback):
		target.tree_exiting.disconnect(exit_callback)


func _is_target_alive(target: BaseEnemy) -> bool:
	return (
		is_instance_valid(target)
		and not target.is_queued_for_deletion()
		and target.is_alive()
	)


func _on_target_died(target: BaseEnemy) -> void:
	unregister_target(target)


func _on_target_tree_exiting(target: BaseEnemy) -> void:
	unregister_target(target)
