extends GutGameplayTest

## PS-200 — Secondo set di armi, cast completo. La matrice dei cinque assi di
## PS-196 vale ora su tutte e otto le armi dei personaggi, non solo dentro un
## set; il tetto aritmetico di kill-rate resta entro il margine del 10% gia'
## dichiarato in PS-198; ogni arma nuova regge le cinque Specialita' legate al
## proiettile e spara sia in automatico sia in manuale.

const PIERCING_ROUNDS := preload("res://data/upgrades/specialities/piercing_rounds.tres")
const DOUBLE_BARREL := preload("res://data/upgrades/specialities/double_barrel.tres")
const DEATH_BURST := preload("res://data/upgrades/specialities/death_burst.tres")
const GOSSIP := preload("res://data/upgrades/specialities/gossip_projectiles.tres")
const BEER := preload("res://data/upgrades/specialities/beer_signature.tres")

const SHARED_WEAPON_ID := &"scintilla"
const NEW_FRIENDS: Array[StringName] = [&"zat", &"aleo", &"lollo", &"marghe"]
const NEW_WEAPONS: Array[StringName] = [&"paletta", &"soffietto", &"attizzatoio", &"marinata"]

## Stessa build di riferimento di PS-198, cosi' i due tetti sono confrontabili.
const BUILD_FIRE_RATE_MULTIPLIER := 1.25
const BUILD_DAMAGE_MULTIPLIER := 1.5
const BUILD_MULTISHOT_COUNT := 3
const BUILD_PIERCE_BONUS := 3
const BUILD_ENEMY_HEALTH := 100.0
const KILL_RATE_MARGIN := 0.10

var _fired_projectiles: Array[Projectile] = []


