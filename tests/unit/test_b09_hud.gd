extends GutGameplayTest

const HUD_SCENE := preload("res://scenes/ui/hud.tscn")
const EXPERIENCE_CURVE := preload("res://data/progression/default_experience_curve.tres")
const HUD_FLOAT_TOLERANCE := 0.01
const LAYOUT_TOLERANCE := 1.0


func test_hud_values_and_authoritative_clock() -> void:
	var fixture := Control.new()
	fixture.name = "HudValuesFixture"
	fixture.process_mode = Node.PROCESS_MODE_ALWAYS
	fixture.size = Vector2(1240.0, 680.0)

	var controller := RunController.new()
	controller.name = "RunController"
	controller.set_process(false)
	var health := HealthComponent.new()
	health.name = "HealthComponent"
	health.health_max = 100.0
	var experience := ExperienceSystem.new()
	experience.name = "ExperienceSystem"
	experience.experience_curve = EXPERIENCE_CURVE
	var hud := HUD_SCENE.instantiate() as GameHud

	fixture.add_child(controller)
	fixture.add_child(health)
	fixture.add_child(experience)
	fixture.add_child(hud)
	add_child_autofree(fixture)
	await wait_process_frames(2)

	experience.set_run_controller(controller)
	assert_true(hud.configure(controller, health, experience), "L'HUD deve accettare sorgenti gameplay valide.")
	assert_eq(hud.get_time_text(), "00:00", "Il timer deve partire da 00:00.")
	assert_true(hud.get_health_text().is_empty(), "B18Q deve rimuovere il testo vita.")
	assert_true(hud.get_level_text().is_empty(), "B18Q deve rimuovere il livello dall'HUD.")
	assert_true(hud.get_experience_text().is_empty(), "B18Q deve rimuovere il testo XP.")
	assert_almost_eq(hud.get_health_value(), 100.0, HUD_FLOAT_TOLERANCE, "La barra vita deve partire piena.")
	assert_almost_eq(hud.get_health_max(), 100.0, HUD_FLOAT_TOLERANCE, "La barra vita deve usare gli HP massimi.")
	assert_almost_eq(hud.get_experience_value(), 0.0, HUD_FLOAT_TOLERANCE, "La barra XP deve partire vuota.")
	assert_almost_eq(hud.get_experience_max(), 10.0, HUD_FLOAT_TOLERANCE, "La barra XP deve usare la soglia corrente.")
	assert_true(hud.get_pause_button().disabled, "PAUSA deve restare disabilitato prima della run.")

	assert_true(controller.start_run(9001), "La fixture HUD deve avviare la run.")
	assert_false(hud.get_pause_button().disabled, "PAUSA deve attivarsi in RUNNING.")
	controller._process(62.9)
	assert_eq(hud.get_time_text(), "01:02", "Il timer deve formattare il clock come MM:SS.")
	var feedback_count_before := hud.get_health_feedback_count()
	assert_true(health.take_damage(25.0), "La fixture deve applicare un danno di prova.")
	assert_almost_eq(hud.get_health_value(), 75.0, HUD_FLOAT_TOLERANCE, "La barra vita deve reagire al segnale atomico.")
	assert_true(hud.get_health_text().is_empty(), "Il danno non deve ripristinare valori numerici vita.")
	assert_eq(
		hud.get_health_feedback_count(),
		feedback_count_before + 1,
		"Il danno deve produrre un solo impulso presentazionale sull'HUD."
	)
	assert_true(experience.add_experience(5), "La fixture deve accreditare XP di prova.")
	assert_almost_eq(hud.get_experience_value(), 5.0, HUD_FLOAT_TOLERANCE, "La barra XP deve reagire alla progressione.")
	assert_true(hud.get_experience_text().is_empty(), "La progressione non deve ripristinare valori numerici XP.")

	var paused_time := controller.get_run_time()
	var paused_text := hud.get_time_text()
	assert_true(controller.request_manual_pause(), "La fixture HUD deve entrare in pausa.")
	assert_true(hud.get_pause_button().disabled, "PAUSA deve disabilitarsi in MANUAL_PAUSE.")
	controller._process(100.0)
	assert_almost_eq(
		controller.get_run_time(), paused_time, HUD_FLOAT_TOLERANCE, "Il clock autorevole deve fermarsi fuori da RUNNING."
	)
	assert_eq(hud.get_time_text(), paused_text, "L'HUD non deve avanzare un clock locale in pausa.")
	assert_true(controller.resume_run(), "La fixture HUD deve riprendere la run.")
	controller._process(0.2)
	assert_eq(hud.get_time_text(), "01:03", "Il timer deve riprendere dallo stesso istante.")

	assert_true(experience.add_experience(5), "La soglia esatta deve produrre il level-up.")
	assert_true(hud.get_level_text().is_empty(), "Il level-up non deve ripristinare il livello nell'HUD.")
	assert_almost_eq(hud.get_experience_value(), 0.0, HUD_FLOAT_TOLERANCE, "La barra deve ripartire vuota al nuovo livello.")
	assert_almost_eq(hud.get_experience_max(), 15.0, HUD_FLOAT_TOLERANCE, "La barra deve adottare la soglia successiva.")
	var level_up_text := hud.get_time_text()
	controller._process(10.0)
	assert_eq(hud.get_time_text(), level_up_text, "LEVEL_UP deve lasciare fermo il timer HUD.")
	assert_true(experience.complete_level_up(), "La fixture deve chiudere il level-up.")
	controller._process(1.0)
	assert_eq(hud.get_time_text(), "01:04", "Il timer deve riprendere dopo LEVEL_UP.")

	assert_true(controller.request_defeat(), "La fixture deve entrare nello stato terminale.")
	var terminal_text := hud.get_time_text()
	controller._process(10.0)
	assert_eq(hud.get_time_text(), terminal_text, "DEFEAT deve lasciare fermo il timer HUD.")
	assert_true(controller.restart_run(9002), "Il terminale deve accettare il restart.")
	assert_eq(hud.get_time_text(), "00:00", "Il restart deve azzerare subito il timer HUD.")
	assert_true(hud.get_level_text().is_empty(), "Il restart non deve ripristinare il livello HUD.")
	assert_almost_eq(hud.get_experience_value(), 0.0, HUD_FLOAT_TOLERANCE, "Il restart deve azzerare la barra XP.")
	assert_almost_eq(hud.get_experience_max(), 10.0, HUD_FLOAT_TOLERANCE, "Il restart deve ripristinare la soglia XP.")
	assert_eq(GameHud.format_run_time(-INF), "00:00", "Il formatter deve difendersi da valori non finiti.")
	assert_eq(GameHud.format_run_time(3605.9), "60:05", "Il formatter non deve riciclare i minuti.")

	controller.prepare_restart()


