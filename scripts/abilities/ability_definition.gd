class_name AbilityDefinition
extends Resource

const MINIMUM_POSITIVE_VALUE := 0.001

@export var id: StringName = &""
@export var title := ""
## Sentence describing what the ability does, without numbers.
@export_multiline var description := ""
## Compact stat line with the rank 1 values.
@export var effect_summary := ""
@export var icon: Texture2D

@export_group("Timing")
@export_range(0.01, 600.0, 0.01, "or_greater") var cooldown_seconds := 1.0:
	set(value):
		cooldown_seconds = _positive_or_minimum(value)

@export_range(0.0, 600.0, 0.01, "or_greater") var duration_seconds := 0.0:
	set(value):
		duration_seconds = _non_negative(value)

@export_group("Area And Damage")
@export_range(0.0, 4096.0, 1.0, "or_greater") var area_radius := 0.0:
	set(value):
		area_radius = _non_negative(value)

@export_range(0.0, 1000000.0, 0.1, "or_greater") var damage := 0.0:
	set(value):
		damage = _non_negative(value)

@export_group("Effect")
@export var effect_id: StringName = &""
@export var effect_parameters: Dictionary = {}
@export var tags: Array[StringName] = []

@export_group("Ranks")
@export var rank_snapshots: Array[AbilityRankSnapshot] = []

var _resolved_rank := 1


func is_valid() -> bool:
	return (
		not id.is_empty()
		and not title.strip_edges().is_empty()
		and not effect_id.is_empty()
		and is_finite(cooldown_seconds)
		and cooldown_seconds > 0.0
		and is_finite(duration_seconds)
		and duration_seconds >= 0.0
		and is_finite(area_radius)
		and area_radius >= 0.0
		and is_finite(damage)
		and damage >= 0.0
		and _has_valid_rank_snapshots()
	)


func resolve_rank(rank: int) -> AbilityDefinition:
	if rank_snapshots.is_empty():
		if rank != 1:
			return null
		var baseline := duplicate(false) as AbilityDefinition
		baseline._resolved_rank = 1
		return baseline if baseline.is_valid() else null
	var snapshot := get_rank_snapshot(rank)
	if snapshot == null:
		return null
	var resolved := duplicate(false) as AbilityDefinition
	resolved.cooldown_seconds = snapshot.cooldown_seconds
	resolved.duration_seconds = snapshot.duration_seconds
	resolved.area_radius = snapshot.area_radius
	resolved.damage = snapshot.damage
	resolved.effect_parameters = snapshot.effect_parameters.duplicate(true)
	resolved.rank_snapshots = rank_snapshots.duplicate()
	resolved._resolved_rank = snapshot.rank
	return resolved if resolved.is_valid() else null


func get_rank_snapshot(rank: int) -> AbilityRankSnapshot:
	for snapshot in rank_snapshots:
		if snapshot != null and snapshot.rank == rank:
			return snapshot
	return null


func get_resolved_rank() -> int:
	return _resolved_rank


func get_effect_float(
	parameter_name: StringName,
	default_value: float = 0.0,
	minimum_value: float = -INF
) -> float:
	var raw_value: Variant = effect_parameters.get(parameter_name, default_value)
	var parsed_value := float(raw_value)
	if not is_finite(parsed_value):
		parsed_value = default_value
	return maxf(parsed_value, minimum_value)


func has_all_tags(required_tags: Array[StringName]) -> bool:
	for required_tag in required_tags:
		if not required_tag in tags:
			return false
	return true


func _positive_or_minimum(value: float) -> float:
	return maxf(value, MINIMUM_POSITIVE_VALUE) if is_finite(value) else MINIMUM_POSITIVE_VALUE


func _non_negative(value: float) -> float:
	return maxf(value, 0.0) if is_finite(value) else 0.0


func _has_valid_rank_snapshots() -> bool:
	if rank_snapshots.is_empty():
		return true
	if rank_snapshots.size() != 5:
		return false
	var seen_ranks: Dictionary = {}
	for snapshot in rank_snapshots:
		if snapshot == null or not snapshot.is_valid() or seen_ranks.has(snapshot.rank):
			return false
		seen_ranks[snapshot.rank] = true
	for rank in range(1, 6):
		if not seen_ranks.has(rank):
			return false
	var current_snapshot := get_rank_snapshot(_resolved_rank)
	return (
		current_snapshot != null
		and is_equal_approx(cooldown_seconds, current_snapshot.cooldown_seconds)
		and is_equal_approx(duration_seconds, current_snapshot.duration_seconds)
		and is_equal_approx(area_radius, current_snapshot.area_radius)
		and is_equal_approx(damage, current_snapshot.damage)
		and effect_parameters == current_snapshot.effect_parameters
	)
