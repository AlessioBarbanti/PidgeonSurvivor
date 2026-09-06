extends Control

const SETUP_VALIDATOR = preload("res://scripts/app/setup_validator.gd")
const B22_PHYSICAL_VERIFICATION_FLAG := "user://b22_physical_verification.flag"
const B22_PHYSICAL_VERIFICATION_SEED := 4
const B22_PHYSICAL_AUTODEFEAT_DELAY_SECONDS := 8.0

## Impostato da tests/unit/helpers/gameplay_test.gd su questa istanza, prima
## che entri nell'albero, cosicche' l'auto-avvio headless in _ready() usi un
## seed fisso invece dell'orologio di sistema (PS-032). Zero fuori dai test:
## non tocca --run-seed=, --smoke-test ne' l'eseguibile esportato.
var gut_test_run_seed_override := 0

@export_group("Safe Area Controls")
## Extra left/bottom distance from the OS safe area for edge gestures.
## Values are viewport units, so they stay independent from device pixels.
@export var gesture_navigation_padding := Vector2(16.0, 32.0)
@export var joystick_edge_padding := Vector2(24.0, 24.0)
## Visual breathing room for HUD actions after the OS safe area.
## The ability keeps this inset in addition to the mandatory gesture padding.
@export var hud_control_edge_padding := Vector2(20.0, 20.0)
## PS-085: extra vertical lift for the active-ability button, in both fire
## modes, so it reads as intentionally clear of the aim joystick's corner
## instead of flush with it. The joystick itself is dynamic-origin and
## invisible at rest, so this is a cosmetic margin, not a collision budget.
@export_range(0.0, 200.0, 1.0) var ability_panel_aim_lift := 72.0

@export_group("Performance Hardening")
@export var windows_performance_profile: PerformanceProfile
@export var mobile_performance_profile: PerformanceProfile

@onready var _arena_layout: ArenaLayout = %ArenaLayout
@onready var _arena_world: ArenaWorld = %ArenaWorld
@onready var _camera: Camera2D = %Camera2D
@onready var _run_controller: RunController = %RunController
@onready var _visual_accessibility_settings: VisualAccessibilitySettings = %VisualAccessibilitySettings
@onready var _touch_control_settings: TouchControlSettings = %TouchControlSettings
@onready var _fire_mode_settings: FireModeSettings = %FireModeSettings
@onready var _friend_registry: FriendRegistry = %FriendRegistry
@onready var _game_director: GameDirector = %GameDirector
@onready var _boss_encounter: BossEncounter = %BossEncounter
@onready var _enemy_spawner: EnemySpawner = %EnemySpawner
@onready var _wave_event_scheduler: WaveEventScheduler = %WaveEventScheduler
@onready var _targeting_system: TargetingSystem = %TargetingSystem
@onready var _ability_effect_registry: AbilityEffectRegistry = %AbilityEffectRegistry
@onready var _friend_passive_controller: FriendPassiveController = %FriendPassiveController
@onready var _experience_system: ExperienceSystem = %ExperienceSystem
@onready var _upgrade_registry: UpgradeRegistry = %UpgradeRegistry
@onready var _upgrade_service: UpgradeService = %UpgradeService
@onready var _upgrade_effect_registry: UpgradeEffectRegistry = %UpgradeEffectRegistry
@onready var _experience_dropper: ExperienceDropper = %ExperienceDropper
@onready var _health_pickup_dropper: HealthPickupDropper = %HealthPickupDropper
@onready var _game_audio: GameAudio = %GameAudio
@onready var _arena_view: ArenaView = %ArenaView
@onready var _player: Player = %Player
@onready var _enemies: Node2D = %Enemies
@onready var _projectiles: Node2D = %Projectiles
@onready var _boss_projectiles: Node2D = %BossProjectiles
@onready var _pickups: Node2D = %Pickups
@onready var _health_pickups: Node2D = %HealthPickups
@onready var _ability_effects: Node2D = %AbilityEffects
@onready var _combat_feedback: CombatFeedback = %CombatFeedback
@onready var _weapon_controller: WeaponController = _player.get_weapon_controller()
@onready var _ability_controller: AbilityController = _player.get_ability_controller()
@onready var _input_router: InputRouter = %InputRouter
@onready var _platform_lifecycle: PlatformLifecycle = %PlatformLifecycle
@onready var _performance_stress_harness: PerformanceStressHarness = %PerformanceStressHarness
@onready var _touch_joystick: TouchJoystick = %TouchJoystick
@onready var _aim_touch_joystick: TouchJoystick = %AimTouchJoystick
@onready var _vignette_effect: VignetteEffect = %VignetteEffect
@onready var _safe_area_root: Control = %SafeAreaRoot
@onready var _performance_monitor: PerformanceMonitor = %PerformanceMonitor
@onready var _hud: GameHud = %HUD
@onready var _boss_ui: BossUI = %BossUI
@onready var _upgrade_overlay: UpgradeOverlay = %UpgradeOverlay
@onready var _barb_reward_overlay: BarbRewardOverlay = %BarbRewardOverlay
@onready var _welcome_screen: WelcomeScreen = %WelcomeScreen
@onready var _tutorial_screen: TutorialScreen = %TutorialScreen
@onready var _character_select_overlay: CharacterSelectOverlay = %CharacterSelectOverlay
@onready var _pause_overlay: PauseOverlay = %PauseOverlay
@onready var _end_screen: EndScreen = %EndScreen

var _last_logged_safe_area := Rect2()
var _last_logged_joystick_rect := Rect2()
## PS-053: nessun sistema tiene gia' un totale dei Boss sconfitti nella run
## (solo il segnale boss_defeated e l'ultimo titolo); il riepilogo finale lo
## richiede, quindi il conteggio vive qui invece che in BossEncounter.
var _defeated_boss_count := 0


