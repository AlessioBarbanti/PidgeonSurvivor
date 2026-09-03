extends GutGameplayTest

## B45 — Identità dipendenti dai nemici: Bea, Migi, Magno.
##
## Verifica che il Sesto Senso Equino di Bea annulli il primo colpo eleggibile
## rispettando cooldown e i-frame (e che un input degenere non sposti il
## Player), che il guscio a cariche di Migi blocchi colpi interi e si
## ricarichi nel tempo dichiarato, che Rallentamento Zen assorba i proiettili
## ostili senza toccare quelli alleati, e che lo slancio di Magno si
## accumuli/decada secondo le regole dichiarate scalando l'Onda d'Urto
## Tellurica.

const BOSS_PROJECTILE_SCENE := preload("res://scenes/combat/boss_projectile.tscn")
const PROJECTILE_SCENE := preload("res://scenes/combat/projectile.tscn")


func test_bea_instinctive_dodge() -> void:
	var context := await _build_context()
	if context.is_empty():
		return
	var controller: RunController = context["controller"]
	var registry: FriendRegistry = context["registry"]
	var player: Player = context["player"]
	var passive: FriendPassiveController = context["passive"]

	var bea := registry.resolve_definition(&"bea")
	assert_true(bea != null, "Il profilo Bea deve esistere.")
	if bea == null:
		return
	player.set_friend_definition(bea)
	assert_true(passive.equip_definition(bea), "La passiva deve accettare Bea.")

	var cooldown := bea.get_passive_float(&"dodge_cooldown", 9.0, 0.001)
	assert_true(cooldown > 0.0, "Bea deve dichiarare un cooldown per il Sesto Senso Equino.")
	assert_true(
		passive.get_bea_dodge_cooldown_remaining() <= 0.0, "Il Sesto Senso Equino deve partire pronto a inizio run."
	)

	assert_almost_eq(
		passive.resolve_incoming_damage(20.0), 0.0, FLOAT_TOLERANCE, "Il primo colpo eleggibile deve essere annullato."
	)
	assert_true(
		player.get_health_component().is_invulnerable(),
		"Il Sesto Senso Equino deve concedere un i-frame anche quando il colpo annullato non passa da take_damage()."
	)
	assert_true(passive.get_bea_dodge_cooldown_remaining() > 0.0, "Lo scarto deve avviare il proprio cooldown.")
	assert_almost_eq(
		passive.resolve_incoming_damage(20.0), 20.0, FLOAT_TOLERANCE,
		"Durante il cooldown il colpo successivo deve passare, senza salvataggi concatenati."
	)

	passive._process(cooldown)
	assert_true(passive.get_bea_dodge_cooldown_remaining() <= 0.0, "Il cooldown deve esaurirsi dopo l'attesa dichiarata.")
	assert_almost_eq(
		passive.resolve_incoming_damage(20.0), 0.0, FLOAT_TOLERANCE,
		"A cooldown esaurito il Sesto Senso Equino deve annullare di nuovo il colpo."
	)

	# Fallback senza destinazione sicura: un input degenere (nessuna
	# direzione) deve essere rifiutato dal metodo pubblico che lo scarto usa
	# per spostare Bea, senza muoverla.
	var origin := player.global_position
	assert_true(
		not player.try_shove_to_safe_position(Vector2.ZERO, 90.0), "Uno scarto senza direzione valida non deve muovere il Player."
	)
	assert_almost_eq(
		player.global_position.distance_to(origin), 0.0, FLOAT_TOLERANCE,
		"Il fallback senza destinazione sicura non deve spostare il Player."
	)

	controller.prepare_restart()


