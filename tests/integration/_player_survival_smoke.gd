extends SceneTree

const PLAYER_SCENE := preload("res://scenes/actors/player.tscn")
const ENEMY_SCENE := preload("res://scenes/actors/base_enemy.tscn")
const MOVEMENT_SLICE_SCENE := preload("res://scenes/game/movement_slice.tscn")
const FLOAT_TOLERANCE := 0.001
const INITIAL_VIEWPORT_SIZE := Vector2i(1280, 720)

var _failures: Array[String] = []
var _player_damage_count := 0
var _player_death_count := 0
var _run_end_count := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	await _validate_health_invulnerability()
	await _validate_contact_damage()
	await _validate_physics_contact()
	await _validate_composed_defeat_and_restart()
	await _finish()


func _validate_health_invulnerability() -> void:
	var health := HealthComponent.new()
	health.name = "HealthComponent"
	health.health_max = 100.0
	health.invulnerability_duration = 0.75
	root.add_child(health)
	await process_frame

	_expect(health.take_damage(25.0), "Il primo danno deve essere applicato.")
	_expect_float_near(health.health_current, 75.0, "Il danno deve ridurre gli HP.")
	_expect(health.is_invulnerable(), "Un danno non letale deve aprire la finestra di invulnerabilita.")
	_expect_float_near(
		health.invulnerability_remaining,
		0.75,
		"La finestra deve partire dalla durata configurata."
	)
	_expect(not health.take_damage(10.0), "Il danno ripetuto nella stessa finestra deve essere respinto.")
	_expect(not health.advance_invulnerability(-1.0), "Un delta negativo non deve consumare invulnerabilita.")
	health.advance_invulnerability(0.5)
	_expect_float_near(
		health.invulnerability_remaining,
		0.25,
		"L'invulnerabilita deve avanzare con il tempo di gameplay."
	)
	_expect(not health.take_damage(10.0), "La finestra parzialmente consumata deve restare attiva.")
	health.advance_invulnerability(0.2499999)
	health.advance_invulnerability(0.0000001)
	_expect(not health.is_invulnerable(), "La finestra deve chiudersi senza residui floating point.")
	_expect(health.take_damage(1000.0), "Il danno oltre gli HP residui deve essere applicato una volta.")
	_expect_float_near(health.health_current, 0.0, "Gli HP letali devono essere clamped a zero.")
	_expect(not health.is_alive(), "Zero HP deve rendere la salute morta.")
	_expect(not health.take_damage(1.0), "Una salute morta non deve accettare altri danni.")

	health.reset_to_max()
	_expect_float_near(health.health_current, 100.0, "Il reset deve ripristinare gli HP massimi.")
	_expect(not health.is_invulnerable(), "Il reset deve cancellare l'invulnerabilita residua.")
	health.queue_free()
	await process_frame


