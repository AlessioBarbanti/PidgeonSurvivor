class_name BossUI
extends Control

## Identita' individuale della Boss Intro (PS-051): ritratto, icona Signature e
## una tinta personale ripresa dall'`accent_color` della Signature. Il
## Piccione Malvagio non ha Signature e resta sul trattamento neutro.

signal intro_continue_requested()
## PS-074: bottone Continua della Boss intro.
signal ui_click_requested()

const DEFAULT_TITLE_COLOR := Color(0.92, 0.76, 1, 1)
const DEFAULT_PANEL_MODULATE := Color(1, 1, 1, 1)
const ACCENT_TITLE_MIX := 0.34
const ACCENT_FRAME_MIX := 0.62

# PS-071: separazione preferita fra i blocchi del pannello (ritratto, titolo,
# citazione, CTA). E' una preferenza morbida: quando il contenuto reale
# (titolo/citazione più lunghi del solito) non entra nella safe area con
# questo spacing, si restringe fino al minimo prima di lasciare traboccare
# il pannello, che è invece un vincolo duro (vedi _reflow_intro_panel_position).
const VBOX_SEPARATION_PREFERRED := 18
const VBOX_SEPARATION_MIN := 8
const VBOX_GAP_COUNT := 4

# PS-103: il medaglione della cornice generata da PS-102
# (`generated/boss_intro_frame.png`) è un cerchio scavato nella parte alta
# dell'immagine, fuori dal flusso della VBox. `PortraitFrame` è quindi un
# overlay disegnato prima di `%Center` nell'ordine dei figli di `IntroLayer`
# (vedi `boss_ui.tscn`): l'anello opaco della cornice, disegnato sopra, ne
# ritaglia gli angoli quadrati in un cerchio senza bisogno di uno shader.
# Dimensione e offset verticale riflettono il foro della cornice a 620px di
# larghezza pannello (`custom_minimum_size` di `IntroPanel`) e restano da
# rifinire nel controllo percettivo manuale della card.
const PORTRAIT_MEDALLION_SIZE := Vector2(128.0, 144.0)
const PORTRAIT_MEDALLION_CENTER_Y := 136.0

@onready var _intro_layer: Control = %IntroLayer
@onready var _intro_position: MarginContainer = %Center
@onready var _intro_panel: PanelContainer = %IntroPanel
@onready var _intro_vbox: VBoxContainer = %VBox
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
	# PS-071: `BossUI` è un `Control` semplice (non un `Container`), quindi la
	# sua `size` riflette sempre il rettangolo assegnato da `SafeAreaRoot`
	# (la vera safe area) e non viene mai gonfiata dal contenuto del
	# pannello, a differenza di `%Center` (un `MarginContainer`, che come
	# ogni `Container` non può riportare una size più piccola della propria
	# minima). La vecchia `CenterContainer` centrava senza mai contenere:
	# quando titolo/citazione più lunghi del solito superavano l'altezza
	# disponibile, il pannello sconfinava dalla safe area.
	resized.connect(_reflow_intro_panel_position)
	_reflow_intro_panel_position()
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
	_reflow_intro_panel_position()
	# Il testo di titolo/citazione può assestare il proprio wrapping un paio
	# di frame dopo l'assegnazione (stesso caso di PS-063 sulle carte
	# upgrade): questa chiamata ricalcola col contenuto vero, altrimenti il
	# clamp resterebbe basato sull'altezza misurata prima dell'assestamento.
	_defer_reflow_intro_panel_position()
	return true


func _defer_reflow_intro_panel_position() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if is_instance_valid(self) and is_inside_tree():
		_reflow_intro_panel_position()


## PS-071: centra il pannello nel rettangolo di `BossUI` (che coincide con la
## safe area, vedi `_ready()`), restringendo prima la spaziatura interna fino
## al minimo consentito se il contenuto reale non ci sta con lo spacing
## preferito, e azzerando infine i margini di centratura piuttosto che
## lasciar traboccare il pannello: il contenimento nella safe area è un
## vincolo duro, la spaziatura e la centratura sono preferenze morbide.
func _reflow_intro_panel_position() -> void:
	if (
		not is_instance_valid(_intro_position)
		or not is_instance_valid(_intro_panel)
		or not is_instance_valid(_intro_vbox)
		or not is_inside_tree()
	):
		return
	_intro_vbox.add_theme_constant_override("separation", VBOX_SEPARATION_PREFERRED)
	var available := size
	var content := _intro_panel.get_combined_minimum_size()
	var deficit_y := content.y - available.y
	if deficit_y > 0.0:
		var shrink_per_gap := ceili(deficit_y / VBOX_GAP_COUNT)
		var separation := maxi(VBOX_SEPARATION_PREFERRED - shrink_per_gap, VBOX_SEPARATION_MIN)
		_intro_vbox.add_theme_constant_override("separation", separation)
		content = _intro_panel.get_combined_minimum_size()
	var margin_x := maxf((available.x - content.x) / 2.0, 0.0)
	var margin_y := maxf((available.y - content.y) / 2.0, 0.0)
	_intro_position.add_theme_constant_override("margin_left", int(margin_x))
	_intro_position.add_theme_constant_override("margin_right", int(margin_x))
	_intro_position.add_theme_constant_override("margin_top", int(margin_y))
	_intro_position.add_theme_constant_override("margin_bottom", int(margin_y))
	_reflow_portrait_frame(Vector2(margin_x, margin_y), content)


## PS-103: `%Center` (un `MarginContainer`) posiziona `IntroPanel` esattamente
## a `(margin_x, margin_y)` al prossimo sort — leggere `_intro_panel.position`
## qui sarebbe ancora il valore di un frame fa. Riusare gli stessi valori già
## calcolati sopra evita quel ritardo di un frame.
func _reflow_portrait_frame(panel_position: Vector2, panel_size: Vector2) -> void:
	if not is_instance_valid(_portrait_frame):
		return
	var center := panel_position + Vector2(panel_size.x / 2.0, PORTRAIT_MEDALLION_CENTER_Y)
	_portrait_frame.position = center - PORTRAIT_MEDALLION_SIZE / 2.0
	_portrait_frame.size = PORTRAIT_MEDALLION_SIZE


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


func get_continue_button() -> Button:
	return _continue_button if is_instance_valid(_continue_button) else null


func get_continue_button_style(state_name: StringName) -> StyleBox:
	return _continue_button.get_theme_stylebox(state_name) if is_instance_valid(_continue_button) else null


func _on_continue_button_pressed() -> void:
	if not is_accepting_continue():
		return
	ui_click_requested.emit()
	_accepting_continue = false
	_continue_button.disabled = true
	intro_continue_requested.emit()
