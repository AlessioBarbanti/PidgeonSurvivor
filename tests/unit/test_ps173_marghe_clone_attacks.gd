extends GutGameplayTest

## PS-173 — Il clone di Marghe (Reggeton time!) spara ai nemici vicini.
##
## Verifica che l'illusione infligga danno periodico al nemico vivo piu'
## vicino fin dal rango 1 (non solo al rango massimo), che danno/cadenza
## crescano di rango in rango, che il colpo riusi la pipeline Projectile
## esistente (stessa Hurtbox dei colpi del Player, non un canale di danno
## parallelo) senza toccare WeaponController, e che smetta di sparare a
## scadenza naturale senza lasciare proiettili orfani dopo
## clear_active_effects().

const MARGHE_ID := &"marghe_shadow_deception"


func test_clone_attacks_nearest_enemy_from_rank_one() -> void:
	var context := await _build_context()
	if context.is_empty():
		return
	var abilities: AbilityEffectRegistry = context["abilities"]
	var player: Player = context["player"]
	var enemy: BaseEnemy = context["enemy"]
	var controller: RunController = context["controller"]
	var weapon: WeaponController = context["weapon"]

	var rank_one := _resolve_rank(abilities, 1)
	assert_not_null(rank_one, "Il rango 1 di Reggeton time! deve essere risolvibile.")
	if rank_one == null:
		return

	var base_weapon_damage := weapon.get_effective_damage()
	var illusion := abilities.execute_effect(rank_one, player) as IllusionDecoy
	assert_not_null(illusion, "Reggeton time! deve generare il clone.")
	if illusion == null:
		return
	illusion.global_position = enemy.global_position + Vector2(40.0, 0.0)

	var health_before := enemy.get_health_component().health_current
	illusion._process(1.6)
	var projectile := _latest_tracked_projectile(abilities)
	assert_not_null(projectile, "Il clone deve sparare un Projectile al primo intervallo (rango 1: 1,6s).")
	if projectile == null:
		return
	assert_almost_eq(
		projectile.damage, 2.0, FLOAT_TOLERANCE,
		"Il rango 1 deve infliggere il danno dichiarato nei dati (2,0)."
	)
	assert_true(
		projectile.damage < base_weapon_damage,
		"PS-173: il clone non deve fare gli stessi danni dell'arma di Marghe, solo un aiuto minore."
	)

	projectile.set_physics_process(false)
	assert_true(projectile.try_hit(enemy), "Il colpo del clone deve applicarsi al nemico piu' vicino.")
	assert_true(
		enemy.get_health_component().health_current < health_before,
		"Il colpo del clone deve infliggere danno reale, non solo un evento senza effetto."
	)
	assert_almost_eq(
		weapon.get_effective_damage(), base_weapon_damage, FLOAT_TOLERANCE,
		"PS-173: l'attacco del clone non deve toccare WeaponController."
	)

	controller.prepare_restart()


## Rango 5 deve sparare piu' spesso e piu' forte del rango 1: nessuno dei due
## assi resta piatto lungo la curva (criterio "monotono").
func test_damage_and_cadence_grow_from_rank_one_to_five() -> void:
	var context := await _build_context()
	if context.is_empty():
		return
	var abilities: AbilityEffectRegistry = context["abilities"]
	var player: Player = context["player"]
	var controller: RunController = context["controller"]

	var rank_one := _resolve_rank(abilities, 1)
	var rank_five := _resolve_rank(abilities, 5)
	assert_true(rank_one != null and rank_five != null, "I ranghi 1 e 5 devono essere risolvibili.")
	if rank_one == null or rank_five == null:
		return

	var damage_one := rank_one.get_effect_float(&"clone_attack_damage", 0.0, 0.0)
	var interval_one := rank_one.get_effect_float(&"clone_attack_interval", 0.0, 0.0)
	var damage_five := rank_five.get_effect_float(&"clone_attack_damage", 0.0, 0.0)
	var interval_five := rank_five.get_effect_float(&"clone_attack_interval", 0.0, 0.0)

	assert_true(damage_five > damage_one, "Il danno per colpo deve crescere dal rango 1 al 5.")
	assert_true(interval_five < interval_one, "La cadenza deve accelerare (intervallo piu' corto) dal rango 1 al 5.")

	var illusion := abilities.execute_effect(rank_five, player) as IllusionDecoy
	assert_not_null(illusion, "Il rango 5 deve poter generare il clone.")
	if illusion == null:
		return
	illusion.global_position = player.global_position + Vector2(200.0, 0.0)
	controller.prepare_restart()


