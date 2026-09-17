extends SceneTree

## PS-178: sonda riproducibile, distinta dai test GUT e dal gate Pixel 9.
## Spawn, nemici, arma, passiva e clone restano attivi. Il percorso sintetico
## mantiene vivo il Player, guida su un'orbita e sceglie il primo upgrade:
## non pretende di riprodurre la build ignota del giocatore.
## Eseguire senza altri benchmark concorrenti; headless misura soltanto CPU.
##
## godot_console --headless --path . --script tools/_diagnose_boss_lag_ps178.gd --
##   --friend=marghe --run-seed=20260915 --tag=marghe-clone
## Opzioni: --mobile-profile, --no-active-ability, --stationary, --run-seconds=126,
## --capture-from=90, --wall-timeout=180. CSV in exports/diagnostics/.

const MOVEMENT_SLICE_SCENE := preload("res://scenes/game/movement_slice.tscn")
const FORCE_WELCOME_SETTING := "application/run/b18o_force_welcome_for_test"
const OUT_DIR := "res://exports/diagnostics"

var _slice: Control
var _controller: RunController
var _player: Player
var _monitor: PerformanceMonitor
var _upgrades: UpgradeService
var _boss: BossEncounter
var _rows: Array[Dictionary] = []
var _start_usec := 0
var _last_tick_usec := 0
var _intro_started_usec := 0
var _capture_from := 90.0
var _run_seconds := 126.0
var _wall_timeout := 180.0
var _active_ability := true
var _stationary := false
var _tag := "marghe-clone"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var friend_id := StringName(_argument("--friend=", "marghe"))
	var seed_value := int(_argument("--run-seed=", "20260915"))
	_capture_from = maxf(float(_argument("--capture-from=", "90")), 0.0)
	_run_seconds = maxf(float(_argument("--run-seconds=", "126")), 0.1)
	_wall_timeout = maxf(float(_argument("--wall-timeout=", "180")), 0.1)
	_active_ability = not OS.get_cmdline_user_args().has("--no-active-ability")
	_stationary = OS.get_cmdline_user_args().has("--stationary")
	_tag = _argument("--tag=", "marghe-clone").validate_filename()
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	var previous_welcome: Variant = ProjectSettings.get_setting(FORCE_WELCOME_SETTING, null)
	ProjectSettings.set_setting(FORCE_WELCOME_SETTING, true)
	_slice = MOVEMENT_SLICE_SCENE.instantiate() as Control
	if OS.get_cmdline_user_args().has("--mobile-profile"):
		_slice.set("windows_performance_profile", _slice.get("mobile_performance_profile"))
	root.add_child(_slice)
	ProjectSettings.set_setting(FORCE_WELCOME_SETTING, previous_welcome)
	await process_frame
	_controller = _slice.call("get_run_controller") as RunController
	_player = _slice.call("get_player") as Player
	_monitor = _slice.call("get_performance_monitor") as PerformanceMonitor
	_upgrades = _slice.call("get_upgrade_service") as UpgradeService
	_boss = _slice.call("get_boss_encounter") as BossEncounter
	if not _slice.call("select_friend_for_next_run", friend_id) or not _slice.call("start_selected_run", seed_value):
		await _finish(false, "avvio_run")
		return
	(_slice.get_node("InputRouter") as InputRouter).set_process(false)
	_player.get_weapon_controller().set_manual_fire_enabled(false)
	_controller.state_changed.connect(_on_state_changed)
	_upgrades.upgrade_selected.connect(_on_upgrade_selected)
	print("PS178_DIAGNOSTIC_START friend=%s seed=%d renderer=%s profile=%s ability=%s stationary=%s assisted_health=true automatic_choices=true" % [
		friend_id, seed_value, DisplayServer.get_name(), _monitor.get_profile().profile_id, _active_ability, _stationary,
	])
	_start_usec = Time.get_ticks_usec()
	_last_tick_usec = _start_usec
	while _controller.get_run_time() < _run_seconds:
		await process_frame
		_record_frame()
		if float(Time.get_ticks_usec() - _start_usec) / 1000000.0 >= _wall_timeout:
			await _finish(false, "wall_timeout")
			return
		if _controller.get_state() == RunController.RunState.DEFEAT:
			await _finish(false, "sconfitta")
			return
		_advance_harness()
	await _finish(true, "finestra_completata")


