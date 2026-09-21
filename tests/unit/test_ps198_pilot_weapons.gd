extends GutGameplayTest

## PS-198 — Primo set di armi pilota. Verifica che le quattro armi siano
## davvero diverse fra loro (almeno tre assi su cinque di PS-196), che ognuna
## regga tutte e cinque le Specialita' legate al proiettile, e che il tetto
## aritmetico di kill-rate resti dentro il margine dichiarato nella card.
##
## Le Specialita' vengono applicate dai setter di WeaponController, non dalla
## pesca di UpgradeService: quel percorso e' gia' coperto da
## test_b41_weapon_shapes.gd, mentre qui serve provare che il canale unico
## dichiarato da PS-196 arrivi davvero ai proiettili di ogni arma.

const PIERCING_ROUNDS := preload("res://data/upgrades/specialities/piercing_rounds.tres")
const DOUBLE_BARREL := preload("res://data/upgrades/specialities/double_barrel.tres")
const DEATH_BURST := preload("res://data/upgrades/specialities/death_burst.tres")
const GOSSIP := preload("res://data/upgrades/specialities/gossip_projectiles.tres")
const BEER := preload("res://data/upgrades/specialities/beer_signature.tres")

const SHARED_WEAPON_ID := &"scintilla"
const PILOT_FRIENDS: Array[StringName] = [&"magno", &"bea", &"alea", &"migi"]
const PILOT_WEAPONS: Array[StringName] = [&"carbonella", &"spiedo", &"cavatappi", &"graticola"]

## Build di riferimento per il tetto aritmetico, dichiarata in PS-198:
## Alette (cadenza x1,25), danno x1,5, Tagliata a rango 2 (tre proiettili),
## Arrosticini a rango 3 (+3 perforazioni, decadimento 0,7).
const BUILD_FIRE_RATE_MULTIPLIER := 1.25
const BUILD_DAMAGE_MULTIPLIER := 1.5
const BUILD_MULTISHOT_COUNT := 3
const BUILD_PIERCE_BONUS := 3
const BUILD_ENEMY_HEALTH := 100.0
## Scarto massimo ammesso fra l'arma pilota piu' forte e la piu' debole.
const KILL_RATE_MARGIN := 0.10

var _fired_projectiles: Array[Projectile] = []


