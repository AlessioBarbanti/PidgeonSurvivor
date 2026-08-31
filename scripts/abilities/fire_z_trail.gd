class_name FireZTrail
extends Node2D

signal finished(effect: FireZTrail)
signal targets_affected(count: int)

const VISUAL_FAMILY_ID := &"powerslide_ribbon_and_sparks"
const VISUAL_PARTICLE_COUNT := 16
const VISUAL_MATERIAL_COUNT := 0
const FIRE_TRAIL_TEXTURE := preload(
	"res://assets/art/vfx/abilities/generated/fire_trail.png"
)
## Passo fra due stampi, in frazioni di lato: sovrapposizione sufficiente a
## nascondere le estremita' rastremate senza moltiplicare i tasselli.
const STAMP_SPACING_RATIO := 0.72
## Opacita' del singolo tassello, tarata per la sovrapposizione qui sopra.
const STAMP_ALPHA := 0.62

var _source: Player
var _definition: AbilityDefinition
var _run_controller: RunController
var _targeting_system: TargetingSystem
var _path_points: PackedVector2Array = []
var _trail_width := 36.0
var _trail_duration_total := 0.0
var _trail_duration_remaining := 0.0
var _tick_interval := 0.25
var _tick_remaining := 0.0
var _finished := false


func initialize(
	source: Player,
	definition: AbilityDefinition,
	run_controller: RunController,
	targeting_system: TargetingSystem,
	arena_layout: ArenaLayout
) -> bool:
	if (
		not is_instance_valid(source)
		or definition == null
		or not definition.is_valid()
		or not is_instance_valid(run_controller)
		or not run_controller.is_running()
		or not is_instance_valid(targeting_system)
	):
		return false
	_source = source
	_definition = definition
	_run_controller = run_controller
	_targeting_system = targeting_system
	_trail_duration_total = definition.get_effect_float(
		&"trail_duration",
		definition.duration_seconds,
		AbilityDefinition.MINIMUM_POSITIVE_VALUE
	)
	_trail_duration_remaining = _trail_duration_total
	_tick_interval = definition.get_effect_float(
		&"trail_tick_interval",
		0.25,
		AbilityDefinition.MINIMUM_POSITIVE_VALUE
	)
	_trail_width = definition.get_effect_float(&"trail_width", 36.0, 1.0)
	_build_straight_path(source, definition, arena_layout)
	global_position = Vector2.ZERO
	_source.global_position = _path_points[-1]
	_grant_landing_invulnerability(definition)
	_apply_damage_tick()
	_tick_remaining = _tick_interval
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	queue_redraw()
	return true


func _process(delta: float) -> void:
	if _finished or not is_instance_valid(_run_controller) or not _run_controller.is_running():
		return
	if not is_instance_valid(_source) or not _source.is_alive():
		_finish_effect()
		return

	var safe_delta := maxf(delta, 0.0) if is_finite(delta) else 0.0
	_tick_remaining -= safe_delta
	while _tick_remaining <= 0.0 and _trail_duration_remaining > 0.0:
		_apply_damage_tick()
		_tick_remaining += _tick_interval
	_trail_duration_remaining = maxf(_trail_duration_remaining - safe_delta, 0.0)
	queue_redraw()
	if _trail_duration_remaining <= 0.0:
		_finish_effect()


func _draw() -> void:
	if _path_points.size() < 2 or _trail_duration_total <= 0.0:
		return
	var alpha := clampf(
		_trail_duration_remaining / _trail_duration_total,
		0.0,
		1.0
	)
	var origin := _path_points[0]
	var destination := _path_points[1]
	var direction := (destination - origin).normalized()
	var normal := direction.orthogonal()
	var path_length := origin.distance_to(destination)
	var stamp_size := maxf(_trail_width * 2.55, 64.0)
	var stamp_count := maxi(1, ceili(path_length / (stamp_size * STAMP_SPACING_RATIO)))
	var trail_angle := direction.angle()
	# Il master non e' raccordabile: gli stampi si sovrappongono per fondere le
	# estremita' rastremate, quindi l'alpha del singolo tassello resta bassa per
	# non accumularsi in grumi opachi, e le fiamme si specchiano a alternanza
	# per spezzare la ripetizione della stessa silhouette.
	for stamp_index in stamp_count + 1:
		var ratio := float(stamp_index) / float(stamp_count)
		var center := origin.lerp(destination, ratio)
		var mirror := -1.0 if stamp_index % 2 == 1 else 1.0
		draw_set_transform(center, trail_angle, Vector2(1.0, mirror))
		draw_texture_rect(
			FIRE_TRAIL_TEXTURE,
			Rect2(Vector2.ONE * stamp_size * -0.5, Vector2.ONE * stamp_size),
			false,
			Color(1.0, 1.0, 1.0, alpha * STAMP_ALPHA)
		)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var elapsed := maxf(_trail_duration_total - _trail_duration_remaining, 0.0)
	for spark_index in VISUAL_PARTICLE_COUNT:
		var ratio := (float(spark_index) + 0.5) / float(VISUAL_PARTICLE_COUNT)
		var phase := elapsed * 7.0 + float(spark_index) * 2.17
		var center := origin.lerp(destination, ratio)
		center += normal * sin(phase) * _trail_width * 0.42
		var spark_size := 2.0 + float(spark_index % 3)
		var spark_color := Color(1.0, 0.88, 0.36, alpha * (0.55 + 0.4 * sin(phase) ** 2))
		draw_colored_polygon(
			PackedVector2Array([
				center + direction * spark_size * 1.8,
				center + normal * spark_size,
				center - direction * spark_size * 1.8,
				center - normal * spark_size,
			]),
			spark_color
		)


