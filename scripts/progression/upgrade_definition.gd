class_name UpgradeDefinition
extends Resource

@export var id: StringName = &""
@export var title := ""
@export_multiline var description := ""
@export var icon: Texture2D

@export_group("Effect")
@export var effect_id: StringName = &""
@export var effect_parameters: Dictionary = {}

@export_group("Draw")
@export_range(0.001, 1000.0, 0.001, "or_greater") var weight := 1.0
@export_range(1, 100, 1, "or_greater") var max_rank := 1
@export var repeatable := false
@export var fallback := false
@export var tags: Array[StringName] = []
## Maps another upgrade ID to the minimum rank required for this definition.
@export var prerequisites: Dictionary = {}


func is_valid() -> bool:
	if (
		not is_valid_id(id)
		or title.strip_edges().is_empty()
		or description.strip_edges().is_empty()
		or not is_valid_id(effect_id)
		or not is_finite(weight)
		or weight <= 0.0
		or max_rank < 1
		or (fallback and not repeatable)
	):
		return false

	var seen_tags: Dictionary = {}
	for tag in tags:
		if not is_valid_id(tag) or seen_tags.has(tag):
			return false
		seen_tags[tag] = true

	for prerequisite_key: Variant in prerequisites:
		var prerequisite_id := StringName(str(prerequisite_key))
		if (
			not is_valid_id(prerequisite_id)
			or prerequisite_id == id
			or int(prerequisites[prerequisite_key]) < 1
		):
			return false
	return true


func is_eligible(current_ranks: Dictionary) -> bool:
	if not is_valid():
		return false
	if not repeatable and get_rank_from(current_ranks, id) >= max_rank:
		return false
	for prerequisite_key: Variant in prerequisites:
		var prerequisite_id := StringName(str(prerequisite_key))
		if get_rank_from(current_ranks, prerequisite_id) < int(prerequisites[prerequisite_key]):
			return false
	return true


func has_all_tags(required_tags: Array[StringName]) -> bool:
	for required_tag in required_tags:
		if required_tag not in tags:
			return false
	return true


static func get_rank_from(current_ranks: Dictionary, upgrade_id: StringName) -> int:
	if current_ranks.has(upgrade_id):
		return maxi(int(current_ranks[upgrade_id]), 0)
	var string_id := String(upgrade_id)
	return maxi(int(current_ranks.get(string_id, 0)), 0)


static func is_valid_id(value: StringName) -> bool:
	var text := String(value)
	return (
		not text.is_empty()
		and text == text.to_lower()
		and text.is_valid_identifier()
	)
