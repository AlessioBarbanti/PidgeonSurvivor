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
	if is_instance_valid(_safe_margins):
		_safe_margins.add_theme_constant_override("margin_top", int(CONTENT_TOP_MARGIN))
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
