extends GutGameplayTest

## PS-046: verifica che i modal di scelta (LEVEL_UP, BARB_REWARD) isolino
## davvero l'HUD di run — ordine di disegno, velo senza z-index negativo,
## titolo che non interseca la fascia superiore dell'HUD — e che tutto torni
## come prima alla chiusura, al restart e alla sconfitta. La resa percettiva
## resta un gate manuale (vedi card).


func test_ps046_level_up_and_barb_reward_isolate_hud() -> void:
	var movement_slice := await instantiate_movement_slice()
	var controller := movement_slice.get_run_controller() as RunController
	var hud := movement_slice.get_hud() as GameHud
	var upgrade_overlay := movement_slice.get_upgrade_overlay() as UpgradeOverlay
	var barb_overlay := movement_slice.get_barb_reward_overlay() as BarbRewardOverlay
	var experience := movement_slice.get_experience_system() as ExperienceSystem
	var upgrade_service := movement_slice.get_upgrade_service() as UpgradeService
	var joystick := movement_slice.get_node("UI/SafeAreaRoot/TouchJoystick") as TouchJoystick

	assert_true(
		(
			controller != null and controller.is_running() and hud != null
			and upgrade_overlay != null and barb_overlay != null and experience != null
			and upgrade_service != null and joystick != null
		),
		"PS-046 richiede una run attiva con HUD, i due overlay di scelta e il joystick composti."
	)
	if (
		controller == null or hud == null or upgrade_overlay == null or barb_overlay == null
		or experience == null or upgrade_service == null or joystick == null
	):
		return

	# Ordine di disegno strutturale: entrambi gli overlay restano dopo l'HUD fra
	# i figli di SafeAreaRoot, cosi' il velo disegna sopra la fascia HUD invece
	# che dietro (PS-046: prima il Dimmer aveva z_index negativo e la
	# ribaltava).
	assert_true(
		hud.get_index() < upgrade_overlay.get_index() and hud.get_index() < barb_overlay.get_index(),
		"UpgradeOverlay e BarbRewardOverlay devono restare dopo l'HUD nell'ordine dei figli di SafeAreaRoot."
	)
	assert_true(
		upgrade_overlay.get_dimmer_z_index() >= 0 and barb_overlay.get_dimmer_z_index() >= 0,
		"Il velo di entrambi gli overlay non deve avere uno z_index negativo."
	)

	var joystick_visible_before := joystick.visible
	var health_value_before := hud.get_health_value()
	var health_max_before := hud.get_health_max()
	var time_text_before := hud.get_time_text()
	var ability_cooldown_text_before := hud.get_ability_cooldown_text()

	# --- LEVEL_UP ---
	assert_true(
		experience.add_experience(experience.get_experience_required()),
		"Esperienza sufficiente deve innescare un level-up."
	)
	await wait_process_frames(1)
	assert_eq(
		controller.get_state(), RunController.RunState.LEVEL_UP,
		"Un level-up deve portare il RunController in LEVEL_UP."
	)
	assert_true(upgrade_overlay.visible, "L'overlay di livello deve mostrarsi durante LEVEL_UP.")
	assert_false(joystick.visible, "Il joystick touch deve sparire durante LEVEL_UP.")
	assert_false(
		hud.get_top_band_rect().intersects(upgrade_overlay.get_level_label_rect()),
		"Il titolo del level-up non deve intersecare la fascia superiore dell'HUD (barre e cronometro)."
	)
	assert_eq(hud.get_health_value(), health_value_before, "I dati vita dell'HUD non devono cambiare dietro il modal.")
	assert_eq(hud.get_health_max(), health_max_before, "Il massimo vita dell'HUD non deve cambiare dietro il modal.")
	assert_eq(hud.get_time_text(), time_text_before, "Il cronometro dell'HUD resta invariato mentre la run e' in pausa logica.")

	# Il lock anti-tap usa il tempo reale (non i frame): bisogna aspettarlo per
	# davvero prima di poter selezionare una carta.
	await get_tree().create_timer(UpgradeOverlay.SELECTION_LOCK_SECONDS + 0.1).timeout
	assert_true(upgrade_overlay.submit_card(0), "La selezione della prima carta deve essere accettata.")
	await wait_process_frames(1)
	assert_false(upgrade_overlay.visible, "L'overlay di livello deve chiudersi dopo la scelta.")
	assert_eq(
		controller.get_state(), RunController.RunState.RUNNING,
		"La scelta deve far tornare il RunController in RUNNING."
	)
	assert_eq(joystick.visible, joystick_visible_before, "Il joystick deve tornare visibile come prima del modal.")
	assert_eq(
		hud.get_ability_cooldown_text(), ability_cooldown_text_before,
		"Lo stato di ricarica dell'abilita' non deve essere alterato dal modal."
	)

	# --- BARB_REWARD ---
	upgrade_service.queue_barb_reward()
	await wait_process_frames(1)
	assert_eq(
		controller.get_state(), RunController.RunState.BARB_REWARD,
		"La ricompensa Barb deve portare il RunController in BARB_REWARD."
	)
	assert_true(barb_overlay.visible, "L'overlay Barb deve mostrarsi durante BARB_REWARD.")
	assert_false(joystick.visible, "Il joystick touch deve sparire anche durante BARB_REWARD.")
	assert_false(
		hud.get_top_band_rect().intersects(barb_overlay.get_title_label_rect()),
		"Il titolo della ricompensa Barb non deve intersecare la fascia superiore dell'HUD."
	)

	var barb_cards := barb_overlay.get_cards()
	var chosen_id := barb_cards[0].get_upgrade_id() if not barb_cards.is_empty() else &""
	await get_tree().create_timer(BarbRewardOverlay.SELECTION_LOCK_SECONDS + 0.1).timeout
	assert_true(
		not chosen_id.is_empty() and barb_overlay.submit_card(0),
		"La selezione della prima carta Barb deve essere accettata."
	)
	await wait_process_frames(1)
	assert_false(barb_overlay.visible, "L'overlay Barb deve chiudersi dopo la scelta.")
	assert_eq(
		controller.get_state(), RunController.RunState.RUNNING,
		"La scelta Barb deve far tornare il RunController in RUNNING."
	)
	assert_eq(joystick.visible, joystick_visible_before, "Il joystick deve tornare visibile come prima del modal Barb.")


