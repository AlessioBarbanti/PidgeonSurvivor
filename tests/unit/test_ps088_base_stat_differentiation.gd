extends GutTest

## PS-088 — Guardrail automatico sulla differenziazione statistica dei
## personaggi dichiarata da PS-087.
##
## Scopre dinamicamente ogni `data/friends/*.tres` (nessun elenco statico nel
## test) e fallisce se due profili condividono la stessa tripla di scarti
## entro la soglia di PS-087, o se un profilo resta interamente neutro su
## tutti e tre gli assi.

const FRIENDS_DIRECTORY := "res://data/friends"
const DIFFERENTIATION_THRESHOLD := 0.03


func test_no_profile_is_neutral_and_no_pair_collapses_within_threshold() -> void:
	var definitions := _discover_friend_definitions()
	assert_true(
		definitions.size() >= 2,
		"Servono almeno due profili in %s per verificare la differenziazione." % FRIENDS_DIRECTORY
	)

	for definition in definitions:
		var is_entirely_neutral := (
			is_equal_approx(definition.get_base_health_multiplier(), 1.0)
			and is_equal_approx(definition.get_base_move_speed_multiplier(), 1.0)
			and is_equal_approx(definition.get_base_fire_rate_multiplier(), 1.0)
		)
		assert_false(
			is_entirely_neutral,
			"%s non deve restare neutro su tutti e tre gli assi (PS-087)." % definition.id
		)

	for i in definitions.size():
		for j in range(i + 1, definitions.size()):
			var profile_a: FriendDefinition = definitions[i]
			var profile_b: FriendDefinition = definitions[j]
			var health_delta := absf(
				profile_a.get_base_health_multiplier() - profile_b.get_base_health_multiplier()
			)
			var speed_delta := absf(
				profile_a.get_base_move_speed_multiplier() - profile_b.get_base_move_speed_multiplier()
			)
			var fire_rate_delta := absf(
				profile_a.get_base_fire_rate_multiplier() - profile_b.get_base_fire_rate_multiplier()
			)
			var collapses_within_threshold := (
				health_delta < DIFFERENTIATION_THRESHOLD
				and speed_delta < DIFFERENTIATION_THRESHOLD
				and fire_rate_delta < DIFFERENTIATION_THRESHOLD
			)
			assert_false(
				collapses_within_threshold,
				(
					"%s e %s condividono la stessa tripla di scarti entro la soglia %.2f (PS-087)."
					% [profile_a.id, profile_b.id, DIFFERENTIATION_THRESHOLD]
				)
			)

	print("BASE_STAT_DIFFERENTIATION_SMOKE_OK")


func _discover_friend_definitions() -> Array[FriendDefinition]:
	var discovered: Array[FriendDefinition] = []
	var dir := DirAccess.open(FRIENDS_DIRECTORY)
	assert_not_null(dir, "Cartella dei profili amico mancante: %s." % FRIENDS_DIRECTORY)
	if dir == null:
		return discovered
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var definition := load("%s/%s" % [FRIENDS_DIRECTORY, file_name]) as FriendDefinition
			assert_not_null(definition, "Impossibile caricare il profilo: %s." % file_name)
			if definition != null:
				discovered.append(definition)
		file_name = dir.get_next()
	dir.list_dir_end()
	return discovered
