extends SceneTree

const MOVEMENT_SLICE_SCENE := preload("res://scenes/game/movement_slice.tscn")
const INITIAL_VIEWPORT_SIZE := Vector2i(1280, 720)
const EXPECTED_PAGE_IDS: Array[StringName] = [
	&"objective",
	&"movement",
	&"ability",
	&"progression",
	&"enemies",
	&"boss",
]
const EXPECTED_ENEMY_TITLES: Array[String] = [
	"BASE",
	"SCIAME",
	"ARMATO",
	"DIVIDE",
	"SPARA",
]
const TUTORIAL_ARTWORK_PATHS: Array[String] = [
	"res://assets/art/ui/tutorial/generated/tutorial_objective.png",
	"res://assets/art/ui/tutorial/generated/tutorial_movement.png",
	"res://assets/art/ui/tutorial/generated/tutorial_boss.png",
]
const SPECIAL_ENEMY_ICON_PATHS: Array[String] = [
	"res://assets/art/icons/enemies/generated/enemy_swarmer.png",
	"res://assets/art/icons/enemies/generated/enemy_armored.png",
	"res://assets/art/icons/enemies/generated/enemy_splitter.png",
	"res://assets/art/icons/enemies/generated/enemy_ranged.png",
]
const LAYOUT_PROFILES: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 720),
	Vector2i(960, 720),
]

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	paused = false
	root.content_scale_size = INITIAL_VIEWPORT_SIZE
	root.size = INITIAL_VIEWPORT_SIZE
	await _wait_processed_frame()
	await _validate_tutorial_flow()
	await _finish()


