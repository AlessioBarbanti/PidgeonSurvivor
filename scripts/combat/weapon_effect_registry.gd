class_name WeaponEffectRegistry
extends Node

## Registry di emissione delle armi (PS-197), gemello di AbilityEffectRegistry
## per l'attacco automatico. Possiede **solo** l'emissione: ricevuta la
## direzione di mira, dichiara da dove partono i proiettili dell'arma attiva e
## in che direzione vanno. Bersagliamento, cooldown, mira manuale e
## modificatori delle Specialita' restano in WeaponController, cosi' ogni arma
## nuova eredita gratis sparo automatico e manuale.

const STRAIGHT_SHOT := &"straight_shot"

@export var definitions: Array[WeaponDefinition] = []

var _definitions_by_id: Dictionary = {}


func _ready() -> void:
	_rebuild_definition_index()


func register_definition(definition: WeaponDefinition) -> bool:
	if definition == null or not definition.is_valid():
		return false
	if _definitions_by_id.has(definition.id):
		return _definitions_by_id[definition.id] == definition
	_definitions_by_id[definition.id] = definition
	if not definitions.has(definition):
		definitions.append(definition)
	return true


func resolve_definition(weapon_id: StringName) -> WeaponDefinition:
	if _definitions_by_id.is_empty():
		_rebuild_definition_index()
	var definition: Variant = _definitions_by_id.get(weapon_id)
	return definition as WeaponDefinition


func get_definitions() -> Array[WeaponDefinition]:
	var valid_definitions: Array[WeaponDefinition] = []
	for definition in definitions:
		if definition != null and resolve_definition(definition.id) == definition:
			valid_definitions.append(definition)
	return valid_definitions


## Emissioni di un singolo colpo: per ciascuna, `offset` e' la posizione di
## partenza relativa alla sorgente e `direction` la direzione di volo.
## Un `effect_id` sconosciuto ricade sul colpo dritto invece di non sparare:
## un dato malformato deve degradare l'arma, non disarmare il personaggio.
func build_emissions(definition: WeaponDefinition, aim_direction: Vector2) -> Array[Dictionary]:
	if definition == null or not aim_direction.is_finite() or aim_direction.is_zero_approx():
		return build_straight_emissions(Vector2.RIGHT)
	return build_straight_emissions(aim_direction.normalized())


static func build_straight_emissions(aim_direction: Vector2) -> Array[Dictionary]:
	return [make_emission(Vector2.ZERO, aim_direction)]


static func make_emission(offset: Vector2, direction: Vector2) -> Dictionary:
	return {"offset": offset, "direction": direction}


func _rebuild_definition_index() -> void:
	_definitions_by_id.clear()
	for definition in definitions:
		if definition == null or not definition.is_valid():
			continue
		if not _definitions_by_id.has(definition.id):
			_definitions_by_id[definition.id] = definition