func _validate_contact_damage() -> void:
	_player_damage_count = 0
	_player_death_count = 0
	var fixture := Node2D.new()
	fixture.name = "ContactDamageFixture"
	var controller := RunController.new()
	controller.name = "RunController"
	controller.set_process(false)
	var player := PLAYER_SCENE.instantiate() as Player
	var enemy := ENEMY_SCENE.instantiate() as BaseEnemy
	fixture.add_child(controller)
	fixture.add_child(player)
	fixture.add_child(enemy)
	root.add_child(fixture)
	player.set_physics_process(false)
	enemy.set_physics_process(false)
	enemy.get_contact_damage().set_physics_process(false)
	player.set_run_controller(controller)
	enemy.set_target(player)
	enemy.set_run_controller(controller)
	player.damaged.connect(_on_player_damaged)
	player.died.connect(_on_fixture_player_died.bind(controller))

	var health := player.get_health_component()
	var contact := enemy.get_contact_damage()
	_expect(health != null, "Il Player deve comporre HealthComponent.")
	_expect(contact != null, "BaseEnemy deve comporre ContactDamage.")
	if health == null or contact == null:
		fixture.queue_free()
		await process_frame
		return

	_expect_float_near(health.health_max, 100.0, "La baseline Player deve essere 100 HP.")
	_expect_float_near(contact.damage, 20.0, "La baseline del contatto deve essere 20 danni.")
	_expect(not contact.try_damage(player), "Il contatto in BOOT non deve applicare danno.")
	_expect(controller.start_run(6001), "La fixture contatto deve avviare la run.")
	_expect(contact.try_damage(player), "Il contatto in RUNNING deve applicare danno.")
	_expect_float_near(health.health_current, 80.0, "Il contatto deve sottrarre il danno configurato.")
	_expect(_player_damage_count == 1, "Il Player deve inoltrare un solo segnale di danno effettivo.")
	_expect(not contact.try_damage(player), "Il contatto persistente deve rispettare l'invulnerabilita.")
	_expect(player.is_damage_blink_active(), "L'invulnerabilita deve attivare il lampeggio Player.")
	_expect(player.is_damage_blink_visible(), "Il lampeggio deve iniziare dal frame visibile.")
	player._physics_process(PresentationTimings.PLAYER_DAMAGE_BLINK_INTERVAL_SECONDS + 0.01)
	_expect(
		not player.is_damage_blink_visible(),
		"Il Player deve alternare visibilita durante l'invulnerabilita."
	)

	var paused_remaining := health.invulnerability_remaining
	_expect(controller.request_manual_pause(), "La fixture deve entrare in pausa.")
	player._physics_process(5.0)
	_expect_float_near(
		health.invulnerability_remaining,
		paused_remaining,
		"La pausa non deve consumare l'invulnerabilita."
	)
	_expect(not contact.try_damage(player), "La pausa deve bloccare il danno da contatto.")
	_expect(controller.resume_run(), "La fixture deve riprendere la run.")
	player._physics_process(0.5)
	_expect(not contact.try_damage(player), "La finestra deve restare attiva prima della scadenza.")
	player._physics_process(0.25)
	_expect(contact.try_damage(player), "Il contatto deve poter colpire di nuovo a finestra scaduta.")
	_expect_float_near(health.health_current, 60.0, "La seconda hit valida deve sottrarre altri 20 HP.")

	health.clear_invulnerability()
	health.set_health_max(contact.damage)
	_expect(contact.try_damage(player), "Il contatto letale deve essere applicato.")
	_expect(controller.get_state() == RunController.RunState.DEFEAT, "La morte Player deve richiedere DEFEAT.")
	_expect(_player_death_count == 1, "La morte Player deve essere inoltrata una sola volta.")
	_expect(not contact.try_damage(player), "Il terminale deve bloccare contatti successivi.")
	_expect(controller.restart_run(6002), "Il terminale deve poter avviare una nuova run.")
	_expect(controller.is_running() and not paused, "Il restart deve tornare a RUNNING senza pausa.")
	_expect(player.is_alive(), "Il restart deve rendere di nuovo vivo il Player.")
	_expect_float_near(health.health_max, 100.0, "Il restart deve ripristinare la vita massima base.")
	_expect_float_near(health.health_current, health.health_max, "Il restart deve ripristinare tutti gli HP.")
	_expect(not health.is_invulnerable(), "Il restart deve cancellare il timer di invulnerabilita.")

	controller.prepare_restart()
	paused = false
	fixture.queue_free()
	await process_frame


