class_name CharacterSelectOverlay
extends Control

signal friend_confirmed(friend_id: StringName)
signal back_requested()

const TRANSITION_DURATION := 0.14
const SWIPE_DISTANCE := 56.0
const DRAG_CANCEL_DISTANCE := 18.0
const EMULATED_MOUSE_SUPPRESSION_MSEC := 600
const SELECTED_CARD_FRAME := preload("res://assets/art/ui/pause/pause_panel_frame.png")

## Il pannello non e' piu' una scatola fissa: cresce con la viewport fra questi
## due limiti, cosi' il 20:9 usa larghezza reale invece di restare una colonna
## centrata (PS-069 assorbe PS-054).
const PANEL_MIN_SIZE := Vector2(910.0, 490.0)
const PANEL_MAX_SIZE := Vector2(1400.0, 760.0)
## Margini asimmetrici: in landscape il ritaglio fotocamera del Pixel 9 sta a
## sinistra, quindi quel lato conserva piu' guardia degli altri anche dopo aver
## recuperato spazio verticale per il busto.
const PANEL_MARGIN_LEFT := 32.0
const PANEL_MARGIN_RIGHT := 20.0
const PANEL_MARGIN_VERTICAL := 14.0

## Le card Passiva/Abilita' occupano una quota della larghezza disponibile,
## non il busto: cosi' il personaggio resta l'elemento dominante a ogni
## risoluzione, invece di farsi restringere da testi piu' lunghi che
## allargano le card. I limiti evitano card troppo strette (testo illeggibile)
## o troppo larghe (schiacciano il busto) ai formati estremi.
const ABILITY_CARDS_WIDTH_RATIO := 0.30
## 410 e' il minimo gia' verificato non far esplodere l'altezza del testo piu'
## lungo del roster (piu' stretto, il wrap aggiunge righe, la card cresce, il
## busto la insegue in altezza e il pannello sfora la safe area).
const ABILITY_CARDS_MIN_WIDTH := 410.0
const ABILITY_CARDS_MAX_WIDTH := 440.0

const IDENTITY_MIN_HEIGHT := 96.0
## Il fondo sfumato dietro nome e ruolo copre solo una fascia centrale, non
## l'intera colonna: si legge come un alone dietro il testo, non come una
## seconda card sotto il busto.
const IDENTITY_BACKDROP_WIDTH_RATIO := 0.78
const IDENTITY_BACKDROP_MIN_WIDTH := 220.0
## Quanto l'alone sale sopra il testo, cosi' la sfumatura comincia dentro il
## busto invece che a filo del blocco identita'.
const IDENTITY_BACKDROP_BLEND_ABOVE := 36.0

## Slot mostrati contemporaneamente dalla fascia: il selezionato resta al
## centro e gli altri scorrono attorno a lui, quindi il numero e' dispari e il
## Friend diametralmente opposto resta fuori finche' non ruota dentro.
const ROSTER_VISIBLE_SLOTS := 7
const ROSTER_CARD_GAP := 6.0
const ROSTER_PREVIEW_INSET := Vector2(10.0, 14.0)
## Tinta piena, non trasparenza: il busto sconfina dietro la fascia e con un
## alpha < 1 traspariva attraverso le miniature.
const ROSTER_PREVIEW_MODULATE := Color(0.66, 0.7, 0.74, 1.0)
const ROSTER_SELECTED_ICON_PADDING := 16.0
const ROSTER_PREVIEW_ICON_PADDING := 22.0
const ROSTER_MIN_ICON_WIDTH := 24
## Ritaglio headshot della fascia roster: una sola regione per tutti e otto i
## busti, senza adattamenti per-personaggio (vincolo PS-069). A ~70px di lato
## un volto resta riconoscibile dove un busto intero non lo sarebbe.
const ROSTER_HEADSHOT_REGION := Rect2(56.0, 6.0, 144.0, 144.0)

