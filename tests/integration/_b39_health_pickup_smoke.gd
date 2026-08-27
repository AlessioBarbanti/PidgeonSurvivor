extends SceneTree

const MOVEMENT_SLICE_SCENE: PackedScene = preload("res://scenes/game/movement_slice.tscn")
const HEALTH_PICKUP_SCENE: PackedScene = preload("res://scenes/pickups/health_pickup.tscn")
const ENEMY_SCENE: PackedScene = preload("res://scenes/actors/base_enemy.tscn")
const FLOAT_TOLERANCE := 0.001
const INITIAL_VIEWPORT_SIZE := Vector2i(1280, 720)

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	paused = false
	await _validate_pickup_collection_and_heal_cap()
	await _validate_dropper_wiring()
	await _validate_composed_scene()
	await _finish()


func _validate_pickup_collection_and_heal_cap() -> void:
	var fixture := Node2D.new()
	var controller := RunController.new()
	controller.set_process(false)
	var player := (preload("res://scenes/actors/player.tscn") as PackedScene).instantiate() as Player
	var pickup := HEALTH_PICKUP_SCENE.instantiate() as HealthPickup
	fixture.add_child(controller)
	fixture.add_child(player)
	fixture.add_child(pickup)
	root.add_child(fixture)
	await process_frame
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
	_expect(pickup.try_collect(), "Il pickup a distanza zero deve essere raccoglibile.")
	_expect_float_near(
		collected_amount[0], 15.0, "Il pickup deve segnalare l'HP configurato al momento della raccolta."
	)
	_expect_float_near(
		health.health_current,
		health_before_pickup,
		"HealthPickup non deve applicare la cura da solo: e' compito del dropper."
	)

	# Cura oltre il massimo: HealthComponent.heal deve gia' fare da cap.
	var overheal := health.heal(10000.0)
	_expect_float_near(
		health.health_current, health.health_max, "La cura non deve superare gli HP massimi."
	)
	_expect(overheal > 0.0 and overheal < 10000.0, "heal() deve restituire solo la parte applicata.")

	controller.prepare_restart()
	paused = false
	fixture.queue_free()
	await process_frame


func _validate_dropper_wiring() -> void:
	var fixture := Node2D.new()
	var controller := RunController.new()
	controller.set_process(false)
	var arena := ArenaLayout.new()
	arena.respect_display_safe_area = false
	var player := (preload("res://scenes/actors/player.tscn") as PackedScene).instantiate() as Player
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
	root.add_child(fixture)
	await process_frame
	await process_frame

	spawner.configure(controller, arena, player, enemy_parent)
	dropper.configure(controller, spawner, player, arena, pickup_parent)
	controller.start_run(99)
	player.global_position = arena.get_playfield_center()

	var health := player.get_health_component()
	health.take_damage(50.0)
	var health_before := health.health_current

	var enemy := spawner.try_spawn_enemy()
	_expect(enemy != null, "La fixture deve produrre un nemico da uccidere.")
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
		_expect(
			enemy.take_damage(enemy.get_health_component().health_current),
			"La kill con drop_chance=1.0 deve essere letale."
		)
		_expect(dropper.get_active_count() == 1, "drop_chance=1.0 deve generare un pickup ad ogni morte.")
		var pickup := dropper.get_active_pickups()[0]
		pickup.set_physics_process(false)
		_expect(
			pickup.try_collect(),
			"Il pickup generato dal dropper deve essere raccoglibile a distanza zero."
		)
		_expect_float_near(applied_amount[0], 12.0, "Il dropper deve applicare l'heal_amount configurato.")
		_expect_float_near(
			health.health_current,
			health_before + 12.0,
			"La HealthComponent del Player deve ricevere la cura effettiva."
		)
		_expect_float_near(
			reported_health[0], health.health_current, "Il segnale deve riportare l'HP corrente aggiornato."
		)

	# drop_chance a zero non deve mai generare pickup.
	dropper.clear_active_pickups()
	dropper.drop_chance = 0.0
	var second_enemy := spawner.try_spawn_enemy()
	if second_enemy != null:
		second_enemy.set_physics_process(false)
		second_enemy.take_damage(second_enemy.get_health_component().health_current)
		_expect(
			dropper.get_active_count() == 0,
			"drop_chance=0.0 non deve mai generare un pickup."
		)

	controller.prepare_restart()
	paused = false
	fixture.queue_free()
	await process_frame


func _validate_composed_scene() -> void:
	root.content_scale_size = INITIAL_VIEWPORT_SIZE
	root.size = INITIAL_VIEWPORT_SIZE
	await process_frame
	await process_frame
	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	root.add_child(movement_slice)
	await process_frame
	await process_frame

	var dropper := movement_slice.get_health_pickup_dropper() as HealthPickupDropper
	_expect(dropper != null, "La scena composta deve contenere HealthPickupDropper.")
	if dropper == null:
		paused = false
		movement_slice.queue_free()
		await process_frame
		return

	_expect(
		dropper.pickup_scene != null
		and dropper.get_run_controller() != null
		and dropper.get_enemy_spawner() != null
		and dropper.get_player() != null
		and dropper.get_arena_layout() != null
		and dropper.get_pickup_parent() != null,
		"HealthPickupDropper deve essere collegato ai nodi della scena composta."
	)
	_expect(
		dropper.drop_chance > 0.0 and dropper.drop_chance < 0.2,
		"Il drop rate deve restare basso per non annullare la pressione delle orde."
	)

	paused = false
	movement_slice.queue_free()
	await process_frame
	root.content_scale_size = INITIAL_VIEWPORT_SIZE
	root.size = INITIAL_VIEWPORT_SIZE
	await process_frame


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
		print("B39_HEALTH_PICKUP_SMOKE_OK")
		quit(0)
		return
	for failure in _failures:
		printerr(failure)
	printerr("B39_HEALTH_PICKUP_SMOKE_FAIL count=%d" % _failures.size())
	quit(1)
