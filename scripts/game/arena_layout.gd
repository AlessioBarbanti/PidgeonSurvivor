class_name ArenaLayout
extends Node

signal playfield_changed(playfield_rect: Rect2)

@export_range(0.1, 4.0, 0.001) var target_aspect_ratio: float = 16.0 / 9.0:
	set(value):
		target_aspect_ratio = maxf(value, 0.1)
		_queue_refresh()

@export_range(0.0, 256.0, 1.0) var edge_inset: float = 0.0:
	set(value):
		edge_inset = maxf(value, 0.0)
		_queue_refresh()

@export var respect_display_safe_area: bool = true:
	set(value):
		respect_display_safe_area = value
		_queue_refresh()

@export_range(1, 8, 1) var resume_refresh_frames: int = 2

var _safe_area_rect := Rect2()
var _playfield_rect := Rect2()
var _refresh_queued := false
var _deferred_refresh_frames := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)
	var viewport := get_viewport()
	if not viewport.size_changed.is_connected(_on_viewport_size_changed):
		viewport.size_changed.connect(_on_viewport_size_changed)
	refresh_layout()
	request_deferred_refresh(1)


func _exit_tree() -> void:
	var viewport := get_viewport()
	if viewport.size_changed.is_connected(_on_viewport_size_changed):
		viewport.size_changed.disconnect(_on_viewport_size_changed)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_SIZE_CHANGED, NOTIFICATION_WM_POSITION_CHANGED:
			_queue_refresh()
		NOTIFICATION_APPLICATION_RESUMED, \
		NOTIFICATION_APPLICATION_FOCUS_IN, \
		NOTIFICATION_WM_WINDOW_FOCUS_IN:
			request_deferred_refresh(resume_refresh_frames)


func _process(_delta: float) -> void:
	if _deferred_refresh_frames <= 0:
		set_process(false)
		return

	_deferred_refresh_frames -= 1
	if _deferred_refresh_frames == 0:
		set_process(false)
		_queue_refresh()


func refresh_layout() -> void:
	if not is_inside_tree():
		return

	var viewport := get_viewport()
	var viewport_rect := viewport.get_visible_rect()
	var next_safe_area := viewport_rect
	if respect_display_safe_area:
		var display_safe_area := DisplayServer.get_display_safe_area()
		var window_position := DisplayServer.window_get_position()
		var window_size := DisplayServer.window_get_size()
		next_safe_area = map_display_safe_area_with_screen_transform(
			viewport_rect,
			display_safe_area,
			window_position,
			window_size,
			viewport.get_screen_transform()
		)
		if not next_safe_area.has_area():
			next_safe_area = map_display_safe_area_to_viewport(
				viewport_rect,
				display_safe_area,
				window_position,
				window_size
			)
	next_safe_area = inset_rect(next_safe_area, edge_inset)
	var next_playfield := calculate_playfield_rect(
		next_safe_area,
		target_aspect_ratio
	)
	var changed := (
		next_safe_area != _safe_area_rect
		or next_playfield != _playfield_rect
	)

	_safe_area_rect = next_safe_area
	_playfield_rect = next_playfield
	if changed:
		playfield_changed.emit(_playfield_rect)


func request_deferred_refresh(after_frames: int = 1) -> void:
	if not is_inside_tree():
		return

	_queue_refresh()
	_deferred_refresh_frames = maxi(
		_deferred_refresh_frames,
		maxi(after_frames, 1)
	)
	set_process(true)


func get_safe_area_rect() -> Rect2:
	return _safe_area_rect


func get_playfield_rect() -> Rect2:
	return _playfield_rect


func get_playfield_center() -> Vector2:
	return _playfield_rect.get_center()


func get_viewport_rect() -> Rect2:
	if not is_inside_tree():
		return Rect2()
	return get_viewport().get_visible_rect()


func get_spawn_inner_rect(inner_margin: float) -> Rect2:
	var viewport_rect := get_viewport_rect()
	if not viewport_rect.has_area():
		return Rect2(viewport_rect.position, Vector2.ZERO)
	return viewport_rect.grow(maxf(inner_margin, 0.0))


func get_spawn_outer_rect(
	inner_margin: float,
	outer_margin: float
) -> Rect2:
	var viewport_rect := get_viewport_rect()
	if not viewport_rect.has_area():
		return Rect2(viewport_rect.position, Vector2.ZERO)
	var effective_margin := maxf(
		maxf(inner_margin, 0.0),
		maxf(outer_margin, 0.0)
	)
	return viewport_rect.grow(effective_margin)


func get_despawn_rect(despawn_margin: float) -> Rect2:
	var viewport_rect := get_viewport_rect()
	if not viewport_rect.has_area():
		return Rect2(viewport_rect.position, Vector2.ZERO)
	return viewport_rect.grow(maxf(despawn_margin, 0.0))


