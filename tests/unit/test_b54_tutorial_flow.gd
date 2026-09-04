extends GutGameplayTest

const EXPECTED_PAGE_IDS: Array[StringName] = [
	&"objective", &"movement", &"ability", &"progression", &"enemies", &"boss",
]
const EXPECTED_ENEMY_SPRITE_PATHS: Array[String] = [
	"res://assets/art/enemies/pigeons/pigeon_base.png",
	"res://assets/art/enemies/pigeons/pigeon_swarmer.png",
	"res://assets/art/enemies/pigeons/pigeon_armored.png",
	"res://assets/art/enemies/pigeons/pigeon_splitter.png",
	"res://assets/art/enemies/pigeons/pigeon_ranged.png",
]
const ABILITY_PAGE_INDEX := 2
const PROGRESSION_PAGE_INDEX := 3
const ENEMIES_PAGE_INDEX := 4
const BOSS_PAGE_INDEX := 5
## Campionatura fine del loop: uno scarto oltre la soglia indica un teletrasporto
## fra ultimo e primo frame, non il normale avanzamento continuo.
const LOOP_SAMPLE_COUNT := 720
const LOOP_CONTINUITY_TOLERANCE := 2.5
const TUTORIAL_ARTWORK_PATHS: Array[String] = [
	"res://assets/art/ui/tutorial/generated/tutorial_objective.png",
	"res://assets/art/ui/tutorial/generated/tutorial_movement.png",
]
## PS-048: ability, progression e boss sono passate da vetrina a icone a un
## singolo artwork fedele al runtime; i tre file sono segnaposto "fake_"
## in attesa dell'arte definitiva di PS-049.
# PS-049 ha sostituito i placeholder `fake_*` con le illustrazioni definitive;
# questo file era fermo a PS-048 e cercava ancora i percorsi vecchi.
const ABILITY_ARTWORK_PATH := "res://assets/art/ui/tutorial/generated/tutorial_ability_button.png"
const PROGRESSION_ARTWORK_PATH := "res://assets/art/ui/tutorial/generated/tutorial_pickups.png"
const BOSS_ARTWORK_PATH := "res://assets/art/ui/tutorial/generated/tutorial_telegraphs.png"
const LAYOUT_PROFILES: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 720),
	Vector2i(960, 720),
]


