class_name ArenaView
extends Node2D

@export var safe_area_color := Color(0.035, 0.047, 0.067, 1.0)
@export var playfield_color := Color(0.07, 0.09, 0.115, 1.0)
@export var background_texture: Texture2D
@export var background_modulate := Color(0.82, 0.86, 0.92, 0.92)
@export var tonal_patch_color := Color(0.11, 0.13, 0.15, 0.16)
@export var joint_color := Color(0.2, 0.22, 0.23, 0.16)
@export var stain_color := Color(0.025, 0.031, 0.038, 0.13)
@export var crack_color := Color(0.28, 0.29, 0.27, 0.18)
@export var edge_shadow_color := Color(0.008, 0.012, 0.018, 0.58)
@export_range(4, 32, 1) var tonal_patch_count := 18
@export_range(2, 24, 1) var joint_count := 10
@export_range(2, 24, 1) var stain_count := 9
@export_range(2, 24, 1) var crack_count := 7

var _safe_area_rect := Rect2()
var _playfield_rect := Rect2()


func update_layout(safe_area_rect: Rect2, playfield_rect: Rect2) -> void:
	_safe_area_rect = safe_area_rect
	_playfield_rect = playfield_rect
	queue_redraw()


func get_playfield_rect() -> Rect2:
	return _playfield_rect


func uses_debug_grid() -> bool:
	return false


func has_raster_background() -> bool:
	return background_texture != null and background_texture.get_size().x > 0.0


func uses_procedural_fallback() -> bool:
	return not has_raster_background()


func get_background_source_rect() -> Rect2:
	if not has_raster_background():
		return Rect2()
	return calculate_background_source_rect(
		_playfield_rect,
		background_texture.get_size()
	)


static func calculate_background_source_rect(
	destination_rect: Rect2,
	texture_size: Vector2
) -> Rect2:
	if not destination_rect.has_area() or texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return Rect2()
	var destination_aspect := destination_rect.size.x / destination_rect.size.y
	var texture_aspect := texture_size.x / texture_size.y
	if texture_aspect > destination_aspect:
		var source_width := texture_size.y * destination_aspect
		return Rect2(
			Vector2((texture_size.x - source_width) * 0.5, 0.0),
			Vector2(source_width, texture_size.y)
		)
	var source_height := texture_size.x / destination_aspect
	return Rect2(
		Vector2(0.0, (texture_size.y - source_height) * 0.5),
		Vector2(texture_size.x, source_height)
	)


func get_floor_feature_budget() -> Dictionary:
	return {
		"tonal_patches": tonal_patch_count,
		"joints": joint_count,
		"stains": stain_count,
		"cracks": crack_count,
	}


func _draw() -> void:
	if _safe_area_rect.has_area():
		draw_rect(_safe_area_rect, safe_area_color, true)
	if not _playfield_rect.has_area():
		return

	draw_rect(_playfield_rect, playfield_color, true)
	if has_raster_background():
		draw_texture_rect_region(
			background_texture,
			_playfield_rect,
			get_background_source_rect(),
			background_modulate,
			false,
			true
		)
	else:
		var random := RandomNumberGenerator.new()
		random.seed = _layout_seed()
		_draw_tonal_patches(random)
		_draw_broken_joints(random)
		_draw_stains(random)
		_draw_cracks(random)
	# Il bordo scuro chiude il pavimento senza ricreare il rettangolo ciano debug.
	draw_rect(_playfield_rect, edge_shadow_color, false, 2.0, true)


func _draw_tonal_patches(random: RandomNumberGenerator) -> void:
	for _index in range(tonal_patch_count):
		var half_size := Vector2(
			random.randf_range(34.0, 96.0),
			random.randf_range(22.0, 68.0)
		)
		var center := _random_point(random, maxf(half_size.x, half_size.y) + 3.0)
		var points := PackedVector2Array([
			_clamp_to_playfield(
				center + Vector2(-half_size.x, -half_size.y * random.randf_range(0.72, 1.0)),
				2.0
			),
			_clamp_to_playfield(
				center + Vector2(half_size.x * random.randf_range(0.72, 1.0), -half_size.y),
				2.0
			),
			_clamp_to_playfield(
				center + Vector2(half_size.x, half_size.y * random.randf_range(0.66, 1.0)),
				2.0
			),
			_clamp_to_playfield(
				center + Vector2(-half_size.x * random.randf_range(0.68, 1.0), half_size.y),
				2.0
			),
		])
		draw_colored_polygon(points, tonal_patch_color)


func _draw_broken_joints(random: RandomNumberGenerator) -> void:
	for index in range(joint_count):
		var start := _random_point(random, 28.0)
		var horizontal := index % 3 != 0
		var length := random.randf_range(70.0, 210.0)
		var angle := random.randf_range(-0.08, 0.08)
		if not horizontal:
			angle += PI * 0.5
		var finish := start + Vector2.RIGHT.rotated(angle) * length
		finish = _clamp_to_playfield(finish, 18.0)
		draw_line(start, finish, joint_color, 1.0, true)
		if index % 2 == 0:
			var notch_direction := (finish - start).normalized().orthogonal()
			var notch_center := start.lerp(finish, random.randf_range(0.3, 0.7))
			draw_line(
				notch_center,
				notch_center + notch_direction * random.randf_range(5.0, 12.0),
				joint_color,
				1.0,
				true
			)


func _draw_stains(random: RandomNumberGenerator) -> void:
	for _index in range(stain_count):
		var radius := random.randf_range(18.0, 54.0)
		var center := _random_point(random, radius * 1.55 + 3.0)
		draw_circle(center, radius, stain_color)
		var secondary_radius := radius * random.randf_range(0.2, 0.42)
		var secondary_center := _clamp_to_playfield(
			center + Vector2(radius * 0.42, -radius * 0.18),
			secondary_radius + 2.0
		)
		draw_circle(
			secondary_center,
			secondary_radius,
			stain_color
		)


func _draw_cracks(random: RandomNumberGenerator) -> void:
	for _index in range(crack_count):
		var points := PackedVector2Array()
		var cursor := _random_point(random, 34.0)
		points.append(cursor)
		var direction := Vector2.RIGHT.rotated(random.randf_range(0.0, TAU))
		for _segment in range(random.randi_range(2, 4)):
			direction = direction.rotated(random.randf_range(-0.58, 0.58))
			cursor = _clamp_to_playfield(
				cursor + direction * random.randf_range(10.0, 24.0),
				12.0
			)
			points.append(cursor)
		draw_polyline(points, crack_color, 1.15, true)


func _random_point(random: RandomNumberGenerator, margin: float) -> Vector2:
	var inset := _playfield_rect.grow(-maxf(margin, 0.0))
	if not inset.has_area():
		return _playfield_rect.get_center()
	return Vector2(
		random.randf_range(inset.position.x, inset.end.x),
		random.randf_range(inset.position.y, inset.end.y)
	)


func _clamp_to_playfield(point: Vector2, margin: float) -> Vector2:
	var inset := _playfield_rect.grow(-maxf(margin, 0.0))
	if not inset.has_area():
		return _playfield_rect.get_center()
	return Vector2(
		clampf(point.x, inset.position.x, inset.end.x),
		clampf(point.y, inset.position.y, inset.end.y)
	)


func _layout_seed() -> int:
	return (
		1818
		+ int(round(_playfield_rect.position.x * 17.0))
		+ int(round(_playfield_rect.position.y * 31.0))
		+ int(round(_playfield_rect.size.x * 43.0))
		+ int(round(_playfield_rect.size.y * 59.0))
	)
