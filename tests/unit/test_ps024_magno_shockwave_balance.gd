extends GutGameplayTest

## PS-024 — L'Onda d'Urto Tellurica deve restare uno strumento di controllo:
## il knockback e' l'effetto dominante, il danno resta secondario. Verifica
## che al rank 1, anche a slancio pieno (il caso peggiore per il bonus
## danno), un nemico comune standard a vita piena (18 HP, il piccione base
## dichiarato in scenes/actors/base_enemy.tscn) sopravviva a una singola
## attivazione, e che il knockback resti comunque applicato.

const COMMON_ENEMY_HEALTH := 18.0


func test_rank_one_damage_stays_below_common_enemy_health() -> void:
	var context := await _build_context()
	if context.is_empty():
		return
	var registry: FriendRegistry = context["registry"]
	var player: Player = context["player"]
	var movement_slice: Control = context["slice"]
	var effects := movement_slice.get_ability_effect_registry() as AbilityEffectRegistry

	var magno := registry.resolve_definition(&"magno")
	assert_true(magno != null, "Il profilo Magno deve esistere.")
	if magno == null:
		return
	player.set_friend_definition(magno)

	var earthquake := effects.resolve_definition(magno.active_ability_id)
	assert_true(earthquake != null, "L'Onda d'Urto Tellurica deve essere risolvibile.")
	if earthquake == null:
		return
	assert_true(
		earthquake.damage < COMMON_ENEMY_HEALTH,
		"Al rank 1 il danno dichiarato (%.1f) deve restare sotto la vita di un nemico comune standard (%.1f HP)."
			% [earthquake.damage, COMMON_ENEMY_HEALTH]
	)
	var damage_bonus_max: float = earthquake.effect_parameters.get("momentum_damage_bonus_max", 0.0)
	var max_momentum_damage := earthquake.damage * (1.0 + damage_bonus_max)
	assert_true(
		max_momentum_damage < COMMON_ENEMY_HEALTH,
		(
			"Il danno bonus dello slancio pieno (%.1f) non deve rendere il danno il beneficio "
			+ "principale: deve restare sotto la vita di un nemico comune standard (%.1f HP)."
		) % [max_momentum_damage, COMMON_ENEMY_HEALTH]
	)


func test_full_momentum_activation_does_not_kill_common_enemy_but_still_knocks_back() -> void:
	var context := await _build_context()
	if context.is_empty():
		return
	var controller: RunController = context["controller"]
	var registry: FriendRegistry = context["registry"]
	var player: Player = context["player"]
	var passive: FriendPassiveController = context["passive"]
	var movement_slice: Control = context["slice"]
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	var effects := movement_slice.get_ability_effect_registry() as AbilityEffectRegistry
	var ability := movement_slice.get_ability_controller() as AbilityController

	var magno := registry.resolve_definition(&"magno")
	assert_true(magno != null, "Il profilo Magno deve esistere.")
	if magno == null:
		return
	player.set_friend_definition(magno)
	assert_true(passive.equip_definition(magno), "La passiva deve accettare Magno.")

	var earthquake := effects.resolve_definition(magno.active_ability_id)
	assert_true(earthquake != null, "L'Onda d'Urto Tellurica deve essere risolvibile.")
	if earthquake == null:
		return
	assert_true(ability.equip_definition(earthquake), "Il controller deve equipaggiare l'Onda d'Urto Tellurica.")

	# Slancio pieno: il caso peggiore per il bonus danno.
	player.set_movement_input(Vector2.RIGHT)
	for _tick_index in 20:
		player._advance_momentum(0.1)
	assert_true(player.get_momentum_ratio() > 0.9, "Il test deve partire da slancio quasi saturo.")

	var enemy := spawner.try_spawn_enemy()
	assert_true(enemy != null, "Serve un bersaglio fixture per l'Onda d'Urto Tellurica.")
	if enemy == null:
		return
	enemy.set_physics_process(false)
	enemy.global_position = player.global_position + Vector2(60.0, 0.0)
	var enemy_health := enemy.get_health_component()
	enemy_health.set_health_max(COMMON_ENEMY_HEALTH)
	enemy_health.reset_to_max()

	assert_true(ability.try_activate(), "L'Onda d'Urto Tellurica deve essere eseguibile a slancio pieno.")
	assert_true(
		enemy_health.health_current > 0.0,
		"Un nemico comune standard a vita piena non deve essere eliminato da una singola Onda d'Urto Tellurica al rank 1, nemmeno a slancio pieno."
	)
	assert_true(
		enemy.get_knockback_remaining() > 0.0 and enemy.get_knockback_velocity().length() > 0.0,
		"Il knockback deve restare l'effetto chiaramente percepibile e dominante dell'attivazione."
	)

	controller.prepare_restart()


func _build_context() -> Dictionary:
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_run_controller() as RunController
	var registry := movement_slice.get_friend_registry() as FriendRegistry
	var player := movement_slice.get_player() as Player
	var passive := movement_slice.get_friend_passive_controller() as FriendPassiveController
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	if controller == null or registry == null or player == null or passive == null or spawner == null:
		assert_true(false, "La scena di run deve esporre le dipendenze PS-024.")
		return {}

	controller.set_process(false)
	spawner.set_process(false)
	player.set_physics_process(false)
	passive.set_process(false)
	controller.start_run(2024)
	return {
		"slice": movement_slice,
		"controller": controller,
		"registry": registry,
		"player": player,
		"passive": passive,
		"spawner": spawner,
	}
