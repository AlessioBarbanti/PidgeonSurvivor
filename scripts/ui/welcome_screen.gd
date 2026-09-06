class_name WelcomeScreen
extends Control

signal play_requested()
signal tutorial_requested()
signal audio_volume_changed(value: float)
signal audio_mute_toggled(muted: bool)
signal reduced_flashes_toggled(enabled: bool)
signal touch_control_scale_changed(control_id: StringName, value: float)
signal fire_mode_toggled(manual_enabled: bool)

@onready var _content_area: Control = %Center
@onready var _content_panel: Control = %ContentPanel
@onready var _title_plaque: Control = %TitlePlaque
@onready var _welcome_logo: TextureRect = %WelcomeLogo
@onready var _actions_frame: PanelContainer = %ActionsFrame
@onready var _background: TextureRect = %Background
@onready var _main_actions: VBoxContainer = %MainActions
@onready var _settings_panel: PanelContainer = %SettingsPanel
@onready var _settings_scroll: ScrollContainer = %SettingsScroll
@onready var _settings_content: VBoxContainer = %SettingsContent
@onready var _play_button: Button = %PlayButton
@onready var _tutorial_button: Button = %TutorialButton
@onready var _settings_button: Button = %SettingsButton
@onready var _volume_slider: HSlider = %VolumeSlider
@onready var _volume_value_label: Label = %VolumeValueLabel
@onready var _mute_check_button: CheckButton = %MuteCheckButton
@onready var _reduced_flashes_check_button: CheckButton = %ReducedFlashesCheckButton
@onready var _manual_fire_check_button: CheckButton = %ManualFireCheckButton
@onready var _ability_size_slider: HSlider = %AbilitySizeSlider
@onready var _ability_size_value_label: Label = %AbilitySizeValueLabel
@onready var _joystick_size_slider: HSlider = %JoystickSizeSlider
@onready var _joystick_size_value_label: Label = %JoystickSizeValueLabel
@onready var _close_settings_button: Button = %CloseSettingsButton

var _syncing_controls := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	## Il centraggio di ContentPanel e' calcolato qui invece che con un
	## CenterContainer: Godot non riordina i Container di un ramo nascosto
	## (welcome resta invisibile dietro il tutorial), quindi un centraggio
	## automatico resterebbe congelato alla safe area del boot.
	_content_area.resized.connect(_update_content_panel_rect)
	_update_content_panel_rect()
	_play_button.pressed.connect(_on_play_pressed)
	_tutorial_button.pressed.connect(_on_tutorial_pressed)
	_settings_button.pressed.connect(_open_settings)
	_volume_slider.value_changed.connect(_on_volume_changed)
	_mute_check_button.toggled.connect(_on_mute_toggled)
	_reduced_flashes_check_button.toggled.connect(_on_reduced_flashes_toggled)
	_manual_fire_check_button.toggled.connect(_on_manual_fire_toggled)
	_ability_size_slider.value_changed.connect(_on_ability_size_changed)
	_joystick_size_slider.value_changed.connect(_on_joystick_size_changed)
	_close_settings_button.pressed.connect(_close_settings)
	_refresh_volume_label(_volume_slider.value)
	_refresh_scale_label(_ability_size_value_label, _ability_size_slider.value)
	_refresh_scale_label(_joystick_size_value_label, _joystick_size_slider.value)
	_update_main_action_focus()
	hide_welcome()


func _unhandled_input(event: InputEvent) -> void:
	if (
		event.is_echo()
		or not visible
		or not event.is_action_pressed(&"ui_cancel")
	):
		return
	if handle_back_requested():
		get_viewport().set_input_as_handled()


func show_welcome(focus_tutorial: bool = false) -> void:
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_show_main_actions()
	if focus_tutorial:
		_tutorial_button.call_deferred("grab_focus")
	else:
		_play_button.call_deferred("grab_focus")


func hide_welcome() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if is_instance_valid(_play_button):
		_play_button.disabled = true
	if is_instance_valid(_tutorial_button):
		_tutorial_button.disabled = true
	if is_instance_valid(_settings_button):
		_settings_button.disabled = true
	if is_instance_valid(_close_settings_button):
		_close_settings_button.disabled = true


func handle_back_requested() -> bool:
	if not visible or not is_settings_visible():
		return false
	_close_settings()
	return true


func set_audio_settings(volume: float, muted: bool) -> void:
	_syncing_controls = true
	_volume_slider.value = clampf(volume, 0.0, 1.0)
	_mute_check_button.button_pressed = muted
	_syncing_controls = false
	_refresh_volume_label(_volume_slider.value)


func set_reduced_flashes(enabled: bool) -> void:
	_syncing_controls = true
	_reduced_flashes_check_button.button_pressed = enabled
	_syncing_controls = false


func set_manual_fire_mode(enabled: bool) -> void:
	_syncing_controls = true
	_manual_fire_check_button.button_pressed = enabled
	_syncing_controls = false


