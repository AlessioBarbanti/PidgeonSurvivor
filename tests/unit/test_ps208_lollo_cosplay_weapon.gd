extends GutGameplayTest

## PS-208 — Lollo impugna l'arma del personaggio la cui abilità è sul pulsante
## di Cosplay Casuale, e la cambia a ogni nuova estrazione. Gli altri sette
## personaggi usano sempre la propria.

const LOLLO_ID := &"lollo"
const FALLBACK_WEAPON_ID := &"attizzatoio"
const REROLLS := 60


func test_lollo_wears_the_costume_weapon() -> void:
	var movement_slice := await instantiate_movement_slice()
	var controller: RunController = movement_slice.get_run_controller()
	var weapon: WeaponController = movement_slice.get_weapon_controller()
	var friends: FriendRegistry = movement_slice.get_friend_registry()
	var ability: AbilityController = movement_slice.get_ability_controller()
	var effects: AbilityEffectRegistry = movement_slice.get_ability_effect_registry()
	controller.prepare_restart()
	await wait_process_frames(2)
	assert_eq(controller.get_state(), RunController.RunState.BOOT, "Il cambio personaggio richiede BOOT.")

	assert_true(movement_slice.select_friend_for_next_run(LOLLO_ID), "Lollo deve essere equipaggiabile.")
	var lollo := friends.resolve_definition(LOLLO_ID)
	assert_false(ability.get_pending_cosplay_ability_id().is_empty(), "Cosplay estrae subito un'abilità.")
	_assert_costume(weapon, friends, ability, "Primo equipaggiamento")
	assert_ne(weapon.get_weapon_definition().id, FALLBACK_WEAPON_ID, "Con un costume l'Attizzatoio non si usa.")
	# Il validatore gira in partita solo all'avvio della scena, con Magno: il
	# controllo B18K sull'icona del pulsante non vale per Lollo, che mostra
	# quella del costume. Qui conta soltanto il controllo sull'arma.
	var weapon_failures := RunContractValidator.collect_failures(movement_slice).filter(
		func(failure: String) -> bool: return failure.contains("arma")
	)
	assert_eq(weapon_failures, [], "Il validatore accetta l'arma del costume.")

	# Potenziamenti e scarti devono sopravvivere al cambio d'arma.
	assert_true(weapon.set_upgrade_stat_multipliers(1.3, 1.4, 1.1), "Potenziamenti della run.")
	var character_damage := weapon.get_character_damage_multiplier()
	var character_fire := weapon.get_character_fire_rate_multiplier()

	var seen := {}
	for index in REROLLS:
		effects.prepare_pending_cosplay(ability.get_definition())
		_assert_costume(weapon, friends, ability, "Estrazione %d" % index)
		var equipped := weapon.get_weapon_definition()
		seen[equipped.id] = true
		assert_almost_eq(
			weapon.get_effective_damage(), equipped.damage * character_damage * 1.4, FLOAT_TOLERANCE,
			"Estrazione %d: danno = arma × scarto × potenziamento." % index
		)
		assert_almost_eq(
			weapon.get_effective_shots_per_second(), equipped.shots_per_second * character_fire * 1.3,
			FLOAT_TOLERANCE, "Estrazione %d: cadenza = arma × scarto × potenziamento." % index
		)
	var expected_weapons := {}
	for friend in friends.get_definitions():
		if friend.id != LOLLO_ID:
			expected_weapons[friend.weapon_id] = true
	assert_eq(seen.size(), 7, "Compaiono tutte e sette le armi degli altri: %s." % [seen.keys()])
	assert_eq(seen.keys().filter(func(id: StringName) -> bool: return not expected_weapons.has(id)), [],
		"Solo armi degli altri personaggi.")
	assert_true(seen.has(&"coperchio"), "Anche il Coperchio di Magno.")
	weapon.reset_upgrade_stat_multipliers()

	# Restart o ri-selezione: anche quando l'estrazione ripete la precedente
	# (nessun segnale) l'arma torna quella del costume.
	for index in 12:
		weapon.set_weapon_definition(movement_slice.get_weapon_effect_registry().resolve_definition(FALLBACK_WEAPON_ID))
		assert_true(movement_slice.select_friend_for_next_run(LOLLO_ID), "Ri-selezione %d." % index)
		_assert_costume(weapon, friends, ability, "Ri-selezione %d" % index)

	for friend in friends.get_definitions():
		if friend.id == LOLLO_ID:
			continue
		assert_true(movement_slice.select_friend_for_next_run(friend.id), "%s equipaggiabile." % friend.id)
		assert_eq(weapon.get_weapon_definition().id, friend.weapon_id, "%s usa la propria arma." % friend.id)
		assert_eq(RunContractValidator.collect_failures(movement_slice), [], "%s: validatore pulito." % friend.id)

	assert_eq(friends.resolve_weapon_id(lollo, &""), FALLBACK_WEAPON_ID, "Senza costume: Attizzatoio.")
	print("PS208_LOLLO_COSPLAY_WEAPON_OK seen=%s" % [seen.keys()])


func _assert_costume(
	weapon: WeaponController, friends: FriendRegistry, ability: AbilityController, context: String
) -> void:
	var pending := ability.get_pending_cosplay_ability_id()
	var costume := friends.resolve_by_ability_id(pending)
	assert_true(costume != null, "%s: l'abilità %s ha un proprietario." % [context, pending])
	if costume == null:
		return
	assert_eq(weapon.get_weapon_definition().id, costume.weapon_id, "%s: arma di %s." % [context, costume.id])
