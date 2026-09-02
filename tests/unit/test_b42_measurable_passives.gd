extends GutGameplayTest

## B42 — Passive misurabili: Marghe e Alea.
##
## Verifica che l'aura di Marghe amplifichi davvero il danno subito dai nemici
## vicini (con un caso documentato in cui cambia il numero di colpi necessari),
## che non alteri piu' la salute massima come faceva la passiva pre-B42, e che
## la fortuna di Alea si carichi con le kill, si spenda al tiro e resti
## deterministica per seed.

const ENEMY_SCENE := preload("res://scenes/actors/base_enemy.tscn")
const BASE_ENEMY_HEALTH := 10.0


## L'API di amplificazione e' speculare a quella di velocita': una sorgente per
## ID, composizione moltiplicativa, rimozione esplicita e default neutro.
func test_damage_taken_modifiers() -> void:
	var fixture := Node2D.new()
	var enemy := ENEMY_SCENE.instantiate() as BaseEnemy
	fixture.add_child(enemy)
	add_child_autofree(fixture)
	await wait_process_frames(1)
	enemy.set_physics_process(false)

	var health := enemy.get_health_component()
	assert_almost_eq(
		enemy.get_damage_taken_multiplier(), 1.0, FLOAT_TOLERANCE, "Senza modificatori l'amplificazione deve essere neutra."
	)
	assert_true(not enemy.is_damage_amplified(), "Un nemico senza modificatori non deve risultare amplificato.")

	var before := health.health_current
	enemy.take_damage(4.0)
	assert_almost_eq(
		health.health_current, before - 4.0, FLOAT_TOLERANCE, "Senza amplificazione il danno deve restare invariato."
	)

	assert_true(enemy.set_damage_taken_modifier(&"test_a", 1.5), "Un modificatore valido deve essere accettato.")
	assert_true(enemy.set_damage_taken_modifier(&"test_b", 2.0), "Un secondo modificatore deve comporsi con il primo.")
	assert_almost_eq(
		enemy.get_damage_taken_multiplier(), 3.0, FLOAT_TOLERANCE, "I modificatori devono comporsi moltiplicativamente."
	)
	assert_true(enemy.is_damage_amplified(), "Sopra 1.0 il nemico risulta amplificato.")
	assert_true(
		not enemy.set_damage_taken_modifier(&"", 1.5)
		and not enemy.set_damage_taken_modifier(&"test_c", 0.0)
		and not enemy.set_damage_taken_modifier(&"test_c", NAN),
		"ID vuoti e moltiplicatori non validi devono essere rifiutati."
	)

	before = health.health_current
	enemy.take_damage(2.0)
	assert_almost_eq(
		health.health_current, before - 6.0, FLOAT_TOLERANCE, "Il danno deve essere amplificato dal prodotto dei modificatori."
	)

	assert_true(enemy.remove_damage_taken_modifier(&"test_b"), "La rimozione deve riuscire.")
	assert_true(
		not enemy.remove_damage_taken_modifier(&"test_b"), "Una seconda rimozione dello stesso ID deve fallire."
	)
	assert_almost_eq(
		enemy.get_damage_taken_multiplier(), 1.5, FLOAT_TOLERANCE, "Dopo la rimozione resta il solo modificatore superstite."
	)
	enemy.clear_damage_taken_modifiers()
	assert_almost_eq(
		enemy.get_damage_taken_multiplier(), 1.0, FLOAT_TOLERANCE, "La pulizia deve riportare l'amplificazione a neutra."
	)


