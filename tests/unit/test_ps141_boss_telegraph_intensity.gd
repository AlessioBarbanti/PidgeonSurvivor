extends GutGameplayTest


func test_countdown_geometry_palette_and_pause_remain_honest() -> void:
	var scene := await instantiate_movement_slice()
	var controller := scene.get_run_controller() as RunController
	if not controller.is_terminal():
		controller.request_defeat()
	assert_true(scene.restart_run(14101))
	await wait_process_frames(2)
	controller.set_process(false)
	var encounter := scene.get_boss_encounter() as BossEncounter
	encounter.evil_boss_chance = 0.0
	controller._process(120.01)
	var boss := encounter.get_active_boss()
	assert_not_null(boss)
	if boss == null:
		scene.free()
		return
	assert_true(encounter.complete_intro())
	boss.set_physics_process(false)
	boss.move_speed = 0.0
	boss._physics_process(boss.get_attack_cooldown_remaining() + 0.01)
	var duration := boss.get_telegraph_remaining()
	var early := BossAttackVisuals.intensity(0.0)
	boss._physics_process(duration * 0.8)
	var remaining := boss.get_telegraph_remaining()
	var late := BossAttackVisuals.intensity(1.0 - remaining / duration)
	assert_gt(late, early * 1.8, "Il countdown aumenta realmente l'opacita' usata dal renderer.")
	assert_true(controller.request_level_up())
	boss._physics_process(5.0)
	assert_eq(boss.get_telegraph_remaining(), remaining, "La pausa congela anche l'intensita'.")
	assert_true(controller.complete_level_up())
	boss._physics_process(remaining + 0.01)
	boss._physics_process(boss.get_attack_cooldown_remaining() + 0.01)
	assert_eq(boss.get_active_pattern_id(), FirstBoss.TARGETED_BLAST)
	var center := boss.get_targeted_position()
	var radius := boss.definition.targeted_blast_radius
	var player := scene.get_player() as Player
	var rect := BossAttackVisuals.ring_rect(center, radius)
	assert_almost_eq(rect.size.x * BossAttackVisuals.RING_ALPHA_RADIUS, radius, 0.001)
	assert_true(boss._is_within_targeted_blast(center + Vector2.RIGHT * (radius + player.collision_radius - 0.1), center, player.collision_radius))
	assert_false(boss._is_within_targeted_blast(center + Vector2.RIGHT * (radius + player.collision_radius + 0.1), center, player.collision_radius))
	assert_eq(boss.definition.telegraph_color, Color(1.0, 0.22, 0.5, 0.76), "Palette baseline corrente, preservata senza reinterpretare il testo storico.")
	assert_eq(BossEncounter.EVIL_TELEGRAPH_COLOR, Color(0.92, 0.12, 0.78, 0.78))
	boss._physics_process(boss.get_telegraph_remaining() + 0.01)
	assert_gt(boss._blast_visual_remaining, 0.0, "L'esecuzione lascia la coda raster senza introdurre altro danno.")
	assert_true(controller.request_level_up())
	var tail := boss._blast_visual_remaining
	boss._physics_process(5.0)
	assert_eq(boss._blast_visual_remaining, tail)
	boss.clear_attack_runtime()
	assert_eq(boss._blast_visual_remaining, 0.0)
	assert_true(boss._blast_visual_positions.is_empty())
	scene.free()
	print("PS141_BOSS_TELEGRAPH_OK")


func test_every_signature_and_common_attack_has_imported_raster() -> void:
	for texture: Texture2D in [BossAttackVisuals.RING, BossAttackVisuals.BLAST, BossAttackVisuals.CORRIDOR, BossAttackVisuals.RETICLE]:
		assert_not_null(texture)
		assert_gt(texture.get_width(), 0)
	for effect_id in BossSignatureRegistry.get_supported_effect_ids():
		assert_true(BossAttackVisuals.SIGNATURE_TEXTURES.has(effect_id))
		assert_not_null(BossAttackVisuals.signature_texture(effect_id))
	assert_gt(
		BossAttackVisuals.corridor_tiles(FirstBoss.FEATHER_LINE_TELEGRAPH_LENGTH, 31.0), 1,
		"Una corsia lunga ripete il nastro invece di stirarlo in un tratto piatto."
	)
	assert_eq(BossAttackVisuals.corridor_tiles(120.0, 40.0), 1, "Una corsia corta resta una sola stampa a proporzione nativa.")
