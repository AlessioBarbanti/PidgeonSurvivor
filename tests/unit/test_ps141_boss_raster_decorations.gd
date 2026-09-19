extends GutTest


func test_boss_raster_charge_preserves_tier_and_does_not_change_player_aura() -> void:
	var boss_aura := ThunderChargeAura.new()
	var player_aura := ThunderChargeAura.new()
	add_child_autofree(boss_aura)
	add_child_autofree(player_aura)
	boss_aura.set_tier(ThunderChargeAura.TIER_HIGH)
	boss_aura.set_rotation_speed(1.4)
	boss_aura.advance(0.5)
	var phase_before := boss_aura.get_angle()
	var color_before := boss_aura.get_bolt_color()
	var texture: Texture2D = load("res://assets/art/vfx/abilities/generated/lightning_impact.png")
	boss_aura.set_bolt_texture(texture)
	assert_same(boss_aura.get_bolt_texture(), texture)
	assert_null(player_aura.get_bolt_texture(), "La variante raster appartiene solo all'istanza Boss.")
	assert_eq(boss_aura.get_bolt_count(), 3, "La fascia alta conserva tre segnali di carica.")
	assert_eq(boss_aura.get_bolt_color(), color_before)
	assert_eq(boss_aura.get_angle(), phase_before, "Cambiare resa non avanza il tempo del tell.")
	boss_aura.advance(0.0)
	assert_eq(boss_aura.get_angle(), phase_before)
	print("PS141_BOSS_RASTER_DECORATIONS_OK")


func test_clone_texture_disables_procedural_body_fallback() -> void:
	var scene: PackedScene = load("res://scenes/actors/boss_decoy.tscn")
	var clone := scene.instantiate() as BossDecoy
	add_child_autofree(clone)
	assert_false(clone.has_visual_sprite())
	var sprite := clone.get_node("DecoySprite") as Sprite2D
	var texture: Texture2D = load("res://assets/art/vfx/abilities/generated/reggaeton_decoy.png")
	sprite.texture = texture
	assert_true(clone.has_visual_sprite(), "Lo sprite del clone sopprime la sagoma procedurale ereditata.")
	assert_same(clone.get_decoy_texture(), texture)
