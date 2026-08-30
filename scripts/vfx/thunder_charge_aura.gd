class_name ThunderChargeAura
extends Node2D

## Aura orbitante di Zat (PS-004): tell persistente della fascia di carica di
## Guarigione Ritardata, e allo stesso tempo preavviso della potenza del
## prossimo Tempesta di Tuoni.
##
## E' puramente presentazionale: nessuna Area2D, nessuna collisione, nessun
## effetto di gameplay. Fascia e velocita' di rotazione arrivano dall'esterno
## (`FriendPassiveController`, che legge i dati di Zat); qui si disegna
## soltanto quanto viene impostato.

const TIER_LOW := 0
const TIER_MEDIUM := 1
const TIER_HIGH := 2

const BOLT_COUNTS := {
	TIER_LOW: 1,
	TIER_MEDIUM: 2,
	TIER_HIGH: 3,
}
const BOLT_COLORS := {
	TIER_LOW: Color(0.36, 1.0, 0.48, 1.0),
	TIER_MEDIUM: Color(1.0, 0.86, 0.24, 1.0),
	TIER_HIGH: Color(1.0, 0.28, 0.24, 1.0),
}
const ORBIT_RADIUS := 34.0
const BOLT_LENGTH := 15.0
const BOLT_WIDTH := 3.0
const CORE_RADIUS := 3.5

var _tier := TIER_LOW
var _rotation_speed := 0.0
var _angle := 0.0


func set_tier(tier: int) -> bool:
	var clamped := clampi(tier, TIER_LOW, TIER_HIGH)
	if clamped == _tier:
		return true
	_tier = clamped
	queue_redraw()
	return true


func get_tier() -> int:
	return _tier


func set_rotation_speed(value: float) -> void:
	var safe_value := value if is_finite(value) else 0.0
	_rotation_speed = maxf(safe_value, 0.0)


func get_rotation_speed() -> float:
	return _rotation_speed


## Avanza la rotazione. Va chiamata dal chiamante soltanto quando la run e'
## `RUNNING`: l'aura stessa non conosce il `RunController`.
func advance(delta: float) -> void:
	if not is_finite(delta) or delta <= 0.0 or _rotation_speed <= 0.0:
		return
	_angle = wrapf(_angle + _rotation_speed * delta, 0.0, TAU)
	queue_redraw()


func get_angle() -> float:
	return _angle


func set_presented(value: bool) -> void:
	if visible == value:
		return
	visible = value
	queue_redraw()


func is_presented() -> bool:
	return visible


func get_bolt_count() -> int:
	return BOLT_COUNTS.get(_tier, 1)


func get_bolt_color() -> Color:
	return BOLT_COLORS.get(_tier, BOLT_COLORS[TIER_LOW])


func _draw() -> void:
	var count := get_bolt_count()
	var color := get_bolt_color()
	for index in count:
		var bolt_angle := _angle + TAU * float(index) / float(count)
		var direction := Vector2.RIGHT.rotated(bolt_angle)
		var tangent := direction.orthogonal()
		var center := direction * ORBIT_RADIUS
		draw_line(
			center - tangent * BOLT_LENGTH * 0.5,
			center + tangent * BOLT_LENGTH * 0.5,
			color,
			BOLT_WIDTH,
			true
		)
		draw_circle(center, CORE_RADIUS, color)
