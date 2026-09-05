class_name UpgradeCard
extends Button

signal upgrade_chosen(upgrade_id: StringName)

@onready var _icon: TextureRect = %Icon
@onready var _title_label: Label = %TitleLabel
@onready var _description_label: Label = %DescriptionLabel
@onready var _effect_summary_label: Label = %EffectSummaryLabel
@onready var _rank_label: Label = %RankLabel

var _definition: UpgradeDefinition
var _offer_index := -1
var _speciality_treatment := false
var _base_styles: Dictionary[StringName, StyleBox] = {}
var _base_minimum_size := Vector2.ZERO


func _ready() -> void:
	_cache_base_styles()
	_base_minimum_size = custom_minimum_size
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
	# Fire-and-forget: subito dopo configure() la carta non ha ancora la sua
	# larghezza reale assegnata da `Cards` (nemmeno a fine frame, un
	# `call_deferred` non basta), e un'etichetta con autowrap misurata a
	# larghezza non definitiva riporta un'altezza minima gonfiata (va a capo
	# come se fosse strettissima). Un paio di frame dopo la larghezza è
	# quella vera e il wrapping è quello che si vede a schermo.
	_grow_to_fit_content()
	return true


## `Margins` è posizionato con ancore, non gestito da un Container del
## bottone: Godot non ricalcola da solo `custom_minimum_size` in base al suo
## contenuto. Senza questo, un titolo o una descrizione più lunghi del
## previsto (testo variabile per carta) fanno traboccare il `MetaPanel` sotto
## il bordo della carta invece di allargarla. `_base_minimum_size` resta il
## pavimento dichiarato in scena; qui si cresce solo se il contenuto reale
## richiede di più, cosi' `Cards` (che stira tutte le carte alla stessa
## altezza) vede sempre il fabbisogno vero di questa carta specifica.
##
## Non usa `margins.get_combined_minimum_size()` sull'intero sottoalbero:
## interrogata prima che la riga abbia assegnato la larghezza reale, restituisce
## un'altezza gonfiata (un'etichetta con autowrap misurata a larghezza ~0 va a
## capo come se fosse strettissima). Sommare le altezze minime dei singoli figli
## — già corrette, perché ciascuna riflette la propria larghezza reale assegnata
## — evita il problema.
##
## Usa due connessioni one-shot a `process_frame` invece di
## `await get_tree().process_frame` ripetuto (PS-096): una carta liberata
## (es. `add_child_autofree` a fine test) mentre una coroutine `await` è
## sospesa su quel segnale può riprendere su un'istanza già distrutta,
## producendo l'errore motore "Resumed function ... after await, but class
## instance is gone" — l'`is_inside_tree()` di guardia non basta perché il
## crash avviene nel tentativo stesso di riprendere la funzione, prima che il
## suo corpo torni a eseguire. Una connessione a segnale, quando il bersaglio
## viene liberato, si disconnette invece da sola senza invocare nulla.
func _grow_to_fit_content() -> void:
	# La riga assegna la larghezza reale delle carte solo un paio di frame
	# dopo configure(): prima di allora ogni misura di un'etichetta con
	# autowrap è inattendibile (vedi commento sopra la chiamata).
	if not is_inside_tree():
		return
	var frame_signal := get_tree().process_frame
	if not frame_signal.is_connected(_on_first_grow_frame_elapsed):
		frame_signal.connect(_on_first_grow_frame_elapsed, CONNECT_ONE_SHOT)


func _on_first_grow_frame_elapsed() -> void:
	if not is_instance_valid(self) or not is_inside_tree():
		return
	var frame_signal := get_tree().process_frame
	if not frame_signal.is_connected(_on_second_grow_frame_elapsed):
		frame_signal.connect(_on_second_grow_frame_elapsed, CONNECT_ONE_SHOT)


func _on_second_grow_frame_elapsed() -> void:
	if not is_instance_valid(self) or not is_inside_tree():
		return

	var content := get_node_or_null("Margins/Content") as VBoxContainer
	if content == null:
		return
	var margins := get_node("Margins") as MarginContainer
	var separation: int = content.get_theme_constant(&"separation")
	var required_height: float = (
		margins.get_theme_constant(&"margin_top")
		+ margins.get_theme_constant(&"margin_bottom")
		+ separation * maxi(content.get_child_count() - 1, 0)
	)
	for child in content.get_children():
		if child is Control:
			required_height += (child as Control).get_combined_minimum_size().y

	custom_minimum_size = Vector2(
		_base_minimum_size.x, maxf(_base_minimum_size.y, required_height)
	)


func clear_card() -> void:
	_definition = null
	_offer_index = -1
	disabled = true
	tooltip_text = ""
	if not is_node_ready():
		return
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
