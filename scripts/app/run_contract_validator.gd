class_name RunContractValidator
extends RefCounted

## Diagnostica della scena composta, invocata dopo il wiring e prima dell'avvio.
## Nessuno stato persistente: i controlli leggono le dipendenze della scena e
## liberano subito le istanze temporanee usate per verificare i PackedScene.
const CONTRACT_MARKERS: Array[String] = [
	"B03_CONTRACT_OK",
	"B04_CONTRACT_OK",
	"B05_CONTRACT_OK",
	"B06_CONTRACT_OK",
	"B06A_CONTRACT_OK",
	"B07_CONTRACT_OK",
	"B08_CONTRACT_OK",
	"B09_CONTRACT_OK",
	"B09A_CONTRACT_OK",
	"B10_CONTRACT_OK",
	"B11_CONTRACT_OK",
	"B12_CONTRACT_OK",
	"B13_CONTRACT_OK",
	"B14_CONTRACT_OK",
	"B15_CONTRACT_OK",
	"B16_CONTRACT_OK",
	"B17_CONTRACT_OK",
	"B17A_CONTRACT_OK",
	"B18_CONTRACT_OK",
	"B18B_CONTRACT_OK",
	"B18C_CONTRACT_OK",
	"B18D_CONTRACT_OK",
	"B18E_CONTRACT_OK",
	"B18F_CONTRACT_OK",
	"B18G_CONTRACT_OK",
	"B18H_CONTRACT_OK",
	"B18I_CONTRACT_OK",
	"B18J_CONTRACT_OK",
	"B18K_CONTRACT_OK",
	"B18L_CONTRACT_OK",
	"B18M_CONTRACT_OK",
	"B18N_CONTRACT_OK",
	"B18O_CONTRACT_OK",
	"B18P_CONTRACT_OK",
	"B18Q_CONTRACT_OK",
	"B18R_CONTRACT_OK",
	"B18S_CONTRACT_OK",
	"B18T_CONTRACT_OK",
	"B18U_CONTRACT_OK",
	"B18W_CONTRACT_OK",
	"B18V_CONTRACT_OK",
	"B54_CONTRACT_OK",
]


static func collect_failures(scene: Control) -> Array[String]:
	var failures: Array[String] = []
	_validate_input(scene, failures)
	_validate_friend_catalog(scene, failures)
	_validate_player_and_director(scene, failures)
	_validate_boss(scene, failures)
	_validate_lifecycle_and_pause(scene, failures)
	_validate_menus(scene, failures)
	_validate_settings(scene, failures)
	_validate_spawning(scene, failures)
	_validate_ability_catalog(scene, failures)
	_validate_weapon_and_ability(scene, failures)
	_validate_progression(scene, failures)
	_validate_upgrade_effects(scene, failures)
	_validate_initial_stats(scene, failures)
	_validate_upgrade_overlays(scene, failures)
	_validate_experience_pickups(scene, failures)
	_validate_audio_and_world(scene, failures)
	_validate_selection(scene, failures)
	_validate_cast_sprites(scene, failures)
	_validate_hud(scene, failures)
	_validate_enemy_scene(scene, failures)
	_validate_performance(scene, failures)
	return failures


static func print_result(scene: Control) -> bool:
	var failures := collect_failures(scene)
	if failures.is_empty():
		for marker in CONTRACT_MARKERS:
			print(marker)
		return true
	for failure in failures:
		push_error(failure)
	printerr("B18V_CONTRACT_FAIL")
	return false


static func _validate_input(scene: Control, failures: Array[String]) -> void:
	var arena_layout: ArenaLayout = scene.get_arena_layout()
	var run_controller: RunController = scene.get_run_controller()
	var fire_mode_settings: FireModeSettings = scene.get_fire_mode_settings()
	var player: Player = scene.get_player()
	var weapon_controller: WeaponController = scene.get_weapon_controller()
	var touch_joystick: TouchJoystick = scene.get_touch_joystick()
	var aim_touch_joystick: TouchJoystick = scene.get_aim_touch_joystick()
	for action in [&"move_left", &"move_right", &"move_up", &"move_down"]:
		if not InputMap.has_action(action):
			failures.append("InputMap privo di %s." % action)
	if not InputMap.has_action(&"pause_game"):
		failures.append("InputMap privo di pause_game.")
	if not InputMap.has_action(&"active_ability"):
		failures.append("InputMap privo di active_ability.")
	if not arena_layout.get_playfield_rect().has_area():
		failures.append("ArenaLayout non ha prodotto un playfield valido.")
	if not touch_joystick.dynamic_origin:
		failures.append("B18L richiede il joystick dinamico.")
	elif not touch_joystick.get_capture_rect().has_area():
		failures.append("B18L richiede una zona di acquisizione dinamica valida.")
	elif touch_joystick.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		failures.append("B18L non deve intercettare il secondo dito via GUI.")
	if not aim_touch_joystick.dynamic_origin:
		failures.append("PS-085 richiede il joystick di mira dinamico.")
	elif aim_touch_joystick.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		failures.append("PS-085 non deve intercettare il secondo dito via GUI.")
	for action in [&"aim_left", &"aim_right", &"aim_up", &"aim_down", &"manual_fire_hold"]:
		if not InputMap.has_action(action):
			failures.append("InputMap privo di %s." % action)
	if weapon_controller.is_manual_fire_enabled() != fire_mode_settings.is_manual_fire_enabled():
		failures.append("WeaponController non riflette FireModeSettings.")
	if player.get_arena_layout() != arena_layout:
		failures.append("Player non collegato ad ArenaLayout.")
	if player.get_run_controller() != run_controller:
		failures.append("Player non collegato al RunController.")


