class_name BossDefinition
extends Resource

const MINIMUM_POSITIVE_VALUE := 0.001

enum VisualKind {
	SPECIAL_PIGEON,
	EVIL_FRIEND,
}

@export var id: StringName = &"first_boss"
@export var title := "IL CAPOSQUADRA OMBRA"
@export var friend_profile: FriendDefinition
@export_multiline var quote := "Citazione personale in attesa di approvazione."
@export var quote_approved := false
@export_multiline var safe_quote_placeholder := "Il Boss entra nell'arena."

@export_group("Stats")
@export_range(1.0, 1000000.0, 1.0, "or_greater") var health_max := 2400.0
@export_range(0.0, 2000.0, 1.0, "or_greater") var move_speed := 85.0
@export_range(1.0, 256.0, 0.5, "or_greater") var collision_radius := 46.0
@export_range(0.0, 1000000.0, 1.0, "or_greater") var contact_damage := 25.0

@export_group("Pattern cadence")
@export_range(0.01, 60.0, 0.01, "or_greater") var initial_attack_delay := 1.5
@export_range(0.01, 60.0, 0.01, "or_greater") var pattern_interval := 2.5

@export_group("Baseline hardening")
## PS-127: il piccione baseline (mai Evil, mai una Signature) attacca con
## questo cooldown invece di `pattern_interval`, cosi' resta piu' aggressivo
## dei suoi stessi cloni Evil senza toccare il valore che questi ultimi
## ereditano per duplicazione da `resolve_variant()`.
@export_range(0.01, 60.0, 0.01, "or_greater") var baseline_pattern_interval := 1.6
## Frazione di vita residua sotto la quale il baseline attiva lo specchio a
## doppio attacco (PS-127): non una seconda entita', solo una seconda origine
## fantasma da cui ripetere ogni pattern normale.
@export_range(0.0, 1.0, 0.01) var split_health_ratio := 0.5
@export_range(1.0, 1024.0, 1.0, "or_greater") var split_ghost_distance := 96.0
@export_range(0.0, 16.0, 0.01, "or_greater") var split_ghost_orbit_speed := 0.8

@export_group("Feather line")
## PS-127: terzo pattern nativo del baseline (mai usato dagli Evil, che
## restano sul ciclo radiale/mirato/Signature). Un ventaglio di linee oblique
## (mai allineate agli assi dell'arena) attraversa il campo, ciascuna
## telegrafata e poi attraversata da una sequenza continua di
## proiettili-piuma, stile Tiratore.
@export_range(0.01, 10.0, 0.01, "or_greater") var feather_line_telegraph_duration := 0.9
## Numero di linee del ventaglio (ognuna attraversa il campo in entrambe le
## direzioni dall'origine, quindi conta come una singola "linea" anche se
## produce due raggi di piume opposti).
@export_range(1, 16, 1, "or_greater") var feather_line_count := 6
@export_range(1, 64, 1, "or_greater") var feather_line_projectile_count := 20
@export_range(0.01, 2.0, 0.01, "or_greater") var feather_line_launch_interval := 0.08
@export_range(0.0, 1000000.0, 0.1, "or_greater") var feather_line_projectile_damage := 10.0
@export_range(1.0, 4000.0, 1.0, "or_greater") var feather_line_projectile_speed := 420.0
@export_range(0.01, 30.0, 0.01, "or_greater") var feather_line_projectile_lifetime := 3.0
@export_range(1.0, 128.0, 0.5, "or_greater") var feather_line_projectile_radius := 7.0

@export_group("Radial volley")
@export_range(0.01, 10.0, 0.01, "or_greater") var radial_telegraph_duration := 0.75
@export_range(4, 64, 1, "or_greater") var radial_projectile_count := 12
@export_range(0.0, 1000000.0, 0.1, "or_greater") var radial_projectile_damage := 14.0
@export_range(1.0, 4000.0, 1.0, "or_greater") var radial_projectile_speed := 270.0
@export_range(0.01, 30.0, 0.01, "or_greater") var radial_projectile_lifetime := 4.0
@export_range(1.0, 128.0, 0.5, "or_greater") var radial_projectile_radius := 9.0

