extends SceneTree

const ICON_PATH := "res://assets/art/branding/pidgeon_survivor_app_icon.png"
const ADAPTIVE_FOREGROUND_PATH := (
	"res://assets/art/branding/pidgeon_survivor_adaptive_foreground.png"
)
const ADAPTIVE_BACKGROUND_PATH := (
	"res://assets/art/branding/pidgeon_survivor_adaptive_background.png"
)
const MANIFEST_PATH := "res://assets/art/branding/ASSET-MANIFEST.md"
const ICON_SHA256 := "99e86e1354361736973e789e80f0c2382650d54ef4f5160c49c04fe856c5ba32"
const ADAPTIVE_FOREGROUND_SHA256 := (
	"a1a0ea8bb66a3a1818f285b8c46aa110db4a74f02cd696d1d9d9e3206ce43a4f"
)
const ADAPTIVE_BACKGROUND_SHA256 := (
	"86ec85dbe31e6dccc77933b6b7f0d595c1f6068b90d95a99435441b5bfc6ad4f"
)

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_validate_project_icon()
	_validate_export_presets()
	_validate_manifest()
	_finish()


func _validate_project_icon() -> void:
	_expect(
		ProjectSettings.get_setting("application/config/icon", "") == ICON_PATH,
		"Il progetto deve usare l'icona Pidgeon Survivor."
	)
	_validate_image(ICON_PATH, Vector2i(1254, 1254), ICON_SHA256, false)
	_validate_image(
		ADAPTIVE_FOREGROUND_PATH,
		Vector2i(1254, 1254),
		ADAPTIVE_FOREGROUND_SHA256,
		true
	)
	_validate_image(
		ADAPTIVE_BACKGROUND_PATH,
		Vector2i(432, 432),
		ADAPTIVE_BACKGROUND_SHA256,
		false
	)


func _validate_image(
	path: String,
	expected_size: Vector2i,
	expected_hash: String,
	expects_alpha: bool
) -> void:
	_expect(FileAccess.file_exists(path), "L'asset branding deve esistere: %s." % path)
	if not FileAccess.file_exists(path):
		return
	_expect(
		FileAccess.get_sha256(path) == expected_hash,
		"L'asset branding deve conservare lo SHA-256 approvato: %s." % path
	)
	var texture := load(path) as Texture2D
	_expect(texture != null, "L'asset branding deve essere caricabile: %s." % path)
	if texture == null:
		return
	var image := texture.get_image()
	_expect(image.get_size() == expected_size, "Dimensioni inattese per %s." % path)
	if expects_alpha:
		_expect(image.detect_alpha() != Image.ALPHA_NONE, "%s deve avere trasparenza." % path)
	else:
		_expect(image.detect_alpha() == Image.ALPHA_NONE, "%s deve essere opaco." % path)


func _validate_export_presets() -> void:
	var presets := FileAccess.get_file_as_string("res://export_presets.cfg")
	var quoted_icon := '"%s"' % ICON_PATH
	var quoted_foreground := '"%s"' % ADAPTIVE_FOREGROUND_PATH
	var quoted_background := '"%s"' % ADAPTIVE_BACKGROUND_PATH
	_expect(
		presets.contains("application/icon=%s" % quoted_icon),
		"Il preset Windows deve usare l'icona Pidgeon Survivor."
	)
	_expect(
		presets.count("launcher_icons/main_192x192=%s" % quoted_icon) == 2,
		"Entrambi i preset Android devono usare la main icon Pidgeon Survivor."
	)
	_expect(
		presets.count(
			"launcher_icons/adaptive_foreground_432x432=%s" % quoted_foreground
		) == 2,
		"Entrambi i preset Android devono usare il foreground adattivo Pidgeon Survivor."
	)
	_expect(
		presets.count(
			"launcher_icons/adaptive_background_432x432=%s" % quoted_background
		) == 2,
		"Entrambi i preset Android devono usare il background adattivo notte."
	)


func _validate_manifest() -> void:
	_expect(FileAccess.file_exists(MANIFEST_PATH), "L'icona deve avere un manifest.")
	if not FileAccess.file_exists(MANIFEST_PATH):
		return
	var manifest := FileAccess.get_file_as_string(MANIFEST_PATH)
	_expect(manifest.contains("OpenAI ImageGen built-in"), "Il manifest deve indicare ImageGen.")
	_expect(manifest.contains(ICON_SHA256), "Il manifest deve registrare l'hash dell'icona.")
	_expect(
		manifest.contains(ADAPTIVE_FOREGROUND_SHA256),
		"Il manifest deve registrare l'hash del foreground adattivo."
	)
	_expect(
		manifest.contains(ADAPTIVE_BACKGROUND_SHA256),
		"Il manifest deve registrare l'hash del background adattivo."
	)
	_expect(manifest.contains("Text: none."), "Il prompt deve vietare testo nell'icona.")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("APP_ICON_SMOKE_OK")
		quit(0)
		return
	for failure in _failures:
		printerr("APP_ICON_SMOKE_FAIL: %s" % failure)
	quit(1)
