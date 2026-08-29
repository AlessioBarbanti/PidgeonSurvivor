extends GutTest

## Prototipo GUT: nessuna scene tree, nessuna movement_slice — solo Resource.


func _make_snapshot(rank: int, cooldown: float) -> AbilityRankSnapshot:
	var snapshot := AbilityRankSnapshot.new()
	snapshot.rank = rank
	snapshot.cooldown_seconds = cooldown
	snapshot.duration_seconds = 0.0
	snapshot.area_radius = 100.0
	snapshot.damage = 10.0
	snapshot.effect_parameters = {"strike_count": rank}
	return snapshot


func _make_definition_with_ranks() -> AbilityDefinition:
	var definition := AbilityDefinition.new()
	definition.id = &"test_ability"
	definition.title = "Test"
	definition.effect_id = &"test_effect"
	definition.rank_snapshots = [
		_make_snapshot(1, 8.0),
		_make_snapshot(2, 7.5),
		_make_snapshot(3, 7.0),
		_make_snapshot(4, 6.5),
		_make_snapshot(5, 6.0),
	]
	var baseline := definition.get_rank_snapshot(1)
	definition.cooldown_seconds = baseline.cooldown_seconds
	definition.duration_seconds = baseline.duration_seconds
	definition.area_radius = baseline.area_radius
	definition.damage = baseline.damage
	definition.effect_parameters = baseline.effect_parameters.duplicate(true)
	return definition


func test_definition_without_snapshots_is_valid_at_rank_one() -> void:
	var definition := AbilityDefinition.new()
	definition.id = &"magno_earthquake_shockwave"
	definition.title = "Terremoto"
	definition.effect_id = &"earthquake"
	assert_true(definition.is_valid(), "Una AbilityDefinition senza rank deve essere valida al rank 1.")


func test_resolve_rank_returns_null_outside_declared_ranks() -> void:
	var definition := _make_definition_with_ranks()
	assert_null(definition.resolve_rank(6), "Un rank non dichiarato deve risolvere a null.")


func test_resolve_rank_applies_snapshot_values() -> void:
	var definition := _make_definition_with_ranks()
	var resolved := definition.resolve_rank(3)
	assert_not_null(resolved, "Il rank 3 dichiarato deve risolvere.")
	assert_eq(resolved.get_resolved_rank(), 3, "Il resolved deve riportare il rank richiesto.")
	assert_almost_eq(resolved.cooldown_seconds, 7.0, 0.001, "Il cooldown deve provenire dallo snapshot rank 3.")
	assert_eq(resolved.effect_parameters.get("strike_count"), 3, "I parametri effetto devono provenire dallo snapshot.")


func test_resolve_rank_does_not_mutate_original_definition() -> void:
	var definition := _make_definition_with_ranks()
	var original_cooldown := definition.cooldown_seconds
	definition.resolve_rank(5)
	assert_almost_eq(
		definition.cooldown_seconds,
		original_cooldown,
		0.001,
		"resolve_rank deve restituire una copia, mai mutare l'originale."
	)


func test_incomplete_rank_snapshots_are_invalid() -> void:
	var definition := _make_definition_with_ranks()
	definition.rank_snapshots = definition.rank_snapshots.slice(0, 4)
	assert_false(definition.is_valid(), "Con meno di cinque rank la definizione non deve essere valida.")
