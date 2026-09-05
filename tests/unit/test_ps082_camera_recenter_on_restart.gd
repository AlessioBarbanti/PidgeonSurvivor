extends GutGameplayTest

## PS-082: dopo un restart, il player deve riapparire esattamente al centro
## dell'area di gioco visibile, senza alcun frame in cui la camera resta
## ancora sfalsata dal drag margin della run precedente (vedi Decisioni:
## `Camera2D.align()` deve precedere `reset_smoothing()` in
## `_recenter_camera_on_player()`, altrimenti resta un offset pari al 35% del
## margine di drag).

const CAMERA_OFFSET_TOLERANCE := 1.0
const RESTART_SEED := 321


func test_camera_recenter_on_restart() -> void:
	var movement_slice := await instantiate_movement_slice()
	var controller := movement_slice.get_run_controller() as RunController
	var player := movement_slice.get_player() as Player
	var camera := movement_slice.get_camera() as Camera2D
	var arena_world := movement_slice.get_arena_world() as ArenaWorld
	assert_true(
		controller != null and player != null and camera != null and arena_world != null,
		"PS-082 richiede RunController, Player, Camera2D e ArenaWorld composti."
	)
	if controller == null or player == null or camera == null or arena_world == null:
		return

	# Sposta il player abbastanza a lungo da far seguire davvero il drag
	# margin della camera (non un singolo salto): riproduce il "trascinamento"
	# di una run reale prima del restart.
	var world_center := arena_world.get_world_center()
	var far_position := world_center + Vector2(600.0, 300.0)
	for _step in range(40):
		player.global_position += (far_position - player.global_position) * 0.2
		await wait_process_frames(1)

	var drifted_offset := camera.get_screen_center_position() - player.global_position
	assert_true(
		drifted_offset.length() > CAMERA_OFFSET_TOLERANCE,
		(
			"Precondizione del test: il drag deve aver spostato la camera dal player (comportamento normale invariato), altrimenti il test non prova nulla. Offset=%s"
			% drifted_offset
		)
	)

	assert_true(controller.request_defeat(), "PS-082 richiede una run in stato terminale per poter chiedere il restart.")
	assert_true(
		movement_slice.restart_run(RESTART_SEED),
		"PS-082 richiede che il restart abbia successo da uno stato terminale."
	)

	# Un frame e' il confine naturale di rendering: `align()`/`reset_smoothing()`
	# aggiornano lo stato interno della Camera2D dentro restart_run(), ma il
	# valore che _update_scroll() espone si allinea al frame successivo, lo
	# stesso che il motore presenta a schermo. Zero frame misurerebbe uno
	# stato intermedio mai visibile al giocatore, non un ritardo reale.
	await wait_process_frames(1)
	var recentered_player_position := player.global_position
	var recentered_offset := camera.get_screen_center_position() - recentered_player_position
	assert_true(
		recentered_offset.length() <= CAMERA_OFFSET_TOLERANCE,
		(
			"La camera deve ricentrarsi sul player entro il primo frame dopo il restart, senza il ritardo del drag margin. Offset=%s"
			% recentered_offset
		)
	)
	assert_vector_near(
		recentered_player_position, world_center, "Il restart deve riposizionare il player al centro dell'arena.", CAMERA_OFFSET_TOLERANCE
	)

	# Nessuna ulteriore interpolazione: lo snap resta stabile, non converge
	# gradualmente in altri frame successivi.
	await wait_process_frames(5)
	var stable_offset := camera.get_screen_center_position() - player.global_position
	assert_true(
		stable_offset.length() <= CAMERA_OFFSET_TOLERANCE,
		"Lo snap deve restare stabile, non e' un'interpolazione che si conclude dopo il restart. Offset=%s" % stable_offset
	)

	controller.prepare_restart()
	print("PS082_CAMERA_RECENTER_OK")