func _ready() -> void:
	_input_router.bind_touch_joystick(_touch_joystick)
	_input_router.bind_aim_touch_joystick(_aim_touch_joystick)
	_input_router.bind_aim_origin(_player)
	_input_router.bind_active_ability_button(_hud.get_active_ability_button())
	_input_router.movement_vector_changed.connect(_on_movement_vector_changed)
	_input_router.manual_aim_changed.connect(_on_manual_aim_changed)
	_arena_layout.playfield_changed.connect(_on_playfield_changed)
	_run_controller.state_changed.connect(_on_run_state_changed_for_joystick)
	_player.died.connect(_on_player_died)
	_run_controller.run_ended.connect(_on_run_ended)
	_boss_encounter.boss_spawned.connect(_on_boss_spawned_for_horde_pause)
	_boss_encounter.boss_defeated.connect(_on_boss_defeated_for_horde_pause)
	_boss_encounter.boss_defeated.connect(_on_boss_defeated_for_barb_reward)
	_boss_encounter.boss_defeated.connect(_on_boss_defeated_for_summary)
	_run_controller.run_started.connect(_on_run_started_for_summary)
	_hud.pause_requested.connect(_on_pause_requested)
	_end_screen.restart_requested.connect(_on_restart_requested)
	_end_screen.change_character_requested.connect(_on_change_character_requested)
	_pause_overlay.change_character_requested.connect(_on_change_character_requested)
	_welcome_screen.play_requested.connect(_on_welcome_play_requested)
	_welcome_screen.tutorial_requested.connect(_on_welcome_tutorial_requested)
	_welcome_screen.audio_volume_changed.connect(_on_welcome_audio_volume_changed)
	_welcome_screen.audio_mute_toggled.connect(_on_welcome_audio_mute_toggled)
	_welcome_screen.reduced_flashes_toggled.connect(_on_welcome_reduced_flashes_toggled)
	_tutorial_screen.close_requested.connect(_on_tutorial_close_requested)
	_tutorial_screen.play_requested.connect(_on_tutorial_play_requested)
	_character_select_overlay.friend_confirmed.connect(_on_friend_confirmed)
	_character_select_overlay.back_requested.connect(_on_character_selection_back_requested)
	_platform_lifecycle.configure(
		_run_controller,
		_input_router,
		_pause_overlay
	)
	_platform_lifecycle.set_boot_back_handler(_on_boot_back_requested)
	_visual_accessibility_settings.configure(_pause_overlay)
	_touch_control_settings.configure(_welcome_screen, _pause_overlay)
	_touch_control_settings.settings_changed.connect(_on_touch_control_settings_changed)
	_fire_mode_settings.configure(_welcome_screen, _pause_overlay)
	_fire_mode_settings.settings_changed.connect(_on_fire_mode_settings_changed)

	_arena_layout.set_top_reserved_height(_hud.get_gameplay_top_inset())
	_arena_layout.refresh_layout()
	var world_rect := _arena_world.get_world_rect()
	_camera.limit_left = int(world_rect.position.x)
	_camera.limit_top = int(world_rect.position.y)
	_camera.limit_right = int(world_rect.end.x)
	_camera.limit_bottom = int(world_rect.end.y)
	_player.set_arena_layout(_arena_layout)
	_player.set_world_bounds(world_rect)
	_hud.set_ability_fade_target(_camera, _player, _player.collision_radius)
	_player.set_run_controller(_run_controller)
	_player.global_position = _arena_world.get_world_center()
	_recenter_camera_on_player()
	_player.set_movement_input(_input_router.movement_vector)
	_game_director.configure(_run_controller, _enemy_spawner)
	_enemy_spawner.configure(
		_run_controller,
		_arena_layout,
		_player,
		_enemies,
		_camera,
		_boss_projectiles
	)
	_wave_event_scheduler.configure(
		_run_controller,
		_game_director,
		_enemy_spawner
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
		_arena_layout,
		_visual_accessibility_settings
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
		_boss_ui,
		_friend_registry,
		_camera
	)
	_upgrade_service.configure(
		_upgrade_registry,
		_run_controller,
		_experience_system
	)
	_upgrade_overlay.configure(_upgrade_service, _touch_joystick)
	_barb_reward_overlay.configure(_upgrade_service, _touch_joystick)
	_experience_dropper.configure(
		_run_controller,
		_enemy_spawner,
		_experience_system,
		_player,
		_arena_layout,
		_pickups
	)
	_experience_dropper.set_world_bounds(world_rect)
	_health_pickup_dropper.configure(
		_run_controller,
		_enemy_spawner,
		_player,
		_arena_layout,
		_health_pickups
	)
	_health_pickup_dropper.set_world_bounds(world_rect)
	_weapon_controller.configure(
		_run_controller,
		_targeting_system,
		_projectiles,
		_player,
		_arena_layout
	)
	_weapon_controller.set_manual_fire_enabled(_fire_mode_settings.is_manual_fire_enabled())
	_friend_passive_controller.configure(
		_run_controller,
		_player,
		_weapon_controller,
		_targeting_system,
		_experience_system
	)
	_friend_passive_controller.instinctive_dodge_triggered.connect(
		_on_instinctive_dodge_triggered
	)
	_ability_controller.configure(
		_run_controller,
		_input_router,
		_ability_effect_registry,
		_player
	)
	_upgrade_effect_registry.configure(
		_upgrade_service,
		_upgrade_registry,
		_player,
		_weapon_controller,
		_vignette_effect,
		_ability_effects,
		_ability_controller
	)
	_equip_friend(&"magno")
	_hud.configure(
		_run_controller,
		_player.get_health_component(),
		_experience_system,
		_ability_controller,
		_game_director,
		_wave_event_scheduler
	)
	_hud.set_friend_definition(_player.get_friend_definition())
	_character_select_overlay.configure(_friend_registry, _ability_effect_registry)
	_game_audio.configure(
		_run_controller,
		_player,
		_weapon_controller,
		_ability_controller,
		_experience_system,
		_boss_encounter,
		_upgrade_overlay,
		_barb_reward_overlay,
		_character_select_overlay,
		_pause_overlay
	)
	_game_audio.settings_changed.connect(_welcome_screen.set_audio_settings)
	_visual_accessibility_settings.settings_changed.connect(
		_welcome_screen.set_reduced_flashes
	)
	_visual_accessibility_settings.settings_changed.connect(
		_tutorial_screen.set_reduced_flashes
	)
	_welcome_screen.set_audio_settings(
		_game_audio.get_effects_volume(),
		_game_audio.is_muted()
	)
	_welcome_screen.set_reduced_flashes(
		_visual_accessibility_settings.is_reduced_flashes_enabled()
	)
	_tutorial_screen.set_reduced_flashes(
		_visual_accessibility_settings.is_reduced_flashes_enabled()
	)
	_apply_touch_control_settings(
		_touch_control_settings.get_ability_scale(),
		_touch_control_settings.get_joystick_scale()
	)
	_apply_layout()
	_configure_performance_hardening()

	var success := SETUP_VALIDATOR.print_result() and _validate_current_contract()
	if _should_auto_start_default_character():
		_start_selected_run(_resolve_run_seed())
	else:
		_show_welcome_screen()
	call_deferred("_start_b18v_stress_from_args")
	call_deferred("_start_b22_physical_verification_from_flag")
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


func _on_manual_aim_changed(direction: Vector2, active: bool) -> void:
	_weapon_controller.set_manual_aim_state(direction, active)


func _on_playfield_changed(_playfield_rect: Rect2) -> void:
	_apply_layout()


func _on_run_state_changed_for_joystick(
	_previous_state: RunController.RunState,
	current_state: RunController.RunState
) -> void:
	var running := current_state == RunController.RunState.RUNNING
	_touch_joystick.set_capture_enabled(running)
	_sync_aim_touch_joystick_capture(running)


## PS-085: joystick di mira attivo solo mentre la run e' RUNNING e la
## modalita' e' Manuale — in Automatico resta disabilitato anche a schermo
## visibile, cosi' non ruba mai un tocco al joystick di movimento.
func _sync_aim_touch_joystick_capture(running: bool) -> void:
	_aim_touch_joystick.set_capture_enabled(
		running and _fire_mode_settings.is_manual_fire_enabled()
	)


func _sync_aim_touch_joystick_visibility() -> void:
	if _fire_mode_settings.is_manual_fire_enabled() and _touch_joystick.visible:
		_aim_touch_joystick.show()
	else:
		_aim_touch_joystick.hide()


func _on_fire_mode_settings_changed(manual_enabled: bool) -> void:
	_weapon_controller.set_manual_fire_enabled(manual_enabled)
	if is_node_ready():
		_apply_layout()
	_sync_aim_touch_joystick_capture(_run_controller.is_running())
	_sync_aim_touch_joystick_visibility()


func _is_dynamic_joystick_origin_valid(viewport_position: Vector2) -> bool:
	if not _run_controller.is_running():
		return false
	if _hud.is_touch_origin_excluded(viewport_position):
		return false
	return not (
		_upgrade_overlay.visible
		or _barb_reward_overlay.visible
		or _character_select_overlay.visible
		or _pause_overlay.visible
		or _end_screen.visible
		or _boss_ui.is_intro_visible()
	)


