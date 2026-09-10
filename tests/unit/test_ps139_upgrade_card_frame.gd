extends GutGameplayTest

## PS-139: verifica che la carta upgrade abbia i quattro ornamenti d'angolo
## (un solo `Texture2D` riusato via `flip_h`/`flip_v`, PS-152), visibili in
## offerta normale e nascosti durante il trattamento Speciality di Barb
## (stile distinto, non oggetto di questa card). Il bordo dello stato normale
## resta blu (freddo): PS-036 lo usa come identità di sistema per distinguere
## le carte level-up/bonus (fredde) dalle carte Speciality di Barb (calde) —
## la cornice dorata a rivetti arriva solo dai quattro angoli, non
## ricolorando il bordo. Verifica anche che gli stati restino distinguibili
## fra loro e che gli ornamenti non si sovrappongano al contenuto reale
## (icona, titolo). Il file d'angolo referenziato è oggi un placeholder
## deterministico (PS-110): questo test verifica il cablaggio, non la resa
## pixel-perfetta dell'asset reale, che resta un gate percettivo manuale
## validato dal direttore-artistico (bocciato una prima volta sul tentativo
## di ritaglio diretto di `pause_panel_frame.png`, vedi Decisioni di PS-139).

const UPGRADE_CARD_SCENE := preload("res://scenes/ui/upgrade_card.tscn")
# Valore esatto del bordo piatto sostituito da questa card: un valore diverso
# non e' di per se' garanzia di correttezza (vedi PS-036 sopra), ma il ritorno
# esatto a questo valore indicherebbe che la modifica non e' stata applicata.
const OLD_FLAT_BORDER_COLOR := Color(0.19, 0.48, 0.68, 0.9)
const CORNER_NAMES: Array[StringName] = [
	&"CornerTopLeft", &"CornerTopRight", &"CornerBottomLeft", &"CornerBottomRight",
]


func test_ps139_normal_style_no_longer_flat_blue_border() -> void:
	var card := UPGRADE_CARD_SCENE.instantiate() as UpgradeCard
	add_child_autofree(card)
	await wait_process_frames(1)

	var normal_style := card.get_theme_stylebox(&"normal") as StyleBoxFlat
	assert_true(normal_style != null, "La carta deve avere uno StyleBoxFlat per lo stato normal.")
	if normal_style == null:
		return
	assert_ne(
		normal_style.border_color, OLD_FLAT_BORDER_COLOR,
		"Il bordo normale non deve più essere il blu-grigio piatto sostituito da questa card."
	)


func test_ps139_states_remain_distinct() -> void:
	var card := UPGRADE_CARD_SCENE.instantiate() as UpgradeCard
	add_child_autofree(card)
	await wait_process_frames(1)

	var normal_style := card.get_theme_stylebox(&"normal") as StyleBoxFlat
	var pressed_style := card.get_theme_stylebox(&"pressed") as StyleBoxFlat
	var focus_style := card.get_theme_stylebox(&"focus") as StyleBoxFlat
	var disabled_style := card.get_theme_stylebox(&"disabled") as StyleBoxFlat
	assert_true(
		(
			normal_style != null and pressed_style != null
			and focus_style != null and disabled_style != null
		),
		"Normal, pressed, focus e disabled devono restare StyleBoxFlat distinti."
	)
	if normal_style == null or pressed_style == null or focus_style == null or disabled_style == null:
		return

	assert_ne(normal_style.border_color, pressed_style.border_color, "Normal e pressed devono restare distinguibili.")
	assert_ne(normal_style.border_color, disabled_style.border_color, "Normal e disabled devono restare distinguibili.")
	assert_ne(pressed_style.border_color, disabled_style.border_color, "Pressed e disabled devono restare distinguibili.")
	assert_false(focus_style.draw_center, "Il focus deve restare un anello sovrapposto, non un riempimento pieno.")


