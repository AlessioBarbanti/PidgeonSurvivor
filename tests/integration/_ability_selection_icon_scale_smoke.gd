extends SceneTree

const CHARACTER_SELECT_SCENE := preload("res://scenes/ui/character_select_overlay.tscn")
const VIEWPORTS: Array[Vector2i] = [Vector2i(1280, 720), Vector2i(1080, 2400), Vector2i(1024, 768)]
const ABILITY_ICON_PATH := NodePath("Center/SelectionPanel/Content/MainRow/AbilityCards/AbilityCard/AbilityContent/AbilityIconSlot/AbilityIcon")
const PASSIVE_ICON_PATH := NodePath("Center/SelectionPanel/Content/MainRow/AbilityCards/PassiveCard/PassiveContent/PassiveIconSlot/PassiveIcon")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for viewport_size in VIEWPORTS:
		root.content_scale_size = viewport_size
		root.size = viewport_size
		var selector := CHARACTER_SELECT_SCENE.instantiate() as CharacterSelectOverlay
		root.add_child(selector)
		selector.show()
		await process_frame
		await process_frame
		var ability_icon := selector.get_node_or_null(ABILITY_ICON_PATH) as TextureRect
		var passive_icon := selector.get_node_or_null(PASSIVE_ICON_PATH) as TextureRect
		_expect(ability_icon != null, "%s: icona abilita assente." % viewport_size)
		_expect(passive_icon != null, "%s: icona passiva assente." % viewport_size)
		if ability_icon != null:
			_expect(ability_icon.custom_minimum_size == Vector2(128.0, 128.0), "%s: icona abilita deve essere 128x128." % viewport_size)
			_expect(ability_icon.expand_mode == 1 and ability_icon.stretch_mode == 5, "%s: icona abilita deve conservare proporzioni e nitidezza." % viewport_size)
		if passive_icon != null:
			_expect(passive_icon.custom_minimum_size == Vector2(94.0, 94.0), "%s: icona passiva deve essere 94x94 per compensare il padding trasparente dell'attiva." % viewport_size)
			_expect(passive_icon.expand_mode == 1 and passive_icon.stretch_mode == 5, "%s: icona passiva deve conservare proporzioni e nitidezza." % viewport_size)
		selector.queue_free()
		await process_frame
	if _failures.is_empty():
		print("ABILITY_SELECTION_ICON_SCALE_SMOKE_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	printerr("ABILITY_SELECTION_ICON_SCALE_SMOKE_FAIL count=%d" % _failures.size())
	quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
