class_name GameHud
extends Control

signal pause_requested()

@onready var _level_label: Label = %LevelLabel
@onready var _experience_label: Label = %ExperienceLabel
@onready var _experience_bar: ProgressBar = %ExperienceBar
@onready var _health_label: Label = %HealthLabel
@onready var _health_bar: ProgressBar = %HealthBar
@onready var _time_label: Label = %TimeLabel
@onready var _experience_panel: Control = %ExperiencePanel
@onready var _health_panel: Control = %HealthPanel
@onready var _timer_slot: Control = %TimerSlot
@onready var _pause_button: Button = %PauseButton
@onready var _ability_panel: Control = %AbilityPanel
@onready var _ability_icon: TextureRect = %AbilityIcon
@onready var _ability_name_label: Label = %AbilityNameLabel
@onready var _ability_cooldown_label: Label = %AbilityCooldownLabel
@onready var _ability_cooldown_bar: ProgressBar = %AbilityCooldownBar
@onready var _active_ability_button: Button = %ActiveAbilityButton

var _run_controller: RunController
var _health_component: HealthComponent
var _experience_system: ExperienceSystem
var _ability_controller: AbilityController


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_pause_button.pressed.connect(_on_pause_button_pressed)
	_show_default_values()


func _exit_tree() -> void:
	_disconnect_sources()


func configure(
	run_controller: RunController,
	health_component: HealthComponent,
	experience_system: ExperienceSystem,
	ability_controller: AbilityController = null
) -> bool:
	if (
		not is_node_ready()
		or not is_instance_valid(run_controller)
		or not is_instance_valid(health_component)
		or not is_instance_valid(experience_system)
	):
		return false

	_disconnect_sources()
	_run_controller = run_controller
	_health_component = health_component
	_experience_system = experience_system
	_ability_controller = ability_controller

	_run_controller.run_time_changed.connect(_on_run_time_changed)
	_run_controller.state_changed.connect(_on_run_state_changed)
	_health_component.health_changed.connect(_on_health_changed)
	_experience_system.progression_changed.connect(_on_progression_changed)
	if is_instance_valid(_ability_controller):
		_ability_controller.cooldown_changed.connect(_on_ability_cooldown_changed)
		_ability_controller.readiness_changed.connect(_on_ability_readiness_changed)
	_refresh_from_sources()
	return true


func get_run_controller() -> RunController:
	return _run_controller if is_instance_valid(_run_controller) else null


func get_health_component() -> HealthComponent:
	return _health_component if is_instance_valid(_health_component) else null


func get_experience_system() -> ExperienceSystem:
	return _experience_system if is_instance_valid(_experience_system) else null


func get_ability_controller() -> AbilityController:
	return _ability_controller if is_instance_valid(_ability_controller) else null


func get_health_value() -> float:
	return _health_bar.value


func get_health_max() -> float:
	return _health_bar.max_value


func get_experience_value() -> float:
	return _experience_bar.value


func get_experience_max() -> float:
	return _experience_bar.max_value


func get_health_text() -> String:
	return _health_label.text


func get_experience_text() -> String:
	return _experience_label.text


func get_level_text() -> String:
	return _level_label.text


func get_time_text() -> String:
	return _time_label.text


func get_experience_panel_rect() -> Rect2:
	return _experience_panel.get_global_rect()


func get_health_panel_rect() -> Rect2:
	return _health_panel.get_global_rect()


func get_timer_slot_rect() -> Rect2:
	return _timer_slot.get_global_rect()


func get_pause_button() -> Button:
	return _pause_button if is_instance_valid(_pause_button) else null


func get_pause_button_rect() -> Rect2:
	return _pause_button.get_global_rect() if is_instance_valid(_pause_button) else Rect2()


func get_ability_panel_rect() -> Rect2:
	return _ability_panel.get_global_rect() if is_instance_valid(_ability_panel) else Rect2()


func get_active_ability_button() -> Button:
	return _active_ability_button if is_instance_valid(_active_ability_button) else null


func get_active_ability_button_rect() -> Rect2:
	return (
		_active_ability_button.get_global_rect()
		if is_instance_valid(_active_ability_button)
		else Rect2()
	)


func get_ability_name_text() -> String:
	return _ability_name_label.text


func get_ability_cooldown_text() -> String:
	return _ability_cooldown_label.text


func get_ability_cooldown_value() -> float:
	return _ability_cooldown_bar.value


static func format_run_time(run_time: float) -> String:
	var safe_time := maxf(run_time, 0.0) if is_finite(run_time) else 0.0
	var total_seconds := int(floor(safe_time))
	return "%02d:%02d" % [total_seconds / 60, total_seconds % 60]


func _refresh_from_sources() -> void:
	_on_run_time_changed(_run_controller.get_run_time())
	_on_run_state_changed(_run_controller.get_state(), _run_controller.get_state())
	_on_health_changed(
		_health_component.health_current,
		_health_component.health_max
	)
	_on_progression_changed(
		_experience_system.level,
		_experience_system.experience_current,
		_experience_system.experience_required,
		_experience_system.experience_total
	)
	_refresh_ability_definition()


func _show_default_values() -> void:
	_on_run_time_changed(0.0)
	_set_pause_available(false)
	_on_health_changed(0.0, 1.0)
	_on_progression_changed(1, 0, 1, 0)
	_show_default_ability()


