extends SceneTree

const ENEMY_SCENE: PackedScene = preload("res://scenes/actors/base_enemy.tscn")
const PROJECTILE_SCENE: PackedScene = preload("res://scenes/combat/projectile.tscn")
const MOVEMENT_SLICE_SCENE: PackedScene = preload("res://scenes/game/movement_slice.tscn")
const INITIAL_VIEWPORT_SIZE := Vector2i(1280, 720)
const FLOAT_TOLERANCE := 0.001

var _failures: Array[String] = []
var _damage_event_count := 0
var _death_event_count := 0
var _hit_event_count := 0
var _shot_event_count := 0
var _last_shot_target: BaseEnemy
var _projectile_expired_count := 0
var _health_component_death_count := 0
var _health_snapshots: Array[Vector2] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	paused = false
	root.content_scale_size = INITIAL_VIEWPORT_SIZE
	root.size = INITIAL_VIEWPORT_SIZE
	await _wait_processed_frame()

	_validate_weapon_profile()
	await _validate_health_component()
	await _validate_health_and_targeting()
	await _validate_weapon_and_projectile()
	await _validate_projectile_lifecycle()
	await _validate_physics_hit()
	await _validate_composed_scene()
	await _finish()


func _validate_weapon_profile() -> void:
	var profile := WeaponProfile.new()
	profile.shots_per_second = 4.0
	profile.damage = 10.0
	profile.projectile_speed = 900.0
	profile.projectile_lifetime = 2.0
	profile.projectile_radius = 6.0
	profile.muzzle_offset = 32.0
	_expect_float_near(
		profile.get_fire_interval(),
		0.25,
		FLOAT_TOLERANCE,
		"La frequenza deve produrre il cooldown corretto."
	)

	profile.shots_per_second = -1.0
	profile.damage = -1.0
	profile.projectile_speed = -1.0
	profile.projectile_lifetime = -1.0
	profile.projectile_radius = -1.0
	profile.muzzle_offset = -1.0
	_expect(profile.shots_per_second > 0.0, "La frequenza deve restare positiva.")
	_expect(profile.damage > 0.0, "Il danno deve restare positivo.")
	_expect(profile.projectile_speed > 0.0, "La velocita del proiettile deve restare positiva.")
	_expect(profile.projectile_lifetime > 0.0, "La lifetime deve restare positiva.")
	_expect(profile.projectile_radius >= 1.0, "Il raggio del proiettile deve avere un minimo.")
	_expect(profile.muzzle_offset >= 0.0, "L'offset della volata non puo essere negativo.")

	var configured_profile := load(
		"res://data/weapons/default_weapon_profile.tres"
	) as WeaponProfile
	_expect(configured_profile != null, "Il profilo arma B05 deve essere caricabile.")
	if configured_profile != null:
		_expect_float_near(
			configured_profile.shots_per_second,
			4.0,
			FLOAT_TOLERANCE,
			"Il profilo dati deve fissare la baseline di frequenza."
		)
		_expect_float_near(
			configured_profile.damage,
			10.0,
			FLOAT_TOLERANCE,
			"Il profilo dati deve fissare la baseline di danno."
		)
		_expect_float_near(
			configured_profile.projectile_speed,
			900.0,
			FLOAT_TOLERANCE,
			"Il profilo dati deve fissare la velocita del proiettile."
		)
		_expect_float_near(
			configured_profile.projectile_lifetime,
			2.0,
			FLOAT_TOLERANCE,
			"Il profilo dati deve fissare la lifetime del proiettile."
		)
		_expect_float_near(
			configured_profile.projectile_radius,
			6.0,
			FLOAT_TOLERANCE,
			"Il profilo dati deve fissare il raggio del proiettile."
		)
		_expect_float_near(
			configured_profile.muzzle_offset,
			32.0,
			FLOAT_TOLERANCE,
			"Il profilo dati deve fissare l'offset della volata."
		)


