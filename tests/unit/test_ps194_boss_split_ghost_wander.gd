extends GutGameplayTest

## PS-194: la copia fantasma dello specchio passeggia dentro un anello invece
## di orbitare a raggio fisso. Stesso seed di run, stesso percorso; distanza
## sempre entro i limiti dichiarati nella card; nessuna seconda entita'
## generata (contratto PS-127 intatto).

const BOSS_THRESHOLD_SECONDS := 120.01
const SAMPLE_STEP := 0.05
const SAMPLE_COUNT := 120
## Sei secondi di passeggiata devono produrre un tragitto vero, non un punto
## fermo ne' un cerchio a raggio costante.
const MIN_PATH_LENGTH := 100.0
const MIN_RADIUS_SPREAD := 20.0


func test_split_ghost_wanders_inside_the_declared_ring_and_repeats_with_the_seed() -> void:
	var slice := await instantiate_movement_slice()
	var controller := slice.get_run_controller() as RunController
	var encounter := slice.get_boss_encounter() as BossEncounter
	assert_true(controller != null and encounter != null)
	if controller == null or encounter == null:
		return
	controller.set_process(false)
	encounter.evil_boss_chance = 0.0
	controller._process(BOSS_THRESHOLD_SECONDS)
	var boss := encounter.get_active_boss()
	var definition := encounter.get_active_definition()
	assert_true(boss != null and definition != null and not definition.is_evil_variant())
	if boss == null or definition == null:
		return
	assert_true(encounter.complete_intro())
	boss.set_physics_process(false)
	boss.move_speed = 0.0

	var boss_health := boss.get_health_component()
	assert_true(boss.take_damage(boss_health.health_max * 0.5))
	assert_true(boss.is_split_active(), "Lo specchio deve attivarsi a meta' vita, come prima della card.")

	var first_path := _sample_wander(boss)

	var health_components := 0
	for child in boss.get_children():
		if child is HealthComponent:
			health_components += 1
	assert_eq(health_components, 1, "PS-127: lo specchio non genera un secondo HealthComponent.")
	assert_eq(boss.get_active_decoy_count(), 0, "La copia non e' un'entita': nessun clone nella scena.")
	assert_same(encounter.get_active_boss(), boss, "Resta un solo Boss attivo nell'incontro.")

	var minimum_radius := INF
	var maximum_radius := 0.0
	var path_length := 0.0
	var previous := Vector2.ZERO
	for index in first_path.size():
		var offset := first_path[index]
		var radius := offset.length()
		assert_between(
			radius,
			definition.split_ghost_min_distance - FLOAT_TOLERANCE,
			definition.split_ghost_distance + FLOAT_TOLERANCE,
			"La copia resta nell'anello dichiarato: mai sopra il Boss, mai staccata dall'incontro."
		)
		minimum_radius = minf(minimum_radius, radius)
		maximum_radius = maxf(maximum_radius, radius)
		if index > 0:
			path_length += offset.distance_to(previous)
		previous = offset
	assert_gt(path_length, MIN_PATH_LENGTH, "L'offset varia nel tempo: la copia si sposta davvero.")
	assert_gt(
		maximum_radius - minimum_radius, MIN_RADIUS_SPREAD,
		"Il raggio varia: non e' piu' l'orbita circolare a raggio fisso."
	)

	boss.reset_attack_cycle()
	assert_false(boss.is_split_active(), "Il restart del ciclo spegne lo specchio, come prima della card.")
	assert_eq(boss.get_split_ghost_offset(), Vector2.ZERO)
	assert_true(boss.take_damage(1.0))
	assert_true(boss.is_split_active(), "Sotto soglia lo specchio si riattiva.")
	assert_eq(
		_sample_wander(boss), first_path,
		"Stesso seed di run, stesso percorso della copia: il wander resta riproducibile."
	)

	controller.prepare_restart()
	slice.free()
	print("PS194_BOSS_SPLIT_GHOST_WANDER_SMOKE_OK")


func _sample_wander(boss: FirstBoss) -> PackedVector2Array:
	var samples := PackedVector2Array()
	for index in SAMPLE_COUNT:
		boss._advance_split_ghost(SAMPLE_STEP)
		samples.append(boss.get_split_ghost_offset())
	return samples
