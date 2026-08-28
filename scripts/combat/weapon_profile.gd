class_name WeaponProfile
extends Resource

const MINIMUM_POSITIVE_VALUE := 0.001

@export_range(0.01, 100.0, 0.01, "or_greater") var shots_per_second := 4.0:
	set(value):
		shots_per_second = maxf(value, MINIMUM_POSITIVE_VALUE) if is_finite(value) else MINIMUM_POSITIVE_VALUE

@export_range(0.01, 100000.0, 0.1, "or_greater") var damage := 10.0:
	set(value):
		damage = maxf(value, MINIMUM_POSITIVE_VALUE) if is_finite(value) else MINIMUM_POSITIVE_VALUE

@export_range(1.0, 10000.0, 1.0, "or_greater") var projectile_speed := 900.0:
	set(value):
		projectile_speed = maxf(value, MINIMUM_POSITIVE_VALUE) if is_finite(value) else MINIMUM_POSITIVE_VALUE

@export_range(0.01, 60.0, 0.01, "or_greater") var projectile_lifetime := 2.0:
	set(value):
		projectile_lifetime = maxf(value, MINIMUM_POSITIVE_VALUE) if is_finite(value) else MINIMUM_POSITIVE_VALUE

@export_range(1.0, 128.0, 0.5, "or_greater") var projectile_radius := 6.0:
	set(value):
		projectile_radius = maxf(value, 1.0) if is_finite(value) else 1.0

@export_range(0.0, 256.0, 0.5, "or_greater") var muzzle_offset := 32.0:
	set(value):
		muzzle_offset = maxf(value, 0.0) if is_finite(value) else 0.0

## Bersagli attraversabili di base prima di applicare le carte di perforazione.
@export_range(1, 20, 1, "or_greater") var base_pierce_count := 1:
	set(value):
		base_pierce_count = maxi(value, 1)

@export_range(0.01, 1.0, 0.01) var base_pierce_damage_falloff := 1.0:
	set(value):
		base_pierce_damage_falloff = clampf(value, 0.01, 1.0) if is_finite(value) else 1.0

## Proiettili sparati per colpo di base prima di applicare le carte di raffica.
@export_range(1, 20, 1, "or_greater") var base_multishot_count := 1:
	set(value):
		base_multishot_count = maxi(value, 1)

@export_range(0.0, 179.0, 0.1, "or_greater") var base_multishot_spread_degrees := 0.0:
	set(value):
		base_multishot_spread_degrees = clampf(value, 0.0, 179.0) if is_finite(value) else 0.0


func get_fire_interval() -> float:
	return 1.0 / shots_per_second
