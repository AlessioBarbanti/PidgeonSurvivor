class_name ThunderStorm
extends Node2D

## Tempesta di Tuoni (B43).
##
## Non e' piu' un wipe istantaneo dello schermo: l'attivazione apre una
## tempesta che dura alcuni secondi e fa cadere una sequenza di fulmini su
## posizioni fisse, telegrafate in anticipo. Le posizioni sono fotografate
## all'attivazione e non inseguono i nemici, quindi il valore dell'abilita'
## sta nel portare orde e Boss sopra le zone annunciate.
##
## Il budget di flash resta quello del B18E: un solo flash fullscreen per
## attivazione, acceso sul primo fulmine e chiuso entro 0,30 s. I fulmini
## successivi hanno soltanto VFX locali.

signal finished(effect: ThunderStorm)
signal targets_affected(count: int)
signal impact_started()
signal strike_landed(strike_index: int, strike_position: Vector2, affected_count: int)

enum Phase {
	WARNING,
	STORM,
	FINISHED,
}

enum FlashPhase {
	IDLE,
	RISE,
	HOLD,
	FADE,
	DONE,
}

const DEFAULT_WARNING_SECONDS := 0.45
const DEFAULT_TELEGRAPH_SECONDS := 0.85
const DEFAULT_STRIKE_COUNT := 5
const DEFAULT_STORM_DURATION := 2.75
const DEFAULT_STRIKE_RADIUS := 150.0
const DEFAULT_STORM_RADIUS := 260.0
const DEFAULT_NORMAL_RATIO := 0.5
const DEFAULT_BOSS_RATIO := 0.008
const MINIMUM_STRIKE_COUNT := 1
const MAXIMUM_STRIKE_COUNT := 24
const DEFAULT_FLASH_RISE_SECONDS := 0.06
const DEFAULT_FLASH_HOLD_SECONDS := 0.06
const DEFAULT_FLASH_FADE_SECONDS := 0.18
const DEFAULT_WINDOWS_ALPHA := 0.55
const DEFAULT_ANDROID_ALPHA := 0.40
const DEFAULT_REDUCED_ALPHA := 0.15
const GOLDEN_ANGLE := 2.399963229728653
const VISUAL_FAMILY_ID := &"thunder_cloud_warning_and_waves"
const VISUAL_PARTICLE_COUNT := 0
const VISUAL_MATERIAL_COUNT := 0
const LIGHTNING_IMPACT_TEXTURE := preload(
	"res://assets/art/vfx/abilities/generated/lightning_impact.png"
)
## Il decal elettrico riempie il quadrato fino agli angoli, mentre l'AoE e'
## circolare: inscrivendolo nel cerchio la diagonale non eccede _strike_radius.
const INSCRIBED_DECAL_SCALE := 0.70710678

var _definition: AbilityDefinition
var _run_controller: RunController
var _targeting_system: TargetingSystem
var _visual_settings: VisualAccessibilitySettings
var _origin := Vector2.ZERO
var _phase := Phase.WARNING
var _elapsed := 0.0
var _warning_seconds := DEFAULT_WARNING_SECONDS
var _telegraph_seconds := DEFAULT_TELEGRAPH_SECONDS
var _storm_duration := DEFAULT_STORM_DURATION
var _strike_interval := 0.55
var _strike_radius := DEFAULT_STRIKE_RADIUS
var _storm_radius := DEFAULT_STORM_RADIUS
var _normal_ratio := DEFAULT_NORMAL_RATIO
var _boss_ratio := DEFAULT_BOSS_RATIO
var _total_duration := 0.0
var _strike_positions := PackedVector2Array()
var _strike_times := PackedFloat32Array()
var _strike_hit_counts := PackedInt32Array()
var _strikes_resolved := 0
var _flash_alpha := 0.0
var _flash_max_alpha := 0.0
var _flash_rise_seconds := DEFAULT_FLASH_RISE_SECONDS
var _flash_hold_seconds := DEFAULT_FLASH_HOLD_SECONDS
var _flash_fade_seconds := DEFAULT_FLASH_FADE_SECONDS
var _flash_count := 0
var _affected_count := 0
var _impacted_target_ids: Array[int] = []
var _flash_layer: CanvasLayer
var _flash_rect: ColorRect


