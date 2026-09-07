extends GutGameplayTest

## PS-094: la Specialità di Barb "Bis alla Griglia" introduce un modello a
## cariche multiple sull'abilità attiva (universale, come Ravviva la Brace!).
## Questo smoke verifica: parità bit-per-bit del modello a cooldown singolo
## senza la Specialità, la tabella dei 5 ranghi, la ricarica indipendente
## delle cariche, le 4 attivazioni consecutive a rango 5 pieno e l'azzeramento
## al restart.

const CHARGE_STACKING := preload("res://data/upgrades/specialities/ability_charge_stacking.tres")
const SWIFT_STEPS := preload("res://data/upgrades/swift_steps.tres")
const RAPID_FIRE := preload("res://data/upgrades/rapid_fire.tres")
const WIDE_MAGNET := preload("res://data/upgrades/wide_magnet.tres")
const MEAT_FORK_DAMAGE := preload("res://data/upgrades/meat_fork_damage.tres")

const PS094_TOLERANCE := 0.02
const EXPECTED_CHARGES_BY_RANK := [2, 2, 3, 3, 4]
const EXPECTED_COOLDOWN_MULTIPLIER_BY_RANK := [1.0, 0.5, 0.5, 1.0, 1.0]
const FILLER_IDS: Array[StringName] = [&"swift_steps", &"rapid_fire", &"wide_magnet", &"meat_fork_damage"]


