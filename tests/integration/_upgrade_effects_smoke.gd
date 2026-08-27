extends SceneTree

const MOVEMENT_SLICE_SCENE := preload("res://scenes/game/movement_slice.tscn")
const SWIFT_STEPS := preload("res://data/upgrades/swift_steps.tres")
const RAPID_FIRE := preload("res://data/upgrades/rapid_fire.tres")
const WIDE_MAGNET := preload("res://data/upgrades/wide_magnet.tres")
const MEAT_FORK_DAMAGE := preload("res://data/upgrades/meat_fork_damage.tres")
const INITIAL_VIEWPORT_SIZE := Vector2i(1280, 720)
const FLOAT_TOLERANCE := 0.001
const OFFER_RETRY_LIMIT := 40

var _failures: Array[String] = []
var _applied_effect_count := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	paused = false
	await process_frame
	await _validate_composed_upgrade_effects()
	await _finish()


func _validate_composed_upgrade_effects() -> void:
	root.content_scale_size = INITIAL_VIEWPORT_SIZE
	root.size = INITIAL_VIEWPORT_SIZE
	await _wait_processed_frame()
	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	root.add_child(movement_slice)
	await _wait_processed_frame()

	var controller := movement_slice.get_run_controller() as RunController
	var experience := movement_slice.get_experience_system() as ExperienceSystem
	var service := movement_slice.get_upgrade_service() as UpgradeService
	var catalog := movement_slice.get_upgrade_registry() as UpgradeRegistry
	var registry := movement_slice.get_upgrade_effect_registry() as UpgradeEffectRegistry
	var player := movement_slice.get_node_or_null("World/Player") as Player
	var weapon := movement_slice.get_weapon_controller() as WeaponController
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	var projectiles := movement_slice.get_projectile_parent() as Node2D

	_expect(controller != null and experience != null, "B12 deve conservare run e progressione.")
	_expect(service != null and registry != null, "B12 deve comporre service e registry effetti.")
	_expect(player != null and weapon != null, "B12 deve comporre Player e arma.")
	if (
		controller == null
		or experience == null
		or service == null
		or catalog == null
		or registry == null
		or player == null
		or weapon == null
		or spawner == null
		or projectiles == null
	):
		paused = false
		movement_slice.queue_free()
		await process_frame
		return

	controller.set_process(false)
	spawner.set_process(false)
	player.set_physics_process(false)
	weapon.set_process(false)
	var ability := player.get_ability_controller()
	if ability != null:
		ability.set_process(false)
	# B12 resta una regressione isolata: la scena completa valida prima il
	# catalogo B13, poi questa fixture limita la pesca ai sei Resource B12.
	catalog.definitions = [
		SWIFT_STEPS,
		RAPID_FIRE,
		WIDE_MAGNET,
		MEAT_FORK_DAMAGE,
	]
	_expect(catalog.rebuild_registry(), "La fixture B12 isolata deve avere un catalogo valido.")
	service.reset_for_run(controller.get_seed())
	_expect(registry.recalculate_effects(), "Il registry deve accettare il sottoinsieme B12.")
	registry.effect_applied.connect(_on_effect_applied)

	_expect(registry.has_valid_configuration(), "Il registry B12 deve accettare tutto il catalogo.")
	_validate_rejected_definitions(registry)

	var base_move_speed := player.get_base_move_speed()
	var base_pickup_radius := player.get_base_pickup_radius()
	var base_fire_rate := weapon.get_base_shots_per_second()
	var base_damage := weapon.get_base_damage()
	_expect_float_near(player.move_speed, base_move_speed, "La velocita iniziale deve essere quella base.")
	_expect_float_near(player.get_pickup_radius(), base_pickup_radius, "Il pickup iniziale deve essere quello base.")
	_expect_float_near(weapon.get_effective_shots_per_second(), base_fire_rate, "La frequenza iniziale deve essere quella base.")
	_expect_float_near(weapon.get_effective_damage(), base_damage, "Il danno iniziale deve essere quello base.")

	# Una modifica alla frequenza non riscrive il cooldown in corso. Il colpo
	# successivo usa pero' subito il nuovo intervallo.
	spawner.reset_for_run(12012)
	spawner._process(spawner.spawn_profile.initial_spawn_delay)
	_expect(spawner.get_alive_count() == 1, "La fixture B12 deve creare un bersaglio.")
	if spawner.get_alive_count() == 1:
		var target := spawner.get_spawned_enemies()[0]
		target.set_physics_process(false)
		target.global_position = player.global_position + Vector2(160.0, 0.0)
		var first_projectile := weapon.try_fire()
		_expect(first_projectile != null, "L'arma deve sparare prima dell'upgrade.")
		if first_projectile != null:
			first_projectile.set_physics_process(false)
		var cooldown_before_upgrade := weapon.get_cooldown_remaining()
		_expect(
			_grant_and_select(experience, service, &"rapid_fire"),
			"Ritmo Serrato deve essere selezionabile dalla prima offerta."
		)
		_expect_float_near(
			weapon.get_cooldown_remaining(),
			cooldown_before_upgrade,
			"Un upgrade non deve riscalare il cooldown gia iniziato."
		)
		_expect_float_near(
			weapon.get_effective_fire_interval(),
			1.0 / (base_fire_rate * 1.1),
			"Il colpo successivo deve usare la nuova frequenza."
		)
		weapon._process(cooldown_before_upgrade)
		_expect_float_near(
			weapon.get_cooldown_remaining(),
			1.0 / (base_fire_rate * 1.1),
			"Dopo il colpo, il cooldown deve usare l'intervallo B12."
		)
		_disable_projectiles(projectiles)

	# Porta i tre upgrade primari al rank massimo. Il ricalcolo parte sempre
	# dai valori base, quindi non accumula errori o mutazioni irreversibili.
	for upgrade_id in [&"swift_steps", &"rapid_fire", &"wide_magnet"]:
		var rank_guard := 0
		while service.get_rank(upgrade_id) < 5 and rank_guard < 100:
			_expect(
				_grant_and_select(experience, service, upgrade_id),
				"L'upgrade %s deve raggiungere il rank massimo." % upgrade_id
			)
			rank_guard += 1
		_expect(
			rank_guard < 100,
			"L'upgrade %s deve raggiungere il rank massimo entro il guard." % upgrade_id
		)

	var expected_move_multiplier := pow(1.1, 5)
	var expected_fire_multiplier := pow(1.1, 5)
	var expected_pickup_multiplier := pow(1.15, 5)
	_expect_float_near(
		player.move_speed,
		base_move_speed * expected_move_multiplier,
		"Passo Leggero deve comporre cinque rank moltiplicativi."
	)
	_expect_float_near(
		weapon.get_effective_shots_per_second(),
		base_fire_rate * expected_fire_multiplier,
		"Ritmo Serrato deve comporre cinque rank moltiplicativi."
	)
	_expect_float_near(
		player.get_pickup_radius(),
		base_pickup_radius * expected_pickup_multiplier,
		"Campo Ampio deve comporre cinque rank moltiplicativi."
	)

	# Forchettone da Braciere deve raggiungere anche i proiettili creati dopo
	# la scelta.
	_expect(
		_grant_and_select(experience, service, &"meat_fork_damage"),
		"Il fallback Potenza deve essere selezionabile."
	)
	_expect_float_near(
		weapon.get_effective_damage(),
		base_damage * 1.15,
		"Potenza deve aumentare il danno effettivo senza mutare il Resource."
	)
	weapon._process(weapon.get_cooldown_remaining())
	var latest_projectile := _get_latest_projectile(projectiles)
	_expect(latest_projectile != null, "L'arma deve creare un proiettile dopo Potenza.")
	if latest_projectile != null:
		latest_projectile.set_physics_process(false)
		_expect_float_near(
			latest_projectile.damage,
			base_damage * 1.15,
			"Il nuovo proiettile deve ricevere il danno effettivo B12."
		)

	_expect(
		_grant_and_select(experience, service, &"wide_magnet"),
		"Il fallback Portata deve essere selezionabile."
	)
	_expect_float_near(
		player.get_pickup_radius(),
		base_pickup_radius * expected_pickup_multiplier * 1.15,
		"Upgrade primario e fallback devono comporsi sullo stesso effetto."
	)

	var haste_rank_before_cap := service.get_rank(&"rapid_fire")
	var guard := 0
	while (
		registry.get_effective_multiplier(&"weapon_fire_rate_multiplier")
		< registry.max_fire_rate_multiplier - FLOAT_TOLERANCE
		and guard < 100
	):
		_expect(
			_grant_and_select(experience, service, &"rapid_fire"),
			"Il fallback Rapidita deve restare ripetibile fino al cap."
		)
		guard += 1
	_expect(guard < 100, "Il cap della frequenza deve essere raggiungibile.")
	_expect_float_near(
		registry.get_effective_multiplier(&"weapon_fire_rate_multiplier"),
		registry.max_fire_rate_multiplier,
		"La frequenza deve fermarsi al cap configurato."
	)
	var capped_fire_rate := weapon.get_effective_shots_per_second()
	_expect(
		_grant_and_select(experience, service, &"rapid_fire"),
		"Un fallback ripetibile deve restare consumabile al cap."
	)
	_expect(
		service.get_rank(&"rapid_fire") > haste_rank_before_cap,
		"I rank fallback devono restare tracciati oltre max_rank."
	)
	_expect_float_near(
		weapon.get_effective_shots_per_second(),
		capped_fire_rate,
		"Selezioni oltre il cap non devono aumentare la statistica."
	)

	_expect_float_near(
		weapon.weapon_profile.shots_per_second,
		base_fire_rate,
		"B12 non deve mutare la frequenza nel Resource condiviso."
	)
	_expect_float_near(
		weapon.weapon_profile.damage,
		base_damage,
		"B12 non deve mutare il danno nel Resource condiviso."
	)
	_expect(_applied_effect_count > 15, "Ogni scelta B12 deve emettere effect_applied.")

	_expect(controller.request_defeat(), "La fixture deve poter terminare la prima run.")
	_expect(movement_slice.restart_run(12013), "Il restart deve avviare una seconda run.")
	_expect(service.get_ranks().is_empty(), "Il restart deve azzerare tutti i rank.")
	for effect_id in [
		&"player_move_speed_multiplier",
		&"player_pickup_radius_multiplier",
		&"weapon_fire_rate_multiplier",
		&"weapon_damage_multiplier",
	]:
		_expect_float_near(
			registry.get_effective_multiplier(effect_id),
			1.0,
			"Il restart deve riportare %s a identita." % effect_id
		)
	_expect_float_near(player.move_speed, base_move_speed, "Il restart deve ripristinare la velocita base.")
	_expect_float_near(player.get_pickup_radius(), base_pickup_radius, "Il restart deve ripristinare il pickup base.")
	_expect_float_near(weapon.get_effective_shots_per_second(), base_fire_rate, "Il restart deve ripristinare la frequenza base.")
	_expect_float_near(weapon.get_effective_damage(), base_damage, "Il restart deve ripristinare il danno base.")

	# Se la progressione viene interrotta fra la chiusura dell'offerta e il
	# commit, il service ripristina il rank e non pubblica alcun effetto.
	var applied_count_before_failed_commit := _applied_effect_count
	var interrupt_commit := func(_level: int) -> void:
		controller.request_defeat()
	service.offer_cleared.connect(interrupt_commit, CONNECT_ONE_SHOT)
	_expect(
		experience.add_experience(experience.experience_required),
		"La terza run deve poter aprire una scelta da interrompere."
	)
	var interrupted_offer := service.get_current_offer_ids()
	_expect(interrupted_offer.size() == 3, "La scelta interrotta deve avere tre opzioni.")
	if not interrupted_offer.is_empty():
		_expect(
			not service.select_upgrade(interrupted_offer[0]),
			"Un commit interrotto deve essere rifiutato."
		)
	_expect(service.get_ranks().is_empty(), "Un commit fallito deve ripristinare il rank.")
	_expect(
		_applied_effect_count == applied_count_before_failed_commit,
		"Un commit fallito non deve emettere effect_applied."
	)
	_expect_float_near(player.move_speed, base_move_speed, "Un commit fallito non deve alterare il Player.")
	_expect_float_near(weapon.get_effective_damage(), base_damage, "Un commit fallito non deve alterare l'arma.")

	controller.prepare_restart()
	paused = false
	movement_slice.queue_free()
	await process_frame