func initialize(
	origin: Vector2,
	definition: AbilityDefinition,
	run_controller: RunController,
	targeting_system: TargetingSystem,
	visual_settings: VisualAccessibilitySettings = null,
	arena_layout: ArenaLayout = null,
	strike_seed: int = 0
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
	_targeting_system = targeting_system
	_visual_settings = visual_settings
	if (
		is_instance_valid(_visual_settings)
		and not _visual_settings.settings_changed.is_connected(_on_visual_settings_changed)
	):
		_visual_settings.settings_changed.connect(_on_visual_settings_changed)
	_origin = origin if origin.is_finite() else Vector2.ZERO
	global_position = Vector2.ZERO
	_flash_rise_seconds = _definition.get_effect_float(
		&"flash_rise_seconds",
		DEFAULT_FLASH_RISE_SECONDS,
		AbilityDefinition.MINIMUM_POSITIVE_VALUE
	)
	_flash_hold_seconds = _definition.get_effect_float(
		&"flash_hold_seconds",
		DEFAULT_FLASH_HOLD_SECONDS,
		0.0
	)
	_flash_fade_seconds = _definition.get_effect_float(
		&"flash_fade_seconds",
		DEFAULT_FLASH_FADE_SECONDS,
		AbilityDefinition.MINIMUM_POSITIVE_VALUE
	)
	_warning_seconds = _definition.get_effect_float(
		&"warning_seconds",
		DEFAULT_WARNING_SECONDS,
		0.0
	)
	_telegraph_seconds = _definition.get_effect_float(
		&"strike_telegraph_seconds",
		DEFAULT_TELEGRAPH_SECONDS,
		AbilityDefinition.MINIMUM_POSITIVE_VALUE
	)
	_storm_duration = resolve_storm_duration(_definition)
	_strike_radius = resolve_strike_radius(_definition)
	_storm_radius = _definition.get_effect_float(
		&"storm_radius",
		DEFAULT_STORM_RADIUS,
		AbilityDefinition.MINIMUM_POSITIVE_VALUE
	)
	_normal_ratio = _definition.get_effect_float(
		&"normal_max_health_damage_ratio",
		DEFAULT_NORMAL_RATIO,
		0.0
	)
	_boss_ratio = _definition.get_effect_float(
		&"boss_max_health_damage_ratio",
		DEFAULT_BOSS_RATIO,
		0.0
	)
	_build_strike_plan(resolve_strike_count(_definition), strike_seed, arena_layout)
	_total_duration = _warning_seconds + _storm_duration
	_phase = Phase.WARNING
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_create_flash_overlay()
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
	while (
		_strikes_resolved < _strike_times.size()
		and _strike_times[_strikes_resolved] <= _elapsed
	):
		_resolve_strike(_strikes_resolved)
	_update_flash_alpha()
	_sync_flash_overlay()
	_release_spent_flash_overlay()
	queue_redraw()
	if _elapsed >= _total_duration and _strikes_resolved >= _strike_times.size():
		_finish()


func _exit_tree() -> void:
	if (
		is_instance_valid(_visual_settings)
		and _visual_settings.settings_changed.is_connected(_on_visual_settings_changed)
	):
		_visual_settings.settings_changed.disconnect(_on_visual_settings_changed)


func _draw() -> void:
	if _phase == Phase.FINISHED:
		return
	for index in _strike_positions.size():
		var lead := _strike_times[index] - _elapsed
		if index < _strikes_resolved:
			_draw_strike_afterglow(_strike_positions[index], -lead)
		elif lead <= _telegraph_seconds:
			_draw_strike_telegraph(_strike_positions[index], lead)


func get_phase() -> Phase:
	return _phase


func get_flash_phase() -> FlashPhase:
	var flash_age := _get_flash_age()
	if flash_age < 0.0:
		return FlashPhase.IDLE
	if flash_age < _flash_rise_seconds:
		return FlashPhase.RISE
	if flash_age < _flash_rise_seconds + _flash_hold_seconds:
		return FlashPhase.HOLD
	if flash_age < _flash_rise_seconds + _flash_hold_seconds + _flash_fade_seconds:
		return FlashPhase.FADE
	return FlashPhase.DONE


func get_elapsed() -> float:
	return _elapsed


func get_total_duration() -> float:
	return _total_duration


func get_warning_remaining() -> float:
	if _phase != Phase.WARNING or _strike_times.is_empty():
		return 0.0
	return maxf(_strike_times[0] - _elapsed, 0.0)


## Secondi mancanti al prossimo fulmine gia' telegrafato; `0` se la sequenza
## e' esaurita. Serve all'HUD e ai test per leggere la finestra di reazione.
func get_next_strike_remaining() -> float:
	if _strikes_resolved >= _strike_times.size():
		return 0.0
	return maxf(_strike_times[_strikes_resolved] - _elapsed, 0.0)


func get_strike_count() -> int:
	return _strike_times.size()


func get_strikes_resolved() -> int:
	return _strikes_resolved


func get_strike_positions() -> PackedVector2Array:
	return _strike_positions.duplicate()


func get_strike_times() -> PackedFloat32Array:
	return _strike_times.duplicate()


func get_strike_hit_count(strike_index: int) -> int:
	if strike_index < 0 or strike_index >= _strike_hit_counts.size():
		return 0
	return _strike_hit_counts[strike_index]


func get_strike_radius() -> float:
	return _strike_radius


func get_storm_radius() -> float:
	return _storm_radius


func get_visual_extent() -> float:
	return _strike_radius


func get_flash_alpha() -> float:
	return _flash_alpha


func get_flash_max_alpha() -> float:
	return _flash_max_alpha


## Numero di flash fullscreen accesi dall'attivazione. Il contratto di
## accessibilita' B18E ne ammette esattamente uno, anche ora che i fulmini
## sono molti.
func get_flash_count() -> int:
	return _flash_count


func get_flash_rect() -> Rect2:
	return _flash_rect.get_global_rect() if is_instance_valid(_flash_rect) else Rect2()


func get_affected_count() -> int:
	return _affected_count


func has_impacted() -> bool:
	return _strikes_resolved > 0


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
	return true


static func resolve_strike_count(definition: AbilityDefinition) -> int:
	if definition == null:
		return DEFAULT_STRIKE_COUNT
	return clampi(
		int(definition.get_effect_float(&"strike_count", float(DEFAULT_STRIKE_COUNT), 1.0)),
		MINIMUM_STRIKE_COUNT,
		MAXIMUM_STRIKE_COUNT
	)


static func resolve_storm_duration(definition: AbilityDefinition) -> float:
	if definition == null:
		return DEFAULT_STORM_DURATION
	var declared := definition.duration_seconds
	if not is_finite(declared) or declared <= 0.0:
		declared = DEFAULT_STORM_DURATION
	return declared


static func resolve_strike_radius(definition: AbilityDefinition) -> float:
	if definition == null:
		return DEFAULT_STRIKE_RADIUS
	var declared := definition.area_radius
	if not is_finite(declared) or declared <= 0.0:
		declared = DEFAULT_STRIKE_RADIUS
	return declared


## Tetto aritmetico del contributo dell'attiva alla vita del Boss in una
## finestra Boss, espresso come frazione della vita massima. Assume il caso
## peggiore: il Boss dentro l'area di *ogni* fulmine di *ogni* attivazione.
## Il criterio B43 chiede che resti sotto `0,50` a tutti i rank.
static func calculate_boss_window_contribution_ratio(
	definition: AbilityDefinition,
	boss_window_seconds: float
) -> float:
	if (
		definition == null
		or not is_finite(boss_window_seconds)
		or boss_window_seconds <= 0.0
	):
		return 0.0
	var cooldown := maxf(definition.cooldown_seconds, AbilityDefinition.MINIMUM_POSITIVE_VALUE)
	var activations := floorf(boss_window_seconds / cooldown) + 1.0
	var boss_ratio := definition.get_effect_float(
		&"boss_max_health_damage_ratio",
		DEFAULT_BOSS_RATIO,
		0.0
	)
	return float(resolve_strike_count(definition)) * boss_ratio * activations


static func resolve_flash_max_alpha(
	reduced_flashes: bool,
	is_android: bool,
	windows_alpha: float = DEFAULT_WINDOWS_ALPHA,
	android_alpha: float = DEFAULT_ANDROID_ALPHA,
	reduced_alpha: float = DEFAULT_REDUCED_ALPHA
) -> float:
	if reduced_flashes:
		return clampf(reduced_alpha, 0.0, 1.0)
	return clampf(android_alpha if is_android else windows_alpha, 0.0, 1.0)


## Dispone i fulmini a spirale attorno all'origine dell'attivazione. Il primo
## cade sempre esattamente sull'origine, cosi' l'attiva non e' mai una
## lotteria e non e' mai spostato dall'arena: il giocatore che attiva sopra
## un bersaglio lo colpisce sempre. I successivi si allontanano con angolo
## aureo e jitter preso dall'RNG seedato della run, quindi la stessa run
## rigioca la stessa tempesta; solo questi vengono ricondotti dentro il
## playfield, perche' l'origine e' per costruzione gia' dentro l'arena in
## partita (il movimento del Player e' clampato) e non deve mai muoversi.
func _build_strike_plan(
	strike_count: int,
	strike_seed: int,
	arena_layout: ArenaLayout
) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = strike_seed if strike_seed != 0 else 1
	_strike_interval = _storm_duration / float(maxi(strike_count, MINIMUM_STRIKE_COUNT))
	for index in strike_count:
		_strike_times.append(_warning_seconds + float(index) * _strike_interval)
		_strike_hit_counts.append(0)
		var strike_position := _origin
		if index > 0:
			var spread := float(index) / float(maxi(strike_count - 1, 1))
			var angle := float(index) * GOLDEN_ANGLE + rng.randf_range(-0.35, 0.35)
			var distance := _storm_radius * sqrt(spread) * rng.randf_range(0.78, 1.0)
			strike_position = _origin + Vector2.RIGHT.rotated(angle) * distance
			if is_instance_valid(arena_layout):
				strike_position = arena_layout.clamp_circle_center(
					strike_position,
					_strike_radius * 0.5
				)
		_strike_positions.append(strike_position)


func _resolve_strike(strike_index: int) -> void:
	_strikes_resolved = strike_index + 1
	if strike_index == 0:
		_phase = Phase.STORM
		impact_started.emit()
		_begin_flash()
	var strike_position := _strike_positions[strike_index]
	var squared_radius := _strike_radius * _strike_radius
	var hit_count := 0
	var resolved_ids: Array[int] = []
	for target in _targeting_system.get_alive_targets():
		if not is_instance_valid(target) or not target.is_alive():
			continue
		var health := target.get_health_component()
		if health == null or not health.is_alive():
			continue
		var target_id := target.get_instance_id()
		if target_id in resolved_ids:
			continue
		if strike_position.distance_squared_to(target.global_position) > squared_radius:
			continue
		resolved_ids.append(target_id)
		if not target_id in _impacted_target_ids:
			_impacted_target_ids.append(target_id)
		var is_boss := target is FirstBoss or target.is_in_group(&"bosses")
		var damage_ratio := _boss_ratio if is_boss else _normal_ratio
		if target.take_damage(health.health_max * damage_ratio):
			hit_count += 1
	_strike_hit_counts[strike_index] = hit_count
	_affected_count += hit_count
	strike_landed.emit(strike_index, strike_position, hit_count)
	targets_affected.emit(_affected_count)


func _begin_flash() -> void:
	if _flash_count > 0:
		return
	_flash_count = 1
	var reduced_flashes := (
		is_instance_valid(_visual_settings)
		and _visual_settings.is_reduced_flashes_enabled()
	)
	_flash_max_alpha = resolve_flash_max_alpha(
		reduced_flashes,
		OS.has_feature("android"),
		_definition.get_effect_float(&"windows_flash_alpha", DEFAULT_WINDOWS_ALPHA, 0.0),
		_definition.get_effect_float(&"android_flash_alpha", DEFAULT_ANDROID_ALPHA, 0.0),
		_definition.get_effect_float(&"reduced_flash_alpha", DEFAULT_REDUCED_ALPHA, 0.0)
	)
	if reduced_flashes:
		_flash_hold_seconds = 0.0


func _get_flash_age() -> float:
	if _flash_count <= 0 or _strike_times.is_empty():
		return -1.0
	return _elapsed - _strike_times[0]


func _update_flash_alpha() -> void:
	var flash_age := _get_flash_age()
	match get_flash_phase():
		FlashPhase.RISE:
			_flash_alpha = _flash_max_alpha * clampf(
				flash_age / maxf(_flash_rise_seconds, AbilityDefinition.MINIMUM_POSITIVE_VALUE),
				0.0,
				1.0
			)
		FlashPhase.HOLD:
			_flash_alpha = _flash_max_alpha
		FlashPhase.FADE:
			var fade_age := flash_age - _flash_rise_seconds - _flash_hold_seconds
			_flash_alpha = _flash_max_alpha * clampf(
				1.0 - fade_age / maxf(_flash_fade_seconds, AbilityDefinition.MINIMUM_POSITIVE_VALUE),
				0.0,
				1.0
			)
		_:
			_flash_alpha = 0.0


## L'overlay fullscreen vive solo per il flash: appena si spegne viene
## rimosso, cosi' i fulmini successivi non possono riaccenderlo.
func _release_spent_flash_overlay() -> void:
	if get_flash_phase() != FlashPhase.DONE or not is_instance_valid(_flash_layer):
		return
	_flash_alpha = 0.0
	_flash_layer.queue_free()
	_flash_layer = null
	_flash_rect = null


func _create_flash_overlay() -> void:
	_flash_layer = CanvasLayer.new()
	_flash_layer.name = "ThunderFlashLayer"
	_flash_layer.layer = 20
	add_child(_flash_layer)
	_flash_rect = ColorRect.new()
	_flash_rect.name = "ThunderFlash"
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash_rect.color = Color(1.0, 1.0, 1.0, 0.0)
	_flash_layer.add_child(_flash_rect)
	_sync_flash_overlay()
	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_sync_flash_overlay):
		viewport.size_changed.connect(_sync_flash_overlay)


