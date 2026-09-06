extends GutGameplayTest

## PS-093 — Cinque nuovi assi di scarto base per personaggio.
##
## Copre i quattro assi moltiplicativi (danno, avidità/XP, raggio pickup,
## riduzione danno subito) sullo stesso pattern a due stadi "character" +
## "upgrade" già maturo su cadenza (B47), e il quinto asse additivo
## (probabilità critica): default neutro, range B47 per i primi quattro,
## composizione corretta con il rispettivo upgrade del catalogo, nessuna
## mutazione dei dati base condivisi dopo reset, e per il critico una
## risoluzione deterministica su RNG seminato dal seed di run (mai
## dall'orologio di sistema), cap rispettato, nessun critico a chance zero.

const FRIEND_IDS: Array[StringName] = [
	&"magno", &"bea", &"zat", &"alea", &"aleo", &"lollo", &"migi", &"marghe",
]


func test_definition_defaults_and_normalization() -> void:
	var definition := FriendDefinition.new()
	for value in [
		definition.get_base_damage_multiplier(),
		definition.get_base_xp_gain_multiplier(),
		definition.get_base_pickup_radius_multiplier(),
		definition.get_base_damage_taken_multiplier(),
	]:
		assert_almost_eq(value, 1.0, FLOAT_TOLERANCE, "Il default dei quattro assi moltiplicativi deve essere neutro.")
	assert_almost_eq(
		definition.get_base_critical_chance_bonus(), 0.0, FLOAT_TOLERANCE, "Il default della probabilità critica deve essere zero."
	)
	assert_false(
		definition.has_extended_base_stat_spread(), "Un profilo senza scarti estesi non deve risultare caratterizzato."
	)

	definition.base_damage_multiplier = 99.0
	definition.base_xp_gain_multiplier = -4.0
	definition.base_pickup_radius_multiplier = NAN
	definition.base_damage_taken_multiplier = 99.0
	definition.base_critical_chance_bonus = NAN
	assert_almost_eq(
		definition.get_base_damage_multiplier(),
		FriendDefinition.MAXIMUM_BASE_STAT_MULTIPLIER,
		FLOAT_TOLERANCE,
		"Uno scarto sopra il massimo deve essere normalizzato."
	)
	assert_almost_eq(
		definition.get_base_xp_gain_multiplier(),
		FriendDefinition.MINIMUM_BASE_STAT_MULTIPLIER,
		FLOAT_TOLERANCE,
		"Uno scarto sotto il minimo deve essere normalizzato."
	)
	assert_almost_eq(
		definition.get_base_pickup_radius_multiplier(), 1.0, FLOAT_TOLERANCE, "Uno scarto non finito deve ricadere sul valore neutro."
	)
	assert_almost_eq(
		definition.get_base_critical_chance_bonus(), 0.0, FLOAT_TOLERANCE, "Un bonus critico non finito deve ricadere su zero, non sul neutro ×1.0."
	)


func test_declared_profiles_stay_in_range() -> void:
	for friend_id in FRIEND_IDS:
		var definition := load("res://data/friends/%s.tres" % friend_id) as FriendDefinition
		assert_not_null(definition, "Profilo mancante: %s." % friend_id)
		if definition == null:
			continue
		for value in [
			definition.get_base_damage_multiplier(),
			definition.get_base_xp_gain_multiplier(),
			definition.get_base_pickup_radius_multiplier(),
			definition.get_base_damage_taken_multiplier(),
		]:
			assert_true(
				(
					value >= FriendDefinition.MINIMUM_BASE_STAT_MULTIPLIER
					and value <= FriendDefinition.MAXIMUM_BASE_STAT_MULTIPLIER
				),
				"%s dichiara uno scarto esteso fuori intervallo." % friend_id
			)
		var critical_bonus := definition.get_base_critical_chance_bonus()
		assert_true(
			critical_bonus >= 0.0 and critical_bonus <= 1.0,
			"%s dichiara un bonus critico fuori intervallo." % friend_id
		)


