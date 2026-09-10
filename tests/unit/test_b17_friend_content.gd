extends GutGameplayTest

const MAGNO := preload("res://data/friends/magno.tres")
const BEA := preload("res://data/friends/bea.tres")
const ZAT := preload("res://data/friends/zat.tres")
const ALEA := preload("res://data/friends/alea.tres")
const ALEO := preload("res://data/friends/aleo.tres")
const LOLLO := preload("res://data/friends/lollo.tres")
const MIGI := preload("res://data/friends/migi.tres")
const MARGHE := preload("res://data/friends/marghe.tres")


func _definitions() -> Array[FriendDefinition]:
	return [
		MAGNO as FriendDefinition,
		BEA as FriendDefinition,
		ZAT as FriendDefinition,
		ALEA as FriendDefinition,
		ALEO as FriendDefinition,
		LOLLO as FriendDefinition,
		MIGI as FriendDefinition,
		MARGHE as FriendDefinition,
	]


func test_catalog_and_approvals() -> void:
	var registry := FriendRegistry.new()
	registry.definitions = _definitions()
	assert_true(registry.rebuild_registry(), "Gli otto profili B17 devono formare un catalogo valido.")
	assert_eq(registry.get_definitions().size(), 8, "Il roster dati B17 deve contenere otto amici.")
	assert_true(
		registry.is_catalog_publication_ready(), "Testi e ritratti placeholder devono avere un'approvazione registrata."
	)

	var expected_ids: Array[StringName] = [
		&"magno", &"bea", &"zat", &"alea", &"aleo", &"lollo", &"migi", &"marghe",
	]
	var expected_approval_dates := {
		&"aleo": "2026-08-28",
		&"bea": "2026-08-24",
		&"zat": "2026-08-24",
	}
	var seen_ability_ids: Dictionary = {}
	for friend_id in expected_ids:
		var definition := registry.resolve_definition(friend_id)
		assert_not_null(definition, "Profilo amico mancante: %s." % friend_id)
		if definition == null:
			continue
		assert_true(definition.is_valid(), "Profilo non valido: %s." % friend_id)
		assert_true(definition.is_publication_ready(), "Profilo non approvato: %s." % friend_id)
		assert_true(
			definition.approved_by == "Proprietario del progetto"
			and definition.approval_date == expected_approval_dates.get(friend_id, "2026-08-17")
			and not definition.approval_reference.is_empty(),
			"L'approvazione deve essere tracciabile per %s." % friend_id
		)
		assert_eq(
			definition.get_public_display_name(), definition.display_name, "Il nome approvato deve essere pubblico per %s." % friend_id
		)
		assert_eq(
			definition.get_public_evil_display_name(),
			"Evil %s" % definition.display_name,
			"La controparte Boss deve seguire la convenzione Evil <Nome>."
		)
		assert_true(
			definition.get_public_portrait() != null
			and definition.get_public_evil_portrait() != null,
			"I due ritratti pubblici di %s devono risolversi." % friend_id
		)
		assert_eq(
			definition.get_public_portrait().get_size(),
			Vector2(256.0, 256.0),
			"Il ritratto Player definitivo di %s deve usare il derivato PS-068 256x256." % friend_id
		)
		assert_true(
			not definition.portraits_are_placeholders and "PS-068" in definition.portrait_source,
			"L'origine del ritratto Player definitivo deve restare esplicita per %s." % friend_id
		)
		assert_false(
			seen_ability_ids.has(definition.active_ability_id), "Ogni amico deve dichiarare un Ability ID distinto."
		)
		seen_ability_ids[definition.active_ability_id] = true
	var marghe := registry.resolve_definition(&"marghe")
	assert_true(
		marghe != null
		and marghe.get_public_active_ability_title() == "Reggaeton time!"
		and "reggaeton" in marghe.get_public_active_ability_description().to_lower(),
		"L'attiva approvata di Marghe deve usare il retheme reggaeton."
	)
	registry.free()


