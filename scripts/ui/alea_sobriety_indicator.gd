class_name AleaSobrietyIndicator
extends Control

## PS-138: sostituisce il precedente `TextureProgressBar` (vetro+vino
## mascherato verticalmente), che disegnava le texture 128x128 di PS-104 alla
## loro risoluzione nativa invece di scalarle al riquadro assegnato in HUD
## (bug di scala verificato con cattura reale: la coppa sconfinava sopra la
## barra XP pur avendo un rect logico non sovrapposto). `_draw()` qui sotto
## scala sempre esplicitamente al `size` del nodo, coerente col pattern già
## in uso da `TouchAbilityButton`/`PixelArcadeMedallion` per anelli e cornici
## procedurali — nessuno shader, nessun nuovo asset raster.

## Fascia verticale della coppa nel canvas sorgente 128x128 di
## `alea_sobriety_glass_empty.png` (misurata pixel-per-pixel dal
## game-art-designer in pianificazione, PS-109): dal rim (y~5) al collo dove
## inizia lo stelo (y~72), centrata su x=64. Espressa come frazione 0..1 del
## lato del canvas così resta valida a qualunque dimensione di resa.
const COPPA_CENTER_Y_FRACTION := 39.0 / 128.0
const COPPA_RADIUS_FRACTION := 46.0 / 128.0
const RING_SEGMENTS := 40
const RING_WIDTH := 4.0
## Stesso oro/bronzo già presente nei bordi del master di PS-104 (campionato
## dal game-art-designer): l'anello scalda la propria tinta lungo la stessa
## rampa, non introduce un colore nuovo.
const RING_BRONZE := Color(0xA6 / 255.0, 0x7B / 255.0, 0x35 / 255.0, 1.0)
const RING_GOLD := Color(0xF4 / 255.0, 0xBC / 255.0, 0x55 / 255.0, 1.0)
const RING_TRACK_COLOR := Color(0xA6 / 255.0, 0x7B / 255.0, 0x35 / 255.0, 0.32)
const GLOW_COLOR := Color(0xF4 / 255.0, 0xBC / 255.0, 0x55 / 255.0, 1.0)
const GLOW_LAYERS := 3
const GLOW_MAX_ALPHA := 0.30
const BRILLA_GLASS_TINT := Color(1.28, 1.2, 0.95, 1.0)

@export var glass_texture: Texture2D:
	set(value):
		glass_texture = value
		queue_redraw()
@export var wine_texture: Texture2D:
	set(value):
		wine_texture = value
		queue_redraw()

var _charge_ratio := 0.0
var _brilla_active := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func set_charge_ratio(value: float) -> void:
	var clamped := clampf(value, 0.0, 1.0)
	if is_equal_approx(clamped, _charge_ratio):
		return
	_charge_ratio = clamped
	queue_redraw()


func get_charge_ratio() -> float:
	return _charge_ratio


func set_brilla_active(active: bool) -> void:
	if active == _brilla_active:
		return
	_brilla_active = active
	queue_redraw()


func is_brilla_active() -> bool:
	return _brilla_active


func _draw() -> void:
	if glass_texture == null:
		return
	var rect := Rect2(Vector2.ZERO, size)
	if _brilla_active:
		_draw_brilla_glow()
	draw_texture_rect(glass_texture, rect, false, BRILLA_GLASS_TINT if _brilla_active else Color.WHITE)
	if _charge_ratio > 0.0 and wine_texture != null:
		_draw_wine_fill(rect)
	_draw_charge_ring()


## Riempimento dal basso identico a `TextureProgressBar.fill_mode = 3`
## (FILL_BOTTOM_TO_TOP): solo la frazione inferiore della texture sorgente,
## disegnata nella corrispondente frazione inferiore del riquadro.
func _draw_wine_fill(rect: Rect2) -> void:
	var texture_size := wine_texture.get_size()
	var source_height := texture_size.y * _charge_ratio
	var source_rect := Rect2(
		0.0, texture_size.y - source_height, texture_size.x, source_height
	)
	var dest_height := rect.size.y * _charge_ratio
	var dest_rect := Rect2(
		rect.position.x, rect.position.y + rect.size.y - dest_height, rect.size.x, dest_height
	)
	draw_texture_rect_region(wine_texture, dest_rect, source_rect)


func _coppa_center() -> Vector2:
	return Vector2(size.x * 0.5, size.y * COPPA_CENTER_Y_FRACTION)


func _coppa_radius() -> float:
	return size.x * COPPA_RADIUS_FRACTION


## Segnale primario del "quanto manca": traccia sempre visibile + arco che
## avanza in senso orario dal colore bronzo spento (vuoto) all'oro vivo
## (pronto), scaldandosi con `_charge_ratio`. In Brilla l'arco resta pieno e
## oro vivo (enfatizzato), ma il segnale primario dello stato attivo resta il
## glow del calice, non l'anello.
func _draw_charge_ring() -> void:
	var center := _coppa_center()
	var radius := _coppa_radius()
	draw_arc(center, radius, -PI * 0.5, PI * 1.5, RING_SEGMENTS, RING_TRACK_COLOR, RING_WIDTH, true)
	if _brilla_active:
		draw_arc(center, radius, -PI * 0.5, PI * 1.5, RING_SEGMENTS, RING_GOLD, RING_WIDTH, true)
		return
	if _charge_ratio <= 0.001:
		return
	var fill_color := RING_BRONZE.lerp(RING_GOLD, _charge_ratio)
	draw_arc(
		center, radius, -PI * 0.5, -PI * 0.5 + TAU * _charge_ratio, RING_SEGMENTS, fill_color,
		RING_WIDTH, true
	)


## Alone morbido dietro al vetro: alcuni cerchi concentrici a bassa opacità
## decrescente, nessuno shader. Disegnato prima del vetro perché resti
## dietro alla silhouette invece di coprirla.
func _draw_brilla_glow() -> void:
	var center := _coppa_center()
	var base_radius := _coppa_radius()
	for layer_index in GLOW_LAYERS:
		var t := float(layer_index) / float(GLOW_LAYERS)
		var glow_radius := base_radius * (1.35 + t * 0.85)
		var alpha := GLOW_MAX_ALPHA * (1.0 - t)
		draw_circle(center, glow_radius, Color(GLOW_COLOR.r, GLOW_COLOR.g, GLOW_COLOR.b, alpha))
