extends GutTest

## PS-146: le barre HP/XP dell'HUD devono leggersi come un elemento "sospeso"
## sopra la scena, non incorniciato a piena larghezza. Verifica che il
## pannello esterno non disegni più lo stesso StyleBox del track interno
## (niente doppio bordo), che il track/colore della ProgressBar resti quello
## di PS-140 e che pannello ed etichette abbiano i nuovi margini laterali.

const HUD_SCENE := preload("res://scenes/ui/hud.tscn")


func test_ps146_hud_bars_floating_no_double_border() -> void:
	var hud := HUD_SCENE.instantiate() as GameHud
	add_child_autofree(hud)
	await wait_frames(1)

	var experience_panel := hud.get_node("%ExperiencePanel") as PanelContainer
	var health_panel := hud.get_node("%HealthPanel") as PanelContainer
	var experience_bar := hud.get_node("%ExperienceBar") as ProgressBar
	var health_bar := hud.get_node("%HealthBar") as ProgressBar
	assert_true(
		experience_panel != null and health_panel != null and experience_bar != null and health_bar != null,
		"PS-146 richiede pannelli e barre HP/XP dalla scena HUD."
	)
	if experience_panel == null or health_panel == null or experience_bar == null or health_bar == null:
		return

	# Il pannello esterno non disegna più lo StyleBox condiviso col track: niente doppio bordo.
	var experience_panel_style := experience_panel.get_theme_stylebox(&"panel")
	var health_panel_style := health_panel.get_theme_stylebox(&"panel")
	var experience_bar_style := experience_bar.get_theme_stylebox(&"background") as StyleBoxFlat
	var health_bar_style := health_bar.get_theme_stylebox(&"background") as StyleBoxFlat

	assert_true(
		experience_panel_style is StyleBoxEmpty, "ExperiencePanel deve usare uno StyleBoxEmpty, non il bordo del track."
	)
	assert_true(
		health_panel_style is StyleBoxEmpty, "HealthPanel deve usare uno StyleBoxEmpty, non il bordo del track."
	)
	assert_ne(
		experience_panel_style, experience_bar_style,
		"Pannello e barra XP non devono più condividere lo stesso StyleBox (doppio bordo)."
	)
	assert_ne(
		health_panel_style, health_bar_style,
		"Pannello e barra HP non devono più condividere lo stesso StyleBox (doppio bordo)."
	)

	# Lo StyleBoxEmpty preserva l'inset attuale via content_margin, cosi' la ProgressBar non cambia dimensione.
	var empty_style := experience_panel_style as StyleBoxEmpty
	assert_eq(empty_style.content_margin_left, 3.0, "content_margin_left deve preservare l'inset attuale (3px).")
	assert_eq(empty_style.content_margin_top, 3.0, "content_margin_top deve preservare l'inset attuale (3px).")
	assert_eq(empty_style.content_margin_right, 3.0, "content_margin_right deve preservare l'inset attuale (3px).")
	assert_eq(empty_style.content_margin_bottom, 2.0, "content_margin_bottom deve preservare l'inset attuale (2px).")

	# Il track/colore della ProgressBar resta quello di PS-140: nessuna proprieta' del track cambia.
	assert_not_null(experience_bar_style, "ExperienceBar deve conservare il proprio StyleBoxFlat di sfondo.")
	assert_not_null(health_bar_style, "HealthBar deve conservare il proprio StyleBoxFlat di sfondo.")
	if experience_bar_style != null and health_bar_style != null:
		assert_eq(
			experience_bar_style.border_color, health_bar_style.border_color,
			"HP e XP devono continuare a condividere lo stesso bordo/colore del track."
		)

	# Le barre non toccano piu' i lati dello schermo: stesso margine 20px gia' in uso nell'HUD.
	assert_eq(experience_panel.offset_left, 20.0, "ExperiencePanel deve avere offset_left=20.")
	assert_eq(experience_panel.offset_right, -20.0, "ExperiencePanel deve avere offset_right=-20.")
	assert_eq(health_panel.offset_left, 20.0, "HealthPanel deve avere offset_left=20.")
	assert_eq(health_panel.offset_right, -20.0, "HealthPanel deve avere offset_right=-20.")

	# Le etichette seguono il nuovo inset, restando allineate all'inizio della barra.
	var experience_label := hud.get_node("%ExperienceKindLabel") as Label
	var health_label := hud.get_node("%HealthKindLabel") as Label
	assert_true(
		experience_label != null and health_label != null, "PS-146 richiede le etichette XP/HP dalla scena HUD."
	)
	if experience_label != null and health_label != null:
		assert_eq(experience_label.offset_left, 30.0, "ExperienceKindLabel deve avere offset_left=30.")
		assert_eq(experience_label.offset_right, 78.0, "ExperienceKindLabel deve avere offset_right=78.")
		assert_eq(health_label.offset_left, 30.0, "HealthKindLabel deve avere offset_left=30.")
		assert_eq(health_label.offset_right, 78.0, "HealthKindLabel deve avere offset_right=78.")

	print("PS146_HUD_BARS_FLOATING_OK")
