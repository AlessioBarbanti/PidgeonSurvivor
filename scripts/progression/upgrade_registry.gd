class_name UpgradeRegistry
extends Node

@export var definitions: Array[UpgradeDefinition] = []

var _definitions_by_id: Dictionary = {}
var _validation_errors: Array[String] = []


func _ready() -> void:
	rebuild_registry()


func rebuild_registry() -> bool:
	_definitions_by_id.clear()
	_validation_errors.clear()

	var candidates_by_id: Dictionary = {}
	var duplicate_ids: Dictionary = {}
	for index in definitions.size():
		var definition := definitions[index]
		if definition == null:
			_validation_errors.append("Definizione nulla all'indice %d." % index)
			continue
		if not definition.is_valid():
			_validation_errors.append(
				"Definizione non valida all'indice %d (ID: %s)." % [index, definition.id]
			)
			continue
		if candidates_by_id.has(definition.id):
			duplicate_ids[definition.id] = true
			continue
		candidates_by_id[definition.id] = definition

	for duplicate_id: Variant in duplicate_ids:
		candidates_by_id.erase(duplicate_id)
		_validation_errors.append("ID upgrade duplicato: %s." % duplicate_id)

	var catalog_changed := true
	while catalog_changed:
		catalog_changed = false
		for candidate_id: Variant in candidates_by_id.keys():
			var definition := candidates_by_id[candidate_id] as UpgradeDefinition
			for prerequisite_key: Variant in definition.prerequisites:
				var prerequisite_id := StringName(str(prerequisite_key))
				if candidates_by_id.has(prerequisite_id):
					continue
				_validation_errors.append(
					"Upgrade %s richiede l'ID non registrato %s."
					% [definition.id, prerequisite_id]
				)
				candidates_by_id.erase(candidate_id)
				catalog_changed = true
				break

	_definitions_by_id = candidates_by_id
	return _validation_errors.is_empty()


func register_definition(definition: UpgradeDefinition) -> bool:
	if definition == null or not definition.is_valid():
		return false
	for registered_definition in definitions:
		if registered_definition != null and registered_definition.id == definition.id:
			return registered_definition == definition
	definitions.append(definition)
	rebuild_registry()
	return resolve_definition(definition.id) == definition


func resolve_definition(upgrade_id: StringName) -> UpgradeDefinition:
	var definition: Variant = _definitions_by_id.get(upgrade_id)
	return definition as UpgradeDefinition


func get_definitions() -> Array[UpgradeDefinition]:
	var registered: Array[UpgradeDefinition] = []
	for definition in definitions:
		if definition != null and resolve_definition(definition.id) == definition:
			registered.append(definition)
	return registered


func get_eligible_definitions(current_ranks: Dictionary) -> Array[UpgradeDefinition]:
	var eligible: Array[UpgradeDefinition] = []
	for definition in get_definitions():
		if definition.is_eligible(current_ranks):
			eligible.append(definition)
	return eligible


func get_repeatable_definitions() -> Array[UpgradeDefinition]:
	var repeatable: Array[UpgradeDefinition] = []
	for definition in get_definitions():
		if definition.repeatable:
			repeatable.append(definition)
	return repeatable


func get_speciality_definitions() -> Array[UpgradeDefinition]:
	var specialities: Array[UpgradeDefinition] = []
	for definition in get_definitions():
		if definition.is_speciality:
			specialities.append(definition)
	return specialities


func get_validation_errors() -> Array[String]:
	return _validation_errors.duplicate()


func is_catalog_valid() -> bool:
	return _validation_errors.is_empty() and not _definitions_by_id.is_empty()
