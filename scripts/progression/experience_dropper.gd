class_name ExperienceDropper
extends Node

signal pickup_spawned(pickup: ExperiencePickup)
signal pickup_collected(
	pickup: ExperiencePickup,
	amount: int,
	experience_current: int
)
signal pickup_removed(pickup_instance_id: int)

@export var pickup_scene: PackedScene

var _run_controller: RunController
var _enemy_spawner: EnemySpawner
var _experience_system: ExperienceSystem
var _player: Player
var _pickup_parent: Node
var _active_pickups: Array[ExperiencePickup] = []
var _observed_enemy_ids: Dictionary = {}
var _dropped_enemy_ids: Dictionary = {}
var _invalid_scene_warning_emitted := false


func configure(
	run_controller: RunController,
	enemy_spawner: EnemySpawner,
	experience_system: ExperienceSystem,
	player: Player,
	pickup_parent: Node
) -> void:
	set_run_controller(run_controller)
	bind_enemy_spawner(enemy_spawner)
	_experience_system = experience_system
	_player = player
	_pickup_parent = pickup_parent


func set_run_controller(value: RunController) -> void:
	if value == _run_controller:
		return
	_disconnect_run_controller()
	_run_controller = value
	if not is_instance_valid(_run_controller):
		return
	if not _run_controller.restart_prepared.is_connected(_on_restart_prepared):
		_run_controller.restart_prepared.connect(_on_restart_prepared)


func bind_enemy_spawner(value: EnemySpawner) -> void:
	if value == _enemy_spawner:
		return
	_disconnect_enemy_spawner()
	_enemy_spawner = value
	if not is_instance_valid(_enemy_spawner):
		return
	if not _enemy_spawner.enemy_spawned.is_connected(_on_enemy_spawned):
		_enemy_spawner.enemy_spawned.connect(_on_enemy_spawned)
	for enemy in _enemy_spawner.get_spawned_enemies():
		_on_enemy_spawned(enemy)


func try_spawn_drop(enemy: BaseEnemy) -> ExperiencePickup:
	if not is_instance_valid(enemy) or not _has_valid_dependencies():
		return null
	if not _run_controller.is_running():
		return null

	var enemy_instance_id: int = enemy.get_instance_id()
	if _dropped_enemy_ids.has(enemy_instance_id):
		return null

	var instance := pickup_scene.instantiate()
	if not instance is ExperiencePickup:
		if is_instance_valid(instance):
			instance.free()
		if not _invalid_scene_warning_emitted:
			_invalid_scene_warning_emitted = true
			push_warning(
				"ExperienceDropper: pickup_scene deve avere ExperiencePickup come nodo root."
			)
		return null

	var pickup := instance as ExperiencePickup
	pickup.configure(
		_run_controller,
		_player,
		enemy.get_experience_amount()
	)
	_pickup_parent.add_child(pickup)
	pickup.global_position = enemy.global_position
	pickup.collected.connect(_on_pickup_collected, CONNECT_ONE_SHOT)
	pickup.tree_exiting.connect(
		_on_pickup_tree_exiting.bind(pickup),
		CONNECT_ONE_SHOT
	)
	_dropped_enemy_ids[enemy_instance_id] = true
	_active_pickups.append(pickup)
	pickup_spawned.emit(pickup)
	return pickup


func clear_active_pickups() -> void:
	var pickups_to_clear: Array[ExperiencePickup] = _active_pickups.duplicate()
	_active_pickups.clear()
	for pickup in pickups_to_clear:
		if not is_instance_valid(pickup):
			continue
		var instance_id: int = pickup.get_instance_id()
		if not pickup.is_queued_for_deletion():
			pickup.queue_free()
		pickup_removed.emit(instance_id)


func get_active_count() -> int:
	_prune_invalid_pickups()
	return _active_pickups.size()


func get_active_pickups() -> Array[ExperiencePickup]:
	_prune_invalid_pickups()
	return _active_pickups.duplicate()


func get_run_controller() -> RunController:
	return _run_controller if is_instance_valid(_run_controller) else null


func get_enemy_spawner() -> EnemySpawner:
	return _enemy_spawner if is_instance_valid(_enemy_spawner) else null


func get_experience_system() -> ExperienceSystem:
	return _experience_system if is_instance_valid(_experience_system) else null


func get_player() -> Player:
	return _player if is_instance_valid(_player) else null


func get_pickup_parent() -> Node:
	return _pickup_parent if is_instance_valid(_pickup_parent) else null


func _exit_tree() -> void:
	_disconnect_enemy_spawner()
	_disconnect_run_controller()


func _has_valid_dependencies() -> bool:
	return (
		pickup_scene != null
		and is_instance_valid(_run_controller)
		and is_instance_valid(_experience_system)
		and is_instance_valid(_player)
		and is_instance_valid(_pickup_parent)
		and _pickup_parent.is_inside_tree()
	)


func _prune_invalid_pickups() -> void:
	for index in range(_active_pickups.size() - 1, -1, -1):
		if not is_instance_valid(_active_pickups[index]):
			_active_pickups.remove_at(index)


func _disconnect_run_controller() -> void:
	if not is_instance_valid(_run_controller):
		_run_controller = null
		return
	if _run_controller.restart_prepared.is_connected(_on_restart_prepared):
		_run_controller.restart_prepared.disconnect(_on_restart_prepared)
	_run_controller = null


func _disconnect_enemy_spawner() -> void:
	if not is_instance_valid(_enemy_spawner):
		_enemy_spawner = null
		return
	if _enemy_spawner.enemy_spawned.is_connected(_on_enemy_spawned):
		_enemy_spawner.enemy_spawned.disconnect(_on_enemy_spawned)
	_enemy_spawner = null


func _on_enemy_spawned(enemy: BaseEnemy) -> void:
	if not is_instance_valid(enemy):
		return
	var instance_id: int = enemy.get_instance_id()
	if _observed_enemy_ids.has(instance_id):
		return
	_observed_enemy_ids[instance_id] = true
	if not enemy.died.is_connected(_on_enemy_died):
		enemy.died.connect(_on_enemy_died)
	enemy.tree_exiting.connect(
		_on_enemy_tree_exiting.bind(instance_id),
		CONNECT_ONE_SHOT
	)


func _on_enemy_died(enemy: BaseEnemy) -> void:
	try_spawn_drop(enemy)


func _on_enemy_tree_exiting(enemy_instance_id: int) -> void:
	_observed_enemy_ids.erase(enemy_instance_id)
	_dropped_enemy_ids.erase(enemy_instance_id)


func _on_pickup_collected(
	pickup: ExperiencePickup,
	amount: int
) -> void:
	if not is_instance_valid(_experience_system):
		return
	if not _experience_system.add_experience(amount):
		return
	pickup_collected.emit(
		pickup,
		amount,
		_experience_system.experience_current
	)


func _on_pickup_tree_exiting(pickup: ExperiencePickup) -> void:
	var index := _active_pickups.find(pickup)
	if index < 0:
		return
	var instance_id: int = pickup.get_instance_id()
	_active_pickups.remove_at(index)
	pickup_removed.emit(instance_id)


func _on_restart_prepared() -> void:
	_invalid_scene_warning_emitted = false
	_observed_enemy_ids.clear()
	_dropped_enemy_ids.clear()
	clear_active_pickups()
