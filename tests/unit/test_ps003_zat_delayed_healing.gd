extends GutGameplayTest

## PS-003 — Contratto runtime di Guarigione Ritardata (passiva di Zat).
##
## Questo file non introduce comportamento: fotografa quello esistente perche'
## PS-004 (Tempesta di Tuoni legata al danno recuperabile) possa dipendere da
## una quota di HP recuperabili definita invece che presunta. Ogni asserzione
## corrisponde a una voce dei criteri di accettazione della card.
##
## I parametri vivono in data/friends/zat.tres e sono letti qui dalla
## definizione: se il bilanciamento cambia, il contratto resta valido e a
## cambiare sono solo i numeri.

const ZAT_ID := &"zat"
const OTHER_FRIEND_ID := &"magno"
const FIXTURE_DAMAGE := 20.0


func test_ps003_singolo_colpo_quota_attesa_e_ritmo() -> void:
	var context := await _build_zat_context()
	if context.is_empty():
		return
	var player: Player = context["player"]
	var passive: FriendPassiveController = context["passive"]
	var health: HealthComponent = context["health"]
	var fraction: float = context["fraction"]
	var delay: float = context["delay"]
	var duration: float = context["duration"]

	assert_true(_hit(player, health, FIXTURE_DAMAGE), "Zat deve ricevere il danno fixture.")
	var expected := FIXTURE_DAMAGE * fraction
	assert_almost_eq(
		passive.get_recoverable_health(), expected, FLOAT_TOLERANCE,
		"PS-003: la quota recuperabile e' la frazione dichiarata del danno applicato."
	)

	# L'attesa e' un tempo morto: nessun HP torna indietro finche' non scade.
	var damaged_health := health.health_current
	passive._process(delay)
	assert_almost_eq(
		health.health_current, damaged_health, FLOAT_TOLERANCE,
		"PS-003: durante l'attesa non viene restituito alcun HP."
	)
	assert_almost_eq(
		passive.get_recoverable_health(), expected, FLOAT_TOLERANCE,
		"PS-003: l'attesa non consuma la quota recuperabile."
	)

	# Il recupero e' progressivo e lineare: un quarto della finestra rende un
	# quarto della quota. E' la proprieta' che PS-004 puo' leggere frame per
	# frame senza dover indovinare una curva.
	var step := duration * 0.25
	for index in range(1, 5):
		passive._process(step)
		var consumed := expected * (float(index) / 4.0)
		assert_almost_eq(
			passive.get_recoverable_health(), expected - consumed, FLOAT_TOLERANCE,
			"PS-003: il recupero drena la quota in modo lineare (passo %d)." % index
		)
		assert_almost_eq(
			health.health_current, damaged_health + consumed, FLOAT_TOLERANCE,
			"PS-003: ogni passo restituisce la quota corrispondente (passo %d)." % index
		)

	assert_almost_eq(
		passive.get_recoverable_health(), 0.0, FLOAT_TOLERANCE,
		"PS-003: a fine finestra la quota e' esaurita."
	)


func test_ps003_colpi_multipli_accumulano_senza_tetto() -> void:
	var context := await _build_zat_context()
	if context.is_empty():
		return
	var player: Player = context["player"]
	var passive: FriendPassiveController = context["passive"]
	var health: HealthComponent = context["health"]
	var definition: FriendDefinition = context["definition"]
	var fraction: float = context["fraction"]

	var hits := 5
	for index in range(hits):
		assert_true(
			_hit(player, health, FIXTURE_DAMAGE),
			"PS-003: il colpo %d deve essere applicato." % index
		)
	var expected := FIXTURE_DAMAGE * fraction * float(hits)
	assert_almost_eq(
		passive.get_recoverable_health(), expected, FLOAT_TOLERANCE,
		"PS-003: piu' colpi sommano le rispettive quote."
	)

	# Nessun tetto dichiarato nei dati e nessun tetto implicito nel runtime:
	# la quota accumulata puo' superare la vita residua.
	assert_false(
		definition.passive_parameters.has(&"recoverable_max"),
		"PS-003: la passiva non dichiara un tetto alla quota recuperabile."
	)
	assert_true(
		passive.get_recoverable_health() > health.health_current,
		"PS-003: la quota accumulata non e' limitata dalla vita residua."
	)


