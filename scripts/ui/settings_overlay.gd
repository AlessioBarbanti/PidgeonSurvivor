class_name SettingsOverlay
extends Control

## PS-137: overlay impostazioni condiviso fra welcome (BOOT) e pausa
## (MANUAL_PAUSE) — istanza unica, mai duplicata. Sostituisce i due pannelli
## paralleli introdotti da PS-050 (uno per schermata, sincronizzati a mano).
## Resta un layer puramente visivo: non introduce stati in `RunController` e
## non sa da quale schermata è stato aperto.

signal audio_volume_changed(value: float)
signal audio_mute_toggled(muted: bool)
signal reduced_flashes_toggled(enabled: bool)
signal touch_control_scale_changed(control_id: StringName, value: float)
signal fire_mode_toggled(manual_enabled: bool)
## Emesso alla chiusura, qualunque sia la causa (bottone Chiudi, Back/ui_cancel).
## Chi ha aperto l'overlay (welcome o pausa) lo usa per riabilitare i propri
## controlli e restituire il focus, senza che l'overlay sappia chi l'ha aperto.
signal closed()
## PS-074: click generico — tab e bottone Chiudi.
signal ui_click_requested()

enum Tab { AUDIO, ACCESSIBILITY, CONTROLS }

const DEFAULT_TAB := Tab.AUDIO
## Respiro minimo fra il pannello e i bordi del viewport, stesso valore di
## PauseOverlay.PAUSE_SCROLL_SAFETY_MARGIN: stessa grammatica di sicurezza.
const SAFETY_MARGIN := 24.0

@onready var _center: CenterContainer = %Center
@onready var _panel: PanelContainer = %Panel
@onready var _vbox: VBoxContainer = %VBox
@onready var _audio_tab_button: Button = %AudioTabButton
@onready var _accessibility_tab_button: Button = %AccessibilityTabButton
@onready var _controls_tab_button: Button = %ControlsTabButton
@onready var _page_scroll: ScrollContainer = %PageScroll
@onready var _page_stack: VBoxContainer = %PageStack
@onready var _audio_page: VBoxContainer = %AudioPage
@onready var _accessibility_page: VBoxContainer = %AccessibilityPage
@onready var _controls_page: VBoxContainer = %ControlsPage
@onready var _close_button: Button = %CloseButton
@onready var _volume_slider: HSlider = %VolumeSlider
@onready var _volume_value_label: Label = %VolumeValueLabel
@onready var _mute_check_button: CheckButton = %MuteCheckButton
@onready var _reduced_flashes_check_button: CheckButton = %ReducedFlashesCheckButton
@onready var _manual_fire_check_button: CheckButton = %ManualFireCheckButton
@onready var _ability_size_slider: HSlider = %AbilitySizeSlider
@onready var _ability_size_value_label: Label = %AbilitySizeValueLabel
@onready var _joystick_size_slider: HSlider = %JoystickSizeSlider
@onready var _joystick_size_value_label: Label = %JoystickSizeValueLabel

var _syncing_controls := false
var _active_tab: Tab = DEFAULT_TAB
var _chrome_height := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_audio_tab_button.pressed.connect(_on_audio_tab_pressed)
	_accessibility_tab_button.pressed.connect(_on_accessibility_tab_pressed)
	_controls_tab_button.pressed.connect(_on_controls_tab_pressed)
	_close_button.pressed.connect(_on_close_button_pressed)
	_volume_slider.value_changed.connect(_on_volume_changed)
	_mute_check_button.toggled.connect(_on_mute_toggled)
	_reduced_flashes_check_button.toggled.connect(_on_reduced_flashes_toggled)
	_manual_fire_check_button.toggled.connect(_on_manual_fire_toggled)
	_ability_size_slider.value_changed.connect(_on_ability_size_changed)
	_joystick_size_slider.value_changed.connect(_on_joystick_size_changed)
	get_viewport().size_changed.connect(_clamp_panel_height)
	_refresh_volume_label(_volume_slider.value)
	_refresh_scale_label(_ability_size_value_label, _ability_size_slider.value)
	_refresh_scale_label(_joystick_size_value_label, _joystick_size_slider.value)
	_select_tab(DEFAULT_TAB)
	# Misurato prima di applicare qualunque clamp: a questo punto
	# `_page_scroll` è ancora al proprio minimo naturale (piccolo, non quello
	# del contenuto — è la natura stessa di uno ScrollContainer), quindi
	# questo totale è "tutto il pannello tranne lo scroll" (titolo, tab,
	# separatore, bottone Chiudi, spaziature) — la parte che non varia mai
	# in altezza. Misurarlo una sola volta evita il ciclo che si creerebbe
	# rileggendolo dopo aver già impostato `custom_minimum_size` sullo scroll.
	_chrome_height = _vbox.get_combined_minimum_size().y
	_clamp_panel_height()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo() or not visible or not event.is_action_pressed(&"ui_cancel"):
		return
	get_viewport().set_input_as_handled()
	close()


