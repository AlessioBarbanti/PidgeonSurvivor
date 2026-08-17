class_name UpgradeCard
extends Button

signal upgrade_chosen(upgrade_id: StringName)

@onready var _shortcut_label: Label = %ShortcutLabel
@onready var _type_label: Label = %TypeLabel
@onready var _icon: TextureRect = %Icon
@onready var _title_label: Label = %TitleLabel
@onready var _description_label: Label = %DescriptionLabel
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
	_type_label.text = "BONUS CONTINUO" if definition.fallback else "POTENZIAMENTO"
	_icon.texture = definition.icon
	_title_label.text = definition.title
	_description_label.text = definition.description
	_rank_label.text = "RANGO %d  >  %d" % [
		maxi(current_rank, 0),
		maxi(current_rank, 0) + 1,
	]
	tooltip_text = "%s: %s" % [definition.title, definition.description]
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


func get_rank_text() -> String:
	return _rank_label.text if is_instance_valid(_rank_label) else ""


func _on_pressed() -> void:
	if disabled or _definition == null:
		return
	upgrade_chosen.emit(_definition.id)
