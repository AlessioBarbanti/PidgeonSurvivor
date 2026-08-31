extends GutGameplayTest

## PS-006 — Signature Ability degli Evil.
##
## Un test per voce della copertura minima dichiarata nella card: risoluzione
## Evil → Signature, telegraph prima del danno, le otto mosse dedicate, la copia
## seedata e non ricorsiva di Evil Lollo, il congelamento in pausa e il cleanup
## alla morte del Boss e al restart.
##
## Il Boss viene guidato con `_physics_process` manuale, come gia' fanno gli
## smoke sui nemici ordinari: rende le prove deterministiche senza dipendere dal
## tempo reale. Il preavviso della Signature e' il punto di sincronizzazione di
## ogni misura, perche' a quel punto i due pattern Boss comuni hanno gia' fatto
## il loro corso.

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/combat/projectile.tscn")
const BOSS_THRESHOLD_SECONDS := 120.01
const DRIVE_STEP := 0.2
const MAX_DRIVE_STEPS := 400
const AREA_STEP := 0.05
const AREA_STEPS := 40
const FAR_AWAY := Vector2(4000.0, 4000.0)
const NEAR_OFFSET := Vector2(600.0, 0.0)


## Copre: ogni Evil possiede una Signature dedicata, derivata dall'attiva del
## personaggio corrispondente, e nessun comportamento e' condiviso fra due Evil.
func test_every_evil_has_a_signature_derived_from_its_active() -> void:
	var built := await _build_fixture(60601)
	var catalog: BossSignatureCatalog = built.get("catalog")
	var registry: FriendRegistry = built.get("registry")
	if catalog == null:
		return

	assert_true(catalog.is_valid(), "Il catalogo delle Signature deve essere valido.")
	assert_eq(catalog.get_valid_signatures().size(), 8, "Ogni Evil deve avere una Signature dedicata.")

	var seen_effects: Dictionary = {}
	for friend in registry.get_definitions():
		var signature := catalog.resolve_for_friend(friend.id)
		assert_not_null(signature, "%s deve avere una Signature." % friend.id)
		if signature == null:
			continue
		assert_eq(
			signature.get_safe_title(),
			friend.active_ability_title.strip_edges(),
			"La Signature di %s deve derivare dall'attiva del personaggio." % friend.id
		)
		assert_false(
			seen_effects.has(signature.effect_id),
			"Due Evil non possono condividere lo stesso comportamento Signature."
		)
		seen_effects[signature.effect_id] = true

	_teardown_fixture(built)


## Copre: le Signature usano parametri Boss propri. Bilanciare una Signature non
## puo' toccare l'abilita' del personaggio giocabile, e viceversa.
func test_signature_parameters_are_separate_from_player_abilities() -> void:
	var built := await _build_fixture(60602)
	var catalog: BossSignatureCatalog = built.get("catalog")
	var registry: FriendRegistry = built.get("registry")
	var abilities: AbilityEffectRegistry = built.get("abilities")
	if catalog == null:
		return

	for friend in registry.get_definitions():
		var signature := catalog.resolve_for_friend(friend.id)
		var ability := abilities.resolve_definition(friend.active_ability_id)
		assert_not_null(ability, "L'attiva di %s deve restare nel registry Player." % friend.id)
		if signature == null or ability == null:
			continue
		var ability_damage := ability.damage
		var ability_radius := ability.area_radius
		var probe := signature.duplicate(true) as BossSignatureDefinition
		probe.damage += 999.0
		probe.area_radius += 999.0
		assert_almost_eq(
			ability.damage, ability_damage, FLOAT_TOLERANCE,
			"Bilanciare la Signature Boss non deve cambiare il danno dell'attiva Player."
		)
		assert_almost_eq(
			ability.area_radius, ability_radius, FLOAT_TOLERANCE,
			"Bilanciare la Signature Boss non deve cambiare l'area dell'attiva Player."
		)

	_teardown_fixture(built)


## Copre: risoluzione Evil → Signature corretta. Ogni variante composta riceve la
## mossa del proprio profilo; il piccione baseline resta senza Signature.
func test_evil_resolution_assigns_the_matching_signature() -> void:
	var built := await _build_fixture(60603)
	var encounter: BossEncounter = built.get("encounter")
	var catalog: BossSignatureCatalog = built.get("catalog")
	if encounter == null:
		return

	assert_false(
		encounter.boss_definition.has_signature(),
		"Il piccione baseline non deve avere una Signature."
	)

	encounter.evil_boss_chance = 1.0
	var covered: Dictionary = {}
	for seed_value in range(1, 513):
		var resolved := encounter.resolve_definition_for_event(seed_value, 0)
		if resolved == null or not resolved.is_evil_variant():
			continue
		assert_true(resolved.has_signature(), "Ogni Evil risolto deve ricevere una Signature valida.")
		if not resolved.has_signature():
			continue
		assert_eq(
			resolved.signature,
			catalog.resolve_for_friend(resolved.friend_profile.id),
			"La Signature deve essere quella del profilo estratto."
		)
		covered[resolved.friend_profile.id] = true
	assert_eq(covered.size(), 8, "La selezione seed deve coprire tutti gli otto Evil.")

	_teardown_fixture(built)