func _apply_layout() -> void:
	var safe_area := _arena_layout.get_safe_area_rect()
	if not safe_area.has_area():
		safe_area = get_viewport().get_visible_rect()

	_safe_area_root.position = safe_area.position
	_safe_area_root.size = safe_area.size
	_apply_bar_horizontal_margins(safe_area)
	_upgrade_overlay.apply_safe_area(safe_area)
	_barb_reward_overlay.apply_safe_area(safe_area)

	var joystick_rect := calculate_bottom_left_control_rect(
		safe_area,
		_touch_joystick.custom_minimum_size,
		joystick_edge_padding,
		gesture_navigation_padding
	)
	_touch_joystick.position = joystick_rect.position - safe_area.position
	_touch_joystick.size = joystick_rect.size

	var aim_joystick_rect := calculate_bottom_right_control_rect(
		safe_area,
		_aim_touch_joystick.custom_minimum_size,
		joystick_edge_padding,
		gesture_navigation_padding
	)
	_aim_touch_joystick.position = aim_joystick_rect.position - safe_area.position
	_aim_touch_joystick.size = aim_joystick_rect.size

	# PS-085: in automatico il joystick di movimento resta invariato (tutta la
	# safe area, come da B18L); in manuale la meta' destra e' riservata alla
	# mira, cosi' i due tocchi non si contendono la stessa origine dinamica.
	var manual_fire_enabled := _fire_mode_settings.is_manual_fire_enabled()
	_touch_joystick.configure_dynamic_capture(
		calculate_dynamic_movement_capture_rect(
			safe_area,
			joystick_edge_padding,
			gesture_navigation_padding,
			manual_fire_enabled
		),
		_is_dynamic_joystick_origin_valid
	)
	_aim_touch_joystick.configure_dynamic_capture(
		calculate_dynamic_aim_capture_rect(
			safe_area,
			joystick_edge_padding,
			gesture_navigation_padding,
			manual_fire_enabled
		),
		_is_dynamic_joystick_origin_valid
	)
	var world_rect := _arena_world.get_world_rect()
	_arena_view.update_layout(
		world_rect,
		world_rect
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


func _apply_bar_horizontal_margins(safe_area: Rect2) -> void:
	# Le barre XP/HP escono dalla safe area: quel rettangolo rientra solo dal
	# lato del cutout e le lascerebbe staccate da un bordo e a filo sull'altro.
	# Le ancoriamo invece al viewport con margini simmetrici percentuali.
	if not is_instance_valid(_hud):
		return
	var viewport_rect := get_viewport().get_visible_rect()
	if not viewport_rect.has_area():
		return
	var margin := viewport_rect.size.x * GameHud.BAR_HORIZONTAL_MARGIN_RATIO
	# Offset relativi ai bordi della HUD, che coincidono con la safe area.
	_hud.set_bar_horizontal_offsets(
		viewport_rect.position.x + margin - safe_area.position.x,
		viewport_rect.end.x - margin - safe_area.end.x
	)


func _apply_touch_control_settings(
	ability_scale: float,
	joystick_scale: float
) -> void:
	_hud.set_pause_edge_padding(hud_control_edge_padding)
	# PS-085: il pulsante abilita' sale leggermente rispetto al bordo, in
	# entrambe le modalita' di sparo (decisione: il layout non deve mai
	# saltare quando si cambia modalita'). Il joystick di mira e' a origine
	# dinamica come quello di movimento: resta invisibile a riposo e non
	# disegna nulla nel suo angolo (TouchJoystick._draw()), quindi non serve
	# riservargli l'intera altezza di controllo, solo un margine di cortesia.
	_hud.set_active_ability_scale(
		ability_scale,
		hud_control_edge_padding + gesture_navigation_padding + Vector2(0.0, ability_panel_aim_lift)
	)
	_touch_joystick.set_control_scale(joystick_scale)
	_aim_touch_joystick.set_control_scale(joystick_scale)
	if is_node_ready():
		_apply_layout()


func get_touch_joystick_viewport_rect() -> Rect2:
	if not is_node_ready():
		return Rect2()
	return Rect2(
		_safe_area_root.position + _touch_joystick.position,
		_touch_joystick.size
	)


func get_touch_joystick_capture_rect() -> Rect2:
	return _touch_joystick.get_capture_rect() if is_node_ready() else Rect2()


func get_aim_touch_joystick_viewport_rect() -> Rect2:
	if not is_node_ready():
		return Rect2()
	return Rect2(
		_safe_area_root.position + _aim_touch_joystick.position,
		_aim_touch_joystick.size
	)


func get_aim_touch_joystick_capture_rect() -> Rect2:
	return _aim_touch_joystick.get_capture_rect() if is_node_ready() else Rect2()


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


static func calculate_dynamic_joystick_capture_rect(
	safe_area: Rect2,
	edge_padding: Vector2,
	gesture_padding: Vector2
) -> Rect2:
	if not safe_area.has_area():
		return Rect2(safe_area.position, Vector2.ZERO)

	var left_margin := maxf(edge_padding.x, 0.0) + maxf(
		gesture_padding.x,
		0.0
	)
	var right_margin := left_margin
	var top_margin := maxf(edge_padding.y, 0.0)
	var bottom_margin := top_margin + maxf(gesture_padding.y, 0.0)
	var available_size := safe_area.size - Vector2(
		left_margin + right_margin,
		top_margin + bottom_margin
	)
	if available_size.x <= 0.0 or available_size.y <= 0.0:
		return Rect2(safe_area.get_center(), Vector2.ZERO)
	return Rect2(
		safe_area.position + Vector2(left_margin, top_margin),
		available_size
	)


## Specchio di calculate_bottom_left_control_rect() per il riposo del
## joystick di mira (PS-085): stesso angolo che occupava il pulsante
## abilita' prima del suo spostamento verso l'alto.
static func calculate_bottom_right_control_rect(
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
			safe_area.end.x - fitted_size.x - applied_padding.x,
			safe_area.end.y - fitted_size.y - applied_padding.y
		),
		fitted_size
	)


## PS-085: in automatico il movimento conserva l'intera safe area dinamica
## (comportamento B18L invariato, criterio di accettazione "nessuna
## regressione sull'automatico"); in manuale si ferma alla meta' sinistra,
## lasciando la destra alla mira.
static func calculate_dynamic_movement_capture_rect(
	safe_area: Rect2,
	edge_padding: Vector2,
	gesture_padding: Vector2,
	manual_fire_enabled: bool
) -> Rect2:
	var full_rect := calculate_dynamic_joystick_capture_rect(
		safe_area,
		edge_padding,
		gesture_padding
	)
	if not manual_fire_enabled or not full_rect.has_area():
		return full_rect
	return Rect2(
		full_rect.position,
		Vector2(full_rect.size.x * 0.5, full_rect.size.y)
	)


## Specchio di calculate_dynamic_movement_capture_rect(): nullo in
## automatico (il joystick di mira e' nascosto e non deve mai catturare un
## tocco), meta' destra della stessa zona dinamica in manuale.
static func calculate_dynamic_aim_capture_rect(
	safe_area: Rect2,
	edge_padding: Vector2,
	gesture_padding: Vector2,
	manual_fire_enabled: bool
) -> Rect2:
	if not manual_fire_enabled:
		return Rect2(safe_area.get_center(), Vector2.ZERO)
	var full_rect := calculate_dynamic_joystick_capture_rect(
		safe_area,
		edge_padding,
		gesture_padding
	)
	if not full_rect.has_area():
		return full_rect
	var half_width := full_rect.size.x * 0.5
	return Rect2(
		Vector2(full_rect.position.x + half_width, full_rect.position.y),
		Vector2(half_width, full_rect.size.y)
	)


func get_run_controller() -> RunController:
	return _run_controller


func get_enemy_spawner() -> EnemySpawner:
	return _enemy_spawner


func get_wave_event_scheduler() -> WaveEventScheduler:
	return _wave_event_scheduler


func get_arena_layout() -> ArenaLayout:
	return _arena_layout


func get_arena_world() -> ArenaWorld:
	return _arena_world


func get_camera() -> Camera2D:
	return _camera


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


func get_welcome_screen() -> WelcomeScreen:
	return _welcome_screen


func get_tutorial_screen() -> TutorialScreen:
	return _tutorial_screen


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


func get_barb_reward_overlay() -> BarbRewardOverlay:
	return _barb_reward_overlay


func get_upgrade_effect_registry() -> UpgradeEffectRegistry:
	return _upgrade_effect_registry


func get_vignette_effect() -> VignetteEffect:
	return _vignette_effect


func get_experience_dropper() -> ExperienceDropper:
	return _experience_dropper


func get_health_pickup_dropper() -> HealthPickupDropper:
	return _health_pickup_dropper


func get_game_audio() -> GameAudio:
	return _game_audio


