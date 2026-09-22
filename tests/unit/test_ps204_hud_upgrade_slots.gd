extends GutGameplayTest

## PS-204 — Griglia HUD dei power up presi (3 righe × 2 colonne, tetto
## PS-203) e griglia separata delle Specialità di Barb (4 × 2), dal bordo
## sinistro del viewport, sopra e sotto la fascia libera del foro fotocamera.
## Il calice di Alea sta a destra della griglia.

const HUD_SCENE := preload("res://scenes/ui/hud.tscn")
const MOVEMENT_SLICE_SCRIPT := preload("res://scripts/game/movement_slice.gd")
const LAYOUT_PROFILES: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 720),
	Vector2i(960, 720),
]
const COMPACT_PROFILE := Vector2i(960, 720)
const ALEA_ID := &"alea"
## Caselle "circa il doppio" della prima stesura (32 px), richiesta owner.
const MIN_EXPECTED_SLOT_SIZE := 60.0


func test_slots_follow_acquisition_order_ranks_and_reset() -> void:
	var slice := await instantiate_movement_slice()
	var controller := slice.get_run_controller() as RunController
	var service := slice.get_upgrade_service() as UpgradeService
	var hud := slice.get_hud() as GameHud
	controller.set_process(false)

	var slots := hud.get_upgrade_slots()
	assert_eq(slots.size(), service.get_distinct_upgrade_cap(), "Tante caselle quanto il tetto PS-203.")
	for slot in slots:
		assert_false(slot.is_filled(), "A inizio run le caselle sono vuote ma presenti.")
		assert_true(slot.visible)

	var expected_order: Array[StringName] = []
	for _pick in 10:
		var picked := _level_up_preferring_owned(slice, expected_order)
		if not expected_order.has(picked):
			expected_order.append(picked)
		for index in slots.size():
			if index < expected_order.size():
				assert_eq(slots[index].get_upgrade_id(), expected_order[index], "Ordine di acquisizione, riga per riga.")
				assert_eq(slots[index].get_rank(), service.get_rank(expected_order[index]), "Il rango segue la build.")
			else:
				assert_false(slots[index].is_filled())
	assert_true(
		slots[0].get_rank() > 1, "Salire di rango aggiorna la stessa casella (prima scelta ripresa)."
	)

	_unlock_speciality(service)
	await wait_process_frames(1)
	var group := hud.get_speciality_slots()
	assert_eq(group.size(), 8, "Una casella per ogni Specialità del catalogo.")
	assert_eq(_filled_count(group), 1, "Solo la Specialità sbloccata compare nel gruppo separato.")
	assert_true(service.is_speciality_unlocked(group[0].get_upgrade_id()))
	assert_eq(group[0].get_rank_color(), HudUpgradeSlot.SPECIALITY_RANK_COLOR, "Trattamento oro PS-164.")
	for slot in slots:
		assert_false(service.is_speciality_unlocked(slot.get_upgrade_id()), "Mai una Specialità nelle 6 caselle.")

	assert_true(slice.run_b18v_restart_profile_cycle(ALEA_ID, 20401), "Cambio personaggio verso Alea.")
	await wait_process_frames(1)
	for slot in hud.get_upgrade_slots():
		assert_false(slot.is_filled(), "Il cambio personaggio svuota le caselle.")
	assert_eq(_filled_count(hud.get_speciality_slots()), 0, "Il cambio personaggio svuota il gruppo Specialità.")
	_level_up_preferring_owned(slice, [])
	controller.prepare_restart()
	await wait_process_frames(1)
	for slot in hud.get_upgrade_slots():
		assert_false(slot.is_filled(), "Il restart svuota le caselle.")


func test_layout_stays_in_the_left_strip_around_the_camera_band() -> void:
	for profile in LAYOUT_PROFILES:
		var slice := await instantiate_movement_slice(profile)
		var hud := slice.get_hud() as GameHud
		var registry := slice.get_friend_registry() as FriendRegistry
		(slice.get_run_controller() as RunController).set_process(false)
		hud.set_friend_definition(registry.resolve_definition(ALEA_ID))
		await wait_process_frames(1)
		_assert_layout(slice, hud, "%dx%d" % [profile.x, profile.y])
		(slice.get_run_controller() as RunController).prepare_restart()


