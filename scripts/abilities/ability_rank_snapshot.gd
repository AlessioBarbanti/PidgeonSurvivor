class_name AbilityRankSnapshot
extends Resource

@export_range(1, 5, 1) var rank := 1
@export_range(0.01, 600.0, 0.01, "or_greater") var cooldown_seconds := 1.0
@export_range(0.0, 600.0, 0.01, "or_greater") var duration_seconds := 0.0
@export_range(0.0, 4096.0, 1.0, "or_greater") var area_radius := 0.0
@export_range(0.0, 1000000.0, 0.1, "or_greater") var damage := 0.0
@export var effect_parameters: Dictionary = {}


func is_valid() -> bool:
	return (
		rank >= 1
		and rank <= 5
		and is_finite(cooldown_seconds)
		and cooldown_seconds > 0.0
		and is_finite(duration_seconds)
		and duration_seconds >= 0.0
		and is_finite(area_radius)
		and area_radius >= 0.0
		and is_finite(damage)
		and damage >= 0.0
	)
