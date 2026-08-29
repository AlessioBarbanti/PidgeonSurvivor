extends SceneTree

const MOVEMENT_SLICE_SCENE := preload("res://scenes/game/movement_slice.tscn")
const INITIAL_VIEWPORT_SIZE := Vector2i(1280, 720)
const FRIEND_IDS: Array[StringName] = [
	&"magno",
	&"bea",
	&"zat",
	&"alea",
	&"aleo",
	&"lollo",
	&"migi",
	&"marghe",
]
const FLOAT_TOLERANCE := 0.02

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	paused = false
	root.content_scale_size = INITIAL_VIEWPORT_SIZE
	root.size = INITIAL_VIEWPORT_SIZE
	await _wait_processed_frame()
	await _validate_complete_roster()
	await _finish()


func _validate_complete_roster() -> void:
	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	root.add_child(movement_slice)
	await _wait_processed_frame()

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

	_expect(registry != null and registry.get_definitions().size() == 8, "Il roster deve contenere otto profili.")
	_expect(overlay != null and overlay.get_roster_size() == 8, "Il selettore deve contenere otto target touch/focus.")
	_expect(effects != null and effects.get_definitions().size() == 8, "Il registry deve contenere otto abilita.")
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
		movement_slice.queue_free()
		await process_frame
		return

	controller.set_process(false)
	spawner.set_process(false)
	player.set_physics_process(false)
	weapon.set_process(false)
	ability.set_process(false)
	passive.set_process(false)

	for friend_id in FRIEND_IDS:
		await _switch_character(movement_slice, friend_id)
		_expect(controller.is_running(), "%s deve avviare una run da selezione." % friend_id)
		var definition := registry.resolve_definition(friend_id)
		_expect(definition != null, "Profilo mancante: %s." % friend_id)
		if definition == null:
			continue
		_expect(player.get_friend_definition() == definition, "Il Player deve equipaggiare %s." % friend_id)
		_expect(passive.get_definition() == definition, "La passiva deve equipaggiare %s." % friend_id)
		_expect(
			ability.get_definition().id == definition.active_ability_id,
			"L'attiva equipaggiata deve corrispondere a %s." % friend_id
		)
		_expect(definition.get_public_portrait() != null, "%s deve avere un ritratto runtime." % friend_id)
		_validate_multiplier_composition(player, weapon, friend_id)
		_validate_passive(player, passive, weapon, friend_id)
		_validate_ability(movement_slice, player, ability, effects, spawner, friend_id)

	if controller.is_running():
		controller.request_defeat()
	controller.prepare_restart()
	paused = false
	movement_slice.queue_free()
	await process_frame


func _switch_character(movement_slice: Control, friend_id: StringName) -> void:
	var controller := movement_slice.get_run_controller() as RunController
	var overlay := movement_slice.get_character_select_overlay() as CharacterSelectOverlay
	var end_screen := movement_slice.get_end_screen() as EndScreen
	if controller.is_running():
		controller.request_defeat()
	await process_frame
	var change_button := end_screen.get_change_character_button()
	_expect(change_button != null and not change_button.disabled, "Il terminale deve offrire Cambia personaggio.")
	if change_button == null:
		return
	change_button.pressed.emit()
	await process_frame
	_expect(
		controller.get_state() == RunController.RunState.BOOT and overlay.visible,
		"Cambia personaggio deve ripulire la run e riaprire il selettore in BOOT."
	)
	var safe_area := (movement_slice.get_node("ArenaLayout") as ArenaLayout).get_safe_area_rect()
	_expect(
		_rect_inside(overlay.get_selection_panel_rect(), safe_area),
		"Il pannello roster deve restare nella safe area."
	)
	_expect(
		movement_slice.get_ability_effect_registry().get_active_effect_count() == 0,
		"Il cambio personaggio deve rimuovere gli effetti della run precedente."
	)
	var friend_button := overlay.get_button(friend_id)
	_expect(friend_button != null, "Il selettore deve esporre %s." % friend_id)
	if friend_button == null:
		return
	friend_button.pressed.emit()
	_expect(
		friend_button.visible
		and friend_button.size.x >= 44.0
		and friend_button.size.y >= 44.0,
		"Il profilo selezionato deve restare un target touch ampio durante la transizione."
	)
	_expect(
		overlay.get_selected_definition() != null
		and overlay.get_selected_definition().id == friend_id,
		"Il tap/focus deve selezionare %s." % friend_id
	)
	overlay.get_confirm_button().pressed.emit()
	await process_frame
	_expect(not overlay.visible, "La conferma deve chiudere il selettore.")


