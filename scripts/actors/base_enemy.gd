class_name BaseEnemy
extends CharacterBody2D

signal health_changed(enemy: BaseEnemy, health_current: float, health_max: float)
signal damaged(enemy: BaseEnemy, amount: float, health_current: float)
signal died(enemy: BaseEnemy)
signal speed_modifiers_changed(enemy: BaseEnemy, effective_multiplier: float)

@export_range(0.0, 2000.0, 1.0) var move_speed: float = 140.0

@export_range(1, 1000000, 1, "or_greater") var experience_amount := 1:
	set(value):
		experience_amount = maxi(value, 1)

## Moltiplicatore assegnato dallo spawn ordinario per conservare il budget XP
## quando cresce la frequenza delle kill. I Boss non passano dallo spawner e
## restano quindi al valore unitario dichiarato nei propri dati.
@export_range(0.0, 64.0, 0.001, "or_greater") var experience_reward_scale := 1.0:
	set(value):
		experience_reward_scale = maxf(value, 0.0) if is_finite(value) else 0.0

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

@export_enum("Base", "Special") var visual_variant := 0:
	set(value):
		visual_variant = clampi(value, 0, 1)
		if is_node_ready():
			_sync_enemy_sprite_animation()

@export_group("Combat Feedback")
@export_range(0.0, 1.0, 0.01) var damage_flash_duration := PresentationTimings.ENEMY_DAMAGE_FLASH_SECONDS
@export_range(0.0, 1.0, 0.01) var hit_reaction_duration := PresentationTimings.ENEMY_HIT_REACTION_SECONDS
@export_range(0.0, 0.5, 0.01) var hit_squash_strength := 0.16

var _target: Node2D
var _pursuit_offset := Vector2.ZERO
var _run_controller: RunController
var _damage_flash_remaining := 0.0
var _hit_reaction_remaining := 0.0
var _death_handled := false
var _knockback_velocity := Vector2.ZERO
var _knockback_remaining := 0.0
var _speed_modifiers: Dictionary = {}

@onready var _collision_shape: CollisionShape2D = %CollisionShape
@onready var _health_component: HealthComponent = %HealthComponent
@onready var _hurtbox: Hurtbox = %Hurtbox
@onready var _hurtbox_collision_shape: CollisionShape2D = %HurtboxCollisionShape
@onready var _contact_damage: ContactDamage = %ContactDamage
@onready var _contact_collision_shape: CollisionShape2D = %ContactCollisionShape
@onready var _enemy_sprite := get_node_or_null("EnemySprite") as AnimatedSprite2D


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
	_sync_enemy_sprite_animation()
	_sync_enemy_sprite_feedback()
	queue_redraw()


func _exit_tree() -> void:
	_disconnect_run_controller()
	_disconnect_health_component()


func _process(delta: float) -> void:
	if is_instance_valid(_run_controller) and not _run_controller.is_running():
		return
	var safe_delta := maxf(delta, 0.0) if is_finite(delta) else 0.0
	_damage_flash_remaining = maxf(
		_damage_flash_remaining - safe_delta,
		0.0
	)
	_hit_reaction_remaining = maxf(
		_hit_reaction_remaining - safe_delta,
		0.0
	)
	_sync_enemy_sprite_feedback()
	queue_redraw()
	if (
		is_zero_approx(_damage_flash_remaining)
		and is_zero_approx(_hit_reaction_remaining)
	):
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

	var offset_to_target := (
		_target.global_position + _pursuit_offset - global_position
	)
	if offset_to_target.is_zero_approx():
		velocity = Vector2.ZERO
		return
	_sync_enemy_sprite_facing(offset_to_target)

	var desired_direction := offset_to_target.normalized()
	velocity = desired_direction * get_effective_move_speed()
	move_and_slide()
	_steer_around_blocking_obstacle(desired_direction)


## move_and_slide() azzera la componente tangenziale quando la direzione
## desiderata punta quasi frontalmente contro un ostacolo, lasciando il
## nemico immobile all'infinito: qui lo si fa scivolare lungo il bordo
## dell'ostacolo scegliendo la tangente piu' vicina al bersaglio.
func _steer_around_blocking_obstacle(desired_direction: Vector2) -> void:
	if get_slide_collision_count() == 0:
		return
	var normal := get_slide_collision(0).get_normal()
	if normal.dot(desired_direction) >= -0.3:
		return
	var tangent := Vector2(-normal.y, normal.x)
	if tangent.dot(desired_direction) < 0.0:
		tangent = -tangent
	velocity = tangent * get_effective_move_speed()
	move_and_slide()


func _draw() -> void:
	if not has_visual_sprite():
		draw_set_transform(Vector2.ZERO, 0.0, get_visual_hit_scale())
		var visible_body_color := body_color
		if get_speed_multiplier() < 1.0 - 0.0001:
			visible_body_color = visible_body_color.lerp(
				Color(0.25, 0.68, 1.0, visible_body_color.a),
				0.38
			)
		if _damage_flash_remaining > 0.0:
			visible_body_color = visible_body_color.lerp(Color.WHITE, 0.82)
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
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
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


func set_speed_modifier(modifier_id: StringName, multiplier: float) -> bool:
	if (
		String(modifier_id).is_empty()
		or not is_finite(multiplier)
		or multiplier <= 0.0
	):
		return false
	_speed_modifiers[modifier_id] = multiplier
	speed_modifiers_changed.emit(self, get_speed_multiplier())
	_sync_enemy_sprite_feedback()
	queue_redraw()
	return true


