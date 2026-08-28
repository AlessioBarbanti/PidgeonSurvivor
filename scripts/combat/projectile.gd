class_name Projectile
extends Area2D

signal hit_processed(target: BaseEnemy, damage: float)
signal expired(projectile: Projectile)
signal chain_jumped(from_target: BaseEnemy, to_target: BaseEnemy, damage: float)

const ENEMY_HURTBOX_MASK := 1 << 1

@export_group("Visual")
@export var body_color := Color(1.0, 0.91, 0.2, 1.0):
	set(value):
		body_color = value
		queue_redraw()

@export var outline_color := Color(0.18, 0.025, 0.07, 1.0):
	set(value):
		outline_color = value
		queue_redraw()

@export var trail_color := Color(0.05, 0.88, 1.0, 0.8):
	set(value):
		trail_color = value
		queue_redraw()

@export_range(1.0, 8.0, 0.1) var trail_length_multiplier := 4.2:
	set(value):
		trail_length_multiplier = maxf(value, 1.0)
		queue_redraw()

var damage := 0.0
var direction := Vector2.RIGHT
var speed := 0.0
var lifetime_remaining := 0.0
var projectile_radius := 6.0

var _run_controller: RunController
var _spent := false
var _chain_enabled := false
var _chain_jumps_remaining := 0
var _chain_damage_falloff := 1.0
var _chain_radius := 0.0
var _chain_current_damage := 0.0
var _aim_spread_degrees := 0.0
var _targeting_system: TargetingSystem
var _hit_target_ids: Dictionary = {}
var _pierce_enabled := false
var _pierce_remaining := 1
var _pierce_damage_falloff := 1.0
var _pierce_current_damage := 0.0
var _death_burst_enabled := false
var _death_burst_radius := 0.0
var _death_burst_damage_multiplier := 0.0

@onready var _collision_shape: CollisionShape2D = %CollisionShape


func _ready() -> void:
	_make_collision_shape_unique()
	_sync_collision_radius()
	collision_layer = 0
	collision_mask = ENEMY_HURTBOX_MASK
	monitoring = true
	monitorable = false
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	queue_redraw()


func _physics_process(delta: float) -> void:
	if _spent or not is_instance_valid(_run_controller) or not _run_controller.is_running():
		return

	var safe_delta := maxf(delta, 0.0)
	var movement_delta := minf(safe_delta, maxf(lifetime_remaining, 0.0))
	global_position += direction * speed * movement_delta
	lifetime_remaining -= safe_delta
	if lifetime_remaining <= 0.0:
		expire()
		return


func _draw() -> void:
	var outline_width := maxf(projectile_radius * 0.45, 2.0)
	var trail_length := projectile_radius * trail_length_multiplier
	for layer in range(3):
		var layer_ratio := float(layer) / 2.0
		var layer_color := trail_color
		layer_color.a *= lerpf(0.72, 0.24, layer_ratio)
		var y_offset := (float(layer) - 1.0) * projectile_radius * 0.3
		draw_line(
			Vector2(-trail_length * lerpf(1.0, 0.7, layer_ratio), y_offset),
			Vector2(-projectile_radius * 0.7, y_offset * 0.35),
			layer_color,
			maxf(projectile_radius * lerpf(0.72, 0.3, layer_ratio), 1.0),
			true
		)
	for echo_index in range(2):
		var echo_color := trail_color
		echo_color.a *= 0.28 - float(echo_index) * 0.09
		draw_circle(
			Vector2(-trail_length * (0.5 + float(echo_index) * 0.3), 0.0),
			maxf(projectile_radius * (0.42 - float(echo_index) * 0.1), 1.0),
			echo_color
		)
	draw_circle(Vector2.ZERO, projectile_radius + outline_width, outline_color)
	draw_circle(Vector2.ZERO, projectile_radius, body_color)


