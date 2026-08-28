extends SceneTree

## B42 — Passive misurabili: Marghe e Alea.
##
## Verifica che l'aura di Marghe amplifichi davvero il danno subito dai nemici
## vicini (con un caso documentato in cui cambia il numero di colpi necessari),
## che non alteri piu' la salute massima come faceva la passiva pre-B42, e che
## la fortuna di Alea si carichi con le kill, si spenda al tiro e resti
## deterministica per seed.

const MOVEMENT_SLICE_SCENE := preload("res://scenes/game/movement_slice.tscn")
const ENEMY_SCENE := preload("res://scenes/actors/base_enemy.tscn")
const INITIAL_VIEWPORT_SIZE := Vector2i(1280, 720)
const FLOAT_TOLERANCE := 0.001
const BASE_ENEMY_HEALTH := 18.0

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	paused = false
	root.content_scale_size = INITIAL_VIEWPORT_SIZE
	root.size = INITIAL_VIEWPORT_SIZE
	await process_frame
	await _validate_damage_taken_modifiers()
	await _validate_marghe_aura()
	await _validate_alea_luck()
	await _finish()


## L'API di amplificazione e' speculare a quella di velocita': una sorgente per
## ID, composizione moltiplicativa, rimozione esplicita e default neutro.
func _validate_damage_taken_modifiers() -> void:
	var fixture := Node2D.new()
	var enemy := ENEMY_SCENE.instantiate() as BaseEnemy
	fixture.add_child(enemy)
	root.add_child(fixture)
	await process_frame
	enemy.set_physics_process(false)

	var health := enemy.get_health_component()
	_expect_float_near(
		enemy.get_damage_taken_multiplier(),
		1.0,
		"Senza modificatori l'amplificazione deve essere neutra."
	)
	_expect(
		not enemy.is_damage_amplified(),
		"Un nemico senza modificatori non deve risultare amplificato."
	)

	var before := health.health_current
	enemy.take_damage(4.0)
	_expect_float_near(
		health.health_current,
		before - 4.0,
		"Senza amplificazione il danno deve restare invariato."
	)

	_expect(
		enemy.set_damage_taken_modifier(&"test_a", 1.5),
		"Un modificatore valido deve essere accettato."
	)
	_expect(
		enemy.set_damage_taken_modifier(&"test_b", 2.0),
		"Un secondo modificatore deve comporsi con il primo."
	)
	_expect_float_near(
		enemy.get_damage_taken_multiplier(),
		3.0,
		"I modificatori devono comporsi moltiplicativamente."
	)
	_expect(enemy.is_damage_amplified(), "Sopra 1.0 il nemico risulta amplificato.")
	_expect(
		not enemy.set_damage_taken_modifier(&"", 1.5)
		and not enemy.set_damage_taken_modifier(&"test_c", 0.0)
		and not enemy.set_damage_taken_modifier(&"test_c", NAN),
		"ID vuoti e moltiplicatori non validi devono essere rifiutati."
	)

	before = health.health_current
	enemy.take_damage(2.0)
	_expect_float_near(
		health.health_current,
		before - 6.0,
		"Il danno deve essere amplificato dal prodotto dei modificatori."
	)

	_expect(enemy.remove_damage_taken_modifier(&"test_b"), "La rimozione deve riuscire.")
	_expect(
		not enemy.remove_damage_taken_modifier(&"test_b"),
		"Una seconda rimozione dello stesso ID deve fallire."
	)
	_expect_float_near(
		enemy.get_damage_taken_multiplier(),
		1.5,
		"Dopo la rimozione resta il solo modificatore superstite."
	)
	enemy.clear_damage_taken_modifiers()
	_expect_float_near(
		enemy.get_damage_taken_multiplier(),
		1.0,
		"La pulizia deve riportare l'amplificazione a neutra."
	)

	fixture.queue_free()
	await process_frame


