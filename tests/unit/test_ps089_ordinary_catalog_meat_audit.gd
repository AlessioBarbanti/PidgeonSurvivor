extends GutTest

## PS-089 — Il catalogo powerup ordinario non nomina pezzi di carne.
##
## Le otto Specialità di Barb (`data/upgrades/specialities/`) sono l'unico
## registro autorizzato a nominare tagli/pezzi/piatti di carne alla griglia
## (PS-078). Questo smoke scopre dinamicamente ogni `.tres` di primo livello
## in `data/upgrades/` (esclusa la sottocartella `specialities/`) e fallisce
## se un `title` contiene una parola della lista vietata.

const UPGRADES_DIRECTORY := "res://data/upgrades"
const SPECIALITIES_DIRECTORY_NAME := "specialities"

## Lista di partenza sui casi noti nel catalogo attuale; da estendere quando
## PS-078 assegna i nomi definitivi delle otto Specialità, per evitare falsi
## negativi su nuovi tagli non ancora presenti in questo elenco.
const FORBIDDEN_MEAT_WORDS: Array[String] = [
	"salsiccia",
	"bistecca",
	"costata",
	"spiedino",
	"spiedo",
	"filetto",
	"prosciutto",
	"hamburger",
	"polpetta",
	"braciola",
	"arrosto",
	"cotoletta",
	"salame",
	"wurstel",
	"kebab",
	"pancetta",
	"lonza",
	"straccetti",
	"tagliata",
	"controfiletto",
	"scamone",
	"fesa",
	"girello",
	"salamoia",
	"carne",
]


func test_no_ordinary_upgrade_title_names_a_meat_cut() -> void:
	var definitions := _discover_ordinary_upgrade_definitions()
	assert_true(definitions.size() > 0, "Il catalogo ordinario deve avere almeno una carta da controllare.")

	for definition in definitions:
		var normalized_title := definition.title.to_lower()
		for forbidden_word in FORBIDDEN_MEAT_WORDS:
			assert_false(
				normalized_title.contains(forbidden_word),
				(
					"%s (%s) nomina un pezzo di carne (\"%s\"), riservato alle Specialità di Barb (PS-089)."
					% [definition.title, definition.id, forbidden_word]
				)
			)

	print("ORDINARY_CATALOG_MEAT_AUDIT_SMOKE_OK")


func test_ability_cooldown_rename_kept_mechanics_bit_for_bit() -> void:
	var definition := load("res://data/upgrades/ability_cooldown.tres") as UpgradeDefinition
	assert_not_null(definition, "ability_cooldown.tres deve restare caricabile.")
	if definition == null:
		return

	assert_ne(definition.title, "Bis di Salsiccia", "Il titolo deve essere stato rinominato fuori dal registro carne.")
	assert_eq(
		definition.effect_id, &"active_ability_cooldown_multiplier", "effect_id deve restare identico alla rinomina."
	)
	assert_true(
		definition.effect_parameters.has("multiplier")
		and is_equal_approx(float(definition.effect_parameters["multiplier"]), 0.92),
		"effect_parameters deve restare identico alla rinomina."
	)
	assert_almost_eq(definition.weight, 1.0, 0.0001, "weight deve restare identico alla rinomina.")
	assert_eq(definition.max_rank, 5, "max_rank deve restare identico alla rinomina.")


func _discover_ordinary_upgrade_definitions() -> Array[UpgradeDefinition]:
	var discovered: Array[UpgradeDefinition] = []
	var dir := DirAccess.open(UPGRADES_DIRECTORY)
	assert_not_null(dir, "Cartella del catalogo upgrade mancante: %s." % UPGRADES_DIRECTORY)
	if dir == null:
		return discovered
	dir.list_dir_begin()
	var entry_name := dir.get_next()
	while entry_name != "":
		if dir.current_is_dir():
			entry_name = dir.get_next()
			continue
		if entry_name.ends_with(".tres"):
			var definition := load("%s/%s" % [UPGRADES_DIRECTORY, entry_name]) as UpgradeDefinition
			assert_not_null(definition, "Impossibile caricare la carta: %s." % entry_name)
			if definition != null:
				discovered.append(definition)
		entry_name = dir.get_next()
	dir.list_dir_end()
	return discovered
