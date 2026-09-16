extends GutTest

## PS-158 — Una build offensiva matura (piercing/rimbalzo/esplosione/danno/
## fire rate) puo' uccidere il Tiratore appena dopo che ha sparato. Un
## proiettile gia' in volo e' pero' indipendente dalla propria fonte:
## cancellarlo insieme a lei azzererebbe l'unica pressione anti-AFK della
## curva ordinaria che non dipende dal solo output di danno del Player (vedi
## Decisioni di PS-158). Solo un vero restart pulisce anche i proiettili
## ancora in volo del tiratore rimosso.

const PLAYER_SCENE: PackedScene = preload("res://scenes/actors/player.tscn")
const RANGED_ENEMY_SCENE: PackedScene = preload("res://scenes/actors/ranged_enemy.tscn")


func test_killing_the_shooter_after_it_fires_does_not_cancel_the_projectile() -> void:
	var built := await _build_fixture()
	var controller: RunController = built["controller"]
	var enemy: RangedEnemy = built["enemy"]
	var definition: EnemyArchetypeDefinition = built["definition"]
	var projectile_parent: Node2D = built["projectile_parent"]

	enemy._advance_attack_cycle(definition.ranged_attack_interval)
	var projectile := _find_projectile(projectile_parent)
	assert_not_null(projectile, "Il tiratore deve sparare subito col bersaglio a tiro, senza telegraph.")
	if projectile == null:
		return

	var start_position := projectile.global_position
	enemy.get_health_component().take_damage(definition.health_max)
	assert_true(not enemy.is_alive(), "Un burst letale deve poter uccidere il tiratore.")
	enemy.queue_free()
	await wait_physics_frames(2)

	assert_true(controller.is_running(), "La morte del tiratore non deve terminare la run.")
	assert_false(is_instance_valid(enemy), "Il tiratore deve essere davvero uscito dall'albero.")
	assert_true(
		is_instance_valid(projectile) and not projectile.is_queued_for_deletion(),
		"Il proiettile gia' sparato non deve sparire con la fonte uccisa mentre la run e' ancora in corso."
	)
	if is_instance_valid(projectile):
		assert_true(projectile.global_position.x > start_position.x, "Il colpo deve continuare a volare senza la fonte.")

	print("PS158_MATURE_BUILD_ANTI_AFK_SMOKE_OK")
	controller.prepare_restart()


func test_restart_still_clears_the_shooters_in_flight_projectile() -> void:
	var built := await _build_fixture()
	var controller: RunController = built["controller"]
	var enemy: RangedEnemy = built["enemy"]
	var definition: EnemyArchetypeDefinition = built["definition"]
	var projectile_parent: Node2D = built["projectile_parent"]

	enemy._advance_attack_cycle(definition.ranged_attack_interval)
	var projectile := _find_projectile(projectile_parent)
	assert_not_null(projectile, "Il tiratore deve sparare subito col bersaglio a tiro.")
	if projectile == null:
		return

	controller.prepare_restart()
	enemy.queue_free()
	await wait_process_frames(1)

	assert_true(
		not is_instance_valid(projectile) or projectile.is_queued_for_deletion(),
		"Un vero restart deve pulire anche i proiettili ancora in volo del tiratore rimosso."
	)


func _build_fixture() -> Dictionary:
	var fixture := Node2D.new()
	var controller := RunController.new()
	controller.set_process(false)
	var target := PLAYER_SCENE.instantiate() as Player
	# PS-177: registra subito il corpo nella posizione finale. Spostarlo dopo
	# il primo frame lasciava una collisione pendente all'origine, consegnata
	# al proiettile appena sparato nella successiva sincronizzazione fisica.
	target.position = Vector2(200.0, 0.0)
	target.set_physics_process(false)
	var projectile_parent := Node2D.new()
	var enemy := RANGED_ENEMY_SCENE.instantiate() as RangedEnemy
	enemy.set_physics_process(false)
	fixture.add_child(controller)
	fixture.add_child(target)
	fixture.add_child(projectile_parent)
	fixture.add_child(enemy)
	add_child_autofree(fixture)

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
	definition.ranged_attack_interval = 1.0
	definition.ranged_projectile_damage = 8.0
	definition.ranged_projectile_speed = 200.0
	definition.ranged_projectile_lifetime = 4.0
	definition.ranged_projectile_radius = 8.0

	assert_true(controller.start_run(15800), "La fixture deve avviare una run valida.")
	target.set_run_controller(controller)
	enemy.apply_archetype_definition(definition)
	enemy.configure_ranged(definition, projectile_parent)
	enemy.set_target(target)
	enemy.set_run_controller(controller)
	enemy.global_position = Vector2.ZERO
	await wait_physics_frames(1)

	return {
		"fixture": fixture,
		"controller": controller,
		"enemy": enemy,
		"definition": definition,
		"projectile_parent": projectile_parent,
		"target": target,
	}


func _find_projectile(projectile_parent: Node2D) -> BossProjectile:
	for child in projectile_parent.get_children():
		if child is BossProjectile:
			return child
	return null
