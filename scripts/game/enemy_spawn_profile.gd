class_name EnemySpawnProfile
extends Resource

const MINIMUM_INTERVAL_SECONDS := 0.01

@export_group("Timing")
@export_range(0.01, 60.0, 0.01, "or_greater") var base_spawn_interval := 1.0:
	set(value):
		base_spawn_interval = maxf(value, MINIMUM_INTERVAL_SECONDS)

@export_range(0.01, 60.0, 0.01, "or_greater") var min_spawn_interval := 0.25:
	set(value):
		min_spawn_interval = maxf(value, MINIMUM_INTERVAL_SECONDS)

@export_range(0.0, 1.0, 0.0001, "or_greater") var spawn_acceleration := 0.0025:
	set(value):
		spawn_acceleration = maxf(value, 0.0)

@export_range(0.0, 60.0, 0.01, "or_greater") var initial_spawn_delay := 0.75:
	set(value):
		initial_spawn_delay = maxf(value, 0.0)

@export_group("Population")
@export_range(1, 512, 1, "or_greater") var max_alive_enemies := 80:
	set(value):
		max_alive_enemies = maxi(value, 1)

@export_group("Progression")
## Baseline di cadenza usata per conservare il ritmo XP quando cambia la
## densita. Il valore viene campionato allo spawn e non coinvolge i Boss.
@export_range(0.01, 60.0, 0.01, "or_greater") var progression_reference_base_spawn_interval := 1.0:
	set(value):
		progression_reference_base_spawn_interval = maxf(value, MINIMUM_INTERVAL_SECONDS)

@export_range(0.01, 60.0, 0.01, "or_greater") var progression_reference_min_spawn_interval := 0.25:
	set(value):
		progression_reference_min_spawn_interval = maxf(value, MINIMUM_INTERVAL_SECONDS)

@export_range(0.0, 1.0, 0.0001, "or_greater") var progression_reference_spawn_acceleration := 0.0025:
	set(value):
		progression_reference_spawn_acceleration = maxf(value, 0.0)

## Bonus esplicito sul budget XP della baseline. Resta frazionario per kill e
## non viene applicato ai Boss.
@export_range(0.1, 4.0, 0.05, "or_greater") var progression_experience_multiplier := 1.5:
	set(value):
		progression_experience_multiplier = maxf(value, 0.1)

@export_group("Placement")
@export_range(0.0, 2048.0, 1.0, "or_greater") var inner_spawn_margin := 48.0:
	set(value):
		inner_spawn_margin = maxf(value, 0.0)

@export_range(0.0, 2048.0, 1.0, "or_greater") var outer_spawn_margin := 160.0:
	set(value):
		outer_spawn_margin = maxf(value, 0.0)

@export_range(0.0, 4096.0, 1.0, "or_greater") var min_player_distance := 240.0:
	set(value):
		min_player_distance = maxf(value, 0.0)

@export_range(1, 128, 1, "or_greater") var spawn_sample_attempts := 12:
	set(value):
		spawn_sample_attempts = maxi(value, 1)

@export_group("Dispersion")
## Raggio min/max dell'offset di inseguimento assegnato a ogni nemico allo
## spawn, cosicche' grandi gruppi non convergano sullo stesso pixel del target.
@export_range(0.0, 256.0, 1.0, "or_greater") var pursuit_offset_min_radius := 8.0:
	set(value):
		pursuit_offset_min_radius = maxf(value, 0.0)

@export_range(0.0, 256.0, 1.0, "or_greater") var pursuit_offset_max_radius := 28.0:
	set(value):
		pursuit_offset_max_radius = maxf(value, 0.0)

@export_group("Sectors")
## Durata min/max con cui uno stesso insieme di settori (N/E/S/O) resta
## attivo prima di ruotare verso una nuova combinazione non prevedibile.
@export_range(0.5, 120.0, 0.5, "or_greater") var sector_hold_duration_min := 6.0:
	set(value):
		sector_hold_duration_min = maxf(value, 0.5)

@export_range(0.5, 120.0, 0.5, "or_greater") var sector_hold_duration_max := 12.0:
	set(value):
		sector_hold_duration_max = maxf(value, 0.5)

## Probabilita che una rotazione apra 2 settori invece di 1.
@export_range(0.0, 1.0, 0.01) var sector_multi_chance := 0.3:
	set(value):
		sector_multi_chance = clampf(value, 0.0, 1.0)

## Probabilita che una rotazione apra un picco a 3-4 settori simultanei.
@export_range(0.0, 1.0, 0.01) var sector_spike_chance := 0.08:
	set(value):
		sector_spike_chance = clampf(value, 0.0, 1.0)

@export_group("Archetypes")
## Peso del profilo base (piccione) nel pool pesato dello spawner (B40): un
## valore alto rispetto ai pesi degli archetipi lo mantiene dominante finche'
## gli altri non sono numerosi o non hanno peso comparabile.
@export_range(0.0, 64.0, 0.01, "or_greater") var base_archetype_weight := 6.0:
	set(value):
		base_archetype_weight = maxf(value, 0.0) if is_finite(value) else 0.0

@export_group("Cleanup")
@export_range(0.01, 60.0, 0.01, "or_greater") var cleanup_interval := 1.0:
	set(value):
		cleanup_interval = maxf(value, MINIMUM_INTERVAL_SECONDS)

@export_range(0.0, 4096.0, 1.0, "or_greater") var despawn_margin := 320.0:
	set(value):
		despawn_margin = maxf(value, 0.0)


func get_spawn_interval(run_time: float) -> float:
	var sanitized_run_time := maxf(run_time, 0.0)
	return maxf(
		min_spawn_interval,
		base_spawn_interval - sanitized_run_time * spawn_acceleration
	)


func get_progression_reference_spawn_interval(run_time: float) -> float:
	var sanitized_run_time := maxf(run_time, 0.0)
	return maxf(
		progression_reference_min_spawn_interval,
		progression_reference_base_spawn_interval
			- sanitized_run_time * progression_reference_spawn_acceleration
	)


func get_experience_reward_scale(run_time: float) -> float:
	var reference_interval := get_progression_reference_spawn_interval(run_time)
	if reference_interval <= 0.0:
		return 1.0
	# Con uno spawn ogni N secondi, il valore XP per kill usa N / N_ref; il
	# moltiplicatore mantiene il nuovo ritmo dichiarato senza tornare a 1 XP/kill.
	return maxf(
		get_spawn_interval(run_time) / reference_interval * progression_experience_multiplier,
		0.0
	)


func get_effective_outer_spawn_margin() -> float:
	return maxf(inner_spawn_margin, outer_spawn_margin)


func get_effective_pursuit_offset_min_radius() -> float:
	return minf(pursuit_offset_min_radius, pursuit_offset_max_radius)


func get_effective_pursuit_offset_max_radius() -> float:
	return maxf(pursuit_offset_min_radius, pursuit_offset_max_radius)


func get_effective_sector_hold_duration_min() -> float:
	return minf(sector_hold_duration_min, sector_hold_duration_max)


func get_effective_sector_hold_duration_max() -> float:
	return maxf(sector_hold_duration_min, sector_hold_duration_max)


func get_effective_despawn_margin() -> float:
	return maxf(get_effective_outer_spawn_margin(), despawn_margin)


func get_effective_cleanup_interval() -> float:
	return maxf(cleanup_interval, MINIMUM_INTERVAL_SECONDS)
