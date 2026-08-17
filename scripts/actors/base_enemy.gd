class_name BaseEnemy
extends CharacterBody2D

signal health_changed(enemy: BaseEnemy, health_current: float, health_max: float)
signal damaged(enemy: BaseEnemy, amount: float, health_current: float)
signal died(enemy: BaseEnemy)

@export_range(0.0, 2000.0, 1.0) var move_speed: float = 140.0

@export_range(1, 1000000, 1, "or_greater") var experience_amount := 1:
	set(value):
		experience_amount = maxi(value, 1)

@export_range(1.0, 128.0, 0.5) var collision_radius: float = 20.0:
	set(value):
		collision_radius = maxf(value, 1.0)
		if is_node_ready():
			_sync_collision_radius()
		queue_redraw()

@export_group("Visual")
@export var body_color := Color(0.93, 0.2, 0.36, 1.0):
	set(value):
		body_color = value
		queue_redraw()

@export var outline_color := Color(0.18, 0.025, 0.07, 1.0):
	set(value):
		outline_color = value
		queue_redraw()

@export var accent_color := Color(1.0, 0.77, 0.22, 1.0):
	set(value):
		accent_color = value
		queue_redraw()

@export_range(0.0, 16.0, 0.5) var outline_width: float = 4.0:
	set(value):
		outline_width = maxf(value, 0.0)
		queue_redraw()

@export_group("Combat Feedback")
@export_range(0.0, 1.0, 0.01) var damage_flash_duration := 0.08

var _target: Node2D
var _run_controller: RunController
var _damage_flash_remaining := 0.0
var _death_handled := false
var _knockback_velocity := Vector2.ZERO
var _knockback_remaining := 0.0

@onready var _collision_shape: CollisionShape2D = %CollisionShape
@onready var _health_component: HealthComponent = %HealthComponent
@onready var _hurtbox: Hurtbox = %Hurtbox
@onready var _hurtbox_collision_shape: CollisionShape2D = %HurtboxCollisionShape
@onready var _contact_damage: ContactDamage = %ContactDamage
@onready var _contact_collision_shape: CollisionShape2D = %ContactCollisionShape


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	_make_collision_shapes_unique()
	_sync_collision_radius()
	_connect_health_component()
	_hurtbox.enable()
	_contact_damage.set_run_controller(_run_controller)
	_contact_damage.enable()
	_connect_run_controller()
	set_process(false)
	queue_redraw()


func _exit_tree() -> void:
	_disconnect_run_controller()
	_disconnect_health_component()


func _process(delta: float) -> void:
	_damage_flash_remaining = maxf(
		_damage_flash_remaining - maxf(delta, 0.0),
		0.0
	)
	queue_redraw()
	if is_zero_approx(_damage_flash_remaining):
		set_process(false)


func _physics_process(delta: float) -> void:
	if not _can_chase_target():
		velocity = Vector2.ZERO
		return
	if _knockback_remaining > 0.0:
		var safe_delta := maxf(delta, 0.0) if is_finite(delta) else 0.0
		velocity = _knockback_velocity
		move_and_slide()
		_knockback_remaining = maxf(_knockback_remaining - safe_delta, 0.0)
		if _knockback_remaining <= 0.0:
			_knockback_velocity = Vector2.ZERO
		return

	var offset_to_target := _target.global_position - global_position
	if offset_to_target.is_zero_approx():
		velocity = Vector2.ZERO
		return

	velocity = offset_to_target.normalized() * move_speed
	move_and_slide()


