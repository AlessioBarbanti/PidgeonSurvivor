extends SceneTree

const MOVEMENT_SLICE_SCENE := preload("res://scenes/game/movement_slice.tscn")
const MAGNO := preload("res://data/friends/magno.tres")
const BEA := preload("res://data/friends/bea.tres")
const ZAT := preload("res://data/friends/zat.tres")
const ALEA := preload("res://data/friends/alea.tres")
const ALEO := preload("res://data/friends/aleo.tres")
const LOLLO := preload("res://data/friends/lollo.tres")
const MIGI := preload("res://data/friends/migi.tres")
const MARGHE := preload("res://data/friends/marghe.tres")
const DERIVED_SHEET_PATH := (
	"res://assets/art/third_party/eldiran_rpg_characters/"
	+ "RPGCharacterSprites32x32-transparent.png"
)
const EXPECTED_DERIVED_SHA256 := (
	"60A60B1BEC00296E31EA2121FF1B461EDABD31075765066AF52A538B05CAE2AF"
)
const INITIAL_VIEWPORT_SIZE := Vector2i(1280, 720)

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	paused = false
	root.size = INITIAL_VIEWPORT_SIZE
	await process_frame
	_validate_catalog_and_approvals()
	_validate_safe_fallbacks_and_replacement()
	_validate_ambiguous_catalog_rejection()
	_validate_asset_integrity()
	await _validate_composed_scene()
	await _finish()


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


func _validate_catalog_and_approvals() -> void:
	var registry := FriendRegistry.new()
	registry.definitions = _definitions()
	_expect(registry.rebuild_registry(), "Gli otto profili B17 devono formare un catalogo valido.")
	_expect(registry.get_definitions().size() == 8, "Il roster dati B17 deve contenere otto amici.")
	_expect(
		registry.is_catalog_publication_ready(),
		"Testi e ritratti placeholder devono avere un'approvazione registrata."
	)

	var expected_ids: Array[StringName] = [
		&"magno", &"bea", &"zat", &"alea", &"aleo", &"lollo", &"migi", &"marghe",
	]
	var seen_ability_ids: Dictionary = {}
	for friend_id in expected_ids:
		var definition := registry.resolve_definition(friend_id)
		_expect(definition != null, "Profilo amico mancante: %s." % friend_id)
		if definition == null:
			continue
		_expect(definition.is_valid(), "Profilo non valido: %s." % friend_id)
		_expect(definition.is_publication_ready(), "Profilo non approvato: %s." % friend_id)
		_expect(
			definition.approved_by == "Proprietario del progetto"
			and definition.approval_date == "2026-08-17"
			and not definition.approval_reference.is_empty(),
			"L'approvazione deve essere tracciabile per %s." % friend_id
		)
		_expect(
			definition.get_public_display_name() == definition.display_name,
			"Il nome approvato deve essere pubblico per %s." % friend_id
		)
		_expect(
			definition.get_public_evil_display_name() == "Evil %s" % definition.display_name,
			"La controparte Boss deve seguire la convenzione Evil <Nome>."
		)
		_expect(
			definition.get_public_portrait() != null
			and definition.get_public_evil_portrait() != null
			and definition.get_public_portrait().get_size() == Vector2(32.0, 32.0)
			and definition.get_public_evil_portrait().get_size() == Vector2(32.0, 32.0),
			"I due ritratti placeholder di %s devono essere ritagli 32x32." % friend_id
		)
		_expect(
			definition.portraits_are_placeholders
			and "CC0" in definition.portrait_source,
			"L'origine placeholder deve restare esplicita per %s." % friend_id
		)
		_expect(
			not seen_ability_ids.has(definition.active_ability_id),
			"Ogni amico deve dichiarare un Ability ID distinto."
		)
		seen_ability_ids[definition.active_ability_id] = true
	var marghe := registry.resolve_definition(&"marghe")
	_expect(
		marghe != null
		and marghe.get_public_active_ability_title() == "Reggeton time!"
		and "reggaeton" in marghe.get_public_active_ability_description().to_lower(),
		"L'attiva approvata di Marghe deve usare il retheme reggaeton."
	)
	registry.free()