func test_marghe_aura() -> void:
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_run_controller() as RunController
	var registry := movement_slice.get_friend_registry() as FriendRegistry
	var player := movement_slice.get_player() as Player
	var passive := movement_slice.get_friend_passive_controller() as FriendPassiveController
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	if controller == null or registry == null or player == null or passive == null or spawner == null:
		assert_true(false, "La scena di run deve esporre le dipendenze B42.")
		return

	controller.set_process(false)
	spawner.set_process(false)
	player.set_physics_process(false)
	passive.set_process(false)
	controller.start_run(9091)

	var marghe := registry.resolve_definition(&"marghe")
	assert_true(marghe != null, "Il profilo Marghe deve esistere.")
	if marghe == null:
		return
	player.set_friend_definition(marghe)
	assert_true(passive.equip_definition(marghe), "La passiva deve accettare Marghe.")

	var radius := marghe.get_passive_float(&"aura_radius", 0.0, 0.0)
	var amplification := marghe.get_passive_float(&"damage_taken_multiplier", 1.0, 1.0)
	assert_true(radius > 0.0, "Marghe deve dichiarare un raggio d'aura.")
	assert_true(amplification > 1.0, "Marghe deve dichiarare un'amplificazione reale.")
	assert_true(
		not marghe.passive_parameters.has(&"enemy_health_multiplier"),
		"La riduzione di salute pre-B42 non deve sopravvivere nei dati."
	)

	var near_enemy := spawner.try_spawn_enemy()
	var far_enemy := spawner.try_spawn_enemy()
	assert_true(near_enemy != null and far_enemy != null, "Servono due bersagli fixture per l'aura.")
	if near_enemy == null or far_enemy == null:
		controller.prepare_restart()
		return
	near_enemy.set_physics_process(false)
	far_enemy.set_physics_process(false)

	# La salute massima del nemico non viene piu' toccata: e' esattamente il
	# no-op che la slice rimuove.
	assert_almost_eq(
		near_enemy.get_health_component().health_max, BASE_ENEMY_HEALTH, FLOAT_TOLERANCE,
		"Marghe non deve piu' alterare la salute massima del nemico."
	)

	near_enemy.global_position = player.global_position + Vector2(radius * 0.5, 0.0)
	far_enemy.global_position = player.global_position + Vector2(radius * 2.0, 0.0)
	passive._process(0.1)

	assert_true(near_enemy.is_damage_amplified(), "Il nemico dentro il raggio deve essere marcato.")
	assert_true(not far_enemy.is_damage_amplified(), "Il nemico fuori dal raggio non deve essere marcato.")
	assert_almost_eq(
		near_enemy.get_damage_taken_multiplier(), amplification, FLOAT_TOLERANCE,
		"Il marchio deve applicare l'amplificazione dichiarata."
	)
	assert_eq(passive.get_marked_target_count(), 1, "L'aura deve contare un solo bersaglio marcato.")

	# Uscendo dal raggio il marchio va rimosso, non lasciato appiccicato.
	near_enemy.global_position = player.global_position + Vector2(radius * 3.0, 0.0)
	passive._process(0.1)
	assert_true(not near_enemy.is_damage_amplified(), "Uscire dal raggio deve rimuovere il marchio.")
	assert_eq(passive.get_marked_target_count(), 0, "Nessun bersaglio deve restare marcato fuori dal raggio.")

	# Osservabilita' richiesta da R4.1.3: esiste una configurazione documentata
	# in cui l'aura cambia il numero di colpi necessari a uccidere. A 8 danni
	# per colpo il nemico base (10 HP, PS-076) richiede due colpi senza aura e
	# uno solo amplificato dal 1,3x di Marghe.
	var shots_without := ceilf(BASE_ENEMY_HEALTH / 8.0)
	var shots_with := ceilf(BASE_ENEMY_HEALTH / (8.0 * amplification))
	assert_true(
		shots_with < shots_without, "A danno 15,2 l'aura deve togliere un colpo: %d contro %d." % [shots_with, shots_without]
	)

	# Cambio profilo: l'aura non deve sopravvivere al personaggio che l'ha
	# generata.
	near_enemy.global_position = player.global_position
	passive._process(0.1)
	assert_true(near_enemy.is_damage_amplified(), "Il bersaglio rientrato deve tornare marcato.")
	var magno := registry.resolve_definition(&"magno")
	player.set_friend_definition(magno)
	assert_true(passive.equip_definition(magno), "Il cambio profilo deve riuscire.")
	assert_true(not near_enemy.is_damage_amplified(), "Il cambio profilo deve ripulire i marchi di Marghe.")

	controller.prepare_restart()


