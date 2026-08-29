class_name GutGameplayTest
extends GutTest

## Base condivisa per i test GUT che devono instanziare la scena di gioco.
## Raccoglie gli helper duplicati in decine di smoke legacy
## (tests/integration/_*_smoke.gd): attesa frame dopo l'istanza,
## costruttori di InputEvent, asserzioni vettore/rect "quasi uguale".

const FLOAT_TOLERANCE := 0.001
const MOVEMENT_SLICE_SCENE := preload("res://scenes/game/movement_slice.tscn")
const INITIAL_VIEWPORT_SIZE := Vector2i(1280, 720)


func instantiate_movement_slice(viewport_size: Vector2i = INITIAL_VIEWPORT_SIZE) -> Control:
	get_tree().root.content_scale_size = viewport_size
	get_tree().root.size = viewport_size
	await wait_process_frames(2)
	var slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	add_child_autofree(slice)
	await wait_process_frames(2)
	return slice


func assert_vector_near(
	actual: Vector2,
	expected: Vector2,
	text: String = "",
	tolerance: float = FLOAT_TOLERANCE
) -> void:
	assert_true(
		actual.distance_to(expected) <= tolerance,
		"%s Atteso %s, ottenuto %s." % [text, expected, actual]
	)


func assert_rect_near(
	actual: Rect2,
	expected: Rect2,
	text: String = "",
	tolerance: float = FLOAT_TOLERANCE
) -> void:
	assert_true(
		actual.position.distance_to(expected.position) <= tolerance
		and actual.size.distance_to(expected.size) <= tolerance,
		"%s Atteso %s, ottenuto %s." % [text, expected, actual]
	)


func assert_rect_inside(
	inner: Rect2,
	outer: Rect2,
	text: String = "",
	tolerance: float = FLOAT_TOLERANCE
) -> void:
	assert_true(
		inner.has_area()
		and outer.has_area()
		and inner.position.x >= outer.position.x - tolerance
		and inner.position.y >= outer.position.y - tolerance
		and inner.end.x <= outer.end.x + tolerance
		and inner.end.y <= outer.end.y + tolerance,
		"%s Interno %s, esterno %s." % [text, inner, outer]
	)


func make_touch_event(index: int, pressed: bool, position: Vector2) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.pressed = pressed
	event.position = position
	return event


func make_drag_event(index: int, position: Vector2, relative: Vector2) -> InputEventScreenDrag:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = position
	event.relative = relative
	return event


func make_key_event(keycode: Key, pressed: bool) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = pressed
	return event


func make_joy_button_event(button_index: JoyButton, pressed: bool) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = button_index
	event.pressed = pressed
	return event
