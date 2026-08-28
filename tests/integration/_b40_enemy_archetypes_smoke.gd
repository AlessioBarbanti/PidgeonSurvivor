extends SceneTree

const ENEMY_SCENE: PackedScene = preload("res://scenes/actors/base_enemy.tscn")
const CONFIGURABLE_ENEMY_SCENE: PackedScene = preload("res://scenes/actors/configurable_enemy.tscn")
const SPLITTER_ENEMY_SCENE: PackedScene = preload("res://scenes/actors/splitter_enemy.tscn")
const RANGED_ENEMY_SCENE: PackedScene = preload("res://scenes/actors/ranged_enemy.tscn")
const PLAYER_SCENE: PackedScene = preload("res://scenes/actors/player.tscn")
const FLOAT_TOLERANCE := 0.001

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	paused = false
	_validate_pick_weighted_index()
	_validate_archetype_eligibility_window()
	await _validate_deterministic_archetype_sequence()
	await _validate_cluster_respects_cap()
	await _validate_ranged_enemy_telegraph_and_range()
	await _validate_splitter_generates_two_fragments()
	await _validate_no_residue_after_restart()
	await _validate_b49_archetype_textures()
	await _finish()


func _validate_pick_weighted_index() -> void:
	var empty_rng := RandomNumberGenerator.new()
	_expect(
		EnemySpawner.pick_weighted_index([], empty_rng) == -1,
		"Un pool vuoto deve restituire -1."
	)
	_expect(
		EnemySpawner.pick_weighted_index([0.0, 0.0], empty_rng) == -1,
		"Pesi tutti nulli devono restituire -1."
	)
	_expect(
		EnemySpawner.pick_weighted_index([1.0, 2.0], null) == -1,
		"Senza RNG la scelta deve restare -1 invece di generare errori."
	)

	var deterministic_a := RandomNumberGenerator.new()
	var deterministic_b := RandomNumberGenerator.new()
	deterministic_a.seed = 13579
	deterministic_b.seed = 13579
	var weights: Array[float] = [1.0, 3.0, 0.0, 2.0]
	var picks_a: Array[int] = []
	var picks_b: Array[int] = []
	for _sample_index in range(40):
		picks_a.append(EnemySpawner.pick_weighted_index(weights, deterministic_a))
		picks_b.append(EnemySpawner.pick_weighted_index(weights, deterministic_b))
	_expect(
		picks_a == picks_b,
		"Lo stesso seed deve riprodurre la stessa sequenza di indici pesati."
	)
	for pick in picks_a:
		_expect(pick != 2, "Un peso a zero non deve mai essere scelto.")
		_expect(pick >= 0 and pick < weights.size(), "L'indice scelto deve restare nel pool.")

	var distribution_rng := RandomNumberGenerator.new()
	distribution_rng.seed = 2024
	var distribution_weights: Array[float] = [1.0, 3.0]
	var counts := [0, 0]
	var sample_count := 4000
	for _sample_index in range(sample_count):
		var picked_index := EnemySpawner.pick_weighted_index(distribution_weights, distribution_rng)
		if picked_index >= 0:
			counts[picked_index] += 1
	var expected_ratio: float = distribution_weights[1] / distribution_weights[0]
	var actual_ratio := float(counts[1]) / maxf(float(counts[0]), 1.0)
	_expect(
		absf(actual_ratio - expected_ratio) < 0.6,
		(
			"La proporzione osservata (%.2f) deve avvicinarsi al rapporto dei pesi (%.2f)."
			% [actual_ratio, expected_ratio]
		)
	)