func _validate_tutorial_flow() -> void:
	ProjectSettings.set_setting("application/run/b18o_force_welcome_for_test", true)
	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	root.add_child(movement_slice)
	ProjectSettings.set_setting("application/run/b18o_force_welcome_for_test", false)
	await _wait_processed_frame()

	var controller := movement_slice.get_run_controller() as RunController
	var welcome := movement_slice.get_welcome_screen() as WelcomeScreen
	var tutorial := movement_slice.get_tutorial_screen() as TutorialScreen
	var selector := movement_slice.get_character_select_overlay() as CharacterSelectOverlay
	var lifecycle := movement_slice.get_platform_lifecycle() as PlatformLifecycle
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	var router := movement_slice.get_node("InputRouter") as InputRouter
	var hud := movement_slice.get_hud() as GameHud
	var joystick := movement_slice.get_node("UI/SafeAreaRoot/TouchJoystick") as TouchJoystick

	_expect(
		controller != null and welcome != null and tutorial != null and selector != null,
		"Il frontend B54 deve essere composto."
	)
	if controller == null or welcome == null or tutorial == null or selector == null:
		await _dispose(movement_slice, controller)
		return

	var play_button := welcome.get_play_button()
	var tutorial_button := welcome.get_tutorial_button()
	var settings_button := welcome.get_settings_button()
	_expect(
		play_button != null and tutorial_button != null and settings_button != null,
		"La welcome B54 deve esporre GIOCA, TUTORIAL e ingranaggio."
	)
	if play_button == null or tutorial_button == null or settings_button == null:
		await _dispose(movement_slice, controller)
		return
	_expect(tutorial_button.text == "TUTORIAL", "Il CTA secondario deve chiamarsi TUTORIAL.")
	_expect(
		tutorial_button.custom_minimum_size.y >= 44.0
		and tutorial_button.custom_minimum_size.y < play_button.custom_minimum_size.y,
		"TUTORIAL deve conservare un target touch valido ma meno enfasi di GIOCA."
	)
	_expect(
		tutorial_button.get_theme_stylebox("normal") is StyleBoxFlat
		and play_button.get_theme_stylebox("normal") is StyleBoxTexture,
		"TUTORIAL deve usare la tinta secondaria distinta dalla placca primaria."
	)
	_expect(
		play_button.focus_neighbor_bottom == play_button.get_path_to(tutorial_button)
		and tutorial_button.focus_neighbor_top == tutorial_button.get_path_to(play_button)
		and tutorial_button.focus_neighbor_bottom == tutorial_button.get_path_to(settings_button),
		"Il percorso focus B54 deve essere GIOCA, TUTORIAL, impostazioni."
	)
	_expect(
		tutorial_button.global_position.y >= play_button.global_position.y + play_button.size.y,
		"TUTORIAL deve essere posizionato sotto GIOCA."
	)

	_expect(controller.get_state() == RunController.RunState.BOOT, "La welcome deve partire in BOOT.")
	tutorial_button.pressed.emit()
	await _wait_processed_frame()
	_expect(tutorial.visible and not welcome.visible and not selector.visible, "TUTORIAL deve aprire solo la sezione dedicata.")
	_validate_boot_invariants(controller, spawner, router, hud, joystick, "apertura")
	_expect(tutorial.get_page_count() == 6, "Il carosello B54 deve contenere sei pagine.")
	_expect(tutorial.get_page_ids() == EXPECTED_PAGE_IDS, "Le sei pagine B54 devono avere ordine autorevole.")
	for page in tutorial.pages:
		_expect(page != null and page.is_valid(), "Ogni pagina tutorial deve essere una risorsa valida.")
	_expect(tutorial.get_current_page_index() == 0, "Una nuova apertura deve partire dalla prima pagina.")
	_expect(tutorial.get_page_counter_text() == "01 / 06", "La prima pagina deve mostrare 01 / 06.")
	_expect(
		not tutorial.get_previous_button().disabled
		and tutorial.get_previous_button().text == "ESCI",
		"Il controllo sinistro deve essere attivo e chiamarsi ESCI sulla prima pagina."
	)
	_expect(tutorial.get_next_button().text == "AVANTI", "Il CTA intermedio deve chiamarsi AVANTI.")
	_expect(
		tutorial.pages[0].artwork.resource_path == TUTORIAL_ARTWORK_PATHS[0]
		and tutorial.pages[1].artwork.resource_path == TUTORIAL_ARTWORK_PATHS[1]
		and tutorial.pages[5].artwork.resource_path == TUTORIAL_ARTWORK_PATHS[2],
		"Obiettivo, movimento e Boss devono usare gli artwork tutorial dedicati."
	)
	_expect(tutorial.is_preview_animation_active(), "La preview visibile deve animarsi.")
	var first_phase := tutorial.get_preview_animation_phase()
	await _wait_processed_frame()
	_expect(
		tutorial.get_preview_animation_phase() > first_phase,
		"La preview visibile deve avanzare senza usare il clock della run."
	)
	_validate_boot_invariants(controller, spawner, router, hud, joystick, "preview")
	tutorial.get_previous_button().pressed.emit()
	await _wait_processed_frame()
	_expect(
		welcome.visible and not tutorial.visible,
		"ESCI sulla prima pagina deve tornare alla welcome invece di sembrare rotto."
	)
	_expect(root.gui_get_focus_owner() == tutorial_button, "ESCI deve restituire il focus a TUTORIAL.")
	tutorial_button.pressed.emit()
	await _wait_processed_frame()
	_expect(tutorial.get_current_page_index() == 0, "Una nuova apertura dopo ESCI deve ripartire da pagina uno.")

	tutorial.get_next_button().pressed.emit()
	await _wait_processed_frame()
	_expect(tutorial.get_current_page_index() == 1, "AVANTI deve mostrare una sola pagina successiva.")
	_expect(
		not tutorial.simulate_swipe(Vector2(400.0, 300.0), Vector2(390.0, 180.0))
		and tutorial.get_current_page_index() == 1,
		"Un gesto verticale non deve cambiare pagina."
	)
	_simulate_touch_swipe(tutorial, Vector2(700.0, 300.0), Vector2(540.0, 304.0))
	await _wait_processed_frame()
	_expect(tutorial.get_current_page_index() == 2, "Uno swipe a sinistra deve avanzare di una pagina.")
	_simulate_touch_swipe(tutorial, Vector2(540.0, 300.0), Vector2(700.0, 304.0))
	await _wait_processed_frame()
	_expect(tutorial.get_current_page_index() == 1, "Uno swipe a destra deve tornare di una pagina.")

	_expect(tutorial.show_page(4), "La pagina Nemici deve essere raggiungibile.")
	await _wait_processed_frame()
	_expect(tutorial.get_page_counter_text() == "05 / 06", "La pagina Nemici deve mostrare 05 / 06.")
	_expect(tutorial.get_showcase_item_count() == 5, "La pagina Nemici deve mostrare cinque famiglie.")
	_expect(tutorial.get_current_page().showcase_labels == EXPECTED_ENEMY_TITLES, "Nomi e ordine dei nemici devono essere autorevoli.")
	var enemy_icons := tutorial.get_showcase_textures()
	_expect(enemy_icons.size() == 5, "Ogni famiglia nemica deve avere un'icona.")
	if enemy_icons.size() == 5:
		_expect(enemy_icons[0] is AtlasTexture, "Il piccione base deve usare una posa della sprite gameplay.")
		for index in SPECIAL_ENEMY_ICON_PATHS.size():
			var icon := enemy_icons[index + 1]
			_expect(
				icon != null and icon.resource_path == SPECIAL_ENEMY_ICON_PATHS[index],
				"La pagina Nemici deve riusare l'icona B49 %s." % SPECIAL_ENEMY_ICON_PATHS[index]
			)
	_expect(tutorial.is_preview_animation_active(), "Le icone definitive devono ricevere soltanto l'animazione presentazionale attiva.")

	_expect(tutorial.show_page(5), "La pagina Boss deve essere raggiungibile.")
	await _wait_processed_frame()
	_expect(tutorial.get_next_button().text == "GIOCA", "L'ultima pagina deve sostituire AVANTI con GIOCA.")
	_expect(tutorial.is_preview_animation_active(), "La pagina Boss deve avere una preview attiva.")
	await _validate_layout_profiles(movement_slice, welcome, tutorial)

	_expect(lifecycle.request_back(), "Back deve chiudere il tutorial in BOOT.")
	await _wait_processed_frame()
	_expect(welcome.visible and not tutorial.visible, "Back dal tutorial deve tornare alla welcome.")
	_expect(not tutorial.is_preview_animation_active(), "Le preview devono fermarsi quando il tutorial è nascosto.")
	_expect(root.gui_get_focus_owner() == tutorial_button, "Back deve restituire il focus a TUTORIAL.")
	_validate_boot_invariants(controller, spawner, router, hud, joystick, "chiusura")

	tutorial_button.pressed.emit()
	await _wait_processed_frame()
	_expect(tutorial.get_current_page_index() == 0, "Riaprire il tutorial deve resettare la prima pagina.")
	_expect(tutorial.show_page(5), "La CTA finale deve essere testabile.")
	tutorial.get_next_button().pressed.emit()
	await _wait_processed_frame()
	_expect(selector.visible and not tutorial.visible and not welcome.visible, "GIOCA finale deve aprire il selettore.")
	_validate_boot_invariants(controller, spawner, router, hud, joystick, "selettore finale")

	await _dispose(movement_slice, controller)


