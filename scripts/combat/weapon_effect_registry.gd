class_name WeaponEffectRegistry
extends Node

## Registry di emissione delle armi (PS-197), gemello di AbilityEffectRegistry
## per l'attacco automatico. Possiede **solo** l'emissione: ricevuta la
## direzione di mira, dichiara da dove partono i proiettili dell'arma attiva e
## in che direzione vanno. Bersagliamento, cooldown, mira manuale e
## modificatori delle Specialita' restano in WeaponController, cosi' ogni arma
## nuova eredita gratis sparo automatico e manuale.

const STRAIGHT_SHOT := &"straight_shot"
const ALTERNATING_SKEWERS := &"alternating_skewers"
const SPLITTING_SHOT := &"splitting_shot"
const ORBITING_FRAGMENTS := &"orbiting_fragments"

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
## partenza relativa alla sorgente, `direction` la direzione di volo e
## `trajectory` come il proiettile si muovera' poi.
## `shot_index` e' il numero del colpo nella run: serve alle armi che
## alternano fra un colpo e il successivo e tiene il registry senza stato.
## Un `effect_id` serve solo dove cambia la *geometria* dell'emissione: le armi
## che differiscono per sola traiettoria la dichiarano nei dati (PS-200).
## Un `effect_id` sconosciuto ricade sul colpo dritto invece di non sparare:
## un dato malformato deve degradare l'arma, non disarmare il personaggio.
func build_emissions(
	definition: WeaponDefinition,
	aim_direction: Vector2,
	shot_index: int = 0
) -> Array[Dictionary]:
	if definition == null or not aim_direction.is_finite() or aim_direction.is_zero_approx():
		return build_straight_emissions(Vector2.RIGHT)
	var direction := aim_direction.normalized()
	match definition.effect_id:
		ALTERNATING_SKEWERS:
			# Spiedo: uno spiedo sottile per colpo, alternato ai due fianchi.
			# L'alternanza e' geometria d'emissione, non un secondo proiettile:
			# il ritmo resta di un colpo per volta.
			var lateral := definition.get_effect_float(&"lateral_offset", 18.0, 0.0)
			var side := 1.0 if shot_index % 2 == 0 else -1.0
			return [make_emission(direction.orthogonal() * lateral * side, direction)]
		SPLITTING_SHOT:
			# Cavatappi: due colpi perfettamente sovrapposti che divergono
			# poco dopo la volata. Sono due proiettili dal primo istante, non
			# uno che si duplica: finche' viaggiano insieme sono
			# indistinguibili da un colpo solo, e il tetto di kill-rate li
			# conta entrambi. Il ritardo va tenuto corto: con 0,8 s lo
			# sdoppiamento cadeva a 656 px, cioe' fuori dallo schermo sull'asse
			# verticale (mezza altezza = 360 px) e oltre il bersaglio piu'
			# vicino, quindi non avveniva quasi mai.
			var delay := definition.get_effect_float(&"split_delay_seconds", 0.22, 0.0)
			var divergence := definition.get_effect_float(&"divergence_degrees", 10.0, 0.0)
			return [
				make_emission(
					Vector2.ZERO, direction, Projectile.TRAJECTORY_SPLIT,
					{"delay": delay, "turn_degrees": divergence}
				),
				make_emission(
					Vector2.ZERO, direction, Projectile.TRAJECTORY_SPLIT,
					{"delay": delay, "turn_degrees": -divergence}
				),
			]
		ORBITING_FRAGMENTS:
			# Graticola: frammenti distribuiti sull'anello, non sulla mira.
			# La direzione di mira resta l'ancora dell'anello, cosi' Tagliata
			# continua a ruotare il gruppo e Alette a irregolarizzarne i pezzi.
			var fragment_count := maxi(definition.get_effect_int(&"fragment_count", 3, 1), 1)
			var orbit_radius := definition.get_effect_float(&"orbit_radius", 104.0, 1.0)
			var emissions: Array[Dictionary] = []
			var step := TAU / float(fragment_count)
			for index in fragment_count:
				var fragment_direction := direction.rotated(step * float(index))
				emissions.append(make_emission(
					fragment_direction * orbit_radius,
					fragment_direction,
					Projectile.TRAJECTORY_ORBIT,
					{"radius": orbit_radius}
				))
			return emissions
		_:
			# Colpo frontale singolo. Se l'arma dichiara una traiettoria nei
			# propri dati se la porta dietro: una differenza di sola
			# traiettoria non giustifica un effect_id dedicato, perche'
			# l'emissione e' identica (PS-200). I parametri passano interi,
			# Projectile legge solo le chiavi della traiettoria che ha.
			return [make_emission(
				Vector2.ZERO,
				direction,
				StringName(definition.effect_parameters.get(
					"trajectory", Projectile.TRAJECTORY_STRAIGHT
				)),
				definition.effect_parameters
			)]


static func build_straight_emissions(aim_direction: Vector2) -> Array[Dictionary]:
	return [make_emission(Vector2.ZERO, aim_direction)]


static func make_emission(
	offset: Vector2,
	direction: Vector2,
	trajectory := Projectile.TRAJECTORY_STRAIGHT,
	parameters: Dictionary = {}
) -> Dictionary:
	return {
		"offset": offset,
		"direction": direction,
		"trajectory": trajectory,
		"parameters": parameters,
	}


func _rebuild_definition_index() -> void:
	_definitions_by_id.clear()
	for definition in definitions:
		if definition == null or not definition.is_valid():
			continue
		if not _definitions_by_id.has(definition.id):
			_definitions_by_id[definition.id] = definition
