extends GutGameplayTest

## PS-099 — Sostituisci il particellare di Lollo e Aleo con aura di
## potenziamento e tell termico.
##
## Copre il contratto specifico dei tre nuovi VFX (PS-098): l'aura di
## potenziamento di Lollo compare solo in iperfocus e sparisce in
## distrazione, l'aura a terra di Aleo distingue le due modalita' e resta
## persistente, il termometro annuncia il passaggio e scade da solo, il
## flash da danno mantiene la precedenza su tutti e tre, avanzano solo in
## `RunController.RUNNING`, restart e cambio personaggio azzerano ogni
## residuo, e Alea/Migi restano invariati sul particellare di PS-079.

const RUN_SEED := 5501


func test_lollo_aura_visible_only_during_hyperfocus() -> void:
	var context := await _build_context()
	if context.is_empty():
		return
	var player: Player = context["player"]
	var passive: FriendPassiveController = context["passive"]
	var registry: FriendRegistry = context["registry"]
	var controller: RunController = context["controller"]

	var lollo := registry.resolve_definition(&"lollo")
	assert_true(lollo != null, "Il profilo Lollo deve esistere.")
	if lollo == null:
		return
	player.set_friend_definition(lollo)
	assert_true(passive.equip_definition(lollo), "La passiva deve accettare Lollo.")

	assert_true(passive.is_hyperfocused(), "Lollo deve avviarsi in iperfocus.")
	assert_true(player.is_hyperfocus_aura_presented(), "L'aura deve essere attiva in iperfocus.")

	passive._process(passive.get_hyperfocus_remaining() + 0.01)
	assert_true(not passive.is_hyperfocused(), "Deve passare in distrazione.")
	assert_false(
		player.is_hyperfocus_aura_presented(),
		"Scelta esplicita del proprietario: la distrazione non presenta alcun tell."
	)

	passive._process(passive.get_hyperfocus_remaining() + 0.01)
	assert_true(passive.is_hyperfocused(), "Deve tornare in iperfocus.")
	assert_true(player.is_hyperfocus_aura_presented(), "L'aura deve riaccendersi al ritorno in iperfocus.")

	controller.prepare_restart()


func test_aleo_ground_aura_and_transition_announcement() -> void:
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
		player.is_thermal_ground_aura_presented() and player.is_thermal_ground_aura_hot(),
		"Aleo deve avviarsi con l'aura calda."
	)
	assert_false(
		player.is_thermal_transition_announcement_presented(),
		"L'avvio non e' un passaggio: nessun termometro all'equip iniziale."
	)

	# Passaggio caldo -> freddo: l'aura cambia soggetto e il termometro
	# annuncia il momento del cambio.
	player.get_health_component().take_damage(player.get_health_component().health_max * 0.7)
	passive._process(0.1)
	assert_true(
		player.is_thermal_ground_aura_presented() and not player.is_thermal_ground_aura_hot(),
		"Sotto meta' vita l'aura deve diventare fredda."
	)
	assert_true(
		player.is_thermal_transition_announcement_presented()
		and not player.is_thermal_transition_announcement_hot(),
		"Il termometro freddo deve comparire esattamente al passaggio."
	)

	# Il termometro scade da solo, l'aura a terra resta.
	passive._process(PresentationTimings.THERMAL_TRANSITION_ANNOUNCE_SECONDS + 0.05)
	assert_false(
		player.is_thermal_transition_announcement_presented(),
		"Il termometro non e' persistente: deve scadere da solo."
	)
	assert_true(
		player.is_thermal_ground_aura_presented() and not player.is_thermal_ground_aura_hot(),
		"L'aura a terra resta il tell persistente anche dopo la scadenza del termometro."
	)

	# Passaggio freddo -> caldo: stesso contratto nella direzione opposta.
	player.get_health_component().heal(player.get_health_component().health_max)
	passive._process(0.1)
	assert_true(
		player.is_thermal_ground_aura_presented() and player.is_thermal_ground_aura_hot(),
		"Curandosi Aleo deve tornare all'aura calda."
	)
	assert_true(
		player.is_thermal_transition_announcement_presented()
		and player.is_thermal_transition_announcement_hot(),
		"Il termometro caldo deve comparire al passaggio inverso."
	)

	controller.prepare_restart()


