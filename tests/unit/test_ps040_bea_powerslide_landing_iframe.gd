extends GutGameplayTest

## PS-040 — La Powerslide di Bea concede un breve i-frame subito dopo il
## teletrasporto istantaneo dello scatto, per proteggere l'atterraggio (il
## momento piu' rischioso). Il valore vive in `effect_parameters.iframe_duration`
## di `data/abilities/bea_fire_z_trail.tres`; zero o assente disabilita senza
## errori, e non si somma ad altre fonti di invulnerabilita' gia' attive.


func test_activation_grants_invulnerability_matching_the_declared_duration() -> void:
	var context := await _build_context()
	if context.is_empty():
		return
	var registry: FriendRegistry = context["registry"]
	var player: Player = context["player"]
	var movement_slice: Control = context["slice"]
	var effects := movement_slice.get_ability_effect_registry() as AbilityEffectRegistry
	var ability := movement_slice.get_ability_controller() as AbilityController

	var bea := registry.resolve_definition(&"bea")
	assert_true(bea != null, "Il profilo Bea deve esistere.")
	if bea == null:
		return
	player.set_friend_definition(bea)

	var powerslide := effects.resolve_definition(bea.active_ability_id)
	assert_true(powerslide != null, "La Powerslide deve essere risolvibile.")
	if powerslide == null:
		return
	var iframe_duration := powerslide.get_effect_float(&"iframe_duration", 0.0, 0.0)
	assert_true(
		iframe_duration > 0.0,
		"PS-040: il rank equipaggiato deve dichiarare un iframe_duration positivo."
	)
	assert_true(ability.equip_definition(powerslide), "Il controller deve equipaggiare la Powerslide.")

	var health := player.get_health_component()
	assert_false(
		health.is_invulnerable(), "Il Player non deve essere invulnerabile prima dell'attivazione."
	)
	player.set_movement_input(Vector2.RIGHT)

	assert_true(ability.try_activate(), "La Powerslide deve essere eseguibile.")
	assert_true(
		health.is_invulnerable(), "L'atterraggio dello scatto deve concedere invulnerabilita' immediata."
	)
	assert_almost_eq(
		health.invulnerability_remaining, iframe_duration, FLOAT_TOLERANCE,
		"La finestra concessa deve corrispondere al dato dichiarato dal rank."
	)


func test_landing_invulnerability_does_not_stack_with_an_active_window() -> void:
	var context := await _build_context()
	if context.is_empty():
		return
	var registry: FriendRegistry = context["registry"]
	var player: Player = context["player"]
	var movement_slice: Control = context["slice"]
	var effects := movement_slice.get_ability_effect_registry() as AbilityEffectRegistry
	var ability := movement_slice.get_ability_controller() as AbilityController

	var bea := registry.resolve_definition(&"bea")
	if bea == null:
		return
	player.set_friend_definition(bea)
	var powerslide := effects.resolve_definition(bea.active_ability_id)
	if powerslide == null:
		return
	assert_true(ability.equip_definition(powerslide), "Il controller deve equipaggiare la Powerslide.")

	var health := player.get_health_component()
	# Una finestra gia' piu' lunga di quella dell'atterraggio non deve essere
	# accorciata dall'attivazione: grant_invulnerability prende il massimo.
	var longer_window := powerslide.get_effect_float(&"iframe_duration", 0.0, 0.0) + 10.0
	health.grant_invulnerability(longer_window)

	player.set_movement_input(Vector2.RIGHT)
	assert_true(ability.try_activate(), "La Powerslide deve essere eseguibile.")
	assert_almost_eq(
		health.invulnerability_remaining, longer_window, FLOAT_TOLERANCE,
		"L'atterraggio non deve accorciare una finestra di invulnerabilita' gia' piu' lunga."
	)


func test_activation_still_deals_damage_on_the_first_tick() -> void:
	var context := await _build_context()
	if context.is_empty():
		return
	var registry: FriendRegistry = context["registry"]
	var player: Player = context["player"]
	var movement_slice: Control = context["slice"]
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	var effects := movement_slice.get_ability_effect_registry() as AbilityEffectRegistry
	var ability := movement_slice.get_ability_controller() as AbilityController

	var bea := registry.resolve_definition(&"bea")
	if bea == null:
		return
	player.set_friend_definition(bea)
	var powerslide := effects.resolve_definition(bea.active_ability_id)
	if powerslide == null:
		return
	assert_true(ability.equip_definition(powerslide), "Il controller deve equipaggiare la Powerslide.")

	var enemy := spawner.try_spawn_enemy()
	assert_true(enemy != null, "Serve un bersaglio fixture per la scia.")
	if enemy == null:
		return
	enemy.set_physics_process(false)

	player.set_movement_input(Vector2.RIGHT)
	enemy.global_position = player.global_position + Vector2(160.0, 0.0)
	var enemy_health := enemy.get_health_component()
	enemy_health.set_health_max(500.0)
	enemy_health.reset_to_max()

	assert_true(ability.try_activate(), "La Powerslide deve essere eseguibile.")
	assert_true(
		enemy_health.health_current < 500.0,
		"PS-040 non deve disattivare il primo tick di danno della scia."
	)


func _build_context() -> Dictionary:
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_run_controller() as RunController
	var registry := movement_slice.get_friend_registry() as FriendRegistry
	var player := movement_slice.get_player() as Player
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	if controller == null or registry == null or player == null or spawner == null:
		assert_true(false, "La scena di run deve esporre le dipendenze PS-040.")
		return {}

	controller.set_process(false)
	spawner.set_process(false)
	player.set_physics_process(false)
	controller.start_run(2040)
	return {
		"slice": movement_slice,
		"controller": controller,
		"registry": registry,
		"player": player,
		"spawner": spawner,
	}