func get_visual_accessibility_settings() -> VisualAccessibilitySettings:
	return _visual_accessibility_settings


func get_touch_control_settings() -> TouchControlSettings:
	return _touch_control_settings


func get_pickup_parent() -> Node2D:
	return _pickups


func get_health_pickup_parent() -> Node2D:
	return _health_pickups


func get_end_screen() -> EndScreen:
	return _end_screen


func get_hud() -> GameHud:
	return _hud


func get_touch_joystick() -> TouchJoystick:
	return _touch_joystick


func get_aim_touch_joystick() -> TouchJoystick:
	return _aim_touch_joystick


func get_fire_mode_settings() -> FireModeSettings:
	return _fire_mode_settings


func get_platform_lifecycle() -> PlatformLifecycle:
	return _platform_lifecycle


func get_performance_monitor() -> PerformanceMonitor:
	return _performance_monitor


func get_performance_stress_harness() -> PerformanceStressHarness:
	return _performance_stress_harness


func get_active_performance_profile() -> PerformanceProfile:
	return _resolve_performance_profile()


func get_pause_overlay() -> PauseOverlay:
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

	_player.global_position = _arena_world.get_world_center()
	_recenter_camera_on_player()
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


func run_b18v_restart_profile_cycle(friend_id: StringName, seed_value: int) -> bool:
	if not _run_controller.is_running() or seed_value == 0:
		return false
	_input_router.suspend_input()
	_player.clear_movement_input()
	_run_controller.prepare_restart()
	if not select_friend_for_next_run(friend_id):
		return false
	return start_selected_run(seed_value)


## PS-082: dopo un teletrasporto del player, `align()` deve precedere
## `reset_smoothing()`. La Camera2D con drag margin insegue il target solo
## entro una dead zone: `camera_pos` (l'ancora del drag) resta quello della
## posizione precedente finche' un frame di processo non lo ricalcola, e lo
## fa agganciando il player al bordo del margine, non al centro. `align()`
## ricalcola subito `camera_pos` esattamente sul target; solo a quel punto
## `reset_smoothing()` puo' azzerare anche il ritardo di smoothing visivo.
## Scambiare l'ordine, o omettere `align()`, lascia la camera visibilmente
## sfalsata del margine di drag (qui 35%) fin dal primo frame.
func _recenter_camera_on_player() -> void:
	_camera.align()
	_camera.reset_smoothing()


func _configure_performance_hardening() -> void:
	var profile := _resolve_performance_profile()
	if profile == null or not profile.is_valid():
		push_error("B18V: PerformanceProfile non valido.")
		return
	_combat_feedback.set_max_active_effects(profile.max_transient_feedback)
	var sources := {
		&"arena": _arena_layout,
		&"controller": _run_controller,
		&"player": _player,
		&"enemies": _enemies,
		&"projectiles": _projectiles,
		&"boss_projectiles": _boss_projectiles,
		&"pickups": _pickups,
		&"ability_registry": _ability_effect_registry,
		&"feedback": _combat_feedback,
		&"audio": _game_audio,
		&"targeting": _targeting_system,
	}
	_performance_monitor.configure(profile, sources)
	_performance_monitor.set_overlay_enabled(
		OS.get_cmdline_user_args().has("--performance-overlay")
	)
	_performance_stress_harness.configure(self, profile, sources)


func _resolve_performance_profile() -> PerformanceProfile:
	if OS.get_name() == "Android":
		return mobile_performance_profile
	return windows_performance_profile


func _start_b18v_stress_from_args() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.has("--b18v-stress") and not args.has("--b18v-soak"):
		return
	if not _run_controller.is_running():
		return
	var duration := 1200.0 if args.has("--b18v-soak") else 60.0
	if _performance_stress_harness.start(duration):
		print("B18V_CONTRACT_OK")


func _start_b22_physical_verification_from_flag() -> void:
	if not _has_b22_physical_verification_flag():
		return
	var flag_path := ProjectSettings.globalize_path(B22_PHYSICAL_VERIFICATION_FLAG)
	var removal_error := DirAccess.remove_absolute(flag_path)
	if removal_error != OK:
		push_error(
			"B22 physical verification: impossibile consumare il flag monouso (%d)."
			% removal_error
		)
		return
	if not _run_controller.is_running():
		push_error("B22 physical verification: run debug non avviata.")
		return
	var thresholds := _game_director.get_thresholds()
	if thresholds.is_empty():
		push_error("B22 physical verification: soglia Boss assente.")
		return
	if not _boss_encounter.boss_intro_completed.is_connected(
		_on_b22_physical_verification_intro_completed
	):
		_boss_encounter.boss_intro_completed.connect(
			_on_b22_physical_verification_intro_completed,
			CONNECT_ONE_SHOT
		)
	print(
		"B22_PHYSICAL_VERIFICATION_ARMED seed=%d threshold=%.2f"
		% [_run_controller.get_seed(), thresholds[0]]
	)
	# Advance only the debug run clock through the normal Director signal path.
	# Boss definition, scene, stats, patterns, UI, reward and terminal flow stay unchanged.
	_run_controller._process(thresholds[0] + 0.01)
	var definition := _boss_encounter.get_active_definition()
	var boss := _boss_encounter.get_active_boss()
	if (
		_run_controller.get_state() != RunController.RunState.BOSS_INTRO
		or not is_instance_valid(boss)
		or definition == null
	):
		push_error("B22 physical verification: intro Boss non raggiunta.")
		return
	print(
		"B22_PHYSICAL_BOSS_INTRO id=%s title=%s evil=%s"
		% [definition.id, definition.get_safe_title(), definition.is_evil_variant()]
	)


func _on_b22_physical_verification_intro_completed(
	boss: FirstBoss,
	schedule_index: int
) -> void:
	print(
		"B22_PHYSICAL_BOSS_ACTIVE schedule=%d pattern=%s"
		% [schedule_index, boss.get_active_pattern_id()]
	)
	await get_tree().create_timer(B22_PHYSICAL_AUTODEFEAT_DELAY_SECONDS).timeout
	if (
		not is_instance_valid(boss)
		or boss != _boss_encounter.get_active_boss()
		or not _run_controller.is_running()
	):
		return
	var health := boss.get_health_component()
	if health == null or not boss.take_damage(health.health_current):
		push_error("B22 physical verification: auto-defeat Boss fallita.")
		return
	print("B22_PHYSICAL_BOSS_AUTODEFEAT damage=%.1f" % health.health_max)


func _has_b22_physical_verification_flag() -> bool:
	return (
		OS.is_debug_build()
		and OS.get_name() == "Android"
		and FileAccess.file_exists(B22_PHYSICAL_VERIFICATION_FLAG)
	)


func _resolve_run_seed() -> int:
	if _has_b22_physical_verification_flag():
		return B22_PHYSICAL_VERIFICATION_SEED
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--run-seed="):
			return int(argument.trim_prefix("--run-seed="))
	if OS.get_cmdline_user_args().has("--smoke-test"):
		return 1
	if gut_test_run_seed_override != 0:
		return gut_test_run_seed_override
	return int(Time.get_unix_time_from_system())


func _should_auto_start_default_character() -> bool:
	if _has_b22_physical_verification_flag():
		return true
	if (
		OS.get_cmdline_user_args().has("--show-welcome")
		or bool(ProjectSettings.get_setting(
			"application/run/b18o_force_welcome_for_test",
			false
		))
	):
		return false
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
	if not _upgrade_service.set_equipped_ability_id(ability_definition.id):
		return false
	if not _friend_passive_controller.equip_definition(definition):
		return false
	return true


func _start_selected_run(seed_value: int) -> bool:
	if not _run_controller.start_run(seed_value):
		return false
	_game_audio.stop_menu_music()
	_character_select_overlay.hide_selection()
	_welcome_screen.hide_welcome()
	_tutorial_screen.hide_tutorial()
	_hud.show()
	_touch_joystick.show()
	_sync_aim_touch_joystick_visibility()
	_player.global_position = _arena_world.get_world_center()
	_recenter_camera_on_player()
	_input_router.resume_input()
	return true