@onready var _selection_panel: Control = %SelectionPanel
@onready var _backdrop: TextureRect = $Backdrop
@onready var _portrait_stage: Control = %PortraitStage
@onready var _bust_portrait: TextureRect = %BustPortrait
@onready var _identity_backdrop: Control = %IdentityBackdrop
@onready var _identity_block: Control = %IdentityBlock
@onready var _roster_row: Control = %RosterRow
@onready var _carousel_viewport: Control = %CarouselViewport
@onready var _previous_button: Button = %PreviousButton
@onready var _next_button: Button = %NextButton
@onready var _name_label: Label = %NameLabel
@onready var _role_label: Label = %RoleLabel
@onready var _ability_cards: Control = %AbilityCards
@onready var _passive_card: PanelContainer = %PassiveCard
@onready var _passive_icon: TextureRect = %PassiveIcon
@onready var _passive_title_label: Label = %PassiveTitleLabel
@onready var _passive_description_label: Label = %PassiveDescriptionLabel
@onready var _ability_card: PanelContainer = %AbilityCard
@onready var _ability_icon: TextureRect = %AbilityIcon
@onready var _ability_title_label: Label = %AbilityTitleLabel
@onready var _ability_description_label: Label = %AbilityDescriptionLabel
@onready var _confirm_button: Button = %ConfirmButton
@onready var _back_button: Button = %BackButton

var _registry: FriendRegistry
var _ability_registry: AbilityEffectRegistry
var _definitions: Array[FriendDefinition] = []
var _selected_definition: FriendDefinition
var _selected_index := -1
var _buttons_by_id: Dictionary = {}
var _transition_tween: Tween
var _touch_pointer_id := -1
var _touch_start := Vector2.ZERO
var _touch_started_in_carousel := false
var _touch_dragged := false
var _touch_swipe_navigated := false
var _suppress_card_press := false
var _suppress_card_press_until_msec := 0
var _navigation_lock_until_msec := 0
var _controller_axis_direction := 0
var _center_style: StyleBoxTexture
var _center_focus_style: StyleBoxTexture
var _preview_style: StyleBoxFlat
var _preview_focus_style: StyleBoxFlat


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_card_styles()
	_previous_button.pressed.connect(navigate_previous)
	_next_button.pressed.connect(navigate_next)
	_carousel_viewport.resized.connect(_on_carousel_resized)
	_portrait_stage.resized.connect(_on_portrait_stage_resized)
	resized.connect(_on_overlay_resized)
	_confirm_button.pressed.connect(_on_confirm_pressed)
	_back_button.pressed.connect(_on_back_pressed)
	_on_overlay_resized()
	hide_selection()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if (
		_process_touch_event(event)
		or _process_navigation_event(event)
	) and is_instance_valid(get_viewport()):
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo() or not visible:
		return
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_emit_back_requested()
	elif _process_navigation_event(event):
		get_viewport().set_input_as_handled()


func configure(
	registry: FriendRegistry,
	ability_registry: AbilityEffectRegistry = null
) -> bool:
	if not is_node_ready() or not is_instance_valid(registry) or not registry.is_catalog_valid():
		return false
	_registry = registry
	_ability_registry = ability_registry
	_rebuild_buttons()
	return _buttons_by_id.size() == _definitions.size()


func show_selection(default_friend_id: StringName = &"magno") -> void:
	if not is_instance_valid(_registry) or _buttons_by_id.is_empty():
		return
	_kill_transition()
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_back_button.disabled = false
	_controller_axis_direction = 0
	_suppress_card_press = false
	_suppress_card_press_until_msec = 0
	_navigation_lock_until_msec = 0
	_on_overlay_resized()
	var definition := _registry.resolve_definition(default_friend_id)
	if definition == null:
		definition = _definitions[0]
	_select_definition(definition, false)
	call_deferred("_focus_selected_card")


func hide_selection() -> void:
	_kill_transition()
	_reset_touch_state()
	_controller_axis_direction = 0
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if is_instance_valid(_confirm_button):
		_confirm_button.disabled = true
	if is_instance_valid(_back_button):
		_back_button.disabled = true


func get_selected_definition() -> FriendDefinition:
	return _selected_definition


func get_button(friend_id: StringName) -> Button:
	return _buttons_by_id.get(friend_id) as Button


func get_roster_size() -> int:
	return _buttons_by_id.size()


func get_selected_index() -> int:
	return _selected_index


func get_definition_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for definition in _definitions:
		ids.append(definition.id)
	return ids


func get_visible_card_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for definition in _definitions:
		var button := get_button(definition.id)
		if button != null and button.visible:
			ids.append(definition.id)
	return ids