## Il ground aura di Aleo riusa lo stesso principio (verificato in
## `test_ps079_damage_flash_takes_precedence_over_tell`, aggiornato da
## questa stessa card): qui si copre quanto e' specifico di questo file,
## l'aura di Lollo.
func test_damage_flash_takes_precedence_over_lollo_aura() -> void:
	var context := await _build_context()
	if context.is_empty():
		return
	var player: Player = context["player"]
	var passive: FriendPassiveController = context["passive"]
	var registry: FriendRegistry = context["registry"]
	var controller: RunController = context["controller"]

	var lollo := registry.resolve_definition(&"lollo")
	assert_true(lollo != null, "Il profilo Lollo deve esistere.")
	if lollo == null:
		return
	player.set_friend_definition(lollo)
	assert_true(passive.equip_definition(lollo), "La passiva deve accettare Lollo.")
	assert_true(
		player.is_hyperfocus_aura_effectively_visible(),
		"Fuori dal lampeggio da invulnerabilita' l'aura di Lollo deve risultare visibile."
	)

	var health := player.get_health_component()
	var blink_interval := PresentationTimings.PLAYER_DAMAGE_BLINK_INTERVAL_SECONDS
	health.take_damage(1.0)
	health.advance_invulnerability(blink_interval * 1.5)
	assert_true(
		not player.is_damage_blink_visible(),
		"Il fixture deve trovarsi in un frame di lampeggio invisibile per verificare la precedenza."
	)
	assert_true(
		not player.is_hyperfocus_aura_effectively_visible(),
		"PS-099: il flash da danno deve nascondere l'aura di Lollo durante il lampeggio."
	)
	health.advance_invulnerability(blink_interval)
	assert_true(
		player.is_hyperfocus_aura_effectively_visible(),
		"PS-099: fuori dal frame di lampeggio invisibile l'aura deve ricomparire."
	)

	controller.prepare_restart()


## Fixture separata dal test precedente: l'invulnerabilita' concessa li'
## resterebbe attiva e impedirebbe al danno sotto di applicarsi davvero,
## mascherando il passaggio caldo->freddo che questo test deve osservare.
func test_damage_flash_takes_precedence_over_thermometer() -> void:
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
	var health := player.get_health_component()
	health.take_damage(health.health_max * 0.7)
	passive._process(0.1)
	assert_true(
		player.is_thermal_transition_announcement_presented(), "Serve un annuncio attivo per verificare la precedenza."
	)
	assert_true(
		player.is_thermal_transition_announcement_effectively_visible(),
		"Fuori dal lampeggio da invulnerabilita' il termometro deve risultare visibile."
	)

	health.clear_invulnerability()
	var blink_interval := PresentationTimings.PLAYER_DAMAGE_BLINK_INTERVAL_SECONDS
	health.take_damage(1.0)
	health.advance_invulnerability(blink_interval * 1.5)
	assert_true(
		not player.is_damage_blink_visible(),
		"Il fixture deve trovarsi in un frame di lampeggio invisibile per verificare la precedenza."
	)
	assert_true(
		not player.is_thermal_transition_announcement_effectively_visible(),
		"PS-099: il flash da danno deve nascondere il termometro durante il lampeggio."
	)
	health.advance_invulnerability(blink_interval)
	assert_true(
		player.is_thermal_transition_announcement_effectively_visible(),
		"PS-099: fuori dal frame di lampeggio invisibile il termometro deve ricomparire."
	)

	controller.prepare_restart()


func test_new_tells_advance_only_while_running() -> void:
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
	player.get_health_component().take_damage(player.get_health_component().health_max * 0.7)
	passive._process(0.1)
	assert_true(
		player.is_thermal_transition_announcement_presented(), "Serve un annuncio attivo per verificare il congelamento."
	)

	assert_true(controller.request_manual_pause(), "La pausa manuale deve riuscire.")
	assert_false(
		player.is_thermal_ground_aura_presented(),
		"L'aura a terra deve nascondersi durante la pausa."
	)
	# Il countdown del termometro non deve avanzare (ne' scadere) mentre e'
	# nascosto in pausa: deve restare congelato, pronto a riapparire.
	passive._process(PresentationTimings.THERMAL_TRANSITION_ANNOUNCE_SECONDS + 0.05)
	assert_true(controller.resume_run(), "La ripresa deve riuscire.")
	assert_true(
		player.is_thermal_transition_announcement_presented(),
		"Il countdown del termometro deve restare congelato (non scaduto) durante la pausa."
	)
	assert_true(
		player.is_thermal_ground_aura_presented(), "L'aura a terra deve ricomparire alla ripresa."
	)

	controller.prepare_restart()


