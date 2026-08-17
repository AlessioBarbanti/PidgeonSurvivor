class_name GameDirectorProfile
extends Resource

const MINIMUM_BOSS_THRESHOLD_SECONDS := 0.001

@export var enemy_spawn_profile: EnemySpawnProfile
@export var boss_thresholds_seconds := PackedFloat32Array([240.0])


func get_effective_boss_thresholds() -> PackedFloat32Array:
	var sorted_thresholds: Array[float] = []
	for threshold in boss_thresholds_seconds:
		if not is_finite(threshold):
			continue
		if threshold < MINIMUM_BOSS_THRESHOLD_SECONDS:
			continue
		sorted_thresholds.append(threshold)
	sorted_thresholds.sort()

	var unique_thresholds: Array[float] = []
	for threshold in sorted_thresholds:
		if (
			unique_thresholds.is_empty()
			or not is_equal_approx(unique_thresholds[-1], threshold)
		):
			unique_thresholds.append(threshold)
	return PackedFloat32Array(unique_thresholds)


func is_valid() -> bool:
	return (
		enemy_spawn_profile != null
		and not get_effective_boss_thresholds().is_empty()
	)