## PS-137: ogni apertura riparte sempre dalla tab AUDIO (Decisioni), a
## prescindere da quale tab fosse attiva all'ultima chiusura.
func open() -> void:
	if visible:
		return
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_select_tab(DEFAULT_TAB)
	_clamp_panel_height()
	_audio_tab_button.call_deferred("grab_focus")


func close() -> void:
	if not visible:
		return
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	closed.emit()


func is_open() -> bool:
	return visible


## Stessa convenzione di ogni altro overlay del progetto
## (WelcomeScreen/TutorialScreen/PauseOverlay.handle_back_requested()):
## true se ha consumato la richiesta, false se non c'era nulla da chiudere.
func handle_back_requested() -> bool:
	if not is_open():
		return false
	close()
	return true


func get_active_tab() -> Tab:
	return _active_tab


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


func get_audio_volume() -> float:
	return float(_volume_slider.value) if is_instance_valid(_volume_slider) else 0.0


func is_audio_muted() -> bool:
	return _mute_check_button.button_pressed if is_instance_valid(_mute_check_button) else false


func is_reduced_flashes_enabled() -> bool:
	return (
		_reduced_flashes_check_button.button_pressed
		if is_instance_valid(_reduced_flashes_check_button)
		else false
	)


func is_manual_fire_mode_enabled() -> bool:
	return (
		_manual_fire_check_button.button_pressed
		if is_instance_valid(_manual_fire_check_button)
		else false
	)


func get_audio_tab_button() -> Button:
	return _audio_tab_button if is_instance_valid(_audio_tab_button) else null


func get_accessibility_tab_button() -> Button:
	return _accessibility_tab_button if is_instance_valid(_accessibility_tab_button) else null


func get_controls_tab_button() -> Button:
	return _controls_tab_button if is_instance_valid(_controls_tab_button) else null


func get_close_button() -> Button:
	return _close_button if is_instance_valid(_close_button) else null


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


func get_audio_page() -> Control:
	return _audio_page if is_instance_valid(_audio_page) else null


func get_accessibility_page() -> Control:
	return _accessibility_page if is_instance_valid(_accessibility_page) else null


func get_controls_page() -> Control:
	return _controls_page if is_instance_valid(_controls_page) else null


func get_panel_rect() -> Rect2:
	if not is_instance_valid(_panel):
		return Rect2()
	return Rect2(_panel.global_position, _panel.size)


func _on_audio_tab_pressed() -> void:
	ui_click_requested.emit()
	_select_tab(Tab.AUDIO)


func _on_accessibility_tab_pressed() -> void:
	ui_click_requested.emit()
	_select_tab(Tab.ACCESSIBILITY)


func _on_controls_tab_pressed() -> void:
	ui_click_requested.emit()
	_select_tab(Tab.CONTROLS)


func _on_close_button_pressed() -> void:
	ui_click_requested.emit()
	close()


func _select_tab(tab: Tab) -> void:
	_active_tab = tab
	_audio_tab_button.button_pressed = tab == Tab.AUDIO
	_accessibility_tab_button.button_pressed = tab == Tab.ACCESSIBILITY
	_controls_tab_button.button_pressed = tab == Tab.CONTROLS
	_audio_page.visible = tab == Tab.AUDIO
	_accessibility_page.visible = tab == Tab.ACCESSIBILITY
	_controls_page.visible = tab == Tab.CONTROLS
	_update_close_button_focus(tab)


## Il bottone Chiudi è l'unico nodo dopo le tre pagine nel VBox: il suo
## focus_neighbor_top statico (impostato in scena) punterebbe sempre
## all'ultimo controllo della tab AUDIO. Va ripuntato dinamicamente
## sull'ultimo controllo della pagina davvero visibile, altrimenti "su" da
## Chiudi non porterebbe da nessuna parte quando è attiva un'altra tab
## (stesso principio di WelcomeScreen._update_main_action_focus()).
func _update_close_button_focus(tab: Tab) -> void:
	if not is_instance_valid(_close_button):
		return
	var last_control: Control
	match tab:
		Tab.AUDIO:
			last_control = _mute_check_button
		Tab.ACCESSIBILITY:
			last_control = _reduced_flashes_check_button
		Tab.CONTROLS:
			last_control = _joystick_size_slider
	if is_instance_valid(last_control):
		_close_button.focus_neighbor_top = _close_button.get_path_to(last_control)


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


## Stesso principio di WelcomeScreen._clamp_settings_scroll_height()/
## PauseOverlay._clamp_pause_scroll_height(): una sola pagina alla volta è
## già più corta del vecchio pannello a scroll unico, ma il target resta
## comunque un tetto (`min(naturale, disponibile)`), mai un pavimento — sui
## profili larghi il risultato è identico al contenuto naturale, su quello
## compatto (960×720, PS-085) scorre internamente invece di sforare.
func _clamp_panel_height() -> void:
	if not is_instance_valid(_page_scroll) or not is_instance_valid(_page_stack) or not is_inside_tree():
		return
	var natural_content := _page_stack.get_combined_minimum_size().y
	var viewport_height := get_viewport().get_visible_rect().size.y
	var available := maxf(viewport_height - _chrome_height - SAFETY_MARGIN, 0.0)
	_page_scroll.custom_minimum_size.y = minf(natural_content, available)
