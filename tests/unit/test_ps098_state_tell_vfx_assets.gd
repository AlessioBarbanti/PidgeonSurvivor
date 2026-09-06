extends GutTest

const RUNTIME_PATHS: Array[String] = [
	"res://assets/art/vfx/state_tells/generated/hyperfocus_aura.png",
	"res://assets/art/vfx/state_tells/generated/thermal_aura_hot.png",
	"res://assets/art/vfx/state_tells/generated/thermal_aura_cold.png",
	"res://assets/art/vfx/state_tells/generated/thermometer_hot.png",
	"res://assets/art/vfx/state_tells/generated/thermometer_cold.png",
]


func test_ps098_state_tell_vfx_assets_are_square_imported_and_transparent() -> void:
	for path in RUNTIME_PATHS:
		assert_true(FileAccess.file_exists(path), "PS-098: derivato runtime mancante: %s." % path)
		var texture := load(path) as Texture2D
		assert_not_null(texture, "PS-098: il derivato deve importarsi come Texture2D: %s." % path)
		if texture == null:
			continue
		assert_eq(
			texture.get_size(), Vector2(512.0, 512.0),
			"PS-098: il derivato deve usare il canvas quadrato 512x512: %s." % path
		)
		var image := texture.get_image()
		assert_not_null(image, "PS-098: il derivato deve esporre pixel ispezionabili: %s." % path)
		if image == null:
			continue
		assert_true(
			image.get_pixel(0, 0).a < 0.04,
			"PS-098: il derivato deve mantenere angoli trasparenti: %s." % path
		)

	print("STATE_TELL_VFX_ASSETS_SMOKE_OK")
