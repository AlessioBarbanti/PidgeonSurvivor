extends SceneTree

const MOVEMENT_SLICE_SCENE := preload("res://scenes/game/movement_slice.tscn")
const INITIAL_VIEWPORT_SIZE := Vector2i(1280, 720)
const FLOAT_TOLERANCE := 0.01

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.content_scale_size = INITIAL_VIEWPORT_SIZE
	root.size = INITIAL_VIEWPORT_SIZE
	await _wait_processed_frame()

	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	root.add_child(movement_slice)
	await _wait_processed_frame()

	var controller := movement_slice.get_run_controller() as RunController
	var player := movement_slice.get_player() as Player
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	var weapon := movement_slice.get_weapon_controller() as WeaponController
	var ability := movement_slice.get_ability_controller() as AbilityController
	var hud := movement_slice.get_hud() as GameHud
	var arena_view := movement_slice.get_arena_view() as ArenaView
	var feedback := movement_slice.get_combat_feedback() as CombatFeedback
	var audio := movement_slice.get_game_audio() as GameAudio
	var joystick := movement_slice.get_node_or_null("UI/SafeAreaRoot/TouchJoystick") as TouchJoystick
	var boss_ui := movement_slice.get_boss_ui() as BossUI

	_expect(controller != null, "B18B richiede RunController.")
	_expect(player != null, "B18B richiede Player.")
	_expect(spawner != null, "B18B richiede EnemySpawner.")
	_expect(ability != null, "B18B richiede AbilityController.")
	_expect(hud != null, "B18B richiede HUD.")
	_expect(arena_view != null, "B18B richiede ArenaView.")
	_expect(feedback != null, "B18B richiede CombatFeedback.")
	_expect(joystick != null, "B18B richiede TouchJoystick.")
	if (
		controller == null
		or player == null
		or spawner == null
		or ability == null
		or hud == null
		or arena_view == null
		or feedback == null
		or joystick == null
	):
		await _finish(movement_slice, controller)
		return

	controller.set_process(false)
	spawner.set_process(false)
	player.set_physics_process(false)
	ability.set_process(false)
	if weapon != null:
		weapon.set_process(false)
	if audio != null:
		audio.stop_all()
		audio.set_muted(true, false)

	_validate_compact_hud(hud, joystick, boss_ui)
	_validate_arena_identity(arena_view)
	_validate_joystick_contract(joystick)
	_validate_combat_feedback(controller, player, spawner, ability, hud, feedback)

	_expect(controller.request_defeat(), "La fixture B18B deve raggiungere un terminale.")
	_expect(movement_slice.restart_run(1819), "Il restart B18B deve riuscire.")
	_expect(
		feedback.get_active_effect_count() == 0,
		"Il restart deve rimuovere ogni feedback della run precedente."
	)

	await _finish(movement_slice, controller)


func _validate_compact_hud(
	hud: GameHud,
	joystick: TouchJoystick,
	boss_ui: BossUI
) -> void:
	var top_band := hud.get_top_band_rect()
	var xp_line := hud.get_experience_panel_rect()
	var pause_button := hud.get_pause_button_rect()
	var ability_panel := hud.get_ability_panel_rect()
	var ability_button := hud.get_active_ability_button_rect()
	_expect_float_near(top_band.size.y, GameHud.GAMEPLAY_TOP_INSET, "La fascia HUD deve riservare l'inset B18Q.")
	_expect_float_near(xp_line.size.y, 18.0, "La barra XP deve essere alta 18 unita.")
	_expect(
		absf(top_band.position.y - xp_line.position.y) <= FLOAT_TOLERANCE,
		"La barra XP deve aprire la fascia minimale."
	)
	_expect(
		pause_button.size.x >= 44.0 and pause_button.size.y >= 44.0,
		"Pausa deve conservare un target touch di almeno 44 unita."
	)
	_expect(
		ability_button.size.x >= 64.0 and ability_button.size.y >= 64.0,
		"L'abilita deve conservare il target touch 64 x 64 B18K."
	)
	_expect(
		ability_panel.position.distance_to(ability_button.position) <= FLOAT_TOLERANCE
		and ability_panel.size.distance_to(ability_button.size) <= FLOAT_TOLERANCE,
		"B18K deve mostrare soltanto l'icona senza card esterna."
	)
	_expect(hud.get_portrait_texture() == null, "B18Q deve rimuovere il ritratto dall'HUD.")
	var joystick_rect := joystick.get_global_rect()
	_expect(
		not joystick_rect.intersects(ability_panel, true),
		"Joystick e icona abilita devono restare separati."
	)
	if boss_ui != null:
		var boss_rect := boss_ui.get_boss_health_panel_rect()
		_expect(
			not boss_rect.has_area() or top_band.end.y <= boss_rect.position.y,
			"Boss UI e fascia HUD non devono sovrapporsi."
		)


func _validate_arena_identity(arena_view: ArenaView) -> void:
	_expect(not arena_view.uses_debug_grid(), "L'arena non deve usare la griglia debug regolare.")
	if arena_view.has_raster_background():
		_expect(
			not arena_view.uses_procedural_fallback(),
			"Lo sfondo raster B18S deve sostituire le variazioni procedurali nel runtime."
		)
		return
	var features := arena_view.get_floor_feature_budget()
	_expect(int(features.get("tonal_patches", 0)) >= 4, "Il pavimento richiede variazioni tonali.")
	_expect(int(features.get("joints", 0)) >= 2, "Il pavimento richiede giunti irregolari.")
	_expect(int(features.get("stains", 0)) >= 2, "Il pavimento richiede macchie leggere.")
	_expect(int(features.get("cracks", 0)) >= 2, "Il pavimento richiede crepe leggere.")