func _validate_multiplier_composition(
	player: Player,
	weapon: WeaponController,
	friend_id: StringName
) -> void:
	var character_move_speed := player.get_base_move_speed()
	var character_fire_rate := weapon.get_base_shots_per_second()
	_expect(player.set_upgrade_stat_multipliers(1.2, 1.0, 1.0), "Fixture upgrade Player non valida.")
	_expect(weapon.set_upgrade_stat_multipliers(1.25, 1.0), "Fixture upgrade arma non valida.")
	_expect_float_near(
		player.move_speed,
		character_move_speed * 1.2,
		"Passiva e upgrade movimento devono comporsi per %s." % friend_id
	)
	_expect_float_near(
		weapon.get_effective_shots_per_second(),
		character_fire_rate * 1.25,
		"Passiva e upgrade frequenza devono comporsi per %s." % friend_id
	)
	player.reset_upgrade_stat_multipliers()
	weapon.reset_upgrade_stat_multipliers()


func _validate_passive(
	player: Player,
	passive: FriendPassiveController,
	weapon: WeaponController,
	friend_id: StringName
) -> void:
	match friend_id:
		&"magno":
			var magno_definition := passive.get_definition()
			var magno_base := magno_definition.get_base_move_speed_multiplier()
			_expect_float_near(
				player.get_character_move_speed_multiplier(),
				1.0 * magno_base,
				"Magno deve partire dal moltiplicatore base a slancio zero."
			)
			player.set_movement_input(Vector2.RIGHT)
			for _tick_index in 20:
				player._advance_momentum(0.1)
			passive._apply_character_multipliers()
			_expect(
				player.get_momentum_ratio() > 0.9,
				"Venti tick in linea retta devono quasi saturare lo slancio."
			)
			_expect_float_near(
				player.get_character_move_speed_multiplier(),
				1.35 * magno_base,
				"Lo slancio pieno deve avvicinare Magno al tetto dichiarato."
			)
			player.clear_movement_input()
		&"bea":
			_expect_float_near(
				passive.resolve_incoming_damage(20.0),
				0.0,
				"Il primo colpo di Bea deve essere annullato dal Sesto Senso Equino."
			)
			_expect_float_near(
				passive.resolve_incoming_damage(20.0),
				20.0,
				"Un secondo colpo durante il cooldown deve passare."
			)
			var bea_cooldown := passive.get_definition().get_passive_float(
				&"dodge_cooldown",
				9.0,
				AbilityDefinition.MINIMUM_POSITIVE_VALUE
			)
			passive._process(bea_cooldown)
			_expect_float_near(
				passive.resolve_incoming_damage(20.0),
				0.0,
				"A cooldown esaurito il Sesto Senso Equino deve annullare di nuovo il colpo."
			)
		&"zat":
			var health := player.get_health_component()
			_expect(player.take_contact_damage(20.0), "Zat deve ricevere il danno fixture.")
			_expect_float_near(passive.get_recoverable_health(), 7.0, "Zat deve rendere recuperabile il 35%.")
			var damaged_health := health.health_current
			passive._process(3.0)
			_expect_float_near(health.health_current, damaged_health, "Il delay di Zat deve usare il clock RUNNING.")
			passive._process(4.0)
			_expect(health.health_current > damaged_health, "Zat deve recuperare la quota differita.")
		&"alea":
			var definition := passive.get_definition()
			passive._process(definition.get_passive_float(&"trigger_interval"))
			_expect(
				player.get_character_move_speed_multiplier() != 1.0
				or weapon.get_character_fire_rate_multiplier() != 1.0,
				"Alea deve ottenere un modificatore temporaneo deterministico."
			)
			passive._process(definition.get_passive_float(&"effect_duration"))
			_expect_float_near(player.get_character_move_speed_multiplier(), 1.0, "L'effetto Alea deve terminare.")
			_expect_float_near(weapon.get_character_fire_rate_multiplier(), 1.0, "L'effetto arma Alea deve terminare.")
		&"aleo":
			_expect_float_near(
				weapon.get_character_damage_multiplier(),
				1.2,
				"Aleo in riscaldamento deve infliggere +20% danno."
			)
			_expect_float_near(
				passive.resolve_incoming_damage(20.0),
				20.0,
				"Aleo in riscaldamento non deve ridurre il danno subito."
			)
			var aleo_health := player.get_health_component()
			_expect(
				player.take_contact_damage(aleo_health.health_max * 0.6),
				"La fixture deve portare Aleo sotto la soglia termica."
			)
			passive._process(0.1)
			_expect_float_near(
				weapon.get_character_damage_multiplier(),
				1.0,
				"Il raffrescamento deve annullare il bonus di danno."
			)
			_expect_float_near(
				passive.resolve_incoming_damage(20.0),
				15.0,
				"Aleo in raffrescamento deve ridurre il danno del 25%."
			)
		&"lollo":
			var lollo_definition := passive.get_definition()
			_expect(passive.is_hyperfocused(), "Lollo deve avviare la run in iperfocus.")
			var lollo_base_move := lollo_definition.get_base_move_speed_multiplier()
			var lollo_base_fire := lollo_definition.get_base_fire_rate_multiplier()
			_expect_float_near(
				player.get_character_move_speed_multiplier(),
				1.35 * lollo_base_move,
				"L'iperfocus di Lollo deve dare +35% movimento sopra lo scarto base."
			)
			_expect_float_near(
				weapon.get_character_fire_rate_multiplier(),
				1.45 * lollo_base_fire,
				"L'iperfocus di Lollo deve dare +45% frequenza sopra lo scarto base."
			)
			var focus_remaining := passive.get_hyperfocus_remaining()
			_expect(
				focus_remaining >= lollo_definition.get_passive_float(&"focus_duration_min")
				and focus_remaining <= lollo_definition.get_passive_float(&"focus_duration_max"),
				"La fase di iperfocus deve durare un tempo casuale nell'intervallo dichiarato."
			)
			passive._process(focus_remaining + 0.01)
			_expect(not passive.is_hyperfocused(), "Alla scadenza Lollo deve passare in distrazione.")
			_expect_float_near(
				player.get_character_move_speed_multiplier(),
				0.85 * lollo_base_move,
				"La distrazione di Lollo deve ridurre il movimento del 15%."
			)
			_expect_float_near(
				weapon.get_character_fire_rate_multiplier(),
				0.8 * lollo_base_fire,
				"La distrazione di Lollo deve ridurre la frequenza del 20%."
			)
			var distracted_remaining := passive.get_hyperfocus_remaining()
			_expect(
				distracted_remaining >= lollo_definition.get_passive_float(&"distracted_duration_min")
				and distracted_remaining <= lollo_definition.get_passive_float(&"distracted_duration_max"),
				"La fase di distrazione deve durare un tempo casuale nell'intervallo dichiarato."
			)
			passive._process(distracted_remaining + 0.01)
			_expect(passive.is_hyperfocused(), "Dopo la distrazione Lollo deve rientrare in iperfocus.")
			_expect_float_near(
				player.get_character_move_speed_multiplier(),
				1.35 * lollo_base_move,
				"Il ritorno in iperfocus deve ripristinare il bonus movimento."
			)
		&"migi":
			var migi_health := player.get_health_component()
			var migi_charge_max := passive.get_definition().get_passive_int(
				&"shell_charge_max",
				2,
				0
			)
			for _charge_index in migi_charge_max:
				_expect(
					not player.take_contact_damage(5.0),
					"Ogni carica del guscio piccolo di Migi deve annullare un colpo intero."
				)
			_expect(
				passive.get_migi_shell_charges() == 0,
				"Le cariche del guscio devono esaurirsi dopo l'uso."
			)
			var migi_threshold := passive.get_definition().get_passive_float(
				&"shield_health_threshold",
				0.35,
				0.0,
				1.0
			)
			# La soglia si misura sulla salute effettiva del profilo, che dal
			# B47 include lo scarto base; le cariche esaurite sopra non hanno
			# ridotto la salute, quindi non serve maggiorare il colpo.
			var migi_damage := migi_health.health_max * (1.0 - migi_threshold) + 1.0
			_expect(
				player.take_contact_damage(migi_damage),
				"Migi deve attraversare la soglia scudo dopo aver esaurito le cariche."
			)
			_expect(passive.is_shield_active(), "Migi deve attivare lo scudo sotto il 35%.")
			_expect_float_near(passive.resolve_incoming_damage(20.0), 0.0, "Lo scudo Migi deve negare un colpo.")
			_expect(not passive.is_shield_active(), "Lo scudo a un colpo deve consumarsi.")