func _validate_marghe_aura() -> void:
	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	root.add_child(movement_slice)
	await process_frame

	var controller := movement_slice.get_run_controller() as RunController
	var registry := movement_slice.get_friend_registry() as FriendRegistry
	var player := movement_slice.get_player() as Player
	var passive := movement_slice.get_friend_passive_controller() as FriendPassiveController
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	if (
		controller == null
		or registry == null
		or player == null
		or passive == null
		or spawner == null
	):
		_expect(false, "La scena di run deve esporre le dipendenze B42.")
		movement_slice.queue_free()
		await process_frame
		return

	controller.set_process(false)
	spawner.set_process(false)
	player.set_physics_process(false)
	passive.set_process(false)
	controller.start_run(9091)

	var marghe := registry.resolve_definition(&"marghe")
	_expect(marghe != null, "Il profilo Marghe deve esistere.")
	if marghe == null:
		movement_slice.queue_free()
		await process_frame
		return
	player.set_friend_definition(marghe)
	_expect(passive.equip_definition(marghe), "La passiva deve accettare Marghe.")

	var radius := marghe.get_passive_float(&"aura_radius", 0.0, 0.0)
	var amplification := marghe.get_passive_float(&"damage_taken_multiplier", 1.0, 1.0)
	_expect(radius > 0.0, "Marghe deve dichiarare un raggio d'aura.")
	_expect(amplification > 1.0, "Marghe deve dichiarare un'amplificazione reale.")
	_expect(
		not marghe.passive_parameters.has(&"enemy_health_multiplier"),
		"La riduzione di salute pre-B42 non deve sopravvivere nei dati."
	)

	var near_enemy := spawner.try_spawn_enemy()
	var far_enemy := spawner.try_spawn_enemy()
	_expect(
		near_enemy != null and far_enemy != null,
		"Servono due bersagli fixture per l'aura."
	)
	if near_enemy == null or far_enemy == null:
		movement_slice.queue_free()
		await process_frame
		return
	near_enemy.set_physics_process(false)
	far_enemy.set_physics_process(false)

	# La salute massima del nemico non viene piu' toccata: e' esattamente il
	# no-op che la slice rimuove.
	_expect_float_near(
		near_enemy.get_health_component().health_max,
		BASE_ENEMY_HEALTH,
		"Marghe non deve piu' alterare la salute massima del nemico."
	)

	near_enemy.global_position = player.global_position + Vector2(radius * 0.5, 0.0)
	far_enemy.global_position = player.global_position + Vector2(radius * 2.0, 0.0)
	passive._process(0.1)

	_expect(
		near_enemy.is_damage_amplified(),
		"Il nemico dentro il raggio deve essere marcato."
	)
	_expect(
		not far_enemy.is_damage_amplified(),
		"Il nemico fuori dal raggio non deve essere marcato."
	)
	_expect_float_near(
		near_enemy.get_damage_taken_multiplier(),
		amplification,
		"Il marchio deve applicare l'amplificazione dichiarata."
	)
	_expect(
		passive.get_marked_target_count() == 1,
		"L'aura deve contare un solo bersaglio marcato."
	)

	# Uscendo dal raggio il marchio va rimosso, non lasciato appiccicato.
	near_enemy.global_position = player.global_position + Vector2(radius * 3.0, 0.0)
	passive._process(0.1)
	_expect(
		not near_enemy.is_damage_amplified(),
		"Uscire dal raggio deve rimuovere il marchio."
	)
	_expect(
		passive.get_marked_target_count() == 0,
		"Nessun bersaglio deve restare marcato fuori dal raggio."
	)

	# Osservabilita' richiesta da R4.1.3: esiste una configurazione documentata
	# in cui l'aura cambia il numero di colpi necessari a uccidere.
	var shots_without := ceilf(BASE_ENEMY_HEALTH / 15.2)
	var shots_with := ceilf(BASE_ENEMY_HEALTH / (15.2 * amplification))
	_expect(
		shots_with < shots_without,
		(
			"A danno 15,2 l'aura deve togliere un colpo: %d contro %d."
			% [shots_with, shots_without]
		)
	)

	# Cambio profilo: l'aura non deve sopravvivere al personaggio che l'ha
	# generata.
	near_enemy.global_position = player.global_position
	passive._process(0.1)
	_expect(near_enemy.is_damage_amplified(), "Il bersaglio rientrato deve tornare marcato.")
	var magno := registry.resolve_definition(&"magno")
	player.set_friend_definition(magno)
	_expect(passive.equip_definition(magno), "Il cambio profilo deve riuscire.")
	_expect(
		not near_enemy.is_damage_amplified(),
		"Il cambio profilo deve ripulire i marchi di Marghe."
	)

	controller.prepare_restart()
	paused = false
	movement_slice.queue_free()
	await process_frame


