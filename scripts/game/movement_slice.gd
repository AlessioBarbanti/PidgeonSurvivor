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
## PS-137: overlay impostazioni condiviso fra welcome e pausa, istanza unica.
@onready var _settings_overlay: SettingsOverlay = %SettingsOverlay

var _last_logged_safe_area := Rect2()
var _last_logged_joystick_rect := Rect2()
## PS-053: nessun sistema tiene gia' un totale dei Boss sconfitti nella run
## (solo il segnale boss_defeated e l'ultimo titolo); il riepilogo finale lo
## richiede, quindi il conteggio vive qui invece che in BossEncounter.
var _defeated_boss_count := 0
## PS-184: totale delle uccisioni della run mostrato nel recap. I nemici
## ordinari si agganciano per-istanza allo spawn; i Boss non passano dallo
## spawner, quindi arrivano dal segnale boss_defeated.
var _defeated_enemy_count := 0

# TEMP DEBUG — telemetria di validazione batch PS-123/124/126, da rimuovere
# dopo la sessione di raccolta dati sul Pixel (non e' una card).
const _DEBUG_BALANCE_SAMPLE_INTERVAL_SECONDS := 5.0
var _debug_balance_sample_elapsed := 0.0
var _debug_balance_window_enemy_count := 0
var _debug_balance_window_hp_sum := 0.0
var _debug_balance_window_contact_damage_sum := 0.0
var _debug_balance_window_xp_awarded := 0


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
	_enemy_spawner.enemy_spawned.connect(_on_enemy_spawned_for_summary)
	_hud.pause_requested.connect(_on_pause_requested)
	_end_screen.restart_requested.connect(_on_restart_requested)
	_end_screen.change_character_requested.connect(_on_change_character_requested)
	_pause_overlay.change_character_requested.connect(_on_change_character_requested)
	_pause_overlay.exit_requested.connect(_on_exit_requested)
	_welcome_screen.play_requested.connect(_on_welcome_play_requested)
	_welcome_screen.tutorial_requested.connect(_on_welcome_tutorial_requested)
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
	_welcome_screen.configure_settings_overlay(_settings_overlay)
	_pause_overlay.configure_settings_overlay(_settings_overlay)
	_pause_overlay.configure_upgrade_service(_upgrade_service)
	_visual_accessibility_settings.configure(_settings_overlay)
	_touch_control_settings.configure(_settings_overlay)
	_touch_control_settings.settings_changed.connect(_on_touch_control_settings_changed)
	_fire_mode_settings.configure(_settings_overlay)
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
	# TEMP DEBUG — vedi dichiarazione dei campi sopra.
	_enemy_spawner.enemy_spawned.connect(_on_debug_balance_enemy_spawned)
	_run_controller.run_started.connect(_on_debug_balance_run_started)
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
	# TEMP DEBUG — vedi dichiarazione dei campi sopra.
	_experience_system.experience_added.connect(_on_debug_balance_experience_added)
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
	_upgrade_service.set_effect_registry(_upgrade_effect_registry)
	_equip_friend(&"magno")
	_hud.configure(
		_run_controller,
		_player.get_health_component(),
		_experience_system,
		_ability_controller,
		_game_director,
		_wave_event_scheduler,
		_friend_passive_controller
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
		_pause_overlay,
		_game_director,
		_welcome_screen,
		_tutorial_screen,
		_end_screen,
		_boss_ui,
		_settings_overlay
	)
	_game_audio.settings_changed.connect(_settings_overlay.set_audio_settings)
	_visual_accessibility_settings.settings_changed.connect(
		_settings_overlay.set_reduced_flashes
	)
	_visual_accessibility_settings.settings_changed.connect(
		_tutorial_screen.set_reduced_flashes
	)
	_settings_overlay.set_audio_settings(
		_game_audio.get_effects_volume(),
		_game_audio.is_muted()
	)
	_settings_overlay.set_reduced_flashes(
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

	var success := SETUP_VALIDATOR.print_result() and RunContractValidator.print_result(self)
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


func get_settings_overlay() -> SettingsOverlay:
	return _settings_overlay


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
	## PS-113: senza questo cap il motore rende senza limite di frame, unico
	## responsabile del calore/consumo batteria segnalato su Android di fascia
	## bassa a refresh rate alto (90/120Hz) dove nulla lo limitava prima.
	Engine.max_fps = profile.target_fps
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
		current_friend.id if current_friend != null else _pick_random_friend_id()
	)
	print("B18O_CHARACTER_SELECT_SHOWN")


