extends SceneTree

const MOVEMENT_SLICE_SCENE := preload("res://scenes/game/movement_slice.tscn")
const INITIAL_VIEWPORT_SIZE := Vector2i(1280, 720)
const FLOAT_TOLERANCE := 0.002

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	paused = false
	root.content_scale_size = INITIAL_VIEWPORT_SIZE
	root.size = INITIAL_VIEWPORT_SIZE
	_validate_central_contract()
	await _validate_composed_timing_and_cleanup()
	await _finish()


func _validate_central_contract() -> void:
	_expect(PresentationTimings.is_valid(), "I timing centralizzati B18R devono essere validi.")
	_expect(
		PresentationTimings.ABILITY_VFX_TAIL_SECONDS > 0.72,
		"Il burst principale deve superare la baseline B18M da 0,72 s."
	)
	_expect(
		PresentationTimings.PLAYER_DAMAGE_FLASH_SECONDS <= 0.08
		and PresentationTimings.ENEMY_DAMAGE_FLASH_SECONDS <= 0.08,
		"I flash di hit devono restare brevi."
	)
	_expect_float_near(
		PresentationTimings.one_shot_opacity(0.0, 1.2),
		0.0,
		"L'entrata deve partire trasparente."
	)
	_expect(
		PresentationTimings.one_shot_opacity(0.4, 1.2) > 0.99,
		"Il corpo del one-shot deve raggiungere piena leggibilita."
	)
	_expect_float_near(
		PresentationTimings.one_shot_opacity(1.2, 1.2),
		0.0,
		"La coda deve terminare trasparente."
	)


func _validate_composed_timing_and_cleanup() -> void:
	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	root.add_child(movement_slice)
	await _wait_processed_frame()

	var controller := movement_slice.get_run_controller() as RunController
	var registry := movement_slice.get_ability_effect_registry() as AbilityEffectRegistry
	var player := movement_slice.get_player() as Player
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	var feedback := movement_slice.get_combat_feedback() as CombatFeedback
	var hud := movement_slice.get_hud() as GameHud
	var ability := movement_slice.get_ability_controller() as AbilityController
	_expect(controller != null and controller.is_running(), "B18R richiede una run attiva.")
	_expect(registry != null, "B18R richiede AbilityEffectRegistry.")
	_expect(player != null and spawner != null, "B18R richiede attori composti.")
	_expect(feedback != null and hud != null, "B18R richiede feedback mondo e HUD.")
	if (
		controller == null
		or registry == null
		or player == null
		or spawner == null
		or feedback == null
		or hud == null
	):
		movement_slice.queue_free()
		await process_frame
		return

	controller.set_process(false)
	player.set_physics_process(false)
	spawner.set_process(false)
	if ability != null:
		ability.set_process(false)

	_validate_actor_and_feedback_timings(controller, player, spawner, feedback, hud)
	await _validate_non_interactive_ability_tail(controller, registry, player)
	await _validate_two_run_cleanup(controller, registry, player, feedback, hud)

	paused = false
	movement_slice.queue_free()
	await _wait_processed_frame()