func test_cast_weapons() -> void:
	var movement_slice := await instantiate_movement_slice()
	var controller: RunController = movement_slice.get_run_controller()
	var registry: WeaponEffectRegistry = movement_slice.get_weapon_effect_registry()
	var friend_registry: FriendRegistry = movement_slice.get_friend_registry()
	var weapon: WeaponController = movement_slice.get_weapon_controller()
	var spawner: EnemySpawner = movement_slice.get_enemy_spawner()
	var player: Player = movement_slice.get_player()

	# 1. Il cast e' chiuso: nessun personaggio resta sull'arma condivisa.
	var friend_definitions := friend_registry.get_definitions()
	assert_eq(friend_definitions.size(), 8, "PS-200: il roster deve restare di otto personaggi.")
	var cast_weapons: Array[WeaponDefinition] = []
	var seen_ids: Dictionary = {}
	for friend in friend_definitions:
		assert_ne(
			friend.weapon_id, SHARED_WEAPON_ID,
			"PS-200: %s non deve piu' usare l'arma condivisa." % friend.id
		)
		var definition := registry.resolve_definition(friend.weapon_id)
		assert_true(
			definition != null and definition.is_valid(),
			"PS-200: %s deve risolvere un'arma valida (%s)." % [friend.id, friend.weapon_id]
		)
		if definition == null:
			continue
		assert_false(
			seen_ids.has(definition.id),
			"PS-200: %s non puo' condividere l'arma con un altro personaggio." % friend.id
		)
		seen_ids[definition.id] = true
		cast_weapons.append(definition)
	assert_eq(cast_weapons.size(), 8, "PS-200: il cast deve avere otto armi distinte.")
	if cast_weapons.size() != 8:
		return
	for weapon_id in NEW_WEAPONS:
		assert_true(
			seen_ids.has(weapon_id), "PS-200: l'arma %s deve essere assegnata." % weapon_id
		)

	# 2. Matrice dei cinque assi su tutte le coppie del cast. L'arma condivisa
	#    resta fuori: e' la baseline da cui le altre si scostano, non un'ottava
	#    identita' che deve distinguersi dalle altre sette.
	for first_index in cast_weapons.size():
		for second_index in range(first_index + 1, cast_weapons.size()):
			var first := cast_weapons[first_index]
			var second := cast_weapons[second_index]
			var differences := _count_axis_differences(registry, first, second)
			assert_true(
				differences >= 3,
				(
					"PS-200: %s e %s devono differire su almeno tre assi (trovati %d)."
					% [first.id, second.id, differences]
				)
			)

	# 3. Tetto aritmetico: tutte e otto entro il margine, con l'arma condivisa
	#    come ancora dichiarata della calibrazione.
	var pierce_falloff := float(PIERCING_ROUNDS.effect_parameters["damage_falloff"])
	var shared_weapon := registry.resolve_definition(SHARED_WEAPON_ID)
	assert_true(shared_weapon != null, "PS-200: l'arma condivisa deve restare nel registry.")
	var kill_rates: Array[float] = []
	for definition in cast_weapons:
		kill_rates.append(_build_kill_rate(registry, definition, pierce_falloff))
	kill_rates.sort()
	var weakest := kill_rates[0]
	var strongest := kill_rates[kill_rates.size() - 1]
	assert_true(
		weakest > 0.0 and (strongest - weakest) / weakest <= KILL_RATE_MARGIN,
		(
			"PS-200: lo scarto fra la piu' forte (%.3f) e la piu' debole (%.3f) deve restare entro il %d%%."
			% [strongest, weakest, int(KILL_RATE_MARGIN * 100.0)]
		)
	)
	if shared_weapon != null:
		var shared_rate := _build_kill_rate(registry, shared_weapon, pierce_falloff)
		assert_true(
			shared_rate > 0.0
			and absf(weakest - shared_rate) / shared_rate <= KILL_RATE_MARGIN
			and absf(strongest - shared_rate) / shared_rate <= KILL_RATE_MARGIN,
			(
				"PS-200: il cast deve restare calibrato sull'arma condivisa (%.3f), non alla deriva."
				% shared_rate
			)
		)

	# 4. Per ogni personaggio nuovo: traiettoria dichiarata, sparo automatico e
	#    manuale, e le cinque Specialita' osservabili sui proiettili veri.
	weapon.projectile_fired.connect(_on_projectile_fired)
	for index in NEW_FRIENDS.size():
		var friend_id := NEW_FRIENDS[index]
		controller.prepare_restart()
		await wait_process_frames(2)
		assert_true(
			movement_slice.select_friend_for_next_run(friend_id),
			"PS-200: %s deve essere equipaggiabile." % friend_id
		)
		assert_eq(
			weapon.get_weapon_definition().id,
			friend_registry.resolve_weapon_id(
				friend_registry.resolve_definition(friend_id),
				movement_slice.get_ability_controller().get_pending_cosplay_ability_id()
			),
			"PS-200: %s deve impugnare la sua arma (o quella del costume, PS-208)." % friend_id
		)
		assert_true(
			movement_slice.start_selected_run(20001 + index),
			"PS-200: la run di %s deve partire." % friend_id
		)
		await wait_process_frames(2)
		controller.set_process(false)
		spawner.set_process(false)
		weapon.set_process(false)
		# PS-208: Lollo impugna l'arma del costume e l'Attizzatoio resta il
		# ripiego dei dati; come Scintilla, lo si monta a mano per provarlo.
		weapon.set_weapon_definition(registry.resolve_definition(NEW_WEAPONS[index]))
		var definition := weapon.get_weapon_definition()

		# 4a. Automatico: serve un bersaglio da cui ricavare la mira.
		spawner.reset_for_run(5150)
		spawner._process(spawner.spawn_profile.initial_spawn_delay)
		assert_eq(
			spawner.get_alive_count(), 1,
			"PS-200: la fixture di %s deve avere un bersaglio." % friend_id
		)
		if spawner.get_alive_count() == 1:
			var enemy := spawner.get_spawned_enemies()[0]
			enemy.set_physics_process(false)
			enemy.global_position = player.global_position + Vector2(200.0, 0.0)
			var auto_volley := _fire_weapon(weapon)
			assert_eq(
				auto_volley.size(), 1,
				"PS-200: in automatico %s deve emettere un colpo frontale." % definition.id
			)
			_expire(auto_volley)

		# 4b. Manuale (PS-085) e traiettoria dichiarata dall'arma.
		weapon.set_manual_fire_enabled(true)
		weapon.set_manual_aim_state(Vector2.RIGHT, true)
		var manual_volley := _fire_weapon(weapon)
		assert_eq(
			manual_volley.size(), 1,
			"PS-200: in manuale %s deve emettere un colpo frontale." % definition.id
		)
		_assert_trajectory(definition, manual_volley, player)
		_expire(manual_volley)

		_assert_speciality_effects(weapon, definition, pierce_falloff)
		weapon.set_manual_fire_enabled(false)

	weapon.projectile_fired.disconnect(_on_projectile_fired)
	controller.prepare_restart()
	print("PS200_CAST_WEAPONS_SMOKE_OK")


func _build_kill_rate(
	registry: WeaponEffectRegistry,
	definition: WeaponDefinition,
	pierce_falloff: float
) -> float:
	var emissions := registry.build_emissions(definition, Vector2.RIGHT, 0).size()
	return WeaponController.calculate_full_build_kill_rate_per_second(
		definition.shots_per_second,
		definition.damage,
		BUILD_FIRE_RATE_MULTIPLIER,
		BUILD_DAMAGE_MULTIPLIER,
		BUILD_MULTISHOT_COUNT * emissions,
		definition.base_pierce_count + BUILD_PIERCE_BONUS,
		pierce_falloff,
		BUILD_ENEMY_HEALTH
	)


