extends GutGameplayTest

const TIMING_FLOAT_TOLERANCE := 0.002


func test_central_contract() -> void:
	assert_true(PresentationTimings.is_valid(), "I timing centralizzati B18R devono essere validi.")
	assert_true(
		PresentationTimings.ABILITY_VFX_TAIL_SECONDS > 0.72,
		"Il burst principale deve superare la baseline B18M da 0,72 s."
	)
	assert_true(
		PresentationTimings.PLAYER_DAMAGE_FLASH_SECONDS <= 0.08
		and PresentationTimings.ENEMY_DAMAGE_FLASH_SECONDS <= 0.08,
		"I flash di hit devono restare brevi."
	)
	assert_almost_eq(
		PresentationTimings.one_shot_opacity(0.0, 1.2), 0.0, TIMING_FLOAT_TOLERANCE,
		"L'entrata deve partire trasparente."
	)
	assert_true(
		PresentationTimings.one_shot_opacity(0.4, 1.2) > 0.99,
		"Il corpo del one-shot deve raggiungere piena leggibilita."
	)
	assert_almost_eq(
		PresentationTimings.one_shot_opacity(1.2, 1.2), 0.0, TIMING_FLOAT_TOLERANCE,
		"La coda deve terminare trasparente."
	)


func test_composed_timing_and_cleanup() -> void:
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_run_controller() as RunController
	var registry := movement_slice.get_ability_effect_registry() as AbilityEffectRegistry
	var player := movement_slice.get_player() as Player
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	var feedback := movement_slice.get_combat_feedback() as CombatFeedback
	var hud := movement_slice.get_hud() as GameHud
	var ability := movement_slice.get_ability_controller() as AbilityController
	assert_true(controller != null and controller.is_running(), "B18R richiede una run attiva.")
	assert_not_null(registry, "B18R richiede AbilityEffectRegistry.")
	assert_true(player != null and spawner != null, "B18R richiede attori composti.")
	assert_true(feedback != null and hud != null, "B18R richiede feedback mondo e HUD.")
	if controller == null or registry == null or player == null or spawner == null or feedback == null or hud == null:
		return

	controller.set_process(false)
	player.set_physics_process(false)
	spawner.set_process(false)
	if ability != null:
		ability.set_process(false)

	_assert_actor_and_feedback_timings(controller, player, spawner, feedback, hud)
	await _assert_non_interactive_ability_tail(controller, registry, player)
	await _assert_two_run_cleanup(controller, registry, player, feedback, hud)


func _assert_actor_and_feedback_timings(
	controller: RunController, player: Player, spawner: EnemySpawner, feedback: CombatFeedback, hud: GameHud
) -> void:
	assert_almost_eq(
		player.damage_reaction_duration, PresentationTimings.PLAYER_DAMAGE_REACTION_SECONDS, TIMING_FLOAT_TOLERANCE,
		"La reazione Player deve usare il timing centrale."
	)
	assert_almost_eq(
		player.damage_flash_duration, PresentationTimings.PLAYER_DAMAGE_FLASH_SECONDS, TIMING_FLOAT_TOLERANCE,
		"Il flash Player deve usare il timing breve centrale."
	)

	var enemy := spawner.try_spawn_enemy()
	assert_not_null(enemy, "La fixture B18R deve creare un nemico.")
	if enemy != null:
		enemy.set_physics_process(false)
		enemy.set_process(false)
		assert_almost_eq(
			enemy.hit_reaction_duration, PresentationTimings.ENEMY_HIT_REACTION_SECONDS, TIMING_FLOAT_TOLERANCE,
			"La reazione nemico deve usare il timing centrale."
		)
		assert_true(enemy.take_damage(10.0), "Il danno di prova al nemico deve riuscire.")
		assert_almost_eq(
			enemy.get_hit_reaction_remaining(), PresentationTimings.ENEMY_HIT_REACTION_SECONDS, TIMING_FLOAT_TOLERANCE,
			"La reazione nemico deve partire per intero."
		)
		assert_true(
			enemy.get_damage_flash_remaining() <= 0.08 + TIMING_FLOAT_TOLERANCE,
			"Il flash nemico non deve essere allungato."
		)
		var reaction_before_pause := enemy.get_hit_reaction_remaining()
		assert_true(controller.request_manual_pause(), "La pausa deve aprirsi durante la reazione.")
		enemy._process(0.5)
		feedback._process(0.5)
		assert_almost_eq(
			enemy.get_hit_reaction_remaining(), reaction_before_pause, TIMING_FLOAT_TOLERANCE,
			"La reazione nemico deve congelarsi in pausa."
		)
		assert_true(controller.resume_run(), "La run deve riprendere dopo la reazione congelata.")
		assert_true(enemy.take_damage(1000.0), "La hit letale di prova deve riuscire.")

	assert_almost_eq(
		feedback.get_active_effect_remaining(CombatFeedback.DEATH_BURST), PresentationTimings.DEATH_BURST_SECONDS,
		TIMING_FLOAT_TOLERANCE, "La morte deve usare il burst leggibile centralizzato."
	)
	assert_true(player.take_contact_damage(5.0), "Il danno Player di prova deve riuscire.")
	assert_almost_eq(
		player.get_damage_reaction_remaining(), PresentationTimings.PLAYER_DAMAGE_REACTION_SECONDS,
		TIMING_FLOAT_TOLERANCE, "La reazione Player deve partire per intero."
	)
	assert_almost_eq(
		feedback.get_active_effect_remaining(CombatFeedback.PLAYER_DAMAGE),
		PresentationTimings.PLAYER_DAMAGE_BURST_SECONDS, TIMING_FLOAT_TOLERANCE,
		"L'impulso mondo Player deve usare il timing centrale."
	)
	assert_almost_eq(
		hud.get_health_feedback_remaining(), PresentationTimings.HUD_HEALTH_FEEDBACK_SECONDS, TIMING_FLOAT_TOLERANCE,
		"L'impulso vita HUD deve usare il timing centrale."
	)
	hud._on_ability_readiness_changed(false)
	hud._on_ability_readiness_changed(true)
	assert_almost_eq(
		hud.get_ability_ready_pulse_remaining(), PresentationTimings.ABILITY_READY_PULSE_SECONDS,
		TIMING_FLOAT_TOLERANCE, "L'impulso di prontezza deve usare il timing centrale."
	)
	var hud_health_before_pause := hud.get_health_feedback_remaining()
	var hud_ready_before_pause := hud.get_ability_ready_pulse_remaining()
	assert_true(controller.request_manual_pause(), "La pausa deve aprirsi durante gli impulsi HUD.")
	hud._process(0.4)
	assert_almost_eq(
		hud.get_health_feedback_remaining(), hud_health_before_pause, TIMING_FLOAT_TOLERANCE,
		"L'impulso vita HUD deve congelarsi in pausa."
	)
	assert_almost_eq(
		hud.get_ability_ready_pulse_remaining(), hud_ready_before_pause, TIMING_FLOAT_TOLERANCE,
		"L'impulso pronta deve congelarsi in pausa."
	)
	assert_true(controller.resume_run(), "La run deve riprendere dopo gli impulsi HUD congelati.")


