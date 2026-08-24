extends SceneTree

const HUD_SCENE := preload("res://scenes/ui/hud.tscn")
const MOVEMENT_SLICE_SCENE := preload("res://scenes/game/movement_slice.tscn")
const EXPERIENCE_CURVE := preload("res://data/progression/default_experience_curve.tres")
const FLOAT_TOLERANCE := 0.01
const LAYOUT_TOLERANCE := 1.0
const INITIAL_VIEWPORT_SIZE := Vector2i(1280, 720)

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	await _validate_hud_values_and_clock()
	await _validate_responsive_layouts()
	await _validate_composed_hud()
	await _finish()


func _validate_hud_values_and_clock() -> void:
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
	root.add_child(fixture)
	await _wait_processed_frame()

	experience.set_run_controller(controller)
	_expect(
		hud.configure(controller, health, experience),
		"L'HUD deve accettare sorgenti gameplay valide."
	)
	_expect(hud.get_time_text() == "00:00", "Il timer deve partire da 00:00.")
	_expect(hud.get_health_text() == "VITA  100 / 100", "La vita iniziale deve essere leggibile.")
	_expect(hud.get_level_text() == "LV 1", "Il livello iniziale deve essere leggibile.")
	_expect(hud.get_experience_text() == "0 / 10 XP", "La prima soglia XP deve essere leggibile.")
	_expect_float_near(hud.get_health_value(), 100.0, "La barra vita deve partire piena.")
	_expect_float_near(hud.get_health_max(), 100.0, "La barra vita deve usare gli HP massimi.")
	_expect_float_near(hud.get_experience_value(), 0.0, "La barra XP deve partire vuota.")
	_expect_float_near(hud.get_experience_max(), 10.0, "La barra XP deve usare la soglia corrente.")
	_expect(hud.get_pause_button().disabled, "PAUSA deve restare disabilitato prima della run.")

	_expect(controller.start_run(9001), "La fixture HUD deve avviare la run.")
	_expect(not hud.get_pause_button().disabled, "PAUSA deve attivarsi in RUNNING.")
	controller._process(62.9)
	_expect(hud.get_time_text() == "01:02", "Il timer deve formattare il clock come MM:SS.")
	var feedback_count_before := hud.get_health_feedback_count()
	_expect(health.take_damage(25.0), "La fixture deve applicare un danno di prova.")
	_expect_float_near(hud.get_health_value(), 75.0, "La barra vita deve reagire al segnale atomico.")
	_expect(hud.get_health_text() == "VITA  75 / 100", "Il testo vita deve seguire la barra.")
	_expect(
		hud.get_health_feedback_count() == feedback_count_before + 1,
		"Il danno deve produrre un solo impulso presentazionale sull'HUD."
	)
	_expect(experience.add_experience(5), "La fixture deve accreditare XP di prova.")
	_expect_float_near(hud.get_experience_value(), 5.0, "La barra XP deve reagire alla progressione.")
	_expect(hud.get_experience_text() == "5 / 10 XP", "Il testo XP deve mostrare il progresso.")

	var paused_time := controller.get_run_time()
	var paused_text := hud.get_time_text()
	_expect(controller.request_manual_pause(), "La fixture HUD deve entrare in pausa.")
	_expect(hud.get_pause_button().disabled, "PAUSA deve disabilitarsi in MANUAL_PAUSE.")
	controller._process(100.0)
	_expect_float_near(
		controller.get_run_time(),
		paused_time,
		"Il clock autorevole deve fermarsi fuori da RUNNING."
	)
	_expect(hud.get_time_text() == paused_text, "L'HUD non deve avanzare un clock locale in pausa.")
	_expect(controller.resume_run(), "La fixture HUD deve riprendere la run.")
	controller._process(0.2)
	_expect(hud.get_time_text() == "01:03", "Il timer deve riprendere dallo stesso istante.")

	_expect(experience.add_experience(5), "La soglia esatta deve produrre il level-up.")
	_expect(hud.get_level_text() == "LV 2", "Il livello HUD deve aggiornarsi nello stesso evento.")
	_expect(hud.get_experience_text() == "0 / 15 XP", "La barra deve adottare la soglia successiva.")
	var level_up_text := hud.get_time_text()
	controller._process(10.0)
	_expect(hud.get_time_text() == level_up_text, "LEVEL_UP deve lasciare fermo il timer HUD.")
	_expect(experience.complete_level_up(), "La fixture deve chiudere il level-up.")
	controller._process(1.0)
	_expect(hud.get_time_text() == "01:04", "Il timer deve riprendere dopo LEVEL_UP.")

	_expect(controller.request_defeat(), "La fixture deve entrare nello stato terminale.")
	var terminal_text := hud.get_time_text()
	controller._process(10.0)
	_expect(hud.get_time_text() == terminal_text, "DEFEAT deve lasciare fermo il timer HUD.")
	_expect(controller.restart_run(9002), "Il terminale deve accettare il restart.")
	_expect(hud.get_time_text() == "00:00", "Il restart deve azzerare subito il timer HUD.")
	_expect(hud.get_level_text() == "LV 1", "Il restart deve azzerare il livello HUD.")
	_expect(hud.get_experience_text() == "0 / 10 XP", "Il restart deve azzerare la barra XP.")
	_expect(GameHud.format_run_time(-INF) == "00:00", "Il formatter deve difendersi da valori non finiti.")
	_expect(GameHud.format_run_time(3605.9) == "60:05", "Il formatter non deve riciclare i minuti.")

	controller.prepare_restart()
	paused = false
	fixture.queue_free()
	await process_frame