## Copre: la Signature entra come terzo pattern senza eliminare i pattern Boss
## comuni, che restano entrambi nella rotazione.
func test_signature_is_the_third_pattern_of_the_rotation() -> void:
	var built := await _build_fixture(60604)
	var player: Player = built.get("player")
	var boss := _spawn_boss_with_signature(built, &"magno")
	if boss == null:
		return
	player.global_position = boss.global_position + FAR_AWAY

	assert_true(
		_drive_until_executed(boss, FirstBoss.RADIAL_VOLLEY),
		"Il primo pattern della rotazione deve restare la salva radiale."
	)
	assert_true(
		_drive_until_executed(boss, FirstBoss.TARGETED_BLAST),
		"Il secondo pattern della rotazione deve restare il colpo mirato."
	)
	assert_true(
		_drive_until_executed(boss, FirstBoss.SIGNATURE),
		"La Signature deve entrare come terzo pattern della rotazione."
	)
	assert_eq(boss.get_radial_volley_count(), 1, "Il ciclo di tre non deve saltare la salva radiale.")
	assert_eq(boss.get_targeted_blast_count(), 1, "Il ciclo di tre non deve saltare il colpo mirato.")

	_teardown_fixture(built)


## Copre: telegraph prima del danno. Durante il preavviso non esiste ancora
## nessuna area e il Player non subisce nulla.
func test_telegraph_precedes_every_dangerous_effect() -> void:
	var built := await _build_fixture(60605)
	var player: Player = built.get("player")
	var boss := _spawn_boss_with_signature(built, &"magno")
	if boss == null:
		return
	player.global_position = boss.global_position + FAR_AWAY

	assert_true(
		_drive_to_signature_telegraph(boss, player),
		"La Signature deve annunciarsi con un preavviso."
	)
	assert_not_null(
		boss.get_announced_signature(),
		"Il telegraph deve dichiarare la Signature che verra' eseguita."
	)
	assert_true(boss.get_telegraph_remaining() > 0.0, "Il preavviso deve avere una durata leggibile.")

	var health := player.get_health_component().health_current
	assert_eq(boss.get_active_signature_area_count(), 0, "Il telegraph non deve gia' creare l'area.")
	boss._physics_process(DRIVE_STEP)
	assert_true(boss.is_telegraph_active(), "Il preavviso deve durare piu' di un frame.")
	assert_eq(
		boss.get_active_signature_area_count(), 0,
		"Durante il preavviso non deve esistere ancora nessuna area."
	)
	assert_almost_eq(
		player.get_health_component().health_current, health, FLOAT_TOLERANCE,
		"Il telegraph non deve infliggere danno."
	)

	assert_true(_drive_until_executed(boss, FirstBoss.SIGNATURE), "La Signature deve poi eseguirsi.")
	assert_eq(boss.get_active_signature_area_count(), 1, "L'area deve nascere solo dopo il preavviso.")

	_teardown_fixture(built)


## Copre: Onda d'Urto Tellurica di Evil Magno. Il fronte parte dal Boss, si
## espande e colpisce una sola volta chi lo attraversa, con knockback.
func test_magno_shockwave_front_damages_and_pushes_once() -> void:
	var built := await _build_fixture(60606)
	var player: Player = built.get("player")
	var boss := _spawn_and_execute_signature(built, &"magno", FAR_AWAY)
	if boss == null:
		return
	var wave := _single_signature_area(
		boss,
		BossSignatureRegistry.AreaMode.EXPANDING_FRONT,
		"L'onda di Evil Magno deve essere un fronte in espansione."
	)
	if wave == null:
		return

	player.global_position = wave.global_position + Vector2(240.0, 0.0)
	var health := player.get_health_component().health_current
	wave.set_process(false)
	for _step in range(AREA_STEPS):
		wave._process(AREA_STEP)
		if player.get_health_component().health_current < health:
			break
	assert_true(
		player.get_health_component().health_current < health,
		"Il fronte deve danneggiare il Player quando lo attraversa."
	)
	assert_true(player.is_external_impulse_active(), "L'onda deve respingere il Player.")

	var health_after := player.get_health_component().health_current
	for _step in range(AREA_STEPS):
		wave._process(AREA_STEP)
	assert_almost_eq(
		player.get_health_component().health_current, health_after, FLOAT_TOLERANCE,
		"Il fronte non deve colpire due volte lo stesso Player."
	)

	_teardown_fixture(built)


