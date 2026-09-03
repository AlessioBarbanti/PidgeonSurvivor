class_name PassiveStateParticles
extends Node2D

## Tell particellare di stato delle passive a fasi (PS-079): piccole
## particelle non aderenti che si sollevano/orbitano sopra la testa del
## personaggio invece di ricalcarne il profilo.
##
## Sostituisce PassiveStateOutline (PS-001/PS-029), un contorno colorato
## attorno alla sagoma che il proprietario ha bocciato per rottura della
## silhouette pixel-art (vedi Decisioni di PS-079). Il colore continua ad
## arrivare da fuori (`FriendPassiveController`) con lo stesso significato di
## fase: qui cambia solo il canale, non cosa comunica.
##
## Vive come fratello di `CharacterSprite`, non figlio: l'offset verticale
## fisso lo tiene sempre staccato dalla sagoma per costruzione, qualunque
## siano texture, flip o frame di camminata correnti.

const PARTICLE_COUNT := 5
## Centro dell'orbita: abbastanza sopra la testa da restare fuori dal
## riquadro 32x32 del cast (mezza diagonale ~46.7 unita' alla scala fissa
## 1.65 x 1.25 del Player) anche al massimo dell'escursione verticale.
const HEAD_OFFSET := Vector2(0.0, -48.0)
const ORBIT_RADIUS := 12.0
const ORBIT_RADIUS_JITTER := 3.0
const ORBIT_VERTICAL_SCALE := 0.3
const ORBIT_SPEED := 1.3
const BOB_AMPLITUDE := 4.0
const BOB_SPEED := 2.6
const PARTICLE_DRAW_RADIUS := 2.75

var _color := Color(0.0, 0.0, 0.0, 0.0)
var _angle := 0.0
var _sprite: Sprite2D


func _ready() -> void:
	_sprite = get_parent().get_node_or_null(^"CharacterSprite") as Sprite2D


func set_state_color(value: Color) -> bool:
	if not is_finite(value.r) or not is_finite(value.g) or not is_finite(value.b):
		return false
	var opaque := Color(value.r, value.g, value.b, 1.0)
	if opaque == _color:
		return true
	_color = opaque
	queue_redraw()
	return true


func clear_state_color() -> void:
	if not has_state_color():
		return
	_color = Color(0.0, 0.0, 0.0, 0.0)
	queue_redraw()


func get_state_color() -> Color:
	return _color


func has_state_color() -> bool:
	return _color.a > 0.0


## Il colore resta memorizzato durante i modali, ma il tell viene presentato
## soltanto quando la run e' effettivamente in corso (stesso principio di
## PassiveStateOutline).
func set_state_presented(value: bool) -> void:
	if visible == value:
		return
	visible = value
	queue_redraw()


func is_state_presented() -> bool:
	return visible and has_state_color()


## Osservabilita' per lo smoke PS-079: a differenza di `is_state_presented()`
## (che riflette solo RUNNING/pausa), tiene conto anche del lampeggio da
## invulnerabilita', cosi' il test puo' verificare che il flash da danno
## mantenga davvero la precedenza sul tell senza dover leggere pixel.
func is_effectively_visible() -> bool:
	if not is_state_presented():
		return false
	return not is_instance_valid(_sprite) or _sprite.visible


## Va chiamata dal chiamante soltanto quando la run e' RUNNING (stesso
## principio di ThunderChargeAura): il nodo stesso non conosce il
## RunController.
func advance(delta: float) -> void:
	if not is_finite(delta) or delta <= 0.0 or not has_state_color():
		return
	_angle = wrapf(_angle + ORBIT_SPEED * delta, 0.0, TAU)
	queue_redraw()


## Osservabilita' per lo smoke PS-079: espone l'angolo di orbita cosi' il
## test puo' verificare che avanzi solo mentre la run e' RUNNING, stesso
## principio di `ThunderChargeAura.get_angle()`.
func get_orbit_angle() -> float:
	return _angle


func _draw() -> void:
	if not has_state_color():
		return
	# Il flash da danno mantiene la precedenza sul tell di stato (PS-001): se
	# il personaggio non e' disegnato (lampeggio da invulnerabilita'), nemmeno
	# le sue particelle lo sono.
	if is_instance_valid(_sprite) and not _sprite.visible:
		return
	for index in PARTICLE_COUNT:
		var phase := TAU * float(index) / float(PARTICLE_COUNT)
		var particle_angle := _angle + phase
		var radius := ORBIT_RADIUS + sin(_angle * 1.7 + phase * 2.0) * ORBIT_RADIUS_JITTER
		var bob := sin(_angle * BOB_SPEED + phase * 2.3) * BOB_AMPLITUDE
		var offset := Vector2(
			cos(particle_angle) * radius,
			sin(particle_angle) * radius * ORBIT_VERTICAL_SCALE + bob
		)
		draw_circle(HEAD_OFFSET + offset, PARTICLE_DRAW_RADIUS, _color)