func _validate_alea_luck() -> void:
	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	root.add_child(movement_slice)
	await process_frame

	var controller := movement_slice.get_run_controller() as RunController
	var registry := movement_slice.get_friend_registry() as FriendRegistry
	var player := movement_slice.get_player() as Player
	var passive := movement_slice.get_friend_passive_controller() as FriendPassiveController
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	if controller == null or registry == null or passive == null or spawner == null:
		_expect(false, "La scena di run deve esporre le dipendenze di Alea.")
		movement_slice.queue_free()
		await process_frame
		return

	controller.set_process(false)
	spawner.set_process(false)
	player.set_physics_process(false)
	passive.set_process(false)
	controller.start_run(3131)

	var alea := registry.resolve_definition(&"alea")
	_expect(alea != null, "Il profilo Alea deve esistere.")
	if alea == null:
		movement_slice.queue_free()
		await process_frame
		return
	player.set_friend_definition(alea)
	_expect(passive.equip_definition(alea), "La passiva deve accettare Alea.")

	var base_chance := alea.get_passive_float(&"positive_chance", 0.6, 0.0, 1.0)
	var luck_per_kill := alea.get_passive_float(&"luck_per_kill", 0.0, 0.0, 1.0)
	var chance_cap := alea.get_passive_float(&"luck_chance_cap", 0.95, 0.0, 1.0)
	var positive_multiplier := alea.get_passive_float(&"positive_multiplier", 1.2, 0.0)
	var negative_multiplier := alea.get_passive_float(&"negative_multiplier", 0.9, 0.0)

	_expect(luck_per_kill > 0.0, "Alea deve dichiarare una carica di fortuna per kill.")
	_expect(
		positive_multiplier >= 1.4 and negative_multiplier <= 0.8,
		"La posta di Alea deve essere alta in entrambe le direzioni."
	)
	_expect_float_near(
		passive.get_luck_bonus(),
		0.0,
		"La run deve iniziare senza fortuna accumulata."
	)
	_expect_float_near(
		passive.get_effective_positive_chance(),
		base_chance,
		"Senza kill la probabilita' effettiva coincide con quella base."
	)

	# Le kill caricano la fortuna e la caricano fino a un tetto dichiarato.
	var enemy := spawner.try_spawn_enemy()
	_expect(enemy != null, "Serve un bersaglio fixture per le kill di Alea.")
	if enemy != null:
		enemy.set_physics_process(false)
		enemy.take_damage(9999.0)
		await process_frame
		_expect_float_near(
			passive.get_luck_bonus(),
			luck_per_kill,
			"Una kill deve caricare esattamente la quota dichiarata."
		)
		_expect_float_near(
			passive.get_effective_positive_chance(),
			base_chance + luck_per_kill,
			"La fortuna deve sommarsi alla probabilita' base."
		)

	for _index in range(500):
		passive._charge_alea_luck()
	_expect(
		passive.get_luck_bonus() <= chance_cap + FLOAT_TOLERANCE,
		"La fortuna accumulata non deve superare il tetto dichiarato."
	)
	_expect(
		passive.get_effective_positive_chance() <= chance_cap + FLOAT_TOLERANCE,
		"La probabilita' effettiva non deve superare il tetto dichiarato."
	)

	# Il tiro spende integralmente la fortuna accumulata.
	passive._process(alea.get_passive_float(&"trigger_interval", 10.0))
	_expect_float_near(
		passive.get_luck_bonus(),
		0.0,
		"Il tiro deve azzerare la fortuna accumulata."
	)

	# Restart: nessun residuo di fortuna fra le run.
	passive._charge_alea_luck()
	controller.prepare_restart()
	_expect_float_near(
		passive.get_luck_bonus(),
		0.0,
		"Il restart deve azzerare la fortuna accumulata."
	)

	paused = false
	movement_slice.queue_free()
	await process_frame


func _expect_float_near(actual: float, expected: float, message: String) -> void:
	_expect(
		absf(actual - expected) <= FLOAT_TOLERANCE,
		"%s Atteso %s, ottenuto %s." % [message, expected, actual]
	)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	paused = false
	await process_frame
	if _failures.is_empty():
		print("B42_MEASURABLE_PASSIVES_SMOKE_OK")
		quit(0)
		return
	for failure in _failures:
		printerr(failure)
	printerr("B42_MEASURABLE_PASSIVES_SMOKE_FAIL count=%d" % _failures.size())
	quit(1)
