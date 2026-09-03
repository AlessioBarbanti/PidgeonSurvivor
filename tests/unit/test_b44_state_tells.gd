extends GutGameplayTest

## B44 — Tell di stato e fasi: Aleo e Lollo.
##
## Verifica che lo stato termico di Aleo sia leggibile e che la fase fredda
## eroda davvero i nemici brinati, che le kill accorcino la distrazione di
## Lollo senza toccare l'iperfocus, e che il Cosplay sia deciso in anticipo e
## quindi pianificabile invece che risolto al momento del lancio.


func test_aleo_thermal_state() -> void:
	var context := await _build_context()
	if context.is_empty():
		return
	var controller: RunController = context["controller"]
	var registry: FriendRegistry = context["registry"]
	var player: Player = context["player"]
	var passive: FriendPassiveController = context["passive"]
	var spawner: EnemySpawner = context["spawner"]

	var aleo := registry.resolve_definition(&"aleo")
	assert_true(aleo != null, "Il profilo Aleo deve esistere.")
	if aleo == null:
		return
	player.set_friend_definition(aleo)
	assert_true(passive.equip_definition(aleo), "La passiva deve accettare Aleo.")

	var cold_dps := aleo.get_passive_float(&"cold_aura_damage_per_second", 0.0, 0.0)
	var tick_interval := aleo.get_passive_float(&"cold_aura_tick_interval", 0.25, 0.001)
	var aura_radius := aleo.get_passive_float(&"cold_aura_radius", 0.0, 0.0)
	assert_true(cold_dps > 0.0, "La fase fredda deve dichiarare una componente offensiva.")

	# Sopra meta' vita: modalita' calda, tell caldo, nessun danno d'aura.
	passive._process(0.1)
	assert_true(passive.is_thermal_hot(), "Sopra meta' vita Aleo deve essere in riscaldamento.")
	assert_true(
		player.get_passive_state_tell_color() == FriendPassiveController.TELL_ALEO_HOT,
		"Il tell caldo deve essere attivo sopra la soglia."
	)
	# PS-001/PS-079: il tell vive nel particellare, non nello sprite. Se questa
	# cade, la tinta piena e' rientrata dalla finestra e il personaggio torna a
	# essere ridipinto.
	assert_true(
		player.get_character_self_modulate() == Color.WHITE,
		"Lo sprite del personaggio non deve essere ridipinto dal tell di stato."
	)
	assert_true(
		player.is_passive_state_tell_presented(), "Il tell deve risultare attivo quando la fase e' dichiarata."
	)

	var enemy := spawner.try_spawn_enemy()
	assert_true(enemy != null, "Serve un bersaglio fixture per l'aura fredda.")
	if enemy == null:
		return
	enemy.set_physics_process(false)
	enemy.global_position = player.global_position + Vector2(aura_radius * 0.5, 0.0)

	var health_before := enemy.get_health_component().health_current
	passive._process(tick_interval * 2.0)
	assert_almost_eq(
		enemy.get_health_component().health_current, health_before, FLOAT_TOLERANCE,
		"In riscaldamento l'aura non deve infliggere danno."
	)

	# Sotto meta' vita: modalita' fredda, tell freddo, brina e danno periodico.
	var player_health := player.get_health_component()
	player_health.take_damage(player_health.health_max * 0.7)
	passive._process(0.1)
	assert_true(not passive.is_thermal_hot(), "Sotto meta' vita Aleo deve passare in raffrescamento.")
	assert_true(
		player.get_passive_state_tell_color() == FriendPassiveController.TELL_ALEO_COLD,
		"Il tell freddo deve essere attivo sotto la soglia."
	)
	assert_eq(passive.get_chilled_target_count(), 1, "Il bersaglio dentro il raggio deve risultare brinato.")
	assert_true(enemy.get_speed_multiplier() < 1.0, "La brina deve continuare a rallentare il bersaglio.")

	health_before = enemy.get_health_component().health_current
	passive._process(tick_interval)
	assert_true(
		enemy.get_health_component().health_current < health_before, "La fase fredda deve erodere i nemici brinati."
	)

	# Il tick non avanza fuori da RUNNING.
	assert_true(controller.request_manual_pause(), "La pausa manuale deve riuscire.")
	health_before = enemy.get_health_component().health_current
	passive._process(tick_interval * 4.0)
	assert_almost_eq(
		enemy.get_health_component().health_current, health_before, FLOAT_TOLERANCE,
		"L'aura fredda non deve avanzare fuori da RUNNING."
	)
	assert_true(
		not player.is_passive_state_tell_presented(),
		"Il tell di stato deve sparire durante la pausa."
	)
	assert_true(controller.resume_run(), "La ripresa deve riuscire.")
	assert_true(
		player.is_passive_state_tell_presented(),
		"Il tell di stato deve riapparire alla ripresa della run."
	)

	# Tornando sopra la soglia l'accumulatore si azzera e la brina sparisce.
	player_health.heal(player_health.health_max)
	passive._process(0.1)
	assert_true(passive.is_thermal_hot(), "Curandosi Aleo deve tornare in riscaldamento.")
	assert_almost_eq(
		passive.get_cold_damage_accumulator(), 0.0, FLOAT_TOLERANCE,
		"Il rientro in riscaldamento deve azzerare l'accumulatore."
	)
	assert_eq(passive.get_chilled_target_count(), 0, "Il rientro in riscaldamento deve sciogliere la brina.")

	assert_true(controller.prepare_restart(), "Il restart deve tornare in BOOT.")
	assert_true(
		not player.is_passive_state_tell_presented(),
		"Il tell di stato deve restare nascosto in BOOT dopo il restart."
	)
	assert_true(controller.start_run(4712), "La nuova run deve poter partire.")
	assert_true(passive.is_thermal_hot(), "Il restart deve azzerare Aleo alla fase calda iniziale.")
	assert_true(
		player.is_passive_state_tell_presented()
		and player.get_passive_state_tell_color() == FriendPassiveController.TELL_ALEO_HOT,
		"La nuova run deve ripresentare il tell della fase iniziale."
	)
	controller.prepare_restart()


