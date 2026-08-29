extends GutGameplayTest

const FRIEND_IDS: Array[StringName] = [&"magno", &"bea", &"zat", &"alea", &"aleo"]
const LAYOUT_PROFILES: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1440, 720),
	Vector2i(1600, 720),
	Vector2i(960, 720),
]


func test_hardening_performance_contract() -> void:
	var movement_slice := await instantiate_movement_slice(LAYOUT_PROFILES[0])

	var monitor := movement_slice.get_performance_monitor() as PerformanceMonitor
	var harness := movement_slice.get_performance_stress_harness() as PerformanceStressHarness
	var profile := movement_slice.get_active_performance_profile() as PerformanceProfile
	assert_true(profile != null and profile.is_valid(), "B18V richiede un profilo valido.")
	assert_true(profile.profile_id == &"windows", "Headless Windows deve selezionare il profilo Windows.")
	assert_true(monitor != null and not monitor.is_overlay_enabled(), "L'overlay deve essere opt-in.")
	assert_not_null(harness, "B18V richiede lo stress harness.")
	if monitor == null or harness == null or profile == null:
		return

	monitor.set_overlay_enabled(true)
	assert_true(monitor.is_overlay_enabled(), "L'overlay debug deve attivarsi esplicitamente.")
	monitor.set_overlay_enabled(false)
	assert_true(not monitor.is_overlay_enabled(), "L'overlay deve potersi disattivare.")

	assert_true(harness.start(60.0), "Lo stress harness deve avviarsi in debug.")
	await wait_process_frames(1)
	await wait_physics_frames(1)
	assert_true(
		harness.get_active_stress_count() == harness.get_expected_stress_count(),
		"Lo stress deve mantenere tutte le entita reali dichiarate."
	)
	var snapshot := monitor.get_snapshot()
	for key in [
		"fps", "frame_ms", "nodes", "enemies", "projectiles", "pickups", "ability_effects",
		"feedback", "audio_voices"
	]:
		assert_true(snapshot.has(key), "Snapshot B18V privo di %s." % key)
	assert_true(int(snapshot.get("audio_voices", -1)) <= 12, "Il pool audio B18 non deve crescere.")
	harness.stop()
	await wait_process_frames(1)
	await wait_physics_frames(1)
	assert_eq(harness.get_active_stress_count(), 0, "Stop stress deve liberare tutte le fixture.")

	for index in FRIEND_IDS.size():
		assert_true(
			movement_slice.run_b18v_restart_profile_cycle(FRIEND_IDS[index], 91801 + index),
			"Ciclo B18V %d deve riaprire una run pulita." % (index + 1)
		)
		await wait_process_frames(1)
		assert_true(
			movement_slice.get_run_controller().is_running(),
			"Il ciclo B18V %d deve finire in RUNNING." % (index + 1)
		)
		assert_true(
			movement_slice.get_ability_effect_parent().get_child_count() == 0
			and movement_slice.get_projectile_parent().get_child_count() == 0
			and movement_slice.get_pickup_parent().get_child_count() == 0,
			"Il ciclo B18V %d non deve lasciare residui runtime." % (index + 1)
		)

	for viewport_size in LAYOUT_PROFILES:
		get_tree().root.content_scale_size = viewport_size
		get_tree().root.size = viewport_size
		await wait_process_frames(2)
		assert_true(
			movement_slice.get_arena_layout().get_playfield_rect().has_area(),
			"%s: il playfield B18V deve restare valido." % viewport_size
		)
		assert_true(
			monitor.get_profile() == profile,
			"%s: il resize non deve cambiare profilo." % viewport_size
		)
