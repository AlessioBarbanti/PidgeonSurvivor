extends GutGameplayTest

const GOSSIP := preload("res://data/upgrades/specialities/gossip_projectiles.tres")
const CHRONIC_DELAY := preload("res://data/upgrades/specialities/chronic_delay.tres")
const BEER := preload("res://data/upgrades/specialities/beer_signature.tres")
const DAMAGE_SHOCKWAVE := preload("res://data/upgrades/specialities/damage_shockwave.tres")
const SWIFT_STEPS := preload("res://data/upgrades/swift_steps.tres")
const RAPID_FIRE := preload("res://data/upgrades/rapid_fire.tres")
const WIDE_MAGNET := preload("res://data/upgrades/wide_magnet.tres")
const MEAT_FORK_DAMAGE := preload("res://data/upgrades/meat_fork_damage.tres")

const SLOW_MODIFIER := &"upgrade_chronic_delay"

## Vita dei nemici della fixture, slegata dai dati di bilanciamento.
##
## Questo file misura quanto danno arriva a bersaglio (pieno al primo, con
## falloff al secondo) e chi viene respinto: entrambe le cose sono osservabili
## solo su un nemico che sopravvive al colpo. Con gli HP dell'archetipo il
## confronto misurava l'azzeramento della vita invece del danno, e un nemico
## gia' morto non riceve knockback.
const FIXTURE_ENEMY_HEALTH := 500.0

var _applied_ids: Array[StringName] = []
var _shockwave_affected_counts: Array[int] = []


