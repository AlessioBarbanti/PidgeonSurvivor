extends SceneTree

## Cattura di sviluppo PS-204 (non un test): Alea con 6 power up diversi, alcuni
## a rango alto, e tutte le Specialità di Barb sbloccate, per giudicare griglia
## e gruppo Specialità nell'HUD. Il profilo 20:9 su desktop non ha il foro
## fotocamera: la striscia fuori dalla safe area si vede solo su device.
const RUN_SCENE := preload("res://scenes/game/movement_slice.tscn")
const OUT_DIR := "res://exports/ui-screenshots/ps204-hud-build"
const PROFILES: Array[Vector2i] = [Vector2i(1280, 720), Vector2i(2424, 1080), Vector2i(960, 720)]
const RUN_SEED := 204204
const EXTRA_RANK_PICKS := 8

var _failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	for profile in PROFILES:
		await _capture(profile)
	print("PS204_CAPTURE_DONE" if not _failed else "CAPTURE_FAIL")
	quit(1 if _failed else 0)


func _capture(profile: Vector2i) -> void:
	root.content_scale_size = profile
	root.size = profile
	DisplayServer.window_set_size(profile)
	await _frames(4)
	ProjectSettings.set_setting("application/run/b18o_force_welcome_for_test", true)
	var slice := RUN_SCENE.instantiate() as Control
	root.add_child(slice)
	ProjectSettings.set_setting("application/run/b18o_force_welcome_for_test", false)
	await _frames(15)
	var lifecycle := slice.call("get_platform_lifecycle") as PlatformLifecycle
	if lifecycle != null:
		lifecycle.get_parent().remove_child(lifecycle)
		lifecycle.free()
	(slice.call("get_welcome_screen") as WelcomeScreen).get_play_button().emit_signal("pressed")
	await _frames(3)
	if not slice.call("select_friend_for_next_run", &"alea") or not slice.call("start_selected_run", RUN_SEED):
		printerr("CAPTURE_FAIL run con Alea non avviata")
		_failed = true
		return
	await _frames(30)
	var controller := slice.call("get_run_controller") as RunController
	var service := slice.call("get_upgrade_service") as UpgradeService
	var experience := slice.call("get_experience_system") as ExperienceSystem
	while not service.get_locked_speciality_definitions().is_empty():
		service.queue_barb_reward()
		service.select_barb_speciality(service.get_current_barb_offer_ids()[0])
	var guard := 0
	var extra := 0
	while (service.get_distinct_upgrade_ids().size() < 6 or extra < EXTRA_RANK_PICKS) and guard < 80:
		guard += 1
		experience.add_experience(experience.get_experience_required())
		var offer := service.get_current_offer_ids()
		var owned := service.get_distinct_upgrade_ids()
		var picked := offer[0]
		for upgrade_id in offer:
			var is_new := not owned.has(upgrade_id) and not service.is_speciality_unlocked(upgrade_id)
			if is_new == (owned.size() < 6):
				picked = upgrade_id
				break
		if owned.size() >= 6:
			extra += 1
		service.select_upgrade(picked)
	await _frames(30)
	if controller.get_state() != RunController.RunState.RUNNING:
		printerr("CAPTURE_FAIL stato %s invece di RUNNING" % controller.get_state())
		_failed = true
	var hud := slice.call("get_hud") as GameHud
	var path := "%s/hud_build_%dx%d.png" % [OUT_DIR, profile.x, profile.y]
	var error := root.get_texture().get_image().save_png(path)
	print("SHOT %s (err %d) grid=%s group=%s slot=%s owned=%s" % [
		path, error, hud.get_upgrade_slot_grid_rect(), hud.get_speciality_group_rect(),
		hud.get_upgrade_slot_size(), service.get_distinct_upgrade_ids(),
	])
	slice.queue_free()
	await _frames(6)


func _frames(count: int) -> void:
	for _index in count:
		await process_frame