func test_ps003_colpo_durante_attesa_riparte_senza_perdere_quota() -> void:
	var context := await _build_zat_context()
	if context.is_empty():
		return
	var player: Player = context["player"]
	var passive: FriendPassiveController = context["passive"]
	var health: HealthComponent = context["health"]
	var fraction: float = context["fraction"]
	var delay: float = context["delay"]
	var duration: float = context["duration"]

	assert_true(_hit(player, health, FIXTURE_DAMAGE), "Serve un primo colpo.")
	passive._process(delay * 0.6)
	assert_true(_hit(player, health, FIXTURE_DAMAGE), "Serve un secondo colpo durante l'attesa.")

	var expected := FIXTURE_DAMAGE * fraction * 2.0
	assert_almost_eq(
		passive.get_recoverable_health(), expected, FLOAT_TOLERANCE,
		"PS-003: un colpo durante l'attesa somma la quota invece di annullarla."
	)

	# L'attesa riparte da capo: la penalita' di un nuovo colpo e' il tempo, non
	# la quota.
	var damaged_health := health.health_current
	passive._process(delay * 0.9)
	assert_almost_eq(
		health.health_current, damaged_health, FLOAT_TOLERANCE,
		"PS-003: l'attesa riparte dal valore pieno dopo un nuovo colpo."
	)
	passive._process(delay)
	passive._process(duration)
	assert_almost_eq(
		health.health_current, damaged_health + expected, FLOAT_TOLERANCE,
		"PS-003: scaduta la nuova attesa viene restituita l'intera quota accumulata."
	)


func test_ps003_colpo_durante_recupero_conserva_il_residuo() -> void:
	var context := await _build_zat_context()
	if context.is_empty():
		return
	var player: Player = context["player"]
	var passive: FriendPassiveController = context["passive"]
	var health: HealthComponent = context["health"]
	var fraction: float = context["fraction"]
	var delay: float = context["delay"]
	var duration: float = context["duration"]

	assert_true(_hit(player, health, FIXTURE_DAMAGE), "Serve un primo colpo.")
	var first_quota := FIXTURE_DAMAGE * fraction
	passive._process(delay)
	passive._process(duration * 0.25)
	var residual := first_quota * 0.75
	assert_almost_eq(
		passive.get_recoverable_health(), residual, FLOAT_TOLERANCE,
		"PS-003: dopo un quarto di finestra resta tre quarti della quota."
	)

	assert_true(_hit(player, health, FIXTURE_DAMAGE), "Serve un colpo durante il recupero.")
	var expected := residual + first_quota
	assert_almost_eq(
		passive.get_recoverable_health(), expected, FLOAT_TOLERANCE,
		"PS-003: il residuo non restituito sopravvive al nuovo colpo e vi si somma."
	)

	# Il recupero in corso viene interrotto: riparte l'attesa piena.
	var damaged_health := health.health_current
	passive._process(delay * 0.9)
	assert_almost_eq(
		health.health_current, damaged_health, FLOAT_TOLERANCE,
		"PS-003: un colpo durante il recupero lo interrompe e riapre l'attesa."
	)
	passive._process(delay)
	passive._process(duration)
	assert_almost_eq(
		health.health_current, damaged_health + expected, FLOAT_TOLERANCE,
		"PS-003: dopo l'interruzione l'intera quota viene comunque restituita."
	)