func initialize(
	initial_direction: Vector2,
	initial_damage: float,
	initial_speed: float,
	initial_lifetime: float,
	initial_radius: float,
	run_controller: RunController
) -> bool:
	if (
		initial_direction.is_zero_approx()
		or not initial_direction.is_finite()
		or not is_finite(initial_damage)
		or initial_damage <= 0.0
	):
		return false

	direction = initial_direction.normalized()
	damage = initial_damage
	speed = maxf(initial_speed, 0.0) if is_finite(initial_speed) else 0.0
	lifetime_remaining = maxf(initial_lifetime, 0.0) if is_finite(initial_lifetime) else 0.0
	projectile_radius = maxf(initial_radius, 1.0) if is_finite(initial_radius) else 1.0
	_run_controller = run_controller
	rotation = direction.angle()
	if is_node_ready():
		_sync_collision_radius()
	queue_redraw()
	return lifetime_remaining > 0.0 and is_instance_valid(_run_controller)


func configure_signature_effects(
	chain_enabled: bool,
	chain_jumps: int,
	chain_damage_falloff: float,
	chain_radius: float,
	aim_spread_degrees: float,
	targeting_system: TargetingSystem = null
) -> bool:
	if (
		chain_jumps < 0
		or not is_finite(chain_damage_falloff)
		or chain_damage_falloff <= 0.0
		or chain_damage_falloff > 1.0
		or not is_finite(chain_radius)
		or chain_radius < 0.0
		or (chain_enabled and (chain_jumps <= 0 or chain_radius <= 0.0))
		or (chain_enabled and not is_instance_valid(targeting_system))
		or not is_finite(aim_spread_degrees)
		or aim_spread_degrees < 0.0
		or aim_spread_degrees >= 90.0
	):
		return false
	_chain_enabled = chain_enabled
	_chain_jumps_remaining = chain_jumps
	_chain_damage_falloff = chain_damage_falloff
	_chain_radius = chain_radius
	_chain_current_damage = damage
	_aim_spread_degrees = aim_spread_degrees
	_targeting_system = targeting_system
	_hit_target_ids.clear()
	return true


func configure_shape_effects(
	pierce_count: int,
	pierce_damage_falloff: float,
	death_burst_enabled: bool,
	death_burst_radius: float,
	death_burst_damage_multiplier: float
) -> bool:
	if (
		pierce_count < 1
		or not is_finite(pierce_damage_falloff)
		or pierce_damage_falloff <= 0.0
		or pierce_damage_falloff > 1.0
		or not is_finite(death_burst_radius)
		or death_burst_radius < 0.0
		or not is_finite(death_burst_damage_multiplier)
		or death_burst_damage_multiplier < 0.0
		or (death_burst_enabled and (death_burst_radius <= 0.0 or death_burst_damage_multiplier <= 0.0))
	):
		return false
	# La perforazione cede il passo alla catena (Gossip): sono due modi diversi
	# di continuare oltre il primo bersaglio e non compongono la stessa vita.
	_pierce_enabled = pierce_count > 1 and not _chain_enabled
	_pierce_remaining = pierce_count
	_pierce_damage_falloff = pierce_damage_falloff
	_pierce_current_damage = damage
	_death_burst_enabled = death_burst_enabled
	_death_burst_radius = death_burst_radius
	_death_burst_damage_multiplier = death_burst_damage_multiplier
	return true


