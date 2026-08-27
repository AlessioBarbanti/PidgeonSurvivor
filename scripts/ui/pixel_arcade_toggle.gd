extends CheckButton

const Palette = preload("res://scripts/ui/pixel_arcade_palette.gd")
const BOX_SIZE := 24.0
const BOX_OFFSET_X := -30.0

var _transparent_icon: ImageTexture


func _ready() -> void:
	_install_native_overrides()
	toggled.connect(_on_toggled)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	var box_rect := Rect2(
		Vector2(BOX_OFFSET_X, maxf((size.y - BOX_SIZE) * 0.5, 0.0)),
		Vector2.ONE * BOX_SIZE
	)
	var edge_color := Palette.CREAM if has_focus() else Palette.GOLD
	draw_rect(box_rect.grow(2.0), Palette.OUTLINE_DARK)
	draw_rect(box_rect, Palette.PANEL_DEEP)
	draw_rect(box_rect.grow(-2.0), Palette.CYAN if button_pressed else Palette.METAL)
	if button_pressed:
		draw_line(
			box_rect.position + Vector2(5.0, 12.0),
			box_rect.position + Vector2(10.0, 17.0),
			Palette.NIGHT,
			3.0,
			false
		)
		draw_line(
			box_rect.position + Vector2(10.0, 17.0),
			box_rect.position + Vector2(19.0, 6.0),
			Palette.NIGHT,
			3.0,
			false
		)
	else:
		draw_rect(box_rect, edge_color, false, 1.0)


func _install_native_overrides() -> void:
	_transparent_icon = _make_transparent_icon()
	for icon_name in [&"checked", &"unchecked", &"checked_disabled", &"unchecked_disabled"]:
		add_theme_icon_override(icon_name, _transparent_icon)
	add_theme_constant_override(&"h_separation", 8)


func _on_toggled(_pressed: bool) -> void:
	queue_redraw()


static func _make_transparent_icon() -> ImageTexture:
	var image := Image.create_empty(roundi(BOX_SIZE), roundi(BOX_SIZE), false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	return ImageTexture.create_from_image(image)
