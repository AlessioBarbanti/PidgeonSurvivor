class_name EnemyArchetypeDefinition
extends Resource

## Dati di un archetipo nemico oltre al piccione base (B40): sciamatore,
## corazzato, divisore e tiratore condividono questa stessa risorsa e si
## distinguono per la scena assegnata e per quali gruppi di campi usano.

@export_enum("Round", "Swarmer", "Armored", "Segmented", "Turret") var silhouette_kind := 0

@export_group("Identity")
@export var id: StringName = &""
@export var scene: PackedScene

## Peso relativo nel pool pesato dello spawner; 0 esclude l'archetipo.
@export_range(0.0, 64.0, 0.01, "or_greater") var spawn_weight := 1.0:
	set(value):
		spawn_weight = maxf(value, 0.0) if is_finite(value) else 0.0

## Moltiplicatore raggiunto gradualmente dalla curva qualitativa PS-007. Non
## modifica le statistiche dell'archetipo e resta inerte prima della soglia.
@export_range(0.0, 8.0, 0.01, "or_greater") var late_run_weight_multiplier := 1.0:
	set(value):
		late_run_weight_multiplier = maxf(value, 0.0) if is_finite(value) else 0.0

## Finestra temporale (secondi di run) in cui l'archetipo e' eleggibile.
@export_range(0.0, 3600.0, 1.0, "or_greater") var eligible_time_start := 0.0:
	set(value):
		eligible_time_start = maxf(value, 0.0) if is_finite(value) else 0.0

@export_range(0.0, 3600.0, 1.0, "or_greater") var eligible_time_end := 3600.0:
	set(value):
		eligible_time_end = maxf(value, 0.0) if is_finite(value) else 0.0

## Numero di unita' generate insieme a ogni spawn vinto da questo archetipo
## (lo sciamatore si presenta "in gruppo").
@export_range(1, 16, 1, "or_greater") var spawn_cluster_size := 1:
	set(value):
		spawn_cluster_size = maxi(value, 1)

@export_group("Stats")
@export_range(0.001, 1000000.0, 0.1, "or_greater") var health_max := 18.0:
	set(value):
		health_max = maxf(value, 0.001) if is_finite(value) else 0.001

@export_range(0.0, 2000.0, 1.0, "or_greater") var move_speed := 140.0:
	set(value):
		move_speed = maxf(value, 0.0) if is_finite(value) else 0.0

@export_range(1.0, 128.0, 0.5, "or_greater") var collision_radius := 20.0:
	set(value):
		collision_radius = maxf(value, 1.0) if is_finite(value) else 1.0

@export_range(0.0, 1000000.0, 0.1, "or_greater") var contact_damage := 20.0:
	set(value):
		contact_damage = maxf(value, 0.0) if is_finite(value) else 0.0

## Dato esplicito, non ricavato da health_max (contratto B40).
@export_range(1, 1000000, 1, "or_greater") var experience_amount := 1:
	set(value):
		experience_amount = maxi(value, 1)

@export_group("Visual")
@export var body_color := Color(0.93, 0.2, 0.36, 1.0)
@export var outline_color := Color(0.18, 0.025, 0.07, 1.0)
@export var accent_color := Color(1.0, 0.77, 0.22, 1.0)

## Sprite pixel dedicato dell'archetipo (B49). Se assente, BaseEnemy ricade sul
## disegno procedurale per silhouette_kind: nessun asset mancante lascia un
## nemico invisibile.
@export var sprite_frames: SpriteFrames

@export_group("Splitter")
## Usato solo dall'archetipo divisore: definizione del frammento generato
## alla morte. Deve puntare a un archetipo senza propria scissione, cosicche'
## la divisione non sia ricorsiva.
@export var split_fragment_definition: EnemyArchetypeDefinition
@export_range(1, 8, 1, "or_greater") var split_fragment_count := 2:
	set(value):
		split_fragment_count = maxi(value, 1)

@export_group("Ranged")
## Usati solo dall'archetipo tiratore.
@export_range(1.0, 4096.0, 1.0, "or_greater") var ranged_attack_range := 420.0:
	set(value):
		ranged_attack_range = maxf(value, 1.0) if is_finite(value) else 1.0

@export_range(0.0, 4096.0, 1.0, "or_greater") var ranged_preferred_distance := 320.0:
	set(value):
		ranged_preferred_distance = maxf(value, 0.0) if is_finite(value) else 0.0

@export_range(0.01, 10.0, 0.01, "or_greater") var ranged_telegraph_duration := 0.6:
	set(value):
		ranged_telegraph_duration = maxf(value, 0.01) if is_finite(value) else 0.01

@export_range(0.01, 60.0, 0.01, "or_greater") var ranged_attack_interval := 2.0:
	set(value):
		ranged_attack_interval = maxf(value, 0.01) if is_finite(value) else 0.01

@export_range(0.0, 1000000.0, 0.1, "or_greater") var ranged_projectile_damage := 8.0:
	set(value):
		ranged_projectile_damage = maxf(value, 0.0) if is_finite(value) else 0.0

@export_range(1.0, 4000.0, 1.0, "or_greater") var ranged_projectile_speed := 180.0:
	set(value):
		ranged_projectile_speed = maxf(value, 1.0) if is_finite(value) else 1.0

@export_range(0.01, 30.0, 0.01, "or_greater") var ranged_projectile_lifetime := 4.0:
	set(value):
		ranged_projectile_lifetime = maxf(value, 0.01) if is_finite(value) else 0.01

@export_range(1.0, 128.0, 0.5, "or_greater") var ranged_projectile_radius := 8.0:
	set(value):
		ranged_projectile_radius = maxf(value, 1.0) if is_finite(value) else 1.0

@export var ranged_telegraph_color := Color(1.0, 0.24, 0.18, 0.72)


func get_effective_eligible_time_start() -> float:
	return minf(eligible_time_start, eligible_time_end)


func get_effective_eligible_time_end() -> float:
	return maxf(eligible_time_start, eligible_time_end)


func is_eligible_at(run_time: float) -> bool:
	return (
		spawn_weight > 0.0
		and run_time >= get_effective_eligible_time_start()
		and run_time <= get_effective_eligible_time_end()
	)


func is_valid() -> bool:
	if scene == null or String(id).is_empty():
		return false
	if not is_finite(health_max) or health_max <= 0.0:
		return false
	if not is_finite(move_speed) or move_speed < 0.0:
		return false
	if not is_finite(collision_radius) or collision_radius <= 0.0:
		return false
	if not is_finite(contact_damage) or contact_damage < 0.0:
		return false
	if experience_amount <= 0:
		return false
	if (
		split_fragment_definition != null
		and split_fragment_definition.split_fragment_definition != null
	):
		return false
	return true
