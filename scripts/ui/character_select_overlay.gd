class_name CharacterSelectOverlay
extends Control

signal friend_confirmed(friend_id: StringName)
signal back_requested()

const TRANSITION_DURATION := 0.14
const SWIPE_DISTANCE := 56.0
const DRAG_CANCEL_DISTANCE := 18.0
const EMULATED_MOUSE_SUPPRESSION_MSEC := 600

@onready var _selection_panel: Control = %SelectionPanel
@onready var _backdrop: NinePatchRect = $Backdrop
@onready var _carousel_viewport: Control = %CarouselViewport
@onready var _previous_button: Button = %PreviousButton
@onready var _next_button: Button = %NextButton
@onready var _name_label: Label = %NameLabel
@onready var _role_label: Label = %RoleLabel
@onready var _ability_panel: PanelContainer = %AbilityPanel
@onready var _kit_label: Label = %KitLabel
@onready var _passive_icon: TextureRect = %PassiveIcon
@onready var _passive_title_label: Label = %PassiveTitleLabel
@onready var _passive_description_label: Label = %PassiveDescriptionLabel
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
var _center_style: StyleBoxFlat
var _center_focus_style: StyleBoxFlat
var _preview_style: StyleBoxFlat
var _preview_focus_style: StyleBoxFlat


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_card_styles()
	_previous_button.pressed.connect(navigate_previous)
	_next_button.pressed.connect(navigate_next)
	_carousel_viewport.resized.connect(_on_carousel_resized)
	_confirm_button.pressed.connect(_on_confirm_pressed)
	_back_button.pressed.connect(_on_back_pressed)
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


func get_backdrop() -> NinePatchRect:
	return _backdrop if is_instance_valid(_backdrop) else null


func get_ability_panel_rect() -> Rect2:
	return _global_rect(_ability_panel)


func get_ability_icon() -> Texture2D:
	return _ability_icon.texture if is_instance_valid(_ability_icon) else null


func get_passive_icon() -> Texture2D:
	return _passive_icon.texture if is_instance_valid(_passive_icon) else null


func get_title_rect() -> Rect2:
	return _global_rect($Center/SelectionPanel/Content/Title)


func get_name_rect() -> Rect2:
	return _global_rect(_name_label)


func get_role_rect() -> Rect2:
	return _global_rect(_role_label)


func get_displayed_copy() -> Dictionary:
	return {
		"kit_title": _kit_label.text if is_instance_valid(_kit_label) else "",
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
		button.icon = definition.get_public_selection_portrait()
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.tooltip_text = "Seleziona %s" % definition.get_public_display_name()
		button.pressed.connect(_on_card_pressed.bind(definition))
		_carousel_viewport.add_child(button)
		_buttons_by_id[definition.id] = button


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
	_name_label.text = definition.get_public_display_name()
	_role_label.text = definition.get_public_role()
	_kit_label.text = "KIT DI %s" % definition.get_public_display_name().to_upper()
	_passive_icon.texture = definition.get_public_passive_icon()
	_passive_icon.visible = _passive_icon.texture != null
	_passive_title_label.text = definition.get_public_passive_title()
	_passive_description_label.text = definition.get_public_passive_description()
	_ability_title_label.text = definition.get_public_active_ability_title()
	_ability_description_label.text = definition.get_public_active_ability_description()
	var ability_definition: AbilityDefinition = null
	if is_instance_valid(_ability_registry):
		ability_definition = _ability_registry.resolve_definition(definition.active_ability_id)
	_ability_icon.texture = ability_definition.icon if ability_definition != null else null
	_ability_icon.visible = _ability_icon.texture != null
	_confirm_button.text = "Gioca con %s" % definition.get_public_display_name()
	_confirm_button.disabled = false
	_layout_cards(animate)
	call_deferred("_focus_selected_card")


func _navigate(direction: int) -> void:
	if (
		not visible
		or _definitions.is_empty()
		or direction == 0
		or Time.get_ticks_msec() < _navigation_lock_until_msec
	):
		return
	_select_index(_selected_index + signi(direction), true)


func _layout_cards(animate: bool) -> void:
	if not is_instance_valid(_carousel_viewport) or _selected_index < 0:
		return
	_kill_transition()
	var viewport_size := _carousel_viewport.size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var current_card_size := Vector2(
		clampf(viewport_size.x * 0.58, 200.0, 350.0),
		minf(viewport_size.y - 8.0, 304.0)
	)
	var preview_width := clampf(
		(viewport_size.x - current_card_size.x) * 0.5 - 10.0,
		44.0,
		154.0
	)
	var preview_card_size := Vector2(
		preview_width,
		minf(viewport_size.y - 46.0, 238.0)
	)
	var card_gap := 8.0
	var tween: Tween
	if animate:
		tween = create_tween()
		tween.set_parallel(true)
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		_transition_tween = tween
	var count := _definitions.size()
	for index in count:
		var definition := _definitions[index]
		var button := get_button(definition.id)
		var relative := index - _selected_index
		if relative > count / 2:
			relative -= count
		elif relative < -count / 2:
			relative += count
		if absi(relative) > 1:
			button.visible = false
			button.focus_mode = Control.FOCUS_NONE
			continue
		var is_current := relative == 0
		var target_size := current_card_size if is_current else preview_card_size
		var target_position := Vector2(
			(viewport_size.x - target_size.x) * 0.5,
			(viewport_size.y - target_size.y) * 0.5
		)
		if relative < 0:
			target_position.x = (viewport_size.x - current_card_size.x) * 0.5 - card_gap - target_size.x
		elif relative > 0:
			target_position.x = (viewport_size.x + current_card_size.x) * 0.5 + card_gap
		var target_modulate := Color.WHITE if is_current else Color(0.7, 0.74, 0.78, 0.72)
		var was_visible := button.visible
		button.visible = true
		button.z_index = 2 if is_current else 1
		button.focus_mode = Control.FOCUS_ALL if is_current else Control.FOCUS_NONE
		button.add_theme_constant_override(
			"icon_max_width",
			mini(int(target_size.x - 24.0), 264) if is_current else mini(int(target_size.x - 12.0), 132)
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
	_center_style = _make_card_style(Color(0.018, 0.04, 0.06, 0.9), Color(0.25, 0.66, 0.76, 0.92), 2)
	_center_focus_style = _make_card_style(Color(0.026, 0.055, 0.08, 0.94), Color(0.42, 0.9, 1.0, 1.0), 3)
	_preview_style = _make_card_style(Color(0.01, 0.022, 0.034, 0.9), Color(0.2, 0.24, 0.28, 1.0), 3)
	_preview_focus_style = _make_card_style(Color(0.035, 0.04, 0.045, 0.96), Color(0.78, 0.58, 0.27, 1.0), 3)


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
	style.content_margin_left = 8.0
	style.content_margin_top = 8.0
	style.content_margin_right = 8.0
	style.content_margin_bottom = 8.0
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
