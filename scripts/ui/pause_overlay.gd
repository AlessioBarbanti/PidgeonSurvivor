class_name PauseOverlay
extends Control

signal resume_requested()
signal change_character_requested()
## PS-074: bottoni senza un cue dedicato (il resume esistente segue lo stato
## RunController, non questo segnale).
signal ui_click_requested()

@onready var _resume_button: Button = %ResumeButton
@onready var _change_character_button: Button = %ChangeCharacterButton
@onready var _settings_button: Button = %SettingsButton
@onready var _pause_center: CenterContainer = %PauseCenter
@onready var _confirmation_center: CenterContainer = %ConfirmationCenter
@onready var _cancel_change_button: Button = %CancelChangeButton
@onready var _confirm_change_button: Button = %ConfirmChangeButton
@onready var _pause_scroll: ScrollContainer = %PauseScroll
@onready var _pause_vbox: VBoxContainer = %VBox

## PS-085: margine di respiro fra lo scroll del pannello e i bordi del
## viewport, cosi' il contenuto non tocca mai esattamente il limite anche
## quando e' clampato al massimo consentito.
const PAUSE_SCROLL_SAFETY_MARGIN := 24.0

var _accepting_resume := false

## PS-137: overlay impostazioni condiviso con la welcome, istanza unica
## posseduta da `movement_slice.gd` — vedi `configure_settings_overlay()`.
var _settings_overlay: SettingsOverlay


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_resume_button.pressed.connect(_on_resume_button_pressed)
	_change_character_button.pressed.connect(_on_change_character_button_pressed)
	_settings_button.pressed.connect(_on_settings_button_pressed)
	_cancel_change_button.pressed.connect(_on_cancel_change_button_pressed)
	_confirm_change_button.pressed.connect(_on_confirm_change_button_pressed)
	get_viewport().size_changed.connect(_clamp_pause_scroll_height)
	hide_pause()
	_request_pause_scroll_height_refresh()


## PS-137: chiamata una sola volta da `movement_slice.gd` dopo aver
## istanziato l'overlay condiviso.
func configure_settings_overlay(overlay: SettingsOverlay) -> bool:
	if not is_instance_valid(overlay):
		return false
	_settings_overlay = overlay
	if not _settings_overlay.closed.is_connected(_on_settings_overlay_closed):
		_settings_overlay.closed.connect(_on_settings_overlay_closed)
	return true


## PS-137: l'overlay impostazioni ha sempre precedenza — se è aperto, `ui_cancel`
## deve chiuderlo, non la conferma di cambio personaggio sottostante.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo() or not event.is_action_pressed(&"ui_cancel"):
		return
	if not (is_instance_valid(_settings_overlay) and _settings_overlay.is_open()) and not is_change_confirmation_visible():
		return
	get_viewport().set_input_as_handled()
	handle_back_requested()


func show_pause() -> void:
	_accepting_resume = true
	visible = true
	_request_pause_scroll_height_refresh()
	_show_pause_controls()
	_resume_button.call_deferred("grab_focus")


func hide_pause() -> void:
	_accepting_resume = false
	visible = false
	# Difesa contro un overlay rimasto aperto se la pausa si chiude per una via
	# diversa dal bottone Riprendi (es. la run finisce mentre l'overlay è
	# aperto): evita un modal orfano sopra il nulla.
	if is_instance_valid(_settings_overlay) and _settings_overlay.is_open():
		_settings_overlay.close()
	if is_instance_valid(_resume_button):
		_resume_button.disabled = true
	if is_instance_valid(_change_character_button):
		_change_character_button.disabled = true
	if is_instance_valid(_settings_button):
		_settings_button.disabled = true
	if is_instance_valid(_pause_center):
		_pause_center.visible = true
	if is_instance_valid(_confirmation_center):
		_confirmation_center.visible = false
	_set_confirmation_buttons_disabled(true)


func is_accepting_resume() -> bool:
	return _accepting_resume and visible


func get_resume_button() -> Button:
	return _resume_button if is_instance_valid(_resume_button) else null


func get_change_character_button() -> Button:
	return _change_character_button if is_instance_valid(_change_character_button) else null


func get_settings_button() -> Button:
	return _settings_button if is_instance_valid(_settings_button) else null


func get_cancel_change_button() -> Button:
	return _cancel_change_button if is_instance_valid(_cancel_change_button) else null


func get_confirm_change_button() -> Button:
	return _confirm_change_button if is_instance_valid(_confirm_change_button) else null


func is_change_confirmation_visible() -> bool:
	return (
		is_accepting_resume()
		and is_instance_valid(_confirmation_center)
		and _confirmation_center.visible
	)


## PS-137: l'overlay impostazioni ha sempre priorità su Back — se è aperto,
## Back lo chiude e basta, senza toccare la conferma di cambio personaggio
## sottostante (mai entrambe visibili insieme, ma l'ordine resta esplicito).
func handle_back_requested() -> bool:
	if is_instance_valid(_settings_overlay) and _settings_overlay.handle_back_requested():
		return true
	if not is_change_confirmation_visible():
		return false
	_cancel_change_character()
	return true


## PS-142: espone il valore assegnato dal clamp per la verifica di
## regressione (mai un pavimento più grande dell'altezza naturale del VBox).
func get_pause_scroll_min_height() -> float:
	return _pause_scroll.custom_minimum_size.y if is_instance_valid(_pause_scroll) else 0.0


## PS-142: altezza naturale corrente del contenuto (titolo + bottoni),
## letta a fresco per confrontarla con `get_pause_scroll_min_height()`.
func get_pause_content_natural_height() -> float:
	return _pause_vbox.get_combined_minimum_size().y if is_instance_valid(_pause_vbox) else 0.0