func test_ps046_restart_and_defeat_close_open_offer() -> void:
	# Restart con un'offerta Barb ancora aperta.
	var restart_slice := await instantiate_movement_slice()
	var restart_controller := restart_slice.get_run_controller() as RunController
	var restart_barb_overlay := restart_slice.get_barb_reward_overlay() as BarbRewardOverlay
	var restart_upgrade_service := restart_slice.get_upgrade_service() as UpgradeService
	var restart_joystick := restart_slice.get_node("UI/SafeAreaRoot/TouchJoystick") as TouchJoystick
	assert_true(
		(
			restart_controller != null and restart_barb_overlay != null
			and restart_upgrade_service != null and restart_joystick != null
		),
		"Il fixture di restart deve esporre RunController, BarbRewardOverlay, UpgradeService e joystick."
	)
	if (
		restart_controller == null or restart_barb_overlay == null
		or restart_upgrade_service == null or restart_joystick == null
	):
		return

	var joystick_visible_before := restart_joystick.visible
	restart_upgrade_service.queue_barb_reward()
	await wait_process_frames(1)
	assert_true(restart_barb_overlay.visible, "L'overlay Barb deve essere aperto prima del restart.")

	assert_true(
		restart_controller.prepare_restart(), "Il restart deve essere accettato con un'offerta Barb aperta."
	)
	await wait_process_frames(1)
	assert_false(restart_barb_overlay.visible, "Il restart deve chiudere l'overlay Barb ancora aperto.")
	assert_eq(
		restart_joystick.visible, joystick_visible_before,
		"Il restart deve ripristinare la visibilita' del joystick precedente al modal."
	)

	# Sconfitta con un'offerta di livello ancora aperta (fixture indipendente).
	var defeat_slice := await instantiate_movement_slice()
	var defeat_controller := defeat_slice.get_run_controller() as RunController
	var defeat_upgrade_overlay := defeat_slice.get_upgrade_overlay() as UpgradeOverlay
	var defeat_experience := defeat_slice.get_experience_system() as ExperienceSystem
	var defeat_joystick := defeat_slice.get_node("UI/SafeAreaRoot/TouchJoystick") as TouchJoystick
	assert_true(
		(
			defeat_controller != null and defeat_upgrade_overlay != null
			and defeat_experience != null and defeat_joystick != null
		),
		"Il fixture di sconfitta deve esporre RunController, UpgradeOverlay, ExperienceSystem e joystick."
	)
	if (
		defeat_controller == null or defeat_upgrade_overlay == null
		or defeat_experience == null or defeat_joystick == null
	):
		return

	var defeat_joystick_visible_before := defeat_joystick.visible
	assert_true(
		defeat_experience.add_experience(defeat_experience.get_experience_required()),
		"Esperienza sufficiente deve innescare un level-up anche nel fixture di sconfitta."
	)
	await wait_process_frames(1)
	assert_true(defeat_upgrade_overlay.visible, "L'overlay di livello deve essere aperto prima della sconfitta.")

	assert_true(
		defeat_controller.request_defeat(), "La sconfitta deve essere accettata con un'offerta di livello aperta."
	)
	await wait_process_frames(1)
	assert_eq(
		defeat_controller.get_state(), RunController.RunState.DEFEAT,
		"Il RunController deve entrare in DEFEAT."
	)
	assert_false(defeat_upgrade_overlay.visible, "La sconfitta deve chiudere l'overlay di livello ancora aperto.")
	assert_eq(
		defeat_joystick.visible, defeat_joystick_visible_before,
		"La sconfitta deve ripristinare la visibilita' del joystick precedente al modal."
	)

	print("LEVEL_UP_MODAL_ISOLATION_SMOKE_OK")
