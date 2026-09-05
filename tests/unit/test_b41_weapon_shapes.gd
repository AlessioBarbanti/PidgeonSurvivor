extends GutGameplayTest

const PIERCING_ROUNDS := preload("res://data/upgrades/specialities/piercing_rounds.tres")
const DOUBLE_BARREL := preload("res://data/upgrades/specialities/double_barrel.tres")
const DEATH_BURST := preload("res://data/upgrades/specialities/death_burst.tres")
const MEAT_FORK_DAMAGE := preload("res://data/upgrades/meat_fork_damage.tres")
const RAPID_FIRE := preload("res://data/upgrades/rapid_fire.tres")
const GOSSIP := preload("res://data/upgrades/specialities/gossip_projectiles.tres")
const WIDE_MAGNET := preload("res://data/upgrades/wide_magnet.tres")
const SWIFT_STEPS := preload("res://data/upgrades/swift_steps.tres")

const SPAWN_ATTEMPT_LIMIT := 20
const ICON_MANIFEST_PATH := "res://assets/art/icons/upgrades/ASSET-MANIFEST.md"
const PIERCING_ICON_PATH := "res://assets/art/icons/upgrades/generated/arrosticini.png"
const DOUBLE_ICON_PATH := "res://assets/art/icons/upgrades/generated/tagliata.png"
const DEATH_BURST_ICON_PATH := "res://assets/art/icons/upgrades/generated/fiorentina.png"
const PIERCING_ICON_SHA256 := "4d42b3845ec05006b8caabf921f03eb72a2b17cb510ac1ad5c8cba64296a4801"
const DOUBLE_ICON_SHA256 := "ccd2c3fc0384ef17835183a4229227ecec6595bad4a352105f846d3236f08a53"
const DEATH_BURST_ICON_SHA256 := "0485a376b82e5999bad0a3172e612417a72863baaba3e96aadc3eb5887536eb0"

var _fired_projectiles: Array[Projectile] = []


func test_upgrade_icons() -> void:
	_assert_upgrade_icon(PIERCING_ROUNDS, PIERCING_ICON_PATH, PIERCING_ICON_SHA256, "Arrosticini")
	_assert_upgrade_icon(DOUBLE_BARREL, DOUBLE_ICON_PATH, DOUBLE_ICON_SHA256, "Tagliata")
	_assert_upgrade_icon(DEATH_BURST, DEATH_BURST_ICON_PATH, DEATH_BURST_ICON_SHA256, "Fiorentina")
	assert_true(FileAccess.file_exists(ICON_MANIFEST_PATH), "Le icone B41 richiedono un manifest.")
	var manifest := FileAccess.get_file_as_string(ICON_MANIFEST_PATH)
	var manifest_lower := manifest.to_lower()
	assert_true(manifest.contains("OpenAI ImageGen built-in"), "Il manifest B41 deve registrare il generatore.")
	assert_true(
		manifest.contains("upgrade_piercing_rounds_spiedino.png"), "Il manifest deve registrare il master Spiedino."
	)
	assert_true(
		manifest.contains("upgrade_double_barrel_costine.png"), "Il manifest deve registrare il master Costine."
	)
	assert_true(manifest.contains("upgrade_death_burst_coppa.png"), "Il manifest deve registrare il master Coppa.")
	assert_true(
		manifest_lower.contains(PIERCING_ICON_SHA256), "Il manifest deve registrare l'hash di Arrosticini."
	)
	assert_true(manifest_lower.contains(DOUBLE_ICON_SHA256), "Il manifest deve registrare l'hash di Tagliata.")
	assert_true(
		manifest_lower.contains(DEATH_BURST_ICON_SHA256), "Il manifest deve registrare l'hash di Fiorentina."
	)


func _assert_upgrade_icon(
	definition: UpgradeDefinition, path: String, expected_sha256: String, label: String
) -> void:
	assert_true(definition.icon != null, "%s deve avere un'icona dedicata." % label)
	if definition.icon != null:
		assert_true(definition.icon.get_size() == Vector2(128.0, 128.0), "%s deve usare un'icona 128x128." % label)
	assert_true(FileAccess.file_exists(path), "File icona mancante per %s." % label)
	assert_eq(FileAccess.get_sha256(path), expected_sha256, "Hash icona inatteso per %s." % label)