func test_ability_charge_stacking() -> void:
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_run_controller() as RunController
	var experience := movement_slice.get_experience_system() as ExperienceSystem
	var service := movement_slice.get_upgrade_service() as UpgradeService
	var catalog := movement_slice.get_upgrade_registry() as UpgradeRegistry
	var effects := movement_slice.get_upgrade_effect_registry() as UpgradeEffectRegistry
	var player := movement_slice.get_player() as Player
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	var weapon := movement_slice.get_weapon_controller() as WeaponController
	var hud := movement_slice.get_hud() as GameHud

	assert_true(controller != null and experience != null, "PS-094 richiede run e progressione.")
	assert_true(service != null and catalog != null and effects != null, "PS-094 richiede i tre registry upgrade.")
	assert_true(player != null and spawner != null and weapon != null, "PS-094 richiede la scena gameplay composta.")
	assert_not_null(hud, "PS-094 richiede la HUD per verificare il wiring dei pallini di carica.")
	if (
		controller == null
		or experience == null
		or service == null
		or catalog == null
		or effects == null
		or player == null
		or spawner == null
		or weapon == null
		or hud == null
	):
		return

	controller.set_process(false)
	spawner.set_process(false)
	player.set_physics_process(false)
	weapon.set_process(false)
	effects.set_process(false)
	var ability := player.get_ability_controller()
	assert_not_null(ability, "PS-094 richiede l'AbilityController del Player.")
	if ability == null:
		return
	ability.set_process(false)
	var button := hud.get_active_ability_button()
	assert_not_null(button, "PS-094 richiede il pulsante icona dell'abilità.")

	# Senza la Specialità: il modello a cooldown singolo resta bit-per-bit
	# identico a oggi.
	var base_cooldown := ability.get_activation_definition().cooldown_seconds
	assert_eq(ability.get_max_charges(), 1, "Di base deve esistere una sola carica.")
	assert_eq(ability.get_available_charges(), 1, "Di base la carica unica deve partire disponibile.")
	assert_true(ability.try_activate(), "La carica unica deve attivarsi.")
	assert_eq(ability.get_available_charges(), 0, "L'uso deve consumare l'unica carica.")
	assert_false(ability.try_activate(), "Senza cariche extra un secondo uso immediato deve fallire.")
	if button != null:
		assert_true(button.has_circular_cooldown(), "A zero cariche il pulsante deve mostrare il cooldown.")
		assert_false(
			button.is_recharging_extra_capacity(),
			"PS-119: a zero cariche deve restare la maschera piena, non il solo contorno."
		)
	ability._process(base_cooldown + 0.01)
	assert_eq(ability.get_available_charges(), 1, "La ricarica singola deve restituire l'unica carica.")
	assert_true(ability.is_cooldown_ready(), "Dopo la ricarica l'abilità deve tornare pronta.")
	if button != null:
		assert_eq(button.get_max_charges(), 1, "Senza la Specialità il pulsante non deve mostrare pallini extra.")

	catalog.definitions = [CHARGE_STACKING, SWIFT_STEPS, RAPID_FIRE, WIDE_MAGNET, MEAT_FORK_DAMAGE]
	assert_true(catalog.rebuild_registry(), "Il catalogo isolato PS-094 deve essere valido.")
	service.reset_for_run(controller.get_seed())
	assert_true(effects.recalculate_effects(), "Il registry deve accettare Bis alla Griglia.")
	assert_true(effects.has_valid_configuration(), "Le dipendenze PS-094 devono essere complete.")
	assert_eq(
		ability.get_max_charges(), 1, "Il reset di run deve riportare a carica singola prima dello sblocco."
	)

	service.queue_barb_reward()
	var barb_offer := service.get_current_barb_offer_ids()
	assert_true(CHARGE_STACKING.id in barb_offer, "Bis alla Griglia deve comparire nell'offerta Boss isolata.")
	assert_true(service.select_barb_speciality(CHARGE_STACKING.id), "Lo sblocco Boss deve accettare la carta.")
	assert_eq(service.get_rank(CHARGE_STACKING.id), 1, "Lo sblocco deve fermarsi al rango 1.")
	_assert_rank_configuration(ability, base_cooldown, 1)
	if button != null:
		assert_eq(
			button.get_max_charges(), ability.get_max_charges(),
			"Il pulsante deve rispecchiare il tetto di cariche dell'AbilityController."
		)
		assert_eq(
			button.get_available_charges(), ability.get_available_charges(),
			"Il pulsante deve rispecchiare le cariche disponibili dell'AbilityController."
		)

	# Ricarica indipendente: una carica usata a metà ricarica dell'altra non
	# ne blocca ne' anticipa il rilascio.
	assert_true(ability.try_activate(), "La prima carica di rango 1 deve attivarsi.")
	var half_gap := base_cooldown * 0.5
	ability._process(half_gap)
	assert_true(ability.try_activate(), "La seconda carica deve restare indipendente dalla prima.")
	assert_eq(ability.get_available_charges(), 0, "Entrambe le cariche di rango 1 devono risultare consumate.")
	ability._process(half_gap + 0.01)
	assert_eq(
		ability.get_available_charges(), 1,
		"Solo la prima carica (partita prima) deve essere già tornata disponibile."
	)
	assert_true(ability.is_cooldown_ready(), "Con una carica pronta il pulsante deve tornare attivabile.")
	if button != null:
		assert_true(
			button.is_recharging_extra_capacity(),
			"PS-119: con una carica pronta e un'altra in ricarica deve mostrarsi solo il contorno."
		)
		assert_false(
			button.disabled,
			"PS-119: con almeno una carica disponibile il pulsante deve restare premibile."
		)
	ability._process(half_gap)
	assert_eq(ability.get_available_charges(), 2, "Anche la seconda carica deve tornare, senza essere rimasta bloccata.")

	# Percorre i ranghi 2-5 tramite level-up ordinari (PS-077: solo il primo
	# sblocco passa da Barb, i successivi sono normali offerte casuali).
	for target_rank in range(2, 6):
		assert_true(
			_grant_and_select(experience, service, CHARGE_STACKING.id),
			"Bis alla Griglia deve essere selezionabile al rango %d." % target_rank
		)
		assert_eq(service.get_rank(CHARGE_STACKING.id), target_rank, "Il rango deve avanzare una sola volta.")
		ability._process(9999.0)
		_assert_rank_configuration(ability, base_cooldown, target_rank)

	# Rango 5 a cariche piene: 4 attivazioni consecutive senza attesa.
	assert_eq(ability.get_available_charges(), 4, "A rango 5 pieno devono esserci 4 cariche.")
	for activation_index in 4:
		assert_true(
			ability.try_activate(), "L'attivazione consecutiva %d deve riuscire senza attesa." % (activation_index + 1)
		)
	assert_eq(ability.get_available_charges(), 0, "Le 4 attivazioni consecutive devono esaurire le cariche.")
	assert_false(ability.try_activate(), "Una quinta attivazione immediata deve fallire.")

	# Restart: le cariche accumulate e il tetto della Specialità si azzerano.
	assert_true(controller.prepare_restart(), "La fixture deve poter preparare un restart.")
	assert_eq(ability.get_max_charges(), 1, "Il restart deve azzerare il tetto di cariche della Specialità.")
	assert_eq(ability.get_available_charges(), 1, "Il restart deve ripartire con l'unica carica di base disponibile.")

	print("ABILITY_CHARGE_STACKING_SMOKE_OK")


