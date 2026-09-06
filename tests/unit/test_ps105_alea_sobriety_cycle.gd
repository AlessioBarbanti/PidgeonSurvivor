extends GutGameplayTest

## PS-105 — Sostituisci la passiva di Alea con Due Dita e Parto.
##
## Copre il nuovo meccanismo Sobrietà/Brilla che rimpiazza integralmente
## "L'Aquila Non Sbaglia Mai" (RNG a intervalli, luck-per-kill): accumulo
## lineare deterministico, trigger automatico di Brilla alla soglia,
## moltiplicatori di cadenza/movimento applicati e rimossi correttamente,
## deriva periodica sull'input durante Brilla, azzeramento completo dopo
## Brilla, congelamento fuori da RUNNING, e nessuna dipendenza da RNG in
## nessun punto del nuovo percorso (verificato confrontando due seed diversi:
## un ciclo che dipendesse da RNG produrrebbe timeline diverse).

const ALEA_ID := &"alea"
const RUN_SEED_A := 3131
const RUN_SEED_B := 9042


func test_alea_sobriety_accumulates_linearly_and_freezes_outside_running() -> void:
	var context := await _build_alea_context(RUN_SEED_A)
	if context.is_empty():
		return
	var controller: RunController = context["controller"]
	var passive: FriendPassiveController = context["passive"]
	var fill_duration: float = context["fill_duration"]

	assert_almost_eq(
		passive.get_alea_sobriety_ratio(), 0.0, FLOAT_TOLERANCE,
		"La run deve iniziare senza Sobrietà accumulata."
	)
	assert_false(passive.is_alea_brilla_active(), "Nessun Brilla subito dopo l'equip.")

	passive._process(fill_duration * 0.5)
	assert_almost_eq(
		passive.get_alea_sobriety_ratio(), 0.5, 0.01,
		"PS-105: l'accumulo deve essere lineare nel tempo, senza RNG ne' dipendenza da kill/danno."
	)
	assert_false(passive.is_alea_brilla_active(), "A metà accumulo Brilla non deve ancora attivarsi.")

	# Pausa manuale, level-up e Boss intro condividono il contratto RUNNING
	# gia' rispettato da Zat (PS-003): il clock della Sobrietà non e' diverso.
	assert_true(controller.request_manual_pause(), "La pausa manuale deve essere accettata.")
	passive._process(fill_duration)
	assert_true(controller.resume_run(), "La run deve poter riprendere.")
	assert_almost_eq(
		passive.get_alea_sobriety_ratio(), 0.5, 0.01,
		"PS-105: la pausa manuale non deve far avanzare la Sobrietà."
	)

	assert_true(controller.request_level_up(), "Il level-up deve essere accettato.")
	passive._process(fill_duration)
	assert_true(controller.complete_level_up(), "Il level-up deve potersi chiudere.")
	assert_almost_eq(
		passive.get_alea_sobriety_ratio(), 0.5, 0.01,
		"PS-105: il level-up non deve far avanzare la Sobrietà."
	)

	assert_true(controller.request_boss_intro(), "L'intro del Boss deve essere accettata.")
	passive._process(fill_duration)
	assert_true(controller.complete_boss_intro(), "L'intro del Boss deve potersi chiudere.")
	get_tree().paused = false
	assert_almost_eq(
		passive.get_alea_sobriety_ratio(), 0.5, 0.01,
		"PS-105: la Boss Intro non deve far avanzare la Sobrietà."
	)

	controller.prepare_restart()


