extends SceneTree

## Utility di sviluppo (non un test): cattura le superfici UI principali per le
## revisioni visive. Guida la welcome, il selettore, la run, il level-up, la
## ricompensa Barb, il boss, la pausa e il terminale, salvando un PNG per stato.
##
## PS-044: ogni scatto passa da `_shot`, che rifiuta di salvare se lo stato del
## RunController non e' quello atteso o se sono visibili due modali che il
## contratto degli stati non puo' tenere aperti insieme. Le catture documentano
## solo stati che il gioco produce davvero.

const MOVEMENT_SLICE_SCENE := preload("res://scenes/game/movement_slice.tscn")
## Passo del cronometro logico pompato a mano per raggiungere la soglia Boss.
const RUN_TIME_PUMP_STEP := 0.25
const RUN_TIME_PUMP_FRAME_EVERY := 6
const RUN_TIME_PUMP_LIMIT := 4000
## Quanto gameplay reale lasciar scorrere prima dello scatto sotto pressione.
const PRESSURE_PREVIEW_SECONDS := 8.0
const PRESSURE_SETTLE_SECONDS := 3.0
const BOSS_FIGHT_SECONDS := 2.5
## `exports/` è ignorato da git: le catture restano artefatti locali.
const OUT_DIR := "res://exports/ui-screenshots"
## Il pacchetto 16:9 resta al percorso storico perche' i documenti lo citano;
## il formato allungato del Pixel 9 vive in una sottocartella dedicata.
const PIXEL9_OUT_DIR := "res://exports/ui-screenshots/pixel9-20x9"
const LANDSCAPE_16X9 := Vector2i(1280, 720)
## Pixel 9: pannello 1080x2424, usato in landscape come impone il target.
const LANDSCAPE_20X9 := Vector2i(2424, 1080)

var _slice: Control
var _controller: RunController
var _hud: GameHud
var _upgrade_overlay: UpgradeOverlay
var _barb_overlay: BarbRewardOverlay
var _boss_ui: BossUI
var _pause_overlay: PauseOverlay
var _end_screen: EndScreen
var _out_dir := OUT_DIR
var _profile_id := ""
var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for profile in _capture_profiles():
		_profile_id = String(profile["id"])
		_out_dir = String(profile["dir"])
		print("PROFILE %s %s" % [_profile_id, profile["size"]])
		await _capture_profile(profile["size"] as Vector2i)
		if not _failures.is_empty():
			break

	if not _failures.is_empty():
		for failure in _failures:
			printerr("CAPTURE_FAIL %s" % failure)
		quit(1)
		return

	print("CAPTURE_DONE")
	quit(0)


## Un solo posto dichiara i pacchetti prodotti: aggiungere un formato non
## richiede di toccare la sequenza di cattura.
func _capture_profiles() -> Array[Dictionary]:
	return [
		{"id": "16x9", "size": LANDSCAPE_16X9, "dir": OUT_DIR},
		{"id": "20x9", "size": LANDSCAPE_20X9, "dir": PIXEL9_OUT_DIR},
	]


