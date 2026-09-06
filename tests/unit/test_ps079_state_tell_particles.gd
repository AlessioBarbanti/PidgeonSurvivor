extends GutGameplayTest

## PS-079 — Sostituisci il contorno bocciato con un particellare non aderente.
##
## Verifica il contratto del nuovo sistema che rimpiazza il contorno di
## PassiveStateOutline (PS-001/PS-029): le due fasi di ciascun personaggio
## restano distinguibili tramite l'API pubblica del tell, il flash da danno
## mantiene la precedenza sul particellare, l'animazione avanza solo in
## RUNNING, lo stato si azzera a restart e cambio personaggio, il numero di
## particelle resta contenuto, e il vecchio contorno non e' piu' agganciato
## a nulla.
##
## La leggibilita' percettiva reale (silhouette, densita' nemici, schermo
## Android) resta un gate manuale separato: qui si verificano solo le
## precondizioni strutturali osservabili senza leggere pixel.


func test_ps079_phase_tells_are_distinct_per_character() -> void:
	var context := await _build_context()
	if context.is_empty():
		return
	var player: Player = context["player"]
	var passive: FriendPassiveController = context["passive"]
	var registry: FriendRegistry = context["registry"]
	var controller: RunController = context["controller"]

	var aleo := registry.resolve_definition(&"aleo")
	assert_true(aleo != null, "Il profilo Aleo deve esistere.")
	if aleo != null:
		player.set_friend_definition(aleo)
		passive.equip_definition(aleo)
		var hot := player.get_passive_state_tell_color()
		assert_eq(hot, FriendPassiveController.TELL_ALEO_HOT, "Aleo deve avviarsi in fase calda.")
		player.get_health_component().take_damage(player.get_health_component().health_max * 0.7)
		passive._process(0.1)
		var cold := player.get_passive_state_tell_color()
		assert_eq(cold, FriendPassiveController.TELL_ALEO_COLD, "Sotto meta' vita Aleo deve passare alla fase fredda.")
		assert_true(hot != cold, "PS-079: le due fasi di Aleo devono restare cromaticamente distinte.")

	var lollo := registry.resolve_definition(&"lollo")
	assert_true(lollo != null, "Il profilo Lollo deve esistere.")
	if lollo != null:
		player.set_friend_definition(lollo)
		passive.equip_definition(lollo)
		var focused := player.get_passive_state_tell_color()
		assert_eq(focused, FriendPassiveController.TELL_LOLLO_FOCUSED, "Lollo deve avviarsi in iperfocus.")
		passive._process(passive.get_hyperfocus_remaining() + 0.01)
		var distracted := player.get_passive_state_tell_color()
		assert_eq(
			distracted, FriendPassiveController.TELL_LOLLO_DISTRACTED,
			"Alla scadenza dell'iperfocus il tell deve passare alla distrazione."
		)
		assert_true(focused != distracted, "PS-079: le due fasi di Lollo devono restare cromaticamente distinte.")

	var alea := registry.resolve_definition(&"alea")
	assert_true(alea != null, "Il profilo Alea deve esistere.")
	if alea != null:
		player.set_friend_definition(alea)
		passive.equip_definition(alea)
		assert_true(not player.has_passive_state_tell(), "Fuori da Brilla Alea non deve mostrare alcun tell.")
		passive._start_alea_brilla()
		assert_eq(
			player.get_passive_state_tell_color(), FriendPassiveController.TELL_ALEA_BRILLA,
			"PS-105: durante Brilla il tell di Alea deve essere il colore dedicato (non piu' una coppia positiva/negativa)."
		)

	var migi := registry.resolve_definition(&"migi")
	assert_true(migi != null, "Il profilo Migi deve esistere.")
	if migi != null:
		player.set_friend_definition(migi)
		passive.equip_definition(migi)
		var shell_ready := player.get_passive_state_tell_color()
		assert_eq(
			shell_ready, FriendPassiveController.TELL_MIGI_SHELL_READY,
			"Con cariche disponibili il tell di Migi deve essere quello del guscio piccolo."
		)
		passive._activate_migi_shield()
		var shield := player.get_passive_state_tell_color()
		assert_eq(
			shield, FriendPassiveController.TELL_MIGI_SHIELD,
			"Con lo scudo d'emergenza attivo il tell deve passare a quello dedicato."
		)
		assert_true(shell_ready != shield, "PS-079: le due fasi di Migi devono restare cromaticamente distinte.")

	controller.prepare_restart()