func remove_speed_modifier(modifier_id: StringName) -> bool:
	if not _speed_modifiers.erase(modifier_id):
		return false
	speed_modifiers_changed.emit(self, get_speed_multiplier())
	_sync_enemy_sprite_feedback()
	queue_redraw()
	return true


func clear_speed_modifiers() -> void:
	if _speed_modifiers.is_empty():
		return
	_speed_modifiers.clear()
	speed_modifiers_changed.emit(self, 1.0)
	_sync_enemy_sprite_feedback()
	queue_redraw()


func has_speed_modifier(modifier_id: StringName) -> bool:
	return _speed_modifiers.has(modifier_id)


func get_speed_multiplier() -> float:
	var multiplier := 1.0
	for value: Variant in _speed_modifiers.values():
		multiplier *= float(value)
	return multiplier


func get_effective_move_speed() -> float:
	return move_speed * get_speed_multiplier()


func is_alive() -> bool:
	return (
		is_instance_valid(_health_component)
		and not _death_handled
		and _health_component.is_alive()
	)


func get_damage_flash_remaining() -> float:
	return _damage_flash_remaining


func get_hit_reaction_remaining() -> float:
	return _hit_reaction_remaining


func get_visual_hit_scale() -> Vector2:
	if hit_reaction_duration <= 0.0 or _hit_reaction_remaining <= 0.0:
		return Vector2.ONE
	var strength := clampf(
		_hit_reaction_remaining / hit_reaction_duration,
		0.0,
		1.0
	)
	return Vector2(
		1.0 + hit_squash_strength * strength,
		1.0 - hit_squash_strength * strength
	)


func get_visual_variant() -> int:
	return visual_variant


func set_visual_variant(value: int) -> void:
	visual_variant = value


func get_enemy_sprite() -> AnimatedSprite2D:
	return _enemy_sprite if is_instance_valid(_enemy_sprite) else null


## Vero se un nemico offre già un proprio sprite visivo, cosicché il corpo
## e il contorno geometrici di riserva restino confinati ai nemici senza
## un'illustrazione dedicata (i sottotipi con sprite proprio, come i Boss,
## sovrascrivono questo metodo).
func has_visual_sprite() -> bool:
	return is_instance_valid(_enemy_sprite)


func get_health_component() -> HealthComponent:
	return _health_component if is_instance_valid(_health_component) else null


func get_hurtbox() -> Hurtbox:
	return _hurtbox if is_instance_valid(_hurtbox) else null


func get_contact_damage() -> ContactDamage:
	return _contact_damage if is_instance_valid(_contact_damage) else null


func get_experience_amount() -> int:
	return experience_amount


func get_experience_reward_value() -> float:
	return float(experience_amount) * experience_reward_scale


func set_target(value: Node2D) -> void:
	_target = value
	velocity = Vector2.ZERO


func get_target() -> Node2D:
	return _target if is_instance_valid(_target) else null


## Offset stabile assegnato allo spawn per disperdere il punto di inseguimento
## di ogni nemico attorno al target, cosicche' grandi gruppi non convergano
## visivamente sullo stesso pixel pur restando privi di collisione reciproca.
func set_pursuit_offset(offset: Vector2) -> void:
	_pursuit_offset = offset if offset.is_finite() else Vector2.ZERO


func get_pursuit_offset() -> Vector2:
	return _pursuit_offset


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
	_sync_enemy_sprite_animation()


func get_run_controller() -> RunController:
	return _run_controller if is_instance_valid(_run_controller) else null


func clear_chase_dependencies() -> void:
	_target = null
	_pursuit_offset = Vector2.ZERO
	_disconnect_run_controller()
	_run_controller = null
	if is_instance_valid(_contact_damage):
		_contact_damage.set_run_controller(null)
	velocity = Vector2.ZERO
	_clear_knockback()
	clear_speed_modifiers()
	_sync_enemy_sprite_animation()


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
	_sync_enemy_sprite_animation()


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
	_hit_reaction_remaining = maxf(hit_reaction_duration, 0.0)
	set_process(
		_damage_flash_remaining > 0.0
		or _hit_reaction_remaining > 0.0
	)
	_sync_enemy_sprite_feedback()
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


func _sync_enemy_sprite_animation() -> void:
	if not is_instance_valid(_enemy_sprite):
		return
	var animation_name := &"special" if visual_variant == 1 else &"base"
	if _enemy_sprite.animation != animation_name:
		_enemy_sprite.animation = animation_name
		_enemy_sprite.frame = 0
	if is_instance_valid(_run_controller) and _run_controller.is_running():
		_enemy_sprite.play(animation_name)
	else:
		_enemy_sprite.pause()


func _sync_enemy_sprite_facing(offset_to_target: Vector2) -> void:
	if not is_instance_valid(_enemy_sprite) or is_zero_approx(offset_to_target.x):
		return
	_enemy_sprite.flip_h = offset_to_target.x < 0.0


func _sync_enemy_sprite_feedback() -> void:
	if not is_instance_valid(_enemy_sprite):
		return
	_enemy_sprite.scale = get_visual_hit_scale()
	if _damage_flash_remaining > 0.0:
		_enemy_sprite.self_modulate = Color(1.35, 1.35, 1.35, 1.0)
	elif get_speed_multiplier() < 1.0 - 0.0001:
		_enemy_sprite.self_modulate = Color(0.66, 0.84, 1.0, 1.0)
	else:
		_enemy_sprite.self_modulate = Color.WHITE


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