func _validate_ability(
	movement_slice: Control,
	player: Player,
	ability: AbilityController,
	effects: AbilityEffectRegistry,
	spawner: EnemySpawner,
	friend_id: StringName
) -> void:
	var enemy := spawner.try_spawn_enemy()
	_expect(enemy != null, "L'attiva di %s richiede un bersaglio fixture." % friend_id)
	if enemy == null:
		return
	enemy.set_physics_process(false)
	var origin := player.global_position
	enemy.global_position = origin + Vector2(70.0, 0.0)
	if friend_id == &"bea":
		enemy.global_position = origin
	var initial_health := enemy.get_health_component().health_current
	player.set_movement_input(Vector2.RIGHT)
	_expect(ability.try_activate(), "L'attiva di %s deve essere eseguibile." % friend_id)
	var active_effects := effects.get_active_effects()
	_expect(not active_effects.is_empty(), "L'attiva di %s deve creare un effetto scene-local." % friend_id)
	var effect: Node2D = active_effects.back() if not active_effects.is_empty() else null
	match friend_id:
		&"magno":
			_expect(enemy.get_health_component().health_current < initial_health, "Magno deve danneggiare nel raggio.")
		&"bea":
			_expect(effect is FireZTrail, "Bea deve creare Powerslide.")
			if effect is FireZTrail:
				(effect as FireZTrail)._process(0.1)
			_expect(player.global_position.x > origin.x, "Bea deve scattare in avanti.")
			_expect(enemy.get_health_component().health_current < initial_health, "La scia di Bea deve infliggere un tick.")
		&"zat":
			_expect(effect is ThunderStorm, "Zat deve creare la Tempesta di Tuoni.")
			_expect_float_near(
				enemy.get_health_component().health_current,
				initial_health,
				"Il preavviso del tuono deve precedere il danno."
			)
			if effect is ThunderStorm:
				(effect as ThunderStorm)._process(0.45)
			_expect(
				enemy.get_health_component().health_current < initial_health,
				"Il tuono deve colpire dopo il preavviso."
			)
		&"alea":
			_expect(effect is AbilityAreaEffect, "Alea deve creare l'area di Piroetta.")
			_expect(enemy.get_health_component().health_current < initial_health, "La Piroetta deve colpire subito.")
		&"aleo":
			_expect(effect is ThermalShock, "Aleo deve creare lo Shock Termico.")
			_expect_float_near(enemy.get_speed_multiplier(), 0.45, "La brina deve rallentare del 55%.")
			_expect_float_near(
				enemy.get_health_component().health_current,
				initial_health,
				"La fase fredda deve precedere il danno."
			)
			if effect is ThermalShock:
				(effect as ThermalShock)._process(1.2)
				_expect(
					(effect as ThermalShock).get_frosted_on_detonation() == 1,
					"Il bersaglio brinato deve essere contato allo shock."
				)
			_expect(
				enemy.get_health_component().health_current < initial_health,
				"Lo shock deve colpire alla fine della fase fredda."
			)
		&"lollo":
			_expect(
				not effects.get_last_copied_ability_id().is_empty()
				and effects.get_last_copied_ability_id() != &"lollo_random_cosplay",
				"Cosplay Casuale deve copiare un'altra attiva compatibile."
			)
		&"migi":
			_expect(effect is AbilityAreaEffect, "Migi deve creare l'aura Zen.")
			_expect_float_near(enemy.get_speed_multiplier(), 0.4, "L'aura Zen deve rallentare del 60%.")
		&"marghe":
			_expect_float_near(initial_health, 18.0, "B42: Marghe non altera piu' la salute base del nemico.")
			_expect(effect is IllusionDecoy, "Marghe deve creare un'illusione.")
			_expect(enemy.get_target() == effect, "L'illusione deve deviare l'aggro.")
	_validate_effect_pause(movement_slice.get_run_controller(), effect, friend_id)
	player.clear_movement_input()


