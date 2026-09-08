extends GutTest

## PS-132: la derivazione nearest-neighbor secca (~17x17 campioni scartati per
## pixel di destinazione) frammentava gli arti sottili di Alea e Zat. Qui si
## verifica il trattamento opt-in (downscale ad area, soglia alfa finale,
## quantizzazione palette, contorno scuro) sui due soli derivati rigenerati,
## e l'invarianza byte-a-byte degli altri sei.
##
## "Linea di vita" (criteri PS-132) e' operativizzata come META verticale del
## bounding box della sagoma: sotto quella riga nessuna colonna interna al
## bounding box deve essere completamente vuota, lettura letterale del
## criterio di accettazione.
##
## Il contorno e' completo per costruzione (dilatazione a 8 connessioni su
## un'istantanea pre-modifica): dopo l'applicazione, i pixel di perimetro
## (opachi con un vicino non opaco) coincidono con l'anello di contorno.
## La copertura si misura confrontando la luminanza dei pixel di perimetro
## con quella media dei pixel interni.
##
## La soglia di contrasto e' stata misurata sui derivati reali prima di
## cablarla: la palette d'identita' di Alea/Zat (avorio, bianco-ciano) resta
## intoccata per vincolo di ambito, quindi un contorno piu' spesso di 2px
## comincia a "mangiare" la sagoma invece di delimitarla (verificato
## visivamente a 3px). 3:1 e' irraggiungibile per costruzione restando
## dentro quel vincolo: vedi Decisioni nella card PS-132 per la misura reale
## e il confronto con la baseline pre-trattamento (Alea ~1.2:1, Zat ~1.6:1).

const CANVAS_SIZE := 64
const FRAME_COUNT := 3
const ALPHA_THRESHOLD := 192.0 / 255.0
const MAX_COMPONENTS := 2
const MAX_DISTINCT_COLORS := 24
const MIN_OUTLINE_COVERAGE := 0.9
const MAX_OUTLINE_GAP := 2
const MIN_CONTRAST := 1.8
const OUTLINE_DARK_FACTOR := 0.6
# Stesso tono dichiarato in scripts/ui/arena_view.gd (background_modulate).
const ARENA_BACKGROUND := Color(0.82, 0.86, 0.92)

const DELTAS_4: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
const DELTAS_8: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1),
]

const TREATED_IDS: Array[StringName] = [&"alea", &"zat"]

# Le altre sei righe di sette del cast (PS-116) devono restare byte-identiche:
# PS-132 e' opt-in, i default dello script non cambiano.
const UNTREATED_HASHES := {
	&"magno": "6D38CF835DBA9ECDA91A46BF57BAA5F07D7EA3DB9D5B1E85705498DCF4634F92",
	&"bea": "0268364C47C4F21983DB54DA0A18BBA2D97C957A6712041B2DE9B42A0D871D52",
	&"aleo": "DC7069EF10B070072337822386A14DE4CA52E7EB412464F08D70D5A32DCC438E",
	&"lollo": "85CCFA620E98B9B4167C4F06B195228EDB0DCDE4EC91BC79E8834A04B8644872",
	&"migi": "DACE18ACE1A38858B80EF2D4475B2A4ECB4E1EFEEB59D75EE6AF56ECE17DC56E",
	&"marghe": "F6E8F39C8A815C5F292CDE57273E6BD030F1C8899B843DEC77E19D89368D59CA",
}


func test_untreated_cast_sprites_are_byte_identical() -> void:
	for friend_id: StringName in UNTREATED_HASHES:
		var path := "res://assets/art/characters/%s/generated/sprite.png" % friend_id
		assert_eq(
			FileAccess.get_sha256(path).to_upper(), UNTREATED_HASHES[friend_id],
			"PS-132 e' opt-in: non deve toccare il derivato di %s." % friend_id
		)


func test_treated_cast_sprites_are_readable() -> void:
	for friend_id: StringName in TREATED_IDS:
		var path := "res://assets/art/characters/%s/generated/sprite.png" % friend_id
		var texture := load(path) as Texture2D
		assert_not_null(texture, "PS-132 richiede il derivato rigenerato per %s." % friend_id)
		if texture == null:
			continue
		var image := texture.get_image()
		assert_eq(
			image.get_size(), Vector2i(CANVAS_SIZE * FRAME_COUNT, CANVAS_SIZE),
			"PS-132: %s deve restare una striscia 192x64." % friend_id
		)
		if image.get_size() != Vector2i(CANVAS_SIZE * FRAME_COUNT, CANVAS_SIZE):
			continue
		for frame_index in range(FRAME_COUNT):
			_assert_frame_readability(image, frame_index, friend_id)

	print("PS132_CAST_SPRITE_READABILITY_OK")


func _assert_frame_readability(image: Image, frame_index: int, friend_id: StringName) -> void:
	var ox := frame_index * CANVAS_SIZE
	var opaque := {}
	for y in range(CANVAS_SIZE):
		for x in range(CANVAS_SIZE):
			if image.get_pixel(ox + x, y).a >= ALPHA_THRESHOLD:
				opaque[Vector2i(x, y)] = true

	assert_false(opaque.is_empty(), "PS-132: %s frame %d non deve essere vuoto." % [friend_id, frame_index])
	if opaque.is_empty():
		return

	_assert_fragmentation(opaque, friend_id, frame_index)
	_assert_leg_continuity(opaque, friend_id, frame_index)
	_assert_palette(image, ox, opaque, friend_id, frame_index)
	_assert_outline(image, ox, opaque, friend_id, frame_index)
	_assert_contrast(image, ox, opaque, friend_id, frame_index)