## Copre: Powerslide e scia di Evil Bea. La traiettoria e' annunciata prima dello
## scatto e la scia che ne resta infligge danno nel tempo.
func test_bea_powerslide_shows_trajectory_and_leaves_a_burning_trail() -> void:
	var built := await _build_fixture(60607)
	var player: Player = built.get("player")
	var boss := _spawn_boss_with_signature(built, &"bea")
	if boss == null:
		return
	player.global_position = boss.global_position + NEAR_OFFSET

	assert_true(
		_drive_to_signature_telegraph(boss, player),
		"Evil Bea deve telegrafare il Powerslide."
	)
	assert_eq(
		boss.get_active_signature_area_count(), 0,
		"La traiettoria mostrata non deve gia' essere una scia pericolosa."
	)
	assert_true(_drive_until_executed(boss, FirstBoss.SIGNATURE), "Evil Bea deve eseguire il Powerslide.")
	assert_true(boss.is_signature_motion_active(), "Il Powerslide deve muovere il Boss lungo la traiettoria.")

	var trail := _single_signature_area(
		boss,
		BossSignatureRegistry.AreaMode.TRAIL_CORRIDOR,
		"La scia di Evil Bea deve essere un corridoio lungo la traiettoria."
	)
	if trail == null:
		return
	var corridor_end := boss.get_signature_corridor_end()
	assert_true(
		corridor_end.is_finite() and trail.global_position.distance_to(corridor_end) > 100.0,
		"La scia deve coprire la traiettoria annunciata."
	)

	player.global_position = trail.global_position.lerp(corridor_end, 0.5)
	var health := player.get_health_component().health_current
	trail.set_process(false)
	trail._process(0.6)
	assert_true(
		player.get_health_component().health_current < health,
		"La scia di fuoco deve infliggere danno nel tempo."
	)

	_teardown_fixture(built)


## Copre: Gran Piroetta di Evil Alea. Area di contatto visibile ancorata al Boss
## e inseguimento piu' lento del Player, quindi evitabile.
func test_alea_grand_spin_chases_slowly_with_a_visible_area() -> void:
	var built := await _build_fixture(60608)
	var player: Player = built.get("player")
	var boss := _spawn_and_execute_signature(built, &"alea", NEAR_OFFSET)
	if boss == null:
		return
	var aura := _single_signature_area(
		boss,
		BossSignatureRegistry.AreaMode.FOLLOWING_CONTACT,
		"L'area della Piroetta deve seguire il Boss."
	)
	if aura == null:
		return
	assert_true(boss.is_signature_motion_active(), "La Piroetta deve muovere il Boss.")

	var before := boss.global_position
	boss._physics_process(0.1)
	assert_true(
		before.distance_to(boss.global_position) < player.move_speed * 0.1,
		"La Piroetta non deve inseguire piu' rapidamente del Player."
	)

	aura.set_process(false)
	aura._process(AREA_STEP)
	assert_almost_eq(
		aura.global_position.distance_to(boss.global_position), 0.0, FLOAT_TOLERANCE,
		"L'area pericolosa deve restare ancorata al Boss."
	)

	player.global_position = boss.global_position
	var health := player.get_health_component().health_current
	aura._process(1.0)
	assert_true(
		player.get_health_component().health_current < health,
		"Restare dentro l'area della Piroetta deve costare vita."
	)

	_teardown_fixture(built)


