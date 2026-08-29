extends GutTest

## Prototipo GUT: nessuna scene tree, nessuna movement_slice — solo Resource.


func _make_ability_rank_card(ability_id: StringName) -> UpgradeDefinition:
	var definition := UpgradeDefinition.new()
	definition.id = UpgradeDefinition.get_ability_rank_upgrade_id(ability_id)
	definition.title = "Rank"
	definition.description = "Aumenta il rank dell'abilita."
	definition.effect_id = &"ability_rank"
	definition.effect_parameters = {"ability_id": ability_id}
	definition.initial_rank = 1
	definition.max_rank = 5
	definition.repeatable = false
	return definition


func test_valid_id_rejects_uppercase_and_empty() -> void:
	assert_true(UpgradeDefinition.is_valid_id(&"magno_earthquake"), "Un id minuscolo valido deve passare.")
	assert_false(UpgradeDefinition.is_valid_id(&"Magno_Earthquake"), "Un id con maiuscole non deve essere valido.")
	assert_false(UpgradeDefinition.is_valid_id(&""), "Un id vuoto non deve essere valido.")


func test_ability_rank_upgrade_id_is_derived_from_ability_id() -> void:
	var derived := UpgradeDefinition.get_ability_rank_upgrade_id(&"bea_fire_z_trail")
	assert_eq(derived, &"ability_rank_bea_fire_z_trail", "L'id carta deve derivare dall'ability id.")


func test_is_ability_rank_definition_true_for_well_formed_card() -> void:
	var card := _make_ability_rank_card(&"magno_earthquake_shockwave")
	assert_true(card.is_ability_rank_definition(), "Una carta rank ben formata deve essere riconosciuta come tale.")


func test_is_ability_rank_definition_false_when_repeatable() -> void:
	var card := _make_ability_rank_card(&"magno_earthquake_shockwave")
	card.repeatable = true
	assert_false(card.is_ability_rank_definition(), "Una carta rank non deve mai essere ripetibile.")


func test_is_eligible_respects_max_rank() -> void:
	var card := _make_ability_rank_card(&"magno_earthquake_shockwave")
	var ranks := {card.id: 5}
	assert_false(card.is_eligible(ranks), "Al rank massimo la carta non deve essere piu eleggibile.")


func test_is_eligible_respects_prerequisites() -> void:
	var card := UpgradeDefinition.new()
	card.id = &"advanced_upgrade"
	card.title = "Avanzato"
	card.description = "Richiede un prerequisito."
	card.effect_id = &"stat_boost"
	card.max_rank = 3
	card.prerequisites = {&"base_upgrade": 2}

	assert_false(card.is_eligible({&"base_upgrade": 1}), "Sotto il rank richiesto la carta non deve essere eleggibile.")
	assert_true(card.is_eligible({&"base_upgrade": 2}), "Al rank richiesto la carta deve essere eleggibile.")
