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


func get_effective_outer_spawn_margin() -> float:
	return maxf(inner_spawn_margin, outer_spawn_margin)


func get_effective_despawn_margin() -> float:
	return maxf(get_effective_outer_spawn_margin(), despawn_margin)


func get_effective_cleanup_interval() -> float:
	return maxf(cleanup_interval, MINIMUM_INTERVAL_SECONDS)