func _show_character_selection() -> void:
	_input_router.suspend_input()
	_player.clear_movement_input()
	_hud.hide()
	_touch_joystick.hide()
	_aim_touch_joystick.hide()
	_welcome_screen.hide_welcome()
	_tutorial_screen.hide_tutorial()
	_game_audio.start_menu_music()
	var current_friend := _player.get_friend_definition()
	_character_select_overlay.show_selection(
		current_friend.id if current_friend != null else &"magno"
	)
	print("B18O_CHARACTER_SELECT_SHOWN")


func _show_welcome_screen(focus_tutorial: bool = false) -> void:
	if _run_controller.get_state() != RunController.RunState.BOOT:
		return
	_input_router.suspend_input()
	_player.clear_movement_input()
	_hud.hide()
	_touch_joystick.hide()
	_aim_touch_joystick.hide()
	_character_select_overlay.hide_selection()
	_tutorial_screen.hide_tutorial()
	_game_audio.start_menu_music()
	_welcome_screen.show_welcome(focus_tutorial)
	print("B18O_WELCOME_SHOWN")


func _show_tutorial_screen() -> void:
	if _run_controller.get_state() != RunController.RunState.BOOT:
		return
	_input_router.suspend_input()
	_player.clear_movement_input()
	_hud.hide()
	_touch_joystick.hide()
	_aim_touch_joystick.hide()
	_character_select_overlay.hide_selection()
	_welcome_screen.hide_welcome()
	_game_audio.start_menu_music()
	_tutorial_screen.show_tutorial(
		_visual_accessibility_settings.is_reduced_flashes_enabled()
	)
	print("B54_TUTORIAL_SHOWN")


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
	if not _touch_joystick.dynamic_origin:
		failures.append("B18L richiede il joystick dinamico.")
	elif not _touch_joystick.get_capture_rect().has_area():
		failures.append("B18L richiede una zona di acquisizione dinamica valida.")
	elif _touch_joystick.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		failures.append("B18L non deve intercettare il secondo dito via GUI.")
	if not _aim_touch_joystick.dynamic_origin:
		failures.append("PS-085 richiede il joystick di mira dinamico.")
	elif _aim_touch_joystick.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		failures.append("PS-085 non deve intercettare il secondo dito via GUI.")
	for action in [&"aim_left", &"aim_right", &"aim_up", &"aim_down", &"manual_fire_hold"]:
		if not InputMap.has_action(action):
			failures.append("InputMap privo di %s." % action)
	if _weapon_controller.is_manual_fire_enabled() != _fire_mode_settings.is_manual_fire_enabled():
		failures.append("WeaponController non riflette FireModeSettings.")
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
			elif roster_ability.rank_snapshots.size() != 5:
				failures.append("AbilityDefinition B18G priva di cinque rank: %s." % friend_definition.id)
			else:
				for rank in range(1, 6):
					var ranked_definition := roster_ability.resolve_rank(rank)
					if ranked_definition == null or ranked_definition.get_resolved_rank() != rank:
						failures.append(
							"Snapshot B18G non valido per %s rank %d."
							% [friend_definition.id, rank]
						)
			if roster_ability != null and friend_definition.id == &"bea":
				if (
					roster_ability.title != "Powerslide"
					or not is_equal_approx(roster_ability.duration_seconds, 4.0)
					or roster_ability.icon == null
					or roster_ability.icon.resource_path != "res://assets/art/icons/abilities/generated/powerslide.png"
				):
					failures.append("Powerslide B18D non rispetta dati, durata o icona approvati.")
			elif roster_ability != null and friend_definition.id == &"alea":
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
			or not is_equal_approx(boss_thresholds[0], 120.0)
		):
			failures.append("Il profilo Director PS-005 deve schedulare il Boss a 02:00.")
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
		if _boss_encounter.get_friend_registry() != _friend_registry:
			failures.append("BossEncounter B22 non collegato al catalogo amici.")
		var boss_definition := _boss_encounter.boss_definition
		if boss_definition == null or not boss_definition.is_valid():
			failures.append("BossEncounter privo di BossDefinition valida.")
		else:
			if (
				boss_definition.is_evil_variant()
				or boss_definition.friend_profile != null
				or boss_definition.id != &"special_pigeon"
			):
				failures.append("B22 richiede il piccione speciale come Boss baseline.")
			if not is_equal_approx(_boss_encounter.evil_boss_chance, 0.5):
				failures.append("PS-037 richiede evil_boss_chance dati al 50%.")
			if (
				not boss_definition.quote_approved
				and boss_definition.get_safe_quote() != boss_definition.safe_quote_placeholder
			):
				failures.append("La citazione Boss non approvata deve usare il placeholder sicuro.")
	if _boss_ui == null:
		failures.append("BossUI non presente.")
	elif _boss_ui.is_intro_visible():
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
		if _pause_overlay.get_reduced_flashes_check_button() == null:
			failures.append("PauseOverlay B18E privo dell'opzione Flash ridotti.")
		if (
			_pause_overlay.get_ability_size_slider() == null
			or _pause_overlay.get_joystick_size_slider() == null
		):
			failures.append("PauseOverlay B18P privo delle scale touch.")
		if _pause_overlay.get_change_character_button() == null:
			failures.append("PauseOverlay B18N privo di Cambia personaggio.")
		if (
			_pause_overlay.get_cancel_change_button() == null
			or _pause_overlay.get_confirm_change_button() == null
		):
			failures.append("PauseOverlay B18N privo della conferma di abbandono run.")
	if _welcome_screen == null:
		failures.append("WelcomeScreen B18O non presente.")
	else:
		if _welcome_screen.get_play_button() == null:
			failures.append("WelcomeScreen B18O priva di GIOCA.")
		if _welcome_screen.get_tutorial_button() == null:
			failures.append("WelcomeScreen B54 priva di TUTORIAL.")
		if _welcome_screen.get_settings_button() == null:
			failures.append("WelcomeScreen B18O priva di IMPOSTAZIONI.")
		if (
			_welcome_screen.get_ability_size_slider() == null
			or _welcome_screen.get_joystick_size_slider() == null
		):
			failures.append("WelcomeScreen B18P priva delle scale touch.")
		if (
			_welcome_screen.get_volume_slider() == null
			or _welcome_screen.get_mute_check_button() == null
			or _welcome_screen.get_reduced_flashes_check_button() == null
		):
			failures.append("WelcomeScreen B18O priva delle impostazioni correnti.")
	if _tutorial_screen == null:
		failures.append("TutorialScreen B54 non presente.")
	elif (
		_tutorial_screen.get_page_count() != 6
		or _tutorial_screen.get_page_ids()
		!= [&"objective", &"movement", &"ability", &"progression", &"enemies", &"boss"]
	):
		failures.append("TutorialScreen B54 deve esporre le sei pagine autorevoli.")
	if _character_select_overlay.get_back_button() == null:
		failures.append("Il selettore B18O deve esporre INDIETRO.")
	if _visual_accessibility_settings == null:
		failures.append("VisualAccessibilitySettings B18E non presente.")
	elif (
		_ability_effect_registry.get_visual_settings()
		!= _visual_accessibility_settings
	):
		failures.append("AbilityEffectRegistry B18E non collegato alle impostazioni visuali.")
	if _touch_control_settings == null:
		failures.append("TouchControlSettings B18P non presente.")
	else:
		if (
			_touch_control_settings.get_ability_scale()
			< TouchControlSettings.MIN_ABILITY_SCALE
			or _touch_control_settings.get_ability_scale()
			> TouchControlSettings.MAX_ABILITY_SCALE
		):
			failures.append("La scala abilita B18P deve restare nell'intervallo sicuro.")
		if (
			_touch_control_settings.get_joystick_scale()
			< TouchControlSettings.MIN_JOYSTICK_SCALE
			or _touch_control_settings.get_joystick_scale()
			> TouchControlSettings.MAX_JOYSTICK_SCALE
		):
			failures.append("La scala joystick B18P deve restare nell'intervallo sicuro.")
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
	if _wave_event_scheduler == null:
		failures.append("WaveEventScheduler PS-008 non presente.")
	else:
		if not _wave_event_scheduler.has_valid_configuration():
			failures.append("WaveEventScheduler PS-008 privo di una configurazione valida.")
		if _wave_event_scheduler.get_run_controller() != _run_controller:
			failures.append("WaveEventScheduler PS-008 non collegato al RunController.")
		if _wave_event_scheduler.get_game_director() != _game_director:
			failures.append("WaveEventScheduler PS-008 non collegato al GameDirector.")
		if _wave_event_scheduler.get_enemy_spawner() != _enemy_spawner:
			failures.append("WaveEventScheduler PS-008 non collegato a EnemySpawner.")
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
	var ability_rank_definitions := 0
	for upgrade_definition in _upgrade_registry.get_definitions():
		if upgrade_definition.effect_id != UpgradeEffectRegistry.ABILITY_RANK:
			continue
		ability_rank_definitions += 1
		if not upgrade_definition.is_ability_rank_definition():
			failures.append("Carta rank B18G non valida: %s." % upgrade_definition.id)
	if ability_rank_definitions != 8:
		failures.append("B18G richiede una carta rank autorevole per ciascuna delle otto abilita.")
	var summer_grill := _upgrade_registry.resolve_definition(&"summer_grill")
	if (
		summer_grill == null
		or summer_grill.effect_id != UpgradeEffectRegistry.SUMMER_GRILL
		or summer_grill.max_rank != 5
		or not _upgrade_effect_registry.can_apply(summer_grill)
	):
		failures.append("B18J richiede Grigliata estiva dati a cinque rank.")
	if _upgrade_registry.get_repeatable_definitions().size() < UpgradeService.DEFAULT_OFFER_SIZE:
		failures.append("UpgradeRegistry privo di tre potenziamenti normali ripetibili.")
	if not _upgrade_service.has_valid_configuration():
		failures.append("UpgradeService non configurato per offerte da tre carte.")
	if _upgrade_service.get_registry() != _upgrade_registry:
		failures.append("UpgradeService non collegato a UpgradeRegistry.")
	if _upgrade_service.get_run_controller() != _run_controller:
		failures.append("UpgradeService non collegato al RunController.")
	if (
		_ability_controller != null
		and _upgrade_service.get_equipped_ability_id() != _ability_controller.get_definition().id
	):
		failures.append("UpgradeService B18G non sincronizzato con l'abilita equipaggiata.")
	if _ability_controller != null and _ability_controller.get_ability_rank() != 1:
		failures.append("Ogni run B18G deve iniziare con l'abilita al rank 1.")
	if _upgrade_service.get_experience_system() != _experience_system:
		failures.append("UpgradeService non collegato a ExperienceSystem.")
	if _upgrade_registry.get_speciality_definitions().size() != 8:
		failures.append("UpgradeRegistry deve contenere le otto Specialità di Barb PS-077.")
	if _upgrade_service.get_locked_speciality_definitions().size() != 8:
		failures.append("Ogni run deve iniziare con tutte le Specialità di Barb bloccate.")
	if _upgrade_service.is_barb_reward_active():
		failures.append("La run non deve iniziare con una ricompensa Barb già attiva.")
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
			_weapon_controller.get_projectile_aim_spread_degrees()
		)
	):
		failures.append("La run deve iniziare senza modificatori proiettile B13.")
	if (
		_weapon_controller.get_effective_pierce_count() != 1
		or _weapon_controller.get_effective_multishot_count() != 1
		or _weapon_controller.is_death_burst_enabled()
	):
		failures.append("La run deve iniziare senza forme d'attacco B41.")
	if _vignette_effect.visible or not is_zero_approx(_vignette_effect.intensity):
		failures.append("La vignetta B13 deve essere disattiva a inizio run.")
	if _barb_reward_overlay == null:
		failures.append("BarbRewardOverlay non presente.")
	else:
		if _barb_reward_overlay.get_upgrade_service() != _upgrade_service:
			failures.append("BarbRewardOverlay non collegato a UpgradeService.")
		if _barb_reward_overlay.get_touch_joystick() != _touch_joystick:
			failures.append("BarbRewardOverlay non collegato al joystick touch.")
		if _barb_reward_overlay.visible:
			failures.append("BarbRewardOverlay deve essere nascosto senza una ricompensa Boss attiva.")
		if _barb_reward_overlay.get_cards().size() != 3:
			failures.append("BarbRewardOverlay deve avere tre slot carta disponibili.")
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
	if _arena_view != null:
		if not _arena_view.has_raster_background():
			failures.append("ArenaView B18S privo dello sfondo raster ImageGen.")
		elif _arena_view.uses_procedural_fallback():
			failures.append("ArenaView B18S non deve usare il fallback procedurale nel runtime.")
		if _arena_view.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST:
			failures.append("ArenaView B18S deve preservare il campionamento pixel-art.")
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
		if (
			not is_equal_approx(
				_combat_feedback.death_burst_duration,
				PresentationTimings.DEATH_BURST_SECONDS
			)
			or not is_equal_approx(
				_combat_feedback.player_damage_duration,
				PresentationTimings.PLAYER_DAMAGE_BURST_SECONDS
			)
		):
			failures.append("B18R richiede timing feedback centralizzati.")
	if not PresentationTimings.is_valid():
		failures.append("B18R richiede timing presentazionali validi e separati dal gameplay.")
	if (
		not is_equal_approx(
			_player.damage_reaction_duration,
			PresentationTimings.PLAYER_DAMAGE_REACTION_SECONDS
		)
		or _player.damage_flash_duration > 0.08
	):
		failures.append("B18R deve allungare la reazione Player mantenendo breve il flash.")
	if _ability_effect_registry.get_active_visual_tail_count() != 0:
		failures.append("B18R non deve iniziare una run con code visive residue.")
	if _end_screen == null:
		failures.append("EndScreen non presente.")
	elif _end_screen.visible:
		failures.append("EndScreen deve essere nascosto durante la run.")
	if _character_select_overlay == null:
		failures.append("CharacterSelectOverlay B17A non presente.")
	elif _character_select_overlay.get_roster_size() != 8:
		failures.append("CharacterSelectOverlay B17A deve esporre otto profili.")
	else:
		if _character_select_overlay.get_previous_button() == null:
			failures.append("B18T richiede la navigazione precedente del carosello.")
		if _character_select_overlay.get_next_button() == null:
			failures.append("B18T richiede la navigazione successiva del carosello.")
		if (
			_character_select_overlay.get_confirm_button() == null
			or _character_select_overlay.get_confirm_button().custom_minimum_size.y < 44.0
		):
			failures.append("B18T richiede una conferma separata con target minimo 44x44.")
		if (
			_character_select_overlay.get_back_button() == null
			or _character_select_overlay.get_back_button().text != "INDIETRO"
		):
			failures.append("B18W richiede Back distinto in alto con copy naturale.")
		if _character_select_overlay.get_ability_panel_rect().size.x < 260.0:
			failures.append("B18W richiede il pannello laterale dedicato a passiva e abilita.")
		var selection_backdrop := _character_select_overlay.get_backdrop()
		if (
			selection_backdrop == null
			or selection_backdrop.texture == null
			or selection_backdrop.texture.resource_path
			!= "res://assets/art/ui/character_select/character_select_backdrop.png"
		):
			failures.append("B18W richiede il fondale pixel-art tracciato del selettore.")
		var cta_style := (
			_character_select_overlay.get_confirm_button().get_theme_stylebox("normal")
			as StyleBoxTexture
		)
		if (
			cta_style == null
			or cta_style.texture == null
		):
			failures.append("B18W richiede il CTA ornamentale ImageGen.")
		for definition in _friend_registry.get_definitions():
			var selection_portrait := definition.get_public_selection_portrait()
			if selection_portrait == null or selection_portrait.get_size() != Vector2(256.0, 256.0):
				failures.append("B18T richiede un ritratto carosello HD derivato per %s." % definition.id)
	var character_sprite := _player.get_node_or_null("CharacterSprite") as Sprite2D
	if character_sprite == null:
		failures.append("B18U richiede lo sprite Player dati.")
	elif character_sprite.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST:
		failures.append("B18U deve mostrare le strisce Player con filtro nearest.")
	for friend_definition in _friend_registry.get_definitions():
		var expected_cast_path := (
			"res://assets/art/characters/%s/generated/sprite.png" % friend_definition.id
		)
		var cast_idle := friend_definition.get_gameplay_idle_right() as AtlasTexture
		var cast_walk := friend_definition.get_gameplay_walk_right_frames()
		if (
			cast_idle == null
			or cast_idle.atlas == null
			or cast_idle.atlas.resource_path != expected_cast_path
			or cast_idle.get_size() != Vector2(32.0, 32.0)
		):
			failures.append("B18U idle originale mancante per %s." % friend_definition.id)
		if cast_walk.size() != 4:
			failures.append("B18U richiede quattro fasi per %s." % friend_definition.id)
			continue
		for cast_frame in cast_walk:
			var cast_atlas := cast_frame as AtlasTexture
			if (
				cast_atlas == null
				or cast_atlas.atlas == null
				or cast_atlas.atlas.resource_path != expected_cast_path
				or cast_atlas.get_size() != Vector2(32.0, 32.0)
			):
				failures.append("B18U frame originale non valido per %s." % friend_definition.id)
				break
		if cast_walk[0] == cast_idle or cast_walk[2] == cast_idle or cast_walk[0] == cast_walk[2]:
			failures.append("B18U richiede due passi distinti per %s." % friend_definition.id)
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
		if _hud.get_game_director() != _game_director:
			failures.append("HUD PS-005 non collegato al GameDirector.")
		if _hud.get_wave_event_scheduler() != _wave_event_scheduler:
			failures.append("HUD PS-008 non collegato al WaveEventScheduler.")
		if _hud.is_wave_event_telegraph_visible():
			failures.append("HUD PS-008 deve partire senza telegraph d'ondata visibile.")
		if _hud.is_boss_warning_visible():
			failures.append("HUD PS-005 deve partire senza warning Boss visibile.")
		if _hud.get_friend_definition() != _player.get_friend_definition():
			failures.append("HUD B18B privo del profilo Player corrente.")
		var top_band_rect := _hud.get_top_band_rect()
		if absf(top_band_rect.size.y - _hud.get_gameplay_top_inset()) > 1.0:
			failures.append("La fascia HUD B18Q deve coincidere con l'inset gameplay dichiarato.")
		var xp_line_rect := _hud.get_experience_panel_rect()
		var health_line_rect := _hud.get_health_panel_rect()
		var hud_viewport_rect := get_viewport().get_visible_rect()
		if absf(xp_line_rect.size.y - 18.0) > 1.0:
			failures.append("La barra XP B18Q deve essere alta 18 unita logiche.")
		if absf(health_line_rect.size.y - 20.0) > 1.0:
			failures.append("La barra vita B18Q deve essere alta 20 unita logiche.")
		if _hud.get_experience_kind_text() != "XP" or _hud.get_health_kind_text() != "HP":
			failures.append("Le barre B18Q devono mostrare soltanto i tag fissi XP e HP.")
		# UI-004: le barre ignorano la safe area asimmetrica e si allineano al
		# viewport con margini orizzontali simmetrici.
		var expected_bar_margin := (
			hud_viewport_rect.size.x * GameHud.BAR_HORIZONTAL_MARGIN_RATIO
		)
		var xp_left_margin := xp_line_rect.position.x - hud_viewport_rect.position.x
		var xp_right_margin := hud_viewport_rect.end.x - xp_line_rect.end.x
		var health_left_margin := (
			health_line_rect.position.x - hud_viewport_rect.position.x
		)
		var health_right_margin := hud_viewport_rect.end.x - health_line_rect.end.x
		if (
			absf(xp_left_margin - expected_bar_margin) > 1.0
			or absf(xp_right_margin - expected_bar_margin) > 1.0
			or absf(health_left_margin - expected_bar_margin) > 1.0
			or absf(health_right_margin - expected_bar_margin) > 1.0
		):
			failures.append(
				"Le barre XP e vita B18Q devono avere margini simmetrici sul viewport."
			)
		if _arena_layout.get_playfield_rect().position.y < top_band_rect.end.y - 1.0:
			failures.append("Il playfield B18Q deve iniziare sotto l'intera fascia HUD.")
		var ability_panel_rect := _hud.get_ability_panel_rect()
		var expected_ability_size := (
			TouchAbilityButton.BASE_TARGET_SIZE
			* _touch_control_settings.get_ability_scale()
		)
		if (
			absf(ability_panel_rect.size.x - expected_ability_size) > 1.0
			or absf(ability_panel_rect.size.y - expected_ability_size) > 1.0
		):
			failures.append("B18P deve scalare insieme pannello e target abilita.")
		if _hud.get_portrait_texture() != null or _hud.get_portrait_rect().has_area():
			failures.append("B18Q deve rimuovere il ritratto Player dall'HUD.")
		if (
			not _hud.get_health_text().is_empty()
			or not _hud.get_experience_text().is_empty()
			or not _hud.get_level_text().is_empty()
		):
			failures.append("B18Q non deve mostrare livello, label o valori numerici.")
		if _hud.find_child("TimerPanel", true, false) != null:
			failures.append("Il cronometro B18Q deve essere flottante e senza card.")
		if not _hud.get_experience_panel_rect().has_area():
			failures.append("HUD privo di una barra XP con layout valido.")
		if not _hud.get_pause_button_rect().has_area():
			failures.append("HUD privo di un pulsante pausa con layout valido.")
		if not _hud.get_active_ability_button_rect().has_area():
			failures.append("HUD privo del pulsante abilita touch.")
		elif (
			_hud.get_active_ability_button_rect().size.x < TouchAbilityButton.BASE_TARGET_SIZE
			or _hud.get_active_ability_button_rect().size.y < TouchAbilityButton.BASE_TARGET_SIZE
		):
			failures.append("Il pulsante abilita B31 deve conservare il target touch base raddoppiato.")
		var ability_button := _hud.get_active_ability_button()
		if ability_button == null:
			failures.append("B18K richiede un TouchAbilityButton valido.")
		elif ability_button.get_ability_icon() != _ability_controller.get_definition().icon:
			failures.append("Il pulsante B18K deve usare l'icona dell'abilita equipaggiata.")
		elif not ability_button.text.is_empty():
			failures.append("Il pulsante B18K non deve mostrare testo esterno all'icona.")
		elif not ability_button.get_theme_stylebox("normal") is StyleBoxEmpty:
			failures.append("Il pulsante B18K non deve disegnare un rettangolo di sfondo.")
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
			var enemy_sprite := (
				enemy_candidate.get_node_or_null("EnemySprite") as AnimatedSprite2D
			)
			if enemy_sprite == null:
				failures.append("B18H richiede il piccione animato sul nemico ordinario.")
			elif (
				not enemy_sprite.sprite_frames.has_animation(&"base")
				or not enemy_sprite.sprite_frames.has_animation(&"special")
				or enemy_sprite.sprite_frames.get_frame_count(&"base") != 3
				or enemy_sprite.sprite_frames.get_frame_count(&"special") != 3
			):
				failures.append("B18H richiede tre pose per i piccioni base e speciale.")
		else:
			failures.append("La scena nemico non istanzia BaseEnemy.")
		if is_instance_valid(enemy_candidate):
			enemy_candidate.free()
	var performance_profile := _resolve_performance_profile()
	if performance_profile == null or not performance_profile.is_valid():
		failures.append("B18V richiede un PerformanceProfile valido.")
	if _performance_monitor == null or _performance_monitor.get_profile() != performance_profile:
		failures.append("B18V richiede il monitor configurato con il profilo corrente.")
	if _performance_stress_harness == null:
		failures.append("B18V richiede lo stress harness scene-local.")
	if _combat_feedback.max_active_effects != performance_profile.max_transient_feedback:
		failures.append("B18V deve applicare il budget VFX dichiarativo.")

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
		print("B18E_CONTRACT_OK")
		print("B18F_CONTRACT_OK")
		print("B18G_CONTRACT_OK")
		print("B18H_CONTRACT_OK")
		print("B18I_CONTRACT_OK")
		print("B18J_CONTRACT_OK")
		print("B18K_CONTRACT_OK")
		print("B18L_CONTRACT_OK")
		print("B18M_CONTRACT_OK")
		print("B18N_CONTRACT_OK")
		print("B18O_CONTRACT_OK")
		print("B18P_CONTRACT_OK")
		print("B18Q_CONTRACT_OK")
		print("B18R_CONTRACT_OK")
		print("B18S_CONTRACT_OK")
		print("B18T_CONTRACT_OK")
		print("B18U_CONTRACT_OK")
		print("B18W_CONTRACT_OK")
		print("B18V_CONTRACT_OK")
		print("B54_CONTRACT_OK")
		return true

	for failure in failures:
		push_error(failure)
	printerr("B18V_CONTRACT_FAIL")
	return false


