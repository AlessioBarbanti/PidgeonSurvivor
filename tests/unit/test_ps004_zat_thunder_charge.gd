extends GutGameplayTest

## PS-004 — Tempesta di Tuoni legata al danno recuperabile.
##
## Copre il contratto della card: fotografia dei bersagli vivi, danno a tre
## fasce derivato dagli HP recuperabili di Guarigione Ritardata (PS-003),
## quota non consumata, aura orbitante come tell (numero/colore/velocita'),
## congelamento fuori da `RUNNING` e cleanup su restart/cambio personaggio.
##
## I due colpi fixture da `FIXTURE_DAMAGE` riproducono l'esempio della card:
## con `recoverable_fraction = 0,35` e gli HP massimi di Zat, un colpo supera
## la soglia media e due colpi superano la soglia alta.

const ZAT_ID := &"zat"
const MAGNO_ID := &"magno"
const FIXTURE_DAMAGE := 20.0
const TANKY_ENEMY_HEALTH := 500.0
const RUN_SEED := 4711


func test_ps004_fascia_bassa_danno_12_e_aura_verde() -> void:
	await _assert_tier_damage_and_aura(
		0, 12.0, ThunderChargeAura.TIER_LOW, 1, ThunderChargeAura.BOLT_COLORS[ThunderChargeAura.TIER_LOW]
	)


func test_ps004_fascia_media_danno_24_e_aura_gialla() -> void:
	await _assert_tier_damage_and_aura(
		1, 24.0, ThunderChargeAura.TIER_MEDIUM, 2, ThunderChargeAura.BOLT_COLORS[ThunderChargeAura.TIER_MEDIUM]
	)


func test_ps004_fascia_alta_danno_36_e_aura_rossa() -> void:
	await _assert_tier_damage_and_aura(
		2, 36.0, ThunderChargeAura.TIER_HIGH, 3, ThunderChargeAura.BOLT_COLORS[ThunderChargeAura.TIER_HIGH]
	)


func test_ps004_velocita_rotazione_cresce_con_la_fascia() -> void:
	var context := await _build_zat_context()
	if context.is_empty():
		return
	var player: Player = context["player"]
	var passive: FriendPassiveController = context["passive"]
	var health: HealthComponent = context["health"]

	var aura := player.find_child("ThunderChargeAura") as ThunderChargeAura
	assert_true(aura != null, "PS-004: il Player deve esporre l'aura del Tuono.")
	if aura == null:
		return

	assert_eq(
		passive.get_thunder_charge_tier(), ThunderChargeAura.TIER_LOW,
		"PS-004: senza quota accumulata la fascia deve restare bassa."
	)
	var low_speed := aura.get_rotation_speed()

	assert_true(_hit(player, health, FIXTURE_DAMAGE), "Serve un colpo per la fascia media.")
	assert_eq(
		passive.get_thunder_charge_tier(), ThunderChargeAura.TIER_MEDIUM,
		"PS-004: un colpo da 20 deve portare in fascia media."
	)
	var medium_speed := aura.get_rotation_speed()

	assert_true(_hit(player, health, FIXTURE_DAMAGE), "Serve un secondo colpo per la fascia alta.")
	assert_eq(
		passive.get_thunder_charge_tier(), ThunderChargeAura.TIER_HIGH,
		"PS-004: due colpi da 20 devono portare in fascia alta."
	)
	var high_speed := aura.get_rotation_speed()

	assert_true(
		low_speed < medium_speed and medium_speed < high_speed,
		"PS-004: la velocita' di rotazione deve crescere da fascia bassa ad alta."
	)