func _validate_archetype_eligibility_window() -> void:
	var definition := EnemyArchetypeDefinition.new()
	definition.id = &"b40_window_test"
	definition.scene = CONFIGURABLE_ENEMY_SCENE
	definition.spawn_weight = 1.0
	definition.eligible_time_start = 100.0
	definition.eligible_time_end = 200.0
	_expect(
		not definition.is_eligible_at(50.0),
		"Prima della finestra l'archetipo non deve essere eleggibile."
	)
	_expect(
		definition.is_eligible_at(150.0),
		"Dentro la finestra l'archetipo deve essere eleggibile."
	)
	_expect(
		not definition.is_eligible_at(250.0),
		"Dopo la finestra l'archetipo non deve essere piu' eleggibile."
	)

	var zero_weight := EnemyArchetypeDefinition.new()
	zero_weight.id = &"b40_zero_weight_test"
	zero_weight.scene = CONFIGURABLE_ENEMY_SCENE
	zero_weight.spawn_weight = 0.0
	_expect(
		not zero_weight.is_eligible_at(10.0),
		"Un peso nullo deve escludere l'archetipo indipendentemente dal tempo."
	)


func _validate_deterministic_archetype_sequence() -> void:
	var profile := _make_test_profile()
	var run_a := await _build_spawner(24601, profile, _make_test_archetypes())
	var run_b := await _build_spawner(24601, profile, _make_test_archetypes())
	var spawner_a: EnemySpawner = run_a["spawner"]
	var spawner_b: EnemySpawner = run_b["spawner"]

	var signatures_a: Array[float] = []
	var signatures_b: Array[float] = []
	for _spawn_index in range(16):
		var enemy_a := spawner_a.try_spawn_enemy()
		var enemy_b := spawner_b.try_spawn_enemy()
		signatures_a.append(enemy_a.move_speed if enemy_a != null else -1.0)
		signatures_b.append(enemy_b.move_speed if enemy_b != null else -1.0)
	_expect(
		signatures_a == signatures_b,
		"Due spawner con lo stesso seed devono produrre la stessa sequenza di archetipi."
	)

	await _teardown_fixture(run_a)
	await _teardown_fixture(run_b)


func _validate_cluster_respects_cap() -> void:
	var profile := _make_test_profile()
	profile.max_alive_enemies = 2
	profile.base_archetype_weight = 0.0
	var swarmer := EnemyArchetypeDefinition.new()
	swarmer.id = &"b40_cap_swarmer"
	swarmer.scene = CONFIGURABLE_ENEMY_SCENE
	swarmer.spawn_weight = 1.0
	swarmer.spawn_cluster_size = 3
	swarmer.eligible_time_start = 0.0
	swarmer.eligible_time_end = 3600.0

	var built := await _build_spawner(777, profile, [swarmer])
	var spawner: EnemySpawner = built["spawner"]
	var enemy := spawner.try_spawn_enemy()
	_expect(enemy != null, "Il primo spawn del cluster deve riuscire.")
	_expect(
		spawner.get_alive_count() <= profile.max_alive_enemies,
		(
			"Il cluster dello sciamatore non deve superare max_alive_enemies (%d), attuale %d."
			% [profile.max_alive_enemies, spawner.get_alive_count()]
		)
	)
	await _teardown_fixture(built)


