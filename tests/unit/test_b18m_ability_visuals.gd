extends GutGameplayTest

const MAX_FULLSCREEN_OVERLAYS := 1
const MAX_VISUAL_PARTICLES := 64
const MAX_VISUAL_MATERIALS := 2
const VFX_MANIFEST_PATH := "res://assets/art/vfx/ASSET-MANIFEST.md"

const EXPECTED_FAMILIES := {
	&"earthquake_shockwave": &"earthquake_rings_and_cracks",
	&"fire_z_trail": &"powerslide_ribbon_and_sparks",
	&"lightning_storm": &"thunder_cloud_warning_and_waves",
	&"grand_spin": &"grand_spin_rotating_arcs",
	&"thermal_shock": &"thermal_shock_frost_ring_and_bloom",
	&"random_cosplay": &"cosplay_confetti_and_copied_palette",
	&"zen_slowdown": &"zen_concentric_rings_and_motes",
	&"shadow_deception": &"reggeton_clone_speaker_and_notes",
}

const MANIFEST_RUNTIME_PATHS := [
	"res://scripts/abilities/ability_area_effect.gd",
	"res://scripts/abilities/cosplay_accent.gd",
	"res://scripts/abilities/earthquake_wave.gd",
	"res://scripts/abilities/fire_z_trail.gd",
	"res://scripts/abilities/illusion_decoy.gd",
	"res://scripts/abilities/lightning_storm.gd",
	"res://scripts/abilities/thermal_shock.gd",
	"res://scripts/abilities/instinctive_dodge_accent.gd",
	"res://assets/art/vfx/abilities/generated/earthquake_wave.png",
	"res://assets/art/vfx/abilities/generated/fire_trail.png",
	"res://assets/art/vfx/abilities/generated/lightning_impact.png",
	"res://assets/art/vfx/abilities/generated/grand_spin.png",
	"res://assets/art/vfx/abilities/generated/thermal_frost.png",
	"res://assets/art/vfx/abilities/generated/thermal_bloom.png",
	"res://assets/art/vfx/abilities/generated/cosplay_reveal.png",
	"res://assets/art/vfx/abilities/generated/zen_field.png",
	"res://assets/art/vfx/abilities/generated/reggaeton_decoy.png",
]


func test_visual_families_and_budgets() -> void:
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_run_controller() as RunController
	var registry := movement_slice.get_ability_effect_registry() as AbilityEffectRegistry
	var player := movement_slice.get_player() as Player
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	var weapon := movement_slice.get_weapon_controller() as WeaponController
	var ability := movement_slice.get_ability_controller() as AbilityController
	var effect_parent := movement_slice.get_ability_effect_parent() as Node2D
	assert_true(controller != null and controller.is_running(), "B18M richiede una run attiva.")
	assert_true(
		registry != null and registry.get_definitions().size() == 8, "B18M richiede otto abilita registrate."
	)
	assert_true(player != null and player.is_alive(), "B18M richiede un Player valido.")
	assert_true(
		effect_parent != null and effect_parent.z_index == 0, "I VFX alleati devono restare sul layer mondo 0."
	)
	if controller == null or registry == null or player == null or effect_parent == null:
		return

	controller.set_process(false)
	player.set_physics_process(false)
	if spawner != null:
		spawner.set_process(false)
	if weapon != null:
		weapon.set_process(false)
	if ability != null:
		ability.set_process(false)

	var family_ids: Dictionary = {}
	var source_origin := player.global_position
	for definition in registry.get_definitions():
		registry.clear_active_effects()
		await wait_process_frames(1)
		player.global_position = source_origin
		player.set_movement_input(Vector2.RIGHT)
		var effect := registry.execute_effect(definition, player)
		assert_not_null(effect, "L'abilita %s deve creare un VFX B18M." % definition.id)
		if effect == null:
			continue

		var visual_node := effect
		if definition.effect_id == AbilityEffectRegistry.RANDOM_COSPLAY:
			visual_node = registry.get_last_cosplay_accent() as Node2D
			assert_true(visual_node is CosplayAccent, "Cosplay Casuale deve aggiungere confetti scene-local.")
			assert_eq(
				effect.get_meta(&"cosplay_source", &""), AbilityEffectRegistry.RANDOM_COSPLAY,
				"Cosplay Casuale deve marcare l'effetto copiato."
			)
			assert_false(
				StringName(effect.get_meta(&"copied_effect_id", &"")).is_empty(),
				"Cosplay Casuale deve esporre la palette dell'abilita copiata."
			)
		if visual_node == null:
			continue

		_assert_visual_contract(visual_node, definition.effect_id)
		_assert_generated_vfx_asset(registry, visual_node, definition)
		var family_id := StringName(visual_node.call("get_visual_family_id"))
		family_ids[family_id] = true
		var total_particles := int(effect.call("get_visual_particle_count"))
		if visual_node != effect:
			total_particles += int(visual_node.call("get_visual_particle_count"))
		assert_true(
			total_particles <= MAX_VISUAL_PARTICLES,
			"%s supera il budget di %d particelle." % [definition.id, MAX_VISUAL_PARTICLES]
		)
		var overlay_count := 1 if bool(effect.call("uses_fullscreen_overlay")) else 0
		assert_true(
			overlay_count <= MAX_FULLSCREEN_OVERLAYS, "%s supera il budget overlay fullscreen." % definition.id
		)
		var material_count := int(effect.call("get_visual_material_count"))
		if visual_node != effect:
			material_count += int(visual_node.call("get_visual_material_count"))
		assert_true(
			material_count <= MAX_VISUAL_MATERIALS, "%s supera il budget materiali aggiuntivi." % definition.id
		)
		if definition.effect_id != AbilityEffectRegistry.RANDOM_COSPLAY:
			_assert_visual_extent(effect, definition)
		if definition.effect_id == AbilityEffectRegistry.GRAND_SPIN:
			assert_true(
				effect is AbilityAreaEffect and (effect as AbilityAreaEffect).get_visual_rotation_turns() >= 2.0,
				"Gran Piroetta deve compiere almeno due rotazioni visive per attivazione."
			)
		if visual_node is CosplayAccent:
			_assert_cosplay_pause(controller, visual_node as CosplayAccent)

	assert_eq(family_ids.size(), 8, "Le otto abilita devono avere famiglie VFX distinguibili.")
	registry.clear_active_effects()
	await wait_process_frames(1)
	assert_eq(
		effect_parent.get_child_count(), 0, "Restart/cleanup deve rimuovere anche gli accenti B18M."
	)
	player.clear_movement_input()
	controller.prepare_restart()