func _validate_responsive_layouts() -> void:
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
		root.add_child(safe_root)
		await _wait_processed_frame()

		var xp_rect := hud.get_experience_panel_rect()
		var top_band_rect := hud.get_top_band_rect()
		var health_rect := hud.get_health_panel_rect()
		var portrait_rect := hud.get_portrait_rect()
		var timer_rect := hud.get_timer_slot_rect()
		var pause_rect := hud.get_pause_button_rect()
		var ability_rect := hud.get_ability_panel_rect()
		var ability_button_rect := hud.get_active_ability_button_rect()
		var expected_content := Rect2(
			safe_rect.position + Vector2(12.0, 10.0),
			safe_rect.size - Vector2(24.0, 22.0)
		)
		var profile_name := String(profile.name)
		_expect_rect_inside(xp_rect, safe_rect, "%s: la barra XP deve restare nella safe area." % profile_name)
		_expect_rect_inside(health_rect, safe_rect, "%s: la vita deve restare nella safe area." % profile_name)
		_expect_rect_inside(portrait_rect, safe_rect, "%s: il ritratto deve restare nella safe area." % profile_name)
		_expect_rect_inside(timer_rect, safe_rect, "%s: il timer deve restare nella safe area." % profile_name)
		_expect_rect_inside(pause_rect, safe_rect, "%s: PAUSA deve restare nella safe area." % profile_name)
		_expect_rect_inside(ability_rect, safe_rect, "%s: l'abilita deve restare nella safe area." % profile_name)
		_expect_rect_inside(ability_button_rect, safe_rect, "%s: il touch abilita deve restare nella safe area." % profile_name)
		_expect_float_near(
			xp_rect.position.x,
			expected_content.position.x,
			"%s: la barra XP deve partire dal margine sicuro." % profile_name,
			LAYOUT_TOLERANCE
		)
		_expect_float_near(
			xp_rect.size.x,
			expected_content.size.x,
			"%s: la barra XP deve occupare tutta la larghezza utile." % profile_name,
			LAYOUT_TOLERANCE
		)
		_expect_float_near(
			timer_rect.get_center().x,
			safe_rect.get_center().x,
			"%s: il timer deve restare centrato." % profile_name,
			LAYOUT_TOLERANCE
		)
		_expect_float_near(
			top_band_rect.size.y,
			64.0,
			"%s: la fascia HUD deve restare compatta." % profile_name,
			LAYOUT_TOLERANCE
		)
		_expect(
			top_band_rect.end.y <= xp_rect.position.y + LAYOUT_TOLERANCE,
			"%s: la linea XP deve seguire la fascia senza sovrapporla." % profile_name
		)
		_expect(
			xp_rect.size.y >= 6.0 - LAYOUT_TOLERANCE
			and xp_rect.size.y <= 8.0 + LAYOUT_TOLERANCE,
			"%s: la linea XP deve essere alta 6-8 unita logiche." % profile_name
		)
		_expect(
			health_rect.size.x >= 244.0 - LAYOUT_TOLERANCE,
			"%s: la barra vita deve conservare una larghezza leggibile." % profile_name
		)
		_expect(
			pause_rect.size.x >= 44.0 - LAYOUT_TOLERANCE
			and pause_rect.size.y >= 44.0 - LAYOUT_TOLERANCE,
			"%s: PAUSA deve conservare un target touch leggibile." % profile_name
		)
		_expect(
			ability_button_rect.size.x >= 64.0 - LAYOUT_TOLERANCE
			and ability_button_rect.size.y >= 64.0 - LAYOUT_TOLERANCE,
			"%s: ATTIVA deve conservare un target touch leggibile." % profile_name
		)
		_expect(
			ability_rect.position.distance_to(ability_button_rect.position) <= LAYOUT_TOLERANCE
			and ability_rect.size.distance_to(ability_button_rect.size) <= LAYOUT_TOLERANCE,
			"%s: B18K deve lasciare soltanto l'icona senza card esterna." % profile_name
		)
		_expect(
			timer_rect.end.x <= pause_rect.position.x + LAYOUT_TOLERANCE,
			"%s: timer e PAUSA non devono sovrapporsi." % profile_name
		)

		safe_root.queue_free()
		await process_frame