func _validate_ranged_enemy_telegraph_and_range() -> void:
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
	root.add_child(fixture)
	await process_frame
	enemy.set_physics_process(false)

	var definition := EnemyArchetypeDefinition.new()
	definition.id = &"b40_ranged_test"
	definition.scene = RANGED_ENEMY_SCENE
	definition.health_max = 16.0
	definition.move_speed = 110.0
	definition.collision_radius = 20.0
	definition.contact_damage = 12.0
	definition.experience_amount = 2
	definition.ranged_attack_range = 400.0
	definition.ranged_preferred_distance = 300.0
	definition.ranged_telegraph_duration = 0.5
	definition.ranged_attack_interval = 1.0
	definition.ranged_projectile_damage = 8.0
	definition.ranged_projectile_speed = 200.0
	definition.ranged_projectile_lifetime = 4.0
	definition.ranged_projectile_radius = 8.0

	controller.start_run(4242)
	_expect(
		enemy.apply_archetype_definition(definition),
		"apply_archetype_definition deve riuscire su un RangedEnemy valido."
	)
	enemy.configure_ranged(definition, projectile_parent)
	enemy.set_target(target)
	enemy.set_run_controller(controller)
	enemy.global_position = Vector2.ZERO
	target.global_position = Vector2(200.0, 0.0)

	# Il cooldown iniziale e' ranged_attack_interval: lo esaurisce per far
	# partire subito il telegraph con il bersaglio a tiro.
	enemy._advance_attack_cycle(definition.ranged_attack_interval)
	_expect(
		enemy.is_telegraph_active(),
		"Il tiratore deve avviare il telegraph quando il bersaglio e' a tiro."
	)
	enemy._advance_attack_cycle(definition.ranged_telegraph_duration * 0.5)
	_expect(
		enemy.get_active_projectile_count() == 0,
		"Nessun proiettile deve partire prima che il telegraph sia completo."
	)
	enemy._advance_attack_cycle(definition.ranged_telegraph_duration * 0.5 + 0.001)
	_expect(
		enemy.get_active_projectile_count() == 1,
		"Il tiratore deve sparare un proiettile a telegraph completo con il bersaglio a tiro."
	)

	# Seconda finestra: il bersaglio esce dal raggio prima che il telegraph finisca.
	enemy.clear_attack_runtime()
	enemy._advance_attack_cycle(definition.ranged_attack_interval)
	_expect(
		enemy.is_telegraph_active(),
		"Il secondo ciclo deve avviare comunque il telegraph con il bersaglio ancora a tiro."
	)
	target.global_position = Vector2(5000.0, 0.0)
	enemy._advance_attack_cycle(definition.ranged_telegraph_duration + 0.001)
	_expect(
		enemy.get_active_projectile_count() == 0,
		"Se il bersaglio esce dal raggio durante il telegraph, il colpo non deve partire."
	)

	controller.prepare_restart()
	paused = false
	fixture.queue_free()
	await process_frame


func _validate_splitter_generates_two_fragments() -> void:
	var profile := _make_test_profile()
	var built := await _build_spawner(555, profile, [])
	var spawner: EnemySpawner = built["spawner"]

	var fragment_def := EnemyArchetypeDefinition.new()
	fragment_def.id = &"b40_test_fragment"
	fragment_def.scene = CONFIGURABLE_ENEMY_SCENE
	fragment_def.health_max = 5.0
	fragment_def.move_speed = 90.0
	fragment_def.collision_radius = 10.0
	fragment_def.contact_damage = 5.0
	fragment_def.experience_amount = 1

	var splitter_def := EnemyArchetypeDefinition.new()
	splitter_def.id = &"b40_test_splitter"
	splitter_def.scene = SPLITTER_ENEMY_SCENE
	splitter_def.health_max = 20.0
	splitter_def.move_speed = 90.0
	splitter_def.collision_radius = 18.0
	splitter_def.contact_damage = 10.0
	splitter_def.experience_amount = 2
	splitter_def.split_fragment_definition = fragment_def
	splitter_def.split_fragment_count = 2
	_expect(splitter_def.is_valid(), "La definizione del divisore di test deve essere valida.")

	var splitter := spawner.spawn_archetype_instance(splitter_def, Vector2(120.0, 0.0))
	_expect(
		splitter is SplitterEnemy,
		"spawn_archetype_instance deve produrre un SplitterEnemy dalla scena assegnata."
	)

	var health := splitter.get_health_component() if splitter != null else null
	_expect(health != null, "Il divisore deve avere una HealthComponent valida.")
	if health != null:
		health.take_damage(9999.0)
	await process_frame

	var alive := spawner.get_spawned_enemies()
	_expect(
		alive.size() == 2,
		"La morte del divisore deve lasciare esattamente due frammenti vivi, trovati %d." % alive.size()
	)
	for fragment in alive:
		_expect(
			not (fragment is SplitterEnemy),
			"Un frammento non deve essere a sua volta un divisore (nessuna ricorsione)."
		)

	await _teardown_fixture(built)


