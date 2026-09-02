extends GutGameplayTest

## PS-057: un piccione viola (SplitterEnemy) ucciso durante una vera
## collisione fisica muore dentro il flush delle query fisiche
## (Projectile._on_area_entered -> try_hit -> take_damage -> died), lo
## stesso momento in cui il server fisico rifiuta ogni cambiamento di stato
## (`Can't change this state while flushing queries`, quattro firme diverse
## documentate dalla card). Il fix differisce con call_deferred() lo spawn
## dei frammenti in SplitterEnemy._on_died(). Chiamare _on_died() o
## take_damage() a mano dal test non riprodurrebbe il problema: qui la
## morte arriva da una sovrapposizione Area2D reale rilevata dal motore
## durante wait_physics_frames(), esattamente come in una run vera.

const SPLITTER_ENEMY_SCENE: PackedScene = preload("res://scenes/actors/splitter_enemy.tscn")
const CONFIGURABLE_ENEMY_SCENE: PackedScene = preload("res://scenes/actors/configurable_enemy.tscn")
const PROJECTILE_SCENE: PackedScene = preload("res://scenes/combat/projectile.tscn")
const PLAYER_SCENE: PackedScene = preload("res://scenes/actors/player.tscn")


func test_real_projectile_collision_kills_splitter_and_spawns_independent_fragments() -> void:
	var fixture := await _build_fixture()
	var controller: RunController = fixture["controller"]
	var spawner: EnemySpawner = fixture["spawner"]
	controller.start_run(5057)

	var outcome := await _kill_splitter_with_real_projectile(fixture)
	var health: Variant = outcome["health"]
	var spawned_fragments: Array[BaseEnemy] = outcome["spawned_fragments"]
	var death_frame: int = outcome["death_frame"]
	var spawn_frame: int = outcome["spawn_frame"]

	assert_true(death_frame >= 0, "Il divisore deve morire per la collisione reale col proiettile entro pochi frame.")
	assert_true(spawn_frame >= 0, "I frammenti devono comparire entro pochi frame dalla morte del divisore.")
	if death_frame >= 0 and spawn_frame >= 0:
		assert_true(
			spawn_frame - death_frame <= 2,
			(
				"Lo spawn differito dei frammenti deve avvenire entro un paio di frame dalla morte "
				+ "(morte al frame %d, frammenti al frame %d)." % [death_frame, spawn_frame]
			)
		)
	assert_false(is_instance_valid(health) and health.is_alive(), "Il divisore deve restare morto dopo la collisione.")

	assert_eq(
		spawned_fragments.size(), 2,
		"La morte reale del divisore deve generare esattamente due frammenti, ne sono nati %d." % spawned_fragments.size()
	)
	for fragment in spawned_fragments:
		assert_false(fragment is SplitterEnemy, "Un frammento non deve essere a sua volta un divisore (nessuna ricorsione).")
		assert_true(is_instance_valid(fragment) and not fragment.is_queued_for_deletion(), "Ogni frammento deve restare vivo.")

	var alive := spawner.get_spawned_enemies()
	assert_eq(alive.size(), 2, "Devono restare vivi esattamente due frammenti, trovati %d." % alive.size())

	var seen_shape_ids: Array[int] = []
	for fragment in alive:
		var fragment_shape := fragment.get_node_or_null("Hurtbox/HurtboxCollisionShape") as CollisionShape2D
		assert_true(
			fragment_shape != null and fragment_shape.shape != null,
			"Ogni frammento deve avere una propria CollisionShape2D valorizzata sulla Hurtbox."
		)
		if fragment_shape == null or fragment_shape.shape == null:
			continue
		var shape_id := fragment_shape.shape.get_instance_id()
		assert_false(
			seen_shape_ids.has(shape_id),
			"I frammenti non devono condividere la stessa risorsa Shape2D: le collisioni devono restare indipendenti."
		)
		seen_shape_ids.append(shape_id)

	print("SPLITTER_SPAWN_PHYSICS_SMOKE_OK")
	controller.prepare_restart()


