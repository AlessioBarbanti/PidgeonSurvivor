class_name UpgradeOverlay
extends Control

signal selection_submitted(upgrade_id: StringName)

const CARD_COUNT := UpgradeService.DEFAULT_OFFER_SIZE
# Il pollice sta ancora muovendo il joystick quando le carte compaiono: questa
# finestra breve scarta il tap accidentale sopra la carta appena disegnata.
const SELECTION_LOCK_SECONDS := 0.45

@onready var _level_label: Label = %LevelLabel
@onready var _queue_label := get_node_or_null("SafeMargins/Layout/QueueLabel") as Label
@onready var _cards: Array[UpgradeCard] = [
	%UpgradeCard1,
	%UpgradeCard2,
	%UpgradeCard3,
]

var _upgrade_service: UpgradeService
var _touch_joystick: TouchJoystick
var _displayed_level := 0
var _accepting_selection := false
var _joystick_was_visible := false
var _joystick_hidden_by_overlay := false
var _selection_unlock_msec := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)
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
	_upgrade_service.offer_generated.connect(_on_offer_generated)
	_upgrade_service.offer_cleared.connect(_on_offer_cleared)

	var current_offer := _upgrade_service.get_current_offer()
	if current_offer.size() == CARD_COUNT:
		_show_offer(_upgrade_service.get_active_offer_level(), current_offer)
	else:
		hide_offer()
	return true


func hide_offer() -> void:
	_accepting_selection = false
	_displayed_level = 0
	_selection_unlock_msec = 0
	set_process(false)
	visible = false
	if is_node_ready():
		for card in _cards:
			card.clear_card()
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


func get_displayed_level() -> int:
	return _displayed_level


func get_level_text() -> String:
	return _level_label.text if is_instance_valid(_level_label) else ""


func get_queue_text() -> String:
	return _queue_label.text if is_instance_valid(_queue_label) else ""


func get_focused_card_index() -> int:
	if not is_inside_tree():
		return -1
	var focused_card := get_viewport().gui_get_focus_owner() as UpgradeCard
	if focused_card == null:
		return -1
	return _cards.find(focused_card)


func focus_card(index: int) -> bool:
	if not is_accepting_selection() or index < 0 or index >= _cards.size():
		return false
	_cards[index].grab_focus()
	return true


func submit_card(index: int) -> bool:
	if index < 0 or index >= _cards.size():
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


func _show_offer(level: int, offers: Array[UpgradeDefinition]) -> void:
	if (
		level <= 0
		or offers.size() != CARD_COUNT
		or not is_instance_valid(_upgrade_service)
	):
		hide_offer()
		return

	for index in CARD_COUNT:
		var definition := offers[index]
		if not _cards[index].configure(
			definition,
			_upgrade_service.get_rank(definition.id),
			index
		):
			hide_offer()
			return

	_displayed_level = level
	_level_label.text = "LIVELLO %d" % level
	var pending_choices := 1
	var experience_system := _upgrade_service.get_experience_system()
	if is_instance_valid(experience_system):
		pending_choices = maxi(experience_system.pending_level_ups, 1)
		if _queue_label != null:
			_queue_label.text = (
				"Scegli un potenziamento"
				if pending_choices == 1
				else "Scegli un potenziamento  •  %d scelte in coda" % pending_choices
			)
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

	var accepted := _upgrade_service.select_upgrade(upgrade_id)
	if accepted:
		selection_submitted.emit(upgrade_id)
		return true

	# Preserve interactivity only when the same authoritative offer is still
	# active. A clear/new-offer signal may already have rebuilt this overlay.
	if (
		visible
		and _displayed_level == _upgrade_service.get_active_offer_level()
		and upgrade_id in _upgrade_service.get_current_offer_ids()
	):
		for card in _cards:
			card.disabled = false
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
	# Alla seconda offerta il focus GUI appartiene spesso a un Control esterno
	# alle carte: cercarlo direttamente in un Array[UpgradeCard] fa fallire la
	# validazione del TypedArray, quindi si restringe prima il tipo.
	var focused_card := get_viewport().gui_get_focus_owner() as UpgradeCard
	if focused_card != null and _cards.has(focused_card):
		focused_card.release_focus()


func _focus_relative(direction: int) -> void:
	var focused_index := get_focused_card_index()
	if focused_index < 0:
		focused_index = 0
	else:
		focused_index = wrapi(focused_index + direction, 0, _cards.size())
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


func _on_offer_generated(level: int, offers: Array[UpgradeDefinition]) -> void:
	_show_offer(level, offers)


func _on_offer_cleared(level: int) -> void:
	if _displayed_level == level:
		hide_offer()


func _on_card_chosen(upgrade_id: StringName) -> void:
	_submit_selection(upgrade_id)


func _disconnect_service() -> void:
	if is_instance_valid(_upgrade_service):
		if _upgrade_service.offer_generated.is_connected(_on_offer_generated):
			_upgrade_service.offer_generated.disconnect(_on_offer_generated)
		if _upgrade_service.offer_cleared.is_connected(_on_offer_cleared):
			_upgrade_service.offer_cleared.disconnect(_on_offer_cleared)
	_upgrade_service = null
