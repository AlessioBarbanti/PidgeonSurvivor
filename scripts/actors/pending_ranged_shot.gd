class_name PendingRangedShot
extends Node2D

## PS-158: quando un Tiratore muore durante il proprio telegraph, il colpo
## gia' annunciato non deve sparire con lui. Questo nodo eredita origine e
## tempo residuo del telegraph e completa lo sparo in autonomia, cosi' una
## build ad alto DPS/piercing non puo' azzerare la minaccia semplicemente
## uccidendo la fonte prima che il colpo parta (vedi ranged_enemy.gd
## `_on_died`). Il ring di telegraph resta disegnato per tutta l'attesa: la
## minaccia continua a essere leggibile e schivabile, non diventa danno
## invisibile.

@export var projectile_scene: PackedScene

var _remaining := 0.0
var _duration := 0.001
var _attack_range := 0.0
var _telegraph_color := Color.WHITE
var _ring_base_radius := 20.0
var _damage := 0.0
var _speed := 0.0
var _lifetime := 0.0
var _radius := 8.0
var _pressure_multiplier := 1.0
var _run_controller: RunController
var _player: Player
var _projectile_parent: Node


func setup(
	remaining_seconds: float,
	duration_seconds: float,
	attack_range: float,
	telegraph_color: Color,
	ring_base_radius: float,
	damage: float,
	speed: float,
	lifetime: float,
	radius: float,
	pressure_multiplier_value: float,
	run_controller: RunController,
	player: Player,
	projectile_parent: Node
) -> void:
	_remaining = maxf(remaining_seconds, 0.0)
	_duration = maxf(duration_seconds, 0.001)
	_attack_range = attack_range
	_telegraph_color = telegraph_color
	_ring_base_radius = ring_base_radius
	_damage = damage
	_speed = speed
	_lifetime = lifetime
	_radius = radius
	_pressure_multiplier = pressure_multiplier_value
	_run_controller = run_controller
	_player = player
	_projectile_parent = projectile_parent
	queue_redraw()


func get_remaining() -> float:
	return _remaining


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_run_controller) or not _run_controller.is_running():
		return
	_remaining = maxf(_remaining - maxf(delta, 0.0), 0.0)
	queue_redraw()
	if _remaining <= 0.0:
		_fire()


func _draw() -> void:
	var progress := 1.0 - clampf(_remaining / _duration, 0.0, 1.0)
	var ring_radius := _ring_base_radius + progress * 14.0
	draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 32, _telegraph_color, 4.0, true)


## Ricontrolla il raggio a fine attesa, come farebbe il Tiratore ancora vivo:
## il bersaglio puo' essere uscito dal raggio nel frattempo.
func _fire() -> void:
	if (
		is_instance_valid(_player)
		and _player.is_alive()
		and global_position.distance_squared_to(_player.global_position) <= _attack_range * _attack_range
		and projectile_scene != null
		and is_instance_valid(_projectile_parent)
		and _projectile_parent.is_inside_tree()
	):
		var instance := projectile_scene.instantiate()
		if instance is BossProjectile:
			var projectile := instance as BossProjectile
			_projectile_parent.add_child(projectile)
			projectile.global_position = global_position
			var direction := _player.global_position - global_position
			if direction.is_zero_approx():
				direction = Vector2.RIGHT
			if not projectile.initialize(
				direction.normalized(),
				_damage * _pressure_multiplier,
				_speed,
				_lifetime,
				_radius,
				_run_controller,
				_player
			):
				projectile.queue_free()
		elif is_instance_valid(instance):
			instance.free()
	queue_free()
