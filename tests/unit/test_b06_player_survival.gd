extends GutGameplayTest

const PLAYER_SCENE := preload("res://scenes/actors/player.tscn")
const ENEMY_SCENE := preload("res://scenes/actors/base_enemy.tscn")

var _player_damage_count := 0
var _player_death_count := 0
var _run_end_count := 0


func test_health_invulnerability() -> void:
	var health := HealthComponent.new()
	health.name = "HealthComponent"
	health.health_max = 100.0
	health.invulnerability_duration = 0.75
	add_child_autofree(health)
	await wait_process_frames(1)

	assert_true(health.take_damage(25.0), "Il primo danno deve essere applicato.")
	assert_almost_eq(health.health_current, 75.0, FLOAT_TOLERANCE, "Il danno deve ridurre gli HP.")
	assert_true(health.is_invulnerable(), "Un danno non letale deve aprire la finestra di invulnerabilita.")
	assert_almost_eq(
		health.invulnerability_remaining, 0.75, FLOAT_TOLERANCE, "La finestra deve partire dalla durata configurata."
	)
	assert_true(not health.take_damage(10.0), "Il danno ripetuto nella stessa finestra deve essere respinto.")
	assert_true(not health.advance_invulnerability(-1.0), "Un delta negativo non deve consumare invulnerabilita.")
	health.advance_invulnerability(0.5)
	assert_almost_eq(
		health.invulnerability_remaining, 0.25, FLOAT_TOLERANCE, "L'invulnerabilita deve avanzare con il tempo di gameplay."
	)
	assert_true(not health.take_damage(10.0), "La finestra parzialmente consumata deve restare attiva.")
	health.advance_invulnerability(0.2499999)
	health.advance_invulnerability(0.0000001)
	assert_true(not health.is_invulnerable(), "La finestra deve chiudersi senza residui floating point.")
	assert_true(health.take_damage(1000.0), "Il danno oltre gli HP residui deve essere applicato una volta.")
	assert_almost_eq(health.health_current, 0.0, FLOAT_TOLERANCE, "Gli HP letali devono essere clamped a zero.")
	assert_true(not health.is_alive(), "Zero HP deve rendere la salute morta.")
	assert_true(not health.take_damage(1.0), "Una salute morta non deve accettare altri danni.")

	health.reset_to_max()
	assert_almost_eq(health.health_current, 100.0, FLOAT_TOLERANCE, "Il reset deve ripristinare gli HP massimi.")
	assert_true(not health.is_invulnerable(), "Il reset deve cancellare l'invulnerabilita residua.")


func test_contact_damage() -> void:
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
	add_child_autofree(fixture)
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
	assert_true(health != null, "Il Player deve comporre HealthComponent.")
	assert_true(contact != null, "BaseEnemy deve comporre ContactDamage.")
	if health == null or contact == null:
		return

	assert_almost_eq(health.health_max, 100.0, FLOAT_TOLERANCE, "La baseline Player deve essere 100 HP.")
	assert_almost_eq(contact.damage, 20.0, FLOAT_TOLERANCE, "La baseline del contatto deve essere 20 danni.")
	assert_true(not contact.try_damage(player), "Il contatto in BOOT non deve applicare danno.")
	assert_true(controller.start_run(6001), "La fixture contatto deve avviare la run.")
	assert_true(contact.try_damage(player), "Il contatto in RUNNING deve applicare danno.")
	assert_almost_eq(health.health_current, 80.0, FLOAT_TOLERANCE, "Il contatto deve sottrarre il danno configurato.")
	assert_eq(_player_damage_count, 1, "Il Player deve inoltrare un solo segnale di danno effettivo.")
	assert_true(not contact.try_damage(player), "Il contatto persistente deve rispettare l'invulnerabilita.")
	assert_true(player.is_damage_blink_active(), "L'invulnerabilita deve attivare il lampeggio Player.")
	assert_true(player.is_damage_blink_visible(), "Il lampeggio deve iniziare dal frame visibile.")
	player._physics_process(PresentationTimings.PLAYER_DAMAGE_BLINK_INTERVAL_SECONDS + 0.01)
	assert_true(not player.is_damage_blink_visible(), "Il Player deve alternare visibilita durante l'invulnerabilita.")

	var paused_remaining := health.invulnerability_remaining
	assert_true(controller.request_manual_pause(), "La fixture deve entrare in pausa.")
	player._physics_process(5.0)
	assert_almost_eq(
		health.invulnerability_remaining, paused_remaining, FLOAT_TOLERANCE, "La pausa non deve consumare l'invulnerabilita."
	)
	assert_true(not contact.try_damage(player), "La pausa deve bloccare il danno da contatto.")
	assert_true(controller.resume_run(), "La fixture deve riprendere la run.")
	player._physics_process(0.5)
	assert_true(not contact.try_damage(player), "La finestra deve restare attiva prima della scadenza.")
	player._physics_process(0.25)
	assert_true(contact.try_damage(player), "Il contatto deve poter colpire di nuovo a finestra scaduta.")
	assert_almost_eq(health.health_current, 60.0, FLOAT_TOLERANCE, "La seconda hit valida deve sottrarre altri 20 HP.")

	health.clear_invulnerability()
	health.set_health_max(contact.damage)
	assert_true(contact.try_damage(player), "Il contatto letale deve essere applicato.")
	assert_true(controller.get_state() == RunController.RunState.DEFEAT, "La morte Player deve richiedere DEFEAT.")
	assert_eq(_player_death_count, 1, "La morte Player deve essere inoltrata una sola volta.")
	assert_true(not contact.try_damage(player), "Il terminale deve bloccare contatti successivi.")
	assert_true(controller.restart_run(6002), "Il terminale deve poter avviare una nuova run.")
	assert_true(controller.is_running() and not get_tree().paused, "Il restart deve tornare a RUNNING senza pausa.")
	assert_true(player.is_alive(), "Il restart deve rendere di nuovo vivo il Player.")
	assert_almost_eq(health.health_max, 100.0, FLOAT_TOLERANCE, "Il restart deve ripristinare la vita massima base.")
	assert_almost_eq(health.health_current, health.health_max, FLOAT_TOLERANCE, "Il restart deve ripristinare tutti gli HP.")
	assert_true(not health.is_invulnerable(), "Il restart deve cancellare il timer di invulnerabilita.")

	controller.prepare_restart()