func test_weapon_damage_composes_character_and_upgrade_stages() -> void:
	var context := await _build_context()
	if context.is_empty():
		return
	var weapon: WeaponController = context["weapon"]
	var controller: RunController = context["controller"]

	weapon.reset_character_stat_multipliers()
	weapon.reset_upgrade_stat_multipliers()
	var base_damage := weapon.get_effective_damage()

	assert_true(
		weapon.set_character_stat_multipliers(1.0, 1.3), "Il moltiplicatore character deve essere accettato."
	)
	assert_almost_eq(
		weapon.get_effective_damage(), base_damage * 1.3, FLOAT_TOLERANCE,
		"Lo stadio character deve comporsi da solo con il danno base."
	)

	assert_true(
		weapon.set_upgrade_stat_multipliers(1.0, 1.15), "Il moltiplicatore upgrade deve essere accettato."
	)
	assert_almost_eq(
		weapon.get_effective_damage(), base_damage * 1.3 * 1.15, FLOAT_TOLERANCE,
		"PS-093: character e upgrade devono comporsi moltiplicativamente, come già per la cadenza."
	)

	weapon.reset_character_stat_multipliers()
	assert_almost_eq(
		weapon.get_effective_damage(), base_damage * 1.15, FLOAT_TOLERANCE,
		"Rimuovere lo stadio character deve lasciare intatto il solo upgrade."
	)

	controller.prepare_restart()


func test_xp_gain_composes_character_and_upgrade_stages() -> void:
	var context := await _build_context()
	if context.is_empty():
		return
	var experience: ExperienceSystem = context["experience"]
	var controller: RunController = context["controller"]

	experience.reset_character_value_multiplier()
	experience.reset_upgrade_value_multiplier()

	assert_true(
		experience.set_character_value_multiplier(1.2), "Il moltiplicatore XP character deve essere accettato."
	)
	assert_true(experience.add_experience(10), "L'esperienza deve poter essere aggiunta.")
	assert_eq(
		experience.experience_current, 12, "PS-093: lo stadio character deve applicarsi anche senza upgrade."
	)

	assert_true(
		experience.set_upgrade_value_multiplier(1.1), "Il moltiplicatore XP upgrade deve essere accettato."
	)
	assert_true(experience.add_experience(10), "L'esperienza deve poter essere aggiunta di nuovo.")
	# 10 * 1.2 * 1.1 = 13.2 -> 13 (il credito frazionario resta in sospeso).
	assert_eq(
		experience.experience_current, 25, "PS-093: character e upgrade devono comporsi moltiplicativamente sull'XP."
	)

	controller.prepare_restart()


func test_pickup_radius_and_damage_taken_character_stage() -> void:
	var context := await _build_context()
	if context.is_empty():
		return
	var player: Player = context["player"]
	var controller: RunController = context["controller"]

	player.reset_character_stat_multipliers()
	player.reset_upgrade_stat_multipliers()
	var base_radius := player.get_base_pickup_radius()

	assert_true(
		player.set_character_stat_multipliers(1.0, 1.25, 1.0, 0.8),
		"Il quartetto di moltiplicatori character deve essere accettato."
	)
	assert_almost_eq(
		player.get_base_pickup_radius(), base_radius * 1.25, FLOAT_TOLERANCE,
		"PS-093: il raggio pickup deve riflettere lo stadio character."
	)

	var health := player.get_health_component()
	health.reset_to_max()
	var before := health.health_current
	assert_true(player.take_contact_damage(10.0), "Il danno di contatto deve applicarsi.")
	assert_almost_eq(
		health.health_current, before - 8.0, FLOAT_TOLERANCE,
		"PS-093: la riduzione danno subito 'character' deve applicarsi anche senza upgrade (10 * 0.8 = 8)."
	)

	health.reset_to_max()
	assert_true(
		player.set_upgrade_stat_multipliers(1.0, 1.0, 1.0, true, 0.9),
		"Il moltiplicatore upgrade di riduzione danno deve essere accettato."
	)
	before = health.health_current
	assert_true(player.take_contact_damage(10.0), "Il danno di contatto deve applicarsi di nuovo.")
	assert_almost_eq(
		health.health_current, before - 7.2, FLOAT_TOLERANCE,
		"PS-093: character (×0.8) e upgrade (×0.9) devono comporsi moltiplicativamente (10 * 0.8 * 0.9 = 7.2)."
	)

	controller.prepare_restart()