func _validate_health_component() -> void:
	_health_component_death_count = 0
	_health_snapshots.clear()
	var fixture := Node.new()
	fixture.name = "HealthComponentFixture"
	var health := HealthComponent.new()
	health.name = "HealthComponent"
	health.health_max = 30.0
	fixture.add_child(health)
	root.add_child(fixture)
	await process_frame

	_expect(health.take_damage(15.0), "La fixture salute deve accettare il danno.")
	health.health_changed.connect(_on_health_component_changed)
	_health_snapshots.clear()
	health.set_health_max(15.0, true)
	_expect_float_near(
		health.health_current,
		7.5,
		FLOAT_TOLERANCE,
		"Ridurre health_max deve conservare la percentuale richiesta."
	)
	_expect(
		_health_snapshots.size() == 1,
		"set_health_max atomico deve emettere un solo health_changed."
	)
	if _health_snapshots.size() == 1:
		_expect_vector_near(
			_health_snapshots[0],
			Vector2(7.5, 15.0),
			FLOAT_TOLERANCE,
			"Il segnale salute deve esporre soltanto lo stato finale."
		)

	health.set_health_max(1.0)
	health.reset_to_max()
	_expect(
		health.take_damage(0.999999),
		"Un danno quasi letale deve essere applicato."
	)
	_expect(
		health.is_alive(),
		"Un residuo positivo, anche minimo, non deve essere classificato come morte."
	)
	health.set_health_max(2.0)
	_expect(
		health.is_alive(),
		"Cambiare health_max non deve uccidere una salute ancora positiva."
	)

	health.set_health_max(10.0)
	health.reset_to_max()
	health.damaged.connect(_on_reentrant_health_damage.bind(health))
	health.died.connect(_on_health_component_died)
	_expect(health.take_damage(10.0), "Il danno letale deve chiudere la salute.")
	_expect(not health.is_alive(), "Una callback rientrante non deve annullare la morte.")
	_expect_float_near(
		health.health_current,
		0.0,
		FLOAT_TOLERANCE,
		"La transizione letale deve restare clamped a zero."
	)
	_expect(
		_health_component_death_count == 1,
		"La transizione letale deve emettere died una sola volta."
	)

	fixture.queue_free()
	await process_frame


func _validate_health_and_targeting() -> void:
	var fixture := Node2D.new()
	fixture.name = "HealthTargetingFixture"
	var targeting := TargetingSystem.new()
	targeting.name = "TargetingSystem"
	var far_enemy := ENEMY_SCENE.instantiate() as BaseEnemy
	var near_enemy := ENEMY_SCENE.instantiate() as BaseEnemy
	var closest_enemy := ENEMY_SCENE.instantiate() as BaseEnemy
	var tie_enemy := ENEMY_SCENE.instantiate() as BaseEnemy
	far_enemy.name = "FarEnemy"
	near_enemy.name = "NearEnemy"
	closest_enemy.name = "ClosestEnemy"
	tie_enemy.name = "TieEnemy"
	fixture.add_child(targeting)
	fixture.add_child(far_enemy)
	fixture.add_child(near_enemy)
	fixture.add_child(closest_enemy)
	fixture.add_child(tie_enemy)
	root.add_child(fixture)
	await process_frame

	for enemy in [far_enemy, near_enemy, closest_enemy, tie_enemy]:
		enemy.set_physics_process(false)
		enemy.get_health_component().set_health_max(10.0)
		enemy.get_health_component().reset_to_max()
	_expect_float_near(
		far_enemy.get_health_component().health_max,
		10.0,
		FLOAT_TOLERANCE,
		"La fixture deve poter configurare gli HP del nemico."
	)
	var default_enemy := ENEMY_SCENE.instantiate() as BaseEnemy
	fixture.add_child(default_enemy)
	await process_frame
	default_enemy.set_physics_process(false)
	_expect_float_near(
		default_enemy.get_health_component().health_max,
		18.0,
		FLOAT_TOLERANCE,
		"La scena BaseEnemy deve fissare la baseline B37 di 18 HP."
	)
	default_enemy.queue_free()

	far_enemy.global_position = Vector2(100.0, 400.0)
	near_enemy.global_position = Vector2(140.0, 130.0)
	closest_enemy.global_position = Vector2(112.0, 116.0)
	tie_enemy.global_position = Vector2(400.0, 100.0)
	var origin := Vector2(100.0, 100.0)

	# Ordine non monotono e distanze 2D: ne l'ultimo registrato ne il solo asse X
	# possono simulare una selezione corretta.
	_expect(targeting.register_target(far_enemy), "Il bersaglio lontano deve essere registrato.")
	_expect(targeting.register_target(closest_enemy), "Il bersaglio piu vicino deve essere registrato.")
	_expect(targeting.register_target(near_enemy), "Il bersaglio vicino deve essere registrato.")
	_expect(targeting.register_target(tie_enemy), "Il bersaglio equidistante deve essere registrato.")
	_expect(not targeting.register_target(far_enemy), "Il registro non deve accettare duplicati.")
	_expect(targeting.get_registered_count() == 4, "Un duplicato non deve alterare il registro.")
	_expect(
		targeting.get_nearest_alive(origin) == closest_enemy,
		"Il targeting deve scegliere il vivo geometricamente piu vicino."
	)

	_expect(closest_enemy.take_damage(10.0), "Il danno letale deve essere applicato.")
	_expect(not closest_enemy.is_alive(), "La morte deve rendere il nemico non targettabile subito.")
	_expect(
		targeting.get_nearest_alive(origin) == near_enemy,
		"Un morto nello stesso frame deve essere escluso prima di queue_free."
	)
	_expect(near_enemy.take_damage(10.0), "Il secondo danno letale deve essere applicato.")
	_expect(
		targeting.get_nearest_alive(origin) == far_enemy,
		"A parita deve prevalere il primo target registrato ancora vivo."
	)
	_expect(far_enemy.take_damage(10.0), "Anche l'ultimo bersaglio deve poter morire.")
	_expect(
		targeting.get_nearest_alive(origin) == tie_enemy,
		"Dopo la morte del primo equidistante deve restare il secondo."
	)
	_expect(tie_enemy.take_damage(10.0), "Il bersaglio equidistante deve poter morire.")
	_expect(
		targeting.get_nearest_alive(origin) == null,
		"Senza bersagli vivi il targeting deve restituire null."
	)
	_expect(targeting.get_registered_count() == 0, "Le morti devono svuotare il registro sincronicamente.")

	var spawner_a := EnemySpawner.new()
	var spawner_b := EnemySpawner.new()
	var rebind_enemy := ENEMY_SCENE.instantiate() as BaseEnemy
	fixture.add_child(spawner_a)
	fixture.add_child(spawner_b)
	fixture.add_child(rebind_enemy)
	rebind_enemy.set_physics_process(false)
	targeting.bind_enemy_spawner(spawner_a)
	_expect(targeting.register_target(rebind_enemy), "Il target pre-rebind deve entrare nel registro.")
	targeting.bind_enemy_spawner(spawner_b)
	_expect(
		targeting.get_registered_count() == 0,
		"Cambiare spawner deve rimuovere i target appartenenti al registro precedente."
	)

	await process_frame
	fixture.queue_free()
	await process_frame