func test_signature_composition() -> void:
	_applied_ids.clear()
	_shockwave_affected_counts.clear()

	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_run_controller() as RunController
	var experience := movement_slice.get_experience_system() as ExperienceSystem
	var service := movement_slice.get_upgrade_service() as UpgradeService
	var catalog := movement_slice.get_upgrade_registry() as UpgradeRegistry
	var effects := movement_slice.get_upgrade_effect_registry() as UpgradeEffectRegistry
	var player := movement_slice.get_node_or_null("World/Player") as Player
	var weapon := movement_slice.get_weapon_controller() as WeaponController
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	var targeting := movement_slice.get_targeting_system() as TargetingSystem
	var arena := movement_slice.get_node_or_null("ArenaLayout") as ArenaLayout
	var projectiles := movement_slice.get_projectile_parent() as Node2D

	assert_true(controller != null and experience != null, "B13 deve conservare run e XP.")
	assert_true(service != null and catalog != null and effects != null, "B13 deve comporre i registry upgrade.")
	assert_true(player != null and weapon != null, "B13 deve comporre Player e arma.")
	assert_true(spawner != null and targeting != null and arena != null, "B13 deve comporre nemici e arena.")
	assert_true(projectiles != null, "B13 deve comporre i proiettili.")
	if (
		controller == null
		or experience == null
		or service == null
		or catalog == null
		or effects == null
		or player == null
		or weapon == null
		or spawner == null
		or targeting == null
		or arena == null
		or projectiles == null
	):
		return

	controller.set_process(false)
	spawner.set_process(false)
	player.set_physics_process(false)
	weapon.set_process(false)
	effects.set_process(false)
	var ability := player.get_ability_controller()
	if ability != null:
		ability.set_process(false)

	# Isola le quattro signature rimaste (PS-100 ha rimosso L'Ansia) e le carte
	# normali ripetibili senza eludere la validazione della scena completa,
	# gia eseguita durante _ready().
	catalog.definitions = [
		GOSSIP, CHRONIC_DELAY, BEER, DAMAGE_SHOCKWAVE, SWIFT_STEPS, RAPID_FIRE, WIDE_MAGNET, MEAT_FORK_DAMAGE,
	]
	assert_true(catalog.rebuild_registry(), "Il catalogo signature isolato deve essere valido.")
	service.reset_for_run(controller.get_seed())
	assert_true(effects.recalculate_effects(), "Il registry deve accettare le quattro signature.")
	assert_true(effects.has_valid_configuration(), "Le dipendenze B13 devono essere complete.")
	effects.effect_applied.connect(_on_effect_applied)
	effects.damage_shockwave_emitted.connect(_on_damage_shockwave_emitted)
	_assert_rejected_definitions(effects)

	var health := player.get_health_component()
	var base_health_max := player.get_base_health_max()
	var base_move_speed := player.get_base_move_speed()
	var base_fire_rate := weapon.get_base_shots_per_second()
	assert_true(health != null, "Il Player B13 deve avere salute.")
	if health == null:
		controller.prepare_restart()
		return
	assert_true(player.take_contact_damage(base_health_max * 0.5), "La fixture deve portare il Player al 50%.")
	health.clear_invulnerability()

	# PS-077: tutte e quattro le signature rimaste sono Specialità di Barb,
	# bloccate all'inizio della run (PS-100 ha rimosso L'Ansia). Nessuna passa
	# più dal level-up normale: si compongono solo accumulando ricompense Boss.
	var signature_ids: Array[StringName] = [
		&"gossip_projectiles", &"chronic_delay", &"beer_signature", &"damage_shockwave",
	]
	for signature_id in signature_ids:
		assert_true(
			catalog.resolve_definition(signature_id).is_speciality,
			"%s deve dichiararsi Specialità di Barb." % signature_id
		)
	for draw_index in 8:
		for offered_definition in service.generate_offer(draw_index + 1):
			assert_false(
				offered_definition.is_speciality,
				"Il level-up normale non deve offrire signature ancora bloccate."
			)
	assert_true(
		_unlock_every_speciality(service, signature_ids.size()),
		"Ogni ricompensa Boss deve sbloccare una signature, senza mai ripetere la stessa carta."
	)
	assert_eq(_applied_ids.size(), 4, "Ogni signature deve applicarsi una sola volta.")
	for signature_id in signature_ids:
		assert_eq(service.get_rank(signature_id), 1, "%s deve fermarsi al rank 1." % signature_id)
		assert_true(effects.has_signature_effect(signature_id), "%s deve essere attiva." % signature_id)

	# Birra compone trade-off e statistiche senza mutare i Resource base.
	assert_almost_eq(
		weapon.get_effective_shots_per_second(), base_fire_rate * 1.25, FLOAT_TOLERANCE, "Birra deve aumentare la frequenza."
	)
	assert_almost_eq(
		weapon.weapon_profile.shots_per_second, base_fire_rate, FLOAT_TOLERANCE, "Il profilo arma deve restare immutabile."
	)

	assert_true(weapon.is_projectile_chain_enabled(), "Gossip deve abilitare la catena.")
	assert_eq(weapon.get_projectile_chain_jumps(), 2, "Gossip deve dare due salti.")
	assert_almost_eq(
		weapon.get_projectile_chain_damage_falloff(), 0.65, FLOAT_TOLERANCE, "Gossip deve ridurre progressivamente il danno."
	)
	assert_almost_eq(weapon.get_projectile_chain_radius(), 260.0, FLOAT_TOLERANCE, "Gossip deve usare il raggio dati.")
	assert_almost_eq(
		weapon.get_projectile_aim_spread_degrees(), 24.0, FLOAT_TOLERANCE, "Birra deve impostare la dispersione dati."
	)

	var near_enemy := _spawn_enemy(spawner, player.global_position + Vector2(100.0, 0.0))
	var far_enemy := _spawn_enemy(spawner, player.global_position + Vector2(300.0, 0.0))
	assert_true(near_enemy != null and far_enemy != null, "La fixture deve creare due nemici registrati.")
	if near_enemy == null or far_enemy == null:
		controller.prepare_restart()
		return

	# Ritardo Cronico usa soltanto tempo RUNNING, colpisce i bersagli presenti e
	# aggancia anche un nemico registrato mentre il pulse e gia attivo.
	assert_almost_eq(
		effects.get_slow_interval_remaining(), 12.0, FLOAT_TOLERANCE, "Il primo slow deve attendere 12 secondi."
	)
	effects._process(11.9)
	assert_true(not effects.is_slow_pulse_active(), "Lo slow non deve partire in anticipo.")
	effects._process(0.1)
	assert_true(effects.is_slow_pulse_active(), "Lo slow deve partire alla soglia di 12 secondi.")
	assert_true(near_enemy.has_speed_modifier(SLOW_MODIFIER), "Il nemico vicino deve ricevere lo slow.")
	assert_true(far_enemy.has_speed_modifier(SLOW_MODIFIER), "Tutti i nemici registrati devono ricevere lo slow.")
	assert_almost_eq(
		near_enemy.get_effective_move_speed(), near_enemy.move_speed * 0.5, FLOAT_TOLERANCE,
		"Lo slow deve dimezzare la velocita."
	)

	var joining_enemy := _spawn_enemy(spawner, player.global_position + Vector2(0.0, 180.0))
	assert_true(joining_enemy != null, "Un nemico deve poter entrare durante lo slow.")
	if joining_enemy != null:
		assert_true(joining_enemy.has_speed_modifier(SLOW_MODIFIER), "Un nuovo nemico deve ereditare lo slow attivo.")
	near_enemy.global_position = player.global_position + Vector2(100.0, 0.0)
	far_enemy.global_position = player.global_position + Vector2(220.0, 0.0)
	if joining_enemy != null:
		joining_enemy.global_position = player.global_position + Vector2(300.0, 0.0)

	var slow_remaining_before_pause := effects.get_slow_duration_remaining()
	assert_true(controller.request_manual_pause(), "La fixture deve mettere in pausa la run.")
	effects._process(2.0)
	assert_almost_eq(
		effects.get_slow_duration_remaining(), slow_remaining_before_pause, FLOAT_TOLERANCE,
		"La pausa non deve consumare la durata dello slow."
	)
	assert_true(controller.resume_run(), "La fixture deve riprendere la run.")
	effects._process(3.0)
	assert_true(not effects.is_slow_pulse_active(), "Lo slow deve terminare dopo tre secondi RUNNING.")
	assert_true(not near_enemy.has_speed_modifier(SLOW_MODIFIER), "La fine del pulse deve rimuovere lo status locale.")

	# Gossip e Birra convivono nello stesso snapshot: il colpo fotografa catena
	# e dispersione, senza centrare automaticamente il bersaglio mirato.
	var projectile := weapon.try_fire()
	assert_true(projectile != null, "L'arma combinata deve creare un proiettile.")
	if projectile != null:
		projectile.set_physics_process(false)
		assert_true(projectile.is_chain_enabled(), "Il nuovo proiettile deve avere la catena Gossip.")
		assert_eq(projectile.get_chain_jumps_remaining(), 2, "Il nuovo proiettile deve avere due salti.")
		assert_almost_eq(
			projectile.get_chain_damage_falloff(), 0.65, FLOAT_TOLERANCE, "Il nuovo proiettile deve conservare il falloff."
		)
		assert_almost_eq(
			projectile.get_aim_spread_degrees(), 24.0, FLOAT_TOLERANCE, "Il nuovo proiettile deve conservare la dispersione."
		)
		assert_true(
			absf(projectile.direction.angle_to(Vector2.RIGHT)) > deg_to_rad(1.0)
			and absf(projectile.direction.angle_to(Vector2.RIGHT)) <= deg_to_rad(24.0),
			"Birra deve deviare il colpo dal bersaglio, entro la dispersione dati."
		)
		var near_health_before := near_enemy.get_health_component().health_current
		var far_health_before := far_enemy.get_health_component().health_current
		var joining_health_before := joining_enemy.get_health_component().health_current if joining_enemy != null else 0.0
		assert_true(projectile.try_hit(near_enemy), "Gossip deve danneggiare il primo nemico.")
		assert_almost_eq(
			near_enemy.get_health_component().health_current, near_health_before - projectile.damage, FLOAT_TOLERANCE,
			"Il primo bersaglio Gossip deve ricevere il danno pieno."
		)
		assert_almost_eq(
			far_enemy.get_health_component().health_current, far_health_before - projectile.damage * 0.65, FLOAT_TOLERANCE,
			"Il secondo bersaglio Gossip deve ricevere danno ridotto."
		)
		if joining_enemy != null:
			assert_almost_eq(
				joining_enemy.get_health_component().health_current,
				joining_health_before - projectile.damage * 0.65 * 0.65, FLOAT_TOLERANCE,
				"Il terzo bersaglio Gossip deve ricevere danno ulteriormente ridotto."
			)
		assert_true(projectile.has_hit_target(near_enemy), "Gossip deve ricordare il primo bersaglio.")
		assert_true(projectile.is_spent(), "Gossip deve consumarsi dopo i salti disponibili.")

	# Riattiva lo slow: la shockwave deve applicare knockback senza eliminare il
	# modificatore locale e non deve riattivarsi durante gli i-frame.
	effects._process(9.0)
	assert_true(effects.is_slow_pulse_active(), "Il secondo pulse deve rispettare l'intervallo globale.")
	near_enemy.global_position = player.global_position + Vector2(100.0, 0.0)
	far_enemy.global_position = player.global_position + Vector2(300.0, 0.0)
	if joining_enemy != null:
		joining_enemy.global_position = player.global_position + Vector2(0.0, 180.0)
	health.clear_invulnerability()
	assert_true(player.take_contact_damage(10.0), "Un danno effettivo deve attivare la shockwave.")
	assert_eq(_shockwave_affected_counts.size(), 1, "Una hit deve emettere una sola shockwave.")
	assert_eq(_shockwave_affected_counts[0], 2, "La shockwave deve respingere solo i due nemici nel raggio.")
	assert_true(near_enemy.get_knockback_remaining() > 0.0, "Il nemico vicino deve ricevere knockback.")
	assert_true(is_zero_approx(far_enemy.get_knockback_remaining()), "Il nemico lontano non deve ricevere knockback.")
	assert_true(near_enemy.has_speed_modifier(SLOW_MODIFIER), "Knockback e slow devono convivere senza conflitto.")
	assert_eq(effects.get_active_shockwave_count(), 1, "La shockwave deve creare un VFX scene-local.")
	assert_true(not player.take_contact_damage(10.0), "Gli i-frame devono rifiutare il danno immediato.")
	assert_eq(_shockwave_affected_counts.size(), 1, "Un danno rifiutato non deve riattivare la shockwave.")

	# Il restart elimina status, VFX, vignetta e profilo dei proiettili, oltre ai
	# rank. La seconda run riparte dai valori base.
	assert_true(controller.request_defeat(), "La fixture deve terminare la prima run.")
	assert_true(movement_slice.restart_run(13014), "B13 deve supportare una seconda run pulita.")
	await wait_process_frames(2)
	assert_true(service.get_ranks().is_empty(), "Il restart deve azzerare i rank signature.")
	assert_almost_eq(player.move_speed, base_move_speed, FLOAT_TOLERANCE, "Il restart deve ripristinare la velocita.")
	assert_almost_eq(health.health_max, base_health_max, FLOAT_TOLERANCE, "Il restart deve ripristinare la vita massima.")
	assert_almost_eq(health.health_current, base_health_max, FLOAT_TOLERANCE, "Il restart deve curare il Player.")
	assert_almost_eq(
		weapon.get_effective_shots_per_second(), base_fire_rate, FLOAT_TOLERANCE, "Il restart deve ripristinare la frequenza."
	)
	assert_true(not weapon.is_projectile_chain_enabled(), "Il restart deve rimuovere Gossip.")
	assert_eq(weapon.get_projectile_chain_jumps(), 0, "Il restart deve rimuovere i salti Gossip.")
	assert_true(is_zero_approx(weapon.get_projectile_aim_spread_degrees()), "Il restart deve rimuovere la dispersione.")
	assert_true(not effects.is_slow_pulse_active(), "Il restart deve fermare lo slow.")
	assert_true(is_zero_approx(effects.get_slow_interval_remaining()), "Il restart deve azzerare lo scheduler slow.")
	assert_eq(effects.get_active_shockwave_count(), 0, "Il restart deve eliminare i VFX shockwave.")
	assert_eq(targeting.get_registered_count(), 0, "Il restart deve svuotare i bersagli della run precedente.")
	assert_eq(projectiles.get_child_count(), 0, "Il restart deve eliminare i proiettili precedenti.")

	controller.prepare_restart()