func _sync_flash_overlay() -> void:
	if not is_instance_valid(_flash_rect):
		return
	_flash_rect.position = Vector2.ZERO
	_flash_rect.size = get_viewport_rect().size
	_flash_rect.color = Color(1.0, 1.0, 1.0, _flash_alpha)


func _draw_strike_telegraph(center: Vector2, lead: float) -> void:
	var progress := clampf(1.0 - lead / maxf(_telegraph_seconds, 0.001), 0.0, 1.0)
	var preview_radius := _strike_radius * lerpf(0.72, 0.96, progress)
	var preview_size := Vector2.ONE * preview_radius * 2.0 * INSCRIBED_DECAL_SCALE
	draw_texture_rect(
		LIGHTNING_IMPACT_TEXTURE,
		Rect2(center - preview_size * 0.5, preview_size),
		false,
		Color(0.62, 0.78, 1.0, 0.08 + progress * 0.12)
	)
	var cross_size := lerpf(13.0, 5.0, progress)
	draw_line(center - Vector2(cross_size, 0.0), center + Vector2(cross_size, 0.0), Color(1.0, 0.92, 0.5, 0.72), 3.0, true)
	draw_line(center - Vector2(0.0, cross_size), center + Vector2(0.0, cross_size), Color(1.0, 0.92, 0.5, 0.72), 3.0, true)


func _draw_strike_afterglow(center: Vector2, age: float) -> void:
	var fade := 1.0 - clampf(age / maxf(_strike_interval, 0.001), 0.0, 1.0)
	if fade <= 0.0:
		return
	var impact_radius := _strike_radius * (1.0 + (1.0 - fade) * 0.08)
	var impact_size := Vector2.ONE * impact_radius * 2.0 * INSCRIBED_DECAL_SCALE
	draw_texture_rect(
		LIGHTNING_IMPACT_TEXTURE,
		Rect2(center - impact_size * 0.5, impact_size),
		false,
		Color(1.0, 1.0, 1.0, fade * 0.94)
	)


func _finish() -> void:
	if _phase == Phase.FINISHED:
		return
	_phase = Phase.FINISHED
	_flash_alpha = 0.0
	_sync_flash_overlay()
	queue_redraw()
	finished.emit(self)
	queue_free()


func _on_visual_settings_changed(reduced_flashes: bool) -> void:
	if _flash_count <= 0 or get_flash_phase() == FlashPhase.DONE:
		return
	_flash_max_alpha = resolve_flash_max_alpha(
		reduced_flashes,
		OS.has_feature("android"),
		_definition.get_effect_float(&"windows_flash_alpha", DEFAULT_WINDOWS_ALPHA, 0.0),
		_definition.get_effect_float(&"android_flash_alpha", DEFAULT_ANDROID_ALPHA, 0.0),
		_definition.get_effect_float(&"reduced_flash_alpha", DEFAULT_REDUCED_ALPHA, 0.0)
	)
	_flash_hold_seconds = (
		0.0
		if reduced_flashes
		else _definition.get_effect_float(
			&"flash_hold_seconds",
			DEFAULT_FLASH_HOLD_SECONDS,
			0.0
		)
	)
	_update_flash_alpha()
	_sync_flash_overlay()
	_release_spent_flash_overlay()
	queue_redraw()