func get_pause_panel_rect() -> Rect2:
	if not is_instance_valid(_pause_center) or _pause_center.get_child_count() == 0:
		return Rect2()
	var panel := _pause_center.get_child(0) as Control
	return panel.get_global_rect() if is_instance_valid(panel) else Rect2()


## PS-142: quando il pannello passa da nascosto a visibile, Godot rimanda al
## prossimo frame di idle la sort dei container che assegna a `_pause_vbox`
## la larghezza reale su cui misura la propria altezza minima. Leggere
## `get_combined_minimum_size()` nello stesso istante sincrono di
## `visible = true` restituisce quindi un valore stale (misurato mentre il
## pannello era ancora nascosto), che il clamp applicherebbe come un
## pavimento invece che come un tetto — il bug osservato da questa card.
## Una connessione one-shot a `process_frame`, invece di
## `await get_tree().process_frame` (stesso schema di PS-096/PS-097 in
## `upgrade_card.gd`/`upgrade_overlay.gd`), evita l'errore motore "Resumed
## function ... after await, but class instance is gone" se l'overlay viene
## liberato (fine test, restart) mentre l'attesa è sospesa: la connessione si
## scioglie da sola senza invocare nulla.
func _request_pause_scroll_height_refresh() -> void:
	if not is_inside_tree():
		return
	var frame_signal := get_tree().process_frame
	if not frame_signal.is_connected(_on_pause_scroll_height_frame_elapsed):
		frame_signal.connect(_on_pause_scroll_height_frame_elapsed, CONNECT_ONE_SHOT)


func _on_pause_scroll_height_frame_elapsed() -> void:
	if not is_instance_valid(self) or not is_inside_tree():
		return
	_clamp_pause_scroll_height()


## PS-085: PauseCenter (CenterContainer) non clippa ne' scorre da solo: senza
## questo clamp il pannello sforerebbe semplicemente il viewport invece di
## restare centrato. Sui profili con margine sufficiente il risultato resta
## identico a prima (nessuno scroll). Il pannello è più corto da PS-137 (solo
## titolo + Riprendi + Cambia personaggio): il clamp resta comunque un tetto,
## non un pavimento, per coerenza con lo stesso principio ovunque applicato.
func _clamp_pause_scroll_height() -> void:
	if (
		not is_instance_valid(_pause_scroll)
		or not is_instance_valid(_pause_vbox)
		or not is_instance_valid(_pause_center)
		or _pause_center.get_child_count() == 0
		or not is_inside_tree()
	):
		return
	var panel := _pause_center.get_child(0) as PanelContainer
	if panel == null:
		return
	var natural_height := _pause_vbox.get_combined_minimum_size().y
	var style := panel.get_theme_stylebox(&"panel")
	var chrome := (style.content_margin_top + style.content_margin_bottom) if style != null else 0.0
	var viewport_height := get_viewport().get_visible_rect().size.y
	var available_height := maxf(viewport_height - chrome - PAUSE_SCROLL_SAFETY_MARGIN, 0.0)
	_pause_scroll.custom_minimum_size.y = minf(natural_height, available_height)


func _on_resume_button_pressed() -> void:
	if not is_accepting_resume() or is_change_confirmation_visible():
		return
	resume_requested.emit()


func _on_change_character_button_pressed() -> void:
	if not is_accepting_resume() or is_change_confirmation_visible():
		return
	ui_click_requested.emit()
	_pause_center.visible = false
	_confirmation_center.visible = true
	_resume_button.disabled = true
	_change_character_button.disabled = true
	_settings_button.disabled = true
	_set_confirmation_buttons_disabled(false)
	_cancel_change_button.call_deferred("grab_focus")


## PS-137: apre l'overlay condiviso. Riprendi/Cambia personaggio/Impostazioni
## restano disabilitati finché l'overlay non si chiude
## (`_on_settings_overlay_closed`), cosi' il focus non può finire su un
## bottone coperto dal modal.
func _on_settings_button_pressed() -> void:
	if not is_accepting_resume() or is_change_confirmation_visible() or not is_instance_valid(_settings_overlay):
		return
	ui_click_requested.emit()
	_resume_button.disabled = true
	_change_character_button.disabled = true
	_settings_button.disabled = true
	_settings_overlay.open()


func _on_settings_overlay_closed() -> void:
	if not is_accepting_resume() or is_change_confirmation_visible():
		return
	_resume_button.disabled = false
	_change_character_button.disabled = false
	_settings_button.disabled = false
	_settings_button.call_deferred("grab_focus")


func _on_cancel_change_button_pressed() -> void:
	if not is_change_confirmation_visible():
		return
	ui_click_requested.emit()
	_cancel_change_character()


func _on_confirm_change_button_pressed() -> void:
	if not is_change_confirmation_visible() or _confirm_change_button.disabled:
		return
	ui_click_requested.emit()
	_accepting_resume = false
	_set_confirmation_buttons_disabled(true)
	change_character_requested.emit()


func _cancel_change_character() -> void:
	_show_pause_controls()
	_change_character_button.call_deferred("grab_focus")


func _show_pause_controls() -> void:
	_pause_center.visible = true
	_confirmation_center.visible = false
	_resume_button.disabled = false
	_change_character_button.disabled = false
	_settings_button.disabled = false
	_set_confirmation_buttons_disabled(true)


func _set_confirmation_buttons_disabled(disabled: bool) -> void:
	if is_instance_valid(_cancel_change_button):
		_cancel_change_button.disabled = disabled
	if is_instance_valid(_confirm_change_button):
		_confirm_change_button.disabled = disabled