## Copre: doppia fase di Evil Aleo. Prima il freddo rallenta senza far danno, poi
## la stessa area detona su chi e' rimasto dentro.
func test_aleo_thermal_shock_slows_then_detonates_on_the_same_area() -> void:
	var built := await _build_fixture(60609)
	var player: Player = built.get("player")
	var boss := _spawn_and_execute_signature(built, &"aleo", Vector2(500.0, 0.0))
	if boss == null:
		return
	var shock := _single_signature_area(
		boss,
		BossSignatureRegistry.AreaMode.TWO_PHASE_BURST,
		"Lo Shock Termico deve essere un'area in due fasi."
	)
	if shock == null:
		return
	assert_true(shock.is_cold_phase_active(), "La prima fase deve essere il freddo.")
	assert_false(shock.has_detonated(), "La detonazione non puo' precedere il freddo.")

	player.global_position = shock.global_position
	var health := player.get_health_component().health_current
	shock.set_process(false)
	shock._process(0.1)
	assert_true(shock.is_player_slowed(), "La fase fredda deve rallentare il Player dentro l'area.")
	assert_true(
		player.get_external_speed_multiplier() < 1.0,
		"Il rallentamento deve ridurre la velocita' effettiva del Player."
	)
	assert_almost_eq(
		player.get_health_component().health_current, health, FLOAT_TOLERANCE,
		"La fase fredda non deve infliggere danno."
	)

	for _step in range(AREA_STEPS):
		shock._process(0.1)
		if shock.has_detonated():
			break
	assert_true(shock.has_detonated(), "Dopo il freddo la stessa area deve detonare.")
	assert_true(
		player.get_health_component().health_current < health,
		"La detonazione deve colpire chi e' rimasto nell'area."
	)
	assert_almost_eq(
		player.get_external_speed_multiplier(), 1.0, FLOAT_TOLERANCE,
		"La detonazione deve restituire al Player la velocita' piena."
	)

	_teardown_fixture(built)


## Copre: nessun danno inevitabile. Chi legge il telegraph di Evil Aleo e si
## allontana non subisce la detonazione.
func test_aleo_thermal_shock_can_be_escaped_after_the_telegraph() -> void:
	var built := await _build_fixture(60610)
	var player: Player = built.get("player")
	var boss := _spawn_and_execute_signature(built, &"aleo", Vector2(500.0, 0.0))
	if boss == null:
		return
	var shock := _single_signature_area(
		boss,
		BossSignatureRegistry.AreaMode.TWO_PHASE_BURST,
		"La prova di fuga deve avere l'area in due fasi."
	)
	if shock == null:
		return

	player.global_position = shock.global_position + Vector2(900.0, 0.0)
	var health := player.get_health_component().health_current
	shock.set_process(false)
	for _step in range(AREA_STEPS):
		shock._process(0.1)
		if shock.has_detonated():
			break
	assert_true(shock.has_detonated(), "L'area deve detonare comunque.")
	assert_almost_eq(
		player.get_health_component().health_current, health, FLOAT_TOLERANCE,
		"Uscire dall'area prima della detonazione deve evitare del tutto il danno."
	)

	_teardown_fixture(built)


## Copre: zona Zen e assorbimento di Evil Migi. Rallenta, consuma i proiettili
## alleati che vi entrano e non infligge mai danno diretto.
func test_migi_zen_zone_slows_and_absorbs_without_dealing_damage() -> void:
	var built := await _build_fixture(60611)
	var controller: RunController = built.get("controller")
	var movement_slice: Control = built.get("movement_slice")
	var player: Player = built.get("player")
	var boss := _spawn_and_execute_signature(built, &"migi", NEAR_OFFSET)
	if boss == null:
		return
	var zone := _single_signature_area(
		boss,
		BossSignatureRegistry.AreaMode.FOLLOWING_SLOW_ABSORB,
		"La zona Zen deve seguire il Boss e assorbire i proiettili."
	)
	if zone == null:
		return

	var projectile := PROJECTILE_SCENE.instantiate() as Projectile
	movement_slice.get_projectile_parent().add_child(projectile)
	projectile.global_position = zone.global_position
	projectile.initialize(Vector2.RIGHT, 5.0, 0.0, 4.0, 6.0, controller)
	projectile.set_physics_process(false)

	player.global_position = zone.global_position
	var health := player.get_health_component().health_current
	zone.set_process(false)
	zone._process(0.1)
	assert_true(projectile.is_spent(), "La zona Zen deve assorbire i proiettili alleati che vi entrano.")
	assert_eq(zone.get_absorbed_projectile_count(), 1, "L'assorbimento deve essere contabilizzato.")
	assert_true(zone.is_player_slowed(), "La zona Zen deve rallentare il Player.")
	assert_almost_eq(
		player.get_health_component().health_current, health, FLOAT_TOLERANCE,
		"La zona Zen non deve infliggere danno diretto."
	)

	player.global_position = zone.global_position + Vector2(900.0, 0.0)
	zone._process(0.1)
	assert_almost_eq(
		player.get_external_speed_multiplier(), 1.0, FLOAT_TOLERANCE,
		"Uscire dalla zona Zen deve restituire la velocita' piena."
	)

	projectile.queue_free()
	_teardown_fixture(built)


