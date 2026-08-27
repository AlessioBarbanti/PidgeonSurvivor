class_name HealthPickup
extends Node2D

## Pickup di cura ("coscia di piccione"): stessa meccanica di calamita e
## raccolta di ExperiencePickup, ma trasporta HP invece di XP. Non applica la
## cura direttamente: il dropper che la riceve dal segnale `collected` decide
## come usarla, cosi' il pickup resta un semplice trasportatore di valore.
signal collected(pickup: HealthPickup, amount: float)

const VISUAL_RADIUS := 11.0

@export_range(0.001, 1000000.0, 0.1, "or_greater") var heal_amount := 10.0:
	set(value):
		heal_amount = maxf(value, 0.001) if is_finite(value) else 0.001

@export_range(1.0, 2000.0, 1.0, "or_greater") var magnet_speed := 460.0:
	set(value):
		magnet_speed = maxf(value, 1.0) if is_finite(value) else 1.0

@export_range(1.0, 128.0, 0.5, "or_greater") var collect_radius := 18.0:
	set(value):
		collect_radius = maxf(value, 1.0) if is_finite(value) else 1.0

@export_group("Visual")
@export var meat_color := Color(0.62, 0.32, 0.14, 1.0):
	set(value):
		meat_color = value
		queue_redraw()

@export var char_color := Color(0.28, 0.12, 0.05, 1.0):
	set(value):
		char_color = value
		queue_redraw()

@export var bone_color := Color(0.94, 0.9, 0.8, 1.0):
	set(value):
		bone_color = value
		queue_redraw()

## Slot pronto per l'arte definitiva: quando assegnata, sostituisce il
## disegno segnaposto senza toccare raccolta, calamita o layout.
@export var texture: Texture2D:
	set(value):
		texture = value
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
	if texture != null:
		var half_size := Vector2.ONE * VISUAL_RADIUS * 2.0
		draw_texture_rect(texture, Rect2(-half_size, half_size * 2.0), false)
		return

	# Osso chiaro verso il basso a sinistra, "carne" grigliata caricaturale
	# in alto a destra: leggibile e distinta dal cristallo XP a rombo.
	draw_line(Vector2(-8.0, 9.0), Vector2(-2.0, 3.0), bone_color, 4.0, true)
	draw_circle(Vector2(-8.0, 9.0), 2.6, bone_color)

	var meat_points := PackedVector2Array([
		Vector2(-3.0, 4.0),
		Vector2(2.0, -9.0),
		Vector2(9.0, -6.0),
		Vector2(9.0, 2.0),
		Vector2(3.0, 8.0),
	])
	draw_colored_polygon(meat_points, meat_color)
	draw_polyline(
		PackedVector2Array([meat_points[meat_points.size() - 1], meat_points[0]]),
		char_color,
		1.5,
		true
	)

	draw_line(Vector2(1.0, -3.0), Vector2(6.0, -1.0), char_color, 1.4, true)
	draw_line(Vector2(-0.5, 1.0), Vector2(5.0, 3.5), char_color, 1.4, true)


func configure(
	run_controller: RunController,
	target: Player,
	amount: float
) -> void:
	_run_controller = run_controller
	_target = target
	heal_amount = amount


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


func get_confinement_radius() -> float:
	return maxf(VISUAL_RADIUS, collect_radius)


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
	collected.emit(self, heal_amount)
	queue_free()
	return true
