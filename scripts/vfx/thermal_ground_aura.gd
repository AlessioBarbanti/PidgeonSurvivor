class_name ThermalGroundAura
extends Node2D

## Aura a terra della modalita' termica di Aleo (PS-099): resta sotto i piedi
## per tutta la durata della modalita' calda o fredda, cambiando texture al
## passaggio (PS-098: `thermal_aura_hot`/`thermal_aura_cold`).
##
## Vive come fratello di `CharacterSprite`, non figlio, con `z_index`
## inferiore nella scena cosi' il corpo non viene mai coperto dall'aura.

const HOT_TEXTURE := preload("res://assets/art/vfx/state_tells/generated/thermal_aura_hot.png")
const COLD_TEXTURE := preload("res://assets/art/vfx/state_tells/generated/thermal_aura_cold.png")
const DISPLAY_SIZE := Vector2(88.0, 88.0)
const FOOT_OFFSET := Vector2(0.0, 22.0)
const BASE_ALPHA := 0.92
const ALPHA_JITTER := 0.06
const PULSE_SPEED := 2.1

var _presented := false
var _hot := true
var _phase := 0.0
var _sprite: Sprite2D


func _ready() -> void:
	_sprite = get_parent().get_node_or_null(^"CharacterSprite") as Sprite2D


## Imposta la modalita' corrente e assicura che l'aura sia mostrata: chi
## chiama gestisce separatamente il congelamento durante pausa/modali con
## `set_presented`, stesso schema di `ThunderChargeAura`.
func set_mode(hot: bool) -> void:
	if _presented and _hot == hot:
		return
	_hot = hot
	_presented = true
	visible = true
	queue_redraw()


func set_presented(value: bool) -> void:
	if _presented == value:
		return
	_presented = value
	visible = value
	queue_redraw()


func is_presented() -> bool:
	return _presented


func is_hot() -> bool:
	return _hot


func is_effectively_visible() -> bool:
	if not _presented:
		return false
	return not is_instance_valid(_sprite) or _sprite.visible


func advance(delta: float) -> void:
	if not is_finite(delta) or delta <= 0.0 or not _presented:
		return
	_phase = wrapf(_phase + PULSE_SPEED * delta, 0.0, TAU)
	queue_redraw()


func _draw() -> void:
	if not _presented:
		return
	if is_instance_valid(_sprite) and not _sprite.visible:
		return
	var alpha := clampf(BASE_ALPHA + sin(_phase) * ALPHA_JITTER, 0.0, 1.0)
	var texture := HOT_TEXTURE if _hot else COLD_TEXTURE
	draw_texture_rect(
		texture,
		Rect2(FOOT_OFFSET - DISPLAY_SIZE * 0.5, DISPLAY_SIZE),
		false,
		Color(1.0, 1.0, 1.0, alpha)
	)