func _validate_actor_and_feedback_timings(
	controller: RunController,
	player: Player,
	spawner: EnemySpawner,
	feedback: CombatFeedback,
	hud: GameHud
) -> void:
	_expect_float_near(
		player.damage_reaction_duration,
		PresentationTimings.PLAYER_DAMAGE_REACTION_SECONDS,
		"La reazione Player deve usare il timing centrale."
	)
	_expect_float_near(
		player.damage_flash_duration,
		PresentationTimings.PLAYER_DAMAGE_FLASH_SECONDS,
		"Il flash Player deve usare il timing breve centrale."
	)

	var enemy := spawner.try_spawn_enemy()
	_expect(enemy != null, "La fixture B18R deve creare un nemico.")
	if enemy != null:
		enemy.set_physics_process(false)
		enemy.set_process(false)
		_expect_float_near(
			enemy.hit_reaction_duration,
			PresentationTimings.ENEMY_HIT_REACTION_SECONDS,
			"La reazione nemico deve usare il timing centrale."
		)
		_expect(enemy.take_damage(10.0), "Il danno di prova al nemico deve riuscire.")
		_expect_float_near(
			enemy.get_hit_reaction_remaining(),
			PresentationTimings.ENEMY_HIT_REACTION_SECONDS,
			"La reazione nemico deve partire per intero."
		)
		_expect(
			enemy.get_damage_flash_remaining() <= 0.08 + FLOAT_TOLERANCE,
			"Il flash nemico non deve essere allungato."
		)
		var reaction_before_pause := enemy.get_hit_reaction_remaining()
		_expect(controller.request_manual_pause(), "La pausa deve aprirsi durante la reazione.")
		enemy._process(0.5)
		feedback._process(0.5)
		_expect_float_near(
			enemy.get_hit_reaction_remaining(),
			reaction_before_pause,
			"La reazione nemico deve congelarsi in pausa."
		)
		_expect(controller.resume_run(), "La run deve riprendere dopo la reazione congelata.")
		_expect(enemy.take_damage(1000.0), "La hit letale di prova deve riuscire.")

	_expect_float_near(
		feedback.get_active_effect_remaining(CombatFeedback.DEATH_BURST),
		PresentationTimings.DEATH_BURST_SECONDS,
		"La morte deve usare il burst leggibile centralizzato."
	)
	_expect(player.take_contact_damage(5.0), "Il danno Player di prova deve riuscire.")
	_expect_float_near(
		player.get_damage_reaction_remaining(),
		PresentationTimings.PLAYER_DAMAGE_REACTION_SECONDS,
		"La reazione Player deve partire per intero."
	)
	_expect_float_near(
		feedback.get_active_effect_remaining(CombatFeedback.PLAYER_DAMAGE),
		PresentationTimings.PLAYER_DAMAGE_BURST_SECONDS,
		"L'impulso mondo Player deve usare il timing centrale."
	)
	_expect_float_near(
		hud.get_health_feedback_remaining(),
		PresentationTimings.HUD_HEALTH_FEEDBACK_SECONDS,
		"L'impulso vita HUD deve usare il timing centrale."
	)
	hud._on_ability_readiness_changed(false)
	hud._on_ability_readiness_changed(true)
	_expect_float_near(
		hud.get_ability_ready_pulse_remaining(),
		PresentationTimings.ABILITY_READY_PULSE_SECONDS,
		"L'impulso di prontezza deve usare il timing centrale."
	)
	var hud_health_before_pause := hud.get_health_feedback_remaining()
	var hud_ready_before_pause := hud.get_ability_ready_pulse_remaining()
	_expect(controller.request_manual_pause(), "La pausa deve aprirsi durante gli impulsi HUD.")
	hud._process(0.4)
	_expect_float_near(
		hud.get_health_feedback_remaining(),
		hud_health_before_pause,
		"L'impulso vita HUD deve congelarsi in pausa."
	)
	_expect_float_near(
		hud.get_ability_ready_pulse_remaining(),
		hud_ready_before_pause,
		"L'impulso pronta deve congelarsi in pausa."
	)
	_expect(controller.resume_run(), "La run deve riprendere dopo gli impulsi HUD congelati.")