func test_ps079_damage_flash_takes_precedence_over_tell() -> void:
	var context := await _build_context()
	if context.is_empty():
		return
	var player: Player = context["player"]
	var passive: FriendPassiveController = context["passive"]
	var registry: FriendRegistry = context["registry"]
	var controller: RunController = context["controller"]

	var aleo := registry.resolve_definition(&"aleo")
	assert_true(aleo != null, "Il profilo Aleo deve esistere.")
	if aleo == null:
		return
	player.set_friend_definition(aleo)
	assert_true(passive.equip_definition(aleo), "La passiva deve accettare Aleo.")

	assert_true(
		player.is_passive_state_tell_effectively_visible(),
		"Fuori dal lampeggio da invulnerabilita' il tell deve risultare visibile."
	)

	var health := player.get_health_component()
	var blink_interval := PresentationTimings.PLAYER_DAMAGE_BLINK_INTERVAL_SECONDS
	# take_damage() concede l'invulnerabilita' alla durata base configurata
	# (player.tscn): e' la stessa via presa dal danno reale in gioco, a
	# differenza di grant_invulnerability() che accetterebbe una durata
	# arbitraria e sfaserebbe il calcolo del lampeggio.
	#
	# Gli offset restano a meta' strada fra i confini dei bucket di
	# floori(elapsed / blink_interval): un offset esatto sul confine
	# (1.0x, 2.0x...) rischia di cadere nel bucket sbagliato per un errore
	# di arrotondamento float sulla sottrazione (0.10 non e' esatto in
	# binario).
	health.take_damage(1.0)
	health.advance_invulnerability(blink_interval * 1.5)
	assert_true(
		not player.is_damage_blink_visible(),
		"Il fixture deve trovarsi in un frame di lampeggio invisibile per verificare la precedenza."
	)
	assert_true(
		not player.is_passive_state_tell_effectively_visible(),
		"PS-079: il flash da danno deve mantenere la precedenza e nascondere il tell durante il lampeggio."
	)

	health.advance_invulnerability(blink_interval)
	assert_true(player.is_damage_blink_visible(), "Il fixture deve tornare a un frame di lampeggio visibile.")
	assert_true(
		player.is_passive_state_tell_effectively_visible(),
		"PS-079: fuori dal frame di lampeggio invisibile il tell deve ricomparire."
	)

	controller.prepare_restart()


func test_ps079_particles_advance_only_while_running() -> void:
	var context := await _build_context()
	if context.is_empty():
		return
	var player: Player = context["player"]
	var passive: FriendPassiveController = context["passive"]
	var registry: FriendRegistry = context["registry"]
	var controller: RunController = context["controller"]

	var aleo := registry.resolve_definition(&"aleo")
	assert_true(aleo != null, "Il profilo Aleo deve esistere.")
	if aleo == null:
		return
	player.set_friend_definition(aleo)
	assert_true(passive.equip_definition(aleo), "La passiva deve accettare Aleo.")

	var angle_running := player.get_passive_state_particles_orbit_angle()
	passive._process(0.2)
	assert_true(
		player.get_passive_state_particles_orbit_angle() != angle_running,
		"PS-079: in RUNNING l'orbita delle particelle deve avanzare."
	)

	assert_true(controller.request_manual_pause(), "La pausa manuale deve riuscire.")
	assert_true(
		not player.is_passive_state_tell_presented(),
		"PS-079: il tell deve sparire durante la pausa."
	)
	var angle_paused := player.get_passive_state_particles_orbit_angle()
	passive._process(0.2)
	assert_almost_eq(
		player.get_passive_state_particles_orbit_angle(), angle_paused, FLOAT_TOLERANCE,
		"PS-079: fuori da RUNNING l'orbita delle particelle non deve avanzare."
	)

	assert_true(controller.resume_run(), "La ripresa deve riuscire.")
	assert_true(
		player.is_passive_state_tell_presented(),
		"PS-079: il tell deve riapparire alla ripresa della run."
	)

	controller.prepare_restart()