## Cinque assi di PS-196: traiettoria, geometria d'emissione, ritmo, corpo del
## proiettile e comportamento a fine vita.
func _count_axis_differences(
	registry: WeaponEffectRegistry,
	first: WeaponDefinition,
	second: WeaponDefinition
) -> int:
	var first_emissions := registry.build_emissions(first, Vector2.RIGHT, 0)
	var second_emissions := registry.build_emissions(second, Vector2.RIGHT, 0)
	var differences := 0
	if first_emissions[0]["trajectory"] != second_emissions[0]["trajectory"]:
		differences += 1
	if (
		first_emissions.size() != second_emissions.size()
		or (
			(first_emissions[0]["offset"] as Vector2).is_zero_approx()
			!= (second_emissions[0]["offset"] as Vector2).is_zero_approx()
		)
	):
		differences += 1
	if not is_equal_approx(first.shots_per_second, second.shots_per_second):
		differences += 1
	if (
		not is_equal_approx(first.projectile_radius, second.projectile_radius)
		and not is_equal_approx(first.projectile_speed, second.projectile_speed)
	):
		differences += 1
	if (
		first.base_pierce_count != second.base_pierce_count
		or not is_equal_approx(first.base_pierce_damage_falloff, second.base_pierce_damage_falloff)
	):
		differences += 1
	return differences


func _assert_trajectory(
	definition: WeaponDefinition,
	volley: Array[Projectile],
	player: Player
) -> void:
	if volley.is_empty():
		return
	var projectile := volley[0]
	var declared := StringName(
		definition.effect_parameters.get("trajectory", Projectile.TRAJECTORY_STRAIGHT)
	)
	assert_eq(
		projectile.get_trajectory(), declared,
		"PS-200: %s deve portare al proiettile la traiettoria dichiarata nei dati." % definition.id
	)
	var start_position := projectile.global_position
	match declared:
		Projectile.TRAJECTORY_RETURN:
			var outbound := definition.get_effect_float(&"outbound_seconds", 0.0, 0.0)
			projectile._physics_process(outbound * 0.5)
			var outbound_position := projectile.global_position
			assert_true(
				outbound_position.x > start_position.x and not projectile.has_returned(),
				"PS-200: la Paletta deve prima allontanarsi."
			)
			projectile._physics_process(outbound * 0.5 + 0.01)
			assert_true(projectile.has_returned(), "PS-200: la Paletta deve invertire la corsa.")
			projectile._physics_process(outbound * 0.5)
			assert_true(
				projectile.global_position.x < outbound_position.x,
				"PS-200: dopo l'inversione la Paletta deve tornare verso chi l'ha lanciata."
			)
		Projectile.TRAJECTORY_FADING, Projectile.TRAJECTORY_BUILDING:
			var step := definition.projectile_lifetime * 0.25
			projectile._physics_process(step)
			var first_leg := projectile.global_position.distance_to(start_position)
			var midpoint := projectile.global_position
			projectile._physics_process(step)
			var second_leg := projectile.global_position.distance_to(midpoint)
			if declared == Projectile.TRAJECTORY_FADING:
				assert_true(
					second_leg < first_leg,
					"PS-200: il Soffietto deve perdere spinta invece di mantenerla."
				)
			else:
				assert_true(
					second_leg > first_leg,
					"PS-200: l'Attizzatoio deve guadagnare velocita' invece di mantenerla."
				)
		Projectile.TRAJECTORY_LINGERING:
			var travel := definition.get_effect_float(&"travel_seconds", 0.0, 0.0)
			projectile._physics_process(travel + 0.01)
			var landing := projectile.global_position
			assert_true(
				landing.distance_to(start_position) > 1.0,
				"PS-200: la Marinata deve percorrere la sua corsa prima di fermarsi."
			)
			projectile._physics_process(0.3)
			assert_almost_eq(
				projectile.global_position.distance_to(landing), 0.0, FLOAT_TOLERANCE,
				"PS-200: dopo la corsa la Marinata deve restare ferma dov'e' arrivata."
			)
			assert_false(
				projectile.is_spent(),
				"PS-200: la Marinata deve sopravvivere alla fine della corsa, non spegnersi."
			)
		_:
			assert_true(false, "PS-200: %s deve dichiarare una traiettoria propria." % definition.id)


