extends SceneTree

## B47 — Scarti di statistiche base per profilo.
##
## Verifica che `FriendDefinition` dichiari scarti di partenza, che il default
## resti neutro per un profilo non aggiornato, che i valori malformati vengano
## normalizzati e che gli scarti compongano moltiplicativamente con la passiva
## senza mutare i dati base condivisi di Player e arma.

const MOVEMENT_SLICE_SCENE := preload("res://scenes/game/movement_slice.tscn")
const INITIAL_VIEWPORT_SIZE := Vector2i(1280, 720)
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
const FLOAT_TOLERANCE := 0.001

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	paused = false
	root.content_scale_size = INITIAL_VIEWPORT_SIZE
	root.size = INITIAL_VIEWPORT_SIZE
	await process_frame
	_validate_definition_defaults()
	_validate_declared_profiles()
	await _validate_runtime_composition()
	await _finish()


## Un profilo che non dichiara scarti deve restare identico alla baseline
## condivisa: e' la garanzia che la slice sia incrementale.
func _validate_definition_defaults() -> void:
	var definition := FriendDefinition.new()
	_expect_float_near(
		definition.get_base_health_multiplier(),
		1.0,
		"Il default della salute deve essere neutro."
	)
	_expect_float_near(
		definition.get_base_move_speed_multiplier(),
		1.0,
		"Il default del movimento deve essere neutro."
	)
	_expect_float_near(
		definition.get_base_fire_rate_multiplier(),
		1.0,
		"Il default della cadenza deve essere neutro."
	)
	_expect(
		not definition.has_base_stat_spread(),
		"Un profilo senza scarti non deve risultare caratterizzato."
	)

	# Valori fuori intervallo o non finiti non possono sostituire la baseline.
	definition.base_health_multiplier = 99.0
	definition.base_move_speed_multiplier = -4.0
	definition.base_fire_rate_multiplier = NAN
	_expect_float_near(
		definition.get_base_health_multiplier(),
		FriendDefinition.MAXIMUM_BASE_STAT_MULTIPLIER,
		"Uno scarto sopra il massimo deve essere normalizzato."
	)
	_expect_float_near(
		definition.get_base_move_speed_multiplier(),
		FriendDefinition.MINIMUM_BASE_STAT_MULTIPLIER,
		"Uno scarto sotto il minimo deve essere normalizzato."
	)
	_expect_float_near(
		definition.get_base_fire_rate_multiplier(),
		1.0,
		"Uno scarto non finito deve ricadere sul valore neutro."
	)


func _validate_declared_profiles() -> void:
	var characterized := 0
	for friend_id in FRIEND_IDS:
		var definition := load(
			"res://data/friends/%s.tres" % friend_id
		) as FriendDefinition
		_expect(definition != null, "Profilo mancante: %s." % friend_id)
		if definition == null:
			continue
		for value in [
			definition.get_base_health_multiplier(),
			definition.get_base_move_speed_multiplier(),
			definition.get_base_fire_rate_multiplier(),
		]:
			_expect(
				(
					value >= FriendDefinition.MINIMUM_BASE_STAT_MULTIPLIER
					and value <= FriendDefinition.MAXIMUM_BASE_STAT_MULTIPLIER
				),
				"%s dichiara uno scarto fuori intervallo." % friend_id
			)
		if definition.has_base_stat_spread():
			characterized += 1
	_expect(
		characterized >= 6,
		"La maggioranza del roster deve dichiarare uno scarto proprio."
	)


func _validate_runtime_composition() -> void:
	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	root.add_child(movement_slice)
	await process_frame

	var controller := movement_slice.get_run_controller() as RunController
	var registry := movement_slice.get_friend_registry() as FriendRegistry
	var player := movement_slice.get_player() as Player
	var passive := movement_slice.get_friend_passive_controller() as FriendPassiveController
	var weapon := movement_slice.get_weapon_controller() as WeaponController
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	if (
		controller == null
		or registry == null
		or player == null
		or passive == null
		or weapon == null
	):
		_expect(false, "La scena di run deve esporre le dipendenze B47.")
		movement_slice.queue_free()
		await process_frame
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
	_expect_float_near(
		player.get_character_move_speed_multiplier(),
		1.0 * magno.get_base_move_speed_multiplier(),
		"Magno deve comporre passiva e scarto base sul movimento."
	)
	_expect_float_near(
		weapon.get_character_fire_rate_multiplier(),
		magno.get_base_fire_rate_multiplier(),
		"Senza passiva sulla cadenza resta il solo scarto base."
	)
	_expect_float_near(
		player.get_health_component().health_max,
		baseline_health * magno.get_base_health_multiplier(),
		"Lo scarto di salute deve applicarsi al massimo effettivo."
	)
	_expect_float_near(
		player.get_base_move_speed(),
		baseline_move * 1.0 * magno.get_base_move_speed_multiplier(),
		"La velocita' base effettiva deve riflettere la composizione."
	)

	# Alea e' il profilo neutro: cambiando personaggio gli scarti si azzerano
	# e restano soltanto i contributi della passiva.
	var alea := registry.resolve_definition(&"alea")
	_equip(player, passive, alea)
	_expect_float_near(
		player.get_health_component().health_max,
		baseline_health * alea.get_base_health_multiplier(),
		"Il cambio profilo deve ricalcolare la salute sul nuovo scarto."
	)
	_expect_float_near(
		weapon.get_character_fire_rate_multiplier(),
		alea.get_base_fire_rate_multiplier(),
		"Il cambio profilo non deve conservare la cadenza del profilo precedente."
	)

	# I dati base condivisi non vengono mutati: rimuovere il profilo riporta
	# esattamente alla baseline di scena.
	passive._definition = null
	player.reset_character_stat_multipliers()
	weapon.reset_character_stat_multipliers()
	_expect_float_near(
		player.get_health_component().health_max,
		baseline_health,
		"Il reset deve riportare la salute alla baseline condivisa."
	)
	_expect_float_near(
		player.get_base_move_speed(),
		baseline_move,
		"Il reset deve riportare la velocita' alla baseline condivisa."
	)

	controller.prepare_restart()
	paused = false
	movement_slice.queue_free()
	await process_frame


func _equip(
	player: Player,
	passive: FriendPassiveController,
	definition: FriendDefinition
) -> void:
	_expect(definition != null, "Definizione mancante durante l'equipaggiamento.")
	if definition == null:
		return
	player.set_friend_definition(definition)
	_expect(
		passive.equip_definition(definition),
		"La passiva deve accettare %s." % definition.id
	)


func _expect_float_near(actual: float, expected: float, message: String) -> void:
	_expect(
		absf(actual - expected) <= FLOAT_TOLERANCE,
		"%s Atteso %s, ottenuto %s." % [message, expected, actual]
	)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	paused = false
	await process_frame
	if _failures.is_empty():
		print("B47_BASE_STATS_SMOKE_OK")
		quit(0)
		return
	for failure in _failures:
		printerr(failure)
	printerr("B47_BASE_STATS_SMOKE_FAIL count=%d" % _failures.size())
	quit(1)
