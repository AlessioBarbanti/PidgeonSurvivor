extends SceneTree

const MOVEMENT_SLICE_SCENE := preload("res://scenes/game/movement_slice.tscn")
const INITIAL_VIEWPORT_SIZE := Vector2i(1280, 720)
const FLOAT_TOLERANCE := 0.001

const EXPECTED_RANKS: Dictionary = {
	&"magno_earthquake_shockwave": [
		[8.0, 0.0, 220.0, 20.0, {"knockback_force": 300.0, "stun_duration": 0.2}],
		[8.0, 0.0, 220.0, 26.0, {"knockback_force": 300.0, "stun_duration": 0.2}],
		[8.0, 0.0, 260.0, 26.0, {"knockback_force": 300.0, "stun_duration": 0.2}],
		[7.0, 0.0, 260.0, 26.0, {"knockback_force": 300.0, "stun_duration": 0.25}],
		[7.0, 0.0, 280.0, 36.0, {"knockback_force": 380.0, "stun_duration": 0.25}],
	],
	&"bea_fire_z_trail": [
		[10.0, 4.0, 0.0, 6.0, {"dash_distance": 320.0, "trail_width": 40.0}],
		[10.0, 4.0, 0.0, 8.0, {"dash_distance": 320.0, "trail_width": 40.0}],
		[10.0, 4.0, 0.0, 8.0, {"dash_distance": 380.0, "trail_width": 48.0}],
		[9.0, 5.0, 0.0, 8.0, {"dash_distance": 380.0, "trail_width": 48.0}],
		[9.0, 5.0, 0.0, 11.0, {"dash_distance": 440.0, "trail_width": 56.0}],
	],
	&"zat_lightning_storm": [
		[60.0, 2.75, 150.0, 0.0, {"strike_count": 5, "storm_radius": 260.0, "normal_max_health_damage_ratio": 0.5, "boss_max_health_damage_ratio": 0.008}],
		[60.0, 3.3, 150.0, 0.0, {"strike_count": 6, "storm_radius": 260.0, "normal_max_health_damage_ratio": 0.55, "boss_max_health_damage_ratio": 0.008}],
		[55.0, 3.0, 170.0, 0.0, {"strike_count": 6, "storm_radius": 290.0, "normal_max_health_damage_ratio": 0.55, "boss_max_health_damage_ratio": 0.009}],
		[55.0, 3.5, 170.0, 0.0, {"strike_count": 7, "storm_radius": 290.0, "normal_max_health_damage_ratio": 0.6, "boss_max_health_damage_ratio": 0.01}],
		[50.0, 3.6, 190.0, 0.0, {"strike_count": 8, "storm_radius": 320.0, "normal_max_health_damage_ratio": 0.7, "boss_max_health_damage_ratio": 0.01}],
	],
	&"alea_grand_spin": [
		[9.0, 1.2, 140.0, 5.0, {"hits_per_second": 12.0}],
		[9.0, 1.2, 140.0, 6.0, {"hits_per_second": 12.0}],
		[9.0, 1.4, 165.0, 6.0, {"hits_per_second": 12.0}],
		[8.0, 1.4, 165.0, 6.0, {"hits_per_second": 14.0}],
		[8.0, 1.6, 180.0, 8.0, {"hits_per_second": 14.0}],
	],
	&"aleo_thermal_shock": [
		[12.0, 1.2, 200.0, 14.0, {"shock_multiplier": 2.0, "slow_factor": 0.45}],
		[12.0, 1.2, 200.0, 18.0, {"shock_multiplier": 2.0, "slow_factor": 0.45}],
		[12.0, 1.4, 230.0, 18.0, {"shock_multiplier": 2.0, "slow_factor": 0.45}],
		[11.0, 1.4, 230.0, 18.0, {"shock_multiplier": 2.2, "slow_factor": 0.35}],
		[11.0, 1.6, 250.0, 26.0, {"shock_multiplier": 2.5, "slow_factor": 0.35}],
	],
	&"lollo_random_cosplay": [
		[14.0, 0.0, 0.0, 0.0, {"copy_rank": 1, "avoid_repeat": false}],
		[13.0, 0.0, 0.0, 0.0, {"copy_rank": 1, "avoid_repeat": false}],
		[13.0, 0.0, 0.0, 0.0, {"copy_rank": 2, "avoid_repeat": false}],
		[12.0, 0.0, 0.0, 0.0, {"copy_rank": 2, "avoid_repeat": true}],
		[11.0, 0.0, 0.0, 0.0, {"copy_rank": 3, "avoid_repeat": true}],
	],
	&"migi_zen_slowdown": [
		[11.0, 3.5, 260.0, 0.0, {"slow_factor": 0.4}],
		[11.0, 4.5, 260.0, 0.0, {"slow_factor": 0.4}],
		[11.0, 4.5, 300.0, 0.0, {"slow_factor": 0.4}],
		[10.0, 4.5, 300.0, 0.0, {"slow_factor": 0.32}],
		[10.0, 6.0, 340.0, 0.0, {"slow_factor": 0.25}],
	],
	&"marghe_shadow_deception": [
		[13.0, 3.0, 0.0, 0.0, {"illusion_lifetime_on_death": true}],
		[13.0, 4.0, 0.0, 0.0, {"illusion_lifetime_on_death": true}],
		[12.0, 4.0, 0.0, 0.0, {"illusion_lifetime_on_death": true}],
		[12.0, 5.0, 0.0, 0.0, {"illusion_lifetime_on_death": true}],
		[10.0, 6.0, 0.0, 0.0, {"illusion_lifetime_on_death": true}],
	],
}

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	paused = false
	root.content_scale_size = INITIAL_VIEWPORT_SIZE
	root.size = INITIAL_VIEWPORT_SIZE
	await process_frame
	await process_frame
	await _validate_rank_catalog_and_flow()
	await _finish()


