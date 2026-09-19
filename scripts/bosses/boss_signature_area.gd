class_name BossSignatureArea
extends Node2D

## Area persistente lasciata da una Signature Evil (PS-006).
##
## Un solo nodo copre tutte le forme dichiarate da `BossSignatureRegistry`: il
## fronte tellurico di Magno, la scia di Bea, l'aura rotante di Alea, lo Shock
## Termico di Aleo, la zona Zen di Migi e il Tuono di Zat. Il bersaglio e'
## sempre e solo il `Player`: nessuna Signature tocca i nemici comuni.
##
## L'area avanza soltanto mentre la run e' `RUNNING`; pausa, Boss intro e stati
## terminali la congelano, e uscire dall'albero rimuove ogni rallentamento
## applicato.

signal finished(area: BossSignatureArea)
signal player_damaged(area: BossSignatureArea, amount: float)

const DEFAULT_KNOCKBACK_SECONDS := 0.18
const DEFAULT_TICK_SECONDS := 0.5

var _mode := BossSignatureRegistry.AreaMode.NONE
var _definition: BossSignatureDefinition
var _run_controller: RunController
var _player: Player
var _source: Node2D
var _modifier_id: StringName
var _damage_scale := 1.0
var _corridor_end := Vector2.INF
var _duration_total := 0.0
var _duration_remaining := 0.0
var _front_radius := 0.0
var _tick_interval := INF
var _tick_remaining := 0.0
var _cold_total := 0.0
var _cold_remaining := 0.0
var _detonated := false
var _front_hit_player := false
var _slow_applied := false
var _damage_dealt := 0.0
var _absorbed_projectiles := 0
var _finished := false


func initialize(
	mode: BossSignatureRegistry.AreaMode,
	definition: BossSignatureDefinition,
	origin: Vector2,
	source: Node2D,
	player: Player,
	run_controller: RunController,
	modifier_id: StringName,
	damage_scale: float = 1.0,
	corridor_end: Vector2 = Vector2.INF
) -> bool:
	if (
		mode == BossSignatureRegistry.AreaMode.NONE
		or definition == null
		or not definition.is_valid()
		or not origin.is_finite()
		or not is_instance_valid(player)
		or not is_instance_valid(run_controller)
		or not run_controller.is_running()
		or String(modifier_id).is_empty()
	):
		return false

	_mode = mode
	_definition = definition
	_player = player
	_run_controller = run_controller
	_source = source
	_modifier_id = modifier_id
	_damage_scale = maxf(damage_scale, 0.0) if is_finite(damage_scale) else 1.0
	_corridor_end = corridor_end
	global_position = origin
	_duration_total = definition.duration_seconds
	_duration_remaining = _duration_total
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	match _mode:
		BossSignatureRegistry.AreaMode.TRAIL_CORRIDOR:
			if not _corridor_end.is_finite():
				return false
			_tick_interval = definition.get_effect_float(
				&"dot_tick",
				DEFAULT_TICK_SECONDS,
				BossSignatureDefinition.MINIMUM_POSITIVE_VALUE
			)
			_tick_remaining = _tick_interval
		BossSignatureRegistry.AreaMode.FOLLOWING_CONTACT:
			var hits_per_second := definition.get_effect_float(
				&"hits_per_second",
				2.0,
				BossSignatureDefinition.MINIMUM_POSITIVE_VALUE
			)
			_tick_interval = 1.0 / hits_per_second
			_tick_remaining = _tick_interval
		BossSignatureRegistry.AreaMode.TWO_PHASE_BURST:
			_cold_total = minf(
				definition.get_effect_float(
					&"cold_seconds",
					_duration_total * 0.5,
					BossSignatureDefinition.MINIMUM_POSITIVE_VALUE
				),
				_duration_total
			)
			_cold_remaining = _cold_total
		BossSignatureRegistry.AreaMode.INSTANT_BURST:
			_apply_instant_burst()

	_advance_state(0.0)
	queue_redraw()
	return true