func _validate_weapon_and_projectile() -> void:
	_damage_event_count = 0
	_death_event_count = 0
	_hit_event_count = 0
	_shot_event_count = 0
	_last_shot_target = null

	var fixture := Node2D.new()
	fixture.name = "WeaponProjectileFixture"
	var controller := RunController.new()
	controller.name = "RunController"
	controller.set_process(false)
	var targeting := TargetingSystem.new()
	targeting.name = "TargetingSystem"
	var source := Node2D.new()
	source.name = "Source"
	var projectiles := Node2D.new()
	projectiles.name = "Projectiles"
	var weapon := WeaponController.new()
	weapon.name = "WeaponController"
	weapon.weapon_profile = WeaponProfile.new()
	weapon.weapon_profile.shots_per_second = 4.0
	weapon.weapon_profile.damage = 7.0
	weapon.weapon_profile.projectile_speed = 600.0
	weapon.weapon_profile.projectile_lifetime = 1.0
	weapon.weapon_profile.projectile_radius = 6.0
	weapon.weapon_profile.muzzle_offset = 24.0
	weapon.projectile_scene = PROJECTILE_SCENE
	var enemy := ENEMY_SCENE.instantiate() as BaseEnemy
	enemy.name = "DamageTarget"

	fixture.add_child(controller)
	fixture.add_child(targeting)
	fixture.add_child(source)
	fixture.add_child(projectiles)
	fixture.add_child(weapon)
	fixture.add_child(enemy)
	root.add_child(fixture)
	await process_frame
	weapon.set_process(false)
	enemy.set_physics_process(false)
	enemy.get_health_component().set_health_max(20.0)
	enemy.get_health_component().reset_to_max()
	source.global_position = Vector2(100.0, 100.0)
	enemy.global_position = Vector2(220.0, 260.0)
	weapon.configure(controller, targeting, projectiles, source)
	weapon.projectile_fired.connect(_on_projectile_fired)
	enemy.damaged.connect(_on_enemy_damaged)
	enemy.died.connect(_on_enemy_died)

	var boot_projectile := PROJECTILE_SCENE.instantiate() as Projectile
	projectiles.add_child(boot_projectile)
	boot_projectile.initialize(Vector2.RIGHT, 5.0, 0.0, 1.0, 6.0, controller)
	boot_projectile.set_physics_process(false)
	_expect(
		not boot_projectile.try_hit(enemy),
		"In BOOT una callback proiettile non deve applicare danno."
	)
	_expect_float_near(
		enemy.get_health_component().health_current,
		20.0,
		FLOAT_TOLERANCE,
		"BOOT deve lasciare invariata la salute del target."
	)
	boot_projectile.expire()
	await process_frame

	_expect(weapon.try_fire() == null, "In BOOT l'arma non deve sparare.")
	_expect(controller.start_run(4242), "La fixture dell'arma deve avviare la run.")
	weapon._process(100.0)
	_expect(projectiles.get_child_count() == 0, "Senza target non deve nascere alcun proiettile.")
	_expect(_shot_event_count == 0, "Senza target non deve essere emesso projectile_fired.")
	_expect(weapon.is_ready_to_fire(), "Un tentativo senza target non deve consumare il cooldown.")

	_expect(targeting.register_target(enemy), "Il bersaglio dell'arma deve essere registrato.")
	weapon._process(0.0)
	_expect(_shot_event_count == 1, "Un target vivo deve produrre esattamente un colpo.")
	_expect(projectiles.get_child_count() == 1, "Il colpo deve essere figlio di Projectiles.")
	_expect(_last_shot_target == enemy, "Il segnale di fuoco deve riportare il target selezionato.")
	_expect(not weapon.is_ready_to_fire(), "Un colpo riuscito deve avviare il cooldown.")
	_expect(weapon.try_fire() == null, "Il cooldown deve impedire un secondo colpo immediato.")

	if projectiles.get_child_count() != 1:
		controller.prepare_restart()
		paused = false
		fixture.queue_free()
		await process_frame
		return
	var first_projectile := projectiles.get_child(0) as Projectile
	first_projectile.set_physics_process(false)
	_expect_vector_near(
		first_projectile.direction,
		Vector2(0.6, 0.8),
		FLOAT_TOLERANCE,
		"Il proiettile deve mirare al target diagonale."
	)
	_expect_vector_near(
		first_projectile.global_position,
		Vector2(114.4, 119.2),
		FLOAT_TOLERANCE,
		"La volata deve applicare l'offset lungo la direzione di mira."
	)
	_expect_float_near(
		first_projectile.damage,
		7.0,
		FLOAT_TOLERANCE,
		"Il proiettile deve fotografare il danno del profilo."
	)
	_expect_float_near(
		first_projectile.speed,
		600.0,
		FLOAT_TOLERANCE,
		"Il proiettile deve fotografare la velocita del profilo."
	)
	_expect_float_near(
		first_projectile.lifetime_remaining,
		1.0,
		FLOAT_TOLERANCE,
		"Il proiettile deve fotografare la lifetime del profilo."
	)
	_expect_float_near(
		first_projectile.projectile_radius,
		6.0,
		FLOAT_TOLERANCE,
		"Il proiettile deve fotografare il raggio del profilo."
	)
	first_projectile.hit_processed.connect(_on_hit_processed)
	_expect(first_projectile.try_hit(enemy), "La prima callback deve applicare la hit.")
	_expect(not first_projectile.try_hit(enemy), "La stessa hit non deve essere elaborata due volte nello stesso frame.")
	_expect_float_near(
		enemy.get_health_component().health_current,
		13.0,
		FLOAT_TOLERANCE,
		"Un proiettile da 7 deve sottrarre esattamente 7 HP."
	)
	_expect(_damage_event_count == 1, "La doppia callback deve emettere un solo evento danno.")
	_expect(_hit_event_count == 1, "La doppia callback deve emettere un solo hit_processed.")
	_expect(_death_event_count == 0, "Il primo colpo non deve essere letale.")

	weapon._process(0.24)
	_expect(_shot_event_count == 1, "Il cooldown incompleto non deve produrre un colpo.")
	weapon._process(0.02)
	_expect(_shot_event_count == 2, "Superare il cooldown deve produrre un solo nuovo colpo.")
	var cadence_projectile: Projectile
	for child in projectiles.get_children():
		if child is Projectile and not child.is_queued_for_deletion():
			cadence_projectile = child as Projectile
	if cadence_projectile != null:
		cadence_projectile.expire()

	# Collisioni o chiamate gia accodate non possono oltrepassare la pausa.
	var cooldown_before_pause := weapon.get_cooldown_remaining()
	controller.request_manual_pause()
	var paused_projectile := PROJECTILE_SCENE.instantiate() as Projectile
	projectiles.add_child(paused_projectile)
	paused_projectile.initialize(Vector2.RIGHT, 13.0, 0.0, 1.0, 6.0, controller)
	paused_projectile.set_physics_process(false)
	_expect(
		not paused_projectile.try_hit(enemy),
		"Una callback proiettile in pausa non deve applicare danno."
	)
	_expect_float_near(
		enemy.get_health_component().health_current,
		13.0,
		FLOAT_TOLERANCE,
		"La pausa deve lasciare invariata la salute."
	)
	weapon._process(100.0)
	_expect_float_near(
		weapon.get_cooldown_remaining(),
		cooldown_before_pause,
		FLOAT_TOLERANCE,
		"La pausa non deve consumare il cooldown dell'arma."
	)
	paused_projectile.expire()
	controller.resume_run()

	var lethal_projectile := PROJECTILE_SCENE.instantiate() as Projectile
	projectiles.add_child(lethal_projectile)
	lethal_projectile.global_position = enemy.global_position
	_expect(
		lethal_projectile.initialize(Vector2.RIGHT, 13.0, 0.0, 1.0, 6.0, controller),
		"Il proiettile letale deve accettare una configurazione valida."
	)
	lethal_projectile.set_physics_process(false)
	lethal_projectile.hit_processed.connect(_on_hit_processed)
	_expect(lethal_projectile.try_hit(enemy), "Il secondo proiettile deve applicare il danno letale.")
	_expect(not lethal_projectile.try_hit(enemy), "La hit letale deve restare monouso.")
	_expect_float_near(
		enemy.get_health_component().health_current,
		0.0,
		FLOAT_TOLERANCE,
		"La vita deve essere clamped a zero."
	)
	_expect(_damage_event_count == 2, "Due proiettili distinti devono produrre due danni.")
	_expect(_hit_event_count == 2, "Il colpo letale deve emettere un solo hit_processed aggiuntivo.")
	_expect(_death_event_count == 1, "La morte deve essere emessa esattamente una volta.")
	_expect(targeting.get_nearest_alive(source.global_position) == null, "Il morto deve uscire subito dal targeting.")

	var dead_target_projectile := PROJECTILE_SCENE.instantiate() as Projectile
	projectiles.add_child(dead_target_projectile)
	dead_target_projectile.initialize(Vector2.RIGHT, 99.0, 0.0, 1.0, 6.0, controller)
	dead_target_projectile.set_physics_process(false)
	_expect(not dead_target_projectile.try_hit(enemy), "Un nemico morto non deve ricevere altre hit.")
	dead_target_projectile.expire()
	_expect(_death_event_count == 1, "Tentativi successivi non devono duplicare died.")

	var terminal_enemy := ENEMY_SCENE.instantiate() as BaseEnemy
	fixture.add_child(terminal_enemy)
	terminal_enemy.set_physics_process(false)
	terminal_enemy.get_health_component().set_health_max(20.0)
	terminal_enemy.get_health_component().reset_to_max()
	controller.request_victory()
	var terminal_projectile := PROJECTILE_SCENE.instantiate() as Projectile
	projectiles.add_child(terminal_projectile)
	terminal_projectile.initialize(Vector2.RIGHT, 20.0, 0.0, 1.0, 6.0, controller)
	terminal_projectile.set_physics_process(false)
	_expect(
		not terminal_projectile.try_hit(terminal_enemy),
		"Uno stato terminale non deve accettare danni gia accodati."
	)
	_expect_float_near(
		terminal_enemy.get_health_component().health_current,
		20.0,
		FLOAT_TOLERANCE,
		"Il terminale deve lasciare invariata la salute."
	)
	terminal_projectile.expire()
	controller.prepare_restart()
	paused = false
	_expect(weapon.is_ready_to_fire(), "Il restart deve azzerare il cooldown.")
	_expect(targeting.get_registered_count() == 0, "Il registro deve restare privo del target morto.")
	await process_frame
	_expect(projectiles.get_child_count() == 0, "Il restart deve liberare i proiettili entro fine frame.")

	fixture.queue_free()
	await process_frame
	paused = false