func test_tutorial_flow() -> void:
	ProjectSettings.set_setting("application/run/b18o_force_welcome_for_test", true)
	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	add_child_autofree(movement_slice)
	ProjectSettings.set_setting("application/run/b18o_force_welcome_for_test", false)
	await wait_process_frames(2)

	var controller := movement_slice.get_run_controller() as RunController
	var welcome := movement_slice.get_welcome_screen() as WelcomeScreen
	var tutorial := movement_slice.get_tutorial_screen() as TutorialScreen
	var selector := movement_slice.get_character_select_overlay() as CharacterSelectOverlay
	var lifecycle := movement_slice.get_platform_lifecycle() as PlatformLifecycle
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	var router := movement_slice.get_node("InputRouter") as InputRouter
	var hud := movement_slice.get_hud() as GameHud
	var joystick := movement_slice.get_node("UI/SafeAreaRoot/TouchJoystick") as TouchJoystick

	assert_true(
		controller != null and welcome != null and tutorial != null and selector != null, "Il frontend B54 deve essere composto."
	)
	if controller == null or welcome == null or tutorial == null or selector == null:
		ProjectSettings.set_setting("application/run/b18o_force_welcome_for_test", false)
		return

	var play_button := welcome.get_play_button()
	var tutorial_button := welcome.get_tutorial_button()
	var settings_button := welcome.get_settings_button()
	assert_true(
		play_button != null and tutorial_button != null and settings_button != null,
		"La welcome B54 deve esporre GIOCA, TUTORIAL e ingranaggio."
	)
	if play_button == null or tutorial_button == null or settings_button == null:
		return
	assert_eq(tutorial_button.text, "TUTORIAL", "Il CTA secondario deve chiamarsi TUTORIAL.")
	assert_true(
		tutorial_button.custom_minimum_size.y >= 44.0 and tutorial_button.custom_minimum_size.y < play_button.custom_minimum_size.y,
		"TUTORIAL deve conservare un target touch valido ma meno enfasi di GIOCA."
	)
	var tutorial_style := tutorial_button.get_theme_stylebox("normal") as StyleBoxTexture
	var play_style := play_button.get_theme_stylebox("normal") as StyleBoxTexture
	assert_true(
		tutorial_style != null and play_style != null and tutorial_style.texture != play_style.texture,
		"TUTORIAL deve usare la placca secondaria, distinta da quella primaria di GIOCA."
	)
	assert_true(
		play_button.focus_neighbor_bottom == play_button.get_path_to(tutorial_button)
		and tutorial_button.focus_neighbor_top == tutorial_button.get_path_to(play_button)
		and tutorial_button.focus_neighbor_bottom == tutorial_button.get_path_to(settings_button),
		"Il percorso focus B54 deve essere GIOCA, TUTORIAL, impostazioni."
	)
	assert_true(
		tutorial_button.global_position.y >= play_button.global_position.y + play_button.size.y,
		"TUTORIAL deve essere posizionato sotto GIOCA."
	)

	assert_true(controller.get_state() == RunController.RunState.BOOT, "La welcome deve partire in BOOT.")
	tutorial_button.pressed.emit()
	await wait_process_frames(2)
	assert_true(
		tutorial.visible and not welcome.visible and not selector.visible, "TUTORIAL deve aprire solo la sezione dedicata."
	)
	_assert_boot_invariants(controller, spawner, router, hud, joystick, "apertura")
	assert_eq(tutorial.get_page_count(), 6, "Il carosello B54 deve contenere sei pagine.")
	assert_true(tutorial.get_page_ids() == EXPECTED_PAGE_IDS, "Le sei pagine B54 devono avere ordine autorevole.")
	for page in tutorial.pages:
		assert_true(page != null and page.is_valid(), "Ogni pagina tutorial deve essere una risorsa valida.")
	assert_eq(tutorial.get_current_page_index(), 0, "Una nuova apertura deve partire dalla prima pagina.")
	assert_eq(tutorial.get_page_counter_text(), "01 / 06", "La prima pagina deve mostrare 01 / 06.")
	assert_true(
		not tutorial.get_previous_button().disabled and tutorial.get_previous_button().text == "ESCI",
		"Il controllo sinistro deve essere attivo e chiamarsi ESCI sulla prima pagina."
	)
	assert_eq(tutorial.get_next_button().text, "AVANTI", "Il CTA intermedio deve chiamarsi AVANTI.")
	assert_true(
		tutorial.pages[0].artwork.resource_path == TUTORIAL_ARTWORK_PATHS[0]
		and tutorial.pages[1].artwork.resource_path == TUTORIAL_ARTWORK_PATHS[1],
		"Obiettivo e movimento devono usare gli artwork tutorial dedicati."
	)
	assert_true(not tutorial.is_preview_animation_active(), "L'artwork della prima pagina deve restare immobile.")
	await wait_process_frames(2)
	assert_true(is_zero_approx(tutorial.get_preview_animation_phase()), "Senza camminata la fase non deve avanzare.")
	_assert_boot_invariants(controller, spawner, router, hud, joystick, "preview")
	tutorial.get_previous_button().pressed.emit()
	await wait_process_frames(2)
	assert_true(
		welcome.visible and not tutorial.visible, "ESCI sulla prima pagina deve tornare alla welcome invece di sembrare rotto."
	)
	assert_true(
		get_tree().root.gui_get_focus_owner() == tutorial_button, "ESCI deve restituire il focus a TUTORIAL."
	)
	tutorial_button.pressed.emit()
	await wait_process_frames(2)
	assert_eq(tutorial.get_current_page_index(), 0, "Una nuova apertura dopo ESCI deve ripartire da pagina uno.")

	tutorial.get_next_button().pressed.emit()
	await wait_process_frames(2)
	assert_eq(tutorial.get_current_page_index(), 1, "AVANTI deve mostrare una sola pagina successiva.")
	assert_true(
		not tutorial.simulate_swipe(Vector2(400.0, 300.0), Vector2(390.0, 180.0)) and tutorial.get_current_page_index() == 1,
		"Un gesto verticale non deve cambiare pagina."
	)
	_simulate_touch_swipe(tutorial, Vector2(700.0, 300.0), Vector2(540.0, 304.0))
	await wait_process_frames(2)
	assert_eq(tutorial.get_current_page_index(), 2, "Uno swipe a sinistra deve avanzare di una pagina.")
	_simulate_touch_swipe(tutorial, Vector2(540.0, 300.0), Vector2(700.0, 304.0))
	await wait_process_frames(2)
	assert_eq(tutorial.get_current_page_index(), 1, "Uno swipe a destra deve tornare di una pagina.")

	await _assert_artwork_page(tutorial, ABILITY_PAGE_INDEX, "03 / 06", "Abilità", ABILITY_ARTWORK_PATH)
	await _assert_artwork_page(tutorial, PROGRESSION_PAGE_INDEX, "04 / 06", "Potenziamenti", PROGRESSION_ARTWORK_PATH)

	assert_true(tutorial.show_page(ENEMIES_PAGE_INDEX), "La pagina Nemici deve essere raggiungibile.")
	await wait_process_frames(2)
	assert_eq(tutorial.get_page_counter_text(), "05 / 06", "La pagina Nemici deve mostrare 05 / 06.")
	assert_eq(tutorial.get_showcase_item_count(), 5, "La pagina Nemici deve mostrare cinque famiglie.")
	assert_true(
		tutorial.get_walker_row_counts() == [2, 3], "I cinque piccioni devono stare su due file, due sopra e tre sotto."
	)
	assert_eq(
		tutorial.get_gallery_label_count(), 0, "La composizione Nemici non deve contenere etichette: i nomi restano nel testo."
	)
	var enemy_sprites := tutorial.get_showcase_textures()
	assert_eq(enemy_sprites.size(), 5, "Ogni famiglia nemica deve avere la propria sprite.")
	if enemy_sprites.size() == 5:
		for index in EXPECTED_ENEMY_SPRITE_PATHS.size():
			var sprite := enemy_sprites[index]
			assert_true(
				sprite != null and sprite.resource_path == EXPECTED_ENEMY_SPRITE_PATHS[index],
				"La pagina Nemici deve riusare lo strip di camminata %s." % EXPECTED_ENEMY_SPRITE_PATHS[index]
			)
	assert_true(tutorial.is_preview_animation_active(), "La camminata dei piccioni deve essere attiva.")
	var walk_phase := tutorial.get_preview_animation_phase()
	await wait_process_frames(2)
	assert_true(
		tutorial.get_preview_animation_phase() > walk_phase, "La camminata dei piccioni deve avanzare senza usare il clock della run."
	)
	_assert_continuous_loop(tutorial, "Nemici")

	assert_true(tutorial.show_page(BOSS_PAGE_INDEX), "La pagina Boss deve essere raggiungibile.")
	await wait_process_frames(2)
	assert_eq(tutorial.get_next_button().text, "GIOCA", "L'ultima pagina deve sostituire AVANTI con GIOCA.")
	assert_true(not tutorial.is_preview_animation_active(), "L'artwork della pagina Boss deve restare immobile.")
	assert_true(
		tutorial.pages[BOSS_PAGE_INDEX].artwork != null
		and tutorial.pages[BOSS_PAGE_INDEX].artwork.resource_path == BOSS_ARTWORK_PATH,
		"PS-048: la pagina Boss deve mostrare i tre telegraph (linea, anello, area)."
	)
	await _assert_layout_profiles(movement_slice, welcome, tutorial)

	## Il ritorno avviene dalla pagina Nemici: e' l'unica animata, quindi l'unica
	## che potrebbe restare a girare dietro la welcome.
	assert_true(tutorial.show_page(ENEMIES_PAGE_INDEX), "La pagina Nemici deve restare raggiungibile.")
	await wait_process_frames(2)
	assert_true(lifecycle.request_back(), "Back deve chiudere il tutorial in BOOT.")
	await wait_process_frames(2)
	assert_true(welcome.visible and not tutorial.visible, "Back dal tutorial deve tornare alla welcome.")
	assert_true(
		not tutorial.is_preview_animation_active(), "La camminata deve fermarsi quando il tutorial è nascosto."
	)
	assert_true(get_tree().root.gui_get_focus_owner() == tutorial_button, "Back deve restituire il focus a TUTORIAL.")
	_assert_boot_invariants(controller, spawner, router, hud, joystick, "chiusura")

	tutorial_button.pressed.emit()
	await wait_process_frames(2)
	assert_eq(tutorial.get_current_page_index(), 0, "Riaprire il tutorial deve resettare la prima pagina.")
	assert_true(tutorial.show_page(5), "La CTA finale deve essere testabile.")
	tutorial.get_next_button().pressed.emit()
	await wait_process_frames(2)
	assert_true(selector.visible and not tutorial.visible and not welcome.visible, "GIOCA finale deve aprire il selettore.")
	_assert_boot_invariants(controller, spawner, router, hud, joystick, "selettore finale")

	if is_instance_valid(controller):
		controller.prepare_restart()


