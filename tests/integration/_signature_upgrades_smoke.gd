extends SceneTree

const MOVEMENT_SLICE_SCENE := preload("res://scenes/game/movement_slice.tscn")
const ANXIETY := preload("res://data/upgrades/anxiety_signature.tres")
const GOSSIP := preload("res://data/upgrades/gossip_projectiles.tres")
const CHRONIC_DELAY := preload("res://data/upgrades/chronic_delay.tres")
const BEER := preload("res://data/upgrades/beer_signature.tres")
const DAMAGE_SHOCKWAVE := preload("res://data/upgrades/damage_shockwave.tres")
const SWIFT_STEPS := preload("res://data/upgrades/swift_steps.tres")
const RAPID_FIRE := preload("res://data/upgrades/rapid_fire.tres")
const WIDE_MAGNET := preload("res://data/upgrades/wide_magnet.tres")
const MEAT_FORK_DAMAGE := preload("res://data/upgrades/meat_fork_damage.tres")

const INITIAL_VIEWPORT_SIZE := Vector2i(1280, 720)
const FLOAT_TOLERANCE := 0.001
const SLOW_MODIFIER := &"upgrade_chronic_delay"

var _failures: Array[String] = []
var _applied_ids: Array[StringName] = []
var _shockwave_affected_counts: Array[int] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	paused = false
	root.content_scale_size = INITIAL_VIEWPORT_SIZE
	root.size = INITIAL_VIEWPORT_SIZE
	await _wait_processed_frame()
	await _validate_signature_composition()
	await _finish()


