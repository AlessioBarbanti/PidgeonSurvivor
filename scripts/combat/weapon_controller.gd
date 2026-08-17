class_name WeaponController
extends Node2D

signal projectile_fired(projectile: Projectile, target: BaseEnemy)

@export var weapon_profile: WeaponProfile
@export var projectile_scene: PackedScene

@export_group("Visual")
@export var weapon_color := Color(1.0, 0.91, 0.2, 1.0):
	set(value):
		weapon_color = value
		queue_redraw()

@export var outline_color := Color(0.015, 0.025, 0.06, 1.0):
	set(value):
		outline_color = value
		queue_redraw()

var _run_controller: RunController
var _targeting_system: TargetingSystem
var _projectile_parent: Node
var _source: Node2D
var _arena_layout: ArenaLayout
var _cooldown_remaining := 0.0
var _last_aim_direction := Vector2.RIGHT
var _invalid_projectile_scene_warning_emitted := false
var _projectile_scene_valid := true
var _base_shots_per_second := 0.0
var _base_damage := 0.0
var _character_fire_rate_multiplier := 1.0
var _character_damage_multiplier := 1.0
var _fire_rate_multiplier := 1.0
var _damage_multiplier := 1.0
var _projectile_chain_enabled := false
var _projectile_chain_jumps := 0
var _projectile_chain_damage_falloff := 1.0
var _projectile_chain_radius := 0.0
var _projectile_oscillation_amplitude := 0.0
var _projectile_oscillation_frequency_hz := 0.0


func _ready() -> void:
	queue_redraw()


func _exit_tree() -> void:
	_disconnect_run_controller()


func _process(delta: float) -> void:
	if not _has_valid_dependencies() or not _run_controller.is_running():
		return

	if _cooldown_remaining > 0.0:
		_cooldown_remaining = maxf(_cooldown_remaining - maxf(delta, 0.0), 0.0)
	if _cooldown_remaining <= 0.0:
		try_fire()


func _draw() -> void:
	var length := 32.0
	if weapon_profile != null:
		length = maxf(weapon_profile.muzzle_offset, 12.0)
	var start := Vector2(9.0, 0.0)
	var finish := Vector2(length, 0.0)
	draw_line(start, finish, outline_color, 10.0, true)
	draw_line(start, finish, weapon_color, 5.0, true)
	draw_circle(finish, 3.0, weapon_color)


func configure(
	run_controller: RunController,
	targeting_system: TargetingSystem,
	projectile_parent: Node,
	source: Node2D = null,
	arena_layout: ArenaLayout = null
) -> void:
	_disconnect_run_controller()
	_run_controller = run_controller
	_targeting_system = targeting_system
	_projectile_parent = projectile_parent
	_source = source if is_instance_valid(source) else get_parent() as Node2D
	_arena_layout = arena_layout
	_capture_base_stats()
	_connect_run_controller()
	reset_for_run(false)


func try_fire() -> Projectile:
	if (
		not _has_valid_dependencies()
		or not _run_controller.is_running()
		or _cooldown_remaining > 0.0
	):
		return null

	var target := _targeting_system.get_nearest_alive(_source.global_position)
	if target == null:
		return null

	var offset_to_target := target.global_position - _source.global_position
	var aim_direction := _last_aim_direction
	var muzzle_offset := 0.0
	if not offset_to_target.is_zero_approx():
		aim_direction = offset_to_target.normalized()
		muzzle_offset = minf(weapon_profile.muzzle_offset, offset_to_target.length())

	var instance := projectile_scene.instantiate()
	if not instance is Projectile:
		if is_instance_valid(instance):
			instance.free()
		if not _invalid_projectile_scene_warning_emitted:
			_invalid_projectile_scene_warning_emitted = true
			_projectile_scene_valid = false
			push_warning(
				"WeaponController: projectile_scene deve avere Projectile come nodo root."
			)
		return null

	var projectile := instance as Projectile
	_projectile_parent.add_child(projectile)
	projectile.global_position = _source.global_position + aim_direction * muzzle_offset
	if not projectile.initialize(
		aim_direction,
		get_effective_damage(),
		weapon_profile.projectile_speed,
		weapon_profile.projectile_lifetime,
		weapon_profile.projectile_radius,
		_run_controller
	):
		projectile.queue_free()
		return null
	if not projectile.configure_signature_effects(
		_projectile_chain_enabled,
		_projectile_chain_jumps,
		_projectile_chain_damage_falloff,
		_projectile_chain_radius,
		_projectile_oscillation_amplitude,
		_projectile_oscillation_frequency_hz,
		_targeting_system
	):
		projectile.expire()
		return null

	_last_aim_direction = aim_direction
	rotation = _last_aim_direction.angle()
	_cooldown_remaining = get_effective_fire_interval()
	queue_redraw()
	projectile_fired.emit(projectile, target)
	return projectile


func reset_for_run(clear_existing_projectiles: bool = true) -> void:
	_cooldown_remaining = 0.0
	reset_upgrade_stat_multipliers()
	_last_aim_direction = Vector2.RIGHT
	_invalid_projectile_scene_warning_emitted = false
	_projectile_scene_valid = true
	rotation = 0.0
	queue_redraw()
	if clear_existing_projectiles:
		clear_projectiles()


func clear_projectiles() -> void:
	if not is_instance_valid(_projectile_parent):
		return
	for child in _projectile_parent.get_children():
		if child is Projectile and not child.is_queued_for_deletion():
			(child as Projectile).expire()


func get_run_controller() -> RunController:
	return _run_controller if is_instance_valid(_run_controller) else null


