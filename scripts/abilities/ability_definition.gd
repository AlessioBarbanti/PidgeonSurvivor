class_name AbilityDefinition
extends Resource

const MINIMUM_POSITIVE_VALUE := 0.001

@export var id: StringName = &""
@export var title := ""
@export_multiline var description := ""
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
	)


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