func test_ps139_corner_ornaments_present_and_share_one_texture() -> void:
	var card := UPGRADE_CARD_SCENE.instantiate() as UpgradeCard
	add_child_autofree(card)
	await wait_process_frames(1)

	var shared_texture: Texture2D = null
	for corner_name in CORNER_NAMES:
		var corner := card.get_node_or_null(NodePath(corner_name)) as TextureRect
		assert_true(corner != null, "La carta deve avere l'ornamento d'angolo %s." % corner_name)
		if corner == null:
			continue
		assert_true(
			corner.texture != null and corner.texture.resource_path.ends_with(
				"upgrade_card_corner.png"
			),
			"%s deve usare l'asset dedicato dell'ornamento d'angolo (PS-152)." % corner_name
		)
		if shared_texture == null:
			shared_texture = corner.texture
		else:
			assert_eq(
				corner.texture, shared_texture,
				"%s deve riusare lo stesso file degli altri angoli (un solo master, PS-152)." % corner_name
			)
		assert_true(corner.mouse_filter == Control.MOUSE_FILTER_IGNORE, "%s non deve intercettare l'input." % corner_name)

	var top_left := card.get_node(^"CornerTopLeft") as TextureRect
	var top_right := card.get_node(^"CornerTopRight") as TextureRect
	var bottom_left := card.get_node(^"CornerBottomLeft") as TextureRect
	var bottom_right := card.get_node(^"CornerBottomRight") as TextureRect
	assert_false(top_left.flip_h or top_left.flip_v, "L'angolo in alto a sinistra è il master, senza mirroring.")
	assert_true(top_right.flip_h and not top_right.flip_v, "L'angolo in alto a destra deve essere speculare orizzontalmente.")
	assert_true(bottom_left.flip_v and not bottom_left.flip_h, "L'angolo in basso a sinistra deve essere speculare verticalmente.")
	assert_true(bottom_right.flip_h and bottom_right.flip_v, "L'angolo in basso a destra deve essere speculare su entrambi gli assi.")


func test_ps139_corner_ornaments_visible_in_normal_offer_hidden_in_speciality() -> void:
	var card := UPGRADE_CARD_SCENE.instantiate() as UpgradeCard
	add_child_autofree(card)
	await wait_process_frames(1)

	for corner_name in CORNER_NAMES:
		var corner := card.get_node(NodePath(corner_name)) as TextureRect
		assert_true(corner.visible, "%s deve essere visibile nell'offerta normale." % corner_name)

	card.set_speciality_treatment(true)
	for corner_name in CORNER_NAMES:
		var corner := card.get_node(NodePath(corner_name)) as TextureRect
		assert_false(
			corner.visible,
			"%s non deve comparire nel trattamento Speciality Barb (stile distinto, PS-047)." % corner_name
		)

	card.set_speciality_treatment(false)
	for corner_name in CORNER_NAMES:
		var corner := card.get_node(NodePath(corner_name)) as TextureRect
		assert_true(corner.visible, "%s deve ricomparire tornando all'offerta normale." % corner_name)


func test_ps139_corner_ornaments_do_not_cover_real_content() -> void:
	var definition := load("res://data/upgrades/wide_magnet.tres") as UpgradeDefinition
	var card := UPGRADE_CARD_SCENE.instantiate() as UpgradeCard
	add_child_autofree(card)
	card.position = Vector2(40, 40)
	await wait_process_frames(1)
	assert_true(card.configure(definition, 0, 0), "La carta deve configurarsi con una definizione reale.")
	await wait_process_frames(3)

	var icon := card.get_node("Margins/Content/IconCenter/Icon") as Control
	var title := card.get_node("Margins/Content/TitleLabel") as Control
	assert_true(icon != null and title != null, "La carta configurata deve avere icona e titolo.")
	if icon == null or title == null:
		return

	var icon_rect := icon.get_global_rect()
	var title_rect := title.get_global_rect()
	for corner_name in CORNER_NAMES:
		var corner := card.get_node(NodePath(corner_name)) as Control
		var corner_rect := corner.get_global_rect()
		assert_false(
			corner_rect.intersects(icon_rect),
			"%s non deve sovrapporsi all'icona reale della carta." % corner_name
		)
		assert_false(
			corner_rect.intersects(title_rect),
			"%s non deve sovrapporsi al titolo reale della carta." % corner_name
		)

	print("PS139_UPGRADE_CARD_FRAME_OK")
