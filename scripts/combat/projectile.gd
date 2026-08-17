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
var _oscillation_amplitude := 0.0
var _oscillation_frequency_hz := 0.0
var _oscillation_phase := 0.0
var _targeting_system: TargetingSystem
var _hit_target_ids: Dictionary = {}

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
	var previous_phase := _oscillation_phase
	_oscillation_phase += TAU * _oscillation_frequency_hz * movement_delta
	var movement := direction * speed * movement_delta
	if _oscillation_amplitude > 0.0:
		movement += direction.orthogonal() * _oscillation_amplitude * (
			sin(_oscillation_phase) - sin(previous_phase)
		)
	global_position += movement
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
	oscillation_amplitude: float,
	oscillation_frequency_hz: float,
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
		or not is_finite(oscillation_amplitude)
		or oscillation_amplitude < 0.0
		or not is_finite(oscillation_frequency_hz)
		or oscillation_frequency_hz < 0.0
		or (oscillation_amplitude > 0.0 and oscillation_frequency_hz <= 0.0)
	):
		return false
	_chain_enabled = chain_enabled
	_chain_jumps_remaining = chain_jumps
	_chain_damage_falloff = chain_damage_falloff
	_chain_radius = chain_radius
	_chain_current_damage = damage
	_oscillation_amplitude = oscillation_amplitude
	_oscillation_frequency_hz = oscillation_frequency_hz
	_oscillation_phase = 0.0
	_targeting_system = targeting_system
	_hit_target_ids.clear()
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
	var hit_damage := _chain_current_damage if _chain_enabled else damage
	# Il latch precede il danno: callback duplicate o rientranti non possono
	# riutilizzare lo stesso bersaglio durante la catena.
	if not _chain_enabled:
		_spent = true
		_disable_immediately()
	var damage_applied := target.take_damage(hit_damage)
	if damage_applied:
		hit_processed.emit(target, hit_damage)
	if not _chain_enabled:
		queue_free()
		return damage_applied

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


func get_oscillation_amplitude() -> float:
	return _oscillation_amplitude


func get_oscillation_frequency_hz() -> float:
	return _oscillation_frequency_hz


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
