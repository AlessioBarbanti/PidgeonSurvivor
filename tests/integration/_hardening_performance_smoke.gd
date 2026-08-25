extends SceneTree

const MOVEMENT_SLICE_SCENE := preload("res://scenes/game/movement_slice.tscn")
const LAYOUT_PROFILES: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1440, 720),
	Vector2i(1600, 720),
	Vector2i(960, 720),
]
const FRIEND_IDS: Array[StringName] = [&"magno", &"bea", &"zat", &"alea", &"aleo"]

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	paused = false
	root.content_scale_size = LAYOUT_PROFILES[0]
	root.size = LAYOUT_PROFILES[0]
	await process_frame
	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	root.add_child(movement_slice)
	await process_frame
	await physics_frame

	var monitor := movement_slice.get_performance_monitor() as PerformanceMonitor
	var harness := movement_slice.get_performance_stress_harness() as PerformanceStressHarness
	var profile := movement_slice.get_active_performance_profile() as PerformanceProfile
	_expect(profile != null and profile.is_valid(), "B18V richiede un profilo valido.")
	_expect(profile.profile_id == &"windows", "Headless Windows deve selezionare il profilo Windows.")
	_expect(monitor != null and not monitor.is_overlay_enabled(), "L'overlay deve essere opt-in.")
	_expect(harness != null, "B18V richiede lo stress harness.")
	if monitor == null or harness == null or profile == null:
		await _finish(movement_slice)
		return

	monitor.set_overlay_enabled(true)
	_expect(monitor.is_overlay_enabled(), "L'overlay debug deve attivarsi esplicitamente.")
	monitor.set_overlay_enabled(false)
	_expect(not monitor.is_overlay_enabled(), "L'overlay deve potersi disattivare.")

	_expect(harness.start(60.0), "Lo stress harness deve avviarsi in debug.")
	await process_frame
	await physics_frame
	_expect(
		harness.get_active_stress_count() == harness.get_expected_stress_count(),
		"Lo stress deve mantenere tutte le entita reali dichiarate."
	)
	var snapshot := monitor.get_snapshot()
	for key in ["fps", "frame_ms", "nodes", "enemies", "projectiles", "pickups", "ability_effects", "feedback", "audio_voices"]:
		_expect(snapshot.has(key), "Snapshot B18V privo di %s." % key)
	_expect(int(snapshot.get("audio_voices", -1)) <= 12, "Il pool audio B18 non deve crescere.")
	harness.stop()
	await process_frame
	await physics_frame
	_expect(harness.get_active_stress_count() == 0, "Stop stress deve liberare tutte le fixture.")

	for index in FRIEND_IDS.size():
		_expect(
			movement_slice.run_b18v_restart_profile_cycle(FRIEND_IDS[index], 91801 + index),
			"Ciclo B18V %d deve riaprire una run pulita." % (index + 1)
		)
		await process_frame
		_expect(
			movement_slice.get_run_controller().is_running(),
			"Il ciclo B18V %d deve finire in RUNNING." % (index + 1)
		)
		_expect(
			movement_slice.get_ability_effect_parent().get_child_count() == 0
			and movement_slice.get_projectile_parent().get_child_count() == 0
			and movement_slice.get_pickup_parent().get_child_count() == 0,
			"Il ciclo B18V %d non deve lasciare residui runtime." % (index + 1)
		)

	for viewport_size in LAYOUT_PROFILES:
		root.content_scale_size = viewport_size
		root.size = viewport_size
		await process_frame
		_expect(
			movement_slice.get_arena_layout().get_playfield_rect().has_area(),
			"%s: il playfield B18V deve restare valido." % viewport_size
		)
		_expect(
			monitor.get_profile() == profile,
			"%s: il resize non deve cambiare profilo." % viewport_size
		)

	await _finish(movement_slice)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish(movement_slice: Control) -> void:
	if is_instance_valid(movement_slice):
		movement_slice.queue_free()
	await process_frame
	if _failures.is_empty():
		print("B18V_HARDENING_PERFORMANCE_SMOKE_OK")
		quit(0)
		return
	for failure in _failures:
		printerr(failure)
	printerr("B18V_HARDENING_PERFORMANCE_SMOKE_FAIL count=%d" % _failures.size())
	quit(1)