func test_pilot_weapons() -> void:
	var movement_slice := await instantiate_movement_slice()
	var controller: RunController = movement_slice.get_run_controller()
	var registry: WeaponEffectRegistry = movement_slice.get_weapon_effect_registry()
	var friend_registry: FriendRegistry = movement_slice.get_friend_registry()
	var weapon: WeaponController = movement_slice.get_weapon_controller()
	var spawner: EnemySpawner = movement_slice.get_enemy_spawner()
	var player: Player = movement_slice.get_player()

	# 1. Solo i quattro del pilota cambiano arma; gli altri restano su Scintilla.
	var expected_by_friend: Dictionary = {}
	for index in PILOT_FRIENDS.size():
		expected_by_friend[PILOT_FRIENDS[index]] = PILOT_WEAPONS[index]
	for friend in friend_registry.get_definitions():
		var expected: StringName = expected_by_friend.get(friend.id, SHARED_WEAPON_ID)
		assert_eq(
			friend.weapon_id, expected,
			"PS-198: %s deve dichiarare l'arma %s." % [friend.id, expected]
		)

	var pilots: Array[WeaponDefinition] = []
	for weapon_id in PILOT_WEAPONS:
		var definition := registry.resolve_definition(weapon_id)
		assert_true(
			definition != null and definition.is_valid(),
			"PS-198: l'arma pilota %s deve essere registrata e valida." % weapon_id
		)
		if definition != null:
			assert_false(
				definition.display_name.strip_edges().is_empty(),
				"PS-198: ogni arma pilota deve avere un nome visibile."
			)
			pilots.append(definition)
	assert_eq(pilots.size(), 4, "PS-198: il set pilota deve contare quattro armi.")
	if pilots.size() != 4:
		return

	# 2. Almeno tre assi di differenza su cinque, fra due armi qualsiasi.
	for first_index in pilots.size():
		for second_index in range(first_index + 1, pilots.size()):
			var first := pilots[first_index]
			var second := pilots[second_index]
			var differences := _count_axis_differences(registry, first, second)
			assert_true(
				differences >= 3,
				(
					"PS-198: %s e %s devono differire su almeno tre assi (trovati %d)."
					% [first.id, second.id, differences]
				)
			)

	# 3. Tetto aritmetico comparabile fra le quattro armi.
	var pierce_falloff := float(PIERCING_ROUNDS.effect_parameters["damage_falloff"])
	var kill_rates: Array[float] = []
	for definition in pilots:
		var emissions := registry.build_emissions(definition, Vector2.RIGHT, 0).size()
		var kill_rate := WeaponController.calculate_full_build_kill_rate_per_second(
			definition.shots_per_second,
			definition.damage,
			BUILD_FIRE_RATE_MULTIPLIER,
			BUILD_DAMAGE_MULTIPLIER,
			BUILD_MULTISHOT_COUNT * emissions,
			definition.base_pierce_count + BUILD_PIERCE_BONUS,
			pierce_falloff,
			BUILD_ENEMY_HEALTH
		)
		assert_true(kill_rate > 0.0, "PS-198: %s deve avere un tetto positivo." % definition.id)
		kill_rates.append(kill_rate)
	kill_rates.sort()
	var weakest := kill_rates[0]
	var strongest := kill_rates[kill_rates.size() - 1]
	assert_true(
		weakest > 0.0 and (strongest - weakest) / weakest <= KILL_RATE_MARGIN,
		(
			"PS-198: lo scarto fra la piu' forte (%.3f) e la piu' debole (%.3f) deve restare entro il %d%%."
			% [strongest, weakest, int(KILL_RATE_MARGIN * 100.0)]
		)
	)

	# 4. Per ogni personaggio del pilota: emissione attesa, sparo automatico e
	#    manuale, e le cinque Specialita' osservabili sui proiettili veri.
	weapon.projectile_fired.connect(_on_projectile_fired)
	for index in PILOT_FRIENDS.size():
		var friend_id := PILOT_FRIENDS[index]
		controller.prepare_restart()
		await wait_process_frames(2)
		assert_true(
			movement_slice.select_friend_for_next_run(friend_id),
			"PS-198: %s deve essere equipaggiabile." % friend_id
		)
		var definition := weapon.get_weapon_definition()
		assert_eq(
			definition.id, PILOT_WEAPONS[index],
			"PS-198: %s deve impugnare la sua arma pilota." % friend_id
		)
		assert_true(
			movement_slice.start_selected_run(19801 + index),
			"PS-198: la run di %s deve partire." % friend_id
		)
		await wait_process_frames(2)
		controller.set_process(false)
		spawner.set_process(false)
		weapon.set_process(false)

		var emission_count := registry.build_emissions(definition, Vector2.RIGHT, 0).size()

		# 4a. Automatico: serve un bersaglio da cui ricavare la mira.
		spawner.reset_for_run(5150)
		spawner._process(spawner.spawn_profile.initial_spawn_delay)
		assert_eq(
			spawner.get_alive_count(), 1,
			"PS-198: la fixture di %s deve avere un bersaglio." % friend_id
		)
		if spawner.get_alive_count() == 1:
			var enemy := spawner.get_spawned_enemies()[0]
			enemy.set_physics_process(false)
			enemy.global_position = player.global_position + Vector2(200.0, 0.0)
			var auto_volley := _fire_weapon(weapon)
			assert_eq(
				auto_volley.size(), emission_count,
				"PS-198: in automatico %s deve emettere %d proiettili." % [definition.id, emission_count]
			)
			_expire(auto_volley)

		# 4b. Manuale (PS-085) e geometria dichiarata dall'arma.
		weapon.set_manual_fire_enabled(true)
		weapon.set_manual_aim_state(Vector2.RIGHT, true)
		var manual_volley := _fire_weapon(weapon)
		assert_eq(
			manual_volley.size(), emission_count,
			"PS-198: in manuale %s deve emettere %d proiettili." % [definition.id, emission_count]
		)
		_assert_trajectory(definition, manual_volley, player)
		_expire(manual_volley)

		# 4c. Arrosticini, Tagliata e Fiorentina: stesso setter di forma per
		#     tutte le armi, effetto misurato sui proiettili emessi.
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
			"PS-198: i modificatori di forma devono restare applicabili su %s." % definition.id
		)
		var expected_pierce := definition.base_pierce_count + shape_pierce - 1
		assert_eq(
			weapon.get_effective_pierce_count(), expected_pierce,
			(
				"PS-198: Arrosticini deve aggiungere perforazione anche a %s, che ne ha gia' %d."
				% [definition.id, definition.base_pierce_count]
			)
		)
		var shape_volley := _fire_weapon(weapon)
		assert_eq(
			shape_volley.size(), emission_count * shape_multishot,
			"PS-198: Tagliata deve moltiplicare le emissioni di %s." % definition.id
		)
		for projectile in shape_volley:
			assert_true(
				projectile.is_pierce_enabled() and projectile.get_pierce_remaining() == expected_pierce,
				"PS-198: la perforazione deve arrivare ai proiettili di %s." % definition.id
			)
			assert_true(
				projectile.is_death_burst_enabled()
				and is_equal_approx(projectile.get_death_burst_radius(), burst_radius),
				"PS-198: Fiorentina deve arrivare ai proiettili di %s." % definition.id
			)
		_expire(shape_volley)
		weapon.reset_projectile_shape_modifiers()

		# 4d. Salsiccia e Alette: stesso setter signature per tutte le armi.
		var chain_jumps := int(GOSSIP.effect_parameters["chain_jumps_per_rank"])
		var chain_radius := float(GOSSIP.effect_parameters["chain_radius"])
		var chain_falloff := float(GOSSIP.effect_parameters["damage_falloff"])
		var aim_spread := float(BEER.effect_parameters["aim_spread_degrees"])
		var reference_angles := _emission_angles(registry, definition)
		assert_true(
			weapon.set_projectile_upgrade_modifiers(
				true, chain_jumps, chain_falloff, chain_radius, aim_spread
			),
			"PS-198: i modificatori signature devono restare applicabili su %s." % definition.id
		)
		var signature_volley := _fire_weapon(weapon)
		assert_eq(
			signature_volley.size(), emission_count,
			"PS-198: la signature non deve cambiare il numero di emissioni di %s." % definition.id
		)
		var deviation := 0.0
		for projectile_index in signature_volley.size():
			var projectile := signature_volley[projectile_index]
			assert_true(
				projectile.is_chain_enabled()
				and projectile.get_chain_jumps_remaining() == chain_jumps,
				"PS-198: Salsiccia deve arrivare ai proiettili di %s." % definition.id
			)
			assert_almost_eq(
				projectile.get_aim_spread_degrees(), aim_spread, FLOAT_TOLERANCE,
				(
					"PS-198: la dispersione di Alette deve arrivare a %s, mai essere ignorata."
					% definition.id
				)
			)
			if projectile_index < reference_angles.size():
				deviation += absf(
					_normalize_angle(projectile.direction.angle() - reference_angles[projectile_index])
				)
		# Il valore non basta: su un'arma senza direzione di mira la
		# dispersione deve spostare davvero gli angoli di emissione, altrimenti
		# ruoterebbe rigidamente un anello simmetrico e sarebbe invisibile.
		assert_true(
			deviation > 0.0,
			(
				"PS-198: la dispersione deve irregolarizzare l'emissione di %s, non lasciarla identica."
				% definition.id
			)
		)
		_expire(signature_volley)
		weapon.reset_projectile_upgrade_modifiers()
		weapon.set_manual_fire_enabled(false)

	weapon.projectile_fired.disconnect(_on_projectile_fired)
	controller.prepare_restart()
	print("PS198_PILOT_WEAPONS_SMOKE_OK")


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