func test_compact_profile_holds_a_full_build_and_every_speciality() -> void:
	var slice := await instantiate_movement_slice(COMPACT_PROFILE)
	var controller := slice.get_run_controller() as RunController
	var service := slice.get_upgrade_service() as UpgradeService
	var hud := slice.get_hud() as GameHud
	controller.set_process(false)
	hud.set_friend_definition(slice.get_friend_registry().resolve_definition(ALEA_ID))
	while not service.get_locked_speciality_definitions().is_empty():
		_unlock_speciality(service)
	var guard := 0
	while service.get_distinct_upgrade_ids().size() < service.get_distinct_upgrade_cap() and guard < 60:
		_level_up_preferring_new(slice)
		guard += 1
	await wait_process_frames(1)
	assert_eq(_filled_count(hud.get_upgrade_slots()), 6, "Sei caselle piene.")
	assert_eq(_filled_count(hud.get_speciality_slots()), 8, "Tutte le otto Specialità nel gruppo.")
	for slot in hud.get_speciality_slots():
		assert_true(hud.get_speciality_group_rect().encloses(slot.get_global_rect()), "Specialità dentro il gruppo.")
	for slot in hud.get_upgrade_slots():
		assert_true(hud.get_upgrade_slot_grid_rect().encloses(slot.get_global_rect()), "Casella dentro la griglia.")
	_assert_layout(slice, hud, "960x720 piena")
	controller.prepare_restart()


func test_cutout_profile_puts_the_first_column_in_the_outer_strip() -> void:
	var slice := await instantiate_movement_slice(Vector2i(1600, 720))
	(slice.get_run_controller() as RunController).set_process(false)
	var viewport_rect := Rect2(0.0, 0.0, 1600.0, 720.0)
	var safe_rect := Rect2(64.0, 20.0, 1472.0, 680.0)
	var safe_root := Control.new()
	safe_root.position = safe_rect.position
	safe_root.size = safe_rect.size
	var hud := HUD_SCENE.instantiate() as GameHud
	safe_root.add_child(hud)
	add_child_autofree(safe_root)
	await wait_process_frames(2)
	assert_true(hud.configure_upgrade_service(slice.get_upgrade_service()))
	var margin := viewport_rect.size.x * GameHud.BAR_HORIZONTAL_MARGIN_RATIO
	hud.set_bar_horizontal_offsets(margin - safe_rect.position.x, viewport_rect.end.x - margin - safe_rect.end.x)
	var joystick_rect: Rect2 = MOVEMENT_SLICE_SCRIPT.calculate_bottom_left_control_rect(
		safe_rect, Vector2(224.0, 224.0), Vector2(24.0, 24.0), Vector2(16.0, 32.0)
	)
	var obstacles: Array[Rect2] = [hud.get_ability_panel_rect()]
	hud.layout_upgrade_slots(viewport_rect, safe_rect.position.y, obstacles)
	await wait_process_frames(1)
	# Con caselle doppie la colonna non entra tutta nella striscia: ci parte.
	var first_slot := hud.get_upgrade_slots()[0].get_global_rect()
	assert_true(first_slot.position.x < safe_rect.position.x, "La griglia parte nella striscia esterna.")
	assert_true(
		hud.get_speciality_slots()[0].get_global_rect().position.x < safe_rect.position.x,
		"Il gruppo Specialità parte nella striscia esterna."
	)
	assert_false(hud.get_upgrade_slot_grid_rect().intersects(hud.get_sobriety_icon_rect()), "Calice libero.")
	print("PS204_CUTOUT grid=%s group=%s joystick_rest=%s" % [
		hud.get_upgrade_slot_grid_rect(), hud.get_speciality_group_rect(), joystick_rect
	])


