extends Control

const SETUP_VALIDATOR = preload("res://scripts/app/setup_validator.gd")

@export_group("Safe Area Controls")
## Extra left/bottom distance from the OS safe area for edge gestures.
## Values are viewport units, so they stay independent from device pixels.
@export var gesture_navigation_padding := Vector2(16.0, 32.0)
@export var joystick_edge_padding := Vector2(24.0, 24.0)

@onready var _arena_layout: ArenaLayout = %ArenaLayout
@onready var _run_controller: RunController = %RunController
@onready var _enemy_spawner: EnemySpawner = %EnemySpawner
@onready var _targeting_system: TargetingSystem = %TargetingSystem
@onready var _ability_effect_registry: AbilityEffectRegistry = %AbilityEffectRegistry
@onready var _experience_system: ExperienceSystem = %ExperienceSystem
@onready var _upgrade_registry: UpgradeRegistry = %UpgradeRegistry
@onready var _upgrade_service: UpgradeService = %UpgradeService
@onready var _upgrade_effect_registry: UpgradeEffectRegistry = %UpgradeEffectRegistry
@onready var _experience_dropper: ExperienceDropper = %ExperienceDropper
@onready var _arena_view = %ArenaView
@onready var _player: Player = %Player
@onready var _enemies: Node2D = %Enemies
@onready var _projectiles: Node2D = %Projectiles
@onready var _pickups: Node2D = %Pickups
@onready var _ability_effects: Node2D = %AbilityEffects
@onready var _weapon_controller: WeaponController = _player.get_weapon_controller()
@onready var _ability_controller: AbilityController = _player.get_ability_controller()
@onready var _input_router: InputRouter = %InputRouter
@onready var _platform_lifecycle: PlatformLifecycle = %PlatformLifecycle
@onready var _touch_joystick: TouchJoystick = %TouchJoystick
@onready var _safe_area_root: Control = %SafeAreaRoot
@onready var _hud: GameHud = %HUD
@onready var _upgrade_overlay: UpgradeOverlay = %UpgradeOverlay
@onready var _pause_overlay: Control = %PauseOverlay
@onready var _end_screen: EndScreen = %EndScreen

var _last_logged_safe_area := Rect2()
var _last_logged_joystick_rect := Rect2()


func _ready() -> void:
	_input_router.bind_touch_joystick(_touch_joystick)
	_input_router.bind_active_ability_button(_hud.get_active_ability_button())
	_input_router.movement_vector_changed.connect(_on_movement_vector_changed)
	_arena_layout.playfield_changed.connect(_on_playfield_changed)
	_player.died.connect(_on_player_died)
	_run_controller.run_ended.connect(_on_run_ended)
	_hud.pause_requested.connect(_on_pause_requested)
	_end_screen.restart_requested.connect(_on_restart_requested)
	_platform_lifecycle.configure(
		_run_controller,
		_input_router,
		_pause_overlay
	)

	_arena_layout.refresh_layout()
	_player.set_arena_layout(_arena_layout)
	_player.set_run_controller(_run_controller)
	_player.global_position = _arena_layout.get_playfield_center()
	_player.set_movement_input(_input_router.movement_vector)
	_enemy_spawner.configure(
		_run_controller,
		_arena_layout,
		_player,
		_enemies
	)
	_targeting_system.bind_enemy_spawner(_enemy_spawner)
	_ability_effect_registry.configure(
		_run_controller,
		_targeting_system,
		_ability_effects
	)
	_experience_system.set_run_controller(_run_controller)
	_upgrade_service.configure(
		_upgrade_registry,
		_run_controller,
		_experience_system
	)
	_upgrade_overlay.configure(_upgrade_service, _touch_joystick)
	_experience_dropper.configure(
		_run_controller,
		_enemy_spawner,
		_experience_system,
		_player,
		_pickups
	)
	_weapon_controller.configure(
		_run_controller,
		_targeting_system,
		_projectiles,
		_player
	)
	_upgrade_effect_registry.configure(
		_upgrade_service,
		_upgrade_registry,
		_player,
		_weapon_controller
	)
	_ability_controller.configure(
		_run_controller,
		_input_router,
		_ability_effect_registry,
		_player
	)
	_hud.configure(
		_run_controller,
		_player.get_health_component(),
		_experience_system,
		_ability_controller
	)
	_apply_layout()

	var success := SETUP_VALIDATOR.print_result() and _validate_current_contract()
	_run_controller.start_run(_resolve_run_seed())
	print(
		"B12_READY os=%s viewport=%s window=%s display_safe=%s playfield=%s safe_area=%s seed=%d"
		% [
			OS.get_name(),
			get_viewport().get_visible_rect(),
			DisplayServer.window_get_size(),
			DisplayServer.get_display_safe_area(),
			_arena_layout.get_playfield_rect(),
			_arena_layout.get_safe_area_rect(),
			_run_controller.get_seed(),
		]
	)

	if OS.get_cmdline_user_args().has("--smoke-test"):
		get_tree().quit(0 if success else 1)


