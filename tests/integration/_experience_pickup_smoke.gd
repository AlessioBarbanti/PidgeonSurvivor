extends SceneTree

const PLAYER_SCENE: PackedScene = preload("res://scenes/actors/player.tscn")
const PICKUP_SCENE: PackedScene = preload(
	"res://scenes/pickups/experience_pickup.tscn"
)
const MOVEMENT_SLICE_SCENE: PackedScene = preload(
	"res://scenes/game/movement_slice.tscn"
)
const INITIAL_VIEWPORT_SIZE := Vector2i(1280, 720)
const FLOAT_TOLERANCE := 0.001

var _failures: Array[String] = []
var _direct_collection_count := 0
var _drop_spawn_count := 0
var _drop_collection_count := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	paused = false
	await process_frame
	await _validate_experience_system()
	await _validate_pickup_magnet_and_single_credit()
	await _validate_composed_drop_flow()
	await _finish()


func _validate_experience_system() -> void:
	var controller := RunController.new()
	controller.name = "RunController"
	controller.set_process(false)
	var experience := ExperienceSystem.new()
	experience.name = "ExperienceSystem"
	controller.add_child(experience)
	root.add_child(controller)
	experience.set_run_controller(controller)
	await process_frame

	_expect(
		experience.get_run_controller() == controller,
		"ExperienceSystem deve usare il RunController configurato."
	)
	_expect(
		not experience.add_experience(1),
		"BOOT deve bloccare l'accredito XP."
	)
	_expect(controller.start_run(7001), "La fixture XP deve avviare la run.")
	_expect(
		experience.add_experience(3),
		"RUNNING deve accettare un accredito XP positivo."
	)
	_expect(
		experience.experience_current == 3,
		"L'accredito deve aggiornare il totale XP."
	)
	_expect(
		not experience.add_experience(0),
		"Un accredito nullo deve essere respinto."
	)
	_expect(controller.request_manual_pause(), "La fixture XP deve entrare in pausa.")
	_expect(
		not experience.add_experience(5)
		and experience.experience_current == 3,
		"La pausa deve bloccare la progressione."
	)
	_expect(controller.resume_run(), "La fixture XP deve riprendere.")
	_expect(experience.add_experience(2), "Il resume deve riaprire l'accredito XP.")
	_expect(controller.request_victory(), "La fixture XP deve entrare nel terminale.")
	_expect(
		not experience.add_experience(9)
		and experience.experience_current == 5,
		"Un terminale deve bloccare XP residui."
	)
	_expect(controller.restart_run(7002), "Il terminale deve accettare il restart.")
	_expect(
		experience.experience_current == 0,
		"Il restart deve azzerare gli XP della run precedente."
	)

	controller.prepare_restart()
	paused = false
	controller.queue_free()
	await process_frame


func _validate_pickup_magnet_and_single_credit() -> void:
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
	root.add_child(fixture)
	player.set_physics_process(false)
	player.set_run_controller(controller)
	experience.set_run_controller(controller)
	pickup.configure(controller, player, 3)
	pickup.collected.connect(
		_on_direct_pickup_collected.bind(experience)
	)
	await process_frame

	_expect(controller.start_run(7101), "La fixture pickup deve avviare la run.")
	player.global_position = Vector2(300.0, 240.0)
	pickup.global_position = player.global_position + Vector2(
		player.get_pickup_radius() + 1.0,
		0.0
	)
	var outside_position := pickup.global_position
	pickup._physics_process(1.0)
	_expect_vector_near(
		pickup.global_position,
		outside_position,
		"Un drop fuori da pickup_radius deve restare fermo."
	)
	_expect(
		experience.experience_current == 0,
		"Un drop fuori raggio non deve accreditare XP."
	)

	pickup.global_position = player.global_position + Vector2(120.0, 0.0)
	var distance_before := pickup.global_position.distance_to(player.global_position)
	pickup._physics_process(0.1)
	var distance_after := pickup.global_position.distance_to(player.global_position)
	_expect(
		distance_after < distance_before
		and not pickup.is_collected(),
		"Entro pickup_radius il drop deve muoversi verso il Player."
	)

	var paused_position := pickup.global_position
	_expect(controller.request_manual_pause(), "La fixture pickup deve entrare in pausa.")
	pickup._physics_process(5.0)
	_expect_vector_near(
		pickup.global_position,
		paused_position,
		"La pausa deve fermare il magnete XP."
	)
	_expect(
		not pickup.try_collect(),
		"La raccolta esplicita deve essere bloccata in pausa."
	)
	_expect(controller.resume_run(), "La fixture pickup deve riprendere.")
	pickup._physics_process(1.0)
	_expect(pickup.is_collected(), "Il magnete deve completare la raccolta vicino al Player.")
	_expect(
		experience.experience_current == 3,
		"La raccolta deve accreditare il valore configurato."
	)
	_expect(
		_direct_collection_count == 1,
		"Il pickup deve emettere un solo evento collected."
	)
	_expect(
		not pickup.try_collect()
		and experience.experience_current == 3
		and _direct_collection_count == 1,
		"Tentativi ripetuti prima del free non devono duplicare l'accredito."
	)

	player.pickup_radius = 280.0
	player.reset_for_run()
	_expect_float_near(
		player.get_pickup_radius(),
		160.0,
		"Il reset deve ripristinare il pickup_radius base."
	)

	controller.prepare_restart()
	paused = false
	fixture.queue_free()
	await process_frame


