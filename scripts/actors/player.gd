class_name Player
extends CharacterBody2D

signal health_changed(player: Player, health_current: float, health_max: float)
signal damaged(player: Player, amount: float, health_current: float)
signal died(player: Player)
signal friend_changed(definition: FriendDefinition)
signal facing_direction_changed(direction: Vector2)

@export_group("Content")
@export var friend_definition: FriendDefinition

@export_group("Movement")
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

@export_group("Combat Feedback")
@export_range(0.0, 1.0, 0.005) var damage_flash_duration := PresentationTimings.PLAYER_DAMAGE_FLASH_SECONDS
@export_range(0.0, 1.0, 0.01) var damage_reaction_duration := PresentationTimings.PLAYER_DAMAGE_REACTION_SECONDS
@export_range(0.0, 0.5, 0.01) var damage_squash_strength := 0.13

const DEFAULT_FACING_DIRECTION := Vector2.RIGHT
const HORIZONTAL_FACING_EPSILON := 0.001

var movement_input := Vector2.ZERO:
	set(value):
		movement_input = value.limit_length(1.0)
		_update_facing_from_movement(movement_input)
		if is_node_ready():
			_sync_character_animation_state()

var _arena_layout: ArenaLayout
var _run_controller: RunController
var _damage_flash_remaining := 0.0
var _damage_reaction_remaining := 0.0
var _death_handled := false
var _base_health_max := 100.0
var _base_move_speed := 360.0
var _base_pickup_radius := 160.0
var _character_move_speed_multiplier := 1.0
var _character_pickup_radius_multiplier := 1.0
var _character_health_max_multiplier := 1.0
var _move_speed_multiplier := 1.0
var _pickup_radius_multiplier := 1.0
var _health_max_multiplier := 1.0
var _passive_controller: FriendPassiveController
var _character_base_scale := Vector2.ONE
var _facing_direction := DEFAULT_FACING_DIRECTION
var _character_idle_texture: Texture2D
var _character_walk_frames: Array[Texture2D] = []
var _character_walk_frame_index := 0
var _character_walk_elapsed := 0.0
var _character_is_walking := false
var _last_movement_direction := DEFAULT_FACING_DIRECTION

@onready var _collision_shape: CollisionShape2D = %CollisionShape
@onready var _health_component: HealthComponent = %HealthComponent
@onready var _weapon_controller: WeaponController = %WeaponController
@onready var _ability_controller: AbilityController = %AbilityController
@onready var _character_sprite: Sprite2D = %CharacterSprite


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	_make_collision_shape_unique()
	_sync_collision_radius()
	_base_health_max = _health_component.health_max
	_base_move_speed = move_speed
	_base_pickup_radius = pickup_radius
	_character_base_scale = _character_sprite.scale
	_connect_health_component()
	_connect_arena_layout()
	_refresh_character_visual()
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
	_damage_reaction_remaining = maxf(
		_damage_reaction_remaining - safe_delta,
		0.0
	)
	_health_component.advance_invulnerability(safe_delta)
	velocity = movement_input * move_speed
	move_and_slide()
	_clamp_to_playfield()
	_advance_character_animation(safe_delta)
	_update_character_feedback()
	if (
		_damage_flash_remaining > 0.0
		or _damage_reaction_remaining > 0.0
		or _health_component.is_invulnerable()
	):
		queue_redraw()


func _draw() -> void:
	_draw_health_arc()


func set_movement_input(value: Vector2) -> void:
	movement_input = value


func clear_movement_input() -> void:
	movement_input = Vector2.ZERO
	velocity = Vector2.ZERO


func get_facing_direction() -> Vector2:
	return _facing_direction


func get_last_movement_direction() -> Vector2:
	return _last_movement_direction


func is_character_walking() -> bool:
	return _character_is_walking


func get_character_walk_frame_index() -> int:
	return _character_walk_frame_index


func get_character_texture() -> Texture2D:
	return _character_sprite.texture if is_instance_valid(_character_sprite) else null


func is_character_flipped_horizontally() -> bool:
	return _character_sprite.flip_h if is_instance_valid(_character_sprite) else false


func get_character_visual_offset() -> Vector2:
	return _character_sprite.position if is_instance_valid(_character_sprite) else Vector2.ZERO


func get_character_visual_rotation() -> float:
	return _character_sprite.rotation if is_instance_valid(_character_sprite) else 0.0


func get_friend_definition() -> FriendDefinition:
	return friend_definition


func set_friend_definition(definition: FriendDefinition) -> bool:
	if definition == null or not definition.is_valid():
		return false
	friend_definition = definition
	_refresh_character_visual()
	friend_changed.emit(friend_definition)
	return true


