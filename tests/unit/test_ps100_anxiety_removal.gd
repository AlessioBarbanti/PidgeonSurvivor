extends GutGameplayTest

## PS-100: L'Ansia (anxiety_signature) esce dal gioco per decisione del
## proprietario, non solo dal catalogo di run ma anche dal registro effetti
## (UpgradeEffectRegistry.can_apply() non riconosce piu' l'effect_id). La
## vignetta resta cablata come infrastruttura riusabile ma nessuna carta la
## pilota piu'.

const EXPECTED_SPECIALITY_COUNT := 8


func test_anxiety_removed_from_game() -> void:
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_run_controller() as RunController
	var registry := movement_slice.get_upgrade_registry() as UpgradeRegistry
	var service := movement_slice.get_upgrade_service() as UpgradeService
	var effects := movement_slice.get_upgrade_effect_registry() as UpgradeEffectRegistry
	var vignette := movement_slice.get_vignette_effect() as VignetteEffect
	assert_true(
		controller != null and registry != null and service != null and effects != null,
		"PS-100 richiede run, catalogo, service e registro effetti."
	)
	assert_not_null(vignette, "PS-100 richiede il nodo vignetta (infrastruttura riusabile, ora senza piloti).")
	if controller == null or registry == null or service == null or effects == null or vignette == null:
		return
	controller.set_process(false)

	assert_null(
		registry.resolve_definition(&"anxiety_signature"),
		"PS-100: L'Ansia non deve più esistere nel catalogo di run."
	)
	assert_eq(
		registry.get_speciality_definitions().size(), EXPECTED_SPECIALITY_COUNT,
		"PS-100: il pool delle Specialità deve contare otto carte."
	)
	assert_eq(
		service.get_locked_speciality_definitions().size(), EXPECTED_SPECIALITY_COUNT,
		"PS-100: ogni run deve iniziare con tutte le Specialità rimaste bloccate."
	)

	# Anche con dati identici a quelli storici, il registro non deve più saper
	# applicare l'effetto: la rimozione vive nel meccanismo, non solo nel
	# roster referenziato da movement_slice.tscn.
	var probe := UpgradeDefinition.new()
	probe.id = &"anxiety_signature"
	probe.title = "L'Ansia"
	probe.description = "Sonda PS-100: l'effetto non deve più essere applicabile."
	probe.effect_id = &"anxiety_signature"
	probe.effect_parameters = {
		"move_speed_multiplier": 1.35,
		"health_max_multiplier": 0.8,
		"vignette_intensity": 0.42,
	}
	probe.weight = 1.0
	probe.max_rank = 1
	probe.is_speciality = true
	assert_true(probe.is_valid(), "La sonda PS-100 deve restare un dato valido di per sé.")
	assert_false(
		effects.can_apply(probe),
		"PS-100: il registro non deve più riconoscere l'effect_id anxiety_signature."
	)

	# Nessuna offerta, né di Barb né di level-up ordinario, deve mai più
	# proporre L'Ansia: esaurisce tutte le Specialità bloccate rimaste e pesca
	# a lungo nel pool normale.
	for _reward_index in EXPECTED_SPECIALITY_COUNT:
		service.queue_barb_reward()
		var offer_ids := service.get_current_barb_offer_ids()
		assert_false(&"anxiety_signature" in offer_ids, "PS-100: Barb non deve mai offrire L'Ansia.")
		if offer_ids.is_empty():
			break
		assert_true(
			service.select_barb_speciality(offer_ids[0]),
			"PS-100: la fixture deve poter sbloccare le Specialità rimaste."
		)
	assert_true(
		service.get_locked_speciality_definitions().is_empty(),
		"PS-100: tutte le Specialità rimaste devono sbloccarsi senza mai incontrare L'Ansia."
	)

	for draw_index in 24:
		for offered in service.generate_offer(draw_index + 1):
			assert_false(
				offered.id == &"anxiety_signature",
				"PS-100: il level-up ordinario non deve mai offrire L'Ansia (pesca %d)." % (draw_index + 1)
			)

	# La vignetta resta a riposo per l'intera run: nessuna carta la pilota più.
	assert_false(vignette.visible, "PS-100: la vignetta non deve mai attivarsi a inizio run.")
	assert_true(is_zero_approx(vignette.intensity), "PS-100: l'intensità della vignetta deve restare a zero.")
	assert_true(
		effects.recalculate_effects(), "PS-100: il ricalcolo con le Specialità rimaste sbloccate deve restare valido."
	)
	assert_false(vignette.visible, "PS-100: il ricalcolo non deve riattivare la vignetta.")
	assert_true(is_zero_approx(vignette.intensity), "PS-100: il ricalcolo non deve alzare l'intensità della vignetta.")

	assert_true(controller.request_defeat(), "PS-100: la fixture deve poter terminare la run.")
	assert_true(movement_slice.restart_run(10099), "PS-100: la fixture deve poter riavviare una run pulita.")
	await wait_process_frames(2)
	assert_eq(
		service.get_locked_speciality_definitions().size(), EXPECTED_SPECIALITY_COUNT,
		"PS-100: il restart deve ribloccare tutte le Specialità rimaste."
	)
	assert_false(vignette.visible, "PS-100: il restart non deve lasciare la vignetta accesa.")
	assert_true(is_zero_approx(vignette.intensity), "PS-100: il restart deve azzerare l'intensità della vignetta.")

	controller.prepare_restart()
	print("ANXIETY_REMOVAL_SMOKE_OK")
