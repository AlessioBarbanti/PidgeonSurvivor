class_name ThermalTransitionAnnouncer
extends Node2D

## Annuncio transitorio del passaggio caldo<->freddo di Aleo (PS-099): mostra
## il termometro corrispondente (PS-098) per una finestra breve dichiarata in
## `PresentationTimings`, poi sparisce da solo. `ThermalGroundAura` resta il
## tell persistente della modalita' corrente; questo nodo segnala solo il
## momento del cambio, non lo stato.

const HOT_TEXTURE := preload("res://assets/art/vfx/state_tells/generated/thermometer_hot.png")
const COLD_TEXTURE := preload("res://assets/art/vfx/state_tells/generated/thermometer_cold.png")
const DISPLAY_SIZE := Vector2(36.0, 36.0)
const ANCHOR_OFFSET := Vector2(26.0, -46.0)

var _remaining := 0.0
var _hot := true
var _sprite: Sprite2D


func _ready() -> void:
	_sprite = get_parent().get_node_or_null(^"CharacterSprite") as Sprite2D


## Avvia (o riavvia) l'annuncio per la modalita' appena raggiunta.
func trigger(hot: bool) -> void:
	_hot = hot
	_remaining = PresentationTimings.THERMAL_TRANSITION_ANNOUNCE_SECONDS
	queue_redraw()


## Azzera l'annuncio senza attendere lo scadere naturale (restart, cambio
## personaggio): nessun residuo deve sopravvivere a questi eventi.
func clear() -> void:
	_remaining = 0.0
	visible = false
	queue_redraw()


func has_active_announcement() -> bool:
	return _remaining > 0.0


## Combina il gate esterno (RUNNING) con lo stato interno del countdown:
## a differenza di `ThunderChargeAura`, qui la "presenza" dipende anche da un
## timer che il nodo possiede da solo, quindi la combinazione vive qui invece
## che nel chiamante.
func set_presented(value: bool) -> void:
	var next_visible := value and has_active_announcement()
	if visible == next_visible:
		return
	visible = next_visible
	queue_redraw()


func is_presented() -> bool:
	return visible


func is_hot() -> bool:
	return _hot


func get_remaining() -> float:
	return _remaining


func is_effectively_visible() -> bool:
	if not visible:
		return false
	return not is_instance_valid(_sprite) or _sprite.visible


## Va chiamata dal chiamante soltanto quando la run e' RUNNING (stesso
## principio degli altri tell): il nodo stesso non conosce il
## `RunController`.
func advance(delta: float) -> void:
	if not is_finite(delta) or delta <= 0.0 or _remaining <= 0.0:
		return
	_remaining = maxf(_remaining - delta, 0.0)
	if _remaining <= 0.0:
		visible = false
	queue_redraw()


func _draw() -> void:
	if not visible or _remaining <= 0.0:
		return
	if is_instance_valid(_sprite) and not _sprite.visible:
		return
	var total := PresentationTimings.THERMAL_TRANSITION_ANNOUNCE_SECONDS
	var elapsed := total - _remaining
	var alpha := PresentationTimings.one_shot_opacity(elapsed, total)
	var texture := HOT_TEXTURE if _hot else COLD_TEXTURE
	draw_texture_rect(
		texture,
		Rect2(ANCHOR_OFFSET - DISPLAY_SIZE * 0.5, DISPLAY_SIZE),
		false,
		Color(1.0, 1.0, 1.0, alpha)
	)