@export_group("Targeted blast")
@export_range(0.01, 10.0, 0.01, "or_greater") var targeted_telegraph_duration := 1.0
@export_range(1.0, 1024.0, 1.0, "or_greater") var targeted_blast_radius := 115.0
@export_range(0.0, 1000000.0, 0.1, "or_greater") var targeted_blast_damage := 26.0

@export_group("Signature")
## Signature Ability dell'Evil (PS-006). Il piccione baseline non ne ha:
## resta `null` e il terzo slot del ciclo va invece alla Scia di Piume
## (PS-127), esclusiva del baseline.
@export var signature: BossSignatureDefinition

@export_group("Visual")
@export var visual_kind := VisualKind.SPECIAL_PIGEON
@export var portrait: Texture2D
@export var sprite_modulate := Color.WHITE
@export var body_color := Color(0.55, 0.17, 0.92, 1.0)
@export var outline_color := Color(0.08, 0.015, 0.16, 1.0)
@export var accent_color := Color(1.0, 0.72, 0.18, 1.0)
@export var telegraph_color := Color(1.0, 0.24, 0.18, 0.72)


func get_safe_quote() -> String:
	var approved_quote := quote.strip_edges()
	if quote_approved and not approved_quote.is_empty():
		return approved_quote
	return safe_quote_placeholder.strip_edges()


func get_safe_title() -> String:
	if is_evil_variant() and friend_profile != null and friend_profile.is_valid():
		return friend_profile.get_public_evil_display_name()
	return title.strip_edges()


func get_safe_portrait() -> Texture2D:
	if is_evil_variant() and friend_profile != null and friend_profile.is_valid():
		return friend_profile.get_public_evil_portrait()
	return portrait


func get_visual_texture() -> Texture2D:
	if is_evil_variant() and friend_profile != null and friend_profile.is_valid():
		return friend_profile.get_gameplay_idle_right()
	return portrait


func is_evil_variant() -> bool:
	return visual_kind == VisualKind.EVIL_FRIEND


func has_signature() -> bool:
	return signature != null and signature.is_valid()


func is_valid() -> bool:
	return (
		not id.is_empty()
		and not get_safe_title().is_empty()
		and not get_safe_quote().is_empty()
		and visual_kind >= VisualKind.SPECIAL_PIGEON
		and visual_kind <= VisualKind.EVIL_FRIEND
		and (
			not is_evil_variant()
			or (friend_profile != null and friend_profile.is_valid())
		)
		and (signature == null or signature.is_valid())
		and is_finite(health_max)
		and health_max > 0.0
		and is_finite(move_speed)
		and move_speed >= 0.0
		and is_finite(collision_radius)
		and collision_radius > 0.0
		and is_finite(contact_damage)
		and contact_damage >= 0.0
		and _is_positive_finite(initial_attack_delay)
		and _is_positive_finite(pattern_interval)
		and _is_positive_finite(baseline_pattern_interval)
		and is_finite(split_health_ratio)
		and split_health_ratio >= 0.0
		and split_health_ratio <= 1.0
		and _is_positive_finite(split_ghost_distance)
		and is_finite(split_ghost_orbit_speed)
		and split_ghost_orbit_speed >= 0.0
		and _is_positive_finite(feather_line_telegraph_duration)
		and feather_line_count >= 1
		and feather_line_projectile_count >= 1
		and _is_positive_finite(feather_line_launch_interval)
		and _is_positive_finite(feather_line_projectile_damage)
		and _is_positive_finite(feather_line_projectile_speed)
		and _is_positive_finite(feather_line_projectile_lifetime)
		and _is_positive_finite(feather_line_projectile_radius)
		and _is_positive_finite(radial_telegraph_duration)
		and radial_projectile_count >= 4
		and _is_positive_finite(radial_projectile_damage)
		and _is_positive_finite(radial_projectile_speed)
		and _is_positive_finite(radial_projectile_lifetime)
		and _is_positive_finite(radial_projectile_radius)
		and _is_positive_finite(targeted_telegraph_duration)
		and _is_positive_finite(targeted_blast_radius)
		and _is_positive_finite(targeted_blast_damage)
	)


static func _is_positive_finite(value: float) -> bool:
	return is_finite(value) and value >= MINIMUM_POSITIVE_VALUE