## Le cinque Specialita' legate al proiettile passano dagli stessi due setter
## per tutte le armi: qui si verifica che arrivino ai proiettili emessi.
func _assert_speciality_effects(
	weapon: WeaponController,
	definition: WeaponDefinition,
	pierce_falloff: float
) -> void:
	var shape_pierce := 1 + int(PIERCING_ROUNDS.effect_parameters["pierce_count_per_rank"])
	var shape_multishot := 1 + int(DOUBLE_BARREL.effect_parameters["projectiles_per_rank"])
	var shape_spread := float(DOUBLE_BARREL.effect_parameters["spread_degrees_per_projectile"])
	var burst_radius := float(DEATH_BURST.effect_parameters["radius"])
	var burst_multiplier := float(DEATH_BURST.effect_parameters["damage_multiplier_per_rank"])
	assert_true(
		weapon.set_projectile_shape_modifiers(
			shape_pierce, pierce_falloff, shape_multishot, shape_spread,
			true, burst_radius, burst_multiplier
		),
		"PS-200: i modificatori di forma devono restare applicabili su %s." % definition.id
	)
	var expected_pierce := definition.base_pierce_count + shape_pierce - 1
	assert_eq(
		weapon.get_effective_pierce_count(), expected_pierce,
		(
			"PS-200: Arrosticini deve aggiungere perforazione anche a %s, che ne ha gia' %d."
			% [definition.id, definition.base_pierce_count]
		)
	)
	var shape_volley := _fire_weapon(weapon)
	assert_eq(
		shape_volley.size(), shape_multishot,
		"PS-200: Tagliata deve moltiplicare le emissioni di %s." % definition.id
	)
	for projectile in shape_volley:
		assert_true(
			projectile.is_pierce_enabled() and projectile.get_pierce_remaining() == expected_pierce,
			"PS-200: la perforazione deve arrivare ai proiettili di %s." % definition.id
		)
		assert_true(
			projectile.is_death_burst_enabled()
			and is_equal_approx(projectile.get_death_burst_radius(), burst_radius),
			"PS-200: Fiorentina deve arrivare ai proiettili di %s." % definition.id
		)
	_expire(shape_volley)
	weapon.reset_projectile_shape_modifiers()

	var chain_jumps := int(GOSSIP.effect_parameters["chain_jumps_per_rank"])
	var chain_radius := float(GOSSIP.effect_parameters["chain_radius"])
	var chain_falloff := float(GOSSIP.effect_parameters["damage_falloff"])
	var aim_spread := float(BEER.effect_parameters["aim_spread_degrees"])
	assert_true(
		weapon.set_projectile_upgrade_modifiers(
			true, chain_jumps, chain_falloff, chain_radius, aim_spread
		),
		"PS-200: i modificatori signature devono restare applicabili su %s." % definition.id
	)
	var signature_volley := _fire_weapon(weapon)
	assert_eq(
		signature_volley.size(), 1,
		"PS-200: la signature non deve cambiare il numero di emissioni di %s." % definition.id
	)
	var deviation := 0.0
	for projectile in signature_volley:
		assert_true(
			projectile.is_chain_enabled() and projectile.get_chain_jumps_remaining() == chain_jumps,
			"PS-200: Salsiccia deve arrivare ai proiettili di %s." % definition.id
		)
		assert_almost_eq(
			projectile.get_aim_spread_degrees(), aim_spread, FLOAT_TOLERANCE,
			"PS-200: la dispersione di Alette deve arrivare a %s, mai essere ignorata." % definition.id
		)
		deviation += absf(wrapf(projectile.direction.angle(), -PI, PI))
	assert_true(
		deviation > 0.0,
		(
			"PS-200: la dispersione deve spostare davvero il colpo di %s rispetto alla mira."
			% definition.id
		)
	)
	_expire(signature_volley)
	weapon.reset_projectile_upgrade_modifiers()


func _expire(volley: Array[Projectile]) -> void:
	for projectile in volley:
		if is_instance_valid(projectile) and not projectile.is_spent():
			projectile.expire()


func _fire_weapon(weapon: WeaponController) -> Array[Projectile]:
	# _process e' disabilitato in tutta la fixture: forzarlo con un delta ampio
	# azzera il cooldown residuo e fa scattare try_fire() come farebbe il
	# normale ciclo di frame, catturando ogni proiettile dal segnale.
	_fired_projectiles.clear()
	weapon._process(999.0)
	return _fired_projectiles.duplicate()


func _on_projectile_fired(projectile: Projectile, _target: BaseEnemy) -> void:
	_fired_projectiles.append(projectile)
