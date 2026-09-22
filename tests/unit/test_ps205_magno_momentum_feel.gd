extends GutGameplayTest

## PS-205 — Slancio di Magno: parte al 60% della velocità base condivisa,
## arriva al 140% in 2,5 s di corsa dritta e perde slancio in proporzione alla
## curva (90° circa metà, inversione a U tutto), misurata rispetto a un
## riferimento che non si riallinea a ogni frame.

const TICK := 1.0 / 60.0
const SPEED_TOLERANCE := 0.02
const MAGNO_ID := &"magno"


func test_speed_curve_from_standstill_to_full_momentum() -> void:
	var context := await _build_context()
	if context.is_empty():
		return
	var player: Player = context["player"]
	var passive: FriendPassiveController = context["passive"]

	_apply(passive)
	assert_almost_eq(player.get_character_move_speed_multiplier(), 0.60, SPEED_TOLERANCE, "Da fermo: 60%.")

	player.set_movement_input(Vector2.RIGHT)
	_run(player, 1.25, func(_elapsed: float) -> Vector2: return Vector2.RIGHT)
	_apply(passive)
	assert_almost_eq(player.get_momentum_ratio(), 0.5, 0.02, "A 1,25 s lo slancio è a metà.")
	assert_almost_eq(player.get_character_move_speed_multiplier(), 1.00, SPEED_TOLERANCE, "A metà: 100%.")

	_run(player, 1.25, func(_elapsed: float) -> Vector2: return Vector2.RIGHT)
	_apply(passive)
	assert_almost_eq(player.get_momentum_ratio(), 1.0, 0.01, "A 2,5 s lo slancio è pieno.")
	assert_almost_eq(player.get_character_move_speed_multiplier(), 1.40, SPEED_TOLERANCE, "A pieno: 140%.")
	print("PS205_SPEED_CURVE_OK")


func test_turns_cost_momentum_in_proportion_to_the_angle() -> void:
	var context := await _build_context()
	if context.is_empty():
		return
	var player: Player = context["player"]

	var cases := [
		["90° secca", PI * 0.5, 0.0, 0.4, 0.6],
		["90° graduale", PI * 0.5, 0.5, 0.4, 0.6],
		["U secca", PI, 0.0, 0.0, 0.0],
		["U graduale", PI, 0.5, 0.0, 0.0],
	]
	for turn_case: Array in cases:
		var label: String = turn_case[0]
		var total_angle: float = turn_case[1]
		var duration: float = turn_case[2]
		_fill_momentum(player)
		if duration <= 0.0:
			_run(player, TICK, func(_elapsed: float) -> Vector2: return Vector2.RIGHT.rotated(total_angle))
		else:
			var turn_rate := total_angle / duration
			_run(player, duration, func(elapsed: float) -> Vector2: return Vector2.RIGHT.rotated(turn_rate * elapsed))
		var ratio := player.get_momentum_ratio()
		print("PS205_TURN %s ratio=%.3f" % [label, ratio])
		assert_between(ratio, turn_case[3] - 0.001, turn_case[4] + 0.001, "%s: slancio %.3f." % [label, ratio])


func test_small_corrections_are_free_and_circling_never_builds_momentum() -> void:
	var context := await _build_context()
	if context.is_empty():
		return
	var player: Player = context["player"]

	player.reset_for_run()
	var wobble := func(elapsed: float) -> Vector2: return Vector2.RIGHT.rotated(deg_to_rad(15.0) * sin(elapsed * TAU * 2.0))
	_run(player, 2.5, wobble)
	assert_almost_eq(player.get_momentum_ratio(), 1.0, 0.01, "Correzioni entro ±15° per 2,5 s: slancio pieno.")

	player.reset_for_run()
	var peak := 0.0
	var elapsed := 0.0
	while elapsed < 3.0:
		player.set_movement_input(Vector2.RIGHT.rotated(TAU * elapsed))
		player._advance_momentum(TICK)
		peak = maxf(peak, player.get_momentum_ratio())
		elapsed += TICK
	print("PS205_CIRCLE peak=%.3f" % peak)
	assert_true(peak <= 0.5, "Girare in tondo non porta lo slancio sopra 0,5 (picco %.3f)." % peak)


func test_stop_restart_and_other_characters_keep_their_behaviour() -> void:
	var context := await _build_context()
	if context.is_empty():
		return
	var registry: FriendRegistry = context["registry"]
	var player: Player = context["player"]
	var passive: FriendPassiveController = context["passive"]

	_fill_momentum(player)
	player.clear_movement_input()
	for _index in 30:
		player._advance_momentum(TICK)
	assert_almost_eq(player.get_momentum_ratio(), 0.0, FLOAT_TOLERANCE, "Fermarsi azzera lo slancio in 0,5 s.")

	_fill_momentum(player)
	player.reset_for_run()
	assert_almost_eq(player.get_momentum_ratio(), 0.0, FLOAT_TOLERANCE, "Il restart azzera lo slancio.")
	assert_almost_eq(player._momentum_ramp_seconds, 2.5, FLOAT_TOLERANCE, "Rincorsa letta dai dati di Magno.")

	for definition in registry.get_definitions():
		if definition.id == MAGNO_ID:
			continue
		player.set_friend_definition(definition)
		assert_true(passive.equip_definition(definition), "La passiva deve accettare %s." % definition.id)
		assert_almost_eq(
			player._momentum_ramp_seconds, Player.MOMENTUM_RAMP_SECONDS, FLOAT_TOLERANCE,
			"%s non eredita la rincorsa di Magno." % definition.id
		)
		_apply(passive)
		var standing := player.get_character_move_speed_multiplier()
		_fill_momentum(player)
		_apply(passive)
		assert_almost_eq(
			player.get_character_move_speed_multiplier(), standing, FLOAT_TOLERANCE,
			"%s non cambia velocità con lo slancio." % definition.id
		)
		assert_almost_eq(player.get_momentum_ratio(), 1.0, 0.01, "%s: slancio tracciato come prima." % definition.id)
		player.reset_for_run()
	print("PS205_OTHERS_UNCHANGED_OK")


func _fill_momentum(player: Player) -> void:
	player.reset_for_run()
	_run(player, 2.6, func(_elapsed: float) -> Vector2: return Vector2.RIGHT)


func _run(player: Player, seconds: float, direction_at: Callable) -> void:
	var elapsed := 0.0
	while elapsed < seconds - TICK * 0.5:
		elapsed += TICK
		player.set_movement_input(direction_at.call(elapsed))
		player._advance_momentum(TICK)


func _apply(passive: FriendPassiveController) -> void:
	passive._apply_character_multipliers()


func _build_context() -> Dictionary:
	var movement_slice := await instantiate_movement_slice()
	var controller := movement_slice.get_run_controller() as RunController
	var registry := movement_slice.get_friend_registry() as FriendRegistry
	var player := movement_slice.get_player() as Player
	var passive := movement_slice.get_friend_passive_controller() as FriendPassiveController
	if controller == null or registry == null or player == null or passive == null:
		assert_true(false, "La scena di run deve esporre le dipendenze PS-205.")
		return {}
	controller.set_process(false)
	player.set_physics_process(false)
	passive.set_process(false)
	controller.start_run(2205)
	var magno := registry.resolve_definition(MAGNO_ID)
	assert_true(magno != null, "Il profilo Magno deve esistere.")
	if magno == null:
		return {}
	player.set_friend_definition(magno)
	assert_true(passive.equip_definition(magno), "La passiva deve accettare Magno.")
	return {"registry": registry, "player": player, "passive": passive}
