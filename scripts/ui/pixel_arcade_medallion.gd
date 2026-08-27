extends Control

const Palette = preload("res://scripts/ui/pixel_arcade_palette.gd")
const SEGMENTS := 32


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	var radius := maxf(minf(size.x, size.y) * 0.5 - 2.0, 0.0)
	if radius <= 0.0:
		return
	var center := size * 0.5
	draw_circle(center, radius, Palette.OUTLINE_DARK)
	draw_circle(center, maxf(radius - 3.0, 0.0), Palette.METAL)
	draw_circle(center, maxf(radius - 6.0, 0.0), Palette.PANEL_DEEP)
	draw_arc(center, radius - 3.0, 0.0, TAU, SEGMENTS, Palette.GOLD, 2.0, true)
	draw_arc(center, maxf(radius - 9.0, 0.0), 0.0, TAU, SEGMENTS, Palette.ORANGE_DEEP, 2.0, true)
	for direction in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
		draw_rect(
			Rect2(center + direction * (radius - 8.0) - Vector2(2.0, 2.0), Vector2(4.0, 4.0)),
			Palette.GOLD
		)