func _process(delta: float) -> void:
	if (
		_finished
		or not is_instance_valid(_run_controller)
		or not _run_controller.is_running()
	):
		return
	var safe_delta := maxf(delta, 0.0) if is_finite(delta) else 0.0
	_advance_state(safe_delta)
	_duration_remaining = maxf(_duration_remaining - safe_delta, 0.0)
	queue_redraw()
	if _duration_remaining <= 0.0 or _is_front_exhausted():
		_finish()


func _exit_tree() -> void:
	_clear_player_slow()


func get_mode() -> BossSignatureRegistry.AreaMode:
	return _mode


func get_signature_definition() -> BossSignatureDefinition:
	return _definition


func get_duration_remaining() -> float:
	return _duration_remaining


func get_front_radius() -> float:
	return _front_radius


func get_damage_dealt() -> float:
	return _damage_dealt


func get_absorbed_projectile_count() -> int:
	return _absorbed_projectiles


func is_cold_phase_active() -> bool:
	return (
		_mode == BossSignatureRegistry.AreaMode.TWO_PHASE_BURST
		and not _detonated
	)


func has_detonated() -> bool:
	return _detonated


func is_player_slowed() -> bool:
	return _slow_applied


func _advance_state(delta: float) -> void:
	match _mode:
		BossSignatureRegistry.AreaMode.EXPANDING_FRONT:
			_advance_expanding_front(delta)
		BossSignatureRegistry.AreaMode.TRAIL_CORRIDOR:
			_advance_periodic_damage(delta, _is_player_on_corridor())
		BossSignatureRegistry.AreaMode.FOLLOWING_CONTACT:
			_follow_source()
			_advance_periodic_damage(delta, _is_player_inside_radius())
		BossSignatureRegistry.AreaMode.TWO_PHASE_BURST:
			_advance_two_phase(delta)
		BossSignatureRegistry.AreaMode.FOLLOWING_SLOW_ABSORB:
			_follow_source()
			_sync_player_slow(_is_player_inside_radius())
			_absorb_player_projectiles()


## Il fronte parte dal Boss e corre verso l'esterno a velocita' dichiarata:
## resta piu' lento del Player, quindi allontanarsi o attraversarlo nel momento
## giusto e' sempre possibile. Colpisce una volta sola.
func _advance_expanding_front(delta: float) -> void:
	var expansion_speed := _definition.get_effect_float(
		&"expansion_speed",
		240.0,
		BossSignatureDefinition.MINIMUM_POSITIVE_VALUE
	)
	_front_radius = minf(
		_front_radius + expansion_speed * delta,
		_definition.area_radius
	)
	if _front_hit_player or not _is_player_alive():
		return
	var thickness := _definition.get_effect_float(&"front_thickness", 48.0, 1.0)
	var offset := _player.global_position - global_position
	var distance := offset.length()
	if absf(distance - _front_radius) > thickness * 0.5 + _player.collision_radius:
		return
	_front_hit_player = true
	var direction := offset.normalized() if not offset.is_zero_approx() else Vector2.RIGHT
	_damage_player(_definition.damage * _damage_scale)
	var knockback_force := _definition.get_effect_float(&"knockback_force", 0.0, 0.0)
	if knockback_force <= 0.0:
		return
	_player.apply_external_impulse(
		direction * knockback_force,
		_definition.get_effect_float(
			&"knockback_seconds",
			DEFAULT_KNOCKBACK_SECONDS,
			BossSignatureDefinition.MINIMUM_POSITIVE_VALUE
		)
	)


func _advance_periodic_damage(delta: float, player_is_inside: bool) -> void:
	if not is_finite(_tick_interval) or _tick_interval <= 0.0:
		return
	_tick_remaining = maxf(_tick_remaining - delta, 0.0)
	if _tick_remaining > 0.0:
		return
	_tick_remaining = _tick_interval
	if player_is_inside:
		_damage_player(_definition.damage * _damage_scale)