## Copre: clone e targeting di Evil Marghe. Il clone e' un bersaglio registrato
## che l'auto-targeting puo' preferire, distinguibile dal Boss reale, mentre
## Marghe continua a usare i propri pattern.
func test_marghe_decoy_diverts_targeting_and_stays_distinguishable() -> void:
	var built := await _build_fixture(60612)
	var targeting: TargetingSystem = built.get("targeting")
	var player: Player = built.get("player")
	var boss := _spawn_and_execute_signature(built, &"marghe", NEAR_OFFSET)
	if boss == null:
		return
	var decoy := boss.get_active_decoy()
	assert_not_null(decoy, "Reggaeton time! deve generare il clone.")
	if decoy == null:
		return

	assert_true(targeting.has_target(decoy), "Il clone deve essere un bersaglio registrato.")
	assert_eq(
		targeting.get_nearest_alive(player.global_position), decoy,
		"L'auto-targeting deve poter preferire il clone al Boss reale."
	)
	assert_ne(
		decoy.get_decoy_modulate(), boss.get_boss_visual_modulate(),
		"Il clone deve essere distinguibile dal Boss reale."
	)
	var decoy_contact := decoy.get_contact_damage()
	assert_true(
		decoy_contact != null and is_zero_approx(decoy_contact.damage),
		"Il clone non deve infliggere danno da contatto."
	)

	assert_true(
		_drive_until_executed(boss, FirstBoss.RADIAL_VOLLEY),
		"Evil Marghe deve continuare a usare normalmente i propri pattern."
	)
	assert_true(is_instance_valid(boss.get_active_decoy()), "Il clone deve sopravvivere al pattern comune.")

	_teardown_fixture(built)


## Copre: Tempesta di Tuoni di Evil Zat. L'aura dichiara la fascia di carica, il
## colpo resta dentro il raggio annunciato e la fascia alta batte quella bassa.
func test_zat_thunder_is_avoidable_and_scales_with_charge() -> void:
	var built := await _build_fixture(60613)
	var player: Player = built.get("player")
	var boss := _spawn_boss_with_signature(built, &"zat")
	if boss == null:
		return

	var aura := boss.get_thunder_charge_aura()
	assert_true(aura != null and aura.is_presented(), "Evil Zat deve mostrare l'aura di carica del Tuono.")
	assert_eq(
		boss.get_thunder_charge_tier(), ThunderChargeAura.TIER_LOW,
		"Con il Boss intatto la carica deve restare in fascia bassa."
	)

	# Lontano dal raggio annunciato il Tuono non arriva: nessun danno globale
	# inevitabile, a differenza della versione Player di PS-004.
	player.global_position = boss.global_position + FAR_AWAY
	assert_true(_drive_to_signature_telegraph(boss, player), "Evil Zat deve telegrafare il Tuono.")
	var health := player.get_health_component().health_current
	assert_true(_drive_until_executed(boss, FirstBoss.SIGNATURE), "Evil Zat deve eseguire il Tuono.")
	assert_almost_eq(
		player.get_health_component().health_current, health, FLOAT_TOLERANCE,
		"Il Tuono Boss non deve infliggere danno globale inevitabile."
	)
	assert_not_null(
		_single_signature_area(
			boss,
			BossSignatureRegistry.AreaMode.INSTANT_BURST,
			"Il Tuono Boss deve essere un colpo radiale istantaneo."
		),
		"Il Tuono deve lasciare la propria coda visiva."
	)

	# La carica sale con il danno gia' subito dal Boss: e' la controparte del
	# danno recuperabile che alimenta il Tuono di Zat (PS-004).
	var low_damage := _measure_thunder_damage(built, player, 0.0)
	var high_damage := _measure_thunder_damage(built, player, 0.6)
	assert_eq(
		boss.get_thunder_charge_tier(), ThunderChargeAura.TIER_HIGH,
		"Un Boss molto danneggiato deve raggiungere la fascia alta."
	)
	assert_true(low_damage > 0.0, "Dentro il raggio annunciato il Tuono deve colpire.")
	assert_true(
		high_damage > low_damage,
		"La fascia alta deve infliggere piu' danno della fascia bassa (%s contro %s)."
		% [high_damage, low_damage]
	)

	_teardown_fixture(built)


## Copre: copia deterministica e anti-ricorsione di Evil Lollo. Lo stesso seed
## estrae sempre la stessa sequenza e Cosplay Casuale non e' mai fra le copie.
func test_lollo_cosplay_is_seeded_and_never_recursive() -> void:
	var first := await _record_cosplay_sequence(60614)
	var second := await _record_cosplay_sequence(60614)
	var other_seed := await _record_cosplay_sequence(60615)

	assert_true(first.size() >= 3, "La prova deve osservare almeno tre copie consecutive.")
	assert_eq(first, second, "Lo stesso seed deve estrarre sempre la stessa sequenza di copie.")
	assert_ne(first, other_seed, "Seed diversi devono poter estrarre sequenze diverse.")
	for copied_id: StringName in first:
		assert_ne(
			copied_id, &"evil_lollo_random_cosplay",
			"Evil Lollo non puo' copiare Cosplay Casuale."
		)


