class_name BossProjectile
extends Area2D

signal hit_processed(player: Player, damage: float)
signal expired(projectile: BossProjectile)

const PLAYER_BODY_MASK := 1 << 0

@export var body_color := Color(1.0, 0.28, 0.18, 1.0):
	set(value):
		body_color = value
		queue_redraw()

@export var outline_color := Color(0.22, 0.02, 0.04, 1.0):
	set(value):
		outline_color = value
		queue_redraw()

var direction := Vector2.RIGHT
var damage := 0.0
var speed := 0.0
var lifetime_remaining := 0.0
var projectile_radius := 8.0

var _run_controller: RunController
var _player: Player
var _spent := false

@onready var _collision_shape: CollisionShape2D = %CollisionShape


func _ready() -> void:
	add_to_group(&"enemy_projectiles")
	_make_collision_shape_unique()
	_sync_collision_radius()
	collision_layer = 0
	collision_mask = PLAYER_BODY_MASK
	monitoring = true
	monitorable = false
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	queue_redraw()


func _physics_process(delta: float) -> void:
	if (
		_spent
		or not is_instance_valid(_run_controller)
		or not _run_controller.is_running()
	):
		return

	var safe_delta := maxf(delta, 0.0) if is_finite(delta) else 0.0
	var movement_delta := minf(safe_delta, maxf(lifetime_remaining, 0.0))
	global_position += direction * speed * movement_delta
	lifetime_remaining -= safe_delta
	if lifetime_remaining <= 0.0:
		expire()


func _draw() -> void:
	draw_circle(Vector2.ZERO, projectile_radius + 3.0, outline_color)
	draw_circle(Vector2.ZERO, projectile_radius, body_color)
	draw_arc(
		Vector2.ZERO,
		projectile_radius + 6.0,
		0.0,
		TAU,
		16,
		Color(body_color, 0.55),
		2.0,
		true
	)


func initialize(
	initial_direction: Vector2,
	initial_damage: float,
	initial_speed: float,
	initial_lifetime: float,
	initial_radius: float,
	run_controller: RunController,
	player: Player
) -> bool:
	if (
		initial_direction.is_zero_approx()
		or not initial_direction.is_finite()
		or not is_finite(initial_damage)
		or initial_damage <= 0.0
		or not is_instance_valid(run_controller)
		or not is_instance_valid(player)
	):
		return false

	direction = initial_direction.normalized()
	damage = initial_damage
	speed = maxf(initial_speed, 0.0) if is_finite(initial_speed) else 0.0
	lifetime_remaining = maxf(initial_lifetime, 0.0) if is_finite(initial_lifetime) else 0.0
	projectile_radius = maxf(initial_radius, 1.0) if is_finite(initial_radius) else 1.0
	_run_controller = run_controller
	_player = player
	rotation = direction.angle()
	if is_node_ready():
		_sync_collision_radius()
	queue_redraw()
	return lifetime_remaining > 0.0


func try_hit(player: Player) -> bool:
	if (
		_spent
		or player != _player
		or not is_instance_valid(player)
		or not player.is_alive()
		or not is_instance_valid(_run_controller)
		or not _run_controller.is_running()
	):
		return false

	_spent = true
	_disable_immediately()
	var damage_applied := player.take_contact_damage(damage, global_position)
	if damage_applied:
		hit_processed.emit(player, damage)
	expired.emit(self)
	queue_free()
	return damage_applied


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


func get_player() -> Player:
	return _player if is_instance_valid(_player) else null


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		try_hit(body as Player)


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