func _validate_no_residue_after_restart() -> void:
	var profile := _make_test_profile()
	var built := await _build_spawner(909, profile, _make_test_archetypes())
	var spawner: EnemySpawner = built["spawner"]
	var controller: RunController = built["controller"]

	for _spawn_index in range(6):
		spawner.try_spawn_enemy()
	_expect(
		spawner.get_alive_count() > 0,
		"Il fixture deve aver generato almeno un nemico prima del restart."
	)

	controller.prepare_restart()
	await process_frame
	_expect(
		spawner.get_alive_count() == 0,
		"Dopo prepare_restart() non deve restare alcun nemico, inclusi quelli generati da archetipi."
	)

	paused = false
	(built["fixture"] as Node2D).queue_free()
	await process_frame


## B49: le texture pixel degli archetipi speciali devono essere assegnate,
## distinte fra loro, e un archetipo senza sprite_frames deve ricadere sul
## disegno procedurale invece di restare invisibile (fallback sicuro per un
## asset mancante).
func _validate_b49_archetype_textures() -> void:
	var archetype_paths := {
		"swarmer": "res://data/enemies/enemy_archetype_swarmer.tres",
		"armored": "res://data/enemies/enemy_archetype_armored.tres",
		"splitter": "res://data/enemies/enemy_archetype_splitter.tres",
		"ranged": "res://data/enemies/enemy_archetype_ranged.tres",
	}
	var seen_textures: Dictionary = {}
	for archetype_id: String in archetype_paths:
		var definition := load(archetype_paths[archetype_id]) as EnemyArchetypeDefinition
		_expect(
			definition != null and definition.sprite_frames != null,
			"L'archetipo '%s' deve avere uno sprite_frames B49 assegnato." % archetype_id
		)
		if definition == null or definition.sprite_frames == null:
			continue
		var frames := definition.sprite_frames
		_expect(
			frames.has_animation(&"base") and frames.get_frame_count(&"base") == 3,
			"L'archetipo '%s' deve avere l'animazione 'base' a tre pose." % archetype_id
		)
		var first_texture := frames.get_frame_texture(&"base", 0)
		_expect(
			first_texture != null,
			"L'archetipo '%s' deve avere una texture valida sul primo frame." % archetype_id
		)
		var atlas := first_texture as AtlasTexture
		var texture_key: String = (
			atlas.atlas.resource_path if atlas != null and atlas.atlas != null
			else str(first_texture)
		)
		_expect(
			not seen_textures.has(texture_key),
			(
				"L'archetipo '%s' condivide la texture con '%s': ogni archetipo speciale deve "
				% [archetype_id, str(seen_textures.get(texture_key))]
				+ "restare distinguibile."
			)
		)
		seen_textures[texture_key] = archetype_id

	var fragment_definition := load(
		"res://data/enemies/enemy_archetype_splitter_fragment.tres"
	) as EnemyArchetypeDefinition
	_expect(
		fragment_definition != null and fragment_definition.sprite_frames == null,
		"Il frammento del divisore non ha ancora un asset dedicato: deve restare senza sprite_frames."
	)

	var fixture := Node2D.new()
	var enemy := CONFIGURABLE_ENEMY_SCENE.instantiate() as BaseEnemy
	fixture.add_child(enemy)
	root.add_child(fixture)
	await process_frame
	_expect(
		not enemy.has_visual_sprite(),
		"Senza sprite_frames assegnato l'archetipo deve ricadere sul disegno procedurale."
	)
	_expect(
		fragment_definition != null and enemy.apply_archetype_definition(fragment_definition),
		"apply_archetype_definition deve riuscire anche senza sprite_frames (fallback sicuro)."
	)
	_expect(
		not enemy.has_visual_sprite(),
		"Un archetipo senza asset dedicato deve restare sul fallback procedurale dopo l'applicazione."
	)

	var swarmer_definition := load(archetype_paths["swarmer"]) as EnemyArchetypeDefinition
	_expect(
		swarmer_definition != null and enemy.apply_archetype_definition(swarmer_definition),
		"apply_archetype_definition deve riuscire con uno sprite_frames B49 assegnato."
	)
	_expect(
		enemy.has_visual_sprite(),
		"Con uno sprite_frames B49 assegnato l'archetipo deve usare la texture dedicata."
	)

	paused = false
	fixture.queue_free()
	await process_frame


