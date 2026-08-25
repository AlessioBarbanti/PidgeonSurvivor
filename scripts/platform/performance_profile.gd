class_name PerformanceProfile
extends Resource

## Profilo dichiarativo: modifica solo la presentazione e non il bilanciamento.
@export var profile_id: StringName = &"desktop"
@export_range(30, 240, 1) var target_fps := 60
@export_range(0.5, 1.0, 0.05) var render_scale := 1.0
@export_range(1, 1024, 1) var max_transient_feedback := 300
@export_range(1, 512, 1) var stress_enemy_count := 150
@export_range(1, 512, 1) var stress_projectile_count := 200
@export_range(1, 512, 1) var stress_pickup_count := 200


func is_valid() -> bool:
	return (
		not profile_id.is_empty()
		and target_fps >= 30
		and is_finite(render_scale)
		and render_scale >= 0.5
		and render_scale <= 1.0
		and max_transient_feedback > 0
		and stress_enemy_count > 0
		and stress_projectile_count > 0
		and stress_pickup_count > 0
	)