func test_critical_strike_chance_and_damage_composition_and_cap() -> void:
	var context := await _build_context()
	if context.is_empty():
		return
	var weapon: WeaponController = context["weapon"]
	var controller: RunController = context["controller"]

	weapon.reset_character_stat_multipliers()
	weapon.reset_upgrade_stat_multipliers()
	assert_almost_eq(
		weapon.get_effective_critical_chance(), 0.0, FLOAT_TOLERANCE, "Senza scarto né carta la chance critica deve essere zero."
	)

	assert_true(
		weapon.set_character_stat_multipliers(1.0, 1.0, 0.10), "Il bonus critico character deve essere accettato."
	)
	assert_almost_eq(
		weapon.get_effective_critical_chance(), 0.10, FLOAT_TOLERANCE,
		"PS-093: lo scarto base del personaggio deve applicarsi da solo, come chance critica."
	)

	assert_true(
		weapon.set_critical_strike_modifiers(0.30, 1.75), "Il bonus critico della carta deve essere accettato."
	)
	assert_almost_eq(
		weapon.get_effective_critical_chance(), WeaponController.MAXIMUM_CRITICAL_CHANCE, FLOAT_TOLERANCE,
		"PS-093: 0.10 + 0.30 supera il cap dichiarato (35%%): il totale deve restare limitato."
	)

	controller.prepare_restart()


func test_critical_strike_never_procs_at_zero_chance() -> void:
	var context := await _build_context()
	if context.is_empty():
		return
	var weapon: WeaponController = context["weapon"]
	var controller: RunController = context["controller"]

	weapon.reset_character_stat_multipliers()
	weapon.reset_upgrade_stat_multipliers()
	var base_damage := weapon.get_effective_damage()
	for _shot_index in range(100):
		assert_almost_eq(
			weapon.resolve_shot_damage(), base_damage, FLOAT_TOLERANCE,
			"A chance zero nessun colpo deve mai risultare critico."
		)
		assert_false(weapon.was_last_shot_critical(), "A chance zero was_last_shot_critical() deve restare falso.")

	controller.prepare_restart()


func test_critical_strike_resolution_is_deterministic_per_seed() -> void:
	var context_a := await _build_context(2026)
	if context_a.is_empty():
		return
	var weapon_a: WeaponController = context_a["weapon"]
	assert_true(weapon_a.set_critical_strike_modifiers(0.30, 1.75), "Il bonus critico deve essere accettato (seed A, prima lettura).")
	var sequence_a: Array[bool] = []
	for _shot_index in range(40):
		weapon_a.resolve_shot_damage()
		sequence_a.append(weapon_a.was_last_shot_critical())
	context_a["controller"].prepare_restart()

	var context_b := await _build_context(2026)
	if context_b.is_empty():
		return
	var weapon_b: WeaponController = context_b["weapon"]
	assert_true(weapon_b.set_critical_strike_modifiers(0.30, 1.75), "Il bonus critico deve essere accettato (seed A, seconda lettura).")
	var sequence_b: Array[bool] = []
	for _shot_index in range(40):
		weapon_b.resolve_shot_damage()
		sequence_b.append(weapon_b.was_last_shot_critical())
	context_b["controller"].prepare_restart()

	assert_eq(
		sequence_a, sequence_b,
		"PS-093: lo stesso seed di run deve produrre la stessa identica sequenza di critici (RNG seminato, non dall'orologio)."
	)
	assert_true(
		sequence_a.count(true) > 0, "Con chance 0.30 su 40 colpi ci si aspetta almeno un critico (precondizione del test)."
	)

	var context_c := await _build_context(4242)
	if context_c.is_empty():
		return
	var weapon_c: WeaponController = context_c["weapon"]
	assert_true(weapon_c.set_critical_strike_modifiers(0.30, 1.75), "Il bonus critico deve essere accettato (seed B).")
	var sequence_c: Array[bool] = []
	for _shot_index in range(40):
		weapon_c.resolve_shot_damage()
		sequence_c.append(weapon_c.was_last_shot_critical())
	context_c["controller"].prepare_restart()

	assert_true(
		sequence_a != sequence_c,
		"PS-093: un seed diverso deve (con probabilità schiacciante) produrre una sequenza diversa."
	)