func set_passive_controller(controller: FriendPassiveController) -> void:
	_passive_controller = controller


func get_passive_controller() -> FriendPassiveController:
	return _passive_controller if is_instance_valid(_passive_controller) else null


func take_contact_damage(amount: float) -> bool:
	if (
		not is_instance_valid(_run_controller)
		or not _run_controller.is_running()
		or not is_instance_valid(_health_component)
		or _death_handled
	):
		return false
	var resolved_amount := amount
	if is_instance_valid(_passive_controller):
		resolved_amount = _passive_controller.resolve_incoming_damage(amount)
	if resolved_amount <= 0.0:
		return false
	return _health_component.take_damage(resolved_amount)


func reset_for_run() -> void:
	_death_handled = false
	_damage_flash_remaining = 0.0
	_damage_reaction_remaining = 0.0
	reset_upgrade_stat_multipliers()
	clear_movement_input()
	_set_facing_direction(DEFAULT_FACING_DIRECTION)
	_last_movement_direction = DEFAULT_FACING_DIRECTION
	if is_instance_valid(_health_component):
		_health_component.set_health_max(get_base_health_max())
		_health_component.reset_to_max()
	_update_character_feedback()
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


func set_upgrade_stat_multipliers(
	move_speed_multiplier: float,
	pickup_radius_multiplier: float,
	health_max_multiplier: float = 1.0,
	preserve_health_ratio: bool = true
) -> bool:
	if (
		not is_finite(move_speed_multiplier)
		or move_speed_multiplier <= 0.0
		or not is_finite(pickup_radius_multiplier)
		or pickup_radius_multiplier <= 0.0
		or not is_finite(health_max_multiplier)
		or health_max_multiplier <= 0.0
	):
		return false

	_move_speed_multiplier = move_speed_multiplier
	_pickup_radius_multiplier = pickup_radius_multiplier
	_health_max_multiplier = health_max_multiplier
	_recalculate_effective_stats(preserve_health_ratio)
	return true


func set_character_stat_multipliers(
	move_speed_multiplier: float,
	pickup_radius_multiplier: float = 1.0,
	health_max_multiplier: float = 1.0
) -> bool:
	if (
		not is_finite(move_speed_multiplier)
		or move_speed_multiplier <= 0.0
		or not is_finite(pickup_radius_multiplier)
		or pickup_radius_multiplier <= 0.0
		or not is_finite(health_max_multiplier)
		or health_max_multiplier <= 0.0
	):
		return false
	_character_move_speed_multiplier = move_speed_multiplier
	_character_pickup_radius_multiplier = pickup_radius_multiplier
	_character_health_max_multiplier = health_max_multiplier
	_recalculate_effective_stats(true)
	return true


func reset_character_stat_multipliers() -> void:
	_character_move_speed_multiplier = 1.0
	_character_pickup_radius_multiplier = 1.0
	_character_health_max_multiplier = 1.0
	_recalculate_effective_stats(true)


func reset_upgrade_stat_multipliers() -> void:
	_move_speed_multiplier = 1.0
	_pickup_radius_multiplier = 1.0
	_health_max_multiplier = 1.0
	_recalculate_effective_stats(true)


func get_base_move_speed() -> float:
	return _base_move_speed * _character_move_speed_multiplier


func get_base_pickup_radius() -> float:
	return _base_pickup_radius * _character_pickup_radius_multiplier


func get_move_speed_multiplier() -> float:
	return _move_speed_multiplier


func get_pickup_radius_multiplier() -> float:
	return _pickup_radius_multiplier


func get_base_health_max() -> float:
	return _base_health_max * _character_health_max_multiplier


func get_health_max_multiplier() -> float:
	return _health_max_multiplier


func get_character_move_speed_multiplier() -> float:
	return _character_move_speed_multiplier


func get_character_health_max_multiplier() -> float:
	return _character_health_max_multiplier


func is_alive() -> bool:
	return (
		is_instance_valid(_health_component)
		and not _death_handled
		and _health_component.is_alive()
	)


func get_damage_flash_remaining() -> float:
	return _damage_flash_remaining


func get_damage_reaction_remaining() -> float:
	return _damage_reaction_remaining


func get_visual_damage_scale() -> Vector2:
	if damage_reaction_duration <= 0.0 or _damage_reaction_remaining <= 0.0:
		return Vector2.ONE
	var strength := clampf(
		_damage_reaction_remaining / damage_reaction_duration,
		0.0,
		1.0
	)
	return Vector2(
		1.0 + damage_squash_strength * strength,
		1.0 - damage_squash_strength * strength
	)


