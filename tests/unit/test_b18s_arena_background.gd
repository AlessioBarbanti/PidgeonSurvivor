extends GutGameplayTest

const BACKGROUND_PATH := "res://assets/art/arena/generated/texture_gravel.png"
const MANIFEST_PATH := "res://assets/art/arena/ASSET-MANIFEST.md"
const EXPECTED_SHA256 := "8EF8E91C6EBBEF5B8D68EB2CFD3777C69C79EE713ABE701103D709D73E20CFED"
const BACKGROUND_FLOAT_TOLERANCE := 0.01


func test_runtime_background_stays_raster_and_responsive() -> void:
	var movement_slice := await instantiate_movement_slice()
	var arena_view := movement_slice.get_arena_view() as ArenaView
	assert_not_null(arena_view, "B18S richiede ArenaView.")
	if arena_view == null:
		return

	assert_true(arena_view.has_raster_background(), "Lo sfondo raster deve essere assegnato.")
	assert_false(arena_view.uses_procedural_fallback(), "La scena runtime non deve usare il fallback procedurale.")
	assert_eq(
		arena_view.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST, "Il filtro texture deve restare nearest-neighbor."
	)
	var texture := arena_view.background_texture
	if texture == null:
		return
	assert_eq(texture.get_size(), Vector2(256.0, 256.0), "Il derivato runtime deve essere 256 x 256.")
	assert_true(
		arena_view.background_modulate.r <= 0.9
		and arena_view.background_modulate.g <= 0.9
		and arena_view.background_modulate.b <= 0.95,
		"La modulazione runtime deve mantenere basso il contrasto."
	)

	var playfield_before := arena_view.get_playfield_rect()
	var test_sizes := [
		Vector2(1280.0, 720.0),
		Vector2(2400.0, 1080.0),
		Vector2(1024.0, 768.0),
	]
	for size in test_sizes:
		var destination := Rect2(Vector2(13.0, 91.0), size)
		var source := ArenaView.calculate_background_source_rect(destination, texture.get_size())
		assert_true(source.has_area(), "Ogni aspect ratio deve produrre un crop valido.")
		assert_true(source.position.x >= 0.0 and source.position.y >= 0.0, "Il crop deve restare nella texture.")
		assert_true(
			source.end.x <= texture.get_size().x + BACKGROUND_FLOAT_TOLERANCE
			and source.end.y <= texture.get_size().y + BACKGROUND_FLOAT_TOLERANCE,
			"Il crop responsive non deve oltrepassare la texture."
		)
		assert_almost_eq(
			source.size.x / source.size.y,
			size.x / size.y,
			BACKGROUND_FLOAT_TOLERANCE,
			"Il crop aspect-cover non deve deformare il raster."
		)
	assert_eq(
		arena_view.get_playfield_rect(), playfield_before, "Il calcolo presentazionale non deve modificare la geometria del playfield."
	)


func test_source_asset_is_approved_and_dark() -> void:
	assert_true(FileAccess.file_exists(BACKGROUND_PATH), "Il PNG runtime B18S deve esistere.")
	assert_true(FileAccess.file_exists(MANIFEST_PATH), "Il manifest B18S deve esistere.")
	if not FileAccess.file_exists(BACKGROUND_PATH):
		return
	var imported_texture := load(BACKGROUND_PATH) as Texture2D
	assert_not_null(imported_texture, "Il PNG B18S deve essere importato come Texture2D.")
	if imported_texture == null:
		return
	var image := imported_texture.get_image()
	assert_true(image != null and not image.is_empty(), "La texture importata deve esporre i pixel.")
	if image == null or image.is_empty():
		return
	assert_true(image.get_width() == 256 and image.get_height() == 256, "Dimensioni PNG B38 inattese.")
	assert_eq(image.detect_alpha(), Image.ALPHA_NONE, "Lo sfondo opaco non deve allocare un canale alpha inutile.")

	var luminance_sum := 0.0
	var luminance_max := 0.0
	var sample_count := 0
	for y in range(0, image.get_height(), 4):
		for x in range(0, image.get_width(), 4):
			var color := image.get_pixel(x, y)
			var luminance := color.get_luminance()
			luminance_sum += luminance
			luminance_max = maxf(luminance_max, luminance)
			sample_count += 1
	var luminance_average := luminance_sum / float(maxi(sample_count, 1))
	assert_true(luminance_average <= 0.22, "La luminanza media deve restare dietro al gameplay.")
	assert_true(luminance_max <= 0.52, "Lo sfondo non deve contenere highlight dominanti.")

	var digest := _sha256_file(BACKGROUND_PATH)
	assert_eq(digest, EXPECTED_SHA256, "Lo SHA-256 del PNG deve corrispondere al manifest.")
	var manifest := FileAccess.get_file_as_string(MANIFEST_PATH)
	for required_text in [
		"forniti direttamente dal proprietario",
		"nearest-neighbor",
		EXPECTED_SHA256,
	]:
		assert_true(manifest.contains(required_text), "Manifest B38 incompleto: %s." % required_text)


func _sha256_file(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	while file.get_position() < file.get_length():
		context.update(file.get_buffer(mini(65536, file.get_length() - file.get_position())))
	return context.finish().hex_encode().to_upper()