func _validate_physics_contact() -> void:
	var fixture := Node2D.new()
	fixture.name = "PhysicsContactFixture"
	var controller := RunController.new()
	controller.name = "RunController"
	controller.set_process(false)
	var player := PLAYER_SCENE.instantiate() as Player
	var enemy := ENEMY_SCENE.instantiate() as BaseEnemy
	fixture.add_child(controller)
	fixture.add_child(player)
	fixture.add_child(enemy)
	root.add_child(fixture)
	player.set_run_controller(controller)
	enemy.set_target(player)
	enemy.set_run_controller(controller)
	player.set_physics_process(false)
	enemy.set_physics_process(false)
	player.global_position = Vector2(320.0, 240.0)
	enemy.global_position = player.global_position
	_expect(controller.start_run(6101), "La fixture fisica deve avviare la run.")

	for _frame_index in range(4):
		await physics_frame
	var health := player.get_health_component()
	_expect_float_near(
		health.health_current,
		health.health_max - enemy.get_contact_damage().damage,
		"L'overlap fisico deve produrre una hit da contatto."
	)
	_expect(health.is_invulnerable(), "L'overlap persistente deve lasciare attiva la protezione post-hit.")
	_expect(enemy.get_contact_damage().collision_mask == 1, "ContactDamage deve monitorare il layer Player Body.")
	_expect(player.collision_layer == 1, "Il Player deve esporsi sul layer fisico dedicato.")

	controller.prepare_restart()
	paused = false
	fixture.queue_free()
	await process_frame