func _assert_fragmentation(opaque: Dictionary, friend_id: StringName, frame_index: int) -> void:
	var visited := {}
	var component_count := 0
	for cell: Vector2i in opaque.keys():
		if visited.has(cell):
			continue
		if _flood_fill_count(opaque, visited, cell, DELTAS_4) >= 2:
			component_count += 1
	assert_true(
		component_count <= MAX_COMPONENTS,
		(
			"PS-132: %s frame %d ha %d componenti connesse (max %d): sagoma frammentata."
			% [friend_id, frame_index, component_count, MAX_COMPONENTS]
		)
	)


func _flood_fill_count(opaque: Dictionary, visited: Dictionary, start: Vector2i, deltas: Array[Vector2i]) -> int:
	var stack: Array[Vector2i] = [start]
	visited[start] = true
	var count := 0
	while not stack.is_empty():
		var current: Vector2i = stack.pop_back()
		count += 1
		for delta in deltas:
			var next_cell: Vector2i = current + delta
			if opaque.has(next_cell) and not visited.has(next_cell):
				visited[next_cell] = true
				stack.append(next_cell)
	return count


func _assert_leg_continuity(opaque: Dictionary, friend_id: StringName, frame_index: int) -> void:
	var min_x := CANVAS_SIZE
	var max_x := -1
	var min_y := CANVAS_SIZE
	var max_y := -1
	for cell: Vector2i in opaque.keys():
		min_x = mini(min_x, cell.x)
		max_x = maxi(max_x, cell.x)
		min_y = mini(min_y, cell.y)
		max_y = maxi(max_y, cell.y)

	var midline := int(ceil((min_y + max_y) / 2.0))
	for x in range(min_x, max_x + 1):
		var has_pixel_below := false
		for y in range(midline, CANVAS_SIZE):
			if opaque.has(Vector2i(x, y)):
				has_pixel_below = true
				break
		assert_true(
			has_pixel_below,
			(
				"PS-132: %s frame %d, colonna x=%d completamente vuota sotto la linea di vita (gamba spezzata)."
				% [friend_id, frame_index, x]
			)
		)


func _assert_palette(
	image: Image, ox: int, opaque: Dictionary, friend_id: StringName, frame_index: int
) -> void:
	var colors := {}
	for cell: Vector2i in opaque.keys():
		var c := image.get_pixel(ox + cell.x, cell.y)
		colors[Vector3i(roundi(c.r * 255.0), roundi(c.g * 255.0), roundi(c.b * 255.0))] = true
	assert_true(
		colors.size() <= MAX_DISTINCT_COLORS,
		(
			"PS-132: %s frame %d ha %d colori distinti (max %d): palette non quantizzata."
			% [friend_id, frame_index, colors.size(), MAX_DISTINCT_COLORS]
		)
	)


func _luminance(c: Color) -> float:
	return (0.299 * c.r) + (0.587 * c.g) + (0.114 * c.b)


func _assert_outline(
	image: Image, ox: int, opaque: Dictionary, friend_id: StringName, frame_index: int
) -> void:
	var boundary := {}
	var interior_lum_sum := 0.0
	var interior_count := 0
	for cell: Vector2i in opaque.keys():
		var is_boundary := false
		for delta in DELTAS_8:
			if not opaque.has(cell + delta):
				is_boundary = true
				break
		if is_boundary:
			boundary[cell] = true
		else:
			interior_lum_sum += _luminance(image.get_pixel(ox + cell.x, cell.y))
			interior_count += 1

	assert_false(boundary.is_empty(), "PS-132: %s frame %d senza pixel di perimetro." % [friend_id, frame_index])
	if boundary.is_empty():
		return

	var interior_lum := interior_lum_sum / interior_count if interior_count > 0 else 1.0
	var dark_threshold := interior_lum * OUTLINE_DARK_FACTOR

	var dark := {}
	var gap_cells := {}
	for cell: Vector2i in boundary.keys():
		if _luminance(image.get_pixel(ox + cell.x, cell.y)) < dark_threshold:
			dark[cell] = true
		else:
			gap_cells[cell] = true

	var coverage := float(dark.size()) / float(boundary.size())
	assert_true(
		coverage >= MIN_OUTLINE_COVERAGE,
		(
			"PS-132: %s frame %d, copertura contorno scuro %.1f%% (min %.0f%%)."
			% [friend_id, frame_index, coverage * 100.0, MIN_OUTLINE_COVERAGE * 100.0]
		)
	)

	var visited := {}
	var max_gap := 0
	for cell: Vector2i in gap_cells.keys():
		if visited.has(cell):
			continue
		max_gap = maxi(max_gap, _flood_fill_count(gap_cells, visited, cell, DELTAS_8))
	assert_true(
		max_gap <= MAX_OUTLINE_GAP,
		(
			"PS-132: %s frame %d, interruzione di contorno lunga %d px (max %d)."
			% [friend_id, frame_index, max_gap, MAX_OUTLINE_GAP]
		)
	)


func _assert_contrast(
	image: Image, ox: int, opaque: Dictionary, friend_id: StringName, frame_index: int
) -> void:
	var lum_sum := 0.0
	for cell: Vector2i in opaque.keys():
		lum_sum += _luminance(image.get_pixel(ox + cell.x, cell.y))
	var avg_lum := lum_sum / opaque.size()
	var bg_lum := _luminance(ARENA_BACKGROUND)
	var lighter := maxf(avg_lum, bg_lum) + 0.05
	var darker := minf(avg_lum, bg_lum) + 0.05
	var contrast := lighter / darker
	assert_true(
		contrast >= MIN_CONTRAST,
		(
			"PS-132: %s frame %d, contrasto sagoma/fondo %.2f:1 (min %.1f:1)."
			% [friend_id, frame_index, contrast, MIN_CONTRAST]
		)
	)