func test_ps004_snapshot_esclude_nemici_comparsi_dopo() -> void:
	var context := await _build_zat_context()
	if context.is_empty():
		return
	var player: Player = context["player"]
	var ability: AbilityController = context["ability"]
	var effects: AbilityEffectRegistry = context["effects"]
	var spawner: EnemySpawner = context["spawner"]

	var early_enemy := _spawn_tanky_enemy(spawner, player.global_position + Vector2(80.0, 0.0))
	assert_true(early_enemy != null, "Serve un bersaglio presente prima dell'attivazione.")
	if early_enemy == null:
		return
	var early_health := early_enemy.get_health_component()
	var early_initial := early_health.health_current

	assert_true(ability.try_activate(), "PS-004: Tempesta di Tuoni deve attivarsi con un bersaglio vivo.")
	var storm := _last_effect(effects) as ThunderStorm
	assert_true(storm != null, "PS-004: l'attivazione deve creare un ThunderStorm.")
	if storm == null:
		return
	assert_eq(storm.get_snapshot_count(), 1, "PS-004: lo snapshot deve fotografare solo i nemici gia' vivi.")

	var late_enemy := _spawn_tanky_enemy(spawner, player.global_position + Vector2(-80.0, 0.0))
	assert_true(late_enemy != null, "Serve un bersaglio comparso dopo lo snapshot.")
	if late_enemy == null:
		return
	var late_health := late_enemy.get_health_component()
	var late_initial := late_health.health_current

	storm._process(1.0)

	assert_almost_eq(
		early_initial - early_health.health_current, storm.get_per_target_damage(), FLOAT_TOLERANCE,
		"PS-004: il bersaglio fotografato deve ricevere esattamente un colpo."
	)
	assert_almost_eq(
		late_health.health_current, late_initial, FLOAT_TOLERANCE,
		"PS-004: un nemico comparso dopo lo snapshot non deve essere colpito."
	)


func test_ps004_ogni_nemico_fotografato_riceve_un_solo_colpo() -> void:
	var context := await _build_zat_context()
	if context.is_empty():
		return
	var player: Player = context["player"]
	var ability: AbilityController = context["ability"]
	var effects: AbilityEffectRegistry = context["effects"]
	var spawner: EnemySpawner = context["spawner"]

	var offsets := [Vector2(80.0, 0.0), Vector2(-80.0, 0.0), Vector2(0.0, 90.0)]
	var enemies: Array[BaseEnemy] = []
	var initial_health_values: Array[float] = []
	for offset in offsets:
		var enemy := _spawn_tanky_enemy(spawner, player.global_position + offset)
		assert_true(enemy != null, "Serve un bersaglio fixture per ogni offset.")
		if enemy == null:
			return
		enemies.append(enemy)
		initial_health_values.append(enemy.get_health_component().health_current)

	assert_true(ability.try_activate(), "PS-004: Tempesta di Tuoni deve attivarsi.")
	var storm := _last_effect(effects) as ThunderStorm
	assert_true(storm != null, "PS-004: l'attivazione deve creare un ThunderStorm.")
	if storm == null:
		return
	assert_eq(storm.get_snapshot_count(), enemies.size(), "PS-004: lo snapshot deve includere tutti i nemici vivi.")

	storm._process(1.0)

	assert_eq(storm.get_affected_count(), enemies.size(), "PS-004: ogni nemico fotografato deve essere colpito.")
	for index in enemies.size():
		var health := enemies[index].get_health_component()
		assert_almost_eq(
			initial_health_values[index] - health.health_current, storm.get_per_target_damage(), FLOAT_TOLERANCE,
			"PS-004: il nemico %d deve ricevere esattamente un colpo." % index
		)