func clamp_circle_center(point: Vector2, radius: float) -> Vector2:
	if not _playfield_rect.has_area():
		return point

	var safe_radius := maxf(radius, 0.0)
	var minimum := _playfield_rect.position + Vector2.ONE * safe_radius
	var maximum := _playfield_rect.end - Vector2.ONE * safe_radius
	var center := _playfield_rect.get_center()

	if minimum.x > maximum.x:
		minimum.x = center.x
		maximum.x = center.x
	if minimum.y > maximum.y:
		minimum.y = center.y
		maximum.y = center.y

	return Vector2(
		clampf(point.x, minimum.x, maximum.x),
		clampf(point.y, minimum.y, maximum.y)
	)


static func calculate_playfield_rect(
	bounds: Rect2,
	desired_aspect_ratio: float
) -> Rect2:
	if not bounds.has_area():
		return Rect2(bounds.position, Vector2.ZERO)

	var aspect_ratio := maxf(desired_aspect_ratio, 0.1)
	var fitted_size := bounds.size
	var bounds_aspect_ratio := bounds.size.x / bounds.size.y
	if bounds_aspect_ratio > aspect_ratio:
		fitted_size.x = bounds.size.y * aspect_ratio
	else:
		fitted_size.y = bounds.size.x / aspect_ratio

	return Rect2(
		bounds.position + (bounds.size - fitted_size) * 0.5,
		fitted_size
	)


static func inset_rect(bounds: Rect2, inset: float) -> Rect2:
	if not bounds.has_area():
		return Rect2(bounds.position, Vector2.ZERO)

	var maximum_inset := minf(bounds.size.x, bounds.size.y) * 0.5
	var applied_inset := clampf(inset, 0.0, maximum_inset)
	return Rect2(
		bounds.position + Vector2.ONE * applied_inset,
		bounds.size - Vector2.ONE * applied_inset * 2.0
	)


static func map_display_safe_area_to_viewport(
	viewport_rect: Rect2,
	display_safe_area: Rect2i,
	window_position: Vector2i,
	window_size: Vector2i
) -> Rect2:
	if (
		not viewport_rect.has_area()
		or not display_safe_area.has_area()
		or window_size.x <= 0
		or window_size.y <= 0
	):
		return viewport_rect

	var window_rect := Rect2i(window_position, window_size)
	var clipped_safe_area := display_safe_area.intersection(window_rect)
	if not clipped_safe_area.has_area():
		return viewport_rect

	var local_position := clipped_safe_area.position - window_position
	var viewport_scale := Vector2(
		viewport_rect.size.x / float(window_size.x),
		viewport_rect.size.y / float(window_size.y)
	)
	return Rect2(
		viewport_rect.position + Vector2(local_position) * viewport_scale,
		Vector2(clipped_safe_area.size) * viewport_scale
	)


static func map_display_safe_area_with_screen_transform(
	viewport_rect: Rect2,
	display_safe_area: Rect2i,
	window_position: Vector2i,
	window_size: Vector2i,
	screen_transform: Transform2D
) -> Rect2:
	if (
		not viewport_rect.has_area()
		or not display_safe_area.has_area()
		or window_size.x <= 0
		or window_size.y <= 0
	):
		return Rect2()

	var window_rect := Rect2i(window_position, window_size)
	var clipped_safe_area := display_safe_area.intersection(window_rect)
	if not clipped_safe_area.has_area():
		return Rect2()

	var window_local_safe_area := Rect2(
		Vector2(clipped_safe_area.position - window_position),
		Vector2(clipped_safe_area.size)
	)
	return map_screen_rect_to_viewport(
		viewport_rect,
		window_local_safe_area,
		screen_transform
	)


static func map_screen_rect_to_viewport(
	viewport_rect: Rect2,
	screen_rect: Rect2,
	screen_transform: Transform2D
) -> Rect2:
	var determinant := screen_transform.determinant()
	if (
		not viewport_rect.has_area()
		or not screen_rect.has_area()
		or not is_finite(determinant)
		or is_zero_approx(determinant)
	):
		return Rect2()

	var inverse_transform := screen_transform.affine_inverse()
	var mapped_corners := PackedVector2Array([
		inverse_transform * screen_rect.position,
		inverse_transform * Vector2(screen_rect.end.x, screen_rect.position.y),
		inverse_transform * screen_rect.end,
		inverse_transform * Vector2(screen_rect.position.x, screen_rect.end.y),
	])
	var mapped_rect := Rect2(mapped_corners[0], Vector2.ZERO)
	for corner_index in range(1, mapped_corners.size()):
		mapped_rect = mapped_rect.expand(mapped_corners[corner_index])

	return mapped_rect.intersection(viewport_rect)


func _on_viewport_size_changed() -> void:
	_queue_refresh()


func _queue_refresh() -> void:
	if not is_inside_tree() or _refresh_queued:
		return
	_refresh_queued = true
	call_deferred("_apply_queued_refresh")


func _apply_queued_refresh() -> void:
	_refresh_queued = false
	refresh_layout()
