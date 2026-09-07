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

## Emesso quando Barb propone una scelta dopo la sconfitta di un Boss (PS-012).
## `is_bonus` distingue le due modalità: sblocco Specialità (indici a zero) o
## selezione upgrade bonus di fallback (indici 1-based su `bonus_total`).
signal barb_offer_generated(
	offers: Array[UpgradeDefinition],
	is_bonus: bool,
	bonus_index: int,
	bonus_total: int
)
signal barb_offer_cleared()
signal barb_speciality_unlocked(definition: UpgradeDefinition, rank: int)
signal barb_bonus_upgrade_selected(
	definition: UpgradeDefinition,
	new_rank: int,
	bonus_index: int,
	bonus_total: int
)
signal barb_reward_completed()

const DEFAULT_OFFER_SIZE := 3
const RNG_STREAM_SALT := 0x4F1BBCDC
const BARB_RNG_STREAM_SALT := 0x8A21FEED
const BARB_OFFER_SIZE := 3
const BARB_BONUS_SELECTIONS := 2

enum BarbMode { NONE, SPECIALITY, BONUS }

@export_range(1, 10, 1) var offer_size := DEFAULT_OFFER_SIZE

var _registry: UpgradeRegistry
var _effect_registry: UpgradeEffectRegistry
var _run_controller: RunController
var _experience_system: ExperienceSystem
var _rng := RandomNumberGenerator.new()
var _run_seed := 0
var _draw_count := 0
var _current_offer: Array[UpgradeDefinition] = []
var _active_offer_level := 0
var _ranks: Dictionary = {}
var _equipped_ability_id: StringName
var _unlocked_specialities: Dictionary = {}
var _barb_rng := RandomNumberGenerator.new()
var _pending_barb_reward := false
var _barb_mode: BarbMode = BarbMode.NONE
var _barb_current_offer: Array[UpgradeDefinition] = []
var _barb_bonus_index := 0
var _barb_bonus_total := 0


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


## PS-120: cablaggio separato da configure(), non un suo parametro. L'effect
## registry si configura con il service già pronto (dipendenza inversa), e
## resta comunque opzionale qui: senza, il filtro di saturazione non si
## applica e il comportamento resta quello di sempre (usato dalle fixture di
## test isolate che non compongono un UpgradeEffectRegistry).
func set_effect_registry(effect_registry: UpgradeEffectRegistry) -> void:
	_effect_registry = effect_registry


func get_effect_registry() -> UpgradeEffectRegistry:
	return _effect_registry if is_instance_valid(_effect_registry) else null


func has_valid_configuration() -> bool:
	return (
		is_instance_valid(_registry)
		and _registry.is_catalog_valid()
		and _registry.get_repeatable_definitions().size() >= offer_size
		and is_instance_valid(_run_controller)
		and is_instance_valid(_experience_system)
		and _experience_system.get_run_controller() == _run_controller
		and offer_size == DEFAULT_OFFER_SIZE
	)


func reset_for_run(seed_value: int) -> void:
	var had_ranks := not _ranks.is_empty()
	var had_specialities := not _unlocked_specialities.is_empty()
	_ranks.clear()
	_unlocked_specialities.clear()
	_clear_current_offer()
	_clear_barb_offer()
	_barb_mode = BarbMode.NONE
	_barb_bonus_index = 0
	_barb_bonus_total = 0
	_pending_barb_reward = false
	_run_seed = seed_value
	_draw_count = 0
	_rng.seed = seed_value ^ RNG_STREAM_SALT
	_barb_rng.seed = seed_value ^ BARB_RNG_STREAM_SALT
	if had_ranks or had_specialities:
		ranks_reset.emit()


func generate_offer(level: int) -> Array[UpgradeDefinition]:
	_clear_current_offer()
	if level < 1 or not is_instance_valid(_registry):
		return []

	var candidates := _registry.get_eligible_definitions(_ranks)
	_filter_ability_rank_candidates(candidates)
	_filter_locked_speciality_candidates(candidates)
	_filter_saturated_repeatable_candidates(candidates)
	var next_offer := _draw_weighted_without_replacement(candidates, offer_size)

	_current_offer = next_offer
	_active_offer_level = level
	_draw_count += 1
	offer_generated.emit(level, get_current_offer())
	return get_current_offer()