func test_ps003_stati_non_running_congelano_attesa_e_recupero() -> void:
	var context := await _build_zat_context()
	if context.is_empty():
		return
	var controller: RunController = context["controller"]
	var player: Player = context["player"]
	var passive: FriendPassiveController = context["passive"]
	var health: HealthComponent = context["health"]
	var fraction: float = context["fraction"]
	var delay: float = context["delay"]
	var duration: float = context["duration"]

	assert_true(_hit(player, health, FIXTURE_DAMAGE), "Serve un colpo da congelare.")
	var expected := FIXTURE_DAMAGE * fraction
	var damaged_health := health.health_current

	# Pausa manuale, level-up e Boss intro sono tre stati distinti ma un solo
	# contratto: il clock della passiva e' quello di RUNNING.
	assert_true(controller.request_manual_pause(), "La pausa manuale deve essere accettata.")
	passive._process(delay + duration)
	assert_true(controller.resume_run(), "La run deve poter riprendere.")

	assert_true(controller.request_level_up(), "Il level-up deve essere accettato.")
	passive._process(delay + duration)
	assert_true(controller.complete_level_up(), "Il level-up deve potersi chiudere.")

	assert_true(controller.request_boss_intro(), "L'intro del Boss deve essere accettata.")
	passive._process(delay + duration)
	assert_true(controller.complete_boss_intro(), "L'intro del Boss deve potersi chiudere.")
	get_tree().paused = false

	assert_almost_eq(
		health.health_current, damaged_health, FLOAT_TOLERANCE,
		"PS-003: fuori da RUNNING nessun HP viene restituito."
	)
	assert_almost_eq(
		passive.get_recoverable_health(), expected, FLOAT_TOLERANCE,
		"PS-003: fuori da RUNNING la quota resta intatta."
	)

	# L'attesa non e' stata consumata dai modali: serve ancora per intero.
	passive._process(delay * 0.9)
	assert_almost_eq(
		health.health_current, damaged_health, FLOAT_TOLERANCE,
		"PS-003: l'attesa non e' avanzata durante i modali."
	)
	passive._process(delay)
	passive._process(duration)
	assert_almost_eq(
		health.health_current, damaged_health + expected, FLOAT_TOLERANCE,
		"PS-003: tornati in RUNNING il recupero riprende dal punto in cui era."
	)


func test_ps003_danno_letale_non_viene_annullato_dalla_quota() -> void:
	var context := await _build_zat_context()
	if context.is_empty():
		return
	var player: Player = context["player"]
	var passive: FriendPassiveController = context["passive"]
	var health: HealthComponent = context["health"]
	var fraction: float = context["fraction"]
	var delay: float = context["delay"]
	var duration: float = context["duration"]

	assert_true(_hit(player, health, FIXTURE_DAMAGE), "Serve una quota gia' accumulata.")
	var residual_health := health.health_current
	assert_true(residual_health > 0.0, "Zat deve essere viva prima del colpo letale.")

	assert_true(
		_hit(player, health, residual_health + 500.0),
		"Il colpo letale deve essere applicato."
	)
	assert_almost_eq(
		health.health_current, 0.0, FLOAT_TOLERANCE,
		"PS-003: la quota recuperabile non assorbe il colpo letale."
	)
	assert_false(health.is_alive(), "PS-003: Zat muore anche con HP recuperabili in sospeso.")

	# La quota accreditata dal colpo letale e' calcolata sul danno *applicato*
	# (la vita residua), non sul valore grezzo del colpo.
	assert_true(
		passive.get_recoverable_health() <= (FIXTURE_DAMAGE + residual_health) * fraction
			+ FLOAT_TOLERANCE,
		"PS-003: il colpo letale accredita solo la frazione della vita residua."
	)

	passive._process(delay + duration + 10.0)
	assert_almost_eq(
		health.health_current, 0.0, FLOAT_TOLERANCE,
		"PS-003: la quota in sospeso non resuscita Zat dopo la morte."
	)
	assert_false(health.is_alive(), "PS-003: la morte resta definitiva.")