func test_responsive_layouts_across_aspect_ratios() -> void:
	var profiles := [
		{"name": "16:9", "safe_rect": Rect2(20.0, 20.0, 1240.0, 680.0)},
		{"name": "20:9 cutout", "safe_rect": Rect2(64.0, 20.0, 1472.0, 680.0)},
		{"name": "4:3", "safe_rect": Rect2(20.0, 20.0, 920.0, 680.0)},
	]

	for profile in profiles:
		var safe_rect: Rect2 = profile.safe_rect
		var safe_root := Control.new()
		safe_root.name = "SafeArea%s" % String(profile.name).replace(":", "")
		safe_root.position = safe_rect.position
		safe_root.size = safe_rect.size
		var hud := HUD_SCENE.instantiate() as GameHud
		safe_root.add_child(hud)
		add_child(safe_root)
		await wait_process_frames(2)

		var xp_rect := hud.get_experience_panel_rect()
		var top_band_rect := hud.get_top_band_rect()
		var health_rect := hud.get_health_panel_rect()
		var timer_rect := hud.get_timer_slot_rect()
		var pause_rect := hud.get_pause_button_rect()
		var ability_rect := hud.get_ability_panel_rect()
		var ability_button_rect := hud.get_active_ability_button_rect()
		var profile_name := String(profile.name)
		assert_rect_inside(xp_rect, safe_rect, "%s: la barra XP deve restare nella safe area." % profile_name, LAYOUT_TOLERANCE)
		assert_rect_inside(health_rect, safe_rect, "%s: la vita deve restare nella safe area." % profile_name, LAYOUT_TOLERANCE)
		assert_false(hud.get_portrait_rect().has_area(), "%s: B18Q deve rimuovere il ritratto." % profile_name)
		assert_rect_inside(timer_rect, safe_rect, "%s: il timer deve restare nella safe area." % profile_name, LAYOUT_TOLERANCE)
		assert_rect_inside(pause_rect, safe_rect, "%s: PAUSA deve restare nella safe area." % profile_name, LAYOUT_TOLERANCE)
		assert_rect_inside(ability_rect, safe_rect, "%s: l'abilita deve restare nella safe area." % profile_name, LAYOUT_TOLERANCE)
		assert_rect_inside(
			ability_button_rect, safe_rect, "%s: il touch abilita deve restare nella safe area." % profile_name, LAYOUT_TOLERANCE
		)
		assert_almost_eq(
			xp_rect.position.x,
			safe_rect.position.x,
			LAYOUT_TOLERANCE,
			"%s: la barra XP deve partire dall'inizio della safe area." % profile_name
		)
		assert_almost_eq(
			xp_rect.size.x, safe_rect.size.x, LAYOUT_TOLERANCE, "%s: la barra XP deve occupare tutta la larghezza utile." % profile_name
		)
		assert_almost_eq(
			timer_rect.get_center().x, safe_rect.get_center().x, LAYOUT_TOLERANCE, "%s: il timer deve restare centrato." % profile_name
		)
		assert_almost_eq(
			top_band_rect.size.y,
			GameHud.GAMEPLAY_TOP_INSET,
			LAYOUT_TOLERANCE,
			"%s: la fascia HUD deve dichiarare l'intero inset gameplay." % profile_name
		)
		assert_true(
			xp_rect.position.distance_to(safe_rect.position) <= LAYOUT_TOLERANCE,
			"%s: la barra XP deve essere il primo elemento della fascia." % profile_name
		)
		assert_true(
			absf(xp_rect.size.y - 18.0) <= LAYOUT_TOLERANCE, "%s: la barra XP deve essere alta 18 unita logiche." % profile_name
		)
		assert_true(
			absf(health_rect.position.y - xp_rect.end.y) <= LAYOUT_TOLERANCE
			and absf(health_rect.position.x - safe_rect.position.x) <= LAYOUT_TOLERANCE
			and absf(health_rect.size.x - safe_rect.size.x) <= LAYOUT_TOLERANCE,
			"%s: la vita deve seguire XP e usare tutta la larghezza." % profile_name
		)
		assert_true(
			absf(health_rect.size.y - 20.0) <= LAYOUT_TOLERANCE, "%s: la barra HP deve essere alta 20 unita logiche." % profile_name
		)
		assert_true(
			hud.get_experience_kind_text() == "XP" and hud.get_health_kind_text() == "HP",
			"%s: le barre devono avere soltanto i tag XP e HP." % profile_name
		)
		assert_true(timer_rect.position.y >= health_rect.end.y, "%s: il timer deve stare sotto le barre." % profile_name)
		assert_null(hud.find_child("TimerPanel", true, false), "%s: il timer non deve avere card o sfondo." % profile_name)
		assert_true(
			pause_rect.size.x >= 44.0 - LAYOUT_TOLERANCE and pause_rect.size.y >= 44.0 - LAYOUT_TOLERANCE,
			"%s: PAUSA deve conservare un target touch leggibile." % profile_name
		)
		assert_true(
			ability_button_rect.size.x >= 64.0 - LAYOUT_TOLERANCE and ability_button_rect.size.y >= 64.0 - LAYOUT_TOLERANCE,
			"%s: ATTIVA deve conservare un target touch leggibile." % profile_name
		)
		assert_true(
			ability_rect.position.distance_to(ability_button_rect.position) <= LAYOUT_TOLERANCE
			and ability_rect.size.distance_to(ability_button_rect.size) <= LAYOUT_TOLERANCE,
			"%s: B18K deve lasciare soltanto l'icona senza card esterna." % profile_name
		)
		assert_true(
			timer_rect.end.x <= pause_rect.position.x + LAYOUT_TOLERANCE, "%s: timer e PAUSA non devono sovrapporsi." % profile_name
		)

		safe_root.queue_free()
		await wait_process_frames(1)


