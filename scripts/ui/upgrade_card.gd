class_name UpgradeCard
extends Button

signal upgrade_chosen(upgrade_id: StringName)

@onready var _shortcut_label: Label = %ShortcutLabel
@onready var _icon: TextureRect = %Icon
@onready var _title_label: Label = %TitleLabel
@onready var _description_label: Label = %DescriptionLabel
@onready var _effect_summary_label: Label = %EffectSummaryLabel
@onready var _rank_label: Label = %RankLabel

var _definition: UpgradeDefinition
var _offer_index := -1
var _speciality_treatment := false
var _base_styles: Dictionary[StringName, StyleBox] = {}


func _ready() -> void:
	_cache_base_styles()
	pressed.connect(_on_pressed)
	clear_card()


func configure(
	definition: UpgradeDefinition,
	current_rank: int,
	offer_index: int
) -> bool:
	if definition == null or not definition.is_valid() or offer_index < 0:
		clear_card()
		return false

	_definition = definition
	_offer_index = offer_index
	_shortcut_label.text = "%d" % (offer_index + 1)
	_icon.texture = definition.icon
	_title_label.text = definition.title.to_upper()
	_description_label.text = definition.description
	_set_effect_summary(definition.effect_summary)
	_rank_label.text = "RANGO %d  >  %d" % [
		maxi(current_rank, 0),
		maxi(current_rank, 0) + 1,
	]
	tooltip_text = _build_tooltip(definition)
	disabled = false
	return true


func clear_card() -> void:
	_definition = null
	_offer_index = -1
	disabled = true
	tooltip_text = ""
	if not is_node_ready():
		return
	_shortcut_label.text = ""
	_icon.texture = null
	_title_label.text = ""
	_description_label.text = ""
	_set_effect_summary("")
	_rank_label.text = ""


func get_definition() -> UpgradeDefinition:
	return _definition


func get_upgrade_id() -> StringName:
	return _definition.id if _definition != null else &""


func get_offer_index() -> int:
	return _offer_index


func set_speciality_treatment(enabled: bool) -> void:
	_speciality_treatment = enabled
	if not is_node_ready():
		return
	_apply_visual_treatment()


func is_speciality_treatment_enabled() -> bool:
	return _speciality_treatment


func get_title_text() -> String:
	return _title_label.text if is_instance_valid(_title_label) else ""


func get_description_text() -> String:
	return _description_label.text if is_instance_valid(_description_label) else ""


func get_effect_summary_text() -> String:
	return _effect_summary_label.text if is_instance_valid(_effect_summary_label) else ""


func get_rank_text() -> String:
	return _rank_label.text if is_instance_valid(_rank_label) else ""


func _set_effect_summary(summary: String) -> void:
	if not is_instance_valid(_effect_summary_label):
		return
	var trimmed := summary.strip_edges()
	_effect_summary_label.text = trimmed
	_effect_summary_label.visible = not trimmed.is_empty()


func _build_tooltip(definition: UpgradeDefinition) -> String:
	var summary := definition.effect_summary.strip_edges()
	if summary.is_empty():
		return "%s: %s" % [definition.title, definition.description]
	return "%s: %s\n%s" % [definition.title, definition.description, summary]


func _cache_base_styles() -> void:
	for style_name in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
		var style := get_theme_stylebox(style_name)
		if style != null:
			_base_styles[style_name] = style


func _apply_visual_treatment() -> void:
	if not _speciality_treatment:
		for style_name in _base_styles:
			add_theme_stylebox_override(style_name, _base_styles[style_name])
		return

	add_theme_stylebox_override(
		&"normal",
		_make_speciality_style(Color(0.22, 0.1, 0.06, 0.99), Color(0.90, 0.48, 0.10, 1.0), 4)
	)
	add_theme_stylebox_override(
		&"hover",
		_make_speciality_style(Color(0.28, 0.13, 0.07, 1.0), Color(1.0, 0.68, 0.18, 1.0), 4)
	)
	add_theme_stylebox_override(
		&"pressed",
		_make_speciality_style(Color(0.34, 0.16, 0.08, 1.0), Color(1.0, 0.86, 0.42, 1.0), 5)
	)
	var focus_style := _make_speciality_style(Color.TRANSPARENT, Color(1.0, 0.86, 0.28, 1.0), 6)
	focus_style.draw_center = false
	add_theme_stylebox_override(&"focus", focus_style)
	add_theme_stylebox_override(
		&"disabled",
		_make_speciality_style(Color(0.15, 0.07, 0.045, 0.98), Color(0.63, 0.34, 0.10, 0.92), 4)
	)


func _make_speciality_style(background: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(18)
	style.border_blend = true
	style.anti_aliasing = false
	return style


func _on_pressed() -> void:
	if disabled or _definition == null:
		return
	upgrade_chosen.emit(_definition.id)
