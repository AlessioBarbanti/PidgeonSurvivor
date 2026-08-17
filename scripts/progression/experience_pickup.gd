class_name ExperiencePickup
extends Node2D

signal collected(pickup: ExperiencePickup, amount: int)

@export_range(1, 1000000, 1, "or_greater") var experience_amount := 1:
	set(value):
		experience_amount = maxi(value, 1)

@export_range(1.0, 2000.0, 1.0, "or_greater") var magnet_speed := 460.0:
	set(value):
		magnet_speed = maxf(value, 1.0) if is_finite(value) else 1.0

@export_range(1.0, 128.0, 0.5, "or_greater") var collect_radius := 18.0:
	set(value):
		collect_radius = maxf(value, 1.0) if is_finite(value) else 1.0

@export_group("Visual")
@export var body_color := Color(1.0, 0.78, 0.16, 1.0):
	set(value):
		body_color = value
		queue_redraw()

@export var outline_color := Color(0.25, 0.09, 0.02, 1.0):
	set(value):
		outline_color = value
		queue_redraw()

var _target: Player
var _run_controller: RunController
var _collected := false


func _ready() -> void:
	queue_redraw()


func _physics_process(delta: float) -> void:
	if not _can_advance():
		return

	var offset := _target.global_position - global_position
	var distance_squared := offset.length_squared()
	var pickup_radius := _target.get_pickup_radius()
	if distance_squared > pickup_radius * pickup_radius:
		return

	if distance_squared <= collect_radius * collect_radius:
		_collect_once()
		return

	var safe_delta := maxf(delta, 0.0) if is_finite(delta) else 0.0
	global_position = global_position.move_toward(
		_target.global_position,
		magnet_speed * safe_delta
	)
	if global_position.distance_squared_to(_target.global_position) <= (
		collect_radius * collect_radius
	):
		_collect_once()


func _draw() -> void:
	var outer_points := PackedVector2Array([
		Vector2(0.0, -10.0),
		Vector2(9.0, 0.0),
		Vector2(0.0, 10.0),
		Vector2(-9.0, 0.0),
	])
	var inner_points := PackedVector2Array([
		Vector2(0.0, -6.0),
		Vector2(5.5, 0.0),
		Vector2(0.0, 6.0),
		Vector2(-5.5, 0.0),
	])
	draw_colored_polygon(outer_points, outline_color)
	draw_colored_polygon(inner_points, body_color)
	draw_circle(Vector2.ZERO, 2.0, Color.WHITE)


func configure(
	run_controller: RunController,
	target: Player,
	amount: int
) -> void:
	_run_controller = run_controller
	_target = target
	experience_amount = amount


func try_collect() -> bool:
	if not _can_advance():
		return false
	var distance_squared := global_position.distance_squared_to(
		_target.global_position
	)
	var effective_radius := minf(_target.get_pickup_radius(), collect_radius)
	if distance_squared > effective_radius * effective_radius:
		return false
	return _collect_once()


func is_collected() -> bool:
	return _collected


func get_target() -> Player:
	return _target if is_instance_valid(_target) else null


func get_run_controller() -> RunController:
	return _run_controller if is_instance_valid(_run_controller) else null


func _can_advance() -> bool:
	return (
		not _collected
		and is_instance_valid(_target)
		and _target.is_alive()
		and is_instance_valid(_run_controller)
		and _run_controller.is_running()
	)


func _collect_once() -> bool:
	if _collected:
		return false
	_collected = true
	set_physics_process(false)
	collected.emit(self, experience_amount)
	queue_free()
	return true
