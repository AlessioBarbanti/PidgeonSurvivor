class_name Projectile
extends Area2D

signal hit_processed(target: BaseEnemy, damage: float)
signal expired(projectile: Projectile)

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

var damage := 0.0
var direction := Vector2.RIGHT
var speed := 0.0
var lifetime_remaining := 0.0
var projectile_radius := 6.0

var _run_controller: RunController
var _spent := false

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


func _draw() -> void:
	var outline_width := maxf(projectile_radius * 0.45, 2.0)
	draw_line(
		Vector2(-projectile_radius * 2.8, 0.0),
		Vector2(-projectile_radius * 0.65, 0.0),
		trail_color,
		maxf(projectile_radius * 0.8, 2.0),
		true
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

	# Il latch precede il danno: callback duplicate o rientranti nello stesso frame
	# non possono applicare due hit mentre queue_free e ancora differito.
	_spent = true
	_disable_immediately()
	var damage_applied := target.take_damage(damage)
	if damage_applied:
		hit_processed.emit(target, damage)
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
