class_name SetupValidator
extends RefCounted

const EXPECTED_VERSION := Vector3i(4, 7, 1)
const EXPECTED_RENDERER := "gl_compatibility"
const EXPECTED_VIEWPORT := Vector2i(1280, 720)


static func version_vector() -> Vector3i:
	var version_info: Dictionary = Engine.get_version_info()
	return Vector3i(
		int(version_info.get("major", -1)),
		int(version_info.get("minor", -1)),
		int(version_info.get("patch", -1))
	)


static func version_text() -> String:
	var version := version_vector()
	return "%d.%d.%d" % [version.x, version.y, version.z]


static func collect_failures() -> Array[String]:
	var failures: Array[String] = []
	var version := version_vector()
	var renderer := str(
		ProjectSettings.get_setting("rendering/renderer/rendering_method", "")
	)

	if version != EXPECTED_VERSION:
		failures.append(
			"Godot atteso 4.7.1, trovato %s." % version_text()
		)
	if renderer != EXPECTED_RENDERER:
		failures.append(
			"Renderer atteso gl_compatibility, trovato %s." % renderer
		)
	if not bool(ProjectSettings.get_setting(
		"rendering/textures/vram_compression/import_etc2_astc", false
	)):
		failures.append("Compressione texture ETC2/ASTC richiesta per Android.")

	var viewport_size := Vector2i(
		int(ProjectSettings.get_setting("display/window/size/viewport_width", 0)),
		int(ProjectSettings.get_setting("display/window/size/viewport_height", 0))
	)
	if viewport_size != EXPECTED_VIEWPORT:
		failures.append("Viewport atteso 1280x720, trovato %s." % viewport_size)
	if str(ProjectSettings.get_setting("display/window/stretch/mode", "")) != "canvas_items":
		failures.append("Stretch mode deve essere canvas_items.")
	if str(ProjectSettings.get_setting("display/window/stretch/aspect", "")) != "expand":
		failures.append("Stretch aspect deve essere expand.")
	if int(ProjectSettings.get_setting(
		"display/window/handheld/orientation", -1
	)) != DisplayServer.SCREEN_LANDSCAPE:
		failures.append("Orientamento mobile non impostato su landscape.")
	if bool(ProjectSettings.get_setting("application/config/quit_on_go_back", true)):
		failures.append("Il tasto Back Android non deve chiudere automaticamente l'app.")

	return failures


static func print_result() -> bool:
	var failures := collect_failures()
	if failures.is_empty():
		print(
			"SMOKE_OK version=%s renderer=%s os=%s"
			% [version_text(), EXPECTED_RENDERER, OS.get_name()]
		)
		return true

	for failure in failures:
		push_error(failure)
	printerr("SMOKE_FAIL")
	return false