func test_migi_shell_charges() -> void:
	var context := await _build_context()
	if context.is_empty():
		return
	var controller: RunController = context["controller"]
	var registry: FriendRegistry = context["registry"]
	var player: Player = context["player"]
	var passive: FriendPassiveController = context["passive"]

	var migi := registry.resolve_definition(&"migi")
	assert_true(migi != null, "Il profilo Migi deve esistere.")
	if migi == null:
		return
	player.set_friend_definition(migi)
	assert_true(passive.equip_definition(migi), "La passiva deve accettare Migi.")

	var charge_max := migi.get_passive_int(&"shell_charge_max", 2, 0)
	var regen_seconds := migi.get_passive_float(&"shell_charge_regen_seconds", 12.0, 0.001)
	assert_true(charge_max > 0, "Migi deve dichiarare almeno una carica di guscio.")
	assert_true(passive.get_migi_shell_charges() == charge_max, "Il guscio piccolo deve partire carico a inizio run.")
	assert_true(
		player.get_passive_state_tell_color() == FriendPassiveController.TELL_MIGI_SHELL_READY,
		"Il tell del guscio pronto deve essere attivo con cariche disponibili."
	)

	for _charge_index in charge_max:
		assert_true(not player.take_contact_damage(5.0), "Ogni carica del guscio deve annullare un colpo intero.")
	assert_true(passive.get_migi_shell_charges() == 0, "Le cariche devono esaurirsi dopo l'uso.")
	assert_true(
		player.get_passive_state_tell_color() != FriendPassiveController.TELL_MIGI_SHELL_READY,
		"Senza cariche il tell del guscio pronto deve spegnersi."
	)
	assert_true(player.take_contact_damage(5.0), "Senza cariche disponibili il colpo deve passare.")

	passive._process(regen_seconds)
	assert_true(passive.get_migi_shell_charges() == 1, "Una carica deve rigenerarsi dopo il tempo dichiarato.")

	controller.prepare_restart()
	controller.start_run(4711)
	player.set_friend_definition(migi)
	passive.equip_definition(migi)
	assert_true(
		passive.get_migi_shell_charges() == charge_max, "Il restart deve riportare il guscio a pieno carico, senza residui fra run."
	)

	controller.prepare_restart()


func test_migi_zone_absorbs_projectiles() -> void:
	var context := await _build_context()
	if context.is_empty():
		return
	var controller: RunController = context["controller"]
	var registry: FriendRegistry = context["registry"]
	var player: Player = context["player"]
	var passive: FriendPassiveController = context["passive"]
	var movement_slice: Control = context["slice"]
	var ability := movement_slice.get_ability_controller() as AbilityController
	var effects := movement_slice.get_ability_effect_registry() as AbilityEffectRegistry
	assert_true(ability != null and effects != null, "Servono controller e registry delle attive.")
	if ability == null or effects == null:
		return

	var migi := registry.resolve_definition(&"migi")
	if migi == null:
		return
	player.set_friend_definition(migi)
	passive.equip_definition(migi)
	var zen := effects.resolve_definition(migi.active_ability_id)
	assert_true(zen != null, "L'attiva di Migi deve essere risolvibile.")
	if zen == null:
		return
	assert_true(ability.equip_definition(zen), "Il controller deve equipaggiare Rallentamento Zen.")
	assert_true(ability.try_activate(), "Rallentamento Zen deve essere eseguibile.")

	var area: AbilityAreaEffect = null
	for effect in effects.get_active_effects():
		if effect is AbilityAreaEffect:
			area = effect as AbilityAreaEffect
	assert_true(area != null, "Rallentamento Zen deve creare un AbilityAreaEffect.")
	if area == null:
		return
	assert_true(
		area.get_mode() == AbilityAreaEffect.AreaMode.FOLLOWING_SLOW_ABSORB,
		"La zona di Migi deve usare il modo che assorbe anche i proiettili."
	)

	# I proiettili alleati non entrano mai nel gruppo che la zona interroga:
	# e' una garanzia architetturale, non solo un test a runtime.
	var ally_projectile := PROJECTILE_SCENE.instantiate() as Projectile
	movement_slice.get_projectile_parent().add_child(ally_projectile)
	assert_true(
		not ally_projectile.is_in_group(&"enemy_projectiles"),
		"I proiettili alleati non devono mai entrare nel gruppo assorbito dalla zona di Migi."
	)
	ally_projectile.queue_free()

	var hostile := BOSS_PROJECTILE_SCENE.instantiate() as BossProjectile
	movement_slice.get_boss_projectile_parent().add_child(hostile)
	assert_true(
		hostile.initialize(Vector2.RIGHT, 10.0, 0.0, 5.0, 8.0, controller, player), "Il proiettile ostile fixture deve inizializzarsi."
	)
	hostile.global_position = player.global_position
	assert_true(not hostile.is_spent(), "Il proiettile ostile deve nascere attivo per essere un test valido.")

	area._process(0.0)
	await wait_process_frames(1)
	assert_true(
		not is_instance_valid(hostile) or hostile.is_spent(), "La zona di Migi deve assorbire il proiettile ostile che entra nel raggio."
	)

	controller.prepare_restart()


