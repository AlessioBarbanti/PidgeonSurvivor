extends GutGameplayTest

## PS-181 — Il telegraph di attacco del Boss deve sempre risolversi in un
## colpo effettivo, o annullarsi in modo pulito, mai restare "a meta'".
##
## Ipotesi di lavoro registrata nella card: la guardia
## is_alive()/run_controller.is_running() in FirstBoss._advance_attack_cycle()
## potrebbe congelare un telegraph a meta' se una di quelle condizioni diventa
## transitoriamente falsa (es. un level-up richiesto mentre il Boss e' in
## combattimento, molto comune nella run reale). Questo test forza
## deterministicamente quella condizione esatta - una pausa (LEVEL_UP) che
## scade il telegraph mentre la run e' ferma - su ogni tipo di pattern
## (Raffica Radiale, Area Mirata, Scia di Piume del baseline, Signature di tre
## Evil diversi compreso Alea) e verifica che si risolva sempre correttamente
## alla ripresa, senza mai perdere un colpo ne' produrne uno "fantasma" da un
## Boss gia' morto durante la pausa.

const NEAR_OFFSET := Vector2(60.0, 0.0)
const RESUME_MARGIN := 0.01
const PAUSE_OVERSHOOT := 5.0
const DRIVE_STEP := 0.2
const MAX_DRIVE_STEPS := 400


func test_radial_volley_survives_level_up_interruption_on_baseline() -> void:
	var built := await _build_fixture(18101)
	var boss := _spawn_baseline(built, NEAR_OFFSET)
	if boss == null:
		return
	var controller: RunController = built.get("controller")
	var log := _watch_attacks(boss)

	assert_true(
		_drive_until_telegraph(boss, FirstBoss.RADIAL_VOLLEY),
		"La Raffica Radiale deve telegrafare entro i passi previsti."
	)
	_assert_pause_freezes_and_resume_resolves(
		boss, controller, log, FirstBoss.RADIAL_VOLLEY,
		"Raffica Radiale (baseline)"
	)
	_teardown_fixture(built)


func test_targeted_blast_survives_level_up_interruption_and_still_hits() -> void:
	var built := await _build_fixture(18102)
	var boss := _spawn_baseline(built, NEAR_OFFSET)
	if boss == null:
		return
	var controller: RunController = built.get("controller")
	var player: Player = built.get("player")
	var log := _watch_attacks(boss)

	assert_true(
		_drive_until_telegraph(boss, FirstBoss.RADIAL_VOLLEY),
		"Serve superare prima la Raffica Radiale."
	)
	boss._physics_process(boss.get_telegraph_remaining() + RESUME_MARGIN)
	boss._physics_process(boss.get_attack_cooldown_remaining() + RESUME_MARGIN)
	assert_eq(
		boss.get_active_pattern_id(), FirstBoss.TARGETED_BLAST,
		"Il secondo pattern del ciclo deve essere l'Area Mirata."
	)
	# Il colpo mirato congela la posizione bersaglio all'inizio del telegraph:
	# il Player deve restare dentro il raggio anche durante la pausa.
	player.global_position = boss.get_targeted_position()
	var health_before := player.get_health_component().health_current

	_assert_pause_freezes_and_resume_resolves(
		boss, controller, log, FirstBoss.TARGETED_BLAST,
		"Area Mirata (baseline)"
	)
	assert_true(
		player.get_health_component().health_current < health_before,
		"L'Area Mirata ripresa dopo la pausa deve colpire davvero il Player, non risolversi a vuoto."
	)
	_teardown_fixture(built)