## PS-195: al primo ingresso nel selettore nessun personaggio e' ancora stato
## scelto in questa sessione, quindi evidenziarne uno a caso invece del
## letterale "magno". E' presentazione: usa l'RNG globale, non il seed di run.
func _pick_random_friend_id() -> StringName:
	var definitions := _friend_registry.get_definitions()
	if definitions.is_empty():
		return &"magno"
	var picked: FriendDefinition = definitions.pick_random()
	return picked.id


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
	summary.enemies_defeated = _defeated_enemy_count
	summary.run_time = run_time
	summary.top_upgrades = _upgrade_service.get_acquired_upgrades().slice(0, 3)
	return summary


func _on_boss_defeated_for_summary(_boss: FirstBoss) -> void:
	_defeated_boss_count += 1
	_defeated_enemy_count += 1


func _on_run_started_for_summary(_seed_value: int) -> void:
	_defeated_boss_count = 0
	_defeated_enemy_count = 0


func _on_enemy_spawned_for_summary(enemy: BaseEnemy) -> void:
	if not is_instance_valid(enemy):
		return
	# ONE_SHOT: un died duplicato sullo stesso nemico non puo' gonfiare il totale.
	enemy.died.connect(_on_enemy_died_for_summary, CONNECT_ONE_SHOT)


func _on_enemy_died_for_summary(_enemy: BaseEnemy) -> void:
	_defeated_enemy_count += 1


# TEMP DEBUG — telemetria di validazione batch PS-123/124/126, da rimuovere
# dopo la sessione di raccolta dati sul Pixel (non e' una card). Campiona
# ogni _DEBUG_BALANCE_SAMPLE_INTERVAL_SECONDS il flusso HP/danno/XP in
# ingresso nella finestra appena trascorsa, cosi' i numeri si confrontano
# direttamente con le stime statiche del report analista-bilanciamento.
func _process(_delta: float) -> void:
	if not _run_controller.is_running():
		return
	_debug_balance_sample_elapsed += _delta
	if _debug_balance_sample_elapsed < _DEBUG_BALANCE_SAMPLE_INTERVAL_SECONDS:
		return
	var window_seconds := _debug_balance_sample_elapsed
	var sample := {
		"t": snappedf(_run_controller.get_run_time(), 0.1),
		"enemies_spawned_per_s": snappedf(_debug_balance_window_enemy_count / window_seconds, 0.01),
		"hp_flow_per_s": snappedf(_debug_balance_window_hp_sum / window_seconds, 0.1),
		"contact_dmg_flow_per_s": snappedf(_debug_balance_window_contact_damage_sum / window_seconds, 0.1),
		"xp_flow_per_s": snappedf(_debug_balance_window_xp_awarded / window_seconds, 0.1),
		"alive_now": _enemies.get_child_count(),
		"post_curve_mult": snappedf(
			_enemy_spawner.spawn_profile.get_post_curve_pressure_multiplier(
				_run_controller.get_run_time()
			),
			0.001
		),
		"boss_recurrences": _game_director.get_recurring_boss_count(),
	}
	print("PS_BALANCE_TELEMETRY %s" % JSON.stringify(sample))
	_debug_balance_sample_elapsed = 0.0
	_debug_balance_window_enemy_count = 0
	_debug_balance_window_hp_sum = 0.0
	_debug_balance_window_contact_damage_sum = 0.0
	_debug_balance_window_xp_awarded = 0


func _on_debug_balance_enemy_spawned(enemy: BaseEnemy) -> void:
	_debug_balance_window_enemy_count += 1
	var health_component := enemy.get_health_component()
	if health_component != null:
		_debug_balance_window_hp_sum += health_component.health_max
	var contact_damage_component := enemy.get_contact_damage()
	if contact_damage_component != null:
		_debug_balance_window_contact_damage_sum += contact_damage_component.damage


func _on_debug_balance_experience_added(amount: int, _experience_current: int) -> void:
	_debug_balance_window_xp_awarded += amount


func _on_debug_balance_run_started(_seed_value: int) -> void:
	_debug_balance_sample_elapsed = 0.0
	_debug_balance_window_enemy_count = 0
	_debug_balance_window_hp_sum = 0.0
	_debug_balance_window_contact_damage_sum = 0.0
	_debug_balance_window_xp_awarded = 0


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


## PS-147: ESCI abbandona la run corrente e torna alla welcome, a differenza
## di CAMBIA PERSONAGGIO che porta alla selezione.
func _on_exit_requested() -> void:
	if _run_controller.get_state() != RunController.RunState.MANUAL_PAUSE:
		return
	_input_router.suspend_input()
	_player.clear_movement_input()
	_run_controller.prepare_restart()
	_show_welcome_screen()


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


func _on_touch_control_settings_changed(
	ability_scale: float,
	joystick_scale: float
) -> void:
	_apply_touch_control_settings(ability_scale, joystick_scale)


func _on_pause_requested() -> void:
	_platform_lifecycle.request_manual_pause()
