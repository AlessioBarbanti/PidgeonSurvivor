extends GutGameplayTest

## PS-029 — Rendi piu' visibili i tell di stato dei personaggi.
##
## Copre cio' che e' verificabile in modo deterministico dal contratto della
## card: le coppie di colori delle fasi restano a una distanza cromatica
## minima (non piu' affidata alla sola sfumatura), e i tell di Alea e Migi —
## non coperti da `test_b44_state_tells.gd` — seguono la finestra attiva
## dichiarata senza toccare durata o logica dello stato.
##
## PS-079 ha sostituito il contorno del tell con un particellare non
## aderente: la verifica di spessore/bordo di separazione, specifica del
## contorno, non si applica piu' e vive ora in
## `test_ps079_state_tell_particles.gd` con il contratto del nuovo sistema.
##
## La leggibilita' percettiva reale (densita' nemici, VFX, schermo Android)
## resta un gate manuale separato: qui si verificano solo le precondizioni
## strutturali (distanza cromatica, presentazione/pulizia).

const MINIMUM_STATE_COLOR_DISTANCE := 0.4
const RUN_SEED := 4711


func test_ps029_state_color_pairs_meet_minimum_contrast() -> void:
	# PS-105: Alea non ha piu' una coppia di colori (l'esito non e' piu'
	# casuale), quindi non compare in questa lista di coppie di stato.
	# PS-099: Aleo e Lollo non usano piu' una tinta a portare la distinzione
	# fra fasi — l'aura a terra di Aleo distingue caldo/freddo per soggetto
	# (brace/brina, non solo colore) e l'aura di Lollo compare solo in
	# iperfocus (la distrazione non ha alcun tell da contrastare). Il test di
	# contrasto cromatico non si applica piu' a loro; resta per Migi, che
	# continua a usare `PassiveStateParticles`.
	var pairs := [
		["Migi", FriendPassiveController.TELL_MIGI_SHELL_READY, FriendPassiveController.TELL_MIGI_SHIELD],
	]
	for pair in pairs:
		var character_name: String = pair[0]
		var distance := _color_distance(pair[1], pair[2])
		assert_true(
			distance >= MINIMUM_STATE_COLOR_DISTANCE,
			(
				"PS-029: le due fasi di %s devono restare a distanza cromatica minima (%.3f < %.3f)."
				% [character_name, distance, MINIMUM_STATE_COLOR_DISTANCE]
			)
		)


func test_ps029_alea_tell_active_only_during_brilla() -> void:
	var context := await _build_context()
	if context.is_empty():
		return
	var player: Player = context["player"]
	var passive: FriendPassiveController = context["passive"]
	var registry: FriendRegistry = context["registry"]
	var controller: RunController = context["controller"]

	var alea := registry.resolve_definition(&"alea")
	assert_true(alea != null, "Il profilo Alea deve esistere.")
	if alea == null:
		return
	player.set_friend_definition(alea)
	assert_true(passive.equip_definition(alea), "La passiva deve accettare Alea.")

	assert_true(
		not player.has_passive_state_tell(),
		"PS-029: fuori da Brilla Alea non deve mostrare alcun tell."
	)

	passive._start_alea_brilla()
	assert_true(player.has_passive_state_tell(), "PS-029: durante Brilla il tell deve comparire.")
	assert_true(
		player.get_passive_state_tell_color() == FriendPassiveController.TELL_ALEA_BRILLA,
		"PS-029: durante Brilla il tell deve essere il colore dedicato (PS-105)."
	)

	var brilla_duration := alea.get_passive_float(
		&"brilla_duration", 6.0, AbilityDefinition.MINIMUM_POSITIVE_VALUE
	)
	passive._process(brilla_duration + 0.01)
	assert_true(
		not player.has_passive_state_tell(),
		"PS-029: allo scadere di Brilla il tell deve tornare neutro."
	)

	controller.prepare_restart()


func test_ps029_migi_shell_and_shield_tells_are_distinct() -> void:
	var context := await _build_context()
	if context.is_empty():
		return
	var player: Player = context["player"]
	var passive: FriendPassiveController = context["passive"]
	var registry: FriendRegistry = context["registry"]
	var controller: RunController = context["controller"]

	var migi := registry.resolve_definition(&"migi")
	assert_true(migi != null, "Il profilo Migi deve esistere.")
	if migi == null:
		return
	player.set_friend_definition(migi)
	assert_true(passive.equip_definition(migi), "La passiva deve accettare Migi.")

	assert_true(passive.get_migi_shell_charges() > 0, "Migi deve avere cariche del guscio subito dopo l'equip.")
	assert_true(
		player.get_passive_state_tell_color() == FriendPassiveController.TELL_MIGI_SHELL_READY,
		"PS-029: con cariche disponibili il tell deve essere quello del guscio piccolo."
	)

	passive._activate_migi_shield()
	assert_true(
		player.get_passive_state_tell_color() == FriendPassiveController.TELL_MIGI_SHIELD,
		"PS-029: con lo scudo d'emergenza attivo il tell deve passare a quello dedicato."
	)

	var shield_duration := migi.get_passive_float(
		&"shield_duration", 4.0, AbilityDefinition.MINIMUM_POSITIVE_VALUE
	)
	passive._process(shield_duration + 0.01)
	assert_true(
		player.get_passive_state_tell_color() == FriendPassiveController.TELL_MIGI_SHELL_READY,
		"PS-029: allo scadere dello scudo il tell deve tornare al guscio piccolo se restano cariche."
	)

	controller.prepare_restart()


func _color_distance(a: Color, b: Color) -> float:
	return Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length()


func _build_context() -> Dictionary:
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_run_controller() as RunController
	var registry := movement_slice.get_friend_registry() as FriendRegistry
	var player := movement_slice.get_player() as Player
	var passive := movement_slice.get_friend_passive_controller() as FriendPassiveController
	if controller == null or registry == null or player == null or passive == null:
		assert_true(false, "La scena di run deve esporre le dipendenze PS-029.")
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
