class_name BossUI
extends Control

signal intro_continue_requested()

@onready var _boss_health_panel: Control = %BossHealthPanel
@onready var _boss_name_label: Label = %BossNameLabel
@onready var _boss_health_label: Label = %BossHealthLabel
@onready var _boss_health_bar: ProgressBar = %BossHealthBar
@onready var _intro_layer: Control = %IntroLayer
@onready var _intro_title_label: Label = %IntroTitleLabel
@onready var _intro_quote_label: Label = %IntroQuoteLabel
@onready var _continue_button: Button = %ContinueButton

var _boss: FirstBoss
var _accepting_continue := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_continue_button.pressed.connect(_on_continue_button_pressed)
	reset_presentation()


func _exit_tree() -> void:
	_disconnect_boss()


func bind_boss(boss: FirstBoss, definition: BossDefinition) -> bool:
	if (
		not is_node_ready()
		or not is_instance_valid(boss)
		or definition == null
		or not definition.is_valid()
	):
		return false

	_disconnect_boss()
	_boss = boss
	_boss.health_changed.connect(_on_boss_health_changed)
	_boss.tree_exiting.connect(_on_boss_tree_exiting, CONNECT_ONE_SHOT)
	_boss_name_label.text = definition.get_safe_title().to_upper()
	var health_component := _boss.get_health_component()
	if health_component == null:
		_disconnect_boss()
		return false
	_on_boss_health_changed(
		_boss,
		health_component.health_current,
		health_component.health_max
	)
	_boss_health_panel.visible = true
	return true


func show_intro(definition: BossDefinition) -> bool:
	if (
		not is_node_ready()
		or definition == null
		or not definition.is_valid()
	):
		return false
	_intro_title_label.text = definition.get_safe_title().to_upper()
	_intro_quote_label.text = "\u201c%s\u201d" % definition.get_safe_quote()
	_accepting_continue = true
	_intro_layer.visible = true
	_continue_button.disabled = false
	_continue_button.call_deferred("grab_focus")
	return true


func hide_intro() -> void:
	_accepting_continue = false
	_intro_layer.visible = false
	if is_instance_valid(_continue_button):
		_continue_button.disabled = true


func clear_boss() -> void:
	_disconnect_boss()
	if is_instance_valid(_boss_health_panel):
		_boss_health_panel.visible = false


func reset_presentation() -> void:
	hide_intro()
	clear_boss()


func is_intro_visible() -> bool:
	return is_instance_valid(_intro_layer) and _intro_layer.visible


func is_accepting_continue() -> bool:
	return _accepting_continue and is_intro_visible()


func is_boss_health_visible() -> bool:
	return is_instance_valid(_boss_health_panel) and _boss_health_panel.visible


func get_boss() -> FirstBoss:
	return _boss if is_instance_valid(_boss) else null


func get_intro_title_text() -> String:
	return _intro_title_label.text if is_instance_valid(_intro_title_label) else ""


func get_intro_quote_text() -> String:
	return _intro_quote_label.text if is_instance_valid(_intro_quote_label) else ""


func get_boss_health_value() -> float:
	return _boss_health_bar.value if is_instance_valid(_boss_health_bar) else 0.0


func get_boss_health_max() -> float:
	return _boss_health_bar.max_value if is_instance_valid(_boss_health_bar) else 0.0


func get_boss_health_panel_rect() -> Rect2:
	return (
		_boss_health_panel.get_global_rect()
		if is_instance_valid(_boss_health_panel)
		else Rect2()
	)


func get_intro_panel_rect() -> Rect2:
	var intro_panel := get_node_or_null("IntroLayer/Center/IntroPanel") as Control
	return intro_panel.get_global_rect() if intro_panel != null else Rect2()


func _on_boss_health_changed(
	boss: BaseEnemy,
	health_current: float,
	health_max: float
) -> void:
	if boss != _boss:
		return
	var safe_max := maxf(health_max, HealthComponent.MINIMUM_HEALTH)
	var safe_current := clampf(health_current, 0.0, safe_max)
	_boss_health_bar.max_value = safe_max
	_boss_health_bar.value = safe_current
	_boss_health_label.text = "%d / %d" % [
		int(round(safe_current)),
		int(round(safe_max)),
	]


func _on_continue_button_pressed() -> void:
	if not is_accepting_continue():
		return
	_accepting_continue = false
	_continue_button.disabled = true
	intro_continue_requested.emit()


func _on_boss_tree_exiting() -> void:
	_boss = null
	_boss_health_panel.visible = false


func _disconnect_boss() -> void:
	if not is_instance_valid(_boss):
		_boss = null
		return
	if _boss.health_changed.is_connected(_on_boss_health_changed):
		_boss.health_changed.disconnect(_on_boss_health_changed)
	if _boss.tree_exiting.is_connected(_on_boss_tree_exiting):
		_boss.tree_exiting.disconnect(_on_boss_tree_exiting)
	_boss = null
