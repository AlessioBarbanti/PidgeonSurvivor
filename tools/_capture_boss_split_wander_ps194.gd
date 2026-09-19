extends SceneTree

## Cattura di sviluppo con renderer Windows reale (PS-193/PS-194). La run gira
## a frame veri: si misura la cadenza d'attacco osservata e si fotografa la
## copia fantasma in istanti diversi, per mostrare che passeggia invece di
## orbitare. Non sostituisce una partita ne' l'approvazione percettiva owner.
const RUN_SCENE := preload("res://scenes/game/movement_slice.tscn")
const OUT_DIR := "res://exports/ui-screenshots/ps194-boss-split-wander"
const SHOT_COUNT := 5
const SHOT_INTERVAL_SECONDS := 3.4

var _slice: Control
var _boss: FirstBoss
var _controller: RunController
var _encounter: BossEncounter
var _failed := false
var _telegraph_starts := 0
var _telegraph_was_active := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	DisplayServer.window_set_size(root.size)
	ProjectSettings.set_setting("application/run/b18o_force_welcome_for_test", true)
	_slice = RUN_SCENE.instantiate() as Control
	root.add_child(_slice)
	ProjectSettings.set_setting("application/run/b18o_force_welcome_for_test", false)
	await _frames(15)
	var lifecycle := _slice.call("get_platform_lifecycle") as PlatformLifecycle
	if lifecycle != null:
		lifecycle.get_parent().remove_child(lifecycle)
		lifecycle.free()
	var welcome := _slice.call("get_welcome_screen") as WelcomeScreen
	welcome.get_play_button().emit_signal("pressed")
	await _frames(3)
	_slice.call("start_selected_run", 193194)
	await _frames(3)
	_controller = _slice.call("get_run_controller") as RunController
	_encounter = _slice.call("get_boss_encounter") as BossEncounter
	var player := _slice.call("get_player") as Player
	_encounter.evil_boss_chance = 0.0
	var director := _slice.call("get_game_director") as GameDirector
	director.call("_evaluate_run_time", director.get_thresholds()[0])
	_boss = _encounter.get_active_boss()
	if _boss == null:
		printerr("CAPTURE_FAIL boss non creato")
		quit(1)
		return
	_encounter.complete_intro()
	# Il Boss resta fermo e lontano: la prova riguarda cadenza e copia, non
	# l'inseguimento ne' il danno da contatto.
	_boss.move_speed = 0.0
	player.global_position = _boss.global_position + Vector2(520.0, 240.0)
	_boss.take_damage(_boss.get_health_component().health_max * 0.5)
	print("PS194_SPLIT_ACTIVE %s" % _boss.is_split_active())
	DirAccess.make_dir_recursive_absolute(OUT_DIR)

	# Il tempo di riferimento e' quello logico del RunController, non il wall
	# clock: a frame lenti le due misure divergono e il giocatore vive il primo.
	var started_at := _controller.get_run_time()
	for index in SHOT_COUNT:
		var window_start := _controller.get_run_time()
		while _controller.get_run_time() - window_start < SHOT_INTERVAL_SECONDS:
			await process_frame
			_sample_telegraph()
		await _shot("split_%02d" % index, _controller.get_run_time() - started_at)
	var elapsed := _controller.get_run_time() - started_at
	var resolved := maxi(_telegraph_starts - 1, 0)
	print("PS193_CADENCE_OBSERVED telegraph_starts=%d seconds=%.2f average=%.2f" % [
		_telegraph_starts,
		elapsed,
		(elapsed / float(resolved)) if resolved > 0 else -1.0,
	])
	print("PS194_CAPTURE_DONE" if not _failed else "CAPTURE_FAIL")
	quit(1 if _failed else 0)


func _sample_telegraph() -> void:
	var active := _boss.is_telegraph_active()
	if active and not _telegraph_was_active:
		_telegraph_starts += 1
	_telegraph_was_active = active


func _shot(label: String, elapsed: float) -> void:
	await RenderingServer.frame_post_draw
	var screenshot := root.get_texture().get_image()
	var path := "%s/%s.png" % [OUT_DIR, label]
	var error := screenshot.save_png(path)
	_failed = _failed or error != OK or not _controller.is_running()
	print("PS194_SHOT %s error=%d t=%.2f ghost=%s running=%s" % [
		path,
		error,
		elapsed,
		_boss.get_split_ghost_offset(),
		_controller.is_running(),
	])


func _frames(count: int) -> void:
	for index: int in count:
		await process_frame
