class_name AbilityController
extends Node

signal cooldown_changed(cooldown_remaining: float, cooldown_total: float)
signal readiness_changed(is_ready: bool)
signal ability_activated(definition: AbilityDefinition)
signal definition_changed(definition: AbilityDefinition)

@export var ability_definition: AbilityDefinition

var _run_controller: RunController
var _input_router: InputRouter
var _effect_registry: AbilityEffectRegistry
var _source: Node2D
var _cooldown_remaining := 0.0
var _ready_state := true


func _exit_tree() -> void:
	_disconnect_dependencies()


func _process(delta: float) -> void:
	if (
		_cooldown_remaining <= 0.0
		or not is_instance_valid(_run_controller)
		or not _run_controller.is_running()
	):
		return

	var previous_remaining := _cooldown_remaining
	_cooldown_remaining = maxf(_cooldown_remaining - maxf(delta, 0.0), 0.0)
	if not is_equal_approx(previous_remaining, _cooldown_remaining):
		cooldown_changed.emit(_cooldown_remaining, get_cooldown_total())
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
	if not _has_valid_dependencies():
		return false
	if not _effect_registry.register_definition(ability_definition):
		return false

	_input_router.active_ability_requested.connect(try_activate)
	_run_controller.restart_prepared.connect(_on_restart_prepared)
	reset_for_run()
	return true


func try_activate() -> bool:
	if (
		not _has_valid_dependencies()
		or not _run_controller.is_running()
		or _cooldown_remaining > 0.0
		or not _effect_registry.can_execute(ability_definition)
	):
		return false

	var effect := _effect_registry.execute_effect(ability_definition, _source)
	if effect == null:
		return false

	_cooldown_remaining = get_cooldown_total()
	cooldown_changed.emit(_cooldown_remaining, get_cooldown_total())
	_update_ready_state()
	ability_activated.emit(ability_definition)
	return true


func equip_definition(definition: AbilityDefinition) -> bool:
	if definition == null or not definition.is_valid():
		return false
	if is_instance_valid(_effect_registry) and not _effect_registry.register_definition(definition):
		return false
	ability_definition = definition
	reset_for_run()
	definition_changed.emit(ability_definition)
	return true


func reset_for_run() -> void:
	var was_ready := _ready_state
	_cooldown_remaining = 0.0
	_ready_state = true
	cooldown_changed.emit(_cooldown_remaining, get_cooldown_total())
	if not was_ready:
		readiness_changed.emit(true)


func get_definition() -> AbilityDefinition:
	return ability_definition


func get_run_controller() -> RunController:
	return _run_controller if is_instance_valid(_run_controller) else null


func get_input_router() -> InputRouter:
	return _input_router if is_instance_valid(_input_router) else null


func get_effect_registry() -> AbilityEffectRegistry:
	return _effect_registry if is_instance_valid(_effect_registry) else null


func get_source() -> Node2D:
	return _source if is_instance_valid(_source) else null


func get_cooldown_remaining() -> float:
	return _cooldown_remaining


func get_cooldown_total() -> float:
	return ability_definition.cooldown_seconds if ability_definition != null else 0.0


func is_cooldown_ready() -> bool:
	return _cooldown_remaining <= 0.0


func _has_valid_dependencies() -> bool:
	return (
		ability_definition != null
		and ability_definition.is_valid()
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
	_run_controller = null
	_input_router = null
	_effect_registry = null
	_source = null


func _on_restart_prepared() -> void:
	reset_for_run()