func test_lollo_distraction() -> void:
	var context := await _build_context()
	if context.is_empty():
		return
	var controller: RunController = context["controller"]
	var registry: FriendRegistry = context["registry"]
	var player: Player = context["player"]
	var passive: FriendPassiveController = context["passive"]
	var spawner: EnemySpawner = context["spawner"]

	var lollo := registry.resolve_definition(&"lollo")
	assert_true(lollo != null, "Il profilo Lollo deve esistere.")
	if lollo == null:
		return
	player.set_friend_definition(lollo)
	assert_true(passive.equip_definition(lollo), "La passiva deve accettare Lollo.")

	var reduction := lollo.get_passive_float(&"distraction_seconds_per_kill", 0.0, 0.0)
	assert_true(reduction > 0.0, "Lollo deve dichiarare una riduzione della distrazione per kill.")

	# In iperfocus il tell e' quello focalizzato e le kill non accorciano nulla.
	assert_true(passive.is_hyperfocused(), "Lollo deve avviare la run in iperfocus.")
	assert_true(
		player.get_passive_state_tell_color() == FriendPassiveController.TELL_LOLLO_FOCUSED,
		"Il tell di iperfocus deve essere attivo."
	)
	var focus_before := passive.get_hyperfocus_remaining()
	var focus_enemy := spawner.try_spawn_enemy()
	if focus_enemy != null:
		focus_enemy.set_physics_process(false)
		focus_enemy.take_damage(9999.0)
		await wait_process_frames(1)
	assert_almost_eq(
		passive.get_hyperfocus_remaining(), focus_before, FLOAT_TOLERANCE,
		"Le kill non devono accorciare la fase di iperfocus."
	)

	# Passaggio in distrazione: tell distratto e kill che accorciano la fase.
	passive._process(passive.get_hyperfocus_remaining() + 0.01)
	assert_true(not passive.is_hyperfocused(), "Alla scadenza Lollo deve passare in distrazione.")
	assert_true(
		player.get_passive_state_tell_color() == FriendPassiveController.TELL_LOLLO_DISTRACTED,
		"Il tell di distrazione deve essere attivo."
	)

	var distracted_before := passive.get_hyperfocus_remaining()
	var kill_enemy := spawner.try_spawn_enemy()
	assert_true(kill_enemy != null, "Serve un bersaglio fixture per la kill di Lollo.")
	if kill_enemy != null:
		kill_enemy.set_physics_process(false)
		kill_enemy.take_damage(9999.0)
		await wait_process_frames(1)
		assert_almost_eq(
			passive.get_hyperfocus_remaining(), maxf(distracted_before - reduction, 0.0), FLOAT_TOLERANCE,
			"Una kill deve accorciare la distrazione della quota dichiarata."
		)

	# La distrazione resta una fase reale: non puo' andare sotto zero.
	for _index in range(200):
		passive._shorten_lollo_distraction()
	assert_true(passive.get_hyperfocus_remaining() >= 0.0, "La distrazione non puo' diventare negativa.")

	controller.prepare_restart()


