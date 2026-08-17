class_name Hurtbox
extends Area2D

const ENEMY_HURTBOX_LAYER := 1 << 1

var _enabled := true


func _ready() -> void:
	monitoring = false
	monitorable = _enabled
	collision_layer = ENEMY_HURTBOX_LAYER if _enabled else 0
	collision_mask = 0


func enable() -> void:
	_enabled = true
	set_deferred("monitorable", true)
	set_deferred("collision_layer", ENEMY_HURTBOX_LAYER)


func disable() -> void:
	_enabled = false
	set_deferred("monitorable", false)
	set_deferred("collision_layer", 0)


func is_enabled() -> bool:
	return _enabled


func get_damage_receiver() -> Node:
	return get_parent()
