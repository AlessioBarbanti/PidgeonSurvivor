extends SceneTree

## PS-189: fixture prestazionale a popolazione fissa, ricostruita dal JSON che
## `_diagnose_boss_lag_ps178.gd --dump-fixture` salva nel frame a densita'
## massima. Stessi nemici, posizioni, raggi, velocita' e bersaglio: il
## confronto prima/dopo non dipende dal seed ne' dall'evoluzione della run.
##
## godot_console --headless --path . --script tools/_profile_clone_pileup_ps189.gd --
##   --fixture=exports/diagnostics/ps189-fixture-ps189-fixture.json
## Opzioni: --repeats=20, --label=baseline.
##
## Cosa la fixture NON riproduce (resta diagnostica, non un replay):
## - proiettili in volo, XP, VFX, HUD e rendering;
## - l'attacco a distanza dei Tiratori parte dalla cadenza iniziale;
## - i nemici sono ricostruiti fermi, quindi il primo passo fisico misurato
##   parte da velocity zero.
## Cio' che riproduce e' esattamente cio' che governa il costo misurato:
## popolazione, posizioni, raggi e bersaglio comune.

const OUT_DIR := "res://exports/diagnostics"

var _repeats := 20
var _label := "baseline"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var fixture_path := _argument("--fixture=", "exports/diagnostics/ps189-fixture-ps189-fixture.json")
	_repeats = maxi(int(_argument("--repeats=", "20")), 1)
	_label = _argument("--label=", "baseline")
	var fixture := _load_fixture(fixture_path)
	if fixture.is_empty():
		print("PS189_PROFILE_FAIL reason=fixture_illeggibile path=%s" % fixture_path)
		quit(1)
		return

	var scene_root := Node2D.new()
	root.add_child(scene_root)
	var controller := RunController.new()
	controller.set_process(false)
	scene_root.add_child(controller)
	controller.start_run(189)

	var targeting := TargetingSystem.new()
	scene_root.add_child(targeting)

	var decoy_anchor := Node2D.new()
	decoy_anchor.global_position = Vector2(float(fixture["decoy_x"]), float(fixture["decoy_y"]))
	scene_root.add_child(decoy_anchor)

	var enemies := _spawn_population(scene_root, controller, targeting, decoy_anchor, fixture["enemies"] as Array)
	if enemies.is_empty():
		print("PS189_PROFILE_FAIL reason=popolazione_vuota")
		quit(1)
		return
	await physics_frame

	print("PS189_PROFILE_FIXTURE label=%s enemies=%d max_cell=%d run_time=%.3f repeats=%d" % [
		_label, enemies.size(), int(fixture["max_cell"]), float(fixture["run_time"]), _repeats,
	])
	print("PS189_PROFILE_DENSITY %s" % _describe_density(enemies))

	var grid_ms := _measure_grid_rebuild(controller, enemies)
	var separation_ms := _measure_separation(enemies)
	var nearest_ms := _measure_nearest(targeting, decoy_anchor.global_position)
	var redirect_ms := _measure_redirect(targeting, decoy_anchor)
	var move_ms := _measure_move_only(enemies)
	var step_ms := _measure_physics_step(enemies)

	print("PS189_PROFILE label=%s grid_rebuild_ms=%.3f separation_ms=%.3f move_ms=%.3f nearest_ms=%.3f redirect_ms=%.3f step_ms=%.3f" % [
		_label, grid_ms, separation_ms, move_ms, nearest_ms, redirect_ms, step_ms,
	])
	# Il passo fisico include gia' separazione e riassegnazione di cella: il
	# budget per frame a 60 FPS e' 16,667 ms per un singolo passo.
	print("PS189_PROFILE_BUDGET label=%s step_ms=%.3f budget_ms=16.667 over=%s" % [
		_label, step_ms, "si" if step_ms > 16.667 else "no",
	])

	controller.prepare_restart()
	scene_root.queue_free()
	await process_frame
	await process_frame
	quit(0)