func _validate_rank_catalog_and_flow() -> void:
	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	root.add_child(movement_slice)
	await process_frame
	await process_frame

	var controller := movement_slice.get_run_controller() as RunController
	var abilities := movement_slice.get_ability_effect_registry() as AbilityEffectRegistry
	var ability := movement_slice.get_ability_controller() as AbilityController
	var upgrades := movement_slice.get_upgrade_registry() as UpgradeRegistry
	var service := movement_slice.get_upgrade_service() as UpgradeService
	var experience := movement_slice.get_experience_system() as ExperienceSystem
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	var player := movement_slice.get_player() as Player
	var weapon := movement_slice.get_weapon_controller() as WeaponController
	if (
		controller == null
		or abilities == null
		or ability == null
		or upgrades == null
		or service == null
		or experience == null
	):
		_expect(false, "La scena composta B18G deve esporre tutti i servizi richiesti.")
		movement_slice.queue_free()
		return

	controller.set_process(false)
	ability.set_process(false)
	if spawner != null:
		spawner.set_process(false)
	if player != null:
		player.set_physics_process(false)
	if weapon != null:
		weapon.set_process(false)

	_validate_declared_snapshots(abilities, upgrades)
	var magno_id := &"magno_earthquake_shockwave"
	var magno_card_id := UpgradeDefinition.get_ability_rank_upgrade_id(magno_id)
	_expect(service.get_equipped_ability_id() == magno_id, "La run iniziale deve filtrare le carte rank su Magno.")
	_expect(service.get_rank(magno_card_id) == 1, "L'abilita equipaggiata deve partire al rank 1.")
	_expect(ability.get_ability_rank() == 1, "AbilityController deve partire dal profilo rank 1.")

	for target_rank in range(2, 4):
		_expect(_open_next_level(experience), "La fixture deve aprire il level-up per il rank %d." % target_rank)
		var rank_card := _reroll_until_rank_card(service, magno_id)
		_expect(rank_card != null, "La carta Magno deve essere eleggibile al rank %d." % target_rank)
		if rank_card == null or not service.select_upgrade(rank_card.id):
			_expect(false, "La selezione rank %d deve essere atomica." % target_rank)
			break
		_expect(service.get_rank(magno_card_id) == target_rank, "UpgradeService deve registrare il rank %d." % target_rank)
		_expect(ability.get_ability_rank() == target_rank, "AbilityController deve applicare il rank %d." % target_rank)

	var activated_snapshots: Array[AbilityDefinition] = []
	ability.ability_activated.connect(
		func(definition: AbilityDefinition) -> void: activated_snapshots.append(definition),
		CONNECT_ONE_SHOT
	)
	_expect(ability.try_activate(), "Il rank 3 deve produrre uno snapshot di attivazione.")
	var activated_snapshot: AbilityDefinition = (
		activated_snapshots[0] if not activated_snapshots.is_empty() else null
	)
	_expect(activated_snapshot != null and activated_snapshot.get_resolved_rank() == 3, "L'attivazione deve fotografare il rank 3.")
	_expect_float(ability.get_cooldown_total(), 8.0, "Il cooldown rank 3 deve essere 8 s.")

	_expect(_open_next_level(experience), "La fixture deve aprire il level-up rank 4 durante il cooldown.")
	var rank_four_card := _reroll_until_rank_card(service, magno_id)
	_expect(rank_four_card != null and service.select_upgrade(rank_four_card.id), "La carta rank 4 deve essere selezionabile durante il cooldown.")
	_expect(ability.get_ability_rank() == 4, "Il nuovo rank deve valere per la prossima attivazione.")
	_expect_float(ability.get_activation_definition().cooldown_seconds, 7.0, "Il profilo successivo deve usare cooldown 7 s.")
	_expect_float(ability.get_cooldown_total(), 8.0, "Il cooldown gia iniziato deve conservare lo snapshot rank 3.")
	_expect(
		activated_snapshot != null
		and activated_snapshot.get_resolved_rank() == 3
		and is_equal_approx(activated_snapshot.cooldown_seconds, 8.0),
		"Lo snapshot dell'attivazione precedente non deve essere mutato dal rank 4."
	)
	ability._process(8.0)
	_expect(ability.is_cooldown_ready(), "Il cooldown fotografato deve completarsi nel clock RUNNING.")
	_expect_float(ability.get_cooldown_total(), 7.0, "Da pronto, il cooldown deve mostrare il nuovo rank.")

	_expect(_open_next_level(experience), "La fixture deve aprire il level-up rank 5.")
	var rank_five_card := _reroll_until_rank_card(service, magno_id)
	_expect(rank_five_card != null and service.select_upgrade(rank_five_card.id), "La carta rank 5 deve essere selezionabile.")
	_expect(service.get_rank(magno_card_id) == 5 and ability.get_ability_rank() == 5, "Servizio e controller devono convergere al rank 5.")

	_expect(_open_next_level(experience), "La fixture deve aprire un'offerta dopo il cap.")
	for _attempt in 12:
		var offer := service.generate_offer(experience.get_active_level_up_level())
		_expect(_has_unique_ids(offer), "Ogni offerta B18G deve avere ID unici.")
		_expect(magno_card_id not in _offer_ids(offer), "Al rank 5 la carta abilita non deve piu essere eleggibile.")

	controller.prepare_restart()
	_expect(service.get_ranks().is_empty(), "Il restart deve rimuovere tutti i rank della run.")
	_expect(service.get_rank(magno_card_id) == 1 and ability.get_ability_rank() == 1, "La seconda run deve ripartire dal rank 1.")
	_expect(movement_slice.select_friend_for_next_run(&"bea"), "In BOOT deve essere possibile cambiare profilo.")
	var bea_id := &"bea_fire_z_trail"
	var bea_card_id := UpgradeDefinition.get_ability_rank_upgrade_id(bea_id)
	_expect(service.get_equipped_ability_id() == bea_id, "Il filtro carta deve seguire il nuovo personaggio.")
	_expect(service.get_rank(bea_card_id) == 1 and ability.get_ability_rank() == 1, "Bea deve iniziare al rank 1 senza eredita da Magno.")
	_expect(movement_slice.start_selected_run(1807), "La seconda run B18G deve avviarsi.")
	_expect(_open_next_level(experience), "La seconda run deve generare una nuova offerta.")
	var bea_card := _reroll_until_rank_card(service, bea_id)
	_expect(bea_card != null, "La seconda run deve offrire soltanto la carta dell'abilita equipaggiata.")
	if bea_card != null:
		_expect(bea_card.id == bea_card_id, "L'ID carta deve essere derivato dall'ability ID selezionato.")

	controller.prepare_restart()
	paused = false
	movement_slice.queue_free()
	await process_frame


