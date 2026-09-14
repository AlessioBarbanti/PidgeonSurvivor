extends GutGameplayTest

## PS-176: ritratto Boss "fluttuante" mostrato per intero in `contain` dentro
## la safe area, senza pannello ne cornice esterna, con la citazione
## sovrapposta come percentuale del ritratto scalato (non coordinate
## hardcoded). Copre tutte e 9 le varianti (8 Evil + Piccione Malvagio).

const BOSS_UI_SCENE := preload("res://scenes/ui/boss_ui.tscn")

const EXPECTED_ASPECT_RATIO := 1.5  # 1536x1024, identico per le 9 varianti
const ASPECT_TOLERANCE := 0.02
const RECT_TOLERANCE := 4.0

# Percentuali misurate sul rettangolo verde di `assets/Evil portrais new/REFERENCE.png`.
const QUOTE_ANCHOR_LEFT := 0.325
const QUOTE_ANCHOR_TOP := 0.782
const QUOTE_ANCHOR_RIGHT := 0.673
const QUOTE_ANCHOR_BOTTOM := 0.884

const EVIL_FRIEND_IDS := ["alea", "aleo", "bea", "lollo", "magno", "marghe", "migi", "zat"]

# Stessa citazione di stress (167 caratteri) gia' usata da
# test_ps103_boss_intro_frame_wiring.gd.
const STRESS_QUOTE := (
	"Nessuno resiste al profumo della griglia quando la fame vince la " +
	"ragione: stanotte il fuoco brucia piu' forte e nessuno tornera' a " +
	"casa senza aver assaggiato la brace."
)

const ASPECT_PROFILES := [
	{"name": "16:9", "viewport": Vector2i(1280, 720)},
	{"name": "20:9", "viewport": Vector2i(1600, 720)},
	{"name": "4:3", "viewport": Vector2i(960, 720)},
]


func _build_nine_definitions() -> Array[BossDefinition]:
	var definitions: Array[BossDefinition] = []
	# `duplicate()`: la risorsa caricata e' condivisa e cachata dal motore, i
	# test mutano `quote`/`quote_approved` sulla copia per evitare di sporcare
	# lo stato letto da altri test che caricano lo stesso `.tres`.
	var baseline := (load("res://data/bosses/first_boss.tres") as BossDefinition).duplicate() as BossDefinition
	definitions.append(baseline)
	for friend_id in EVIL_FRIEND_IDS:
		var friend := load("res://data/friends/%s.tres" % friend_id) as FriendDefinition
		var evil := BossDefinition.new()
		evil.id = StringName("ps176_evil_%s" % friend_id)
		evil.visual_kind = BossDefinition.VisualKind.EVIL_FRIEND
		evil.friend_profile = friend
		evil.quote_approved = true
		evil.quote = "Citazione di prova per %s." % friend_id
		definitions.append(evil)
	return definitions


func _expected_quote_rect(portrait_rect: Rect2) -> Rect2:
	return Rect2(
		portrait_rect.position + portrait_rect.size * Vector2(QUOTE_ANCHOR_LEFT, QUOTE_ANCHOR_TOP),
		portrait_rect.size * Vector2(QUOTE_ANCHOR_RIGHT - QUOTE_ANCHOR_LEFT, QUOTE_ANCHOR_BOTTOM - QUOTE_ANCHOR_TOP)
	)


func test_intro_layer_has_no_panel_or_frame() -> void:
	var boss_ui := BOSS_UI_SCENE.instantiate() as BossUI
	add_child_autofree(boss_ui)
	await wait_process_frames(1)

	assert_true(
		boss_ui.get_node_or_null("IntroLayer/Center/IntroPanel") == null,
		"PS-176 rimuove IntroPanel: il ritratto non deve avere alcun pannello esterno."
	)
	assert_true(
		boss_ui.find_children("*", "PanelContainer", true, false).is_empty(),
		"La Boss Intro non deve contenere alcun PanelContainer/StyleBoxTexture."
	)
	assert_true(
		boss_ui.find_child("IntroTitleLabel", true, false) == null,
		"Il titolo del Boss deve essere rimosso dalla scena, non solo nascosto."
	)
	assert_true(
		boss_ui.find_child("SignatureIcon", true, false) == null,
		"L'icona Signature deve essere rimossa dalla scena, non solo nascosta."
	)


