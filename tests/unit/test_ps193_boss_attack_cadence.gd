extends GutGameplayTest

## PS-193: il Boss deve occupare la finestra in cui ha gia' sospeso le ondate.
## Qui si verifica che la cadenza dichiarata nella card sia davvero quella usata
## dal ciclo, che il baseline resti piu' rapido di ogni Evil (PS-127) e che la
## guardia "un solo preavviso alla volta" regga anche col cooldown piu' corto.

const BOSS_DEFINITION_PATH := "res://data/bosses/first_boss.tres"
const BOSS_THRESHOLD_SECONDS := 120.01
## Valori precedenti alla card, tenuti qui per rendere la riduzione esplicita.
const PREVIOUS_INITIAL_ATTACK_DELAY := 1.5
const PREVIOUS_PATTERN_INTERVAL := 2.5
const PREVIOUS_BASELINE_PATTERN_INTERVAL := 1.6
## Ogni Signature del catalogo usa il telegraph di default: e' il terzo slot
## del ciclo Evil e quindi pesa sulla media della cadenza.
const SIGNATURE_TELEGRAPH_DURATION := 1.2


func test_resolved_attack_interval_is_shorter_and_keeps_the_baseline_gap() -> void:
	var definition := load(BOSS_DEFINITION_PATH) as BossDefinition
	assert_not_null(definition)
	if definition == null:
		return
	assert_lt(definition.initial_attack_delay, PREVIOUS_INITIAL_ATTACK_DELAY)
	assert_lt(definition.pattern_interval, PREVIOUS_PATTERN_INTERVAL)
	assert_lt(definition.baseline_pattern_interval, PREVIOUS_BASELINE_PATTERN_INTERVAL)
	assert_lt(
		definition.baseline_pattern_interval, definition.pattern_interval,
		"PS-127: il baseline resta piu' aggressivo di ogni Evil anche dopo il tuning."
	)

	var baseline_average := definition.baseline_pattern_interval + (
		definition.radial_telegraph_duration
		+ definition.targeted_telegraph_duration
		+ definition.feather_line_telegraph_duration
	) / 3.0
	var evil_average := definition.pattern_interval + (
		definition.radial_telegraph_duration
		+ definition.targeted_telegraph_duration
		+ SIGNATURE_TELEGRAPH_DURATION
	) / 3.0
	var previous_baseline_average := baseline_average + (
		PREVIOUS_BASELINE_PATTERN_INTERVAL - definition.baseline_pattern_interval
	)
	var previous_evil_average := evil_average + (
		PREVIOUS_PATTERN_INTERVAL - definition.pattern_interval
	)
	assert_lt(baseline_average, previous_baseline_average * 0.8, "Riduzione sensibile, non cosmetica.")
	assert_lt(evil_average, previous_evil_average * 0.8, "Riduzione sensibile, non cosmetica.")
	assert_lt(baseline_average, evil_average)


func test_rotation_and_single_telegraph_guard_survive_the_faster_cooldown() -> void:
	var slice := await instantiate_movement_slice()
	var controller := slice.get_run_controller() as RunController
	var encounter := slice.get_boss_encounter() as BossEncounter
	assert_true(controller != null and encounter != null)
	if controller == null or encounter == null:
		return
	controller.set_process(false)
	encounter.evil_boss_chance = 0.0
	controller._process(BOSS_THRESHOLD_SECONDS)
	var boss := encounter.get_active_boss()
	var definition := encounter.get_active_definition()
	assert_true(boss != null and definition != null and not definition.is_evil_variant())
	if boss == null or definition == null:
		return
	assert_true(encounter.complete_intro())
	boss.set_physics_process(false)
	boss.move_speed = 0.0

	boss._physics_process(definition.initial_attack_delay + 0.01)
	assert_eq(boss.get_active_pattern_id(), FirstBoss.RADIAL_VOLLEY, "La rotazione parte sempre dalla Raffica Radiale.")
	boss._physics_process(boss.get_telegraph_remaining() + 0.01)
	assert_almost_eq(
		boss.get_attack_cooldown_remaining(), definition.baseline_pattern_interval, FLOAT_TOLERANCE,
		"Il cooldown applicato dopo un'esecuzione e' quello nuovo, non un valore residuo."
	)
	boss._physics_process(definition.baseline_pattern_interval + 0.01)
	assert_eq(boss.get_active_pattern_id(), FirstBoss.TARGETED_BLAST, "Secondo slot invariato.")
	boss._physics_process(boss.get_telegraph_remaining() + 0.01)
	boss._physics_process(definition.baseline_pattern_interval + 0.01)
	assert_eq(boss.get_active_pattern_id(), FirstBoss.FEATHER_LINE, "Terzo slot invariato.")
	boss._physics_process(boss.get_telegraph_remaining() + 0.01)
	boss._physics_process(
		definition.feather_line_launch_interval * float(definition.feather_line_projectile_count) + 0.1
	)

	# La motion della Signature non e' toccata da questa card: col cooldown piu'
	# corto scade *durante* lo scatto, quindi la guardia e' l'unica cosa che
	# impedisce un secondo preavviso sopra quello in corso.
	boss.set("_signature_motion", FirstBoss.SignatureMotion.DASH)
	boss.set("_signature_motion_remaining", 30.0)
	var pattern_before_motion := boss.get_active_pattern_id()
	boss._physics_process(definition.pattern_interval + 1.0)
	assert_true(boss.is_signature_motion_active())
	assert_false(boss.is_telegraph_active(), "Nessun preavviso puo' aprirsi mentre il Boss e' ancora in movimento Signature.")
	assert_eq(boss.get_active_pattern_id(), pattern_before_motion)
	assert_eq(boss.get_attack_cooldown_remaining(), 0.0, "Il cooldown e' gia' scaduto: solo la guardia trattiene il pattern.")

	boss.set("_signature_motion_remaining", 0.0)
	boss.set("_signature_motion", FirstBoss.SignatureMotion.NONE)
	boss._physics_process(0.02)
	assert_true(boss.is_telegraph_active(), "Finita la motion il ciclo riprende subito, senza attendere un altro cooldown.")
	print("PS193_BOSS_ATTACK_CADENCE_SMOKE_OK")
