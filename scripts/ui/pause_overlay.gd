class_name PauseOverlay
extends Control

signal resume_requested()
signal change_character_requested()
## PS-147: abbandono esplicito della run corrente verso la welcome, distinto
## da CAMBIA PERSONAGGIO (che porta alla selezione).
signal exit_requested()
## PS-074: bottoni senza un cue dedicato (il resume esistente segue lo stato
## RunController, non questo segnale).
signal ui_click_requested()

@onready var _resume_button: Button = %ResumeButton
@onready var _change_character_button: Button = %ChangeCharacterButton
@onready var _settings_button: Button = %SettingsButton
@onready var _exit_button: Button = %ExitButton
@onready var _pause_center: CenterContainer = %PauseCenter
@onready var _confirmation_center: CenterContainer = %ConfirmationCenter
@onready var _confirmation_title_label: Label = %ConfirmationTitleLabel
@onready var _confirmation_summary_label: Label = %ConfirmationSummaryLabel
@onready var _cancel_change_button: Button = %CancelChangeButton
@onready var _confirm_change_button: Button = %ConfirmChangeButton
@onready var _pause_scroll: ScrollContainer = %PauseScroll
@onready var _pause_vbox: VBoxContainer = %VBox
@onready var _build_summary_separator: HSeparator = %BuildSummarySeparator
@onready var _build_summary_title: Label = %BuildSummaryTitle
@onready var _build_summary_list: VBoxContainer = %BuildSummaryList

## PS-085: margine di respiro fra lo scroll del pannello e i bordi del
## viewport, cosi' il contenuto non tocca mai esattamente il limite anche
## quando e' clampato al massimo consentito.
const PAUSE_SCROLL_SAFETY_MARGIN := 24.0

## PS-164: icona alla stessa dimensione già validata per la leggibilità delle
## icone upgrade (vedi `EndScreen.UPGRADE_CHIP_ICON_SIZE`), non un valore
## ridotto per "risparmiare spazio" — se la lista cresce ci pensa lo
## scroll/clamp già esistente del pannello.
const BUILD_SUMMARY_ICON_SIZE := Vector2(48, 48)
const BUILD_SUMMARY_ROW_SEPARATION := 12
## Stesso oro già in uso in questo pannello per `ConfirmationTitleLabel`
## (elemento "in rilievo"): unico scarto di colore ammesso, solo sul titolo —
## mai un bordo/sfondo dedicato come su `UpgradeCard`, che resta riservato
## alle card cliccabili (revisione direttore-artistico, PS-164).
const BUILD_SUMMARY_SPECIALITY_TITLE_COLOR := Color(1, 0.85, 0.32, 1)
const BUILD_SUMMARY_TITLE_COLOR := Color(1, 0.91, 0.7, 1)
const BUILD_SUMMARY_RANK_COLOR := Color(0.722, 0.784, 0.85, 1)

var _upgrade_service: UpgradeService

## PS-147: `ConfirmationCenter` serve due scopi (CAMBIA PERSONAGGIO ed ESCI);
## questi valori distinguono quale testo mostrare e quale segnale emettere
## alla conferma, invece di duplicare il pannello.
enum ConfirmationAction { CHANGE_CHARACTER, EXIT }

const CHANGE_CHARACTER_TITLE := "CAMBIA PERSONAGGIO?"
const CHANGE_CHARACTER_SUMMARY := "I progressi della run corrente saranno azzerati."
const EXIT_TITLE := "USCIRE DALLA PARTITA?"
const EXIT_SUMMARY := "Abbandonerai la run corrente e tornerai al menu."

var _accepting_resume := false
var _pending_confirmation_action: ConfirmationAction = ConfirmationAction.CHANGE_CHARACTER

## PS-137: overlay impostazioni condiviso con la welcome, istanza unica
## posseduta da `movement_slice.gd` — vedi `configure_settings_overlay()`.
var _settings_overlay: SettingsOverlay


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_resume_button.pressed.connect(_on_resume_button_pressed)
	_change_character_button.pressed.connect(_on_change_character_button_pressed)
	_settings_button.pressed.connect(_on_settings_button_pressed)
	_exit_button.pressed.connect(_on_exit_button_pressed)
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


