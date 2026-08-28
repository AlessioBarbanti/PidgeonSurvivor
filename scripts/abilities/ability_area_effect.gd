class_name AbilityAreaEffect
extends Node2D

signal finished(effect: AbilityAreaEffect)
signal targets_affected(count: int)

enum AreaMode {
	PULSE_DAMAGE,
	FOLLOWING_PULSE_DAMAGE,
	GROUND_SLOW_DAMAGE,
	FOLLOWING_SLOW,
	## Guscio condiviso di Migi (B45): stessa logica di FOLLOWING_SLOW (il
	## rallentamento resta) piu' l'assorbimento dei proiettili ostili che
	## entrano nel raggio.
	FOLLOWING_SLOW_ABSORB,
}

const GRAND_SPIN_VISUAL_FAMILY_ID := &"grand_spin_rotating_arcs"
const CEMENT_VISUAL_FAMILY_ID := &"cement_pool_border_and_bubbles"
const ZEN_VISUAL_FAMILY_ID := &"zen_concentric_rings_and_motes"
const GRAND_SPIN_PARTICLE_COUNT := 12
const CEMENT_PARTICLE_COUNT := 10
const ZEN_PARTICLE_COUNT := 18
const VISUAL_MATERIAL_COUNT := 0

var _mode := AreaMode.PULSE_DAMAGE
var _definition: AbilityDefinition
var _run_controller: RunController
var _targeting_system: TargetingSystem
var _source: Node2D
var _duration_remaining := 0.0
var _duration_total := 0.0
var _tick_interval := INF
var _tick_remaining := 0.0
var _tick_damage := 0.0
var _slow_factor := 1.0
var _modifier_id: StringName
var _slowed_targets: Array[BaseEnemy] = []
var _effect_color := Color(1.0, 0.7, 0.2, 0.7)
var _finished := false


func initialize(
	mode: AreaMode,
	origin: Vector2,
	source: Node2D,
	definition: AbilityDefinition,
	run_controller: RunController,
	targeting_system: TargetingSystem,
	modifier_id: StringName,
	effect_color: Color
) -> bool:
	if (
		definition == null
		or not definition.is_valid()
		or definition.area_radius <= 0.0
		or definition.duration_seconds <= 0.0
		or not is_instance_valid(run_controller)
		or not run_controller.is_running()
		or not is_instance_valid(targeting_system)
	):
		return false
	_mode = mode
	_definition = definition
	_run_controller = run_controller
	_targeting_system = targeting_system
	_source = source
	global_position = origin
	_duration_total = definition.duration_seconds
	_duration_remaining = _duration_total
	_modifier_id = modifier_id
	_effect_color = effect_color
	_tick_damage = definition.damage
	match _mode:
		AreaMode.PULSE_DAMAGE, AreaMode.FOLLOWING_PULSE_DAMAGE:
			var hits_per_second := definition.get_effect_float(
				&"hits_per_second",
				1.0,
				AbilityDefinition.MINIMUM_POSITIVE_VALUE
			)
			_tick_interval = 1.0 / hits_per_second
		AreaMode.GROUND_SLOW_DAMAGE:
			_tick_interval = definition.get_effect_float(
				&"dot_tick",
				0.5,
				AbilityDefinition.MINIMUM_POSITIVE_VALUE
			)
			_slow_factor = definition.get_effect_float(
				&"slow_factor",
				1.0,
				AbilityDefinition.MINIMUM_POSITIVE_VALUE
			)
		AreaMode.FOLLOWING_SLOW, AreaMode.FOLLOWING_SLOW_ABSORB:
			_tick_interval = INF
			_tick_damage = 0.0
			_slow_factor = definition.get_effect_float(
				&"slow_factor",
				1.0,
				AbilityDefinition.MINIMUM_POSITIVE_VALUE
			)
	_refresh_slow_targets()
	if _tick_damage > 0.0:
		_apply_damage_tick()
	_tick_remaining = _tick_interval
	queue_redraw()
	return true


