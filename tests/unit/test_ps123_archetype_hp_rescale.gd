extends GutTest

## PS-123 — Ricalibra HP/danno degli arcehtipi nemici dopo PS-076.
##
## PS-076 ha densificato lo spawn del piccione base di un fattore 12/7 e ha
## ricalibrato in proporzione (fattore 7/12) il suo HP/danno da contatto, ma
## non ha mai toccato i quattro archetipi (swarmer/ranged/armored/splitter)
## ne' il frammento del divisore: la loro HP/danno era rimasta quella
## pre-PS-076. Questo test fissa i valori ricalibrati e, soprattutto, blocca
## una regressione in cui qualcuno tocchi di nuovo solo un sottoinsieme degli
## archetipi.
##
## Fattore di riferimento: 7.0 / 12.0, lo stesso gia' applicato al piccione
## base in PS-076 (18->10 HP, 20->12 danno). Sugli esatti multipli di 0.5
## generati da questo fattore, PS-076 ha arrotondato per difetto (18*7/12=10.5
## -> 10, 18*7/12 danno 20*7/12=11.67 -> 12 e' invece un arrotondamento
## normale, nessuna ambiguita'): questo test applica la stessa convenzione
## (arrotondamento normale, ma per difetto sui multipli esatti di 0.5) ai
## quattro archetipi + frammento.

const RESCALE_FACTOR := 7.0 / 12.0
const TOLERANCE := 0.01

## archetype_id -> [health_max pre-PS-076, contact_damage pre-PS-076]
const PRE_PS076_STATS := {
	&"swarmer": [9.0, 12.0],
	&"ranged": [16.0, 12.0],
	&"armored": [54.0, 26.0],
	&"splitter": [26.0, 18.0],
	&"splitter_fragment": [7.0, 10.0],
}

## archetype_id -> path del .tres
const ARCHETYPE_PATHS := {
	&"swarmer": "res://data/enemies/enemy_archetype_swarmer.tres",
	&"ranged": "res://data/enemies/enemy_archetype_ranged.tres",
	&"armored": "res://data/enemies/enemy_archetype_armored.tres",
	&"splitter": "res://data/enemies/enemy_archetype_splitter.tres",
	&"splitter_fragment": "res://data/enemies/enemy_archetype_splitter_fragment.tres",
}

## archetype_id -> [health_max atteso, contact_damage atteso] (7/12 di
## PRE_PS076_STATS, arrotondato all'intero piu' vicino e per difetto sui
## multipli esatti di 0.5, come PS-076 per il piccione base).
const EXPECTED_STATS := {
	&"swarmer": [5.0, 7.0],
	&"ranged": [9.0, 7.0],
	&"armored": [31.0, 15.0],
	&"splitter": [15.0, 10.0],
	&"splitter_fragment": [4.0, 6.0],
}


func test_archetypes_are_rescaled_by_the_same_factor_as_the_base_pigeon() -> void:
	for archetype_id in ARCHETYPE_PATHS:
		var definition := load(ARCHETYPE_PATHS[archetype_id]) as EnemyArchetypeDefinition
		assert_not_null(definition, "Archetipo mancante: %s." % archetype_id)
		if definition == null:
			continue

		var expected: Array = EXPECTED_STATS[archetype_id]
		assert_eq(
			definition.health_max,
			expected[0],
			"%s deve avere health_max=%s (7/12 del valore pre-PS-076)." % [archetype_id, expected[0]]
		)
		assert_eq(
			definition.contact_damage,
			expected[1],
			"%s deve avere contact_damage=%s (7/12 del valore pre-PS-076)." % [archetype_id, expected[1]]
		)


func test_expected_stats_match_the_pre_ps076_reference_within_rounding() -> void:
	# Blocca una regressione piu' sottile: verifica che EXPECTED_STATS sia
	# davvero derivato dal fattore 7/12 applicato ai valori storici, non solo
	# scelto a mano scollegato dal riferimento.
	for archetype_id in PRE_PS076_STATS:
		var pre: Array = PRE_PS076_STATS[archetype_id]
		var expected: Array = EXPECTED_STATS[archetype_id]
		for stat_index in range(2):
			var rescaled: float = float(pre[stat_index]) * RESCALE_FACTOR
			assert_true(
				absf(rescaled - expected[stat_index]) <= TOLERANCE + 0.5,
				(
					"%s: il valore atteso %s si scosta troppo dal 7/12 esatto (%.4f) del riferimento pre-PS-076."
					% [archetype_id, expected[stat_index], rescaled]
				)
			)


func test_base_pigeon_is_unchanged_by_this_card() -> void:
	# Il piccione base e' gia' corretto da PS-076: questa card non lo tocca.
	var scene := load("res://scenes/actors/base_enemy.tscn") as PackedScene
	assert_not_null(scene, "Scena del piccione base mancante.")
	if scene == null:
		return
	var instance := scene.instantiate()
	if not instance is BaseEnemy:
		instance.queue_free()
		fail_test("base_enemy.tscn deve avere BaseEnemy come nodo root.")
		return
	add_child_autofree(instance)
	var enemy := instance as BaseEnemy
	var health_component := enemy.get_health_component()
	var contact_damage := enemy.get_contact_damage()
	assert_not_null(health_component, "Il piccione base deve avere una HealthComponent.")
	assert_not_null(contact_damage, "Il piccione base deve avere un ContactDamage.")
	if health_component != null:
		assert_eq(health_component.health_max, 10.0, "Il piccione base resta a 10 HP (PS-076), invariato da PS-123.")
	if contact_damage != null:
		assert_eq(contact_damage.damage, 12.0, "Il piccione base resta a 12 danno (PS-076), invariato da PS-123.")

	print("PS123_ARCHETYPE_HP_RESCALE_SMOKE_OK")