func select_upgrade(upgrade_id: StringName) -> bool:
	if (
		not has_valid_configuration()
		# PS-120: non "esattamente offer_size". Il pool eleggibile può scendere
		# sotto offer_size (carte ripetibili sature filtrate, o un catalogo
		# isolato piccolo in test): un'offerta più corta ma non vuota resta
		# valida. Un'offerta vuota qui non può comunque accadere davvero
		# (_filter_saturated_repeatable_candidates non svuota mai il pool),
		# ma la guardia resta a protezione di qualunque altro filtro futuro.
		or _current_offer.is_empty()
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


## Richiesta dalla morte di un Boss: apre subito la scelta di Barb se la run è
## `RUNNING`, oppure resta in attesa che un level-up già in corso si chiuda
## (vedi `_on_run_state_changed_for_barb_reward`) prima di occupare lo stato.
func queue_barb_reward() -> void:
	_pending_barb_reward = true
	_try_start_barb_reward()


func is_barb_reward_active() -> bool:
	return _barb_mode != BarbMode.NONE


func is_barb_bonus_mode() -> bool:
	return _barb_mode == BarbMode.BONUS


func get_barb_bonus_index() -> int:
	return _barb_bonus_index


func get_barb_bonus_total() -> int:
	return _barb_bonus_total


func get_current_barb_offer() -> Array[UpgradeDefinition]:
	return _barb_current_offer.duplicate()


func get_current_barb_offer_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for definition in _barb_current_offer:
		ids.append(definition.id)
	return ids


func get_locked_speciality_definitions() -> Array[UpgradeDefinition]:
	if not is_instance_valid(_registry):
		return []
	var locked: Array[UpgradeDefinition] = []
	for definition in _registry.get_speciality_definitions():
		if not _unlocked_specialities.has(definition.id):
			locked.append(definition)
	return locked


func is_speciality_unlocked(upgrade_id: StringName) -> bool:
	return _unlocked_specialities.has(upgrade_id)


func get_unlocked_specialities() -> Array[StringName]:
	var ids: Array[StringName] = []
	for unlocked_id: Variant in _unlocked_specialities:
		ids.append(unlocked_id)
	return ids


func select_barb_speciality(upgrade_id: StringName) -> bool:
	if (
		_barb_mode != BarbMode.SPECIALITY
		or not is_instance_valid(_run_controller)
		or _run_controller.get_state() != RunController.RunState.BARB_REWARD
	):
		return false
	var selected_definition := _find_in_offer(_barb_current_offer, upgrade_id)
	if selected_definition == null:
		return false

	_unlocked_specialities[upgrade_id] = true
	_ranks[upgrade_id] = 1
	_clear_barb_offer()
	barb_speciality_unlocked.emit(selected_definition, 1)
	# UpgradeEffectRegistry applica gli effetti solo in risposta a questo
	# segnale: senza riusarlo lo sblocco assegnerebbe il rank senza attivarlo.
	upgrade_selected.emit(selected_definition, 1, 0)
	_finish_barb_reward()
	return true


func select_barb_bonus_upgrade(upgrade_id: StringName) -> bool:
	if (
		_barb_mode != BarbMode.BONUS
		or not is_instance_valid(_run_controller)
		or _run_controller.get_state() != RunController.RunState.BARB_REWARD
	):
		return false
	var selected_definition := _find_in_offer(_barb_current_offer, upgrade_id)
	if selected_definition == null or not selected_definition.is_eligible(_ranks):
		return false

	var new_rank := get_rank(upgrade_id) + 1
	_ranks[upgrade_id] = new_rank
	var completed_index := _barb_bonus_index
	var total := _barb_bonus_total
	_clear_barb_offer()
	barb_bonus_upgrade_selected.emit(selected_definition, new_rank, completed_index, total)
	upgrade_selected.emit(selected_definition, new_rank, 0)
	if completed_index < total:
		_barb_bonus_index = completed_index + 1
		_generate_bonus_offer()
	else:
		_finish_barb_reward()
	return true


func get_current_offer() -> Array[UpgradeDefinition]:
	return _current_offer.duplicate()


func get_current_offer_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for definition in _current_offer:
		ids.append(definition.id)
	return ids


func get_rank(upgrade_id: StringName) -> int:
	var definition := _registry.resolve_definition(upgrade_id) if is_instance_valid(_registry) else null
	return (
		definition.get_current_rank(_ranks)
		if definition != null
		else UpgradeDefinition.get_rank_from(_ranks, upgrade_id)
	)


func set_equipped_ability_id(ability_id: StringName) -> bool:
	if not ability_id.is_empty() and not UpgradeDefinition.is_valid_id(ability_id):
		return false
	_equipped_ability_id = ability_id
	_clear_current_offer()
	return true


func get_equipped_ability_id() -> StringName:
	return _equipped_ability_id


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
	requested_count: int,
	rng: RandomNumberGenerator = null
) -> Array[UpgradeDefinition]:
	var draw_rng := rng if rng != null else _rng
	var available := candidates.duplicate()
	var selected: Array[UpgradeDefinition] = []
	var count := mini(maxi(requested_count, 0), available.size())
	for _selection_index in count:
		var total_weight := 0.0
		for definition in available:
			total_weight += definition.weight
		var roll := draw_rng.randf() * total_weight
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