func _validate_effect_pause(
	controller: RunController,
	effect: Node2D,
	friend_id: StringName
) -> void:
	if effect == null:
		return
	var before := _get_effect_progress(effect)
	_expect(controller.request_manual_pause(), "La fixture deve mettere in pausa %s." % friend_id)
	effect.call("_process", 1.0)
	var after := _get_effect_progress(effect)
	_expect_float_near(after, before, "L'effetto di %s deve fermarsi in pausa." % friend_id)
	_expect(controller.resume_run(), "La fixture deve riprendere %s." % friend_id)


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


func _expect_float_near(actual: float, expected: float, message: String) -> void:
	_expect(
		absf(actual - expected) <= FLOAT_TOLERANCE,
		"%s Atteso %.3f, ottenuto %.3f." % [message, expected, actual]
	)


func _rect_inside(rect: Rect2, bounds: Rect2, tolerance: float = 1.0) -> bool:
	return (
		rect.position.x >= bounds.position.x - tolerance
		and rect.position.y >= bounds.position.y - tolerance
		and rect.end.x <= bounds.end.x + tolerance
		and rect.end.y <= bounds.end.y + tolerance
	)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _wait_processed_frame() -> void:
	await process_frame
	await process_frame


func _finish() -> void:
	paused = false
	await process_frame
	if _failures.is_empty():
		print("B17A_COMPLETE_ROSTER_ABILITIES_SMOKE_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	printerr("B17A_COMPLETE_ROSTER_ABILITIES_SMOKE_FAIL count=%d" % _failures.size())
	quit(1)