## Freddo poi caldo sulla stessa area: il rallentamento non impedisce di
## uscire prima della detonazione, che colpisce solo chi e' rimasto dentro.
func _advance_two_phase(delta: float) -> void:
	if _detonated:
		return
	_cold_remaining = maxf(_cold_remaining - delta, 0.0)
	if _cold_remaining > 0.0:
		_sync_player_slow(_is_player_inside_radius())
		return
	_detonated = true
	_sync_player_slow(false)
	if _is_player_inside_radius():
		_damage_player(_definition.damage * _damage_scale)


func _follow_source() -> void:
	if is_instance_valid(_source):
		global_position = _source.global_position


func _is_player_alive() -> bool:
	return is_instance_valid(_player) and _player.is_alive()


func _is_player_inside_radius() -> bool:
	if not _is_player_alive():
		return false
	var reach := _definition.area_radius + _player.collision_radius
	return global_position.distance_squared_to(_player.global_position) <= reach * reach


func _is_player_on_corridor() -> bool:
	if not _is_player_alive() or not _corridor_end.is_finite():
		return false
	var closest := Geometry2D.get_closest_point_to_segment(
		_player.global_position,
		global_position,
		_corridor_end
	)
	var reach := _definition.area_radius + _player.collision_radius
	return closest.distance_squared_to(_player.global_position) <= reach * reach


func _apply_instant_burst() -> void:
	if _is_player_inside_radius():
		_damage_player(_definition.damage * _damage_scale)


func _damage_player(amount: float) -> void:
	if amount <= 0.0 or not _is_player_alive():
		return
	if not _player.take_contact_damage(amount, global_position):
		return
	_damage_dealt += amount
	player_damaged.emit(self, amount)


func _sync_player_slow(should_slow: bool) -> void:
	if not is_instance_valid(_player) or should_slow == _slow_applied:
		return
	if should_slow:
		var slow_factor := clampf(
			_definition.get_effect_float(
				&"slow_factor",
				1.0,
				BossSignatureDefinition.MINIMUM_POSITIVE_VALUE
			),
			BossSignatureDefinition.MINIMUM_POSITIVE_VALUE,
			1.0
		)
		_slow_applied = _player.set_external_speed_modifier(_modifier_id, slow_factor)
		return
	_player.remove_external_speed_modifier(_modifier_id)
	_slow_applied = false


func _clear_player_slow() -> void:
	if _slow_applied and is_instance_valid(_player):
		_player.remove_external_speed_modifier(_modifier_id)
	_slow_applied = false


## La zona Zen di Evil Migi non respinge i proiettili alleati: li consuma,
## riusando `expire()`, che e' gia' idempotente.
func _absorb_player_projectiles() -> void:
	if not is_inside_tree():
		return
	for node in get_tree().get_nodes_in_group(&"player_projectiles"):
		if not node is Projectile:
			continue
		var projectile := node as Projectile
		if projectile.is_spent():
			continue
		if (
			global_position.distance_squared_to(projectile.global_position)
			> _definition.area_radius * _definition.area_radius
		):
			continue
		projectile.expire()
		_absorbed_projectiles += 1


func _is_front_exhausted() -> bool:
	return (
		_mode == BossSignatureRegistry.AreaMode.EXPANDING_FRONT
		and _front_radius >= _definition.area_radius
	)


func _finish() -> void:
	if _finished:
		return
	_finished = true
	_clear_player_slow()
	finished.emit(self)
	queue_free()


