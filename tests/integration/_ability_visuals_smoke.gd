extends SceneTree

const MOVEMENT_SLICE_SCENE := preload("res://scenes/game/movement_slice.tscn")
const INITIAL_VIEWPORT_SIZE := Vector2i(1280, 720)
const MAX_FULLSCREEN_OVERLAYS := 1
const MAX_VISUAL_PARTICLES := 64
const MAX_VISUAL_MATERIALS := 2
const VFX_MANIFEST_PATH := "res://assets/art/vfx/ASSET-MANIFEST.md"

const EXPECTED_FAMILIES := {
	&"earthquake_shockwave": &"earthquake_rings_and_cracks",
	&"fire_z_trail": &"powerslide_ribbon_and_sparks",
	&"lightning_storm": &"thunder_cloud_warning_and_waves",
	&"grand_spin": &"grand_spin_rotating_arcs",
	&"cement_pour": &"cement_pool_border_and_bubbles",
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
	"res://assets/art/icons/abilities/earthquake.svg",
	"res://assets/art/icons/abilities/powerslide.svg",
	"res://assets/art/icons/abilities/lightning.svg",
	"res://assets/art/icons/abilities/grand_spin.svg",
	"res://assets/art/icons/abilities/cement.svg",
	"res://assets/art/icons/abilities/cosplay.svg",
	"res://assets/art/icons/abilities/zen.svg",
	"res://assets/art/icons/abilities/reggaeton.svg",
]

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	paused = false
	root.content_scale_size = INITIAL_VIEWPORT_SIZE
	root.size = INITIAL_VIEWPORT_SIZE
	await _wait_processed_frame()
	await _validate_visual_families_and_budgets()
	_validate_manifest()
	await _finish()


func _validate_visual_families_and_budgets() -> void:
	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	root.add_child(movement_slice)
	await _wait_processed_frame()

	var controller := movement_slice.get_run_controller() as RunController
	var registry := movement_slice.get_ability_effect_registry() as AbilityEffectRegistry
	var player := movement_slice.get_player() as Player
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	var weapon := movement_slice.get_weapon_controller() as WeaponController
	var ability := movement_slice.get_ability_controller() as AbilityController
	var effect_parent := movement_slice.get_ability_effect_parent() as Node2D
	_expect(controller != null and controller.is_running(), "B18M richiede una run attiva.")
	_expect(registry != null and registry.get_definitions().size() == 8, "B18M richiede otto abilita registrate.")
	_expect(player != null and player.is_alive(), "B18M richiede un Player valido.")
	_expect(effect_parent != null and effect_parent.z_index == 0, "I VFX alleati devono restare sul layer mondo 0.")
	if controller == null or registry == null or player == null or effect_parent == null:
		movement_slice.queue_free()
		await process_frame
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
		await process_frame
		player.global_position = source_origin
		player.set_movement_input(Vector2.RIGHT)
		var effect := registry.execute_effect(definition, player)
		_expect(effect != null, "L'abilita %s deve creare un VFX B18M." % definition.id)
		if effect == null:
			continue

		var visual_node := effect
		if definition.effect_id == AbilityEffectRegistry.RANDOM_COSPLAY:
			visual_node = effect.get_node_or_null("CosplayAccent") as Node2D
			_expect(visual_node is CosplayAccent, "Cosplay Casuale deve aggiungere confetti scene-local.")
			_expect(
				effect.get_meta(&"cosplay_source", &"") == AbilityEffectRegistry.RANDOM_COSPLAY,
				"Cosplay Casuale deve marcare l'effetto copiato."
			)
			_expect(
				not StringName(effect.get_meta(&"copied_effect_id", &"")).is_empty(),
				"Cosplay Casuale deve esporre la palette dell'abilita copiata."
			)
		if visual_node == null:
			continue

		_validate_visual_contract(visual_node, definition.effect_id)
		var family_id := StringName(visual_node.call("get_visual_family_id"))
		family_ids[family_id] = true
		var total_particles := int(effect.call("get_visual_particle_count"))
		if visual_node != effect:
			total_particles += int(visual_node.call("get_visual_particle_count"))
		_expect(
			total_particles <= MAX_VISUAL_PARTICLES,
			"%s supera il budget di %d particelle." % [definition.id, MAX_VISUAL_PARTICLES]
		)
		var overlay_count := 1 if bool(effect.call("uses_fullscreen_overlay")) else 0
		_expect(
			overlay_count <= MAX_FULLSCREEN_OVERLAYS,
			"%s supera il budget overlay fullscreen." % definition.id
		)
		var material_count := int(effect.call("get_visual_material_count"))
		if visual_node != effect:
			material_count += int(visual_node.call("get_visual_material_count"))
		_expect(
			material_count <= MAX_VISUAL_MATERIALS,
			"%s supera il budget materiali aggiuntivi." % definition.id
		)
		if definition.effect_id != AbilityEffectRegistry.RANDOM_COSPLAY:
			_validate_visual_extent(effect, definition)
		if visual_node is CosplayAccent:
			_validate_cosplay_pause(controller, visual_node as CosplayAccent)

	_expect(family_ids.size() == 8, "Le otto abilita devono avere famiglie VFX distinguibili.")
	registry.clear_active_effects()
	await process_frame
	_expect(effect_parent.get_child_count() == 0, "Restart/cleanup deve rimuovere anche gli accenti B18M.")
	player.clear_movement_input()
	controller.prepare_restart()
	paused = false
	movement_slice.queue_free()
	await process_frame


