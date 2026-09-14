class_name BossUI
extends Control

## Boss Intro (PS-176): ritratto Boss "fluttuante" mostrato per intero in
## `contain` dentro la safe area, senza pannello/cornice esterna. La citazione
## e' sovrapposta al ritratto tramite ancore percentuali del `Control` che
## `AspectRatioContainer` ridimensiona gia' all'area effettiva dell'immagine
## (nessun calcolo di reflow manuale): la geometria del cartiglio e' quella
## misurata su `assets/Evil portrais new/REFERENCE.png`. Titolo e icona
## Signature non sono piu' mostrati (sostituiscono PS-051/PS-102/PS-103).
##
## La citazione e' un `RichTextLabel` (`fit_content = false`), non un `Label`:
## un `Label` con autowrap forza la propria size al minimo necessario per
## mostrare tutte le righe, anche oltre il rettangolo assegnato dalle ancore
## (un vincolo di Godot su qualunque `Control`, non solo nei `Container`) — con
## una citazione lunga sforerebbe il cartiglio. `RichTextLabel` con
## `fit_content = false` non contribuisce le proprie righe alla minimum size:
## il testo in eccesso resta clippato (`clip_contents`) dentro il rettangolo.

signal intro_continue_requested()
## PS-074: bottone Continua della Boss intro.
signal ui_click_requested()

## PS-176: `BossUI` e' figlio diretto di `SafeAreaRoot` come `GameHud`
## (`movement_slice.tscn`), quindi la sua origine locale coincide gia' con
## l'angolo della safe area (PS-071) — a differenza di `UpgradeOverlay`/
## `BarbRewardOverlay`, non serve un `apply_safe_area()` dall'orchestratore.
## Il ritratto pero' e' molto piu' alto del vecchio pannello e, senza questo
## margine, il suo bordo superiore invade la fascia HUD in alto (cronometro),
## esattamente il problema gia' risolto altrove da `GameHud.GAMEPLAY_TOP_INSET`
## + `UpgradeOverlay.TOP_BAND_CLEARANCE` (PS-046). L'`AspectRatioContainer` si
## limita a restringersi nello spazio residuo (mai un vincolo duro da forzare
## come in PS-067/PS-071): un margine statico basta, non serve ricalcolarlo a
## ogni resize.
const CONTENT_TOP_MARGIN := GameHud.GAMEPLAY_TOP_INSET + UpgradeOverlay.TOP_BAND_CLEARANCE

@onready var _intro_layer: Control = %IntroLayer
@onready var _content_vbox: VBoxContainer = %ContentVBox
@onready var _portrait_aspect: AspectRatioContainer = %PortraitAspect
@onready var _portrait_texture: TextureRect = %PortraitTexture
@onready var _intro_quote_label: RichTextLabel = %IntroQuoteLabel
@onready var _continue_button: Button = %ContinueButton

var _accepting_continue := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_continue_button.pressed.connect(_on_continue_button_pressed)
	_content_vbox.offset_top = CONTENT_TOP_MARGIN
	reset_presentation()


func show_intro(definition: BossDefinition) -> bool:
	if (
		not is_node_ready()
		or definition == null
		or not definition.is_valid()
	):
		return false
	_intro_quote_label.text = "“%s”" % definition.get_safe_quote()
	_apply_portrait(definition.get_safe_portrait())
	_accepting_continue = true
	_intro_layer.visible = true
	_continue_button.disabled = false
	_continue_button.call_deferred("grab_focus")
	return true


func _apply_portrait(portrait: Texture2D) -> void:
	_portrait_texture.texture = portrait
	_portrait_aspect.visible = portrait != null


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


func get_intro_quote_text() -> String:
	return _intro_quote_label.text if is_instance_valid(_intro_quote_label) else ""


func get_intro_quote_label_rect() -> Rect2:
	return _intro_quote_label.get_global_rect() if is_instance_valid(_intro_quote_label) else Rect2()


func get_intro_portrait_texture() -> Texture2D:
	return _portrait_texture.texture if is_instance_valid(_portrait_texture) else null


func get_intro_portrait_rect() -> Rect2:
	return _portrait_texture.get_global_rect() if is_instance_valid(_portrait_texture) else Rect2()


func is_intro_portrait_visible() -> bool:
	return is_instance_valid(_portrait_aspect) and _portrait_aspect.visible


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