func set_touch_control_scales(ability_scale: float, joystick_scale: float) -> void:
	_syncing_controls = true
	_ability_size_slider.value = TouchControlSettings.sanitize_ability_scale(ability_scale)
	_joystick_size_slider.value = TouchControlSettings.sanitize_joystick_scale(joystick_scale)
	_syncing_controls = false
	_refresh_scale_label(_ability_size_value_label, _ability_size_slider.value)
	_refresh_scale_label(_joystick_size_value_label, _joystick_size_slider.value)


func is_settings_visible() -> bool:
	return visible and is_instance_valid(_settings_panel) and _settings_panel.visible


func is_title_plaque_visible() -> bool:
	return is_instance_valid(_title_plaque) and _title_plaque.visible


func get_play_button() -> Button:
	return _play_button if is_instance_valid(_play_button) else null


func get_tutorial_button() -> Button:
	return _tutorial_button if is_instance_valid(_tutorial_button) else null


func get_settings_button() -> Button:
	return _settings_button if is_instance_valid(_settings_button) else null


func get_settings_button_rect() -> Rect2:
	if not is_instance_valid(_settings_button):
		return Rect2()
	return Rect2(_settings_button.global_position, _settings_button.size)


func get_close_settings_button() -> Button:
	return _close_settings_button if is_instance_valid(_close_settings_button) else null


## PS-050: espone il pannello impostazioni per verificare che condivida la
## cornice e la grammatica visiva della pausa (vedi PauseOverlay.get_pause_panel_rect()).
func get_settings_panel() -> PanelContainer:
	return _settings_panel if is_instance_valid(_settings_panel) else null


func get_volume_slider() -> HSlider:
	return _volume_slider if is_instance_valid(_volume_slider) else null


func get_mute_check_button() -> CheckButton:
	return _mute_check_button if is_instance_valid(_mute_check_button) else null


func get_reduced_flashes_check_button() -> CheckButton:
	return (
		_reduced_flashes_check_button
		if is_instance_valid(_reduced_flashes_check_button)
		else null
	)


func get_manual_fire_check_button() -> CheckButton:
	return (
		_manual_fire_check_button
		if is_instance_valid(_manual_fire_check_button)
		else null
	)


func get_ability_size_slider() -> HSlider:
	return _ability_size_slider if is_instance_valid(_ability_size_slider) else null


func get_joystick_size_slider() -> HSlider:
	return _joystick_size_slider if is_instance_valid(_joystick_size_slider) else null


func get_content_panel_rect() -> Rect2:
	if not is_instance_valid(_content_panel):
		return Rect2()
	return Rect2(_content_panel.global_position, _content_panel.size)


func get_title_plaque_rect() -> Rect2:
	if not is_instance_valid(_title_plaque):
		return Rect2()
	return Rect2(_title_plaque.global_position, _title_plaque.size)


func get_logo_rect() -> Rect2:
	if not is_instance_valid(_welcome_logo):
		return Rect2()
	return Rect2(_welcome_logo.global_position, _welcome_logo.size)


func get_actions_frame_rect() -> Rect2:
	if not is_instance_valid(_actions_frame):
		return Rect2()
	return Rect2(_actions_frame.global_position, _actions_frame.size)


func get_actions_frame() -> PanelContainer:
	return _actions_frame if is_instance_valid(_actions_frame) else null


func get_background_texture() -> Texture2D:
	return _background.texture if is_instance_valid(_background) else null


func get_logo_texture() -> Texture2D:
	return _welcome_logo.texture if is_instance_valid(_welcome_logo) else null


func _on_play_pressed() -> void:
	if not visible or is_settings_visible() or _play_button.disabled:
		return
	_play_button.disabled = true
	_tutorial_button.disabled = true
	_settings_button.disabled = true
	play_requested.emit()


func _on_tutorial_pressed() -> void:
	if not visible or is_settings_visible() or _tutorial_button.disabled:
		return
	_play_button.disabled = true
	_tutorial_button.disabled = true
	_settings_button.disabled = true
	tutorial_requested.emit()


func _open_settings() -> void:
	if not visible or is_settings_visible():
		return
	_main_actions.visible = false
	_settings_panel.visible = true
	_title_plaque.visible = false
	_play_button.disabled = true
	_tutorial_button.disabled = true
	_settings_button.disabled = true
	_settings_button.visible = false
	_close_settings_button.disabled = false
	_update_content_panel_rect()
	_volume_slider.call_deferred("grab_focus")


func _close_settings() -> void:
	if not visible or not is_settings_visible():
		return
	_show_main_actions()
	_settings_button.call_deferred("grab_focus")


func _show_main_actions() -> void:
	_title_plaque.visible = true
	_main_actions.visible = true
	_settings_panel.visible = false
	_play_button.disabled = false
	_tutorial_button.disabled = false
	_settings_button.disabled = false
	_settings_button.visible = true
	_close_settings_button.disabled = true
	_update_content_panel_rect()
	_update_main_action_focus()