func _draw() -> void:
	var visible_body_color := body_color
	if _damage_flash_remaining > 0.0:
		visible_body_color = body_color.lerp(Color.WHITE, 0.78)
	draw_circle(
		Vector2.ZERO,
		collision_radius + outline_width,
		outline_color
	)
	draw_circle(Vector2.ZERO, collision_radius, visible_body_color)

	var eye_offset := Vector2(collision_radius * 0.35, -collision_radius * 0.2)
	var eye_radius := collision_radius * 0.13
	draw_circle(Vector2(-eye_offset.x, eye_offset.y), eye_radius, accent_color)
	draw_circle(eye_offset, eye_radius, accent_color)
	draw_line(
		Vector2(-collision_radius * 0.4, collision_radius * 0.35),
		Vector2(collision_radius * 0.4, collision_radius * 0.35),
		outline_color,
		maxf(outline_width * 0.75, 1.0),
		true
	)
	_draw_health_bar()


func take_damage(amount: float) -> bool:
	if not is_instance_valid(_health_component) or _death_handled:
		return false
	return _health_component.take_damage(amount)


func apply_knockback(knockback_velocity: Vector2, duration: float) -> bool:
	if (
		not is_alive()
		or not is_instance_valid(_run_controller)
		or not _run_controller.is_running()
		or not knockback_velocity.is_finite()
		or knockback_velocity.is_zero_approx()
		or not is_finite(duration)
		or duration <= 0.0
	):
		return false
	_knockback_velocity = knockback_velocity
	_knockback_remaining = duration
	return true


func get_knockback_remaining() -> float:
	return _knockback_remaining


func get_knockback_velocity() -> Vector2:
	return _knockback_velocity


func is_alive() -> bool:
	return (
		is_instance_valid(_health_component)
		and not _death_handled
		and _health_component.is_alive()
	)


func get_health_component() -> HealthComponent:
	return _health_component if is_instance_valid(_health_component) else null


func get_hurtbox() -> Hurtbox:
	return _hurtbox if is_instance_valid(_hurtbox) else null


func get_contact_damage() -> ContactDamage:
	return _contact_damage if is_instance_valid(_contact_damage) else null


func get_experience_amount() -> int:
	return experience_amount


func set_target(value: Node2D) -> void:
	_target = value
	velocity = Vector2.ZERO


func get_target() -> Node2D:
	return _target if is_instance_valid(_target) else null


func set_run_controller(value: RunController) -> void:
	if value == _run_controller:
		if not is_instance_valid(_run_controller) or not _run_controller.is_running():
			velocity = Vector2.ZERO
		return

	_disconnect_run_controller()
	_run_controller = value
	if is_node_ready() and is_instance_valid(_contact_damage):
		_contact_damage.set_run_controller(_run_controller)
	_connect_run_controller()
	if not is_instance_valid(_run_controller) or not _run_controller.is_running():
		velocity = Vector2.ZERO


func get_run_controller() -> RunController:
	return _run_controller if is_instance_valid(_run_controller) else null


func clear_chase_dependencies() -> void:
	_target = null
	_disconnect_run_controller()
	_run_controller = null
	if is_instance_valid(_contact_damage):
		_contact_damage.set_run_controller(null)
	velocity = Vector2.ZERO
	_clear_knockback()


func _can_chase_target() -> bool:
	return (
		is_alive()
		and is_instance_valid(_target)
		and is_instance_valid(_run_controller)
		and _run_controller.is_running()
	)


func _connect_run_controller() -> void:
	if not is_instance_valid(_run_controller):
		return
	if not _run_controller.state_changed.is_connected(_on_run_state_changed):
		_run_controller.state_changed.connect(_on_run_state_changed)


func _disconnect_run_controller() -> void:
	if not is_instance_valid(_run_controller):
		return
	if _run_controller.state_changed.is_connected(_on_run_state_changed):
		_run_controller.state_changed.disconnect(_on_run_state_changed)


func _on_run_state_changed(_previous_state: int, _current_state: int) -> void:
	if not is_instance_valid(_run_controller) or not _run_controller.is_running():
		velocity = Vector2.ZERO