func test_ps079_tell_resets_on_restart_and_character_change() -> void:
	var context := await _build_context()
	if context.is_empty():
		return
	var player: Player = context["player"]
	var passive: FriendPassiveController = context["passive"]
	var registry: FriendRegistry = context["registry"]
	var controller: RunController = context["controller"]

	var aleo := registry.resolve_definition(&"aleo")
	var migi := registry.resolve_definition(&"migi")
	assert_true(aleo != null and migi != null, "I profili Aleo e Migi devono esistere.")
	if aleo == null or migi == null:
		return

	player.set_friend_definition(aleo)
	assert_true(passive.equip_definition(aleo), "La passiva deve accettare Aleo.")
	player.get_health_component().take_damage(player.get_health_component().health_max * 0.7)
	passive._process(0.1)
	assert_eq(
		player.get_passive_state_tell_color(), FriendPassiveController.TELL_ALEO_COLD,
		"Aleo deve trovarsi in fase fredda prima del cambio personaggio."
	)

	# Cambio personaggio (selezione): il tell del profilo precedente non deve
	# restare agganciato, la nuova passiva riparte dalla sua fase iniziale.
	player.set_friend_definition(migi)
	assert_true(passive.equip_definition(migi), "La passiva deve accettare Migi dopo il cambio personaggio.")
	assert_eq(
		player.get_passive_state_tell_color(), FriendPassiveController.TELL_MIGI_SHELL_READY,
		"PS-079: il cambio personaggio deve azzerare il tell precedente e presentare la fase iniziale del nuovo."
	)

	assert_true(controller.prepare_restart(), "Il restart deve tornare in BOOT.")
	assert_true(
		not player.is_passive_state_tell_presented(),
		"PS-079: il tell deve restare nascosto in BOOT dopo il restart."
	)

	assert_true(controller.start_run(4713), "La nuova run deve poter partire.")
	player.set_friend_definition(migi)
	assert_true(passive.equip_definition(migi), "La passiva deve accettare Migi nella nuova run.")
	assert_eq(
		player.get_passive_state_tell_color(), FriendPassiveController.TELL_MIGI_SHELL_READY,
		"PS-079: la nuova run deve ripresentare la fase iniziale della passiva."
	)

	controller.prepare_restart()


func test_ps079_particle_count_stays_bounded() -> void:
	# Un solo Player, non un'orda (vedi criteri di accettazione): nessuna
	# scala per PerformanceProfile e' richiesta, ma il conteggio resta
	# comunque piccolo per costruzione.
	assert_true(
		PassiveStateParticles.PARTICLE_COUNT > 0 and PassiveStateParticles.PARTICLE_COUNT <= 8,
		"PS-079: il numero di particelle del tell deve restare piccolo per un singolo Player."
	)


func test_ps079_outline_system_is_no_longer_hooked() -> void:
	var context := await _build_context()
	if context.is_empty():
		return
	var player: Player = context["player"]

	assert_true(
		not ResourceLoader.exists("res://scripts/vfx/passive_state_outline.gd"),
		"PS-079: PassiveStateOutline deve essere stato rimosso, non solo scollegato."
	)
	assert_true(
		not player.has_method(&"set_passive_state_outline")
		and not player.has_method(&"clear_passive_state_outline")
		and not player.has_method(&"get_passive_state_outline_color")
		and not player.has_method(&"has_passive_state_outline"),
		"PS-079: il Player non deve piu' esporre gli agganci del vecchio contorno."
	)

	print("STATE_TELL_PARTICLES_SMOKE_OK")


func _build_context() -> Dictionary:
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_run_controller() as RunController
	var registry := movement_slice.get_friend_registry() as FriendRegistry
	var player := movement_slice.get_player() as Player
	var passive := movement_slice.get_friend_passive_controller() as FriendPassiveController
	if controller == null or registry == null or player == null or passive == null:
		assert_true(false, "La scena di run deve esporre le dipendenze PS-079.")
		return {}

	controller.set_process(false)
	player.set_physics_process(false)
	passive.set_process(false)
	controller.start_run(4711)
	return {
		"slice": movement_slice,
		"controller": controller,
		"registry": registry,
		"player": player,
		"passive": passive,
	}