func _capture_profile(viewport_size: Vector2i) -> void:
	paused = false
	root.content_scale_size = viewport_size
	root.size = viewport_size
	DisplayServer.window_set_size(viewport_size)
	await _frames(4)

	ProjectSettings.set_setting("application/run/b18o_force_welcome_for_test", true)
	_slice = MOVEMENT_SLICE_SCENE.instantiate() as Control
	root.add_child(_slice)
	ProjectSettings.set_setting("application/run/b18o_force_welcome_for_test", false)
	await _frames(20)

	var welcome := _slice.get_welcome_screen() as WelcomeScreen
	var selector := _slice.get_character_select_overlay() as CharacterSelectOverlay
	var experience := _slice.get_experience_system() as ExperienceSystem
	var upgrade_service := _slice.get_upgrade_service() as UpgradeService
	var director := _slice.get_game_director() as GameDirector
	var boss_encounter := _slice.get_boss_encounter() as BossEncounter
	_controller = _slice.get_run_controller() as RunController
	_hud = _slice.get_hud() as GameHud
	_upgrade_overlay = _slice.get_upgrade_overlay() as UpgradeOverlay
	_barb_overlay = _slice.get_barb_reward_overlay() as BarbRewardOverlay
	_boss_ui = _slice.get_boss_ui() as BossUI
	_pause_overlay = _slice.get_pause_overlay() as PauseOverlay
	_end_screen = _slice.get_end_screen() as EndScreen

	# La cattura gira con il focus sul terminale: senza staccare il lifecycle il
	# focus-out manda la run in MANUAL_PAUSE e ogni scatto di gameplay
	# ripeterebbe il modale di pausa invece dello stato richiesto. Il router
	# viene memorizzato prima: `_exit_tree` azzera i riferimenti del lifecycle.
	var lifecycle := _slice.get_platform_lifecycle() as PlatformLifecycle
	var input_router := lifecycle.get_input_router() if lifecycle != null else null
	_detach_lifecycle(lifecycle)

	await _shot("01_welcome", RunController.RunState.BOOT)

	if welcome != null and welcome.get_settings_button() != null:
		welcome.get_settings_button().emit_signal("pressed")
		await _frames(12)
		await _shot("02_welcome_settings", RunController.RunState.BOOT)
		if welcome.get_close_settings_button() != null:
			welcome.get_close_settings_button().emit_signal("pressed")
			await _frames(12)

	if welcome != null and welcome.get_tutorial_button() != null:
		welcome.get_tutorial_button().emit_signal("pressed")
		await _frames(24)
		var tutorial := _slice.get_tutorial_screen() as TutorialScreen
		if tutorial != null:
			for page_index in tutorial.get_page_count():
				tutorial.show_page(page_index)
				await _frames(16)
				await _shot(
					"02b_tutorial_%02d" % (page_index + 1),
					RunController.RunState.BOOT
				)
			if tutorial.get_previous_button() != null:
				tutorial.show_page(0)
				await _frames(8)
				tutorial.get_previous_button().emit_signal("pressed")
			await _frames(24)

	if welcome != null and welcome.get_play_button() != null:
		welcome.get_play_button().emit_signal("pressed")
		await _frames(30)
		await _shot("03_character_select", RunController.RunState.BOOT)
		await _capture_roster(selector)

	if selector != null and selector.get_confirm_button() != null:
		selector.get_confirm_button().emit_signal("pressed")
		await _frames(10)
		await _timeout(4.0)
		await _shot("04_gameplay_hud", RunController.RunState.RUNNING)

	if experience != null:
		experience.add_experience(40)
		await _frames(24)
		await _shot("05_upgrade_overlay", RunController.RunState.LEVEL_UP)
		await _drain_level_ups()

	if upgrade_service != null:
		await _capture_barb_reward(upgrade_service)

	await _capture_boss(director, boss_encounter)

	await _capture_pause(lifecycle, input_router)

	if _controller.request_defeat():
		await _frames(24)
		await _shot("08_end_screen", RunController.RunState.DEFEAT)
		_check_terminal_time_coherence()
	else:
		_failures.append("%s: request_defeat rifiutata" % _profile_id)

	if lifecycle != null and lifecycle.get_parent() == null:
		lifecycle.free()
	_slice.queue_free()
	_slice = null
	await _frames(6)


## `add_experience` puo' accodare piu' salite di livello: svuota la coda,
## altrimenti il modale resta aperto sotto agli scatti successivi.
func _drain_level_ups() -> void:
	var drain_guard := 0
	while _upgrade_overlay != null and _upgrade_overlay.visible and drain_guard < 8:
		drain_guard += 1
		await _timeout(UpgradeOverlay.SELECTION_LOCK_SECONDS + 0.2)
		if not _upgrade_overlay.is_accepting_selection():
			break
		_upgrade_overlay.submit_card(0)
		await _frames(20)
	if _controller.get_state() != RunController.RunState.RUNNING:
		_failures.append(
			"%s: la run non e' tornata RUNNING dopo il level-up (stato %d)"
			% [_profile_id, _controller.get_state()]
		)