func _validate_composed_defeat_and_restart() -> void:
	_run_end_count = 0
	root.content_scale_size = INITIAL_VIEWPORT_SIZE
	root.size = INITIAL_VIEWPORT_SIZE
	await _wait_processed_frame()
	var movement_slice = MOVEMENT_SLICE_SCENE.instantiate()
	root.add_child(movement_slice)
	await _wait_processed_frame()

	var controller := movement_slice.get_node_or_null("RunController") as RunController
	var spawner := movement_slice.get_node_or_null("EnemySpawner") as EnemySpawner
	var player := movement_slice.get_node_or_null("World/Player") as Player
	var enemies := movement_slice.get_node_or_null("World/Enemies") as Node2D
	var projectiles := movement_slice.get_node_or_null("World/Projectiles") as Node2D
	var router := movement_slice.get_node_or_null("InputRouter") as InputRouter
	var arena := movement_slice.get_node_or_null("ArenaLayout") as ArenaLayout
	var end_screen := movement_slice.get_node_or_null("UI/EndScreen") as EndScreen
	var weapon: WeaponController
	if player != null:
		weapon = player.get_weapon_controller()

	_expect(controller != null, "La scena B06 deve contenere RunController.")
	_expect(spawner != null, "La scena B06 deve contenere EnemySpawner.")
	_expect(player != null, "La scena B06 deve contenere Player.")
	_expect(end_screen != null, "La scena B06 deve contenere EndScreen.")
	if (
		controller == null
		or spawner == null
		or player == null
		or enemies == null
		or projectiles == null
		or router == null
		or arena == null
		or end_screen == null
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
	controller.run_ended.connect(_on_run_ended)
	_expect(controller.is_running(), "La scena B06 deve partire in RUNNING.")
	_expect(player.get_run_controller() == controller, "Il Player composto deve usare RunController.")
	_expect(not end_screen.visible, "EndScreen deve partire nascosto.")
	_expect(not movement_slice.restart_run(6999), "Una run attiva non deve accettare restart.")

	spawner.reset_for_run(6201)
	spawner._process(spawner.spawn_profile.initial_spawn_delay)
	_expect(spawner.get_alive_count() == 1, "La scena deve generare un nemico di prova.")
	var enemy: BaseEnemy
	if spawner.get_alive_count() == 1:
		enemy = spawner.get_spawned_enemies()[0]
		enemy.set_physics_process(false)
		enemy.get_contact_damage().set_physics_process(false)
		enemy.global_position = player.global_position

	var projectile := weapon.try_fire()
	_expect(projectile != null, "La fixture deve creare un proiettile da ripulire.")
	if projectile != null:
		projectile.set_physics_process(false)

	if enemy != null:
		var health := player.get_health_component()
		health.set_health_max(enemy.get_contact_damage().damage)
		health.reset_to_max()
		_expect(enemy.get_contact_damage().try_damage(player), "Il contatto composto deve infliggere la hit letale.")
		_expect(controller.get_state() == RunController.RunState.DEFEAT, "La morte composta deve entrare in DEFEAT.")
		_expect(paused, "DEFEAT deve mettere in pausa il SceneTree.")
		_expect(end_screen.visible and end_screen.is_accepting_restart(), "DEFEAT deve mostrare un Game Over interattivo.")
		_expect(EndScreen.format_run_time(125.9) == "02:05", "Il riepilogo deve formattare il tempo come MM:SS.")
		_expect(not enemy.get_contact_damage().try_damage(player), "Il terminale deve bloccare il danno residuo.")
		_expect_vector_near(router.movement_vector, Vector2.ZERO, "DEFEAT deve azzerare il router.")

	var previous_seed := controller.get_seed()
	var restart_button := end_screen.get_restart_button()
	_expect(restart_button != null and not restart_button.disabled, "Il bottone RIPROVA deve essere attivo in Game Over.")
	if restart_button != null:
		restart_button.emit_signal(&"pressed")
	_expect(controller.is_running() and not paused, "RIPROVA deve avviare subito una nuova run.")
	_expect(controller.get_seed() == previous_seed + 1, "Il restart UI deve avanzare il seed della run.")
	_expect(not end_screen.visible, "Il restart deve nascondere EndScreen.")
	_expect(player.is_alive(), "Il restart composto deve ripristinare il Player.")
	_expect_float_near(
		player.get_health_component().health_max,
		100.0,
		"Il restart composto deve rimuovere modifiche alla vita massima."
	)
	_expect_float_near(
		player.get_health_component().health_current,
		player.get_health_component().health_max,
		"Il restart composto deve ripristinare gli HP."
	)
	_expect(not player.get_health_component().is_invulnerable(), "Il restart non deve conservare invulnerabilita.")
	_expect_vector_near(player.global_position, arena.get_playfield_center(), "Il restart deve ricentrare il Player.")
	_expect(not router.is_input_suspended(), "Il restart neutro deve riarmare InputRouter.")
	await process_frame
	_expect(enemies.get_child_count() == 0, "Il restart deve liberare tutti i nemici entro fine frame.")
	_expect(projectiles.get_child_count() == 0, "Il restart deve liberare tutti i proiettili entro fine frame.")

	for restart_index in range(5):
		var health := player.get_health_component()
		health.clear_invulnerability()
		_expect(
			player.take_contact_damage(health.health_current),
			"Ogni run rapida deve poter terminare per danno letale."
		)
		_expect(controller.is_terminal() and paused, "Ogni sconfitta rapida deve chiudere la run.")
		_expect(
			movement_slice.restart_run(7000 + restart_index),
			"Ogni sconfitta rapida deve accettare un restart."
		)
		await process_frame
		_expect(controller.is_running() and not paused, "Ogni restart rapido deve tornare a RUNNING.")
		_expect(player.is_alive(), "Ogni restart rapido deve ripristinare il Player.")
		_expect(not player.get_health_component().is_invulnerable(), "Nessun timer deve sopravvivere al restart.")
		_expect(enemies.get_child_count() == 0, "Un restart rapido non deve lasciare nemici.")
		_expect(projectiles.get_child_count() == 0, "Un restart rapido non deve lasciare proiettili.")

	_expect(_run_end_count == 6, "Sei sconfitte devono emettere sei soli eventi terminali.")
	controller.prepare_restart()
	paused = false
	movement_slice.queue_free()
	await process_frame


func _on_player_damaged(_player: Player, _amount: float, _health_current: float) -> void:
	_player_damage_count += 1


func _on_fixture_player_died(_player: Player, controller: RunController) -> void:
	_player_death_count += 1
	controller.request_defeat()


func _on_run_ended(_final_state: RunController.RunState, _run_time: float) -> void:
	_run_end_count += 1


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
		print("B06_PLAYER_SURVIVAL_SMOKE_OK")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	printerr("B06_PLAYER_SURVIVAL_SMOKE_FAIL count=%d" % _failures.size())
	quit(1)
