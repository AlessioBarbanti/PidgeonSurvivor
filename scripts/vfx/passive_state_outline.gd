class_name PassiveStateOutline
extends Node2D

## Tell di stato delle passive (PS-001): contorno colorato attorno alla sagoma
## del personaggio, disegnato dietro allo sprite.
##
## Sostituisce la tinta piena introdotta da B44, che moltiplicava ogni pixel
## dello sprite tramite `self_modulate` e quindi ridipingeva il personaggio:
## Alea in fase positiva diventava tutta verde. Il difetto non era la scelta dei
## colori ma il canale. Qui il colore si aggiunge accanto al personaggio invece
## di sostituirlo, e la fase resta leggibile a colpo d'occhio.
##
## Vive come figlio di `CharacterSprite` per ereditarne posizione, rotazione e
## scala. `flip_h`/`flip_v` non sono trasformazioni ma flag di disegno, quindi
## non si propagano ai figli e vanno letti dallo sprite a ogni `_draw()`.

## Otto direzioni: le quattro diagonali evitano gli angoli scoperti che un
## contorno a sole quattro direzioni lascia sulle sagome oblique.
const OFFSET_DIRECTIONS: Array[Vector2] = [
	Vector2(1.0, 0.0),
	Vector2(-1.0, 0.0),
	Vector2(0.0, 1.0),
	Vector2(0.0, -1.0),
	Vector2(0.70710678, 0.70710678),
	Vector2(-0.70710678, 0.70710678),
	Vector2(0.70710678, -0.70710678),
	Vector2(-0.70710678, -0.70710678),
]

## Spessore in unita' locali dello sprite. Lo sprite del cast e' gia' scalato
## (scena `1,65` per `visual_scale_multiplier`), quindi il contorno cresce con
## il personaggio invece di assottigliarsi.
@export_range(0.5, 8.0, 0.1) var thickness := 4.0:
	set(value):
		thickness = clampf(value, 0.5, 8.0) if is_finite(value) else 4.0
		queue_redraw()

## Spessore aggiuntivo di un bordo di separazione scuro, disegnato piu'
## esterno e sotto al colore di stato (PS-029). Contro sfondi arena, orde
## dense o nemici dai colori simili al tell, la sola tinta satura puo'
## mimetizzarsi; il bordo scuro crea un margine di contrasto indipendente
## dalla combinazione cromatica di sfondo e stato. Valori alzati oltre la
## prima stima dopo segnalazione diretta del proprietario: la sagoma restava
## sottile soprattutto su schermo Android.
@export_range(0.0, 4.0, 0.1) var separator_thickness := 2.0:
	set(value):
		separator_thickness = clampf(value, 0.0, 4.0) if is_finite(value) else 2.0
		queue_redraw()

const SEPARATOR_COLOR := Color(0.04, 0.03, 0.07, 1.0)

var _color := Color(0.0, 0.0, 0.0, 0.0)
var _sprite: Sprite2D
var _last_texture: Texture2D
var _last_flip_h := false
var _last_flip_v := false
var _last_sprite_visible := false


func _ready() -> void:
	show_behind_parent = true
	_sprite = get_parent() as Sprite2D
	_sync_sprite_snapshot()
	queue_redraw()


func _process(_delta: float) -> void:
	# Lo sprite cambia texture a ogni frame di camminata e flip a ogni
	# inversione di direzione. Il contorno si risincronizza da se' invece di
	# dipendere dal fatto che ogni punto di chiamata del Player si ricordi di
	# avvisarlo.
	if not is_instance_valid(_sprite):
		return
	if not _sync_sprite_snapshot():
		return
	queue_redraw()


## Restituisce `true` quando qualcosa di rilevante per il disegno e' cambiato.
func _sync_sprite_snapshot() -> bool:
	if not is_instance_valid(_sprite):
		return false
	var changed := (
		_sprite.texture != _last_texture
		or _sprite.flip_h != _last_flip_h
		or _sprite.flip_v != _last_flip_v
		or _sprite.visible != _last_sprite_visible
	)
	_last_texture = _sprite.texture
	_last_flip_h = _sprite.flip_h
	_last_flip_v = _sprite.flip_v
	_last_sprite_visible = _sprite.visible
	return changed


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
## soltanto quando la run e' effettivamente in corso.
func set_state_presented(value: bool) -> void:
	if visible == value:
		return
	visible = value
	queue_redraw()


func is_state_presented() -> bool:
	return visible and has_state_color()


func _draw() -> void:
	if not has_state_color() or not is_instance_valid(_sprite):
		return
	# Il contorno segue lo sprite anche nel lampeggio da danno: se il
	# personaggio non e' disegnato, non lo e' nemmeno il suo bordo.
	if not _sprite.visible:
		return
	var texture := _sprite.texture
	if texture == null:
		return

	var size := texture.get_size()
	var top_left := _sprite.offset
	if _sprite.centered:
		top_left -= size * 0.5
	var flip_scale := Vector2(
		-1.0 if _sprite.flip_h else 1.0,
		-1.0 if _sprite.flip_v else 1.0
	)
	# Bordo di separazione scuro, piu' esterno: garantisce contrasto contro
	# qualunque sfondo prima ancora che intervenga il colore di stato.
	if separator_thickness > 0.0:
		var separator_reach := thickness + separator_thickness
		for direction in OFFSET_DIRECTIONS:
			draw_set_transform(direction * separator_reach, 0.0, flip_scale)
			draw_texture(texture, top_left, SEPARATOR_COLOR)
	for direction in OFFSET_DIRECTIONS:
		draw_set_transform(direction * thickness, 0.0, flip_scale)
		draw_texture(texture, top_left, _color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