func test_feather_line_survives_interruption_at_telegraph_and_mid_stream() -> void:
	var built := await _build_fixture(18103)
	var boss := _spawn_baseline(built, NEAR_OFFSET)
	if boss == null:
		return
	var definition: BossDefinition = built.get("definition")
	var controller: RunController = built.get("controller")
	var log := _watch_attacks(boss)

	# Consuma i primi due pattern comuni per arrivare alla Scia di Piume,
	# terzo slot esclusivo del baseline (PS-127).
	assert_true(_drive_until_telegraph(boss, FirstBoss.RADIAL_VOLLEY), "Manca la Raffica Radiale.")
	boss._physics_process(boss.get_telegraph_remaining() + RESUME_MARGIN)
	boss._physics_process(boss.get_attack_cooldown_remaining() + RESUME_MARGIN)
	assert_eq(boss.get_active_pattern_id(), FirstBoss.TARGETED_BLAST, "Manca l'Area Mirata.")
	boss._physics_process(boss.get_telegraph_remaining() + RESUME_MARGIN)
	boss._physics_process(boss.get_attack_cooldown_remaining() + RESUME_MARGIN)
	assert_eq(
		boss.get_active_pattern_id(), FirstBoss.FEATHER_LINE,
		"Il terzo pattern del baseline deve essere la Scia di Piume."
	)
	assert_true(boss.is_telegraph_active(), "La Scia di Piume deve telegrafare prima di sparare.")
	# Radial Volley e Area Mirata sono gia' stati eseguiti sopra e restano nel
	# log condiviso: la baseline isola i soli attacchi di questa fase.
	var attacks_before := log.size()

	# Fase 1: la pausa deve congelare il telegraph della Scia di Piume, non
	# lasciarlo scadere nel vuoto.
	var telegraph_remaining := boss.get_telegraph_remaining()
	assert_true(controller.request_level_up(), "Deve poter richiedere il level-up.")
	boss._physics_process(telegraph_remaining + PAUSE_OVERSHOOT)
	assert_true(
		boss.is_telegraph_active() and not boss.is_feather_line_active(),
		"In pausa il telegraph della Scia di Piume non deve risolversi nello stream."
	)
	assert_eq(log.size(), attacks_before, "Nessun attacco deve eseguirsi mentre la run e' in pausa.")

	assert_true(controller.complete_level_up(), "Deve poter chiudere il level-up.")
	boss._physics_process(telegraph_remaining + RESUME_MARGIN)
	assert_true(
		boss.is_feather_line_active(),
		"Alla ripresa il telegraph deve risolversi nell'avvio dello stream."
	)
	assert_eq(boss.get_feather_line_fired_count(), 0, "Nessuna piuma deve partire nello stesso frame di avvio.")

	# Fase 2: la pausa deve congelare anche lo stream gia' avviato, non solo
	# il telegraph iniziale.
	assert_true(controller.request_level_up(), "Deve poter mettere in pausa a stream avviato.")
	var stream_duration := definition.feather_line_launch_interval * definition.feather_line_projectile_count
	boss._physics_process(stream_duration + PAUSE_OVERSHOOT)
	assert_eq(
		boss.get_feather_line_fired_count(), 0,
		"In pausa lo stream della Scia di Piume non deve avanzare."
	)
	assert_eq(log.size(), attacks_before, "Lo stream in pausa non deve ancora contare come attacco eseguito.")

	assert_true(controller.complete_level_up(), "Deve poter riprendere dopo la pausa a meta' stream.")
	boss._physics_process(stream_duration + RESUME_MARGIN)
	assert_false(boss.is_feather_line_active(), "Alla ripresa lo stream deve concludersi.")
	assert_eq(
		boss.get_feather_line_fired_count(), definition.feather_line_projectile_count,
		"Tutte le piume dello stream devono partire dopo la ripresa, nessuna persa dalla pausa."
	)
	assert_eq(
		log.size(), attacks_before + 1,
		"La Scia di Piume deve contare come un solo attacco eseguito, non zero ne' doppio."
	)
	var resolved: Array = log[attacks_before]
	assert_eq(resolved[0], FirstBoss.FEATHER_LINE, "L'attacco eseguito deve essere la Scia di Piume.")
	assert_true(resolved[1] > 0, "La Scia di Piume ripresa dopo la pausa non deve risolversi a vuoto.")
	_teardown_fixture(built)


func test_evil_alea_grand_spin_signature_survives_level_up_interruption() -> void:
	await _assert_signature_survives_pause(18104, &"alea", "Gran Piroetta (Evil Alea)")


func test_evil_magno_shockwave_signature_survives_level_up_interruption() -> void:
	await _assert_signature_survives_pause(18105, &"magno", "Scossa Tellurica (Evil Magno)")


func test_evil_marghe_decoy_signature_survives_level_up_interruption() -> void:
	await _assert_signature_survives_pause(18106, &"marghe", "Reggeton time! (Evil Marghe)")


## Copre il criterio "nessun colpo fantasma": se il Boss muore davvero mentre
## un telegraph e' congelato in pausa, la ripresa non deve produrre alcun
## attacco e la pulizia successiva (equivalente a BossEncounter alla morte)
## deve lasciare lo stato pulito.
func test_boss_death_during_paused_telegraph_produces_no_phantom_shot() -> void:
	var built := await _build_fixture(18107)
	var boss := _spawn_baseline(built, NEAR_OFFSET)
	if boss == null:
		return
	var controller: RunController = built.get("controller")
	var log := _watch_attacks(boss)

	assert_true(_drive_until_telegraph(boss, FirstBoss.RADIAL_VOLLEY), "Manca la Raffica Radiale.")
	var telegraph_remaining := boss.get_telegraph_remaining()
	assert_true(controller.request_level_up(), "Deve poter mettere in pausa.")

	var health_component := boss.get_health_component()
	health_component.take_damage(health_component.health_max)
	assert_false(boss.is_alive(), "Il Boss deve risultare morto dopo il danno letale.")

	boss._physics_process(telegraph_remaining + PAUSE_OVERSHOOT)
	assert_eq(
		log.size(), 0,
		"Un Boss morto durante la pausa non deve mai produrre un attacco, nemmeno alla scadenza del telegraph."
	)

	assert_true(controller.complete_level_up(), "La run deve poter riprendere anche dopo la morte del Boss.")
	boss._physics_process(telegraph_remaining + PAUSE_OVERSHOOT)
	assert_eq(
		log.size(), 0,
		"Un Boss gia' morto non deve sparare nemmeno dopo la ripresa della run."
	)

	# Pulizia equivalente a BossEncounter._clear_active_boss() alla morte.
	boss.clear_attack_runtime()
	assert_false(boss.is_telegraph_active(), "Il cleanup alla morte deve chiudere il telegraph pendente.")
	assert_eq(boss.get_active_projectile_count(), 0, "Il cleanup alla morte non deve lasciare proiettili residui.")
	_teardown_fixture(built)


