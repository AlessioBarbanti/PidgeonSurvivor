extends GutGameplayTest

const IDENTITY_FLOAT_TOLERANCE := 0.01

## Vita del nemico usato per osservare il feedback di combattimento, slegata
## dai dati di bilanciamento: serve un colpo non letale seguito da uno letale.
const FEEDBACK_FIXTURE_HEALTH := 200.0


func test_visual_identity_contract() -> void:
	var movement_slice := await instantiate_movement_slice()

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

	assert_not_null(controller, "B18B richiede RunController.")
	assert_not_null(player, "B18B richiede Player.")
	assert_not_null(spawner, "B18B richiede EnemySpawner.")
	assert_not_null(ability, "B18B richiede AbilityController.")
	assert_not_null(hud, "B18B richiede HUD.")
	assert_not_null(arena_view, "B18B richiede ArenaView.")
	assert_not_null(feedback, "B18B richiede CombatFeedback.")
	assert_not_null(joystick, "B18B richiede TouchJoystick.")
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

	_assert_compact_hud(hud, joystick)
	_assert_arena_identity(arena_view)
	_assert_joystick_contract(joystick)
	_assert_combat_feedback(controller, player, spawner, ability, hud, feedback)

	assert_true(controller.request_defeat(), "La fixture B18B deve raggiungere un terminale.")
	assert_true(movement_slice.restart_run(1819), "Il restart B18B deve riuscire.")
	assert_eq(
		feedback.get_active_effect_count(), 0, "Il restart deve rimuovere ogni feedback della run precedente."
	)


func _assert_compact_hud(hud: GameHud, joystick: TouchJoystick) -> void:
	var top_band := hud.get_top_band_rect()
	var xp_line := hud.get_experience_panel_rect()
	var pause_button := hud.get_pause_button_rect()
	var ability_panel := hud.get_ability_panel_rect()
	var ability_button := hud.get_active_ability_button_rect()
	assert_almost_eq(
		top_band.size.y, GameHud.GAMEPLAY_TOP_INSET, IDENTITY_FLOAT_TOLERANCE, "La fascia HUD deve riservare l'inset B18Q."
	)
	assert_almost_eq(xp_line.size.y, 18.0, IDENTITY_FLOAT_TOLERANCE, "La barra XP deve essere alta 18 unita.")
	assert_true(
		absf(top_band.position.y - xp_line.position.y) <= IDENTITY_FLOAT_TOLERANCE,
		"La barra XP deve aprire la fascia minimale."
	)
	assert_true(
		pause_button.size.x >= 44.0 and pause_button.size.y >= 44.0,
		"Pausa deve conservare un target touch di almeno 44 unita."
	)
	assert_true(
		ability_button.size.x >= 64.0 and ability_button.size.y >= 64.0,
		"L'abilita deve conservare il target touch 64 x 64 B18K."
	)
	assert_true(
		ability_panel.position.distance_to(ability_button.position) <= IDENTITY_FLOAT_TOLERANCE
		and ability_panel.size.distance_to(ability_button.size) <= IDENTITY_FLOAT_TOLERANCE,
		"B18K deve mostrare soltanto l'icona senza card esterna."
	)
	assert_null(hud.get_portrait_texture(), "B18Q deve rimuovere il ritratto dall'HUD.")
	var joystick_rect := joystick.get_global_rect()
	assert_false(
		joystick_rect.intersects(ability_panel, true), "Joystick e icona abilita devono restare separati."
	)


func _assert_arena_identity(arena_view: ArenaView) -> void:
	assert_false(arena_view.uses_debug_grid(), "L'arena non deve usare la griglia debug regolare.")
	if arena_view.has_raster_background():
		assert_false(
			arena_view.uses_procedural_fallback(), "Lo sfondo raster B18S deve sostituire le variazioni procedurali nel runtime."
		)
		return
	var features := arena_view.get_floor_feature_budget()
	assert_true(int(features.get("tonal_patches", 0)) >= 4, "Il pavimento richiede variazioni tonali.")
	assert_true(int(features.get("joints", 0)) >= 2, "Il pavimento richiede giunti irregolari.")
	assert_true(int(features.get("stains", 0)) >= 2, "Il pavimento richiede macchie leggere.")
	assert_true(int(features.get("cracks", 0)) >= 2, "Il pavimento richiede crepe leggere.")


