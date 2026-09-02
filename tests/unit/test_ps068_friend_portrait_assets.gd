extends GutTest

const FRIEND_IDS: Array[StringName] = [
	&"alea",
	&"aleo",
	&"bea",
	&"lollo",
	&"magno",
	&"marghe",
	&"migi",
	&"zat",
]


func test_all_player_portraits_resolve_unique_definitive_assets() -> void:
	var portrait_paths: Array[String] = []
	for friend_id in FRIEND_IDS:
		var definition_path := "res://data/friends/%s.tres" % friend_id
		var definition := load(definition_path) as FriendDefinition
		assert_not_null(definition, "%s deve risolvere un FriendDefinition." % friend_id)
		if definition == null:
			continue

		var expected_path := (
			"res://assets/art/characters/%s/generated/portrait.png" % friend_id
		)
		assert_true(definition.portraits_approved, "%s deve mantenere l'approvazione." % friend_id)
		assert_false(
			definition.portraits_are_placeholders,
			"%s non deve più dichiarare il busto Player come placeholder." % friend_id
		)
		assert_not_null(definition.portrait, "%s deve avere il busto Player definitivo." % friend_id)
		assert_eq(
			definition.portrait,
			definition.portrait_placeholder,
			"%s deve usare il busto definitivo anche come fallback approvato." % friend_id
		)
		if definition.portrait == null:
			continue

		assert_false(
			definition.portrait is AtlasTexture,
			"%s non deve più usare un ritaglio AtlasTexture dello spritesheet CC0." % friend_id
		)
		assert_eq(
			definition.portrait.resource_path,
			expected_path,
			"%s deve puntare al derivato runtime PS-068." % friend_id
		)
		assert_eq(
			definition.portrait.get_size(),
			Vector2(256.0, 256.0),
			"%s deve usare un derivato runtime 256x256." % friend_id
		)
		assert_false(
			portrait_paths.has(expected_path),
			"%s non deve riusare il ritratto di un altro personaggio." % friend_id
		)
		portrait_paths.append(expected_path)

	assert_eq(portrait_paths.size(), FRIEND_IDS.size(), "La famiglia deve contenere otto busti unici.")
	print("FRIEND_PORTRAIT_ASSETS_SMOKE_OK")