func _validate_declared_snapshots(
	abilities: AbilityEffectRegistry,
	upgrades: UpgradeRegistry
) -> void:
	_expect(abilities.get_definitions().size() == 8, "B18G richiede otto AbilityDefinition.")
	var rank_card_count := 0
	for ability_id_value: Variant in EXPECTED_RANKS:
		var ability_id := StringName(str(ability_id_value))
		var definition := abilities.resolve_definition(ability_id)
		_expect(definition != null and definition.is_valid(), "AbilityDefinition non valida: %s." % ability_id)
		if definition == null:
			continue
		_expect(definition.rank_snapshots.size() == 5, "%s deve dichiarare cinque snapshot." % ability_id)
		var baseline_keys := definition.get_rank_snapshot(1).effect_parameters.keys()
		var expected_rows := EXPECTED_RANKS[ability_id] as Array
		for rank_index in 5:
			var rank := rank_index + 1
			var snapshot := definition.get_rank_snapshot(rank)
			var resolved := definition.resolve_rank(rank)
			var expected := expected_rows[rank_index] as Array
			_expect(snapshot != null and resolved != null, "%s rank %d deve essere risolvibile." % [ability_id, rank])
			if snapshot == null or resolved == null:
				continue
			_expect_float(resolved.cooldown_seconds, float(expected[0]), "%s R%d cooldown." % [ability_id, rank])
			_expect_float(resolved.duration_seconds, float(expected[1]), "%s R%d durata." % [ability_id, rank])
			_expect_float(resolved.area_radius, float(expected[2]), "%s R%d area." % [ability_id, rank])
			_expect_float(resolved.damage, float(expected[3]), "%s R%d danno." % [ability_id, rank])
			_expect(snapshot.effect_parameters.keys().size() == baseline_keys.size(), "%s R%d deve essere uno snapshot completo." % [ability_id, rank])
			for baseline_key: Variant in baseline_keys:
				_expect(snapshot.effect_parameters.has(baseline_key), "%s R%d non deve perdere %s." % [ability_id, rank, baseline_key])
			var expected_parameters := expected[4] as Dictionary
			for parameter_key: Variant in expected_parameters:
				_expect(
					snapshot.effect_parameters.get(parameter_key) == expected_parameters[parameter_key],
					"%s R%d parametro %s non conforme." % [ability_id, rank, parameter_key]
				)
		var card_id := UpgradeDefinition.get_ability_rank_upgrade_id(ability_id)
		var card := upgrades.resolve_definition(card_id)
		_expect(card != null and card.is_ability_rank_definition(), "Carta rank non valida per %s." % ability_id)
		if card != null:
			rank_card_count += 1
	_expect(rank_card_count == 8, "Il catalogo deve contenere otto carte rank distinte.")