func _on_player_died(player: Player) -> void:
	if player != _player or _run_controller.is_terminal():
		return
	_input_router.suspend_input()
	_player.clear_movement_input()
	_run_controller.request_defeat()


func _on_run_ended(final_state: RunController.RunState, run_time: float) -> void:
	_show_terminal_screen(final_state, run_time)


## B53: lo spawn ordinario si ferma per tutta la presenza di un Boss attivo
## (dall'ingresso effettivo, non dalla sola richiesta) e riprende alla sua
## uscita. EnemySpawner resta la fonte autorevole del cap e della sequenza
## RNG: qui si tocca solo il flag di sospensione.
func _on_boss_spawned_for_horde_pause(_boss: FirstBoss, _schedule_index: int) -> void:
	_enemy_spawner.set_ordinary_spawn_suspended(true)


func _on_boss_defeated_for_horde_pause(_boss: FirstBoss) -> void:
	_enemy_spawner.set_ordinary_spawn_suspended(false)


## La ricompensa Boss (PS-012) resta accodata da UpgradeService se la run non
## e' gia' RUNNING nello stesso istante (es. un level-up di un nemico ordinario
## in corso, o un nuovo Boss gia' pendente): riparte da sola non appena lo
## stato torna RUNNING.
func _on_boss_defeated_for_barb_reward(_boss: FirstBoss) -> void:
	_barb_reward_overlay.set_redeemed_friend_name(_boss_encounter.get_last_defeated_friend_name())
	_upgrade_service.queue_barb_reward()