## PS-036 aveva uno script dedicato per la schermata Barb: qui la si raggiunge
## dal percorso reale della run, cosi' `05b` mostra il layout corrente.
func _capture_barb_reward(upgrade_service: UpgradeService) -> void:
	if _controller.get_state() != RunController.RunState.RUNNING:
		return
	upgrade_service.queue_barb_reward()
	await _frames(24)
	if _controller.get_state() != RunController.RunState.BARB_REWARD:
		_failures.append("%s: la ricompensa Barb non si e' aperta" % _profile_id)
		return
	await _shot("05b_barb_speciality", RunController.RunState.BARB_REWARD)
	if not await _close_barb_speciality(upgrade_service):
		return

	# Con tutte le specialita' sbloccate la stessa schermata passa in modalita'
	# bonus: e' un secondo layout, non una variante grafica del primo.
	var unlock_guard := 0
	while not upgrade_service.get_locked_speciality_definitions().is_empty():
		unlock_guard += 1
		if unlock_guard > 8:
			_failures.append("%s: specialita' Barb non esaurite" % _profile_id)
			return
		upgrade_service.queue_barb_reward()
		await _frames(20)
		if not await _close_barb_speciality(upgrade_service):
			return

	upgrade_service.queue_barb_reward()
	await _frames(24)
	if not upgrade_service.is_barb_bonus_mode():
		_failures.append("%s: la modalita' bonus di Barb non si e' aperta" % _profile_id)
		return
	await _shot("05c_barb_bonus", RunController.RunState.BARB_REWARD)
	var bonus_guard := 0
	while _controller.get_state() == RunController.RunState.BARB_REWARD:
		bonus_guard += 1
		if bonus_guard > 8:
			_failures.append("%s: il premio bonus di Barb non si chiude" % _profile_id)
			return
		var bonus_offer := upgrade_service.get_current_barb_offer()
		if bonus_offer.is_empty():
			break
		upgrade_service.select_barb_bonus_upgrade(bonus_offer[0].id)
		await _frames(20)


func _close_barb_speciality(upgrade_service: UpgradeService) -> bool:
	var offer := upgrade_service.get_current_barb_offer()
	if offer.is_empty() or not upgrade_service.select_barb_speciality(offer[0].id):
		_failures.append("%s: impossibile chiudere la ricompensa Barb" % _profile_id)
		return false
	await _frames(20)
	return true


## Il cast e' identita' di prodotto: un pacchetto pensato per il design deve
## mostrarlo tutto, non solo il personaggio predefinito del selettore.
func _capture_roster(selector: CharacterSelectOverlay) -> void:
	if selector == null:
		return
	for index in selector.get_roster_size():
		var definition := selector.get_selected_definition()
		if definition == null:
			_failures.append("%s: nessun personaggio all'indice %d" % [_profile_id, index])
			return
		# La prima posizione del carosello e' gia' `03_character_select`: farne
		# un secondo PNG identico gonfierebbe il pacchetto senza aggiungere nulla.
		if index > 0:
			await _shot(
				"03b_character_%02d_%s" % [index + 1, definition.id],
				RunController.RunState.BOOT
			)
		selector.navigate_next()
		var transition_guard := 0
		while selector.has_active_transition() and transition_guard < 60:
			transition_guard += 1
			await _frames(2)
		await _frames(8)


