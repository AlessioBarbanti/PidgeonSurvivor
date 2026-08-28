extends SceneTree

## B18E — Accessibilita' del flash di Tempesta di Tuoni.
##
## Il B43 ha riprogettato l'attiva in una sequenza di fulmini telegrafati
## (vedi `_b43_lightning_storm_smoke.gd` per il contratto di decisione e il
## tetto sulla vita del Boss); questo smoke resta il presidio del contratto
## di accessibilita' B18E originale, che non si tocca: un solo flash
## fullscreen per attivazione, alpha massimo per piattaforma, chiusura entro
## 0,30 s e l'opzione persistente Flash ridotti, incluso il toggle live
## mentre il flash e' in corso.

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

	var warning_seconds := THUNDER_DEFINITION.get_effect_float(&"warning_seconds", 0.45, 0.0)
	var origin := source.global_position
	# Il primo fulmine cade sempre esattamente sull'origine (B43): i bersagli
	# fixture restano vicini a Zat cosi' il preavviso e l'impatto restano
	# osservabili come nel contratto B18E originale.
	var normal_enemy := await _spawn_target(fixture, targeting, false, 100.0, origin + Vector2(40.0, 0.0))
	var boss := await _spawn_target(fixture, targeting, true, 1000.0, origin + Vector2(-40.0, 0.0))
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
	_expect_float_near(effect.get_warning_remaining(), warning_seconds, "Il preavviso deve durare 0,45 s.")
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

	var late_enemy := await _spawn_target(fixture, targeting, false, 80.0, origin + Vector2(0.0, 40.0))
	_expect(late_enemy != null, "Un nemico deve poter entrare durante il preavviso.")
	effect._process(paused_warning)
	_expect(effect.has_impacted(), "Il primo fulmine deve cadere al termine del preavviso.")
	_expect(effect.get_strikes_resolved() == 1, "Il preavviso deve risolvere un solo fulmine.")
	_expect(effect.get_flash_count() == 1, "Il primo fulmine deve accendere il flash.")
	_expect(effect.get_affected_count() == 3, "Il primo fulmine deve fotografare tutti e tre i bersagli vivi.")
	_expect(effect.get_impacted_target_ids().size() == 3, "Ogni bersaglio deve comparire una sola volta nello snapshot.")
	var normal_ratio := THUNDER_DEFINITION.get_effect_float(&"normal_max_health_damage_ratio", 0.5, 0.0)
	var boss_ratio := THUNDER_DEFINITION.get_effect_float(&"boss_max_health_damage_ratio", 0.008, 0.0)
	_expect_float_near(
		normal_enemy.get_health_component().health_current,
		100.0 * (1.0 - normal_ratio),
		"Un nemico normale deve perdere la quota di HP massimi dichiarata."
	)
	_expect_float_near(
		boss.get_health_component().health_current,
		1000.0 * (1.0 - boss_ratio),
		"Un Boss deve perdere la quota per fulmine dichiarata."
	)
	if late_enemy != null:
		_expect_float_near(
			late_enemy.get_health_component().health_current,
			80.0 * (1.0 - normal_ratio),
			"Il nemico entrato nel preavviso deve essere incluso nel primo fulmine."
		)

	# Budget di flash: si accende una volta sola e si chiude entro 0,30 s,
	# anche se la tempesta continuera' a colpire per altri fulmini.
	var normal_after_impact := normal_enemy.get_health_component().health_current
	var peak_alpha := 0.0
	for _step in 30:
		effect._process(0.01)
		peak_alpha = maxf(peak_alpha, effect.get_flash_alpha())
	_expect(
		peak_alpha <= effect.get_flash_max_alpha() + FLOAT_TOLERANCE,
		"Il flash non deve superare l'alpha massimo dichiarato."
	)
	_expect(
		effect.get_flash_phase() == ThunderStorm.FlashPhase.DONE,
		"Il flash standard deve chiudersi entro 0,30 s."
	)
	_expect(
		effect.get_flash_rect() == Rect2(),
		"L'overlay fullscreen deve essere rimosso quando il flash finisce."
	)
	_expect_float_near(
		normal_enemy.get_health_component().health_current,
		normal_after_impact,
		"Il flash non deve applicare un secondo danno entro il proprio budget."
	)
	_expect(
		registry.get_active_effect_count() == 1,
		"La tempesta resta attiva oltre il flash: deve ancora colpire i fulmini successivi."
	)

	# Il budget di flash non deve crescere anche dopo tutti i fulmini
	# successivi della stessa attivazione (contratto B43).
	effect._process(effect.get_total_duration())
	_expect(
		effect.get_flash_count() == 1,
		"Una attivazione deve accendere un solo flash, quanti che siano i fulmini."
	)
	_expect(
		effect.get_strikes_resolved() == effect.get_strike_count(),
		"Tutti i fulmini pianificati devono cadere entro la durata dichiarata."
	)
	await _wait_processed_frame()
	_expect(registry.get_active_effect_count() == 0, "La tempesta esaurita deve liberarsi da sola.")

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
		reduced_effect._process(warning_seconds)
		_expect(reduced_effect.has_impacted(), "Il primo fulmine deve cadere anche in modalita' ridotta.")
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
			reduced_effect.get_flash_phase() == ThunderStorm.FlashPhase.HOLD,
			"La modalità standard riattivata deve conservare la tenuta."
		)
		if reduced_button != null:
			reduced_button.button_pressed = true
		_expect(
			reduced_effect.get_flash_phase() == ThunderStorm.FlashPhase.FADE,
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
