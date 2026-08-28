extends SceneTree

## Utility di sviluppo (non un test): cattura le sei pagine del tutorial B54 e
## una sequenza temporale di due cicli completi sulle pagine animate, così la
## revisione percettiva non si basa sul solo primo/ultimo frame.

const MOVEMENT_SLICE_SCENE := preload("res://scenes/game/movement_slice.tscn")
## `exports/` è ignorato da git: le catture restano artefatti locali.
const OUT_DIR := "res://exports/ui-screenshots/b54-tutorial"
const VIEWPORT_SIZE := Vector2i(1280, 720)
const PAGE_IDS: Array[String] = [
	"objective",
	"movement",
	"ability",
	"progression",
	"enemies",
	"boss",
]
## Pagine con animazione: indice, passo di campionamento e numero di scatti che
## coprono due periodi interi del loop.
const LOOP_PAGES: Array[int] = [2, 3, 4]
const LOOP_STEP_SECONDS := 0.5
const LOOP_SHOT_COUNT := 25
## Profili verificati: 16:9, Pixel 9 20:9 e 4:3.
const ASPECT_PROFILES: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 720),
	Vector2i(960, 720),
]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	paused = false
	root.content_scale_size = VIEWPORT_SIZE
	root.size = VIEWPORT_SIZE
	DisplayServer.window_set_size(VIEWPORT_SIZE)
	await _frames(6)

	ProjectSettings.set_setting("application/run/b18o_force_welcome_for_test", true)
	var slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	root.add_child(slice)
	ProjectSettings.set_setting("application/run/b18o_force_welcome_for_test", false)
	await _frames(20)

	var welcome := slice.get_welcome_screen() as WelcomeScreen
	welcome.get_tutorial_button().pressed.emit()
	await _frames(24)

	var tutorial := slice.get_tutorial_screen() as TutorialScreen
	for index in tutorial.get_page_count():
		tutorial.show_page(index)
		await _frames(16)
		await _shot("page_%02d_%s" % [index + 1, PAGE_IDS[index]])

	for index in LOOP_PAGES:
		tutorial.show_page(index)
		await _frames(16)
		for step in LOOP_SHOT_COUNT:
			await _shot("loop_%s_%02d" % [PAGE_IDS[index], step])
			await _timeout(LOOP_STEP_SECONDS)
		print(
			"LOOP_COVERAGE page=%s seconds=%.1f period=%.1f"
			% [
				PAGE_IDS[index],
				float(LOOP_SHOT_COUNT - 1) * LOOP_STEP_SECONDS,
				TutorialPreview.LOOP_PERIOD,
			]
		)

	for profile in ASPECT_PROFILES:
		root.content_scale_size = profile
		root.size = profile
		DisplayServer.window_set_size(profile)
		await _frames(6)
		var arena := slice.get_arena_layout() as ArenaLayout
		arena.refresh_layout()
		await _frames(12)
		tutorial.show_page(4)
		await _frames(16)
		await _shot("aspect_%dx%d" % [profile.x, profile.y])
		print(
			"ASPECT %dx%d backdrop=%s viewport=%s panel=%s"
			% [
				profile.x,
				profile.y,
				tutorial.get_backdrop_rect(),
				root.get_visible_rect(),
				tutorial.get_main_panel_rect(),
			]
		)

	print("B54_TUTORIAL_CAPTURE_DONE")
	quit(0)


func _shot(shot_name: String) -> void:
	await _frames(2)
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	var image := root.get_texture().get_image()
	if image == null:
		printerr("Nessuna immagine per %s" % shot_name)
		return
	var path := "%s/%s.png" % [OUT_DIR, shot_name]
	var error := image.save_png(path)
	print("SHOT %s -> %s (err %d)" % [shot_name, path, error])


func _frames(count: int) -> void:
	for _index in count:
		await process_frame


func _timeout(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout
