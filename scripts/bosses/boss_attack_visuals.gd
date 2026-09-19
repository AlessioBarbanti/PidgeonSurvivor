class_name BossAttackVisuals
extends RefCounted

## PS-141/144: geometria stabile; il countdown cambia solo l'intensita'.
const RING: Texture2D = preload("res://assets/art/vfx/boss_attacks/generated/boss_danger_ring.png")
const BLAST: Texture2D = preload("res://assets/art/vfx/boss_attacks/generated/boss_blast.png")
const RETICLE: Texture2D = preload("res://assets/art/vfx/boss_attacks/generated/boss_reticle.png")
const CORRIDOR: Texture2D = preload("res://assets/art/vfx/boss_attacks/generated/boss_corridor.png")
const RING_ALPHA_RADIUS := 0.46
const CORRIDOR_REGION := Rect2(21.0, 203.0, 470.0, 106.0)
const CORRIDOR_MAX_TILES := 4
const ABILITY_ROOT := "res://assets/art/vfx/abilities/generated/"
const SIGNATURE_TEXTURES := {
	BossSignatureRegistry.TELLURIC_SHOCKWAVE: preload(ABILITY_ROOT + "earthquake_wave.png"),
	BossSignatureRegistry.POWERSLIDE: preload(ABILITY_ROOT + "fire_trail.png"),
	BossSignatureRegistry.THUNDER_STORM: preload(ABILITY_ROOT + "lightning_impact.png"),
	BossSignatureRegistry.GRAND_SPIN: preload(ABILITY_ROOT + "grand_spin.png"),
	BossSignatureRegistry.THERMAL_SHOCK: preload(ABILITY_ROOT + "thermal_frost.png"),
	BossSignatureRegistry.RANDOM_COSPLAY: preload(ABILITY_ROOT + "cosplay_reveal.png"),
	BossSignatureRegistry.ZEN_SLOWDOWN: preload(ABILITY_ROOT + "zen_field.png"),
	BossSignatureRegistry.REGGAETON_CLONE: preload(ABILITY_ROOT + "reggaeton_decoy.png"),
}
const THERMAL_HOT: Texture2D = preload(ABILITY_ROOT + "thermal_bloom.png")


static func intensity(progress: float) -> float:
	return lerpf(0.42, 1.0, clampf(progress, 0.0, 1.0))


static func ring_rect(center: Vector2, radius: float) -> Rect2:
	var half_size := Vector2.ONE * maxf(radius, 0.0) / (2.0 * RING_ALPHA_RADIUS)
	return Rect2(center - half_size, half_size * 2.0)


static func stamp(canvas: CanvasItem, texture: Texture2D, center: Vector2, radius: float, tint: Color, angle: float = 0.0) -> void:
	canvas.draw_set_transform(center, angle)
	canvas.draw_texture_rect(texture, Rect2(-Vector2.ONE * radius, Vector2.ONE * radius * 2.0), false, tint)
	canvas.draw_set_transform(Vector2.ZERO)


static func ring(canvas: CanvasItem, center: Vector2, radius: float, tint: Color) -> void:
	canvas.draw_texture_rect(RING, ring_rect(center, radius), false, tint)


static func warning(canvas: CanvasItem, center: Vector2, radius: float, progress: float, tint: Color) -> void:
	var strength := intensity(progress)
	stamp(canvas, BLAST, center, radius * lerpf(0.24, 0.9, progress), Color(tint, tint.a * strength * 0.42))
	ring(canvas, center, radius, Color(tint, tint.a * strength))
	stamp(canvas, RETICLE, center, minf(radius * 0.23, 20.0), Color(tint, tint.a * strength))


static func corridor_tiles(length: float, radius: float) -> int:
	var native := maxf(radius, 1.0) * 2.0 * CORRIDOR_REGION.size.x / CORRIDOR_REGION.size.y
	return clampi(ceili(maxf(length, 0.0) / native), 1, CORRIDOR_MAX_TILES)


## Il nastro viene ripetuto vicino alla proporzione nativa: una sola quad
## stirata su tutta la corsia appiattisce la materia in un tratto da wireframe.
static func corridor(canvas: CanvasItem, start: Vector2, end: Vector2, radius: float, tint: Color) -> void:
	var offset := end - start
	if offset.is_zero_approx():
		ring(canvas, start, radius, tint)
		return
	var length := offset.length()
	var band := maxf(radius, 1.0) * 2.0
	var tiles := corridor_tiles(length, radius)
	var step := length / float(tiles)
	canvas.draw_set_transform(start, offset.angle())
	for index in tiles:
		canvas.draw_texture_rect_region(CORRIDOR, Rect2(step * float(index), -band * 0.5, step, band), CORRIDOR_REGION, tint)
	canvas.draw_set_transform(Vector2.ZERO)
	ring(canvas, start, radius, tint)
	ring(canvas, end, radius, tint)


static func signature_texture(effect_id: StringName) -> Texture2D:
	return SIGNATURE_TEXTURES.get(effect_id, BLAST) as Texture2D
