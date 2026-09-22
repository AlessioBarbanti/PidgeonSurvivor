extends GutGameplayTest

## PS-197 — L'impianto arma per personaggio deve essere neutro: ogni profilo
## risolve un'arma valida nel registry, i valori effettivi a inizio run
## restano quelli odierni per tutti e otto i personaggi, e lo sparo continua
## a passare dal punto unico `WeaponController.try_fire()` sia in automatico
## sia in manuale.

## Baseline storica di `data/weapons/default_weapon_profile.tres` prima di
## PS-197: e' contro questi numeri che si misura "il gioco non e' cambiato",
## non contro il file stesso, che dopo la card e' anche la sorgente letta.
const BASELINE_SHOTS_PER_SECOND := 4.0
const BASELINE_DAMAGE := 10.0
const BASELINE_PROJECTILE_SPEED := 900.0
const BASELINE_PROJECTILE_LIFETIME := 2.0
const BASELINE_PROJECTILE_RADIUS := 6.0
const BASELINE_MUZZLE_OFFSET := 32.0
const SHARED_WEAPON_ID := &"scintilla"

var _fired_projectiles: Array[Projectile] = []


func test_weapon_definition_wiring() -> void:
	var movement_slice := await instantiate_movement_slice()
	var controller: RunController = movement_slice.get_run_controller()
	var weapon: WeaponController = movement_slice.get_weapon_controller()
	var registry: WeaponEffectRegistry = movement_slice.get_weapon_effect_registry()
	var friend_registry: FriendRegistry = movement_slice.get_friend_registry()
	var player: Player = movement_slice.get_player()
	var spawner: EnemySpawner = movement_slice.get_enemy_spawner()
	var targeting: TargetingSystem = movement_slice.get_targeting_system()

	assert_true(registry != null, "PS-197: la scena deve montare il WeaponEffectRegistry.")
	assert_eq(
		weapon.get_weapon_effect_registry(), registry,
		"PS-197: WeaponController deve ricevere il registry dal wiring della scena."
	)
	if registry == null:
		return

	# 1. Ogni profilo risolve un'arma valida, e l'arma condivisa continua a
	#    portare esattamente la baseline di prima della card: e' l'ancora
	#    rispetto a cui si misura che l'impianto non ha cambiato il gioco.
	var friend_definitions := friend_registry.get_definitions()
	assert_eq(friend_definitions.size(), 8, "PS-197: il roster deve restare di otto personaggi.")
	for friend in friend_definitions:
		var definition := registry.resolve_definition(friend.weapon_id)
		assert_true(
			definition != null and definition.is_valid(),
			"PS-197: %s deve risolvere un'arma valida (%s)." % [friend.id, friend.weapon_id]
		)
	var shared_weapon := registry.resolve_definition(SHARED_WEAPON_ID)
	assert_true(shared_weapon != null, "PS-197: l'arma condivisa deve restare nel registry.")
	if shared_weapon == null:
		return
	_assert_shared_baseline(shared_weapon)

	# 2. Per tutti e otto, i valori effettivi a inizio run restano il prodotto
	#    dei due strati e di nient'altro: l'arma porta i valori base, il
	#    personaggio i soli moltiplicatori, senza contare due volte lo stesso
	#    scarto. Chi usa l'arma condivisa deve inoltre ritrovare la baseline.
	# instantiate_movement_slice() consegna una run gia' avviata: il cambio
	# personaggio e' ammesso solo in BOOT, come dal contratto RunController.
	controller.prepare_restart()
	await wait_process_frames(2)
	assert_true(
		controller.get_state() == RunController.RunState.BOOT,
		"PS-197: il confronto per personaggio richiede lo stato BOOT."
	)
	for friend in friend_definitions:
		assert_true(
			movement_slice.select_friend_for_next_run(friend.id),
			"PS-197: %s deve essere equipaggiabile." % friend.id
		)
		var equipped := weapon.get_weapon_definition()
		assert_true(equipped != null, "PS-197: %s deve avere un'arma equipaggiata." % friend.id)
		if equipped == null:
			continue
		# PS-208: Lollo impugna l'arma del personaggio che sta copiando.
		assert_eq(
			equipped.id,
			friend_registry.resolve_weapon_id(
				friend, movement_slice.get_ability_controller().get_pending_cosplay_ability_id()
			),
			"PS-197: l'arma equipaggiata deve essere la sua (o quella del costume)."
		)
		# I due strati vanno verificati separati, non nel loro prodotto: le
		# passive dinamiche (Termostato di Aleo, Iperfocus di Lollo) muovono
		# il moltiplicatore di personaggio a run in corso. Il contratto di
		# PS-196 e' che l'arma porti i valori base e il personaggio vi si
		# componga sopra, senza contare lo stesso scarto due volte.
		assert_almost_eq(
			weapon.get_base_shots_per_second(),
			equipped.shots_per_second * weapon.get_character_fire_rate_multiplier(),
			FLOAT_TOLERANCE,
			"PS-197: la cadenza di %s resta arma x moltiplicatore di personaggio." % friend.id
		)
		assert_almost_eq(
			weapon.get_base_damage(),
			equipped.damage * weapon.get_character_damage_multiplier(),
			FLOAT_TOLERANCE,
			"PS-197: il danno di %s resta arma x moltiplicatore di personaggio." % friend.id
		)
		assert_almost_eq(
			weapon.get_effective_projectile_speed(), equipped.projectile_speed, FLOAT_TOLERANCE,
			"PS-197: la velocita' del proiettile di %s viene dall'arma." % friend.id
		)
		if friend.weapon_id == SHARED_WEAPON_ID:
			_assert_shared_baseline(equipped)
		assert_eq(
			weapon.get_effective_pierce_count(), equipped.base_pierce_count,
			"PS-197: %s non deve partire con perforazione oltre quella dell'arma." % friend.id
		)
		assert_eq(
			weapon.get_effective_multishot_count(), equipped.base_multishot_count,
			"PS-197: %s non deve partire con un ventaglio oltre quello dell'arma." % friend.id
		)

	# La prova di neutralita' dello sparo va fatta sull'arma condivisa, che
	# dopo PS-200 non e' piu' impugnata da nessun personaggio: il cast e'
	# chiuso e `Scintilla` sopravvive solo come fallback dei dati. Si monta
	# quindi a mano, invece di sperare che qualcuno la usi ancora.
	assert_true(
		movement_slice.select_friend_for_next_run(&"magno"),
		"PS-197: la fixture deve poter equipaggiare un personaggio."
	)
	assert_true(movement_slice.start_selected_run(19701), "PS-197 richiede una run avviata.")
	await wait_process_frames(2)
	assert_true(
		weapon.set_weapon_definition(shared_weapon),
		"PS-197: l'arma condivisa deve restare montabile sul WeaponController."
	)

	controller.set_process(false)
	spawner.set_process(false)
	weapon.set_process(false)

	spawner.reset_for_run(5150)
	spawner._process(spawner.spawn_profile.initial_spawn_delay)
	assert_eq(spawner.get_alive_count(), 1, "PS-197 richiede un bersaglio per lo sparo automatico.")
	if spawner.get_alive_count() != 1:
		controller.prepare_restart()
		return
	var enemy := spawner.get_spawned_enemies()[0]
	enemy.set_physics_process(false)
	enemy.global_position = player.global_position + Vector2(150.0, 0.0)
	assert_true(targeting.has_target(enemy), "Il bersaglio deve entrare nel TargetingSystem.")

	# 3. Lo sparo resta un punto unico: l'emissione passa dal registry ma il
	#    colpo continua a nascere in try_fire(), in automatico come in manuale.
	weapon.projectile_fired.connect(_on_projectile_fired)

	var auto_volley := _fire_weapon(weapon)
	assert_eq(auto_volley.size(), 1, "PS-197: l'arma condivisa emette un proiettile per colpo.")
	if not auto_volley.is_empty():
		var auto_projectile := auto_volley[0]
		auto_projectile.set_physics_process(false)
		assert_almost_eq(
			auto_projectile.global_position.distance_to(player.global_position),
			BASELINE_MUZZLE_OFFSET, FLOAT_TOLERANCE,
			"PS-197: il proiettile automatico deve nascere sulla volata, senza offset d'emissione."
		)
		assert_almost_eq(
			auto_projectile.direction.angle(), 0.0, FLOAT_TOLERANCE,
			"PS-197: l'automatico deve continuare a mirare il nemico piu' vicino."
		)

	weapon.set_manual_fire_enabled(true)
	weapon.set_manual_aim_state(Vector2.UP, true)
	var manual_volley := _fire_weapon(weapon)
	assert_eq(manual_volley.size(), 1, "PS-197: anche in manuale l'arma emette un proiettile.")
	if not manual_volley.is_empty():
		var manual_projectile := manual_volley[0]
		manual_projectile.set_physics_process(false)
		assert_almost_eq(
			manual_projectile.direction.angle(), Vector2.UP.angle(), FLOAT_TOLERANCE,
			"PS-197: il colpo manuale deve seguire la mira, non il bersaglio."
		)
	weapon.set_manual_fire_enabled(false)
	weapon.projectile_fired.disconnect(_on_projectile_fired)

	controller.prepare_restart()
	print("PS197_WEAPON_DEFINITION_WIRING_SMOKE_OK")


