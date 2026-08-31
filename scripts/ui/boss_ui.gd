class_name BossUI
extends Control

signal intro_continue_requested()

@onready var _intro_layer: Control = %IntroLayer
@onready var _intro_title_label: Label = %IntroTitleLabel
@onready var _intro_quote_label: Label = %IntroQuoteLabel
@onready var _continue_button: Button = %ContinueButton

var _accepting_continue := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_continue_button.pressed.connect(_on_continue_button_pressed)
	reset_presentation()


func show_intro(definition: BossDefinition) -> bool:
	if (
		not is_node_ready()
		or definition == null
		or not definition.is_valid()
	):
		return false
	_intro_title_label.text = definition.get_safe_title().to_upper()
	_intro_quote_label.text = "“%s”" % definition.get_safe_quote()
	_accepting_continue = true
	_intro_layer.visible = true
	_continue_button.disabled = false
	_continue_button.call_deferred("grab_focus")
	return true


func hide_intro() -> void:
	_accepting_continue = false
	_intro_layer.visible = false
	if is_instance_valid(_continue_button):
		_continue_button.disabled = true


func reset_presentation() -> void:
	hide_intro()


func is_intro_visible() -> bool:
	return is_instance_valid(_intro_layer) and _intro_layer.visible


func is_accepting_continue() -> bool:
	return _accepting_continue and is_intro_visible()


func get_intro_title_text() -> String:
	return _intro_title_label.text if is_instance_valid(_intro_title_label) else ""


func get_intro_quote_text() -> String:
	return _intro_quote_label.text if is_instance_valid(_intro_quote_label) else ""


func get_intro_panel_rect() -> Rect2:
	var intro_panel := get_node_or_null("IntroLayer/Center/IntroPanel") as Control
	return intro_panel.get_global_rect() if intro_panel != null else Rect2()


func _on_continue_button_pressed() -> void:
	if not is_accepting_continue():
		return
	_accepting_continue = false
	_continue_button.disabled = true
	intro_continue_requested.emit()