func test_ps003_cura_esterna_a_vita_piena_scarta_la_quota() -> void:
	var context := await _build_zat_context()
	if context.is_empty():
		return
	var player: Player = context["player"]
	var passive: FriendPassiveController = context["passive"]
	var health: HealthComponent = context["health"]
	var fraction: float = context["fraction"]
	var delay: float = context["delay"]
	var duration: float = context["duration"]

	assert_true(_hit(player, health, FIXTURE_DAMAGE), "Serve una quota gia' accumulata.")
	assert_almost_eq(
		passive.get_recoverable_health(), FIXTURE_DAMAGE * fraction, FLOAT_TOLERANCE,
		"La quota deve esistere prima della cura esterna."
	)

	# Un pickup di salute riporta Zat al massimo: al primo tick di recupero la
	# cura non e' applicabile e l'intera quota viene scartata, non conservata.
	assert_true(health.heal(FIXTURE_DAMAGE * 2.0) > 0.0, "La cura esterna deve applicarsi.")
	assert_almost_eq(
		health.health_current, health.health_max, FLOAT_TOLERANCE,
		"La cura esterna deve riportare Zat a vita piena."
	)
	passive._process(delay)
	passive._process(duration * 0.1)
	assert_almost_eq(
		passive.get_recoverable_health(), 0.0, FLOAT_TOLERANCE,
		"PS-003: a vita piena la quota recuperabile viene scartata per intero."
	)


func test_ps003_variazioni_di_hp_massimi() -> void:
	var context := await _build_zat_context()
	if context.is_empty():
		return
	var player: Player = context["player"]
	var passive: FriendPassiveController = context["passive"]
	var health: HealthComponent = context["health"]
	var fraction: float = context["fraction"]
	var delay: float = context["delay"]
	var duration: float = context["duration"]

	assert_true(_hit(player, health, FIXTURE_DAMAGE), "Serve una quota gia' accumulata.")
	var expected := FIXTURE_DAMAGE * fraction
	var damaged_health := health.health_current

	# Alzare il tetto degli HP non tocca la quota: il buco da colmare resta lo
	# stesso e il recupero lo colma per intero.
	health.set_health_max(health.health_max + FIXTURE_DAMAGE * 2.0)
	assert_almost_eq(
		passive.get_recoverable_health(), expected, FLOAT_TOLERANCE,
		"PS-003: aumentare gli HP massimi non altera la quota recuperabile."
	)
	passive._process(delay)
	passive._process(duration)
	assert_almost_eq(
		health.health_current, damaged_health + expected, FLOAT_TOLERANCE,
		"PS-003: con piu' HP massimi la quota viene restituita per intero."
	)

	# Abbassare il tetto sotto la vita corrente la tronca: la quota successiva
	# non puo' sfondare il nuovo tetto e viene scartata.
	assert_true(_hit(player, health, FIXTURE_DAMAGE), "Serve un nuovo colpo.")
	health.set_health_max(health.health_current)
	assert_almost_eq(
		passive.get_recoverable_health(), FIXTURE_DAMAGE * fraction, FLOAT_TOLERANCE,
		"PS-003: ridurre gli HP massimi non altera da solo la quota."
	)
	var capped_health := health.health_current
	passive._process(delay)
	passive._process(duration * 0.1)
	assert_almost_eq(
		health.health_current, capped_health, FLOAT_TOLERANCE,
		"PS-003: il recupero non puo' superare il tetto corrente."
	)
	assert_almost_eq(
		passive.get_recoverable_health(), 0.0, FLOAT_TOLERANCE,
		"PS-003: la quota non restituibile viene scartata."
	)


func test_ps003_restart_e_cambio_personaggio_azzerano_lo_stato() -> void:
	var context := await _build_zat_context()
	if context.is_empty():
		return
	var controller: RunController = context["controller"]
	var registry: FriendRegistry = context["registry"]
	var player: Player = context["player"]
	var passive: FriendPassiveController = context["passive"]
	var health: HealthComponent = context["health"]
	var definition: FriendDefinition = context["definition"]
	var delay: float = context["delay"]
	var duration: float = context["duration"]

	assert_true(_hit(player, health, FIXTURE_DAMAGE), "Serve una quota da azzerare.")
	assert_true(passive.get_recoverable_health() > 0.0, "La quota deve esistere prima del restart.")

	controller.prepare_restart()
	assert_almost_eq(
		passive.get_recoverable_health(), 0.0, FLOAT_TOLERANCE,
		"PS-003: il restart azzera la quota recuperabile."
	)

	assert_true(controller.start_run(4711), "La run deve poter ripartire.")
	player.reset_for_run()
	var restarted_health := health.health_current
	passive._process(delay)
	passive._process(duration)
	assert_almost_eq(
		health.health_current, restarted_health, FLOAT_TOLERANCE,
		"PS-003: dopo il restart non resta alcun timer che restituisca HP."
	)

	assert_true(_hit(player, health, FIXTURE_DAMAGE), "Serve una nuova quota.")
	assert_true(
		passive.get_recoverable_health() > 0.0,
		"La quota deve esistere prima del cambio personaggio."
	)
	var other := registry.resolve_definition(OTHER_FRIEND_ID)
	assert_true(other != null and other != definition, "Serve un secondo profilo per il cambio.")
	if other == null:
		return
	assert_true(passive.equip_definition(other), "Il cambio personaggio deve essere accettato.")
	assert_almost_eq(
		passive.get_recoverable_health(), 0.0, FLOAT_TOLERANCE,
		"PS-003: il cambio personaggio azzera la quota recuperabile."
	)


