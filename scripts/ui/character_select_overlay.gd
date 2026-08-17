class_name CharacterSelectOverlay
extends Control

signal friend_confirmed(friend_id: StringName)

@onready var _roster_grid: GridContainer = %RosterGrid
@onready var _selection_panel: Control = %SelectionPanel
@onready var _portrait: TextureRect = %Portrait
@onready var _name_label: Label = %NameLabel
@onready var _role_label: Label = %RoleLabel
@onready var _passive_label: Label = %PassiveLabel
@onready var _ability_label: Label = %AbilityLabel
@onready var _confirm_button: Button = %ConfirmButton

var _registry: FriendRegistry
var _selected_definition: FriendDefinition
var _buttons_by_id: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_confirm_button.pressed.connect(_on_confirm_pressed)
	hide_selection()


func configure(registry: FriendRegistry) -> bool:
	if not is_node_ready() or not is_instance_valid(registry) or not registry.is_catalog_valid():
		return false
	_registry = registry
	_rebuild_buttons()
	return _buttons_by_id.size() == _registry.get_definitions().size()


func show_selection(default_friend_id: StringName = &"magno") -> void:
	if not is_instance_valid(_registry) or _buttons_by_id.is_empty():
		return
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	var definition := _registry.resolve_definition(default_friend_id)
	if definition == null:
		definition = _registry.get_definitions()[0]
	_select_definition(definition)
	var selected_button := get_button(definition.id)
	if selected_button != null:
		selected_button.call_deferred("grab_focus")


func hide_selection() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if is_instance_valid(_confirm_button):
		_confirm_button.disabled = true


func get_selected_definition() -> FriendDefinition:
	return _selected_definition


func get_button(friend_id: StringName) -> Button:
	return _buttons_by_id.get(friend_id) as Button


func get_roster_size() -> int:
	return _buttons_by_id.size()


func get_confirm_button() -> Button:
	return _confirm_button if is_instance_valid(_confirm_button) else null


func get_selection_panel_rect() -> Rect2:
	if not is_instance_valid(_selection_panel):
		return Rect2()
	return Rect2(_selection_panel.global_position, _selection_panel.size)


func _rebuild_buttons() -> void:
	for child in _roster_grid.get_children():
		child.queue_free()
	_buttons_by_id.clear()
	_selected_definition = null
	for definition in _registry.get_definitions():
		var button := Button.new()
		button.name = "Friend_%s" % definition.id
		button.custom_minimum_size = Vector2(184.0, 92.0)
		button.text = definition.get_public_display_name().to_upper()
		button.icon = definition.get_public_portrait()
		button.expand_icon = true
		button.toggle_mode = true
		button.tooltip_text = definition.get_public_role()
		button.pressed.connect(_select_definition.bind(definition))
		button.focus_entered.connect(_select_definition.bind(definition))
		_roster_grid.add_child(button)
		_buttons_by_id[definition.id] = button


func _select_definition(definition: FriendDefinition) -> void:
	if definition == null:
		return
	_selected_definition = definition
	_portrait.texture = definition.get_public_portrait()
	_name_label.text = definition.get_public_display_name().to_upper()
	_role_label.text = definition.get_public_role()
	_passive_label.text = "%s — %s" % [
		definition.get_public_passive_title(),
		definition.get_public_passive_description(),
	]
	_ability_label.text = "%s — %s" % [
		definition.get_public_active_ability_title(),
		definition.get_public_active_ability_description(),
	]
	_confirm_button.text = "GIOCA CON %s" % definition.get_public_display_name().to_upper()
	_confirm_button.disabled = false
	for friend_id_value: Variant in _buttons_by_id:
		var button := _buttons_by_id[friend_id_value] as Button
		button.button_pressed = StringName(friend_id_value) == definition.id


func _on_confirm_pressed() -> void:
	if not visible or _selected_definition == null or _confirm_button.disabled:
		return
	_confirm_button.disabled = true
	friend_confirmed.emit(_selected_definition.id)