func _notification(what: int) -> void:
	if not is_node_ready():
		return
	match what:
		NOTIFICATION_APPLICATION_RESUMED, \
		NOTIFICATION_APPLICATION_FOCUS_IN, \
		NOTIFICATION_WM_WINDOW_FOCUS_IN:
			_arena_layout.request_deferred_refresh()


func _on_movement_vector_changed(value: Vector2) -> void:
	_player.set_movement_input(value)


func _on_playfield_changed(_playfield_rect: Rect2) -> void:
	_apply_layout()


func _apply_layout() -> void:
	var safe_area := _arena_layout.get_safe_area_rect()
	if not safe_area.has_area():
		safe_area = get_viewport().get_visible_rect()

	_safe_area_root.position = safe_area.position
	_safe_area_root.size = safe_area.size

	var joystick_rect := calculate_bottom_left_control_rect(
		safe_area,
		_touch_joystick.custom_minimum_size,
		joystick_edge_padding,
		gesture_navigation_padding
	)
	_touch_joystick.position = joystick_rect.position - safe_area.position
	_touch_joystick.size = joystick_rect.size
	_arena_view.update_layout(
		safe_area,
		_arena_layout.get_playfield_rect()
	)

	if (
		safe_area != _last_logged_safe_area
		or joystick_rect != _last_logged_joystick_rect
	):
		_last_logged_safe_area = safe_area
		_last_logged_joystick_rect = joystick_rect
		print(
			"B09_SAFE safe_area=%s joystick_rect=%s gesture_padding=%s"
			% [safe_area, joystick_rect, gesture_navigation_padding]
		)


func get_touch_joystick_viewport_rect() -> Rect2:
	if not is_node_ready():
		return Rect2()
	return Rect2(
		_safe_area_root.position + _touch_joystick.position,
		_touch_joystick.size
	)


static func calculate_bottom_left_control_rect(
	safe_area: Rect2,
	control_size: Vector2,
	edge_padding: Vector2,
	gesture_padding: Vector2
) -> Rect2:
	if not safe_area.has_area():
		return Rect2(safe_area.position, Vector2.ZERO)

	var fitted_size := Vector2(
		minf(maxf(control_size.x, 0.0), safe_area.size.x),
		minf(maxf(control_size.y, 0.0), safe_area.size.y)
	)
	var requested_padding := Vector2(
		maxf(edge_padding.x, 0.0) + maxf(gesture_padding.x, 0.0),
		maxf(edge_padding.y, 0.0) + maxf(gesture_padding.y, 0.0)
	)
	var available_padding := (safe_area.size - fitted_size).max(Vector2.ZERO)
	var applied_padding := requested_padding.min(available_padding)

	return Rect2(
		Vector2(
			safe_area.position.x + applied_padding.x,
			safe_area.end.y - fitted_size.y - applied_padding.y
		),
		fitted_size
	)


func get_run_controller() -> RunController:
	return _run_controller


func get_enemy_spawner() -> EnemySpawner:
	return _enemy_spawner


func get_targeting_system() -> TargetingSystem:
	return _targeting_system


func get_weapon_controller() -> WeaponController:
	return _weapon_controller


func get_ability_controller() -> AbilityController:
	return _ability_controller


func get_ability_effect_registry() -> AbilityEffectRegistry:
	return _ability_effect_registry


func get_ability_effect_parent() -> Node2D:
	return _ability_effects


func get_projectile_parent() -> Node2D:
	return _projectiles


func get_experience_system() -> ExperienceSystem:
	return _experience_system


func get_upgrade_registry() -> UpgradeRegistry:
	return _upgrade_registry


func get_upgrade_service() -> UpgradeService:
	return _upgrade_service


func get_upgrade_overlay() -> UpgradeOverlay:
	return _upgrade_overlay


func get_upgrade_effect_registry() -> UpgradeEffectRegistry:
	return _upgrade_effect_registry


func get_experience_dropper() -> ExperienceDropper:
	return _experience_dropper


func get_pickup_parent() -> Node2D:
	return _pickups