func _validate_projectile_lifecycle() -> void:
	_projectile_expired_count = 0
	var fixture := Node2D.new()
	fixture.name = "ProjectileLifecycleFixture"
	var controller := RunController.new()
	controller.name = "RunController"
	controller.set_process(false)
	var projectile := PROJECTILE_SCENE.instantiate() as Projectile
	projectile.name = "LifecycleProjectile"
	fixture.add_child(controller)
	fixture.add_child(projectile)
	root.add_child(fixture)
	projectile.set_physics_process(false)
	projectile.global_position = Vector2(10.0, 20.0)
	projectile.expired.connect(_on_projectile_expired)
	_expect(controller.start_run(707), "La fixture lifetime deve avviare la run.")
	_expect(
		projectile.initialize(Vector2(3.0, 4.0), 1.0, 100.0, 0.5, 6.0, controller),
		"Il proiettile lifetime deve accettare la configurazione."
	)

	projectile._physics_process(0.2)
	_expect_vector_near(
		projectile.global_position,
		Vector2(22.0, 36.0),
		FLOAT_TOLERANCE,
		"Il movimento deve usare direzione, velocita e delta."
	)
	_expect_float_near(
		projectile.lifetime_remaining,
		0.3,
		FLOAT_TOLERANCE,
		"Il movimento deve consumare la lifetime."
	)

	controller.request_manual_pause()
	var paused_position := projectile.global_position
	var paused_lifetime := projectile.lifetime_remaining
	projectile._physics_process(0.2)
	_expect_vector_near(
		projectile.global_position,
		paused_position,
		FLOAT_TOLERANCE,
		"La pausa deve fermare il movimento del proiettile."
	)
	_expect_float_near(
		projectile.lifetime_remaining,
		paused_lifetime,
		FLOAT_TOLERANCE,
		"La pausa deve fermare la lifetime del proiettile."
	)
	controller.resume_run()

	projectile._physics_process(0.29)
	_expect(not projectile.is_spent(), "Il proiettile non deve scadere prima della lifetime.")
	projectile._physics_process(0.02)
	_expect(projectile.is_spent(), "Superare la lifetime deve consumare il proiettile.")
	_expect_vector_near(
		projectile.global_position,
		Vector2(40.0, 60.0),
		FLOAT_TOLERANCE,
		"L'ultimo passo deve essere limitato alla lifetime residua."
	)
	_expect(
		_projectile_expired_count == 1,
		"La scadenza deve essere segnalata esattamente una volta."
	)
	await process_frame
	_expect(not is_instance_valid(projectile), "Il proiettile scaduto deve essere liberato.")

	controller.prepare_restart()
	paused = false
	fixture.queue_free()
	await process_frame


