class_name BarbRewardOverlay
extends Control

signal selection_submitted(upgrade_id: StringName)

const MAX_CARD_COUNT := 3
# Il pollice sta ancora muovendo il joystick quando le carte compaiono: questa
# finestra breve scarta il tap accidentale sopra la carta appena disegnata.
const SELECTION_LOCK_SECONDS := 0.45
# PS-046: il titolo non deve intersecare il rettangolo normalmente occupato
# dal cronometro nella fascia superiore dell'HUD (GameHud.GAMEPLAY_TOP_INSET).
const TOP_BAND_CLEARANCE := 16.0
const CONTENT_TOP_MARGIN := GameHud.GAMEPLAY_TOP_INSET + TOP_BAND_CLEARANCE

@onready var _safe_margins: MarginContainer = %SafeMargins
@onready var _layout: VBoxContainer = %Layout
@onready var _dimmer: ColorRect = $Dimmer
@onready var _title_label: Label = %TitleLabel
@onready var _mode_label: Label = %ModeLabel
@onready var _portrait: TextureRect = %BarbPortrait
@onready var _cards: Array[UpgradeCard] = [
	%BarbCard1,
	%BarbCard2,
	%BarbCard3,
]

var _upgrade_service: UpgradeService
var _touch_joystick: TouchJoystick
var _is_bonus_mode := false
var _active_card_count := 0
var _accepting_selection := false
var _joystick_was_visible := false
var _joystick_hidden_by_overlay := false
var _selection_unlock_msec := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)
	# `apply_safe_area()` normalmente arriva da `movement_slice.gd`
	# (`_apply_layout()`), che non esiste nei fixture di test che instanziano
	# questa scena da sola dentro un Control "nudo" posizionato a mano
	# (test_ps047/b11/ps036). La propria `resized` copre quel caso: essendo
	# ancorato FULL_RECT al genitore reale, il proprio rect riflette già
	# quello giusto non appena il genitore ha la size definitiva.
	resized.connect(_sync_safe_margins_to_own_rect)
	_sync_safe_margins_to_own_rect()
	for index in _cards.size():
		var card := _cards[index]
		card.upgrade_chosen.connect(_on_card_chosen)
		card.focus_neighbor_left = card.get_path_to(_cards[wrapi(index - 1, 0, _cards.size())])
		card.focus_neighbor_right = card.get_path_to(_cards[wrapi(index + 1, 0, _cards.size())])
		card.focus_neighbor_top = NodePath(".")
		card.focus_neighbor_bottom = NodePath(".")
	hide_offer()


# Il lock usa il tempo reale: le abilita' che alterano Engine.time_scale non
# devono allungare o accorciare la finestra di sicurezza.
func _process(_delta: float) -> void:
	if is_selection_locked():
		return
	set_process(false)
	_apply_selection_lock_state()


func _exit_tree() -> void:
	_disconnect_service()
	_restore_touch_joystick()


func configure(
	upgrade_service: UpgradeService,
	touch_joystick: TouchJoystick = null
) -> bool:
	if not is_node_ready() or not is_instance_valid(upgrade_service):
		return false

	_disconnect_service()
	hide_offer()
	_upgrade_service = upgrade_service
	_touch_joystick = touch_joystick
	_upgrade_service.barb_offer_generated.connect(_on_barb_offer_generated)
	_upgrade_service.barb_offer_cleared.connect(_on_barb_offer_cleared)

	var current_offer := _upgrade_service.get_current_barb_offer()
	if not current_offer.is_empty():
		_show_offer(
			current_offer,
			_upgrade_service.is_barb_bonus_mode(),
			_upgrade_service.get_barb_bonus_index(),
			_upgrade_service.get_barb_bonus_total()
		)
	else:
		hide_offer()
	return true


func hide_offer() -> void:
	_accepting_selection = false
	_active_card_count = 0
	_selection_unlock_msec = 0
	set_process(false)
	visible = false
	if is_node_ready():
		for card in _cards:
			card.set_speciality_treatment(false)
			card.clear_card()
			card.visible = true
	_restore_touch_joystick()