## Alla scadenza naturale il clone smette di attaccare; clear_active_effects()
## ripulisce sia il clone sia ogni suo proiettile ancora in volo, senza
## lasciare nulla orfano nella scena.
func test_attacks_stop_at_expiry_and_cleanup_leaves_no_orphans() -> void:
	var context := await _build_context()
	if context.is_empty():
		return
	var abilities: AbilityEffectRegistry = context["abilities"]
	var player: Player = context["player"]
	var enemy: BaseEnemy = context["enemy"]
	var controller: RunController = context["controller"]

	var rank_one := _resolve_rank(abilities, 1)
	if rank_one == null:
		return
	var illusion := abilities.execute_effect(rank_one, player) as IllusionDecoy
	assert_not_null(illusion, "Reggeton time! deve generare il clone.")
	if illusion == null:
		return
	illusion.global_position = enemy.global_position + Vector2(40.0, 0.0)

	illusion._process(1.6)
	assert_not_null(_latest_tracked_projectile(abilities), "Il primo colpo deve produrre un Projectile tracciato.")

	# Rango 1: duration_seconds 3.0. Oltre quella soglia il clone deve finire
	# da solo, senza piu' sparare.
	illusion._process(3.0)
	assert_true(illusion.get_duration_remaining() <= 0.0, "Il clone deve esaurire la propria durata.")

	abilities.clear_active_effects()
	assert_eq(abilities.get_active_effect_count(), 0, "clear_active_effects() deve rimuovere clone e proiettili tracciati.")

	controller.prepare_restart()
	print("PS173_MARGHE_CLONE_ATTACKS_SMOKE_OK")


func _resolve_rank(abilities: AbilityEffectRegistry, rank: int) -> AbilityDefinition:
	var definition := abilities.resolve_definition(MARGHE_ID)
	if definition == null:
		return null
	return definition.resolve_rank(rank)


func _latest_tracked_projectile(abilities: AbilityEffectRegistry) -> Projectile:
	var effects := abilities.get_active_effects()
	for index in range(effects.size() - 1, -1, -1):
		if effects[index] is Projectile:
			return effects[index] as Projectile
	return null


func _build_context() -> Dictionary:
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_run_controller() as RunController
	var abilities := movement_slice.get_ability_effect_registry() as AbilityEffectRegistry
	var targeting := movement_slice.get_targeting_system() as TargetingSystem
	var player := movement_slice.get_player() as Player
	var weapon := movement_slice.get_weapon_controller() as WeaponController
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	if (
		controller == null
		or abilities == null
		or targeting == null
		or player == null
		or weapon == null
		or spawner == null
	):
		assert_true(false, "PS-173 richiede RunController, AbilityEffectRegistry, TargetingSystem, Player, WeaponController e EnemySpawner.")
		return {}

	controller.set_process(false)
	player.set_physics_process(false)
	weapon.set_process(false)
	spawner.set_process(false)

	spawner.reset_for_run(9173)
	spawner._process(spawner.spawn_profile.initial_spawn_delay)
	assert_eq(spawner.get_alive_count(), 1, "La fixture deve produrre un nemico bersaglio.")
	if spawner.get_alive_count() != 1:
		return {}
	var enemy := spawner.get_spawned_enemies()[0]
	enemy.set_physics_process(false)
	enemy.global_position = player.global_position + Vector2(240.0, 0.0)

	return {
		"controller": controller,
		"abilities": abilities,
		"targeting": targeting,
		"player": player,
		"weapon": weapon,
		"enemy": enemy,
	}