func _emission_angles(
	registry: WeaponEffectRegistry,
	definition: WeaponDefinition
) -> Array[float]:
	var angles: Array[float] = []
	for emission in registry.build_emissions(definition, Vector2.RIGHT, 0):
		angles.append((emission["direction"] as Vector2).angle())
	return angles


func _assert_trajectory(
	definition: WeaponDefinition,
	volley: Array[Projectile],
	player: Player
) -> void:
	if volley.is_empty():
		return
	match definition.effect_id:
		WeaponEffectRegistry.ORBITING_FRAGMENTS:
			var orbit_radius := definition.get_effect_float(&"orbit_radius", 104.0, 1.0)
			for projectile in volley:
				assert_eq(
					projectile.get_trajectory(), Projectile.TRAJECTORY_ORBIT,
					"PS-198: la Graticola deve emettere frammenti orbitali."
				)
				assert_almost_eq(
					projectile.global_position.distance_to(player.global_position),
					orbit_radius, 0.5,
					"PS-198: il frammento deve nascere sull'anello, non addosso al personaggio."
				)
		WeaponEffectRegistry.SPLITTING_SHOT:
			assert_eq(volley.size(), 2, "PS-198: il Cavatappi emette due colpi sovrapposti.")
			if volley.size() != 2:
				return
			assert_almost_eq(
				volley[0].global_position.distance_to(volley[1].global_position), 0.0,
				FLOAT_TOLERANCE,
				"PS-198: prima dello sdoppiamento i due colpi devono coincidere."
			)
			for projectile in volley:
				assert_eq(
					projectile.get_trajectory(), Projectile.TRAJECTORY_SPLIT,
					"PS-198: il Cavatappi deve dichiarare la traiettoria divergente."
				)
				assert_false(
					projectile.has_split(),
					"PS-198: lo sdoppiamento non deve avvenire gia' alla volata."
				)
			var delay := definition.get_effect_float(&"split_delay_seconds", 0.8, 0.0)
			volley[0]._physics_process(delay + 0.01)
			volley[1]._physics_process(delay + 0.01)
			assert_true(
				volley[0].has_split() and volley[1].has_split(),
				"PS-198: superato il ritardo dichiarato, entrambi i colpi devono aprirsi."
			)
			assert_true(
				absf(volley[0].direction.angle_to(volley[1].direction)) > 0.1,
				"PS-198: dopo lo sdoppiamento i due colpi devono divergere davvero."
			)
		WeaponEffectRegistry.ALTERNATING_SKEWERS:
			var lateral := definition.get_effect_float(&"lateral_offset", 18.0, 0.0)
			assert_almost_eq(
				volley[0].global_position.distance_to(
					player.global_position + Vector2.RIGHT * definition.muzzle_offset
				),
				lateral, 0.5,
				"PS-198: lo Spiedo deve partire spostato di fianco alla linea di mira."
			)
		_:
			assert_eq(
				volley[0].get_trajectory(), Projectile.TRAJECTORY_STRAIGHT,
				"PS-198: %s deve viaggiare dritto." % definition.id
			)


func _normalize_angle(angle: float) -> float:
	return wrapf(angle, -PI, PI)


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
