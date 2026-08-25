extends SceneTree

const MOVEMENT_SLICE_SCENE := preload("res://scenes/game/movement_slice.tscn")
const BACKGROUND_PATH := "res://assets/art/arena/arena_floor_imagegen.png"
const MANIFEST_PATH := "res://assets/art/arena/ASSET-MANIFEST.md"
const EXPECTED_SHA256 := "210523A96CF0370885BE49E937D85EBD035DF992D8FBC2089A89F36347A615BC"
const INITIAL_VIEWPORT_SIZE := Vector2i(1280, 720)
const FLOAT_TOLERANCE := 0.01

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.content_scale_size = INITIAL_VIEWPORT_SIZE
	root.size = INITIAL_VIEWPORT_SIZE
	await process_frame
	await process_frame

	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	root.add_child(movement_slice)
	await process_frame
	await process_frame

	var arena_view := movement_slice.get_arena_view() as ArenaView
	_expect(arena_view != null, "B18S richiede ArenaView.")
	if arena_view != null:
		_validate_runtime_background(arena_view)
	_validate_asset(arena_view.background_texture if arena_view != null else null)
	if OS.get_cmdline_user_args().has("--capture-b18s"):
		await _capture_runtime_preview(movement_slice)

	var controller := movement_slice.get_run_controller() as RunController
	if controller != null:
		controller.prepare_restart()
	paused = false
	movement_slice.queue_free()
	await process_frame
	await process_frame
	_finish()


func _validate_runtime_background(arena_view: ArenaView) -> void:
	_expect(arena_view.has_raster_background(), "Lo sfondo raster deve essere assegnato.")
	_expect(
		not arena_view.uses_procedural_fallback(),
		"La scena runtime non deve usare il fallback procedurale."
	)
	_expect(
		arena_view.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST,
		"Il filtro texture deve restare nearest-neighbor."
	)
	var texture := arena_view.background_texture
	if texture == null:
		return
	_expect(texture.get_size() == Vector2(768.0, 512.0), "Il derivato runtime deve essere 768 x 512.")
	_expect(
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
		_expect(source.has_area(), "Ogni aspect ratio deve produrre un crop valido.")
		_expect(source.position.x >= 0.0 and source.position.y >= 0.0, "Il crop deve restare nella texture.")
		_expect(
			source.end.x <= texture.get_size().x + FLOAT_TOLERANCE
			and source.end.y <= texture.get_size().y + FLOAT_TOLERANCE,
			"Il crop responsive non deve oltrepassare la texture."
		)
		_expect_float_near(
			source.size.x / source.size.y,
			size.x / size.y,
			"Il crop aspect-cover non deve deformare il raster."
		)
	_expect(
		arena_view.get_playfield_rect() == playfield_before,
		"Il calcolo presentazionale non deve modificare la geometria del playfield."
	)


func _validate_asset(imported_texture: Texture2D) -> void:
	_expect(FileAccess.file_exists(BACKGROUND_PATH), "Il PNG runtime B18S deve esistere.")
	_expect(FileAccess.file_exists(MANIFEST_PATH), "Il manifest B18S deve esistere.")
	if not FileAccess.file_exists(BACKGROUND_PATH):
		return
	_expect(imported_texture != null, "Il PNG B18S deve essere importato come Texture2D.")
	if imported_texture == null:
		return
	var image := imported_texture.get_image()
	_expect(image != null and not image.is_empty(), "La texture importata deve esporre i pixel.")
	if image == null or image.is_empty():
		return
	_expect(image.get_width() == 768 and image.get_height() == 512, "Dimensioni PNG B18S inattese.")
	_expect(not image.detect_alpha(), "Lo sfondo opaco non deve allocare un canale alpha inutile.")

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
	_expect(luminance_average <= 0.22, "La luminanza media deve restare dietro al gameplay.")
	_expect(luminance_max <= 0.52, "Lo sfondo non deve contenere highlight dominanti.")

	var digest := _sha256_file(BACKGROUND_PATH)
	_expect(digest == EXPECTED_SHA256, "Lo SHA-256 del PNG deve corrispondere al manifest.")
	var manifest := FileAccess.get_file_as_string(MANIFEST_PATH)
	for required_text in [
		"OpenAI ImageGen built-in",
		"Licenza del progetto",
		"nearest-neighbor",
		EXPECTED_SHA256,
	]:
		_expect(manifest.contains(required_text), "Manifest B18S incompleto: %s." % required_text)


func _sha256_file(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	while file.get_position() < file.get_length():
		context.update(file.get_buffer(mini(65536, file.get_length() - file.get_position())))
	return context.finish().hex_encode().to_upper()


func _capture_runtime_preview(movement_slice: Control) -> void:
	var selected: bool = movement_slice.select_friend_for_next_run(&"magno")
	var started: bool = selected and movement_slice.start_selected_run(1818)
	_expect(started, "La preview B18S deve avviare una run deterministica.")
	if not started:
		return
	await create_timer(2.0).timeout
	var arena_view := movement_slice.get_arena_view() as ArenaView
	if arena_view == null:
		_expect(false, "La preview B18S richiede ArenaView.")
		return
	var raster_texture := arena_view.background_texture
	_save_runtime_preview("b18s-arena-imagegen.png")
	arena_view.background_texture = null
	arena_view.queue_redraw()
	await process_frame
	await process_frame
	_save_runtime_preview("b18s-arena-procedural-baseline.png")
	arena_view.background_texture = raster_texture
	arena_view.queue_redraw()


func _save_runtime_preview(file_name: String) -> void:
	var image := root.get_texture().get_image()
	var output_path := ProjectSettings.globalize_path(
		"res://exports/windows/%s" % file_name
	)
	var save_error := image.save_png(output_path)
	_expect(save_error == OK, "La preview Windows B18S deve essere salvata.")
	if save_error == OK:
		print("B18S_WINDOWS_PREVIEW_SAVED path=%s" % output_path)


func _expect_float_near(actual: float, expected: float, message: String) -> void:
	_expect(absf(actual - expected) <= FLOAT_TOLERANCE, "%s Atteso %s, ottenuto %s." % [message, expected, actual])


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("B18S_ARENA_BACKGROUND_SMOKE_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	printerr("B18S_ARENA_BACKGROUND_SMOKE_FAIL count=%d" % _failures.size())
	quit(1)
