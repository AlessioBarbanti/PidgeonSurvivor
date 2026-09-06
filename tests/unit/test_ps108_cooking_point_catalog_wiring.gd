extends GutGameplayTest

## PS-108: prova che "Punto di Cottura" (PS-107) sia davvero pescabile nel
## catalogo live (non solo definito in un .tres orfano) e che la sua
## risoluzione tramite UpgradeEffectRegistry applichi il bonus critico
## dichiarato al WeaponController reale.

const COOKING_POINT_CRIT := preload("res://data/upgrades/cooking_point_crit.tres")
const SWIFT_STEPS := preload("res://data/upgrades/swift_steps.tres")
const RAPID_FIRE := preload("res://data/upgrades/rapid_fire.tres")
const WIDE_MAGNET := preload("res://data/upgrades/wide_magnet.tres")
const OFFER_RETRY_LIMIT := 40


func test_cooking_point_crit_is_wired_into_live_catalog_and_applies_effect() -> void:
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_run_controller() as RunController
	var experience := movement_slice.get_experience_system() as ExperienceSystem
	var service := movement_slice.get_upgrade_service() as UpgradeService
	var catalog := movement_slice.get_upgrade_registry() as UpgradeRegistry
	var effects := movement_slice.get_upgrade_effect_registry() as UpgradeEffectRegistry
	var player := movement_slice.get_node_or_null("World/Player") as Player
	var weapon := movement_slice.get_weapon_controller() as WeaponController
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner

	assert_true(controller != null and experience != null, "PS-108 deve conservare run e progressione.")
	assert_true(service != null and catalog != null and effects != null, "PS-108 deve comporre i registry upgrade.")
	assert_true(player != null and weapon != null, "PS-108 deve comporre Player e arma.")
	if (
		controller == null
		or experience == null
		or service == null
		or catalog == null
		or effects == null
		or player == null
		or weapon == null
		or spawner == null
	):
		return

	# Il catalogo live di movement_slice.tscn e' gia' stato costruito e
	# validato da UpgradeRegistry._ready() prima di questa riga: verifichiamo
	# qui che "Punto di Cottura" sia davvero fra i pescabili, non solo un
	# .tres isolato mai referenziato da nessuna scena (il difetto che PS-108
	# doveva correggere).
	var live_ids: Array[StringName] = []
	for definition: UpgradeDefinition in catalog.definitions:
		live_ids.append(definition.id)
	assert_true(
		&"cooking_point_crit" in live_ids,
		"PS-108 richiede che 'cooking_point_crit' sia nel catalogo pescabile live."
	)
	var live_definition: UpgradeDefinition = null
	for definition: UpgradeDefinition in catalog.definitions:
		if definition.id == &"cooking_point_crit":
			live_definition = definition
			break
	assert_true(
		live_definition != null and live_definition.icon != null,
		"La carta live deve referenziare l'icona reale di PS-107, non restare senza icon."
	)

	controller.set_process(false)
	spawner.set_process(false)
	player.set_physics_process(false)
	weapon.set_process(false)
	var ability := player.get_ability_controller()
	if ability != null:
		ability.set_process(false)

	# Isola un piccolo sottoinsieme (stesso pattern di B12/B13) per rendere
	# deterministica la pesca, senza eludere la validazione della scena
	# completa gia' eseguita sopra.
	catalog.definitions = [SWIFT_STEPS, RAPID_FIRE, WIDE_MAGNET, COOKING_POINT_CRIT]
	assert_true(catalog.rebuild_registry(), "Il catalogo isolato PS-108 deve essere valido.")
	service.reset_for_run(controller.get_seed())
	assert_true(effects.recalculate_effects(), "Il registry deve accettare 'cooking_point_crit'.")
	assert_true(effects.has_valid_configuration(), "La configurazione isolata PS-108 deve essere completa.")
	assert_true(
		effects.can_apply(COOKING_POINT_CRIT),
		"UpgradeEffectRegistry.can_apply() deve accettare la carta reale di PS-107/PS-108."
	)

	var base_damage := weapon.get_base_damage()
	assert_almost_eq(
		weapon.get_critical_chance_bonus(), 0.0, FLOAT_TOLERANCE, "Senza upgrade il bonus critico deve restare a zero."
	)
	assert_almost_eq(
		weapon.get_critical_damage_multiplier(), 1.0, FLOAT_TOLERANCE, "Senza upgrade il moltiplicatore critico deve restare a identita."
	)

	assert_true(
		_grant_and_select(experience, service, &"cooking_point_crit"),
		"'Punto di Cottura' deve essere selezionabile dal pool pescabile isolato."
	)
	assert_almost_eq(
		weapon.get_critical_chance_bonus(), 0.05, FLOAT_TOLERANCE, "Il primo rango deve applicare +5%% di probabilita critica."
	)
	assert_almost_eq(
		weapon.get_critical_damage_multiplier(), 1.75, FLOAT_TOLERANCE, "Il moltiplicatore di danno critico deve essere 1,75x."
	)

	assert_true(
		_grant_and_select(experience, service, &"cooking_point_crit"),
		"'Punto di Cottura' deve restare selezionabile al secondo rango (ripetibile)."
	)
	assert_almost_eq(
		weapon.get_critical_chance_bonus(), 0.10, FLOAT_TOLERANCE, "Due ranghi devono comporre +10%% di probabilita critica."
	)
	assert_almost_eq(
		weapon.get_base_damage(), base_damage, FLOAT_TOLERANCE, "L'upgrade critico non deve mutare il danno base condiviso."
	)

	controller.prepare_restart()
	print("COOKING_POINT_CATALOG_WIRING_SMOKE_OK")


func _grant_and_select(experience: ExperienceSystem, service: UpgradeService, upgrade_id: StringName) -> bool:
	for _attempt in range(OFFER_RETRY_LIMIT):
		if not experience.add_experience(experience.experience_required):
			return false
		if upgrade_id in service.get_current_offer_ids():
			return service.select_upgrade(upgrade_id)
		if not experience.complete_level_up():
			return false
	return false
