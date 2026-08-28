class_name TutorialPreview
extends Control

const CARD_MINIMUM_SIZE := Vector2(88.0, 138.0)
const ICON_MINIMUM_SIZE := Vector2(72.0, 72.0)
const GOLD := Color(1.0, 0.72, 0.25, 1.0)
const CREAM := Color(1.0, 0.91, 0.70, 1.0)

@onready var _artwork: TextureRect = %Artwork
@onready var _gallery: HBoxContainer = %Gallery

var _animation_active := false
var _reduced_flashes := false
var _phase := 0.0
var _gallery_icons: Array[TextureRect] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)


func configure(page: TutorialPageDefinition, reduced_flashes: bool) -> void:
	_reduced_flashes = reduced_flashes
	_phase = 0.0
	_artwork.texture = page.artwork
	_artwork.visible = page.artwork != null
	_gallery.visible = page.artwork == null
	_rebuild_gallery(page)
	_reset_animation_state()


func set_animation_active(active: bool) -> void:
	_animation_active = active
	set_process(active)
	if not active:
		_phase = 0.0
		_reset_animation_state()


func set_reduced_flashes(enabled: bool) -> void:
	_reduced_flashes = enabled


func is_animation_active() -> bool:
	return _animation_active and is_processing()


func get_animation_phase() -> float:
	return _phase


func get_showcase_item_count() -> int:
	return _gallery_icons.size()


func get_showcase_textures() -> Array[Texture2D]:
	var result: Array[Texture2D] = []
	for icon in _gallery_icons:
		result.append(icon.texture)
	return result


func _process(delta: float) -> void:
	_phase = fposmod(_phase + maxf(delta, 0.0), 8.0)
	var restrained_amount := 0.004 if _reduced_flashes else 0.008
	if _artwork.visible:
		var artwork_scale := 1.0 + restrained_amount * (0.5 + 0.5 * sin(_phase * 0.85))
		_artwork.scale = Vector2.ONE * artwork_scale
	for index in _gallery_icons.size():
		var icon := _gallery_icons[index]
		var pulse := 0.5 + 0.5 * sin(_phase * 1.35 + float(index) * 0.8)
		var amount := 0.018 if _reduced_flashes else 0.045
		icon.scale = Vector2.ONE * (1.0 + pulse * amount)


func _rebuild_gallery(page: TutorialPageDefinition) -> void:
	for child in _gallery.get_children():
		_gallery.remove_child(child)
		child.queue_free()
	_gallery_icons.clear()
	for index in page.showcase_textures.size():
		_gallery.add_child(
			_build_showcase_card(page.showcase_textures[index], page.showcase_labels[index])
		)


func _build_showcase_card(texture: Texture2D, label_text: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = CARD_MINIMUM_SIZE
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_stylebox_override("panel", _make_card_style())

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 7)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 7)
	margin.add_theme_constant_override("margin_bottom", 8)
	card.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 7)
	margin.add_child(content)

	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(center)

	var icon := TextureRect.new()
	icon.custom_minimum_size = ICON_MINIMUM_SIZE
	icon.texture = texture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.pivot_offset = ICON_MINIMUM_SIZE * 0.5
	center.add_child(icon)
	_gallery_icons.append(icon)

	var label := Label.new()
	label.theme_type_variation = &"TitleXS"
	label.add_theme_color_override("font_color", CREAM)
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.y = 34.0
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(label)
	return card


func _make_card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.055, 0.085, 0.94)
	style.border_color = Color(GOLD, 0.72)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.48)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0.0, 3.0)
	return style


func _reset_animation_state() -> void:
	if is_instance_valid(_artwork):
		_artwork.scale = Vector2.ONE
	for icon in _gallery_icons:
		icon.scale = Vector2.ONE