## PS-164: cablata una sola volta da `movement_slice.gd`, come già fa
## `configure_settings_overlay()`. Sola lettura: il riepilogo legge
## `get_ranks()`/`get_registry()` già esposti da `UpgradeService`, non
## modifica mai la build da qui.
func configure_upgrade_service(service: UpgradeService) -> bool:
	if not is_instance_valid(service):
		return false
	_upgrade_service = service
	return true


func get_upgrade_service() -> UpgradeService:
	return _upgrade_service if is_instance_valid(_upgrade_service) else null


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
	_refresh_build_summary()
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
	if is_instance_valid(_exit_button):
		_exit_button.disabled = true
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


func get_exit_button() -> Button:
	return _exit_button if is_instance_valid(_exit_button) else null


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
	_cancel_confirmation()
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


## PS-164: numero di voci mostrate nel riepilogo build (upgrade ordinari +
## Specialità sbloccate), ricostruito a ogni `show_pause()`.
func get_build_summary_row_count() -> int:
	return _build_summary_list.get_child_count() if is_instance_valid(_build_summary_list) else 0


## PS-164: la sezione resta nascosta finché non c'è almeno un upgrade da
## mostrare, cosi' un'apertura pausa a inizio run non mostra un'intestazione
## vuota.
func is_build_summary_visible() -> bool:
	return is_instance_valid(_build_summary_list) and _build_summary_list.visible


func get_build_summary_row_title_text(index: int) -> String:
	var title_label := _get_build_summary_row_title_label(index)
	return title_label.text if title_label != null else ""


func get_build_summary_row_title_color(index: int) -> Color:
	var title_label := _get_build_summary_row_title_label(index)
	return title_label.get_theme_color(&"font_color") if title_label != null else Color.BLACK


func get_build_summary_row_rank_text(index: int) -> String:
	var row := _get_build_summary_row(index)
	if row == null or row.get_child_count() < 3:
		return ""
	var rank_label := row.get_child(2) as Label
	return rank_label.text if rank_label != null else ""


func _get_build_summary_row_title_label(index: int) -> Label:
	var row := _get_build_summary_row(index)
	if row == null or row.get_child_count() < 2:
		return null
	return row.get_child(1) as Label


func _get_build_summary_row(index: int) -> Control:
	if (
		not is_instance_valid(_build_summary_list)
		or index < 0
		or index >= _build_summary_list.get_child_count()
	):
		return null
	return _build_summary_list.get_child(index) as Control


## PS-164: ricostruito a ogni apertura della pausa — un upgrade appena scelto
## compare senza bisogno di un segnale dedicato, e il riepilogo si azzera da
## solo a restart/cambio personaggio, quando `UpgradeService` svuota i
## ranghi prima della prossima `RUNNING` (nessuno stato duplicato da
## resettare qui).
func _refresh_build_summary() -> void:
	if not is_instance_valid(_build_summary_list):
		return
	for child in _build_summary_list.get_children():
		_build_summary_list.remove_child(child)
		child.queue_free()

	var entries := _collect_build_summary_entries()
	var has_entries := not entries.is_empty()
	if is_instance_valid(_build_summary_separator):
		_build_summary_separator.visible = has_entries
	if is_instance_valid(_build_summary_title):
		_build_summary_title.visible = has_entries
	_build_summary_list.visible = has_entries
	for entry in entries:
		_build_summary_list.add_child(_build_summary_build_row(entry))


## Stesso ordinamento deterministico di
## `movement_slice._build_top_upgrade_entries()` (rango decrescente, poi ID),
## ma senza il troncamento a 3: qui serve l'intera build, non solo i
## migliori. Le Specialità ancora bloccate non hanno rango nel dizionario
## (mai selezionate) e restano fuori da questa lista senza filtro dedicato.
func _collect_build_summary_entries() -> Array[RunSummary.UpgradeEntry]:
	var entries: Array[RunSummary.UpgradeEntry] = []
	if not is_instance_valid(_upgrade_service):
		return entries
	var registry := _upgrade_service.get_registry()
	if not is_instance_valid(registry):
		return entries
	var ranks := _upgrade_service.get_ranks()
	for definition in registry.get_definitions():
		var rank: int = ranks.get(definition.id, 0)
		if rank <= 0:
			continue
		entries.append(RunSummary.UpgradeEntry.new(definition, rank))
	entries.sort_custom(
		func(a: RunSummary.UpgradeEntry, b: RunSummary.UpgradeEntry) -> bool:
			if a.rank != b.rank:
				return a.rank > b.rank
			return String(a.definition.id) < String(b.definition.id)
	)
	return entries