func get_center_card_rect() -> Rect2:
	var button := get_button(_selected_definition.id) if _selected_definition != null else null
	return _global_rect(button)


func get_preview_card_rect(direction: int) -> Rect2:
	if _definitions.is_empty() or _selected_index < 0 or direction == 0:
		return Rect2()
	var index := posmod(_selected_index + signi(direction), _definitions.size())
	return _global_rect(get_button(_definitions[index].id))


func get_carousel_rect() -> Rect2:
	return _global_rect(_carousel_viewport)


func get_roster_rect() -> Rect2:
	return _global_rect(_roster_row)


func has_active_transition() -> bool:
	return is_instance_valid(_transition_tween) and _transition_tween.is_running()


func get_confirm_button() -> Button:
	return _confirm_button if is_instance_valid(_confirm_button) else null


func get_previous_button() -> Button:
	return _previous_button if is_instance_valid(_previous_button) else null


func get_next_button() -> Button:
	return _next_button if is_instance_valid(_next_button) else null


func get_back_button() -> Button:
	return _back_button if is_instance_valid(_back_button) else null


func get_backdrop() -> TextureRect:
	return _backdrop if is_instance_valid(_backdrop) else null


func get_ability_panel_rect() -> Rect2:
	return _global_rect(_ability_cards)


func get_passive_card_rect() -> Rect2:
	return _global_rect(_passive_card)


func get_ability_card_rect() -> Rect2:
	return _global_rect(_ability_card)


func get_ability_icon() -> Texture2D:
	return _ability_icon.texture if is_instance_valid(_ability_icon) else null


func get_ability_icon_rect() -> Rect2:
	return _global_rect(_ability_icon)


func get_passive_icon() -> Texture2D:
	return _passive_icon.texture if is_instance_valid(_passive_icon) else null


## Il busto PS-068 e' la rappresentazione primaria del Friend selezionato:
## questi accessor lo espongono ai test senza far conoscere loro l'albero.
func get_bust_portrait_texture() -> Texture2D:
	return _bust_portrait.texture if is_instance_valid(_bust_portrait) else null


func get_bust_portrait_rect() -> Rect2:
	return _global_rect(_bust_portrait)


## Sorgente della miniatura di roster: i test verificano che ogni slot ritagli
## il busto del proprio Friend, non un asset diverso.
func get_roster_icon_source(friend_id: StringName) -> Texture2D:
	var button := get_button(friend_id)
	if button == null:
		return null
	var headshot := button.icon as AtlasTexture
	return headshot.atlas if headshot != null else null


func get_portrait_stage_rect() -> Rect2:
	return _global_rect(_portrait_stage)


func get_identity_block_rect() -> Rect2:
	return _global_rect(_identity_block)


func get_title_rect() -> Rect2:
	return _global_rect($Center/SelectionPanel/Content/TitleRow/Title)


func get_name_rect() -> Rect2:
	return _global_rect(_name_label)


func get_role_rect() -> Rect2:
	return _global_rect(_role_label)


func get_displayed_copy() -> Dictionary:
	return {
		"name": _name_label.text if is_instance_valid(_name_label) else "",
		"role": _role_label.text if is_instance_valid(_role_label) else "",
		"passive_title": _passive_title_label.text if is_instance_valid(_passive_title_label) else "",
		"passive_description": _passive_description_label.text if is_instance_valid(_passive_description_label) else "",
		"ability_title": _ability_title_label.text if is_instance_valid(_ability_title_label) else "",
		"ability_description": _ability_description_label.text if is_instance_valid(_ability_description_label) else "",
		"passive": "%s: %s" % [
			_passive_title_label.text,
			_passive_description_label.text,
		] if is_instance_valid(_passive_title_label) and is_instance_valid(_passive_description_label) else "",
		"ability": "%s: %s" % [
			_ability_title_label.text,
			_ability_description_label.text,
		] if is_instance_valid(_ability_title_label) and is_instance_valid(_ability_description_label) else "",
	}


func get_selection_panel_rect() -> Rect2:
	return _global_rect(_selection_panel)


func navigate_previous() -> void:
	_navigate(-1)


func navigate_next() -> void:
	_navigate(1)


func handle_touch_event_for_test(event: InputEvent) -> bool:
	return _process_touch_event(event)


