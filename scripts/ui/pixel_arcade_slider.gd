extends HSlider

const Palette = preload("res://scripts/ui/pixel_arcade_palette.gd")
const TRACK_HEIGHT := 10.0
const HANDLE_SIZE := 22.0
const HORIZONTAL_PADDING := 14.0

var _transparent_icon: ImageTexture


func _ready() -> void:
	_install_native_overrides()
	value_changed.connect(_on_value_changed)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	var track_rect := Rect2(
		Vector2(HORIZONTAL_PADDING, maxf((size.y - TRACK_HEIGHT) * 0.5, 0.0)),
		Vector2(maxf(size.x - HORIZONTAL_PADDING * 2.0, 1.0), TRACK_HEIGHT)
	)
	var normalized := _get_normalized_value()
	var fill_width := maxf(track_rect.size.x * normalized, 2.0)
	var handle_center := Vector2(
		lerpf(track_rect.position.x, track_rect.end.x, normalized),
		track_rect.get_center().y
	)
	var handle_rect := Rect2(
		handle_center - Vector2.ONE * HANDLE_SIZE * 0.5,
		Vector2.ONE * HANDLE_SIZE
	)
	var handle_border := Palette.CREAM if has_focus() else Palette.GOLD

	draw_rect(track_rect.grow(2.0), Palette.OUTLINE_DARK)
	draw_rect(track_rect, Palette.PANEL_DEEP)
	draw_rect(
		Rect2(track_rect.position, Vector2(fill_width, track_rect.size.y)),
		Palette.ORANGE
	)
	draw_rect(handle_rect.grow(2.0), Palette.OUTLINE_DARK)
	draw_rect(handle_rect, handle_border)
	draw_rect(handle_rect.grow(-4.0), Palette.ORANGE_DEEP)


func _install_native_overrides() -> void:
	_transparent_icon = _make_transparent_icon()
	add_theme_stylebox_override(&"slider", StyleBoxEmpty.new())
	add_theme_stylebox_override(&"grabber_area", StyleBoxEmpty.new())
	add_theme_stylebox_override(&"grabber_area_highlight", StyleBoxEmpty.new())
	add_theme_icon_override(&"grabber", _transparent_icon)
	add_theme_icon_override(&"grabber_highlight", _transparent_icon)
	add_theme_icon_override(&"grabber_disabled", _transparent_icon)


func _get_normalized_value() -> float:
	var span := max_value - min_value
	if is_zero_approx(span):
		return 0.0
	return clampf((value - min_value) / span, 0.0, 1.0)


func _on_value_changed(_value: float) -> void:
	queue_redraw()


static func _make_transparent_icon() -> ImageTexture:
	var image := Image.create_empty(1, 1, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	return ImageTexture.create_from_image(image)