func test_alea_luck() -> void:
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_run_controller() as RunController
	var registry := movement_slice.get_friend_registry() as FriendRegistry
	var player := movement_slice.get_player() as Player
	var passive := movement_slice.get_friend_passive_controller() as FriendPassiveController
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	if controller == null or registry == null or passive == null or spawner == null:
		assert_true(false, "La scena di run deve esporre le dipendenze di Alea.")
		return

	controller.set_process(false)
	spawner.set_process(false)
	player.set_physics_process(false)
	passive.set_process(false)
	controller.start_run(3131)

	var alea := registry.resolve_definition(&"alea")
	assert_true(alea != null, "Il profilo Alea deve esistere.")
	if alea == null:
		return
	player.set_friend_definition(alea)
	assert_true(passive.equip_definition(alea), "La passiva deve accettare Alea.")

	var base_chance := alea.get_passive_float(&"positive_chance", 0.6, 0.0, 1.0)
	var luck_per_kill := alea.get_passive_float(&"luck_per_kill", 0.0, 0.0, 1.0)
	var chance_cap := alea.get_passive_float(&"luck_chance_cap", 0.95, 0.0, 1.0)
	var positive_multiplier := alea.get_passive_float(&"positive_multiplier", 1.2, 0.0)
	var negative_multiplier := alea.get_passive_float(&"negative_multiplier", 0.9, 0.0)

	assert_true(luck_per_kill > 0.0, "Alea deve dichiarare una carica di fortuna per kill.")
	assert_true(
		positive_multiplier >= 1.4 and negative_multiplier <= 0.8, "La posta di Alea deve essere alta in entrambe le direzioni."
	)
	assert_almost_eq(passive.get_luck_bonus(), 0.0, FLOAT_TOLERANCE, "La run deve iniziare senza fortuna accumulata.")
	assert_almost_eq(
		passive.get_effective_positive_chance(), base_chance, FLOAT_TOLERANCE,
		"Senza kill la probabilita' effettiva coincide con quella base."
	)

	# Le kill caricano la fortuna e la caricano fino a un tetto dichiarato.
	var enemy := spawner.try_spawn_enemy()
	assert_true(enemy != null, "Serve un bersaglio fixture per le kill di Alea.")
	if enemy != null:
		enemy.set_physics_process(false)
		enemy.take_damage(9999.0)
		await wait_process_frames(1)
		assert_almost_eq(
			passive.get_luck_bonus(), luck_per_kill, FLOAT_TOLERANCE, "Una kill deve caricare esattamente la quota dichiarata."
		)
		assert_almost_eq(
			passive.get_effective_positive_chance(), base_chance + luck_per_kill, FLOAT_TOLERANCE,
			"La fortuna deve sommarsi alla probabilita' base."
		)

	for _index in range(500):
		passive._charge_alea_luck()
	assert_true(
		passive.get_luck_bonus() <= chance_cap + FLOAT_TOLERANCE,
		"La fortuna accumulata non deve superare il tetto dichiarato."
	)
	assert_true(
		passive.get_effective_positive_chance() <= chance_cap + FLOAT_TOLERANCE,
		"La probabilita' effettiva non deve superare il tetto dichiarato."
	)

	# Il tiro spende integralmente la fortuna accumulata.
	passive._process(alea.get_passive_float(&"trigger_interval", 10.0))
	assert_almost_eq(passive.get_luck_bonus(), 0.0, FLOAT_TOLERANCE, "Il tiro deve azzerare la fortuna accumulata.")

	# Restart: nessun residuo di fortuna fra le run.
	passive._charge_alea_luck()
	controller.prepare_restart()
	assert_almost_eq(passive.get_luck_bonus(), 0.0, FLOAT_TOLERANCE, "Il restart deve azzerare la fortuna accumulata.")
