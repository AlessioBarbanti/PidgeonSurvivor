class_name ArenaWorld
extends Node

## Dimensione fissa dell'arena in unita' di mondo, indipendente dal viewport:
## la Camera2D mostra soltanto una finestra scorrevole al suo interno.
@export var world_size := Vector2(2400.0, 1500.0):
	set(value):
		world_size = Vector2(maxf(value.x, 1.0), maxf(value.y, 1.0))

## Centro dell'arena in unita' di mondo; il Player e la Camera2D partono qui.
@export var world_origin := Vector2.ZERO


func get_world_rect() -> Rect2:
	return Rect2(world_origin - world_size * 0.5, world_size)


func get_world_center() -> Vector2:
	return world_origin


## Utilita' pura riusabile da Player, dropper dei pickup e futuri consumer:
## confina un cerchio dentro un rettangolo qualsiasi senza dipendere da stato
## di istanza, cosi' ArenaLayout resta invariato per il suo ruolo di
## safe-area/HUD.
static func clamp_circle_center_in_rect(
	rect: Rect2,
	point: Vector2,
	radius: float
) -> Vector2:
	if not rect.has_area():
		return point

	var safe_radius := maxf(radius, 0.0)
	var minimum := rect.position + Vector2.ONE * safe_radius
	var maximum := rect.end - Vector2.ONE * safe_radius
	var center := rect.get_center()

	if minimum.x > maximum.x:
		minimum.x = center.x
		maximum.x = center.x
	if minimum.y > maximum.y:
		minimum.y = center.y
		maximum.y = center.y

	return Vector2(
		clampf(point.x, minimum.x, maximum.x),
		clampf(point.y, minimum.y, maximum.y)
	)


## Spinge un cerchio fuori da un rettangolo riservato (B52: l'ingombro
## runtime di un controllo HUD nel suo angolo). Se il centro cade nel
## rettangolo cresciuto del raggio, lo sposta sul bordo piu' vicino lungo
## l'asse di minima penetrazione, cosi' il cerchio resta appena fuori invece
## di essere teletrasportato altrove.
static func push_circle_outside_rect(
	point: Vector2,
	radius: float,
	reserved_rect: Rect2
) -> Vector2:
	if not reserved_rect.has_area():
		return point
	var inflated := reserved_rect.grow(maxf(radius, 0.0))
	if not inflated.has_point(point):
		return point

	var push_left := point.x - inflated.position.x
	var push_right := inflated.end.x - point.x
	var push_up := point.y - inflated.position.y
	var push_down := inflated.end.y - point.y
	var minimum_push := minf(minf(push_left, push_right), minf(push_up, push_down))

	if minimum_push == push_left:
		return Vector2(inflated.position.x, point.y)
	if minimum_push == push_right:
		return Vector2(inflated.end.x, point.y)
	if minimum_push == push_up:
		return Vector2(point.x, inflated.position.y)
	return Vector2(point.x, inflated.end.y)