func _validate_composed_drop_flow() -> void:
	_drop_spawn_count = 0
	_drop_collection_count = 0
	root.content_scale_size = INITIAL_VIEWPORT_SIZE
	root.size = INITIAL_VIEWPORT_SIZE
	await _wait_processed_frame()
	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	root.add_child(movement_slice)
	await _wait_processed_frame()

	var controller := movement_slice.get_node_or_null("RunController") as RunController
	var spawner := movement_slice.get_node_or_null("EnemySpawner") as EnemySpawner
	var experience := movement_slice.get_node_or_null(
		"ExperienceSystem"
	) as ExperienceSystem
	var dropper := movement_slice.get_node_or_null(
		"ExperienceDropper"
	) as ExperienceDropper
	var player := movement_slice.get_node_or_null("World/Player") as Player
	var pickup_parent := movement_slice.get_node_or_null("World/Pickups") as Node2D
	var weapon: WeaponController
	if player != null:
		weapon = player.get_weapon_controller()

	_expect(controller != null, "La scena B07 deve contenere RunController.")
	_expect(spawner != null, "La scena B07 deve contenere EnemySpawner.")
	_expect(experience != null, "La scena B07 deve contenere ExperienceSystem.")
	_expect(dropper != null, "La scena B07 deve contenere ExperienceDropper.")
	_expect(player != null, "La scena B07 deve contenere il Player.")
	_expect(pickup_parent != null, "La scena B07 deve contenere World/Pickups.")
	if (
		controller == null
		or spawner == null
		or experience == null
		or dropper == null
		or player == null
		or pickup_parent == null
		or weapon == null
	):
		paused = false
		movement_slice.queue_free()
		await process_frame
		return

	controller.set_process(false)
	spawner.set_process(false)
	weapon.set_process(false)
	player.set_physics_process(false)
	dropper.pickup_spawned.connect(_on_drop_spawned)
	dropper.pickup_collected.connect(_on_drop_collected)
	_expect(controller.is_running(), "La scena B07 deve partire in RUNNING.")
	_expect(
		dropper.get_run_controller() == controller
		and dropper.get_enemy_spawner() == spawner
		and dropper.get_experience_system() == experience
		and dropper.get_player() == player
		and dropper.get_pickup_parent() == pickup_parent,
		"ExperienceDropper deve ricevere tutte le dipendenze della scena."
	)

	spawner.reset_for_run(7201)
	await process_frame
	var enemy := spawner.try_spawn_enemy()
	_expect(enemy != null, "La fixture B07 deve generare un nemico.")
	if enemy == null:
		controller.prepare_restart()
		paused = false
		movement_slice.queue_free()
		await process_frame
		return
	enemy.set_physics_process(false)
	enemy.get_contact_damage().set_physics_process(false)
	enemy.experience_amount = 5
	enemy.experience_reward_scale = 1.0
	enemy.global_position = player.global_position + Vector2(
		player.get_pickup_radius() + 80.0,
		0.0
	)
	var death_position := enemy.global_position
	var enemy_health := enemy.get_health_component()
	_expect(
		enemy.take_damage(enemy_health.health_current),
		"La hit letale deve uccidere il nemico di prova."
	)
	_expect(
		dropper.get_active_count() == 1
		and pickup_parent.get_child_count() == 1
		and _drop_spawn_count == 1,
		"Una morte deve generare esattamente un drop."
	)
	_expect(
		experience.experience_current == 0,
		"La morte non deve accreditare XP prima della raccolta."
	)
	enemy.died.emit(enemy)
	_expect(
		dropper.get_active_count() == 1
		and _drop_spawn_count == 1,
		"Un segnale died duplicato nello stesso frame non deve duplicare il drop."
	)

	var pickup := dropper.get_active_pickups()[0]
	pickup.set_physics_process(false)
	_expect_vector_near(
		pickup.global_position,
		death_position,
		"Il drop deve nascere nella posizione della morte."
	)
	pickup._physics_process(1.0)
	_expect_vector_near(
		pickup.global_position,
		death_position,
		"Fuori pickup_radius il drop composto deve restare fermo."
	)
	pickup.global_position = player.global_position + Vector2(100.0, 0.0)
	pickup._physics_process(0.1)
	_expect(
		pickup.global_position.distance_to(player.global_position) < 100.0,
		"Il drop composto deve entrare nel magnete."
	)
	pickup._physics_process(1.0)
	_expect(
		experience.experience_current == 5
		and _drop_collection_count == 1,
		"La raccolta composta deve accreditare una sola volta il valore del nemico."
	)
	_expect(
		not pickup.try_collect()
		and experience.experience_current == 5
		and _drop_collection_count == 1,
		"Il pickup composto non deve poter accreditare due volte."
	)
	await process_frame
	_expect(
		dropper.get_active_count() == 0
		and pickup_parent.get_child_count() == 0,
		"Il pickup raccolto deve uscire dal registro e dal SceneTree."
	)

	var terminal_enemy := spawner.try_spawn_enemy()
	_expect(terminal_enemy != null, "La fixture deve generare il nemico terminale.")
	if terminal_enemy != null:
		terminal_enemy.set_physics_process(false)
		terminal_enemy.get_contact_damage().set_physics_process(false)
		terminal_enemy.experience_amount = 7
		terminal_enemy.experience_reward_scale = 1.0
		terminal_enemy.global_position = player.global_position
		var terminal_health := terminal_enemy.get_health_component()
		_expect(
			terminal_enemy.take_damage(terminal_health.health_current),
			"Il nemico terminale deve poter lasciare un drop."
		)
	_expect(
		dropper.get_active_count() == 1,
		"Prima del terminale deve esistere un pickup non raccolto."
	)
	var terminal_pickup := dropper.get_active_pickups()[0]
	terminal_pickup.set_physics_process(false)
	_expect(controller.request_victory(), "La fixture B07 deve entrare in VICTORY.")
	terminal_pickup._physics_process(1.0)
	_expect(
		not terminal_pickup.is_collected()
		and experience.experience_current == 5,
		"Il terminale deve fermare magnete e progressione."
	)
	_expect(
		movement_slice.restart_run(7202),
		"La scena B07 deve accettare il restart dal terminale."
	)
	_expect(
		experience.experience_current == 0
		and dropper.get_active_count() == 0,
		"Il restart deve azzerare XP e registro pickup immediatamente."
	)
	await process_frame
	_expect(
		pickup_parent.get_child_count() == 0,
		"Il restart deve liberare i pickup entro fine frame."
	)

	var despawned_enemy := spawner.try_spawn_enemy()
	_expect(despawned_enemy != null, "La fixture deve generare il nemico da despawn.")
	if despawned_enemy != null:
		despawned_enemy.queue_free()
	await process_frame
	_expect(
		dropper.get_active_count() == 0,
		"Un despawn senza morte non deve generare XP."
	)

	controller.prepare_restart()
	paused = false
	movement_slice.queue_free()
	await process_frame


