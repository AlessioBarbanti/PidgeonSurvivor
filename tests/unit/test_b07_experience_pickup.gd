extends GutGameplayTest

const PLAYER_SCENE: PackedScene = preload("res://scenes/actors/player.tscn")
const PICKUP_SCENE: PackedScene = preload("res://scenes/pickups/experience_pickup.tscn")

var _direct_collection_count := 0
var _drop_spawn_count := 0
var _drop_collection_count := 0


func test_experience_system_gates_by_run_state() -> void:
	var controller := RunController.new()
	controller.name = "RunController"
	controller.set_process(false)
	var experience := ExperienceSystem.new()
	experience.name = "ExperienceSystem"
	controller.add_child(experience)
	add_child_autofree(controller)
	experience.set_run_controller(controller)
	await wait_process_frames(1)

	assert_eq(experience.get_run_controller(), controller, "ExperienceSystem deve usare il RunController configurato.")
	assert_false(experience.add_experience(1), "BOOT deve bloccare l'accredito XP.")
	assert_true(controller.start_run(7001), "La fixture XP deve avviare la run.")
	assert_true(experience.add_experience(3), "RUNNING deve accettare un accredito XP positivo.")
	assert_eq(experience.experience_current, 3, "L'accredito deve aggiornare il totale XP.")
	assert_false(experience.add_experience(0), "Un accredito nullo deve essere respinto.")
	assert_true(controller.request_manual_pause(), "La fixture XP deve entrare in pausa.")
	assert_true(
		not experience.add_experience(5) and experience.experience_current == 3, "La pausa deve bloccare la progressione."
	)
	assert_true(controller.resume_run(), "La fixture XP deve riprendere.")
	assert_true(experience.add_experience(2), "Il resume deve riaprire l'accredito XP.")
	assert_true(controller.request_victory(), "La fixture XP deve entrare nel terminale.")
	assert_true(
		not experience.add_experience(9) and experience.experience_current == 5, "Un terminale deve bloccare XP residui."
	)
	assert_true(controller.restart_run(7002), "Il terminale deve accettare il restart.")
	assert_eq(experience.experience_current, 0, "Il restart deve azzerare gli XP della run precedente.")

	controller.prepare_restart()


func test_pickup_magnet_and_single_credit() -> void:
	_direct_collection_count = 0
	var fixture := Node2D.new()
	fixture.name = "PickupFixture"
	var controller := RunController.new()
	controller.name = "RunController"
	controller.set_process(false)
	var experience := ExperienceSystem.new()
	experience.name = "ExperienceSystem"
	var player := PLAYER_SCENE.instantiate() as Player
	var pickup := PICKUP_SCENE.instantiate() as ExperiencePickup
	fixture.add_child(controller)
	fixture.add_child(experience)
	fixture.add_child(player)
	fixture.add_child(pickup)
	add_child_autofree(fixture)
	player.set_physics_process(false)
	player.set_run_controller(controller)
	experience.set_run_controller(controller)
	pickup.configure(controller, player, 3)
	pickup.collected.connect(_on_direct_pickup_collected.bind(experience))
	await wait_process_frames(1)

	assert_true(controller.start_run(7101), "La fixture pickup deve avviare la run.")
	player.global_position = Vector2(300.0, 240.0)
	pickup.global_position = player.global_position + Vector2(player.get_pickup_radius() + 1.0, 0.0)
	var outside_position := pickup.global_position
	pickup._physics_process(1.0)
	assert_vector_near(pickup.global_position, outside_position, "Un drop fuori da pickup_radius deve restare fermo.")
	assert_eq(experience.experience_current, 0, "Un drop fuori raggio non deve accreditare XP.")

	pickup.global_position = player.global_position + Vector2(120.0, 0.0)
	var distance_before := pickup.global_position.distance_to(player.global_position)
	pickup._physics_process(0.1)
	var distance_after := pickup.global_position.distance_to(player.global_position)
	assert_true(
		distance_after < distance_before and not pickup.is_collected(), "Entro pickup_radius il drop deve muoversi verso il Player."
	)

	var paused_position := pickup.global_position
	assert_true(controller.request_manual_pause(), "La fixture pickup deve entrare in pausa.")
	pickup._physics_process(5.0)
	assert_vector_near(pickup.global_position, paused_position, "La pausa deve fermare il magnete XP.")
	assert_false(pickup.try_collect(), "La raccolta esplicita deve essere bloccata in pausa.")
	assert_true(controller.resume_run(), "La fixture pickup deve riprendere.")
	pickup._physics_process(1.0)
	assert_true(pickup.is_collected(), "Il magnete deve completare la raccolta vicino al Player.")
	assert_eq(experience.experience_current, 3, "La raccolta deve accreditare il valore configurato.")
	assert_eq(_direct_collection_count, 1, "Il pickup deve emettere un solo evento collected.")
	assert_true(
		not pickup.try_collect() and experience.experience_current == 3 and _direct_collection_count == 1,
		"Tentativi ripetuti prima del free non devono duplicare l'accredito."
	)

	player.pickup_radius = 280.0
	player.reset_for_run()
	assert_almost_eq(
		player.get_pickup_radius(), 160.0, FLOAT_TOLERANCE, "Il reset deve ripristinare il pickup_radius base."
	)

	controller.prepare_restart()