## Copre: la pausa congela Signature e VFX invece di lasciarli correre.
func test_pause_freezes_the_signature() -> void:
	var built := await _build_fixture(60616)
	var controller: RunController = built.get("controller")
	var boss := _spawn_and_execute_signature(built, &"migi", NEAR_OFFSET)
	if boss == null:
		return
	var zone := _single_signature_area(
		boss,
		BossSignatureRegistry.AreaMode.FOLLOWING_SLOW_ABSORB,
		"La prova di pausa deve avere la zona Zen attiva."
	)
	if zone == null:
		return

	assert_true(controller.request_manual_pause(), "La fixture deve poter mettere in pausa la run.")
	var frozen_duration := zone.get_duration_remaining()
	var frozen_signatures := boss.get_signature_count()
	zone.set_process(false)
	zone._process(1.0)
	boss._physics_process(1.0)
	assert_almost_eq(
		zone.get_duration_remaining(), frozen_duration, FLOAT_TOLERANCE,
		"La pausa deve congelare la durata dell'area della Signature."
	)
	assert_eq(
		boss.get_signature_count(), frozen_signatures,
		"La pausa non deve far avanzare la rotazione dei pattern Boss."
	)

	assert_true(controller.resume_run(), "La fixture deve poter riprendere la run.")
	zone._process(0.1)
	assert_true(
		zone.get_duration_remaining() < frozen_duration,
		"Alla ripresa la Signature deve tornare ad avanzare."
	)

	_teardown_fixture(built)


## Copre: cleanup alla morte. Nessuna area, clone, scia o rallentamento
## sopravvive alla sconfitta del Boss.
func test_boss_death_removes_every_signature_residue() -> void:
	var built := await _build_fixture(60617)
	var encounter: BossEncounter = built.get("encounter")
	var movement_slice: Control = built.get("movement_slice")
	var player: Player = built.get("player")
	var boss := _spawn_and_execute_signature(built, &"marghe", NEAR_OFFSET)
	if boss == null:
		return
	var decoy := boss.get_active_decoy()
	assert_not_null(decoy, "La prova di cleanup deve partire con il clone in scena.")

	boss.take_damage(boss.get_health_component().health_current)
	await wait_process_frames(2)
	assert_null(encounter.get_active_boss(), "Il Boss sconfitto non deve restare attivo.")
	assert_false(is_instance_valid(decoy), "La morte del Boss deve rimuovere il clone.")
	assert_eq(
		movement_slice.get_boss_projectile_parent().get_child_count(), 0,
		"La morte del Boss non deve lasciare aree o scie della Signature."
	)
	assert_almost_eq(
		player.get_external_speed_multiplier(), 1.0, FLOAT_TOLERANCE,
		"Nessun rallentamento della Signature deve sopravvivere alla morte del Boss."
	)

	_teardown_fixture(built)


## Copre: cleanup al restart. Il restart in mezzo a una Signature viva non deve
## lasciarne nulla nella run successiva.
func test_restart_clears_the_previous_signature_state() -> void:
	var built := await _build_fixture(60618)
	var controller: RunController = built.get("controller")
	var encounter: BossEncounter = built.get("encounter")
	var movement_slice: Control = built.get("movement_slice")
	var player: Player = built.get("player")
	var boss := _spawn_and_execute_signature(built, &"migi", Vector2.ZERO)
	if boss == null:
		return
	var zone := _single_signature_area(
		boss,
		BossSignatureRegistry.AreaMode.FOLLOWING_SLOW_ABSORB,
		"Il restart deve avvenire con la zona Zen viva."
	)
	if zone == null:
		return

	# Il restart deve trovare uno stato davvero sporco: area viva e Player
	# effettivamente rallentato dalla Signature.
	zone.set_process(false)
	zone._process(0.1)
	assert_true(zone.is_player_slowed(), "La prova di restart deve partire con il Player rallentato.")
	assert_true(
		player.get_external_speed_multiplier() < 1.0,
		"La prova di restart deve partire con la velocita' del Player ridotta."
	)

	if not controller.is_terminal():
		controller.request_defeat()
	assert_true(movement_slice.restart_run(60619), "Il restart deve poter avviare una nuova run.")
	await wait_process_frames(2)

	assert_null(encounter.get_active_boss(), "Il restart deve rimuovere il Boss pendente.")
	assert_null(encounter.get_active_definition(), "Il restart non deve conservare la variante precedente.")
	assert_eq(
		movement_slice.get_boss_projectile_parent().get_child_count(), 0,
		"Il restart non deve lasciare aree della Signature precedente."
	)
	assert_almost_eq(
		player.get_external_speed_multiplier(), 1.0, FLOAT_TOLERANCE,
		"Il restart deve azzerare i rallentamenti imposti dalle Signature."
	)
	assert_false(
		player.is_external_impulse_active(),
		"Il restart deve azzerare le spinte imposte dalle Signature."
	)

	_teardown_fixture(built)