func _validate_joystick_contract(joystick: TouchJoystick) -> void:
	_expect_float_near(joystick.base_radius, 84.0, "Il raggio input joystick non deve cambiare.")
	_expect_float_near(joystick.get_visual_radius(), 68.0, "Il raggio visivo joystick deve essere 68.")
	_expect(
		joystick.dynamic_origin and joystick.get_acquisition_rect().size.x > 224.0,
		"B18L deve sostituire l'area fissa con una zona dinamica piu ampia."
	)
	_expect(not joystick.is_visual_visible(), "Il floating joystick deve essere invisibile al neutro.")
	_expect(joystick.idle_opacity < 0.5, "Il joystick inattivo deve essere meno opaco.")
	var press := InputEventScreenTouch.new()
	press.index = 31
	press.position = joystick.size * 0.5 + Vector2.RIGHT * joystick.base_radius
	press.pressed = true
	joystick._gui_input(press)
	_expect(
		joystick.movement_vector.distance_to(Vector2.RIGHT) <= FLOAT_TOLERANCE,
		"Il bordo input storico deve ancora produrre intensita piena."
	)
	joystick.reset_input()


func _validate_combat_feedback(
	controller: RunController,
	player: Player,
	spawner: EnemySpawner,
	ability: AbilityController,
	hud: GameHud,
	feedback: CombatFeedback
) -> void:
	_expect(controller.is_running(), "La fixture feedback deve essere in RUNNING.")
	var enemy := spawner.try_spawn_enemy()
	_expect(enemy != null, "La fixture B18B deve creare un nemico.")
	if enemy == null:
		return
	enemy.set_physics_process(false)
	var hit_count_before := feedback.get_spawn_count(CombatFeedback.HIT_SPARK)
	_expect(enemy.take_damage(10.0), "Il colpo B18B deve applicare danno.")
	_expect(
		enemy.get_damage_flash_remaining() > 0.0
		and enemy.get_damage_flash_remaining() <= 0.08 + FLOAT_TOLERANCE,
		"Il flash nemico deve durare 0,06-0,08 secondi."
	)
	_expect(enemy.get_hit_reaction_remaining() > 0.0, "Il colpo deve avviare la reazione squash.")
	_expect(
		not enemy.get_visual_hit_scale().is_equal_approx(Vector2.ONE),
		"La reazione visiva non deve modificare il transform gameplay."
	)
	_expect(
		feedback.get_spawn_count(CombatFeedback.HIT_SPARK) == hit_count_before + 1,
		"Ogni danno nemico deve creare un solo hit spark."
	)
	var death_count_before := feedback.get_spawn_count(CombatFeedback.DEATH_BURST)
	_expect(enemy.take_damage(1000.0), "La hit letale B18B deve essere accettata.")
	_expect(
		feedback.get_spawn_count(CombatFeedback.DEATH_BURST) == death_count_before + 1,
		"La morte deve creare un solo pop con particelle."
	)

	var player_feedback_before := feedback.get_spawn_count(CombatFeedback.PLAYER_DAMAGE)
	var hud_feedback_before := hud.get_health_feedback_count()
	_expect(player.take_contact_damage(5.0), "Il danno Player B18B deve essere accettato.")
	_expect(
		player.get_damage_flash_remaining() > 0.0
		and player.get_damage_flash_remaining() <= 0.08 + FLOAT_TOLERANCE,
		"Il flash Player deve durare 0,06-0,08 secondi."
	)
	_expect(player.get_damage_reaction_remaining() > 0.0, "Il Player deve reagire al colpo.")
	_expect(
		feedback.get_spawn_count(CombatFeedback.PLAYER_DAMAGE) == player_feedback_before + 1,
		"Il danno Player deve creare un impulso mondo."
	)
	_expect(
		hud.get_health_feedback_count() == hud_feedback_before + 1,
		"Il danno Player deve creare un impulso HUD."
	)

	var ready_pulses_before := hud.get_ability_ready_pulse_count()
	_expect(ability.try_activate(), "L'abilita B18B deve attivarsi dalla fixture.")
	ability._process(ability.get_cooldown_total())
	_expect(ability.is_cooldown_ready(), "Il cooldown della fixture deve terminare.")
	_expect(
		hud.get_ability_ready_pulse_count() == ready_pulses_before + 1,
		"Il ritorno a PRONTA deve creare un solo impulso HUD."
	)


func _wait_processed_frame() -> void:
	await process_frame
	await process_frame


func _expect_float_near(actual: float, expected: float, message: String) -> void:
	_expect(absf(actual - expected) <= FLOAT_TOLERANCE, "%s Atteso %s, ottenuto %s." % [message, expected, actual])


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish(movement_slice: Control, controller: RunController) -> void:
	if controller != null:
		controller.prepare_restart()
	paused = false
	if is_instance_valid(movement_slice):
		var audio := movement_slice.get_game_audio() as GameAudio
		if audio != null:
			audio.stop_all()
			await process_frame
		movement_slice.queue_free()
	await process_frame
	await process_frame
	if _failures.is_empty():
		print("B18B_VISUAL_IDENTITY_SMOKE_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	printerr("B18B_VISUAL_IDENTITY_SMOKE_FAIL count=%d" % _failures.size())
	quit(1)
