extends GutTest

## PS-140: il bordo delle barre HP/XP dell'HUD deve appartenere alla stessa
## famiglia oro/bronzo usata altrove nella stessa vista (bottone pausa,
## indicatore Alea), non restare la tinta marrone/tan scollegata introdotta
## in origine.

const HUD_SCENE := preload("res://scenes/ui/hud.tscn")

## Valore precedente da PS-140: Color(0.49, 0.39, 0.24, 1) — non più atteso.
const OLD_BROWN_BORDER := Color(0.49, 0.39, 0.24, 1)

## Bordo dorato già in uso dal bottone pausa nello stesso HUD (`hud.tscn`,
## `StyleBoxFlat_pause_normal`), preso come riferimento di famiglia.
const REFERENCE_GOLD := Color(0.72, 0.52, 0.24, 1)
const COLOR_TOLERANCE := 0.15


func test_ps140_hud_bar_border_color_matches_gold_family() -> void:
	var hud := HUD_SCENE.instantiate() as GameHud
	add_child_autofree(hud)
	await wait_frames(1)

	var health_bar := hud.get_node("%HealthBar") as ProgressBar
	var experience_bar := hud.get_node("%ExperienceBar") as ProgressBar
	assert_true(
		health_bar != null and experience_bar != null, "PS-140 richiede le barre HP/XP dalla scena HUD."
	)
	if health_bar == null or experience_bar == null:
		return

	var health_border := (health_bar.get_theme_stylebox(&"background") as StyleBoxFlat).border_color
	var experience_border := (experience_bar.get_theme_stylebox(&"background") as StyleBoxFlat).border_color

	assert_ne(health_border, OLD_BROWN_BORDER, "Il bordo HP non deve più essere il marrone/tan precedente.")
	assert_ne(experience_border, OLD_BROWN_BORDER, "Il bordo XP non deve più essere il marrone/tan precedente.")
	assert_eq(health_border, experience_border, "HP e XP condividono lo stesso StyleBox di sfondo.")

	var channel_delta := maxf(
		absf(health_border.r - REFERENCE_GOLD.r),
		maxf(absf(health_border.g - REFERENCE_GOLD.g), absf(health_border.b - REFERENCE_GOLD.b))
	)
	assert_true(
		channel_delta <= COLOR_TOLERANCE,
		(
			"Il bordo delle barre (%s) deve restare percepibilmente nella stessa famiglia oro del bottone pausa (%s)."
			% [health_border, REFERENCE_GOLD]
		)
	)

	print("PS140_HUD_BAR_BORDER_OK")
