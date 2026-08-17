class_name Player
extends CharacterBody2D

signal health_changed(player: Player, health_current: float, health_max: float)
signal damaged(player: Player, amount: float, health_current: float)
signal died(player: Player)

@export_range(0.0, 2000.0, 1.0) var move_speed: float = 360.0

@export_range(1.0, 1024.0, 1.0, "or_greater") var pickup_radius := 160.0:
	set(value):
		pickup_radius = maxf(value, 1.0) if is_finite(value) else 1.0

@export_range(1.0, 128.0, 0.5) var collision_radius: float = 24.0:
	set(value):
		collision_radius = maxf(value, 1.0)
		if is_node_ready():
			_sync_collision_radius()
		queue_redraw()

@export_group("Visual")
@export var body_color := Color(0.05, 0.88, 1.0, 1.0):
	set(value):
		body_color = value
		queue_redraw()

@export var outline_color := Color(0.015, 0.025, 0.06, 1.0):
	set(value):
		outline_color = value
		queue_redraw()

@export var accent_color := Color(1.0, 0.91, 0.2, 1.0):
	set(value):
		accent_color = value
		queue_redraw()

@export_range(0.0, 16.0, 0.5) var outline_width: float = 4.0:
	set(value):
		outline_width = maxf(value, 0.0)
		queue_redraw()

var movement_input := Vector2.ZERO:
	set(value):
		movement_input = value.limit_length(1.0)

var _arena_layout: ArenaLayout
var _run_controller: RunController
var _damage_flash_remaining := 0.0
var _death_handled := false
var _base_health_max := 100.0
var _base_pickup_radius := 160.0

@onready var _collision_shape: CollisionShape2D = %CollisionShape
@onready var _health_component: HealthComponent = %HealthComponent
@onready var _weapon_controller: WeaponController = %WeaponController
@onready var _ability_controller: AbilityController = %AbilityController


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	_make_collision_shape_unique()
	_sync_collision_radius()
	_base_health_max = _health_component.health_max
	_base_pickup_radius = pickup_radius
	_connect_health_component()
	_connect_arena_layout()
	_clamp_to_playfield()
	queue_redraw()


func _exit_tree() -> void:
	_disconnect_run_controller()
	_disconnect_health_component()
	_disconnect_arena_layout()


func _physics_process(delta: float) -> void:
	if is_instance_valid(_run_controller) and not _run_controller.is_running():
		velocity = Vector2.ZERO
		return
	if not is_alive():
		velocity = Vector2.ZERO
		return

	var safe_delta := maxf(delta, 0.0) if is_finite(delta) else 0.0
	_damage_flash_remaining = maxf(_damage_flash_remaining - safe_delta, 0.0)
	_health_component.advance_invulnerability(safe_delta)
	velocity = movement_input * move_speed
	move_and_slide()
	_clamp_to_playfield()
	if _damage_flash_remaining > 0.0 or _health_component.is_invulnerable():
		queue_redraw()


func _draw() -> void:
	var visible_body_color := body_color
	if _damage_flash_remaining > 0.0:
		visible_body_color = body_color.lerp(Color.WHITE, 0.82)
	elif (
		is_instance_valid(_health_component)
		and _health_component.is_invulnerable()
	):
		visible_body_color = body_color.lerp(Color.WHITE, 0.34)
	draw_circle(
		Vector2.ZERO,
		collision_radius + outline_width,
		outline_color
	)
	draw_circle(Vector2.ZERO, collision_radius, visible_body_color)

	var marker_size := collision_radius * 0.58
	var direction_marker := PackedVector2Array([
		Vector2(0.0, -marker_size),
		Vector2(marker_size * 0.72, marker_size * 0.55),
		Vector2(0.0, marker_size * 0.22),
		Vector2(-marker_size * 0.72, marker_size * 0.55),
	])
	draw_colored_polygon(direction_marker, accent_color)
	draw_circle(Vector2.ZERO, collision_radius * 0.14, outline_color)
	_draw_health_arc()


func set_movement_input(value: Vector2) -> void:
	movement_input = value


func clear_movement_input() -> void:
	movement_input = Vector2.ZERO
	velocity = Vector2.ZERO


func take_contact_damage(amount: float) -> bool:
	if (
		not is_instance_valid(_run_controller)
		or not _run_controller.is_running()
		or not is_instance_valid(_health_component)
		or _death_handled
	):
		return false
	return _health_component.take_damage(amount)


func reset_for_run() -> void:
	_death_handled = false
	_damage_flash_remaining = 0.0
	pickup_radius = _base_pickup_radius
	clear_movement_input()
	if is_instance_valid(_health_component):
		_health_component.set_health_max(_base_health_max)
		_health_component.reset_to_max()
	queue_redraw()


func set_arena_layout(value: ArenaLayout) -> void:
	if value == _arena_layout:
		return

	_disconnect_arena_layout()
	_arena_layout = value
	_connect_arena_layout()
	_clamp_to_playfield()


func get_arena_layout() -> ArenaLayout:
	return _arena_layout


func set_run_controller(value: RunController) -> void:
	if value == _run_controller:
		return
	_disconnect_run_controller()
	_run_controller = value
	_connect_run_controller()


