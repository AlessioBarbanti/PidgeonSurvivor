class_name UpgradeService
extends Node

signal offer_generated(level: int, offers: Array[UpgradeDefinition])
signal offer_cleared(level: int)
signal upgrade_selected(
	definition: UpgradeDefinition,
	new_rank: int,
	level: int
)
signal ranks_reset()

const DEFAULT_OFFER_SIZE := 3
const RNG_STREAM_SALT := 0x4F1BBCDC

@export_range(1, 10, 1) var offer_size := DEFAULT_OFFER_SIZE

var _registry: UpgradeRegistry
var _run_controller: RunController
var _experience_system: ExperienceSystem
var _rng := RandomNumberGenerator.new()
var _run_seed := 0
var _draw_count := 0
var _current_offer: Array[UpgradeDefinition] = []
var _active_offer_level := 0
var _ranks: Dictionary = {}


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _exit_tree() -> void:
	_disconnect_dependencies()


func configure(
	registry: UpgradeRegistry,
	run_controller: RunController,
	experience_system: ExperienceSystem
) -> bool:
	_disconnect_dependencies()
	_registry = registry
	_run_controller = run_controller
	_experience_system = experience_system
	_connect_dependencies()
	if is_instance_valid(_run_controller) and _run_controller.get_state() != RunController.RunState.BOOT:
		reset_for_run(_run_controller.get_seed())
	return has_valid_configuration()


func has_valid_configuration() -> bool:
	return (
		is_instance_valid(_registry)
		and _registry.is_catalog_valid()
		and _registry.get_fallback_definitions().size() >= offer_size
		and is_instance_valid(_run_controller)
		and is_instance_valid(_experience_system)
		and _experience_system.get_run_controller() == _run_controller
		and offer_size == DEFAULT_OFFER_SIZE
	)


func reset_for_run(seed_value: int) -> void:
	var had_ranks := not _ranks.is_empty()
	_ranks.clear()
	_clear_current_offer()
	_run_seed = seed_value
	_draw_count = 0
	_rng.seed = seed_value ^ RNG_STREAM_SALT
	if had_ranks:
		ranks_reset.emit()


func generate_offer(level: int) -> Array[UpgradeDefinition]:
	_clear_current_offer()
	if level < 1 or not is_instance_valid(_registry):
		return []

	var primary_candidates := _registry.get_eligible_definitions(_ranks)
	var next_offer := _draw_weighted_without_replacement(
		primary_candidates,
		mini(offer_size, primary_candidates.size())
	)
	if next_offer.size() < offer_size:
		var fallback_candidates := _registry.get_eligible_definitions(_ranks, true)
		_remove_ids(fallback_candidates, next_offer)
		next_offer.append_array(
			_draw_weighted_without_replacement(
				fallback_candidates,
				offer_size - next_offer.size()
			)
		)

	_current_offer = next_offer
	_active_offer_level = level
	_draw_count += 1
	offer_generated.emit(level, get_current_offer())
	return get_current_offer()


func select_upgrade(upgrade_id: StringName) -> bool:
	if (
		not has_valid_configuration()
		or _current_offer.size() != offer_size
		or _active_offer_level <= 0
		or _run_controller.get_state() != RunController.RunState.LEVEL_UP
		or _experience_system.get_active_level_up_level() != _active_offer_level
	):
		return false

	var selected_definition: UpgradeDefinition
	for definition in _current_offer:
		if definition.id == upgrade_id:
			selected_definition = definition
			break
	if selected_definition == null or not selected_definition.is_eligible(_ranks):
		return false

	var selected_level := _active_offer_level
	var new_rank := get_rank(upgrade_id) + 1
	_ranks[upgrade_id] = new_rank
	_clear_current_offer()
	if _experience_system.complete_level_up():
		upgrade_selected.emit(selected_definition, new_rank, selected_level)
		return true

	# The guards above make this rollback exceptional. Effects are notified only
	# after progression commits, so a failed selection cannot leak runtime state.
	if new_rank <= 1:
		_ranks.erase(upgrade_id)
	else:
		_ranks[upgrade_id] = new_rank - 1
	return false


func get_current_offer() -> Array[UpgradeDefinition]:
	return _current_offer.duplicate()


func get_current_offer_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for definition in _current_offer:
		ids.append(definition.id)
	return ids


