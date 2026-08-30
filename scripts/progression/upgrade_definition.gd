class_name UpgradeDefinition
extends Resource

@export var id: StringName = &""
@export var title := ""
## Sentence describing what the upgrade does, without numbers.
@export_multiline var description := ""
## Compact stat line with the exact values, shown under the description.
@export var effect_summary := ""
@export var icon: Texture2D

@export_group("Effect")
@export var effect_id: StringName = &""
@export var effect_parameters: Dictionary = {}

@export_group("Draw")
@export_range(0.001, 1000.0, 0.001, "or_greater") var weight := 1.0
@export_range(1, 100, 1, "or_greater") var max_rank := 1
@export_range(0, 99, 1, "or_greater") var initial_rank := 0
@export var repeatable := false
## Carta appartenente al roster di Barb: esclusa dal pool normale finché non
## viene sbloccata come ricompensa dopo la sconfitta di un Boss (PS-012).
@export var is_speciality := false
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
		or initial_rank < 0
		or initial_rank >= max_rank
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
	if not repeatable and get_current_rank(current_ranks) >= max_rank:
		return false
	for prerequisite_key: Variant in prerequisites:
		var prerequisite_id := StringName(str(prerequisite_key))
		if get_rank_from(current_ranks, prerequisite_id) < int(prerequisites[prerequisite_key]):
			return false
	return true


func get_current_rank(current_ranks: Dictionary) -> int:
	return maxi(get_rank_from(current_ranks, id), initial_rank)


func is_ability_rank_definition() -> bool:
	if effect_id != &"ability_rank" or initial_rank != 1 or max_rank != 5 or repeatable:
		return false
	var ability_id := StringName(str(effect_parameters.get("ability_id", "")))
	return (
		is_valid_id(ability_id)
		and id == get_ability_rank_upgrade_id(ability_id)
	)


static func get_ability_rank_upgrade_id(ability_id: StringName) -> StringName:
	return StringName("ability_rank_%s" % ability_id)


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
