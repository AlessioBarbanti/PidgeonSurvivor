class_name HyperfocusAura
extends Node2D

## Aura di potenziamento dell'iperfocus di Lollo (PS-099): si accende dietro
## alla sagoma durante l'iperfocus e sparisce durante la distrazione, sulla
## falsariga della scena classica di un personaggio che si carica di energia
## invece di un cambio di tinta (PS-098).
##
## Vive come fratello di `CharacterSprite`, non figlio, con `z_index`
## inferiore nella scena cosi' resta sempre dietro per costruzione — non un
## `show_behind_parent` su un figlio: era lo schema di `PassiveStateOutline`
## (PS-001/PS-029), bocciato perche' ricalcava il profilo dello sprite.
##
## L'asset di PS-098 e' una sola texture animata qui con alfa e scala
## (nessun foglio di frame, vedi Decisioni di PS-098): il tremolio e'
## responsabilita' di questo nodo.

const TEXTURE := preload("res://assets/art/vfx/state_tells/generated/hyperfocus_aura.png")
const DISPLAY_SIZE := Vector2(96.0, 96.0)
const CENTER_OFFSET := Vector2(0.0, -4.0)
const BASE_ALPHA := 0.88
const ALPHA_JITTER := 0.10
const SCALE_JITTER := 0.035
const PULSE_SPEED := 3.4

var _presented := false
var _phase := 0.0
var _sprite: Sprite2D


func _ready() -> void:
	_sprite = get_parent().get_node_or_null(^"CharacterSprite") as Sprite2D


func set_presented(value: bool) -> void:
	if _presented == value:
		return
	_presented = value
	visible = value
	if value:
		_phase = 0.0
	queue_redraw()


func is_presented() -> bool:
	return _presented


## Osservabilita' per lo smoke: tiene conto anche del lampeggio da
## invulnerabilita', stesso principio di `PassiveStateParticles`.
func is_effectively_visible() -> bool:
	if not _presented:
		return false
	return not is_instance_valid(_sprite) or _sprite.visible


## Va chiamata dal chiamante soltanto quando la run e' RUNNING (stesso
## principio di `ThunderChargeAura.advance`): il nodo stesso non conosce il
## `RunController`.
func advance(delta: float) -> void:
	if not is_finite(delta) or delta <= 0.0 or not _presented:
		return
	_phase = wrapf(_phase + PULSE_SPEED * delta, 0.0, TAU)
	queue_redraw()


func get_phase() -> float:
	return _phase


func _draw() -> void:
	if not _presented:
		return
	if is_instance_valid(_sprite) and not _sprite.visible:
		return
	var wobble := sin(_phase)
	var alpha := clampf(BASE_ALPHA + wobble * ALPHA_JITTER, 0.0, 1.0)
	var size := DISPLAY_SIZE * (1.0 + wobble * SCALE_JITTER)
	draw_texture_rect(
		TEXTURE,
		Rect2(CENTER_OFFSET - size * 0.5, size),
		false,
		Color(1.0, 1.0, 1.0, alpha)
	)