func get_run_controller() -> RunController:
	return _run_controller if is_instance_valid(_run_controller) else null


func get_health_component() -> HealthComponent:
	return _health_component if is_instance_valid(_health_component) else null


func get_weapon_controller() -> WeaponController:
	return _weapon_controller


func get_ability_controller() -> AbilityController:
	return _ability_controller


func get_pickup_radius() -> float:
	return pickup_radius


func is_alive() -> bool:
	return (
		is_instance_valid(_health_component)
		and not _death_handled
		and _health_component.is_alive()
	)


func _make_collision_shape_unique() -> void:
	var circle_shape := CircleShape2D.new()
	if _collision_shape.shape is CircleShape2D:
		circle_shape = _collision_shape.shape.duplicate() as CircleShape2D
	_collision_shape.shape = circle_shape


func _sync_collision_radius() -> void:
	if _collision_shape.shape is CircleShape2D:
		var circle_shape := _collision_shape.shape as CircleShape2D
		circle_shape.radius = collision_radius


func _connect_arena_layout() -> void:
	if not is_instance_valid(_arena_layout):
		return
	if not _arena_layout.playfield_changed.is_connected(
		_on_playfield_changed
	):
		_arena_layout.playfield_changed.connect(_on_playfield_changed)


func _disconnect_arena_layout() -> void:
	if not is_instance_valid(_arena_layout):
		return
	if _arena_layout.playfield_changed.is_connected(_on_playfield_changed):
		_arena_layout.playfield_changed.disconnect(_on_playfield_changed)


func _on_playfield_changed(_playfield_rect: Rect2) -> void:
	_clamp_to_playfield()


func _connect_run_controller() -> void:
	if not is_instance_valid(_run_controller):
		return
	if not _run_controller.run_started.is_connected(_on_run_started):
		_run_controller.run_started.connect(_on_run_started)
	if not _run_controller.restart_prepared.is_connected(_on_restart_prepared):
		_run_controller.restart_prepared.connect(_on_restart_prepared)


func _disconnect_run_controller() -> void:
	if not is_instance_valid(_run_controller):
		_run_controller = null
		return
	if _run_controller.run_started.is_connected(_on_run_started):
		_run_controller.run_started.disconnect(_on_run_started)
	if _run_controller.restart_prepared.is_connected(_on_restart_prepared):
		_run_controller.restart_prepared.disconnect(_on_restart_prepared)
	_run_controller = null


func _connect_health_component() -> void:
	if not is_instance_valid(_health_component):
		return
	if not _health_component.health_changed.is_connected(_on_health_changed):
		_health_component.health_changed.connect(_on_health_changed)
	if not _health_component.damaged.is_connected(_on_damaged):
		_health_component.damaged.connect(_on_damaged)
	if not _health_component.died.is_connected(_on_died):
		_health_component.died.connect(_on_died)
	if not _health_component.invulnerability_changed.is_connected(
		_on_invulnerability_changed
	):
		_health_component.invulnerability_changed.connect(
			_on_invulnerability_changed
		)


func _disconnect_health_component() -> void:
	if not is_instance_valid(_health_component):
		return
	if _health_component.health_changed.is_connected(_on_health_changed):
		_health_component.health_changed.disconnect(_on_health_changed)
	if _health_component.damaged.is_connected(_on_damaged):
		_health_component.damaged.disconnect(_on_damaged)
	if _health_component.died.is_connected(_on_died):
		_health_component.died.disconnect(_on_died)
	if _health_component.invulnerability_changed.is_connected(
		_on_invulnerability_changed
	):
		_health_component.invulnerability_changed.disconnect(
			_on_invulnerability_changed
		)


func _on_health_changed(health_current: float, health_max: float) -> void:
	health_changed.emit(self, health_current, health_max)
	queue_redraw()


func _on_damaged(amount: float, health_current: float) -> void:
	_damage_flash_remaining = 0.12
	damaged.emit(self, amount, health_current)
	queue_redraw()


func _on_died() -> void:
	if _death_handled:
		return
	_death_handled = true
	clear_movement_input()
	died.emit(self)
	queue_redraw()


func _on_invulnerability_changed(_active: bool, _remaining: float) -> void:
	queue_redraw()


func _on_run_started(_seed_value: int) -> void:
	reset_for_run()


func _on_restart_prepared() -> void:
	reset_for_run()


func _clamp_to_playfield() -> void:
	if not is_instance_valid(_arena_layout):
		return
	global_position = _arena_layout.clamp_circle_center(
		global_position,
		collision_radius
	)


func _draw_health_arc() -> void:
	if not is_instance_valid(_health_component):
		return
	if _health_component.health_max <= 0.0:
		return
	var ratio := clampf(
		_health_component.health_current / _health_component.health_max,
		0.0,
		1.0
	)
	if ratio >= 1.0 or ratio <= 0.0:
		return
	var radius := collision_radius + outline_width + 6.0
	draw_arc(
		Vector2.ZERO,
		radius,
		-PI * 0.5,
		-PI * 0.5 + TAU * ratio,
		48,
		accent_color,
		4.0,
		true
	)
