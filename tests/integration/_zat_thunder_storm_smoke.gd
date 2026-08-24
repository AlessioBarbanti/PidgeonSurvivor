extends SceneTree

const ENEMY_SCENE := preload("res://scenes/actors/base_enemy.tscn")
const BOSS_SCENE := preload("res://scenes/actors/first_boss.tscn")
const PAUSE_OVERLAY_SCENE := preload("res://scenes/ui/pause_overlay.tscn")
const THUNDER_DEFINITION := preload("res://data/abilities/zat_lightning_storm.tres")
const TEST_VIEWPORT_SIZE := Vector2i(1280, 720)
const SETTINGS_PATH := "user://b18e_visual_accessibility_test.cfg"
const FLOAT_TOLERANCE := 0.002

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	paused = false
	root.content_scale_size = TEST_VIEWPORT_SIZE
	root.size = TEST_VIEWPORT_SIZE
	_remove_test_settings()
	await _wait_processed_frame()
	await _validate_contract_and_full_flash()
	_remove_test_settings()
	await _finish()


func _validate_contract_and_full_flash() -> void:
	var fixture := Node.new()
	fixture.name = "B18EThunderFixture"
	root.add_child(fixture)

	var controller := RunController.new()
	controller.name = "RunController"
	fixture.add_child(controller)
	controller.set_process(false)
	_expect(controller.start_run(1805), "La fixture B18E deve avviare la run.")

	var targeting := TargetingSystem.new()
	targeting.name = "TargetingSystem"
	fixture.add_child(targeting)
	var effect_parent := Node2D.new()
	effect_parent.name = "AbilityEffects"
	fixture.add_child(effect_parent)
	var source := Node2D.new()
	source.name = "Zat"
	source.position = Vector2(640.0, 360.0)
	fixture.add_child(source)

	var pause_overlay := PAUSE_OVERLAY_SCENE.instantiate() as PauseOverlay
	fixture.add_child(pause_overlay)
	var visual_settings := VisualAccessibilitySettings.new()
	visual_settings.settings_path = SETTINGS_PATH
	fixture.add_child(visual_settings)
	await _wait_processed_frame()
	_expect(
		visual_settings.configure(pause_overlay),
		"Le impostazioni visuali devono collegarsi al menu pausa."
	)
	_expect(
		pause_overlay.get_reduced_flashes_check_button() != null,
		"Il menu pausa deve esporre Flash ridotti."
	)

	var registry := AbilityEffectRegistry.new()
	registry.definitions = [THUNDER_DEFINITION]
	fixture.add_child(registry)
	_expect(
		registry.configure(
			controller,
			targeting,
			effect_parent,
			null,
			visual_settings
		),
		"Il registry B18E deve accettare le dipendenze."
	)

	_expect_float_near(
		THUNDER_DEFINITION.cooldown_seconds,
		60.0,
		"Tempesta di Tuoni rank 1 deve avere cooldown 60 s."
	)
	_expect(
		THUNDER_DEFINITION.title == "Tempesta di Tuoni",
		"Il titolo pubblico deve parlare di tuoni, non di fulmini."
	)
	_expect_float_near(
		ThunderStorm.resolve_flash_max_alpha(false, false),
		0.55,
		"Il flash Windows deve avere alpha massimo 0,55."
	)
	_expect_float_near(
		ThunderStorm.resolve_flash_max_alpha(false, true),
		0.40,
		"Il flash Android deve avere alpha massimo 0,40."
	)
	_expect_float_near(
		ThunderStorm.resolve_flash_max_alpha(true, false),
		0.15,
		"Flash ridotti deve usare alpha massimo 0,15."
	)

	var normal_enemy := await _spawn_target(fixture, targeting, false, 100.0, Vector2(300.0, 300.0))
	var boss := await _spawn_target(fixture, targeting, true, 1000.0, Vector2(900.0, 300.0))
	if normal_enemy == null or boss == null:
		fixture.queue_free()
		await process_frame
		return

	var effect := registry.execute_effect(THUNDER_DEFINITION, source) as ThunderStorm
	_expect(effect != null, "Tempesta di Tuoni deve creare un effetto scene-local.")
	if effect == null:
		fixture.queue_free()
		await process_frame
		return
	_expect(effect.get_phase() == ThunderStorm.Phase.WARNING, "L'effetto deve iniziare dal preavviso.")
	_expect_float_near(effect.get_warning_remaining(), 0.45, "Il preavviso deve durare 0,45 s.")
	_expect_float_near(
		normal_enemy.get_health_component().health_current,
		100.0,
		"L'attivazione non deve danneggiare prima dell'impatto."
	)
	_expect_rect_size(effect.get_flash_rect(), Vector2(TEST_VIEWPORT_SIZE), "Il flash deve coprire il viewport logico.")

	effect._process(0.20)
	var paused_warning := effect.get_warning_remaining()
	_expect(controller.request_manual_pause(), "La fixture deve entrare in pausa manuale.")
	effect._process(1.0)
	_expect_float_near(
		effect.get_warning_remaining(),
		paused_warning,
		"Il preavviso non deve avanzare in pausa."
	)
	_expect_float_near(
		normal_enemy.get_health_component().health_current,
		100.0,
		"La pausa non deve anticipare il danno."
	)
	_expect(controller.resume_run(), "La fixture deve riprendere la run.")

	var late_enemy := await _spawn_target(fixture, targeting, false, 80.0, Vector2(640.0, 520.0))
	_expect(late_enemy != null, "Un nemico deve poter entrare durante il preavviso.")
	effect._process(paused_warning)
	_expect(effect.has_impacted(), "L'impatto deve avvenire al termine del preavviso.")
	_expect(effect.get_affected_count() == 3, "L'impatto deve fotografare tutti e tre i bersagli vivi.")
	_expect(effect.get_impacted_target_ids().size() == 3, "Ogni bersaglio deve comparire una sola volta nello snapshot.")
	_expect_float_near(
		normal_enemy.get_health_component().health_current,
		50.0,
		"Un nemico normale deve perdere il 50% degli HP massimi."
	)
	_expect_float_near(
		boss.get_health_component().health_current,
		800.0,
		"Un Boss deve perdere il 20% degli HP massimi."
	)
	if late_enemy != null:
		_expect_float_near(
			late_enemy.get_health_component().health_current,
			40.0,
			"Il nemico entrato nel preavviso deve essere incluso all'impatto."
		)

	var normal_after_impact := normal_enemy.get_health_component().health_current
	effect._process(0.30)
	_expect_float_near(
		normal_enemy.get_health_component().health_current,
		normal_after_impact,
		"Il flash non deve applicare un secondo danno."
	)
	await _wait_processed_frame()
	_expect(registry.get_active_effect_count() == 0, "Il flash standard deve chiudersi entro 0,30 s.")

	var reduced_button := pause_overlay.get_reduced_flashes_check_button()
	if reduced_button != null:
		reduced_button.button_pressed = true
	_expect(visual_settings.is_reduced_flashes_enabled(), "Il toggle deve attivare Flash ridotti.")
	var persisted_settings := VisualAccessibilitySettings.new()
	persisted_settings.settings_path = SETTINGS_PATH
	fixture.add_child(persisted_settings)
	await _wait_processed_frame()
	_expect(
		persisted_settings.is_reduced_flashes_enabled(),
		"Flash ridotti deve persistere nel file impostazioni."
	)
	persisted_settings.queue_free()

	var reduced_effect := registry.execute_effect(THUNDER_DEFINITION, source) as ThunderStorm
	_expect(reduced_effect != null, "Tempesta di Tuoni deve riattivarsi nella fixture ridotta.")
	if reduced_effect != null:
		reduced_effect._process(0.45)
		_expect_float_near(
			reduced_effect.get_flash_max_alpha(),
			0.15,
			"Il runtime ridotto deve applicare alpha 0,15."
		)
		if reduced_button != null:
			reduced_button.button_pressed = false
		_expect_float_near(
			reduced_effect.get_flash_max_alpha(),
			0.55,
			"Disattivare l'opzione durante la salita deve ripristinare l'alpha standard."
		)
		reduced_effect._process(0.06)
		_expect(
			reduced_effect.get_phase() == ThunderStorm.Phase.FLASH_HOLD,
			"La modalità standard riattivata deve conservare la tenuta."
		)
		if reduced_button != null:
			reduced_button.button_pressed = true
		_expect(
			reduced_effect.get_phase() == ThunderStorm.Phase.FLASH_FADE,
			"Attivare Flash ridotti durante la tenuta deve passare subito alla dissolvenza."
		)
		_expect_float_near(
			reduced_effect.get_flash_max_alpha(),
			0.15,
			"Il toggle live deve limitare subito l'alpha a 0,15."
		)

	var cleanup_effect := registry.execute_effect(THUNDER_DEFINITION, source) as ThunderStorm
	_expect(cleanup_effect != null, "La fixture cleanup deve creare un effetto attivo.")
	_expect(controller.request_defeat(), "La morte/terminale deve chiudere la run.")
	await _wait_processed_frame()
	_expect(registry.get_active_effect_count() == 0, "La fine run deve rimuovere preavviso e flash.")

	paused = false
	fixture.queue_free()
	await _wait_processed_frame()