func _update_main_action_focus() -> void:
	if (
		not is_instance_valid(_play_button)
		or not is_instance_valid(_tutorial_button)
		or not is_instance_valid(_settings_button)
	):
		return
	_play_button.focus_neighbor_top = _play_button.get_path_to(_settings_button)
	_play_button.focus_neighbor_bottom = _play_button.get_path_to(_tutorial_button)
	_tutorial_button.focus_neighbor_top = _tutorial_button.get_path_to(_play_button)
	_tutorial_button.focus_neighbor_bottom = _tutorial_button.get_path_to(_settings_button)
	_settings_button.focus_neighbor_top = _settings_button.get_path_to(_tutorial_button)
	_settings_button.focus_neighbor_bottom = _settings_button.get_path_to(_play_button)


func _on_volume_changed(value: float) -> void:
	_refresh_volume_label(value)
	if not _syncing_controls:
		audio_volume_changed.emit(clampf(value, 0.0, 1.0))


func _on_mute_toggled(muted: bool) -> void:
	if not _syncing_controls:
		audio_mute_toggled.emit(muted)


func _on_reduced_flashes_toggled(enabled: bool) -> void:
	if not _syncing_controls:
		reduced_flashes_toggled.emit(enabled)


func _on_manual_fire_toggled(enabled: bool) -> void:
	if not _syncing_controls:
		fire_mode_toggled.emit(enabled)


func _on_ability_size_changed(value: float) -> void:
	_refresh_scale_label(_ability_size_value_label, value)
	if not _syncing_controls:
		touch_control_scale_changed.emit(&"ability", value)


func _on_joystick_size_changed(value: float) -> void:
	_refresh_scale_label(_joystick_size_value_label, value)
	if not _syncing_controls:
		touch_control_scale_changed.emit(&"joystick", value)


func _refresh_volume_label(value: float) -> void:
	if is_instance_valid(_volume_value_label):
		_volume_value_label.text = "%d%%" % roundi(clampf(value, 0.0, 1.0) * 100.0)


func _refresh_scale_label(label: Label, value: float) -> void:
	if is_instance_valid(label):
		label.text = "%d%%" % roundi(value * 100.0)


func _update_content_panel_rect() -> void:
	if not is_instance_valid(_content_area) or not is_instance_valid(_content_panel):
		return
	_clamp_settings_scroll_height()
	var available := _content_area.size
	var content_size := _content_panel.get_combined_minimum_size()
	_content_panel.size = content_size
	var centered := (available - content_size) * 0.5
	_content_panel.position = Vector2(
		maxf(centered.x, 0.0),
		maxf(centered.y, _minimum_content_panel_top())
	)


## PS-085: il pannello IMPOSTAZIONI non ha piu' margine libero nella safe area
## piu' compatta (960x720): un'altezza naturale del contenuto anche di poco
## superiore a quella disponibile lo farebbe uscire dal rettangolo sicuro
## (PS-050/PS-067). Invece di un'altezza fissa, la scroll area riceve il
## minimo fra l'altezza naturale del contenuto e quella davvero disponibile:
## sui profili larghi resta identica a prima (nessuno scroll), su quelli
## compatti scorre internamente invece di sforare.
func _clamp_settings_scroll_height() -> void:
	if (
		not is_instance_valid(_settings_scroll)
		or not is_instance_valid(_settings_content)
		or not is_instance_valid(_content_area)
		or not is_instance_valid(_settings_panel)
		or not is_instance_valid(_actions_frame)
	):
		return
	var natural_height := _settings_content.get_combined_minimum_size().y
	var chrome := _panel_vertical_chrome(_settings_panel) + _panel_vertical_chrome(_actions_frame)
	# Il logo puo' imporre un margine minimo sopra il pannello (vedi
	# _minimum_content_panel_top()) anche a TitlePlaque nascosta: quel margine
	# va tolto dal budget verticale reale, altrimenti il pannello continua a
	# sforare pur restando piu' piccolo del solo content_area.
	var top_floor := maxf(_minimum_content_panel_top(), 0.0)
	var available_height := maxf(_content_area.size.y - chrome - top_floor, 0.0)
	_settings_scroll.custom_minimum_size.y = minf(natural_height, available_height)


static func _panel_vertical_chrome(panel: PanelContainer) -> float:
	var style := panel.get_theme_stylebox(&"panel")
	return style.content_margin_top + style.content_margin_bottom if style != null else 0.0


## Il logo sporge sopra TitlePlaque per design (vedi PS-014): il centraggio
## verticale puro lo spinge fuori dal viewport sui profili piu' bassi.
## Calcolata dalla geometria reale invece che con una costante, cosi' resta
## corretta se il logo o l'insegna cambiano dimensione in futuro.
func _minimum_content_panel_top() -> float:
	if (
		not is_instance_valid(_content_area)
		or not is_instance_valid(_title_plaque)
		or not is_instance_valid(_welcome_logo)
	):
		return 0.0
	var logo_top_local := _title_plaque.position.y + _welcome_logo.position.y
	return -(_content_area.global_position.y + logo_top_local)
