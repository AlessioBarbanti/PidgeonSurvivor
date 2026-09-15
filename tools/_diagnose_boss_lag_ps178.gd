extends SceneTree

## Utility di sviluppo temporanea (non un test, non parte della pipeline di
## verifica): diagnosi PS-178. Cattura il frame time reale (Time.get_ticks_usec,
## non l'FPS medio a campionamento 1Hz di PerformanceMonitor) nei secondi
## intorno alla prima soglia Boss (default 120s,
## GameDirectorProfile.boss_thresholds_seconds[0]), con una run headless dove
## spawner e curva di difficolta' restano realmente attivi — a differenza dello
## stress harness B18V (`--b18v-stress`/`--b18v-soak`), che popola nemici e
## proiettili STATICI e non esercita spawner/curve nel tempo (vedi Decisioni
## di PS-172). Serve a isolare un singolo frame di spawn/transizione da un
## degrado di densita' sostenuto, cosa che il campionamento a 1Hz non puo' fare.
##
## Uso (Windows, dopo il refresh cache editor):
##   godot_console --headless --path . `
##     --script tools/_diagnose_boss_lag_ps178.gd -- `
##     --run-seed=20260915
##
## Nessun time_scale artificiale: la run avanza a velocita' reale, quindi lo
## script impiega circa quanto la soglia Boss configurata (~120s) piu' il
## margine di finestra. Il seed e' opzionale (default fisso per riproducibilita').
## Esito in stdout (marker PS178_DIAGNOSTIC_*) e in un CSV per-frame in
## exports/diagnostics/ps178-boss-lag-frametimes.csv.

const MOVEMENT_SLICE_SCENE := preload("res://scenes/game/movement_slice.tscn")
const WINDOW_BEFORE_SECONDS := 3.0
const WINDOW_AFTER_SECONDS := 3.0
## Rete di sicurezza se la soglia Boss non arriva mai (es. soglia cambiata):
## interrompe comunque lo script invece di girare all'infinito.
const SAFETY_TIMEOUT_SECONDS := 180.0
const OUT_DIR := "res://exports/diagnostics"
const OUT_PATH := "res://exports/diagnostics/ps178-boss-lag-frametimes.csv"

var _run_controller: RunController
var _game_director: GameDirector
var _performance_monitor: PerformanceMonitor
var _boss_threshold := 120.0
var _rows: Array[Dictionary] = []
var _last_tick_usec := 0
var _transition_run_time := -1.0
var _finished := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	var slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	root.add_child(slice)
	await process_frame
	await process_frame

	_run_controller = slice.call("get_run_controller") as RunController
	_game_director = slice.call("get_game_director") as GameDirector
	_performance_monitor = slice.call("get_performance_monitor") as PerformanceMonitor
	if _run_controller == null or _game_director == null:
		print("PS178_DIAGNOSTIC_ABORT missing_controller_or_director")
		quit(1)
		return

	var thresholds := _game_director.get_thresholds()
	if not thresholds.is_empty():
		_boss_threshold = thresholds[0]
	_run_controller.state_changed.connect(_on_state_changed)

	print("PS178_DIAGNOSTIC_START seed=%d boss_threshold=%.1f" % [
		_run_controller.get_seed(),
		_boss_threshold,
	])

	_last_tick_usec = Time.get_ticks_usec()
	while not _finished:
		await process_frame
		_record_frame()
		if _run_controller.get_run_time() > _boss_threshold + SAFETY_TIMEOUT_SECONDS:
			print("PS178_DIAGNOSTIC_TIMEOUT run_time=%.1f" % _run_controller.get_run_time())
			_finished = true

	_summarize()
	_write_csv()
	print("PS178_DIAGNOSTIC_DONE rows=%d" % _rows.size())
	quit(0)


func _on_state_changed(
	_previous_state: RunController.RunState,
	current_state: RunController.RunState
) -> void:
	if current_state == RunController.RunState.BOSS_INTRO and _transition_run_time < 0.0:
		_transition_run_time = _run_controller.get_run_time()
		print("PS178_DIAGNOSTIC_BOSS_INTRO run_time=%.2f" % _transition_run_time)


func _record_frame() -> void:
	var now_usec := Time.get_ticks_usec()
	var frame_ms := float(now_usec - _last_tick_usec) / 1000.0
	_last_tick_usec = now_usec
	var run_time := _run_controller.get_run_time()

	if run_time < _boss_threshold - WINDOW_BEFORE_SECONDS:
		return
	if _transition_run_time >= 0.0 and run_time > _transition_run_time + WINDOW_AFTER_SECONDS:
		_finished = true
		return

	var snapshot := (
		_performance_monitor.get_snapshot() if is_instance_valid(_performance_monitor) else {}
	)
	_rows.append({
		"run_time": run_time,
		"frame_ms": frame_ms,
		"state": RunController.RunState.keys()[_run_controller.get_state()],
		"enemies": int(snapshot.get("enemies", -1)),
		"projectiles": int(snapshot.get("projectiles", -1)),
		"nodes": int(snapshot.get("nodes", -1)),
		"objects": int(snapshot.get("objects", -1)),
		"draw_calls": int(snapshot.get("draw_calls", -1)),
	})


func _summarize() -> void:
	if _rows.is_empty():
		print("PS178_DIAGNOSTIC_PEAK none captured=0")
		return
	var peak: Dictionary = _rows[0]
	for row in _rows:
		if row["frame_ms"] > peak["frame_ms"]:
			peak = row
	print(
		"PS178_DIAGNOSTIC_PEAK run_time=%.2f frame_ms=%.2f state=%s enemies=%d nodes=%d draw_calls=%d"
		% [
			peak["run_time"], peak["frame_ms"], peak["state"],
			peak["enemies"], peak["nodes"], peak["draw_calls"],
		]
	)


func _write_csv() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	var file := FileAccess.open(OUT_PATH, FileAccess.WRITE)
	if file == null:
		print("PS178_DIAGNOSTIC_WRITE_FAILED path=%s" % OUT_PATH)
		return
	file.store_line("run_time,frame_ms,state,enemies,projectiles,nodes,objects,draw_calls")
	for row in _rows:
		file.store_line("%.3f,%.3f,%s,%d,%d,%d,%d,%d" % [
			row["run_time"], row["frame_ms"], row["state"],
			row["enemies"], row["projectiles"], row["nodes"], row["objects"], row["draw_calls"],
		])
	print("PS178_DIAGNOSTIC_CSV %s" % ProjectSettings.globalize_path(OUT_PATH))