func test_manifest_contract() -> void:
	assert_true(FileAccess.file_exists(VFX_MANIFEST_PATH), "Manifest VFX B18M mancante.")
	if not FileAccess.file_exists(VFX_MANIFEST_PATH):
		return
	var manifest := FileAccess.get_file_as_string(VFX_MANIFEST_PATH)
	assert_true(manifest.contains("origine: progetto IL GIOCO"), "Il manifest deve dichiarare l'origine interna.")
	assert_true(
		manifest.contains("Licenza del progetto"), "Il manifest deve dichiarare la licenza dei VFX originali."
	)
	for runtime_path in MANIFEST_RUNTIME_PATHS:
		assert_true(FileAccess.file_exists(runtime_path), "File runtime B18M mancante: %s." % runtime_path)
		if not FileAccess.file_exists(runtime_path):
			continue
		assert_true(
			manifest.contains(runtime_path.trim_prefix("res://")), "Manifest privo di %s." % runtime_path
		)
		var sha256 := FileAccess.get_sha256(runtime_path)
		assert_true(
			not sha256.is_empty() and manifest.contains(sha256), "SHA-256 non registrato per %s." % runtime_path
		)


func _assert_visual_contract(visual_node: Node2D, effect_id: StringName) -> void:
	for method_name in [
		&"get_visual_family_id",
		&"get_visual_particle_count",
		&"get_visual_material_count",
		&"uses_fullscreen_overlay",
	]:
		assert_true(visual_node.has_method(method_name), "%s non espone %s." % [effect_id, method_name])
	if not visual_node.has_method(&"get_visual_family_id"):
		return
	assert_eq(
		StringName(visual_node.call("get_visual_family_id")), EXPECTED_FAMILIES[effect_id],
		"La grammatica VFX non corrisponde per %s." % effect_id
	)


func _assert_generated_vfx_asset(
	registry: AbilityEffectRegistry, visual_node: Node2D, definition: AbilityDefinition
) -> void:
	assert_null(
		registry.get_last_icon_burst(), "%s non deve piu' sovrapporre l'icona HUD nel mondo." % definition.id
	)
	var texture_paths := PackedStringArray()
	if visual_node.has_method(&"get_visual_texture_path"):
		texture_paths.append(String(visual_node.call("get_visual_texture_path")))
	elif visual_node.has_method(&"get_visual_texture_paths"):
		texture_paths = visual_node.call("get_visual_texture_paths")
	assert_false(texture_paths.is_empty(), "%s deve esporre almeno un decal VFX." % definition.id)
	for texture_path in texture_paths:
		assert_true(
			texture_path.begins_with("res://assets/art/vfx/abilities/generated/") and texture_path.ends_with(".png"),
			"%s deve usare un PNG VFX ImageGen runtime." % definition.id
		)
		assert_true(FileAccess.file_exists(texture_path), "Decal VFX mancante: %s." % texture_path)
		var texture := load(texture_path) as Texture2D
		assert_true(
			texture != null and texture.get_size() == Vector2(512.0, 512.0),
			"Il decal %s deve essere RGBA 512x512." % texture_path
		)


func _assert_visual_extent(effect: Node2D, definition: AbilityDefinition) -> void:
	if effect is EarthquakeWave:
		assert_almost_eq(
			(effect as EarthquakeWave).get_radius(), definition.area_radius, 0.02,
			"L'anello tellurico deve comunicare il raggio reale."
		)
	elif effect is FireZTrail:
		var expected_extent := definition.get_effect_float(&"trail_width", 36.0, 1.0) * 0.5
		assert_almost_eq(
			(effect as FireZTrail).get_visual_extent(), expected_extent, 0.02,
			"Il nastro Powerslide deve comunicare la larghezza reale."
		)
	elif effect is AbilityAreaEffect:
		assert_almost_eq(
			(effect as AbilityAreaEffect).get_visual_extent(), definition.area_radius, 0.02,
			"L'area deve comunicare il raggio reale."
		)
	elif effect is ThunderStorm:
		assert_almost_eq(
			(effect as ThunderStorm).get_visual_extent(), definition.area_radius, 0.02,
			"Il telegrafo del fulmine deve comunicare il raggio reale."
		)


func _assert_cosplay_pause(controller: RunController, accent: CosplayAccent) -> void:
	var before := accent.get_duration_remaining()
	assert_true(controller.request_manual_pause(), "La fixture deve sospendere l'accento Cosplay.")
	accent._process(0.3)
	assert_almost_eq(
		accent.get_duration_remaining(), before, 0.02, "I confetti devono fermarsi in pausa."
	)
	assert_true(controller.resume_run(), "La fixture deve riprendere l'accento Cosplay.")
