class_name TouchAbilityButton
extends Button

signal activation_requested()

var _direct_touch_sequence_active := false


func _ready() -> void:
	pressed.connect(_on_native_pressed)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if not touch_event.pressed or touch_event.canceled:
			call_deferred("_finish_direct_touch_sequence")
			return
		if disabled or not is_visible_in_tree():
			return
		if (
			get_global_rect().has_point(touch_event.position)
		):
			_direct_touch_sequence_active = true
			activation_requested.emit()


func _on_native_pressed() -> void:
	if not _direct_touch_sequence_active:
		activation_requested.emit()


func _finish_direct_touch_sequence() -> void:
	_direct_touch_sequence_active = false
