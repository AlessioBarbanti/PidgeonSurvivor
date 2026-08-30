class_name WaveEventSchedulerProfile
extends Resource

## Configurazione dello scheduler eventi d'ondata (PS-008 / B46): soglia
## d'ingresso, frequenza e catalogo degli eventi eleggibili. La formazione e
## il comportamento restano nei singoli WaveEventDefinition; questa risorsa
## sceglie soltanto quando e fra quali eventi rimescolare.

const POLICY_POSTPONE := 0
const POLICY_DISCARD := 1

@export var events: Array[WaveEventDefinition] = []

## Nessun evento puo' iniziare prima di questa soglia (baseline 02:30).
@export_range(0.0, 3600.0, 1.0, "or_greater") var min_start_seconds := 150.0:
	set(value):
		min_start_seconds = maxf(value, 0.0) if is_finite(value) else 0.0

@export_range(1.0, 600.0, 1.0, "or_greater") var cooldown_min_seconds := 45.0:
	set(value):
		cooldown_min_seconds = maxf(value, 1.0) if is_finite(value) else 1.0

@export_range(1.0, 600.0, 1.0, "or_greater") var cooldown_max_seconds := 90.0:
	set(value):
		cooldown_max_seconds = maxf(value, 1.0) if is_finite(value) else 1.0

## Regola dati esplicita per un evento maturato durante un Boss: "postpone" lo
## ritenta non appena il Boss termina, "discard" lo scarta e ripianifica un
## nuovo intervallo casuale. In entrambi i casi resta un solo evento in
## attesa: non si accumula mai una coda.
@export_enum("postpone", "discard") var boss_maturation_policy := POLICY_POSTPONE


func get_effective_min_start_seconds() -> float:
	return maxf(min_start_seconds, 0.0) if is_finite(min_start_seconds) else 0.0


func get_effective_cooldown_min_seconds() -> float:
	return minf(cooldown_min_seconds, cooldown_max_seconds)


func get_effective_cooldown_max_seconds() -> float:
	return maxf(cooldown_min_seconds, cooldown_max_seconds)


func get_eligible_events() -> Array[WaveEventDefinition]:
	var eligible: Array[WaveEventDefinition] = []
	for definition in events:
		if definition != null and definition.is_valid() and definition.weight > 0.0:
			eligible.append(definition)
	return eligible


func is_postpone_policy() -> bool:
	return boss_maturation_policy == POLICY_POSTPONE


func is_valid() -> bool:
	return not get_eligible_events().is_empty()