func test_nine_variants_contain_scale_quote_overlay_and_button_below_portrait() -> void:
	var slice := await instantiate_movement_slice()
	var boss_ui := slice.get_boss_ui() as BossUI
	assert_true(boss_ui != null, "PS-176 richiede BossUI nella scena della run.")
	if boss_ui == null:
		return

	for definition in _build_nine_definitions():
		assert_true(definition != null and definition.is_valid(), "La definizione di prova deve essere valida.")
		if definition == null:
			continue
		assert_true(boss_ui.show_intro(definition), "La intro deve potersi aprire per \"%s\"." % definition.id)
		await wait_process_frames(2)

		assert_true(boss_ui.is_intro_portrait_visible(), "\"%s\": il ritratto deve essere visibile." % definition.id)
		var portrait_rect := boss_ui.get_intro_portrait_rect()
		assert_true(
			portrait_rect.size.x > 1.0 and portrait_rect.size.y > 1.0,
			"\"%s\": il rettangolo del ritratto non deve essere vuoto." % definition.id
		)
		assert_true(
			portrait_rect.position.y >= boss_ui.get_global_rect().position.y + BossUI.CONTENT_TOP_MARGIN - 1.0,
			(
				"\"%s\": il ritratto non deve invadere la fascia HUD in alto "
				+ "(trovato dal controllo percettivo del direttore-artistico, PS-176)."
			) % definition.id
		)
		var rendered_ratio := portrait_rect.size.x / portrait_rect.size.y
		assert_almost_eq(
			rendered_ratio, EXPECTED_ASPECT_RATIO, ASPECT_TOLERANCE,
			"\"%s\": il ritratto deve restare in `contain` (3:2), senza crop ne distorsione." % definition.id
		)

		var expected_quote_rect := _expected_quote_rect(portrait_rect)
		var quote_rect := boss_ui.get_intro_quote_label_rect()
		assert_true(
			quote_rect.position.distance_to(expected_quote_rect.position) <= RECT_TOLERANCE
			and quote_rect.size.distance_to(expected_quote_rect.size) <= RECT_TOLERANCE,
			"\"%s\": la citazione deve restare sulla percentuale misurata su REFERENCE.png, non su coordinate hardcoded." % definition.id
		)

		var continue_button := boss_ui.get_continue_button()
		var button_rect := continue_button.get_global_rect()
		assert_true(
			button_rect.position.y >= portrait_rect.position.y + portrait_rect.size.y - 1.0,
			"\"%s\": AFFRONTA deve restare sotto il ritratto, mai sovrapposto." % definition.id
		)

		boss_ui.hide_intro()

	print("BOSS_INTRO_FLOATING_PORTRAIT_SMOKE_OK")


func test_stress_quote_stays_inside_caption_across_variants_and_aspect_ratios() -> void:
	var slice := await instantiate_movement_slice()
	var boss_ui := slice.get_boss_ui() as BossUI
	assert_true(boss_ui != null, "PS-176 richiede BossUI nella scena della run.")
	if boss_ui == null:
		return

	var quote_label := boss_ui.get_node_or_null("%IntroQuoteLabel") as RichTextLabel
	assert_true(
		quote_label != null and quote_label.clip_contents and not quote_label.fit_content,
		(
			"La citazione deve restare un RichTextLabel con fit_content=false e clip_contents=true: "
			+ "un Label con autowrap forzerebbe la propria size oltre il cartiglio con una citazione lunga."
		)
	)

	for profile in ASPECT_PROFILES:
		var viewport_size: Vector2i = profile.viewport
		get_tree().root.content_scale_size = viewport_size
		get_tree().root.size = viewport_size

		for definition in _build_nine_definitions():
			if definition == null:
				continue
			definition.quote_approved = true
			definition.quote = STRESS_QUOTE
			assert_true(
				boss_ui.show_intro(definition),
				"%s/\"%s\": la intro deve potersi aprire con la citazione di stress." % [profile.name, definition.id]
			)
			await wait_process_frames(2)

			var portrait_rect := boss_ui.get_intro_portrait_rect()
			var expected_quote_rect := _expected_quote_rect(portrait_rect)
			var quote_rect := boss_ui.get_intro_quote_label_rect()
			assert_true(
				quote_rect.position.distance_to(expected_quote_rect.position) <= RECT_TOLERANCE
				and quote_rect.size.distance_to(expected_quote_rect.size) <= RECT_TOLERANCE,
				(
					"%s/\"%s\": il rettangolo del cartiglio non deve spostarsi con una citazione di stress "
					+ "da 167 caratteri. portrait=%s expected=%s actual=%s"
				) % [profile.name, definition.id, portrait_rect, expected_quote_rect, quote_rect]
			)

			boss_ui.hide_intro()

	get_tree().root.content_scale_size = Vector2i(1280, 720)
	get_tree().root.size = Vector2i(1280, 720)


func test_missing_portrait_recomposes_without_empty_space() -> void:
	var slice := await instantiate_movement_slice()
	var boss_ui := slice.get_boss_ui() as BossUI
	assert_true(boss_ui != null, "PS-176 richiede BossUI nella scena della run.")
	if boss_ui == null:
		return

	var with_portrait := load("res://data/bosses/first_boss.tres") as BossDefinition
	assert_true(boss_ui.show_intro(with_portrait), "La intro deve aprirsi con il ritratto baseline.")
	await wait_process_frames(2)
	var button_y_with_portrait := boss_ui.get_continue_button().get_global_rect().position.y
	boss_ui.hide_intro()

	var missing_portrait := BossDefinition.new()
	missing_portrait.id = &"ps176_missing_portrait"
	missing_portrait.quote_approved = true
	missing_portrait.quote = "La intro deve reggere anche senza ritratto."
	missing_portrait.portrait = null
	assert_true(boss_ui.show_intro(missing_portrait), "La intro deve potersi aprire senza portrait.")
	await wait_process_frames(2)
	assert_false(
		boss_ui.is_intro_portrait_visible(),
		"Senza portrait il blocco ritratto+citazione deve restare nascosto invece di mostrare una texture nulla."
	)
	var button_y_without_portrait := boss_ui.get_continue_button().get_global_rect().position.y
	assert_true(
		button_y_without_portrait < button_y_with_portrait,
		"Senza ritratto il bottone deve risalire invece di lasciare uno spazio vuoto dedicato al ritratto mancante."
	)
	boss_ui.hide_intro()