func test_multishot_fan_offsets() -> void:
	var single := WeaponController.calculate_multishot_fan_offsets(1, 40.0)
	assert_true(
		single.size() == 1 and is_zero_approx(single[0]),
		"Un solo proiettile non deve deviare, indipendentemente dal ventaglio dichiarato."
	)

	var fan_a := WeaponController.calculate_multishot_fan_offsets(3, 30.0)
	var fan_b := WeaponController.calculate_multishot_fan_offsets(3, 30.0)
	assert_true(fan_a.size() == 3, "Il ventaglio deve avere un angolo per proiettile.")
	assert_true(
		fan_a == fan_b, "Lo stesso conteggio e la stessa dispersione dichiarata devono produrre lo stesso ventaglio: nessun RNG."
	)
	assert_almost_eq(
		fan_a[0], deg_to_rad(-15.0), FLOAT_TOLERANCE, "Il primo proiettile deve stare al bordo sinistro del ventaglio."
	)
	assert_almost_eq(fan_a[1], 0.0, FLOAT_TOLERANCE, "Il proiettile centrale non deve deviare.")
	assert_almost_eq(
		fan_a[2], deg_to_rad(15.0), FLOAT_TOLERANCE, "L'ultimo proiettile deve stare al bordo destro del ventaglio."
	)

	# Regressione: il ventaglio deve tenere un proiettile sulla linea di mira,
	# altrimenti un bersaglio fermo passa nel buco centrale (caso Raffica Doppia
	# rank 1, che con due proiettili tirava solo a -6 e +6 gradi).
	for fan_count in range(1, 7):
		var centered := WeaponController.calculate_multishot_fan_offsets(
			fan_count, 12.0 * float(maxi(fan_count - 1, 1))
		)
		assert_true(centered.size() == fan_count, "Il ventaglio deve avere un angolo per proiettile a ogni conteggio.")
		assert_true(centered.has(0.0), "Ogni ventaglio deve tenere un proiettile sulla linea di mira.")

	var even_fan := WeaponController.calculate_multishot_fan_offsets(2, 12.0)
	var even_fan_mirrored := WeaponController.calculate_multishot_fan_offsets(2, 12.0, true)
	assert_almost_eq(even_fan[0], 0.0, FLOAT_TOLERANCE, "Con due proiettili il primo deve restare sulla mira.")
	assert_almost_eq(
		even_fan[1], deg_to_rad(12.0), FLOAT_TOLERANCE, "Il secondo proiettile deve deviare di un passo pieno."
	)
	assert_almost_eq(
		even_fan_mirrored[0], deg_to_rad(-12.0), FLOAT_TOLERANCE,
		"Il ventaglio speculare deve spostare il colpo spaiato sull'altro fianco."
	)
	assert_almost_eq(even_fan_mirrored[1], 0.0, FLOAT_TOLERANCE, "Anche da speculare il ventaglio resta sulla mira.")