func _assert_non_interactive_ability_tail(
	controller: RunController, registry: AbilityEffectRegistry, player: Player
) -> void:
	registry.clear_active_effects()
	await wait_process_frames(1)
	var definition := registry.resolve_definition(&"magno_earthquake_shockwave")
	assert_not_null(definition, "La fixture B18R richiede Onda d'Urto.")
	if definition == null:
		return
	assert_almost_eq(definition.cooldown_seconds, 8.0, TIMING_FLOAT_TOLERANCE, "B18R non deve cambiare il cooldown.")
	assert_almost_eq(
		definition.duration_seconds, 0.0, TIMING_FLOAT_TOLERANCE, "B18R non deve aggiungere durata gameplay."
	)
	assert_almost_eq(definition.area_radius, 220.0, TIMING_FLOAT_TOLERANCE, "B18R non deve cambiare il raggio.")
	assert_almost_eq(definition.damage, 8.0, TIMING_FLOAT_TOLERANCE, "B18R non deve cambiare il danno.")

	var effect := registry.execute_effect(definition, player) as EarthquakeWave
	var burst := registry.get_last_icon_burst()
	assert_true(
		effect != null and burst == null, "Onda d'Urto deve usare il decal nel proprio effetto, senza icona HUD."
	)
	if effect == null:
		return
	effect.set_process(false)
	assert_almost_eq(
		effect.get_duration_total(), PresentationTimings.ABILITY_VFX_TAIL_SECONDS, TIMING_FLOAT_TOLERANCE,
		"Il decal tellurico deve usare la durata B18R."
	)
	assert_true(effect.is_non_interactive_tail(), "La coda tellurica deve dichiararsi non interattiva.")
	assert_true(
		effect.find_children("*", "CollisionObject2D", true, false).is_empty(),
		"Il decal tellurico non deve contenere collisioni."
	)
	var before_pause := effect.get_duration_remaining()
	assert_true(controller.request_manual_pause(), "La pausa deve aprirsi durante il decal abilita.")
	effect._process(0.4)
	assert_almost_eq(
		effect.get_duration_remaining(), before_pause, TIMING_FLOAT_TOLERANCE, "Il decal abilita deve congelarsi in pausa."
	)
	assert_true(controller.resume_run(), "La run deve riprendere dopo il decal congelato.")

	effect._process(0.4)
	await wait_process_frames(1)
	assert_eq(
		registry.get_active_effect_count(), 1, "Il decal tellurico deve restare leggibile dopo l'impatto istantaneo."
	)
	assert_eq(
		registry.get_active_visual_tail_count(), 0, "Il decal non deve creare una seconda coda-emblema."
	)
	effect._process(PresentationTimings.ABILITY_VFX_TAIL_SECONDS)
	await wait_process_frames(1)
	assert_eq(registry.get_active_effect_count(), 0, "Il decal deve ripulirsi alla fine visiva.")


func _assert_two_run_cleanup(
	controller: RunController, registry: AbilityEffectRegistry, player: Player, feedback: CombatFeedback, hud: GameHud
) -> void:
	var definition := registry.resolve_definition(&"magno_earthquake_shockwave")
	if definition == null:
		return
	assert_not_null(registry.execute_effect(definition, player), "La prima run deve creare un effetto.")
	assert_eq(registry.get_active_effect_count(), 1, "La prima run deve avere il decal attivo.")
	assert_eq(
		registry.get_active_visual_tail_count(), 0, "La prima run non deve creare un emblema separato."
	)
	assert_true(controller.request_defeat(), "La prima run deve entrare nel terminale.")
	await wait_process_frames(1)
	assert_true(
		registry.get_active_effect_count() == 0 and registry.get_active_visual_tail_count() == 0,
		"Il terminale deve ripulire effetti e code abilita."
	)
	assert_true(
		is_zero_approx(hud.get_health_feedback_remaining())
		and is_zero_approx(hud.get_ability_ready_pulse_remaining()),
		"Il terminale deve neutralizzare gli impulsi HUD."
	)
	assert_true(controller.restart_run(18002), "La seconda run deve ripartire.")
	await wait_process_frames(1)
	assert_eq(feedback.get_active_effect_count(), 0, "La seconda run non deve ereditare feedback mondo.")
	assert_not_null(registry.execute_effect(definition, player), "La seconda run deve creare un nuovo effetto.")
	assert_eq(registry.get_active_effect_count(), 1, "La seconda run deve avere un solo nuovo decal.")
	assert_eq(registry.get_active_visual_tail_count(), 0, "La seconda run non deve avere code-emblema.")
	controller.prepare_restart()
	await wait_process_frames(1)
	assert_true(
		registry.get_active_effect_count() == 0 and registry.get_active_visual_tail_count() == 0,
		"Restart/cambio personaggio deve lasciare zero nodi residui."
	)
