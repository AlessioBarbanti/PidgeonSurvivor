class_name FirstBoss
extends BaseEnemy

signal attack_telegraphed(
	boss: FirstBoss,
	pattern_id: StringName,
	duration: float
)
signal attack_executed(
	boss: FirstBoss,
	pattern_id: StringName,
	affected_count: int
)

const RADIAL_VOLLEY := &"radial_volley"
const TARGETED_BLAST := &"targeted_blast"

@export var definition: BossDefinition
@export var projectile_scene: PackedScene

var _projectile_parent: Node
var _attack_cooldown_remaining := 0.0
var _active_pattern_id: StringName
var _telegraph_remaining := 0.0
var _telegraph_duration := 0.0
var _targeted_position := Vector2.ZERO
var _next_pattern_index := 0
var _radial_volley_count := 0
var _targeted_blast_count := 0
var _active_projectiles: Array[BossProjectile] = []
@onready var _boss_sprite := get_node_or_null("BossSprite") as Sprite2D


func _ready() -> void:
	super._ready()
	_sync_boss_visual()


func _exit_tree() -> void:
	clear_attack_runtime()
	super._exit_tree()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_sync_boss_facing()
	_advance_attack_cycle(delta)


func _draw() -> void:
	super._draw()
	_draw_boss_mark()
	_draw_active_telegraph()


func configure_boss(
	definition_value: BossDefinition,
	target: Player,
	run_controller: RunController,
	projectile_parent: Node
) -> bool:
	if (
		definition_value == null
		or not definition_value.is_valid()
		or not is_instance_valid(target)
		or not is_instance_valid(run_controller)
		or not is_instance_valid(projectile_parent)
		or projectile_scene == null
	):
		return false

	definition = definition_value
	_projectile_parent = projectile_parent
	move_speed = definition.move_speed
	collision_radius = definition.collision_radius
	experience_amount = definition.experience_reward
	body_color = definition.body_color
	outline_color = definition.outline_color
	accent_color = definition.accent_color
	_sync_boss_visual()
	set_target(target)
	set_run_controller(run_controller)

	var health_component := get_health_component()
	var contact_damage := get_contact_damage()
	if health_component == null or contact_damage == null:
		return false
	health_component.set_health_max(definition.health_max)
	health_component.reset_to_max()
	contact_damage.damage = definition.contact_damage
	reset_attack_cycle()
	return true


func reset_attack_cycle() -> void:
	clear_attack_runtime()
	_attack_cooldown_remaining = (
		definition.initial_attack_delay
		if definition != null
		else 0.0
	)
	_next_pattern_index = 0
	_radial_volley_count = 0
	_targeted_blast_count = 0
	queue_redraw()


func clear_attack_runtime() -> void:
	_active_pattern_id = &""
	_telegraph_remaining = 0.0
	_telegraph_duration = 0.0
	_targeted_position = Vector2.ZERO
	var projectiles_to_clear := _active_projectiles.duplicate()
	_active_projectiles.clear()
	for projectile in projectiles_to_clear:
		if is_instance_valid(projectile) and not projectile.is_queued_for_deletion():
			projectile.expire()
	queue_redraw()


func get_definition() -> BossDefinition:
	return definition


func get_boss_visual_texture() -> Texture2D:
	return _boss_sprite.texture if is_instance_valid(_boss_sprite) else null


func get_boss_visual_modulate() -> Color:
	return _boss_sprite.self_modulate if is_instance_valid(_boss_sprite) else Color.WHITE


func get_active_pattern_id() -> StringName:
	return _active_pattern_id


func is_telegraph_active() -> bool:
	return not _active_pattern_id.is_empty() and _telegraph_remaining > 0.0


func get_telegraph_remaining() -> float:
	return _telegraph_remaining


func get_targeted_position() -> Vector2:
	return _targeted_position


func get_radial_volley_count() -> int:
	return _radial_volley_count


func get_targeted_blast_count() -> int:
	return _targeted_blast_count


func get_active_projectile_count() -> int:
	_prune_projectiles()
	return _active_projectiles.size()


func get_attack_cooldown_remaining() -> float:
	return _attack_cooldown_remaining


func _sync_boss_visual() -> void:
	if not is_instance_valid(_boss_sprite) or definition == null:
		return
	_boss_sprite.texture = definition.get_visual_texture()
	_boss_sprite.self_modulate = definition.sprite_modulate
	var texture_size := (
		_boss_sprite.texture.get_size()
		if _boss_sprite.texture != null
		else Vector2.ZERO
	)
	if texture_size.x > 0.0 and texture_size.y > 0.0:
		var target_diameter := collision_radius * 1.9
		var scale_factor := target_diameter / maxf(texture_size.x, texture_size.y)
		_boss_sprite.scale = Vector2.ONE * clampf(scale_factor, 1.0, 4.0)
	_boss_sprite.visible = _boss_sprite.texture != null
	_sync_boss_facing()


func _sync_boss_facing() -> void:
	if not is_instance_valid(_boss_sprite):
		return
	var target := get_target()
	if target == null:
		return
	var offset_to_target := target.global_position - global_position
	if not is_zero_approx(offset_to_target.x):
		_boss_sprite.flip_h = offset_to_target.x < 0.0


func _advance_attack_cycle(delta: float) -> void:
	var run_controller := get_run_controller()
	if (
		definition == null
		or not definition.is_valid()
		or not is_alive()
		or run_controller == null
		or not run_controller.is_running()
	):
		return

	var safe_delta := maxf(delta, 0.0) if is_finite(delta) else 0.0
	if is_telegraph_active():
		_telegraph_remaining = maxf(_telegraph_remaining - safe_delta, 0.0)
		queue_redraw()
		if _telegraph_remaining <= 0.0:
			_execute_active_pattern()
		return

	_attack_cooldown_remaining = maxf(
		_attack_cooldown_remaining - safe_delta,
		0.0
	)
	if _attack_cooldown_remaining <= 0.0:
		_begin_next_pattern()


