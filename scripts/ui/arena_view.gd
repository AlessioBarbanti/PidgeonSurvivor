class_name ArenaView
extends Node2D

@export var safe_area_color := Color(0.055, 0.075, 0.12, 1.0)
@export var playfield_color := Color(0.075, 0.105, 0.17, 1.0)
@export var grid_color := Color(0.18, 0.31, 0.46, 0.28)
@export var border_color := Color(0.22, 0.79, 1.0, 0.9)
@export_range(2, 20, 1) var grid_columns := 12
@export_range(2, 20, 1) var grid_rows := 7

var _safe_area_rect := Rect2()
var _playfield_rect := Rect2()


func update_layout(safe_area_rect: Rect2, playfield_rect: Rect2) -> void:
	_safe_area_rect = safe_area_rect
	_playfield_rect = playfield_rect
	queue_redraw()


func _draw() -> void:
	if _safe_area_rect.has_area():
		draw_rect(_safe_area_rect, safe_area_color, true)
	if not _playfield_rect.has_area():
		return

	draw_rect(_playfield_rect, playfield_color, true)
	for column in range(1, grid_columns):
		var x := lerpf(
			_playfield_rect.position.x,
			_playfield_rect.end.x,
			float(column) / float(grid_columns)
		)
		draw_line(
			Vector2(x, _playfield_rect.position.y),
			Vector2(x, _playfield_rect.end.y),
			grid_color,
			1.0
		)
	for row in range(1, grid_rows):
		var y := lerpf(
			_playfield_rect.position.y,
			_playfield_rect.end.y,
			float(row) / float(grid_rows)
		)
		draw_line(
			Vector2(_playfield_rect.position.x, y),
			Vector2(_playfield_rect.end.x, y),
			grid_color,
			1.0
		)

	draw_rect(_playfield_rect, border_color, false, 3.0, true)

