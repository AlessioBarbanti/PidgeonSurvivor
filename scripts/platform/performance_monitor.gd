class_name PerformanceMonitor
extends Control

signal sample_recorded(sample: Dictionary)

@export_range(0.25, 10.0, 0.25) var sample_interval_seconds := 1.0

var _profile: PerformanceProfile
var _sources: Dictionary = {}
var _elapsed := 0.0
var _samples: Array[Dictionary] = []
var _label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	position = Vector2(12.0, 12.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 14)
	_label.add_theme_color_override("font_color", Color(0.86, 0.96, 1.0, 1.0))
	_label.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.06, 1.0))
	_label.add_theme_constant_override("outline_size", 4)
	add_child(_label)
	visible = false


func configure(profile: PerformanceProfile, sources: Dictionary) -> bool:
	if profile == null or not profile.is_valid():
		return false
	_profile = profile
	_sources = sources.duplicate()
	return true


func set_overlay_enabled(enabled: bool) -> void:
	visible = enabled and OS.is_debug_build()
	if visible:
		_refresh_label(get_snapshot())


func is_overlay_enabled() -> bool:
	return visible


func get_profile() -> PerformanceProfile:
	return _profile


func get_samples() -> Array[Dictionary]:
	return _samples.duplicate(true)


func clear_samples() -> void:
	_samples.clear()


func get_snapshot() -> Dictionary:
	var frame_time_ms := 1000.0 / maxf(Engine.get_frames_per_second(), 0.001)
	return {
		"profile": String(_profile.profile_id) if _profile != null else "unconfigured",
		"fps": snappedf(Engine.get_frames_per_second(), 0.01),
		"frame_ms": snappedf(frame_time_ms, 0.01),
		"process_ms": snappedf(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, 0.01),
		"physics_ms": snappedf(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0, 0.01),
		"nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"objects": int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		"static_memory": int(Performance.get_monitor(Performance.MEMORY_STATIC)),
		"video_memory": int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)),
		"draw_calls": int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		"enemies": _child_count(&"enemies"),
		"projectiles": _child_count(&"projectiles") + _child_count(&"boss_projectiles"),
		"pickups": _child_count(&"pickups"),
		"ability_effects": _ability_effect_count(),
		"feedback": _feedback_count(),
		"audio_voices": _audio_voice_count(),
	}


func _process(delta: float) -> void:
	_elapsed += maxf(delta, 0.0)
	if _elapsed < sample_interval_seconds:
		return
	_elapsed = 0.0
	var sample := get_snapshot()
	_samples.append(sample)
	print("B18V_PERF_SAMPLE %s" % JSON.stringify(sample))
	sample_recorded.emit(sample)
	if visible:
		_refresh_label(sample)


func _refresh_label(sample: Dictionary) -> void:
	if _label == null:
		return
	_label.text = "B18V %s\n%.1f FPS  %.2f ms\nE:%d P:%d X:%d V:%d A:%d\nN:%d DC:%d" % [
		String(sample.get("profile", "-")),
		float(sample.get("fps", 0.0)),
		float(sample.get("frame_ms", 0.0)),
		int(sample.get("enemies", 0)),
		int(sample.get("projectiles", 0)),
		int(sample.get("pickups", 0)),
		int(sample.get("feedback", 0)),
		int(sample.get("audio_voices", 0)),
		int(sample.get("nodes", 0)),
		int(sample.get("draw_calls", 0)),
	]


func _child_count(source_key: StringName) -> int:
	var node := _sources.get(source_key) as Node
	return node.get_child_count() if is_instance_valid(node) else 0


func _ability_effect_count() -> int:
	var registry := _sources.get(&"ability_registry") as AbilityEffectRegistry
	return registry.get_active_effect_count() + registry.get_active_visual_tail_count() if is_instance_valid(registry) else 0


func _feedback_count() -> int:
	var feedback := _sources.get(&"feedback") as CombatFeedback
	return feedback.get_active_effect_count() if is_instance_valid(feedback) else 0


func _audio_voice_count() -> int:
	var audio := _sources.get(&"audio") as GameAudio
	return audio.get_active_voice_count() if is_instance_valid(audio) else 0