func _validate_composed_hud() -> void:
	root.content_scale_size = INITIAL_VIEWPORT_SIZE
	root.size = INITIAL_VIEWPORT_SIZE
	await _wait_processed_frame()
	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	root.add_child(movement_slice)
	await _wait_processed_frame()

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

	_expect(controller != null, "La scena B09 deve contenere RunController.")
	_expect(arena != null, "La scena B09 deve contenere ArenaLayout.")
	_expect(player != null, "La scena B09 deve contenere Player.")
	_expect(experience != null, "La scena B09 deve contenere ExperienceSystem.")
	_expect(hud != null, "La scena B09 deve contenere il nuovo HUD.")
	_expect(safe_root != null, "La scena B09 deve contenere SafeAreaRoot.")
	if (
		controller == null
		or arena == null
		or player == null
		or experience == null
		or hud == null
		or safe_root == null
	):
		paused = false
		movement_slice.queue_free()
		await process_frame
		return

	controller.set_process(false)
	if spawner != null:
		spawner.set_process(false)
	player.set_physics_process(false)
	if weapon != null:
		weapon.set_process(false)

	_expect(hud.get_run_controller() == controller, "L'HUD composto deve osservare RunController.")
	_expect(hud.get_health_component() == player.get_health_component(), "L'HUD composto deve osservare la salute Player.")
	_expect(hud.get_experience_system() == experience, "L'HUD composto deve osservare ExperienceSystem.")
	_expect(hud.get_friend_definition() == player.get_friend_definition(), "L'HUD composto deve osservare il profilo Player.")
	_expect(hud.get_portrait_texture() != null, "L'HUD composto deve mostrare il ritratto Player.")
	_expect(hud.get_health_text() == "VITA  100 / 100", "La scena composta deve mostrare la vita iniziale.")
	_expect(hud.get_experience_text() == "0 / 10 XP", "La scena composta deve mostrare la soglia iniziale.")

	controller._process(4.2)
	_expect(hud.get_time_text() == "00:04", "La scena composta deve inoltrare il clock all'HUD.")
	_expect(player.take_contact_damage(20.0), "La scena composta deve applicare danno di prova.")
	_expect(hud.get_health_text() == "VITA  80 / 100", "La vita composta deve aggiornarsi senza polling.")
	_expect(experience.add_experience(3), "La scena composta deve accreditare XP di prova.")
	_expect(hud.get_experience_text() == "3 / 10 XP", "Gli XP composti devono aggiornarsi senza polling.")

	var safe_rect := arena.get_safe_area_rect()
	_expect_rect_near(
		safe_root.get_global_rect(),
		safe_rect,
		"SafeAreaRoot deve coincidere con la safe area di ArenaLayout."
	)
	_expect_rect_inside(
		hud.get_experience_panel_rect(),
		safe_rect,
		"La barra XP composta deve restare nella safe area."
	)

	controller.request_defeat()
	_expect(movement_slice.restart_run(9003), "Il restart composto deve essere disponibile.")
	_expect(hud.get_time_text() == "00:00", "Il restart composto deve azzerare il timer.")
	_expect(hud.get_health_text() == "VITA  100 / 100", "Il restart composto deve ripristinare la vita HUD.")
	_expect(hud.get_experience_text() == "0 / 10 XP", "Il restart composto deve ripristinare gli XP HUD.")

	controller.prepare_restart()
	paused = false
	movement_slice.queue_free()
	await process_frame


func _expect_rect_inside(rect: Rect2, bounds: Rect2, message: String) -> void:
	_expect(
		rect.position.x >= bounds.position.x - LAYOUT_TOLERANCE
		and rect.position.y >= bounds.position.y - LAYOUT_TOLERANCE
		and rect.end.x <= bounds.end.x + LAYOUT_TOLERANCE
		and rect.end.y <= bounds.end.y + LAYOUT_TOLERANCE,
		"%s Rect %s, bounds %s." % [message, rect, bounds]
	)


func _expect_rect_near(actual: Rect2, expected: Rect2, message: String) -> void:
	_expect(
		actual.position.distance_to(expected.position) <= LAYOUT_TOLERANCE
		and actual.size.distance_to(expected.size) <= LAYOUT_TOLERANCE,
		"%s Atteso %s, ottenuto %s." % [message, expected, actual]
	)


func _expect_float_near(
	actual: float,
	expected: float,
	message: String,
	tolerance: float = FLOAT_TOLERANCE
) -> void:
	_expect(
		absf(actual - expected) <= tolerance,
		"%s Atteso %s, ottenuto %s." % [message, expected, actual]
	)


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
		print("B09_HUD_SMOKE_OK")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	printerr("B09_HUD_SMOKE_FAIL count=%d" % _failures.size())
	quit(1)