## ---------------------------------------------------------------------
## Helper condivisi
## ---------------------------------------------------------------------


## Genera un array log popolato da [pattern_id, affected_count] a ogni
## attacco eseguito, cosi' i test possono verificare sia il conteggio sia
## l'esito reale (mai zero) senza dipendere dagli accessori per-pattern.
func _watch_attacks(boss: FirstBoss) -> Array:
	var log: Array = []
	boss.attack_executed.connect(
		func(_boss: FirstBoss, pattern_id: StringName, affected_count: int) -> void:
			log.append([pattern_id, affected_count])
	)
	return log


## Cuore del test: dato un telegraph gia' attivo per `pattern_id`, verifica
## che una pausa (LEVEL_UP) esattamente a cavallo della sua scadenza non lo
## risolva mai, e che la ripresa lo risolva esattamente una volta, con un
## esito reale (mai un "colpo fantasma" a conteggio zero).
func _assert_pause_freezes_and_resume_resolves(
	boss: FirstBoss,
	controller: RunController,
	log: Array,
	pattern_id: StringName,
	label: String
) -> void:
	assert_eq(boss.get_active_pattern_id(), pattern_id, "%s: pattern atteso non attivo." % label)
	var telegraph_remaining := boss.get_telegraph_remaining()
	# Baseline invece di un indice fisso: alcuni pattern (Area Mirata, Scia di
	# Piume, Signature) si raggiungono solo dopo aver gia' fatto eseguire i
	# pattern precedenti del ciclo, che restano loro stessi nel log condiviso.
	var attacks_before := log.size()

	assert_true(controller.request_level_up(), "%s: deve poter richiedere il level-up." % label)
	assert_false(controller.is_running(), "%s: la run deve risultare non RUNNING durante il level-up." % label)

	boss._physics_process(telegraph_remaining + PAUSE_OVERSHOOT)
	assert_true(
		boss.is_telegraph_active(),
		"%s: il telegraph non deve risolversi mentre la run e' in pausa." % label
	)
	assert_almost_eq(
		boss.get_telegraph_remaining(), telegraph_remaining, FLOAT_TOLERANCE,
		"%s: il tempo residuo del telegraph non deve avanzare durante la pausa." % label
	)
	assert_eq(
		log.size(), attacks_before,
		"%s: nessun attacco deve eseguirsi mentre la run e' in pausa." % label
	)

	assert_true(controller.complete_level_up(), "%s: deve poter chiudere il level-up." % label)
	boss._physics_process(telegraph_remaining + RESUME_MARGIN)
	assert_false(
		boss.is_telegraph_active(),
		"%s: alla ripresa il telegraph deve risolversi, non restare congelato." % label
	)
	assert_eq(
		log.size(), attacks_before + 1,
		"%s: il telegraph ripreso deve produrre esattamente un attacco eseguito." % label
	)
	var resolved: Array = log[attacks_before]
	assert_eq(resolved[0], pattern_id, "%s: l'attacco eseguito deve corrispondere al pattern telegrafato." % label)
	assert_true(
		resolved[1] > 0,
		"%s: l'attacco ripreso dopo la pausa non deve risolversi a vuoto (colpo fantasma inverso)." % label
	)


## Porta un Evil fino al telegraph della sua Signature, verifica che una pausa
## a cavallo della scadenza non la risolva mai e che la ripresa la risolva
## esattamente una volta con un esito reale.
func _assert_signature_survives_pause(seed_value: int, friend_id: StringName, label: String) -> void:
	var built := await _build_fixture(seed_value)
	var boss := _spawn_evil_with_signature(built, friend_id, NEAR_OFFSET)
	if boss == null:
		return
	var controller: RunController = built.get("controller")
	var log := _watch_attacks(boss)

	assert_true(
		_drive_until_telegraph(boss, FirstBoss.SIGNATURE),
		"%s: la Signature deve raggiungere il preavviso entro i passi previsti." % label
	)
	_assert_pause_freezes_and_resume_resolves(boss, controller, log, FirstBoss.SIGNATURE, label)
	_teardown_fixture(built)


