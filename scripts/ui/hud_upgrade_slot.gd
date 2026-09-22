class_name HudUpgradeSlot
extends Control

## PS-204: casella read-only della build nell'HUD. Vuota resta visibile, così
## il tetto dei posti si legge a colpo d'occhio; piena mostra icona e rango.

const FILLED_BACKGROUND := Color(0.012, 0.024, 0.043, 0.85)
const EMPTY_BACKGROUND := Color(0.012, 0.024, 0.043, 0.4)
const FILLED_BORDER := Color(0.72, 0.52, 0.24, 1)
const EMPTY_BORDER := Color(0.72, 0.52, 0.24, 0.45)
const RANK_COLOR := PauseOverlay.BUILD_SUMMARY_TITLE_COLOR
## Stesso oro delle righe read-only della pausa (PS-164): solo il testo cambia
## tinta, mai bordo o sfondo, riservati alle card cliccabili.
const SPECIALITY_RANK_COLOR := PauseOverlay.BUILD_SUMMARY_SPECIALITY_TITLE_COLOR
const RANK_OUTLINE_COLOR := Color(0, 0, 0, 1)
const BORDER_WIDTH := 2.0
const ICON_INSET := 3.0

var _upgrade_id: StringName
var _icon: Texture2D
var _rank := 0
var _is_speciality := false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func set_entry(definition: UpgradeDefinition, rank: int) -> void:
	_upgrade_id = definition.id
	_icon = definition.icon
	_rank = maxi(rank, 0)
	_is_speciality = definition.is_speciality
	queue_redraw()


func clear_entry() -> void:
	_upgrade_id = &""
	_icon = null
	_rank = 0
	_is_speciality = false
	queue_redraw()


func get_upgrade_id() -> StringName:
	return _upgrade_id


func get_rank() -> int:
	return _rank


func get_rank_text() -> String:
	return str(_rank) if is_filled() else ""


func get_rank_color() -> Color:
	return SPECIALITY_RANK_COLOR if _is_speciality else RANK_COLOR


func is_filled() -> bool:
	return not _upgrade_id.is_empty()


func _draw() -> void:
	var box := Rect2(Vector2.ZERO, size)
	draw_rect(box, FILLED_BACKGROUND if is_filled() else EMPTY_BACKGROUND)
	draw_rect(box.grow(-BORDER_WIDTH * 0.5), FILLED_BORDER if is_filled() else EMPTY_BORDER, false, BORDER_WIDTH)
	if not is_filled():
		return
	if _icon != null:
		draw_texture_rect(_icon, box.grow(-ICON_INSET), false)
	var font := get_theme_default_font()
	var font_size := maxi(int(size.y * 0.42), 10)
	var text := get_rank_text()
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var baseline := Vector2(
		size.x - text_size.x - BORDER_WIDTH - 1.0,
		size.y - BORDER_WIDTH - 1.0 - font.get_descent(font_size)
	)
	draw_string_outline(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 4, RANK_OUTLINE_COLOR)
	draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, get_rank_color())
