extends SceneTree

const MOVEMENT_SLICE_SCENE := preload("res://scenes/game/movement_slice.tscn")
const PIERCING_ROUNDS := preload("res://data/upgrades/piercing_rounds.tres")
const DOUBLE_BARREL := preload("res://data/upgrades/double_barrel.tres")
const DEATH_BURST := preload("res://data/upgrades/death_burst.tres")
const MEAT_FORK_DAMAGE := preload("res://data/upgrades/meat_fork_damage.tres")
const RAPID_FIRE := preload("res://data/upgrades/rapid_fire.tres")
const GOSSIP := preload("res://data/upgrades/gossip_projectiles.tres")
const WIDE_MAGNET := preload("res://data/upgrades/wide_magnet.tres")
const SWIFT_STEPS := preload("res://data/upgrades/swift_steps.tres")

const INITIAL_VIEWPORT_SIZE := Vector2i(1280, 720)
const FLOAT_TOLERANCE := 0.001
const SPAWN_ATTEMPT_LIMIT := 20
const ICON_MANIFEST_PATH := "res://assets/art/icons/upgrades/ASSET-MANIFEST.md"
const PIERCING_ICON_PATH := "res://assets/art/icons/upgrades/generated/piercing_rounds.png"
const DOUBLE_ICON_PATH := "res://assets/art/icons/upgrades/generated/double_barrel.png"
const DEATH_BURST_ICON_PATH := "res://assets/art/icons/upgrades/generated/death_burst.png"
const PIERCING_ICON_SHA256 := "c619a100c1e7d31b81aa98474c192211aed394fd8d48c8d2354d245cb851858b"
const DOUBLE_ICON_SHA256 := "a7f5fb212ced181a29050970d397de23795cb2b4405a47d1d154f731e83318ce"
const DEATH_BURST_ICON_SHA256 := "8e47934030daa0a5be124b151b54e10bbc8f58d3a0f7efba79543da388ae450d"

var _failures: Array[String] = []
var _fired_projectiles: Array[Projectile] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	paused = false
	root.content_scale_size = INITIAL_VIEWPORT_SIZE
	root.size = INITIAL_VIEWPORT_SIZE
	await _wait_processed_frame()
	_validate_upgrade_icons()
	_validate_multishot_fan_offsets()
	await _validate_scene_behavior()
	await _finish()


func _validate_upgrade_icons() -> void:
	_validate_upgrade_icon(
		PIERCING_ROUNDS,
		PIERCING_ICON_PATH,
		PIERCING_ICON_SHA256,
		"Colpo Perforante"
	)
	_validate_upgrade_icon(
		DOUBLE_BARREL,
		DOUBLE_ICON_PATH,
		DOUBLE_ICON_SHA256,
		"Raffica Doppia"
	)
	_validate_upgrade_icon(
		DEATH_BURST,
		DEATH_BURST_ICON_PATH,
		DEATH_BURST_ICON_SHA256,
		"Esplosione Finale"
	)
	_expect(FileAccess.file_exists(ICON_MANIFEST_PATH), "Le icone B41 richiedono un manifest.")
	var manifest := FileAccess.get_file_as_string(ICON_MANIFEST_PATH)
	var manifest_lower := manifest.to_lower()
	_expect(manifest.contains("OpenAI ImageGen built-in"), "Il manifest B41 deve registrare il generatore.")
	_expect(manifest.contains("upgrade_piercing_rounds_spiedino.png"), "Il manifest deve registrare il master Spiedino.")
	_expect(manifest.contains("upgrade_double_barrel_costine.png"), "Il manifest deve registrare il master Costine.")
	_expect(manifest.contains("upgrade_death_burst_coppa.png"), "Il manifest deve registrare il master Coppa.")
	_expect(manifest_lower.contains(PIERCING_ICON_SHA256), "Il manifest deve registrare l'hash di Colpo Perforante.")
	_expect(manifest_lower.contains(DOUBLE_ICON_SHA256), "Il manifest deve registrare l'hash di Raffica Doppia.")
	_expect(manifest_lower.contains(DEATH_BURST_ICON_SHA256), "Il manifest deve registrare l'hash di Esplosione Finale.")


func _validate_upgrade_icon(
	definition: UpgradeDefinition,
	path: String,
	expected_sha256: String,
	label: String
) -> void:
	_expect(definition.icon != null, "%s deve avere un'icona dedicata." % label)
	if definition.icon != null:
		_expect(definition.icon.get_size() == Vector2(128.0, 128.0), "%s deve usare un'icona 128x128." % label)
	_expect(FileAccess.file_exists(path), "File icona mancante per %s." % label)
	_expect(FileAccess.get_sha256(path) == expected_sha256, "Hash icona inatteso per %s." % label)


