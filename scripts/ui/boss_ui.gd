class_name BossUI
extends Control

## Identita' individuale della Boss Intro (PS-051): ritratto, icona Signature e
## una tinta personale ripresa dall'`accent_color` della Signature. Il
## Piccione Malvagio non ha Signature e resta sul trattamento neutro.

signal intro_continue_requested()

const DEFAULT_TITLE_COLOR := Color(0.92, 0.76, 1, 1)
const DEFAULT_PANEL_MODULATE := Color(1, 1, 1, 1)
const ACCENT_TITLE_MIX := 0.34
const ACCENT_FRAME_MIX := 0.62

@onready var _intro_layer: Control = %IntroLayer
@onready var _intro_panel: PanelContainer = %IntroPanel
@onready var _portrait_frame: Control = %PortraitFrame
@onready var _portrait_texture: TextureRect = %PortraitTexture
@onready var _signature_icon: TextureRect = %SignatureIcon
@onready var _intro_title_label: Label = %IntroTitleLabel
@onready var _intro_quote_label: Label = %IntroQuoteLabel
@onready var _continue_button: Button = %ContinueButton

var _accepting_continue := false
var _base_panel_style: StyleBoxTexture


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_continue_button.pressed.connect(_on_continue_button_pressed)
	var current_style := _intro_panel.get_theme_stylebox(&"panel") as StyleBoxTexture
	if current_style != null:
		_base_panel_style = current_style.duplicate() as StyleBoxTexture
		_intro_panel.add_theme_stylebox_override(&"panel", _base_panel_style)
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
	_apply_portrait(definition.get_safe_portrait())
	_apply_signature_identity(definition.signature if definition.has_signature() else null)
	_accepting_continue = true
	_intro_layer.visible = true
	_continue_button.disabled = false
	_continue_button.call_deferred("grab_focus")
	return true


func _apply_portrait(portrait: Texture2D) -> void:
	_portrait_texture.texture = portrait
	_portrait_frame.visible = portrait != null


func _apply_signature_identity(signature: BossSignatureDefinition) -> void:
	var icon: Texture2D = signature.icon if signature != null else null
	_signature_icon.texture = icon
	_signature_icon.visible = icon != null

	var accent := DEFAULT_TITLE_COLOR
	var frame_modulate := DEFAULT_PANEL_MODULATE
	if signature != null:
		accent = DEFAULT_TITLE_COLOR.lerp(signature.accent_color, ACCENT_TITLE_MIX)
		accent.a = 1.0
		frame_modulate = DEFAULT_PANEL_MODULATE.lerp(signature.accent_color, ACCENT_FRAME_MIX)
		frame_modulate.a = 1.0
	_intro_title_label.add_theme_color_override(&"font_color", accent)
	if _base_panel_style != null:
		_base_panel_style.modulate_color = frame_modulate


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


func get_intro_portrait_texture() -> Texture2D:
	return _portrait_texture.texture if is_instance_valid(_portrait_texture) else null


func is_intro_portrait_visible() -> bool:
	return is_instance_valid(_portrait_frame) and _portrait_frame.visible


func get_intro_signature_icon_texture() -> Texture2D:
	return _signature_icon.texture if is_instance_valid(_signature_icon) else null


func is_intro_signature_icon_visible() -> bool:
	return is_instance_valid(_signature_icon) and _signature_icon.visible


func get_intro_title_color() -> Color:
	return _intro_title_label.get_theme_color(&"font_color") if is_instance_valid(_intro_title_label) else Color.WHITE


func get_intro_frame_modulate() -> Color:
	return _base_panel_style.modulate_color if _base_panel_style != null else DEFAULT_PANEL_MODULATE


func get_continue_button_style(state_name: StringName) -> StyleBox:
	return _continue_button.get_theme_stylebox(state_name) if is_instance_valid(_continue_button) else null


func _on_continue_button_pressed() -> void:
	if not is_accepting_continue():
		return
	_accepting_continue = false
	_continue_button.disabled = true
	intro_continue_requested.emit()
