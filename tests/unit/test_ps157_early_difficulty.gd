extends GutTest

## PS-157 — Regressione del gate 0-5 minuti dopo la stabilizzazione di Player
## (PS-159/160/165) e archetipi (PS-123/124). Non introduce nuovi valori di
## bilanciamento (vedi Decisioni della card): blocca solo che la
## combinazione attuale resti punitiva al contatto deliberato e che l'arena
## conservi settori di calma nei primi due minuti. Il giudizio percettivo
## resta un gate manuale separato.

const PLAYER_SCENE: PackedScene = preload("res://scenes/actors/player.tscn")
const ENEMY_SCENE: PackedScene = preload("res://scenes/actors/base_enemy.tscn")
const DEFAULT_PROFILE: EnemySpawnProfile = preload(
	"res://data/spawn_profiles/default_enemy_spawn_profile.tres"
)
const EARLY_WINDOW_SAMPLE_SECONDS: Array[float] = [0.0, 30.0, 60.0, 90.0, 120.0]
const MAX_SECONDS_TO_LETHAL_CONTACT := 10.0
const MIN_HITS_TO_LETHAL_CONTACT := 2
const MAX_EARLY_SECTOR_CHANCE := 0.5
const FLOAT_TOLERANCE := 0.001


func test_sustained_contact_with_the_base_pigeon_deals_meaningful_bounded_damage() -> void:
	var fixture := Node2D.new()
	var controller := RunController.new()
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

	var health := player.get_health_component()
	var contact := enemy.get_contact_damage()
	assert_true(controller.start_run(15700), "La fixture deve poter avviare la run.")

	var hits := 0
	var elapsed_seconds := 0.0
	while health.is_alive() and elapsed_seconds <= MAX_SECONDS_TO_LETHAL_CONTACT:
		if contact.try_damage(player):
			hits += 1
			continue
		var step := health.invulnerability_remaining + FLOAT_TOLERANCE
		player._physics_process(step)
		elapsed_seconds += step

	assert_true(
		not health.is_alive(),
		(
			"Restare deliberatamente a contatto deve avere una conseguenza letale entro %.0fs."
			% MAX_SECONDS_TO_LETHAL_CONTACT
		)
	)
	assert_true(
		hits >= MIN_HITS_TO_LETHAL_CONTACT,
		"La vita base non deve svanire in una sola hit: servono almeno %d contatti." % MIN_HITS_TO_LETHAL_CONTACT
	)
	assert_true(
		elapsed_seconds <= MAX_SECONDS_TO_LETHAL_CONTACT,
		(
			"L'attraversamento ripetuto dell'orda deve costare la vita entro %.0fs, non essere gratuito."
			% MAX_SECONDS_TO_LETHAL_CONTACT
		)
	)


func test_early_window_keeps_calm_sectors_available_for_safe_traversal() -> void:
	for sample_seconds in EARLY_WINDOW_SAMPLE_SECONDS:
		var multi_chance := DEFAULT_PROFILE.get_effective_sector_multi_chance(sample_seconds)
		var spike_chance := DEFAULT_PROFILE.get_effective_sector_spike_chance(sample_seconds)
		assert_true(
			multi_chance <= MAX_EARLY_SECTOR_CHANCE,
			(
				"A %.0fs la probabilita' multi-settore (%.3f) non deve superare %.1f: deve restare una finestra sicura."
				% [sample_seconds, multi_chance, MAX_EARLY_SECTOR_CHANCE]
			)
		)
		assert_true(
			spike_chance <= MAX_EARLY_SECTOR_CHANCE,
			(
				"A %.0fs la probabilita' di picco 3-4 settori (%.3f) non deve superare %.1f nei primi due minuti."
				% [sample_seconds, spike_chance, MAX_EARLY_SECTOR_CHANCE]
			)
		)

	print("PS157_EARLY_DIFFICULTY_SMOKE_OK")
