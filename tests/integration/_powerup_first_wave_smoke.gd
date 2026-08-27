extends SceneTree

const MOVEMENT_SLICE_SCENE := preload("res://scenes/game/movement_slice.tscn")
const PROJECTILE_SPEED := preload("res://data/upgrades/projectile_speed.tres")
const REINFORCED_ROASTING_TRAY := preload("res://data/upgrades/reinforced_roasting_tray.tres")
const BARB_SEASONING_XP := preload("res://data/upgrades/barb_seasoning_xp.tres")
const ABILITY_COOLDOWN := preload("res://data/upgrades/ability_cooldown.tres")
const RAPID_FIRE := preload("res://data/upgrades/rapid_fire.tres")
const WIDE_MAGNET := preload("res://data/upgrades/wide_magnet.tres")
const FLOAT_TOLERANCE := 0.001

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	paused = false
	await process_frame
	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	root.add_child(movement_slice)
	await process_frame
	await process_frame

	var controller := movement_slice.get_run_controller() as RunController
	var experience := movement_slice.get_experience_system() as ExperienceSystem
	var catalog := movement_slice.get_upgrade_registry() as UpgradeRegistry
	var service := movement_slice.get_upgrade_service() as UpgradeService
	var effects := movement_slice.get_upgrade_effect_registry() as UpgradeEffectRegistry
	var player := movement_slice.get_node_or_null("World/Player") as Player
	var weapon := movement_slice.get_weapon_controller() as WeaponController
	if (
		controller == null
		or experience == null
		or catalog == null
		or service == null
		or effects == null
		or player == null
		or weapon == null
	):
		_expect(false, "La fixture prima ondata richiede tutti i servizi runtime.")
	else:
		var curve := ExperienceCurve.new()
		curve.base_experience_required = 999
		curve.experience_growth_per_level = 0
		experience.experience_curve = curve
		_validate_data(catalog, effects)
		await _validate_projectile_speed(catalog, service, effects, experience, weapon)
		await _validate_damage_reduction(catalog, service, effects, experience, player)
		await _validate_xp_value(catalog, service, effects, experience)
		await _validate_ability_cooldown(catalog, service, effects, experience, player)
		_expect(controller.request_defeat(), "La fixture deve poter concludere la run.")

	movement_slice.queue_free()
	await process_frame
	_finish()


func _validate_data(catalog: UpgradeRegistry, effects: UpgradeEffectRegistry) -> void:
	for definition in [PROJECTILE_SPEED, REINFORCED_ROASTING_TRAY, BARB_SEASONING_XP, ABILITY_COOLDOWN]:
		_expect(definition.is_valid(), "La definizione prima ondata deve essere valida: %s." % definition.id)
		_expect(definition.repeatable and definition.max_rank == 5, "La carta deve restare ripetibile al rango nominale 5: %s." % definition.id)
		_expect(definition.icon != null and not definition.icon.resource_path.is_empty(), "La carta deve avere un'icona runtime: %s." % definition.id)
		_expect(effects.can_apply(definition), "L'effetto deve essere supportato: %s." % definition.effect_id)
	_expect(RAPID_FIRE.title == "A Tutta Brace!", "rapid_fire deve avere il nuovo nome.")
	_expect(WIDE_MAGNET.title == "Pinza Lunga", "wide_magnet deve avere il nuovo nome.")
	_expect(catalog.resolve_definition(PROJECTILE_SPEED.id) == PROJECTILE_SPEED, "Il catalogo runtime deve registrare Via dalla Griglia!.")


func _validate_projectile_speed(
	catalog: UpgradeRegistry,
	service: UpgradeService,
	effects: UpgradeEffectRegistry,
	experience: ExperienceSystem,
	weapon: WeaponController
) -> void:
	var base_speed := weapon.weapon_profile.projectile_speed
	_expect(await _select_fixture_upgrade(catalog, service, effects, experience, PROJECTILE_SPEED), "Via dalla Griglia! deve essere selezionabile.")
	_expect_near(weapon.get_effective_projectile_speed(), base_speed * 1.1, "La velocita dei proiettili deve crescere del 10%.")
	_expect_near(effects.get_effective_multiplier(UpgradeEffectRegistry.WEAPON_PROJECTILE_SPEED_MULTIPLIER), 1.1, "Il moltiplicatore projectile speed deve essere tracciato.")
	_reset_fixture(catalog, service, effects)


func _validate_damage_reduction(
	catalog: UpgradeRegistry,
	service: UpgradeService,
	effects: UpgradeEffectRegistry,
	experience: ExperienceSystem,
	player: Player
) -> void:
	_expect(await _select_fixture_upgrade(catalog, service, effects, experience, REINFORCED_ROASTING_TRAY), "Pirofila Rinforzata deve essere selezionabile.")
	_expect_near(player.get_damage_taken_multiplier(), 0.94, "La pirofila deve ridurre il danno ricevuto del 6%.")
	var health := player.get_health_component()
	if health != null:
		health.reset_to_max()
		_expect(player.take_contact_damage(10.0), "Il Player deve accettare il danno di contatto.")
		_expect_near(health.health_current, health.health_max - 9.4, "La pirofila non deve modificare invulnerabilita o vita massima.")
	_reset_fixture(catalog, service, effects)


func _validate_xp_value(
	catalog: UpgradeRegistry,
	service: UpgradeService,
	effects: UpgradeEffectRegistry,
	experience: ExperienceSystem
) -> void:
	_expect(await _select_fixture_upgrade(catalog, service, effects, experience, BARB_SEASONING_XP), "Il condimento di Barb deve essere selezionabile.")
	var total_before := experience.experience_total
	_expect(experience.add_experience(10), "L'XP potenziata deve poter essere aggiunta.")
	_expect(experience.experience_total - total_before == 11, "Il condimento deve assegnare il 10% di XP aggiuntiva.")
	_expect_near(experience.get_upgrade_value_multiplier(), 1.1, "Il moltiplicatore XP deve restare separato dal pickup range.")
	_reset_fixture(catalog, service, effects)


func _validate_ability_cooldown(
	catalog: UpgradeRegistry,
	service: UpgradeService,
	effects: UpgradeEffectRegistry,
	experience: ExperienceSystem,
	player: Player
) -> void:
	var ability := player.get_ability_controller()
	if ability == null:
		_expect(false, "La prima ondata richiede l'abilita attiva equipaggiata.")
		return
	var base_cooldown := ability.get_cooldown_total()
	_expect(ability.try_activate(), "L'abilita base deve potersi attivare.")
	var active_snapshot := ability.get_cooldown_total()
	_expect(await _select_fixture_upgrade(catalog, service, effects, experience, ABILITY_COOLDOWN), "Bis di Salsiccia deve essere selezionabile.")
	_expect_near(ability.get_cooldown_total(), active_snapshot, "Un cooldown gia avviato deve conservare il proprio snapshot.")
	ability._process(ability.get_cooldown_remaining())
	_expect(ability.try_activate(), "L'abilita deve potersi riattivare dopo il cooldown.")
	_expect_near(ability.get_cooldown_total(), base_cooldown * 0.92, "Il cooldown successivo deve ridursi dell'8%.")
	_expect_near(effects.get_effective_multiplier(UpgradeEffectRegistry.ACTIVE_ABILITY_COOLDOWN_MULTIPLIER), 0.92, "Il moltiplicatore cooldown deve essere tracciato.")
	_reset_fixture(catalog, service, effects)


func _select_fixture_upgrade(
	catalog: UpgradeRegistry,
	service: UpgradeService,
	effects: UpgradeEffectRegistry,
	experience: ExperienceSystem,
	selected: UpgradeDefinition
) -> bool:
	catalog.definitions = [selected, RAPID_FIRE, WIDE_MAGNET]
	if not catalog.rebuild_registry():
		return false
	service.reset_for_run(77)
	if not effects.recalculate_effects():
		return false
	if not experience.add_experience(experience.experience_required):
		return false
	if selected.id not in service.get_current_offer_ids():
		return false
	return service.select_upgrade(selected.id)


func _reset_fixture(catalog: UpgradeRegistry, service: UpgradeService, effects: UpgradeEffectRegistry) -> void:
	service.reset_for_run(78)
	effects.reset_effects()
	catalog.definitions = [PROJECTILE_SPEED, REINFORCED_ROASTING_TRAY, BARB_SEASONING_XP, ABILITY_COOLDOWN]
	catalog.rebuild_registry()
	effects.recalculate_effects()


func _expect_near(actual: float, expected: float, message: String) -> void:
	_expect(absf(actual - expected) <= FLOAT_TOLERANCE, "%s Atteso %.4f, ottenuto %.4f." % [message, expected, actual])


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("POWERUP_FIRST_WAVE_SMOKE_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	printerr("POWERUP_FIRST_WAVE_SMOKE_FAIL count=%d" % _failures.size())
	quit(1)