func _validate_signature_composition() -> void:
	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	root.add_child(movement_slice)
	await _wait_processed_frame()

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
	var vignette := movement_slice.get_vignette_effect() as VignetteEffect

	_expect(controller != null and experience != null, "B13 deve conservare run e XP.")
	_expect(service != null and catalog != null and effects != null, "B13 deve comporre i registry upgrade.")
	_expect(player != null and weapon != null, "B13 deve comporre Player e arma.")
	_expect(spawner != null and targeting != null and arena != null, "B13 deve comporre nemici e arena.")
	_expect(projectiles != null and vignette != null, "B13 deve comporre proiettili e vignetta.")
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
		or vignette == null
	):
		paused = false
		movement_slice.queue_free()
		await process_frame
		return

	controller.set_process(false)
	spawner.set_process(false)
	player.set_physics_process(false)
	weapon.set_process(false)
	effects.set_process(false)
	var ability := player.get_ability_controller()
	if ability != null:
		ability.set_process(false)

	# Isola le cinque signature e le carte normali ripetibili senza eludere la validazione
	# della scena completa, gia eseguita durante _ready().
	catalog.definitions = [
		ANXIETY,
		GOSSIP,
		CHRONIC_DELAY,
		BEER,
		DAMAGE_SHOCKWAVE,
		SWIFT_STEPS,
		RAPID_FIRE,
		WIDE_MAGNET,
		MEAT_FORK_DAMAGE,
	]
	_expect(catalog.rebuild_registry(), "Il catalogo signature isolato deve essere valido.")
	service.reset_for_run(controller.get_seed())
	_expect(effects.recalculate_effects(), "Il registry deve accettare le cinque signature.")
	_expect(effects.has_valid_configuration(), "Le dipendenze B13 devono essere complete.")
	effects.effect_applied.connect(_on_effect_applied)
	effects.damage_shockwave_emitted.connect(_on_damage_shockwave_emitted)
	_validate_rejected_definitions(effects)

	var health := player.get_health_component()
	var base_health_max := player.get_base_health_max()
	var base_move_speed := player.get_base_move_speed()
	var base_fire_rate := weapon.get_base_shots_per_second()
	_expect(health != null, "Il Player B13 deve avere salute.")
	if health == null:
		controller.prepare_restart()
		paused = false
		movement_slice.queue_free()
		await process_frame
		return
	_expect(player.take_contact_damage(base_health_max * 0.5), "La fixture deve portare il Player al 50%.")
	health.clear_invulnerability()

	var signature_ids: Array[StringName] = [
		&"anxiety_signature",
		&"gossip_projectiles",
		&"chronic_delay",
		&"beer_signature",
		&"damage_shockwave",
	]
	_expect(
		_select_all_signatures(experience, service, signature_ids),
		"Le cinque signature devono essere acquisibili in offerte uniche."
	)
	_expect(_applied_ids.size() == 5, "Ogni signature deve applicarsi una sola volta.")
	for signature_id in signature_ids:
		_expect(service.get_rank(signature_id) == 1, "%s deve fermarsi al rank 1." % signature_id)
		_expect(effects.has_signature_effect(signature_id), "%s deve essere attiva." % signature_id)

	# Ansia e Birra compongono trade-off e statistiche senza mutare i
	# Resource base. La salute conserva esattamente il rapporto precedente.
	_expect_float_near(player.move_speed, base_move_speed * 1.35, "L'Ansia deve aumentare la velocita.")
	_expect_float_near(health.health_max, base_health_max * 0.8, "L'Ansia deve ridurre la vita massima.")
	_expect_float_near(health.health_current, base_health_max * 0.4, "L'Ansia deve conservare il 50% di vita.")
	_expect_float_near(
		weapon.get_effective_shots_per_second(),
		base_fire_rate * 1.25,
		"Birra deve aumentare la frequenza."
	)
	_expect_float_near(weapon.weapon_profile.shots_per_second, base_fire_rate, "Il profilo arma deve restare immutabile.")
	_expect(vignette.visible, "L'Ansia deve mostrare la vignetta.")
	_expect_float_near(vignette.intensity, 0.42, "La vignetta deve usare l'intensita dati.")

	_expect(weapon.is_projectile_chain_enabled(), "Gossip deve abilitare la catena.")
	_expect(weapon.get_projectile_chain_jumps() == 2, "Gossip deve dare due salti.")
	_expect_float_near(weapon.get_projectile_chain_damage_falloff(), 0.65, "Gossip deve ridurre progressivamente il danno.")
	_expect_float_near(weapon.get_projectile_chain_radius(), 260.0, "Gossip deve usare il raggio dati.")
	_expect_float_near(weapon.get_projectile_aim_spread_degrees(), 24.0, "Birra deve impostare la dispersione dati.")

	var near_enemy := _spawn_enemy(spawner, player.global_position + Vector2(100.0, 0.0))
	var far_enemy := _spawn_enemy(spawner, player.global_position + Vector2(300.0, 0.0))
	_expect(near_enemy != null and far_enemy != null, "La fixture deve creare due nemici registrati.")
	if near_enemy == null or far_enemy == null:
		controller.prepare_restart()
		paused = false
		movement_slice.queue_free()
		await process_frame
		return

	# Ritardo Cronico usa soltanto tempo RUNNING, colpisce i bersagli presenti e
	# aggancia anche un nemico registrato mentre il pulse e gia attivo.
	_expect_float_near(effects.get_slow_interval_remaining(), 12.0, "Il primo slow deve attendere 12 secondi.")
	effects._process(11.9)
	_expect(not effects.is_slow_pulse_active(), "Lo slow non deve partire in anticipo.")
	effects._process(0.1)
	_expect(effects.is_slow_pulse_active(), "Lo slow deve partire alla soglia di 12 secondi.")
	_expect(near_enemy.has_speed_modifier(SLOW_MODIFIER), "Il nemico vicino deve ricevere lo slow.")
	_expect(far_enemy.has_speed_modifier(SLOW_MODIFIER), "Tutti i nemici registrati devono ricevere lo slow.")
	_expect_float_near(near_enemy.get_effective_move_speed(), near_enemy.move_speed * 0.5, "Lo slow deve dimezzare la velocita.")

	var joining_enemy := _spawn_enemy(spawner, player.global_position + Vector2(0.0, 180.0))
	_expect(joining_enemy != null, "Un nemico deve poter entrare durante lo slow.")
	if joining_enemy != null:
		_expect(joining_enemy.has_speed_modifier(SLOW_MODIFIER), "Un nuovo nemico deve ereditare lo slow attivo.")
	near_enemy.global_position = player.global_position + Vector2(100.0, 0.0)
	far_enemy.global_position = player.global_position + Vector2(220.0, 0.0)
	if joining_enemy != null:
		joining_enemy.global_position = player.global_position + Vector2(300.0, 0.0)

	var slow_remaining_before_pause := effects.get_slow_duration_remaining()
	_expect(controller.request_manual_pause(), "La fixture deve mettere in pausa la run.")
	effects._process(2.0)
	_expect_float_near(
		effects.get_slow_duration_remaining(),
		slow_remaining_before_pause,
		"La pausa non deve consumare la durata dello slow."
	)
	_expect(controller.resume_run(), "La fixture deve riprendere la run.")
	effects._process(3.0)
	_expect(not effects.is_slow_pulse_active(), "Lo slow deve terminare dopo tre secondi RUNNING.")
	_expect(not near_enemy.has_speed_modifier(SLOW_MODIFIER), "La fine del pulse deve rimuovere lo status locale.")

	# Gossip e Birra convivono nello stesso snapshot: il colpo fotografa catena
	# e dispersione, senza centrare automaticamente il bersaglio mirato.
	var projectile := weapon.try_fire()
	_expect(projectile != null, "L'arma combinata deve creare un proiettile.")
	if projectile != null:
		projectile.set_physics_process(false)
		_expect(projectile.is_chain_enabled(), "Il nuovo proiettile deve avere la catena Gossip.")
		_expect(projectile.get_chain_jumps_remaining() == 2, "Il nuovo proiettile deve avere due salti.")
		_expect_float_near(projectile.get_chain_damage_falloff(), 0.65, "Il nuovo proiettile deve conservare il falloff.")
		_expect_float_near(projectile.get_aim_spread_degrees(), 24.0, "Il nuovo proiettile deve conservare la dispersione.")
		_expect(
			absf(projectile.direction.angle_to(Vector2.RIGHT)) > deg_to_rad(1.0)
			and absf(projectile.direction.angle_to(Vector2.RIGHT)) <= deg_to_rad(24.0),
			"Birra deve deviare il colpo dal bersaglio, entro la dispersione dati."
		)
		var near_health_before := near_enemy.get_health_component().health_current
		var far_health_before := far_enemy.get_health_component().health_current
		var joining_health_before := joining_enemy.get_health_component().health_current if joining_enemy != null else 0.0
		_expect(projectile.try_hit(near_enemy), "Gossip deve danneggiare il primo nemico.")
		_expect_float_near(
			near_enemy.get_health_component().health_current,
			near_health_before - projectile.damage,
			"Il primo bersaglio Gossip deve ricevere il danno pieno."
		)
		_expect_float_near(
			far_enemy.get_health_component().health_current,
			far_health_before - projectile.damage * 0.65,
			"Il secondo bersaglio Gossip deve ricevere danno ridotto."
		)
		if joining_enemy != null:
			_expect_float_near(
				joining_enemy.get_health_component().health_current,
				joining_health_before - projectile.damage * 0.65 * 0.65,
				"Il terzo bersaglio Gossip deve ricevere danno ulteriormente ridotto."
		)
		_expect(projectile.has_hit_target(near_enemy), "Gossip deve ricordare il primo bersaglio.")
		_expect(projectile.is_spent(), "Gossip deve consumarsi dopo i salti disponibili.")


	# Riattiva lo slow: la shockwave deve applicare knockback senza eliminare il
	# modificatore locale e non deve riattivarsi durante gli i-frame.
	effects._process(9.0)
	_expect(effects.is_slow_pulse_active(), "Il secondo pulse deve rispettare l'intervallo globale.")
	near_enemy.global_position = player.global_position + Vector2(100.0, 0.0)
	far_enemy.global_position = player.global_position + Vector2(300.0, 0.0)
	if joining_enemy != null:
		joining_enemy.global_position = player.global_position + Vector2(0.0, 180.0)
	health.clear_invulnerability()
	_expect(player.take_contact_damage(10.0), "Un danno effettivo deve attivare la shockwave.")
	_expect(_shockwave_affected_counts.size() == 1, "Una hit deve emettere una sola shockwave.")
	_expect(_shockwave_affected_counts[0] == 2, "La shockwave deve respingere solo i due nemici nel raggio.")
	_expect(near_enemy.get_knockback_remaining() > 0.0, "Il nemico vicino deve ricevere knockback.")
	_expect(is_zero_approx(far_enemy.get_knockback_remaining()), "Il nemico lontano non deve ricevere knockback.")
	_expect(near_enemy.has_speed_modifier(SLOW_MODIFIER), "Knockback e slow devono convivere senza conflitto.")
	_expect(effects.get_active_shockwave_count() == 1, "La shockwave deve creare un VFX scene-local.")
	_expect(not player.take_contact_damage(10.0), "Gli i-frame devono rifiutare il danno immediato.")
	_expect(_shockwave_affected_counts.size() == 1, "Un danno rifiutato non deve riattivare la shockwave.")

	# Il restart elimina status, VFX, vignetta e profilo dei proiettili, oltre ai
	# rank. La seconda run riparte dai valori base.
	_expect(controller.request_defeat(), "La fixture deve terminare la prima run.")
	_expect(movement_slice.restart_run(13014), "B13 deve supportare una seconda run pulita.")
	await _wait_processed_frame()
	_expect(service.get_ranks().is_empty(), "Il restart deve azzerare i rank signature.")
	_expect(not vignette.visible and is_zero_approx(vignette.intensity), "Il restart deve rimuovere la vignetta.")
	_expect_float_near(player.move_speed, base_move_speed, "Il restart deve ripristinare la velocita.")
	_expect_float_near(health.health_max, base_health_max, "Il restart deve ripristinare la vita massima.")
	_expect_float_near(health.health_current, base_health_max, "Il restart deve curare il Player.")
	_expect_float_near(weapon.get_effective_shots_per_second(), base_fire_rate, "Il restart deve ripristinare la frequenza.")
	_expect(not weapon.is_projectile_chain_enabled(), "Il restart deve rimuovere Gossip.")
	_expect(weapon.get_projectile_chain_jumps() == 0, "Il restart deve rimuovere i salti Gossip.")
	_expect(is_zero_approx(weapon.get_projectile_aim_spread_degrees()), "Il restart deve rimuovere la dispersione.")
	_expect(not effects.is_slow_pulse_active(), "Il restart deve fermare lo slow.")
	_expect(is_zero_approx(effects.get_slow_interval_remaining()), "Il restart deve azzerare lo scheduler slow.")
	_expect(effects.get_active_shockwave_count() == 0, "Il restart deve eliminare i VFX shockwave.")
	_expect(targeting.get_registered_count() == 0, "Il restart deve svuotare i bersagli della run precedente.")
	_expect(projectiles.get_child_count() == 0, "Il restart deve eliminare i proiettili precedenti.")

	controller.prepare_restart()
	paused = false
	movement_slice.queue_free()
	await process_frame