func _validate_physics_hit() -> void:
	_damage_event_count = 0
	_hit_event_count = 0
	var fixture := Node2D.new()
	fixture.name = "PhysicsHitFixture"
	var controller := RunController.new()
	controller.name = "RunController"
	controller.set_process(false)
	var enemy := ENEMY_SCENE.instantiate() as BaseEnemy
	enemy.name = "PhysicsTarget"
	var projectile := PROJECTILE_SCENE.instantiate() as Projectile
	projectile.name = "PhysicsProjectile"
	fixture.add_child(controller)
	fixture.add_child(enemy)
	fixture.add_child(projectile)
	root.add_child(fixture)
	enemy.set_physics_process(false)
	enemy.get_health_component().set_health_max(30.0)
	enemy.get_health_component().reset_to_max()
	enemy.global_position = Vector2(400.0, 260.0)
	projectile.global_position = Vector2(300.0, 260.0)
	enemy.damaged.connect(_on_enemy_damaged)
	projectile.hit_processed.connect(_on_hit_processed)
	_expect(controller.start_run(88), "La fixture fisica deve avviare la run.")
	_expect(
		projectile.initialize(Vector2.RIGHT, 5.0, 900.0, 1.0, 6.0, controller),
		"La fixture fisica deve inizializzare il proiettile."
	)

	for _frame_index in range(12):
		if not is_instance_valid(projectile) or projectile.is_queued_for_deletion():
			break
		await physics_frame
	await process_frame
	_expect(_damage_event_count == 1, "L'overlap Area2D deve produrre una sola hit reale.")
	_expect(_hit_event_count == 1, "La collisione fisica deve usare il seam hit monouso.")
	_expect_float_near(
		enemy.get_health_component().health_current,
		25.0,
		FLOAT_TOLERANCE,
		"La collisione fisica deve inoltrare il danno alla salute."
	)
	_expect(not is_instance_valid(projectile), "Il proiettile fisico deve essere consumato.")

	controller.prepare_restart()
	paused = false
	fixture.queue_free()
	await process_frame