func test_pending_cosplay() -> void:
	var context := await _build_context()
	if context.is_empty():
		return
	var controller: RunController = context["controller"]
	var registry: FriendRegistry = context["registry"]
	var player: Player = context["player"]
	var passive: FriendPassiveController = context["passive"]
	var movement_slice: Control = context["slice"]
	var ability := movement_slice.get_ability_controller() as AbilityController
	var effects := movement_slice.get_ability_effect_registry() as AbilityEffectRegistry
	assert_true(ability != null and effects != null, "Servono controller e registry delle attive.")
	if ability == null or effects == null:
		return

	var lollo := registry.resolve_definition(&"lollo")
	if lollo == null:
		return
	player.set_friend_definition(lollo)
	passive.equip_definition(lollo)
	var cosplay := effects.resolve_definition(lollo.active_ability_id)
	assert_true(cosplay != null, "L'attiva di Lollo deve essere risolvibile.")
	if cosplay == null:
		return
	assert_true(ability.equip_definition(cosplay), "Il controller deve equipaggiare Cosplay.")

	# Il tiro e' gia' risolto prima del lancio: e' cio' che rende l'attiva
	# pianificabile invece che casuale al momento dell'uso.
	var pending := ability.get_pending_cosplay_ability_id()
	assert_true(not pending.is_empty(), "Il prossimo Cosplay deve essere deciso in anticipo.")
	assert_true(pending != lollo.active_ability_id, "Il Cosplay non puo' avere se stesso come bersaglio.")
	assert_true(
		effects.get_pending_cosplay_ability_id() == pending,
		"Controller e registry devono esporre la stessa scelta pendente."
	)

	# Il pulsante HUD resta senza nome (B18K): il tell di pianificabilita'
	# passa dal mostrare l'icona del bersaglio invece di quella di Cosplay.
	var hud := movement_slice.get_hud() as GameHud
	assert_true(hud != null, "La HUD deve essere accessibile per verificare il tell del Cosplay.")
	var pending_icon := ability.get_pending_cosplay_icon()
	assert_true(pending_icon != null, "Il prossimo Cosplay deve avere un'icona risolvibile.")
	if hud != null:
		var button := hud.get_active_ability_button()
		assert_true(
			button != null and pending_icon != null and button.get_ability_icon() == pending_icon,
			"Il pulsante deve mostrare l'icona del prossimo Cosplay invece di quella generica."
		)

	# La scelta pendente e' stabile: non cambia finche' non viene consumata.
	assert_true(
		ability.get_pending_cosplay_ability_id() == pending, "La scelta pendente non deve cambiare fra due letture."
	)

	# Il lancio consuma esattamente la scelta annunciata e ne prepara subito
	# un'altra, cosi' l'HUD ha sempre qualcosa da mostrare.
	assert_true(ability.try_activate(), "Cosplay deve essere eseguibile.")
	assert_true(
		effects.get_last_copied_ability_id() == pending, "Il lancio deve eseguire esattamente l'abilita' annunciata."
	)
	var next_pending := ability.get_pending_cosplay_ability_id()
	assert_true(not next_pending.is_empty(), "Dopo il lancio deve essere pronta una nuova scelta.")
	if hud != null:
		var button := hud.get_active_ability_button()
		var next_icon := ability.get_pending_cosplay_icon()
		assert_true(
			button != null and next_icon != null and button.get_ability_icon() == next_icon,
			"Dopo il lancio il pulsante deve aggiornarsi alla nuova icona pendente."
		)

	# Determinismo per seed: la stessa run rifatta annuncia la stessa scelta.
	var first_pending := pending
	controller.prepare_restart()
	controller.start_run(4711)
	player.set_friend_definition(lollo)
	passive.equip_definition(lollo)
	ability.equip_definition(cosplay)
	assert_true(
		not ability.get_pending_cosplay_ability_id().is_empty(),
		"Anche dopo il restart il prossimo Cosplay deve essere annunciato."
	)
	assert_true(not first_pending.is_empty(), "La prima scelta annunciata deve essere valida.")

	# Un profilo senza Cosplay non espone alcuna scelta pendente.
	var magno := registry.resolve_definition(&"magno")
	var magno_ability := effects.resolve_definition(magno.active_ability_id)
	if magno_ability != null:
		ability.equip_definition(magno_ability)
		assert_true(
			ability.get_pending_cosplay_ability_id().is_empty()
			or effects.resolve_definition(ability.get_pending_cosplay_ability_id()) != null,
			"Un profilo senza Cosplay non deve annunciare una scelta invalida."
		)

	controller.prepare_restart()


