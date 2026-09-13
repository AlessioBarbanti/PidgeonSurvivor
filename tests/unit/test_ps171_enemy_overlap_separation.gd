extends GutGameplayTest

## PS-171: i nemici non collidono mai fisicamente fra loro
## (collision_layer = 0 su tutte le scene, per scelta esplicita — vedi
## Decisioni PS-171) e l'unica dispersione precedente (_pursuit_offset, B37)
## non basta quando molti RangedEnemy si fermano tutti alla stessa
## ranged_preferred_distance dal bersaglio: il proprietario si e' trovato
## circa 1000 tiratori impilati sullo stesso punto. Questo file verifica la
## respinta leggera introdotta in BaseEnemy._compute_separation_velocity().

const RANGED_ENEMY_SCENE: PackedScene = preload("res://scenes/actors/ranged_enemy.tscn")
const BASE_ENEMY_SCENE: PackedScene = preload("res://scenes/actors/base_enemy.tscn")
const RANGED_DEFINITION: EnemyArchetypeDefinition = preload("res://data/enemies/enemy_archetype_ranged.tres")

const ENEMY_COUNT := 32
const PHYSICS_DELTA := 1.0 / 60.0
const SETTLE_TICKS := 240
## Piccolo raggio di innesco, dello stesso ordine di grandezza del
## _pursuit_offset assegnato dallo spawner: da solo non basta a separare un
## gruppo numeroso, che e' esattamente il difetto segnalato.
const INITIAL_CLUSTER_RADIUS := 6.0


func test_dense_ranged_cluster_stops_overlapping_after_settling() -> void:
	var fixture := Node2D.new()
	var target := Node2D.new()
	var controller := RunController.new()
	controller.set_process(false)
	fixture.add_child(target)
	fixture.add_child(controller)
	add_child_autofree(fixture)
	await wait_process_frames(1)

	controller.start_run(7331)
	target.global_position = Vector2.ZERO
	var target_start_position := target.global_position

	var enemies := _spawn_ranged_cluster(fixture, target, controller, ENEMY_COUNT)
	await wait_process_frames(1)

	await _settle(enemies, SETTLE_TICKS)

	var minimum_distance := _minimum_pairwise_distance(enemies)
	var required_distance: float = enemies[0].collision_radius * 1.5
	assert_true(
		minimum_distance >= required_distance,
		(
			"Dopo l'assestamento nessuna coppia di tiratori deve restare sotto %.1f px (osservato %.2f)."
			% [required_distance, minimum_distance]
		)
	)
	assert_vector_near(
		target.global_position,
		target_start_position,
		"La respinta fra nemici non deve mai spostare il bersaglio (Player)."
	)

	controller.prepare_restart()
	print("PS171_ENEMY_OVERLAP_SEPARATION_SMOKE_OK")


## Con un solo nemico, senza alcun affollamento, il percorso verso il
## bersaglio deve restare identico a prima di PS-171: la respinta interviene
## solo quando i cerchi di collisione si sovrappongono davvero.
func test_lone_enemy_pathing_is_unaffected() -> void:
	var fixture := Node2D.new()
	var target := Node2D.new()
	var controller := RunController.new()
	controller.set_process(false)
	var enemy := BASE_ENEMY_SCENE.instantiate() as BaseEnemy
	fixture.add_child(target)
	fixture.add_child(controller)
	fixture.add_child(enemy)
	add_child_autofree(fixture)
	await wait_process_frames(1)
	enemy.set_physics_process(false)

	controller.start_run(1)
	enemy.global_position = Vector2.ZERO
	target.global_position = Vector2(200.0, 0.0)
	enemy.set_target(target)
	enemy.set_run_controller(controller)
	enemy.add_to_group(&"enemies")

	enemy._physics_process(PHYSICS_DELTA)
	assert_vector_near(
		enemy.velocity,
		Vector2.RIGHT * enemy.move_speed,
		"Senza altri nemici vicini la direzione verso il bersaglio deve restare invariata.",
		FLOAT_TOLERANCE
	)

	controller.prepare_restart()