func _make_collision_shape_unique() -> void:
	var circle_shape := CircleShape2D.new()
	if _collision_shape.shape is CircleShape2D:
		circle_shape = _collision_shape.shape.duplicate() as CircleShape2D
	_collision_shape.shape = circle_shape


func _refresh_character_visual() -> void:
	if not is_instance_valid(_character_sprite):
		return
	_character_idle_texture = (
		friend_definition.get_gameplay_idle_right()
		if friend_definition != null
		else null
	)
	_character_walk_frames = (
		friend_definition.get_gameplay_walk_right_frames()
		if friend_definition != null
		else [] as Array[Texture2D]
	)
	_character_walk_frame_index = 0
	_character_walk_elapsed = 0.0
	_character_is_walking = false
	_sync_character_animation_state()
	_update_character_feedback()


func _update_character_feedback() -> void:
	if not is_instance_valid(_character_sprite):
		return
	_character_sprite.scale = _character_base_scale * get_visual_damage_scale()
	_character_sprite.self_modulate = (
		Color(1.0, 0.72, 0.8, 1.0)
		if _damage_flash_remaining > 0.0
		else Color.WHITE
	)


func _update_facing_from_movement(value: Vector2) -> void:
	if value.is_zero_approx():
		return
	_last_movement_direction = value.normalized()
	if absf(value.x) <= HORIZONTAL_FACING_EPSILON:
		return
	_set_facing_direction(Vector2.RIGHT if value.x > 0.0 else Vector2.LEFT)


func _set_facing_direction(value: Vector2) -> void:
	var resolved := Vector2.RIGHT if value.x >= 0.0 else Vector2.LEFT
	if resolved == _facing_direction:
		if is_instance_valid(_character_sprite):
			_character_sprite.flip_h = resolved == Vector2.LEFT
		return
	_facing_direction = resolved
	if is_instance_valid(_character_sprite):
		_character_sprite.flip_h = _facing_direction == Vector2.LEFT
	facing_direction_changed.emit(_facing_direction)


func _sync_character_animation_state() -> void:
	if not is_instance_valid(_character_sprite):
		return
	var should_walk := (
		not movement_input.is_zero_approx()
	)
	if should_walk != _character_is_walking:
		_character_is_walking = should_walk
		_character_walk_frame_index = 0
		_character_walk_elapsed = 0.0
	_apply_character_frame()


func _advance_character_animation(delta: float) -> void:
	_sync_character_animation_state()
	if not _character_is_walking or _character_walk_frames.size() < 2:
		return
	var fps := (
		friend_definition.gameplay_walk_fps
		if friend_definition != null
		else 8.0
	)
	var frame_duration := 1.0 / maxf(fps, 1.0)
	_character_walk_elapsed += maxf(delta, 0.0)
	while _character_walk_elapsed >= frame_duration:
		_character_walk_elapsed -= frame_duration
		_character_walk_frame_index = (
			(_character_walk_frame_index + 1) % _character_walk_frames.size()
		)
	_apply_character_frame()


func _apply_character_frame() -> void:
	if not is_instance_valid(_character_sprite):
		return
	if _character_is_walking and not _character_walk_frames.is_empty():
		_character_sprite.texture = _character_walk_frames[_character_walk_frame_index]
		var gait_phase := _character_walk_frame_index % 4
		_character_sprite.position = (
			Vector2(0.0, -2.0)
			if gait_phase == 1 or gait_phase == 3
			else Vector2.ZERO
		)
		_character_sprite.rotation = (
			-0.035 if gait_phase == 0
			else 0.035 if gait_phase == 2
			else 0.0
		)
	else:
		_character_sprite.texture = _character_idle_texture
		_character_sprite.position = Vector2.ZERO
		_character_sprite.rotation = 0.0
	_character_sprite.visible = _character_sprite.texture != null
	_character_sprite.flip_h = _facing_direction == Vector2.LEFT


func _recalculate_effective_stats(preserve_health_ratio: bool) -> void:
	move_speed = get_base_move_speed() * _move_speed_multiplier
	pickup_radius = get_base_pickup_radius() * _pickup_radius_multiplier
	if is_instance_valid(_health_component):
		_health_component.set_health_max(
			get_base_health_max() * _health_max_multiplier,
			preserve_health_ratio
		)


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
	if is_instance_valid(_run_controller) and not _run_controller.is_running():
		return
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
	_damage_flash_remaining = maxf(damage_flash_duration, 0.0)
	_damage_reaction_remaining = maxf(damage_reaction_duration, 0.0)
	_update_character_feedback()
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
	_update_character_feedback()
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