func is_accepting_selection() -> bool:
	return _accepting_selection and visible


func is_selection_locked() -> bool:
	return _selection_unlock_msec > Time.get_ticks_msec()


func get_selection_lock_remaining() -> float:
	if not is_selection_locked():
		return 0.0
	return float(_selection_unlock_msec - Time.get_ticks_msec()) / 1000.0


func get_upgrade_service() -> UpgradeService:
	return _upgrade_service if is_instance_valid(_upgrade_service) else null


func get_touch_joystick() -> TouchJoystick:
	return _touch_joystick if is_instance_valid(_touch_joystick) else null


func get_cards() -> Array[UpgradeCard]:
	return _cards.duplicate()


func get_active_card_count() -> int:
	return _active_card_count


func is_bonus_mode() -> bool:
	return _is_bonus_mode


func get_title_text() -> String:
	return _title_label.text if is_instance_valid(_title_label) else ""


func get_title_label_rect() -> Rect2:
	return _title_label.get_global_rect() if is_instance_valid(_title_label) else Rect2()


## `SafeMargins` è `top_level` (PS-059, necessario per disegnare sopra il
## `Dimmer`): un nodo `top_level` ancora se stesso al rettangolo del viewport,
## non a quello del suo antenato logico, perdendo l'offset e il
## ridimensionamento che `SafeAreaRoot` applicherebbe normalmente (PS-064).
## L'orchestratore (`movement_slice.gd`) chiama questo metodo ogni volta che
## ricalcola la safe area, cosi' header e carte restano dentro il rettangolo
## vero invece che nel viewport intero.
func apply_safe_area(rect: Rect2) -> void:
	if not is_node_ready() or not is_instance_valid(_safe_margins):
		return
	_safe_margins.position = rect.position
	_safe_margins.size = rect.size
	_reflow_top_margin()


func _sync_safe_margins_to_own_rect() -> void:
	apply_safe_area(get_global_rect())


## Il proprietario vuole header e carte centrati sull'altezza dell'area
## sicura (equivalente al viewport: l'inset strutturale è simmetrico) invece
## che spostati in basso da un margine superiore fisso pensato solo per non
## coprire la fascia HUD (PS-046). Un margine fisso riserverebbe sempre
## `CONTENT_TOP_MARGIN`, anche quando il contenuto è basso e ci sarebbe
## ampio spazio per centrarlo per davvero: qui si centra normalmente, e si
## passa al margine fisso (il vecchio comportamento) solo se altrimenti il
## titolo finirebbe più vicino alla fascia HUD del minimo consentito.
func _reflow_top_margin() -> void:
	if not is_instance_valid(_safe_margins) or not is_instance_valid(_layout) or not is_inside_tree():
		return
	var base_margin: float = _safe_margins.get_theme_constant(&"margin_bottom")
	var content_height := _measure_layout_min_height()
	var safe_top: float = _safe_margins.position.y
	var safe_bottom: float = safe_top + _safe_margins.size.y
	# Il proprietario vuole il container centrato sull'altezza del *viewport*,
	# non della safe area: coincidono quando l'inset e' simmetrico e la
	# finestra e' a (0,0), ma la safe area puo' risultare piu' piccola o non
	# centrata (es. un window manager di test che non piazza la finestra a
	# (0,0)). Resta comunque vincolato dentro la safe area: clearance minima
	# dalla fascia HUD in alto (PS-046), margine base in fondo.
	var viewport_center := get_viewport().get_visible_rect().size.y / 2.0
	var target_top := viewport_center - content_height / 2.0
	var min_top := safe_top + CONTENT_TOP_MARGIN
	var max_top := safe_bottom - base_margin - content_height
	var absolute_top := min_top if max_top < min_top else clampf(target_top, min_top, max_top)
	_safe_margins.add_theme_constant_override("margin_top", int(absolute_top - safe_top))


func _measure_layout_min_height() -> float:
	var separation: int = _layout.get_theme_constant(&"separation")
	var total := separation * maxi(_layout.get_child_count() - 1, 0) as float
	for child in _layout.get_children():
		if child is Control:
			total += (child as Control).get_combined_minimum_size().y
	return total