func _on_direct_pickup_collected(
	_pickup: ExperiencePickup,
	amount: int,
	experience: ExperienceSystem
) -> void:
	_direct_collection_count += 1
	experience.add_experience(amount)


func _on_drop_spawned(_pickup: ExperiencePickup) -> void:
	_drop_spawn_count += 1


func _on_drop_collected(
	_pickup: ExperiencePickup,
	_amount: int,
	_experience_current: int
) -> void:
	_drop_collection_count += 1


func _wait_processed_frame() -> void:
	await process_frame
	await process_frame


func _expect_float_near(actual: float, expected: float, message: String) -> void:
	_expect(
		absf(actual - expected) <= FLOAT_TOLERANCE,
		"%s Atteso %s, ottenuto %s." % [message, expected, actual]
	)


func _expect_vector_near(actual: Vector2, expected: Vector2, message: String) -> void:
	_expect(
		actual.distance_to(expected) <= FLOAT_TOLERANCE,
		"%s Atteso %s, ottenuto %s." % [message, expected, actual]
	)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	paused = false
	await process_frame
	if _failures.is_empty():
		print("B07_EXPERIENCE_PICKUP_SMOKE_OK")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	printerr("B07_EXPERIENCE_PICKUP_SMOKE_FAIL count=%d" % _failures.size())
	quit(1)