func _validate_boot_invariants(
	controller: RunController,
	spawner: EnemySpawner,
	router: InputRouter,
	hud: GameHud,
	joystick: TouchJoystick,
	context: String
) -> void:
	_expect(controller.get_state() == RunController.RunState.BOOT, "%s: il tutorial deve restare in BOOT." % context)
	_expect(controller.get_seed() == 0, "%s: il tutorial non deve inizializzare il seed." % context)
	controller._process(1.0)
	_expect(is_zero_approx(controller.get_run_time()), "%s: il tutorial non deve avanzare il clock." % context)
	_expect(spawner.get_alive_count() == 0, "%s: il tutorial non deve creare nemici." % context)
	_expect(router.is_input_suspended(), "%s: l'input gameplay deve restare sospeso." % context)
	_expect(not hud.visible and not joystick.visible, "%s: HUD e joystick gameplay devono restare nascosti." % context)
	_expect(not joystick.is_active(), "%s: il joystick non deve possedere un dito." % context)


func _validate_layout_profiles(
	movement_slice: Control,
	welcome: WelcomeScreen,
	tutorial: TutorialScreen
) -> void:
	for profile in LAYOUT_PROFILES:
		root.content_scale_size = profile
		root.size = profile
		await _wait_processed_frame()
		var arena := movement_slice.get_arena_layout() as ArenaLayout
		arena.refresh_layout()
		await _wait_processed_frame()
		var safe_area := arena.get_safe_area_rect()
		var tutorial_button_rect := welcome.get_tutorial_button().get_global_rect()
		var panel_rect := tutorial.get_main_panel_rect()
		var previous_rect := tutorial.get_previous_button().get_global_rect()
		var next_rect := tutorial.get_next_button().get_global_rect()
		_expect(panel_rect.has_area(), "%s: il pannello tutorial deve avere area." % profile)
		_expect(
			safe_area.encloses(tutorial_button_rect),
			"%s: il target TUTORIAL deve restare nella safe area della welcome." % profile
		)
		_expect(safe_area.encloses(panel_rect), "%s: il tutorial deve restare nella safe area." % profile)
		_expect(panel_rect.encloses(previous_rect), "%s: ESCI/INDIETRO deve restare nel pannello." % profile)
		_expect(panel_rect.encloses(next_rect), "%s: il CTA pagina deve restare nel pannello." % profile)
		_expect(
			previous_rect.size.y >= 44.0 and next_rect.size.y >= 44.0,
			"%s: tutti i target tutorial devono essere touch-safe." % profile
		)
	root.content_scale_size = INITIAL_VIEWPORT_SIZE
	root.size = INITIAL_VIEWPORT_SIZE
	await _wait_processed_frame()


func _simulate_touch_swipe(tutorial: TutorialScreen, start: Vector2, finish: Vector2) -> void:
	var press := InputEventScreenTouch.new()
	press.index = 7
	press.position = start
	press.pressed = true
	tutorial._input(press)
	var release := InputEventScreenTouch.new()
	release.index = 7
	release.position = finish
	release.pressed = false
	tutorial._input(release)


func _dispose(movement_slice: Node, controller: RunController) -> void:
	ProjectSettings.set_setting("application/run/b18o_force_welcome_for_test", false)
	if is_instance_valid(controller):
		controller.prepare_restart()
	paused = false
	if is_instance_valid(movement_slice):
		movement_slice.queue_free()
	await process_frame


func _wait_processed_frame() -> void:
	await process_frame
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	paused = false
	await process_frame
	if _failures.is_empty():
		print("B54_TUTORIAL_FLOW_SMOKE_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	printerr("B54_TUTORIAL_FLOW_SMOKE_FAIL count=%d" % _failures.size())
	quit(1)
