class_name AbilityController
extends Node

const DEBUG_COOLDOWN_ARGUMENT := "--debug-ability-cooldown"
const MINIMUM_DEBUG_COOLDOWN := 0.01

signal cooldown_changed(cooldown_remaining: float, cooldown_total: float)
signal readiness_changed(is_ready: bool)
signal ability_activated(definition: AbilityDefinition)
signal definition_changed(definition: AbilityDefinition)
## Rilancio del tell di Cosplay: l'estrazione anticipata puo' cambiare anche
## quando la ricarica non emette nulla (per esempio all'avvio della run).
signal pending_cosplay_changed(ability_id: StringName)
## PS-094: cariche disponibili sull'abilità attiva, per l'indicatore HUD a
## pallini. Affianca cooldown_changed/readiness_changed invece di sostituirli:
## quei due restano il "prossimo rilancio", questo copre "quante copie ho".
signal charges_changed(available_charges: int, max_charges: int)

@export var ability_definition: AbilityDefinition

var _run_controller: RunController
var _input_router: InputRouter
var _effect_registry: AbilityEffectRegistry
var _source: Node2D
var _ready_state := true
var _debug_cooldown_override := 0.0
var _activation_definition: AbilityDefinition
var _ability_rank := 1
var _upgrade_cooldown_multiplier := 1.0
var _max_charges := 1
var _available_charges := 1
var _charge_cooldown_multiplier := 1.0
var _charge_timer_remaining: Array[float] = []
var _charge_timer_total: Array[float] = []


func _exit_tree() -> void:
	_disconnect_dependencies()


func _process(delta: float) -> void:
	if (
		_charge_timer_remaining.is_empty()
		or not is_instance_valid(_run_controller)
		or not _run_controller.is_running()
	):
		return

	var previous_remaining := get_cooldown_remaining()
	var safe_delta := maxf(delta, 0.0)
	var recharged_count := 0
	var index := 0
	while index < _charge_timer_remaining.size():
		_charge_timer_remaining[index] = maxf(_charge_timer_remaining[index] - safe_delta, 0.0)
		if _charge_timer_remaining[index] <= 0.0:
			_charge_timer_remaining.remove_at(index)
			_charge_timer_total.remove_at(index)
			recharged_count += 1
		else:
			index += 1
	if recharged_count > 0:
		_available_charges = mini(_available_charges + recharged_count, _max_charges)
		charges_changed.emit(_available_charges, _max_charges)
	var next_remaining := get_cooldown_remaining()
	if not is_equal_approx(previous_remaining, next_remaining):
		cooldown_changed.emit(next_remaining, get_cooldown_total())
	_update_ready_state()


func configure(
	run_controller: RunController,
	input_router: InputRouter,
	effect_registry: AbilityEffectRegistry,
	source: Node2D = null
) -> bool:
	_disconnect_dependencies()
	_run_controller = run_controller
	_input_router = input_router
	_effect_registry = effect_registry
	_source = source if is_instance_valid(source) else get_parent() as Node2D
	_debug_cooldown_override = _read_debug_cooldown_override()
	if not _apply_rank_snapshot(1):
		return false
	if not _has_valid_dependencies():
		return false
	if not _effect_registry.register_definition(ability_definition):
		return false

	_input_router.active_ability_requested.connect(try_activate)
	_run_controller.restart_prepared.connect(_on_restart_prepared)
	_effect_registry.pending_cosplay_changed.connect(_on_pending_cosplay_changed)
	reset_for_run()
	return true


func try_activate() -> bool:
	if (
		not _has_valid_dependencies()
		or not _run_controller.is_running()
		or _available_charges <= 0
		or _activation_definition == null
		or not _effect_registry.can_execute(_activation_definition)
	):
		return false

	var activation_snapshot := _activation_definition.resolve_rank(_ability_rank)
	if activation_snapshot == null:
		return false
	var effect := _effect_registry.execute_effect(activation_snapshot, _source)
	if effect == null:
		return false

	_consume_charge()
	ability_activated.emit(activation_snapshot)
	return true


