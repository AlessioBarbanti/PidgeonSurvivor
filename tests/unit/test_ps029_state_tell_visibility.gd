extends GutGameplayTest

## PS-029 — Rendi piu' visibili i tell di stato dei personaggi.
##
## Copre cio' che e' verificabile in modo deterministico dal contratto della
## card: il contorno di PS-001 e' stato reso piu' spesso e con un bordo di
## separazione scuro, le coppie di colori delle fasi restano a una distanza
## cromatica minima (non piu' affidata alla sola sfumatura), e i tell di Alea
## e Migi — non coperti da `test_b44_state_tells.gd` — seguono la finestra
## attiva dichiarata senza toccare durata o logica dello stato.
##
## La leggibilita' percettiva reale (densita' nemici, VFX, schermo Android)
## resta un gate manuale separato: qui si verificano solo le precondizioni
## strutturali (spessore, distanza cromatica, presentazione/pulizia).

const MINIMUM_STATE_COLOR_DISTANCE := 0.4
const RUN_SEED := 4711


func test_ps029_outline_thickness_and_separator_increased() -> void:
	var outline := PassiveStateOutline.new()
	assert_true(
		outline.thickness >= 3.5,
		"PS-029: lo spessore base deve restare marcatamente sopra i 2.0 unita' di PS-001."
	)
	assert_true(
		outline.separator_thickness > 0.0,
		"PS-029: deve esistere un bordo di separazione scuro per il contrasto contro qualunque sfondo."
	)
	outline.free()


func test_ps029_state_color_pairs_meet_minimum_contrast() -> void:
	var pairs := [
		["Aleo", FriendPassiveController.OUTLINE_ALEO_HOT, FriendPassiveController.OUTLINE_ALEO_COLD],
		["Lollo", FriendPassiveController.OUTLINE_LOLLO_FOCUSED, FriendPassiveController.OUTLINE_LOLLO_DISTRACTED],
		["Alea", FriendPassiveController.OUTLINE_ALEA_POSITIVE, FriendPassiveController.OUTLINE_ALEA_NEGATIVE],
		["Migi", FriendPassiveController.OUTLINE_MIGI_SHELL_READY, FriendPassiveController.OUTLINE_MIGI_SHIELD],
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


func test_ps029_alea_tell_active_only_during_window() -> void:
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
		not player.has_passive_state_outline(),
		"PS-029: fuori dalla finestra attiva Alea non deve mostrare alcun tell."
	)

	passive._activate_alea_effect()
	assert_true(player.has_passive_state_outline(), "PS-029: nella finestra attiva il tell deve comparire.")
	var positive: bool = passive._alea_move_multiplier > 1.0 or passive._alea_fire_multiplier > 1.0
	var expected := (
		FriendPassiveController.OUTLINE_ALEA_POSITIVE if positive
		else FriendPassiveController.OUTLINE_ALEA_NEGATIVE
	)
	assert_true(
		player.get_passive_state_outline_color() == expected,
		"PS-029: il colore del tell deve corrispondere alla polarita' estratta."
	)

	var effect_duration := alea.get_passive_float(
		&"effect_duration", 5.0, AbilityDefinition.MINIMUM_POSITIVE_VALUE
	)
	passive._process(effect_duration + 0.01)
	assert_true(
		not player.has_passive_state_outline(),
		"PS-029: allo scadere della finestra il tell deve tornare neutro."
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
		player.get_passive_state_outline_color() == FriendPassiveController.OUTLINE_MIGI_SHELL_READY,
		"PS-029: con cariche disponibili il tell deve essere quello del guscio piccolo."
	)

	passive._activate_migi_shield()
	assert_true(
		player.get_passive_state_outline_color() == FriendPassiveController.OUTLINE_MIGI_SHIELD,
		"PS-029: con lo scudo d'emergenza attivo il tell deve passare a quello dedicato."
	)

	var shield_duration := migi.get_passive_float(
		&"shield_duration", 4.0, AbilityDefinition.MINIMUM_POSITIVE_VALUE
	)
	passive._process(shield_duration + 0.01)
	assert_true(
		player.get_passive_state_outline_color() == FriendPassiveController.OUTLINE_MIGI_SHELL_READY,
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
