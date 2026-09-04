extends GutGameplayTest

## B47 — Scarti di statistiche base per profilo.
##
## Verifica che `FriendDefinition` dichiari scarti di partenza, che il default
## resti neutro per un profilo non aggiornato, che i valori malformati vengano
## normalizzati e che gli scarti compongano moltiplicativamente con la passiva
## senza mutare i dati base condivisi di Player e arma.

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


## Un profilo che non dichiara scarti deve restare identico alla baseline
## condivisa: e' la garanzia che la slice sia incrementale.
func test_definition_defaults_and_normalization() -> void:
	var definition := FriendDefinition.new()
	assert_almost_eq(
		definition.get_base_health_multiplier(), 1.0, FLOAT_TOLERANCE, "Il default della salute deve essere neutro."
	)
	assert_almost_eq(
		definition.get_base_move_speed_multiplier(), 1.0, FLOAT_TOLERANCE, "Il default del movimento deve essere neutro."
	)
	assert_almost_eq(
		definition.get_base_fire_rate_multiplier(), 1.0, FLOAT_TOLERANCE, "Il default della cadenza deve essere neutro."
	)
	assert_false(
		definition.has_base_stat_spread(), "Un profilo senza scarti non deve risultare caratterizzato."
	)

	# Valori fuori intervallo o non finiti non possono sostituire la baseline.
	definition.base_health_multiplier = 99.0
	definition.base_move_speed_multiplier = -4.0
	definition.base_fire_rate_multiplier = NAN
	assert_almost_eq(
		definition.get_base_health_multiplier(),
		FriendDefinition.MAXIMUM_BASE_STAT_MULTIPLIER,
		FLOAT_TOLERANCE,
		"Uno scarto sopra il massimo deve essere normalizzato."
	)
	assert_almost_eq(
		definition.get_base_move_speed_multiplier(),
		FriendDefinition.MINIMUM_BASE_STAT_MULTIPLIER,
		FLOAT_TOLERANCE,
		"Uno scarto sotto il minimo deve essere normalizzato."
	)
	assert_almost_eq(
		definition.get_base_fire_rate_multiplier(), 1.0, FLOAT_TOLERANCE, "Uno scarto non finito deve ricadere sul valore neutro."
	)


func test_declared_profiles_stay_in_range() -> void:
	var characterized := 0
	for friend_id in FRIEND_IDS:
		var definition := load("res://data/friends/%s.tres" % friend_id) as FriendDefinition
		assert_not_null(definition, "Profilo mancante: %s." % friend_id)
		if definition == null:
			continue
		for value in [
			definition.get_base_health_multiplier(),
			definition.get_base_move_speed_multiplier(),
			definition.get_base_fire_rate_multiplier(),
		]:
			assert_true(
				(
					value >= FriendDefinition.MINIMUM_BASE_STAT_MULTIPLIER
					and value <= FriendDefinition.MAXIMUM_BASE_STAT_MULTIPLIER
				),
				"%s dichiara uno scarto fuori intervallo." % friend_id
			)
		if definition.has_base_stat_spread():
			characterized += 1
	assert_true(characterized >= 6, "La maggioranza del roster deve dichiarare uno scarto proprio.")


func test_runtime_composition_with_passive_and_reset() -> void:
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_run_controller() as RunController
	var registry := movement_slice.get_friend_registry() as FriendRegistry
	var player := movement_slice.get_player() as Player
	var passive := movement_slice.get_friend_passive_controller() as FriendPassiveController
	var weapon := movement_slice.get_weapon_controller() as WeaponController
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	assert_true(
		controller != null and registry != null and player != null and passive != null and weapon != null,
		"La scena di run deve esporre le dipendenze B47."
	)
	if controller == null or registry == null or player == null or passive == null or weapon == null:
		return

	controller.set_process(false)
	player.set_physics_process(false)
	weapon.set_process(false)
	passive.set_process(false)
	if spawner != null:
		spawner.set_process(false)
	controller.start_run(4711)

	# La scena avvia gia' con un profilo equipaggiato: la baseline condivisa si
	# osserva soltanto dopo aver rimosso i moltiplicatori di personaggio.
	player.reset_character_stat_multipliers()
	weapon.reset_character_stat_multipliers()
	var baseline_health := player.get_health_component().health_max
	var baseline_move := player.get_base_move_speed()

	# Magno: passiva movimento (B45: slancio, 1,0 a slancio zero senza fisica
	# attiva in questa fixture) composta con il proprio scarto base.
	var magno := registry.resolve_definition(&"magno")
	_equip(player, passive, magno)
	assert_almost_eq(
		player.get_character_move_speed_multiplier(),
		1.0 * magno.get_base_move_speed_multiplier(),
		FLOAT_TOLERANCE,
		"Magno deve comporre passiva e scarto base sul movimento."
	)
	assert_almost_eq(
		weapon.get_character_fire_rate_multiplier(),
		magno.get_base_fire_rate_multiplier(),
		FLOAT_TOLERANCE,
		"Senza passiva sulla cadenza resta il solo scarto base."
	)
	assert_almost_eq(
		player.get_health_component().health_max,
		baseline_health * magno.get_base_health_multiplier(),
		FLOAT_TOLERANCE,
		"Lo scarto di salute deve applicarsi al massimo effettivo."
	)
	assert_almost_eq(
		player.get_base_move_speed(),
		baseline_move * 1.0 * magno.get_base_move_speed_multiplier(),
		FLOAT_TOLERANCE,
		"La velocita' base effettiva deve riflettere la composizione."
	)

	# Cambiando personaggio gli scarti del profilo precedente si azzerano e
	# restano soltanto i contributi del nuovo profilo (PS-087: Alea non e'
	# piu' il profilo neutro, ma la composizione resta dinamica sui getter).
	var alea := registry.resolve_definition(&"alea")
	_equip(player, passive, alea)
	assert_almost_eq(
		player.get_health_component().health_max,
		baseline_health * alea.get_base_health_multiplier(),
		FLOAT_TOLERANCE,
		"Il cambio profilo deve ricalcolare la salute sul nuovo scarto."
	)
	assert_almost_eq(
		weapon.get_character_fire_rate_multiplier(),
		alea.get_base_fire_rate_multiplier(),
		FLOAT_TOLERANCE,
		"Il cambio profilo non deve conservare la cadenza del profilo precedente."
	)

	# I dati base condivisi non vengono mutati: rimuovere il profilo riporta
	# esattamente alla baseline di scena.
	passive._definition = null
	player.reset_character_stat_multipliers()
	weapon.reset_character_stat_multipliers()
	assert_almost_eq(
		player.get_health_component().health_max, baseline_health, FLOAT_TOLERANCE, "Il reset deve riportare la salute alla baseline condivisa."
	)
	assert_almost_eq(
		player.get_base_move_speed(), baseline_move, FLOAT_TOLERANCE, "Il reset deve riportare la velocita' alla baseline condivisa."
	)

	controller.prepare_restart()


func _equip(player: Player, passive: FriendPassiveController, definition: FriendDefinition) -> void:
	assert_not_null(definition, "Definizione mancante durante l'equipaggiamento.")
	if definition == null:
		return
	player.set_friend_definition(definition)
	assert_true(passive.equip_definition(definition), "La passiva deve accettare %s." % definition.id)