func test_physics_contact() -> void:
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
	add_child_autofree(fixture)
	player.set_run_controller(controller)
	enemy.set_target(player)
	enemy.set_run_controller(controller)
	player.set_physics_process(false)
	enemy.set_physics_process(false)
	player.global_position = Vector2(320.0, 240.0)
	enemy.global_position = player.global_position
	assert_true(controller.start_run(6101), "La fixture fisica deve avviare la run.")

	await wait_physics_frames(4)
	var health := player.get_health_component()
	assert_almost_eq(
		health.health_current, health.health_max - enemy.get_contact_damage().damage, FLOAT_TOLERANCE,
		"L'overlap fisico deve produrre una hit da contatto."
	)
	assert_true(health.is_invulnerable(), "L'overlap persistente deve lasciare attiva la protezione post-hit.")
	assert_true(enemy.get_contact_damage().collision_mask == 1, "ContactDamage deve monitorare il layer Player Body.")
	assert_true(player.collision_layer == 1, "Il Player deve esporsi sul layer fisico dedicato.")

	controller.prepare_restart()


func test_composed_defeat_and_restart() -> void:
	_run_end_count = 0
	var movement_slice := await instantiate_movement_slice()

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

	assert_true(controller != null, "La scena B06 deve contenere RunController.")
	assert_true(spawner != null, "La scena B06 deve contenere EnemySpawner.")
	assert_true(player != null, "La scena B06 deve contenere Player.")
	assert_true(end_screen != null, "La scena B06 deve contenere EndScreen.")
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
		return

	controller.set_process(false)
	spawner.set_process(false)
	weapon.set_process(false)
	player.set_physics_process(false)
	controller.run_ended.connect(_on_run_ended)
	assert_true(controller.is_running(), "La scena B06 deve partire in RUNNING.")
	assert_true(player.get_run_controller() == controller, "Il Player composto deve usare RunController.")
	assert_true(not end_screen.visible, "EndScreen deve partire nascosto.")
	assert_true(not movement_slice.restart_run(6999), "Una run attiva non deve accettare restart.")

	spawner.reset_for_run(6201)
	spawner._process(spawner.spawn_profile.initial_spawn_delay)
	assert_eq(spawner.get_alive_count(), 1, "La scena deve generare un nemico di prova.")
	var enemy: BaseEnemy
	if spawner.get_alive_count() == 1:
		enemy = spawner.get_spawned_enemies()[0]
		enemy.set_physics_process(false)
		enemy.get_contact_damage().set_physics_process(false)
		enemy.global_position = player.global_position

	var projectile := weapon.try_fire()
	assert_true(projectile != null, "La fixture deve creare un proiettile da ripulire.")
	if projectile != null:
		projectile.set_physics_process(false)

	if enemy != null:
		var health := player.get_health_component()
		health.set_health_max(enemy.get_contact_damage().damage)
		health.reset_to_max()
		assert_true(enemy.get_contact_damage().try_damage(player), "Il contatto composto deve infliggere la hit letale.")
		assert_true(controller.get_state() == RunController.RunState.DEFEAT, "La morte composta deve entrare in DEFEAT.")
		assert_true(get_tree().paused, "DEFEAT deve mettere in pausa il SceneTree.")
		assert_true(end_screen.visible and end_screen.is_accepting_restart(), "DEFEAT deve mostrare un Game Over interattivo.")
		assert_eq(EndScreen.format_run_time(125.9), "02:05", "Il riepilogo deve formattare il tempo come MM:SS.")
		assert_true(not enemy.get_contact_damage().try_damage(player), "Il terminale deve bloccare il danno residuo.")
		assert_vector_near(router.movement_vector, Vector2.ZERO, "DEFEAT deve azzerare il router.")

	var previous_seed := controller.get_seed()
	var restart_button := end_screen.get_restart_button()
	assert_true(restart_button != null and not restart_button.disabled, "Il bottone RIPROVA deve essere attivo in Game Over.")
	if restart_button != null:
		restart_button.emit_signal(&"pressed")
	assert_true(controller.is_running() and not get_tree().paused, "RIPROVA deve avviare subito una nuova run.")
	assert_eq(controller.get_seed(), previous_seed + 1, "Il restart UI deve avanzare il seed della run.")
	assert_true(not end_screen.visible, "Il restart deve nascondere EndScreen.")
	assert_true(player.is_alive(), "Il restart composto deve ripristinare il Player.")
	assert_almost_eq(
		player.get_health_component().health_max, player.get_base_health_max(), FLOAT_TOLERANCE,
		"Il restart composto deve rimuovere modifiche alla vita massima, mantenendo il moltiplicatore del personaggio equipaggiato."
	)
	assert_almost_eq(
		player.get_health_component().health_current, player.get_health_component().health_max, FLOAT_TOLERANCE,
		"Il restart composto deve ripristinare gli HP."
	)
	assert_true(not player.get_health_component().is_invulnerable(), "Il restart non deve conservare invulnerabilita.")
	var arena_world := movement_slice.get_arena_world() as ArenaWorld
	assert_vector_near(
		player.global_position,
		arena_world.get_world_center() if arena_world != null else arena.get_playfield_center(),
		"Il restart deve ricentrare il Player."
	)
	assert_true(not router.is_input_suspended(), "Il restart neutro deve riarmare InputRouter.")
	await wait_process_frames(1)
	assert_eq(enemies.get_child_count(), 0, "Il restart deve liberare tutti i nemici entro fine frame.")
	assert_eq(projectiles.get_child_count(), 0, "Il restart deve liberare tutti i proiettili entro fine frame.")

	for restart_index in range(5):
		var health := player.get_health_component()
		health.clear_invulnerability()
		assert_true(player.take_contact_damage(health.health_current), "Ogni run rapida deve poter terminare per danno letale.")
		assert_true(controller.is_terminal() and get_tree().paused, "Ogni sconfitta rapida deve chiudere la run.")
		assert_true(movement_slice.restart_run(7000 + restart_index), "Ogni sconfitta rapida deve accettare un restart.")
		await wait_process_frames(1)
		assert_true(controller.is_running() and not get_tree().paused, "Ogni restart rapido deve tornare a RUNNING.")
		assert_true(player.is_alive(), "Ogni restart rapido deve ripristinare il Player.")
		assert_true(not player.get_health_component().is_invulnerable(), "Nessun timer deve sopravvivere al restart.")
		assert_eq(enemies.get_child_count(), 0, "Un restart rapido non deve lasciare nemici.")
		assert_eq(projectiles.get_child_count(), 0, "Un restart rapido non deve lasciare proiettili.")

	assert_eq(_run_end_count, 6, "Sei sconfitte devono emettere sei soli eventi terminali.")
	controller.prepare_restart()


func _on_player_damaged(_player: Player, _amount: float, _health_current: float) -> void:
	_player_damage_count += 1


func _on_fixture_player_died(_player: Player, controller: RunController) -> void:
	_player_death_count += 1
	controller.request_defeat()


func _on_run_ended(_final_state: RunController.RunState, _run_time: float) -> void:
	_run_end_count += 1