func test_extended_axes_reset_on_restart_and_character_change() -> void:
	var context := await _build_context()
	if context.is_empty():
		return
	var registry: FriendRegistry = context["registry"]
	var player: Player = context["player"]
	var passive: FriendPassiveController = context["passive"]
	var weapon: WeaponController = context["weapon"]
	var experience: ExperienceSystem = context["experience"]
	var controller: RunController = context["controller"]

	var magno := registry.resolve_definition(&"magno")
	var alea := registry.resolve_definition(&"alea")
	assert_true(magno != null and alea != null, "Servono due profili distinti per il cambio personaggio.")
	if magno == null or alea == null:
		return

	player.set_friend_definition(magno)
	assert_true(passive.equip_definition(magno), "La passiva deve accettare Magno.")
	assert_almost_eq(
		weapon.get_character_damage_multiplier(), magno.get_base_damage_multiplier(), FLOAT_TOLERANCE,
		"Equipaggiare Magno deve applicare il suo scarto danno."
	)

	player.set_friend_definition(alea)
	assert_true(passive.equip_definition(alea), "La passiva deve accettare Alea.")
	assert_almost_eq(
		weapon.get_character_damage_multiplier(), alea.get_base_damage_multiplier(), FLOAT_TOLERANCE,
		"PS-093: il cambio personaggio non deve conservare lo scarto danno del profilo precedente."
	)
	assert_almost_eq(
		experience.get_character_value_multiplier(), alea.get_base_xp_gain_multiplier(), FLOAT_TOLERANCE,
		"PS-093: il cambio personaggio deve applicare lo scarto XP del nuovo profilo."
	)
	assert_almost_eq(
		weapon.get_character_critical_chance_bonus(),
		alea.get_base_critical_chance_bonus(),
		FLOAT_TOLERANCE,
		"PS-093: il cambio personaggio deve applicare il bonus critico del nuovo profilo."
	)

	# Il restart azzera lo stato di run, non il personaggio equipaggiato
	# (stesso contratto di RunController per ogni altro contributo di
	# profilo): Alea resta agganciata, i suoi scarti estesi restano applicati.
	controller.prepare_restart()
	assert_almost_eq(
		weapon.get_character_damage_multiplier(), alea.get_base_damage_multiplier(), FLOAT_TOLERANCE,
		"PS-093: il restart non deve staccare il personaggio equipaggiato ne' i suoi scarti estesi."
	)

	# I dati base condivisi non vengono mutati: rimuovere esplicitamente il
	# profilo (stesso pattern di test_b47_base_stats.gd) riporta alla
	# baseline neutra su tutti e cinque gli assi.
	passive._definition = null
	weapon.reset_character_stat_multipliers()
	player.reset_character_stat_multipliers()
	experience.reset_character_value_multiplier()
	assert_almost_eq(
		weapon.get_character_damage_multiplier(), 1.0, FLOAT_TOLERANCE, "Senza profilo il danno character deve tornare neutro."
	)
	assert_almost_eq(
		weapon.get_character_critical_chance_bonus(), 0.0, FLOAT_TOLERANCE, "Senza profilo il bonus critico character deve azzerarsi."
	)
	assert_almost_eq(
		experience.get_character_value_multiplier(), 1.0, FLOAT_TOLERANCE, "Senza profilo l'avidità character deve tornare neutra."
	)
	print("EXTENDED_BASE_STATS_SMOKE_OK")


func _build_context(seed_value: int = 4711) -> Dictionary:
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_run_controller() as RunController
	var registry := movement_slice.get_friend_registry() as FriendRegistry
	var player := movement_slice.get_player() as Player
	var passive := movement_slice.get_friend_passive_controller() as FriendPassiveController
	var weapon := movement_slice.get_weapon_controller() as WeaponController
	var experience := movement_slice.get_experience_system() as ExperienceSystem
	if (
		controller == null
		or registry == null
		or player == null
		or passive == null
		or weapon == null
		or experience == null
	):
		assert_true(false, "La scena di run deve esporre le dipendenze PS-093.")
		return {}

	controller.set_process(false)
	player.set_physics_process(false)
	weapon.set_process(false)
	passive.set_process(false)
	# Soglia altissima: la composizione XP non deve far scattare un level-up
	# a metà asserzione (stesso accorgimento di test_powerup_first_wave.gd).
	var curve := ExperienceCurve.new()
	curve.base_experience_required = 999
	curve.experience_growth_per_level = 0
	experience.experience_curve = curve
	# La scena si auto-avvia già in RUNNING in headless (con il seed fisso di
	# GutGameplayTest): start_run() richiede BOOT e fallirebbe in silenzio
	# senza applicare davvero il seed richiesto. prepare_restart() riporta a
	# BOOT prima di richiedere il seed voluto.
	controller.prepare_restart()
	controller.start_run(seed_value)

	return {
		"slice": movement_slice,
		"controller": controller,
		"registry": registry,
		"player": player,
		"passive": passive,
		"weapon": weapon,
		"experience": experience,
	}