func _assert_layout(slice: Control, hud: GameHud, context: String) -> void:
	var viewport_rect := slice.get_viewport().get_visible_rect()
	var grid := hud.get_upgrade_slot_grid_rect()
	var group := hud.get_speciality_group_rect()
	var band_top := viewport_rect.get_center().y - hud.camera_hole_band_height * 0.5
	var band_bottom := viewport_rect.get_center().y + hud.camera_hole_band_height * 0.5
	assert_true(grid.has_area() and group.has_area(), "%s: griglia e gruppo hanno un'area." % context)
	assert_true(viewport_rect.encloses(grid) and viewport_rect.encloses(group), "%s: dentro il viewport." % context)
	assert_true(
		grid.position.x - viewport_rect.position.x <= GameHud.UPGRADE_SLOT_EDGE_PADDING + 0.5,
		"%s: la griglia parte dal bordo sinistro del viewport." % context
	)
	assert_true(grid.end.y <= band_top, "%s: griglia sopra la fascia del foro." % context)
	assert_true(group.position.y >= band_bottom, "%s: gruppo Specialità sotto la fascia." % context)
	var slot_size := hud.get_upgrade_slot_size()
	var step := slot_size + GameHud.UPGRADE_SLOT_GAP
	assert_true(slot_size >= MIN_EXPECTED_SLOT_SIZE, "%s: caselle circa doppie (%s px)." % [context, slot_size])
	assert_almost_eq(grid.size, Vector2(2.0 * step, 3.0 * step) - Vector2.ONE * GameHud.UPGRADE_SLOT_GAP,
		Vector2.ONE * 0.5, "%s: griglia 3 righe × 2 colonne." % context)
	assert_almost_eq(group.size, Vector2(2.0 * step, 4.0 * step) - Vector2.ONE * GameHud.UPGRADE_SLOT_GAP,
		Vector2.ONE * 0.5, "%s: Specialità 4 righe × 2 colonne." % context)
	assert_true(
		hud.get_sobriety_icon_rect().position.x >= grid.end.x, "%s: il calice sta a destra della griglia." % context
	)
	for obstacle: Rect2 in [
		hud.get_sobriety_icon_rect(),
		hud.get_experience_panel_rect(),
		hud.get_health_panel_rect(),
		hud.get_ability_panel_rect(),
	]:
		assert_false(grid.intersects(obstacle), "%s: la griglia non copre %s." % [context, obstacle])
		assert_false(group.intersects(obstacle), "%s: il gruppo non copre %s." % [context, obstacle])
	# La fascia alta esclude già i tocchi di suo: la lista non aggiunge
	# esclusioni proprie.
	for rect: Rect2 in [grid, group]:
		var point := rect.get_center()
		assert_eq(
			hud.is_touch_origin_excluded(point), hud.get_top_band_rect().has_point(point),
			"%s: la lista non blocca il joystick." % context
		)
	for container: Control in [hud.find_child("UpgradeSlotGrid", true, false), hud.find_child("SpecialitySlotGroup", true, false)]:
		assert_eq(container.mouse_filter, Control.MOUSE_FILTER_IGNORE, "%s: solo da guardare." % context)
	for slot in hud.get_upgrade_slots():
		assert_eq(slot.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	print("PS204_LAYOUT %s grid=%s group=%s slot=%s" % [context, grid, group, hud.get_upgrade_slot_size()])


func _filled_count(slots: Array[HudUpgradeSlot]) -> int:
	var filled := 0
	for slot in slots:
		filled += 1 if slot.is_filled() else 0
	return filled


func _level_up_preferring_owned(slice: Control, owned: Array[StringName]) -> StringName:
	var offer := _level_up(slice)
	var picked: StringName = offer[0]
	for upgrade_id in offer:
		if owned.has(upgrade_id):
			picked = upgrade_id
			break
	assert_true((slice.get_upgrade_service() as UpgradeService).select_upgrade(picked))
	return picked


func _level_up_preferring_new(slice: Control) -> StringName:
	var service := slice.get_upgrade_service() as UpgradeService
	var offer := _level_up(slice)
	var owned := service.get_distinct_upgrade_ids()
	var picked: StringName = offer[0]
	for upgrade_id in offer:
		if not owned.has(upgrade_id) and not service.is_speciality_unlocked(upgrade_id):
			picked = upgrade_id
			break
	assert_true(service.select_upgrade(picked))
	return picked


func _level_up(slice: Control) -> Array[StringName]:
	var experience := slice.get_experience_system() as ExperienceSystem
	assert_true(experience.add_experience(experience.get_experience_required()), "Serve un level-up reale.")
	return (slice.get_upgrade_service() as UpgradeService).get_current_offer_ids()


func _unlock_speciality(service: UpgradeService) -> void:
	service.queue_barb_reward()
	var offer := service.get_current_barb_offer_ids()
	assert_false(offer.is_empty(), "La ricompensa di Barb offre una Specialità.")
	if not offer.is_empty():
		assert_true(service.select_barb_speciality(offer[0]))