## PS-048: ability e progression non mostrano piu' una vetrina a icone ma un
## singolo artwork fedele al runtime (stesso contratto gia' usato da Boss).
func _assert_artwork_page(
	tutorial: TutorialScreen, page_index: int, expected_counter: String, context: String, expected_artwork_path: String
) -> void:
	assert_true(tutorial.show_page(page_index), "%s: la pagina deve essere raggiungibile." % context)
	await wait_process_frames(2)
	assert_eq(tutorial.get_page_counter_text(), expected_counter, "%s: il contatore deve mostrare %s." % [context, expected_counter])
	assert_eq(
		tutorial.get_showcase_item_count(), 0, "%s: l'artwork singolo non deve avere una vetrina a icone." % context
	)
	assert_true(
		tutorial.pages[page_index].artwork != null
		and tutorial.pages[page_index].artwork.resource_path == expected_artwork_path,
		"%s: deve usare l'artwork %s." % [context, expected_artwork_path]
	)
	assert_true(not tutorial.is_preview_animation_active(), "%s: l'artwork deve restare immobile." % context)


func _assert_continuous_loop(tutorial: TutorialScreen, context: String) -> void:
	var worst := tutorial.measure_preview_loop_discontinuity(LOOP_SAMPLE_COUNT)
	assert_true(
		worst <= LOOP_CONTINUITY_TOLERANCE, "%s: il loop deve restare continuo alla giunzione, scarto massimo %.3f." % [context, worst]
	)