func _assert_joystick_contract(joystick: TouchJoystick) -> void:
	assert_almost_eq(joystick.base_radius, 84.0, IDENTITY_FLOAT_TOLERANCE, "Il raggio input joystick non deve cambiare.")
	assert_almost_eq(
		joystick.get_visual_radius(), 68.0, IDENTITY_FLOAT_TOLERANCE, "Il raggio visivo joystick deve essere 68."
	)
	assert_true(
		joystick.dynamic_origin and joystick.get_acquisition_rect().size.x > 224.0,
		"B18L deve sostituire l'area fissa con una zona dinamica piu ampia."
	)
	assert_false(joystick.is_visual_visible(), "Il floating joystick deve essere invisibile al neutro.")
	assert_true(joystick.idle_opacity < 0.5, "Il joystick inattivo deve essere meno opaco.")
	var press := make_touch_event(31, true, joystick.size * 0.5 + Vector2.RIGHT * joystick.base_radius)
	joystick._gui_input(press)
	assert_true(
		joystick.movement_vector.distance_to(Vector2.RIGHT) <= IDENTITY_FLOAT_TOLERANCE,
		"Il bordo input storico deve ancora produrre intensita piena."
	)
	joystick.reset_input()


func _assert_combat_feedback(
	controller: RunController,
	player: Player,
	spawner: EnemySpawner,
	ability: AbilityController,
	hud: GameHud,
	feedback: CombatFeedback
) -> void:
	assert_true(controller.is_running(), "La fixture feedback deve essere in RUNNING.")
	var enemy := spawner.try_spawn_enemy()
	assert_not_null(enemy, "La fixture B18B deve creare un nemico.")
	if enemy == null:
		return
	enemy.set_physics_process(false)
	# Il colpo di prova deve essere non letale per poter osservare flash e
	# squash, e quello dopo deve uccidere: con gli HP dell'archetipo (uno
	# swarmer ne ha 9) i 10 danni erano gia' letali e la sequenza saltava.
	var enemy_health := enemy.get_health_component()
	if enemy_health != null:
		enemy_health.set_health_max(FEEDBACK_FIXTURE_HEALTH)
		enemy_health.heal(FEEDBACK_FIXTURE_HEALTH)
	var hit_count_before := feedback.get_spawn_count(CombatFeedback.HIT_SPARK)
	assert_true(enemy.take_damage(10.0), "Il colpo B18B deve applicare danno.")
	assert_true(
		enemy.get_damage_flash_remaining() > 0.0 and enemy.get_damage_flash_remaining() <= 0.08 + IDENTITY_FLOAT_TOLERANCE,
		"Il flash nemico deve durare 0,06-0,08 secondi."
	)
	assert_true(enemy.get_hit_reaction_remaining() > 0.0, "Il colpo deve avviare la reazione squash.")
	assert_false(
		enemy.get_visual_hit_scale().is_equal_approx(Vector2.ONE),
		"La reazione visiva non deve modificare il transform gameplay."
	)
	assert_eq(
		feedback.get_spawn_count(CombatFeedback.HIT_SPARK), hit_count_before + 1, "Ogni danno nemico deve creare un solo hit spark."
	)
	var death_count_before := feedback.get_spawn_count(CombatFeedback.DEATH_BURST)
	assert_true(enemy.take_damage(1000.0), "La hit letale B18B deve essere accettata.")
	assert_eq(
		feedback.get_spawn_count(CombatFeedback.DEATH_BURST), death_count_before + 1, "La morte deve creare un solo pop con particelle."
	)

	var player_feedback_before := feedback.get_spawn_count(CombatFeedback.PLAYER_DAMAGE)
	var hud_feedback_before := hud.get_health_feedback_count()
	assert_true(player.take_contact_damage(5.0), "Il danno Player B18B deve essere accettato.")
	assert_true(
		player.get_damage_flash_remaining() > 0.0 and player.get_damage_flash_remaining() <= 0.08 + IDENTITY_FLOAT_TOLERANCE,
		"Il flash Player deve durare 0,06-0,08 secondi."
	)
	assert_true(player.get_damage_reaction_remaining() > 0.0, "Il Player deve reagire al colpo.")
	assert_eq(
		feedback.get_spawn_count(CombatFeedback.PLAYER_DAMAGE), player_feedback_before + 1, "Il danno Player deve creare un impulso mondo."
	)
	assert_eq(
		hud.get_health_feedback_count(), hud_feedback_before + 1, "Il danno Player deve creare un impulso HUD."
	)

	var ready_pulses_before := hud.get_ability_ready_pulse_count()
	assert_true(ability.try_activate(), "L'abilita B18B deve attivarsi dalla fixture.")
	ability._process(ability.get_cooldown_total())
	assert_true(ability.is_cooldown_ready(), "Il cooldown della fixture deve terminare.")
	assert_eq(
		hud.get_ability_ready_pulse_count(), ready_pulses_before + 1, "Il ritorno a PRONTA deve creare un solo impulso HUD."
	)
