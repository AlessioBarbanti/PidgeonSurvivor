extends GutGameplayTest

## PS-051, riscritto da PS-176: la Boss Intro deve distinguere il Piccione
## Malvagio (ritratto baseline, mai una Signature) dagli Evil (ritratto del
## FriendDefinition) senza rompersi quando il ritratto manca. Icona Signature
## e tinta personale sono state rimosse da PS-176 (ritratto fluttuante senza
## cornice): quelle asserzioni non hanno più un contratto da coprire qui.

const BOSS_UI_SCENE := preload("res://scenes/ui/boss_ui.tscn")
const BASELINE_PORTRAIT_PATH := "res://assets/art/characters/piccione_malvagio/generated/portrait.png"
const SIGNATURE_CATALOG: BossSignatureCatalog = preload("res://data/bosses/evil_signature_catalog.tres")
const FRIEND_IDS_WITH_EVIL_VARIANT := [
	"alea", "aleo", "bea", "lollo", "magno", "marghe", "migi", "zat",
]
const ASPECT_PROFILES := [
	{"name": "16:9", "viewport": Vector2i(1280, 720), "safe_rect": Rect2(20.0, 20.0, 1240.0, 680.0)},
	{"name": "20:9", "viewport": Vector2i(1600, 720), "safe_rect": Rect2(64.0, 20.0, 1472.0, 680.0)},
	{"name": "4:3", "viewport": Vector2i(960, 720), "safe_rect": Rect2(20.0, 20.0, 920.0, 680.0)},
]


func test_baseline_intro_shows_pigeon_portrait() -> void:
	var slice := await instantiate_movement_slice()
	var controller := slice.get_run_controller() as RunController
	var encounter := slice.get_boss_encounter() as BossEncounter
	var boss_ui := slice.get_boss_ui() as BossUI
	assert_true(controller != null and encounter != null and boss_ui != null, "PS-051 richiede le dipendenze Boss della scena.")
	if controller == null or encounter == null or boss_ui == null:
		return

	controller.set_process(false)
	encounter.evil_boss_chance = 0.0
	controller._process(120.01)

	var definition := encounter.get_active_definition()
	assert_true(definition != null and not definition.is_evil_variant(), "evil_boss_chance=0 deve aprire il Piccione Malvagio.")
	if definition == null:
		return

	var portrait := definition.get_safe_portrait()
	assert_true(portrait != null, "Il Piccione Malvagio deve risolvere il ritratto definitivo.")
	assert_eq(
		portrait.resource_path, BASELINE_PORTRAIT_PATH,
		"Il baseline deve usare il derivato definitivo del ritratto fluttuante PS-176."
	)
	assert_true(boss_ui.is_intro_portrait_visible(), "Il Piccione Malvagio deve mostrare il proprio ritratto.")
	assert_eq(
		boss_ui.get_intro_portrait_texture(), definition.get_safe_portrait(),
		"Il ritratto mostrato deve essere quello risolto dal Boss baseline."
	)

	encounter.complete_intro()
	controller.prepare_restart()


func test_evil_intro_shows_friend_portrait() -> void:
	var slice := await instantiate_movement_slice()
	var controller := slice.get_run_controller() as RunController
	var encounter := slice.get_boss_encounter() as BossEncounter
	var boss_ui := slice.get_boss_ui() as BossUI
	assert_true(controller != null and encounter != null and boss_ui != null, "PS-051 richiede le dipendenze Boss della scena.")
	if controller == null or encounter == null or boss_ui == null:
		return

	controller.set_process(false)
	encounter.evil_boss_chance = 1.0
	controller._process(120.01)

	var definition := encounter.get_active_definition()
	assert_true(definition != null and definition.is_evil_variant(), "evil_boss_chance=1 deve aprire un Evil.")
	if definition == null:
		return
	var friend := definition.friend_profile
	assert_true(definition.has_signature() and friend != null, "Ogni Evil in catalogo deve avere Signature e profilo.")
	if friend == null:
		return

	assert_true(boss_ui.is_intro_portrait_visible(), "L'intro Evil deve mostrare un ritratto.")
	assert_eq(
		boss_ui.get_intro_portrait_texture(), friend.get_public_evil_portrait(),
		"Il ritratto mostrato deve provenire dal FriendDefinition dell'Evil attivo."
	)

	encounter.complete_intro()
	controller.prepare_restart()


