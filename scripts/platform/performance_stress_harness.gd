class_name PerformanceStressHarness
extends Node

signal stress_started(duration_seconds: float)
signal stress_cycle_completed(cycle_index: int)
signal stress_finished(success: bool)

const BASE_ENEMY_SCENE := preload("res://scenes/actors/base_enemy.tscn")
const PROJECTILE_SCENE := preload("res://scenes/combat/projectile.tscn")
const PICKUP_SCENE := preload("res://scenes/pickups/experience_pickup.tscn")
const STRESS_CYCLES := 5

var _movement_slice: Control
var _profile: PerformanceProfile
var _sources: Dictionary = {}
var _active_nodes: Array[Node] = []
var _elapsed := 0.0
var _duration := 0.0
var _next_cycle_elapsed := 0.0
var _cycle_index := 0
var _running := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)


func _exit_tree() -> void:
	clear_stress_nodes()


func configure(
	movement_slice: Control,
	profile: PerformanceProfile,
	sources: Dictionary
) -> bool:
	if not is_instance_valid(movement_slice) or profile == null or not profile.is_valid():
		return false
	_movement_slice = movement_slice
	_profile = profile
	_sources = sources.duplicate()
	return true


func start(duration_seconds: float = 60.0) -> bool:
	if not OS.is_debug_build() or _running or not _is_ready_to_stress():
		return false
	_duration = maxf(duration_seconds, 1.0)
	_elapsed = 0.0
	_next_cycle_elapsed = _duration / float(STRESS_CYCLES)
	_cycle_index = 0
	clear_stress_nodes()
	_spawn_population()
	_running = true
	set_process(true)
	stress_started.emit(_duration)
	print("B18V_STRESS_STARTED profile=%s duration=%.1f enemies=%d projectiles=%d pickups=%d" % [
		_profile.profile_id,
		_duration,
		_profile.stress_enemy_count,
		_profile.stress_projectile_count,
		_profile.stress_pickup_count,
	])
	return true


func stop(success: bool = true) -> void:
	if not _running and _active_nodes.is_empty():
		return
	_running = false
	set_process(false)
	clear_stress_nodes()
	print("B18V_PERFORMANCE_%s" % ("OK" if success else "FAIL"))
	stress_finished.emit(success)


func is_running() -> bool:
	return _running


func get_active_stress_count() -> int:
	_prune_nodes()
	return _active_nodes.size()


func get_expected_stress_count() -> int:
	if _profile == null:
		return 0
	return _profile.stress_enemy_count + _profile.stress_projectile_count + _profile.stress_pickup_count


func clear_stress_nodes() -> void:
	for node in _active_nodes.duplicate():
		if is_instance_valid(node) and not node.is_queued_for_deletion():
			node.queue_free()
	_active_nodes.clear()


func _process(delta: float) -> void:
	if not _running:
		return
	_elapsed += maxf(delta, 0.0)
	if _cycle_index < STRESS_CYCLES and _elapsed >= _next_cycle_elapsed:
		_cycle_index += 1
		if not _run_cycle(_cycle_index):
			stop(false)
			return
		_next_cycle_elapsed += _duration / float(STRESS_CYCLES)
	if _elapsed >= _duration:
		stop(true)


func _run_cycle(next_cycle: int) -> bool:
	clear_stress_nodes()
	var friend_ids: Array[StringName] = [&"magno", &"bea", &"zat", &"alea", &"aleo"]
	var friend_id := friend_ids[(next_cycle - 1) % friend_ids.size()]
	if not _movement_slice.run_b18v_restart_profile_cycle(friend_id, 91800 + next_cycle):
		return false
	_spawn_population()
	stress_cycle_completed.emit(next_cycle)
	print("B18V_STRESS_CYCLE_OK index=%d friend=%s" % [next_cycle, friend_id])
	return true