func _record_cosplay_sequence(seed_value: int) -> Array[StringName]:
	var copied: Array[StringName] = []
	var built := await _build_fixture(seed_value)
	var player: Player = built.get("player")
	var boss := _spawn_boss_with_signature(built, &"lollo")
	if boss == null:
		_teardown_fixture(built)
		return copied

	player.global_position = boss.global_position + FAR_AWAY
	for _use in range(3):
		if not _drive_to_signature_telegraph(boss, player):
			break
		var announced := boss.get_announced_signature()
		if announced == null:
			break
		copied.append(announced.id)
		if not _drive_until_executed(boss, FirstBoss.SIGNATURE):
			break
	_teardown_fixture(built)
	return copied


## Danno inflitto da una Tempesta di Tuoni Boss con il Boss danneggiato della
## quota indicata, misurato con il Player dentro il raggio annunciato.
func _measure_thunder_damage(
	built: Dictionary,
	player: Player,
	missing_health_ratio: float
) -> float:
	var boss := _reconfigure_signature(built, &"zat")
	if boss == null:
		return 0.0
	if missing_health_ratio > 0.0:
		boss.take_damage(boss.get_health_component().health_max * missing_health_ratio)
	boss._physics_process(AREA_STEP)
	if not _drive_to_signature_telegraph(boss, player):
		return 0.0
	# Dentro il raggio annunciato soltanto per l'esecuzione: i pattern Boss
	# comuni sono gia' passati, quindi la misura isola il solo Tuono.
	player.global_position = boss.global_position + Vector2(60.0, 0.0)
	var before := player.get_health_component().health_current
	if not _drive_until_executed(boss, FirstBoss.SIGNATURE):
		return 0.0
	return before - player.get_health_component().health_current


## Esecuzioni gia' contabilizzate per il pattern indicato.
func _executed_count(boss: FirstBoss, pattern_id: StringName) -> int:
	match pattern_id:
		FirstBoss.RADIAL_VOLLEY:
			return boss.get_radial_volley_count()
		FirstBoss.TARGETED_BLAST:
			return boss.get_targeted_blast_count()
	return boss.get_signature_count()


## Guida il Boss a passi fissi finche' il pattern indicato non viene eseguito
## una volta in piu' di quante lo era all'ingresso.
func _drive_until_executed(boss: FirstBoss, pattern_id: StringName) -> bool:
	var before := _executed_count(boss, pattern_id)
	for _step in range(MAX_DRIVE_STEPS):
		if _executed_count(boss, pattern_id) > before:
			return true
		boss._physics_process(DRIVE_STEP)
	return _executed_count(boss, pattern_id) > before


## Porta il Boss fino al preavviso della Signature e riporta il Player a vita
## piena. I due pattern Boss comuni hanno gia' fatto il loro corso, quindi la
## misura successiva riguarda soltanto la Signature e non eredita la finestra di
## invulnerabilita' aperta dal colpo mirato.
func _drive_to_signature_telegraph(boss: FirstBoss, player: Player) -> bool:
	for _step in range(MAX_DRIVE_STEPS):
		if boss.get_active_pattern_id() == FirstBoss.SIGNATURE and boss.is_telegraph_active():
			player.get_health_component().reset_to_max()
			return true
		boss._physics_process(DRIVE_STEP)
	return false


## Unica area lasciata dalla Signature, con la modalita' attesa.
func _single_signature_area(
	boss: FirstBoss,
	expected_mode: BossSignatureRegistry.AreaMode,
	text: String
) -> BossSignatureArea:
	var areas := boss.get_active_signature_areas()
	assert_eq(areas.size(), 1, "La Signature deve lasciare una sola area. %s" % text)
	if areas.is_empty():
		return null
	assert_eq(areas[0].get_mode(), expected_mode, text)
	return areas[0]


