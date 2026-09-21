extends GutGameplayTest

## PS-202 — Il Coperchio di Magno e' un fendente, non un colpo che viaggia:
## nasce mezzo arco prima della mira, passa sulla linea di mira a meta' corsa,
## resta agganciato a Magno se si sposta e scade a fine arco. In automatico
## mira nella direzione di movimento e parte solo con un nemico sotto l'arco.
## E' disegnato a primitive, mentre le altre armi restano sullo sprite della
## brace.

const ANGLE_TOLERANCE := 0.02
const POSITION_TOLERANCE := 0.5

var _fired_projectiles: Array[Projectile] = []


func test_coperchio_sweep() -> void:
	var movement_slice := await instantiate_movement_slice()
	var controller: RunController = movement_slice.get_run_controller()
	var registry: WeaponEffectRegistry = movement_slice.get_weapon_effect_registry()
	var weapon: WeaponController = movement_slice.get_weapon_controller()
	var spawner: EnemySpawner = movement_slice.get_enemy_spawner()
	var player: Player = movement_slice.get_player()

	# La fixture parte con una run gia' avviata: la scelta del personaggio
	# e' ammessa solo in BOOT.
	controller.prepare_restart()
	await wait_process_frames(2)
	assert_true(movement_slice.select_friend_for_next_run(&"magno"), "PS-202: Magno deve essere equipaggiabile.")
	assert_true(movement_slice.start_selected_run(20201), "PS-202: la run di Magno deve partire.")
	await wait_process_frames(2)
	controller.set_process(false)
	spawner.set_process(false)
	weapon.set_process(false)

	var definition := weapon.get_weapon_definition()
	assert_eq(definition.id, &"coperchio", "PS-202: Magno deve impugnare il Coperchio.")
	assert_eq(
		definition.effect_id, WeaponEffectRegistry.SWEEPING_ARC,
		"PS-202: il Coperchio deve dichiarare la geometria del fendente."
	)

	weapon.projectile_fired.connect(_on_projectile_fired)

	# 0. In automatico il fendente va nella direzione di movimento di Magno,
	#    come lo scatto di Bea, e parte solo se un nemico e' davvero sotto
	#    l'arco: un colpo nel vuoto consumerebbe il cooldown proprio quando il
	#    nemico arriva.
	assert_true(definition.aims_along_movement, "PS-202: il Coperchio deve mirare dove Magno va.")
	var reach := registry.get_engage_distance(definition)
	var sweep_half_arc := registry.get_sweep_half_arc(definition)
	assert_true(is_finite(reach), "PS-202: il Coperchio deve dichiarare una portata.")
	assert_eq(
		registry.get_engage_distance(registry.resolve_definition(&"spiedo")), INF,
		"PS-202: le armi a distanza non devono avere un limite di portata."
	)
	spawner.reset_for_run(5150)
	spawner._process(spawner.spawn_profile.initial_spawn_delay)
	assert_eq(spawner.get_alive_count(), 1, "PS-202: la fixture deve avere un bersaglio.")
	if spawner.get_alive_count() == 1:
		var enemy := spawner.get_spawned_enemies()[0]
		enemy.set_physics_process(false)
		player._update_facing_from_movement(Vector2.RIGHT)
		enemy.global_position = player.global_position + Vector2(reach + 40.0, 0.0)
		assert_true(_fire_weapon(weapon).is_empty(), "PS-202: oltre la portata il Coperchio non deve colpire.")
		assert_true(weapon.is_ready_to_fire(), "PS-202: un colpo non partito non deve consumare il cooldown.")
		enemy.global_position = player.global_position + Vector2(-(reach - 10.0), 0.0)
		assert_true(
			_fire_weapon(weapon).is_empty(),
			"PS-202: un nemico alle spalle non deve far partire il fendente."
		)
		enemy.global_position = player.global_position + Vector2(reach - 10.0, 0.0)
		var front_volley := _fire_weapon(weapon)
		assert_eq(front_volley.size(), 1, "PS-202: un nemico davanti e a portata va colpito subito.")
		_expire(front_volley)
		# Girandosi verso il nemico che era alle spalle, il fendente lo segue:
		# conta la direzione di movimento, non dove sta il bersaglio.
		enemy.global_position = player.global_position + Vector2(-(reach - 10.0), 0.0)
		player._update_facing_from_movement(Vector2.LEFT)
		var turned_volley := _fire_weapon(weapon)
		assert_eq(turned_volley.size(), 1, "PS-202: voltandosi, Magno deve colpire il nemico che ora ha davanti.")
		if turned_volley.size() == 1:
			var start_angle := (turned_volley[0].global_position - player.global_position).angle()
			assert_almost_eq(
				wrapf(start_angle + sweep_half_arc - PI, -PI, PI), 0.0, ANGLE_TOLERANCE,
				"PS-202: il fendente deve essere centrato sulla direzione di movimento."
			)
		_expire(turned_volley)

	weapon.set_manual_fire_enabled(true)
	weapon.set_manual_aim_state(Vector2.RIGHT, true)
	var volley := _fire_weapon(weapon)
	assert_eq(volley.size(), 1, "PS-202: un fendente e' un solo coperchio.")
	if volley.size() != 1:
		_finish(weapon, controller)
		return
	var lid := volley[0]
	lid.set_physics_process(false)

	var radius := definition.get_effect_float(&"orbit_radius", WeaponEffectRegistry.DEFAULT_SWEEP_RADIUS, 1.0)
	var lifetime := definition.projectile_lifetime
	var half_arc := weapon.get_effective_projectile_speed() * lifetime / radius * 0.5
	assert_true(
		half_arc > deg_to_rad(60.0),
		"PS-202: il fendente deve coprire un arco ampio davanti a Magno, non una stoccata."
	)
	assert_eq(lid.get_trajectory(), Projectile.TRAJECTORY_ORBIT, "PS-202: il coperchio gira attorno a Magno.")
	assert_eq(lid.get_visual(), Projectile.VISUAL_LID, "PS-202: il coperchio va disegnato a primitive.")
	assert_false(
		(lid.get_node("%ProjectileSprite") as Sprite2D).visible,
		"PS-202: il coperchio non deve mostrare lo sprite della brace."
	)

	# 1. Nasce mezzo arco prima della mira, sulla circonferenza dichiarata.
	var offset := lid.global_position - player.global_position
	assert_almost_eq(offset.length(), radius, POSITION_TOLERANCE, "PS-202: il coperchio nasce sull'arco.")
	assert_almost_eq(
		wrapf(offset.angle() + half_arc, -PI, PI), 0.0, ANGLE_TOLERANCE,
		"PS-202: il fendente parte mezzo arco prima della mira."
	)

	# 2. A meta' corsa passa sulla linea di mira.
	lid._physics_process(lifetime * 0.5)
	offset = lid.global_position - player.global_position
	assert_almost_eq(
		wrapf(offset.angle(), -PI, PI), 0.0, ANGLE_TOLERANCE,
		"PS-202: a meta' corsa il coperchio deve essere sulla linea di mira."
	)

	# 3. Resta agganciato a Magno anche se lui si sposta.
	player.global_position += Vector2(120.0, -80.0)
	lid._physics_process(lifetime * 0.1)
	assert_almost_eq(
		lid.global_position.distance_to(player.global_position), radius, POSITION_TOLERANCE,
		"PS-202: il coperchio deve seguire Magno, non restare dov'era."
	)

	# 4. A fine arco scade da solo.
	lid._physics_process(lifetime)
	assert_true(lid.is_spent(), "PS-202: a fine arco il coperchio deve scadere.")

	# 5. Le altre armi restano sullo sprite della brace.
	assert_true(
		weapon.set_weapon_definition(registry.resolve_definition(&"spiedo")),
		"PS-202: la fixture deve poter montare un'arma senza disegno a primitive."
	)
	var skewer_volley := _fire_weapon(weapon)
	assert_eq(skewer_volley.size(), 1, "PS-202: lo Spiedo emette un colpo.")
	if skewer_volley.size() == 1:
		assert_eq(skewer_volley[0].get_visual(), &"", "PS-202: lo Spiedo non dichiara primitive.")
		assert_true(
			(skewer_volley[0].get_node("%ProjectileSprite") as Sprite2D).visible,
			"PS-202: le armi senza primitive restano sullo sprite della brace."
		)
		skewer_volley[0].expire()

	_finish(weapon, controller)
	print("PS202_COPERCHIO_SWEEP_SMOKE_OK")


func _finish(weapon: WeaponController, controller: RunController) -> void:
	weapon.set_manual_fire_enabled(false)
	weapon.projectile_fired.disconnect(_on_projectile_fired)
	controller.prepare_restart()


func _expire(volley: Array[Projectile]) -> void:
	for projectile in volley:
		if is_instance_valid(projectile) and not projectile.is_spent():
			projectile.expire()


func _fire_weapon(weapon: WeaponController) -> Array[Projectile]:
	# Come in PS-198: _process e' spento nella fixture, un delta ampio azzera il
	# cooldown e fa scattare try_fire() catturando i colpi dal segnale.
	_fired_projectiles.clear()
	weapon._process(999.0)
	return _fired_projectiles.duplicate()


func _on_projectile_fired(projectile: Projectile, _target: BaseEnemy) -> void:
	_fired_projectiles.append(projectile)