func _drive_until_telegraph(boss: FirstBoss, pattern_id: StringName) -> bool:
	for _step in range(MAX_DRIVE_STEPS):
		if boss.get_active_pattern_id() == pattern_id and boss.is_telegraph_active():
			return true
		boss._physics_process(DRIVE_STEP)
	return boss.get_active_pattern_id() == pattern_id and boss.is_telegraph_active()


func _spawn_baseline(built: Dictionary, player_offset: Vector2) -> FirstBoss:
	var controller: RunController = built.get("controller")
	var encounter: BossEncounter = built.get("encounter")
	var player: Player = built.get("player")
	if controller == null or encounter == null or player == null:
		return null
	encounter.evil_boss_chance = 0.0
	controller._process(120.01)
	var boss := encounter.get_active_boss()
	var definition := encounter.get_active_definition()
	assert_true(
		boss != null and definition != null and not definition.is_evil_variant(),
		"La fixture PS-181 deve poter aprire il Piccione Malvagio baseline."
	)
	if boss == null or definition == null:
		return null
	assert_true(encounter.complete_intro(), "L'intro del Boss deve poter terminare.")
	built["definition"] = definition
	return _prepare_boss_for_manual_drive(boss, player, player_offset)


func _spawn_evil_with_signature(
	built: Dictionary,
	friend_id: StringName,
	player_offset: Vector2
) -> FirstBoss:
	var controller: RunController = built.get("controller")
	var encounter: BossEncounter = built.get("encounter")
	var catalog: BossSignatureCatalog = built.get("catalog")
	var movement_slice: Control = built.get("movement_slice")
	var player: Player = built.get("player")
	var targeting: TargetingSystem = built.get("targeting")
	if (
		controller == null
		or encounter == null
		or catalog == null
		or movement_slice == null
		or player == null
	):
		return null

	encounter.evil_boss_chance = 1.0
	controller._process(120.01)
	var boss := encounter.get_active_boss()
	var definition := encounter.get_active_definition()
	assert_true(
		boss != null and definition != null and definition.is_evil_variant(),
		"La fixture PS-181 deve poter aprire un Evil con evil_boss_chance=1.0."
	)
	if boss == null or definition == null:
		return null
	assert_true(encounter.complete_intro(), "L'intro del Boss deve poter terminare.")

	definition.signature = catalog.resolve_for_friend(friend_id)
	assert_true(
		boss.configure_boss(definition, player, controller, movement_slice.get_boss_projectile_parent()),
		"La fixture PS-181 deve poter assegnare la Signature di %s." % friend_id
	)
	assert_true(
		boss.configure_signature(catalog.get_copy_candidates(), 0, targeting, boss.get_parent()),
		"La fixture PS-181 deve poter fornire il contesto della Signature."
	)
	built["definition"] = definition
	return _prepare_boss_for_manual_drive(boss, player, player_offset)


## Il Boss viene guidato con _physics_process manuale (stesso schema di
## test_ps006/test_ps127): deterministico, senza dipendere dal tempo reale ne'
## dalla sospensione reale dell'albero durante gli stati non-RUNNING.
func _prepare_boss_for_manual_drive(boss: FirstBoss, player: Player, player_offset: Vector2) -> FirstBoss:
	boss.set_physics_process(false)
	boss.move_speed = 0.0
	var contact := boss.get_contact_damage()
	if contact != null:
		contact.disable()
	player.get_health_component().reset_to_max()
	player.global_position = boss.global_position + player_offset
	return boss


func _build_fixture(seed_value: int) -> Dictionary:
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_run_controller() as RunController
	var encounter := movement_slice.get_boss_encounter() as BossEncounter
	assert_true(
		controller != null and encounter != null,
		"PS-181 richiede RunController e BossEncounter dalla scena."
	)
	if controller == null or encounter == null:
		return {}

	if not controller.is_terminal():
		controller.request_defeat()
	assert_true(
		movement_slice.restart_run(seed_value),
		"La fixture PS-181 deve poter avviare la run con il seed richiesto."
	)
	await wait_process_frames(2)
	controller.set_process(false)

	return {
		"movement_slice": movement_slice,
		"controller": controller,
		"encounter": encounter,
		"catalog": encounter.get_signature_catalog(),
		"player": movement_slice.get_player(),
		"targeting": movement_slice.get_targeting_system(),
	}


func _teardown_fixture(built: Dictionary) -> void:
	var movement_slice: Control = built.get("movement_slice")
	if is_instance_valid(movement_slice):
		movement_slice.free()