func test_boss_intro_portrait_stays_in_safe_area_across_aspect_ratios() -> void:
	var slice := await instantiate_movement_slice()
	var controller := slice.get_run_controller() as RunController
	var encounter := slice.get_boss_encounter() as BossEncounter
	var boss_ui := slice.get_boss_ui() as BossUI
	assert_true(controller != null and encounter != null and boss_ui != null, "PS-051 richiede le dipendenze Boss della scena.")
	if controller == null or encounter == null or boss_ui == null:
		return

	controller.set_process(false)
	encounter.evil_boss_chance = 1.0
	controller._process(120.01)
	assert_eq(
		controller.get_state(), RunController.RunState.BOSS_INTRO,
		"La fixture PS-051 deve aprire la Boss Intro con identita' Evil al completo."
	)

	for profile in ASPECT_PROFILES:
		var viewport_size: Vector2i = profile.viewport
		var safe_rect: Rect2 = profile.safe_rect
		get_tree().root.content_scale_size = viewport_size
		get_tree().root.size = viewport_size
		await wait_process_frames(2)
		assert_rect_inside(
			boss_ui.get_intro_portrait_rect(), safe_rect,
			"%s: il ritratto della Boss Intro deve restare nella safe area." % profile.name
		)

	encounter.complete_intro()
	controller.prepare_restart()


func test_boss_intro_recomposes_gracefully_when_portrait_is_missing() -> void:
	var boss_ui := BOSS_UI_SCENE.instantiate() as BossUI
	add_child_autofree(boss_ui)
	await wait_process_frames(1)

	var missing_portrait := BossDefinition.new()
	missing_portrait.id = &"ps051_missing_portrait"
	missing_portrait.title = "SENZA RITRATTO"
	missing_portrait.quote_approved = true
	missing_portrait.quote = "La intro deve reggere anche senza ritratto."
	missing_portrait.portrait = null
	assert_true(
		missing_portrait.is_valid(),
		"Un Boss baseline resta valido anche senza portrait: e' il caso di fallback da coprire."
	)
	assert_true(boss_ui.show_intro(missing_portrait), "La intro deve potersi aprire senza portrait.")
	assert_false(
		boss_ui.is_intro_portrait_visible(),
		"Senza portrait il blocco ritratto+citazione deve restare nascosto invece di mostrare una texture nulla."
	)
	assert_eq(
		boss_ui.get_intro_quote_text(), "“%s”" % missing_portrait.get_safe_quote(),
		"La citazione resta indipendente dal ritratto mancante."
	)
	var continue_button := boss_ui.get_continue_button()
	assert_true(
		continue_button != null and not continue_button.disabled,
		"Il bottone AFFRONTA deve restare utilizzabile anche senza ritratto."
	)

	print("BOSS_INTRO_IDENTITY_SMOKE_OK")


## PS-052: gli otto ritratti Evil e le otto icone Signature devono risolvere
## gli asset definitivi prodotti dalla card, non i segnaposto `fake_*.png`
## cablati da PS-051, e restare tutti distinti fra loro.
func test_ps052_evil_portraits_and_signature_icons_resolve_definitive_art() -> void:
	var portrait_paths: Array[String] = []
	for friend_id in FRIEND_IDS_WITH_EVIL_VARIANT:
		var friend := load("res://data/friends/%s.tres" % friend_id) as FriendDefinition
		assert_true(friend != null, "Il friend \"%s\" deve caricarsi." % friend_id)
		if friend == null:
			continue
		assert_true(
			friend.portraits_approved and friend.evil_portrait != null,
			"\"%s\" deve avere un evil_portrait approvato per mostrarlo davvero in game." % friend_id
		)
		if friend.evil_portrait == null:
			continue
		var portrait_path := friend.evil_portrait.resource_path
		assert_false(
			portrait_path.contains("fake_"),
			"\"%s\": evil_portrait deve risolvere l'asset definitivo, non un segnaposto (%s)." % [friend_id, portrait_path]
		)
		assert_false(
			portrait_paths.has(portrait_path),
			"\"%s\": evil_portrait non deve riusare il file di un altro Evil (%s)." % [friend_id, portrait_path]
		)
		portrait_paths.append(portrait_path)

	assert_eq(SIGNATURE_CATALOG.signatures.size(), 8, "Il catalogo Evil deve contenere le otto Signature.")
	var icon_paths: Array[String] = []
	for signature in SIGNATURE_CATALOG.signatures:
		assert_not_null(signature.icon, "La Signature \"%s\" deve avere un'icona valorizzata." % signature.id)
		if signature.icon == null:
			continue
		var icon_path := signature.icon.resource_path
		assert_false(
			icon_path.contains("fake_"),
			"\"%s\": l'icona deve risolvere l'asset definitivo, non un segnaposto (%s)." % [signature.id, icon_path]
		)
		assert_false(
			icon_paths.has(icon_path),
			"\"%s\": l'icona non deve riusare il file di un'altra Signature (%s)." % [signature.id, icon_path]
		)
		icon_paths.append(icon_path)

	print("PS052_EVIL_ART_INTEGRATION_SMOKE_OK")
