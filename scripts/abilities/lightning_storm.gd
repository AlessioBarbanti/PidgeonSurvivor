class_name ThunderStorm
extends Node2D

## Tempesta di Tuoni (PS-004).
##
## Non e' piu' una sequenza di fulmini telegrafati su posizioni fisse
## nell'arena: all'attivazione fotografa i nemici vivi in quel momento e, dopo
## un breve preavviso, li colpisce tutti con un'unica istanza di danno. Il
## danno per bersaglio dipende dalla fascia di carica di Guarigione Ritardata
## al momento dell'attivazione (bassa/media/alta, risolta dal chiamante e
## passata a `initialize`): la Tempesta legge la fascia, non la consuma.
##
## Nemici comparsi dopo lo snapshot non vengono colpiti, anche se entrano
## nell'area prima della risoluzione del colpo.

signal finished(effect: ThunderStorm)
signal targets_affected(count: int)
signal impact_started()

enum Phase {
	WARNING,
	STRIKE,
	FINISHED,
}

const DEFAULT_WARNING_SECONDS := 0.35
const DEFAULT_TOTAL_DURATION := 0.85
const DEFAULT_DECAL_RADIUS := 46.0
const DEFAULT_TIER_MULTIPLIERS := {
	ThunderChargeAura.TIER_LOW: 1.0,
	ThunderChargeAura.TIER_MEDIUM: 2.0,
	ThunderChargeAura.TIER_HIGH: 3.0,
}
const TIER_MULTIPLIER_KEYS := {
	ThunderChargeAura.TIER_LOW: &"tier_multiplier_low",
	ThunderChargeAura.TIER_MEDIUM: &"tier_multiplier_medium",
	ThunderChargeAura.TIER_HIGH: &"tier_multiplier_high",
}
const VISUAL_FAMILY_ID := &"thunder_cloud_warning_and_waves"
const VISUAL_PARTICLE_COUNT := 0
const VISUAL_MATERIAL_COUNT := 0
const LIGHTNING_IMPACT_TEXTURE := preload(
	"res://assets/art/vfx/abilities/generated/lightning_impact.png"
)
## Il decal elettrico riempie il quadrato fino agli angoli, mentre il tell e'
## circolare: inscrivendolo nel cerchio la diagonale non eccede il raggio.
const INSCRIBED_DECAL_SCALE := 0.70710678

var _definition: AbilityDefinition
var _run_controller: RunController
var _tier := ThunderChargeAura.TIER_LOW
var _phase := Phase.WARNING
var _elapsed := 0.0
var _warning_seconds := DEFAULT_WARNING_SECONDS
var _total_duration := DEFAULT_TOTAL_DURATION
var _decal_radius := DEFAULT_DECAL_RADIUS
var _per_target_damage := 0.0
var _snapshot_targets: Array[BaseEnemy] = []
var _impact_positions := PackedVector2Array()
var _affected_count := 0
var _impacted_target_ids: Array[int] = []


func initialize(
	origin: Vector2,
	definition: AbilityDefinition,
	run_controller: RunController,
	targeting_system: TargetingSystem,
	tier: int
) -> bool:
	if (
		definition == null
		or not definition.is_valid()
		or not is_instance_valid(run_controller)
		or not run_controller.is_running()
		or not is_instance_valid(targeting_system)
	):
		return false
	_definition = definition
	_run_controller = run_controller
	_tier = clampi(tier, ThunderChargeAura.TIER_LOW, ThunderChargeAura.TIER_HIGH)
	global_position = origin if origin.is_finite() else Vector2.ZERO
	_warning_seconds = _definition.get_effect_float(
		&"warning_seconds",
		DEFAULT_WARNING_SECONDS,
		0.0
	)
	_total_duration = _definition.duration_seconds
	if not is_finite(_total_duration) or _total_duration <= _warning_seconds:
		_total_duration = _warning_seconds + DEFAULT_TOTAL_DURATION
	_decal_radius = resolve_decal_radius(_definition)
	var multiplier := _definition.get_effect_float(
		TIER_MULTIPLIER_KEYS.get(_tier, &"tier_multiplier_low"),
		DEFAULT_TIER_MULTIPLIERS.get(_tier, 1.0),
		0.0
	)
	_per_target_damage = _definition.damage * multiplier
	_snapshot_targets.assign(targeting_system.get_alive_targets())
	_phase = Phase.WARNING
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	queue_redraw()
	return true


func _process(delta: float) -> void:
	if (
		_phase == Phase.FINISHED
		or not is_instance_valid(_run_controller)
		or not _run_controller.is_running()
	):
		return
	_elapsed += maxf(delta, 0.0) if is_finite(delta) else 0.0
	if _phase == Phase.WARNING and _elapsed >= _warning_seconds:
		_resolve_strike()
	queue_redraw()
	if _elapsed >= _total_duration:
		_finish()