## Riga costruita a runtime come `EndScreen._build_upgrade_chip()`: stessa
## dimensione/filtro icona, nessun nodo salvato in scena da tenere in sync.
func _build_summary_build_row(entry: RunSummary.UpgradeEntry) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", BUILD_SUMMARY_ROW_SEPARATION)

	var icon := TextureRect.new()
	icon.custom_minimum_size = BUILD_SUMMARY_ICON_SIZE
	icon.texture = entry.definition.icon
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)

	var title_label := Label.new()
	title_label.theme_type_variation = &"BodyM"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_color_override(
		&"font_color",
		BUILD_SUMMARY_SPECIALITY_TITLE_COLOR if entry.definition.is_speciality else BUILD_SUMMARY_TITLE_COLOR
	)
	title_label.text = entry.definition.title
	row.add_child(title_label)

	var rank_label := Label.new()
	rank_label.theme_type_variation = &"ValueNumeric"
	rank_label.add_theme_color_override(&"font_color", BUILD_SUMMARY_RANK_COLOR)
	rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rank_label.text = "Rango %d" % entry.rank
	row.add_child(rank_label)

	return row


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
	_pending_confirmation_action = ConfirmationAction.CHANGE_CHARACTER
	_confirmation_title_label.text = CHANGE_CHARACTER_TITLE
	_confirmation_summary_label.text = CHANGE_CHARACTER_SUMMARY
	_pause_center.visible = false
	_confirmation_center.visible = true
	_resume_button.disabled = true
	_change_character_button.disabled = true
	_settings_button.disabled = true
	_exit_button.disabled = true
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
	_exit_button.disabled = true
	_settings_overlay.open()


func _on_settings_overlay_closed() -> void:
	if not is_accepting_resume() or is_change_confirmation_visible():
		return
	_resume_button.disabled = false
	_change_character_button.disabled = false
	_settings_button.disabled = false
	_exit_button.disabled = false
	_settings_button.call_deferred("grab_focus")


## PS-147: apre la stessa conferma di CAMBIA PERSONAGGIO con testo dedicato
## all'abbandono della run, invece di duplicare il pannello.
func _on_exit_button_pressed() -> void:
	if not is_accepting_resume() or is_change_confirmation_visible():
		return
	ui_click_requested.emit()
	_pending_confirmation_action = ConfirmationAction.EXIT
	_confirmation_title_label.text = EXIT_TITLE
	_confirmation_summary_label.text = EXIT_SUMMARY
	_pause_center.visible = false
	_confirmation_center.visible = true
	_resume_button.disabled = true
	_change_character_button.disabled = true
	_settings_button.disabled = true
	_exit_button.disabled = true
	_set_confirmation_buttons_disabled(false)
	_cancel_change_button.call_deferred("grab_focus")


func _on_cancel_change_button_pressed() -> void:
	if not is_change_confirmation_visible():
		return
	ui_click_requested.emit()
	_cancel_confirmation()


func _on_confirm_change_button_pressed() -> void:
	if not is_change_confirmation_visible() or _confirm_change_button.disabled:
		return
	ui_click_requested.emit()
	_accepting_resume = false
	_set_confirmation_buttons_disabled(true)
	if _pending_confirmation_action == ConfirmationAction.EXIT:
		exit_requested.emit()
	else:
		change_character_requested.emit()


func _cancel_confirmation() -> void:
	_show_pause_controls()
	var focus_target := _exit_button if _pending_confirmation_action == ConfirmationAction.EXIT else _change_character_button
	focus_target.call_deferred("grab_focus")


func _show_pause_controls() -> void:
	_pause_center.visible = true
	_confirmation_center.visible = false
	_resume_button.disabled = false
	_change_character_button.disabled = false
	_settings_button.disabled = false
	_exit_button.disabled = false
	_set_confirmation_buttons_disabled(true)


func _set_confirmation_buttons_disabled(disabled: bool) -> void:
	if is_instance_valid(_cancel_change_button):
		_cancel_change_button.disabled = disabled
	if is_instance_valid(_confirm_change_button):
		_confirm_change_button.disabled = disabled
