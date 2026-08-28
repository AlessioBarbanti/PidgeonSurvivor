class_name ArenaView
extends Node2D

@export var safe_area_color := Color(0.035, 0.047, 0.067, 1.0)
@export var playfield_color := Color(0.07, 0.09, 0.115, 1.0)
@export var background_texture: Texture2D
@export var background_modulate := Color(0.82, 0.86, 0.92, 0.92)
## Dimensione di ogni riquadro quando il pavimento raster copre un'arena
## piu' grande del viewport: la texture (seamless) si ripete invece di
## essere stirata su tutto il rettangolo, evitando la sfocatura.
@export var background_tile_size := Vector2(768.0, 768.0)
@export var tonal_patch_color := Color(0.11, 0.13, 0.15, 0.16)
@export var joint_color := Color(0.2, 0.22, 0.23, 0.16)
@export var stain_color := Color(0.025, 0.031, 0.038, 0.13)
@export var crack_color := Color(0.28, 0.29, 0.27, 0.18)
@export var edge_shadow_color := Color(0.008, 0.012, 0.018, 0.58)
@export_range(4, 32, 1) var tonal_patch_count := 18
@export_range(2, 24, 1) var joint_count := 10
@export_range(2, 24, 1) var stain_count := 9
@export_range(2, 24, 1) var crack_count := 7

## B50: delimitatore discreto del confine dell'arena, derivato da
## _playfield_rect (che ArenaWorld passa come rettangolo di mondo) invece che
## da coordinate fisse, cosi' resta corretto in 16:9, 20:9 e 4:3. Slot pronto
## per l'arte definitiva (ImageGen), sullo stesso schema di
## `StaticObstacle.texture`: finche' `boundary_texture` resta vuota disegna un
## cordolo procedurale leggibile; assegnarla piu' avanti la sostituisce senza
## toccare il calcolo delle bande.
@export var boundary_texture: Texture2D:
	set(value):
		boundary_texture = value
		queue_redraw()
@export var boundary_thickness := 28.0:
	set(value):
		boundary_thickness = maxf(value, 0.0)
		queue_redraw()
@export var boundary_tile_size := Vector2(96.0, 96.0)
@export var boundary_color := Color(0.2, 0.17, 0.14, 0.9)
@export var boundary_edge_color := Color(0.06, 0.05, 0.045, 0.95)

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


func has_boundary_texture() -> bool:
	return boundary_texture != null and boundary_texture.get_size().x > 0.0


## Pura e statica (come calculate_background_source_rect) per restare
## testabile senza rendering: quattro bande interne al bordo di `rect`,
## sempre contenute in `rect` qualunque sia l'aspect ratio dello schermo.
static func calculate_boundary_bands(rect: Rect2, thickness: float) -> Array[Rect2]:
	if not rect.has_area() or thickness <= 0.0:
		return []
	var clamped_thickness := minf(thickness, minf(rect.size.x, rect.size.y) * 0.5)
	var inner := rect.grow(-clamped_thickness)
	return [
		Rect2(rect.position, Vector2(rect.size.x, clamped_thickness)),
		Rect2(Vector2(rect.position.x, inner.end.y), Vector2(rect.size.x, clamped_thickness)),
		Rect2(rect.position, Vector2(clamped_thickness, rect.size.y)),
		Rect2(Vector2(inner.end.x, rect.position.y), Vector2(clamped_thickness, rect.size.y)),
	]


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
		_draw_tiled_texture(
			_playfield_rect, background_texture, background_tile_size, background_modulate
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
	_draw_boundary()


func _draw_boundary() -> void:
	for band in calculate_boundary_bands(_playfield_rect, boundary_thickness):
		if has_boundary_texture():
			_draw_tiled_texture(band, boundary_texture, boundary_tile_size, Color.WHITE)
		else:
			draw_rect(band, boundary_color, true)
	if boundary_thickness > 0.0 and not has_boundary_texture():
		var max_thickness := minf(_playfield_rect.size.x, _playfield_rect.size.y) * 0.5
		var inner := _playfield_rect.grow(-minf(boundary_thickness, max_thickness))
		draw_rect(inner, boundary_edge_color, false, 2.0, true)


func _draw_tiled_texture(
	area: Rect2, source_texture: Texture2D, tile_size_hint: Vector2, tint: Color
) -> void:
	# Ogni riquadro ripete l'intera texture sorgente invece di ritagliarla
	# sull'aspect ratio di `area`: un'unica immagine di copertura andrebbe
	# fuori scala se ripetuta su una banda stretta come il delimitatore.
	var source_rect := Rect2(Vector2.ZERO, source_texture.get_size())
	var tile_size := Vector2(maxf(tile_size_hint.x, 1.0), maxf(tile_size_hint.y, 1.0))
	var y := area.position.y
	while y < area.end.y:
		var x := area.position.x
		while x < area.end.x:
			draw_texture_rect_region(
				source_texture,
				Rect2(Vector2(x, y), tile_size),
				source_rect,
				tint,
				false,
				true
			)
			x += tile_size.x
		y += tile_size.y


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
