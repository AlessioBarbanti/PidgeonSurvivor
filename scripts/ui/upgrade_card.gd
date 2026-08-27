class_name UpgradeCard
extends Button

signal upgrade_chosen(upgrade_id: StringName)

@onready var _shortcut_label: Label = %ShortcutLabel
@onready var _type_label: Label = %TypeLabel
@onready var _icon: TextureRect = %Icon
@onready var _title_label: Label = %TitleLabel
@onready var _description_label: Label = %DescriptionLabel
@onready var _effect_summary_label: Label = %EffectSummaryLabel
@onready var _rank_label: Label = %RankLabel

var _definition: UpgradeDefinition
var _offer_index := -1


func _ready() -> void:
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
	_type_label.text = "POTENZIAMENTO"
	_icon.texture = definition.icon
	_title_label.text = definition.title
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
	_type_label.text = ""
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


func _on_pressed() -> void:
	if disabled or _definition == null:
		return
	upgrade_chosen.emit(_definition.id)
