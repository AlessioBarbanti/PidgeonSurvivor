extends SceneTree

## B45 — Identità dipendenti dai nemici: Bea, Migi, Magno.
##
## Verifica che lo Scarto Istintivo di Bea annulli il primo colpo eleggibile
## rispettando cooldown e i-frame (e che un input degenere non sposti il
## Player), che il guscio a cariche di Migi blocchi colpi interi e si
## ricarichi nel tempo dichiarato, che Rallentamento Zen assorba i proiettili
## ostili senza toccare quelli alleati, e che lo slancio di Magno si
## accumuli/decada secondo le regole dichiarate scalando l'Onda d'Urto
## Tellurica.

const MOVEMENT_SLICE_SCENE := preload("res://scenes/game/movement_slice.tscn")
const BOSS_PROJECTILE_SCENE := preload("res://scenes/combat/boss_projectile.tscn")
const PROJECTILE_SCENE := preload("res://scenes/combat/projectile.tscn")
const INITIAL_VIEWPORT_SIZE := Vector2i(1280, 720)
const FLOAT_TOLERANCE := 0.001

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	paused = false
	root.content_scale_size = INITIAL_VIEWPORT_SIZE
	root.size = INITIAL_VIEWPORT_SIZE
	await process_frame
	await _validate_bea_instinctive_dodge()
	await _validate_migi_shell_charges()
	await _validate_migi_zone_absorbs_projectiles()
	await _validate_magno_momentum()
	await _finish()


func _validate_bea_instinctive_dodge() -> void:
	var context := await _build_context()
	if context.is_empty():
		return
	var controller: RunController = context["controller"]
	var registry: FriendRegistry = context["registry"]
	var player: Player = context["player"]
	var passive: FriendPassiveController = context["passive"]
	var movement_slice: Control = context["slice"]

	var bea := registry.resolve_definition(&"bea")
	_expect(bea != null, "Il profilo Bea deve esistere.")
	if bea == null:
		movement_slice.queue_free()
		await process_frame
		return
	player.set_friend_definition(bea)
	_expect(passive.equip_definition(bea), "La passiva deve accettare Bea.")

	var cooldown := bea.get_passive_float(&"dodge_cooldown", 9.0, 0.001)
	_expect(cooldown > 0.0, "Bea deve dichiarare un cooldown per lo Scarto Istintivo.")
	_expect(
		passive.get_bea_dodge_cooldown_remaining() <= 0.0,
		"Lo Scarto Istintivo deve partire pronto a inizio run."
	)

	_expect_float_near(
		passive.resolve_incoming_damage(20.0),
		0.0,
		"Il primo colpo eleggibile deve essere annullato."
	)
	_expect(
		player.get_health_component().is_invulnerable(),
		"Lo Scarto Istintivo deve concedere un i-frame anche quando il colpo annullato non passa da take_damage()."
	)
	_expect(
		passive.get_bea_dodge_cooldown_remaining() > 0.0,
		"Lo scarto deve avviare il proprio cooldown."
	)
	_expect_float_near(
		passive.resolve_incoming_damage(20.0),
		20.0,
		"Durante il cooldown il colpo successivo deve passare, senza salvataggi concatenati."
	)

	passive._process(cooldown)
	_expect(
		passive.get_bea_dodge_cooldown_remaining() <= 0.0,
		"Il cooldown deve esaurirsi dopo l'attesa dichiarata."
	)
	_expect_float_near(
		passive.resolve_incoming_damage(20.0),
		0.0,
		"A cooldown esaurito lo Scarto Istintivo deve annullare di nuovo il colpo."
	)

	# Fallback senza destinazione sicura: un input degenere (nessuna
	# direzione) deve essere rifiutato dal metodo pubblico che lo scarto usa
	# per spostare Bea, senza muoverla.
	var origin := player.global_position
	_expect(
		not player.try_shove_to_safe_position(Vector2.ZERO, 90.0),
		"Uno scarto senza direzione valida non deve muovere il Player."
	)
	_expect_float_near(
		player.global_position.distance_to(origin),
		0.0,
		"Il fallback senza destinazione sicura non deve spostare il Player."
	)

	controller.prepare_restart()
	paused = false
	movement_slice.queue_free()
	await process_frame


