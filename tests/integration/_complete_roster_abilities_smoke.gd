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
	_expect(
		friend_button.size.x >= 180.0 and friend_button.size.y >= 88.0,
		"Ogni profilo deve restare un target touch ampio."
	)
	friend_button.pressed.emit()
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
			_expect_float_near(player.get_character_move_speed_multiplier(), 1.15, "Magno deve avere +15% movimento.")
		&"bea":
			passive._rng.seed = 1
			var avoided := 0
			for _index in 32:
				if passive.resolve_incoming_damage(20.0) <= 0.0:
					avoided += 1
			_expect(avoided > 0 and avoided < 32, "Il seed di Bea deve produrre sia schivate sia colpi validi.")
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
			_expect_float_near(passive.resolve_incoming_damage(20.0), 17.0, "Aleo deve ridurre il danno del 15%.")
		&"lollo":
			_expect_float_near(player.get_character_move_speed_multiplier(), 1.1, "Lollo deve avere +10% movimento.")
			_expect_float_near(weapon.get_character_fire_rate_multiplier(), 1.15, "Lollo deve avere +15% frequenza.")
		&"migi":
			_expect(player.take_contact_damage(75.0), "Migi deve attraversare la soglia scudo.")
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
			_expect(effect is LightningStorm, "Zat deve creare la Tempesta di Fulmini.")
			_expect(enemy.get_health_component().health_current < initial_health, "Il primo fulmine deve colpire subito.")
		&"alea":
			_expect(effect is AbilityAreaEffect, "Alea deve creare l'area di Piroetta.")
			_expect(enemy.get_health_component().health_current < initial_health, "La Piroetta deve colpire subito.")
		&"aleo":
			_expect(effect is AbilityAreaEffect, "Aleo deve creare la Colata di Cemento.")
			_expect_float_near(enemy.get_speed_multiplier(), 0.5, "Il cemento deve rallentare del 50%.")
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
			_expect_float_near(initial_health, 38.0, "Marghe deve ridurre del 5% la salute dei nemici base.")
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
	if effect is LightningStorm:
		return float((effect as LightningStorm).get_strikes_remaining())
	if effect is AbilityAreaEffect:
		return (effect as AbilityAreaEffect).get_duration_remaining()
	if effect is IllusionDecoy:
		return (effect as IllusionDecoy).get_duration_remaining()
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