func _validate_multishot_fan_offsets() -> void:
	var single := WeaponController.calculate_multishot_fan_offsets(1, 40.0)
	_expect(
		single.size() == 1 and is_zero_approx(single[0]),
		"Un solo proiettile non deve deviare, indipendentemente dal ventaglio dichiarato."
	)

	var fan_a := WeaponController.calculate_multishot_fan_offsets(3, 30.0)
	var fan_b := WeaponController.calculate_multishot_fan_offsets(3, 30.0)
	_expect(fan_a.size() == 3, "Il ventaglio deve avere un angolo per proiettile.")
	_expect(fan_a == fan_b, "Lo stesso conteggio e la stessa dispersione dichiarata devono produrre lo stesso ventaglio: nessun RNG.")
	_expect_float_near(fan_a[0], deg_to_rad(-15.0), "Il primo proiettile deve stare al bordo sinistro del ventaglio.")
	_expect_float_near(fan_a[1], 0.0, "Il proiettile centrale non deve deviare.")
	_expect_float_near(fan_a[2], deg_to_rad(15.0), "L'ultimo proiettile deve stare al bordo destro del ventaglio.")


func _validate_scene_behavior() -> void:
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
	var projectiles := movement_slice.get_projectile_parent() as Node2D

	_expect(
		controller != null
		and experience != null
		and service != null
		and catalog != null
		and effects != null
		and player != null
		and weapon != null
		and spawner != null
		and targeting != null
		and projectiles != null,
		"B41 richiede run, upgrade, arma e nemici composti."
	)
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
		or projectiles == null
	):
		return

	controller.set_process(false)
	spawner.set_process(false)
	player.set_physics_process(false)
	weapon.set_process(false)
	weapon.projectile_fired.connect(_on_projectile_fired)
	var ability := player.get_ability_controller()
	if ability != null:
		ability.set_process(false)

	# Isola inizialmente le sole carte statistiche di riferimento: la
	# validazione della scena completa e' gia' eseguita da _ready().
	catalog.definitions = [MEAT_FORK_DAMAGE, RAPID_FIRE, GOSSIP]
	_expect(catalog.rebuild_registry(), "Il catalogo B41 isolato deve essere valido.")
	service.reset_for_run(controller.get_seed())
	_expect(effects.recalculate_effects(), "Il registry deve accettare le carte di riferimento B41.")

	var enemy_health := _reference_enemy_health(spawner)
	_expect(enemy_health > 0.0, "La fixture deve leggere la vita nemica di riferimento.")

	# Tetto aritmetico: build completa (danno e cadenza al rank 5 dichiarato
	# dall'appendice B41, perforazione e ventaglio al cap runtime) deve
	# superare 1,15x lo spawn/s al cap (9,6 kill/s con i valori attuali), a
	# zero overkill e zero tempo di volo, come da metodo dell'appendice.
	var max_damage_multiplier := pow(float(MEAT_FORK_DAMAGE.effect_parameters["multiplier"]), 5)
	var max_fire_rate_multiplier := pow(float(RAPID_FIRE.effect_parameters["multiplier"]), 5)
	var pierce_falloff := float(PIERCING_ROUNDS.effect_parameters["damage_falloff"])
	var kill_rate := WeaponController.calculate_full_build_kill_rate_per_second(
		weapon.get_base_shots_per_second(),
		weapon.get_base_damage(),
		max_fire_rate_multiplier,
		max_damage_multiplier,
		effects.max_weapon_multishot_count,
		effects.max_weapon_pierce_count,
		pierce_falloff,
		enemy_health
	)
	_expect(
		kill_rate >= 9.6,
		"La build completa B41 deve superare 9,6 kill/s, ottenuto %.2f." % kill_rate
	)

	# Fase perforazione: catalogo ridotto a tre carte (= offer_size), cosi'
	# ogni offerta contiene sempre Colpo Perforante e nessuna pesca contamina
	# il rank delle altre due carte forma non ancora testate.
	catalog.definitions = [PIERCING_ROUNDS, WIDE_MAGNET, SWIFT_STEPS]
	_expect(catalog.rebuild_registry(), "Il catalogo perforazione deve essere valido.")
	service.reset_for_run(controller.get_seed())
	_expect(effects.recalculate_effects(), "Il registry deve accettare la fase perforazione.")

	_expect(
		_select_when_offered(experience, service, PIERCING_ROUNDS.id),
		"Colpo Perforante deve entrare nella pesca B41."
	)
	_expect(weapon.get_effective_pierce_count() == 2, "Un rank deve dare due bersagli perforabili.")
	_expect_float_near(weapon.get_effective_pierce_damage_falloff(), 0.7, "Il falloff deve restare quello dichiarato.")

	var pierce_near := _spawn_enemy(spawner, player.global_position + Vector2(100.0, 0.0))
	var pierce_far := _spawn_enemy(spawner, player.global_position + Vector2(160.0, 0.0))
	_expect(pierce_near != null and pierce_far != null, "La fixture perforazione deve creare due bersagli.")
	if pierce_near != null and pierce_far != null:
		var pierce_volley := _fire_weapon(weapon)
		var pierce_projectile := pierce_volley[0] if not pierce_volley.is_empty() else null
		_expect(pierce_projectile != null, "L'arma con perforazione deve sparare.")
		if pierce_projectile != null:
			pierce_projectile.set_physics_process(false)
			_expect(pierce_projectile.is_pierce_enabled(), "Il proiettile deve avere la perforazione attiva.")
			var near_health_before := pierce_near.get_health_component().health_current
			var far_health_before := pierce_far.get_health_component().health_current
			_expect(pierce_projectile.try_hit(pierce_near), "Il primo bersaglio deve ricevere danno pieno.")
			_expect_float_near(
				pierce_near.get_health_component().health_current,
				near_health_before - pierce_projectile.damage,
				"Il primo bersaglio perforato deve ricevere il danno pieno."
			)
			_expect(
				not pierce_projectile.try_hit(pierce_near),
				"Lo stesso bersaglio non puo' essere colpito due volte dallo stesso proiettile."
			)
			_expect_float_near(
				pierce_near.get_health_component().health_current,
				near_health_before - pierce_projectile.damage,
				"Un secondo tentativo sullo stesso bersaglio non deve applicare altro danno."
			)
			_expect(pierce_projectile.try_hit(pierce_far), "Il secondo bersaglio perforato deve ricevere danno.")
			_expect_float_near(
				pierce_far.get_health_component().health_current,
				far_health_before - pierce_projectile.damage * 0.7,
				"Il secondo bersaglio perforato deve ricevere danno ridotto dal falloff."
			)
			_expect(pierce_projectile.is_spent(), "Il proiettile deve consumarsi dopo aver esaurito la perforazione.")

	# La perforazione ripetuta deve rispettare il cap runtime della registry.
	for _extra_rank in range(3):
		_select_when_offered(experience, service, PIERCING_ROUNDS.id)
	_expect(
		weapon.get_effective_pierce_count() == effects.max_weapon_pierce_count,
		"Il conteggio di perforazione deve fermarsi al cap runtime."
	)

	# Fase colpi multipli: nuovo catalogo isolato, di nuovo a tre carte;
	# reset_for_run azzera anche i modificatori arma tramite ranks_reset.
	catalog.definitions = [DOUBLE_BARREL, WIDE_MAGNET, SWIFT_STEPS]
	_expect(catalog.rebuild_registry(), "Il catalogo ventaglio deve essere valido.")
	service.reset_for_run(controller.get_seed())
	_expect(effects.recalculate_effects(), "Il registry deve accettare la fase ventaglio.")
	_expect(weapon.get_effective_pierce_count() == 1, "Il cambio fase deve azzerare la perforazione della fase precedente.")

	_expect(
		_select_when_offered(experience, service, DOUBLE_BARREL.id),
		"Raffica Doppia deve entrare nella pesca B41."
	)
	_expect(weapon.get_effective_multishot_count() == 2, "Un rank deve dare due proiettili per colpo.")
	var multishot_far_enemy := _spawn_enemy(spawner, player.global_position + Vector2(400.0, 0.0))
	_expect(multishot_far_enemy != null, "La fixture ventaglio deve avere un bersaglio lontano da mirare.")
	var volley := _fire_weapon(weapon)
	_expect(not volley.is_empty(), "Il ventaglio deve sparare almeno un proiettile.")
	_expect(
		volley.size() == 2,
		"Un rank di Raffica Doppia deve sparare due proiettili per colpo, ottenuti %d." % volley.size()
	)
	for spawned_projectile in volley:
		spawned_projectile.set_physics_process(false)
	weapon.clear_projectiles()

	# Fase esplosione alla morte: stesso isolamento, colpisce i vicini una
	# sola volta, non il bersaglio lontano e non il bersaglio appena ucciso.
	catalog.definitions = [DEATH_BURST, WIDE_MAGNET, SWIFT_STEPS]
	_expect(catalog.rebuild_registry(), "Il catalogo esplosione deve essere valido.")
	service.reset_for_run(controller.get_seed())
	_expect(effects.recalculate_effects(), "Il registry deve accettare la fase esplosione.")
	_expect(weapon.get_effective_multishot_count() == 1, "Il cambio fase deve azzerare il ventaglio della fase precedente.")

	_expect(
		_select_when_offered(experience, service, DEATH_BURST.id),
		"Esplosione Finale deve entrare nella pesca B41."
	)
	_expect(weapon.is_death_burst_enabled(), "Un rank deve attivare l'esplosione alla morte.")
	_expect_float_near(weapon.get_death_burst_radius(), 85.0, "Il raggio deve restare quello dichiarato.")
	_expect_float_near(weapon.get_death_burst_damage_multiplier(), 0.2, "Un rank deve dare +20% danno arma in area.")

	var victim := _spawn_enemy(spawner, player.global_position + Vector2(500.0, 0.0))
	var bystander := _spawn_enemy(spawner, player.global_position + Vector2(540.0, 0.0))
	var distant := _spawn_enemy(spawner, player.global_position + Vector2(700.0, 0.0))
	_expect(
		victim != null and bystander != null and distant != null,
		"La fixture esplosione deve creare tre nemici."
	)
	if victim != null and bystander != null and distant != null:
		victim.get_health_component().take_damage(victim.get_health_component().health_current - 1.0)
		var bystander_health_before := bystander.get_health_component().health_current
		var distant_health_before := distant.get_health_component().health_current
		var burst_volley := _fire_weapon(weapon)
		var burst_projectile := burst_volley[0] if not burst_volley.is_empty() else null
		_expect(burst_projectile != null, "L'arma con esplosione deve sparare.")
		if burst_projectile != null:
			burst_projectile.set_physics_process(false)
			var expected_burst_damage := burst_projectile.damage * 0.2
			_expect(burst_projectile.try_hit(victim), "Il colpo di grazia deve applicarsi al bersaglio.")
			_expect(not victim.is_alive(), "Il bersaglio deve morire per far scattare l'esplosione.")
			_expect_float_near(
				bystander.get_health_component().health_current,
				bystander_health_before - expected_burst_damage,
				"Il vicino nel raggio deve ricevere l'esplosione una sola volta."
			)
			_expect_float_near(
				distant.get_health_component().health_current,
				distant_health_before,
				"Il bersaglio fuori raggio non deve ricevere l'esplosione."
			)

	# Il restart azzera tutte le forme d'attacco, come i modificatori B13.
	_expect(controller.request_defeat(), "La fixture deve terminare la run B41.")
	_expect(movement_slice.restart_run(41041), "B41 deve supportare una seconda run pulita.")
	await _wait_processed_frame()
	_expect(service.get_ranks().is_empty(), "Il restart deve azzerare i rank delle forme B41.")
	_expect(weapon.get_effective_pierce_count() == 1, "Il restart deve rimuovere la perforazione.")
	_expect(weapon.get_effective_multishot_count() == 1, "Il restart deve rimuovere il ventaglio.")
	_expect(not weapon.is_death_burst_enabled(), "Il restart deve rimuovere l'esplosione alla morte.")
	_expect(targeting.get_registered_count() == 0, "Il restart deve svuotare i bersagli della run precedente.")
	_expect(projectiles.get_child_count() == 0, "Il restart deve eliminare i proiettili precedenti.")

	controller.prepare_restart()
	paused = false
	movement_slice.queue_free()
	await process_frame