func _validate_safe_fallbacks_and_replacement() -> void:
	var pending := (MAGNO as FriendDefinition).duplicate(true) as FriendDefinition
	pending.display_name = "TESTO PERSONALE NON APPROVATO"
	pending.evil_display_name = "EVIL NON APPROVATO"
	pending.content_approved = false
	pending.portraits_approved = false
	_expect(pending.is_valid(), "Un profilo pending con fallback deve restare valido.")
	_expect(
		pending.get_public_display_name() == pending.safe_display_name
		and pending.get_public_evil_display_name() == pending.safe_evil_display_name,
		"Il copy pending non deve raggiungere l'output pubblico."
	)
	_expect(
		pending.get_public_portrait() == pending.portrait_placeholder
		and pending.get_public_evil_portrait() == pending.evil_portrait_placeholder,
		"Un asset pending deve risolversi nel placeholder approvato."
	)

	var replacement := (MAGNO as FriendDefinition).duplicate(true) as FriendDefinition
	var replacement_portrait := GradientTexture2D.new()
	var replacement_evil_portrait := GradientTexture2D.new()
	replacement.portrait = replacement_portrait
	replacement.evil_portrait = replacement_evil_portrait
	replacement.portraits_are_placeholders = false
	replacement.portrait_source = "Fixture locale approvata"
	_expect(replacement.is_valid(), "Un asset sostitutivo dati deve essere valido senza codice nuovo.")
	_expect(
		replacement.get_public_portrait() == replacement_portrait
		and replacement.get_public_evil_portrait() == replacement_evil_portrait,
		"Il profilo deve esporre gli asset sostituiti direttamente dal Resource."
	)

	var missing_approval := (MAGNO as FriendDefinition).duplicate(true) as FriendDefinition
	missing_approval.approved_by = ""
	_expect(
		not missing_approval.is_valid(),
		"Un flag approvato senza autore/data/riferimento deve invalidare il profilo."
	)


func _validate_ambiguous_catalog_rejection() -> void:
	var duplicate := (MAGNO as FriendDefinition).duplicate(true) as FriendDefinition
	var third_duplicate := (MAGNO as FriendDefinition).duplicate(true) as FriendDefinition
	var registry := FriendRegistry.new()
	registry.definitions = [MAGNO as FriendDefinition, duplicate, third_duplicate]
	_expect(not registry.rebuild_registry(), "Il catalogo deve respingere ID amico duplicati.")
	_expect(
		registry.resolve_definition(&"magno") == null,
		"Un profilo ambiguo non deve essere risolvibile."
	)
	registry.free()


func _validate_asset_integrity() -> void:
	var bytes := FileAccess.get_file_as_bytes(DERIVED_SHEET_PATH)
	_expect(not bytes.is_empty(), "Il foglio sprite CC0 derivato deve essere incluso.")
	if bytes.is_empty():
		return
	var hashing := HashingContext.new()
	_expect(hashing.start(HashingContext.HASH_SHA256) == OK, "SHA-256 asset non inizializzabile.")
	_expect(hashing.update(bytes) == OK, "SHA-256 asset non aggiornabile.")
	var digest := hashing.finish().hex_encode().to_upper()
	_expect(
		digest == EXPECTED_DERIVED_SHA256,
		"Il foglio derivato deve corrispondere all'hash documentato."
	)


func _validate_composed_scene() -> void:
	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate()
	root.add_child(movement_slice)
	await process_frame
	await process_frame

	var registry := movement_slice.get_friend_registry() as FriendRegistry
	var player := movement_slice.get_node_or_null("World/Player") as Player
	var boss_encounter := movement_slice.get_boss_encounter() as BossEncounter
	_expect(registry != null and registry.is_catalog_publication_ready(), "La scena deve comporre il catalogo B17.")
	_expect(player != null and player.get_friend_definition() == MAGNO, "Il Player corrente deve usare Magno dati.")
	if player != null:
		_expect(
			player.get_friend_definition().active_ability_id
			== player.get_ability_controller().get_definition().id,
			"Profilo e abilità equipaggiata di Magno devono coincidere."
		)
	_expect(
		boss_encounter != null
		and boss_encounter.boss_definition.friend_profile == BEA
		and boss_encounter.boss_definition.get_safe_title() == "Evil Bea",
		"Il primo Boss dati deve essere la controparte Evil approvata di Bea."
	)
	_expect(
		boss_encounter != null
		and boss_encounter.boss_definition.get_safe_portrait()
		== (BEA as FriendDefinition).get_public_evil_portrait(),
		"Il Boss deve riusare l'asset Evil sostituibile del profilo amico."
	)

	var run_controller := movement_slice.get_run_controller() as RunController
	if run_controller != null:
		run_controller.prepare_restart()
	paused = false
	movement_slice.queue_free()
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	paused = false
	await process_frame
	if _failures.is_empty():
		print("B17_FRIEND_CONTENT_SMOKE_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	printerr("B17_FRIEND_CONTENT_SMOKE_FAIL count=%d" % _failures.size())
	quit(1)