func _spawn_population() -> void:
	var enemy_parent := _sources.get(&"enemies") as Node2D
	var projectile_parent := _sources.get(&"projectiles") as Node2D
	var pickup_parent := _sources.get(&"pickups") as Node2D
	var player := _sources.get(&"player") as Player
	var controller := _sources.get(&"controller") as RunController
	var targeting := _sources.get(&"targeting") as TargetingSystem
	var arena := _sources.get(&"arena") as ArenaLayout
	if (
		not is_instance_valid(enemy_parent)
		or not is_instance_valid(projectile_parent)
		or not is_instance_valid(pickup_parent)
		or not is_instance_valid(player)
		or not is_instance_valid(controller)
		or not is_instance_valid(arena)
	):
		return
	var playfield := arena.get_playfield_rect()
	for index in _profile.stress_enemy_count:
		var enemy := BASE_ENEMY_SCENE.instantiate() as BaseEnemy
		enemy_parent.add_child(enemy)
		enemy.global_position = _grid_position(playfield, index, _profile.stress_enemy_count, 18.0)
		enemy.set_target(player)
		enemy.set_run_controller(controller)
		enemy.move_speed = 0.0
		var contact := enemy.get_contact_damage()
		if contact != null:
			contact.disable()
		var health := enemy.get_health_component()
		if health != null:
			health.set_health_max(1000000.0)
		if is_instance_valid(targeting):
			targeting.register_target(enemy)
		_active_nodes.append(enemy)
	for index in _profile.stress_projectile_count:
		var projectile := PROJECTILE_SCENE.instantiate() as Projectile
		projectile_parent.add_child(projectile)
		projectile.global_position = _grid_position(playfield, index, _profile.stress_projectile_count, 64.0)
		projectile.collision_mask = 0
		projectile.initialize(Vector2.RIGHT, 1.0, 0.0, _duration + 5.0, 4.0, controller)
		_active_nodes.append(projectile)
	for index in _profile.stress_pickup_count:
		var pickup := PICKUP_SCENE.instantiate() as ExperiencePickup
		pickup_parent.add_child(pickup)
		pickup.global_position = _ring_position(playfield, index, _profile.stress_pickup_count, 12.0)
		pickup.configure(controller, player, 1)
		_active_nodes.append(pickup)


func _grid_position(bounds: Rect2, index: int, count: int, inset: float) -> Vector2:
	var safe_bounds := bounds.grow(-minf(inset, minf(bounds.size.x, bounds.size.y) * 0.25))
	if not safe_bounds.has_area():
		return bounds.get_center()
	var columns := maxi(1, ceili(sqrt(float(count))))
	var rows := maxi(1, ceili(float(count) / float(columns)))
	var column := index % columns
	var row := index / columns
	return Vector2(
		lerpf(safe_bounds.position.x, safe_bounds.end.x, (float(column) + 0.5) / float(columns)),
		lerpf(safe_bounds.position.y, safe_bounds.end.y, (float(row) + 0.5) / float(rows))
	)


func _ring_position(bounds: Rect2, index: int, count: int, inset: float) -> Vector2:
	var safe_bounds := bounds.grow(-minf(inset, minf(bounds.size.x, bounds.size.y) * 0.25))
	if not safe_bounds.has_area():
		return bounds.get_center()
	var phase := TAU * float(index) / float(maxi(count, 1))
	var radius := safe_bounds.size * 0.46
	return safe_bounds.get_center() + Vector2(cos(phase) * radius.x, sin(phase) * radius.y)


func _is_ready_to_stress() -> bool:
	var controller := _sources.get(&"controller") as RunController
	return (
		is_instance_valid(_movement_slice)
		and _profile != null
		and _profile.is_valid()
		and is_instance_valid(controller)
		and controller.is_running()
	)


func _prune_nodes() -> void:
	for index in range(_active_nodes.size() - 1, -1, -1):
		if not is_instance_valid(_active_nodes[index]):
			_active_nodes.remove_at(index)