func test_alea_brilla_triggers_at_threshold_and_applies_then_removes_multipliers() -> void:
	var context := await _build_alea_context(RUN_SEED_A)
	if context.is_empty():
		return
	var controller: RunController = context["controller"]
	var passive: FriendPassiveController = context["passive"]
	var player: Player = context["player"]
	var weapon: WeaponController = context["weapon"]
	var fill_duration: float = context["fill_duration"]
	var brilla_duration: float = context["brilla_duration"]
	var move_multiplier: float = context["move_multiplier"]
	var fire_multiplier: float = context["fire_multiplier"]

	passive._process(fill_duration)
	assert_true(
		passive.is_alea_brilla_active(),
		"PS-105: al raggiungimento della soglia Brilla deve attivarsi automaticamente."
	)
	assert_almost_eq(
		passive.get_alea_brilla_remaining(), brilla_duration, FLOAT_TOLERANCE,
		"PS-105: Brilla deve durare esattamente la finestra dichiarata."
	)
	var definition: FriendDefinition = context["definition"]
	var expected_move := move_multiplier * definition.get_base_move_speed_multiplier()
	var expected_fire := fire_multiplier * definition.get_base_fire_rate_multiplier()
	assert_almost_eq(
		player.get_character_move_speed_multiplier(), expected_move, FLOAT_TOLERANCE,
		"PS-105: durante Brilla la velocita' di movimento deve riflettere il moltiplicatore dichiarato (composto con gli scarti base B47)."
	)
	assert_almost_eq(
		weapon.get_character_fire_rate_multiplier(), expected_fire, FLOAT_TOLERANCE,
		"PS-105: durante Brilla la cadenza di fuoco deve riflettere il moltiplicatore dichiarato (composto con gli scarti base B47)."
	)

	passive._process(brilla_duration + 0.01)
	assert_false(passive.is_alea_brilla_active(), "PS-105: trascorsa Brilla, torna allo stato normale.")
	assert_almost_eq(
		player.get_character_move_speed_multiplier(), definition.get_base_move_speed_multiplier(), FLOAT_TOLERANCE,
		"PS-105: trascorsa Brilla la velocita' torna esattamente al valore base del personaggio."
	)
	assert_almost_eq(
		weapon.get_character_fire_rate_multiplier(), definition.get_base_fire_rate_multiplier(), FLOAT_TOLERANCE,
		"PS-105: trascorsa Brilla la cadenza torna esattamente al valore base del personaggio."
	)
	assert_almost_eq(
		passive.get_alea_sobriety_ratio(), 0.0, FLOAT_TOLERANCE,
		"PS-105: trascorsa Brilla la barra Sobrietà si azzera completamente, nessuna quota residua."
	)

	controller.prepare_restart()


func test_alea_drift_deviates_movement_periodically_and_is_correctable() -> void:
	var context := await _build_alea_context(RUN_SEED_A)
	if context.is_empty():
		return
	var controller: RunController = context["controller"]
	var passive: FriendPassiveController = context["passive"]
	var player: Player = context["player"]
	var fill_duration: float = context["fill_duration"]
	var drift_interval: float = context["drift_interval"]
	var drift_duration: float = context["drift_duration"]

	passive._process(fill_duration)
	assert_true(passive.is_alea_brilla_active(), "Serve Brilla attivo per osservare la deriva.")
	assert_almost_eq(
		player.get_movement_drift_rotation(), 0.0, FLOAT_TOLERANCE,
		"PS-105: all'inizio di Brilla, prima del primo impulso, non deve esserci deriva."
	)

	# Il primo impulso scatta al primo intervallo pieno: durante la sua durata
	# la deriva e' non nulla (percettibile), poi torna a zero (correggibile) e
	# resta nulla fino al prossimo impulso.
	passive._process(drift_interval)
	assert_false(
		is_equal_approx(player.get_movement_drift_rotation(), 0.0),
		"PS-105: durante l'impulso di deriva la direzione effettiva deve deviare da quella voluta."
	)

	passive._process(drift_duration + 0.01)
	assert_almost_eq(
		player.get_movement_drift_rotation(), 0.0, FLOAT_TOLERANCE,
		"PS-105: trascorso l'impulso la deriva deve tornare a zero e restare correggibile."
	)

	passive._process(drift_interval - drift_duration - 0.02)
	assert_almost_eq(
		player.get_movement_drift_rotation(), 0.0, FLOAT_TOLERANCE,
		"PS-105: fra un impulso e l'altro la deriva deve restare a zero, non un tremore continuo."
	)

	controller.prepare_restart()


func test_alea_cycle_has_no_rng_dependency_across_seeds() -> void:
	var context_a := await _build_alea_context(RUN_SEED_A)
	var context_b := await _build_alea_context(RUN_SEED_B)
	if context_a.is_empty() or context_b.is_empty():
		return
	var passive_a: FriendPassiveController = context_a["passive"]
	var passive_b: FriendPassiveController = context_b["passive"]
	var fill_duration: float = context_a["fill_duration"]
	var drift_interval: float = context_a["drift_interval"]

	# Stessa timeline applicata a due run seminate diversamente: se un solo
	# punto del nuovo meccanismo dipendesse da RNG, i due passive divergerebbero
	# (soglia, durata di Brilla, verso o tempistica della deriva).
	for _step in range(6):
		passive_a._process(fill_duration / 6.0)
		passive_b._process(fill_duration / 6.0)
		assert_almost_eq(
			passive_a.get_alea_sobriety_ratio(), passive_b.get_alea_sobriety_ratio(), FLOAT_TOLERANCE,
			"PS-105: l'accumulo deve essere identico indipendentemente dal seed."
		)
	assert_eq(
		passive_a.is_alea_brilla_active(), passive_b.is_alea_brilla_active(),
		"PS-105: il trigger di Brilla non deve dipendere dal seed."
	)

	for _step in range(3):
		passive_a._process(drift_interval)
		passive_b._process(drift_interval)
		var player_a: Player = context_a["player"]
		var player_b: Player = context_b["player"]
		assert_almost_eq(
			player_a.get_movement_drift_rotation(), player_b.get_movement_drift_rotation(), FLOAT_TOLERANCE,
			"PS-105: nessun punto della deriva deve dipendere da RNG: stesso verso e tempistica a parita' di seed diversi."
		)

	context_a["controller"].prepare_restart()
	context_b["controller"].prepare_restart()
	print("ALEA_SOBRIETY_CYCLE_SMOKE_OK")