func _filter_ability_rank_candidates(candidates: Array[UpgradeDefinition]) -> void:
	for index in range(candidates.size() - 1, -1, -1):
		var definition := candidates[index]
		if definition.effect_id != &"ability_rank":
			continue
		var ability_id := StringName(str(definition.effect_parameters.get("ability_id", "")))
		if ability_id != _equipped_ability_id:
			candidates.remove_at(index)


func _filter_locked_speciality_candidates(candidates: Array[UpgradeDefinition]) -> void:
	for index in range(candidates.size() - 1, -1, -1):
		var definition := candidates[index]
		if definition.is_speciality and not _unlocked_specialities.has(definition.id):
			candidates.remove_at(index)


## PS-120: una carta ripetibile che ha già raggiunto il proprio tetto/pavimento
## runtime esce dal pool, come una carta non ripetibile a rango massimo. Non
## svuota mai l'offerta del tutto: se ogni candidato residuo risultasse
## saturo (cataloghi molto ristretti, come nelle fixture isolate dei test, o
## un tardo endgame che ha esaurito ogni carta disponibile), meglio riproporre
## carte sature che lasciare un level-up senza nulla da scegliere.
func _filter_saturated_repeatable_candidates(candidates: Array[UpgradeDefinition]) -> void:
	if not is_instance_valid(_effect_registry):
		return
	var saturated_indices: Array[int] = []
	for index in candidates.size():
		var definition := candidates[index]
		if _effect_registry.is_rank_saturated(definition, get_rank(definition.id)):
			saturated_indices.append(index)
	if saturated_indices.size() >= candidates.size():
		return
	for reverse_index in range(saturated_indices.size() - 1, -1, -1):
		candidates.remove_at(saturated_indices[reverse_index])


func _find_in_offer(
	offer: Array[UpgradeDefinition],
	upgrade_id: StringName
) -> UpgradeDefinition:
	for definition in offer:
		if definition.id == upgrade_id:
			return definition
	return null


func _try_start_barb_reward() -> void:
	if (
		not _pending_barb_reward
		or not is_instance_valid(_run_controller)
		or not _run_controller.is_running()
	):
		return
	if not _run_controller.request_barb_reward():
		return
	_pending_barb_reward = false
	_start_barb_reward_session()


func _start_barb_reward_session() -> void:
	var locked := get_locked_speciality_definitions()
	if not locked.is_empty():
		_barb_mode = BarbMode.SPECIALITY
		_barb_current_offer = _draw_weighted_without_replacement(
			locked, mini(BARB_OFFER_SIZE, locked.size()), _barb_rng
		)
		barb_offer_generated.emit(get_current_barb_offer(), false, 0, 0)
	else:
		_barb_mode = BarbMode.BONUS
		_barb_bonus_index = 1
		_barb_bonus_total = BARB_BONUS_SELECTIONS
		_generate_bonus_offer()


func _generate_bonus_offer() -> void:
	var candidates := _registry.get_eligible_definitions(_ranks)
	_filter_ability_rank_candidates(candidates)
	_filter_locked_speciality_candidates(candidates)
	_filter_saturated_repeatable_candidates(candidates)
	_barb_current_offer = _draw_weighted_without_replacement(
		candidates, mini(offer_size, candidates.size()), _barb_rng
	)
	barb_offer_generated.emit(get_current_barb_offer(), true, _barb_bonus_index, _barb_bonus_total)


func _clear_barb_offer() -> void:
	if _barb_current_offer.is_empty():
		return
	_barb_current_offer.clear()
	barb_offer_cleared.emit()


func _finish_barb_reward() -> void:
	_barb_mode = BarbMode.NONE
	_barb_bonus_index = 0
	_barb_bonus_total = 0
	if is_instance_valid(_run_controller):
		_run_controller.complete_barb_reward()
	barb_reward_completed.emit()


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
		if not _run_controller.state_changed.is_connected(_on_run_state_changed_for_barb_reward):
			_run_controller.state_changed.connect(_on_run_state_changed_for_barb_reward)
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
		if _run_controller.state_changed.is_connected(_on_run_state_changed_for_barb_reward):
			_run_controller.state_changed.disconnect(_on_run_state_changed_for_barb_reward)
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
	_clear_barb_offer()
	_barb_mode = BarbMode.NONE
	_pending_barb_reward = false


func _on_restart_prepared() -> void:
	reset_for_run(0)


func _on_level_up_started(level: int, _pending_choices: int) -> void:
	generate_offer(level)


func _on_run_state_changed_for_barb_reward(
	_previous_state: RunController.RunState,
	current_state: RunController.RunState
) -> void:
	if current_state == RunController.RunState.RUNNING:
		_try_start_barb_reward()


func _on_level_up_completed(level: int, _pending_choices: int) -> void:
	if _active_offer_level == level:
		_clear_current_offer()