func _validate_visual_contract(visual_node: Node2D, effect_id: StringName) -> void:
	for method_name in [
		&"get_visual_family_id",
		&"get_visual_particle_count",
		&"get_visual_material_count",
		&"uses_fullscreen_overlay",
	]:
		_expect(visual_node.has_method(method_name), "%s non espone %s." % [effect_id, method_name])
	if not visual_node.has_method(&"get_visual_family_id"):
		return
	_expect(
		StringName(visual_node.call("get_visual_family_id")) == EXPECTED_FAMILIES[effect_id],
		"La grammatica VFX non corrisponde per %s." % effect_id
	)


func _validate_visual_extent(effect: Node2D, definition: AbilityDefinition) -> void:
	if effect is EarthquakeWave:
		_expect_float_near((effect as EarthquakeWave).get_radius(), definition.area_radius, "L'anello tellurico deve comunicare il raggio reale.")
	elif effect is FireZTrail:
		var expected_extent := definition.get_effect_float(&"trail_width", 36.0, 1.0) * 0.5
		_expect_float_near((effect as FireZTrail).get_visual_extent(), expected_extent, "Il nastro Powerslide deve comunicare la larghezza reale.")
	elif effect is AbilityAreaEffect:
		_expect_float_near((effect as AbilityAreaEffect).get_visual_extent(), definition.area_radius, "L'area deve comunicare il raggio reale.")


func _validate_cosplay_pause(controller: RunController, accent: CosplayAccent) -> void:
	var before := accent.get_duration_remaining()
	_expect(controller.request_manual_pause(), "La fixture deve sospendere l'accento Cosplay.")
	accent._process(0.3)
	_expect_float_near(accent.get_duration_remaining(), before, "I confetti devono fermarsi in pausa.")
	_expect(controller.resume_run(), "La fixture deve riprendere l'accento Cosplay.")


func _validate_manifest() -> void:
	_expect(FileAccess.file_exists(VFX_MANIFEST_PATH), "Manifest VFX B18M mancante.")
	if not FileAccess.file_exists(VFX_MANIFEST_PATH):
		return
	var manifest := FileAccess.get_file_as_string(VFX_MANIFEST_PATH)
	_expect(manifest.contains("origine: progetto IL GIOCO"), "Il manifest deve dichiarare l'origine interna.")
	_expect(manifest.contains("Licenza del progetto"), "Il manifest deve dichiarare la licenza dei VFX originali.")
	for runtime_path in MANIFEST_RUNTIME_PATHS:
		_expect(FileAccess.file_exists(runtime_path), "File runtime B18M mancante: %s." % runtime_path)
		if not FileAccess.file_exists(runtime_path):
			continue
		_expect(manifest.contains(runtime_path.trim_prefix("res://")), "Manifest privo di %s." % runtime_path)
		var sha256 := FileAccess.get_sha256(runtime_path)
		_expect(not sha256.is_empty() and manifest.contains(sha256), "SHA-256 non registrato per %s." % runtime_path)


func _expect_float_near(actual: float, expected: float, message: String) -> void:
	_expect(absf(actual - expected) <= 0.02, "%s Atteso %.2f, ottenuto %.2f." % [message, expected, actual])


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _wait_processed_frame() -> void:
	await process_frame
	await process_frame


func _finish() -> void:
	paused = false
	await process_frame
	if _failures.is_empty():
		print("B18M_ABILITY_VISUALS_SMOKE_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	printerr("B18M_ABILITY_VISUALS_SMOKE_FAIL count=%d" % _failures.size())
	quit(1)
