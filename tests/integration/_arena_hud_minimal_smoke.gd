extends SceneTree

const MOVEMENT_SLICE_SCENE := preload("res://scenes/game/movement_slice.tscn")
const LAYOUT_PROFILES: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1440, 720),
	Vector2i(1600, 720),
	Vector2i(960, 720),
]
const FLOAT_TOLERANCE := 1.0

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	paused = false
	root.content_scale_size = LAYOUT_PROFILES[0]
	root.size = LAYOUT_PROFILES[0]
	await _wait_processed_frame()

	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	root.add_child(movement_slice)
	await _wait_processed_frame()

	var controller := movement_slice.get_run_controller() as RunController
	var arena := movement_slice.get_node_or_null("ArenaLayout") as ArenaLayout
	var hud := movement_slice.get_hud() as GameHud
	var player := movement_slice.get_player() as Player
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	var dropper := movement_slice.get_experience_dropper() as ExperienceDropper
	var encounter := movement_slice.get_boss_encounter() as BossEncounter
	var weapon := movement_slice.get_weapon_controller() as WeaponController
	var ability := movement_slice.get_ability_controller() as AbilityController
	var arena_world := movement_slice.get_arena_world() as ArenaWorld

	_expect(controller != null and arena != null and hud != null, "B18Q richiede controller, ArenaLayout e HUD.")
	_expect(player != null and spawner != null and dropper != null, "B18Q richiede Player, spawn e drop XP composti.")
	_expect(encounter != null, "B18Q richiede il consumatore Boss composto.")
	_expect(arena_world != null, "B18Q richiede ArenaWorld composto.")
	if (
		controller == null
		or arena == null
		or hud == null
		or player == null
		or spawner == null
		or dropper == null
		or encounter == null
		or arena_world == null
	):
		await _finish(movement_slice, controller)
		return

	controller.set_process(false)
	spawner.set_process(false)
	player.set_physics_process(false)
	if weapon != null:
		weapon.set_process(false)
	if ability != null:
		ability.set_process(false)

	var camera := movement_slice.get_camera() as Camera2D
	_expect(camera != null, "B52 richiede la Camera2D composta.")

	_validate_minimal_nodes(hud)
	await _validate_layout_profiles(arena, hud, player, spawner, dropper, encounter, arena_world)
	if camera != null:
		await _validate_hud_ability_exclusion(hud, player, camera, arena_world)
	_validate_authoritative_clock(controller, hud)
	await _finish(movement_slice, controller)


func _validate_minimal_nodes(hud: GameHud) -> void:
	for removed_node_name in ["Portrait", "PortraitFrame", "LevelLabel", "ExperienceLabel", "HealthLabel", "Caption", "TimerPanel"]:
		_expect(
			hud.find_child(removed_node_name, true, false) == null,
			"B18Q deve rimuovere il nodo legacy %s." % removed_node_name
		)
	_expect(hud.get_health_text().is_empty(), "B18Q non deve esporre testo vita.")
	_expect(hud.get_experience_text().is_empty(), "B18Q non deve esporre testo XP.")
	_expect(hud.get_level_text().is_empty(), "B18Q non deve esporre il livello.")
	_expect(hud.get_experience_kind_text() == "XP", "La barra esperienza deve mostrare il tag fisso XP.")
	_expect(hud.get_health_kind_text() == "HP", "La barra vita deve mostrare il tag fisso HP.")
	var time_label := hud.find_child("TimeLabel", true, false) as Label
	_expect(time_label != null and time_label.get_theme_font_size("font_size") > 23, "Il cronometro B18Q deve essere leggermente ingrandito.")