func test_ps004_guarigione_ritardata_continua_dopo_lattivazione() -> void:
	var context := await _build_zat_context()
	if context.is_empty():
		return
	var player: Player = context["player"]
	var passive: FriendPassiveController = context["passive"]
	var health: HealthComponent = context["health"]
	var ability: AbilityController = context["ability"]
	var effects: AbilityEffectRegistry = context["effects"]
	var spawner: EnemySpawner = context["spawner"]
	var fraction: float = context["fraction"]
	var delay: float = context["delay"]
	var duration: float = context["duration"]

	assert_true(_hit(player, health, FIXTURE_DAMAGE), "Serve un colpo da recuperare.")
	var expected := FIXTURE_DAMAGE * fraction
	assert_almost_eq(
		passive.get_recoverable_health(), expected, FLOAT_TOLERANCE,
		"PS-004: la quota recuperabile deve maturare come da contratto PS-003."
	)

	var enemy := _spawn_tanky_enemy(spawner, player.global_position + Vector2(80.0, 0.0))
	assert_true(enemy != null, "Serve un bersaglio per attivare il Tuono.")
	if enemy == null:
		return
	assert_true(ability.try_activate(), "PS-004: Tempesta di Tuoni deve attivarsi.")
	var storm := _last_effect(effects) as ThunderStorm
	if storm != null:
		storm._process(1.0)

	assert_almost_eq(
		passive.get_recoverable_health(), expected, FLOAT_TOLERANCE,
		"PS-004: usare Tempesta di Tuoni non deve consumare la quota recuperabile."
	)

	var damaged_health := health.health_current
	passive._process(delay)
	passive._process(duration)
	assert_almost_eq(
		health.health_current, damaged_health + expected, FLOAT_TOLERANCE,
		"PS-004: Guarigione Ritardata deve completare il recupero normalmente dopo l'attivazione."
	)
	assert_almost_eq(
		passive.get_recoverable_health(), 0.0, FLOAT_TOLERANCE,
		"PS-004: a fine finestra la quota deve essere esaurita come da contratto PS-003."
	)


func test_ps004_pausa_congela_aura_e_preavviso() -> void:
	var context := await _build_zat_context()
	if context.is_empty():
		return
	var controller: RunController = context["controller"]
	var player: Player = context["player"]
	var passive: FriendPassiveController = context["passive"]
	var health: HealthComponent = context["health"]
	var ability: AbilityController = context["ability"]
	var effects: AbilityEffectRegistry = context["effects"]
	var spawner: EnemySpawner = context["spawner"]

	assert_true(_hit(player, health, FIXTURE_DAMAGE), "Serve carica per una rotazione non nulla.")
	var aura := player.find_child("ThunderChargeAura") as ThunderChargeAura
	assert_true(aura != null, "PS-004: il Player deve esporre l'aura del Tuono.")
	if aura == null:
		return

	var enemy := _spawn_tanky_enemy(spawner, player.global_position + Vector2(80.0, 0.0))
	assert_true(enemy != null, "Serve un bersaglio per attivare il Tuono.")
	if enemy == null:
		return
	assert_true(ability.try_activate(), "PS-004: Tempesta di Tuoni deve attivarsi.")
	var storm := _last_effect(effects) as ThunderStorm
	assert_true(storm != null, "PS-004: l'attivazione deve creare un ThunderStorm.")
	if storm == null:
		return

	var angle_before := aura.get_angle()
	var elapsed_before := storm.get_elapsed()

	assert_true(controller.request_manual_pause(), "La fixture deve poter mettere in pausa la run.")
	passive._process(1.0)
	storm._process(1.0)
	assert_almost_eq(
		aura.get_angle(), angle_before, FLOAT_TOLERANCE,
		"PS-004: la rotazione dell'aura deve congelarsi fuori da RUNNING."
	)
	assert_almost_eq(
		storm.get_elapsed(), elapsed_before, FLOAT_TOLERANCE,
		"PS-004: il preavviso del Tuono deve congelarsi fuori da RUNNING."
	)

	assert_true(controller.resume_run(), "La run deve poter riprendere.")
	passive._process(0.2)
	storm._process(1.0)
	assert_true(
		not is_equal_approx(aura.get_angle(), angle_before),
		"PS-004: la rotazione deve riprendere tornando in RUNNING."
	)
	assert_true(
		storm.get_elapsed() > elapsed_before,
		"PS-004: il preavviso deve riprendere tornando in RUNNING."
	)
	get_tree().paused = false


