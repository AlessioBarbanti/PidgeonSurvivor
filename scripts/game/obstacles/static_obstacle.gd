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

## B50: quando l'ostacolo ha zone visivamente trasparenti (es. il filo dei
## panni), la collisione deve seguire solo le parti opache invece dell'intero
## footprint. Ogni Rect2 e' espresso in spazio unitario centrato sull'origine
## (-0.5..0.5 su entrambi gli assi, come get_footprint_rect()), cosi' resta
## corretto qualunque sia footprint_size. Vuoto (default) mantiene il
## comportamento storico: un'unica CollisionShape2D grande quanto il footprint.
@export var collision_segments: Array[Rect2] = []:
	set(value):
		collision_segments = value
		if is_node_ready():
			_sync_collision_shape()
		queue_redraw()

@onready var _collision_shape: CollisionShape2D = %CollisionShape

var _segment_shapes: Array[CollisionShape2D] = []


func _ready() -> void:
	add_to_group(&"static_obstacles")
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
	for shape in _segment_shapes:
		shape.queue_free()
	_segment_shapes.clear()

	if collision_segments.is_empty():
		_collision_shape.disabled = false
		if _collision_shape.shape is RectangleShape2D:
			(_collision_shape.shape as RectangleShape2D).size = footprint_size
		return

	_collision_shape.disabled = true
	for index in collision_segments.size():
		var segment := collision_segments[index]
		var rect_shape := RectangleShape2D.new()
		rect_shape.size = segment.size * footprint_size
		var shape := CollisionShape2D.new()
		shape.name = "SegmentShape%d" % index
		shape.shape = rect_shape
		shape.position = (segment.position + segment.size * 0.5) * footprint_size
		add_child(shape)
		_segment_shapes.append(shape)