func _reference_enemy_health(spawner: EnemySpawner) -> float:
	var probe := spawner.try_spawn_enemy()
	if probe == null:
		return 0.0
	var health_component := probe.get_health_component()
	var health_max := health_component.health_max if health_component != null else 0.0
	probe.queue_free()
	return health_max


func _select_when_offered(
	experience: ExperienceSystem,
	service: UpgradeService,
	upgrade_id: StringName
) -> bool:
	for _attempt in SPAWN_ATTEMPT_LIMIT:
		if not experience.add_experience(experience.experience_required):
			return false
		var offered_ids := service.get_current_offer_ids()
		if offered_ids.is_empty():
			return false
		var selected_id := upgrade_id if upgrade_id in offered_ids else offered_ids[0]
		if not service.select_upgrade(selected_id):
			return false
		if selected_id == upgrade_id:
			return true
	return false


func _fire_weapon(weapon: WeaponController) -> Array[Projectile]:
	# _process e' disabilitato in tutta la fixture: forzarlo con un delta ampio
	# azzera il cooldown residuo e fa scattare try_fire() come farebbe il
	# normale ciclo di frame, catturando ogni proiettile del ventaglio tramite
	# il segnale projectile_fired invece di leggere il solo valore di ritorno.
	_fired_projectiles.clear()
	weapon._process(999.0)
	return _fired_projectiles.duplicate()


func _on_projectile_fired(projectile: Projectile, _target: BaseEnemy) -> void:
	_fired_projectiles.append(projectile)


func _spawn_enemy(spawner: EnemySpawner, position: Vector2) -> BaseEnemy:
	var enemy := spawner.try_spawn_enemy()
	if enemy == null:
		return null
	enemy.global_position = position
	enemy.set_physics_process(false)
	return enemy


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
		print("B41_WEAPON_SHAPES_SMOKE_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	printerr("B41_WEAPON_SHAPES_SMOKE_FAIL count=%d" % _failures.size())
	quit(1)