func _spawn_target(
	parent: Node,
	targeting: TargetingSystem,
	is_boss: bool,
	health_max: float,
	position: Vector2
) -> BaseEnemy:
	var target := (
		BOSS_SCENE.instantiate() as BaseEnemy
		if is_boss
		else ENEMY_SCENE.instantiate() as BaseEnemy
	)
	parent.add_child(target)
	await _wait_processed_frame()
	target.set_physics_process(false)
	target.global_position = position
	var health := target.get_health_component()
	if health == null:
		_failures.append("Il bersaglio fixture deve avere HealthComponent.")
		return null
	health.set_health_max(health_max)
	health.reset_to_max()
	_expect(targeting.register_target(target), "Il bersaglio fixture deve registrarsi una volta.")
	return target


func _expect_rect_size(actual: Rect2, expected: Vector2, message: String) -> void:
	_expect(
		actual.size.distance_to(expected) <= 1.0,
		"%s Atteso %s, ottenuto %s." % [message, expected, actual.size]
	)


func _expect_float_near(actual: float, expected: float, message: String) -> void:
	_expect(
		absf(actual - expected) <= FLOAT_TOLERANCE,
		"%s Atteso %.3f, ottenuto %.3f." % [message, expected, actual]
	)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _wait_processed_frame() -> void:
	await process_frame
	await process_frame


func _remove_test_settings() -> void:
	var absolute_path := ProjectSettings.globalize_path(SETTINGS_PATH)
	if FileAccess.file_exists(SETTINGS_PATH):
		DirAccess.remove_absolute(absolute_path)


func _finish() -> void:
	paused = false
	await process_frame
	if _failures.is_empty():
		print("B18E_ZAT_THUNDER_STORM_SMOKE_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	printerr("B18E_ZAT_THUNDER_STORM_SMOKE_FAIL count=%d" % _failures.size())
	quit(1)
