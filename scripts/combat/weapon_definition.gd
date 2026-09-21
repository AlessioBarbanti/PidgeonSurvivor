class_name WeaponDefinition
extends WeaponProfile

## Arma di un personaggio (PS-196, contratto in docs/prd.md 3.1A). Estende
## WeaponProfile invece di affiancarlo: i valori base dell'arma sono gli
## stessi campi validati che WeaponController gia' legge, e aggiungere qui
## identita' ed `effect_id` evita un secondo Resource da tenere allineato.
## Nessuna logica nei dati: `effect_id` e' un nome che WeaponEffectRegistry
## risolve in un'emissione.

@export_group("Identity")
@export var id: StringName = &""
@export var display_name := ""
@export_multiline var description := ""
@export var icon: Texture2D

@export_group("Effect")
@export var effect_id: StringName = &""
@export var effect_parameters: Dictionary = {}

@export_group("Targeting")
## PS-202: in automatico l'arma colpisce nell'ultima direzione di movimento del
## personaggio, come lo scatto di Bea, invece che verso il nemico piu' vicino.
## In manuale vince sempre la mira del giocatore.
@export var aims_along_movement := false


func is_valid() -> bool:
	return (
		FriendDefinition.is_valid_id(id)
		and not display_name.strip_edges().is_empty()
		and not effect_id.is_empty()
	)


func get_public_display_name() -> String:
	return display_name.strip_edges()


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


func get_effect_int(
	parameter_name: StringName,
	default_value: int = 0,
	minimum_value: int = 0
) -> int:
	return maxi(int(effect_parameters.get(parameter_name, default_value)), minimum_value)
