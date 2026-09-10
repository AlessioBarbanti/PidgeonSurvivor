class_name WelcomeScreen
extends Control

signal play_requested()
signal tutorial_requested()
## PS-074: solo Impostazioni — Gioca e Tutorial riusano già UI_CONFIRM
## (movement_slice.gd, `_on_welcome_play_requested`/
## `_on_welcome_tutorial_requested`), scoperto rileggendo il codice invece di
## fidarsi della ricognizione originale della card (vedi Decisioni di PS-074).
signal ui_click_requested()

@onready var _content_area: Control = %Center
@onready var _content_panel: Control = %ContentPanel
@onready var _title_plaque: Control = %TitlePlaque
@onready var _welcome_logo: TextureRect = %WelcomeLogo
@onready var _actions_frame: PanelContainer = %ActionsFrame
@onready var _background: TextureRect = %Background
@onready var _main_actions: VBoxContainer = %MainActions
@onready var _play_button: Button = %PlayButton
@onready var _tutorial_button: Button = %TutorialButton
@onready var _settings_button: Button = %SettingsButton

## PS-137: overlay impostazioni condiviso con la pausa, istanza unica
## posseduta da `movement_slice.gd` — vedi `configure_settings_overlay()`.
var _settings_overlay: SettingsOverlay


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
	_settings_button.pressed.connect(_on_settings_button_pressed)
	_update_main_action_focus()
	hide_welcome()


## PS-137: chiamata una sola volta da `movement_slice.gd` dopo aver
## istanziato l'overlay condiviso. `closed` riabilita i bottoni della
## welcome anche quando l'overlay è stato aperto dalla pausa (il segnale
## arriva comunque; `_on_settings_overlay_closed()` è un no-op se la welcome
## non è quella visibile in quel momento).
func configure_settings_overlay(overlay: SettingsOverlay) -> bool:
	if not is_instance_valid(overlay):
		return false
	_settings_overlay = overlay
	if not _settings_overlay.closed.is_connected(_on_settings_overlay_closed):
		_settings_overlay.closed.connect(_on_settings_overlay_closed)
	return true


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
	# Difesa contro un overlay rimasto aperto se la welcome si chiude per una
	# via diversa dal suo bottone Chiudi (vedi PauseOverlay.hide_pause()).
	if is_instance_valid(_settings_overlay) and _settings_overlay.is_open():
		_settings_overlay.close()
	if is_instance_valid(_play_button):
		_play_button.disabled = true
	if is_instance_valid(_tutorial_button):
		_tutorial_button.disabled = true
	if is_instance_valid(_settings_button):
		_settings_button.disabled = true


## PS-137: delega all'overlay condiviso — non c'è più nulla di locale da
## chiudere. Se l'overlay non è aperto, non c'è nulla da fare qui: Back deve
## restare inerte sulla welcome "nuda" (comportamento invariato).
func handle_back_requested() -> bool:
	if not visible or not is_instance_valid(_settings_overlay):
		return false
	return _settings_overlay.handle_back_requested()


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


## PS-074: niente `ui_click_requested` qui — `play_requested` fa gia' suonare
## `UI_CONFIRM` in `movement_slice.gd:_on_welcome_play_requested`. Un click in
## piu' raddoppierebbe il suono sulla stessa pressione.
func _on_play_pressed() -> void:
	if not visible or _play_button.disabled:
		return
	_play_button.disabled = true
	_tutorial_button.disabled = true
	_settings_button.disabled = true
	play_requested.emit()


## PS-074: come `_on_play_pressed`, `tutorial_requested` fa gia' suonare
## `UI_CONFIRM` in `movement_slice.gd:_on_welcome_tutorial_requested`.
func _on_tutorial_pressed() -> void:
	if not visible or _tutorial_button.disabled:
		return
	_play_button.disabled = true
	_tutorial_button.disabled = true
	_settings_button.disabled = true
	tutorial_requested.emit()


## PS-137: apre l'overlay condiviso invece del pannello locale ormai
## rimosso. Play/Tutorial/Impostazioni restano disabilitati finché
## l'overlay non si chiude (`_on_settings_overlay_closed`), cosi' il focus
## non può finire su un bottone coperto dal modal.
func _on_settings_button_pressed() -> void:
	if not visible or _settings_button.disabled or not is_instance_valid(_settings_overlay):
		return
	ui_click_requested.emit()
	_play_button.disabled = true
	_tutorial_button.disabled = true
	_settings_button.disabled = true
	_title_plaque.visible = false
	_settings_overlay.open()


func _on_settings_overlay_closed() -> void:
	if not visible:
		return
	_title_plaque.visible = true
	_play_button.disabled = false
	_tutorial_button.disabled = false
	_settings_button.disabled = false
	_settings_button.call_deferred("grab_focus")


func _show_main_actions() -> void:
	_title_plaque.visible = true
	_main_actions.visible = true
	_play_button.disabled = false
	_tutorial_button.disabled = false
	_settings_button.disabled = false
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


func _update_content_panel_rect() -> void:
	if not is_instance_valid(_content_area) or not is_instance_valid(_content_panel):
		return
	var available := _content_area.size
	var content_size := _content_panel.get_combined_minimum_size()
	_content_panel.size = content_size
	var centered := (available - content_size) * 0.5
	_content_panel.position = Vector2(
		maxf(centered.x, 0.0),
		maxf(centered.y, _minimum_content_panel_top())
	)


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