## Tell del Sesto Senso Equino di Bea (B45): la passiva non conosce nodi
## visivi o audio, emette solo posizione e direzione; questa e' la stessa
## responsabilita' gia' svolta da AbilityEffectRegistry per le abilita' attive.
func _on_instinctive_dodge_triggered(position: Vector2, direction: Vector2) -> void:
	if not is_instance_valid(_ability_effects):
		return
	var accent := InstinctiveDodgeAccent.new()
	accent.name = "InstinctiveDodgeAccent"
	_ability_effects.add_child(accent)
	if not accent.initialize(position, direction, _run_controller):
		accent.queue_free()
		return
	_game_audio.play_cue(GameAudio.DODGE, -3.0)


func _show_terminal_screen(
	final_state: RunController.RunState,
	run_time: float
) -> void:
	var summary := _build_run_summary(run_time)
	match final_state:
		RunController.RunState.VICTORY:
			_end_screen.show_victory(
				summary,
				_boss_encounter.get_last_defeated_title()
			)
		RunController.RunState.DEFEAT:
			_end_screen.show_defeat(summary)


## PS-053: costruisce lo snapshot dai dati gia' posseduti da run, esperienza,
## Boss e servizio upgrade, cosi' EndScreen non dipende direttamente dai
## sistemi di gameplay.
func _build_run_summary(run_time: float) -> RunSummary:
	var summary := RunSummary.new()
	var friend := _player.get_friend_definition()
	if friend != null:
		summary.character_name = friend.get_public_display_name()
		summary.character_portrait = friend.get_public_selection_portrait()
	summary.level = _experience_system.level
	summary.bosses_defeated = _defeated_boss_count
	summary.run_time = run_time
	summary.top_upgrades = _build_top_upgrade_entries()
	return summary