func test_alea_restart_and_character_change_reset_state() -> void:
	var context := await _build_alea_context(RUN_SEED_A)
	if context.is_empty():
		return
	var controller: RunController = context["controller"]
	var registry: FriendRegistry = context["registry"]
	var player: Player = context["player"]
	var passive: FriendPassiveController = context["passive"]
	var fill_duration: float = context["fill_duration"]

	passive._process(fill_duration * 0.5)
	assert_true(passive.get_alea_sobriety_ratio() > 0.0, "Serve Sobrietà accumulata prima del restart.")

	controller.prepare_restart()
	assert_almost_eq(
		passive.get_alea_sobriety_ratio(), 0.0, FLOAT_TOLERANCE, "PS-105: il restart deve azzerare la Sobrietà."
	)
	assert_almost_eq(
		player.get_movement_drift_rotation(), 0.0, FLOAT_TOLERANCE, "PS-105: il restart deve azzerare la deriva residua."
	)

	assert_true(controller.start_run(4711), "La run deve poter ripartire.")
	player.set_friend_definition(registry.resolve_definition(ALEA_ID))
	assert_true(passive.equip_definition(registry.resolve_definition(ALEA_ID)), "Alea deve poter essere riequipaggiata.")
	passive._process(fill_duration * 0.3)
	assert_true(passive.get_alea_sobriety_ratio() > 0.0, "Serve Sobrietà accumulata prima del cambio personaggio.")

	var other := registry.resolve_definition(&"magno")
	assert_true(other != null, "Serve un secondo profilo per il cambio personaggio.")
	if other == null:
		return
	assert_true(passive.equip_definition(other), "Il cambio personaggio deve essere accettato.")
	assert_almost_eq(
		passive.get_alea_sobriety_ratio(), 0.0, FLOAT_TOLERANCE,
		"PS-105: il cambio personaggio deve azzerare la Sobrietà di Alea."
	)
	assert_almost_eq(
		player.get_movement_drift_rotation(), 0.0, FLOAT_TOLERANCE,
		"PS-105: il cambio personaggio deve azzerare la deriva residua."
	)


func _build_alea_context(seed_value: int) -> Dictionary:
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_run_controller() as RunController
	var registry := movement_slice.get_friend_registry() as FriendRegistry
	var player := movement_slice.get_player() as Player
	var passive := movement_slice.get_friend_passive_controller() as FriendPassiveController
	var weapon := movement_slice.get_weapon_controller() as WeaponController
	if controller == null or registry == null or player == null or passive == null or weapon == null:
		assert_true(false, "La scena di run deve esporre le dipendenze PS-105.")
		return {}

	controller.set_process(false)
	player.set_physics_process(false)
	passive.set_process(false)
	controller.start_run(seed_value)

	var alea := registry.resolve_definition(ALEA_ID)
	assert_true(alea != null, "Il profilo Alea deve esistere.")
	if alea == null:
		return {}
	player.set_friend_definition(alea)
	assert_true(passive.equip_definition(alea), "La passiva deve accettare Alea.")

	return {
		"slice": movement_slice,
		"controller": controller,
		"registry": registry,
		"player": player,
		"passive": passive,
		"weapon": weapon,
		"definition": alea,
		"fill_duration": alea.get_passive_float(
			&"sobriety_fill_duration", 48.0, AbilityDefinition.MINIMUM_POSITIVE_VALUE
		),
		"brilla_duration": alea.get_passive_float(
			&"brilla_duration", 6.0, AbilityDefinition.MINIMUM_POSITIVE_VALUE
		),
		"move_multiplier": alea.get_passive_float(
			&"brilla_move_speed_multiplier", 1.3, FriendPassiveController.MINIMUM_MULTIPLIER
		),
		"fire_multiplier": alea.get_passive_float(
			&"brilla_fire_rate_multiplier", 1.35, FriendPassiveController.MINIMUM_MULTIPLIER
		),
		"drift_interval": alea.get_passive_float(
			&"drift_interval", 1.6, AbilityDefinition.MINIMUM_POSITIVE_VALUE
		),
		"drift_duration": alea.get_passive_float(
			&"drift_duration", 0.35, AbilityDefinition.MINIMUM_POSITIVE_VALUE
		),
	}