func _open_next_level(experience: ExperienceSystem) -> bool:
	var missing := experience.get_experience_required() - experience.experience_current
	return experience.add_experience(maxi(missing, 1))


func _reroll_until_rank_card(
	service: UpgradeService,
	ability_id: StringName
) -> UpgradeDefinition:
	var expected_id := UpgradeDefinition.get_ability_rank_upgrade_id(ability_id)
	var active_level := service.get_active_offer_level()
	for _attempt in 100:
		var offer := service.generate_offer(active_level)
		_expect(_has_unique_ids(offer), "La carta rank non puo duplicarsi nella stessa offerta.")
		for definition in offer:
			if definition.effect_id == UpgradeEffectRegistry.ABILITY_RANK:
				var offered_ability_id := StringName(str(definition.effect_parameters.get("ability_id", "")))
				_expect(offered_ability_id == ability_id, "Le carte di abilita non equipaggiate devono essere escluse.")
			if definition.id == expected_id:
				return definition
	return null


func _offer_ids(offer: Array[UpgradeDefinition]) -> Array[StringName]:
	var ids: Array[StringName] = []
	for definition in offer:
		ids.append(definition.id)
	return ids


func _has_unique_ids(offer: Array[UpgradeDefinition]) -> bool:
	var ids := _offer_ids(offer)
	var unique: Dictionary = {}
	for id in ids:
		unique[id] = true
	return ids.size() == UpgradeService.DEFAULT_OFFER_SIZE and unique.size() == ids.size()


func _expect_float(actual: float, expected: float, message: String) -> void:
	_expect(absf(actual - expected) <= FLOAT_TOLERANCE, "%s Atteso %.3f, ottenuto %.3f." % [message, expected, actual])


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	paused = false
	await process_frame
	if _failures.is_empty():
		print("B18G_ABILITY_RANKS_SMOKE_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	printerr("B18G_ABILITY_RANKS_SMOKE_FAIL count=%d" % _failures.size())
	quit(1)