func _assert_shared_baseline(definition: WeaponDefinition) -> void:
	assert_almost_eq(
		definition.shots_per_second, BASELINE_SHOTS_PER_SECOND, FLOAT_TOLERANCE,
		"PS-197: l'arma condivisa deve portare la cadenza base odierna."
	)
	assert_almost_eq(
		definition.damage, BASELINE_DAMAGE, FLOAT_TOLERANCE,
		"PS-197: l'arma condivisa deve portare il danno base odierno."
	)
	assert_almost_eq(
		definition.projectile_speed, BASELINE_PROJECTILE_SPEED, FLOAT_TOLERANCE,
		"PS-197: la velocita' del proiettile condiviso non deve cambiare."
	)
	assert_almost_eq(
		definition.projectile_lifetime, BASELINE_PROJECTILE_LIFETIME, FLOAT_TOLERANCE,
		"PS-197: la lifetime del proiettile condiviso non deve cambiare."
	)
	assert_almost_eq(
		definition.projectile_radius, BASELINE_PROJECTILE_RADIUS, FLOAT_TOLERANCE,
		"PS-197: il raggio del proiettile condiviso non deve cambiare."
	)
	assert_almost_eq(
		definition.muzzle_offset, BASELINE_MUZZLE_OFFSET, FLOAT_TOLERANCE,
		"PS-197: l'offset di volata condiviso non deve cambiare."
	)


func _fire_weapon(weapon: WeaponController) -> Array[Projectile]:
	# _process e' disabilitato in tutta la fixture: forzarlo con un delta ampio
	# azzera il cooldown residuo e fa scattare try_fire() come farebbe il
	# normale ciclo di frame, catturando ogni proiettile emesso dal segnale.
	_fired_projectiles.clear()
	weapon._process(999.0)
	return _fired_projectiles.duplicate()


func _on_projectile_fired(projectile: Projectile, _target: BaseEnemy) -> void:
	_fired_projectiles.append(projectile)