func _process(delta: float) -> void:
	if _finished or not is_instance_valid(_run_controller) or not _run_controller.is_running():
		return
	var safe_delta := maxf(delta, 0.0) if is_finite(delta) else 0.0
	if _follows_source():
		if not is_instance_valid(_source):
			_finish()
			return
		global_position = _source.global_position
	if _mode in [
		AreaMode.GROUND_SLOW_DAMAGE,
		AreaMode.FOLLOWING_SLOW,
		AreaMode.FOLLOWING_SLOW_ABSORB,
	]:
		_refresh_slow_targets()
	if _mode == AreaMode.FOLLOWING_SLOW_ABSORB:
		_absorb_projectiles()
	if is_finite(_tick_interval) and _tick_damage > 0.0:
		_tick_remaining -= safe_delta
		while _tick_remaining <= 0.0 and _duration_remaining > 0.0:
			_apply_damage_tick()
			_tick_remaining += _tick_interval
	_duration_remaining = maxf(_duration_remaining - safe_delta, 0.0)
	queue_redraw()
	if _duration_remaining <= 0.0:
		_finish()


func _draw() -> void:
	if _definition == null:
		return
	var progress := 1.0 - clampf(_duration_remaining / _duration_total, 0.0, 1.0)
	_draw_mode_pattern(progress)


func _draw_mode_pattern(progress: float) -> void:
	var radius := _definition.area_radius
	match _mode:
		AreaMode.PULSE_DAMAGE, AreaMode.FOLLOWING_PULSE_DAMAGE:
			_draw_grand_spin(radius, progress)
		AreaMode.GROUND_SLOW_DAMAGE:
			_draw_cement_pool(radius, progress)
		AreaMode.FOLLOWING_SLOW, AreaMode.FOLLOWING_SLOW_ABSORB:
			_draw_zen_field(radius, progress)


func _draw_grand_spin(radius: float, progress: float) -> void:
	var pulse := (sin(progress * TAU * 2.0) + 1.0) * 0.5
	draw_circle(Vector2.ZERO, radius, Color(0.55, 0.04, 0.34, 0.08 + pulse * 0.04))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(1.0, 0.34, 0.72, 0.86), 4.0, true)
	for arc_index in 4:
		var direction := -1.0 if arc_index % 2 == 0 else 1.0
		var start_angle := progress * TAU * direction + float(arc_index) * TAU * 0.25
		var arc_radius := radius * (0.42 + float(arc_index) * 0.13)
		var arc_color := Color(1.0, 0.28 + float(arc_index) * 0.1, 0.75, 0.78)
		draw_arc(Vector2.ZERO, arc_radius, start_angle, start_angle + 1.65, 24, arc_color, 6.0, true)
	for spark_index in GRAND_SPIN_PARTICLE_COUNT:
		var angle := progress * TAU * 2.0 + TAU * float(spark_index) / float(GRAND_SPIN_PARTICLE_COUNT)
		var spark_radius := radius * (0.5 + 0.38 * float((spark_index % 4) + 1) / 4.0)
		var spark_position := Vector2.RIGHT.rotated(angle) * spark_radius
		draw_circle(spark_position, 2.5 + float(spark_index % 2), Color(1.0, 0.86, 0.42, 0.8))


func _draw_cement_pool(radius: float, progress: float) -> void:
	var puddle_points := PackedVector2Array()
	for point_index in 32:
		var angle := TAU * float(point_index) / 32.0
		var wobble := 0.9 + 0.06 * sin(float(point_index) * 2.37)
		puddle_points.append(Vector2.RIGHT.rotated(angle) * radius * wobble)
	draw_colored_polygon(puddle_points, Color(0.2, 0.34, 0.38, 0.28))
	draw_polyline(puddle_points + PackedVector2Array([puddle_points[0]]), Color(0.56, 0.88, 0.9, 0.78), 5.0, true)
	for bubble_index in CEMENT_PARTICLE_COUNT:
		var angle := float(bubble_index) * 2.39996
		var orbit := radius * (0.18 + 0.055 * float(bubble_index))
		var bubble_position := Vector2.RIGHT.rotated(angle) * orbit
		var bubble_pulse := (sin(progress * TAU * 3.0 + float(bubble_index)) + 1.0) * 0.5
		draw_circle(bubble_position, 3.0 + bubble_pulse * 4.0, Color(0.68, 0.95, 0.94, 0.24), false, 2.0, true)