func get_targeting_system() -> TargetingSystem:
	return _targeting_system if is_instance_valid(_targeting_system) else null


func get_projectile_parent() -> Node:
	return _projectile_parent if is_instance_valid(_projectile_parent) else null


func get_arena_layout() -> ArenaLayout:
	return _arena_layout if is_instance_valid(_arena_layout) else null


func get_cooldown_remaining() -> float:
	return _cooldown_remaining


func is_ready_to_fire() -> bool:
	return _cooldown_remaining <= 0.0


func set_upgrade_stat_multipliers(
	fire_rate_multiplier: float,
	damage_multiplier: float
) -> bool:
	if (
		not is_finite(fire_rate_multiplier)
		or fire_rate_multiplier <= 0.0
		or not is_finite(damage_multiplier)
		or damage_multiplier <= 0.0
	):
		return false
	_fire_rate_multiplier = fire_rate_multiplier
	_damage_multiplier = damage_multiplier
	return true


func reset_upgrade_stat_multipliers() -> void:
	_fire_rate_multiplier = 1.0
	_damage_multiplier = 1.0
	reset_projectile_upgrade_modifiers()


func set_character_stat_multipliers(
	fire_rate_multiplier: float,
	damage_multiplier: float = 1.0
) -> bool:
	if (
		not is_finite(fire_rate_multiplier)
		or fire_rate_multiplier <= 0.0
		or not is_finite(damage_multiplier)
		or damage_multiplier <= 0.0
	):
		return false
	_character_fire_rate_multiplier = fire_rate_multiplier
	_character_damage_multiplier = damage_multiplier
	return true


func reset_character_stat_multipliers() -> void:
	_character_fire_rate_multiplier = 1.0
	_character_damage_multiplier = 1.0


func set_projectile_upgrade_modifiers(
	chain_enabled: bool,
	chain_jumps: int,
	chain_damage_falloff: float,
	chain_radius: float,
	oscillation_amplitude: float,
	oscillation_frequency_hz: float
) -> bool:
	if (
		chain_jumps < 0
		or not is_finite(chain_damage_falloff)
		or chain_damage_falloff <= 0.0
		or chain_damage_falloff > 1.0
		or not is_finite(chain_radius)
		or chain_radius < 0.0
		or (chain_enabled and (chain_jumps <= 0 or chain_radius <= 0.0))
		or not is_finite(oscillation_amplitude)
		or oscillation_amplitude < 0.0
		or not is_finite(oscillation_frequency_hz)
		or oscillation_frequency_hz < 0.0
		or (oscillation_amplitude > 0.0 and oscillation_frequency_hz <= 0.0)
	):
		return false
	_projectile_chain_enabled = chain_enabled
	_projectile_chain_jumps = chain_jumps
	_projectile_chain_damage_falloff = chain_damage_falloff
	_projectile_chain_radius = chain_radius
	_projectile_oscillation_amplitude = oscillation_amplitude
	_projectile_oscillation_frequency_hz = oscillation_frequency_hz
	return true


func reset_projectile_upgrade_modifiers() -> void:
	_projectile_chain_enabled = false
	_projectile_chain_jumps = 0
	_projectile_chain_damage_falloff = 1.0
	_projectile_chain_radius = 0.0
	_projectile_oscillation_amplitude = 0.0
	_projectile_oscillation_frequency_hz = 0.0


func is_projectile_chain_enabled() -> bool:
	return _projectile_chain_enabled


func get_projectile_chain_jumps() -> int:
	return _projectile_chain_jumps


func get_projectile_chain_damage_falloff() -> float:
	return _projectile_chain_damage_falloff


func get_projectile_chain_radius() -> float:
	return _projectile_chain_radius


func get_projectile_oscillation_amplitude() -> float:
	return _projectile_oscillation_amplitude


func get_projectile_oscillation_frequency_hz() -> float:
	return _projectile_oscillation_frequency_hz


func get_base_shots_per_second() -> float:
	return _base_shots_per_second * _character_fire_rate_multiplier


func get_base_damage() -> float:
	return _base_damage * _character_damage_multiplier


func get_fire_rate_multiplier() -> float:
	return _fire_rate_multiplier


func get_damage_multiplier() -> float:
	return _damage_multiplier


func get_character_fire_rate_multiplier() -> float:
	return _character_fire_rate_multiplier


func get_effective_shots_per_second() -> float:
	return get_base_shots_per_second() * _fire_rate_multiplier


func get_effective_damage() -> float:
	return get_base_damage() * _damage_multiplier


func get_effective_fire_interval() -> float:
	var shots_per_second := get_effective_shots_per_second()
	return 1.0 / shots_per_second if shots_per_second > 0.0 else INF


func _has_valid_dependencies() -> bool:
	return (
		weapon_profile != null
		and get_effective_shots_per_second() > 0.0
		and projectile_scene != null
		and _projectile_scene_valid
		and is_instance_valid(_run_controller)
		and is_instance_valid(_targeting_system)
		and is_instance_valid(_projectile_parent)
		and _projectile_parent.is_inside_tree()
		and is_instance_valid(_source)
	)


func _capture_base_stats() -> void:
	if weapon_profile == null:
		_base_shots_per_second = 0.0
		_base_damage = 0.0
		return
	_base_shots_per_second = weapon_profile.shots_per_second
	_base_damage = weapon_profile.damage


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


func _on_run_started(_seed_value: int) -> void:
	reset_for_run()


func _on_restart_prepared() -> void:
	reset_for_run()