## PS-057: lo spawn dei frammenti e' ora differito con call_deferred(); questo
## verifica che il rinvio non comprometta il determinismo dello stesso seed.
## Riusa lo stesso fixture/spawner per due cicli sequenziali (morte reale,
## prepare_restart(), stesso seed) invece di due fixture fisiche indipendenti
## sovrapposte: quest'ultima combinazione mescola gruppi globali ("enemies")
## e nemici ancora attivi fra le due istanze, instabile per un test.
func test_fragment_rng_sequence_is_deterministic_across_seeded_runs() -> void:
	var fixture := await _build_fixture()
	var controller: RunController = fixture["controller"]

	controller.start_run(24601)
	var outcome_a := await _kill_splitter_with_real_projectile(fixture)
	var offsets_a := _sorted_pursuit_offsets(outcome_a["spawned_fragments"])
	assert_eq(
		offsets_a.size(), 2, "Il primo ciclo deve produrre due frammenti da confrontare, trovati %d." % offsets_a.size()
	)

	controller.prepare_restart()
	await wait_process_frames(1)

	controller.start_run(24601)
	var outcome_b := await _kill_splitter_with_real_projectile(fixture)
	var offsets_b := _sorted_pursuit_offsets(outcome_b["spawned_fragments"])

	assert_eq(
		offsets_a, offsets_b,
		"Lo stesso seed deve produrre lo stesso pursuit_offset campionato da _rng per i frammenti del divisore."
	)
	controller.prepare_restart()


func _sorted_pursuit_offsets(fragments: Array[BaseEnemy]) -> Array[Vector2]:
	var offsets: Array[Vector2] = []
	for fragment in fragments:
		offsets.append(fragment.get_pursuit_offset())
	offsets.sort_custom(
		func(a: Vector2, b: Vector2) -> bool:
			return a.x < b.x if not is_equal_approx(a.x, b.x) else a.y < b.y
	)
	return offsets


## Costruisce l'ambiente condiviso (arena, controller, target, spawner)
## senza avviare la run: ogni test decide seed e cicli di start_run()/
## prepare_restart() propri.
func _build_fixture() -> Dictionary:
	var fixture_root := Node2D.new()
	var arena := ArenaLayout.new()
	arena.respect_display_safe_area = false
	var controller := RunController.new()
	controller.set_process(false)
	var target := PLAYER_SCENE.instantiate() as Player
	var enemy_parent := Node2D.new()
	var projectile_parent := Node2D.new()

	var profile := EnemySpawnProfile.new()
	profile.base_spawn_interval = 0.05
	profile.min_spawn_interval = 0.05
	profile.spawn_acceleration = 0.0
	profile.initial_spawn_delay = 0.0
	profile.max_alive_enemies = 64
	profile.inner_spawn_margin = 24.0
	profile.outer_spawn_margin = 64.0
	profile.min_player_distance = 0.0
	profile.spawn_sample_attempts = 6
	profile.cleanup_interval = 5.0
	profile.despawn_margin = 200.0
	profile.base_archetype_weight = 0.0

	var spawner := EnemySpawner.new()
	spawner.set_process(false)
	spawner.enemy_scene = CONFIGURABLE_ENEMY_SCENE
	spawner.spawn_profile = profile
	spawner.archetypes = []
	spawner.configure(controller, arena, target, enemy_parent)

	fixture_root.add_child(arena)
	fixture_root.add_child(controller)
	fixture_root.add_child(target)
	fixture_root.add_child(enemy_parent)
	fixture_root.add_child(projectile_parent)
	fixture_root.add_child(spawner)
	add_child_autofree(fixture_root)
	await wait_process_frames(1)
	spawner.set_process(false)
	controller.set_process(false)
	target.global_position = Vector2(1200.0, 1200.0)

	return {
		"controller": controller,
		"spawner": spawner,
		"enemy_parent": enemy_parent,
		"projectile_parent": projectile_parent,
	}


