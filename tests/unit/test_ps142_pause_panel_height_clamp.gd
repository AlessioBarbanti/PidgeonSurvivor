extends GutGameplayTest

## PS-142: `_clamp_pause_scroll_height()` deve restare un tetto (mai un
## pavimento) sull'altezza del pannello pausa. Verifica che, appena dopo
## l'apertura, l'altezza assegnata allo scroll corrisponda all'altezza
## naturale del VBox (entro tolleranza), su due profili di viewport diversi,
## e non a un valore stale/residuo più grande calcolato prima che il layout
## avesse processato la dimensione reale di bottoni/testo.

const HEIGHT_TOLERANCE := 2.0

const VIEWPORT_PROFILES := [
	Vector2i(1280, 720),
	Vector2i(2424, 1080),
]


func test_ps142_pause_scroll_height_matches_natural_content_height() -> void:
	for profile in VIEWPORT_PROFILES:
		var movement_slice := await instantiate_movement_slice(profile)
		var controller := movement_slice.get_run_controller() as RunController
		var overlay := movement_slice.get_pause_overlay() as PauseOverlay
		assert_true(
			controller != null and overlay != null, "PS-142 richiede RunController/PauseOverlay dalla scena."
		)
		if controller == null or overlay == null:
			continue

		assert_true(controller.request_manual_pause(), "PS-142 richiede di poter aprire la pausa manuale.")
		await wait_process_frames(1)

		var natural_height := overlay.get_pause_content_natural_height()
		var assigned_height := overlay.get_pause_scroll_min_height()
		assert_true(
			natural_height > 0.0, "%s: il VBox della pausa deve avere un'altezza naturale misurabile." % profile
		)
		assert_almost_eq(
			assigned_height, natural_height, HEIGHT_TOLERANCE,
			(
				"%s: l'altezza assegnata allo scroll pausa (%s) deve corrispondere all'altezza naturale del VBox (%s), non a un pavimento stale."
				% [profile, assigned_height, natural_height]
			)
		)

		controller.request_defeat()
		await wait_process_frames(1)


func test_ps142_pause_scroll_height_still_caps_on_a_tight_viewport() -> void:
	var movement_slice := await instantiate_movement_slice(Vector2i(1280, 200))
	var controller := movement_slice.get_run_controller() as RunController
	var overlay := movement_slice.get_pause_overlay() as PauseOverlay
	assert_true(controller != null and overlay != null, "PS-142 richiede RunController/PauseOverlay dalla scena.")
	if controller == null or overlay == null:
		return

	assert_true(controller.request_manual_pause(), "PS-142 richiede di poter aprire la pausa manuale.")
	await wait_process_frames(1)

	var natural_height := overlay.get_pause_content_natural_height()
	var assigned_height := overlay.get_pause_scroll_min_height()
	assert_true(
		assigned_height <= natural_height + HEIGHT_TOLERANCE,
		"Il clamp deve restare un tetto: l'assegnato (%s) non deve superare il naturale (%s)."
		% [assigned_height, natural_height]
	)
	assert_true(
		assigned_height < natural_height - HEIGHT_TOLERANCE,
		"Su un viewport molto compatto (PS-085) il clamp deve ancora restringere sotto il naturale (%s vs %s)."
		% [assigned_height, natural_height]
	)

	controller.request_defeat()

	print("PS142_PAUSE_PANEL_HEIGHT_OK")


func test_ps142_pause_scroll_height_stays_correct_after_runtime_resize() -> void:
	var movement_slice := await instantiate_movement_slice(Vector2i(1280, 720))
	var controller := movement_slice.get_run_controller() as RunController
	var overlay := movement_slice.get_pause_overlay() as PauseOverlay
	assert_true(controller != null and overlay != null, "PS-142 richiede RunController/PauseOverlay dalla scena.")
	if controller == null or overlay == null:
		return

	assert_true(controller.request_manual_pause(), "PS-142 richiede di poter aprire la pausa manuale.")
	await wait_process_frames(1)

	get_tree().root.content_scale_size = Vector2i(1280, 200)
	get_tree().root.size = Vector2i(1280, 200)
	await wait_process_frames(2)

	var natural_height := overlay.get_pause_content_natural_height()
	var assigned_height := overlay.get_pause_scroll_min_height()
	assert_true(
		assigned_height < natural_height - HEIGHT_TOLERANCE,
		"Dopo un resize a runtime verso un viewport compatto il clamp deve ancora restringersi (%s vs %s)."
		% [assigned_height, natural_height]
	)

	get_tree().root.content_scale_size = Vector2i(1280, 720)
	get_tree().root.size = Vector2i(1280, 720)
	await wait_process_frames(2)

	natural_height = overlay.get_pause_content_natural_height()
	assigned_height = overlay.get_pause_scroll_min_height()
	assert_almost_eq(
		assigned_height, natural_height, HEIGHT_TOLERANCE,
		(
			"Dopo un resize a runtime verso un viewport ampio il clamp deve tornare all'altezza naturale (%s vs %s)."
			% [assigned_height, natural_height]
		)
	)

	controller.request_defeat()
