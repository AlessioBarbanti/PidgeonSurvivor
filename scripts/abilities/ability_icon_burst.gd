extends Node2D

const LOGICAL_ICON_SIZE := 92.0
const BURST_DURATION := PresentationTimings.ABILITY_ICON_BURST_SECONDS

var _effect_id: StringName
var _run_controller: RunController
var _sprite: Sprite2D
var _elapsed := 0.0
var _base_scale := 1.0


func initialize(
	icon_texture: Texture2D,
	effect_id: StringName,
	run_controller: RunController
) -> bool:
	if (
		icon_texture == null
		or effect_id.is_empty()
		or not is_instance_valid(run_controller)
	):
		return false
	_effect_id = effect_id
	_run_controller = run_controller
	_sprite = Sprite2D.new()
	_sprite.name = "GeneratedAbilityEmblem"
	_sprite.texture = icon_texture
	_sprite.centered = true
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.z_index = 1
	add_child(_sprite)
	var texture_size := icon_texture.get_size()
	var longest_side := maxf(texture_size.x, texture_size.y)
	if longest_side <= 0.0:
		return false
	_base_scale = LOGICAL_ICON_SIZE / longest_side
	_apply_animation(0.0)
	return true


func _process(delta: float) -> void:
	if not is_instance_valid(_run_controller) or not _run_controller.is_running():
		return
	var safe_delta := maxf(delta, 0.0) if is_finite(delta) else 0.0
	_elapsed = minf(_elapsed + safe_delta, BURST_DURATION)
	_apply_animation(_elapsed / BURST_DURATION)
	if _elapsed >= BURST_DURATION:
		queue_free()


func _apply_animation(progress: float) -> void:
	if not is_instance_valid(_sprite):
		return
	var t := clampf(progress, 0.0, 1.0)
	var opacity := PresentationTimings.one_shot_opacity(
		_elapsed,
		BURST_DURATION
	)
	var scale_factor := Vector2.ONE
	var offset := Vector2.ZERO
	var angle := 0.0
	match _effect_id:
		AbilityEffectRegistry.EARTHQUAKE_SHOCKWAVE:
			var impact := smoothstep(0.0, 0.42, t)
			scale_factor = Vector2.ONE * lerpf(0.34, 1.16, impact)
			angle = sin(t * TAU * 4.0) * (1.0 - t) * 0.07
		AbilityEffectRegistry.FIRE_Z_TRAIL:
			scale_factor = Vector2(0.68 + t * 0.5, 0.8 + t * 0.18)
			offset.x = lerpf(-20.0, 18.0, t)
			angle = lerpf(-0.16, 0.08, t)
		AbilityEffectRegistry.LIGHTNING_STORM:
			var thunder_pulse := 1.0 + sin(t * TAU * 3.0) * 0.08
			scale_factor = Vector2(0.9, thunder_pulse)
			offset.y = lerpf(-18.0, 0.0, smoothstep(0.0, 0.45, t))
		AbilityEffectRegistry.GRAND_SPIN:
			scale_factor = Vector2.ONE * (0.72 + sin(minf(t * 1.25, 1.0) * PI) * 0.38)
			angle = t * TAU * 1.35
		AbilityEffectRegistry.CEMENT_POUR:
			var drop := smoothstep(0.0, 0.5, t)
			scale_factor = Vector2(0.82 + drop * 0.22, 1.18 - drop * 0.18)
			offset.y = lerpf(-30.0, 8.0, drop)
			angle = lerpf(-0.12, 0.02, drop)
		AbilityEffectRegistry.RANDOM_COSPLAY:
			var reveal := sin(minf(t * 1.45, 1.0) * PI)
			scale_factor = Vector2.ONE * (0.58 + reveal * 0.62)
			angle = sin(t * TAU * 2.0) * 0.16
		AbilityEffectRegistry.ZEN_SLOWDOWN:
			var breath := (sin(t * TAU * 1.5) + 1.0) * 0.5
			scale_factor = Vector2.ONE * (0.82 + breath * 0.18)
			offset.y = -breath * 5.0
		AbilityEffectRegistry.SHADOW_DECEPTION:
			var beat := absf(sin(t * TAU * 2.5))
			scale_factor = Vector2(0.84 + beat * 0.16, 0.84 + beat * 0.22)
			offset.y = -beat * 10.0
			angle = sin(t * TAU * 2.5) * 0.08
	_sprite.scale = scale_factor * _base_scale
	_sprite.position = offset
	_sprite.rotation = angle
	_sprite.modulate = Color(1.0, 1.0, 1.0, opacity * 0.9)


func get_effect_id() -> StringName:
	return _effect_id


func get_texture_path() -> String:
	return _sprite.texture.resource_path if is_instance_valid(_sprite) else ""


func get_duration_remaining() -> float:
	return maxf(BURST_DURATION - _elapsed, 0.0)


func get_duration_total() -> float:
	return BURST_DURATION


func get_visual_opacity() -> float:
	return _sprite.modulate.a if is_instance_valid(_sprite) else 0.0


func is_non_interactive_tail() -> bool:
	return true


func get_visual_element_count() -> int:
	return 1


func get_visual_material_count() -> int:
	return 0