## Il Boss arriva dalla soglia del GameDirector, non da una intro simulata:
## solo cosi' la cattura mostra l'incontro che il gioco produce davvero, con il
## Boss in campo e la sua barra vita overhead.
func _capture_boss(director: GameDirector, encounter: BossEncounter) -> void:
	if director == null or encounter == null:
		_failures.append("%s: GameDirector o BossEncounter assenti" % _profile_id)
		return
	if _controller.get_state() != RunController.RunState.RUNNING:
		_failures.append("%s: la run non e' RUNNING prima del Boss" % _profile_id)
		return
	var thresholds := director.get_thresholds()
	if thresholds.is_empty():
		_failures.append("%s: il profilo del Director non ha soglie Boss" % _profile_id)
		return

	# La curva di difficolta' legge il tempo logico di run: portarlo alla soglia
	# mostra l'arena come si presenta a quel minuto, non ai primi secondi.
	var target := thresholds[0] + 1.0
	var pumped := await _advance_run_time(target - PRESSURE_PREVIEW_SECONDS)
	if not pumped:
		return
	await _timeout(PRESSURE_SETTLE_SECONDS)
	await _shot("04b_gameplay_pressure", RunController.RunState.RUNNING)

	if not await _advance_run_time(target):
		return
	if _controller.get_state() != RunController.RunState.BOSS_INTRO:
		_failures.append(
			"%s: la soglia Boss non ha aperto BOSS_INTRO (stato %d)"
			% [_profile_id, _controller.get_state()]
		)
		return
	await _frames(24)
	await _shot("06_boss_intro", RunController.RunState.BOSS_INTRO)

	if not encounter.complete_intro():
		_failures.append("%s: complete_intro rifiutata" % _profile_id)
		return
	await _frames(12)
	await _timeout(BOSS_FIGHT_SECONDS)
	if encounter.get_active_boss() == null:
		_failures.append("%s: nessun Boss in campo dopo l'intro" % _profile_id)
		return
	await _shot("06b_boss_fight", RunController.RunState.RUNNING)


## Avanza il cronometro logico lasciando respirare il rendering: il gameplay
## continua a girare, quindi l'arena si popola davvero invece di essere
## teletrasportata a difficolta' alta con lo schermo vuoto.
func _advance_run_time(target_seconds: float) -> bool:
	var guard := 0
	while _controller.get_run_time() < target_seconds:
		guard += 1
		if guard > RUN_TIME_PUMP_LIMIT:
			_failures.append(
				"%s: cronometro fermo a %.1fs invece di %.1fs"
				% [_profile_id, _controller.get_run_time(), target_seconds]
			)
			return false
		_controller._process(RUN_TIME_PUMP_STEP)
		if guard % RUN_TIME_PUMP_FRAME_EVERY == 0:
			await _frames(1)
		if not _controller.is_running():
			return true
	return true


## La conferma di cambio personaggio esiste solo sopra la pausa: si arriva
## dallo stato MANUAL_PAUSE, mai sovrapponendola a un altro modale.
func _capture_pause(
	lifecycle: PlatformLifecycle,
	input_router: InputRouter
) -> void:
	if lifecycle == null or input_router == null or _pause_overlay == null:
		_failures.append("%s: lifecycle o router non disponibili" % _profile_id)
		return

	root.add_child(lifecycle)
	if not lifecycle.configure(_controller, input_router, _pause_overlay):
		_failures.append("%s: configure del lifecycle rifiutata" % _profile_id)
		return
	await _frames(6)

	if _controller.get_state() == RunController.RunState.RUNNING:
		lifecycle.request_manual_pause()
	await _frames(20)
	await _shot("07_pause_overlay", RunController.RunState.MANUAL_PAUSE)

	var change_button := _pause_overlay.get_change_character_button()
	if change_button != null:
		change_button.emit_signal("pressed")
		await _frames(16)
		if _pause_overlay.is_change_confirmation_visible():
			await _shot(
				"07b_pause_change_confirmation",
				RunController.RunState.MANUAL_PAUSE
			)
		else:
			_failures.append("%s: conferma di cambio personaggio assente" % _profile_id)
		var cancel_button := _pause_overlay.get_cancel_change_button()
		if cancel_button != null:
			cancel_button.emit_signal("pressed")
			await _frames(12)

	if not lifecycle.request_resume():
		_controller.resume_run()
	await _frames(12)
	_detach_lifecycle(lifecycle)