func _rebuild_buttons() -> void:
	_kill_transition()
	for child in _carousel_viewport.get_children():
		child.queue_free()
	_buttons_by_id.clear()
	_definitions = _registry.get_definitions()
	_selected_definition = null
	_selected_index = -1
	for definition in _definitions:
		var button := Button.new()
		button.name = "Friend_%s" % definition.id
		button.text = ""
		# Il roster mostra i busti PS-068 ritagliati sul volto: a questa scala una
		# figura intera non sarebbe riconoscibile.
		button.icon = _make_roster_headshot(definition.get_public_portrait())
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.tooltip_text = "Seleziona %s" % definition.get_public_display_name()
		button.pressed.connect(_on_card_pressed.bind(definition))
		_carousel_viewport.add_child(button)
		_buttons_by_id[definition.id] = button


func _make_roster_headshot(portrait: Texture2D) -> AtlasTexture:
	if portrait == null:
		return null
	var headshot := AtlasTexture.new()
	headshot.atlas = portrait
	headshot.region = ROSTER_HEADSHOT_REGION
	headshot.filter_clip = true
	return headshot


func _select_definition(definition: FriendDefinition, animate := true) -> void:
	if definition == null:
		return
	var index := _definitions.find(definition)
	if index < 0:
		return
	_select_index(index, animate)


func _select_index(index: int, animate: bool) -> void:
	if _definitions.is_empty():
		return
	_selected_index = posmod(index, _definitions.size())
	var definition := _definitions[_selected_index]
	_selected_definition = definition
	_bust_portrait.texture = definition.get_public_portrait()
	_bust_portrait.visible = _bust_portrait.texture != null
	_name_label.text = definition.get_public_display_name().to_upper()
	_role_label.text = definition.get_public_role()
	_passive_icon.texture = definition.get_public_passive_icon()
	_passive_icon.visible = _passive_icon.texture != null
	_passive_title_label.text = definition.get_public_passive_title().to_upper()
	_passive_description_label.text = definition.get_public_passive_description()
	_ability_title_label.text = definition.get_public_active_ability_title().to_upper()
	_ability_description_label.text = definition.get_public_active_ability_description()
	var ability_definition: AbilityDefinition = null
	if is_instance_valid(_ability_registry):
		ability_definition = _ability_registry.resolve_definition(definition.active_ability_id)
	_ability_icon.texture = ability_definition.icon if ability_definition != null else null
	_ability_icon.visible = _ability_icon.texture != null
	_confirm_button.text = "GIOCA CON %s" % definition.get_public_display_name().to_upper()
	_confirm_button.disabled = false
	_layout_portrait_stage()
	_layout_cards(animate)
	call_deferred("_sync_ability_card_heights")
	call_deferred("_focus_selected_card")


## Passiva e abilita' hanno testi di lunghezza diversa per Friend: senza
## questo passaggio le due card prendono ciascuna la propria altezza naturale
## e non restano affiancate alla stessa quota (fino a una riga intera di
## scarto per alcuni Friend). Rimandato di un frame perche' l'altezza minima
## di una Label con autowrap e' affidabile solo dopo che il layout ha
## assegnato la sua larghezza corrente.
##
## L'altezza condivisa e' il massimo fra i due Friend visti finora nella
## sessione (mai ridotta): resta quindi stabile invece di restringersi ogni
## volta che si torna a un Friend con testi piu' corti.
func _sync_ability_card_heights() -> void:
	if not is_instance_valid(_passive_card) or not is_instance_valid(_ability_card):
		return
	var target_height := maxf(
		_passive_card.get_combined_minimum_size().y, _ability_card.get_combined_minimum_size().y
	)
	_passive_card.custom_minimum_size.y = target_height
	_ability_card.custom_minimum_size.y = target_height


func _navigate(direction: int) -> void:
	if (
		not visible
		or _definitions.is_empty()
		or direction == 0
		or Time.get_ticks_msec() < _navigation_lock_until_msec
	):
		return
	_select_index(_selected_index + signi(direction), true)