func test_magno_momentum() -> void:
	var context := await _build_context()
	if context.is_empty():
		return
	var controller: RunController = context["controller"]
	var registry: FriendRegistry = context["registry"]
	var player: Player = context["player"]
	var passive: FriendPassiveController = context["passive"]
	var movement_slice: Control = context["slice"]
	var effects := movement_slice.get_ability_effect_registry() as AbilityEffectRegistry
	var ability := movement_slice.get_ability_controller() as AbilityController
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner

	var magno := registry.resolve_definition(&"magno")
	assert_true(magno != null, "Il profilo Magno deve esistere.")
	if magno == null:
		return
	player.set_friend_definition(magno)
	assert_true(passive.equip_definition(magno), "La passiva deve accettare Magno.")

	assert_almost_eq(player.get_momentum_ratio(), 0.0, FLOAT_TOLERANCE, "Lo slancio deve partire azzerato a inizio run.")

	player.set_movement_input(Vector2.RIGHT)
	for _tick_index in 20:
		player._advance_momentum(0.1)
	assert_true(player.get_momentum_ratio() > 0.9, "Muoversi a lungo in linea retta deve quasi saturare lo slancio.")

	player.set_movement_input(Vector2.UP)
	player._advance_momentum(0.1)
	assert_true(player.get_momentum_ratio() < 0.9, "Cambiare bruscamente direzione deve far decadere lo slancio.")

	player.clear_movement_input()
	for _decay_index in 20:
		player._advance_momentum(0.1)
	assert_almost_eq(player.get_momentum_ratio(), 0.0, FLOAT_TOLERANCE, "Fermarsi deve azzerare completamente lo slancio.")

	# Lo slancio pieno scala danno/knockback dell'Onda d'Urto Tellurica.
	player.set_movement_input(Vector2.RIGHT)
	for _tick_index in 20:
		player._advance_momentum(0.1)
	var earthquake := effects.resolve_definition(magno.active_ability_id)
	assert_true(earthquake != null, "L'Onda d'Urto Tellurica deve essere risolvibile.")
	if earthquake == null:
		return
	assert_true(ability.equip_definition(earthquake), "Il controller deve equipaggiare l'Onda d'Urto Tellurica.")
	var enemy := spawner.try_spawn_enemy()
	assert_true(enemy != null, "Serve un bersaglio fixture per l'Onda d'Urto Tellurica.")
	if enemy == null:
		return
	enemy.set_physics_process(false)
	enemy.global_position = player.global_position + Vector2(60.0, 0.0)
	var enemy_health := enemy.get_health_component()
	enemy_health.set_health_max(500.0)
	enemy_health.reset_to_max()
	assert_true(ability.try_activate(), "L'Onda d'Urto Tellurica deve essere eseguibile con slancio pieno.")
	var full_momentum_damage := 500.0 - enemy_health.health_current
	assert_true(
		full_momentum_damage > earthquake.damage, "A slancio pieno l'onda deve infliggere piu' del danno dichiarato al rank equipaggiato."
	)

	controller.prepare_restart()


func _build_context() -> Dictionary:
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_run_controller() as RunController
	var registry := movement_slice.get_friend_registry() as FriendRegistry
	var player := movement_slice.get_player() as Player
	var passive := movement_slice.get_friend_passive_controller() as FriendPassiveController
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	if controller == null or registry == null or player == null or passive == null or spawner == null:
		assert_true(false, "La scena di run deve esporre le dipendenze B45.")
		return {}

	controller.set_process(false)
	spawner.set_process(false)
	player.set_physics_process(false)
	passive.set_process(false)
	controller.start_run(4711)
	return {
		"slice": movement_slice,
		"controller": controller,
		"registry": registry,
		"player": player,
		"passive": passive,
		"spawner": spawner,
	}