func get_end_screen() -> EndScreen:
	return _end_screen


func get_hud() -> GameHud:
	return _hud


func get_platform_lifecycle() -> PlatformLifecycle:
	return _platform_lifecycle


func get_pause_overlay() -> Control:
	return _pause_overlay


func restart_run(seed_value: int = 0) -> bool:
	if not _run_controller.is_terminal():
		return false

	var next_seed := seed_value
	if next_seed == 0:
		next_seed = _run_controller.get_seed() + 1
		if next_seed == 0:
			next_seed = 1

	_input_router.suspend_input()
	_player.clear_movement_input()
	_end_screen.hide_end_screen()
	if not _run_controller.restart_run(next_seed):
		_end_screen.show_defeat(_run_controller.get_run_time())
		return false

	_player.global_position = _arena_layout.get_playfield_center()
	_input_router.resume_input()
	return true


func _resolve_run_seed() -> int:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--run-seed="):
			return int(argument.trim_prefix("--run-seed="))
	if OS.get_cmdline_user_args().has("--smoke-test"):
		return 1
	return int(Time.get_unix_time_from_system())


func _validate_current_contract() -> bool:
	var failures: Array[String] = []
	for action in [&"move_left", &"move_right", &"move_up", &"move_down"]:
		if not InputMap.has_action(action):
			failures.append("InputMap privo di %s." % action)
	if not InputMap.has_action(&"pause_game"):
		failures.append("InputMap privo di pause_game.")
	if not InputMap.has_action(&"active_ability"):
		failures.append("InputMap privo di active_ability.")
	if not _arena_layout.get_playfield_rect().has_area():
		failures.append("ArenaLayout non ha prodotto un playfield valido.")
	if _player.get_arena_layout() != _arena_layout:
		failures.append("Player non collegato ad ArenaLayout.")
	if _player.get_run_controller() != _run_controller:
		failures.append("Player non collegato al RunController.")
	var player_health := _player.get_health_component()
	if player_health == null:
		failures.append("Player privo di HealthComponent.")
	elif player_health.invulnerability_duration <= 0.0:
		failures.append("Invulnerabilita Player non configurata.")
	if _run_controller == null:
		failures.append("RunController non presente.")
	if _platform_lifecycle == null:
		failures.append("PlatformLifecycle non presente.")
	else:
		if _platform_lifecycle.get_run_controller() != _run_controller:
			failures.append("PlatformLifecycle non collegato al RunController.")
		if _platform_lifecycle.get_input_router() != _input_router:
			failures.append("PlatformLifecycle non collegato a InputRouter.")
		if _platform_lifecycle.get_pause_overlay() != _pause_overlay:
			failures.append("PlatformLifecycle non collegato a PauseOverlay.")
	if _pause_overlay == null:
		failures.append("PauseOverlay non presente.")
	elif _pause_overlay.visible:
		failures.append("PauseOverlay deve essere nascosto durante la run.")
	if _enemy_spawner.spawn_profile == null:
		failures.append("EnemySpawner privo del profilo dati.")
	if _enemy_spawner.enemy_scene == null:
		failures.append("EnemySpawner privo della scena nemico.")
	if _enemy_spawner.get_run_controller() != _run_controller:
		failures.append("EnemySpawner non collegato al RunController.")
	if _enemy_spawner.get_arena_layout() != _arena_layout:
		failures.append("EnemySpawner non collegato ad ArenaLayout.")
	if _enemy_spawner.get_target() != _player:
		failures.append("EnemySpawner non collegato al Player.")
	if _enemy_spawner.get_enemy_parent() != _enemies:
		failures.append("EnemySpawner non collegato al contenitore Enemies.")
	if _targeting_system.get_enemy_spawner() != _enemy_spawner:
		failures.append("TargetingSystem non collegato a EnemySpawner.")
	if _ability_effect_registry.get_run_controller() != _run_controller:
		failures.append("AbilityEffectRegistry non collegato al RunController.")
	if _ability_effect_registry.get_targeting_system() != _targeting_system:
		failures.append("AbilityEffectRegistry non collegato al TargetingSystem.")
	if _ability_effect_registry.get_effect_parent() != _ability_effects:
		failures.append("AbilityEffectRegistry non collegato ad AbilityEffects.")
	if _weapon_controller.weapon_profile == null:
		failures.append("WeaponController privo del profilo dati.")
	if _weapon_controller.projectile_scene == null:
		failures.append("WeaponController privo della scena proiettile.")
	if _weapon_controller.get_run_controller() != _run_controller:
		failures.append("WeaponController non collegato al RunController.")
	if _weapon_controller.get_targeting_system() != _targeting_system:
		failures.append("WeaponController non collegato al TargetingSystem.")
	if _weapon_controller.get_projectile_parent() != _projectiles:
		failures.append("WeaponController non collegato al contenitore Projectiles.")
	if _ability_controller == null:
		failures.append("Player privo di AbilityController.")
	else:
		var ability_definition := _ability_controller.get_definition()
		if ability_definition == null or not ability_definition.is_valid():
			failures.append("AbilityController privo di AbilityDefinition valida.")
		elif _ability_effect_registry.resolve_definition(ability_definition.id) != ability_definition:
			failures.append("AbilityDefinition non registrata nel registry.")
		if _ability_controller.get_run_controller() != _run_controller:
			failures.append("AbilityController non collegato al RunController.")
		if _ability_controller.get_input_router() != _input_router:
			failures.append("AbilityController non collegato a InputRouter.")
		if _ability_controller.get_effect_registry() != _ability_effect_registry:
			failures.append("AbilityController non collegato al registry.")
		if _ability_controller.get_source() != _player:
			failures.append("AbilityController non collegato al Player.")
	if _player.get_pickup_radius() <= 0.0:
		failures.append("Player privo di pickup_radius valido.")
	if _experience_system.get_run_controller() != _run_controller:
		failures.append("ExperienceSystem non collegato al RunController.")
	if _experience_system.experience_curve == null:
		failures.append("ExperienceSystem privo della curva XP dati.")
	elif _experience_system.get_experience_required(1) <= 0:
		failures.append("ExperienceSystem ha una soglia iniziale non valida.")
	if not _upgrade_registry.is_catalog_valid():
		failures.append(
			"UpgradeRegistry non valido: %s."
			% "; ".join(_upgrade_registry.get_validation_errors())
		)
	if _upgrade_registry.get_fallback_definitions().size() < UpgradeService.DEFAULT_OFFER_SIZE:
		failures.append("UpgradeRegistry privo di tre fallback distinti e ripetibili.")
	if not _upgrade_service.has_valid_configuration():
		failures.append("UpgradeService non configurato per offerte da tre carte.")
	if _upgrade_service.get_registry() != _upgrade_registry:
		failures.append("UpgradeService non collegato a UpgradeRegistry.")
	if _upgrade_service.get_run_controller() != _run_controller:
		failures.append("UpgradeService non collegato al RunController.")
	if _upgrade_service.get_experience_system() != _experience_system:
		failures.append("UpgradeService non collegato a ExperienceSystem.")
	if not _upgrade_effect_registry.has_valid_configuration():
		failures.append("UpgradeEffectRegistry non configurato per il catalogo B12.")
	if _upgrade_effect_registry.get_upgrade_service() != _upgrade_service:
		failures.append("UpgradeEffectRegistry non collegato a UpgradeService.")
	if _upgrade_effect_registry.get_upgrade_registry() != _upgrade_registry:
		failures.append("UpgradeEffectRegistry non collegato a UpgradeRegistry.")
	if _upgrade_effect_registry.get_player() != _player:
		failures.append("UpgradeEffectRegistry non collegato al Player.")
	if _upgrade_effect_registry.get_weapon_controller() != _weapon_controller:
		failures.append("UpgradeEffectRegistry non collegato all'arma.")
	if not is_equal_approx(_player.move_speed, _player.get_base_move_speed()):
		failures.append("La run deve iniziare con la velocita Player base.")
	if not is_equal_approx(_player.get_pickup_radius(), _player.get_base_pickup_radius()):
		failures.append("La run deve iniziare con il raggio pickup base.")
	if not is_equal_approx(
		_weapon_controller.get_effective_shots_per_second(),
		_weapon_controller.get_base_shots_per_second()
	):
		failures.append("La run deve iniziare con la frequenza arma base.")
	if not is_equal_approx(
		_weapon_controller.get_effective_damage(),
		_weapon_controller.get_base_damage()
	):
		failures.append("La run deve iniziare con il danno arma base.")
	if _upgrade_overlay == null:
		failures.append("UpgradeOverlay non presente.")
	else:
		if _upgrade_overlay.get_upgrade_service() != _upgrade_service:
			failures.append("UpgradeOverlay non collegato a UpgradeService.")
		if _upgrade_overlay.get_touch_joystick() != _touch_joystick:
			failures.append("UpgradeOverlay non collegato al joystick touch.")
		if _upgrade_overlay.visible or _upgrade_overlay.is_accepting_selection():
			failures.append("UpgradeOverlay deve essere nascosto senza un'offerta.")
		var upgrade_cards := _upgrade_overlay.get_cards()
		if upgrade_cards.size() != UpgradeService.DEFAULT_OFFER_SIZE:
			failures.append("UpgradeOverlay deve contenere tre carte.")
		else:
			for card in upgrade_cards:
				if card.custom_minimum_size.x < 200.0 or card.custom_minimum_size.y < 200.0:
					failures.append("Le carte upgrade devono essere target touch ampi.")
					break
	if _experience_dropper.pickup_scene == null:
		failures.append("ExperienceDropper privo della scena pickup.")
	if _experience_dropper.get_run_controller() != _run_controller:
		failures.append("ExperienceDropper non collegato al RunController.")
	if _experience_dropper.get_enemy_spawner() != _enemy_spawner:
		failures.append("ExperienceDropper non collegato a EnemySpawner.")
	if _experience_dropper.get_experience_system() != _experience_system:
		failures.append("ExperienceDropper non collegato a ExperienceSystem.")
	if _experience_dropper.get_player() != _player:
		failures.append("ExperienceDropper non collegato al Player.")
	if _experience_dropper.get_pickup_parent() != _pickups:
		failures.append("ExperienceDropper non collegato al contenitore Pickups.")
	if _experience_dropper.pickup_scene != null:
		var pickup_candidate := _experience_dropper.pickup_scene.instantiate()
		if not pickup_candidate is ExperiencePickup:
			failures.append("La scena pickup non istanzia ExperiencePickup.")
		if is_instance_valid(pickup_candidate):
			pickup_candidate.free()
	if _end_screen == null:
		failures.append("EndScreen non presente.")
	elif _end_screen.visible:
		failures.append("EndScreen deve essere nascosto durante la run.")
	if _hud == null:
		failures.append("HUD non presente.")
	else:
		if _hud.get_run_controller() != _run_controller:
			failures.append("HUD non collegato al RunController.")
		if _hud.get_health_component() != player_health:
			failures.append("HUD non collegato alla salute Player.")
		if _hud.get_experience_system() != _experience_system:
			failures.append("HUD non collegato a ExperienceSystem.")
		if _hud.get_ability_controller() != _ability_controller:
			failures.append("HUD non collegato ad AbilityController.")
		if not _hud.get_experience_panel_rect().has_area():
			failures.append("HUD privo di una barra XP con layout valido.")
		if not _hud.get_pause_button_rect().has_area():
			failures.append("HUD privo di un pulsante pausa con layout valido.")
		if not _hud.get_active_ability_button_rect().has_area():
			failures.append("HUD privo del pulsante abilita touch.")
		if _input_router.get_active_ability_button() != _hud.get_active_ability_button():
			failures.append("InputRouter non collegato al pulsante abilita touch.")
	if _enemy_spawner.enemy_scene != null:
		var enemy_candidate := _enemy_spawner.enemy_scene.instantiate()
		if enemy_candidate is BaseEnemy:
			var contact := enemy_candidate.get_node_or_null("ContactDamage")
			if not contact is ContactDamage:
				failures.append("BaseEnemy privo di ContactDamage.")
		else:
			failures.append("La scena nemico non istanzia BaseEnemy.")
		if is_instance_valid(enemy_candidate):
			enemy_candidate.free()

	if failures.is_empty():
		print("B03_CONTRACT_OK")
		print("B04_CONTRACT_OK")
		print("B05_CONTRACT_OK")
		print("B06_CONTRACT_OK")
		print("B06A_CONTRACT_OK")
		print("B07_CONTRACT_OK")
		print("B08_CONTRACT_OK")
		print("B09_CONTRACT_OK")
		print("B09A_CONTRACT_OK")
		print("B10_CONTRACT_OK")
		print("B11_CONTRACT_OK")
		print("B12_CONTRACT_OK")
		return true

	for failure in failures:
		push_error(failure)
	printerr("B12_CONTRACT_FAIL")
	return false


func _on_player_died(player: Player) -> void:
	if player != _player or _run_controller.is_terminal():
		return
	_input_router.suspend_input()
	_player.clear_movement_input()
	_run_controller.request_defeat()


func _on_run_ended(final_state: RunController.RunState, run_time: float) -> void:
	if final_state == RunController.RunState.DEFEAT:
		_end_screen.show_defeat(run_time)


func _on_restart_requested() -> void:
	restart_run()


func _on_pause_requested() -> void:
	_platform_lifecycle.request_manual_pause()