func _make_collision_shapes_unique() -> void:
	var circle_shape := CircleShape2D.new()
	if _collision_shape.shape is CircleShape2D:
		circle_shape = _collision_shape.shape.duplicate() as CircleShape2D
	_collision_shape.shape = circle_shape

	var hurtbox_circle_shape := CircleShape2D.new()
	if _hurtbox_collision_shape.shape is CircleShape2D:
		hurtbox_circle_shape = (
			_hurtbox_collision_shape.shape.duplicate() as CircleShape2D
		)
	_hurtbox_collision_shape.shape = hurtbox_circle_shape

	var contact_circle_shape := CircleShape2D.new()
	if _contact_collision_shape.shape is CircleShape2D:
		contact_circle_shape = (
			_contact_collision_shape.shape.duplicate() as CircleShape2D
		)
	_contact_collision_shape.shape = contact_circle_shape


func _sync_collision_radius() -> void:
	if _collision_shape.shape is CircleShape2D:
		var circle_shape := _collision_shape.shape as CircleShape2D
		circle_shape.radius = collision_radius
	if (
		is_instance_valid(_hurtbox_collision_shape)
		and _hurtbox_collision_shape.shape is CircleShape2D
	):
		(_hurtbox_collision_shape.shape as CircleShape2D).radius = collision_radius
	if (
		is_instance_valid(_contact_collision_shape)
		and _contact_collision_shape.shape is CircleShape2D
	):
		(_contact_collision_shape.shape as CircleShape2D).radius = collision_radius


func _connect_health_component() -> void:
	if not is_instance_valid(_health_component):
		return
	if not _health_component.health_changed.is_connected(_on_health_changed):
		_health_component.health_changed.connect(_on_health_changed)
	if not _health_component.damaged.is_connected(_on_damaged):
		_health_component.damaged.connect(_on_damaged)
	if not _health_component.died.is_connected(_on_died):
		_health_component.died.connect(_on_died)


func _disconnect_health_component() -> void:
	if not is_instance_valid(_health_component):
		return
	if _health_component.health_changed.is_connected(_on_health_changed):
		_health_component.health_changed.disconnect(_on_health_changed)
	if _health_component.damaged.is_connected(_on_damaged):
		_health_component.damaged.disconnect(_on_damaged)
	if _health_component.died.is_connected(_on_died):
		_health_component.died.disconnect(_on_died)


func _on_health_changed(health_current: float, health_max: float) -> void:
	health_changed.emit(self, health_current, health_max)
	queue_redraw()


func _on_damaged(amount: float, health_current: float) -> void:
	_damage_flash_remaining = maxf(damage_flash_duration, 0.0)
	set_process(_damage_flash_remaining > 0.0)
	damaged.emit(self, amount, health_current)
	queue_redraw()


func _on_died() -> void:
	if _death_handled:
		return
	_death_handled = true
	velocity = Vector2.ZERO
	_clear_knockback()
	_hurtbox.disable()
	_contact_damage.disable()
	remove_from_group(&"enemies")
	died.emit(self)
	queue_free()


func _clear_knockback() -> void:
	_knockback_velocity = Vector2.ZERO
	_knockback_remaining = 0.0


func _draw_health_bar() -> void:
	if not is_instance_valid(_health_component):
		return
	var health_max := _health_component.health_max
	var health_current := _health_component.health_current
	if health_max <= 0.0 or health_current >= health_max or health_current <= 0.0:
		return

	var bar_size := Vector2(collision_radius * 2.0, 4.0)
	var bar_position := Vector2(
		-bar_size.x * 0.5,
		-collision_radius - outline_width - 10.0
	)
	draw_rect(Rect2(bar_position, bar_size), outline_color, true)
	var fill_ratio := clampf(health_current / health_max, 0.0, 1.0)
	draw_rect(
		Rect2(bar_position + Vector2.ONE, Vector2((bar_size.x - 2.0) * fill_ratio, bar_size.y - 2.0)),
		accent_color,
		true
	)