## Il tempo del riepilogo terminale nasce da `run_ended`, non da un valore
## inventato: HUD e schermata finale devono leggere lo stesso cronometro.
func _check_terminal_time_coherence() -> void:
	if _end_screen == null or _hud == null:
		return
	var expected := EndScreen.format_run_time(_controller.get_run_time())
	var summary := _end_screen.get_summary_text()
	var hud_time := _hud.get_time_text()
	print("TERMINAL_TIME run=%s hud=%s summary=%s" % [expected, hud_time, summary])
	if not summary.contains(expected):
		_failures.append(
			"%s: il riepilogo (%s) non riporta il tempo di run %s"
			% [_profile_id, summary, expected]
		)
	if hud_time != expected:
		_failures.append(
			"%s: HUD %s e tempo di run %s non coincidono"
			% [_profile_id, hud_time, expected]
		)


func _detach_lifecycle(lifecycle: PlatformLifecycle) -> void:
	if lifecycle != null and lifecycle.get_parent() != null:
		lifecycle.get_parent().remove_child(lifecycle)


func _shot(shot_name: String, expected_state: RunController.RunState) -> void:
	await _frames(3)
	var violation := _describe_state_violation(shot_name, expected_state)
	if not violation.is_empty():
		_failures.append(violation)
		return
	DirAccess.make_dir_recursive_absolute(_out_dir)
	var image := root.get_texture().get_image()
	if image == null:
		_failures.append("%s: nessuna immagine per %s" % [_profile_id, shot_name])
		return
	var path := "%s/%s.png" % [_out_dir, shot_name]
	var error := image.save_png(path)
	print("SHOT %s %s -> %s (err %d)" % [_profile_id, shot_name, path, error])


## Rifiuta lo scatto quando lo stato non e' quello richiesto o quando e'
## visibile un modale che quello stato non prevede: e' cosi' che una
## composizione impossibile viene intercettata invece di finire in un PNG.
func _describe_state_violation(
	shot_name: String,
	expected_state: RunController.RunState
) -> String:
	if _controller == null:
		return "%s/%s: RunController assente" % [_profile_id, shot_name]
	var current := _controller.get_state()
	if current != expected_state:
		return "%s/%s: stato %d invece di %d" % [
			_profile_id,
			shot_name,
			current,
			expected_state,
		]
	var allowed := _allowed_modal_for_state(current)
	var unexpected: Array[String] = []
	for entry in _visible_modals():
		if entry != allowed:
			unexpected.append(entry)
	if unexpected.is_empty():
		return ""
	return "%s/%s: modali non ammessi nello stato %d: %s" % [
		_profile_id,
		shot_name,
		current,
		", ".join(unexpected),
	]


func _visible_modals() -> Array[String]:
	var visible_modals: Array[String] = []
	if _upgrade_overlay != null and _upgrade_overlay.visible:
		visible_modals.append("upgrade")
	if _barb_overlay != null and _barb_overlay.visible:
		visible_modals.append("barb")
	if _boss_ui != null and _boss_ui.is_intro_visible():
		visible_modals.append("boss_intro")
	if _pause_overlay != null and _pause_overlay.visible:
		visible_modals.append("pause")
	if _end_screen != null and _end_screen.visible:
		visible_modals.append("end_screen")
	return visible_modals


func _allowed_modal_for_state(state: RunController.RunState) -> String:
	match state:
		RunController.RunState.LEVEL_UP:
			return "upgrade"
		RunController.RunState.BARB_REWARD:
			return "barb"
		RunController.RunState.BOSS_INTRO:
			return "boss_intro"
		RunController.RunState.MANUAL_PAUSE:
			return "pause"
		RunController.RunState.VICTORY, RunController.RunState.DEFEAT:
			return "end_screen"
		_:
			return ""


func _frames(count: int) -> void:
	for _index in count:
		await process_frame


func _timeout(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout
