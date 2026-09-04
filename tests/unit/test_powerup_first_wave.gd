extends GutGameplayTest

const PROJECTILE_SPEED := preload("res://data/upgrades/projectile_speed.tres")
const REINFORCED_ROASTING_TRAY := preload("res://data/upgrades/reinforced_roasting_tray.tres")
const BARB_SEASONING_XP := preload("res://data/upgrades/barb_seasoning_xp.tres")
const ABILITY_COOLDOWN := preload("res://data/upgrades/ability_cooldown.tres")
const RAPID_FIRE := preload("res://data/upgrades/rapid_fire.tres")
const WIDE_MAGNET := preload("res://data/upgrades/wide_magnet.tres")


func test_first_wave_upgrades_apply_and_reset_cleanly() -> void:
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_run_controller() as RunController
	var experience := movement_slice.get_experience_system() as ExperienceSystem
	var catalog := movement_slice.get_upgrade_registry() as UpgradeRegistry
	var service := movement_slice.get_upgrade_service() as UpgradeService
	var effects := movement_slice.get_upgrade_effect_registry() as UpgradeEffectRegistry
	var player := movement_slice.get_node_or_null("World/Player") as Player
	var weapon := movement_slice.get_weapon_controller() as WeaponController
	assert_true(
		controller != null
		and experience != null
		and catalog != null
		and service != null
		and effects != null
		and player != null
		and weapon != null,
		"La fixture prima ondata richiede tutti i servizi runtime."
	)
	if (
		controller == null
		or experience == null
		or catalog == null
		or service == null
		or effects == null
		or player == null
		or weapon == null
	):
		return

	var curve := ExperienceCurve.new()
	curve.base_experience_required = 999
	curve.experience_growth_per_level = 0
	experience.experience_curve = curve
	_assert_data(catalog, effects)
	await _assert_projectile_speed(catalog, service, effects, experience, weapon)
	await _assert_damage_reduction(catalog, service, effects, experience, player)
	await _assert_xp_value(catalog, service, effects, experience)
	await _assert_ability_cooldown(catalog, service, effects, experience, player)
	assert_true(controller.request_defeat(), "La fixture deve poter concludere la run.")


func _assert_data(catalog: UpgradeRegistry, effects: UpgradeEffectRegistry) -> void:
	for definition in [PROJECTILE_SPEED, REINFORCED_ROASTING_TRAY, BARB_SEASONING_XP, ABILITY_COOLDOWN]:
		assert_true(definition.is_valid(), "La definizione prima ondata deve essere valida: %s." % definition.id)
		assert_true(
			definition.repeatable and definition.max_rank == 5,
			"La carta deve restare ripetibile al rango nominale 5: %s." % definition.id
		)
		assert_true(
			definition.icon != null and not definition.icon.resource_path.is_empty(),
			"La carta deve avere un'icona runtime: %s." % definition.id
		)
		assert_true(effects.can_apply(definition), "L'effetto deve essere supportato: %s." % definition.effect_id)
	assert_eq(RAPID_FIRE.title, "A Tutta Brace!", "rapid_fire deve avere il nuovo nome.")
	assert_eq(WIDE_MAGNET.title, "Pinza Lunga", "wide_magnet deve avere il nuovo nome.")
	assert_eq(
		catalog.resolve_definition(PROJECTILE_SPEED.id), PROJECTILE_SPEED, "Il catalogo runtime deve registrare Via dalla Griglia!."
	)


func _assert_projectile_speed(
	catalog: UpgradeRegistry,
	service: UpgradeService,
	effects: UpgradeEffectRegistry,
	experience: ExperienceSystem,
	weapon: WeaponController
) -> void:
	var base_speed := weapon.weapon_profile.projectile_speed
	assert_true(
		await _select_fixture_upgrade(catalog, service, effects, experience, PROJECTILE_SPEED),
		"Via dalla Griglia! deve essere selezionabile."
	)
	assert_almost_eq(
		weapon.get_effective_projectile_speed(), base_speed * 1.1, FLOAT_TOLERANCE, "La velocita dei proiettili deve crescere del 10%."
	)
	assert_almost_eq(
		effects.get_effective_multiplier(UpgradeEffectRegistry.WEAPON_PROJECTILE_SPEED_MULTIPLIER),
		1.1,
		FLOAT_TOLERANCE,
		"Il moltiplicatore projectile speed deve essere tracciato."
	)
	_reset_fixture(catalog, service, effects)


func _assert_damage_reduction(
	catalog: UpgradeRegistry,
	service: UpgradeService,
	effects: UpgradeEffectRegistry,
	experience: ExperienceSystem,
	player: Player
) -> void:
	assert_true(
		await _select_fixture_upgrade(catalog, service, effects, experience, REINFORCED_ROASTING_TRAY),
		"Pirofila Rinforzata deve essere selezionabile."
	)
	assert_almost_eq(
		player.get_damage_taken_multiplier(), 0.94, FLOAT_TOLERANCE, "La pirofila deve ridurre il danno ricevuto del 6%."
	)
	var health := player.get_health_component()
	if health != null:
		health.reset_to_max()
		assert_true(player.take_contact_damage(10.0), "Il Player deve accettare il danno di contatto.")
		assert_almost_eq(
			health.health_current,
			health.health_max - 9.4,
			FLOAT_TOLERANCE,
			"La pirofila non deve modificare invulnerabilita o vita massima."
		)
	_reset_fixture(catalog, service, effects)


func _assert_xp_value(
	catalog: UpgradeRegistry,
	service: UpgradeService,
	effects: UpgradeEffectRegistry,
	experience: ExperienceSystem
) -> void:
	assert_true(
		await _select_fixture_upgrade(catalog, service, effects, experience, BARB_SEASONING_XP),
		"Il condimento di Barb deve essere selezionabile."
	)
	var total_before := experience.experience_total
	assert_true(experience.add_experience(10), "L'XP potenziata deve poter essere aggiunta.")
	assert_eq(experience.experience_total - total_before, 11, "Il condimento deve assegnare il 10% di XP aggiuntiva.")
	assert_almost_eq(
		experience.get_upgrade_value_multiplier(), 1.1, FLOAT_TOLERANCE, "Il moltiplicatore XP deve restare separato dal pickup range."
	)
	_reset_fixture(catalog, service, effects)


func _assert_ability_cooldown(
	catalog: UpgradeRegistry,
	service: UpgradeService,
	effects: UpgradeEffectRegistry,
	experience: ExperienceSystem,
	player: Player
) -> void:
	var ability := player.get_ability_controller()
	if ability == null:
		assert_true(false, "La prima ondata richiede l'abilita attiva equipaggiata.")
		return
	var base_cooldown := ability.get_cooldown_total()
	assert_true(ability.try_activate(), "L'abilita base deve potersi attivare.")
	var active_snapshot := ability.get_cooldown_total()
	assert_true(
		await _select_fixture_upgrade(catalog, service, effects, experience, ABILITY_COOLDOWN),
		"Ravviva la Brace! deve essere selezionabile."
	)
	assert_almost_eq(
		ability.get_cooldown_total(), active_snapshot, FLOAT_TOLERANCE, "Un cooldown gia avviato deve conservare il proprio snapshot."
	)
	ability._process(ability.get_cooldown_remaining())
	assert_true(ability.try_activate(), "L'abilita deve potersi riattivare dopo il cooldown.")
	assert_almost_eq(
		ability.get_cooldown_total(), base_cooldown * 0.92, FLOAT_TOLERANCE, "Il cooldown successivo deve ridursi dell'8%."
	)
	assert_almost_eq(
		effects.get_effective_multiplier(UpgradeEffectRegistry.ACTIVE_ABILITY_COOLDOWN_MULTIPLIER),
		0.92,
		FLOAT_TOLERANCE,
		"Il moltiplicatore cooldown deve essere tracciato."
	)
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
