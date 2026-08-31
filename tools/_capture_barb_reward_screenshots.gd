extends SceneTree

## Utility visiva PS-036: cattura entrambe le modalita dell'overlay Barb in
## una fixture deterministica, senza lasciare che il gameplay apra altri modali.

const BARB_OVERLAY_SCENE := preload("res://scenes/ui/barb_reward_overlay.tscn")
const GOSSIP := preload("res://data/upgrades/specialities/gossip_projectiles.tres")
const PIERCING_ROUNDS := preload("res://data/upgrades/specialities/piercing_rounds.tres")
const DOUBLE_BARREL := preload("res://data/upgrades/specialities/double_barrel.tres")
const DEATH_BURST := preload("res://data/upgrades/specialities/death_burst.tres")
const SWIFT_STEPS := preload("res://data/upgrades/swift_steps.tres")
const RAPID_FIRE := preload("res://data/upgrades/rapid_fire.tres")
const WIDE_MAGNET := preload("res://data/upgrades/wide_magnet.tres")
const MEAT_FORK_DAMAGE := preload("res://data/upgrades/meat_fork_damage.tres")
const OUT_DIR := "res://exports/ui-screenshots/ps036"
const VIEWPORT_SIZE := Vector2i(1280, 720)

var _fixture: Control
var _controller: RunController
var _service: UpgradeService
var _overlay: BarbRewardOverlay


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	paused = false
	root.content_scale_size = VIEWPORT_SIZE
	root.size = VIEWPORT_SIZE
	DisplayServer.window_set_size(VIEWPORT_SIZE)
	await _frames(4)
	if not await _build_fixture():
		quit(1)
		return

	_service.queue_barb_reward()
	await _frames(12)
	var portrait := _overlay.find_child("BarbPortrait", true, false) as TextureRect
	print(
		"PS036_PORTRAIT rect=%s visible=%s texture=%s" % [
			portrait.get_global_rect() if portrait != null else Rect2(),
			portrait.visible if portrait != null else false,
			portrait.texture.resource_path if portrait != null and portrait.texture != null else "",
		]
	)
	await _shot("01_barb_speciality")

	while not _service.get_locked_speciality_definitions().is_empty():
		var offer := _service.get_current_barb_offer()
		if offer.is_empty() or not _service.select_barb_speciality(offer[0].id):
			printerr("PS036_CAPTURE_FAIL speciality")
			quit(1)
			return
		if not _service.get_locked_speciality_definitions().is_empty():
			_service.queue_barb_reward()

	_service.queue_barb_reward()
	await _frames(12)
	if not _overlay.visible or not _service.is_barb_bonus_mode():
		printerr("PS036_CAPTURE_FAIL bonus")
		quit(1)
		return
	await _shot("02_barb_bonus")

	print("PS036_CAPTURE_DONE")
	quit(0)


func _build_fixture() -> bool:
	_fixture = Control.new()
	_fixture.name = "BarbCaptureFixture"
	_fixture.process_mode = Node.PROCESS_MODE_ALWAYS
	_fixture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_controller = RunController.new()
	_controller.name = "RunController"
	_controller.set_process(false)
	var experience := ExperienceSystem.new()
	experience.name = "ExperienceSystem"
	var curve := ExperienceCurve.new()
	curve.base_experience_required = 1
	curve.experience_growth_per_level = 0
	experience.experience_curve = curve
	var registry := UpgradeRegistry.new()
	registry.name = "UpgradeRegistry"
	var definitions: Array[UpgradeDefinition] = [
		GOSSIP,
		PIERCING_ROUNDS,
		DOUBLE_BARREL,
		DEATH_BURST,
		SWIFT_STEPS,
		RAPID_FIRE,
		WIDE_MAGNET,
		MEAT_FORK_DAMAGE,
	]
	registry.definitions = definitions
	_service = UpgradeService.new()
	_service.name = "UpgradeService"
	_overlay = BARB_OVERLAY_SCENE.instantiate() as BarbRewardOverlay
	_overlay.name = "BarbRewardOverlay"

	_fixture.add_child(_controller)
	_fixture.add_child(experience)
	_fixture.add_child(registry)
	_fixture.add_child(_service)
	_fixture.add_child(_overlay)
	root.add_child(_fixture)
	await _frames(3)

	experience.set_run_controller(_controller)
	return (
		registry.rebuild_registry()
		and _service.configure(registry, _controller, experience)
		and _overlay.configure(_service)
		and _controller.start_run(360036)
	)


func _shot(shot_name: String) -> void:
	await _frames(3)
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	var image := root.get_texture().get_image()
	if image == null:
		printerr("PS036_CAPTURE_FAIL image %s" % shot_name)
		return
	var path := "%s/%s.png" % [OUT_DIR, shot_name]
	var error := image.save_png(path)
	print("PS036_SHOT %s err=%d" % [path, error])


func _frames(count: int) -> void:
	for _index in count:
		await process_frame