func _draw() -> void:
	if _phase == Phase.FINISHED:
		return
	var color := get_tier_color()
	if _phase == Phase.WARNING:
		var progress := clampf(_elapsed / maxf(_warning_seconds, 0.001), 0.0, 1.0)
		for target in _snapshot_targets:
			if is_instance_valid(target):
				_draw_telegraph(to_local(target.global_position), progress, color)
	else:
		var afterglow_seconds := maxf(_total_duration - _warning_seconds, 0.001)
		var age := _elapsed - _warning_seconds
		var fade := 1.0 - clampf(age / afterglow_seconds, 0.0, 1.0)
		if fade <= 0.0:
			return
		for position in _impact_positions:
			_draw_impact(to_local(position), fade, color)


func get_phase() -> Phase:
	return _phase


func get_elapsed() -> float:
	return _elapsed


func get_total_duration() -> float:
	return _total_duration


func get_tier() -> int:
	return _tier


func get_tier_color() -> Color:
	return ThunderChargeAura.BOLT_COLORS.get(_tier, ThunderChargeAura.BOLT_COLORS[ThunderChargeAura.TIER_LOW])


func get_per_target_damage() -> float:
	return _per_target_damage


func get_snapshot_count() -> int:
	return _snapshot_targets.size()


func get_decal_radius() -> float:
	return _decal_radius


func get_visual_extent() -> float:
	return _decal_radius


func get_affected_count() -> int:
	return _affected_count


func has_impacted() -> bool:
	return _phase != Phase.WARNING


func get_impacted_target_ids() -> Array[int]:
	return _impacted_target_ids.duplicate()


func get_visual_family_id() -> StringName:
	return VISUAL_FAMILY_ID


func get_visual_particle_count() -> int:
	return VISUAL_PARTICLE_COUNT


func get_visual_material_count() -> int:
	return VISUAL_MATERIAL_COUNT


func get_visual_texture_path() -> String:
	return LIGHTNING_IMPACT_TEXTURE.resource_path


func uses_fullscreen_overlay() -> bool:
	return false


static func resolve_decal_radius(definition: AbilityDefinition) -> float:
	if definition == null:
		return DEFAULT_DECAL_RADIUS
	var declared := definition.area_radius
	if not is_finite(declared) or declared <= 0.0:
		declared = DEFAULT_DECAL_RADIUS
	return declared


## Fotografa i bersagli vivi al momento dell'attivazione e li colpisce tutti
## con un'unica istanza di danno. Un nemico morto fra lo snapshot e la
## risoluzione (o comparso dopo) non viene conteggiato: lo snapshot non viene
## mai ricalcolato.
func _resolve_strike() -> void:
	_phase = Phase.STRIKE
	impact_started.emit()
	var hit_count := 0
	var resolved_ids: Array[int] = []
	for target in _snapshot_targets:
		if not is_instance_valid(target) or not target.is_alive():
			continue
		var health := target.get_health_component()
		if health == null or not health.is_alive():
			continue
		var target_id := target.get_instance_id()
		if target_id in resolved_ids:
			continue
		resolved_ids.append(target_id)
		_impacted_target_ids.append(target_id)
		_impact_positions.append(target.global_position)
		if target.take_damage(_per_target_damage):
			hit_count += 1
	_affected_count = hit_count
	targets_affected.emit(_affected_count)


func _draw_telegraph(center: Vector2, progress: float, color: Color) -> void:
	var cross_size := lerpf(15.0, 6.0, progress)
	var telegraph_color := Color(color.r, color.g, color.b, 0.35 + progress * 0.45)
	draw_line(center - Vector2(cross_size, 0.0), center + Vector2(cross_size, 0.0), telegraph_color, 3.0, true)
	draw_line(center - Vector2(0.0, cross_size), center + Vector2(0.0, cross_size), telegraph_color, 3.0, true)


func _draw_impact(center: Vector2, fade: float, color: Color) -> void:
	var decal_size := Vector2.ONE * _decal_radius * 2.0 * INSCRIBED_DECAL_SCALE
	draw_texture_rect(
		LIGHTNING_IMPACT_TEXTURE,
		Rect2(center - decal_size * 0.5, decal_size),
		false,
		Color(color.r, color.g, color.b, fade * 0.9)
	)


func _finish() -> void:
	if _phase == Phase.FINISHED:
		return
	_phase = Phase.FINISHED
	queue_redraw()
	finished.emit(self)
	queue_free()