func _load_fixture(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		file = FileAccess.open("res://%s" % path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary or not (parsed as Dictionary).has("enemies"):
		return {}
	return parsed as Dictionary


func _spawn_population(
	parent: Node2D,
	controller: RunController,
	targeting: TargetingSystem,
	decoy_anchor: Node2D,
	rows: Array
) -> Array[BaseEnemy]:
	var enemies: Array[BaseEnemy] = []
	var scene_cache: Dictionary = {}
	for row_value in rows:
		var row := row_value as Dictionary
		var scene_path := String(row["scene"])
		if not scene_cache.has(scene_path):
			scene_cache[scene_path] = load(scene_path) as PackedScene
		var scene := scene_cache[scene_path] as PackedScene
		if scene == null:
			continue
		var enemy := scene.instantiate() as BaseEnemy
		if enemy == null:
			continue
		parent.add_child(enemy)
		enemy.set_physics_process(false)
		enemy.global_position = Vector2(float(row["x"]), float(row["y"]))
		enemy.collision_radius = float(row["radius"])
		enemy.move_speed = float(row["move_speed"])
		enemy.set_pursuit_offset(Vector2(float(row["offset_x"]), float(row["offset_y"])))
		enemy.set_run_controller(controller)
		enemy.set_target(decoy_anchor)
		targeting.register_target(enemy)
		enemies.append(enemy)
	return enemies


## Occupazione delle celle di separazione: e' il numero di vicini che ogni
## query deve scorrere, quindi la variabile indipendente del costo misurato.
func _describe_density(enemies: Array[BaseEnemy]) -> String:
	var cells: Dictionary = {}
	for enemy in enemies:
		var cell := Vector2i(
			floori(enemy.global_position.x / BaseEnemy.SEPARATION_CELL_SIZE),
			floori(enemy.global_position.y / BaseEnemy.SEPARATION_CELL_SIZE)
		)
		cells[cell] = int(cells.get(cell, 0)) + 1
	var occupancies: Array[int] = []
	for cell: Vector2i in cells:
		occupancies.append(int(cells[cell]))
	occupancies.sort()
	return "cells=%d cell_max=%d cell_p50=%d" % [
		occupancies.size(), occupancies[-1], occupancies[occupancies.size() / 2],
	]


func _measure_grid_rebuild(controller: RunController, enemies: Array[BaseEnemy]) -> float:
	var start := Time.get_ticks_usec()
	for _repeat in _repeats:
		BaseEnemy._separation_grids_by_controller.clear()
		enemies[0]._compute_separation_velocity()
	var total_ms := float(Time.get_ticks_usec() - start) / (1000.0 * float(_repeats))
	# Il primo nemico paga anche la propria query: la si sottrae a parte.
	BaseEnemy._separation_grids_by_controller.clear()
	enemies[0]._compute_separation_velocity()
	var start_single := Time.get_ticks_usec()
	for _repeat in _repeats:
		enemies[0]._compute_separation_velocity()
	var single_ms := float(Time.get_ticks_usec() - start_single) / (1000.0 * float(_repeats))
	return maxf(total_ms - single_ms, 0.0)


func _measure_separation(enemies: Array[BaseEnemy]) -> float:
	var checksum := Vector2.ZERO
	enemies[0]._compute_separation_velocity()
	var start := Time.get_ticks_usec()
	for _repeat in _repeats:
		for enemy in enemies:
			checksum += enemy._compute_separation_velocity()
	var elapsed_ms := float(Time.get_ticks_usec() - start) / (1000.0 * float(_repeats))
	print("PS189_PROFILE_CHECKSUM separation=%s" % checksum)
	return elapsed_ms


func _measure_nearest(targeting: TargetingSystem, origin: Vector2) -> float:
	var start := Time.get_ticks_usec()
	for _repeat in _repeats:
		targeting.get_nearest_alive(origin)
	return float(Time.get_ticks_usec() - start) / (1000.0 * float(_repeats))


## Misura il solo ciclo di riassegnazione dei bersagli del clone, con il
## bersaglio gia' assegnato (caso ordinario di tutti i frame dopo il primo).
func _measure_redirect(targeting: TargetingSystem, decoy_anchor: Node2D) -> float:
	for target in targeting.get_alive_targets():
		target.set_target(decoy_anchor)
	var start := Time.get_ticks_usec()
	for _repeat in _repeats:
		for target in targeting.get_alive_targets():
			if target.get_target() != decoy_anchor:
				target.set_target(decoy_anchor)
	return float(Time.get_ticks_usec() - start) / (1000.0 * float(_repeats))


## Solo movimento e collisioni: stessa velocita' di inseguimento del passo
## completo, senza separazione. Sospende la respinta, quindi le posizioni
## divergono dopo il primo passo: e' una misura diagnostica, non un tick di
## gioco valido.
func _measure_move_only(enemies: Array[BaseEnemy]) -> float:
	var start := Time.get_ticks_usec()
	for enemy in enemies:
		enemy.velocity = Vector2.RIGHT * enemy.get_effective_move_speed()
		enemy.move_and_slide()
	return float(Time.get_ticks_usec() - start) / 1000.0


## Un passo fisico completo dell'intera popolazione: separazione, movimento,
## collisioni e riassegnazione di cella insieme, come nel gioco reale.
func _measure_physics_step(enemies: Array[BaseEnemy]) -> float:
	var start := Time.get_ticks_usec()
	for enemy in enemies:
		enemy._physics_process(1.0 / 60.0)
	return float(Time.get_ticks_usec() - start) / 1000.0


func _argument(prefix: String, fallback: String) -> String:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with(prefix):
			return argument.trim_prefix(prefix)
	return fallback