func _validate_composed_scene() -> void:
	root.content_scale_size = INITIAL_VIEWPORT_SIZE
	root.size = INITIAL_VIEWPORT_SIZE
	await _wait_processed_frame()
	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	root.add_child(movement_slice)
	await _wait_processed_frame()

	var controller := movement_slice.get_node_or_null("RunController") as RunController
	var spawner := movement_slice.get_node_or_null("EnemySpawner") as EnemySpawner
	var targeting := movement_slice.get_node_or_null("TargetingSystem") as TargetingSystem
	var player := movement_slice.get_node_or_null("World/Player") as Player
	var enemies := movement_slice.get_node_or_null("World/Enemies") as Node2D
	var projectiles := movement_slice.get_node_or_null("World/Projectiles") as Node2D
	var weapon: WeaponController
	if player != null:
		weapon = player.get_weapon_controller()

	_expect(controller != null, "La scena composta deve contenere RunController.")
	_expect(spawner != null, "La scena composta deve contenere EnemySpawner.")
	_expect(targeting != null, "La scena composta deve contenere TargetingSystem.")
	_expect(player != null, "La scena composta deve contenere Player.")
	_expect(enemies != null, "La scena composta deve contenere Enemies.")
	_expect(projectiles != null, "La scena composta deve contenere Projectiles.")
	_expect(weapon != null, "Il Player deve comporre WeaponController.")
	if (
		controller == null
		or spawner == null
		or targeting == null
		or player == null
		or enemies == null
		or projectiles == null
		or weapon == null
	):
		paused = false
		movement_slice.queue_free()
		await process_frame
		return

	spawner.set_process(false)
	controller.set_process(false)
	weapon.set_process(false)
	_expect(controller.is_running(), "La scena B05 deve avviare la run.")
	_expect(targeting.get_enemy_spawner() == spawner, "TargetingSystem deve osservare lo spawner della scena.")
	_expect(
		weapon.get_run_controller() == controller
		and weapon.get_targeting_system() == targeting
		and weapon.get_projectile_parent() == projectiles,
		"WeaponController deve ricevere tutte le dipendenze della scena."
	)
	_expect(weapon.weapon_profile != null, "La scena deve assegnare il profilo arma.")
	_expect(weapon.projectile_scene != null, "La scena deve assegnare la scena proiettile.")

	spawner.reset_for_run(5150)
	spawner._process(spawner.spawn_profile.initial_spawn_delay)
	_expect(spawner.get_alive_count() == 1, "La scena composta deve generare un bersaglio.")
	_expect(targeting.get_registered_count() == 1, "Lo spawn deve entrare nel registro del targeting.")
	if spawner.get_alive_count() == 1:
		var enemy := spawner.get_spawned_enemies()[0]
		enemy.set_physics_process(false)
		enemy.global_position = player.global_position + Vector2(120.0, 160.0)
		enemy.get_health_component().set_health_max(weapon.weapon_profile.damage)
		enemy.get_health_component().reset_to_max()
		weapon.reset_for_run(false)
		var projectile := weapon.try_fire()
		_expect(projectile != null, "L'arma composta deve sparare al nemico registrato.")
		if projectile != null:
			projectile.set_physics_process(false)
			_expect(projectile.get_parent() == projectiles, "Il proiettile deve usare il parent della scena.")
			_expect_vector_near(
				projectile.direction,
				Vector2(0.6, 0.8),
				FLOAT_TOLERANCE,
				"Il colpo composto deve mirare al piu vicino."
			)
			_expect(projectile.collision_mask == 2, "Il proiettile deve monitorare Enemy Hurtbox.")
		_expect(enemy.get_hurtbox().collision_layer == 2, "La Hurtbox deve stare sul layer dedicato.")
		_expect(enemy.get_hurtbox().monitorable, "La Hurtbox viva deve essere monitorabile.")
		var body_collision := enemy.get_node_or_null("CollisionShape") as CollisionShape2D
		var hurtbox_collision := (
			enemy.get_node_or_null("Hurtbox/HurtboxCollisionShape") as CollisionShape2D
		)
		_expect(body_collision != null, "BaseEnemy deve comporre la shape di movimento.")
		_expect(hurtbox_collision != null, "BaseEnemy deve comporre la shape Hurtbox.")
		if body_collision != null and hurtbox_collision != null:
			var body_shape := body_collision.shape
			var hurtbox_shape := hurtbox_collision.shape
			_expect(
				body_shape != hurtbox_shape,
				"Body e Hurtbox devono possedere shape indipendenti."
			)
			_expect(hurtbox_shape is CircleShape2D, "La Hurtbox deve usare una CircleShape2D.")
			if hurtbox_shape is CircleShape2D:
				_expect_float_near(
					(hurtbox_shape as CircleShape2D).radius,
					enemy.collision_radius,
					FLOAT_TOLERANCE,
					"La Hurtbox deve seguire il raggio configurato del nemico."
				)
		if projectile != null:
			_expect(
				projectile.try_hit(enemy),
				"La catena composta deve applicare il colpo letale."
			)
			_expect(
				targeting.get_registered_count() == 0,
				"La kill deve uscire dal targeting nello stesso frame."
			)
			await process_frame
			_expect(
				spawner.get_alive_count() == 0,
				"La kill deve uscire dal registro dello spawner entro fine frame."
			)

	controller.prepare_restart()
	paused = false
	_expect(targeting.get_registered_count() == 0, "Il restart deve svuotare subito il targeting.")
	_expect(weapon.is_ready_to_fire(), "Il restart deve azzerare il cooldown composto.")
	await process_frame
	_expect(enemies.get_child_count() == 0, "Il restart deve liberare i nemici entro fine frame.")
	_expect(projectiles.get_child_count() == 0, "Il restart deve liberare i proiettili entro fine frame.")

	_expect(controller.start_run(5151), "Una seconda run deve poter partire dopo il restart.")
	spawner._process(spawner.spawn_profile.initial_spawn_delay)
	_expect(spawner.get_alive_count() == 1, "La seconda run deve poter generare un nuovo nemico.")
	_expect(targeting.get_registered_count() == 1, "Il targeting deve ricevere target nella seconda run.")
	_expect(weapon.is_ready_to_fire(), "L'arma deve essere pronta nella seconda run.")
	controller.prepare_restart()
	paused = false
	await process_frame
	_expect(enemies.get_child_count() == 0, "Il secondo restart non deve lasciare nemici residui.")
	_expect(projectiles.get_child_count() == 0, "Il secondo restart non deve lasciare proiettili residui.")

	movement_slice.queue_free()
	await process_frame
	paused = false


