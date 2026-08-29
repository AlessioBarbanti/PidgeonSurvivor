extends GutTest

## Prototipo GUT: stesso flusso cross-sistema di
## tests/integration/_ability_ranks_smoke.gd (rank 1->5 su Magno), riscritto
## con le asserzioni native di GUT invece del marker su stdout.

const MOVEMENT_SLICE_SCENE := preload("res://scenes/game/movement_slice.tscn")
const INITIAL_VIEWPORT_SIZE := Vector2i(1280, 720)

var _movement_slice: Control
var _controller: RunController
var _ability: AbilityController
var _service: UpgradeService
var _experience: ExperienceSystem


func before_each() -> void:
	get_tree().root.content_scale_size = INITIAL_VIEWPORT_SIZE
	get_tree().root.size = INITIAL_VIEWPORT_SIZE
	await wait_process_frames(2)
	_movement_slice = MOVEMENT_SLICE_SCENE.instantiate() as Control
	add_child_autofree(_movement_slice)
	await wait_process_frames(2)

	_controller = _movement_slice.get_run_controller() as RunController
	_ability = _movement_slice.get_ability_controller() as AbilityController
	_service = _movement_slice.get_upgrade_service() as UpgradeService
	_experience = _movement_slice.get_experience_system() as ExperienceSystem

	_controller.set_process(false)
	_ability.set_process(false)
	var spawner := _movement_slice.get_enemy_spawner() as EnemySpawner
	if spawner != null:
		spawner.set_process(false)
	var player := _movement_slice.get_player() as Player
	if player != null:
		player.set_physics_process(false)
	var weapon := _movement_slice.get_weapon_controller() as WeaponController
	if weapon != null:
		weapon.set_process(false)


func _open_next_level() -> bool:
	var missing := _experience.get_experience_required() - _experience.experience_current
	return _experience.add_experience(maxi(missing, 1))


func _reroll_until_rank_card(ability_id: StringName) -> UpgradeDefinition:
	var expected_id := UpgradeDefinition.get_ability_rank_upgrade_id(ability_id)
	var active_level := _service.get_active_offer_level()
	for _attempt in 100:
		var offer := _service.generate_offer(active_level)
		for definition in offer:
			if definition.id == expected_id:
				return definition
	return null


func test_magno_ability_rank_flow_reaches_rank_five() -> void:
	var magno_id := &"magno_earthquake_shockwave"
	var magno_card_id := UpgradeDefinition.get_ability_rank_upgrade_id(magno_id)

	assert_eq(_service.get_equipped_ability_id(), magno_id, "La run iniziale deve filtrare le carte rank su Magno.")
	assert_eq(_service.get_rank(magno_card_id), 1, "L'abilita equipaggiata deve partire al rank 1.")
	assert_eq(_ability.get_ability_rank(), 1, "AbilityController deve partire dal profilo rank 1.")

	for target_rank in range(2, 6):
		assert_true(_open_next_level(), "La fixture deve aprire il level-up per il rank %d." % target_rank)
		var rank_card := _reroll_until_rank_card(magno_id)
		assert_not_null(rank_card, "La carta Magno deve essere eleggibile al rank %d." % target_rank)
		if rank_card == null:
			continue
		assert_true(_service.select_upgrade(rank_card.id), "La selezione rank %d deve essere atomica." % target_rank)
		assert_eq(_service.get_rank(magno_card_id), target_rank, "UpgradeService deve registrare il rank %d." % target_rank)
		assert_eq(_ability.get_ability_rank(), target_rank, "AbilityController deve applicare il rank %d." % target_rank)


func test_rank_up_during_cooldown_does_not_mutate_active_snapshot() -> void:
	var magno_id := &"magno_earthquake_shockwave"

	assert_true(_ability.try_activate(), "Il rank 1 deve poter attivare l'abilita.")
	var cooldown_before_rank_up := _ability.get_cooldown_total()

	assert_true(_open_next_level(), "La fixture deve aprire il level-up rank 2 durante il cooldown.")
	var rank_card := _reroll_until_rank_card(magno_id)
	assert_not_null(rank_card, "La carta rank 2 deve essere disponibile.")
	assert_true(_service.select_upgrade(rank_card.id), "La carta rank 2 deve essere selezionabile durante il cooldown.")

	assert_eq(_ability.get_ability_rank(), 2, "Il nuovo rank deve valere per la prossima attivazione.")
	assert_almost_eq(
		_ability.get_cooldown_total(),
		cooldown_before_rank_up,
		0.001,
		"Il cooldown gia iniziato deve conservare lo snapshot del rank precedente."
	)


func test_restart_resets_ranks_to_baseline() -> void:
	var magno_id := &"magno_earthquake_shockwave"
	var magno_card_id := UpgradeDefinition.get_ability_rank_upgrade_id(magno_id)

	assert_true(_open_next_level(), "La fixture deve aprire il level-up rank 2.")
	var rank_card := _reroll_until_rank_card(magno_id)
	assert_true(_service.select_upgrade(rank_card.id), "La selezione rank 2 deve riuscire.")

	_controller.prepare_restart()
	assert_true(_service.get_ranks().is_empty(), "Il restart deve rimuovere tutti i rank della run.")
	assert_eq(_service.get_rank(magno_card_id), 1, "La run successiva deve ripartire dal rank 1.")
	assert_eq(_ability.get_ability_rank(), 1, "AbilityController deve ripartire dal rank 1 dopo il restart.")