func test_ps004_restart_e_cambio_personaggio_azzerano_laura() -> void:
	var context := await _build_zat_context()
	if context.is_empty():
		return
	var slice: Control = context["slice"]
	var controller: RunController = context["controller"]
	var player: Player = context["player"]
	var passive: FriendPassiveController = context["passive"]
	var health: HealthComponent = context["health"]

	assert_true(_hit(player, health, FIXTURE_DAMAGE), "Primo colpo.")
	assert_true(_hit(player, health, FIXTURE_DAMAGE), "Secondo colpo, deve portare in fascia alta.")
	var aura := player.find_child("ThunderChargeAura") as ThunderChargeAura
	assert_true(aura != null, "PS-004: il Player deve esporre l'aura del Tuono.")
	if aura == null:
		return
	assert_eq(aura.get_tier(), ThunderChargeAura.TIER_HIGH, "La fixture deve raggiungere la fascia alta.")
	assert_true(aura.is_presented(), "L'aura deve essere presentata durante RUNNING.")

	controller.prepare_restart()
	assert_almost_eq(
		passive.get_recoverable_health(), 0.0, FLOAT_TOLERANCE,
		"PS-004: il restart deve azzerare la quota recuperabile."
	)
	assert_eq(
		passive.get_thunder_charge_tier(), ThunderChargeAura.TIER_LOW,
		"PS-004: il restart deve riportare la fascia a bassa."
	)
	assert_false(
		aura.is_presented(), "PS-004: fuori da RUNNING l'aura non deve restare presentata dopo il restart."
	)

	assert_true(slice.select_friend_for_next_run(MAGNO_ID), "Il cambio personaggio deve essere accettato in BOOT.")
	assert_true(slice.start_selected_run(RUN_SEED + 1), "La nuova run deve avviarsi con Magno.")
	assert_false(
		player.is_thunder_charge_presented(),
		"PS-004: cambiando personaggio l'aura del Tuono non deve piu' essere presentata."
	)


func test_ps004_fulmini_orbitanti_sono_solo_vfx() -> void:
	var context := await _build_zat_context()
	if context.is_empty():
		return
	var player: Player = context["player"]
	var aura := player.find_child("ThunderChargeAura") as ThunderChargeAura
	assert_true(aura != null, "PS-004: il Player deve esporre l'aura del Tuono.")
	if aura == null:
		return
	assert_eq(
		aura.get_child_count(), 0,
		"PS-004: l'aura non deve avere figli con collisioni o effetti propri (nessuna Area2D/CollisionObject2D)."
	)


func _assert_tier_damage_and_aura(
	hit_count: int,
	expected_damage: float,
	expected_tier: int,
	expected_bolt_count: int,
	expected_color: Color
) -> void:
	var context := await _build_zat_context()
	if context.is_empty():
		return
	var player: Player = context["player"]
	var passive: FriendPassiveController = context["passive"]
	var health: HealthComponent = context["health"]
	var ability: AbilityController = context["ability"]
	var effects: AbilityEffectRegistry = context["effects"]
	var spawner: EnemySpawner = context["spawner"]

	if hit_count == 1:
		assert_eq(
			effects.resolve_definition(&"zat_lightning_storm").title, "Tempesta di Tuoni",
			"PS-004: il nome pubblico dell'attiva deve restare invariato."
		)

	for _index in hit_count:
		assert_true(_hit(player, health, FIXTURE_DAMAGE), "Serve un colpo per raggiungere la fascia.")

	assert_eq(
		passive.get_thunder_charge_tier(), expected_tier,
		"PS-004: la fascia di carica deve corrispondere agli HP recuperabili accumulati."
	)
	var aura := player.find_child("ThunderChargeAura") as ThunderChargeAura
	assert_true(aura != null, "PS-004: il Player deve esporre l'aura del Tuono.")
	if aura == null:
		return
	assert_eq(aura.get_tier(), expected_tier, "PS-004: l'aura deve riflettere la fascia della passiva.")
	assert_eq(
		aura.get_bolt_count(), expected_bolt_count,
		"PS-004: il numero di fulmini orbitanti deve corrispondere alla fascia."
	)
	assert_eq(
		aura.get_bolt_color(), expected_color,
		"PS-004: il colore dei fulmini orbitanti deve corrispondere alla fascia."
	)
	assert_true(aura.is_presented(), "PS-004: l'aura deve restare visibile in RUNNING.")

	var enemy := _spawn_tanky_enemy(spawner, player.global_position + Vector2(80.0, 0.0))
	assert_true(enemy != null, "Serve un bersaglio fixture.")
	if enemy == null:
		return
	var enemy_health := enemy.get_health_component()
	var initial_enemy_health := enemy_health.health_current
	var recoverable_before := passive.get_recoverable_health()

	assert_true(ability.try_activate(), "PS-004: Tempesta di Tuoni deve attivarsi.")
	var storm := _last_effect(effects) as ThunderStorm
	assert_true(storm != null, "PS-004: l'attivazione deve creare un ThunderStorm.")
	if storm == null:
		return
	assert_almost_eq(
		enemy_health.health_current, initial_enemy_health, FLOAT_TOLERANCE,
		"PS-004: il preavviso deve precedere il danno."
	)

	storm._process(1.0)

	assert_almost_eq(
		initial_enemy_health - enemy_health.health_current, expected_damage, FLOAT_TOLERANCE,
		"PS-004: la fascia deve infliggere esattamente il danno dichiarato dalla card."
	)
	assert_almost_eq(
		passive.get_recoverable_health(), recoverable_before, FLOAT_TOLERANCE,
		"PS-004: l'attivazione non deve consumare gli HP recuperabili."
	)