## PS-004 legge la quota corrente per scalare Tempesta di Tuoni: deve poterla
## ottenere sia a richiesta sia via segnale, senza toccare lo stato interno.
func test_ps003_quota_leggibile_per_ps004() -> void:
	var context := await _build_zat_context()
	if context.is_empty():
		return
	var player: Player = context["player"]
	var passive: FriendPassiveController = context["passive"]
	var health: HealthComponent = context["health"]
	var fraction: float = context["fraction"]

	watch_signals(passive)
	assert_true(_hit(player, health, FIXTURE_DAMAGE), "Serve un colpo da osservare.")
	assert_signal_emitted(
		passive, "delayed_healing_changed",
		"PS-003: ogni variazione della quota deve essere annunciata via segnale."
	)
	var expected := FIXTURE_DAMAGE * fraction
	assert_almost_eq(
		get_signal_parameters(passive, "delayed_healing_changed")[0], expected, FLOAT_TOLERANCE,
		"PS-003: il segnale trasporta la quota corrente."
	)
	assert_almost_eq(
		passive.get_recoverable_health(), expected, FLOAT_TOLERANCE,
		"PS-003: il getter e il segnale espongono lo stesso valore."
	)
	assert_almost_eq(
		passive.get_recoverable_health(), expected, FLOAT_TOLERANCE,
		"PS-003: leggere la quota non la consuma."
	)


## Applica un colpo per la via reale (`take_contact_damage`), azzerando prima
## gli i-frame: la fixture deve poter concatenare piu' colpi senza che
## l'invulnerabilita' post-danno ne mangi qualcuno in silenzio.
func _hit(player: Player, health: HealthComponent, amount: float) -> bool:
	health.clear_invulnerability()
	return player.take_contact_damage(amount)


func _build_zat_context() -> Dictionary:
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_run_controller() as RunController
	var registry := movement_slice.get_friend_registry() as FriendRegistry
	var player := movement_slice.get_player() as Player
	var passive := movement_slice.get_friend_passive_controller() as FriendPassiveController
	if controller == null or registry == null or player == null or passive == null:
		assert_true(false, "La scena di run deve esporre le dipendenze PS-003.")
		return {}

	controller.set_process(false)
	player.set_physics_process(false)
	passive.set_process(false)
	controller.start_run(4711)

	var definition := registry.resolve_definition(ZAT_ID)
	assert_true(definition != null, "Il profilo Zat deve esistere.")
	if definition == null:
		return {}
	player.set_friend_definition(definition)
	assert_true(passive.equip_definition(definition), "La passiva deve accettare Zat.")

	var health := player.get_health_component()
	assert_true(health != null, "Zat deve esporre un HealthComponent.")
	if health == null:
		return {}

	return {
		"slice": movement_slice,
		"controller": controller,
		"registry": registry,
		"player": player,
		"passive": passive,
		"health": health,
		"definition": definition,
		"fraction": definition.get_passive_float(&"recoverable_fraction", 0.0, 0.0, 1.0),
		"delay": definition.get_passive_float(&"recovery_delay", 3.0, 0.0),
		"duration": definition.get_passive_float(
			&"recovery_duration", 4.0, AbilityDefinition.MINIMUM_POSITIVE_VALUE
		),
	}
