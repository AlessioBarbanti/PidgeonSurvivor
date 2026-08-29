extends GutGameplayTest

const COOLDOWN_FLOAT_TOLERANCE := 0.02


func test_ability_button_cooldown_visuals_and_restart() -> void:
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_run_controller() as RunController
	var ability := movement_slice.get_ability_controller() as AbilityController
	var hud := movement_slice.get_hud() as GameHud
	var button: TouchAbilityButton
	if hud != null:
		button = hud.get_active_ability_button()

	assert_not_null(controller, "B18K richiede RunController.")
	assert_not_null(ability, "B18K richiede AbilityController.")
	assert_not_null(hud, "B18K richiede GameHud.")
	assert_not_null(button, "B18K richiede TouchAbilityButton.")
	if controller == null or ability == null or hud == null or button == null:
		return

	controller.set_process(false)
	ability.set_process(false)
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	if spawner != null:
		spawner.set_process(false)
	var player := movement_slice.get_node_or_null("World/Player") as Player
	if player != null:
		player.set_physics_process(false)
	var weapon := movement_slice.get_weapon_controller() as WeaponController
	if weapon != null:
		weapon.set_process(false)

	var definition := ability.get_definition()
	assert_not_null(definition, "Il pulsante B18K richiede una definizione equipaggiata.")
	if definition != null:
		assert_eq(
			button.get_ability_icon(), definition.icon, "L'icona equipaggiata deve essere la superficie del pulsante."
		)
	assert_true(
		button.size.x >= TouchAbilityButton.BASE_TARGET_SIZE and button.size.y >= TouchAbilityButton.BASE_TARGET_SIZE,
		"Il target touch B31 deve misurare almeno la nuova taglia base raddoppiata."
	)
	var ability_rect := hud.get_ability_panel_rect()
	var button_rect := hud.get_active_ability_button_rect()
	assert_rect_near(
		button_rect, ability_rect, "B18K deve lasciare soltanto l'icona senza card esterna.", COOLDOWN_FLOAT_TOLERANCE
	)
	assert_true(button.text.is_empty(), "Il pulsante icona non deve mostrare un nome o una label.")
	assert_true(
		button.get_theme_stylebox("normal") is StyleBoxEmpty, "Il pulsante icona non deve avere un rettangolo di sfondo."
	)
	assert_null(
		hud.find_child("AbilityNameLabel", true, false), "Il nome dell'abilita non deve esistere nel layout HUD."
	)
	assert_false(button.disabled, "Il pulsante deve partire attivabile in RUNNING.")
	assert_true(button.is_ready_visual(), "Lo stato pronto deve mostrare l'anello attivabile.")
	assert_false(button.has_circular_cooldown(), "Da pronta la maschera circolare deve sparire.")
	assert_true(button.get_cooldown_seconds_text().is_empty(), "Da pronta il timer centrale deve sparire.")

	button.pressed.emit()
	assert_true(ability.get_cooldown_remaining() > 0.0, "Il pulsante icona deve attivare l'abilita.")
	assert_true(button.disabled, "Durante il cooldown il pulsante deve essere disabilitato.")
	assert_true(button.has_circular_cooldown(), "Il cooldown deve mostrare la maschera circolare.")
	assert_eq(
		button.get_cooldown_seconds_text(),
		str(int(ceil(ability.get_cooldown_total()))),
		"Il centro deve mostrare i secondi residui arrotondati per eccesso."
	)
	assert_almost_eq(button.get_cooldown_fraction(), 1.0, COOLDOWN_FLOAT_TOLERANCE, "La maschera deve partire piena.")

	var half_cooldown := ability.get_cooldown_total() * 0.5
	ability._process(half_cooldown)
	assert_almost_eq(
		button.get_cooldown_fraction(), 0.5, COOLDOWN_FLOAT_TOLERANCE, "La maschera circolare deve seguire il tempo gameplay."
	)
	var paused_remaining := ability.get_cooldown_remaining()
	assert_true(controller.request_manual_pause(), "La fixture B18K deve entrare in pausa.")
	ability._process(2.0)
	assert_almost_eq(
		ability.get_cooldown_remaining(), paused_remaining, COOLDOWN_FLOAT_TOLERANCE, "La pausa deve congelare cooldown e maschera."
	)
	assert_true(button.disabled, "La pausa deve mantenere il pulsante disabilitato.")
	assert_true(controller.resume_run(), "La fixture B18K deve riprendere la run.")
	ability._process(paused_remaining)
	assert_true(ability.is_cooldown_ready(), "Il cooldown deve tornare pronto.")
	assert_false(button.disabled, "A cooldown concluso il pulsante deve riattivarsi.")
	assert_true(button.is_ready_visual(), "La prontezza deve tornare visibile.")
	assert_false(button.has_circular_cooldown(), "La maschera deve sparire a cooldown concluso.")
	assert_true(button.get_cooldown_seconds_text().is_empty(), "Il timer centrale deve sparire a zero.")

	button.pressed.emit()
	assert_true(button.has_circular_cooldown(), "La seconda attivazione deve riaprire il cooldown.")
	assert_true(controller.request_defeat(), "La fixture B18K deve raggiungere un terminale.")
	assert_true(movement_slice.restart_run(1811), "Il restart B18K deve riuscire.")
	assert_false(button.has_circular_cooldown(), "Il restart deve eliminare la maschera residua.")
	assert_true(button.get_cooldown_seconds_text().is_empty(), "Il restart deve eliminare il timer residuo.")
	assert_true(button.is_ready_visual(), "La nuova run deve ripartire pronta.")