func _spawn_tanky_enemy(spawner: EnemySpawner, position: Vector2) -> BaseEnemy:
	var enemy := spawner.try_spawn_enemy()
	if enemy == null:
		return null
	enemy.set_physics_process(false)
	enemy.global_position = position
	var health := enemy.get_health_component()
	if health != null:
		health.set_health_max(TANKY_ENEMY_HEALTH)
		health.reset_to_max()
	return enemy


func _last_effect(effects: AbilityEffectRegistry) -> Node2D:
	var active_effects := effects.get_active_effects()
	return active_effects.back() if not active_effects.is_empty() else null


func _hit(player: Player, health: HealthComponent, amount: float) -> bool:
	health.clear_invulnerability()
	return player.take_contact_damage(amount)


func _build_zat_context() -> Dictionary:
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_run_controller() as RunController
	var registry := movement_slice.get_friend_registry() as FriendRegistry
	var player := movement_slice.get_player() as Player
	var passive := movement_slice.get_friend_passive_controller() as FriendPassiveController
	var ability := movement_slice.get_ability_controller() as AbilityController
	var effects := movement_slice.get_ability_effect_registry() as AbilityEffectRegistry
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	if (
		controller == null or registry == null or player == null or passive == null
		or ability == null or effects == null or spawner == null
	):
		assert_true(false, "La scena di run deve esporre le dipendenze PS-004.")
		return {}

	controller.prepare_restart()
	assert_true(
		movement_slice.select_friend_for_next_run(ZAT_ID), "Zat deve essere selezionabile in BOOT."
	)
	assert_true(movement_slice.start_selected_run(RUN_SEED), "La run PS-004 deve avviarsi.")

	controller.set_process(false)
	player.set_physics_process(false)
	passive.set_process(false)
	ability.set_process(false)
	spawner.set_process(false)

	var health := player.get_health_component()
	var definition := registry.resolve_definition(ZAT_ID)
	assert_true(health != null and definition != null, "Zat deve esporre salute e profilo.")
	if health == null or definition == null:
		return {}

	return {
		"slice": movement_slice,
		"controller": controller,
		"registry": registry,
		"player": player,
		"passive": passive,
		"ability": ability,
		"effects": effects,
		"spawner": spawner,
		"health": health,
		"definition": definition,
		"fraction": definition.get_passive_float(&"recoverable_fraction", 0.0, 0.0, 1.0),
		"delay": definition.get_passive_float(&"recovery_delay", 3.0, 0.0),
		"duration": definition.get_passive_float(
			&"recovery_duration", 4.0, AbilityDefinition.MINIMUM_POSITIVE_VALUE
		),
	}