func _draw_zen_field(radius: float, progress: float) -> void:
	var breath := (sin(progress * TAU) + 1.0) * 0.5
	draw_circle(Vector2.ZERO, radius, Color(0.08, 0.4, 0.36, 0.08 + breath * 0.03))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(0.35, 0.94, 0.78, 0.76), 4.0, true)
	for ring_index in 4:
		var ring_radius := radius * (0.22 + float(ring_index) * 0.2) + breath * 4.0
		draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 48, Color(0.4, 0.9, 0.82, 0.22), 2.5, true)
	for mote_index in ZEN_PARTICLE_COUNT:
		var base_angle := TAU * float(mote_index) / float(ZEN_PARTICLE_COUNT)
		var drift_angle := base_angle - progress * 0.65
		var mote_radius := radius * (0.24 + 0.6 * float((mote_index % 6) + 1) / 6.0)
		var mote_position := Vector2.RIGHT.rotated(drift_angle) * mote_radius
		mote_position.y += sin(progress * TAU + float(mote_index)) * 5.0
		draw_circle(mote_position, 2.5, Color(0.72, 1.0, 0.88, 0.52))


func get_duration_remaining() -> float:
	return _duration_remaining


func get_mode() -> AreaMode:
	return _mode


func is_following_source() -> bool:
	return _follows_source()


func get_visual_family_id() -> StringName:
	match _mode:
		AreaMode.PULSE_DAMAGE, AreaMode.FOLLOWING_PULSE_DAMAGE:
			return GRAND_SPIN_VISUAL_FAMILY_ID
		AreaMode.GROUND_SLOW_DAMAGE:
			return CEMENT_VISUAL_FAMILY_ID
		AreaMode.FOLLOWING_SLOW, AreaMode.FOLLOWING_SLOW_ABSORB:
			return ZEN_VISUAL_FAMILY_ID
	return &""


func get_visual_particle_count() -> int:
	match _mode:
		AreaMode.PULSE_DAMAGE, AreaMode.FOLLOWING_PULSE_DAMAGE:
			return GRAND_SPIN_PARTICLE_COUNT
		AreaMode.GROUND_SLOW_DAMAGE:
			return CEMENT_PARTICLE_COUNT
		AreaMode.FOLLOWING_SLOW, AreaMode.FOLLOWING_SLOW_ABSORB:
			return ZEN_PARTICLE_COUNT
	return 0


func get_visual_material_count() -> int:
	return VISUAL_MATERIAL_COUNT


func get_visual_extent() -> float:
	return _definition.area_radius if _definition != null else 0.0


func uses_fullscreen_overlay() -> bool:
	return false


func _apply_damage_tick() -> void:
	var affected := 0
	for target in _targeting_system.get_alive_targets():
		if not AbilityEffectRegistry.is_point_within_radius(
			global_position,
			target.global_position,
			_definition.area_radius
		):
			continue
		if target.take_damage(_tick_damage):
			affected += 1
	targets_affected.emit(affected)


func _refresh_slow_targets() -> void:
	if _slow_factor >= 1.0 or _modifier_id.is_empty():
		return
	var inside: Array[BaseEnemy] = []
	for target in _targeting_system.get_alive_targets():
		if AbilityEffectRegistry.is_point_within_radius(
			global_position,
			target.global_position,
			_definition.area_radius
		):
			target.set_speed_modifier(_modifier_id, _slow_factor)
			inside.append(target)
	for target in _slowed_targets:
		if is_instance_valid(target) and not target in inside:
			target.remove_speed_modifier(_modifier_id)
	_slowed_targets = inside
	targets_affected.emit(_slowed_targets.size())


func _follows_source() -> bool:
	return _mode in [
		AreaMode.FOLLOWING_PULSE_DAMAGE,
		AreaMode.FOLLOWING_SLOW,
		AreaMode.FOLLOWING_SLOW_ABSORB,
	]


## Guscio condiviso di Migi: distrugge (invece di respingere) i proiettili
## ostili che entrano nel raggio, riusando il metodo pubblico e idempotente
## gia' esposto da BossProjectile per lo scadere naturale del proiettile.
func _absorb_projectiles() -> void:
	for node in get_tree().get_nodes_in_group(&"enemy_projectiles"):
		if not node is BossProjectile:
			continue
		var projectile := node as BossProjectile
		if projectile.is_spent():
			continue
		if not AbilityEffectRegistry.is_point_within_radius(
			global_position,
			projectile.global_position,
			_definition.area_radius
		):
			continue
		projectile.expire()


func _clear_slow_targets() -> void:
	for target in _slowed_targets:
		if is_instance_valid(target):
			target.remove_speed_modifier(_modifier_id)
	_slowed_targets.clear()


func _finish() -> void:
	if _finished:
		return
	_finished = true
	_clear_slow_targets()
	finished.emit(self)
	queue_free()


func _exit_tree() -> void:
	_clear_slow_targets()