func _assert_boot_invariants(
	controller: RunController, spawner: EnemySpawner, router: InputRouter, hud: GameHud, joystick: TouchJoystick, context: String
) -> void:
	assert_true(controller.get_state() == RunController.RunState.BOOT, "%s: il tutorial deve restare in BOOT." % context)
	assert_true(controller.get_seed() == 0, "%s: il tutorial non deve inizializzare il seed." % context)
	controller._process(1.0)
	assert_true(is_zero_approx(controller.get_run_time()), "%s: il tutorial non deve avanzare il clock." % context)
	assert_true(spawner.get_alive_count() == 0, "%s: il tutorial non deve creare nemici." % context)
	assert_true(router.is_input_suspended(), "%s: l'input gameplay deve restare sospeso." % context)
	assert_true(not hud.visible and not joystick.visible, "%s: HUD e joystick gameplay devono restare nascosti." % context)
	assert_true(not joystick.is_active(), "%s: il joystick non deve possedere un dito." % context)


func _assert_layout_profiles(movement_slice: Control, welcome: WelcomeScreen, tutorial: TutorialScreen) -> void:
	for profile in LAYOUT_PROFILES:
		get_tree().root.content_scale_size = profile
		get_tree().root.size = profile
		await wait_process_frames(2)
		var arena := movement_slice.get_arena_layout() as ArenaLayout
		arena.refresh_layout()
		await wait_process_frames(2)
		var safe_area := arena.get_safe_area_rect()
		var tutorial_button_rect := welcome.get_tutorial_button().get_global_rect()
		var panel_rect := tutorial.get_main_panel_rect()
		var previous_rect := tutorial.get_previous_button().get_global_rect()
		var next_rect := tutorial.get_next_button().get_global_rect()
		assert_true(panel_rect.has_area(), "%s: il pannello tutorial deve avere area." % profile)
		assert_true(
			safe_area.encloses(tutorial_button_rect), "%s: il target TUTORIAL deve restare nella safe area della welcome." % profile
		)
		assert_true(safe_area.encloses(panel_rect), "%s: il tutorial deve restare nella safe area." % profile)
		var viewport_rect := get_tree().root.get_visible_rect()
		var backdrop_rect := tutorial.get_backdrop_rect()
		assert_true(
			backdrop_rect.encloses(viewport_rect), "%s: lo sfondo tutorial deve coprire il viewport intero, non la safe area." % profile
		)
		assert_true(panel_rect.encloses(previous_rect), "%s: ESCI/INDIETRO deve restare nel pannello." % profile)
		assert_true(panel_rect.encloses(next_rect), "%s: il CTA pagina deve restare nel pannello." % profile)
		assert_true(
			previous_rect.size.y >= 44.0 and next_rect.size.y >= 44.0, "%s: tutti i target tutorial devono essere touch-safe." % profile
		)
	get_tree().root.content_scale_size = INITIAL_VIEWPORT_SIZE
	get_tree().root.size = INITIAL_VIEWPORT_SIZE
	await wait_process_frames(2)


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
