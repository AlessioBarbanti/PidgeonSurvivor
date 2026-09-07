class_name RangedEnemy
extends BaseEnemy

## Tiratore (B40): si ferma entro ranged_preferred_distance dal bersaglio e
## spara un proiettile telegrafato, riusando lo stesso layer proiettili e lo
## stesso schema telegraph->esecuzione gia' introdotto per il Boss
## (scripts/bosses/boss_projectile.gd, scripts/bosses/first_boss.gd).

@export var projectile_scene: PackedScene

var _definition: EnemyArchetypeDefinition
var _projectile_parent: Node
var _attack_cooldown_remaining := 0.0
var _telegraph_active := false
var _telegraph_remaining := 0.0
var _telegraph_duration := 0.0
var _active_projectiles: Array[BossProjectile] = []


func _exit_tree() -> void:
	clear_attack_runtime()
	super._exit_tree()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_advance_attack_cycle(delta)


func _draw() -> void:
	super._draw()
	_draw_telegraph_ring()


func configure_ranged(definition: EnemyArchetypeDefinition, projectile_parent: Node) -> void:
	_definition = definition
	_projectile_parent = projectile_parent
	_attack_cooldown_remaining = (
		definition.ranged_attack_interval if definition != null else 0.0
	)
	_telegraph_active = false
	_telegraph_remaining = 0.0
	_telegraph_duration = 0.0
	queue_redraw()


func clear_attack_runtime() -> void:
	_telegraph_active = false
	_telegraph_remaining = 0.0
	_telegraph_duration = 0.0
	var projectiles_to_clear := _active_projectiles.duplicate()
	_active_projectiles.clear()
	for projectile in projectiles_to_clear:
		if is_instance_valid(projectile) and not projectile.is_queued_for_deletion():
			projectile.expire()
	queue_redraw()


func is_telegraph_active() -> bool:
	return _telegraph_active


func get_telegraph_remaining() -> float:
	return _telegraph_remaining


func get_active_projectile_count() -> int:
	_prune_projectiles()
	return _active_projectiles.size()


## Ferma l'inseguimento entro la distanza preferita di tiro invece di
## chiudere sempre sul bersaglio; il resto del movimento (knockback,
## steering attorno agli ostacoli) resta quello di BaseEnemy.
func _compute_chase_offset() -> Vector2:
	var base_offset := super._compute_chase_offset()
	var preferred := _definition.ranged_preferred_distance if _definition != null else 0.0
	if base_offset.length() <= preferred:
		return Vector2.ZERO
	return base_offset


func _advance_attack_cycle(delta: float) -> void:
	var run_controller := get_run_controller()
	if (
		_definition == null
		or not is_alive()
		or run_controller == null
		or not run_controller.is_running()
	):
		return

	var safe_delta := maxf(delta, 0.0) if is_finite(delta) else 0.0
	if _telegraph_active:
		_telegraph_remaining = maxf(_telegraph_remaining - safe_delta, 0.0)
		queue_redraw()
		if _telegraph_remaining <= 0.0:
			_execute_attack()
		return

	var target := get_target()
	if target == null or not _is_target_in_range(target):
		return
	_attack_cooldown_remaining = maxf(_attack_cooldown_remaining - safe_delta, 0.0)
	if _attack_cooldown_remaining <= 0.0:
		_begin_telegraph()


func _begin_telegraph() -> void:
	_telegraph_active = true
	_telegraph_duration = _definition.ranged_telegraph_duration
	_telegraph_remaining = _telegraph_duration
	queue_redraw()


## Ricontrolla il raggio a fine telegraph (come FirstBoss per il targeted
## blast): il bersaglio puo' essere uscito dal raggio mentre il tiratore
## caricava, e in quel caso il colpo non parte.
func _execute_attack() -> void:
	_telegraph_active = false
	_telegraph_remaining = 0.0
	_telegraph_duration = 0.0
	_attack_cooldown_remaining = _definition.ranged_attack_interval
	var target := get_target()
	if target != null and _is_target_in_range(target):
		_fire_projectile(target)
	queue_redraw()


func _is_target_in_range(target: Node2D) -> bool:
	if _definition == null:
		return false
	var range_value := _definition.ranged_attack_range
	return global_position.distance_squared_to(target.global_position) <= range_value * range_value


func _fire_projectile(target: Node2D) -> void:
	if (
		projectile_scene == null
		or not is_instance_valid(_projectile_parent)
		or not _projectile_parent.is_inside_tree()
	):
		return
	var run_controller := get_run_controller()
	var player := target as Player
	if run_controller == null or player == null:
		return

	var instance := projectile_scene.instantiate()
	if not instance is BossProjectile:
		if is_instance_valid(instance):
			instance.free()
		return
	var projectile := instance as BossProjectile
	_projectile_parent.add_child(projectile)
	projectile.global_position = global_position
	var direction := player.global_position - global_position
	if direction.is_zero_approx():
		direction = Vector2.RIGHT
	if not projectile.initialize(
		direction.normalized(),
		_definition.ranged_projectile_damage * pressure_multiplier,
		_definition.ranged_projectile_speed,
		_definition.ranged_projectile_lifetime,
		_definition.ranged_projectile_radius,
		run_controller,
		player
	):
		projectile.queue_free()
		return
	_active_projectiles.append(projectile)
	projectile.tree_exiting.connect(
		_on_projectile_tree_exiting.bind(projectile),
		CONNECT_ONE_SHOT
	)


func _draw_telegraph_ring() -> void:
	if not _telegraph_active or _definition == null:
		return
	var progress := 1.0 - clampf(
		_telegraph_remaining / maxf(_telegraph_duration, 0.001),
		0.0,
		1.0
	)
	var ring_radius := collision_radius + 16.0 + progress * 14.0
	draw_arc(
		Vector2.ZERO,
		ring_radius,
		0.0,
		TAU,
		32,
		_definition.ranged_telegraph_color,
		4.0,
		true
	)


func _prune_projectiles() -> void:
	for index in range(_active_projectiles.size() - 1, -1, -1):
		if not is_instance_valid(_active_projectiles[index]):
			_active_projectiles.remove_at(index)


func _on_projectile_tree_exiting(projectile: BossProjectile) -> void:
	_active_projectiles.erase(projectile)