func _begin_next_pattern() -> void:
	if definition == null or not is_alive():
		return
	if _next_pattern_index % 2 == 0:
		_active_pattern_id = RADIAL_VOLLEY
		_telegraph_duration = definition.radial_telegraph_duration
	else:
		_active_pattern_id = TARGETED_BLAST
		_telegraph_duration = definition.targeted_telegraph_duration
		var target := get_target()
		_targeted_position = (
			target.global_position
			if is_instance_valid(target)
			else global_position
		)
	_telegraph_remaining = _telegraph_duration
	attack_telegraphed.emit(self, _active_pattern_id, _telegraph_duration)
	queue_redraw()


func _execute_active_pattern() -> void:
	var executed_pattern := _active_pattern_id
	var affected_count := 0
	match executed_pattern:
		RADIAL_VOLLEY:
			affected_count = _spawn_radial_volley()
			_radial_volley_count += 1
		TARGETED_BLAST:
			affected_count = _execute_targeted_blast()
			_targeted_blast_count += 1
		_:
			return

	_active_pattern_id = &""
	_telegraph_remaining = 0.0
	_telegraph_duration = 0.0
	_attack_cooldown_remaining = definition.pattern_interval
	_next_pattern_index += 1
	attack_executed.emit(self, executed_pattern, affected_count)
	queue_redraw()


func _spawn_radial_volley() -> int:
	if (
		projectile_scene == null
		or not is_instance_valid(_projectile_parent)
		or not _projectile_parent.is_inside_tree()
	):
		return 0
	var run_controller := get_run_controller()
	var player := get_target() as Player
	if run_controller == null or player == null:
		return 0

	var spawned_count := 0
	for projectile_index in definition.radial_projectile_count:
		var instance := projectile_scene.instantiate()
		if not instance is BossProjectile:
			if is_instance_valid(instance):
				instance.free()
			continue
		var projectile := instance as BossProjectile
		_projectile_parent.add_child(projectile)
		projectile.global_position = global_position
		var angle := TAU * float(projectile_index) / float(definition.radial_projectile_count)
		if not projectile.initialize(
			Vector2.RIGHT.rotated(angle),
			definition.radial_projectile_damage,
			definition.radial_projectile_speed,
			definition.radial_projectile_lifetime,
			definition.radial_projectile_radius,
			run_controller,
			player
		):
			projectile.queue_free()
			continue
		_active_projectiles.append(projectile)
		projectile.tree_exiting.connect(
			_on_projectile_tree_exiting.bind(projectile),
			CONNECT_ONE_SHOT
		)
		spawned_count += 1
	return spawned_count


func _execute_targeted_blast() -> int:
	var run_controller := get_run_controller()
	var player := get_target() as Player
	if (
		run_controller == null
		or not run_controller.is_running()
		or player == null
		or not player.is_alive()
	):
		return 0
	var effective_radius := definition.targeted_blast_radius + player.collision_radius
	if player.global_position.distance_squared_to(_targeted_position) > effective_radius * effective_radius:
		return 0
	return 1 if player.take_contact_damage(definition.targeted_blast_damage) else 0


func _draw_boss_mark() -> void:
	var crown_y := -collision_radius - 12.0
	var crown_points := PackedVector2Array([
		Vector2(-collision_radius * 0.55, crown_y),
		Vector2(-collision_radius * 0.28, crown_y - 18.0),
		Vector2.ZERO + Vector2(0.0, crown_y - 5.0),
		Vector2(collision_radius * 0.28, crown_y - 18.0),
		Vector2(collision_radius * 0.55, crown_y),
	])
	draw_polyline(crown_points, accent_color, 6.0, true)


func _draw_active_telegraph() -> void:
	if not is_telegraph_active() or definition == null:
		return
	var progress := 1.0 - clampf(
		_telegraph_remaining / maxf(_telegraph_duration, BossDefinition.MINIMUM_POSITIVE_VALUE),
		0.0,
		1.0
	)
	var color := definition.telegraph_color
	match _active_pattern_id:
		RADIAL_VOLLEY:
			var ring_radius := collision_radius + 24.0 + progress * 18.0
			draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 48, color, 5.0, true)
			for projectile_index in definition.radial_projectile_count:
				var direction := Vector2.RIGHT.rotated(
					TAU * float(projectile_index) / float(definition.radial_projectile_count)
				)
				draw_line(
					direction * (collision_radius + 8.0),
					direction * (collision_radius + 38.0),
					color,
					3.0,
					true
				)
		TARGETED_BLAST:
			var local_target := _targeted_position - global_position
			draw_circle(
				local_target,
				definition.targeted_blast_radius * progress,
				Color(color, 0.16)
			)
			draw_arc(
				local_target,
				definition.targeted_blast_radius,
				0.0,
				TAU,
				64,
				color,
				5.0,
				true
			)
			var crosshair_radius := definition.targeted_blast_radius * 0.72
			for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
				draw_line(
					local_target + direction * crosshair_radius * 0.62,
					local_target + direction * crosshair_radius,
					Color(1.0, 1.0, 1.0, color.a),
					4.0,
					true
				)


func _prune_projectiles() -> void:
	for index in range(_active_projectiles.size() - 1, -1, -1):
		if not is_instance_valid(_active_projectiles[index]):
			_active_projectiles.remove_at(index)


func _on_projectile_tree_exiting(projectile: BossProjectile) -> void:
	_active_projectiles.erase(projectile)