## Il pannello segue la viewport invece di restare una scatola fissa, ma non
## supera mai lo spazio disponibile: il margine sinistro piu' generoso tiene la
## composizione fuori dal ritaglio fotocamera in landscape.
func _on_overlay_resized() -> void:
	if not is_instance_valid(_selection_panel):
		return
	var available := Vector2(
		maxf(size.x - PANEL_MARGIN_LEFT - PANEL_MARGIN_RIGHT, 0.0),
		maxf(size.y - PANEL_MARGIN_VERTICAL * 2.0, 0.0)
	)
	if available.x <= 0.0 or available.y <= 0.0:
		return
	var panel_width := minf(clampf(available.x, PANEL_MIN_SIZE.x, PANEL_MAX_SIZE.x), available.x)
	_selection_panel.custom_minimum_size = Vector2(
		panel_width,
		minf(clampf(available.y, PANEL_MIN_SIZE.y, PANEL_MAX_SIZE.y), available.y)
	)
	if is_instance_valid(_ability_cards):
		var panel_style := _selection_panel.get_theme_stylebox("panel") as StyleBoxFlat
		var horizontal_chrome := (
			panel_style.content_margin_left + panel_style.content_margin_right
			if panel_style != null
			else 0.0
		)
		var content_width := maxf(panel_width - horizontal_chrome, 0.0)
		_ability_cards.custom_minimum_size.x = clampf(
			content_width * ABILITY_CARDS_WIDTH_RATIO, ABILITY_CARDS_MIN_WIDTH, ABILITY_CARDS_MAX_WIDTH
		)


func _on_portrait_stage_resized() -> void:
	_layout_portrait_stage()


## Il busto occupa l'intera colonna Friend; nome e ruolo non hanno piu' una
## riga propria ma sono sovrapposti al bordo inferiore del busto, su un alone
## sfumato per restare leggibili. La riga cosi' liberata non serve piu' a
## contenere l'identita': la colonna Friend puo' restare stretta e cedere
## larghezza alle card Passiva/Abilita'.
func _layout_portrait_stage() -> void:
	if (
		not is_instance_valid(_portrait_stage)
		or not is_instance_valid(_bust_portrait)
		or not is_instance_valid(_identity_block)
	):
		return
	var stage := _portrait_stage.size
	if stage.x <= 0.0 or stage.y <= 0.0:
		return
	var bust_side := maxf(minf(stage.x, stage.y), 0.0)
	_bust_portrait.position = Vector2((stage.x - bust_side) * 0.5, 0.0)
	_bust_portrait.size = Vector2(bust_side, bust_side)
	var identity_height := maxf(
		_identity_block.get_combined_minimum_size().y,
		IDENTITY_MIN_HEIGHT
	)
	_identity_block.position = Vector2(0.0, bust_side - identity_height)
	_identity_block.size = Vector2(stage.x, identity_height)
	if is_instance_valid(_identity_backdrop):
		var backdrop_width := clampf(
			stage.x * IDENTITY_BACKDROP_WIDTH_RATIO, IDENTITY_BACKDROP_MIN_WIDTH, stage.x
		)
		var backdrop_height := identity_height + IDENTITY_BACKDROP_BLEND_ABOVE
		_identity_backdrop.position = Vector2(
			(stage.x - backdrop_width) * 0.5, bust_side - backdrop_height
		)
		_identity_backdrop.size = Vector2(backdrop_width, backdrop_height)


