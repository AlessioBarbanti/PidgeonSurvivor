class_name ExperienceCurve
extends Resource

const MAX_EXPERIENCE_REQUIREMENT := 2_147_483_647

@export_range(1, 1_000_000, 1, "or_greater")
var base_experience_required := 10

@export_range(0, 1_000_000, 1, "or_greater")
var experience_growth_per_level := 5


func get_experience_required(level: int) -> int:
	var safe_level := maxi(level, 1)
	var safe_base := mini(
		maxi(base_experience_required, 1),
		MAX_EXPERIENCE_REQUIREMENT
	)
	var safe_growth := mini(
		maxi(experience_growth_per_level, 0),
		MAX_EXPERIENCE_REQUIREMENT
	)
	if safe_growth == 0:
		return safe_base

	var level_offset := safe_level - 1
	var maximum_offset := int(
		(MAX_EXPERIENCE_REQUIREMENT - safe_base) / safe_growth
	)
	return safe_base + mini(level_offset, maximum_offset) * safe_growth