func test_scene_behavior() -> void:
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
	var projectiles := movement_slice.get_projectile_parent() as Node2D

	assert_true(
		controller != null and experience != null and service != null and catalog != null and effects != null
		and player != null and weapon != null and spawner != null and targeting != null and projectiles != null,
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
	assert_true(catalog.rebuild_registry(), "Il catalogo B41 isolato deve essere valido.")
	service.reset_for_run(controller.get_seed())
	assert_true(effects.recalculate_effects(), "Il registry deve accettare le carte di riferimento B41.")

	var enemy_health := _reference_enemy_health(spawner)
	assert_true(enemy_health > 0.0, "La fixture deve leggere la vita nemica di riferimento.")

	# Tetto aritmetico: build completa (danno e cadenza al rank 5 dichiarato
	# dall'appendice B41, perforazione e ventaglio al cap runtime) deve
	# superare 1,15x lo spawn/s al cap (9,6 kill/s con i valori attuali), a
	# zero overkill e zero tempo di volo, come da metodo dell'appendice.
	var max_damage_multiplier := pow(float(MEAT_FORK_DAMAGE.effect_parameters["multiplier"]), 5)
	var max_fire_rate_multiplier := pow(float(RAPID_FIRE.effect_parameters["multiplier"]), 5)
	var pierce_falloff := float(PIERCING_ROUNDS.effect_parameters["damage_falloff"])
	var kill_rate := WeaponController.calculate_full_build_kill_rate_per_second(
		weapon.get_base_shots_per_second(), weapon.get_base_damage(), max_fire_rate_multiplier, max_damage_multiplier,
		effects.max_weapon_multishot_count, effects.max_weapon_pierce_count, pierce_falloff, enemy_health
	)
	assert_true(kill_rate >= 9.6, "La build completa B41 deve superare 9,6 kill/s, ottenuto %.2f." % kill_rate)

	# Fase perforazione: catalogo ridotto a tre carte (= offer_size), cosi'
	# ogni offerta contiene sempre Colpo Perforante e nessuna pesca contamina
	# il rank delle altre due carte forma non ancora testate.
	catalog.definitions = [PIERCING_ROUNDS, WIDE_MAGNET, SWIFT_STEPS]
	assert_true(catalog.rebuild_registry(), "Il catalogo perforazione deve essere valido.")
	service.reset_for_run(controller.get_seed())
	assert_true(effects.recalculate_effects(), "Il registry deve accettare la fase perforazione.")

	# PS-012: Colpo Perforante è una Specialità di Barb, bloccata a inizio run.
	service.queue_barb_reward()
	assert_true(
		service.select_barb_speciality(PIERCING_ROUNDS.id),
		"Colpo Perforante deve essere sbloccabile come Specialità di Barb prima della pesca B41."
	)
	assert_eq(weapon.get_effective_pierce_count(), 2, "Un rank deve dare due bersagli perforabili.")
	assert_almost_eq(
		weapon.get_effective_pierce_damage_falloff(), 0.7, FLOAT_TOLERANCE, "Il falloff deve restare quello dichiarato."
	)

	var pierce_near := _spawn_enemy(spawner, player.global_position + Vector2(100.0, 0.0))
	var pierce_far := _spawn_enemy(spawner, player.global_position + Vector2(160.0, 0.0))
	assert_true(pierce_near != null and pierce_far != null, "La fixture perforazione deve creare due bersagli.")
	if pierce_near != null and pierce_far != null:
		var pierce_volley := _fire_weapon(weapon)
		var pierce_projectile := pierce_volley[0] if not pierce_volley.is_empty() else null
		assert_true(pierce_projectile != null, "L'arma con perforazione deve sparare.")
		if pierce_projectile != null:
			pierce_projectile.set_physics_process(false)
			assert_true(pierce_projectile.is_pierce_enabled(), "Il proiettile deve avere la perforazione attiva.")
			var near_health_before := pierce_near.get_health_component().health_current
			var far_health_before := pierce_far.get_health_component().health_current
			assert_true(pierce_projectile.try_hit(pierce_near), "Il primo bersaglio deve ricevere danno pieno.")
			assert_almost_eq(
				pierce_near.get_health_component().health_current, near_health_before - pierce_projectile.damage,
				FLOAT_TOLERANCE, "Il primo bersaglio perforato deve ricevere il danno pieno."
			)
			assert_true(
				not pierce_projectile.try_hit(pierce_near),
				"Lo stesso bersaglio non puo' essere colpito due volte dallo stesso proiettile."
			)
			assert_almost_eq(
				pierce_near.get_health_component().health_current, near_health_before - pierce_projectile.damage,
				FLOAT_TOLERANCE, "Un secondo tentativo sullo stesso bersaglio non deve applicare altro danno."
			)
			assert_true(pierce_projectile.try_hit(pierce_far), "Il secondo bersaglio perforato deve ricevere danno.")
			assert_almost_eq(
				pierce_far.get_health_component().health_current, far_health_before - pierce_projectile.damage * 0.7,
				FLOAT_TOLERANCE, "Il secondo bersaglio perforato deve ricevere danno ridotto dal falloff."
			)
			assert_true(pierce_projectile.is_spent(), "Il proiettile deve consumarsi dopo aver esaurito la perforazione.")

	# La perforazione ripetuta deve rispettare il cap runtime della registry.
	for _extra_rank in range(3):
		_select_when_offered(experience, service, PIERCING_ROUNDS.id)
	assert_eq(
		weapon.get_effective_pierce_count(), effects.max_weapon_pierce_count,
		"Il conteggio di perforazione deve fermarsi al cap runtime."
	)

	# Fase colpi multipli: nuovo catalogo isolato, di nuovo a tre carte;
	# reset_for_run azzera anche i modificatori arma tramite ranks_reset.
	catalog.definitions = [DOUBLE_BARREL, WIDE_MAGNET, SWIFT_STEPS]
	assert_true(catalog.rebuild_registry(), "Il catalogo ventaglio deve essere valido.")
	service.reset_for_run(controller.get_seed())
	assert_true(effects.recalculate_effects(), "Il registry deve accettare la fase ventaglio.")
	assert_eq(weapon.get_effective_pierce_count(), 1, "Il cambio fase deve azzerare la perforazione della fase precedente.")

	# PS-012: Raffica Doppia è una Specialità di Barb, bloccata a inizio run.
	service.queue_barb_reward()
	assert_true(
		service.select_barb_speciality(DOUBLE_BARREL.id),
		"Raffica Doppia deve essere sbloccabile come Specialità di Barb prima della pesca B41."
	)
	assert_eq(weapon.get_effective_multishot_count(), 2, "Un rank deve dare due proiettili per colpo.")
	var multishot_far_enemy := _spawn_enemy(spawner, player.global_position + Vector2(400.0, 0.0))
	assert_true(multishot_far_enemy != null, "La fixture ventaglio deve avere un bersaglio lontano da mirare.")
	var volley := _fire_weapon(weapon)
	assert_true(not volley.is_empty(), "Il ventaglio deve sparare almeno un proiettile.")
	assert_true(
		volley.size() == 2, "Un rank di Raffica Doppia deve sparare due proiettili per colpo, ottenuti %d." % volley.size()
	)
	for spawned_projectile in volley:
		spawned_projectile.set_physics_process(false)
	weapon.clear_projectiles()

	# Fase esplosione alla morte: stesso isolamento, colpisce i vicini una
	# sola volta, non il bersaglio lontano e non il bersaglio appena ucciso.
	catalog.definitions = [DEATH_BURST, WIDE_MAGNET, SWIFT_STEPS]
	assert_true(catalog.rebuild_registry(), "Il catalogo esplosione deve essere valido.")
	service.reset_for_run(controller.get_seed())
	assert_true(effects.recalculate_effects(), "Il registry deve accettare la fase esplosione.")
	assert_true(weapon.get_effective_multishot_count() == 1, "Il cambio fase deve azzerare il ventaglio della fase precedente.")

	# PS-012: Esplosione Finale è una Specialità di Barb, bloccata a inizio run.
	service.queue_barb_reward()
	assert_true(
		service.select_barb_speciality(DEATH_BURST.id),
		"Esplosione Finale deve essere sbloccabile come Specialità di Barb prima della pesca B41."
	)
	assert_true(weapon.is_death_burst_enabled(), "Un rank deve attivare l'esplosione alla morte.")
	assert_almost_eq(weapon.get_death_burst_radius(), 85.0, FLOAT_TOLERANCE, "Il raggio deve restare quello dichiarato.")
	assert_almost_eq(
		weapon.get_death_burst_damage_multiplier(), 0.2, FLOAT_TOLERANCE, "Un rank deve dare +20% danno arma in area."
	)

	var victim := _spawn_enemy(spawner, player.global_position + Vector2(500.0, 0.0))
	var bystander := _spawn_enemy(spawner, player.global_position + Vector2(540.0, 0.0))
	var distant := _spawn_enemy(spawner, player.global_position + Vector2(700.0, 0.0))
	assert_true(victim != null and bystander != null and distant != null, "La fixture esplosione deve creare tre nemici.")
	if victim != null and bystander != null and distant != null:
		victim.get_health_component().take_damage(victim.get_health_component().health_current - 1.0)
		var bystander_health_before := bystander.get_health_component().health_current
		var distant_health_before := distant.get_health_component().health_current
		var burst_volley := _fire_weapon(weapon)
		var burst_projectile := burst_volley[0] if not burst_volley.is_empty() else null
		assert_true(burst_projectile != null, "L'arma con esplosione deve sparare.")
		if burst_projectile != null:
			burst_projectile.set_physics_process(false)
			var expected_burst_damage := burst_projectile.damage * 0.2
			assert_true(burst_projectile.try_hit(victim), "Il colpo di grazia deve applicarsi al bersaglio.")
			assert_true(not victim.is_alive(), "Il bersaglio deve morire per far scattare l'esplosione.")
			assert_almost_eq(
				bystander.get_health_component().health_current, bystander_health_before - expected_burst_damage,
				FLOAT_TOLERANCE, "Il vicino nel raggio deve ricevere l'esplosione una sola volta."
			)
			assert_almost_eq(
				distant.get_health_component().health_current, distant_health_before, FLOAT_TOLERANCE,
				"Il bersaglio fuori raggio non deve ricevere l'esplosione."
			)

	# Il restart azzera tutte le forme d'attacco, come i modificatori B13.
	assert_true(controller.request_defeat(), "La fixture deve terminare la run B41.")
	assert_true(movement_slice.restart_run(41041), "B41 deve supportare una seconda run pulita.")
	await wait_process_frames(2)
	assert_true(service.get_ranks().is_empty(), "Il restart deve azzerare i rank delle forme B41.")
	assert_eq(weapon.get_effective_pierce_count(), 1, "Il restart deve rimuovere la perforazione.")
	assert_eq(weapon.get_effective_multishot_count(), 1, "Il restart deve rimuovere il ventaglio.")
	assert_true(not weapon.is_death_burst_enabled(), "Il restart deve rimuovere l'esplosione alla morte.")
	assert_eq(targeting.get_registered_count(), 0, "Il restart deve svuotare i bersagli della run precedente.")
	assert_eq(projectiles.get_child_count(), 0, "Il restart deve eliminare i proiettili precedenti.")

	controller.prepare_restart()


func _reference_enemy_health(spawner: EnemySpawner) -> float:
	var probe := spawner.try_spawn_enemy()
	if probe == null:
		return 0.0
	var health_component := probe.get_health_component()
	var health_max := health_component.health_max if health_component != null else 0.0
	probe.queue_free()
	return health_max


func _select_when_offered(
	experience: ExperienceSystem, service: UpgradeService, upgrade_id: StringName
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