func _validate_non_interactive_ability_tail(
	controller: RunController,
	registry: AbilityEffectRegistry,
	player: Player
) -> void:
	registry.clear_active_effects()
	await process_frame
	var definition := registry.resolve_definition(&"magno_earthquake_shockwave")
	_expect(definition != null, "La fixture B18R richiede Onda d'Urto.")
	if definition == null:
		return
	_expect_float_near(definition.cooldown_seconds, 8.0, "B18R non deve cambiare il cooldown.")
	_expect_float_near(definition.duration_seconds, 0.0, "B18R non deve aggiungere durata gameplay.")
	_expect_float_near(definition.area_radius, 220.0, "B18R non deve cambiare il raggio.")
	_expect_float_near(definition.damage, 20.0, "B18R non deve cambiare il danno.")

	var effect := registry.execute_effect(definition, player) as EarthquakeWave
	var burst := registry.get_last_icon_burst()
	_expect(effect != null and burst == null, "Onda d'Urto deve usare il decal nel proprio effetto, senza icona HUD.")
	if effect == null:
		return
	effect.set_process(false)
	_expect_float_near(
		effect.get_duration_total(),
		PresentationTimings.ABILITY_VFX_TAIL_SECONDS,
		"Il decal tellurico deve usare la durata B18R."
	)
	_expect(effect.is_non_interactive_tail(), "La coda tellurica deve dichiararsi non interattiva.")
	_expect(
		effect.find_children("*", "CollisionObject2D", true, false).is_empty(),
		"Il decal tellurico non deve contenere collisioni."
	)
	var before_pause := effect.get_duration_remaining()
	_expect(controller.request_manual_pause(), "La pausa deve aprirsi durante il decal abilita.")
	effect._process(0.4)
	_expect_float_near(
		effect.get_duration_remaining(),
		before_pause,
		"Il decal abilita deve congelarsi in pausa."
	)
	_expect(controller.resume_run(), "La run deve riprendere dopo il decal congelato.")

	effect._process(0.4)
	await process_frame
	_expect(registry.get_active_effect_count() == 1, "Il decal tellurico deve restare leggibile dopo l'impatto istantaneo.")
	_expect(registry.get_active_visual_tail_count() == 0, "Il decal non deve creare una seconda coda-emblema.")
	effect._process(PresentationTimings.ABILITY_VFX_TAIL_SECONDS)
	await process_frame
	_expect(registry.get_active_effect_count() == 0, "Il decal deve ripulirsi alla fine visiva.")


func _validate_two_run_cleanup(
	controller: RunController,
	registry: AbilityEffectRegistry,
	player: Player,
	feedback: CombatFeedback,
	hud: GameHud
) -> void:
	var definition := registry.resolve_definition(&"magno_earthquake_shockwave")
	if definition == null:
		return
	_expect(registry.execute_effect(definition, player) != null, "La prima run deve creare un effetto.")
	_expect(registry.get_active_effect_count() == 1, "La prima run deve avere il decal attivo.")
	_expect(registry.get_active_visual_tail_count() == 0, "La prima run non deve creare un emblema separato.")
	_expect(controller.request_defeat(), "La prima run deve entrare nel terminale.")
	await process_frame
	_expect(
		registry.get_active_effect_count() == 0
		and registry.get_active_visual_tail_count() == 0,
		"Il terminale deve ripulire effetti e code abilita."
	)
	_expect(
		is_zero_approx(hud.get_health_feedback_remaining())
		and is_zero_approx(hud.get_ability_ready_pulse_remaining()),
		"Il terminale deve neutralizzare gli impulsi HUD."
	)
	_expect(controller.restart_run(18002), "La seconda run deve ripartire.")
	await process_frame
	_expect(feedback.get_active_effect_count() == 0, "La seconda run non deve ereditare feedback mondo.")
	_expect(registry.execute_effect(definition, player) != null, "La seconda run deve creare un nuovo effetto.")
	_expect(registry.get_active_effect_count() == 1, "La seconda run deve avere un solo nuovo decal.")
	_expect(registry.get_active_visual_tail_count() == 0, "La seconda run non deve avere code-emblema.")
	controller.prepare_restart()
	await process_frame
	_expect(
		registry.get_active_effect_count() == 0
		and registry.get_active_visual_tail_count() == 0,
		"Restart/cambio personaggio deve lasciare zero nodi residui."
	)


func _expect_float_near(actual: float, expected: float, message: String) -> void:
	_expect(
		absf(actual - expected) <= FLOAT_TOLERANCE,
		"%s Atteso %.3f, ottenuto %.3f." % [message, expected, actual]
	)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _wait_processed_frame() -> void:
	await process_frame
	await process_frame


func _finish() -> void:
	paused = false
	await process_frame
	if _failures.is_empty():
		print("B18R_VISUAL_TIMING_SMOKE_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	printerr("B18R_VISUAL_TIMING_SMOKE_FAIL count=%d" % _failures.size())
	quit(1)
