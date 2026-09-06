extends GutGameplayTest

const FRIEND_IDS: Array[StringName] = [
	&"magno", &"bea", &"zat", &"alea", &"aleo", &"lollo", &"migi", &"marghe",
]
const ROSTER_FLOAT_TOLERANCE := 0.02


func test_complete_roster() -> void:
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_run_controller() as RunController
	var registry := movement_slice.get_friend_registry() as FriendRegistry
	var overlay := movement_slice.get_character_select_overlay() as CharacterSelectOverlay
	var player := movement_slice.get_player() as Player
	var passive := movement_slice.get_friend_passive_controller() as FriendPassiveController
	var ability := movement_slice.get_ability_controller() as AbilityController
	var effects := movement_slice.get_ability_effect_registry() as AbilityEffectRegistry
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	var weapon := movement_slice.get_weapon_controller() as WeaponController
	var end_screen := movement_slice.get_end_screen() as EndScreen

	assert_true(registry != null and registry.get_definitions().size() == 8, "Il roster deve contenere otto profili.")
	assert_true(overlay != null and overlay.get_roster_size() == 8, "Il selettore deve contenere otto target touch/focus.")
	assert_true(effects != null and effects.get_definitions().size() == 8, "Il registry deve contenere otto abilita.")
	if (
		controller == null
		or registry == null
		or overlay == null
		or player == null
		or passive == null
		or ability == null
		or effects == null
		or spawner == null
		or weapon == null
		or end_screen == null
	):
		return

	controller.set_process(false)
	spawner.set_process(false)
	player.set_physics_process(false)
	weapon.set_process(false)
	ability.set_process(false)
	passive.set_process(false)

	for friend_id in FRIEND_IDS:
		await _switch_character(movement_slice, friend_id)
		assert_true(controller.is_running(), "%s deve avviare una run da selezione." % friend_id)
		var definition := registry.resolve_definition(friend_id)
		assert_true(definition != null, "Profilo mancante: %s." % friend_id)
		if definition == null:
			continue
		assert_true(player.get_friend_definition() == definition, "Il Player deve equipaggiare %s." % friend_id)
		assert_true(passive.get_definition() == definition, "La passiva deve equipaggiare %s." % friend_id)
		assert_true(
			ability.get_definition().id == definition.active_ability_id, "L'attiva equipaggiata deve corrispondere a %s." % friend_id
		)
		assert_true(definition.get_public_portrait() != null, "%s deve avere un ritratto runtime." % friend_id)
		_assert_multiplier_composition(player, weapon, friend_id)
		_assert_passive(player, passive, weapon, friend_id)
		await _assert_ability(movement_slice, player, ability, effects, spawner, friend_id)

	if controller.is_running():
		controller.request_defeat()
	controller.prepare_restart()


func _switch_character(movement_slice: Control, friend_id: StringName) -> void:
	var controller := movement_slice.get_run_controller() as RunController
	var overlay := movement_slice.get_character_select_overlay() as CharacterSelectOverlay
	var end_screen := movement_slice.get_end_screen() as EndScreen
	if controller.is_running():
		controller.request_defeat()
	await wait_process_frames(1)
	var change_button := end_screen.get_change_character_button()
	assert_true(change_button != null and not change_button.disabled, "Il terminale deve offrire Cambia personaggio.")
	if change_button == null:
		return
	change_button.pressed.emit()
	await wait_process_frames(1)
	assert_true(
		controller.get_state() == RunController.RunState.BOOT and overlay.visible,
		"Cambia personaggio deve ripulire la run e riaprire il selettore in BOOT."
	)
	var safe_area := (movement_slice.get_node("ArenaLayout") as ArenaLayout).get_safe_area_rect()
	assert_rect_inside(overlay.get_selection_panel_rect(), safe_area, "Il pannello roster deve restare nella safe area.")
	assert_true(
		movement_slice.get_ability_effect_registry().get_active_effect_count() == 0,
		"Il cambio personaggio deve rimuovere gli effetti della run precedente."
	)
	var friend_button := overlay.get_button(friend_id)
	assert_true(friend_button != null, "Il selettore deve esporre %s." % friend_id)
	if friend_button == null:
		return
	friend_button.pressed.emit()
	assert_true(
		friend_button.visible and friend_button.size.x >= 44.0 and friend_button.size.y >= 44.0,
		"Il profilo selezionato deve restare un target touch ampio durante la transizione."
	)
	assert_true(
		overlay.get_selected_definition() != null and overlay.get_selected_definition().id == friend_id,
		"Il tap/focus deve selezionare %s." % friend_id
	)
	overlay.get_confirm_button().pressed.emit()
	await wait_process_frames(1)
	assert_true(not overlay.visible, "La conferma deve chiudere il selettore.")


