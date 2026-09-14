extends GutTest

## PS-158 — Una build offensiva matura (piercing/rimbalzo/esplosione/danno/
## fire rate) puo' uccidere il Tiratore prima che il proprio telegraph finisca.
## Senza PendingRangedShot il colpo annunciato spariva con lui, azzerando
## l'unica pressione anti-AFK che non dipende dal solo output di danno del
## Player (vedi Decisioni di PS-158). Questo test dimostra che il colpo resta
## leggibile, schivabile e in arrivo anche se la fonte muore durante l'attesa.

const PLAYER_SCENE: PackedScene = preload("res://scenes/actors/player.tscn")
const RANGED_ENEMY_SCENE: PackedScene = preload("res://scenes/actors/ranged_enemy.tscn")
const FLOAT_TOLERANCE := 0.001


func test_killing_the_shooter_mid_telegraph_does_not_cancel_the_committed_shot() -> void:
	var built := await _build_fixture()
	var controller: RunController = built["controller"]
	var enemy: RangedEnemy = built["enemy"]
	var definition: EnemyArchetypeDefinition = built["definition"]
	var projectile_parent: Node2D = built["projectile_parent"]

	enemy._advance_attack_cycle(definition.ranged_attack_interval)
	assert_true(enemy.is_telegraph_active(), "Il tiratore deve avviare il telegraph col bersaglio a tiro.")
	enemy._advance_attack_cycle(definition.ranged_telegraph_duration * 0.5)

	enemy.get_health_component().take_damage(definition.health_max)
	assert_true(not enemy.is_alive(), "Un burst letale deve poter uccidere il tiratore durante il telegraph.")

	var pending := _find_pending_shot(projectile_parent)
	assert_not_null(
		pending,
		"La morte durante il telegraph deve affidare il colpo gia' annunciato a PendingRangedShot."
	)
	if pending == null:
		return
	assert_almost_eq(
		pending.get_remaining(),
		definition.ranged_telegraph_duration * 0.5,
		FLOAT_TOLERANCE,
		"Il tempo residuo del telegraph deve trasferirsi intatto al colpo pendente."
	)

	pending._physics_process(definition.ranged_telegraph_duration * 0.5 + 0.001)
	assert_not_null(
		_find_projectile(projectile_parent),
		"Il colpo pendente deve sparare un proiettile reale allo scadere del telegraph, anche a tiratore morto."
	)

	print("PS158_MATURE_BUILD_ANTI_AFK_SMOKE_OK")
	controller.prepare_restart()


func test_killing_the_shooter_outside_of_telegraph_spawns_no_pending_shot() -> void:
	var built := await _build_fixture()
	var controller: RunController = built["controller"]
	var enemy: RangedEnemy = built["enemy"]
	var definition: EnemyArchetypeDefinition = built["definition"]
	var projectile_parent: Node2D = built["projectile_parent"]

	assert_true(not enemy.is_telegraph_active(), "Il tiratore non deve partire gia' in telegraph.")
	enemy.get_health_component().take_damage(definition.health_max)
	assert_true(not enemy.is_alive(), "Il danno letale deve uccidere il tiratore.")

	assert_null(
		_find_pending_shot(projectile_parent),
		"Un kill ordinario fuori dal telegraph non deve generare un colpo fantasma."
	)
	controller.prepare_restart()


func test_pending_shot_does_not_fire_if_the_player_leaves_range_before_it_resolves() -> void:
	var built := await _build_fixture()
	var controller: RunController = built["controller"]
	var enemy: RangedEnemy = built["enemy"]
	var definition: EnemyArchetypeDefinition = built["definition"]
	var projectile_parent: Node2D = built["projectile_parent"]
	var target: Player = built["target"]

	enemy._advance_attack_cycle(definition.ranged_attack_interval)
	assert_true(enemy.is_telegraph_active(), "Il tiratore deve avviare il telegraph col bersaglio a tiro.")
	enemy.get_health_component().take_damage(definition.health_max)
	var pending := _find_pending_shot(projectile_parent)
	assert_not_null(pending, "La morte durante il telegraph deve creare il colpo pendente.")
	if pending == null:
		return

	target.global_position = Vector2(definition.ranged_attack_range * 10.0, 0.0)
	pending._physics_process(definition.ranged_telegraph_duration + 0.001)
	assert_null(
		_find_projectile(projectile_parent),
		"Se il bersaglio esce dal raggio prima che il colpo pendente risolva, il colpo non deve partire."
	)
	controller.prepare_restart()


func _build_fixture() -> Dictionary:
	var fixture := Node2D.new()
	var controller := RunController.new()
	controller.set_process(false)
	var target := PLAYER_SCENE.instantiate() as Player
	var projectile_parent := Node2D.new()
	var enemy := RANGED_ENEMY_SCENE.instantiate() as RangedEnemy
	fixture.add_child(controller)
	fixture.add_child(target)
	fixture.add_child(projectile_parent)
	fixture.add_child(enemy)
	add_child_autofree(fixture)
	await wait_process_frames(1)
	enemy.set_physics_process(false)

	var definition := EnemyArchetypeDefinition.new()
	definition.id = &"ps158_ranged_test"
	definition.scene = RANGED_ENEMY_SCENE
	definition.health_max = 9.0
	definition.move_speed = 110.0
	definition.collision_radius = 20.0
	definition.contact_damage = 7.0
	definition.experience_amount = 2
	definition.ranged_attack_range = 400.0
	definition.ranged_preferred_distance = 300.0
	definition.ranged_telegraph_duration = 0.6
	definition.ranged_attack_interval = 1.0
	definition.ranged_projectile_damage = 8.0
	definition.ranged_projectile_speed = 200.0
	definition.ranged_projectile_lifetime = 4.0
	definition.ranged_projectile_radius = 8.0

	controller.start_run(15800)
	enemy.apply_archetype_definition(definition)
	enemy.configure_ranged(definition, projectile_parent)
	enemy.set_target(target)
	enemy.set_run_controller(controller)
	enemy.global_position = Vector2.ZERO
	target.global_position = Vector2(200.0, 0.0)

	return {
		"fixture": fixture,
		"controller": controller,
		"enemy": enemy,
		"definition": definition,
		"projectile_parent": projectile_parent,
		"target": target,
	}


func _find_pending_shot(projectile_parent: Node2D) -> PendingRangedShot:
	for child in projectile_parent.get_children():
		if child is PendingRangedShot:
			return child
	return null


func _find_projectile(projectile_parent: Node2D) -> BossProjectile:
	for child in projectile_parent.get_children():
		if child is BossProjectile:
			return child
	return null