func _make_test_profile() -> EnemySpawnProfile:
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
	profile.base_archetype_weight = 1.5
	return profile


func _make_test_archetypes() -> Array[EnemyArchetypeDefinition]:
	var swarmer := EnemyArchetypeDefinition.new()
	swarmer.id = &"b40_test_swarmer"
	swarmer.scene = CONFIGURABLE_ENEMY_SCENE
	swarmer.spawn_weight = 2.0
	swarmer.eligible_time_start = 0.0
	swarmer.eligible_time_end = 3600.0
	swarmer.health_max = 9.0
	swarmer.move_speed = 210.0
	swarmer.collision_radius = 14.0
	swarmer.contact_damage = 12.0
	swarmer.experience_amount = 1
	swarmer.silhouette_kind = 1

	var armored := EnemyArchetypeDefinition.new()
	armored.id = &"b40_test_armored"
	armored.scene = CONFIGURABLE_ENEMY_SCENE
	armored.spawn_weight = 1.0
	armored.eligible_time_start = 0.0
	armored.eligible_time_end = 3600.0
	armored.health_max = 54.0
	armored.move_speed = 70.0
	armored.collision_radius = 28.0
	armored.contact_damage = 26.0
	armored.experience_amount = 3
	armored.silhouette_kind = 2

	return [swarmer, armored]


func _build_spawner(
	seed_value: int,
	profile: EnemySpawnProfile,
	archetype_list: Array[EnemyArchetypeDefinition]
) -> Dictionary:
	var fixture := Node2D.new()
	var arena := ArenaLayout.new()
	arena.respect_display_safe_area = false
	var controller := RunController.new()
	controller.set_process(false)
	var target := PLAYER_SCENE.instantiate() as Player
	var enemy_parent := Node2D.new()
	var spawner := EnemySpawner.new()
	spawner.set_process(false)
	spawner.enemy_scene = ENEMY_SCENE
	spawner.spawn_profile = profile
	spawner.archetypes = archetype_list
	spawner.configure(controller, arena, target, enemy_parent)
	fixture.add_child(arena)
	fixture.add_child(controller)
	fixture.add_child(target)
	fixture.add_child(enemy_parent)
	fixture.add_child(spawner)
	root.add_child(fixture)
	await process_frame
	spawner.set_process(false)
	controller.set_process(false)
	var viewport_rect := arena.get_playfield_rect()
	target.global_position = viewport_rect.get_center()
	controller.start_run(seed_value)
	return {
		"fixture": fixture,
		"spawner": spawner,
		"controller": controller,
		"target": target,
		"enemy_parent": enemy_parent,
	}


func _teardown_fixture(built: Dictionary) -> void:
	var controller: RunController = built["controller"]
	var fixture: Node2D = built["fixture"]
	controller.prepare_restart()
	paused = false
	fixture.queue_free()
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	paused = false
	await process_frame
	if _failures.is_empty():
		print("B40_ENEMY_ARCHETYPES_SMOKE_OK")
		quit(0)
		return
	for failure in _failures:
		printerr(failure)
	printerr("B40_ENEMY_ARCHETYPES_SMOKE_FAIL count=%d" % _failures.size())
	quit(1)
