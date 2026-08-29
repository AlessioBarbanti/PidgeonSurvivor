class_name PresentationTimings
extends RefCounted

# B18R candidate timings. They remain presentation-only and can be tuned after
# the Windows/Pixel 9 perceptual gate without changing gameplay data.
## Durata della coda visiva non interattiva delle abilita' (ex burst icona).
const ABILITY_VFX_TAIL_SECONDS := 1.20
const ONE_SHOT_ENTRY_SECONDS := 0.18
const ONE_SHOT_EXIT_SECONDS := 0.38
const COSPLAY_ACCENT_SECONDS := 1.00
const INSTINCTIVE_DODGE_ACCENT_SECONDS := 0.60

const PLAYER_DAMAGE_FLASH_SECONDS := 0.075
const PLAYER_DAMAGE_BLINK_INTERVAL_SECONDS := 0.10
const ENEMY_DAMAGE_FLASH_SECONDS := 0.08
const PLAYER_DAMAGE_REACTION_SECONDS := 0.30
const ENEMY_HIT_REACTION_SECONDS := 0.26

const HIT_SPARK_SECONDS := 0.14
const DEATH_BURST_SECONDS := 0.78
const PLAYER_DAMAGE_BURST_SECONDS := 0.46
const HUD_HEALTH_FEEDBACK_SECONDS := 0.36
const ABILITY_READY_PULSE_SECONDS := 0.60
## B52: durata della dissolvenza del controllo abilita' quando il Player gli
## passa sotto. Breve, cosi' l'icona si toglie di mezzo senza sfarfallare.
const HUD_ABILITY_FADE_SECONDS := 0.18


static func is_valid() -> bool:
	return (
		ABILITY_VFX_TAIL_SECONDS > 0.72
		and ONE_SHOT_ENTRY_SECONDS > 0.0
		and ONE_SHOT_EXIT_SECONDS > 0.0
		and ONE_SHOT_ENTRY_SECONDS + ONE_SHOT_EXIT_SECONDS < ABILITY_VFX_TAIL_SECONDS
		and COSPLAY_ACCENT_SECONDS > 0.65
		and INSTINCTIVE_DODGE_ACCENT_SECONDS > 0.3
		and PLAYER_DAMAGE_FLASH_SECONDS <= 0.08
		and PLAYER_DAMAGE_BLINK_INTERVAL_SECONDS >= 0.08
		and PLAYER_DAMAGE_BLINK_INTERVAL_SECONDS <= 0.16
		and ENEMY_DAMAGE_FLASH_SECONDS <= 0.08
		and PLAYER_DAMAGE_REACTION_SECONDS > PLAYER_DAMAGE_FLASH_SECONDS
		and ENEMY_HIT_REACTION_SECONDS > ENEMY_DAMAGE_FLASH_SECONDS
		and DEATH_BURST_SECONDS > 0.38
		and PLAYER_DAMAGE_BURST_SECONDS > 0.24
		and HUD_HEALTH_FEEDBACK_SECONDS > 0.18
		and ABILITY_READY_PULSE_SECONDS > 0.24
		and HUD_ABILITY_FADE_SECONDS > 0.0
		and HUD_ABILITY_FADE_SECONDS < HUD_HEALTH_FEEDBACK_SECONDS
	)


static func normalized_progress_from_remaining(remaining: float, total: float) -> float:
	if not is_finite(remaining) or not is_finite(total) or total <= 0.0:
		return 1.0
	return 1.0 - clampf(remaining / total, 0.0, 1.0)


static func one_shot_opacity(
	elapsed: float,
	total: float,
	entry: float = ONE_SHOT_ENTRY_SECONDS,
	exit: float = ONE_SHOT_EXIT_SECONDS
) -> float:
	if not is_finite(elapsed) or not is_finite(total) or total <= 0.0:
		return 0.0
	var safe_elapsed := clampf(elapsed, 0.0, total)
	var safe_entry := clampf(entry, 0.0, total)
	var safe_exit := clampf(exit, 0.0, total)
	var fade_in := (
		smoothstep(0.0, safe_entry, safe_elapsed)
		if safe_entry > 0.0
		else 1.0
	)
	var exit_start := maxf(total - safe_exit, safe_entry)
	var fade_out := (
		1.0 - smoothstep(exit_start, total, safe_elapsed)
		if safe_exit > 0.0
		else 1.0
	)
	return clampf(minf(fade_in, fade_out), 0.0, 1.0)