## PS-046: espone lo stato del velo per gli smoke, cosi' una regressione dello
## z-index che lo rimanda dietro l'HUD viene colta senza un confronto pixel.
func get_dimmer_z_index() -> int:
	return _dimmer.z_index if is_instance_valid(_dimmer) else -9999


func get_mode_text() -> String:
	return _mode_label.text if is_instance_valid(_mode_label) else ""


func get_portrait_texture() -> Texture2D:
	return _portrait.texture if is_instance_valid(_portrait) else null


func get_focused_card_index() -> int:
	if not is_inside_tree():
		return -1
	var focused_card := get_viewport().gui_get_focus_owner() as UpgradeCard
	if focused_card == null:
		return -1
	return _cards.find(focused_card)


func focus_card(index: int) -> bool:
	if not is_accepting_selection() or index < 0 or index >= _active_card_count:
		return false
	_cards[index].grab_focus()
	return true


func submit_card(index: int) -> bool:
	if index < 0 or index >= _active_card_count:
		return false
	return _submit_selection(_cards[index].get_upgrade_id())


func _unhandled_input(event: InputEvent) -> void:
	if not is_accepting_selection() or event.is_echo() or not event.is_pressed():
		return
	if is_selection_locked():
		return

	if event is InputEventKey:
		var key_event := event as InputEventKey
		var shortcut_index := _shortcut_index_for_key(key_event)
		if shortcut_index >= 0:
			get_viewport().set_input_as_handled()
			submit_card(shortcut_index)
			return

	var direction := 0
	if (
		event.is_action_pressed(&"ui_left")
		or event.is_action_pressed(&"ui_up")
		or event.is_action_pressed(&"move_left")
		or event.is_action_pressed(&"move_up")
	):
		direction = -1
	elif (
		event.is_action_pressed(&"ui_right")
		or event.is_action_pressed(&"ui_down")
		or event.is_action_pressed(&"move_right")
		or event.is_action_pressed(&"move_down")
	):
		direction = 1
	if direction != 0:
		get_viewport().set_input_as_handled()
		_focus_relative(direction)
		return

	# Button focus normally consumes ui_accept first. Senza preselezione il primo
	# accept sceglie soltanto la carta iniziale, non la conferma.
	if event.is_action_pressed(&"ui_accept"):
		get_viewport().set_input_as_handled()
		var focused_index := get_focused_card_index()
		if focused_index < 0:
			focus_card(0)
			return
		submit_card(focused_index)


func _show_offer(
	offers: Array[UpgradeDefinition],
	is_bonus: bool,
	_bonus_index: int,
	_bonus_total: int
) -> void:
	if offers.is_empty() or offers.size() > MAX_CARD_COUNT or not is_instance_valid(_upgrade_service):
		hide_offer()
		return

	for index in MAX_CARD_COUNT:
		_cards[index].set_speciality_treatment(not is_bonus)
		if index < offers.size():
			var definition := offers[index]
			if not _cards[index].configure(
				definition,
				_upgrade_service.get_rank(definition.id),
				index
			):
				hide_offer()
				return
			_cards[index].visible = true
		else:
			_cards[index].clear_card()
			_cards[index].visible = false

	_active_card_count = offers.size()
	_is_bonus_mode = is_bonus
	_mode_label.text = "RICOMPENSA BONUS" if is_bonus else "NUOVA SPECIALITÀ"
	_mode_label.add_theme_color_override(
		&"font_color",
		Color(0.76, 0.84, 0.92, 1.0) if is_bonus else Color(1.0, 0.72, 0.24, 1.0)
	)
	_title_label.text = "IL PREMIO DI BARB" if is_bonus else "LE SPECIALITÀ DI BARB"
	_hide_touch_joystick()
	visible = true
	_accepting_selection = true
	# Nessuna carta preselezionata: il focus compare solo se il giocatore naviga.
	_release_card_focus()
	_selection_unlock_msec = Time.get_ticks_msec() + int(SELECTION_LOCK_SECONDS * 1000.0)
	_apply_selection_lock_state()
	set_process(true)
	_reflow_top_margin()
	# Le carte possono crescere oltre la loro altezza base un paio di frame
	# dopo configure() (PS-063, testo eccezionalmente lungo): questa chiamata
	# ricalcola il margine col contenuto vero, altrimenti resterebbe basato
	# sull'altezza base già superata.
	_defer_reflow_top_margin()