func _validate_layout_profiles(
	arena: ArenaLayout,
	hud: GameHud,
	player: Player,
	spawner: EnemySpawner,
	dropper: ExperienceDropper,
	encounter: BossEncounter,
	arena_world: ArenaWorld
) -> void:
	for profile in LAYOUT_PROFILES:
		root.content_scale_size = profile
		root.size = profile
		await _wait_processed_frame()
		arena.refresh_layout()
		await _wait_processed_frame()

		var context := "%dx%d" % [profile.x, profile.y]
		var safe_area := arena.get_safe_area_rect()
		var playfield := arena.get_playfield_rect()
		var expected_playfield := ArenaLayout.calculate_playfield_rect(
			safe_area,
			arena.target_aspect_ratio,
			hud.get_gameplay_top_inset()
		)
		var top_band := hud.get_top_band_rect()
		var xp_bar := hud.get_experience_panel_rect()
		var health_bar := hud.get_health_panel_rect()
		var timer := hud.get_timer_slot_rect()
		var pause_button := hud.get_pause_button_rect()

		_expect_rect_near(playfield, expected_playfield, "%s: il playfield deve derivare dalla safe area meno l'HUD." % context)
		_expect_float_near(arena.get_top_reserved_height(), hud.get_gameplay_top_inset(), "%s: ArenaLayout e HUD devono condividere lo stesso inset." % context)
		_expect_float_near(xp_bar.position.x, safe_area.position.x, "%s: XP deve partire dal bordo safe." % context)
		_expect_float_near(xp_bar.size.x, safe_area.size.x, "%s: XP deve essere full-width." % context)
		_expect_float_near(health_bar.position.x, safe_area.position.x, "%s: vita deve partire dal bordo safe." % context)
		_expect_float_near(health_bar.size.x, safe_area.size.x, "%s: vita deve essere full-width." % context)
		_expect_float_near(health_bar.position.y, xp_bar.end.y, "%s: vita deve seguire immediatamente XP." % context)
		_expect_float_near(xp_bar.size.y, 18.0, "%s: la barra XP deve essere piu corposa." % context)
		_expect_float_near(health_bar.size.y, 20.0, "%s: la barra HP deve essere piu corposa." % context)
		_expect_float_near(timer.get_center().x, safe_area.get_center().x, "%s: il cronometro deve essere centrato." % context)
		_expect(timer.position.y >= health_bar.end.y, "%s: il cronometro deve stare sotto le barre." % context)
		_expect(pause_button.size.x >= 44.0 and pause_button.size.y >= 44.0, "%s: pausa deve conservare il target touch." % context)
		_expect_float_near(xp_bar.size.x, health_bar.size.x, "%s: pausa non deve ridurre le barre." % context)
		_expect(top_band.encloses(xp_bar) and top_band.encloses(health_bar) and top_band.encloses(timer) and top_band.encloses(pause_button), "%s: la fascia dichiarata deve includere tutta la UI superiore." % context)
		_expect(playfield.position.y >= top_band.end.y - FLOAT_TOLERANCE, "%s: nessun punto del playfield deve stare dietro l'HUD." % context)

		var radius := player.collision_radius
		for point in [
			playfield.get_center(),
			playfield.position - Vector2.ONE * 400.0,
			Vector2(playfield.end.x + 400.0, playfield.position.y - 400.0),
			playfield.end + Vector2.ONE * 400.0,
			Vector2(playfield.position.x - 400.0, playfield.end.y + 400.0),
		]:
			var clamped := arena.clamp_circle_center(point, radius)
			_expect_circle_inside(clamped, radius, playfield, "%s: centro/lati/angoli devono usare il playfield." % context)

		_expect_rect_near(arena.get_spawn_inner_rect(48.0), playfield.grow(48.0), "%s: l'ingresso deve derivare dal playfield." % context)
		_expect_rect_near(arena.get_spawn_outer_rect(48.0, 112.0), playfield.grow(112.0), "%s: l'anello spawn deve derivare dal playfield." % context)
		_expect_rect_near(arena.get_despawn_rect(180.0), playfield.grow(180.0), "%s: il despawn deve derivare dal playfield." % context)

		var boss_position := BossEncounter.calculate_spawn_position(playfield, playfield.position, encounter.boss_definition.collision_radius)
		_expect_circle_inside(boss_position, encounter.boss_definition.collision_radius, playfield, "%s: il Boss deve entrare nel playfield utile." % context)

		spawner.clear_spawned_enemies()
		var enemy := spawner.try_spawn_enemy()
		_expect(enemy != null, "%s: lo spawner deve produrre una fixture." % context)
		if enemy != null:
			enemy.set_physics_process(false)
			# Da B38 lo spawner campiona attorno alla vista corrente della
			# camera, non piu' dal playfield ritagliato sul viewport.
			_expect(
				not EnemySpawner.is_point_in_rect_inclusive(
					spawner.get_visible_reference_rect(), enemy.global_position
				),
				"%s: lo spawn deve partire fuori dalla vista corrente della camera." % context
			)
			enemy.global_position = Vector2(safe_area.get_center().x, safe_area.position.y)
			# Fixture geometrica: il valore XP frazionario B28 non deve nascondere
			# il pickup usato per verificare il clamp nell'arena.
			enemy.experience_reward_scale = 1.0
			var pickup := dropper.try_spawn_drop(enemy)
			_expect(pickup != null, "%s: il drop XP deve essere creato." % context)
			if pickup != null:
				pickup.set_physics_process(false)
				# Da B38 i pickup restano confinati nel mondo fisso di
				# ArenaWorld, non piu' nel playfield ritagliato sull'HUD.
				_expect_circle_inside(
					pickup.global_position,
					pickup.get_confinement_radius(),
					arena_world.get_world_rect(),
					"%s: il pickup non deve finire fuori dall'arena." % context
				)
			dropper.clear_active_pickups()
		spawner.clear_spawned_enemies()


