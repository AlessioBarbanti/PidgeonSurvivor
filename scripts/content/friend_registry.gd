class_name FriendRegistry
extends Node

@export var definitions: Array[FriendDefinition] = []

var _definitions_by_id: Dictionary = {}
var _validation_errors: Array[String] = []


func _ready() -> void:
	rebuild_registry()


func rebuild_registry() -> bool:
	_definitions_by_id.clear()
	_validation_errors.clear()

	var ability_owners: Dictionary = {}
	var evil_name_owners: Dictionary = {}
	var duplicate_ids: Dictionary = {}
	for index in definitions.size():
		var definition := definitions[index]
		if definition == null:
			_validation_errors.append("Definizione amico nulla all'indice %d." % index)
			continue
		if not definition.is_valid():
			_validation_errors.append(
				"Definizione amico non valida all'indice %d (ID: %s)." % [index, definition.id]
			)
			continue
		if duplicate_ids.has(definition.id):
			continue
		if _definitions_by_id.has(definition.id):
			var previous := _definitions_by_id[definition.id] as FriendDefinition
			_definitions_by_id.erase(definition.id)
			duplicate_ids[definition.id] = true
			_validation_errors.append("ID amico duplicato: %s." % definition.id)
			ability_owners.erase(previous.active_ability_id)
			evil_name_owners.erase(previous.evil_display_name.to_lower())
			continue

		if ability_owners.has(definition.active_ability_id):
			_validation_errors.append(
				"Ability ID %s assegnato a più amici." % definition.active_ability_id
			)
			continue
		var normalized_evil_name := definition.evil_display_name.strip_edges().to_lower()
		if evil_name_owners.has(normalized_evil_name):
			_validation_errors.append(
				"Nome controparte Evil duplicato: %s." % definition.evil_display_name
			)
			continue

		_definitions_by_id[definition.id] = definition
		ability_owners[definition.active_ability_id] = definition.id
		evil_name_owners[normalized_evil_name] = definition.id

	return _validation_errors.is_empty()


func resolve_definition(friend_id: StringName) -> FriendDefinition:
	var definition: Variant = _definitions_by_id.get(friend_id)
	return definition as FriendDefinition


func resolve_by_ability_id(ability_id: StringName) -> FriendDefinition:
	for definition in get_definitions():
		if definition.active_ability_id == ability_id:
			return definition
	return null


func get_definitions() -> Array[FriendDefinition]:
	var registered: Array[FriendDefinition] = []
	for definition in definitions:
		if definition != null and resolve_definition(definition.id) == definition:
			registered.append(definition)
	return registered


func get_publication_ready_definitions() -> Array[FriendDefinition]:
	var ready_definitions: Array[FriendDefinition] = []
	for definition in get_definitions():
		if definition.is_publication_ready():
			ready_definitions.append(definition)
	return ready_definitions


func get_validation_errors() -> Array[String]:
	return _validation_errors.duplicate()


func is_catalog_valid() -> bool:
	return _validation_errors.is_empty() and not _definitions_by_id.is_empty()


func is_catalog_publication_ready() -> bool:
	return (
		is_catalog_valid()
		and get_publication_ready_definitions().size() == get_definitions().size()
	)