func _defer_reflow_top_margin() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if is_instance_valid(self) and is_inside_tree():
		_reflow_top_margin()


func _submit_selection(upgrade_id: StringName) -> bool:
	if (
		not is_accepting_selection()
		or is_selection_locked()
		or upgrade_id.is_empty()
		or not is_instance_valid(_upgrade_service)
	):
		return false

	_accepting_selection = false
	for card in _cards:
		card.disabled = true

	var accepted := (
		_upgrade_service.select_barb_bonus_upgrade(upgrade_id)
		if _is_bonus_mode
		else _upgrade_service.select_barb_speciality(upgrade_id)
	)
	if accepted:
		selection_submitted.emit(upgrade_id)
		return true

	# Preserve interactivity only when the same authoritative offer is still
	# active. A clear/new-offer signal may already have rebuilt this overlay.
	if visible and upgrade_id in _upgrade_service.get_current_barb_offer_ids():
		for index in _active_card_count:
			_cards[index].disabled = false
		_accepting_selection = true
	return false


# Durante il lock le carte restano disabilitate: un tap iniziato in quella
# finestra non viene registrato dal Button nemmeno se il dito si stacca dopo.
func _apply_selection_lock_state() -> void:
	var locked := is_selection_locked()
	for card in _cards:
		if card.get_definition() != null:
			card.disabled = locked


func _release_card_focus() -> void:
	if not is_inside_tree():
		return
	var focused_card := get_viewport().gui_get_focus_owner() as UpgradeCard
	if focused_card != null and _cards.has(focused_card):
		focused_card.release_focus()


func _focus_relative(direction: int) -> void:
	if _active_card_count <= 0:
		return
	var focused_index := get_focused_card_index()
	if focused_index < 0:
		focused_index = 0
	else:
		focused_index = wrapi(focused_index + direction, 0, _active_card_count)
	focus_card(focused_index)


func _shortcut_index_for_key(event: InputEventKey) -> int:
	var key := event.physical_keycode
	if key == KEY_NONE:
		key = event.keycode
	match key:
		KEY_1, KEY_KP_1:
			return 0
		KEY_2, KEY_KP_2:
			return 1
		KEY_3, KEY_KP_3:
			return 2
		_:
			return -1


func _hide_touch_joystick() -> void:
	if not is_instance_valid(_touch_joystick) or _joystick_hidden_by_overlay:
		return
	_joystick_was_visible = _touch_joystick.visible
	_touch_joystick.reset_input()
	_touch_joystick.visible = false
	_joystick_hidden_by_overlay = true


func _restore_touch_joystick() -> void:
	if not _joystick_hidden_by_overlay:
		return
	if is_instance_valid(_touch_joystick):
		_touch_joystick.visible = _joystick_was_visible
	_joystick_hidden_by_overlay = false


func _on_barb_offer_generated(
	offers: Array[UpgradeDefinition],
	is_bonus: bool,
	bonus_index: int,
	bonus_total: int
) -> void:
	_show_offer(offers, is_bonus, bonus_index, bonus_total)


func _on_barb_offer_cleared() -> void:
	hide_offer()


func _on_card_chosen(upgrade_id: StringName) -> void:
	_submit_selection(upgrade_id)


func _disconnect_service() -> void:
	if is_instance_valid(_upgrade_service):
		if _upgrade_service.barb_offer_generated.is_connected(_on_barb_offer_generated):
			_upgrade_service.barb_offer_generated.disconnect(_on_barb_offer_generated)
		if _upgrade_service.barb_offer_cleared.is_connected(_on_barb_offer_cleared):
			_upgrade_service.barb_offer_cleared.disconnect(_on_barb_offer_cleared)
	_upgrade_service = null