func _validate_migi_shell_charges() -> void:
	var context := await _build_context()
	if context.is_empty():
		return
	var controller: RunController = context["controller"]
	var registry: FriendRegistry = context["registry"]
	var player: Player = context["player"]
	var passive: FriendPassiveController = context["passive"]
	var movement_slice: Control = context["slice"]

	var migi := registry.resolve_definition(&"migi")
	_expect(migi != null, "Il profilo Migi deve esistere.")
	if migi == null:
		movement_slice.queue_free()
		await process_frame
		return
	player.set_friend_definition(migi)
	_expect(passive.equip_definition(migi), "La passiva deve accettare Migi.")

	var charge_max := migi.get_passive_int(&"shell_charge_max", 2, 0)
	var regen_seconds := migi.get_passive_float(&"shell_charge_regen_seconds", 12.0, 0.001)
	_expect(charge_max > 0, "Migi deve dichiarare almeno una carica di guscio.")
	_expect(
		passive.get_migi_shell_charges() == charge_max,
		"Il guscio piccolo deve partire carico a inizio run."
	)
	_expect(
		player.get_passive_state_tint() == FriendPassiveController.TINT_MIGI_SHELL_READY,
		"Il tell del guscio pronto deve essere attivo con cariche disponibili."
	)

	for _charge_index in charge_max:
		_expect(
			not player.take_contact_damage(5.0),
			"Ogni carica del guscio deve annullare un colpo intero."
		)
	_expect(
		passive.get_migi_shell_charges() == 0,
		"Le cariche devono esaurirsi dopo l'uso."
	)
	_expect(
		player.get_passive_state_tint() != FriendPassiveController.TINT_MIGI_SHELL_READY,
		"Senza cariche il tell del guscio pronto deve spegnersi."
	)
	_expect(
		player.take_contact_damage(5.0),
		"Senza cariche disponibili il colpo deve passare."
	)

	passive._process(regen_seconds)
	_expect(
		passive.get_migi_shell_charges() == 1,
		"Una carica deve rigenerarsi dopo il tempo dichiarato."
	)

	controller.prepare_restart()
	controller.start_run(4711)
	player.set_friend_definition(migi)
	passive.equip_definition(migi)
	_expect(
		passive.get_migi_shell_charges() == charge_max,
		"Il restart deve riportare il guscio a pieno carico, senza residui fra run."
	)

	controller.prepare_restart()
	paused = false
	movement_slice.queue_free()
	await process_frame


func _validate_migi_zone_absorbs_projectiles() -> void:
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
	_expect(ability != null and effects != null, "Servono controller e registry delle attive.")
	if ability == null or effects == null:
		movement_slice.queue_free()
		await process_frame
		return

	var migi := registry.resolve_definition(&"migi")
	if migi == null:
		movement_slice.queue_free()
		await process_frame
		return
	player.set_friend_definition(migi)
	passive.equip_definition(migi)
	var zen := effects.resolve_definition(migi.active_ability_id)
	_expect(zen != null, "L'attiva di Migi deve essere risolvibile.")
	if zen == null:
		movement_slice.queue_free()
		await process_frame
		return
	_expect(ability.equip_definition(zen), "Il controller deve equipaggiare Rallentamento Zen.")
	_expect(ability.try_activate(), "Rallentamento Zen deve essere eseguibile.")

	var area: AbilityAreaEffect = null
	for effect in effects.get_active_effects():
		if effect is AbilityAreaEffect:
			area = effect as AbilityAreaEffect
	_expect(area != null, "Rallentamento Zen deve creare un AbilityAreaEffect.")
	if area == null:
		movement_slice.queue_free()
		await process_frame
		return
	_expect(
		area.get_mode() == AbilityAreaEffect.AreaMode.FOLLOWING_SLOW_ABSORB,
		"La zona di Migi deve usare il modo che assorbe anche i proiettili."
	)

	# I proiettili alleati non entrano mai nel gruppo che la zona interroga:
	# e' una garanzia architetturale, non solo un test a runtime.
	var ally_projectile := PROJECTILE_SCENE.instantiate() as Projectile
	movement_slice.get_projectile_parent().add_child(ally_projectile)
	_expect(
		not ally_projectile.is_in_group(&"enemy_projectiles"),
		"I proiettili alleati non devono mai entrare nel gruppo assorbito dalla zona di Migi."
	)
	ally_projectile.queue_free()

	var hostile := BOSS_PROJECTILE_SCENE.instantiate() as BossProjectile
	movement_slice.get_boss_projectile_parent().add_child(hostile)
	_expect(
		hostile.initialize(Vector2.RIGHT, 10.0, 0.0, 5.0, 8.0, controller, player),
		"Il proiettile ostile fixture deve inizializzarsi."
	)
	hostile.global_position = player.global_position
	_expect(not hostile.is_spent(), "Il proiettile ostile deve nascere attivo per essere un test valido.")

	area._process(0.0)
	await process_frame
	_expect(
		not is_instance_valid(hostile) or hostile.is_spent(),
		"La zona di Migi deve assorbire il proiettile ostile che entra nel raggio."
	)

	controller.prepare_restart()
	paused = false
	movement_slice.queue_free()
	await process_frame


