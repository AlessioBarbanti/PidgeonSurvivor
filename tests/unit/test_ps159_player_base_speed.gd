extends GutTest

## PS-159 — Baseline di movimento più controllabile.
##
## Verifica il valore condiviso, la composizione moltiplicativa degli scarti
## del cast e il picco di Slancio che conserva l'identità mobile di Magno.

const PLAYER_SCENE := preload("res://scenes/actors/player.tscn")
const MAGNO := preload("res://data/friends/magno.tres")
const FRIEND_IDS: Array[StringName] = [
	&"magno",
	&"bea",
	&"zat",
	&"alea",
	&"aleo",
	&"lollo",
	&"migi",
	&"marghe",
]
const EXPECTED_BASE_MOVE_SPEED := 300.0
const PREVIOUS_BASE_MOVE_SPEED := 360.0
const FLOAT_TOLERANCE := 0.001


func test_shared_baseline_is_reduced_and_character_spreads_compose() -> void:
	var player := PLAYER_SCENE.instantiate() as Player
	add_child_autofree(player)
	await get_tree().process_frame
	player.set_physics_process(false)
	player.reset_character_stat_multipliers()

	assert_almost_eq(
		Player.DEFAULT_MOVE_SPEED,
		EXPECTED_BASE_MOVE_SPEED,
		FLOAT_TOLERANCE,
		"La baseline autorevole deve essere 300 px/s."
	)
	assert_true(
		player.get_base_move_speed() < PREVIOUS_BASE_MOVE_SPEED,
		"La nuova baseline deve essere inferiore ai precedenti 360 px/s."
	)
	assert_almost_eq(
		player.get_base_move_speed(),
		EXPECTED_BASE_MOVE_SPEED,
		FLOAT_TOLERANCE,
		"Senza scarti di personaggio il Player deve usare la baseline condivisa."
	)

	for friend_id in FRIEND_IDS:
		var definition := load("res://data/friends/%s.tres" % friend_id) as FriendDefinition
		assert_not_null(definition, "Profilo mancante: %s." % friend_id)
		if definition == null:
			continue
		var character_multiplier := definition.get_base_move_speed_multiplier()
		assert_true(
			player.set_character_stat_multipliers(character_multiplier),
			"Lo scarto di %s deve essere applicabile." % friend_id
		)
		assert_almost_eq(
			player.get_base_move_speed(),
			EXPECTED_BASE_MOVE_SPEED * character_multiplier,
			FLOAT_TOLERANCE,
			"%s deve conservare il proprio scarto sulla nuova baseline." % friend_id
		)

	print("PS159_PLAYER_BASE_SPEED_SMOKE_OK")


func test_magno_momentum_still_exceeds_the_shared_baseline() -> void:
	var player := PLAYER_SCENE.instantiate() as Player
	add_child_autofree(player)
	await get_tree().process_frame
	player.set_physics_process(false)
	player.reset_character_stat_multipliers()

	var base_multiplier := MAGNO.get_base_move_speed_multiplier()
	var momentum_multiplier := MAGNO.get_passive_float(
		&"max_move_speed_multiplier",
		1.35,
		1.0
	)
	assert_true(
		player.set_character_stat_multipliers(base_multiplier * momentum_multiplier),
		"Il picco di Slancio di Magno deve restare applicabile."
	)
	assert_almost_eq(
		player.get_base_move_speed(),
		EXPECTED_BASE_MOVE_SPEED * base_multiplier * momentum_multiplier,
		FLOAT_TOLERANCE,
		"Slancio deve continuare a comporsi con lo scarto base di Magno."
	)
	assert_true(
		player.get_base_move_speed() > EXPECTED_BASE_MOVE_SPEED,
		"A Slancio massimo Magno deve superare la baseline condivisa."
	)