func _consume_charge() -> void:
	_available_charges -= 1
	var charge_cooldown_total := _resolve_ready_cooldown_total()
	_charge_timer_remaining.append(charge_cooldown_total)
	_charge_timer_total.append(charge_cooldown_total)
	cooldown_changed.emit(get_cooldown_remaining(), get_cooldown_total())
	charges_changed.emit(_available_charges, _max_charges)
	_update_ready_state()


func equip_definition(definition: AbilityDefinition) -> bool:
	if definition == null or not definition.is_valid():
		return false
	if is_instance_valid(_effect_registry) and not _effect_registry.register_definition(definition):
		return false
	ability_definition = definition
	if not _apply_rank_snapshot(1):
		return false
	reset_for_run()
	definition_changed.emit(ability_definition)
	return true


func apply_rank(rank: int) -> bool:
	if rank < 1 or rank > 5 or ability_definition == null:
		return false
	if not _apply_rank_snapshot(rank):
		return false
	cooldown_changed.emit(get_cooldown_remaining(), get_cooldown_total())
	definition_changed.emit(ability_definition)
	return true


func reset_rank_for_run() -> bool:
	if not _apply_rank_snapshot(1):
		return false
	reset_for_run()
	definition_changed.emit(ability_definition)
	return true


func reset_for_run() -> void:
	_prepare_pending_cosplay()
	var was_ready := _ready_state
	_charge_timer_remaining.clear()
	_charge_timer_total.clear()
	_available_charges = _max_charges
	_ready_state = true
	cooldown_changed.emit(get_cooldown_remaining(), get_cooldown_total())
	charges_changed.emit(_available_charges, _max_charges)
	if not was_ready:
		readiness_changed.emit(true)


func get_definition() -> AbilityDefinition:
	return ability_definition


## Abilita' che il prossimo Cosplay eseguira', vuota per ogni altro profilo.
## E' il dato che rende l'attiva di Lollo pianificabile invece che casuale al
## momento del lancio.
func get_pending_cosplay_ability_id() -> StringName:
	if not is_instance_valid(_effect_registry):
		return &""
	return _effect_registry.get_pending_cosplay_ability_id()


## Icona dell'abilita' che il prossimo Cosplay eseguira', null per ogni altro
## profilo. E' il tell HUD di B44: il pulsante icona resta senza nome (B18K),
## quindi la pianificabilita' passa dal mostrare l'icona del bersaglio invece
## di quella generica di Cosplay.
func get_pending_cosplay_icon() -> Texture2D:
	var pending_id := get_pending_cosplay_ability_id()
	if pending_id.is_empty() or not is_instance_valid(_effect_registry):
		return null
	var pending_definition := _effect_registry.resolve_definition(pending_id)
	return pending_definition.icon if pending_definition != null else null


func _prepare_pending_cosplay() -> void:
	if not is_instance_valid(_effect_registry) or ability_definition == null:
		return
	_effect_registry.prepare_pending_cosplay(ability_definition)


func get_activation_definition() -> AbilityDefinition:
	return _activation_definition


func get_ability_rank() -> int:
	return _ability_rank


func get_run_controller() -> RunController:
	return _run_controller if is_instance_valid(_run_controller) else null


func get_input_router() -> InputRouter:
	return _input_router if is_instance_valid(_input_router) else null


func get_effect_registry() -> AbilityEffectRegistry:
	return _effect_registry if is_instance_valid(_effect_registry) else null


func get_source() -> Node2D:
	return _source if is_instance_valid(_source) else null


func get_cooldown_remaining() -> float:
	var index := _index_of_soonest_charge()
	return _charge_timer_remaining[index] if index >= 0 else 0.0


func get_cooldown_total() -> float:
	var index := _index_of_soonest_charge()
	return _charge_timer_total[index] if index >= 0 else _resolve_ready_cooldown_total()


func is_cooldown_ready() -> bool:
	return _available_charges > 0


func get_available_charges() -> int:
	return _available_charges


func get_max_charges() -> int:
	return _max_charges


func set_upgrade_cooldown_multiplier(multiplier: float) -> bool:
	if not is_finite(multiplier) or multiplier <= 0.0:
		return false
	_upgrade_cooldown_multiplier = multiplier
	return true


