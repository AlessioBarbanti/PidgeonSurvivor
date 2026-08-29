extends GutTest

const CHARACTER_SELECT_SCENE := preload("res://scenes/ui/character_select_overlay.tscn")
const VIEWPORTS: Array[Vector2i] = [Vector2i(1280, 720), Vector2i(1080, 2400), Vector2i(1024, 768)]
const ABILITY_ICON_PATH := NodePath("Center/SelectionPanel/Content/MainRow/AbilityCards/AbilityCard/AbilityContent/AbilityIconSlot/AbilityIcon")
const PASSIVE_ICON_PATH := NodePath("Center/SelectionPanel/Content/MainRow/AbilityCards/PassiveCard/PassiveContent/PassiveIconSlot/PassiveIcon")


func test_ability_and_passive_icons_keep_scale_across_viewports() -> void:
	for viewport_size: Vector2i in VIEWPORTS:
		get_tree().root.content_scale_size = viewport_size
		get_tree().root.size = viewport_size
		var selector := CHARACTER_SELECT_SCENE.instantiate() as CharacterSelectOverlay
		add_child(selector)
		selector.show()
		await wait_process_frames(2)

		var ability_icon := selector.get_node_or_null(ABILITY_ICON_PATH) as TextureRect
		var passive_icon := selector.get_node_or_null(PASSIVE_ICON_PATH) as TextureRect
		assert_not_null(ability_icon, "%s: icona abilita assente." % viewport_size)
		assert_not_null(passive_icon, "%s: icona passiva assente." % viewport_size)
		if ability_icon != null:
			assert_eq(
				ability_icon.custom_minimum_size,
				Vector2(136.0, 136.0),
				"%s: icona abilita deve essere 136x136." % viewport_size
			)
			assert_true(
				ability_icon.expand_mode == 1 and ability_icon.stretch_mode == 5,
				"%s: icona abilita deve conservare proporzioni e nitidezza." % viewport_size
			)
		if passive_icon != null:
			assert_eq(
				passive_icon.custom_minimum_size,
				Vector2(108.0, 108.0),
				"%s: icona passiva deve essere 108x108 per compensare il padding trasparente dell'attiva." % viewport_size
			)
			assert_true(
				passive_icon.expand_mode == 1 and passive_icon.stretch_mode == 5,
				"%s: icona passiva deve conservare proporzioni e nitidezza." % viewport_size
			)
		selector.queue_free()
		await wait_process_frames(1)
