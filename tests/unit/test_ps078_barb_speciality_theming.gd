extends GutGameplayTest

const BEER := preload("res://data/upgrades/specialities/beer_signature.tres")
const CHRONIC_DELAY := preload("res://data/upgrades/specialities/chronic_delay.tres")
const DAMAGE_SHOCKWAVE := preload("res://data/upgrades/specialities/damage_shockwave.tres")
const DEATH_BURST := preload("res://data/upgrades/specialities/death_burst.tres")
const DOUBLE_BARREL := preload("res://data/upgrades/specialities/double_barrel.tres")
const GOSSIP := preload("res://data/upgrades/specialities/gossip_projectiles.tres")
const PIERCING_ROUNDS := preload("res://data/upgrades/specialities/piercing_rounds.tres")

const ICON_MANIFEST_PATH := "res://assets/art/icons/upgrades/ASSET-MANIFEST.md"
const ORDINARY_UPGRADE_DIRECTORY := "res://data/upgrades/"
const ICON_SIZE := Vector2(128.0, 128.0)

# PS-078 cambia soltanto identità. Questo snapshot fissa ciò che il restyle non
# può portarsi dietro: se una di queste voci cambia, la tematizzazione ha
# toccato il gameplay e il test deve fallire prima di qualunque gate manuale.
const MECHANICAL_SNAPSHOT: Dictionary = {
	&"beer_signature":
	{
		"effect_id": &"beer_signature",
		"weight": 1.0,
		"max_rank": 1,
		"parameters": {"fire_rate_multiplier": 1.25, "aim_spread_degrees": 24.0},
	},
	&"chronic_delay":
	{
		"effect_id": &"chronic_delay",
		"weight": 1.0,
		"max_rank": 1,
		"parameters": {"duration_seconds": 3.0, "interval_seconds": 12.0, "slow_factor": 0.5},
	},
	&"damage_shockwave":
	{
		"effect_id": &"damage_shockwave",
		"weight": 1.0,
		"max_rank": 1,
		"parameters":
		{
			"knockback_duration": 0.2,
			"knockback_speed": 420.0,
			"radius": 220.0,
			"visual_duration": 0.28,
		},
	},
	&"death_burst":
	{
		"effect_id": &"weapon_death_burst",
		"weight": 0.4,
		"max_rank": 3,
		"parameters": {"radius": 85.0, "damage_multiplier_per_rank": 0.2},
	},
	&"double_barrel":
	{
		"effect_id": &"weapon_multishot",
		"weight": 0.45,
		"max_rank": 2,
		"parameters": {"projectiles_per_rank": 1, "spread_degrees_per_projectile": 12.0},
	},
	&"gossip_projectiles":
	{
		"effect_id": &"gossip_projectiles",
		"weight": 0.6,
		"max_rank": 3,
		"parameters": {"chain_jumps_per_rank": 2, "chain_radius": 260.0, "damage_falloff": 0.65},
	},
	&"piercing_rounds":
	{
		"effect_id": &"weapon_pierce",
		"weight": 0.55,
		"max_rank": 3,
		"parameters": {"pierce_count_per_rank": 1, "damage_falloff": 0.7},
	},
}

# I sette nomi approvati dal proprietario il 5 settembre 2026: un taglio alla
# griglia per carta, senza aggettivi.
const THEMED_IDENTITY: Dictionary = {
	&"beer_signature":
	{"title": "Alette", "icon": "res://assets/art/icons/upgrades/generated/alette.png"},
	&"chronic_delay":
	{"title": "Costine", "icon": "res://assets/art/icons/upgrades/generated/costine.png"},
	&"damage_shockwave":
	{"title": "Hamburger", "icon": "res://assets/art/icons/upgrades/generated/hamburger.png"},
	&"death_burst":
	{"title": "Fiorentina", "icon": "res://assets/art/icons/upgrades/generated/fiorentina.png"},
	&"double_barrel":
	{"title": "Tagliata", "icon": "res://assets/art/icons/upgrades/generated/tagliata.png"},
	&"gossip_projectiles":
	{"title": "Salsiccia", "icon": "res://assets/art/icons/upgrades/generated/salsiccia.png"},
	&"piercing_rounds":
	{"title": "Arrosticini", "icon": "res://assets/art/icons/upgrades/generated/arrosticini.png"},
}