func try_hit(target: BaseEnemy) -> bool:
	if (
		_spent
		or not is_instance_valid(_run_controller)
		or not _run_controller.is_running()
		or not is_instance_valid(target)
		or target.is_queued_for_deletion()
		or not target.is_alive()
	):
		return false

	var target_instance_id := target.get_instance_id()
	if _hit_target_ids.has(target_instance_id):
		return false
	_hit_target_ids[target_instance_id] = true
	var is_multi_hit := _chain_enabled or _pierce_enabled
	var hit_damage := _current_hit_damage()
	# Il latch precede il danno: callback duplicate o rientranti non possono
	# riutilizzare lo stesso bersaglio durante la catena o la perforazione.
	if not is_multi_hit:
		_spent = true
		_disable_immediately()
	var damage_applied := target.take_damage(hit_damage)
	if damage_applied:
		hit_processed.emit(target, hit_damage)
		if _death_burst_enabled and not target.is_alive():
			_trigger_death_burst(target.global_position)
	if not is_multi_hit:
		queue_free()
		return damage_applied

	if _chain_enabled:
		if not damage_applied or _chain_jumps_remaining <= 0:
			expire()
			return damage_applied

		_chain_jumps_remaining -= 1
		_chain_current_damage *= _chain_damage_falloff
		global_position = target.global_position
		var next_target := _targeting_system.get_nearest_alive_excluding(
			global_position,
			_hit_target_ids
		)
		if (
			next_target == null
			or global_position.distance_to(next_target.global_position) > _chain_radius
		):
			expire()
			return damage_applied
		chain_jumped.emit(target, next_target, _chain_current_damage)
		try_hit(next_target)
		return damage_applied

	_pierce_remaining -= 1
	if not damage_applied or _pierce_remaining <= 0:
		expire()
		return damage_applied
	_pierce_current_damage *= _pierce_damage_falloff
	return damage_applied


func _current_hit_damage() -> float:
	if _chain_enabled:
		return _chain_current_damage
	if _pierce_enabled:
		return _pierce_current_damage
	return damage


func _trigger_death_burst(origin: Vector2) -> void:
	if not is_instance_valid(_targeting_system):
		return
	var burst_damage := damage * _death_burst_damage_multiplier
	if burst_damage <= 0.0:
		return
	for enemy in _targeting_system.get_alive_targets():
		if not is_instance_valid(enemy) or not enemy.is_alive():
			continue
		if origin.distance_to(enemy.global_position) > _death_burst_radius:
			continue
		enemy.take_damage(burst_damage)


func expire() -> void:
	if _spent:
		return
	_spent = true
	_disable_immediately()
	expired.emit(self)
	queue_free()


func is_spent() -> bool:
	return _spent


func get_run_controller() -> RunController:
	return _run_controller if is_instance_valid(_run_controller) else null


func is_chain_enabled() -> bool:
	return _chain_enabled


func get_chain_jumps_remaining() -> int:
	return _chain_jumps_remaining


func get_chain_damage_falloff() -> float:
	return _chain_damage_falloff


func get_chain_radius() -> float:
	return _chain_radius


func get_aim_spread_degrees() -> float:
	return _aim_spread_degrees


func is_pierce_enabled() -> bool:
	return _pierce_enabled


func get_pierce_remaining() -> int:
	return _pierce_remaining


func get_pierce_damage_falloff() -> float:
	return _pierce_damage_falloff


func is_death_burst_enabled() -> bool:
	return _death_burst_enabled


func get_death_burst_radius() -> float:
	return _death_burst_radius


func get_death_burst_damage_multiplier() -> float:
	return _death_burst_damage_multiplier


func has_hit_target(target: BaseEnemy) -> bool:
	return is_instance_valid(target) and _hit_target_ids.has(target.get_instance_id())


func _on_area_entered(area: Area2D) -> void:
	if _spent or not area is Hurtbox:
		return
	var receiver := (area as Hurtbox).get_damage_receiver()
	if receiver is BaseEnemy:
		try_hit(receiver as BaseEnemy)


func _disable_immediately() -> void:
	set_physics_process(false)
	set_deferred("monitoring", false)
	set_deferred("collision_mask", 0)


func _make_collision_shape_unique() -> void:
	var circle_shape := CircleShape2D.new()
	if _collision_shape.shape is CircleShape2D:
		circle_shape = _collision_shape.shape.duplicate() as CircleShape2D
	_collision_shape.shape = circle_shape


func _sync_collision_radius() -> void:
	if _collision_shape.shape is CircleShape2D:
		(_collision_shape.shape as CircleShape2D).radius = projectile_radius
