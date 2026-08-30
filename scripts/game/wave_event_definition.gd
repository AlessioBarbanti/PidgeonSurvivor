class_name WaveEventDefinition
extends Resource

## Evento d'ondata (PS-008 / B46): formazione finita e riconoscibile che
## compone temporaneamente pesi e settori effettivi di EnemySpawner senza
## introdurre una seconda curva ordinaria parallela a quella late-run PS-007.
## Come EnemyArchetypeDefinition, una sola risorsa copre piu' comportamenti:
## solo i campi del gruppo corrispondente a effect_id vengono letti.

const EFFECT_SURROUND := 0
const EFFECT_LATERAL_SWARM := 1
const EFFECT_RANGED_NEST := 2

const ORDINARY_MODE_UNCHANGED := 0
const ORDINARY_MODE_REDUCED := 1
const ORDINARY_MODE_REPLACED := 2

@export_group("Identity")
@export var event_id: StringName = &""
@export_enum("Surround", "LateralSwarm", "RangedNest") var effect_id := EFFECT_SURROUND

## Peso relativo nella scelta casuale fra eventi eleggibili; 0 esclude l'evento.
@export_range(0.0, 64.0, 0.01, "or_greater") var weight := 1.0:
	set(value):
		weight = maxf(value, 0.0) if is_finite(value) else 0.0

@export_group("Timing")
@export_range(1.0, 120.0, 0.5, "or_greater") var duration_seconds := 10.0:
	set(value):
		duration_seconds = maxf(value, 1.0) if is_finite(value) else 1.0

## Richiesto solo quando la formazione potrebbe produrre danno inevitabile
## prima che il Player abbia il tempo materiale di reagire (Accerchiamento).
@export var requires_telegraph := false
@export_range(0.1, 30.0, 0.1, "or_greater") var telegraph_duration_seconds := 2.5:
	set(value):
		telegraph_duration_seconds = maxf(value, 0.1) if is_finite(value) else 0.1

## Testo HUD mostrato durante il telegraph; ignorato quando requires_telegraph
## e' falso.
@export var telegraph_display_text: String = ""

@export_group("Formation")
## Usato da Surround e LateralSwarm: archetipo generato dalla formazione oltre
## allo spawn ordinario. Deve coincidere con un EnemyArchetypeDefinition.id
## gia' assegnato a EnemySpawner.archetypes.
@export var formation_archetype_id: StringName = &""
@export_range(0, 32, 1, "or_greater") var formation_enemy_count := 0:
	set(value):
		formation_enemy_count = maxi(value, 0)
@export_range(0.05, 10.0, 0.05, "or_greater") var formation_spawn_interval_seconds := 0.5:
	set(value):
		formation_spawn_interval_seconds = maxf(value, 0.05) if is_finite(value) else 0.05

@export_group("Ordinary Spawn")
## Lo spawn ordinario puo' continuare a ritmo ridotto o essere sostituito per
## la durata dell'evento; alla fine riprende sempre senza recuperare arretrati.
@export_enum("Unchanged", "Reduced", "Replaced") var ordinary_spawn_mode := ORDINARY_MODE_UNCHANGED
@export_range(1.0, 8.0, 0.1, "or_greater") var ordinary_spawn_interval_multiplier := 1.0:
	set(value):
		ordinary_spawn_interval_multiplier = maxf(value, 1.0) if is_finite(value) else 1.0

@export_group("Ranged Nest")
## Usato solo da RangedNest: id dell'archetipo la cui presenza relativa va
## aumentata nel pool ordinario esistente (nessuna seconda curva parallela).
@export var ranged_archetype_id: StringName = &""
@export_range(1.0, 16.0, 0.1, "or_greater") var ranged_weight_multiplier := 3.0:
	set(value):
		ranged_weight_multiplier = maxf(value, 1.0) if is_finite(value) else 1.0


func is_valid() -> bool:
	if String(event_id).is_empty():
		return false
	if not is_finite(duration_seconds) or duration_seconds <= 0.0:
		return false
	if requires_telegraph and (
		not is_finite(telegraph_duration_seconds) or telegraph_duration_seconds <= 0.0
	):
		return false
	match effect_id:
		EFFECT_SURROUND, EFFECT_LATERAL_SWARM:
			if String(formation_archetype_id).is_empty() or formation_enemy_count <= 0:
				return false
		EFFECT_RANGED_NEST:
			if String(ranged_archetype_id).is_empty():
				return false
		_:
			return false
	return true
