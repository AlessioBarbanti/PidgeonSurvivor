extends SceneTree

## B36: verifica che il tema tipografico di progetto sia agganciato, che la scala
## sia completa e che la catena font copra italiano accentato e glifi simbolo.

const THEME_PATH := "res://assets/themes/pidgeon_survivor.tres"
const DISPLAY_VARIATION_PATH := "res://assets/fonts/lilita_one_display.tres"
const BODY_VARIATION_PATH := "res://assets/fonts/nunito_semibold.tres"

## Accenti e punteggiatura tipografica usati dalle stringhe italiane del gioco.
const ITALIAN_CHARACTERS := "àèéìòùÀÈÉÌÒÙ‘’“”•…"
## Glifi simbolo presenti nelle scene UI, coperti solo dal fallback Noto Symbols 2.
const SYMBOL_CHARACTERS := "←◀▶⚙"

const LABEL_VARIATIONS := [
	&"TitleXL",
	&"TitleL",
	&"TitleM",
	&"TitleS",
	&"TitleXS",
	&"HudTimer",
	&"BodyXL",
	&"BodyL",
	&"BodyM",
	&"BodyS",
	&"ValueNumeric",
	&"Eyebrow",
]
const BUTTON_VARIATIONS := [
	&"ButtonPrimary",
	&"ButtonStandard",
	&"ButtonCompact",
	&"GlyphButtonS",
	&"GlyphButtonM",
	&"GlyphButtonL",
]
const CHECK_BUTTON_VARIATIONS := [&"CheckLabel"]

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_validate_project_binding()
	_validate_scale()
	_validate_glyph_coverage()
	_validate_scenes_use_variations()
	_finish()


func _validate_project_binding() -> void:
	var configured := String(ProjectSettings.get_setting("gui/theme/custom", ""))
	_expect(
		configured == THEME_PATH,
		"Il tema di progetto deve essere %s, trovato '%s'." % [THEME_PATH, configured]
	)


func _validate_scale() -> void:
	var theme := load(THEME_PATH) as Theme
	_expect(theme != null, "Il tema tipografico deve caricarsi.")
	if theme == null:
		return

	_expect(theme.default_font != null, "Il tema deve definire un font di default.")
	_expect(theme.default_font_size == 16, "La dimensione di default deve essere 16.")

	_validate_variation_group(theme, LABEL_VARIATIONS, &"Label")
	_validate_variation_group(theme, BUTTON_VARIATIONS, &"Button")
	_validate_variation_group(theme, CHECK_BUTTON_VARIATIONS, &"CheckButton")


func _validate_variation_group(
	theme: Theme,
	variations: Array,
	base_type: StringName
) -> void:
	for variation in variations:
		_expect(
			theme.get_type_variation_base(variation) == base_type,
			"La variazione %s deve derivare da %s." % [variation, base_type]
		)
		_expect(
			theme.has_font(&"font", variation),
			"La variazione %s deve dichiarare un font." % variation
		)
		_expect(
			theme.get_font_size(&"font_size", variation) >= 12,
			"La variazione %s deve dichiarare una dimensione leggibile." % variation
		)


func _validate_glyph_coverage() -> void:
	var display := load(DISPLAY_VARIATION_PATH) as FontVariation
	var body := load(BODY_VARIATION_PATH) as FontVariation
	_expect(display != null and body != null, "Le variazioni font devono caricarsi.")
	if display == null or body == null:
		return

	var fonts: Array[Font] = [display, body]
	for font in fonts:
		var font_name: String = font.get_font_name()
		for index in ITALIAN_CHARACTERS.length():
			var character := ITALIAN_CHARACTERS[index]
			_expect(
				_covers(font, character),
				"%s deve coprire '%s' (U+%04X)." % [font_name, character, character.unicode_at(0)]
			)
		for index in SYMBOL_CHARACTERS.length():
			var character := SYMBOL_CHARACTERS[index]
			_expect(
				_covers(font, character),
				"La catena di fallback di %s deve coprire '%s' (U+%04X)." % [
					font_name,
					character,
					character.unicode_at(0),
				]
			)


## Verifica la copertura reale attraverso l'intera catena font (base + fallback)
## chiedendo al TextServer se lo shaping produce un glifo valido invece di tofu.
func _covers(font: Font, character: String) -> bool:
	var server := TextServerManager.get_primary_interface()
	var shaped := server.create_shaped_text()
	server.shaped_text_add_string(shaped, character, font.get_rids(), 32)
	server.shaped_text_shape(shaped)
	var glyphs := server.shaped_text_get_glyphs(shaped)
	var covered := not glyphs.is_empty()
	for glyph in glyphs:
		if int(glyph.get("index", 0)) == 0:
			covered = false
	server.free_rid(shaped)
	return covered


func _validate_scenes_use_variations() -> void:
	var scene_dir := "res://scenes/ui"
	var listing := DirAccess.get_files_at(scene_dir)
	_expect(not listing.is_empty(), "Le scene UI devono essere leggibili.")
	for file_name in listing:
		if not file_name.ends_with(".tscn"):
			continue
		var path := "%s/%s" % [scene_dir, file_name]
		var source := FileAccess.get_file_as_string(path)
		_expect(
			not source.contains("theme_override_font_sizes/font_size"),
			"%s non deve reintrodurre dimensioni font locali: usare theme_type_variation." % path
		)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("TYPOGRAPHY_SMOKE_OK")
		quit(0)
		return
	for failure in _failures:
		printerr(failure)
	printerr("TYPOGRAPHY_SMOKE_FAILED failures=%d" % _failures.size())
	quit(1)