## A parita' di seed e sequenza di costruzione, l'assestamento deve produrre
## esattamente la stessa disposizione finale: nessuna sorgente di
## non-determinismo (RNG, ordine di iterazione) deve intromettersi.
func test_same_setup_produces_identical_settled_positions() -> void:
	var positions_a := await _run_cluster_and_collect_positions(9042)
	var positions_b := await _run_cluster_and_collect_positions(9042)
	assert_eq(positions_a.size(), ENEMY_COUNT, "La prima simulazione deve produrre tutte le posizioni attese.")
	assert_eq(positions_b.size(), ENEMY_COUNT, "La seconda simulazione deve produrre tutte le posizioni attese.")
	for index in mini(positions_a.size(), positions_b.size()):
		assert_vector_near(
			positions_a[index],
			positions_b[index],
			"La posizione assestata del tiratore #%d deve restare deterministica." % index,
			FLOAT_TOLERANCE
		)


## Non usa add_child_autofree(): l'autofree di GUT rimanda la pulizia alla
## fine dell'intero test, ma questa funzione viene chiamata due volte nello
## stesso test per confrontare due run — senza una pulizia immediata, i
## nemici della prima run resterebbero nel gruppo "enemies" durante la
## seconda, alterando la griglia di separazione condivisa e rompendo il
## confronto deterministico.
func _run_cluster_and_collect_positions(seed_value: int) -> Array[Vector2]:
	var fixture := Node2D.new()
	var target := Node2D.new()
	var controller := RunController.new()
	controller.set_process(false)
	fixture.add_child(target)
	fixture.add_child(controller)
	add_child(fixture)
	await wait_process_frames(1)

	controller.start_run(seed_value)
	target.global_position = Vector2.ZERO

	var enemies := _spawn_ranged_cluster(fixture, target, controller, ENEMY_COUNT)
	await wait_process_frames(1)
	await _settle(enemies, SETTLE_TICKS)

	var positions: Array[Vector2] = []
	for enemy in enemies:
		positions.append(enemy.global_position)
	controller.prepare_restart()
	fixture.queue_free()
	await wait_process_frames(2)
	return positions


## Ricrea l'esatto scenario segnalato: molti RangedEnemy configurati con lo
## stesso archetipo, tutti gia' fermi alla loro ranged_preferred_distance
## (_compute_chase_offset() ritorna zero), a partire da un piccolo cluster
## come quello che un _pursuit_offset insufficiente lascerebbe irrisolto.
func _spawn_ranged_cluster(
	fixture: Node2D,
	target: Node2D,
	controller: RunController,
	count: int
) -> Array[BaseEnemy]:
	var enemies: Array[BaseEnemy] = []
	var preferred_distance := RANGED_DEFINITION.ranged_preferred_distance
	for index in count:
		var enemy := RANGED_ENEMY_SCENE.instantiate() as RangedEnemy
		fixture.add_child(enemy)
		enemy.set_physics_process(false)
		enemy.apply_archetype_definition(RANGED_DEFINITION)
		enemy.configure_ranged(RANGED_DEFINITION, null)
		var angle := TAU * float(index) / float(count)
		var jitter := Vector2.RIGHT.rotated(angle) * INITIAL_CLUSTER_RADIUS
		enemy.global_position = (
			target.global_position + Vector2(preferred_distance, 0.0) + jitter
		)
		enemy.set_target(target)
		enemy.set_run_controller(controller)
		enemy.add_to_group(&"enemies")
		enemies.append(enemy)
	return enemies


func _settle(enemies: Array[BaseEnemy], ticks: int) -> void:
	for _tick in ticks:
		for enemy in enemies:
			enemy._physics_process(PHYSICS_DELTA)
		await wait_physics_frames(1)


func _minimum_pairwise_distance(enemies: Array[BaseEnemy]) -> float:
	var minimum_distance := INF
	for i in enemies.size():
		for j in range(i + 1, enemies.size()):
			minimum_distance = minf(
				minimum_distance,
				enemies[i].global_position.distance_to(enemies[j].global_position)
			)
	return minimum_distance