func _disconnect_sources() -> void:
	if is_instance_valid(_run_controller):
		if _run_controller.run_time_changed.is_connected(_on_run_time_changed):
			_run_controller.run_time_changed.disconnect(_on_run_time_changed)
		if _run_controller.state_changed.is_connected(_on_run_state_changed):
			_run_controller.state_changed.disconnect(_on_run_state_changed)
	if is_instance_valid(_health_component):
		if _health_component.health_changed.is_connected(_on_health_changed):
			_health_component.health_changed.disconnect(_on_health_changed)
	if is_instance_valid(_experience_system):
		if _experience_system.progression_changed.is_connected(
			_on_progression_changed
		):
			_experience_system.progression_changed.disconnect(
				_on_progression_changed
			)
	if is_instance_valid(_ability_controller):
		if _ability_controller.cooldown_changed.is_connected(
			_on_ability_cooldown_changed
		):
			_ability_controller.cooldown_changed.disconnect(
				_on_ability_cooldown_changed
			)
		if _ability_controller.readiness_changed.is_connected(
			_on_ability_readiness_changed
		):
			_ability_controller.readiness_changed.disconnect(
				_on_ability_readiness_changed
			)

	_run_controller = null
	_health_component = null
	_experience_system = null
	_ability_controller = null


func _on_run_time_changed(run_time: float) -> void:
	_time_label.text = format_run_time(run_time)


func _on_run_state_changed(
	_previous_state: RunController.RunState,
	current_state: RunController.RunState
) -> void:
	_set_pause_available(current_state == RunController.RunState.RUNNING)
	_refresh_ability_state()


func _set_pause_available(available: bool) -> void:
	if is_instance_valid(_pause_button):
		_pause_button.disabled = not available


func _on_pause_button_pressed() -> void:
	if (
		is_instance_valid(_run_controller)
		and _run_controller.is_running()
		and not _pause_button.disabled
	):
		pause_requested.emit()


func _on_health_changed(health_current: float, health_max: float) -> void:
	var safe_max := maxf(health_max, HealthComponent.MINIMUM_HEALTH)
	var safe_current := clampf(health_current, 0.0, safe_max)
	_health_bar.max_value = safe_max
	_health_bar.value = safe_current
	_health_label.text = "VITA  %d / %d" % [
		int(round(safe_current)),
		int(round(safe_max)),
	]


func _on_progression_changed(
	level: int,
	experience_current: int,
	experience_required: int,
	_experience_total: int
) -> void:
	var safe_level := maxi(level, 1)
	var safe_required := maxi(experience_required, 1)
	var safe_current := clampi(experience_current, 0, safe_required)
	_level_label.text = "LV %d" % safe_level
	_experience_label.text = "%d / %d XP" % [safe_current, safe_required]
	_experience_bar.max_value = safe_required
	_experience_bar.value = safe_current


func _refresh_ability_definition() -> void:
	if not is_instance_valid(_ability_controller):
		_show_default_ability()
		return
	var definition := _ability_controller.get_definition()
	if definition == null:
		_show_default_ability()
		return
	_ability_name_label.text = definition.title.to_upper()
	_ability_icon.texture = definition.icon
	_ability_cooldown_bar.max_value = maxf(
		definition.cooldown_seconds,
		AbilityDefinition.MINIMUM_POSITIVE_VALUE
	)
	_on_ability_cooldown_changed(
		_ability_controller.get_cooldown_remaining(),
		_ability_controller.get_cooldown_total()
	)


func _show_default_ability() -> void:
	_ability_name_label.text = "ABILITÀ ATTIVA"
	_ability_icon.texture = null
	_ability_cooldown_label.text = "NON ASSEGNATA"
	_ability_cooldown_bar.max_value = 1.0
	_ability_cooldown_bar.value = 0.0
	_active_ability_button.text = "ATTIVA"
	_active_ability_button.disabled = true


func _on_ability_cooldown_changed(
	cooldown_remaining: float,
	cooldown_total: float
) -> void:
	var safe_total := maxf(cooldown_total, AbilityDefinition.MINIMUM_POSITIVE_VALUE)
	var safe_remaining := clampf(cooldown_remaining, 0.0, safe_total)
	_ability_cooldown_bar.max_value = safe_total
	_ability_cooldown_bar.value = safe_total - safe_remaining
	if safe_remaining <= 0.0:
		_ability_cooldown_label.text = "PRONTA"
	else:
		_ability_cooldown_label.text = "RICARICA  %.1f s" % safe_remaining
	_refresh_ability_state()


func _on_ability_readiness_changed(_is_ready: bool) -> void:
	_refresh_ability_state()


func _refresh_ability_state() -> void:
	if not is_instance_valid(_active_ability_button):
		return
	if not is_instance_valid(_ability_controller):
		_active_ability_button.disabled = true
		_active_ability_button.text = "ATTIVA"
		return
	var running := (
		is_instance_valid(_run_controller)
		and _run_controller.is_running()
	)
	var ready := (
		_ability_controller.is_cooldown_ready()
	)
	_active_ability_button.disabled = not running or not ready
	if not running:
		_active_ability_button.text = "ATTIVA\nPAUSA"
	elif ready:
		_active_ability_button.text = "ATTIVA\nPRONTA"
	else:
		_active_ability_button.text = "ATTIVA\n%.1f s" % _ability_controller.get_cooldown_remaining()
