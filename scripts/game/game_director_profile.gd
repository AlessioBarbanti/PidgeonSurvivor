class_name GameDirectorProfile
extends Resource

const MINIMUM_BOSS_THRESHOLD_SECONDS := 0.001
const MAXIMUM_WARNING_SECONDS := 120.0

@export var enemy_spawn_profile: EnemySpawnProfile
@export var boss_thresholds_seconds := PackedFloat32Array([120.0])
@export var recurring_boss_window_seconds := 240.0
@export_range(0.0, MAXIMUM_WARNING_SECONDS, 0.5, "suffix:s") var boss_warning_lead_seconds := 15.0:
	set(value):
		boss_warning_lead_seconds = _sanitize_warning_seconds(value)
@export_range(0.0, MAXIMUM_WARNING_SECONDS, 1.0, "suffix:s") var boss_countdown_seconds := 5.0:
	set(value):
		boss_countdown_seconds = _sanitize_warning_seconds(value)
## PS-126: HP/danno del Boss crescono di questa frazione per ogni ricorrenza
## successiva alla prima (schedule_index 0-based: 0 = invariato). Tiene il
## Boss ricorrente una minaccia reale nelle run endless invece di diventare
## trivialmente debole rispetto a una build che continua a crescere. A 0.0 il
## comportamento resta identico a prima di PS-126.
@export_range(0.0, 4.0, 0.01, "or_greater") var boss_recurrence_growth_per_occurrence := 1.2:
	set(value):
		boss_recurrence_growth_per_occurrence = maxf(value, 0.0) if is_finite(value) else 0.0


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


func get_effective_recurring_boss_window() -> float:
	if not is_finite(recurring_boss_window_seconds):
		return 0.0
	if recurring_boss_window_seconds < MINIMUM_BOSS_THRESHOLD_SECONDS:
		return 0.0
	return recurring_boss_window_seconds


func get_effective_boss_warning_lead() -> float:
	return _sanitize_warning_seconds(boss_warning_lead_seconds)


func get_effective_boss_countdown() -> float:
	return minf(
		_sanitize_warning_seconds(boss_countdown_seconds),
		get_effective_boss_warning_lead()
	)


func is_valid() -> bool:
	return (
		enemy_spawn_profile != null
		and not get_effective_boss_thresholds().is_empty()
		and get_effective_recurring_boss_window() > 0.0
	)


## PS-126: 1.0 alla prima occorrenza (schedule_index 0), cresce linearmente
## con le ricorrenze successive di boss_recurrence_growth_per_occurrence.
func get_boss_recurrence_multiplier(schedule_index: int) -> float:
	var sanitized_index := maxi(schedule_index, 0)
	return 1.0 + float(sanitized_index) * boss_recurrence_growth_per_occurrence


static func _sanitize_warning_seconds(value: float) -> float:
	if not is_finite(value):
		return 0.0
	return clampf(value, 0.0, MAXIMUM_WARNING_SECONDS)