func reset_upgrade_cooldown_multiplier() -> void:
	_upgrade_cooldown_multiplier = 1.0


func get_upgrade_cooldown_multiplier() -> float:
	return _upgrade_cooldown_multiplier


## PS-094: configura il modello a cariche multiple della Specialità di Barb.
## Le cariche già in ricarica non cambiano durata a ritroso: la nuova
## velocità vale solo per i consumi successivi, come già fa il moltiplicatore
## di ricarica ordinario. Se il personaggio era a cariche piene, il nuovo
## tetto viene concesso subito pieno; se era a metà ricarica, il tetto sale
## ma la carica in corso continua senza scorciatoie.
func set_charge_configuration(max_charges: int, cooldown_multiplier: float) -> bool:
	if max_charges < 1 or not is_finite(cooldown_multiplier) or cooldown_multiplier <= 0.0:
		return false
	var was_full := _available_charges >= _max_charges
	_max_charges = max_charges
	_charge_cooldown_multiplier = cooldown_multiplier
	_available_charges = _max_charges if was_full else mini(_available_charges, _max_charges)
	charges_changed.emit(_available_charges, _max_charges)
	return true


func reset_charge_configuration() -> void:
	set_charge_configuration(1, 1.0)


func _has_valid_dependencies() -> bool:
	return (
		ability_definition != null
		and ability_definition.is_valid()
		and _activation_definition != null
		and _activation_definition.is_valid()
		and is_instance_valid(_run_controller)
		and is_instance_valid(_input_router)
		and is_instance_valid(_effect_registry)
		and is_instance_valid(_source)
	)


func _update_ready_state() -> void:
	var next_ready := is_cooldown_ready()
	if next_ready == _ready_state:
		return
	_ready_state = next_ready
	readiness_changed.emit(_ready_state)


func _disconnect_dependencies() -> void:
	if (
		is_instance_valid(_input_router)
		and _input_router.active_ability_requested.is_connected(try_activate)
	):
		_input_router.active_ability_requested.disconnect(try_activate)
	if (
		is_instance_valid(_run_controller)
		and _run_controller.restart_prepared.is_connected(_on_restart_prepared)
	):
		_run_controller.restart_prepared.disconnect(_on_restart_prepared)
	if (
		is_instance_valid(_effect_registry)
		and _effect_registry.pending_cosplay_changed.is_connected(_on_pending_cosplay_changed)
	):
		_effect_registry.pending_cosplay_changed.disconnect(_on_pending_cosplay_changed)
	_run_controller = null
	_input_router = null
	_effect_registry = null
	_source = null


func _on_pending_cosplay_changed(ability_id: StringName) -> void:
	pending_cosplay_changed.emit(ability_id)


func _on_restart_prepared() -> void:
	if not reset_rank_for_run():
		push_error("AbilityController: impossibile ripristinare il rank 1.")


func _read_debug_cooldown_override() -> float:
	for argument in OS.get_cmdline_args():
		if not argument.begins_with(DEBUG_COOLDOWN_ARGUMENT + "="):
			continue
		var value_text := argument.trim_prefix(DEBUG_COOLDOWN_ARGUMENT + "=")
		var value := value_text.to_float()
		if is_finite(value) and value >= MINIMUM_DEBUG_COOLDOWN:
			return value
	return 0.0


func _apply_rank_snapshot(rank: int) -> bool:
	var resolved := ability_definition.resolve_rank(rank) if ability_definition != null else null
	if resolved == null:
		return false
	_activation_definition = resolved
	_ability_rank = rank
	return true


func _resolve_ready_cooldown_total() -> float:
	if _debug_cooldown_override > 0.0:
		return _debug_cooldown_override
	return (
		_activation_definition.cooldown_seconds
		* _upgrade_cooldown_multiplier
		* _charge_cooldown_multiplier
		if _activation_definition != null
		else 0.0
	)


func _index_of_soonest_charge() -> int:
	var best_index := -1
	var best_remaining := INF
	for index in _charge_timer_remaining.size():
		if _charge_timer_remaining[index] < best_remaining:
			best_remaining = _charge_timer_remaining[index]
			best_index = index
	return best_index
