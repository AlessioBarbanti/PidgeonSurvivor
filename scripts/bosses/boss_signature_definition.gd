class_name BossSignatureDefinition
extends Resource

## Signature Ability di un Evil (PS-006). Reinterpreta l'attiva del
## personaggio corrispondente in chiave Boss: telegraph piu' lungo, aree piu'
## leggibili e parametri propri.
##
## I valori dichiarati qui non toccano mai l'`AbilityDefinition` del roster
## giocabile: bilanciare una Signature non puo' cambiare l'abilita' del
## personaggio, e viceversa.

const MINIMUM_POSITIVE_VALUE := 0.001

@export var id: StringName = &""
## Profilo del cast a cui la Signature appartiene (`FriendDefinition.id`).
@export var friend_id: StringName = &""
## Nome pubblico della mossa, allineato al titolo dell'attiva del personaggio.
@export var title := ""
## Comportamento eseguito: la logica vive in `BossSignatureRegistry` e in
## `FirstBoss`, mai in questo file dati.
@export var effect_id: StringName = &""

@export_group("Timing")
## Preavviso leggibile prima che la Signature diventi pericolosa.
@export_range(0.01, 10.0, 0.01, "or_greater") var telegraph_duration := 1.2:
	set(value):
		telegraph_duration = _positive_or_minimum(value)

## Durata dell'effetto dopo il telegraph.
@export_range(0.01, 60.0, 0.01, "or_greater") var duration_seconds := 1.0:
	set(value):
		duration_seconds = _positive_or_minimum(value)

## Attesa aggiuntiva prima del pattern Boss successivo, sommata a
## `BossDefinition.pattern_interval`.
@export_range(0.0, 60.0, 0.01, "or_greater") var recovery_seconds := 0.0:
	set(value):
		recovery_seconds = _non_negative(value)

@export_group("Area And Damage")
@export_range(0.0, 4096.0, 1.0, "or_greater") var area_radius := 0.0:
	set(value):
		area_radius = _non_negative(value)

@export_range(0.0, 1000000.0, 0.1, "or_greater") var damage := 0.0:
	set(value):
		damage = _non_negative(value)

@export_group("Effect")
@export var effect_parameters: Dictionary = {}

@export_group("Visual")
## Tinta del telegraph e dell'area: distingue la Signature dai pattern Boss
## comuni, che usano `BossDefinition.telegraph_color`.
@export var accent_color := Color(1.0, 0.42, 0.16, 0.78)
## Icona mostrata nella Boss Intro Evil (PS-051). Puo' restare `null`: la UI
## nasconde semplicemente lo slot invece di mostrare una texture nulla.
@export var icon: Texture2D


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


func get_safe_title() -> String:
	return title.strip_edges()


func is_valid() -> bool:
	return (
		not id.is_empty()
		and not friend_id.is_empty()
		and not get_safe_title().is_empty()
		and BossSignatureRegistry.is_supported(effect_id)
		and _is_positive_finite(telegraph_duration)
		and _is_positive_finite(duration_seconds)
		and is_finite(recovery_seconds)
		and recovery_seconds >= 0.0
		and is_finite(area_radius)
		and area_radius >= 0.0
		and is_finite(damage)
		and damage >= 0.0
		and BossSignatureRegistry.has_required_parameters(self)
	)


static func _positive_or_minimum(value: float) -> float:
	return maxf(value, MINIMUM_POSITIVE_VALUE) if is_finite(value) else MINIMUM_POSITIVE_VALUE


static func _non_negative(value: float) -> float:
	return maxf(value, 0.0) if is_finite(value) else 0.0


static func _is_positive_finite(value: float) -> bool:
	return is_finite(value) and value >= MINIMUM_POSITIVE_VALUE