func _grant_and_select(
	experience: ExperienceSystem,
	service: UpgradeService,
	upgrade_id: StringName
) -> bool:
	# L'offerta espone tre ID su quattro definizioni tutte ripetibili, quindi il
	# bersaglio puo' non essere pescato. In quel caso il livello viene chiuso
	# senza applicare effetti e si ripesca: lasciare aperto il LEVEL_UP
	# bloccherebbe ogni add_experience successiva, perche' richiede RUNNING.
	for _attempt in range(OFFER_RETRY_LIMIT):
		if not experience.add_experience(experience.experience_required):
			return false
		if upgrade_id in service.get_current_offer_ids():
			return service.select_upgrade(upgrade_id)
		if not experience.complete_level_up():
			return false
	return false


func _validate_rejected_definitions(registry: UpgradeEffectRegistry) -> void:
	var unknown := _make_definition(&"unknown_effect")
	unknown.effect_id = &"not_supported"
	_expect(not registry.can_apply(unknown), "Un effect_id sconosciuto deve essere rifiutato.")

	var missing_parameter := _make_definition(&"missing_parameter")
	missing_parameter.effect_parameters = {}
	_expect(not registry.can_apply(missing_parameter), "Un moltiplicatore assente deve essere rifiutato.")

	var invalid_parameter := _make_definition(&"invalid_parameter")
	invalid_parameter.effect_parameters = {"multiplier": "molto"}
	_expect(not registry.can_apply(invalid_parameter), "Un moltiplicatore non numerico deve essere rifiutato.")


func _make_definition(upgrade_id: StringName) -> UpgradeDefinition:
	var definition := UpgradeDefinition.new()
	definition.id = upgrade_id
	definition.title = String(upgrade_id)
	definition.description = "Definizione di prova B12."
	definition.effect_id = &"player_move_speed_multiplier"
	definition.effect_parameters = {"multiplier": 1.1}
	return definition


func _get_latest_projectile(parent: Node2D) -> Projectile:
	for index in range(parent.get_child_count() - 1, -1, -1):
		var child := parent.get_child(index)
		if child is Projectile:
			return child as Projectile
	return null


func _disable_projectiles(parent: Node2D) -> void:
	for child in parent.get_children():
		if child is Projectile:
			(child as Projectile).set_physics_process(false)


func _on_effect_applied(
	_definition: UpgradeDefinition,
	_new_rank: int,
	_effective_multipliers: Dictionary
) -> void:
	_applied_effect_count += 1


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
		print("B12_UPGRADE_EFFECTS_SMOKE_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	printerr("B12_UPGRADE_EFFECTS_SMOKE_FAIL count=%d" % _failures.size())
	quit(1)