# Titoli e icone di prima del restyle: nessuna carta deve essere rimasta indietro.
const LEGACY_TITLES: PackedStringArray = [
	"Birre di classe di Lollo",
	"Ritardo Cronico",
	"Non Ho Tempo Per Questo",
	"Esplosione Finale",
	"Raffica Doppia",
	"Gossip",
	"Colpo Perforante",
]


func test_theming_preserves_every_mechanical_field() -> void:
	for definition in _themed_definitions():
		var expected: Dictionary = MECHANICAL_SNAPSHOT[definition.id]
		assert_eq(
			definition.effect_id,
			expected["effect_id"],
			"%s deve conservare il proprio effect_id dopo la tematizzazione." % definition.id
		)
		assert_almost_eq(
			definition.weight, float(expected["weight"]), 0.0001, "%s deve conservare il proprio peso." % definition.id
		)
		assert_eq(definition.max_rank, int(expected["max_rank"]), "%s deve conservare il proprio max_rank." % definition.id)
		assert_eq(
			definition.effect_parameters,
			expected["parameters"] as Dictionary,
			"%s deve conservare i propri effect_parameters bit per bit." % definition.id
		)
		assert_true(definition.is_speciality, "%s deve restare una Specialità di Barb." % definition.id)
		assert_true(definition.is_valid(), "%s deve restare una definizione valida." % definition.id)


func test_theming_applies_the_approved_grill_identity() -> void:
	var seen_titles: Dictionary = {}
	for definition in _themed_definitions():
		var expected: Dictionary = THEMED_IDENTITY[definition.id]
		var expected_title: String = expected["title"]
		assert_eq(definition.title, expected_title, "%s deve esporre il nome approvato." % definition.id)
		assert_false(
			LEGACY_TITLES.has(definition.title), "%s non deve conservare il titolo pre-restyle." % definition.id
		)
		assert_false(seen_titles.has(definition.title), "Il nome %s non deve ripetersi fra le Specialità." % definition.title)
		seen_titles[definition.title] = true
		assert_false(
			definition.description.strip_edges().is_empty(),
			"%s deve mantenere una descrizione che spieghi l'effetto: il titolo da solo non lo fa più." % definition.id
		)
		_assert_themed_icon(definition, expected["icon"])


func test_themed_titles_do_not_collide_with_the_ordinary_catalog() -> void:
	var speciality_titles: Dictionary = {}
	for definition in _themed_definitions():
		speciality_titles[definition.title] = definition.id
	for ordinary in _ordinary_definitions():
		assert_false(
			speciality_titles.has(ordinary.title),
			(
				"Il catalogo statistico ordinario non deve usare il nome %s, riservato alla Specialità %s."
				% [ordinary.title, speciality_titles.get(ordinary.title, &"")]
			)
		)


func test_manifest_registers_every_new_icon() -> void:
	assert_true(FileAccess.file_exists(ICON_MANIFEST_PATH), "Le icone PS-078 richiedono un manifest.")
	var manifest := FileAccess.get_file_as_string(ICON_MANIFEST_PATH).to_lower()
	for definition in _themed_definitions():
		var icon_path: String = THEMED_IDENTITY[definition.id]["icon"]
		var runtime_hash := FileAccess.get_sha256(icon_path).to_lower()
		assert_false(runtime_hash.is_empty(), "L'icona di %s deve essere leggibile per calcolarne l'hash." % definition.id)
		assert_true(
			manifest.contains(icon_path.get_file().to_lower()),
			"Il manifest deve registrare il derivato %s." % icon_path.get_file()
		)
		assert_true(
			manifest.contains(runtime_hash), "Il manifest deve registrare l'hash SHA-256 di %s." % definition.title
		)


