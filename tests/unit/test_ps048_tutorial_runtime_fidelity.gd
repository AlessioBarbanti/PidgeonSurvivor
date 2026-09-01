extends GutTest

## PS-048 — Le pagine `ability`, `progression` e `boss` del tutorial devono
## mostrare esattamente cio' che il testo insegna: il pulsante abilita' reale
## (non una griglia di icone), i pickup e la carta di scelta reali (non le
## icone upgrade) e piu' forme di telegraph (non un unico avvertimento
## universale). Verifica sui dati (`.tres`), non sul rendering: il controllo
## percettivo resta un gate manuale, dopo che PS-049 avra' sostituito i
## segnaposto con l'arte definitiva.

const OBJECTIVE := preload("res://data/tutorial/objective.tres")
const MOVEMENT := preload("res://data/tutorial/movement.tres")
const ABILITY := preload("res://data/tutorial/ability.tres")
const PROGRESSION := preload("res://data/tutorial/progression.tres")
const ENEMIES := preload("res://data/tutorial/enemies.tres")
const BOSS := preload("res://data/tutorial/boss.tres")

const ALL_PAGES: Array[TutorialPageDefinition] = [
	OBJECTIVE, MOVEMENT, ABILITY, PROGRESSION, ENEMIES, BOSS,
]

const PLACEHOLDER_PREFIX := "fake_"
const ABILITY_ARTWORK_PATH := "res://assets/art/ui/tutorial/generated/fake_tutorial_ability_button.png"
const PROGRESSION_ARTWORK_PATH := "res://assets/art/ui/tutorial/generated/fake_tutorial_pickups.png"
const BOSS_ARTWORK_PATH := "res://assets/art/ui/tutorial/generated/fake_tutorial_telegraphs.png"

## Frasi che dichiarerebbero un'unica forma di telegraph: se il testo Boss ne
## contiene una, la card non ha rimosso la promessa di forma unica.
const UNIVERSAL_SHAPE_CLAIMS := [
	"stessa forma", "un'unica forma", "una sola forma", "identica forma",
]
## Parole che devono comparire nel testo Boss perche' insegni davvero piu' forme.
const EXPECTED_SHAPE_WORDS := ["line", "anell", "area"]


func test_all_six_pages_remain_valid() -> void:
	assert_eq(ALL_PAGES.size(), 6, "Le pagine tutorial restano sei.")
	for page in ALL_PAGES:
		assert_true(
			page != null and page.is_valid(),
			"Ogni pagina tutorial deve restare una TutorialPageDefinition valida."
		)


func test_ability_page_shows_the_real_hud_button_not_a_grid() -> void:
	assert_true(ABILITY.artwork != null, "La pagina Abilità deve avere un artwork singolo.")
	if ABILITY.artwork == null:
		return
	assert_eq(
		ABILITY.artwork.resource_path, ABILITY_ARTWORK_PATH,
		"La pagina Abilità deve puntare al segnaposto del pulsante HUD."
	)
	assert_true(
		ABILITY.showcase_textures.is_empty(),
		"La pagina Abilità non deve piu' mostrare una griglia di icone diverse."
	)


func test_progression_page_shows_real_pickups_not_upgrade_icons() -> void:
	assert_true(PROGRESSION.artwork != null, "La pagina Potenziamenti deve avere un artwork singolo.")
	if PROGRESSION.artwork == null:
		return
	assert_eq(
		PROGRESSION.artwork.resource_path, PROGRESSION_ARTWORK_PATH,
		"La pagina Potenziamenti deve puntare al segnaposto di XP, cura e carta."
	)
	assert_true(
		PROGRESSION.showcase_textures.is_empty(),
		"La pagina Potenziamenti non deve piu' mostrare le quattro icone upgrade."
	)


func test_boss_page_shows_multiple_telegraph_shapes() -> void:
	assert_true(BOSS.artwork != null, "La pagina Boss deve avere un artwork.")
	if BOSS.artwork == null:
		return
	assert_eq(
		BOSS.artwork.resource_path, BOSS_ARTWORK_PATH,
		"La pagina Boss deve puntare al segnaposto con linea, anello e area."
	)


func test_boss_page_text_teaches_the_principle_not_a_single_shape() -> void:
	var body_lower := BOSS.body.to_lower()
	for claim in UNIVERSAL_SHAPE_CLAIMS:
		assert_true(
			not body_lower.contains(claim),
			"Il testo Boss non deve piu' promettere una forma unica ('%s')." % claim
		)
	for word in EXPECTED_SHAPE_WORDS:
		assert_true(
			body_lower.contains(word),
			"Il testo Boss deve nominare la forma '%s' fra quelle mostrate." % word
		)


func test_placeholders_are_explicitly_marked_fake() -> void:
	for path: String in [ABILITY_ARTWORK_PATH, PROGRESSION_ARTWORK_PATH, BOSS_ARTWORK_PATH]:
		var file_name: String = path.get_file()
		assert_true(
			file_name.begins_with(PLACEHOLDER_PREFIX),
			"%s deve restare riconoscibile come segnaposto non definitivo." % file_name
		)


func test_placeholder_textures_load_and_have_final_composition_size() -> void:
	for path: String in [ABILITY_ARTWORK_PATH, PROGRESSION_ARTWORK_PATH, BOSS_ARTWORK_PATH]:
		var texture := load(path) as Texture2D
		assert_true(texture != null, "%s deve esistere e caricarsi come texture." % path)
		if texture == null:
			continue
		assert_true(
			texture.get_width() > 0 and texture.get_height() > 0,
			"%s deve avere dimensioni valide, non zero." % path
		)

	print("TUTORIAL_RUNTIME_FIDELITY_SMOKE_OK")