func test_composed_hud_observes_gameplay_without_polling() -> void:
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_node_or_null("RunController") as RunController
	var arena := movement_slice.get_node_or_null("ArenaLayout") as ArenaLayout
	var player := movement_slice.get_node_or_null("World/Player") as Player
	var experience := movement_slice.get_node_or_null("ExperienceSystem") as ExperienceSystem
	var hud := movement_slice.get_node_or_null("UI/SafeAreaRoot/HUD") as GameHud
	var spawner := movement_slice.get_node_or_null("EnemySpawner") as EnemySpawner
	var safe_root := movement_slice.get_node_or_null("UI/SafeAreaRoot") as Control
	var weapon: WeaponController
	if player != null:
		weapon = player.get_weapon_controller()

	assert_not_null(controller, "La scena B09 deve contenere RunController.")
	assert_not_null(arena, "La scena B09 deve contenere ArenaLayout.")
	assert_not_null(player, "La scena B09 deve contenere Player.")
	assert_not_null(experience, "La scena B09 deve contenere ExperienceSystem.")
	assert_not_null(hud, "La scena B09 deve contenere il nuovo HUD.")
	assert_not_null(safe_root, "La scena B09 deve contenere SafeAreaRoot.")
	if (
		controller == null
		or arena == null
		or player == null
		or experience == null
		or hud == null
		or safe_root == null
	):
		return

	controller.set_process(false)
	if spawner != null:
		spawner.set_process(false)
	player.set_physics_process(false)
	if weapon != null:
		weapon.set_process(false)

	assert_eq(hud.get_run_controller(), controller, "L'HUD composto deve osservare RunController.")
	assert_eq(hud.get_health_component(), player.get_health_component(), "L'HUD composto deve osservare la salute Player.")
	assert_eq(hud.get_experience_system(), experience, "L'HUD composto deve osservare ExperienceSystem.")
	assert_eq(
		hud.get_friend_definition(), player.get_friend_definition(), "L'HUD composto deve osservare il profilo Player."
	)
	assert_null(hud.get_portrait_texture(), "B18Q deve rimuovere il ritratto Player dall'HUD composto.")
	assert_true(hud.get_health_text().is_empty(), "La scena composta non deve mostrare valori vita.")
	assert_true(hud.get_experience_text().is_empty(), "La scena composta non deve mostrare valori XP.")

	controller._process(4.2)
	assert_eq(hud.get_time_text(), "00:04", "La scena composta deve inoltrare il clock all'HUD.")
	assert_true(player.take_contact_damage(20.0), "La scena composta deve applicare danno di prova.")
	assert_almost_eq(hud.get_health_value(), 80.0, HUD_FLOAT_TOLERANCE, "La vita composta deve aggiornarsi senza polling.")
	assert_true(experience.add_experience(3), "La scena composta deve accreditare XP di prova.")
	assert_almost_eq(hud.get_experience_value(), 3.0, HUD_FLOAT_TOLERANCE, "Gli XP composti devono aggiornarsi senza polling.")

	var safe_rect := arena.get_safe_area_rect()
	assert_rect_near(
		safe_root.get_global_rect(), safe_rect, "SafeAreaRoot deve coincidere con la safe area di ArenaLayout.", LAYOUT_TOLERANCE
	)
	assert_rect_inside(
		hud.get_experience_panel_rect(), safe_rect, "La barra XP composta deve restare nella safe area.", LAYOUT_TOLERANCE
	)

	controller.request_defeat()
	assert_true(movement_slice.restart_run(9003), "Il restart composto deve essere disponibile.")
	assert_eq(hud.get_time_text(), "00:00", "Il restart composto deve azzerare il timer.")
	assert_almost_eq(hud.get_health_value(), 100.0, HUD_FLOAT_TOLERANCE, "Il restart composto deve ripristinare la vita HUD.")
	assert_almost_eq(hud.get_experience_value(), 0.0, HUD_FLOAT_TOLERANCE, "Il restart composto deve ripristinare gli XP HUD.")

	controller.prepare_restart()