func get_rank(upgrade_id: StringName) -> int:
	return UpgradeDefinition.get_rank_from(_ranks, upgrade_id)


func get_ranks() -> Dictionary:
	return _ranks.duplicate()


func get_active_offer_level() -> int:
	return _active_offer_level


func get_run_seed() -> int:
	return _run_seed


func get_draw_count() -> int:
	return _draw_count


func get_registry() -> UpgradeRegistry:
	return _registry if is_instance_valid(_registry) else null


func get_run_controller() -> RunController:
	return _run_controller if is_instance_valid(_run_controller) else null


func get_experience_system() -> ExperienceSystem:
	return _experience_system if is_instance_valid(_experience_system) else null


func _draw_weighted_without_replacement(
	candidates: Array[UpgradeDefinition],
	requested_count: int
) -> Array[UpgradeDefinition]:
	var available := candidates.duplicate()
	var selected: Array[UpgradeDefinition] = []
	var count := mini(maxi(requested_count, 0), available.size())
	for _selection_index in count:
		var total_weight := 0.0
		for definition in available:
			total_weight += definition.weight
		var roll := _rng.randf() * total_weight
		var cumulative_weight := 0.0
		var selected_index := available.size() - 1
		for index in available.size():
			cumulative_weight += available[index].weight
			if roll < cumulative_weight:
				selected_index = index
				break
		selected.append(available[selected_index])
		available.remove_at(selected_index)
	return selected


func _remove_ids(
	candidates: Array[UpgradeDefinition],
	already_selected: Array[UpgradeDefinition]
) -> void:
	var selected_ids: Dictionary = {}
	for definition in already_selected:
		selected_ids[definition.id] = true
	for index in range(candidates.size() - 1, -1, -1):
		if selected_ids.has(candidates[index].id):
			candidates.remove_at(index)


func _clear_current_offer() -> void:
	if _current_offer.is_empty() and _active_offer_level == 0:
		return
	var cleared_level := _active_offer_level
	_current_offer.clear()
	_active_offer_level = 0
	offer_cleared.emit(cleared_level)


func _connect_dependencies() -> void:
	if is_instance_valid(_run_controller):
		if not _run_controller.run_started.is_connected(_on_run_started):
			_run_controller.run_started.connect(_on_run_started)
		if not _run_controller.run_ended.is_connected(_on_run_ended):
			_run_controller.run_ended.connect(_on_run_ended)
		if not _run_controller.restart_prepared.is_connected(_on_restart_prepared):
			_run_controller.restart_prepared.connect(_on_restart_prepared)
	if is_instance_valid(_experience_system):
		if not _experience_system.level_up_started.is_connected(_on_level_up_started):
			_experience_system.level_up_started.connect(_on_level_up_started)
		if not _experience_system.level_up_completed.is_connected(_on_level_up_completed):
			_experience_system.level_up_completed.connect(_on_level_up_completed)


func _disconnect_dependencies() -> void:
	if is_instance_valid(_run_controller):
		if _run_controller.run_started.is_connected(_on_run_started):
			_run_controller.run_started.disconnect(_on_run_started)
		if _run_controller.run_ended.is_connected(_on_run_ended):
			_run_controller.run_ended.disconnect(_on_run_ended)
		if _run_controller.restart_prepared.is_connected(_on_restart_prepared):
			_run_controller.restart_prepared.disconnect(_on_restart_prepared)
	if is_instance_valid(_experience_system):
		if _experience_system.level_up_started.is_connected(_on_level_up_started):
			_experience_system.level_up_started.disconnect(_on_level_up_started)
		if _experience_system.level_up_completed.is_connected(_on_level_up_completed):
			_experience_system.level_up_completed.disconnect(_on_level_up_completed)
	_registry = null
	_run_controller = null
	_experience_system = null


func _on_run_started(seed_value: int) -> void:
	reset_for_run(seed_value)


func _on_run_ended(_final_state: RunController.RunState, _run_time: float) -> void:
	_clear_current_offer()


func _on_restart_prepared() -> void:
	reset_for_run(0)


func _on_level_up_started(level: int, _pending_choices: int) -> void:
	generate_offer(level)


func _on_level_up_completed(level: int, _pending_choices: int) -> void:
	if _active_offer_level == level:
		_clear_current_offer()