## Rango decrescente; a parita' di rango l'id testuale decide, cosi' il
## risultato non cambia riaprendo la stessa schermata (PS-053).
func _build_top_upgrade_entries() -> Array[RunSummary.UpgradeEntry]:
	var ranks := _upgrade_service.get_ranks()
	var entries: Array[RunSummary.UpgradeEntry] = []
	for definition in _upgrade_registry.get_definitions():
		var rank: int = ranks.get(definition.id, 0)
		if rank <= 0:
			continue
		entries.append(RunSummary.UpgradeEntry.new(definition, rank))
	entries.sort_custom(
		func(a: RunSummary.UpgradeEntry, b: RunSummary.UpgradeEntry) -> bool:
			if a.rank != b.rank:
				return a.rank > b.rank
			return String(a.definition.id) < String(b.definition.id)
	)
	if entries.size() > 3:
		entries.resize(3)
	return entries


func _on_boss_defeated_for_summary(_boss: FirstBoss) -> void:
	_defeated_boss_count += 1


func _on_run_started_for_summary(_seed_value: int) -> void:
	_defeated_boss_count = 0


func _on_restart_requested() -> void:
	restart_run()


func _on_change_character_requested() -> void:
	if (
		not _run_controller.is_terminal()
		and _run_controller.get_state() != RunController.RunState.MANUAL_PAUSE
	):
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
	else:
		print("B18O_RUN_STARTED friend=%s" % friend_id)


func _on_welcome_play_requested() -> void:
	if _run_controller.get_state() != RunController.RunState.BOOT:
		return
	_game_audio.play_cue(GameAudio.UI_CONFIRM, -3.0)
	_show_character_selection()


func _on_welcome_tutorial_requested() -> void:
	if _run_controller.get_state() != RunController.RunState.BOOT:
		return
	_game_audio.play_cue(GameAudio.UI_CONFIRM, -3.0)
	_show_tutorial_screen()


func _on_tutorial_close_requested() -> void:
	if _run_controller.get_state() == RunController.RunState.BOOT:
		_show_welcome_screen(true)


func _on_tutorial_play_requested() -> void:
	if _run_controller.get_state() != RunController.RunState.BOOT:
		return
	_game_audio.play_cue(GameAudio.UI_CONFIRM, -3.0)
	_show_character_selection()


func _on_character_selection_back_requested() -> void:
	if _run_controller.get_state() == RunController.RunState.BOOT:
		_show_welcome_screen()


func _on_boot_back_requested() -> bool:
	if _tutorial_screen.visible:
		return _tutorial_screen.handle_back_requested()
	if _character_select_overlay.visible:
		_show_welcome_screen()
		return true
	if _welcome_screen.visible:
		return _welcome_screen.handle_back_requested()
	return false


func _on_welcome_audio_volume_changed(value: float) -> void:
	_game_audio.set_effects_volume(value)


func _on_welcome_audio_mute_toggled(muted: bool) -> void:
	_game_audio.set_muted(muted)


func _on_welcome_reduced_flashes_toggled(enabled: bool) -> void:
	_visual_accessibility_settings.set_reduced_flashes(enabled)


func _on_touch_control_settings_changed(
	ability_scale: float,
	joystick_scale: float
) -> void:
	_apply_touch_control_settings(ability_scale, joystick_scale)


func _on_pause_requested() -> void:
	_platform_lifecycle.request_manual_pause()
