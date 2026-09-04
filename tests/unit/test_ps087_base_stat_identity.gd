extends GutTest

## PS-087 — Scarti di statistiche base motivati per ruolo.
##
## Verifica che ogni personaggio dichiarato in `docs/characters.md` abbia
## almeno uno scarto non neutro (nessun profilo resta `×1,0` su tutti e tre
## gli assi) e che i valori restino nell'intervallo B47 (`0,5–2,0`).

const FRIEND_IDS: Array[StringName] = [
	&"magno",
	&"bea",
	&"zat",
	&"alea",
	&"aleo",
	&"lollo",
	&"marghe",
	&"migi",
]


func test_no_profile_is_entirely_neutral_and_all_values_stay_in_range() -> void:
	for friend_id in FRIEND_IDS:
		var definition := load("res://data/friends/%s.tres" % friend_id) as FriendDefinition
		assert_not_null(definition, "Profilo mancante: %s." % friend_id)
		if definition == null:
			continue

		var health := definition.get_base_health_multiplier()
		var speed := definition.get_base_move_speed_multiplier()
		var fire_rate := definition.get_base_fire_rate_multiplier()

		for value in [health, speed, fire_rate]:
			assert_true(
				(
					value >= FriendDefinition.MINIMUM_BASE_STAT_MULTIPLIER
					and value <= FriendDefinition.MAXIMUM_BASE_STAT_MULTIPLIER
				),
				"%s dichiara uno scarto fuori dall'intervallo B47." % friend_id
			)

		var is_entirely_neutral := (
			is_equal_approx(health, 1.0)
			and is_equal_approx(speed, 1.0)
			and is_equal_approx(fire_rate, 1.0)
		)
		assert_false(
			is_entirely_neutral,
			"%s non deve restare neutro su tutti e tre gli assi: uno scarto interamente neutro non comunica un'identita' statistica (PS-087)." % friend_id
		)

	print("BASE_STAT_IDENTITY_SMOKE_OK")