func _assert_multiplier_composition(player: Player, weapon: WeaponController, friend_id: StringName) -> void:
	var character_move_speed := player.get_base_move_speed()
	var character_fire_rate := weapon.get_base_shots_per_second()
	assert_true(player.set_upgrade_stat_multipliers(1.2, 1.0, 1.0), "Fixture upgrade Player non valida.")
	assert_true(weapon.set_upgrade_stat_multipliers(1.25, 1.0), "Fixture upgrade arma non valida.")
	assert_almost_eq(
		player.move_speed, character_move_speed * 1.2, ROSTER_FLOAT_TOLERANCE,
		"Passiva e upgrade movimento devono comporsi per %s." % friend_id
	)
	assert_almost_eq(
		weapon.get_effective_shots_per_second(), character_fire_rate * 1.25, ROSTER_FLOAT_TOLERANCE,
		"Passiva e upgrade frequenza devono comporsi per %s." % friend_id
	)
	player.reset_upgrade_stat_multipliers()
	weapon.reset_upgrade_stat_multipliers()


func _assert_passive(player: Player, passive: FriendPassiveController, weapon: WeaponController, friend_id: StringName) -> void:
	match friend_id:
		&"magno":
			var magno_definition := passive.get_definition()
			var magno_base := magno_definition.get_base_move_speed_multiplier()
			assert_almost_eq(
				player.get_character_move_speed_multiplier(), 1.0 * magno_base, ROSTER_FLOAT_TOLERANCE,
				"Magno deve partire dal moltiplicatore base a slancio zero."
			)
			player.set_movement_input(Vector2.RIGHT)
			for _tick_index in 20:
				player._advance_momentum(0.1)
			passive._apply_character_multipliers()
			assert_true(player.get_momentum_ratio() > 0.9, "Venti tick in linea retta devono quasi saturare lo slancio.")
			assert_almost_eq(
				player.get_character_move_speed_multiplier(), 1.35 * magno_base, ROSTER_FLOAT_TOLERANCE,
				"Lo slancio pieno deve avvicinare Magno al tetto dichiarato."
			)
			player.clear_movement_input()
		&"bea":
			assert_almost_eq(
				passive.resolve_incoming_damage(20.0), 0.0, ROSTER_FLOAT_TOLERANCE,
				"Il primo colpo di Bea deve essere annullato dal Sesto Senso Equino."
			)
			assert_almost_eq(
				passive.resolve_incoming_damage(20.0), 20.0, ROSTER_FLOAT_TOLERANCE, "Un secondo colpo durante il cooldown deve passare."
			)
			var bea_cooldown := passive.get_definition().get_passive_float(
				&"dodge_cooldown", 9.0, AbilityDefinition.MINIMUM_POSITIVE_VALUE
			)
			passive._process(bea_cooldown)
			assert_almost_eq(
				passive.resolve_incoming_damage(20.0), 0.0, ROSTER_FLOAT_TOLERANCE,
				"A cooldown esaurito il Sesto Senso Equino deve annullare di nuovo il colpo."
			)
		&"zat":
			var health := player.get_health_component()
			assert_true(player.take_contact_damage(20.0), "Zat deve ricevere il danno fixture.")
			assert_almost_eq(passive.get_recoverable_health(), 7.0, ROSTER_FLOAT_TOLERANCE, "Zat deve rendere recuperabile il 35%.")
			var damaged_health := health.health_current
			passive._process(3.0)
			assert_almost_eq(health.health_current, damaged_health, ROSTER_FLOAT_TOLERANCE, "Il delay di Zat deve usare il clock RUNNING.")
			passive._process(4.0)
			assert_true(health.health_current > damaged_health, "Zat deve recuperare la quota differita.")
		&"alea":
			var definition := passive.get_definition()
			# PS-087: Alea non e' piu' un profilo neutro, quindi il "riposo" a cui
			# il moltiplicatore di Brilla deve tornare e' il proprio scarto base,
			# non 1.0. PS-105: sostituisce l'RNG a intervalli con Due Dita e Parto,
			# un ciclo Sobrieta'/Brilla interamente deterministico.
			var base_move_speed := definition.get_base_move_speed_multiplier()
			var base_fire_rate := definition.get_base_fire_rate_multiplier()
			assert_almost_eq(
				passive.get_alea_sobriety_ratio(), 0.0, ROSTER_FLOAT_TOLERANCE,
				"Alea deve iniziare senza Sobrieta' accumulata."
			)
			passive._process(definition.get_passive_float(&"sobriety_fill_duration"))
			assert_true(passive.is_alea_brilla_active(), "Al riempimento della barra Alea deve entrare in Brilla.")
			assert_true(
				(
					not is_equal_approx(player.get_character_move_speed_multiplier(), base_move_speed)
					or not is_equal_approx(weapon.get_character_fire_rate_multiplier(), base_fire_rate)
				),
				"Alea deve ottenere un modificatore deterministico durante Brilla."
			)
			passive._process(definition.get_passive_float(&"brilla_duration") + 0.01)
			assert_true(not passive.is_alea_brilla_active(), "Trascorsa Brilla, Alea deve tornare normale.")
			assert_almost_eq(
				player.get_character_move_speed_multiplier(), base_move_speed, ROSTER_FLOAT_TOLERANCE, "L'effetto Alea deve terminare."
			)
			assert_almost_eq(
				weapon.get_character_fire_rate_multiplier(), base_fire_rate, ROSTER_FLOAT_TOLERANCE, "L'effetto arma Alea deve terminare."
			)
			assert_almost_eq(
				passive.get_alea_sobriety_ratio(), 0.0, ROSTER_FLOAT_TOLERANCE, "Trascorsa Brilla la Sobrieta' si azzera completamente."
			)
		&"aleo":
			assert_almost_eq(
				weapon.get_character_damage_multiplier(), 1.2, ROSTER_FLOAT_TOLERANCE, "Aleo in riscaldamento deve infliggere +20% danno."
			)
			assert_almost_eq(
				passive.resolve_incoming_damage(20.0), 20.0, ROSTER_FLOAT_TOLERANCE, "Aleo in riscaldamento non deve ridurre il danno subito."
			)
			var aleo_health := player.get_health_component()
			assert_true(
				player.take_contact_damage(aleo_health.health_max * 0.6), "La fixture deve portare Aleo sotto la soglia termica."
			)
			passive._process(0.1)
			assert_almost_eq(
				weapon.get_character_damage_multiplier(), 1.0, ROSTER_FLOAT_TOLERANCE, "Il raffrescamento deve annullare il bonus di danno."
			)
			assert_almost_eq(
				passive.resolve_incoming_damage(20.0), 15.0, ROSTER_FLOAT_TOLERANCE, "Aleo in raffrescamento deve ridurre il danno del 25%."
			)
		&"lollo":
			var lollo_definition := passive.get_definition()
			assert_true(passive.is_hyperfocused(), "Lollo deve avviare la run in iperfocus.")
			var lollo_base_move := lollo_definition.get_base_move_speed_multiplier()
			var lollo_base_fire := lollo_definition.get_base_fire_rate_multiplier()
			assert_almost_eq(
				player.get_character_move_speed_multiplier(), 1.35 * lollo_base_move, ROSTER_FLOAT_TOLERANCE,
				"L'iperfocus di Lollo deve dare +35% movimento sopra lo scarto base."
			)
			assert_almost_eq(
				weapon.get_character_fire_rate_multiplier(), 1.45 * lollo_base_fire, ROSTER_FLOAT_TOLERANCE,
				"L'iperfocus di Lollo deve dare +45% frequenza sopra lo scarto base."
			)
			var focus_remaining := passive.get_hyperfocus_remaining()
			assert_true(
				focus_remaining >= lollo_definition.get_passive_float(&"focus_duration_min")
				and focus_remaining <= lollo_definition.get_passive_float(&"focus_duration_max"),
				"La fase di iperfocus deve durare un tempo casuale nell'intervallo dichiarato."
			)
			passive._process(focus_remaining + 0.01)
			assert_true(not passive.is_hyperfocused(), "Alla scadenza Lollo deve passare in distrazione.")
			assert_almost_eq(
				player.get_character_move_speed_multiplier(), 0.85 * lollo_base_move, ROSTER_FLOAT_TOLERANCE,
				"La distrazione di Lollo deve ridurre il movimento del 15%."
			)
			assert_almost_eq(
				weapon.get_character_fire_rate_multiplier(), 0.8 * lollo_base_fire, ROSTER_FLOAT_TOLERANCE,
				"La distrazione di Lollo deve ridurre la frequenza del 20%."
			)
			var distracted_remaining := passive.get_hyperfocus_remaining()
			assert_true(
				distracted_remaining >= lollo_definition.get_passive_float(&"distracted_duration_min")
				and distracted_remaining <= lollo_definition.get_passive_float(&"distracted_duration_max"),
				"La fase di distrazione deve durare un tempo casuale nell'intervallo dichiarato."
			)
			passive._process(distracted_remaining + 0.01)
			assert_true(passive.is_hyperfocused(), "Dopo la distrazione Lollo deve rientrare in iperfocus.")
			assert_almost_eq(
				player.get_character_move_speed_multiplier(), 1.35 * lollo_base_move, ROSTER_FLOAT_TOLERANCE,
				"Il ritorno in iperfocus deve ripristinare il bonus movimento."
			)
		&"migi":
			var migi_health := player.get_health_component()
			var migi_charge_max := passive.get_definition().get_passive_int(&"shell_charge_max", 2, 0)
			for _charge_index in migi_charge_max:
				assert_true(
					not player.take_contact_damage(5.0), "Ogni carica del guscio piccolo di Migi deve annullare un colpo intero."
				)
			assert_true(passive.get_migi_shell_charges() == 0, "Le cariche del guscio devono esaurirsi dopo l'uso.")
			var migi_threshold := passive.get_definition().get_passive_float(&"shield_health_threshold", 0.35, 0.0, 1.0)
			# La soglia si misura sulla salute effettiva del profilo, che dal
			# B47 include lo scarto base; le cariche esaurite sopra non hanno
			# ridotto la salute, quindi non serve maggiorare il colpo.
			var migi_damage := migi_health.health_max * (1.0 - migi_threshold) + 1.0
			assert_true(
				player.take_contact_damage(migi_damage), "Migi deve attraversare la soglia scudo dopo aver esaurito le cariche."
			)
			assert_true(passive.is_shield_active(), "Migi deve attivare lo scudo sotto il 35%.")
			assert_almost_eq(
				passive.resolve_incoming_damage(20.0), 0.0, ROSTER_FLOAT_TOLERANCE, "Lo scudo Migi deve negare un colpo."
			)
			assert_true(not passive.is_shield_active(), "Lo scudo a un colpo deve consumarsi.")