func _select_all_signatures(
	experience: ExperienceSystem,
	service: UpgradeService,
	signature_ids: Array[StringName]
) -> bool:
	var remaining := signature_ids.duplicate()
	var guard := 0
	while not remaining.is_empty() and guard < 20:
		if not experience.add_experience(experience.experience_required):
			return false
		var selected_id := StringName()
		for offered_id in service.get_current_offer_ids():
			if offered_id in remaining:
				selected_id = offered_id
				break
		if String(selected_id).is_empty():
			for offered_id in service.get_current_offer_ids():
				if offered_id in [WIDE_MAGNET.id, MEAT_FORK_DAMAGE.id]:
					selected_id = offered_id
					break
		if String(selected_id).is_empty() or not service.select_upgrade(selected_id):
			return false
		remaining.erase(selected_id)
		guard += 1
	return remaining.is_empty()


func _spawn_enemy(spawner: EnemySpawner, position: Vector2) -> BaseEnemy:
	var enemy := spawner.try_spawn_enemy()
	if enemy == null:
		return null
	enemy.global_position = position
	enemy.set_physics_process(false)
	return enemy


func _validate_rejected_definitions(effects: UpgradeEffectRegistry) -> void:
	var bad_anxiety := (ANXIETY as UpgradeDefinition).duplicate(true) as UpgradeDefinition
	bad_anxiety.id = &"bad_anxiety"
	bad_anxiety.effect_parameters = {
		"move_speed_multiplier": 1.35,
		"health_max_multiplier": 0.8,
	}
	_expect(not effects.can_apply(bad_anxiety), "Una vignetta senza intensita deve essere rifiutata.")

	var bad_gossip := (GOSSIP as UpgradeDefinition).duplicate(true) as UpgradeDefinition
	bad_gossip.id = &"bad_gossip"
	bad_gossip.effect_parameters = {
		"chain_jumps": 2.0,
		"chain_radius": 260.0,
		"damage_falloff": 0.65,
	}
	_expect(not effects.can_apply(bad_gossip), "Il conteggio dei salti Gossip deve essere intero.")

	var bad_beer := (BEER as UpgradeDefinition).duplicate(true) as UpgradeDefinition
	bad_beer.id = &"bad_beer"
	bad_beer.effect_parameters = {
		"fire_rate_multiplier": 1.25,
		"aim_spread_degrees": 0.0,
	}
	_expect(not effects.can_apply(bad_beer), "Una dispersione nulla deve essere rifiutata.")

	var repeatable_signature := (DAMAGE_SHOCKWAVE as UpgradeDefinition).duplicate(true) as UpgradeDefinition
	repeatable_signature.id = &"repeatable_signature"
	repeatable_signature.repeatable = true
	_expect(not effects.can_apply(repeatable_signature), "Le signature non devono essere ripetibili.")


func _on_effect_applied(
	definition: UpgradeDefinition,
	_new_rank: int,
	_effective_multipliers: Dictionary
) -> void:
	if definition.id in [ANXIETY.id, GOSSIP.id, CHRONIC_DELAY.id, BEER.id, DAMAGE_SHOCKWAVE.id]:
		_applied_ids.append(definition.id)


func _on_damage_shockwave_emitted(affected_count: int) -> void:
	_shockwave_affected_counts.append(affected_count)


func _expect_float_near(actual: float, expected: float, message: String) -> void:
	_expect(
		absf(actual - expected) <= FLOAT_TOLERANCE,
		"%s Atteso %.5f, ottenuto %.5f." % [message, expected, actual]
	)


func _wait_processed_frame() -> void:
	await process_frame
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	paused = false
	await process_frame
	if _failures.is_empty():
		print("B13_SIGNATURE_UPGRADES_SMOKE_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	printerr("B13_SIGNATURE_UPGRADES_SMOKE_FAIL count=%d" % _failures.size())
	quit(1)