## PS-119: salire di rango (più capacità di cariche) mentre non si è a
## cariche piene apriva una carica "fantasma" senza alcun timer di ricarica
## proprio: le cariche disponibili non potevano mai superare il valore che
## avevano nel momento esatto dello sblocco/rango, per tutto il resto della
## run. Riproduce esattamente lo scenario: consuma una carica, lasciala a
## metà ricarica, sali di rango due volte (una senza variare il tetto, una
## che lo alza), e verifica che la nuova capacità arrivi comunque a piena
## ricarica.
func test_charge_capacity_growth_while_recharging_still_reaches_new_maximum() -> void:
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_run_controller() as RunController
	var experience := movement_slice.get_experience_system() as ExperienceSystem
	var service := movement_slice.get_upgrade_service() as UpgradeService
	var catalog := movement_slice.get_upgrade_registry() as UpgradeRegistry
	var effects := movement_slice.get_upgrade_effect_registry() as UpgradeEffectRegistry
	var player := movement_slice.get_player() as Player
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	var weapon := movement_slice.get_weapon_controller() as WeaponController
	assert_true(
		controller != null and experience != null and service != null and catalog != null
		and effects != null and player != null and spawner != null and weapon != null,
		"PS-119 richiede la scena gameplay composta con i registry upgrade."
	)
	if (
		controller == null
		or experience == null
		or service == null
		or catalog == null
		or effects == null
		or player == null
		or spawner == null
		or weapon == null
	):
		return

	controller.set_process(false)
	spawner.set_process(false)
	player.set_physics_process(false)
	weapon.set_process(false)
	effects.set_process(false)
	var ability := player.get_ability_controller()
	assert_not_null(ability, "PS-119 richiede l'AbilityController del Player.")
	if ability == null:
		return
	ability.set_process(false)

	var base_cooldown := ability.get_activation_definition().cooldown_seconds

	catalog.definitions = [CHARGE_STACKING, SWIFT_STEPS, RAPID_FIRE, WIDE_MAGNET, MEAT_FORK_DAMAGE]
	assert_true(catalog.rebuild_registry(), "Il catalogo isolato PS-119 deve essere valido.")
	service.reset_for_run(controller.get_seed())
	assert_true(effects.recalculate_effects(), "Il registry deve accettare Bis alla Griglia.")

	service.queue_barb_reward()
	var barb_offer := service.get_current_barb_offer_ids()
	assert_true(CHARGE_STACKING.id in barb_offer, "Bis alla Griglia deve comparire nell'offerta Boss isolata.")
	assert_true(service.select_barb_speciality(CHARGE_STACKING.id), "Lo sblocco Boss deve accettare la carta.")
	assert_eq(ability.get_max_charges(), 2, "Il rango 1 deve dare due cariche.")
	ability._process(9999.0)
	assert_eq(ability.get_available_charges(), 2, "La fixture deve poter portare le cariche a piena capacità.")

	# Consuma una carica e lasciala a meta' ricarica, non piena, proprio nel
	# momento in cui si sale di rango.
	assert_true(ability.try_activate(), "La fixture deve poter consumare una carica prima del rango successivo.")
	assert_eq(ability.get_available_charges(), 1, "Il consumo deve lasciare esattamente una carica disponibile.")
	ability._process(base_cooldown * 0.5)

	assert_true(
		_grant_and_select(experience, service, CHARGE_STACKING.id),
		"Bis alla Griglia deve essere selezionabile al rango 2."
	)
	assert_eq(service.get_rank(CHARGE_STACKING.id), 2, "Il rango deve avanzare a 2.")
	assert_eq(ability.get_max_charges(), 2, "Il rango 2 non deve cambiare il tetto di cariche (dati: 2, 2, 3, 3, 4).")
	assert_eq(
		ability.get_available_charges(), 1,
		"Salire di rango senza cambiare il tetto non deve alterare le cariche disponibili."
	)

	assert_true(
		_grant_and_select(experience, service, CHARGE_STACKING.id),
		"Bis alla Griglia deve essere selezionabile al rango 3."
	)
	assert_eq(service.get_rank(CHARGE_STACKING.id), 3, "Il rango deve avanzare a 3.")
	assert_eq(ability.get_max_charges(), 3, "Il rango 3 deve alzare il tetto a tre cariche.")
	assert_eq(
		ability.get_available_charges(), 1,
		"Salire di rango senza essere a cariche piene non deve regalare né sottrarre cariche disponibili."
	)

	# La capacità aggiunta al rango 3 deve avere un proprio timer di ricarica:
	# senza il fix restava bloccata per sempre al valore che aveva al momento
	# del rango, anche aspettando indefinitamente.
	ability._process(9999.0)
	assert_eq(
		ability.get_available_charges(), 3,
		"PS-119: la capacità aggiunta mentre non si era a cariche piene deve comunque ricaricarsi fino al nuovo tetto."
	)

	controller.prepare_restart()
	print("ABILITY_CHARGE_CAPACITY_GROWTH_SMOKE_OK")


func _assert_rank_configuration(ability: AbilityController, base_cooldown: float, rank: int) -> void:
	var rank_index := rank - 1
	assert_eq(
		ability.get_max_charges(), EXPECTED_CHARGES_BY_RANK[rank_index],
		"Il tetto di cariche al rango %d deve seguire la tabella." % rank
	)
	assert_almost_eq(
		ability.get_cooldown_total(),
		base_cooldown * EXPECTED_COOLDOWN_MULTIPLIER_BY_RANK[rank_index],
		PS094_TOLERANCE,
		"La ricarica per carica al rango %d deve seguire il moltiplicatore dati." % rank
	)


func _grant_and_select(
	experience: ExperienceSystem, service: UpgradeService, upgrade_id: StringName
) -> bool:
	for _attempt in 20:
		if not experience.add_experience(experience.experience_required):
			return false
		var offered_ids := service.get_current_offer_ids()
		if offered_ids.is_empty():
			return false
		var selected_id := upgrade_id
		if selected_id not in offered_ids:
			for offered_id in offered_ids:
				if offered_id in FILLER_IDS:
					selected_id = offered_id
					break
		if selected_id not in offered_ids or not service.select_upgrade(selected_id):
			return false
		if selected_id == upgrade_id:
			return true
	return false