func _validate_magno_momentum() -> void:
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
	_expect(magno != null, "Il profilo Magno deve esistere.")
	if magno == null:
		movement_slice.queue_free()
		await process_frame
		return
	player.set_friend_definition(magno)
	_expect(passive.equip_definition(magno), "La passiva deve accettare Magno.")

	_expect_float_near(
		player.get_momentum_ratio(),
		0.0,
		"Lo slancio deve partire azzerato a inizio run."
	)

	player.set_movement_input(Vector2.RIGHT)
	for _tick_index in 20:
		player._advance_momentum(0.1)
	_expect(
		player.get_momentum_ratio() > 0.9,
		"Muoversi a lungo in linea retta deve quasi saturare lo slancio."
	)

	player.set_movement_input(Vector2.UP)
	player._advance_momentum(0.1)
	_expect(
		player.get_momentum_ratio() < 0.9,
		"Cambiare bruscamente direzione deve far decadere lo slancio."
	)

	player.clear_movement_input()
	for _decay_index in 20:
		player._advance_momentum(0.1)
	_expect_float_near(
		player.get_momentum_ratio(),
		0.0,
		"Fermarsi deve azzerare completamente lo slancio."
	)

	# Lo slancio pieno scala danno/knockback dell'Onda d'Urto Tellurica.
	player.set_movement_input(Vector2.RIGHT)
	for _tick_index in 20:
		player._advance_momentum(0.1)
	var earthquake := effects.resolve_definition(magno.active_ability_id)
	_expect(earthquake != null, "L'Onda d'Urto Tellurica deve essere risolvibile.")
	if earthquake == null:
		movement_slice.queue_free()
		await process_frame
		return
	_expect(
		ability.equip_definition(earthquake),
		"Il controller deve equipaggiare l'Onda d'Urto Tellurica."
	)
	var enemy := spawner.try_spawn_enemy()
	_expect(enemy != null, "Serve un bersaglio fixture per l'Onda d'Urto Tellurica.")
	if enemy == null:
		movement_slice.queue_free()
		await process_frame
		return
	enemy.set_physics_process(false)
	enemy.global_position = player.global_position + Vector2(60.0, 0.0)
	var enemy_health := enemy.get_health_component()
	enemy_health.set_health_max(500.0)
	enemy_health.reset_to_max()
	_expect(
		ability.try_activate(),
		"L'Onda d'Urto Tellurica deve essere eseguibile con slancio pieno."
	)
	var full_momentum_damage := 500.0 - enemy_health.health_current
	_expect(
		full_momentum_damage > earthquake.damage,
		"A slancio pieno l'onda deve infliggere piu' del danno dichiarato al rank equipaggiato."
	)

	controller.prepare_restart()
	paused = false
	movement_slice.queue_free()
	await process_frame


func _build_context() -> Dictionary:
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
		_expect(false, "La scena di run deve esporre le dipendenze B45.")
		movement_slice.queue_free()
		await process_frame
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
		print("B45_ROLE_IDENTITY_SMOKE_OK")
		quit(0)
		return
	for failure in _failures:
		printerr(failure)
	printerr("B45_ROLE_IDENTITY_SMOKE_FAIL count=%d" % _failures.size())
	quit(1)
