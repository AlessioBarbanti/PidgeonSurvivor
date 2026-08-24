class_name GameHud
extends Control

signal pause_requested()

@onready var _level_label: Label = %LevelLabel
@onready var _experience_label: Label = %ExperienceLabel
@onready var _experience_bar: ProgressBar = %ExperienceBar
@onready var _health_label: Label = %HealthLabel
@onready var _health_bar: ProgressBar = %HealthBar
@onready var _time_label: Label = %TimeLabel
@onready var _top_band: Control = %TopBand
@onready var _experience_panel: Control = %ExperiencePanel
@onready var _health_panel: Control = %HealthPanel
@onready var _timer_slot: Control = %TimerSlot
@onready var _pause_button: Button = %PauseButton
@onready var _portrait: TextureRect = %Portrait
@onready var _portrait_frame: Control = %PortraitFrame
@onready var _ability_panel: Control = %AbilityPanel
@onready var _active_ability_button: TouchAbilityButton = %ActiveAbilityButton

var _run_controller: RunController
var _health_component: HealthComponent
var _experience_system: ExperienceSystem
var _ability_controller: AbilityController
var _friend_definition: FriendDefinition
var _health_feedback_tween: Tween
var _ability_ready_tween: Tween
var _health_feedback_count := 0
var _ability_ready_pulse_count := 0
var _last_ability_ready := false
var _ability_name_text := "ABILITÀ ATTIVA"
var _ability_cooldown_text := "NON ASSEGNATA"
var _ability_cooldown_value := 0.0


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
	_health_component.damaged.connect(_on_health_damaged)
	_experience_system.progression_changed.connect(_on_progression_changed)
	if is_instance_valid(_ability_controller):
		_ability_controller.cooldown_changed.connect(_on_ability_cooldown_changed)
		_ability_controller.readiness_changed.connect(_on_ability_readiness_changed)
		_ability_controller.definition_changed.connect(_on_ability_definition_changed)
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


func set_friend_definition(definition: FriendDefinition) -> bool:
	if definition == null or not definition.is_valid():
		return false
	_friend_definition = definition
	if is_instance_valid(_portrait):
		_portrait.texture = definition.get_public_portrait()
	return true


func get_friend_definition() -> FriendDefinition:
	return _friend_definition


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


func get_top_band_rect() -> Rect2:
	return _top_band.get_global_rect() if is_instance_valid(_top_band) else Rect2()


func get_portrait_rect() -> Rect2:
	return _portrait_frame.get_global_rect() if is_instance_valid(_portrait_frame) else Rect2()


func get_portrait_texture() -> Texture2D:
	return _portrait.texture if is_instance_valid(_portrait) else null


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


func get_active_ability_button() -> TouchAbilityButton:
	return _active_ability_button if is_instance_valid(_active_ability_button) else null


func get_active_ability_button_rect() -> Rect2:
	return (
		_active_ability_button.get_global_rect()
		if is_instance_valid(_active_ability_button)
		else Rect2()
	)


func is_touch_origin_excluded(viewport_position: Vector2) -> bool:
	for control in [_top_band, _experience_panel, _ability_panel]:
		if (
			is_instance_valid(control)
			and control.is_visible_in_tree()
			and control.get_global_rect().has_point(viewport_position)
		):
			return true
	return false


func get_ability_name_text() -> String:
	return _ability_name_text


func get_ability_cooldown_text() -> String:
	return _ability_cooldown_text


func get_ability_cooldown_value() -> float:
	return _ability_cooldown_value


func get_health_feedback_count() -> int:
	return _health_feedback_count


func get_ability_ready_pulse_count() -> int:
	return _ability_ready_pulse_count


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
	if is_instance_valid(_portrait):
		_portrait.texture = null
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
		if _health_component.damaged.is_connected(_on_health_damaged):
			_health_component.damaged.disconnect(_on_health_damaged)
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
		if _ability_controller.definition_changed.is_connected(
			_on_ability_definition_changed
		):
			_ability_controller.definition_changed.disconnect(
				_on_ability_definition_changed
			)

	_run_controller = null
	_health_component = null
	_experience_system = null
	_ability_controller = null
	_last_ability_ready = false


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


func _on_health_damaged(_amount: float, _health_current: float) -> void:
	_health_feedback_count += 1
	if not is_instance_valid(_health_panel):
		return
	if is_instance_valid(_health_feedback_tween):
		_health_feedback_tween.kill()
	_health_panel.self_modulate = Color(1.0, 0.52, 0.64, 1.0)
	_health_feedback_tween = create_tween()
	_health_feedback_tween.tween_property(
		_health_panel,
		"self_modulate",
		Color.WHITE,
		0.18
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


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
	_ability_name_text = definition.title.to_upper()
	_on_ability_cooldown_changed(
		_ability_controller.get_cooldown_remaining(),
		_ability_controller.get_cooldown_total()
	)
	_last_ability_ready = _ability_controller.is_cooldown_ready()


func _show_default_ability() -> void:
	_ability_name_text = "ABILITÀ ATTIVA"
	_ability_cooldown_text = "NON ASSEGNATA"
	_ability_cooldown_value = 0.0
	_active_ability_button.set_ability_visual(null, 0.0, 1.0, false)
	_last_ability_ready = false


func _on_ability_cooldown_changed(
	cooldown_remaining: float,
	cooldown_total: float
) -> void:
	var safe_total := maxf(cooldown_total, AbilityDefinition.MINIMUM_POSITIVE_VALUE)
	var safe_remaining := clampf(cooldown_remaining, 0.0, safe_total)
	_ability_cooldown_value = safe_total - safe_remaining
	if safe_remaining <= 0.0:
		_ability_cooldown_text = "PRONTA"
	else:
		_ability_cooldown_text = "RICARICA"
	_refresh_ability_state()


func _on_ability_readiness_changed(is_ready: bool) -> void:
	if (
		is_ready
		and not _last_ability_ready
		and is_instance_valid(_run_controller)
		and _run_controller.is_running()
	):
		_play_ability_ready_pulse()
	_last_ability_ready = is_ready
	_refresh_ability_state()


func _on_ability_definition_changed(_definition: AbilityDefinition) -> void:
	_refresh_ability_definition()
	_refresh_ability_state()


func _refresh_ability_state() -> void:
	if not is_instance_valid(_active_ability_button):
		return
	if not is_instance_valid(_ability_controller):
		_active_ability_button.set_ability_visual(null, 0.0, 1.0, false)
		return
	var running := (
		is_instance_valid(_run_controller)
		and _run_controller.is_running()
	)
	var ready := (
		_ability_controller.is_cooldown_ready()
	)
	var definition := _ability_controller.get_definition()
	_active_ability_button.set_ability_visual(
		definition.icon if definition != null else null,
		_ability_controller.get_cooldown_remaining(),
		_ability_controller.get_cooldown_total(),
		running and ready
	)


func _play_ability_ready_pulse() -> void:
	_ability_ready_pulse_count += 1
	if not is_instance_valid(_ability_panel):
		return
	if is_instance_valid(_ability_ready_tween):
		_ability_ready_tween.kill()
	_ability_panel.self_modulate = Color(1.0, 0.76, 0.38, 1.0)
	_ability_ready_tween = create_tween()
	_ability_ready_tween.tween_property(
		_ability_panel,
		"self_modulate",
		Color.WHITE,
		0.24
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
