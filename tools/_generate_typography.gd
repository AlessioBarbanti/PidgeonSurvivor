extends SceneTree

## Generatore deterministico delle risorse tipografiche B36.
## Rilanciabile: riscrive le FontVariation e il tema di progetto da zero.

const DISPLAY_TTF := "res://assets/fonts/LilitaOne-Regular.ttf"
const BODY_TTF := "res://assets/fonts/Nunito-Variable.ttf"
const SYMBOLS_TTF := "res://assets/fonts/NotoSansSymbols2-Regular.ttf"
const FONT_DIR := "res://assets/fonts"
const THEME_PATH := "res://assets/themes/pidgeon_survivor.tres"

## Scala tipografica: variazione -> [risorsa font, dimensione, line_spacing opzionale].
## Lilita One ha un box di riga pari a 1.73x la dimensione: i titoli richiedono
## interlinea negativa per non gonfiare i pannelli e per stare stretti come un display.
const LABEL_SCALE := {
	"TitleXL": ["display", 36, -6],
	"TitleL": ["display", 32, -5],
	"TitleM": ["display", 26, -4],
	"TitleS": ["display", 21, -4],
	"TitleXS": ["display", 17, -3],
	"HudTimer": ["display", 28],
	"BodyXL": ["body_semibold", 20, -2],
	"BodyL": ["body_semibold", 18, -2],
	"BodyM": ["body_semibold", 16, -2],
	"BodyS": ["body_regular", 12, -2],
	"ValueNumeric": ["body_bold", 16],
	"Eyebrow": ["body_eyebrow", 13],
}

const BUTTON_SCALE := {
	"ButtonPrimary": ["display", 28],
	"ButtonStandard": ["display", 20],
	"ButtonCompact": ["body_bold", 16],
	"GlyphButtonS": ["display", 20],
	"GlyphButtonM": ["display", 26],
	"GlyphButtonL": ["display", 32],
}

const CHECK_BUTTON_SCALE := {
	"CheckLabel": ["body_semibold", 16],
}

var _variations: Dictionary = {}


func _initialize() -> void:
	var symbols := load(SYMBOLS_TTF) as FontFile
	var display_base := load(DISPLAY_TTF) as FontFile
	var body_base := load(BODY_TTF) as FontFile
	if symbols == null or display_base == null or body_base == null:
		printerr("Font sorgente mancanti.")
		quit(1)
		return

	var symbol_fallbacks: Array[Font] = [symbols]

	_variations["display"] = _make_variation(display_base, 0.0, symbol_fallbacks, 0, "lilita_one_display")
	_variations["body_regular"] = _make_variation(body_base, 400.0, symbol_fallbacks, 0, "nunito_regular")
	_variations["body_semibold"] = _make_variation(body_base, 600.0, symbol_fallbacks, 0, "nunito_semibold")
	_variations["body_bold"] = _make_variation(body_base, 700.0, symbol_fallbacks, 0, "nunito_bold")
	_variations["body_eyebrow"] = _make_variation(body_base, 800.0, symbol_fallbacks, 1, "nunito_eyebrow")

	var theme := Theme.new()
	theme.default_font = _variations["body_semibold"]
	theme.default_font_size = 16

	_apply_scale(theme, LABEL_SCALE, &"Label")
	_apply_scale(theme, BUTTON_SCALE, &"Button")
	_apply_scale(theme, CHECK_BUTTON_SCALE, &"CheckButton")

	var error := ResourceSaver.save(theme, THEME_PATH)
	print("THEME %s (err %d) variazioni=%d" % [THEME_PATH, error, theme.get_type_variation_list(&"Label").size() + theme.get_type_variation_list(&"Button").size() + theme.get_type_variation_list(&"CheckButton").size()])
	quit(0)


func _make_variation(
	base: FontFile,
	weight: float,
	fallbacks: Array[Font],
	glyph_spacing: int,
	file_name: String
) -> FontVariation:
	var variation := FontVariation.new()
	variation.base_font = base
	variation.fallbacks = fallbacks
	if weight > 0.0:
		var server := TextServerManager.get_primary_interface()
		variation.variation_opentype = {server.name_to_tag("weight"): weight}
	if glyph_spacing != 0:
		variation.set_spacing(TextServer.SPACING_GLYPH, glyph_spacing)
	var path := "%s/%s.tres" % [FONT_DIR, file_name]
	var error := ResourceSaver.save(variation, path)
	print("FONT %s (err %d)" % [path, error])
	return load(path) as FontVariation


func _apply_scale(theme: Theme, scale: Dictionary, base_type: StringName) -> void:
	for variation_name in scale.keys():
		var entry: Array = scale[variation_name]
		var type_name := StringName(variation_name)
		theme.add_type(type_name)
		theme.set_type_variation(type_name, base_type)
		theme.set_font(&"font", type_name, _variations[entry[0]])
		theme.set_font_size(&"font_size", type_name, int(entry[1]))
		if entry.size() > 2:
			theme.set_constant(&"line_spacing", type_name, int(entry[2]))