## Nel gioco reale il profilo si equipaggia nella selezione personaggio, cioe'
## a run ferma: l'estrazione anticipata deve esserci gia' al primo lancio,
## altrimenti il pulsante mostra l'icona generica e il primo Cosplay torna a
## essere un tiro cieco.
func test_pending_cosplay_before_run() -> void:
	var context := await _build_context(false)
	if context.is_empty():
		return
	var controller: RunController = context["controller"]
	var registry: FriendRegistry = context["registry"]
	var movement_slice: Control = context["slice"]
	var ability := movement_slice.get_ability_controller() as AbilityController
	var effects := movement_slice.get_ability_effect_registry() as AbilityEffectRegistry
	var hud := movement_slice.get_hud() as GameHud
	var lollo := registry.resolve_definition(&"lollo")
	var cosplay: AbilityDefinition = effects.resolve_definition(lollo.active_ability_id) if lollo != null else null
	assert_true(
		ability != null and effects != null and hud != null and cosplay != null,
		"Servono controller, registry, HUD e Cosplay per la verifica pre-run."
	)
	if ability == null or effects == null or hud == null or cosplay == null:
		return

	controller.prepare_restart()
	assert_true(ability.equip_definition(cosplay), "Il Cosplay deve essere equipaggiabile a run ferma.")
	assert_true(
		not ability.get_pending_cosplay_ability_id().is_empty(),
		"L'estrazione deve essere annunciata gia' nella selezione personaggio."
	)
	assert_true(controller.start_run(4711), "La run deve poter partire dopo l'equip.")

	# Il tiro viene rifatto con l'RNG della run: resta deterministico per seed.
	var pending := ability.get_pending_cosplay_ability_id()
	assert_true(not pending.is_empty(), "Anche il primo lancio deve avere un'estrazione annunciata.")
	var button := hud.get_active_ability_button()
	var pending_icon := ability.get_pending_cosplay_icon()
	assert_true(
		button != null and pending_icon != null and button.get_ability_icon() == pending_icon,
		"Il pulsante deve mostrare il bersaglio annunciato gia' al primo lancio."
	)
	assert_true(ability.try_activate(), "Il primo Cosplay deve essere eseguibile.")
	assert_true(
		effects.get_last_copied_ability_id() == pending, "Il primo lancio deve eseguire esattamente l'abilita' annunciata."
	)
	assert_true(effects.get_active_effect_count() > 0, "Il primo Cosplay deve produrre un effetto reale in scena.")

	controller.prepare_restart()


func _build_context(start_run := true) -> Dictionary:
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_run_controller() as RunController
	var registry := movement_slice.get_friend_registry() as FriendRegistry
	var player := movement_slice.get_player() as Player
	var passive := movement_slice.get_friend_passive_controller() as FriendPassiveController
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	if controller == null or registry == null or player == null or passive == null or spawner == null:
		assert_true(false, "La scena di run deve esporre le dipendenze B44.")
		return {}

	controller.set_process(false)
	spawner.set_process(false)
	player.set_physics_process(false)
	passive.set_process(false)
	if start_run:
		controller.start_run(4711)
	return {
		"slice": movement_slice,
		"controller": controller,
		"registry": registry,
		"player": player,
		"passive": passive,
		"spawner": spawner,
	}
