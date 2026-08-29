extends GutGameplayTest

const MEAT_FORK_DAMAGE := preload("res://data/upgrades/meat_fork_damage.tres")
const GOSSIP := preload("res://data/upgrades/gossip_projectiles.tres")
const BEER := preload("res://data/upgrades/beer_signature.tres")
const SWIFT_STEPS := preload("res://data/upgrades/swift_steps.tres")
const RAPID_FIRE := preload("res://data/upgrades/rapid_fire.tres")
const WIDE_MAGNET := preload("res://data/upgrades/wide_magnet.tres")


func test_damage_upgrade() -> void:
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_run_controller() as RunController
	var experience := movement_slice.get_experience_system() as ExperienceSystem
	var service := movement_slice.get_upgrade_service() as UpgradeService
	var catalog := movement_slice.get_upgrade_registry() as UpgradeRegistry
	var effects := movement_slice.get_upgrade_effect_registry() as UpgradeEffectRegistry
	var weapon := movement_slice.get_weapon_controller() as WeaponController
	var boss_encounter := movement_slice.get_boss_encounter() as BossEncounter
	var player := movement_slice.get_node_or_null("World/Player") as Player
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	var projectiles := movement_slice.get_projectile_parent() as Node2D
	assert_true(
		controller != null and experience != null and service != null and catalog != null and effects != null
		and weapon != null and boss_encounter != null and player != null and spawner != null and projectiles != null,
		"B26 richiede run, upgrade, arma e Boss composti."
	)
	if (
		controller == null
		or experience == null
		or service == null
		or catalog == null
		or effects == null
		or weapon == null
		or boss_encounter == null
		or player == null
		or spawner == null
		or projectiles == null
	):
		return

	controller.set_process(false)
	spawner.set_process(false)
	player.set_physics_process(false)
	weapon.set_process(false)
	var ability := player.get_ability_controller()
	if ability != null:
		ability.set_process(false)

	# Le carte statistiche normali ripetibili mantengono la pesca completa.
	catalog.definitions = [MEAT_FORK_DAMAGE, GOSSIP, BEER, SWIFT_STEPS, RAPID_FIRE, WIDE_MAGNET]
	assert_true(catalog.rebuild_registry(), "Il catalogo B26 deve essere valido.")
	service.reset_for_run(controller.get_seed())
	assert_true(effects.recalculate_effects(), "Il registry deve accettare B26.")

	var definition := catalog.resolve_definition(&"meat_fork_damage")
	assert_true(definition == MEAT_FORK_DAMAGE, "B26 deve registrare il Forchettone dedicato.")
	assert_true(
		definition != null
		and definition.effect_id == UpgradeEffectRegistry.WEAPON_DAMAGE_MULTIPLIER
		and definition.max_rank == 5
		and definition.repeatable
		and is_equal_approx(float(definition.effect_parameters.get("multiplier", 0.0)), 1.15),
		"B26 deve dichiarare +15% danno per ogni rank ripetibile."
	)
	if definition == null:
		return

	var base_damage := weapon.get_base_damage()
	var base_fire_rate := weapon.get_base_shots_per_second()
	assert_almost_eq(
		weapon.get_effective_damage(), base_damage, FLOAT_TOLERANCE, "Il danno iniziale deve restare base."
	)
	assert_almost_eq(
		weapon.get_effective_shots_per_second(), base_fire_rate, FLOAT_TOLERANCE, "B26 non deve cambiare la cadenza base."
	)

	assert_true(_select_when_offered(experience, service, GOSSIP.id), "Gossip deve entrare nella pesca B26.")
	assert_true(_select_when_offered(experience, service, BEER.id), "Birra deve entrare nella pesca B26.")
	assert_true(effects.has_signature_effect(GOSSIP.effect_id), "Gossip deve restare attivo.")
	assert_true(effects.has_signature_effect(BEER.effect_id), "Birra deve restare attiva.")
	assert_almost_eq(
		weapon.get_effective_damage(), base_damage, FLOAT_TOLERANCE, "Gossip e Birra non devono alterare da soli il danno base."
	)
	var fire_rate_before_damage_ranks := weapon.get_effective_shots_per_second()

	for rank in range(1, definition.max_rank + 1):
		assert_true(
			_select_when_offered(experience, service, definition.id), "Il Forchettone deve essere selezionabile al rank %d." % rank
		)
		assert_eq(service.get_rank(definition.id), rank, "B26 deve registrare il rank %d." % rank)
		assert_almost_eq(
			weapon.get_effective_damage(), base_damage * pow(1.15, rank), FLOAT_TOLERANCE,
			"Il rank %d deve comporre il danno moltiplicativamente." % rank
		)
		assert_almost_eq(
			weapon.get_effective_shots_per_second(), fire_rate_before_damage_ranks, FLOAT_TOLERANCE,
			"B26 non deve modificare la cadenza gia ottenuta da altre carte."
		)

	assert_true(_select_when_offered(experience, service, definition.id), "Il sesto rank deve restare selezionabile.")
	assert_eq(service.get_rank(definition.id), definition.max_rank + 1, "B26 non deve applicare un cap di pesca.")

	spawner.reset_for_run(26026)
	spawner._process(spawner.spawn_profile.initial_spawn_delay)
	assert_eq(spawner.get_alive_count(), 1, "La fixture B26 deve creare un bersaglio.")
	if spawner.get_alive_count() == 1:
		var target := spawner.get_spawned_enemies()[0]
		target.set_physics_process(false)
		target.global_position = player.global_position + Vector2(160.0, 0.0)
		var projectile := weapon.try_fire()
		assert_true(projectile != null, "L'arma deve sparare con B26 attivo.")
		if projectile != null:
			projectile.set_physics_process(false)
			assert_almost_eq(
				projectile.damage, base_damage * pow(1.15, service.get_rank(definition.id)), FLOAT_TOLERANCE,
				"Il proiettile deve fotografare il danno B26."
			)
			assert_eq(projectile.get_chain_jumps_remaining(), 2, "Gossip deve restare composto sul proiettile B26.")
			assert_almost_eq(
				projectile.get_aim_spread_degrees(), 24.0, FLOAT_TOLERANCE, "Birra deve restare composta sul proiettile B26."
			)
		target.queue_free()
		await wait_process_frames(1)

	controller._process(240.01)
	var boss := boss_encounter.get_active_boss()
	assert_true(boss != null, "B26 deve raggiungere il Boss con il normale clock della run.")
	if boss != null:
		assert_true(boss_encounter.complete_intro(), "Il Boss B26 deve entrare nel combattimento normale.")
		var boss_health := boss.get_health_component()
		assert_true(boss_health != null, "Il Boss B26 deve avere HealthComponent.")
		if boss_health != null:
			var before_damage := boss_health.health_current
			assert_true(boss.take_damage(weapon.get_effective_damage()), "Il Boss deve accettare il danno B26.")
			assert_almost_eq(
				boss_health.health_current, before_damage - base_damage * pow(1.15, service.get_rank(definition.id)),
				FLOAT_TOLERANCE, "Il Boss deve ricevere il danno effettivo B26."
			)

	assert_almost_eq(
		weapon.weapon_profile.damage, base_damage, FLOAT_TOLERANCE, "B26 non deve mutare il WeaponProfile condiviso."
	)
	assert_true(controller.request_defeat(), "La fixture deve poter terminare la prima run.")
	assert_true(movement_slice.restart_run(26027), "B26 deve poter avviare una seconda run.")
	assert_true(service.get_ranks().is_empty(), "Restart deve azzerare il Forchettone.")
	assert_almost_eq(
		weapon.get_effective_damage(), base_damage, FLOAT_TOLERANCE, "Restart deve ripristinare il danno base."
	)


func _select_when_offered(
	experience: ExperienceSystem, service: UpgradeService, upgrade_id: StringName
) -> bool:
	for _attempt in 12:
		if not experience.add_experience(experience.experience_required):
			return false
		var offered_ids := service.get_current_offer_ids()
		if offered_ids.is_empty():
			return false
		var selected_id := upgrade_id
		if selected_id not in offered_ids:
			for offered_id in offered_ids:
				if upgrade_id == MEAT_FORK_DAMAGE.id and offered_id in [SWIFT_STEPS.id, WIDE_MAGNET.id]:
					selected_id = offered_id
					break
				if upgrade_id != MEAT_FORK_DAMAGE.id and offered_id not in [MEAT_FORK_DAMAGE.id, GOSSIP.id, BEER.id]:
					selected_id = offered_id
					break
		if selected_id not in offered_ids:
			return false
		if not service.select_upgrade(selected_id):
			return false
		if selected_id == upgrade_id:
			return true
	return false