func test_safe_fallbacks_and_asset_replacement() -> void:
	var pending := (MAGNO as FriendDefinition).duplicate(true) as FriendDefinition
	pending.display_name = "TESTO PERSONALE NON APPROVATO"
	pending.evil_display_name = "EVIL NON APPROVATO"
	pending.content_approved = false
	pending.portraits_approved = false
	assert_true(pending.is_valid(), "Un profilo pending con fallback deve restare valido.")
	assert_true(
		pending.get_public_display_name() == pending.safe_display_name
		and pending.get_public_evil_display_name() == pending.safe_evil_display_name,
		"Il copy pending non deve raggiungere l'output pubblico."
	)
	assert_true(
		pending.get_public_portrait() == pending.portrait_placeholder
		and pending.get_public_evil_portrait() == null,
		"Il ritratto Player pending deve risolversi nel placeholder approvato; l'Evil non ha fallback e resta vuoto."
	)

	var replacement := (MAGNO as FriendDefinition).duplicate(true) as FriendDefinition
	var replacement_portrait := GradientTexture2D.new()
	var replacement_evil_portrait := GradientTexture2D.new()
	replacement.portrait = replacement_portrait
	replacement.evil_portrait = replacement_evil_portrait
	replacement.portraits_are_placeholders = false
	replacement.portrait_source = "Fixture locale approvata"
	assert_true(replacement.is_valid(), "Un asset sostitutivo dati deve essere valido senza codice nuovo.")
	assert_true(
		replacement.get_public_portrait() == replacement_portrait
		and replacement.get_public_evil_portrait() == replacement_evil_portrait,
		"Il profilo deve esporre gli asset sostituiti direttamente dal Resource."
	)

	var missing_approval := (MAGNO as FriendDefinition).duplicate(true) as FriendDefinition
	missing_approval.approved_by = ""
	assert_false(
		missing_approval.is_valid(), "Un flag approvato senza autore/data/riferimento deve invalidare il profilo."
	)


func test_ambiguous_catalog_is_rejected() -> void:
	var duplicate := (MAGNO as FriendDefinition).duplicate(true) as FriendDefinition
	var third_duplicate := (MAGNO as FriendDefinition).duplicate(true) as FriendDefinition
	var registry := FriendRegistry.new()
	registry.definitions = [MAGNO as FriendDefinition, duplicate, third_duplicate]
	assert_false(registry.rebuild_registry(), "Il catalogo deve respingere ID amico duplicati.")
	assert_null(registry.resolve_definition(&"magno"), "Un profilo ambiguo non deve essere risolvibile.")
	registry.free()


func test_composed_scene_uses_approved_catalog() -> void:
	var movement_slice := await instantiate_movement_slice()

	var registry := movement_slice.get_friend_registry() as FriendRegistry
	var player := movement_slice.get_node_or_null("World/Player") as Player
	var boss_encounter := movement_slice.get_boss_encounter() as BossEncounter
	assert_true(
		registry != null and registry.is_catalog_publication_ready(), "La scena deve comporre il catalogo B17."
	)
	assert_true(
		player != null and player.get_friend_definition() == MAGNO, "Il Player corrente deve usare Magno dati."
	)
	if player != null:
		assert_eq(
			player.get_friend_definition().active_ability_id,
			player.get_ability_controller().get_definition().id,
			"Profilo e abilità equipaggiata di Magno devono coincidere."
		)
	assert_true(
		boss_encounter != null
		and boss_encounter.boss_definition.id == &"special_pigeon"
		and not boss_encounter.boss_definition.is_evil_variant()
		and boss_encounter.boss_definition.get_safe_title() == "PICCIONE MALVAGIO",
		"Il Boss baseline B22 deve essere il piccione malvagio approvato."
	)
	assert_true(
		boss_encounter != null and boss_encounter.boss_definition.get_safe_portrait() != null,
		"Il Boss baseline deve esporre il ritratto del piccione speciale."
	)

	var run_controller := movement_slice.get_run_controller() as RunController
	if run_controller != null:
		run_controller.prepare_restart()