func _advance_harness() -> void:
	match _controller.get_state():
		RunController.RunState.RUNNING:
			var health := _player.get_health_component()
			health.heal(health.health_max)
			if not _stationary:
				var arena := _slice.call("get_arena_world") as ArenaWorld
				var destination := arena.get_world_center() + Vector2.RIGHT.rotated(_controller.get_run_time() * 0.65) * 250.0
				_player.set_movement_input(_player.global_position.direction_to(destination))
			if _active_ability:
				_player.get_ability_controller().try_activate()
		RunController.RunState.LEVEL_UP:
			var offer := _upgrades.get_current_offer()
			if not offer.is_empty():
				_upgrades.select_upgrade(offer[0].id)
		RunController.RunState.BOSS_INTRO:
			if Time.get_ticks_usec() - _intro_started_usec >= 1000000:
				_boss.complete_intro()
		RunController.RunState.BARB_REWARD:
			var offer := _upgrades.get_current_barb_offer()
			if not offer.is_empty():
				if _upgrades.is_barb_bonus_mode():
					_upgrades.select_barb_bonus_upgrade(offer[0].id)
				else:
					_upgrades.select_barb_speciality(offer[0].id)


func _on_state_changed(_previous: RunController.RunState, current: RunController.RunState) -> void:
	if current == RunController.RunState.BOSS_INTRO:
		_intro_started_usec = Time.get_ticks_usec()
	print("PS178_DIAGNOSTIC_STATE time=%.3f state=%s" % [_controller.get_run_time(), RunController.RunState.keys()[current]])


func _on_upgrade_selected(definition: UpgradeDefinition, rank: int, level: int) -> void:
	print("PS178_DIAGNOSTIC_UPGRADE time=%.3f id=%s rank=%d level=%d" % [_controller.get_run_time(), definition.id, rank, level])


func _record_frame() -> void:
	var now := Time.get_ticks_usec()
	var frame_ms := float(now - _last_tick_usec) / 1000.0
	_last_tick_usec = now
	if _controller.get_run_time() < _capture_from:
		return
	var snapshot := _monitor.get_snapshot()
	snapshot["wall_seconds"] = float(now - _start_usec) / 1000000.0
	snapshot["run_time"] = _controller.get_run_time()
	snapshot["frame_ms"] = frame_ms
	snapshot["state"] = RunController.RunState.keys()[_controller.get_state()]
	_rows.append(snapshot)


func _finish(success: bool, reason: String) -> void:
	var path := "%s/ps178-%s.csv" % [OUT_DIR, _tag]
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		success = false
		reason = "scrittura_csv"
	else:
		file.store_line("wall_seconds,run_time,frame_ms,process_ms,physics_ms,state,enemies,projectiles,pickups,ability_effects,nodes,draw_calls")
		for row in _rows:
			file.store_line("%.3f,%.3f,%.3f,%.3f,%.3f,%s,%d,%d,%d,%d,%d,%d" % [
				row.wall_seconds, row.run_time, row.frame_ms, row.process_ms, row.physics_ms,
				row.state, row.enemies, row.projectiles, row.pickups, row.ability_effects, row.nodes, row.draw_calls,
			])
		file.close()
	for phase: String in ["RUNNING", "BOSS_INTRO", "LEVEL_UP"]:
		_summarize(phase)
	print("PS178_DIAGNOSTIC_%s reason=%s rows=%d csv=%s" % [
		"DONE" if success else "FAIL", reason, _rows.size(), ProjectSettings.globalize_path(path),
	])
	if is_instance_valid(_controller):
		_controller.prepare_restart()
	if is_instance_valid(_slice):
		_slice.queue_free()
	await process_frame
	await process_frame
	quit(0 if success else 1)


func _summarize(phase: String) -> void:
	var frames: Array[float] = []
	var peak_physics := 0.0
	var peak_process := 0.0
	var peak_enemies := 0
	for row in _rows:
		if row.state != phase:
			continue
		frames.append(float(row.frame_ms))
		peak_physics = maxf(peak_physics, float(row.physics_ms))
		peak_process = maxf(peak_process, float(row.process_ms))
		peak_enemies = maxi(peak_enemies, int(row.enemies))
	if frames.is_empty():
		return
	frames.sort()
	print("PS178_DIAGNOSTIC_SUMMARY state=%s frames=%d p95_ms=%.3f max_ms=%.3f physics_max_ms=%.3f process_max_ms=%.3f enemies_max=%d" % [
		phase, frames.size(), frames[mini(ceili(frames.size() * 0.95) - 1, frames.size() - 1)],
		frames[-1], peak_physics, peak_process, peak_enemies,
	])


func _argument(prefix: String, fallback: String) -> String:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with(prefix):
			return argument.trim_prefix(prefix)
	return fallback
