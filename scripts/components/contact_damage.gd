class_name ContactDamage
extends Area2D

signal damage_applied(player: Player, amount: float)

const PLAYER_BODY_MASK := 1 << 0

@export_range(0.0, 1000000.0, 0.1, "or_greater") var damage := 20.0:
	set(value):
		damage = maxf(value, 0.0) if is_finite(value) else 0.0

var _run_controller: RunController
var _enabled := true


func _ready() -> void:
	collision_layer = 0
	collision_mask = PLAYER_BODY_MASK
	monitoring = _enabled
	monitorable = false


func _physics_process(_delta: float) -> void:
	if not _can_apply_damage():
		return
	for body in get_overlapping_bodies():
		if body is Player and try_damage(body as Player):
			return


func set_run_controller(value: RunController) -> void:
	_run_controller = value


func get_run_controller() -> RunController:
	return _run_controller if is_instance_valid(_run_controller) else null


func try_damage(player: Player) -> bool:
	if (
		not _can_apply_damage()
		or not is_instance_valid(player)
		or player.is_queued_for_deletion()
		or not player.is_alive()
	):
		return false
	if not player.take_contact_damage(damage):
		return false
	damage_applied.emit(player, damage)
	return true


func enable() -> void:
	_enabled = true
	set_physics_process(true)
	set_deferred("monitoring", true)
	set_deferred("collision_mask", PLAYER_BODY_MASK)


func disable() -> void:
	_enabled = false
	set_physics_process(false)
	set_deferred("monitoring", false)
	set_deferred("collision_mask", 0)


func is_enabled() -> bool:
	return _enabled


func _can_apply_damage() -> bool:
	return (
		_enabled
		and damage > 0.0
		and is_instance_valid(_run_controller)
		and _run_controller.is_running()
	)
