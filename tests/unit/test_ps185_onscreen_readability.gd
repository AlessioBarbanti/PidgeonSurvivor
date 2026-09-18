extends GutGameplayTest

## PS-185: ingrandisce gli elementi HUD critici per la leggibilita' in tempo
## reale (cronometro, tag XP/HP, spessore delle barre, avvisi) rispetto ai
## valori precedenti, senza toccare hitbox/danno/velocita' ne' ridurre il
## playfield. I valori "precedenti" sono quelli storici del progetto
## (cronometro 28px, tag XP/HP 13px, avviso Boss 23px, evento ondata 16px,
## margine interno barre 3/2px): questo smoke verifica che siano stati
## superati, non un valore esatto, cosi' un ulteriore ingrandimento futuro
## non lo rompe per costruzione.

const PREVIOUS_TIMER_FONT_SIZE := 28
const PREVIOUS_BAR_LABEL_FONT_SIZE := 13
const PREVIOUS_BOSS_WARNING_FONT_SIZE := 23
const PREVIOUS_WAVE_EVENT_FONT_SIZE := 16
const PREVIOUS_BAR_CONTENT_MARGIN := 2.0

const LAYOUT_PROFILES: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 720),
	Vector2i(960, 720),
]
const READABILITY_FLOAT_TOLERANCE := 1.0


func test_hud_text_and_bars_are_enlarged_without_layout_regression() -> void:
	var movement_slice := await instantiate_movement_slice()
	var controller := movement_slice.get_run_controller() as RunController
	var arena := movement_slice.get_node_or_null("ArenaLayout") as ArenaLayout
	var hud := movement_slice.get_hud() as GameHud
	assert_true(
		controller != null and arena != null and hud != null,
		"PS-185 richiede controller, ArenaLayout e HUD composti."
	)
	if controller == null or arena == null or hud == null:
		return
	controller.set_process(false)

	var time_label := hud.find_child("TimeLabel", true, false) as Label
	var xp_label := hud.find_child("ExperienceKindLabel", true, false) as Label
	var hp_label := hud.find_child("HealthKindLabel", true, false) as Label
	var boss_warning_label := hud.find_child("BossWarningLabel", true, false) as Label
	var wave_event_label := hud.find_child("WaveEventLabel", true, false) as Label
	var experience_panel := hud.find_child("ExperiencePanel", true, false) as PanelContainer
	var health_panel := hud.find_child("HealthPanel", true, false) as PanelContainer
	assert_true(
		time_label != null and xp_label != null and hp_label != null
		and boss_warning_label != null and wave_event_label != null
		and experience_panel != null and health_panel != null,
		"PS-185 richiede tutti i nodi testuali/barre dell'HUD."
	)
	if (
		time_label == null or xp_label == null or hp_label == null
		or boss_warning_label == null or wave_event_label == null
		or experience_panel == null or health_panel == null
	):
		controller.prepare_restart()
		return

	assert_true(
		time_label.get_theme_font_size("font_size") > PREVIOUS_TIMER_FONT_SIZE,
		"Il cronometro deve essere ingrandito oltre il valore precedente (%dpx)." % PREVIOUS_TIMER_FONT_SIZE
	)
	assert_true(
		xp_label.get_theme_font_size("font_size") > PREVIOUS_BAR_LABEL_FONT_SIZE,
		"Il tag XP deve essere ingrandito oltre il valore precedente (%dpx)." % PREVIOUS_BAR_LABEL_FONT_SIZE
	)
	assert_true(
		hp_label.get_theme_font_size("font_size") > PREVIOUS_BAR_LABEL_FONT_SIZE,
		"Il tag HP deve essere ingrandito oltre il valore precedente (%dpx)." % PREVIOUS_BAR_LABEL_FONT_SIZE
	)
	assert_true(
		boss_warning_label.get_theme_font_size("font_size") > PREVIOUS_BOSS_WARNING_FONT_SIZE,
		"L'avviso Boss deve essere ingrandito oltre il valore precedente (%dpx)." % PREVIOUS_BOSS_WARNING_FONT_SIZE
	)
	assert_true(
		wave_event_label.get_theme_font_size("font_size") > PREVIOUS_WAVE_EVENT_FONT_SIZE,
		"Il testo evento ondata deve essere ingrandito oltre il valore precedente (%dpx)." % PREVIOUS_WAVE_EVENT_FONT_SIZE
	)

	for panel in [experience_panel, health_panel]:
		var bar_style := panel.get_theme_stylebox("panel") as StyleBoxEmpty
		assert_true(bar_style != null, "Le barre XP/HP devono avere uno StyleBoxEmpty dedicato.")
		if bar_style == null:
			continue
		assert_true(
			bar_style.content_margin_top < PREVIOUS_BAR_CONTENT_MARGIN
			and bar_style.content_margin_bottom < PREVIOUS_BAR_CONTENT_MARGIN,
			"Il riempimento delle barre XP/HP deve guadagnare spessore riducendo il margine interno."
		)

	for profile in LAYOUT_PROFILES:
		get_tree().root.content_scale_size = profile
		get_tree().root.size = profile
		await wait_process_frames(2)
		arena.refresh_layout()
		await wait_process_frames(2)

		var context := "%dx%d" % [profile.x, profile.y]
		var safe_area := arena.get_safe_area_rect()
		var playfield := arena.get_playfield_rect()
		var expected_playfield := ArenaLayout.calculate_playfield_rect(
			safe_area, arena.target_aspect_ratio, hud.get_gameplay_top_inset()
		)
		assert_rect_near(
			playfield, expected_playfield,
			"%s: il playfield non deve regredire per l'ingrandimento dell'HUD." % context,
			READABILITY_FLOAT_TOLERANCE
		)

		var top_band := hud.get_top_band_rect()
		var xp_bar := hud.get_experience_panel_rect()
		var health_bar := hud.get_health_panel_rect()
		var timer := hud.get_timer_slot_rect()
		var pause_button := hud.get_pause_button_rect()
		assert_true(
			top_band.encloses(xp_bar) and top_band.encloses(health_bar) and top_band.encloses(timer)
			and top_band.encloses(pause_button),
			"%s: la fascia HUD deve continuare a contenere tutti i suoi elementi dopo l'ingrandimento." % context
		)
		assert_true(
			playfield.position.y >= top_band.end.y - READABILITY_FLOAT_TOLERANCE,
			"%s: il playfield non deve finire dietro l'HUD ingrandito." % context
		)

	get_tree().root.content_scale_size = LAYOUT_PROFILES[0]
	get_tree().root.size = LAYOUT_PROFILES[0]
	controller.prepare_restart()
	print("PS185_READABILITY_SMOKE_OK")
