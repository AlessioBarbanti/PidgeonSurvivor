extends GutGameplayTest

## PS-041 — `Player.reset_for_run()` svuotava `_momentum_trail_points` (la
## scia di slancio di Magno) ma non chiedeva mai un ridisegno: un
## `CanvasItem` non si ridisegna da solo quando i suoi dati cambiano, quindi
## l'ultimo frame disegnato dalla run precedente restava a schermo finche'
## `_advance_momentum_trail()` non ridisegnava al primo tick utile. Un test
## headless non può osservare la richiesta di ridisegno di `CanvasItem`
## direttamente (nessuna API pubblica la espone): questo test pinna il fix
## per lettura del sorgente, più la copertura comportamentale sui dati.

const PLAYER_SCRIPT_PATH := "res://scripts/actors/player.gd"


func test_reset_for_run_requests_a_redraw_when_the_trail_had_points() -> void:
	var source := FileAccess.get_file_as_string(PLAYER_SCRIPT_PATH)
	assert_true(not source.is_empty(), "Deve essere possibile leggere lo script del Player.")

	var body := _extract_function_body(source, "func reset_for_run() -> void:")
	assert_true(not body.is_empty(), "reset_for_run() deve esistere in player.gd.")
	assert_true(
		body.contains("_momentum_trail_points.clear()"),
		"reset_for_run() deve continuare a svuotare la scia di slancio."
	)
	assert_true(
		body.contains("queue_redraw()"),
		"PS-041: reset_for_run() deve richiedere un ridisegno dopo aver svuotato la scia, non solo i dati."
	)


func test_reset_for_run_clears_momentum_trail_state() -> void:
	var context := await _build_context()
	if context.is_empty():
		return
	var registry: FriendRegistry = context["registry"]
	var player: Player = context["player"]
	var passive: FriendPassiveController = context["passive"]

	var magno := registry.resolve_definition(&"magno")
	assert_true(magno != null, "Il profilo Magno deve esistere.")
	if magno == null:
		return
	player.set_friend_definition(magno)
	assert_true(passive.equip_definition(magno), "La passiva deve accettare Magno.")

	player.set_movement_input(Vector2.RIGHT)
	for _tick_index in 20:
		player._advance_momentum(0.1)
	assert_true(player.get_momentum_ratio() > 0.9, "Il test deve accumulare slancio quasi pieno.")
	assert_true(
		not player._momentum_trail_points.is_empty(),
		"Con slancio pieno e la scia attiva devono esserci punti campionati."
	)

	player.reset_for_run()

	assert_almost_eq(player.get_momentum_ratio(), 0.0, FLOAT_TOLERANCE, "reset_for_run deve azzerare lo slancio.")
	assert_true(
		player._momentum_trail_points.is_empty(),
		"reset_for_run deve svuotare i punti della scia."
	)


func _extract_function_body(source: String, signature: String) -> String:
	var start := source.find(signature)
	if start < 0:
		return ""
	var body_start := start + signature.length()
	var next_func := source.find("\nfunc ", body_start)
	if next_func < 0:
		next_func = source.length()
	return source.substr(body_start, next_func - body_start)


func _build_context() -> Dictionary:
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_run_controller() as RunController
	var registry := movement_slice.get_friend_registry() as FriendRegistry
	var player := movement_slice.get_player() as Player
	var passive := movement_slice.get_friend_passive_controller() as FriendPassiveController
	if controller == null or registry == null or player == null or passive == null:
		assert_true(false, "La scena di run deve esporre le dipendenze PS-041.")
		return {}

	controller.set_process(false)
	player.set_physics_process(false)
	passive.set_process(false)
	controller.start_run(2041)
	return {
		"controller": controller,
		"registry": registry,
		"player": player,
		"passive": passive,
	}