## Fa nascere un divisore nel fixture ricevuto (la run deve gia' essere
## avviata dal chiamante) e lo uccide con una vera collisione fisica:
## un proiettile fermo sovrapposto alla sua Hurtbox, rilevato dal motore
## durante wait_physics_frames(). Nessuna chiamata diretta a
## take_damage()/_on_died(): e' esattamente la sovrapposizione reale,
## dentro il flush delle query fisiche, a innescare il bug della card.
func _kill_splitter_with_real_projectile(fixture: Dictionary) -> Dictionary:
	var controller: RunController = fixture["controller"]
	var spawner: EnemySpawner = fixture["spawner"]
	var projectile_parent: Node2D = fixture["projectile_parent"]

	var fragment_def := EnemyArchetypeDefinition.new()
	fragment_def.id = &"ps057_test_fragment"
	fragment_def.scene = CONFIGURABLE_ENEMY_SCENE
	fragment_def.health_max = 5.0
	fragment_def.move_speed = 90.0
	fragment_def.collision_radius = 10.0
	fragment_def.contact_damage = 5.0
	fragment_def.experience_amount = 1

	var splitter_def := EnemyArchetypeDefinition.new()
	splitter_def.id = &"ps057_test_splitter"
	splitter_def.scene = SPLITTER_ENEMY_SCENE
	splitter_def.health_max = 20.0
	splitter_def.move_speed = 90.0
	splitter_def.collision_radius = 18.0
	splitter_def.contact_damage = 10.0
	splitter_def.experience_amount = 2
	splitter_def.split_fragment_definition = fragment_def
	splitter_def.split_fragment_count = 2
	assert_true(splitter_def.is_valid(), "La definizione del divisore di test deve essere valida.")

	var splitter := spawner.spawn_archetype_instance(splitter_def, Vector2(400.0, 400.0)) as SplitterEnemy
	assert_true(splitter != null, "Lo spawn del divisore deve riuscire.")
	if splitter == null:
		return {"health": null, "spawned_fragments": [] as Array[BaseEnemy], "death_frame": -1, "spawn_frame": -1}
	# Resta fermo: qui interessa la collisione, non l'inseguimento del target.
	splitter.set_physics_process(false)
	# Hurtbox.enable() e ContactDamage.enable() (chiamati da BaseEnemy._ready())
	# usano set_deferred(): un frame fisico basta a renderle davvero attive
	# prima di far comparire il proiettile.
	await wait_physics_frames(1)

	var projectile := PROJECTILE_SCENE.instantiate() as Projectile
	projectile_parent.add_child(projectile)
	projectile.global_position = splitter.global_position
	assert_true(
		projectile.initialize(Vector2.RIGHT, 9999.0, 0.0, 1.0, 8.0, controller),
		"Il proiettile di test deve inizializzarsi con danno letale e velocita' nulla (resta sovrapposto al divisore)."
	)

	var health := splitter.get_health_component()
	assert_not_null(health, "Il divisore deve avere una HealthComponent valida.")

	var spawned_fragments: Array[BaseEnemy] = []
	spawner.enemy_spawned.connect(func(enemy: BaseEnemy) -> void: spawned_fragments.append(enemy))

	var death_frame := -1
	var spawn_frame := -1
	for frame_index in 8:
		await wait_physics_frames(1)
		if death_frame < 0 and (not is_instance_valid(health) or not health.is_alive()):
			death_frame = frame_index
		if spawn_frame < 0 and spawned_fragments.size() >= 2:
			spawn_frame = frame_index
		if death_frame >= 0 and spawn_frame >= 0:
			break

	return {
		"health": health,
		"spawned_fragments": spawned_fragments,
		"death_frame": death_frame,
		"spawn_frame": spawn_frame,
	}