func _draw() -> void:
	if _definition == null:
		return
	var accent := _definition.accent_color
	var fade := clampf(
		_duration_remaining / maxf(
			_duration_total,
			BossSignatureDefinition.MINIMUM_POSITIVE_VALUE
		),
		0.0,
		1.0
	)
	match _mode:
		BossSignatureRegistry.AreaMode.EXPANDING_FRONT:
			_draw_expanding_front(accent)
		BossSignatureRegistry.AreaMode.TRAIL_CORRIDOR:
			_draw_corridor(accent, fade)
		BossSignatureRegistry.AreaMode.FOLLOWING_CONTACT:
			_draw_spin_aura(accent, fade)
		BossSignatureRegistry.AreaMode.TWO_PHASE_BURST:
			_draw_two_phase(accent, fade)
		BossSignatureRegistry.AreaMode.FOLLOWING_SLOW_ABSORB:
			_draw_zen_zone(accent, fade)
		BossSignatureRegistry.AreaMode.INSTANT_BURST:
			_draw_thunder_burst(accent, fade)


func _draw_expanding_front(accent: Color) -> void:
	if _front_radius <= 0.0:
		return
	var thickness := _definition.get_effect_float(&"front_thickness", 48.0, 1.0)
	var outer := _front_radius + thickness * 0.5
	BossAttackVisuals.stamp(self, BossAttackVisuals.signature_texture(_definition.effect_id), Vector2.ZERO, outer, Color.WHITE)
	BossAttackVisuals.ring(self, Vector2.ZERO, outer, accent)
	if _front_radius > thickness * 0.5:
		BossAttackVisuals.ring(self, Vector2.ZERO, _front_radius - thickness * 0.5, Color(accent, accent.a * 0.65))


func _draw_corridor(accent: Color, fade: float) -> void:
	BossAttackVisuals.corridor(self, Vector2.ZERO, _corridor_end - global_position, _definition.area_radius, Color(accent, accent.a * fade))
	var local_end := _corridor_end - global_position
	var steps := maxi(ceili(local_end.length() / maxf(_definition.area_radius * 1.5, 1.0)), 1)
	for index in steps + 1:
		BossAttackVisuals.stamp(self, BossAttackVisuals.signature_texture(_definition.effect_id), local_end * float(index) / float(steps), _definition.area_radius, Color(1.0, 1.0, 1.0, fade), local_end.angle())


func _draw_spin_aura(accent: Color, fade: float) -> void:
	var phase := maxf(_duration_total - _duration_remaining, 0.0) * TAU
	BossAttackVisuals.stamp(self, BossAttackVisuals.signature_texture(_definition.effect_id), Vector2.ZERO, _definition.area_radius, Color(1.0, 1.0, 1.0, fade), phase)
	BossAttackVisuals.ring(self, Vector2.ZERO, _definition.area_radius, Color(accent, accent.a * fade))


func _draw_two_phase(accent: Color, fade: float) -> void:
	var texture := BossAttackVisuals.THERMAL_HOT if _detonated else BossAttackVisuals.signature_texture(_definition.effect_id)
	var opacity := fade if _detonated else BossAttackVisuals.intensity(PresentationTimings.normalized_progress_from_remaining(_cold_remaining, _cold_total))
	BossAttackVisuals.stamp(self, texture, Vector2.ZERO, _definition.area_radius, Color(1.0, 1.0, 1.0, opacity))
	BossAttackVisuals.ring(self, Vector2.ZERO, _definition.area_radius, Color(accent, accent.a * opacity))


func _draw_zen_zone(accent: Color, fade: float) -> void:
	BossAttackVisuals.stamp(self, BossAttackVisuals.signature_texture(_definition.effect_id), Vector2.ZERO, _definition.area_radius, Color(1.0, 1.0, 1.0, fade))
	BossAttackVisuals.ring(self, Vector2.ZERO, _definition.area_radius, Color(accent, accent.a * fade))


func _draw_thunder_burst(accent: Color, fade: float) -> void:
	BossAttackVisuals.stamp(self, BossAttackVisuals.signature_texture(_definition.effect_id), Vector2.ZERO, _definition.area_radius, Color(1.0, 1.0, 1.0, fade))
	BossAttackVisuals.ring(self, Vector2.ZERO, _definition.area_radius, Color(accent, accent.a * fade))
