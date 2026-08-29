extends GutGameplayTest

const HEALTH_PICKUP_SCENE: PackedScene = preload("res://scenes/pickups/health_pickup.tscn")
const ENEMY_SCENE: PackedScene = preload("res://scenes/actors/base_enemy.tscn")
const PLAYER_SCENE: PackedScene = preload("res://scenes/actors/player.tscn")


func test_pickup_collection_and_heal_cap() -> void:
	var fixture := Node2D.new()
	var controller := RunController.new()
	controller.set_process(false)
	var player := PLAYER_SCENE.instantiate() as Player
	var pickup := HEALTH_PICKUP_SCENE.instantiate() as HealthPickup
	fixture.add_child(controller)
	fixture.add_child(player)
	fixture.add_child(pickup)
	add_child_autofree(fixture)
	await wait_process_frames(1)
	player.set_physics_process(false)
	pickup.set_physics_process(false)

	controller.start_run(4242)
	var health := player.get_health_component()
	health.take_damage(40.0)
	var health_before_pickup := health.health_current

	pickup.configure(controller, player, 15.0)
	pickup.global_position = player.global_position
	# Le lambda GDScript catturano le var locali per valore: un Array come
	# contenitore mutabile e' il modo affidabile di osservare l'emissione.
	var collected_amount := [-1.0]
	pickup.collected.connect(
		func(_p: HealthPickup, amount: float) -> void: collected_amount[0] = amount
	)
	assert_true(pickup.try_collect(), "Il pickup a distanza zero deve essere raccoglibile.")
	assert_almost_eq(
		collected_amount[0], 15.0, FLOAT_TOLERANCE, "Il pickup deve segnalare l'HP configurato al momento della raccolta."
	)
	assert_almost_eq(
		health.health_current,
		health_before_pickup,
		FLOAT_TOLERANCE,
		"HealthPickup non deve applicare la cura da solo: e' compito del dropper."
	)

	# Cura oltre il massimo: HealthComponent.heal deve gia' fare da cap.
	var overheal := health.heal(10000.0)
	assert_almost_eq(health.health_current, health.health_max, FLOAT_TOLERANCE, "La cura non deve superare gli HP massimi.")
	assert_true(overheal > 0.0 and overheal < 10000.0, "heal() deve restituire solo la parte applicata.")

	controller.prepare_restart()


func test_dropper_wiring_respects_drop_chance() -> void:
	var fixture := Node2D.new()
	var controller := RunController.new()
	controller.set_process(false)
	var arena := ArenaLayout.new()
	arena.respect_display_safe_area = false
	var player := PLAYER_SCENE.instantiate() as Player
	var enemy_parent := Node2D.new()
	var pickup_parent := Node2D.new()
	var spawner := EnemySpawner.new()
	spawner.set_process(false)
	var spawn_profile := EnemySpawnProfile.new()
	spawn_profile.max_alive_enemies = 200
	spawner.enemy_scene = ENEMY_SCENE
	spawner.spawn_profile = spawn_profile

	var dropper := HealthPickupDropper.new()
	dropper.pickup_scene = HEALTH_PICKUP_SCENE
	dropper.drop_chance = 1.0
	dropper.heal_amount = 12.0

	fixture.add_child(controller)
	fixture.add_child(arena)
	fixture.add_child(player)
	fixture.add_child(enemy_parent)
	fixture.add_child(pickup_parent)
	fixture.add_child(spawner)
	fixture.add_child(dropper)
	add_child_autofree(fixture)
	await wait_process_frames(2)

	spawner.configure(controller, arena, player, enemy_parent)
	dropper.configure(controller, spawner, player, arena, pickup_parent)
	controller.start_run(99)
	player.global_position = arena.get_playfield_center()

	var health := player.get_health_component()
	health.take_damage(50.0)
	var health_before := health.health_current

	var enemy := spawner.try_spawn_enemy()
	assert_not_null(enemy, "La fixture deve produrre un nemico da uccidere.")
	if enemy != null:
		enemy.set_physics_process(false)
		enemy.global_position = player.global_position
		var applied_amount := [-1.0]
		var reported_health := [-1.0]
		dropper.pickup_collected.connect(
			func(_pickup: HealthPickup, amount: float, current: float) -> void:
				applied_amount[0] = amount
				reported_health[0] = current
		)
		assert_true(
			enemy.take_damage(enemy.get_health_component().health_current), "La kill con drop_chance=1.0 deve essere letale."
		)
		assert_eq(dropper.get_active_count(), 1, "drop_chance=1.0 deve generare un pickup ad ogni morte.")
		var pickup := dropper.get_active_pickups()[0]
		pickup.set_physics_process(false)
		assert_true(pickup.try_collect(), "Il pickup generato dal dropper deve essere raccoglibile a distanza zero.")
		assert_almost_eq(applied_amount[0], 12.0, FLOAT_TOLERANCE, "Il dropper deve applicare l'heal_amount configurato.")
		assert_almost_eq(
			health.health_current,
			health_before + 12.0,
			FLOAT_TOLERANCE,
			"La HealthComponent del Player deve ricevere la cura effettiva."
		)
		assert_almost_eq(
			reported_health[0], health.health_current, FLOAT_TOLERANCE, "Il segnale deve riportare l'HP corrente aggiornato."
		)

	# drop_chance a zero non deve mai generare pickup.
	dropper.clear_active_pickups()
	dropper.drop_chance = 0.0
	var second_enemy := spawner.try_spawn_enemy()
	if second_enemy != null:
		second_enemy.set_physics_process(false)
		second_enemy.take_damage(second_enemy.get_health_component().health_current)
		assert_eq(dropper.get_active_count(), 0, "drop_chance=0.0 non deve mai generare un pickup.")

	controller.prepare_restart()


func test_composed_scene_wires_health_pickup_dropper() -> void:
	var movement_slice := await instantiate_movement_slice()

	var dropper := movement_slice.get_health_pickup_dropper() as HealthPickupDropper
	assert_not_null(dropper, "La scena composta deve contenere HealthPickupDropper.")
	if dropper == null:
		return

	assert_true(
		dropper.pickup_scene != null
		and dropper.get_run_controller() != null
		and dropper.get_enemy_spawner() != null
		and dropper.get_player() != null
		and dropper.get_arena_layout() != null
		and dropper.get_pickup_parent() != null,
		"HealthPickupDropper deve essere collegato ai nodi della scena composta."
	)
	assert_true(
		dropper.drop_chance > 0.0 and dropper.drop_chance < 0.2,
		"Il drop rate deve restare basso per non annullare la pressione delle orde."
	)