## Boss Evil con la Signature richiesta, portato fino all'esecuzione con il
## Player nella posizione indicata rispetto al Boss.
func _spawn_and_execute_signature(
	built: Dictionary,
	friend_id: StringName,
	player_offset: Vector2
) -> FirstBoss:
	var player: Player = built.get("player")
	var boss := _spawn_boss_with_signature(built, friend_id)
	if boss == null:
		return null
	player.global_position = boss.global_position + player_offset
	assert_true(
		_drive_to_signature_telegraph(boss, player),
		"La Signature di %s deve raggiungere il preavviso." % friend_id
	)
	assert_true(
		_drive_until_executed(boss, FirstBoss.SIGNATURE),
		"La Signature di %s deve eseguirsi." % friend_id
	)
	return boss


func _spawn_boss_with_signature(built: Dictionary, friend_id: StringName) -> FirstBoss:
	var controller: RunController = built.get("controller")
	var encounter: BossEncounter = built.get("encounter")
	if controller == null or encounter == null:
		return null
	encounter.evil_boss_chance = 1.0
	controller._process(BOSS_THRESHOLD_SECONDS)
	assert_not_null(encounter.get_active_boss(), "La fixture PS-006 deve poter generare un Boss.")
	if encounter.get_active_boss() == null:
		return null
	assert_true(encounter.complete_intro(), "L'intro del Boss deve poter terminare.")
	return _reconfigure_signature(built, friend_id)


## Impone al Boss attivo la Signature del profilo richiesto. La definizione Evil
## e' gia' una copia per incontro, quindi assegnarle la Signature non tocca ne'
## il catalogo ne' il Boss baseline.
func _reconfigure_signature(built: Dictionary, friend_id: StringName) -> FirstBoss:
	var controller: RunController = built.get("controller")
	var encounter: BossEncounter = built.get("encounter")
	var catalog: BossSignatureCatalog = built.get("catalog")
	var movement_slice: Control = built.get("movement_slice")
	var player: Player = built.get("player")
	var targeting: TargetingSystem = built.get("targeting")

	var boss := encounter.get_active_boss()
	var definition := encounter.get_active_definition()
	assert_true(boss != null and definition != null, "Il Boss attivo deve avere una definizione risolta.")
	if boss == null or definition == null:
		return null
	definition.signature = catalog.resolve_for_friend(friend_id)
	assert_true(
		boss.configure_boss(
			definition,
			player,
			controller,
			movement_slice.get_boss_projectile_parent()
		),
		"La fixture deve poter riconfigurare il Boss con la Signature richiesta."
	)
	assert_true(
		boss.configure_signature(catalog.get_copy_candidates(), 0, targeting, boss.get_parent()),
		"La fixture deve poter fornire il contesto della Signature."
	)
	boss.set_physics_process(false)
	# Ogni prova parte dal Player intatto: le Signature si misurano una alla
	# volta, non in somma.
	player.get_health_component().reset_to_max()
	player.clear_external_speed_modifiers()
	player.clear_external_impulse()
	# Il Boss resta fermo e non fa male al contatto: le prove riguardano la
	# Signature, non l'inseguimento ordinario.
	boss.move_speed = 0.0
	var contact := boss.get_contact_damage()
	if contact != null:
		contact.disable()
	return boss


func _build_fixture(seed_value: int) -> Dictionary:
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_run_controller() as RunController
	var encounter := movement_slice.get_boss_encounter() as BossEncounter
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	var registry := movement_slice.get_friend_registry() as FriendRegistry
	var abilities := movement_slice.get_ability_effect_registry() as AbilityEffectRegistry
	assert_true(
		controller != null
		and encounter != null
		and spawner != null
		and registry != null
		and abilities != null,
		"PS-006 richiede RunController, BossEncounter, EnemySpawner, FriendRegistry e "
		+ "AbilityEffectRegistry dalla scena."
	)
	if (
		controller == null
		or encounter == null
		or spawner == null
		or registry == null
		or abilities == null
	):
		return {}

	# L'avvio automatico della scena usa il seed fisso di test (PS-032): per
	# fissare il seed richiesto serve passare da un terminale, come fa il flusso
	# reale di restart.
	if not controller.is_terminal():
		controller.request_defeat()
	assert_true(
		movement_slice.restart_run(seed_value),
		"La fixture PS-006 deve poter avviare la run con il seed richiesto."
	)
	await wait_process_frames(2)
	controller.set_process(false)
	spawner.set_process(false)

	return {
		"movement_slice": movement_slice,
		"controller": controller,
		"encounter": encounter,
		"spawner": spawner,
		"registry": registry,
		"abilities": abilities,
		"catalog": encounter.get_signature_catalog(),
		"player": movement_slice.get_player(),
		"targeting": movement_slice.get_targeting_system(),
	}


func _teardown_fixture(built: Dictionary) -> void:
	var controller: RunController = built.get("controller")
	if controller != null and not controller.is_terminal():
		controller.request_defeat()
	if controller != null:
		controller.prepare_restart()