func test_reset_clears_new_tells_on_restart_and_character_change() -> void:
	var context := await _build_context()
	if context.is_empty():
		return
	var player: Player = context["player"]
	var passive: FriendPassiveController = context["passive"]
	var registry: FriendRegistry = context["registry"]
	var controller: RunController = context["controller"]

	var aleo := registry.resolve_definition(&"aleo")
	var lollo := registry.resolve_definition(&"lollo")
	assert_true(aleo != null and lollo != null, "I profili Aleo e Lollo devono esistere.")
	if aleo == null or lollo == null:
		return

	player.set_friend_definition(aleo)
	assert_true(passive.equip_definition(aleo), "La passiva deve accettare Aleo.")
	player.get_health_component().take_damage(player.get_health_component().health_max * 0.7)
	passive._process(0.1)
	assert_true(player.is_thermal_transition_announcement_presented(), "Deve esserci un annuncio attivo da azzerare.")

	# Cambio personaggio: nessun residuo di Aleo deve sopravvivere su Lollo.
	player.set_friend_definition(lollo)
	assert_true(passive.equip_definition(lollo), "La passiva deve accettare Lollo dopo il cambio.")
	assert_false(player.is_thermal_ground_aura_presented(), "Il cambio personaggio deve spegnere l'aura a terra di Aleo.")
	assert_false(
		player.is_thermal_transition_announcement_presented(),
		"Il cambio personaggio deve azzerare un termometro residuo, non lasciarlo scadere da solo."
	)
	assert_true(player.is_hyperfocus_aura_presented(), "Lollo deve ripartire in iperfocus.")

	assert_true(controller.prepare_restart(), "Il restart deve tornare in BOOT.")
	assert_false(player.is_hyperfocus_aura_presented(), "In BOOT nessun tell deve restare visibile.")

	assert_true(controller.start_run(RUN_SEED + 1), "La nuova run deve poter partire.")
	player.set_friend_definition(aleo)
	assert_true(passive.equip_definition(aleo), "La passiva deve accettare Aleo nella nuova run.")
	assert_true(
		player.is_thermal_ground_aura_presented() and player.is_thermal_ground_aura_hot(),
		"La nuova run deve ripresentare Aleo alla fase calda iniziale."
	)
	assert_false(
		player.is_thermal_transition_announcement_presented(),
		"La nuova run non deve ereditare un termometro dalla run precedente."
	)

	controller.prepare_restart()


func test_alea_and_migi_particle_tell_unchanged() -> void:
	var context := await _build_context()
	if context.is_empty():
		return
	var player: Player = context["player"]
	var passive: FriendPassiveController = context["passive"]
	var registry: FriendRegistry = context["registry"]
	var controller: RunController = context["controller"]

	var alea := registry.resolve_definition(&"alea")
	assert_true(alea != null, "Il profilo Alea deve esistere.")
	if alea != null:
		player.set_friend_definition(alea)
		assert_true(passive.equip_definition(alea), "La passiva deve accettare Alea.")
		assert_true(not player.has_passive_state_tell(), "Fuori da Brilla Alea non deve mostrare alcun tell.")
		passive._start_alea_brilla()
		assert_true(
			player.has_passive_state_tell()
			and player.get_passive_state_tell_color() == FriendPassiveController.TELL_ALEA_BRILLA,
			"PS-099 non deve toccare il particellare di Alea."
		)
		assert_false(
			player.is_hyperfocus_aura_presented() or player.is_thermal_ground_aura_presented(),
			"Alea non deve mai attivare i nuovi tell di Lollo/Aleo."
		)

	var migi := registry.resolve_definition(&"migi")
	assert_true(migi != null, "Il profilo Migi deve esistere.")
	if migi != null:
		player.set_friend_definition(migi)
		assert_true(passive.equip_definition(migi), "La passiva deve accettare Migi.")
		assert_eq(
			player.get_passive_state_tell_color(), FriendPassiveController.TELL_MIGI_SHELL_READY,
			"PS-099 non deve toccare il particellare di Migi."
		)
		assert_false(
			player.is_hyperfocus_aura_presented() or player.is_thermal_ground_aura_presented(),
			"Migi non deve mai attivare i nuovi tell di Lollo/Aleo."
		)

	print("STATE_TELL_AURA_SMOKE_OK")
	controller.prepare_restart()


func _build_context() -> Dictionary:
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_run_controller() as RunController
	var registry := movement_slice.get_friend_registry() as FriendRegistry
	var player := movement_slice.get_player() as Player
	var passive := movement_slice.get_friend_passive_controller() as FriendPassiveController
	if controller == null or registry == null or player == null or passive == null:
		assert_true(false, "La scena di run deve esporre le dipendenze PS-099.")
		return {}

	controller.set_process(false)
	player.set_physics_process(false)
	passive.set_process(false)
	controller.start_run(RUN_SEED)
	return {
		"slice": movement_slice,
		"controller": controller,
		"registry": registry,
		"player": player,
		"passive": passive,
	}