func get_points() -> PackedVector2Array:
	return _path_points.duplicate()


func get_path_points() -> PackedVector2Array:
	return _path_points.duplicate()


func get_duration_remaining() -> float:
	return _trail_duration_remaining


func get_trail_duration_remaining() -> float:
	return _trail_duration_remaining


func get_visual_family_id() -> StringName:
	return VISUAL_FAMILY_ID


func get_visual_particle_count() -> int:
	return VISUAL_PARTICLE_COUNT


func get_visual_material_count() -> int:
	return VISUAL_MATERIAL_COUNT


func get_visual_texture_path() -> String:
	return FIRE_TRAIL_TEXTURE.resource_path


## Ancora visiva del Powerslide. Il nodo vive a `global_position` zero perche'
## il decal viene stampato direttamente lungo il segmento in coordinate mondo.
func get_visual_anchor_position() -> Vector2:
	if _path_points.is_empty():
		return global_position
	return _path_points[-1]


func get_visual_extent() -> float:
	return _trail_width * 0.5


func uses_fullscreen_overlay() -> bool:
	return false


func _build_straight_path(
	source: Player,
	definition: AbilityDefinition,
	arena_layout: ArenaLayout
) -> void:
	var dash_distance := definition.get_effect_float(&"dash_distance", 320.0, 1.0)
	var direction := source.get_last_movement_direction()
	if direction.is_zero_approx():
		direction = Vector2.RIGHT
	direction = direction.normalized()
	var origin := source.global_position
	var desired_end := origin + direction * dash_distance
	# Il confinamento va chiesto al Player: i suoi limiti sono quelli di
	# ArenaWorld in coordinate di mondo, mentre il playfield di ArenaLayout
	# vive in coordinate di schermo. Usare ArenaLayout qui schiacciava la
	# destinazione verso l'angolo alto-sinistro del mondo, annullando di
	# fatto lo scatto ovunque tranne che al centro dell'arena.
	var actual_end := source.confine_world_point(desired_end)
	if is_instance_valid(arena_layout) and actual_end == desired_end and not source.get_world_bounds().has_area():
		actual_end = arena_layout.clamp_circle_center(desired_end, source.collision_radius)
	_path_points = PackedVector2Array([origin, actual_end])


## PS-040: protegge l'atterraggio, il momento piu' rischioso dello scatto
## (Bea si teletrasporta senza preavviso per il nemico, potenzialmente vicino
## a un bersaglio). Zero o assente disabilita senza errori; usa lo stesso
## meccanismo "prendi il massimo" del Sesto Senso Equino, quindi non si somma
## ad altre fonti di invulnerabilita' gia' attive.
func _grant_landing_invulnerability(definition: AbilityDefinition) -> void:
	var iframe_duration := definition.get_effect_float(&"iframe_duration", 0.0, 0.0)
	if iframe_duration <= 0.0:
		return
	var health := _source.get_health_component()
	if is_instance_valid(health):
		health.grant_invulnerability(iframe_duration)


func _finish_effect() -> void:
	if _finished:
		return
	_finished = true
	finished.emit(self)
	queue_free()


func _apply_damage_tick() -> void:
	var affected := 0
	for target in _targeting_system.get_alive_targets():
		if not _is_point_near_trail(target.global_position):
			continue
		if target.take_damage(_definition.damage):
			affected += 1
	targets_affected.emit(affected)


func _is_point_near_trail(point: Vector2) -> bool:
	if _path_points.size() < 2:
		return false
	return Geometry2D.get_closest_point_to_segment(
		point,
		_path_points[0],
		_path_points[1]
	).distance_to(point) <= _trail_width * 0.5