func _on_enemy_damaged(_enemy: BaseEnemy, _amount: float, _health_current: float) -> void:
	_damage_event_count += 1


func _on_enemy_died(_enemy: BaseEnemy) -> void:
	_death_event_count += 1


func _on_hit_processed(_target: BaseEnemy, _damage: float) -> void:
	_hit_event_count += 1


func _on_projectile_fired(projectile: Projectile, target: BaseEnemy) -> void:
	_shot_event_count += 1
	_last_shot_target = target
	if is_instance_valid(projectile):
		projectile.set_physics_process(false)


func _on_projectile_expired(_projectile: Projectile) -> void:
	_projectile_expired_count += 1


func _on_health_component_changed(health_current: float, health_max: float) -> void:
	_health_snapshots.append(Vector2(health_current, health_max))


func _on_reentrant_health_damage(
	_amount: float,
	_health_current: float,
	health: HealthComponent
) -> void:
	health.reset_to_max()


func _on_health_component_died() -> void:
	_health_component_death_count += 1


func _wait_processed_frame() -> void:
	await process_frame
	await process_frame


func _expect_float_near(
	actual: float,
	expected: float,
	tolerance: float,
	message: String
) -> void:
	_expect(
		absf(actual - expected) <= tolerance,
		"%s Atteso %s, ottenuto %s." % [message, expected, actual]
	)


func _expect_vector_near(
	actual: Vector2,
	expected: Vector2,
	tolerance: float,
	message: String
) -> void:
	_expect(
		actual.distance_to(expected) <= tolerance,
		"%s Atteso %s, ottenuto %s." % [message, expected, actual]
	)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	paused = false
	await process_frame
	if _failures.is_empty():
		print("B05_COMBAT_SLICE_SMOKE_OK")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	printerr("B05_COMBAT_SLICE_SMOKE_FAIL count=%d" % _failures.size())
	quit(1)
