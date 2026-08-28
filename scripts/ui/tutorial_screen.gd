class_name TutorialScreen
extends Control

signal close_requested()
signal play_requested()

## Dimensione desiderata del pannello: viene ridotta quando la safe area del
## dispositivo non la contiene, cosi copy e controlli restano sempre protetti.
const PANEL_PREFERRED_SIZE := Vector2(920.0, 620.0)

const SWIPE_MIN_DISTANCE := 72.0
const SWIPE_HORIZONTAL_DOMINANCE := 1.25

@export var pages: Array[TutorialPageDefinition] = []

@onready var _backdrop: Control = %Backdrop
@onready var _outer_margin: MarginContainer = %OuterMargin
@onready var _main_panel: PanelContainer = %MainPanel
@onready var _page_eyebrow: Label = %PageEyebrow
@onready var _page_title: Label = %PageTitle
@onready var _page_body: Label = %PageBody
@onready var _preview: TutorialPreview = %TutorialPreview
@onready var _page_dots: Label = %PageDots
@onready var _page_counter: Label = %PageCounter
@onready var _previous_button: Button = %PreviousButton
@onready var _next_button: Button = %NextButton

var _current_page_index := 0
var _reduced_flashes := false
var _swipe_touch_index := -1
var _swipe_start := Vector2.ZERO


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	## Lo sfondo decorativo vive fuori dai container della safe area e viene
	## riallineato al viewport completo a ogni cambio di rect o di risoluzione.
	set_notify_transform(true)
	resized.connect(_update_layout)
	get_viewport().size_changed.connect(_update_layout)
	_update_layout()
	_previous_button.pressed.connect(_on_previous_pressed)
	_next_button.pressed.connect(_on_next_pressed)
	_previous_button.focus_neighbor_right = _previous_button.get_path_to(_next_button)
	_next_button.focus_neighbor_left = _next_button.get_path_to(_previous_button)
	hide_tutorial()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		_update_layout()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		_handle_screen_touch(event)
		return
	if event.is_echo():
		return
	if event.is_action_pressed(&"ui_left") and _current_page_index > 0:
		show_page(_current_page_index - 1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_right") and _current_page_index < pages.size() - 1:
		show_page(_current_page_index + 1)
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or event.is_echo() or not event.is_action_pressed(&"ui_cancel"):
		return
	if handle_back_requested():
		get_viewport().set_input_as_handled()


func show_tutorial(reduced_flashes: bool = false) -> void:
	_reduced_flashes = reduced_flashes
	_current_page_index = 0
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_previous_button.disabled = false
	_next_button.disabled = false
	show_page(0)


func hide_tutorial() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_swipe_touch_index = -1
	if is_instance_valid(_preview):
		_preview.set_animation_active(false)
	if is_instance_valid(_previous_button):
		_previous_button.disabled = true
	if is_instance_valid(_next_button):
		_next_button.disabled = true


func handle_back_requested() -> bool:
	if not visible:
		return false
	close_requested.emit()
	return true


## La vetrina non lampeggia più (resta solo la camminata dei piccioni): lo stato
## viene conservato per l'autorità di accessibilità condivisa con welcome/pausa.
func set_reduced_flashes(enabled: bool) -> void:
	_reduced_flashes = enabled


## Rettangolo globale coperto dallo sfondo: deve contenere l'intero viewport.
func get_backdrop_rect() -> Rect2:
	if not is_instance_valid(_backdrop):
		return Rect2()
	return _backdrop.get_global_rect()


func show_page(page_index: int) -> bool:
	if page_index < 0 or page_index >= pages.size():
		return false
	var page := pages[page_index]
	if page == null or not page.is_valid():
		return false
	_current_page_index = page_index
	_page_eyebrow.text = page.eyebrow
	_page_title.text = page.title
	_page_body.text = page.body
	_update_layout()
	_preview.configure(page)
	_preview.set_animation_active(visible)
	_previous_button.text = "ESCI" if page_index == 0 else "INDIETRO"
	_next_button.text = "GIOCA" if page_index == pages.size() - 1 else "AVANTI"
	_page_counter.text = "%02d / %02d" % [page_index + 1, pages.size()]
	_page_dots.text = _build_page_dots(page_index)
	_next_button.call_deferred("grab_focus")
	return true


func get_page_count() -> int:
	return pages.size()


func get_current_page_index() -> int:
	return _current_page_index


func get_current_page() -> TutorialPageDefinition:
	if _current_page_index < 0 or _current_page_index >= pages.size():
		return null
	return pages[_current_page_index]


func get_page_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for page in pages:
		result.append(page.id if page != null else &"")
	return result


func get_main_panel_rect() -> Rect2:
	if not is_instance_valid(_main_panel):
		return Rect2()
	return _main_panel.get_global_rect()


func get_previous_button() -> Button:
	return _previous_button if is_instance_valid(_previous_button) else null


func get_next_button() -> Button:
	return _next_button if is_instance_valid(_next_button) else null


func get_page_counter_text() -> String:
	return _page_counter.text if is_instance_valid(_page_counter) else ""


func get_showcase_item_count() -> int:
	return _preview.get_showcase_item_count() if is_instance_valid(_preview) else 0


func get_gallery_column_count() -> int:
	return _preview.get_gallery_column_count() if is_instance_valid(_preview) else 0


func get_walker_row_counts() -> Array[int]:
	return _preview.get_walker_row_counts() if is_instance_valid(_preview) else []


func get_gallery_label_count() -> int:
	return _preview.get_gallery_label_count() if is_instance_valid(_preview) else 0


func measure_preview_loop_discontinuity(samples: int = 240) -> float:
	return _preview.measure_loop_discontinuity(samples) if is_instance_valid(_preview) else INF


func get_showcase_textures() -> Array[Texture2D]:
	return _preview.get_showcase_textures() if is_instance_valid(_preview) else []


func is_preview_animation_active() -> bool:
	return is_instance_valid(_preview) and _preview.is_animation_active()


func get_preview_animation_phase() -> float:
	return _preview.get_animation_phase() if is_instance_valid(_preview) else 0.0


func _update_layout() -> void:
	if not is_inside_tree():
		return
	_update_backdrop_rect()
	_update_panel_size()


func _update_backdrop_rect() -> void:
	if not is_instance_valid(_backdrop):
		return
	var viewport_rect := get_viewport().get_visible_rect()
	_backdrop.global_position = viewport_rect.position
	_backdrop.size = viewport_rect.size


func _update_panel_size() -> void:
	if not is_instance_valid(_main_panel) or not is_instance_valid(_outer_margin):
		return
	var available := size - Vector2(
		float(
			_outer_margin.get_theme_constant(&"margin_left")
			+ _outer_margin.get_theme_constant(&"margin_right")
		),
		float(
			_outer_margin.get_theme_constant(&"margin_top")
			+ _outer_margin.get_theme_constant(&"margin_bottom")
		)
	)
	_main_panel.custom_minimum_size = Vector2(
		minf(PANEL_PREFERRED_SIZE.x, maxf(available.x, 0.0)),
		minf(PANEL_PREFERRED_SIZE.y, maxf(available.y, 0.0))
	)


func simulate_swipe(start: Vector2, finish: Vector2) -> bool:
	return _apply_swipe_delta(finish - start)


func _on_previous_pressed() -> void:
	if not visible:
		return
	if _current_page_index == 0:
		handle_back_requested()
		return
	show_page(_current_page_index - 1)


func _on_next_pressed() -> void:
	if not visible:
		return
	if _current_page_index >= pages.size() - 1:
		play_requested.emit()
		return
	show_page(_current_page_index + 1)


func _handle_screen_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if _swipe_touch_index < 0:
			_swipe_touch_index = event.index
			_swipe_start = event.position
		return
	if event.index != _swipe_touch_index:
		return
	_swipe_touch_index = -1
	if _apply_swipe_delta(event.position - _swipe_start):
		get_viewport().set_input_as_handled()


func _apply_swipe_delta(delta: Vector2) -> bool:
	if (
		absf(delta.x) < SWIPE_MIN_DISTANCE
		or absf(delta.x) < absf(delta.y) * SWIPE_HORIZONTAL_DOMINANCE
	):
		return false
	if delta.x < 0.0 and _current_page_index < pages.size() - 1:
		return show_page(_current_page_index + 1)
	if delta.x > 0.0 and _current_page_index > 0:
		return show_page(_current_page_index - 1)
	return false


func _build_page_dots(active_index: int) -> String:
	var dots: PackedStringArray = []
	for index in pages.size():
		dots.append("●" if index == active_index else "○")
	return "  ".join(dots)
