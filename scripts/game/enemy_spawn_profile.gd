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

@export_group("Late Run")
## La curva qualitativa parte dopo l'ingresso di tutti gli archetipi e arriva
## gradualmente al pieno valore: prima della soglia il pool B40 resta identico.
@export_range(0.0, 3600.0, 1.0, "or_greater") var late_run_curve_start_seconds := 60.0:
	set(value):
		late_run_curve_start_seconds = maxf(value, 0.0) if is_finite(value) else 0.0

@export_range(0.0, 3600.0, 1.0, "or_greater") var late_run_curve_full_seconds := 300.0:
	set(value):
		late_run_curve_full_seconds = maxf(value, 0.0) if is_finite(value) else 0.0

## Quota residua del peso del piccione base a curva piena. Non modifica HP,
## danno o statistiche del Player: cambia soltanto la composizione del pool.
@export_range(0.0, 1.0, 0.01) var late_run_base_weight_multiplier := 0.33:
	set(value):
		late_run_base_weight_multiplier = clampf(value, 0.0, 1.0)

@export_range(0.0, 1.0, 0.01) var late_run_sector_multi_chance := 0.65:
	set(value):
		late_run_sector_multi_chance = clampf(value, 0.0, 1.0)

@export_range(0.0, 1.0, 0.01) var late_run_sector_spike_chance := 0.25:
	set(value):
		late_run_sector_spike_chance = clampf(value, 0.0, 1.0)

## Dopo questa soglia, il pool non puo' lasciare trascorrere piu' della
## finestra indicata senza generare il tiratore configurato. La minaccia resta
## un normale nemico telegrafato, non danno automatico o scaling sulla build.
@export_range(0.0, 3600.0, 1.0, "or_greater") var late_run_ranged_guarantee_start_seconds := 180.0:
	set(value):
		late_run_ranged_guarantee_start_seconds = maxf(value, 0.0) if is_finite(value) else 0.0

@export_range(0.1, 60.0, 0.1, "or_greater") var late_run_ranged_max_gap_seconds := 4.0:
	set(value):
		late_run_ranged_max_gap_seconds = maxf(value, 0.1) if is_finite(value) else 0.1

@export var late_run_ranged_archetype_id: StringName = &"ranged"

@export_group("Post Curve Pressure")
## PS-126: oltre late_run_curve_full_seconds nessuna curva di questa risorsa
## continua a crescere (pesi, spawn interval e cap sono gia' al loro
## estremo). Questo moltiplicatore lineare su HP/danno di ogni nemico
## spawnato (piccione base incluso) tiene viva la pressione per le run che
## proseguono oltre i 5 minuti (endless, PS-055): a 0.0 il comportamento
## resta identico a prima di PS-126.
@export_range(0.0, 4.0, 0.01, "or_greater") var post_curve_growth_per_minute := 0.15:
	set(value):
		post_curve_growth_per_minute = maxf(value, 0.0) if is_finite(value) else 0.0

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


func get_late_run_progress(run_time: float) -> float:
	var start := minf(late_run_curve_start_seconds, late_run_curve_full_seconds)
	var end := maxf(late_run_curve_start_seconds, late_run_curve_full_seconds)
	if end <= start:
		return 1.0 if run_time >= end else 0.0
	return clampf((maxf(run_time, 0.0) - start) / (end - start), 0.0, 1.0)


func get_effective_base_archetype_weight(run_time: float) -> float:
	return base_archetype_weight * lerpf(
		1.0,
		late_run_base_weight_multiplier,
		get_late_run_progress(run_time)
	)


func get_effective_archetype_weight(
	base_weight: float,
	late_run_multiplier: float,
	run_time: float
) -> float:
	var safe_weight := maxf(base_weight, 0.0) if is_finite(base_weight) else 0.0
	var safe_multiplier := maxf(late_run_multiplier, 0.0) if is_finite(late_run_multiplier) else 0.0
	return safe_weight * lerpf(1.0, safe_multiplier, get_late_run_progress(run_time))


func get_effective_sector_multi_chance(run_time: float) -> float:
	return lerpf(
		sector_multi_chance,
		late_run_sector_multi_chance,
		get_late_run_progress(run_time)
	)


func get_effective_sector_spike_chance(run_time: float) -> float:
	return lerpf(
		sector_spike_chance,
		late_run_sector_spike_chance,
		get_late_run_progress(run_time)
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


## PS-126: 1.0 fino a late_run_curve_full_seconds, poi cresce linearmente di
## post_curve_growth_per_minute ogni minuto oltre quella soglia. Si applica a
## HP/danno di ogni nemico spawnato, non alla cadenza o ai pesi (gia'
## governati da get_effective_* sopra).
func get_post_curve_pressure_multiplier(run_time: float) -> float:
	var sanitized_run_time := maxf(run_time, 0.0) if is_finite(run_time) else 0.0
	var elapsed_past_curve := maxf(sanitized_run_time - late_run_curve_full_seconds, 0.0)
	return 1.0 + (elapsed_past_curve / 60.0) * post_curve_growth_per_minute