static func _validate_friend_catalog(scene: Control, failures: Array[String]) -> void:
	var friend_registry: FriendRegistry = scene.get_friend_registry()
	var ability_effect_registry: AbilityEffectRegistry = scene.get_ability_effect_registry()
	var friend_passive_controller: FriendPassiveController = scene.get_friend_passive_controller()
	var player: Player = scene.get_player()
	if friend_registry == null:
		failures.append("FriendRegistry B17 non presente.")
	else:
		if not friend_registry.is_catalog_valid():
			failures.append(
				"FriendRegistry B17 non valido: %s."
				% "; ".join(friend_registry.get_validation_errors())
			)
		if friend_registry.get_definitions().size() != 8:
			failures.append("Il catalogo B17 deve contenere gli otto amici approvati.")
		if not friend_registry.is_catalog_publication_ready():
			failures.append("Il catalogo B17 contiene profili o asset non approvati.")
		var player_friend := player.get_friend_definition()
		if player_friend == null or friend_registry.resolve_definition(player_friend.id) != player_friend:
			failures.append("Il Player non usa un profilo amico registrato.")
		for friend_definition in friend_registry.get_definitions():
			if not friend_passive_controller.is_supported_definition(friend_definition):
				failures.append("Passiva B17A non supportata: %s." % friend_definition.id)
			if not friend_definition.has_directional_gameplay_animation():
				failures.append(
					"Animazione laterale Player mancante: %s."
					% friend_definition.id
				)
			var roster_ability := ability_effect_registry.resolve_definition(
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


static func _validate_player_and_director(scene: Control, failures: Array[String]) -> void:
	var run_controller: RunController = scene.get_run_controller()
	var game_director: GameDirector = scene.get_game_director()
	var enemy_spawner: EnemySpawner = scene.get_enemy_spawner()
	var player: Player = scene.get_player()
	var player_health := player.get_health_component()
	if player_health == null:
		failures.append("Player privo di HealthComponent.")
	elif player_health.invulnerability_duration <= 0.0:
		failures.append("Invulnerabilita Player non configurata.")
	if run_controller == null:
		failures.append("RunController non presente.")
	if game_director == null:
		failures.append("GameDirector non presente.")
	else:
		if not game_director.has_valid_configuration():
			failures.append("GameDirector privo di una configurazione valida.")
		if game_director.get_run_controller() != run_controller:
			failures.append("GameDirector non collegato al RunController.")
		if game_director.get_enemy_spawner() != enemy_spawner:
			failures.append("GameDirector non collegato a EnemySpawner.")
		var boss_thresholds := game_director.get_thresholds()
		if (
			boss_thresholds.size() != 1
			or not is_equal_approx(boss_thresholds[0], 120.0)
		):
			failures.append("Il profilo Director PS-005 deve schedulare il Boss a 02:00.")


static func _validate_boss(scene: Control, failures: Array[String]) -> void:
	var run_controller: RunController = scene.get_run_controller()
	var friend_registry: FriendRegistry = scene.get_friend_registry()
	var game_director: GameDirector = scene.get_game_director()
	var boss_encounter: BossEncounter = scene.get_boss_encounter()
	var targeting_system: TargetingSystem = scene.get_targeting_system()
	var boss_projectiles: Node2D = scene.get_boss_projectile_parent()
	var boss_ui: BossUI = scene.get_boss_ui()
	if boss_encounter == null:
		failures.append("BossEncounter non presente.")
	else:
		if not boss_encounter.has_valid_configuration():
			failures.append("BossEncounter privo di una configurazione valida.")
		if boss_encounter.get_run_controller() != run_controller:
			failures.append("BossEncounter non collegato al RunController.")
		if boss_encounter.get_game_director() != game_director:
			failures.append("BossEncounter non collegato al GameDirector.")
		if boss_encounter.get_targeting_system() != targeting_system:
			failures.append("BossEncounter non collegato al TargetingSystem.")
		if boss_encounter.get_boss_ui() != boss_ui:
			failures.append("BossEncounter non collegato alla UI Boss.")
		if boss_encounter.get_boss_projectile_parent() != boss_projectiles:
			failures.append("BossEncounter non collegato ai proiettili Boss.")
		if boss_encounter.get_friend_registry() != friend_registry:
			failures.append("BossEncounter B22 non collegato al catalogo amici.")
		var boss_definition := boss_encounter.boss_definition
		if boss_definition == null or not boss_definition.is_valid():
			failures.append("BossEncounter privo di BossDefinition valida.")
		else:
			if (
				boss_definition.is_evil_variant()
				or boss_definition.friend_profile != null
				or boss_definition.id != &"special_pigeon"
			):
				failures.append("B22 richiede il piccione speciale come Boss baseline.")
			if not is_equal_approx(boss_encounter.evil_boss_chance, 0.9):
				failures.append("PS-127 richiede evil_boss_chance dati al 90% (baseline raro al 10%).")
			if (
				not boss_definition.quote_approved
				and boss_definition.get_safe_quote() != boss_definition.safe_quote_placeholder
			):
				failures.append("La citazione Boss non approvata deve usare il placeholder sicuro.")
	if boss_ui == null:
		failures.append("BossUI non presente.")
	elif boss_ui.is_intro_visible():
		failures.append("BossUI deve essere nascosta prima della soglia Boss.")


static func _validate_lifecycle_and_pause(scene: Control, failures: Array[String]) -> void:
	var run_controller: RunController = scene.get_run_controller()
	var upgrade_service: UpgradeService = scene.get_upgrade_service()
	var input_router: InputRouter = scene.get_node("%InputRouter")
	var platform_lifecycle: PlatformLifecycle = scene.get_platform_lifecycle()
	var pause_overlay: PauseOverlay = scene.get_pause_overlay()
	if platform_lifecycle == null:
		failures.append("PlatformLifecycle non presente.")
	else:
		if platform_lifecycle.get_run_controller() != run_controller:
			failures.append("PlatformLifecycle non collegato al RunController.")
		if platform_lifecycle.get_input_router() != input_router:
			failures.append("PlatformLifecycle non collegato a InputRouter.")
		if platform_lifecycle.get_pause_overlay() != pause_overlay:
			failures.append("PlatformLifecycle non collegato a PauseOverlay.")
	if pause_overlay == null:
		failures.append("PauseOverlay non presente.")
	elif pause_overlay.visible:
		failures.append("PauseOverlay deve essere nascosto durante la run.")
	else:
		if pause_overlay.get_settings_button() == null:
			failures.append("PauseOverlay PS-137 privo dell'ingranaggio impostazioni.")
		if pause_overlay.get_change_character_button() == null:
			failures.append("PauseOverlay B18N privo di Cambia personaggio.")
		if (
			pause_overlay.get_cancel_change_button() == null
			or pause_overlay.get_confirm_change_button() == null
		):
			failures.append("PauseOverlay B18N privo della conferma di abbandono run.")
		if pause_overlay.get_exit_button() == null:
			failures.append("PauseOverlay PS-147 privo del bottone ESCI.")
		if pause_overlay.get_upgrade_service() != upgrade_service:
			failures.append("PauseOverlay PS-164 non collegato a UpgradeService.")


static func _validate_menus(scene: Control, failures: Array[String]) -> void:
	var welcome_screen: WelcomeScreen = scene.get_welcome_screen()
	var tutorial_screen: TutorialScreen = scene.get_tutorial_screen()
	var character_select_overlay: CharacterSelectOverlay = scene.get_character_select_overlay()
	var settings_overlay: SettingsOverlay = scene.get_settings_overlay()
	if welcome_screen == null:
		failures.append("WelcomeScreen B18O non presente.")
	else:
		if welcome_screen.get_play_button() == null:
			failures.append("WelcomeScreen B18O priva di GIOCA.")
		if welcome_screen.get_tutorial_button() == null:
			failures.append("WelcomeScreen B54 priva di TUTORIAL.")
		if welcome_screen.get_settings_button() == null:
			failures.append("WelcomeScreen B18O priva di IMPOSTAZIONI.")
	if settings_overlay == null:
		failures.append("SettingsOverlay PS-137 non presente.")
	else:
		if (
			settings_overlay.get_ability_size_slider() == null
			or settings_overlay.get_joystick_size_slider() == null
		):
			failures.append("SettingsOverlay PS-137 privo delle scale touch.")
		if (
			settings_overlay.get_volume_slider() == null
			or settings_overlay.get_mute_check_button() == null
			or settings_overlay.get_reduced_flashes_check_button() == null
			or settings_overlay.get_manual_fire_check_button() == null
		):
			failures.append("SettingsOverlay PS-137 priva delle impostazioni correnti.")
		if (
			settings_overlay.get_audio_tab_button() == null
			or settings_overlay.get_accessibility_tab_button() == null
			or settings_overlay.get_controls_tab_button() == null
		):
			failures.append("SettingsOverlay PS-137 priva delle tre tab.")
	if tutorial_screen == null:
		failures.append("TutorialScreen B54 non presente.")
	elif (
		tutorial_screen.get_page_count() != 6
		or tutorial_screen.get_page_ids()
		!= [&"objective", &"movement", &"ability", &"progression", &"enemies", &"boss"]
	):
		failures.append("TutorialScreen B54 deve esporre le sei pagine autorevoli.")
	if character_select_overlay.get_back_button() == null:
		failures.append("Il selettore B18O deve esporre INDIETRO.")


static func _validate_settings(scene: Control, failures: Array[String]) -> void:
	var visual_accessibility_settings: VisualAccessibilitySettings = scene.get_visual_accessibility_settings()
	var touch_control_settings: TouchControlSettings = scene.get_touch_control_settings()
	var ability_effect_registry: AbilityEffectRegistry = scene.get_ability_effect_registry()
	if visual_accessibility_settings == null:
		failures.append("VisualAccessibilitySettings B18E non presente.")
	elif (
		ability_effect_registry.get_visual_settings()
		!= visual_accessibility_settings
	):
		failures.append("AbilityEffectRegistry B18E non collegato alle impostazioni visuali.")
	if touch_control_settings == null:
		failures.append("TouchControlSettings B18P non presente.")
	else:
		if (
			touch_control_settings.get_ability_scale()
			< TouchControlSettings.MIN_ABILITY_SCALE
			or touch_control_settings.get_ability_scale()
			> TouchControlSettings.MAX_ABILITY_SCALE
		):
			failures.append("La scala abilita B18P deve restare nell'intervallo sicuro.")
		if (
			touch_control_settings.get_joystick_scale()
			< TouchControlSettings.MIN_JOYSTICK_SCALE
			or touch_control_settings.get_joystick_scale()
			> TouchControlSettings.MAX_JOYSTICK_SCALE
		):
			failures.append("La scala joystick B18P deve restare nell'intervallo sicuro.")


static func _validate_spawning(scene: Control, failures: Array[String]) -> void:
	var arena_layout: ArenaLayout = scene.get_arena_layout()
	var run_controller: RunController = scene.get_run_controller()
	var game_director: GameDirector = scene.get_game_director()
	var enemy_spawner: EnemySpawner = scene.get_enemy_spawner()
	var wave_event_scheduler: WaveEventScheduler = scene.get_wave_event_scheduler()
	var targeting_system: TargetingSystem = scene.get_targeting_system()
	var player: Player = scene.get_player()
	var enemies: Node2D = scene.get_node("%Enemies")
	if enemy_spawner.spawn_profile == null:
		failures.append("EnemySpawner privo del profilo dati.")
	if enemy_spawner.enemy_scene == null:
		failures.append("EnemySpawner privo della scena nemico.")
	if enemy_spawner.get_run_controller() != run_controller:
		failures.append("EnemySpawner non collegato al RunController.")
	if enemy_spawner.get_arena_layout() != arena_layout:
		failures.append("EnemySpawner non collegato ad ArenaLayout.")
	if enemy_spawner.get_target() != player:
		failures.append("EnemySpawner non collegato al Player.")
	if enemy_spawner.get_enemy_parent() != enemies:
		failures.append("EnemySpawner non collegato al contenitore Enemies.")
	if wave_event_scheduler == null:
		failures.append("WaveEventScheduler PS-008 non presente.")
	else:
		if not wave_event_scheduler.has_valid_configuration():
			failures.append("WaveEventScheduler PS-008 privo di una configurazione valida.")
		if wave_event_scheduler.get_run_controller() != run_controller:
			failures.append("WaveEventScheduler PS-008 non collegato al RunController.")
		if wave_event_scheduler.get_game_director() != game_director:
			failures.append("WaveEventScheduler PS-008 non collegato al GameDirector.")
		if wave_event_scheduler.get_enemy_spawner() != enemy_spawner:
			failures.append("WaveEventScheduler PS-008 non collegato a EnemySpawner.")
	if targeting_system.get_enemy_spawner() != enemy_spawner:
		failures.append("TargetingSystem non collegato a EnemySpawner.")


static func _validate_ability_catalog(scene: Control, failures: Array[String]) -> void:
	var arena_layout: ArenaLayout = scene.get_arena_layout()
	var run_controller: RunController = scene.get_run_controller()
	var targeting_system: TargetingSystem = scene.get_targeting_system()
	var ability_effect_registry: AbilityEffectRegistry = scene.get_ability_effect_registry()
	var friend_passive_controller: FriendPassiveController = scene.get_friend_passive_controller()
	var player: Player = scene.get_player()
	var ability_effects: Node2D = scene.get_ability_effect_parent()
	if ability_effect_registry.get_run_controller() != run_controller:
		failures.append("AbilityEffectRegistry non collegato al RunController.")
	if ability_effect_registry.get_targeting_system() != targeting_system:
		failures.append("AbilityEffectRegistry non collegato al TargetingSystem.")
	if ability_effect_registry.get_effect_parent() != ability_effects:
		failures.append("AbilityEffectRegistry non collegato ad AbilityEffects.")
	if ability_effect_registry.get_arena_layout() != arena_layout:
		failures.append("AbilityEffectRegistry B17A non collegato ad ArenaLayout.")
	if ability_effect_registry.get_definitions().size() != 8:
		failures.append("AbilityEffectRegistry B17A deve contenere otto abilita.")
	var ability_icon_paths: Dictionary = {}
	for roster_definition in ability_effect_registry.get_definitions():
		if roster_definition.icon == null:
			failures.append("Icona abilita B18 mancante: %s." % roster_definition.id)
			continue
		var ability_icon_path := roster_definition.icon.resource_path
		if ability_icon_path.is_empty() or ability_icon_path.ends_with("/icon.svg"):
			failures.append("Icona abilita B18 ancora generica: %s." % roster_definition.id)
		ability_icon_paths[ability_icon_path] = true
	if ability_icon_paths.size() != 8:
		failures.append("Le otto abilita B18 devono avere icone dedicate e distinguibili.")
	if friend_passive_controller.get_definition() != player.get_friend_definition():
		failures.append("La passiva B17A non corrisponde al profilo Player.")


static func _validate_weapon_and_ability(scene: Control, failures: Array[String]) -> void:
	var run_controller: RunController = scene.get_run_controller()
	var targeting_system: TargetingSystem = scene.get_targeting_system()
	var ability_effect_registry: AbilityEffectRegistry = scene.get_ability_effect_registry()
	var player: Player = scene.get_player()
	var projectiles: Node2D = scene.get_projectile_parent()
	var weapon_controller: WeaponController = scene.get_weapon_controller()
	var ability_controller: AbilityController = scene.get_ability_controller()
	var input_router: InputRouter = scene.get_node("%InputRouter")
	if weapon_controller.weapon_profile == null:
		failures.append("WeaponController privo del profilo dati.")
	if weapon_controller.projectile_scene == null:
		failures.append("WeaponController privo della scena proiettile.")
	if weapon_controller.get_run_controller() != run_controller:
		failures.append("WeaponController non collegato al RunController.")
	if weapon_controller.get_targeting_system() != targeting_system:
		failures.append("WeaponController non collegato al TargetingSystem.")
	if weapon_controller.get_projectile_parent() != projectiles:
		failures.append("WeaponController non collegato al contenitore Projectiles.")
	if ability_controller == null:
		failures.append("Player privo di AbilityController.")
	else:
		var ability_definition := ability_controller.get_definition()
		if ability_definition == null or not ability_definition.is_valid():
			failures.append("AbilityController privo di AbilityDefinition valida.")
		elif ability_effect_registry.resolve_definition(ability_definition.id) != ability_definition:
			failures.append("AbilityDefinition non registrata nel registry.")
		if ability_controller.get_run_controller() != run_controller:
			failures.append("AbilityController non collegato al RunController.")
		if ability_controller.get_input_router() != input_router:
			failures.append("AbilityController non collegato a InputRouter.")
		if ability_controller.get_effect_registry() != ability_effect_registry:
			failures.append("AbilityController non collegato al registry.")
		if ability_controller.get_source() != player:
			failures.append("AbilityController non collegato al Player.")
		var equipped_friend := player.get_friend_definition()
		if (
			equipped_friend != null
			and ability_definition != null
			and equipped_friend.active_ability_id != ability_definition.id
		):
			failures.append("Il profilo selezionato non corrisponde all'AbilityDefinition equipaggiata.")


static func _validate_progression(scene: Control, failures: Array[String]) -> void:
	var run_controller: RunController = scene.get_run_controller()
	var experience_system: ExperienceSystem = scene.get_experience_system()
	var upgrade_registry: UpgradeRegistry = scene.get_upgrade_registry()
	var upgrade_service: UpgradeService = scene.get_upgrade_service()
	var upgrade_effect_registry: UpgradeEffectRegistry = scene.get_upgrade_effect_registry()
	var player: Player = scene.get_player()
	var ability_controller: AbilityController = scene.get_ability_controller()
	if player.get_pickup_radius() <= 0.0:
		failures.append("Player privo di pickup_radius valido.")
	if experience_system.get_run_controller() != run_controller:
		failures.append("ExperienceSystem non collegato al RunController.")
	if experience_system.experience_curve == null:
		failures.append("ExperienceSystem privo della curva XP dati.")
	elif experience_system.get_experience_required(1) <= 0:
		failures.append("ExperienceSystem ha una soglia iniziale non valida.")
	if not upgrade_registry.is_catalog_valid():
		failures.append(
			"UpgradeRegistry non valido: %s."
			% "; ".join(upgrade_registry.get_validation_errors())
		)
	for upgrade_definition in upgrade_registry.get_definitions():
		if (
			upgrade_definition.icon == null
			or upgrade_definition.icon.resource_path.is_empty()
			or upgrade_definition.icon.resource_path.ends_with("/icon.svg")
		):
			failures.append("Icona upgrade B18 ancora generica: %s." % upgrade_definition.id)
	var ability_rank_definitions := 0
	for upgrade_definition in upgrade_registry.get_definitions():
		if upgrade_definition.effect_id != UpgradeEffectRegistry.ABILITY_RANK:
			continue
		ability_rank_definitions += 1
		if not upgrade_definition.is_ability_rank_definition():
			failures.append("Carta rank B18G non valida: %s." % upgrade_definition.id)
	if ability_rank_definitions != 8:
		failures.append("B18G richiede una carta rank autorevole per ciascuna delle otto abilita.")
	var summer_grill := upgrade_registry.resolve_definition(&"summer_grill")
	if (
		summer_grill == null
		or summer_grill.effect_id != UpgradeEffectRegistry.SUMMER_GRILL
		or summer_grill.max_rank != 5
		or not upgrade_effect_registry.can_apply(summer_grill)
	):
		failures.append("B18J richiede Grigliata estiva dati a cinque rank.")
	if upgrade_registry.get_repeatable_definitions().size() < UpgradeService.DEFAULT_OFFER_SIZE:
		failures.append("UpgradeRegistry privo di tre potenziamenti normali ripetibili.")
	if not upgrade_service.has_valid_configuration():
		failures.append("UpgradeService non configurato per offerte da tre carte.")
	if upgrade_service.get_registry() != upgrade_registry:
		failures.append("UpgradeService non collegato a UpgradeRegistry.")
	if upgrade_service.get_run_controller() != run_controller:
		failures.append("UpgradeService non collegato al RunController.")
	if (
		ability_controller != null
		and upgrade_service.get_equipped_ability_id() != ability_controller.get_definition().id
	):
		failures.append("UpgradeService B18G non sincronizzato con l'abilita equipaggiata.")
	if ability_controller != null and ability_controller.get_ability_rank() != 1:
		failures.append("Ogni run B18G deve iniziare con l'abilita al rank 1.")
	if upgrade_service.get_experience_system() != experience_system:
		failures.append("UpgradeService non collegato a ExperienceSystem.")
	if upgrade_registry.get_speciality_definitions().size() != 8:
		failures.append("UpgradeRegistry deve contenere le otto Specialità di Barb (PS-094 - PS-100).")
	if upgrade_service.get_locked_speciality_definitions().size() != 8:
		failures.append("Ogni run deve iniziare con tutte le Specialità di Barb bloccate.")
	if upgrade_service.is_barb_reward_active():
		failures.append("La run non deve iniziare con una ricompensa Barb già attiva.")


static func _validate_upgrade_effects(scene: Control, failures: Array[String]) -> void:
	var run_controller: RunController = scene.get_run_controller()
	var targeting_system: TargetingSystem = scene.get_targeting_system()
	var upgrade_registry: UpgradeRegistry = scene.get_upgrade_registry()
	var upgrade_service: UpgradeService = scene.get_upgrade_service()
	var upgrade_effect_registry: UpgradeEffectRegistry = scene.get_upgrade_effect_registry()
	var player: Player = scene.get_player()
	var ability_effects: Node2D = scene.get_ability_effect_parent()
	var weapon_controller: WeaponController = scene.get_weapon_controller()
	var vignette_effect: VignetteEffect = scene.get_vignette_effect()
	if not upgrade_effect_registry.has_valid_configuration():
		failures.append("UpgradeEffectRegistry non configurato per il catalogo B13.")
	if upgrade_effect_registry.get_upgrade_service() != upgrade_service:
		failures.append("UpgradeEffectRegistry non collegato a UpgradeService.")
	if upgrade_effect_registry.get_upgrade_registry() != upgrade_registry:
		failures.append("UpgradeEffectRegistry non collegato a UpgradeRegistry.")
	if upgrade_effect_registry.get_player() != player:
		failures.append("UpgradeEffectRegistry non collegato al Player.")
	if upgrade_effect_registry.get_weapon_controller() != weapon_controller:
		failures.append("UpgradeEffectRegistry non collegato all'arma.")
	if upgrade_effect_registry.get_run_controller() != run_controller:
		failures.append("UpgradeEffectRegistry non collegato al clock della run.")
	if upgrade_effect_registry.get_targeting_system() != targeting_system:
		failures.append("UpgradeEffectRegistry non collegato ai bersagli B13.")
	if upgrade_effect_registry.get_vignette_effect() != vignette_effect:
		failures.append("UpgradeEffectRegistry non collegato alla vignetta B13.")
	if upgrade_effect_registry.get_effect_parent() != ability_effects:
		failures.append("UpgradeEffectRegistry non collegato ai VFX B13.")
	for signature_id in [
		&"gossip_projectiles",
		&"chronic_delay",
		&"beer_signature",
		&"damage_shockwave",
	]:
		var signature_definition := upgrade_registry.resolve_definition(signature_id)
		if (
			signature_definition == null
			or signature_definition.effect_id != signature_id
			or not upgrade_effect_registry.can_apply(signature_definition)
		):
			failures.append("Upgrade signature B13 non valido: %s." % signature_id)


static func _validate_initial_stats(scene: Control, failures: Array[String]) -> void:
	var player: Player = scene.get_player()
	var weapon_controller: WeaponController = scene.get_weapon_controller()
	var vignette_effect: VignetteEffect = scene.get_vignette_effect()
	if not is_equal_approx(player.move_speed, player.get_base_move_speed()):
		failures.append("La run deve iniziare con la velocita Player base.")
	if not is_equal_approx(player.get_pickup_radius(), player.get_base_pickup_radius()):
		failures.append("La run deve iniziare con il raggio pickup base.")
	if not is_equal_approx(
		weapon_controller.get_effective_shots_per_second(),
		weapon_controller.get_base_shots_per_second()
	):
		failures.append("La run deve iniziare con la frequenza arma base.")
	if not is_equal_approx(
		weapon_controller.get_effective_damage(),
		weapon_controller.get_base_damage()
	):
		failures.append("La run deve iniziare con il danno arma base.")
	if not is_equal_approx(player.get_health_max_multiplier(), 1.0):
		failures.append("La run deve iniziare con la vita massima base.")
	if (
		weapon_controller.is_projectile_chain_enabled()
		or weapon_controller.get_projectile_chain_jumps() != 0
		or not is_zero_approx(
			weapon_controller.get_projectile_aim_spread_degrees()
		)
	):
		failures.append("La run deve iniziare senza modificatori proiettile B13.")
	if (
		weapon_controller.get_effective_pierce_count() != 1
		or weapon_controller.get_effective_multishot_count() != 1
		or weapon_controller.is_death_burst_enabled()
	):
		failures.append("La run deve iniziare senza forme d'attacco B41.")
	if vignette_effect.visible or not is_zero_approx(vignette_effect.intensity):
		failures.append("La vignetta B13 deve essere disattiva a inizio run.")


static func _validate_upgrade_overlays(scene: Control, failures: Array[String]) -> void:
	var upgrade_service: UpgradeService = scene.get_upgrade_service()
	var touch_joystick: TouchJoystick = scene.get_touch_joystick()
	var upgrade_overlay: UpgradeOverlay = scene.get_upgrade_overlay()
	var barb_reward_overlay: BarbRewardOverlay = scene.get_barb_reward_overlay()
	if barb_reward_overlay == null:
		failures.append("BarbRewardOverlay non presente.")
	else:
		if barb_reward_overlay.get_upgrade_service() != upgrade_service:
			failures.append("BarbRewardOverlay non collegato a UpgradeService.")
		if barb_reward_overlay.get_touch_joystick() != touch_joystick:
			failures.append("BarbRewardOverlay non collegato al joystick touch.")
		if barb_reward_overlay.visible:
			failures.append("BarbRewardOverlay deve essere nascosto senza una ricompensa Boss attiva.")
		if barb_reward_overlay.get_cards().size() != 3:
			failures.append("BarbRewardOverlay deve avere tre slot carta disponibili.")
	if upgrade_overlay == null:
		failures.append("UpgradeOverlay non presente.")
	else:
		if upgrade_overlay.get_upgrade_service() != upgrade_service:
			failures.append("UpgradeOverlay non collegato a UpgradeService.")
		if upgrade_overlay.get_touch_joystick() != touch_joystick:
			failures.append("UpgradeOverlay non collegato al joystick touch.")
		if upgrade_overlay.visible or upgrade_overlay.is_accepting_selection():
			failures.append("UpgradeOverlay deve essere nascosto senza un'offerta.")
		var upgrade_cards := upgrade_overlay.get_cards()
		if upgrade_cards.size() != UpgradeService.DEFAULT_OFFER_SIZE:
			failures.append("UpgradeOverlay deve contenere tre carte.")
		else:
			for card in upgrade_cards:
				if card.custom_minimum_size.x < 200.0 or card.custom_minimum_size.y < 200.0:
					failures.append("Le carte upgrade devono essere target touch ampi.")
					break


static func _validate_experience_pickups(scene: Control, failures: Array[String]) -> void:
	var arena_layout: ArenaLayout = scene.get_arena_layout()
	var run_controller: RunController = scene.get_run_controller()
	var enemy_spawner: EnemySpawner = scene.get_enemy_spawner()
	var experience_system: ExperienceSystem = scene.get_experience_system()
	var experience_dropper: ExperienceDropper = scene.get_experience_dropper()
	var player: Player = scene.get_player()
	var pickups: Node2D = scene.get_pickup_parent()
	if experience_dropper.pickup_scene == null:
		failures.append("ExperienceDropper privo della scena pickup.")
	if experience_dropper.get_run_controller() != run_controller:
		failures.append("ExperienceDropper non collegato al RunController.")
	if experience_dropper.get_enemy_spawner() != enemy_spawner:
		failures.append("ExperienceDropper non collegato a EnemySpawner.")
	if experience_dropper.get_experience_system() != experience_system:
		failures.append("ExperienceDropper non collegato a ExperienceSystem.")
	if experience_dropper.get_player() != player:
		failures.append("ExperienceDropper non collegato al Player.")
	if experience_dropper.get_arena_layout() != arena_layout:
		failures.append("ExperienceDropper non collegato ad ArenaLayout.")
	if experience_dropper.get_pickup_parent() != pickups:
		failures.append("ExperienceDropper non collegato al contenitore Pickups.")
	if experience_dropper.pickup_scene != null:
		var pickup_candidate := experience_dropper.pickup_scene.instantiate()
		if not pickup_candidate is ExperiencePickup:
			failures.append("La scena pickup non istanzia ExperiencePickup.")
		if is_instance_valid(pickup_candidate):
			pickup_candidate.free()


static func _validate_audio_and_world(scene: Control, failures: Array[String]) -> void:
	var run_controller: RunController = scene.get_run_controller()
	var boss_encounter: BossEncounter = scene.get_boss_encounter()
	var enemy_spawner: EnemySpawner = scene.get_enemy_spawner()
	var ability_effect_registry: AbilityEffectRegistry = scene.get_ability_effect_registry()
	var game_audio: GameAudio = scene.get_game_audio()
	var arena_view: ArenaView = scene.get_arena_view()
	var player: Player = scene.get_player()
	var enemies: Node2D = scene.get_node("%Enemies")
	var projectiles: Node2D = scene.get_projectile_parent()
	var boss_projectiles: Node2D = scene.get_boss_projectile_parent()
	var ability_effects: Node2D = scene.get_ability_effect_parent()
	var combat_feedback: CombatFeedback = scene.get_combat_feedback()
	if game_audio == null:
		failures.append("GameAudio B18 non presente.")
	else:
		if not game_audio.is_configured():
			failures.append("GameAudio B18 non collegato agli eventi di gioco.")
		if not game_audio.has_complete_cue_set():
			failures.append("GameAudio B18 privo di uno o piu cue obbligatori.")
		if game_audio.get_player_pool_size() < 8:
			failures.append("GameAudio B18 richiede playback concorrente senza tagli evidenti.")
	if not (
		ability_effects.z_index < enemies.z_index
		and ability_effects.z_index < player.z_index
		and ability_effects.z_index < boss_projectiles.z_index
	):
		failures.append("I VFX B18 devono restare sotto attori e attacchi ostili.")
	if boss_projectiles.z_index <= projectiles.z_index:
		failures.append("I proiettili Boss B18 devono avere priorita visiva massima nel mondo.")
	if arena_view == null or arena_view.uses_debug_grid():
		failures.append("ArenaView B18B non deve usare la griglia debug regolare.")
	elif arena_view.get_floor_feature_budget().values().has(0):
		failures.append("ArenaView B18B richiede variazioni, giunti, macchie e crepe.")
	if arena_view != null:
		if not arena_view.has_raster_background():
			failures.append("ArenaView B18S privo dello sfondo raster ImageGen.")
		elif arena_view.uses_procedural_fallback():
			failures.append("ArenaView B18S non deve usare il fallback procedurale nel runtime.")
		if arena_view.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST:
			failures.append("ArenaView B18S deve preservare il campionamento pixel-art.")
	if combat_feedback == null:
		failures.append("CombatFeedback B18B non presente.")
	else:
		if combat_feedback.get_run_controller() != run_controller:
			failures.append("CombatFeedback B18B non collegato al RunController.")
		if combat_feedback.get_enemy_spawner() != enemy_spawner:
			failures.append("CombatFeedback B18B non collegato a EnemySpawner.")
		if combat_feedback.get_player() != player:
			failures.append("CombatFeedback B18B non collegato al Player.")
		if combat_feedback.get_boss_encounter() != boss_encounter:
			failures.append("CombatFeedback B18B non collegato al BossEncounter.")
		if not (
			ability_effects.z_index < combat_feedback.z_index
			and combat_feedback.z_index < player.z_index
			and combat_feedback.z_index < projectiles.z_index
		):
			failures.append("Il feedback B18B deve restare tra aree alleate e attori prioritari.")
		if (
			not is_equal_approx(
				combat_feedback.death_burst_duration,
				PresentationTimings.DEATH_BURST_SECONDS
			)
			or not is_equal_approx(
				combat_feedback.player_damage_duration,
				PresentationTimings.PLAYER_DAMAGE_BURST_SECONDS
			)
		):
			failures.append("B18R richiede timing feedback centralizzati.")
	if not PresentationTimings.is_valid():
		failures.append("B18R richiede timing presentazionali validi e separati dal gameplay.")
	if (
		not is_equal_approx(
			player.damage_reaction_duration,
			PresentationTimings.PLAYER_DAMAGE_REACTION_SECONDS
		)
		or player.damage_flash_duration > 0.08
	):
		failures.append("B18R deve allungare la reazione Player mantenendo breve il flash.")
	if ability_effect_registry.get_active_visual_tail_count() != 0:
		failures.append("B18R non deve iniziare una run con code visive residue.")


static func _validate_selection(scene: Control, failures: Array[String]) -> void:
	var friend_registry: FriendRegistry = scene.get_friend_registry()
	var character_select_overlay: CharacterSelectOverlay = scene.get_character_select_overlay()
	var end_screen: EndScreen = scene.get_end_screen()
	if end_screen == null:
		failures.append("EndScreen non presente.")
	elif end_screen.visible:
		failures.append("EndScreen deve essere nascosto durante la run.")
	if character_select_overlay == null:
		failures.append("CharacterSelectOverlay B17A non presente.")
	elif character_select_overlay.get_roster_size() != 8:
		failures.append("CharacterSelectOverlay B17A deve esporre otto profili.")
	else:
		if character_select_overlay.get_previous_button() == null:
			failures.append("B18T richiede la navigazione precedente del carosello.")
		if character_select_overlay.get_next_button() == null:
			failures.append("B18T richiede la navigazione successiva del carosello.")
		if (
			character_select_overlay.get_confirm_button() == null
			or character_select_overlay.get_confirm_button().custom_minimum_size.y < 44.0
		):
			failures.append("B18T richiede una conferma separata con target minimo 44x44.")
		if (
			character_select_overlay.get_back_button() == null
			or character_select_overlay.get_back_button().text != "INDIETRO"
		):
			failures.append("B18W richiede Back distinto in alto con copy naturale.")
		if character_select_overlay.get_ability_panel_rect().size.x < 260.0:
			failures.append("B18W richiede il pannello laterale dedicato a passiva e abilita.")
		var selection_backdrop := character_select_overlay.get_backdrop()
		if (
			selection_backdrop == null
			or selection_backdrop.texture == null
			or selection_backdrop.texture.resource_path
			!= "res://assets/art/ui/character_select/character_select_backdrop.png"
		):
			failures.append("B18W richiede il fondale pixel-art tracciato del selettore.")
		var cta_style := (
			character_select_overlay.get_confirm_button().get_theme_stylebox("normal")
			as StyleBoxTexture
		)
		if (
			cta_style == null
			or cta_style.texture == null
		):
			failures.append("B18W richiede il CTA ornamentale ImageGen.")
		for definition in friend_registry.get_definitions():
			var selection_portrait := definition.get_public_selection_portrait()
			if selection_portrait == null or selection_portrait.get_size() != Vector2(256.0, 256.0):
				failures.append("B18T richiede un ritratto carosello HD derivato per %s." % definition.id)


static func _validate_cast_sprites(scene: Control, failures: Array[String]) -> void:
	var friend_registry: FriendRegistry = scene.get_friend_registry()
	var player: Player = scene.get_player()
	var character_sprite := player.get_node_or_null("CharacterSprite") as Sprite2D
	if character_sprite == null:
		failures.append("B18U richiede lo sprite Player dati.")
	elif character_sprite.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST:
		failures.append("B18U deve mostrare le strisce Player con filtro nearest.")
	for friend_definition in friend_registry.get_definitions():
		var expected_cast_path := (
			"res://assets/art/characters/%s/generated/sprite.png" % friend_definition.id
		)
		var cast_idle := friend_definition.get_gameplay_idle_right() as AtlasTexture
		var cast_walk := friend_definition.get_gameplay_walk_right_frames()
		if (
			cast_idle == null
			or cast_idle.atlas == null
			or cast_idle.atlas.resource_path != expected_cast_path
			or cast_idle.get_size() != Vector2(64.0, 64.0)
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
				or cast_atlas.get_size() != Vector2(64.0, 64.0)
			):
				failures.append("B18U frame originale non valido per %s." % friend_definition.id)
				break
		if cast_walk[0] == cast_idle or cast_walk[2] == cast_idle or cast_walk[0] == cast_walk[2]:
			failures.append("B18U richiede due passi distinti per %s." % friend_definition.id)


static func _validate_hud(scene: Control, failures: Array[String]) -> void:
	var arena_layout: ArenaLayout = scene.get_arena_layout()
	var run_controller: RunController = scene.get_run_controller()
	var touch_control_settings: TouchControlSettings = scene.get_touch_control_settings()
	var game_director: GameDirector = scene.get_game_director()
	var wave_event_scheduler: WaveEventScheduler = scene.get_wave_event_scheduler()
	var experience_system: ExperienceSystem = scene.get_experience_system()
	var player: Player = scene.get_player()
	var ability_controller: AbilityController = scene.get_ability_controller()
	var input_router: InputRouter = scene.get_node("%InputRouter")
	var hud: GameHud = scene.get_hud()
	var player_health := player.get_health_component()
	if hud == null:
		failures.append("HUD non presente.")
	else:
		if hud.get_run_controller() != run_controller:
			failures.append("HUD non collegato al RunController.")
		if hud.get_health_component() != player_health:
			failures.append("HUD non collegato alla salute Player.")
		if hud.get_experience_system() != experience_system:
			failures.append("HUD non collegato a ExperienceSystem.")
		if hud.get_ability_controller() != ability_controller:
			failures.append("HUD non collegato ad AbilityController.")
		if hud.get_game_director() != game_director:
			failures.append("HUD PS-005 non collegato al GameDirector.")
		if hud.get_wave_event_scheduler() != wave_event_scheduler:
			failures.append("HUD PS-008 non collegato al WaveEventScheduler.")
		if hud.is_wave_event_telegraph_visible():
			failures.append("HUD PS-008 deve partire senza telegraph d'ondata visibile.")
		if hud.is_boss_warning_visible():
			failures.append("HUD PS-005 deve partire senza warning Boss visibile.")
		if hud.get_friend_definition() != player.get_friend_definition():
			failures.append("HUD B18B privo del profilo Player corrente.")
		var top_band_rect := hud.get_top_band_rect()
		if absf(top_band_rect.size.y - hud.get_gameplay_top_inset()) > 1.0:
			failures.append("La fascia HUD B18Q deve coincidere con l'inset gameplay dichiarato.")
		var xp_line_rect := hud.get_experience_panel_rect()
		var health_line_rect := hud.get_health_panel_rect()
		var hud_viewport_rect := scene.get_viewport().get_visible_rect()
		if absf(xp_line_rect.size.y - 18.0) > 1.0:
			failures.append("La barra XP B18Q deve essere alta 18 unita logiche.")
		if absf(health_line_rect.size.y - 20.0) > 1.0:
			failures.append("La barra vita B18Q deve essere alta 20 unita logiche.")
		if hud.get_experience_kind_text() != "XP" or hud.get_health_kind_text() != "HP":
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
		if arena_layout.get_playfield_rect().position.y < top_band_rect.end.y - 1.0:
			failures.append("Il playfield B18Q deve iniziare sotto l'intera fascia HUD.")
		var ability_panel_rect := hud.get_ability_panel_rect()
		var expected_ability_size := (
			TouchAbilityButton.BASE_TARGET_SIZE
			* touch_control_settings.get_ability_scale()
		)
		if (
			absf(ability_panel_rect.size.x - expected_ability_size) > 1.0
			or absf(ability_panel_rect.size.y - expected_ability_size) > 1.0
		):
			failures.append("B18P deve scalare insieme pannello e target abilita.")
		if hud.get_portrait_texture() != null or hud.get_portrait_rect().has_area():
			failures.append("B18Q deve rimuovere il ritratto Player dall'HUD.")
		if (
			not hud.get_health_text().is_empty()
			or not hud.get_experience_text().is_empty()
			or not hud.get_level_text().is_empty()
		):
			failures.append("B18Q non deve mostrare livello, label o valori numerici.")
		if hud.find_child("TimerPanel", true, false) != null:
			failures.append("Il cronometro B18Q deve essere flottante e senza card.")
		if not hud.get_experience_panel_rect().has_area():
			failures.append("HUD privo di una barra XP con layout valido.")
		if not hud.get_pause_button_rect().has_area():
			failures.append("HUD privo di un pulsante pausa con layout valido.")
		if not hud.get_active_ability_button_rect().has_area():
			failures.append("HUD privo del pulsante abilita touch.")
		elif (
			hud.get_active_ability_button_rect().size.x < TouchAbilityButton.BASE_TARGET_SIZE
			or hud.get_active_ability_button_rect().size.y < TouchAbilityButton.BASE_TARGET_SIZE
		):
			failures.append("Il pulsante abilita B31 deve conservare il target touch base raddoppiato.")
		var ability_button := hud.get_active_ability_button()
		if ability_button == null:
			failures.append("B18K richiede un TouchAbilityButton valido.")
		elif ability_button.get_ability_icon() != ability_controller.get_definition().icon:
			failures.append("Il pulsante B18K deve usare l'icona dell'abilita equipaggiata.")
		elif not ability_button.text.is_empty():
			failures.append("Il pulsante B18K non deve mostrare testo esterno all'icona.")
		elif not ability_button.get_theme_stylebox("normal") is StyleBoxEmpty:
			failures.append("Il pulsante B18K non deve disegnare un rettangolo di sfondo.")
		if (
			hud.get_pause_button_rect().size.x < 44.0
			or hud.get_pause_button_rect().size.y < 44.0
		):
			failures.append("Il pulsante pausa B18B deve conservare un target touch di 44 unita.")
		if input_router.get_active_ability_button() != hud.get_active_ability_button():
			failures.append("InputRouter non collegato al pulsante abilita touch.")


static func _validate_enemy_scene(scene: Control, failures: Array[String]) -> void:
	var enemy_spawner: EnemySpawner = scene.get_enemy_spawner()
	if enemy_spawner.enemy_scene != null:
		var enemy_candidate := enemy_spawner.enemy_scene.instantiate()
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


static func _validate_performance(scene: Control, failures: Array[String]) -> void:
	var combat_feedback: CombatFeedback = scene.get_combat_feedback()
	var performance_stress_harness: PerformanceStressHarness = scene.get_performance_stress_harness()
	var performance_monitor: PerformanceMonitor = scene.get_performance_monitor()
	var performance_profile: PerformanceProfile = scene.get_active_performance_profile()
	if performance_profile == null or not performance_profile.is_valid():
		failures.append("B18V richiede un PerformanceProfile valido.")
	if performance_monitor == null or performance_monitor.get_profile() != performance_profile:
		failures.append("B18V richiede il monitor configurato con il profilo corrente.")
	if performance_stress_harness == null:
		failures.append("B18V richiede lo stress harness scene-local.")
	if combat_feedback.max_active_effects != performance_profile.max_transient_feedback:
		failures.append("B18V deve applicare il budget VFX dichiarativo.")