func test_barb_reward_overlay_resolves_the_themed_icons() -> void:
	var movement_slice := await instantiate_movement_slice()
	var controller := movement_slice.get_run_controller() as RunController
	var encounter := movement_slice.get_boss_encounter() as BossEncounter
	var service := movement_slice.get_upgrade_service() as UpgradeService
	var overlay := movement_slice.get_barb_reward_overlay() as BarbRewardOverlay
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	assert_true(
		controller != null and encounter != null and service != null and overlay != null,
		"La scena composta deve esporre le dipendenze della ricompensa di Barb."
	)
	if controller == null or encounter == null or service == null or overlay == null:
		return

	controller.set_process(false)
	if spawner != null:
		spawner.set_process(false)

	controller._process(120.01)
	var boss := encounter.get_active_boss()
	assert_true(boss != null, "La soglia deve generare il primo Boss.")
	if boss == null:
		controller.prepare_restart()
		return
	assert_true(encounter.complete_intro(), "AFFRONTA deve chiudere l'introduzione prima del combattimento.")
	assert_true(boss.take_damage(boss.get_health_component().health_max), "Il danno letale deve concludere il Boss.")

	# Un level-up ordinario può cadere nello stesso frame della morte del Boss:
	# Barb resta in coda finché quel modale non si chiude (vedi PS-012).
	var guard := 0
	while controller.get_state() == RunController.RunState.LEVEL_UP and guard < 10:
		var pending := service.get_current_offer()
		assert_false(pending.is_empty(), "Un level-up aperto deve avere un'offerta da consumare.")
		assert_true(service.select_upgrade(pending[0].id), "Il level-up in coda deve poter essere risolto.")
		guard += 1

	assert_eq(
		controller.get_state(),
		RunController.RunState.BARB_REWARD,
		"La morte del Boss deve aprire la ricompensa di Barb."
	)
	assert_true(overlay.visible, "L'overlay di Barb deve mostrare l'offerta tematizzata.")

	var shown := 0
	for card in overlay.get_cards():
		if not card.visible:
			continue
		var definition := card.get_definition()
		if definition == null or not definition.is_speciality:
			continue
		if not THEMED_IDENTITY.has(definition.id):
			continue
		shown += 1
		# La carta stampa il titolo in maiuscolo per scelta di layout (PS-047):
		# il confronto guarda il nome, non la resa tipografica.
		assert_eq(
			card.get_title_text(),
			String(THEMED_IDENTITY[definition.id]["title"]).to_upper(),
			"La carta di Barb deve mostrare il nome tematizzato di %s." % definition.id
		)
		var icon_rect := card.find_child("Icon", true, false) as TextureRect
		assert_true(icon_rect != null, "La carta di %s deve avere il proprio TextureRect icona." % definition.id)
		if icon_rect != null:
			assert_true(
				icon_rect.texture != null, "L'icona di %s non deve arrivare nulla alla UI." % definition.id
			)
			assert_eq(
				icon_rect.texture, definition.icon, "La carta deve mostrare esattamente l'icona della definizione."
			)
	assert_true(shown >= 1, "L'offerta di Barb deve mostrare almeno una Specialità tematizzata.")

	controller.prepare_restart()
	print("BARB_SPECIALITY_THEMING_SMOKE_OK")


func _themed_definitions() -> Array[UpgradeDefinition]:
	return [BEER, CHRONIC_DELAY, DAMAGE_SHOCKWAVE, DEATH_BURST, DOUBLE_BARREL, GOSSIP, PIERCING_ROUNDS]


func _assert_themed_icon(definition: UpgradeDefinition, expected_path: String) -> void:
	assert_true(definition.icon != null, "%s deve avere un'icona dedicata." % definition.id)
	if definition.icon == null:
		return
	assert_eq(definition.icon.resource_path, expected_path, "%s deve puntare alla nuova icona." % definition.id)
	assert_eq(definition.icon.get_size(), ICON_SIZE, "%s deve usare un'icona 128x128." % definition.id)
	assert_true(FileAccess.file_exists(expected_path), "File icona mancante per %s." % definition.title)


func _ordinary_definitions() -> Array[UpgradeDefinition]:
	var definitions: Array[UpgradeDefinition] = []
	var directory := DirAccess.open(ORDINARY_UPGRADE_DIRECTORY)
	assert_true(directory != null, "Il catalogo ordinario deve essere leggibile.")
	if directory == null:
		return definitions
	for file_name in directory.get_files():
		if not file_name.ends_with(".tres"):
			continue
		var definition := load(ORDINARY_UPGRADE_DIRECTORY + file_name) as UpgradeDefinition
		if definition != null and not definition.is_speciality:
			definitions.append(definition)
	assert_false(definitions.is_empty(), "Il confronto anti-collisione richiede un catalogo ordinario non vuoto.")
	return definitions
