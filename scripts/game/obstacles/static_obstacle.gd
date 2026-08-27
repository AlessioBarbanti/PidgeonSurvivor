class_name StaticObstacle
extends StaticBody2D

## Segnaposto di collisione riusabile per gli elementi fissi dell'arena
## (camino, tavoli, filo dei panni): finche' `texture` resta vuota disegna un
## rettangolo colorato leggibile; assegnare `texture` piu' avanti sostituisce
## il segnaposto senza toccare collisione, posizione o layout.
@export var footprint_size := Vector2(160.0, 80.0):
	set(value):
		footprint_size = Vector2(maxf(value.x, 1.0), maxf(value.y, 1.0))
		if is_node_ready():
			_sync_collision_shape()
		queue_redraw()

@export var placeholder_color := Color(0.36, 0.29, 0.22, 1.0):
	set(value):
		placeholder_color = value
		queue_redraw()

@export var placeholder_outline_color := Color(0.16, 0.12, 0.09, 1.0):
	set(value):
		placeholder_outline_color = value
		queue_redraw()

@export_range(0.0, 16.0, 0.5) var placeholder_outline_width: float = 3.0:
	set(value):
		placeholder_outline_width = maxf(value, 0.0)
		queue_redraw()

## Slot pronto per l'arte definitiva (ImageGen): assegnarlo nell'editor
## sostituisce interamente il rettangolo segnaposto.
@export var texture: Texture2D:
	set(value):
		texture = value
		queue_redraw()

@onready var _collision_shape: CollisionShape2D = %CollisionShape


func _ready() -> void:
	_make_collision_shape_unique()
	_sync_collision_shape()
	queue_redraw()


func _draw() -> void:
	var half_size := footprint_size * 0.5
	if texture != null:
		draw_texture_rect(texture, Rect2(-half_size, footprint_size), false)
		return
	draw_rect(Rect2(-half_size, footprint_size), placeholder_color, true)
	if placeholder_outline_width > 0.0:
		draw_rect(
			Rect2(-half_size, footprint_size),
			placeholder_outline_color,
			false,
			placeholder_outline_width,
			true
		)


func get_footprint_rect() -> Rect2:
	return Rect2(global_position - footprint_size * 0.5, footprint_size)


func _make_collision_shape_unique() -> void:
	var rect_shape := RectangleShape2D.new()
	if _collision_shape.shape is RectangleShape2D:
		rect_shape = _collision_shape.shape.duplicate() as RectangleShape2D
	_collision_shape.shape = rect_shape


func _sync_collision_shape() -> void:
	if _collision_shape.shape is RectangleShape2D:
		(_collision_shape.shape as RectangleShape2D).size = footprint_size