func _assert_ability(
	movement_slice: Control,
	player: Player,
	ability: AbilityController,
	effects: AbilityEffectRegistry,
	spawner: EnemySpawner,
	friend_id: StringName
) -> void:
	var enemy := spawner.try_spawn_enemy()
	assert_true(enemy != null, "L'attiva di %s richiede un bersaglio fixture." % friend_id)
	if enemy == null:
		return
	enemy.set_physics_process(false)
	var origin := player.global_position
	enemy.global_position = origin + Vector2(70.0, 0.0)
	if friend_id == &"bea":
		enemy.global_position = origin
	var initial_health := enemy.get_health_component().health_current
	player.set_movement_input(Vector2.RIGHT)
	assert_true(ability.try_activate(), "L'attiva di %s deve essere eseguibile." % friend_id)
	var active_effects := effects.get_active_effects()
	assert_true(not active_effects.is_empty(), "L'attiva di %s deve creare un effetto scene-local." % friend_id)
	var effect: Node2D = active_effects.back() if not active_effects.is_empty() else null
	match friend_id:
		&"magno":
			assert_true(enemy.get_health_component().health_current < initial_health, "Magno deve danneggiare nel raggio.")
		&"bea":
			assert_true(effect is FireZTrail, "Bea deve creare Powerslide.")
			if effect is FireZTrail:
				(effect as FireZTrail)._process(0.1)
			assert_true(player.global_position.x > origin.x, "Bea deve scattare in avanti.")
			assert_true(enemy.get_health_component().health_current < initial_health, "La scia di Bea deve infliggere un tick.")
		&"zat":
			assert_true(effect is ThunderStorm, "Zat deve creare la Tempesta di Tuoni.")
			assert_almost_eq(
				enemy.get_health_component().health_current, initial_health, ROSTER_FLOAT_TOLERANCE,
				"Il preavviso del tuono deve precedere il danno."
			)
			if effect is ThunderStorm:
				(effect as ThunderStorm)._process(0.45)
			assert_true(enemy.get_health_component().health_current < initial_health, "Il tuono deve colpire dopo il preavviso.")
		&"alea":
			assert_true(effect is AbilityAreaEffect, "Alea deve creare l'area di Piroetta.")
			assert_true(enemy.get_health_component().health_current < initial_health, "La Piroetta deve colpire subito.")
		&"aleo":
			assert_true(effect is ThermalShock, "Aleo deve creare lo Shock Termico.")
			assert_almost_eq(enemy.get_speed_multiplier(), 0.45, ROSTER_FLOAT_TOLERANCE, "La brina deve rallentare del 55%.")
			assert_almost_eq(
				enemy.get_health_component().health_current, initial_health, ROSTER_FLOAT_TOLERANCE,
				"La fase fredda deve precedere il danno."
			)
			if effect is ThermalShock:
				(effect as ThermalShock)._process(1.2)
				assert_true(
					(effect as ThermalShock).get_frosted_on_detonation() == 1, "Il bersaglio brinato deve essere contato allo shock."
				)
			assert_true(enemy.get_health_component().health_current < initial_health, "Lo shock deve colpire alla fine della fase fredda.")
		&"lollo":
			assert_true(
				not effects.get_last_copied_ability_id().is_empty() and effects.get_last_copied_ability_id() != &"lollo_random_cosplay",
				"Cosplay Casuale deve copiare un'altra attiva compatibile."
			)
		&"migi":
			assert_true(effect is AbilityAreaEffect, "Migi deve creare l'aura Zen.")
			assert_almost_eq(enemy.get_speed_multiplier(), 0.4, ROSTER_FLOAT_TOLERANCE, "L'aura Zen deve rallentare del 60%.")
		&"marghe":
			assert_almost_eq(
				initial_health, 10.0, ROSTER_FLOAT_TOLERANCE, "B42: Marghe non altera piu' la salute base del nemico."
			)
			assert_true(effect is IllusionDecoy, "Marghe deve creare un'illusione.")
			assert_true(enemy.get_target() == effect, "L'illusione deve deviare l'aggro.")
	_assert_effect_pause(movement_slice.get_run_controller(), effect, friend_id)
	player.clear_movement_input()


func _assert_effect_pause(controller: RunController, effect: Node2D, friend_id: StringName) -> void:
	if effect == null:
		return
	var before := _get_effect_progress(effect)
	assert_true(controller.request_manual_pause(), "La fixture deve mettere in pausa %s." % friend_id)
	effect.call("_process", 1.0)
	var after := _get_effect_progress(effect)
	assert_almost_eq(after, before, ROSTER_FLOAT_TOLERANCE, "L'effetto di %s deve fermarsi in pausa." % friend_id)
	assert_true(controller.resume_run(), "La fixture deve riprendere %s." % friend_id)


func _get_effect_progress(effect: Node2D) -> float:
	if effect is EarthquakeWave:
		return (effect as EarthquakeWave).get_elapsed()
	if effect is FireZTrail:
		return (effect as FireZTrail).get_duration_remaining()
	if effect is ThunderStorm:
		return (effect as ThunderStorm).get_elapsed()
	if effect is AbilityAreaEffect:
		return (effect as AbilityAreaEffect).get_duration_remaining()
	if effect is IllusionDecoy:
		return (effect as IllusionDecoy).get_duration_remaining()
	if effect is ThermalShock:
		return (effect as ThermalShock).get_phase_remaining()
	return 0.0