## La fascia scorre attorno al Friend selezionato, che resta sempre al centro:
## navigando, le miniature slittano di uno slot invece di limitarsi a spostare
## l'evidenza. Il Friend diametralmente opposto resta fuori dalla fascia e
## rientra ruotando. Wrap e indice restano quelli di `_navigate`.
func _layout_cards(animate: bool) -> void:
	if not is_instance_valid(_carousel_viewport) or _selected_index < 0:
		return
	_kill_transition()
	var viewport_size := _carousel_viewport.size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var count := _definitions.size()
	if count <= 0:
		return
	var slots := mini(ROSTER_VISIBLE_SLOTS, count)
	var half_span := float(slots - 1) * 0.5
	var slot_width := (
		(viewport_size.x - ROSTER_CARD_GAP * float(slots - 1)) / float(slots)
	)
	if slot_width <= 0.0:
		return
	var current_card_size := Vector2(slot_width, maxf(viewport_size.y - 4.0, 1.0))
	var preview_card_size := Vector2(
		maxf(slot_width - ROSTER_PREVIEW_INSET.x, 1.0),
		maxf(viewport_size.y - 4.0 - ROSTER_PREVIEW_INSET.y, 1.0)
	)
	var tween: Tween
	if animate:
		tween = create_tween()
		tween.set_parallel(true)
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		_transition_tween = tween
	for index in count:
		var definition := _definitions[index]
		var button := get_button(definition.id)
		if button == null:
			continue
		var relative := index - _selected_index
		if relative > count / 2:
			relative -= count
		elif relative < -count / 2:
			relative += count
		if absi(relative) > int(half_span):
			button.visible = false
			button.focus_mode = Control.FOCUS_NONE
			continue
		var is_current := relative == 0
		var target_size := current_card_size if is_current else preview_card_size
		var slot_center := (
			viewport_size.x * 0.5 + float(relative) * (slot_width + ROSTER_CARD_GAP)
		)
		var target_position := Vector2(
			slot_center - target_size.x * 0.5,
			(viewport_size.y - target_size.y) * 0.5
		)
		var target_modulate := Color.WHITE if is_current else ROSTER_PREVIEW_MODULATE
		var was_visible := button.visible
		button.visible = true
		button.z_index = 2 if is_current else 1
		button.focus_mode = Control.FOCUS_ALL if is_current else Control.FOCUS_NONE
		var icon_padding := (
			ROSTER_SELECTED_ICON_PADDING if is_current else ROSTER_PREVIEW_ICON_PADDING
		)
		button.add_theme_constant_override(
			"icon_max_width",
			maxi(int(target_size.x - icon_padding), ROSTER_MIN_ICON_WIDTH)
		)
		_apply_card_role(button, is_current)
		if animate:
			if not was_visible:
				button.position = target_position
				button.size = target_size
				button.modulate = Color(target_modulate.r, target_modulate.g, target_modulate.b, 0.0)
			tween.tween_property(button, "position", target_position, TRANSITION_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(button, "size", target_size, TRANSITION_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(button, "modulate", target_modulate, TRANSITION_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		else:
			button.position = target_position
			button.size = target_size
			button.modulate = target_modulate
	_update_focus_neighbors()


func _apply_card_role(button: Button, is_current: bool) -> void:
	button.add_theme_stylebox_override("normal", _center_style if is_current else _preview_style)
	button.add_theme_stylebox_override("hover", _center_focus_style if is_current else _preview_focus_style)
	button.add_theme_stylebox_override("pressed", _center_focus_style if is_current else _preview_focus_style)
	button.add_theme_stylebox_override("focus", _center_focus_style if is_current else _preview_focus_style)


func _build_card_styles() -> void:
	_center_style = _make_selected_card_style(Color.WHITE)
	_center_focus_style = _make_selected_card_style(Color(1.0, 0.96, 0.78, 1.0))
	_preview_style = _make_card_style(Color(0.02, 0.032, 0.046, 1.0), Color(0.2, 0.24, 0.28, 1.0), 3)
	_preview_focus_style = _make_card_style(Color(0.045, 0.05, 0.058, 1.0), Color(0.78, 0.58, 0.27, 1.0), 3)


## Stessa cornice della pausa, ma il 9-slice va ritarato: nella fascia roster la
## card selezionata e' larga ~90-130px, non ~350px come nel vecchio carosello.
func _make_selected_card_style(tint: Color) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = SELECTED_CARD_FRAME
	style.texture_margin_left = 22.0
	style.texture_margin_top = 22.0
	style.texture_margin_right = 22.0
	style.texture_margin_bottom = 22.0
	style.content_margin_left = 6.0
	style.content_margin_top = 6.0
	style.content_margin_right = 6.0
	style.content_margin_bottom = 6.0
	style.modulate_color = tint
	return style


func _make_card_style(background: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(2)
	style.anti_aliasing = false
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.78)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0.0, 3.0)
	style.content_margin_left = 6.0
	style.content_margin_top = 6.0
	style.content_margin_right = 6.0
	style.content_margin_bottom = 6.0
	return style


func _update_focus_neighbors() -> void:
	var current_button := get_button(_selected_definition.id) if _selected_definition != null else null
	if current_button == null:
		return
	current_button.focus_neighbor_top = current_button.get_path_to(_back_button)
	current_button.focus_neighbor_bottom = current_button.get_path_to(_confirm_button)
	_back_button.focus_neighbor_bottom = _back_button.get_path_to(current_button)
	_confirm_button.focus_neighbor_top = _confirm_button.get_path_to(current_button)


func _focus_selected_card() -> void:
	if not visible or _selected_definition == null:
		return
	var button := get_button(_selected_definition.id)
	if button != null and button.visible:
		button.grab_focus()


func _on_card_pressed(definition: FriendDefinition) -> void:
	if (
		_suppress_card_press
		or Time.get_ticks_msec() < _suppress_card_press_until_msec
	):
		return
	_select_definition(definition, definition != _selected_definition)


func _on_carousel_resized() -> void:
	if _selected_index >= 0:
		_layout_cards(false)


func _process_touch_event(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			if not _global_rect(self).has_point(touch.position):
				return false
			_touch_pointer_id = touch.index
			_touch_start = touch.position
			_touch_started_in_carousel = get_carousel_rect().has_point(touch.position)
			_touch_dragged = false
			_touch_swipe_navigated = false
			_suppress_card_press = false
			return false
		if touch.index != _touch_pointer_id:
			return false
		var consume_release := _touch_dragged
		_reset_touch_state(false)
		if consume_release:
			_suppress_emulated_card_press()
		return consume_release
	if event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index != _touch_pointer_id:
			return false
		var delta := drag.position - _touch_start
		if delta.length() >= DRAG_CANCEL_DISTANCE:
			_touch_dragged = true
			_suppress_card_press = true
		if (
			_touch_started_in_carousel
			and not _touch_swipe_navigated
			and absf(delta.x) >= SWIPE_DISTANCE
			and absf(delta.x) > absf(delta.y) * 1.2
		):
			_touch_swipe_navigated = true
			_navigate(1 if delta.x < 0.0 else -1)
		return _touch_dragged
	return false


func _process_navigation_event(event: InputEvent) -> bool:
	if event.is_echo():
		return false
	if event is InputEventJoypadMotion:
		var motion := event as InputEventJoypadMotion
		if motion.axis != JOY_AXIS_LEFT_X:
			return false
		var direction := signi(motion.axis_value) if absf(motion.axis_value) >= 0.65 else 0
		if direction == 0:
			_controller_axis_direction = 0
			return false
		if direction == _controller_axis_direction:
			return true
		_controller_axis_direction = direction
		_navigate(direction)
		return true
	if event is InputEventJoypadButton:
		var joy_button := event as InputEventJoypadButton
		if not joy_button.pressed:
			return false
		if joy_button.button_index == JOY_BUTTON_DPAD_LEFT:
			navigate_previous()
			return true
		if joy_button.button_index == JOY_BUTTON_DPAD_RIGHT:
			navigate_next()
			return true
	if event.is_action_pressed(&"ui_left"):
		navigate_previous()
		return true
	if event.is_action_pressed(&"ui_right"):
		navigate_next()
		return true
	return false


func _reset_touch_state(clear_suppression := true) -> void:
	_touch_pointer_id = -1
	_touch_start = Vector2.ZERO
	_touch_started_in_carousel = false
	_touch_dragged = false
	_touch_swipe_navigated = false
	if clear_suppression:
		_suppress_card_press = false
		_suppress_card_press_until_msec = 0
		_navigation_lock_until_msec = 0


func _clear_touch_suppression() -> void:
	_suppress_card_press = false


func _suppress_emulated_card_press() -> void:
	_suppress_card_press = true
	_suppress_card_press_until_msec = (
		Time.get_ticks_msec() + EMULATED_MOUSE_SUPPRESSION_MSEC
	)
	call_deferred("_clear_touch_suppression")


func _kill_transition() -> void:
	if is_instance_valid(_transition_tween):
		_transition_tween.kill()
	_transition_tween = null


func _global_rect(control: Control) -> Rect2:
	if not is_instance_valid(control):
		return Rect2()
	return Rect2(control.global_position, control.size)


func _on_confirm_pressed() -> void:
	if not visible or _selected_definition == null or _confirm_button.disabled:
		return
	_confirm_button.disabled = true
	friend_confirmed.emit(_selected_definition.id)


func _on_back_pressed() -> void:
	_emit_back_requested()


func _emit_back_requested() -> void:
	if not visible or _back_button.disabled:
		return
	_back_button.disabled = true
	_confirm_button.disabled = true
	back_requested.emit()
