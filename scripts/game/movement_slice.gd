extends Control

const SETUP_VALIDATOR = preload("res://scripts/app/setup_validator.gd")

@export_group("Safe Area Controls")
## Extra left/bottom distance from the OS safe area for edge gestures.
## Values are viewport units, so they stay independent from device pixels.
@export var gesture_navigation_padding := Vector2(16.0, 32.0)
@export var joystick_edge_padding := Vector2(24.0, 24.0)

@onready var _arena_layout: ArenaLayout = %ArenaLayout
@onready var _run_controller: RunController = %RunController
@onready var _friend_registry: FriendRegistry = %FriendRegistry
@onready var _game_director: GameDirector = %GameDirector
@onready var _boss_encounter: BossEncounter = %BossEncounter
@onready var _enemy_spawner: EnemySpawner = %EnemySpawner
@onready var _targeting_system: TargetingSystem = %TargetingSystem
@onready var _ability_effect_registry: AbilityEffectRegistry = %AbilityEffectRegistry
@onready var _friend_passive_controller: FriendPassiveController = %FriendPassiveController
@onready var _experience_system: ExperienceSystem = %ExperienceSystem
@onready var _upgrade_registry: UpgradeRegistry = %UpgradeRegistry
@onready var _upgrade_service: UpgradeService = %UpgradeService
@onready var _upgrade_effect_registry: UpgradeEffectRegistry = %UpgradeEffectRegistry
@onready var _experience_dropper: ExperienceDropper = %ExperienceDropper
@onready var _game_audio: GameAudio = %GameAudio
@onready var _arena_view: ArenaView = %ArenaView
@onready var _player: Player = %Player
@onready var _enemies: Node2D = %Enemies
@onready var _projectiles: Node2D = %Projectiles
@onready var _boss_projectiles: Node2D = %BossProjectiles
@onready var _pickups: Node2D = %Pickups
@onready var _ability_effects: Node2D = %AbilityEffects
@onready var _combat_feedback: CombatFeedback = %CombatFeedback
@onready var _weapon_controller: WeaponController = _player.get_weapon_controller()
@onready var _ability_controller: AbilityController = _player.get_ability_controller()
@onready var _input_router: InputRouter = %InputRouter
@onready var _platform_lifecycle: PlatformLifecycle = %PlatformLifecycle
@onready var _touch_joystick: TouchJoystick = %TouchJoystick
@onready var _vignette_effect: VignetteEffect = %VignetteEffect
@onready var _safe_area_root: Control = %SafeAreaRoot
@onready var _hud: GameHud = %HUD
@onready var _boss_ui: BossUI = %BossUI
@onready var _upgrade_overlay: UpgradeOverlay = %UpgradeOverlay
@onready var _character_select_overlay: CharacterSelectOverlay = %CharacterSelectOverlay
@onready var _pause_overlay: PauseOverlay = %PauseOverlay
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
	_boss_encounter.boss_defeated.connect(_on_boss_defeated)
	_hud.pause_requested.connect(_on_pause_requested)
	_end_screen.restart_requested.connect(_on_restart_requested)
	_end_screen.change_character_requested.connect(_on_change_character_requested)
	_character_select_overlay.friend_confirmed.connect(_on_friend_confirmed)
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
	_game_director.configure(_run_controller, _enemy_spawner)
	_enemy_spawner.configure(
		_run_controller,
		_arena_layout,
		_player,
		_enemies
	)
	_combat_feedback.configure(
		_run_controller,
		_enemy_spawner,
		_player,
		_boss_encounter
	)
	_targeting_system.bind_enemy_spawner(_enemy_spawner)
	_ability_effect_registry.configure(
		_run_controller,
		_targeting_system,
		_ability_effects,
		_arena_layout
	)
	_experience_system.set_run_controller(_run_controller)
	_boss_encounter.configure(
		_run_controller,
		_game_director,
		_arena_layout,
		_player,
		_enemies,
		_boss_projectiles,
		_targeting_system,
		_experience_system,
		_boss_ui
	)
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
		_arena_layout,
		_pickups
	)
	_weapon_controller.configure(
		_run_controller,
		_targeting_system,
		_projectiles,
		_player,
		_arena_layout
	)
	_friend_passive_controller.configure(
		_run_controller,
		_player,
		_weapon_controller,
		_targeting_system
	)
	_upgrade_effect_registry.configure(
		_upgrade_service,
		_upgrade_registry,
		_player,
		_weapon_controller,
		_vignette_effect,
		_ability_effects
	)
	_ability_controller.configure(
		_run_controller,
		_input_router,
		_ability_effect_registry,
		_player
	)
	_equip_friend(&"magno")
	_hud.configure(
		_run_controller,
		_player.get_health_component(),
		_experience_system,
		_ability_controller
	)
	_hud.set_friend_definition(_player.get_friend_definition())
	_character_select_overlay.configure(_friend_registry)
	_game_audio.configure(
		_run_controller,
		_player,
		_weapon_controller,
		_ability_controller,
		_experience_system,
		_boss_encounter,
		_upgrade_overlay,
		_character_select_overlay,
		_pause_overlay
	)
	_apply_layout()

	var success := SETUP_VALIDATOR.print_result() and _validate_current_contract()
	if _should_auto_start_default_character():
		_start_selected_run(_resolve_run_seed())
	else:
		_show_character_selection()
	print(
		"B17A_READY os=%s viewport=%s window=%s display_safe=%s playfield=%s safe_area=%s friend=%s seed=%d"
		% [
			OS.get_name(),
			get_viewport().get_visible_rect(),
			DisplayServer.window_get_size(),
			DisplayServer.get_display_safe_area(),
			_arena_layout.get_playfield_rect(),
			_arena_layout.get_safe_area_rect(),
			_player.get_friend_definition().id,
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


func get_game_director() -> GameDirector:
	return _game_director


func get_friend_registry() -> FriendRegistry:
	return _friend_registry


func get_player() -> Player:
	return _player


func get_friend_passive_controller() -> FriendPassiveController:
	return _friend_passive_controller


func get_character_select_overlay() -> CharacterSelectOverlay:
	return _character_select_overlay


func get_boss_encounter() -> BossEncounter:
	return _boss_encounter


func get_boss_ui() -> BossUI:
	return _boss_ui


func get_boss_projectile_parent() -> Node2D:
	return _boss_projectiles


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


func get_combat_feedback() -> CombatFeedback:
	return _combat_feedback


func get_arena_view() -> ArenaView:
	return _arena_view


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


func get_vignette_effect() -> VignetteEffect:
	return _vignette_effect


func get_experience_dropper() -> ExperienceDropper:
	return _experience_dropper


func get_game_audio() -> GameAudio:
	return _game_audio


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
		_show_terminal_screen(
			_run_controller.get_state(),
			_run_controller.get_run_time()
		)
		return false

	_player.global_position = _arena_layout.get_playfield_center()
	_input_router.resume_input()
	return true


func select_friend_for_next_run(friend_id: StringName) -> bool:
	if _run_controller.get_state() != RunController.RunState.BOOT:
		return false
	return _equip_friend(friend_id)


func start_selected_run(seed_value: int = 0) -> bool:
	if _run_controller.get_state() != RunController.RunState.BOOT:
		return false
	var resolved_seed := seed_value if seed_value != 0 else _resolve_run_seed()
	return _start_selected_run(resolved_seed)


func _resolve_run_seed() -> int:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--run-seed="):
			return int(argument.trim_prefix("--run-seed="))
	if OS.get_cmdline_user_args().has("--smoke-test"):
		return 1
	return int(Time.get_unix_time_from_system())


func _should_auto_start_default_character() -> bool:
	return (
		DisplayServer.get_name() == "headless"
		or OS.get_cmdline_user_args().has("--smoke-test")
		or OS.get_cmdline_user_args().has("--skip-character-select")
	)


func _equip_friend(friend_id: StringName) -> bool:
	var definition := _friend_registry.resolve_definition(friend_id)
	if definition == null or not _friend_passive_controller.is_supported_definition(definition):
		return false
	var ability_definition := _ability_effect_registry.resolve_definition(
		definition.active_ability_id
	)
	if ability_definition == null or not ability_definition.is_valid():
		return false
	if not _player.set_friend_definition(definition):
		return false
	if is_instance_valid(_hud) and _hud.is_node_ready():
		_hud.set_friend_definition(definition)
	if not _ability_controller.equip_definition(ability_definition):
		return false
	if not _friend_passive_controller.equip_definition(definition):
		return false
	return true


func _start_selected_run(seed_value: int) -> bool:
	if not _run_controller.start_run(seed_value):
		return false
	_character_select_overlay.hide_selection()
	_hud.show()
	_touch_joystick.show()
	_player.global_position = _arena_layout.get_playfield_center()
	_input_router.resume_input()
	return true


func _show_character_selection() -> void:
	_input_router.suspend_input()
	_player.clear_movement_input()
	_hud.hide()
	_touch_joystick.hide()
	var current_friend := _player.get_friend_definition()
	_character_select_overlay.show_selection(
		current_friend.id if current_friend != null else &"magno"
	)


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
	if _friend_registry == null:
		failures.append("FriendRegistry B17 non presente.")
	else:
		if not _friend_registry.is_catalog_valid():
			failures.append(
				"FriendRegistry B17 non valido: %s."
				% "; ".join(_friend_registry.get_validation_errors())
			)
		if _friend_registry.get_definitions().size() != 8:
			failures.append("Il catalogo B17 deve contenere gli otto amici approvati.")
		if not _friend_registry.is_catalog_publication_ready():
			failures.append("Il catalogo B17 contiene profili o asset non approvati.")
		var player_friend := _player.get_friend_definition()
		if player_friend == null or _friend_registry.resolve_definition(player_friend.id) != player_friend:
			failures.append("Il Player non usa un profilo amico registrato.")
		for friend_definition in _friend_registry.get_definitions():
			if not _friend_passive_controller.is_supported_definition(friend_definition):
				failures.append("Passiva B17A non supportata: %s." % friend_definition.id)
			if not friend_definition.has_directional_gameplay_animation():
				failures.append(
					"Animazione laterale Player mancante: %s."
					% friend_definition.id
				)
			var roster_ability := _ability_effect_registry.resolve_definition(
				friend_definition.active_ability_id
			)
			if roster_ability == null or not roster_ability.is_valid():
				failures.append("AbilityDefinition B17A mancante: %s." % friend_definition.id)
			elif friend_definition.id == &"bea":
				if (
					roster_ability.title != "Powerslide"
					or not is_equal_approx(roster_ability.duration_seconds, 4.0)
					or roster_ability.icon == null
					or roster_ability.icon.resource_path != "res://assets/art/icons/abilities/powerslide.svg"
				):
					failures.append("Powerslide B18D non rispetta dati, durata o icona approvati.")
			elif friend_definition.id == &"alea":
				if (
					roster_ability.effect_id != AbilityEffectRegistry.GRAND_SPIN
					or not is_equal_approx(roster_ability.duration_seconds, 1.2)
					or not is_equal_approx(roster_ability.area_radius, 140.0)
				):
					failures.append("Gran Piroetta B18F non rispetta durata o area approvate.")
	var player_health := _player.get_health_component()
	if player_health == null:
		failures.append("Player privo di HealthComponent.")
	elif player_health.invulnerability_duration <= 0.0:
		failures.append("Invulnerabilita Player non configurata.")
	if _run_controller == null:
		failures.append("RunController non presente.")
	if _game_director == null:
		failures.append("GameDirector non presente.")
	else:
		if not _game_director.has_valid_configuration():
			failures.append("GameDirector privo di una configurazione valida.")
		if _game_director.get_run_controller() != _run_controller:
			failures.append("GameDirector non collegato al RunController.")
		if _game_director.get_enemy_spawner() != _enemy_spawner:
			failures.append("GameDirector non collegato a EnemySpawner.")
		var boss_thresholds := _game_director.get_thresholds()
		if (
			boss_thresholds.size() != 1
			or not is_equal_approx(boss_thresholds[0], 240.0)
		):
			failures.append("Il profilo Director MVP deve schedulare il Boss a 04:00.")
	if _boss_encounter == null:
		failures.append("BossEncounter non presente.")
	else:
		if not _boss_encounter.has_valid_configuration():
			failures.append("BossEncounter privo di una configurazione valida.")
		if _boss_encounter.get_run_controller() != _run_controller:
			failures.append("BossEncounter non collegato al RunController.")
		if _boss_encounter.get_game_director() != _game_director:
			failures.append("BossEncounter non collegato al GameDirector.")
		if _boss_encounter.get_targeting_system() != _targeting_system:
			failures.append("BossEncounter non collegato al TargetingSystem.")
		if _boss_encounter.get_boss_ui() != _boss_ui:
			failures.append("BossEncounter non collegato alla UI Boss.")
		if _boss_encounter.get_boss_projectile_parent() != _boss_projectiles:
			failures.append("BossEncounter non collegato ai proiettili Boss.")
		var boss_definition := _boss_encounter.boss_definition
		if boss_definition == null or not boss_definition.is_valid():
			failures.append("BossEncounter privo di BossDefinition valida.")
		else:
			if (
				_friend_registry == null
				or boss_definition.friend_profile == null
				or _friend_registry.resolve_definition(boss_definition.friend_profile.id)
				!= boss_definition.friend_profile
			):
				failures.append("Il Boss B17 non usa una controparte Evil registrata.")
			elif (
				boss_definition.get_safe_title()
				!= boss_definition.friend_profile.get_public_evil_display_name()
			):
				failures.append("Il titolo Boss non deriva dal profilo Evil dati.")
			if (
				not boss_definition.quote_approved
				and boss_definition.get_safe_quote() != boss_definition.safe_quote_placeholder
			):
				failures.append("La citazione Boss non approvata deve usare il placeholder sicuro.")
	if _boss_ui == null:
		failures.append("BossUI non presente.")
	elif _boss_ui.is_intro_visible() or _boss_ui.is_boss_health_visible():
		failures.append("BossUI deve essere nascosta prima della soglia Boss.")
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
	else:
		if _pause_overlay.get_volume_slider() == null:
			failures.append("PauseOverlay B18 privo del controllo volume.")
		if _pause_overlay.get_mute_check_button() == null:
			failures.append("PauseOverlay B18 privo del controllo mute.")
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
	if _ability_effect_registry.get_arena_layout() != _arena_layout:
		failures.append("AbilityEffectRegistry B17A non collegato ad ArenaLayout.")
	if _ability_effect_registry.get_definitions().size() != 8:
		failures.append("AbilityEffectRegistry B17A deve contenere otto abilita.")
	var ability_icon_paths: Dictionary = {}
	for roster_definition in _ability_effect_registry.get_definitions():
		if roster_definition.icon == null:
			failures.append("Icona abilita B18 mancante: %s." % roster_definition.id)
			continue
		var ability_icon_path := roster_definition.icon.resource_path
		if ability_icon_path.is_empty() or ability_icon_path.ends_with("/icon.svg"):
			failures.append("Icona abilita B18 ancora generica: %s." % roster_definition.id)
		ability_icon_paths[ability_icon_path] = true
	if ability_icon_paths.size() != 8:
		failures.append("Le otto abilita B18 devono avere icone dedicate e distinguibili.")
	if _friend_passive_controller.get_definition() != _player.get_friend_definition():
		failures.append("La passiva B17A non corrisponde al profilo Player.")
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
		var equipped_friend := _player.get_friend_definition()
		if (
			equipped_friend != null
			and ability_definition != null
			and equipped_friend.active_ability_id != ability_definition.id
		):
			failures.append("Il profilo selezionato non corrisponde all'AbilityDefinition equipaggiata.")
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
	for upgrade_definition in _upgrade_registry.get_definitions():
		if (
			upgrade_definition.icon == null
			or upgrade_definition.icon.resource_path.is_empty()
			or upgrade_definition.icon.resource_path.ends_with("/icon.svg")
		):
			failures.append("Icona upgrade B18 ancora generica: %s." % upgrade_definition.id)
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
		failures.append("UpgradeEffectRegistry non configurato per il catalogo B13.")
	if _upgrade_effect_registry.get_upgrade_service() != _upgrade_service:
		failures.append("UpgradeEffectRegistry non collegato a UpgradeService.")
	if _upgrade_effect_registry.get_upgrade_registry() != _upgrade_registry:
		failures.append("UpgradeEffectRegistry non collegato a UpgradeRegistry.")
	if _upgrade_effect_registry.get_player() != _player:
		failures.append("UpgradeEffectRegistry non collegato al Player.")
	if _upgrade_effect_registry.get_weapon_controller() != _weapon_controller:
		failures.append("UpgradeEffectRegistry non collegato all'arma.")
	if _upgrade_effect_registry.get_run_controller() != _run_controller:
		failures.append("UpgradeEffectRegistry non collegato al clock della run.")
	if _upgrade_effect_registry.get_targeting_system() != _targeting_system:
		failures.append("UpgradeEffectRegistry non collegato ai bersagli B13.")
	if _upgrade_effect_registry.get_vignette_effect() != _vignette_effect:
		failures.append("UpgradeEffectRegistry non collegato alla vignetta B13.")
	if _upgrade_effect_registry.get_effect_parent() != _ability_effects:
		failures.append("UpgradeEffectRegistry non collegato ai VFX B13.")
	for signature_id in [
		&"anxiety_signature",
		&"gossip_projectiles",
		&"chronic_delay",
		&"beer_signature",
		&"damage_shockwave",
	]:
		var signature_definition := _upgrade_registry.resolve_definition(signature_id)
		if (
			signature_definition == null
			or signature_definition.effect_id != signature_id
			or not _upgrade_effect_registry.can_apply(signature_definition)
		):
			failures.append("Upgrade signature B13 non valido: %s." % signature_id)
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
	if not is_equal_approx(_player.get_health_max_multiplier(), 1.0):
		failures.append("La run deve iniziare con la vita massima base.")
	if (
		_weapon_controller.is_projectile_chain_enabled()
		or _weapon_controller.get_projectile_chain_jumps() != 0
		or not is_zero_approx(
			_weapon_controller.get_projectile_oscillation_amplitude()
		)
	):
		failures.append("La run deve iniziare senza modificatori proiettile B13.")
	if _vignette_effect.visible or not is_zero_approx(_vignette_effect.intensity):
		failures.append("La vignetta B13 deve essere disattiva a inizio run.")
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
	if _experience_dropper.get_arena_layout() != _arena_layout:
		failures.append("ExperienceDropper non collegato ad ArenaLayout.")
	if _experience_dropper.get_pickup_parent() != _pickups:
		failures.append("ExperienceDropper non collegato al contenitore Pickups.")
	if _experience_dropper.pickup_scene != null:
		var pickup_candidate := _experience_dropper.pickup_scene.instantiate()
		if not pickup_candidate is ExperiencePickup:
			failures.append("La scena pickup non istanzia ExperiencePickup.")
		if is_instance_valid(pickup_candidate):
			pickup_candidate.free()
	if _game_audio == null:
		failures.append("GameAudio B18 non presente.")
	else:
		if not _game_audio.is_configured():
			failures.append("GameAudio B18 non collegato agli eventi di gioco.")
		if not _game_audio.has_complete_cue_set():
			failures.append("GameAudio B18 privo di uno o piu cue obbligatori.")
		if _game_audio.get_player_pool_size() < 8:
			failures.append("GameAudio B18 richiede playback concorrente senza tagli evidenti.")
	if not (
		_ability_effects.z_index < _enemies.z_index
		and _ability_effects.z_index < _player.z_index
		and _ability_effects.z_index < _boss_projectiles.z_index
	):
		failures.append("I VFX B18 devono restare sotto attori e attacchi ostili.")
	if _boss_projectiles.z_index <= _projectiles.z_index:
		failures.append("I proiettili Boss B18 devono avere priorita visiva massima nel mondo.")
	if _arena_view == null or _arena_view.uses_debug_grid():
		failures.append("ArenaView B18B non deve usare la griglia debug regolare.")
	elif _arena_view.get_floor_feature_budget().values().has(0):
		failures.append("ArenaView B18B richiede variazioni, giunti, macchie e crepe.")
	if _combat_feedback == null:
		failures.append("CombatFeedback B18B non presente.")
	else:
		if _combat_feedback.get_run_controller() != _run_controller:
			failures.append("CombatFeedback B18B non collegato al RunController.")
		if _combat_feedback.get_enemy_spawner() != _enemy_spawner:
			failures.append("CombatFeedback B18B non collegato a EnemySpawner.")
		if _combat_feedback.get_player() != _player:
			failures.append("CombatFeedback B18B non collegato al Player.")
		if _combat_feedback.get_boss_encounter() != _boss_encounter:
			failures.append("CombatFeedback B18B non collegato al BossEncounter.")
		if not (
			_ability_effects.z_index < _combat_feedback.z_index
			and _combat_feedback.z_index < _player.z_index
			and _combat_feedback.z_index < _projectiles.z_index
		):
			failures.append("Il feedback B18B deve restare tra aree alleate e attori prioritari.")
	if _end_screen == null:
		failures.append("EndScreen non presente.")
	elif _end_screen.visible:
		failures.append("EndScreen deve essere nascosto durante la run.")
	if _character_select_overlay == null:
		failures.append("CharacterSelectOverlay B17A non presente.")
	elif _character_select_overlay.get_roster_size() != 8:
		failures.append("CharacterSelectOverlay B17A deve esporre otto profili.")
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
		if _hud.get_friend_definition() != _player.get_friend_definition():
			failures.append("HUD B18B privo del profilo Player corrente.")
		var top_band_rect := _hud.get_top_band_rect()
		if top_band_rect.size.y < 63.0 or top_band_rect.size.y > 72.0:
			failures.append("La fascia HUD B18B deve restare alta circa 64-72 unita logiche.")
		var xp_line_rect := _hud.get_experience_panel_rect()
		if xp_line_rect.size.y < 6.0 or xp_line_rect.size.y > 8.5:
			failures.append("La linea XP B18B deve restare alta 6-8 unita logiche.")
		var ability_panel_rect := _hud.get_ability_panel_rect()
		if (
			ability_panel_rect.size.x < 230.0
			or ability_panel_rect.size.x > 250.0
			or ability_panel_rect.size.y < 88.0
			or ability_panel_rect.size.y > 96.0
		):
			failures.append("La card abilita B18B deve restare circa 230-250 x 88-96.")
		if _hud.get_portrait_texture() == null:
			failures.append("La fascia HUD B18B deve mostrare il ritratto corrente.")
		if not _hud.get_experience_panel_rect().has_area():
			failures.append("HUD privo di una barra XP con layout valido.")
		if not _hud.get_pause_button_rect().has_area():
			failures.append("HUD privo di un pulsante pausa con layout valido.")
		if not _hud.get_active_ability_button_rect().has_area():
			failures.append("HUD privo del pulsante abilita touch.")
		elif (
			_hud.get_active_ability_button_rect().size.x < 44.0
			or _hud.get_active_ability_button_rect().size.y < 44.0
		):
			failures.append("Il pulsante abilita B18B deve conservare un target touch di 44 unita.")
		if (
			_hud.get_pause_button_rect().size.x < 44.0
			or _hud.get_pause_button_rect().size.y < 44.0
		):
			failures.append("Il pulsante pausa B18B deve conservare un target touch di 44 unita.")
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
		print("B13_CONTRACT_OK")
		print("B14_CONTRACT_OK")
		print("B15_CONTRACT_OK")
		print("B16_CONTRACT_OK")
		print("B17_CONTRACT_OK")
		print("B17A_CONTRACT_OK")
		print("B18_CONTRACT_OK")
		print("B18B_CONTRACT_OK")
		print("B18C_CONTRACT_OK")
		print("B18D_CONTRACT_OK")
		print("B18F_CONTRACT_OK")
		return true

	for failure in failures:
		push_error(failure)
	printerr("B18F_CONTRACT_FAIL")
	return false


func _on_player_died(player: Player) -> void:
	if player != _player or _run_controller.is_terminal():
		return
	_input_router.suspend_input()
	_player.clear_movement_input()
	_run_controller.request_defeat()


func _on_run_ended(final_state: RunController.RunState, run_time: float) -> void:
	_show_terminal_screen(final_state, run_time)


func _on_boss_defeated(_boss: FirstBoss, _experience_reward: int) -> void:
	if _run_controller.is_terminal():
		return
	_input_router.suspend_input()
	_player.clear_movement_input()
	_run_controller.request_victory()


func _show_terminal_screen(
	final_state: RunController.RunState,
	run_time: float
) -> void:
	match final_state:
		RunController.RunState.VICTORY:
			_end_screen.show_victory(
				run_time,
				_boss_encounter.get_last_defeated_title(),
				_boss_encounter.get_last_experience_reward()
			)
		RunController.RunState.DEFEAT:
			_end_screen.show_defeat(run_time)


func _on_restart_requested() -> void:
	restart_run()


func _on_change_character_requested() -> void:
	if not _run_controller.is_terminal():
		return
	_input_router.suspend_input()
	_player.clear_movement_input()
	_end_screen.hide_end_screen()
	_run_controller.prepare_restart()
	_show_character_selection()


func _on_friend_confirmed(friend_id: StringName) -> void:
	if not select_friend_for_next_run(friend_id):
		_character_select_overlay.show_selection(friend_id)
		return
	if not start_selected_run():
		_character_select_overlay.show_selection(friend_id)


func _on_pause_requested() -> void:
	_platform_lifecycle.request_manual_pause()