## B52: il Player non deve poter finire sotto l'icona dell'abilita' quando
## raggiunge il limite inferiore destro della mappa, su piu' profili di
## viewport.
func _validate_hud_ability_exclusion(
	hud: GameHud,
	player: Player,
	camera: Camera2D,
	arena_world: ArenaWorld
) -> void:
	for profile in LAYOUT_PROFILES:
		root.content_scale_size = profile
		root.size = profile
		await _wait_processed_frame()

		var context := "%dx%d" % [profile.x, profile.y]
		var button_rect := hud.get_active_ability_button_rect()
		_expect(button_rect.has_area(), "%s: B52 richiede un controllo abilita' con ingombro." % context)
		if not button_rect.has_area():
			continue

		var world_rect := arena_world.get_world_rect()
		var default_radius := player.collision_radius
		# Il margine dichiarato fra il controllo e il vero angolo schermo
		# (hud_control_edge_padding + gesture_navigation_padding + safe area)
		# e' generoso col raggio di default: per esercitare davvero la spinta
		# di B52 anziche' verificare un caso gia' innocuo, la fixture usa un
		# raggio grande quanto il controllo stesso, cosi' il solo clamp sul
		# mondo lo farebbe atterrare dentro l'icona senza l'esclusione HUD.
		var radius := maxf(button_rect.size.x, button_rect.size.y)
		player.collision_radius = radius
		player.global_position = world_rect.end - Vector2.ONE * radius
		camera.reset_smoothing()
		await _wait_processed_frame()
		# Rientra nel confinamento: il setter e' pubblico e riapplica il
		# clamp (compreso B52) con la posizione/camera aggiornate.
		player.set_hud_exclusion(camera, hud.get_active_ability_button())

		var reserved_rect := player.get_hud_exclusion_world_rect()
		_expect(
			reserved_rect.has_area() and reserved_rect.size.distance_to(button_rect.size) <= FLOAT_TOLERANCE,
			"%s: il rettangolo riservato deve corrispondere all'ingombro del controllo." % context
		)
		_expect_circle_inside(player.global_position, radius, world_rect, "%s: l'esclusione HUD non deve espellere il Player dal mondo." % context)
		_expect(
			ArenaWorld.push_circle_outside_rect(player.global_position, radius, reserved_rect) == player.global_position,
			"%s: dopo il confinamento il Player non deve piu' sovrapporsi al rettangolo riservato." % context
		)

		# Proiezione a schermo indipendente: il centro del Player, vicino alla
		# camera clampata nell'angolo, non deve cadere dentro l'ingombro reale
		# del controllo (verifica visiva, non solo geometria di mondo).
		var viewport_rect := player.get_viewport().get_visible_rect()
		var viewport_origin_world := camera.get_screen_center_position() - viewport_rect.size * 0.5
		var projected_screen_position := (
			player.global_position - viewport_origin_world + viewport_rect.position
		)
		_expect(
			not button_rect.grow(-1.0).has_point(projected_screen_position),
			"%s: la proiezione a schermo del Player non deve cadere sotto l'icona abilita'." % context
		)
		player.collision_radius = default_radius

	root.content_scale_size = LAYOUT_PROFILES[0]
	root.size = LAYOUT_PROFILES[0]
	await _wait_processed_frame()


func _validate_authoritative_clock(controller: RunController, hud: GameHud) -> void:
	_expect(controller.is_running(), "La fixture B18Q deve partire in RUNNING.")
	controller._process(1.2)
	var running_text := hud.get_time_text()
	_expect(controller.request_manual_pause(), "B18Q deve poter entrare in pausa.")
	controller._process(20.0)
	_expect(hud.get_time_text() == running_text, "Il cronometro deve fermarsi fuori da RUNNING.")
	_expect(controller.resume_run(), "B18Q deve poter riprendere la run.")
	controller._process(1.0)
	_expect(hud.get_time_text() != running_text, "Il cronometro deve riprendere dal clock autorevole.")


func _expect_circle_inside(center: Vector2, radius: float, bounds: Rect2, message: String) -> void:
	_expect(
		center.x - radius >= bounds.position.x - FLOAT_TOLERANCE
		and center.y - radius >= bounds.position.y - FLOAT_TOLERANCE
		and center.x + radius <= bounds.end.x + FLOAT_TOLERANCE
		and center.y + radius <= bounds.end.y + FLOAT_TOLERANCE,
		"%s Centro %s, raggio %.2f, bounds %s." % [message, center, radius, bounds]
	)


func _expect_rect_near(actual: Rect2, expected: Rect2, message: String) -> void:
	_expect(
		actual.position.distance_to(expected.position) <= FLOAT_TOLERANCE
		and actual.size.distance_to(expected.size) <= FLOAT_TOLERANCE,
		"%s Atteso %s, ottenuto %s." % [message, expected, actual]
	)


func _expect_float_near(actual: float, expected: float, message: String) -> void:
	_expect(absf(actual - expected) <= FLOAT_TOLERANCE, "%s Atteso %.2f, ottenuto %.2f." % [message, expected, actual])


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _wait_processed_frame() -> void:
	await process_frame
	await process_frame


func _finish(movement_slice: Control, controller: RunController) -> void:
	if is_instance_valid(controller):
		controller.prepare_restart()
	paused = false
	if is_instance_valid(movement_slice):
		movement_slice.queue_free()
	await process_frame
	root.content_scale_size = LAYOUT_PROFILES[0]
	root.size = LAYOUT_PROFILES[0]
	if _failures.is_empty():
		print("B18Q_ARENA_HUD_MINIMAL_SMOKE_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	printerr("B18Q_ARENA_HUD_MINIMAL_SMOKE_FAIL count=%d" % _failures.size())
	quit(1)
