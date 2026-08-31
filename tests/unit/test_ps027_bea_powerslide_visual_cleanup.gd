extends GutGameplayTest

## PS-027 — Rimuove il residuo visivo della Powerslide di Bea: due
## `draw_polyline()` a bordo dritto disegnate sotto la texture di fiamma
## (l'implementazione precedente all'introduzione dell'asset pixel-art),
## che restavano visibili come un bordo rettangolare quando il nastro
## ondulato della fiamma si assottigliava. La rimozione e' solo visiva:
## questo test copre il regresso comportamentale dichiarato dalla card
## (direzione, distanza, danno, tick, cleanup) — l'assenza effettiva del
## bordo va confermata a schermo (gate percettivo, non automatizzabile
## in un test headless senza cattura del rendering).

const FIRE_Z_TRAIL_SCRIPT_PATH := "res://scripts/abilities/fire_z_trail.gd"


func test_draw_no_longer_uses_the_legacy_straight_edged_polyline() -> void:
	var source := FileAccess.get_file_as_string(FIRE_Z_TRAIL_SCRIPT_PATH)
	assert_true(not source.is_empty(), "Deve essere possibile leggere lo script della Powerslide.")
	assert_true(
		not source.contains("draw_polyline"),
		"PS-027: il bordo dritto disegnato sotto la texture di fiamma non deve piu' esistere nello script."
	)


func test_trail_direction_distance_damage_and_cleanup_are_unaffected() -> void:
	var context := await _build_context()
	if context.is_empty():
		return
	var controller: RunController = context["controller"]
	var registry: FriendRegistry = context["registry"]
	var player: Player = context["player"]
	var movement_slice: Control = context["slice"]
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
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
	assert_true(ability.equip_definition(powerslide), "Il controller deve equipaggiare la Powerslide.")

	var enemy := spawner.try_spawn_enemy()
	assert_true(enemy != null, "Serve un bersaglio fixture per la scia.")
	if enemy == null:
		return
	enemy.set_physics_process(false)

	player.set_movement_input(Vector2.RIGHT)
	var origin := player.global_position
	enemy.global_position = origin + Vector2(160.0, 0.0)
	var enemy_health := enemy.get_health_component()
	enemy_health.set_health_max(500.0)
	enemy_health.reset_to_max()

	assert_true(ability.try_activate(), "La Powerslide deve essere eseguibile.")

	var active_effects := effects.get_active_effects()
	var trail: FireZTrail = null
	for effect in active_effects:
		if effect is FireZTrail:
			trail = effect
	assert_true(trail != null, "L'attivazione deve creare un nodo FireZTrail.")
	if trail == null:
		return

	var points := trail.get_path_points()
	assert_eq(points.size(), 2, "La scia deve avere esattamente origine e destinazione.")
	assert_almost_eq(
		points[0].distance_to(points[1]), powerslide.get_effect_float(&"dash_distance", 0.0, 0.0),
		1.0, "La distanza dello scatto non deve cambiare."
	)
	assert_true(
		(points[1] - points[0]).normalized().dot(Vector2.RIGHT) > 0.99,
		"La direzione dello scatto deve seguire l'ultimo movimento del Player."
	)
	assert_true(
		enemy_health.health_current < 500.0,
		"Il primo tick di danno all'attivazione deve restare invariato."
	)

	trail._trail_duration_remaining = 0.0
	trail._process(0.001)
	await wait_process_frames(1)
	assert_true(not is_instance_valid(trail) or trail.is_queued_for_deletion(), "La scia deve ripulirsi da sola a fine durata.")

	controller.prepare_restart()


func _build_context() -> Dictionary:
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_run_controller() as RunController
	var registry := movement_slice.get_friend_registry() as FriendRegistry
	var player := movement_slice.get_player() as Player
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	if controller == null or registry == null or player == null or spawner == null:
		assert_true(false, "La scena di run deve esporre le dipendenze PS-027.")
		return {}

	controller.set_process(false)
	spawner.set_process(false)
	player.set_physics_process(false)
	controller.start_run(2027)
	return {
		"slice": movement_slice,
		"controller": controller,
		"registry": registry,
		"player": player,
		"spawner": spawner,
	}