func test_composed_drop_flow_through_death_pause_and_restart() -> void:
	_drop_spawn_count = 0
	_drop_collection_count = 0
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_node_or_null("RunController") as RunController
	var spawner := movement_slice.get_node_or_null("EnemySpawner") as EnemySpawner
	var experience := movement_slice.get_node_or_null("ExperienceSystem") as ExperienceSystem
	var dropper := movement_slice.get_node_or_null("ExperienceDropper") as ExperienceDropper
	var player := movement_slice.get_node_or_null("World/Player") as Player
	var pickup_parent := movement_slice.get_node_or_null("World/Pickups") as Node2D
	var weapon: WeaponController
	if player != null:
		weapon = player.get_weapon_controller()

	assert_not_null(controller, "La scena B07 deve contenere RunController.")
	assert_not_null(spawner, "La scena B07 deve contenere EnemySpawner.")
	assert_not_null(experience, "La scena B07 deve contenere ExperienceSystem.")
	assert_not_null(dropper, "La scena B07 deve contenere ExperienceDropper.")
	assert_not_null(player, "La scena B07 deve contenere il Player.")
	assert_not_null(pickup_parent, "La scena B07 deve contenere World/Pickups.")
	if (
		controller == null
		or spawner == null
		or experience == null
		or dropper == null
		or player == null
		or pickup_parent == null
		or weapon == null
	):
		return

	controller.set_process(false)
	spawner.set_process(false)
	weapon.set_process(false)
	player.set_physics_process(false)
	dropper.pickup_spawned.connect(_on_drop_spawned)
	dropper.pickup_collected.connect(_on_drop_collected)
	assert_true(controller.is_running(), "La scena B07 deve partire in RUNNING.")
	assert_true(
		dropper.get_run_controller() == controller
		and dropper.get_enemy_spawner() == spawner
		and dropper.get_experience_system() == experience
		and dropper.get_player() == player
		and dropper.get_pickup_parent() == pickup_parent,
		"ExperienceDropper deve ricevere tutte le dipendenze della scena."
	)

	spawner.reset_for_run(7201)
	await wait_process_frames(1)
	var enemy := spawner.try_spawn_enemy()
	assert_not_null(enemy, "La fixture B07 deve generare un nemico.")
	if enemy == null:
		controller.prepare_restart()
		return
	enemy.set_physics_process(false)
	enemy.get_contact_damage().set_physics_process(false)
	enemy.experience_amount = 5
	enemy.experience_reward_scale = 1.0
	enemy.global_position = player.global_position + Vector2(player.get_pickup_radius() + 80.0, 0.0)
	var death_position := enemy.global_position
	var enemy_health := enemy.get_health_component()
	assert_true(enemy.take_damage(enemy_health.health_current), "La hit letale deve uccidere il nemico di prova.")
	assert_true(
		dropper.get_active_count() == 1 and pickup_parent.get_child_count() == 1 and _drop_spawn_count == 1,
		"Una morte deve generare esattamente un drop."
	)
	assert_eq(experience.experience_current, 0, "La morte non deve accreditare XP prima della raccolta.")
	enemy.died.emit(enemy)
	assert_true(
		dropper.get_active_count() == 1 and _drop_spawn_count == 1,
		"Un segnale died duplicato nello stesso frame non deve duplicare il drop."
	)

	var pickup := dropper.get_active_pickups()[0]
	pickup.set_physics_process(false)
	assert_vector_near(pickup.global_position, death_position, "Il drop deve nascere nella posizione della morte.")
	pickup._physics_process(1.0)
	assert_vector_near(
		pickup.global_position, death_position, "Fuori pickup_radius il drop composto deve restare fermo."
	)
	pickup.global_position = player.global_position + Vector2(100.0, 0.0)
	pickup._physics_process(0.1)
	assert_true(
		pickup.global_position.distance_to(player.global_position) < 100.0, "Il drop composto deve entrare nel magnete."
	)
	pickup._physics_process(1.0)
	assert_true(
		experience.experience_current == 5 and _drop_collection_count == 1,
		"La raccolta composta deve accreditare una sola volta il valore del nemico."
	)
	assert_true(
		not pickup.try_collect() and experience.experience_current == 5 and _drop_collection_count == 1,
		"Il pickup composto non deve poter accreditare due volte."
	)
	await wait_process_frames(1)
	assert_true(
		dropper.get_active_count() == 0 and pickup_parent.get_child_count() == 0,
		"Il pickup raccolto deve uscire dal registro e dal SceneTree."
	)

	var terminal_enemy := spawner.try_spawn_enemy()
	assert_not_null(terminal_enemy, "La fixture deve generare il nemico terminale.")
	if terminal_enemy != null:
		terminal_enemy.set_physics_process(false)
		terminal_enemy.get_contact_damage().set_physics_process(false)
		terminal_enemy.experience_amount = 7
		terminal_enemy.experience_reward_scale = 1.0
		terminal_enemy.global_position = player.global_position
		var terminal_health := terminal_enemy.get_health_component()
		assert_true(
			terminal_enemy.take_damage(terminal_health.health_current), "Il nemico terminale deve poter lasciare un drop."
		)
	assert_eq(dropper.get_active_count(), 1, "Prima del terminale deve esistere un pickup non raccolto.")
	var terminal_pickup := dropper.get_active_pickups()[0]
	terminal_pickup.set_physics_process(false)
	assert_true(controller.request_victory(), "La fixture B07 deve entrare in VICTORY.")
	terminal_pickup._physics_process(1.0)
	assert_true(
		not terminal_pickup.is_collected() and experience.experience_current == 5,
		"Il terminale deve fermare magnete e progressione."
	)
	assert_true(movement_slice.restart_run(7202), "La scena B07 deve accettare il restart dal terminale.")
	assert_true(
		experience.experience_current == 0 and dropper.get_active_count() == 0,
		"Il restart deve azzerare XP e registro pickup immediatamente."
	)
	await wait_process_frames(1)
	assert_eq(pickup_parent.get_child_count(), 0, "Il restart deve liberare i pickup entro fine frame.")

	var despawned_enemy := spawner.try_spawn_enemy()
	assert_not_null(despawned_enemy, "La fixture deve generare il nemico da despawn.")
	if despawned_enemy != null:
		despawned_enemy.queue_free()
	await wait_process_frames(1)
	assert_eq(dropper.get_active_count(), 0, "Un despawn senza morte non deve generare XP.")

	controller.prepare_restart()


func _on_direct_pickup_collected(_pickup: ExperiencePickup, amount: int, experience: ExperienceSystem) -> void:
	_direct_collection_count += 1
	experience.add_experience(amount)


func _on_drop_spawned(_pickup: ExperiencePickup) -> void:
	_drop_spawn_count += 1


func _on_drop_collected(_pickup: ExperiencePickup, _amount: int, _experience_current: int) -> void:
	_drop_collection_count += 1