## Ogni ricompensa Boss sblocca una sola Specialità: ne servono tante quante
## sono le signature da comporre. L'offerta pesca senza rimpiazzo fra quelle
## ancora bloccate, quindi la prima carta offerta basta a esaurirle tutte.
func _unlock_every_speciality(service: UpgradeService, expected_count: int) -> bool:
	var unlocked_ids: Dictionary = {}
	for _reward_index in expected_count:
		service.queue_barb_reward()
		var offered_ids := service.get_current_barb_offer_ids()
		if offered_ids.is_empty():
			return false
		var chosen_id := offered_ids[0]
		if unlocked_ids.has(chosen_id) or not service.select_barb_speciality(chosen_id):
			return false
		unlocked_ids[chosen_id] = true
	return service.get_locked_speciality_definitions().is_empty()


func _spawn_enemy(spawner: EnemySpawner, position: Vector2) -> BaseEnemy:
	var enemy := spawner.try_spawn_enemy()
	if enemy == null:
		return null
	enemy.global_position = position
	enemy.set_physics_process(false)
	var health := enemy.get_health_component()
	if health != null:
		health.set_health_max(FIXTURE_ENEMY_HEALTH)
		health.heal(FIXTURE_ENEMY_HEALTH)
	return enemy


func _assert_rejected_definitions(effects: UpgradeEffectRegistry) -> void:
	var bad_gossip := (GOSSIP as UpgradeDefinition).duplicate(true) as UpgradeDefinition
	bad_gossip.id = &"bad_gossip"
	bad_gossip.effect_parameters = {
		"chain_jumps_per_rank": 2.0,
		"chain_radius": 260.0,
		"damage_falloff": 0.65,
	}
	assert_true(not effects.can_apply(bad_gossip), "Il conteggio dei salti Gossip deve essere intero.")

	var bad_beer := (BEER as UpgradeDefinition).duplicate(true) as UpgradeDefinition
	bad_beer.id = &"bad_beer"
	bad_beer.effect_parameters = {
		"fire_rate_multiplier": 1.25,
		"aim_spread_degrees": 0.0,
	}
	assert_true(not effects.can_apply(bad_beer), "Una dispersione nulla deve essere rifiutata.")

	var repeatable_signature := (DAMAGE_SHOCKWAVE as UpgradeDefinition).duplicate(true) as UpgradeDefinition
	repeatable_signature.id = &"repeatable_signature"
	repeatable_signature.repeatable = true
	assert_true(not effects.can_apply(repeatable_signature), "Le signature non devono essere ripetibili.")


func _on_effect_applied(definition: UpgradeDefinition, _new_rank: int, _effective_multipliers: Dictionary) -> void:
	if definition.id in [GOSSIP.id, CHRONIC_DELAY.id, BEER.id, DAMAGE_SHOCKWAVE.id]:
		_applied_ids.append(definition.id)


func _on_damage_shockwave_emitted(affected_count: int) -> void:
	_shockwave_affected_counts.append(affected_count)
