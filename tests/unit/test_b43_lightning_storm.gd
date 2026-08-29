extends GutGameplayTest

## B43 — Tempesta di Tuoni con decisione.
##
## Estende il contratto B18E: l'attiva non e' piu' un wipe globale ma una
## sequenza di fulmini telegrafati su posizioni fisse. Qui si verifica che i
## bersagli siano risolti per posizione, che il tetto di contributo al Boss
## resti sotto il 50% della sua vita per finestra a ogni rank, che il budget
## di flash non cresca con il numero di fulmini e che pausa, morte e restart
## non producano impatti tardivi.

const ENEMY_SCENE := preload("res://scenes/actors/base_enemy.tscn")
const BOSS_SCENE := preload("res://scenes/actors/first_boss.tscn")
const STORM_DEFINITION := preload("res://data/abilities/zat_lightning_storm.tres")
const BOSS_DEFINITION := preload("res://data/bosses/first_boss.tres")
const DIRECTOR_PROFILE := preload("res://data/director_profiles/default_game_director_profile.tres")
const RUN_SEED := 4307
const STORM_FLOAT_TOLERANCE := 0.002
const BOSS_CONTRIBUTION_CEILING := 0.5


func after_each() -> void:
	# La pausa manuale del run controller nel test runtime pausa l'intero
	# SceneTree: senza questo reset resterebbe pausato per i test successivi.
	get_tree().paused = false


## Criterio numerico B43: anche nel caso peggiore — il Boss dentro l'area di
## ogni fulmine di ogni attivazione della finestra — l'attiva non puo' valere
## meta' della vita del Boss.
func test_boss_contribution_ceiling() -> void:
	var boss_window := DIRECTOR_PROFILE.get_effective_recurring_boss_window()
	_assert_float_near(boss_window, 240.0, "La finestra Boss di riferimento deve restare 240 s.")
	_assert_float_near(BOSS_DEFINITION.health_max, 2400.0, "Il Boss di riferimento deve avere 2400 HP.")
	for rank in range(1, 6):
		var ranked := STORM_DEFINITION.resolve_rank(rank)
		assert_not_null(ranked, "Il rank %d deve essere risolvibile." % rank)
		if ranked == null:
			continue
		var contribution := ThunderStorm.calculate_boss_window_contribution_ratio(ranked, boss_window)
		assert_true(
			contribution < BOSS_CONTRIBUTION_CEILING,
			(
				"Il rank %d contribuisce %.1f%% della vita del Boss per finestra: deve restare sotto il %d%%."
				% [rank, contribution * 100.0, int(BOSS_CONTRIBUTION_CEILING * 100.0)]
			)
		)
		assert_true(contribution > 0.0, "Il rank %d deve comunque contribuire alla vita del Boss." % rank)


## I cinque rank restano snapshot completi e devono progredire in modo
## monotono su fulmini, raggio e ricarica.
func test_rank_progression_is_monotonic() -> void:
	var previous_strikes := 0
	var previous_radius := 0.0
	var previous_cooldown := INF
	for rank in range(1, 6):
		var ranked := STORM_DEFINITION.resolve_rank(rank)
		if ranked == null:
			continue
		var strikes := ThunderStorm.resolve_strike_count(ranked)
		assert_true(strikes >= previous_strikes, "Il rank %d non deve perdere fulmini." % rank)
		assert_true(
			ranked.area_radius >= previous_radius, "Il rank %d non deve stringere il raggio del fulmine." % rank
		)
		assert_true(
			ranked.cooldown_seconds <= previous_cooldown, "Il rank %d non deve allungare la ricarica." % rank
		)
		assert_true(
			ThunderStorm.resolve_storm_duration(ranked) > 0.0,
			"Il rank %d deve dichiarare una durata di tempesta." % rank
		)
		previous_strikes = strikes
		previous_radius = ranked.area_radius
		previous_cooldown = ranked.cooldown_seconds


func test_storm_runtime_targets_by_position_with_pause_death_and_restart() -> void:
	var fixture := Node.new()
	fixture.name = "B43StormFixture"

	var controller := RunController.new()
	controller.name = "RunController"
	fixture.add_child(controller)
	controller.set_process(false)

	var targeting := TargetingSystem.new()
	targeting.name = "TargetingSystem"
	fixture.add_child(targeting)
	var effect_parent := Node2D.new()
	effect_parent.name = "AbilityEffects"
	fixture.add_child(effect_parent)
	var source := Node2D.new()
	source.name = "Zat"
	source.position = Vector2(640.0, 360.0)
	fixture.add_child(source)

	var registry := AbilityEffectRegistry.new()
	registry.definitions = [STORM_DEFINITION]
	fixture.add_child(registry)
	add_child_autofree(fixture)
	assert_true(
		registry.configure(controller, targeting, effect_parent, null, null),
		"Il registry B43 deve accettare le dipendenze."
	)
	assert_true(controller.start_run(RUN_SEED), "La fixture B43 deve avviare la run.")
	await wait_process_frames(2)

	var rank_five := STORM_DEFINITION.resolve_rank(5)
	assert_not_null(rank_five, "Il rank 5 serve al caso peggiore runtime.")
	if rank_five == null:
		return

	var strike_radius := rank_five.area_radius
	var origin := source.global_position
	# Il primo fulmine cade sempre sull'origine: un bersaglio li' e' colpito
	# di sicuro, uno lontano dalla tempesta non deve essere toccato.
	var near_enemy := await _spawn_target(fixture, targeting, false, 400.0, origin)
	var far_enemy := await _spawn_target(fixture, targeting, false, 400.0, origin + Vector2(6000.0, 0.0))
	var boss := await _spawn_target(fixture, targeting, true, 2400.0, origin)
	if near_enemy == null or far_enemy == null or boss == null:
		return

	var storm := registry.execute_effect(rank_five, source) as ThunderStorm
	assert_not_null(storm, "La Tempesta di Tuoni deve creare un effetto scene-local.")
	if storm == null:
		return

	var strike_count := ThunderStorm.resolve_strike_count(rank_five)
	var storm_duration := ThunderStorm.resolve_storm_duration(rank_five)
	var warning_seconds := rank_five.get_effect_float(&"warning_seconds", 0.45, 0.0)
	var telegraph_seconds := rank_five.get_effect_float(&"strike_telegraph_seconds", 0.85, 0.0)
	var strike_interval := storm_duration / float(strike_count)

	assert_eq(storm.get_phase(), ThunderStorm.Phase.WARNING, "La tempesta deve aprirsi dal preavviso.")
	assert_eq(storm.get_strike_count(), strike_count, "La tempesta deve pianificare %d fulmini." % strike_count)
	_assert_float_near(storm.get_strike_radius(), strike_radius, "Il raggio del fulmine deve seguire il rank.")
	_assert_float_near(
		storm.get_total_duration(),
		warning_seconds + storm_duration,
		"La tempesta deve durare preavviso piu' durata dichiarata."
	)
	_assert_float_near(storm.get_warning_remaining(), warning_seconds, "Il preavviso deve seguire il rank.")
	assert_eq(storm.get_flash_count(), 0, "Nessun flash deve accendersi prima del primo fulmine.")

	var strike_times := storm.get_strike_times()
	assert_eq(strike_times.size(), strike_count, "Ogni fulmine deve avere un istante dichiarato.")
	for index in strike_times.size():
		_assert_float_near(
			strike_times[index],
			warning_seconds + float(index) * strike_interval,
			"Il fulmine %d deve cadere a intervallo regolare." % index
		)
	# Ogni fulmine oltre il primo deve restare telegrafato per l'intera
	# finestra di reazione: e' quella che rende l'attiva una decisione.
	for index in range(1, strike_times.size()):
		assert_true(
			strike_times[index] - telegraph_seconds >= 0.0,
			"Il fulmine %d deve essere annunciato dentro la tempesta." % index
		)
		assert_true(
			strike_times[index] - strike_times[index - 1] <= telegraph_seconds,
			"Il telegrafo del fulmine %d deve aprirsi entro il colpo precedente." % index
		)

	var positions := storm.get_strike_positions()
	assert_eq(positions.size(), strike_count, "Ogni fulmine deve avere una posizione fotografata.")
	assert_true(
		positions.size() > 0 and positions[0].is_equal_approx(origin),
		"Il primo fulmine deve cadere sull'origine dell'attivazione."
	)
	var storm_radius := rank_five.get_effect_float(&"storm_radius", 320.0, 0.0)
	for index in positions.size():
		assert_true(
			positions[index].distance_to(origin) <= storm_radius + 1.0,
			"Il fulmine %d deve restare dentro il raggio della tempesta." % index
		)

	# Pausa: nessun fulmine deve cadere e nessun danno deve anticipare.
	storm._process(0.20)
	var paused_remaining := storm.get_next_strike_remaining()
	assert_true(controller.request_manual_pause(), "La fixture deve entrare in pausa manuale.")
	storm._process(2.0)
	_assert_float_near(
		storm.get_next_strike_remaining(), paused_remaining, "La pausa non deve avvicinare il prossimo fulmine."
	)
	assert_eq(storm.get_strikes_resolved(), 0, "La pausa non deve risolvere fulmini.")
	_assert_float_near(
		near_enemy.get_health_component().health_current, 400.0, "La pausa non deve anticipare il danno."
	)
	assert_true(controller.resume_run(), "La fixture deve riprendere la run.")

	# Primo fulmine: colpisce per posizione, non su tutto lo schermo.
	storm._process(paused_remaining)
	assert_true(storm.has_impacted(), "Il primo fulmine deve cadere al termine del preavviso.")
	assert_eq(storm.get_strikes_resolved(), 1, "Il preavviso deve risolvere un solo fulmine.")
	assert_eq(storm.get_phase(), ThunderStorm.Phase.STORM, "Dopo il primo colpo la tempesta e' in corso.")
	assert_eq(storm.get_flash_count(), 1, "Il primo fulmine deve accendere il flash.")
	_assert_float_near(
		near_enemy.get_health_component().health_current,
		400.0 * (1.0 - rank_five.get_effect_float(&"normal_max_health_damage_ratio", 0.7, 0.0)),
		"Il bersaglio nel raggio deve perdere la quota di vita massima dichiarata."
	)
	_assert_float_near(
		far_enemy.get_health_component().health_current, 400.0, "Un bersaglio fuori dalla tempesta non deve essere colpito."
	)
	var boss_ratio := rank_five.get_effect_float(&"boss_max_health_damage_ratio", 0.01, 0.0)
	_assert_float_near(
		boss.get_health_component().health_current,
		2400.0 * (1.0 - boss_ratio),
		"Il Boss deve perdere solo la quota per fulmine."
	)

	# Il flash resta uno e si chiude entro 0,30 s, come da B18E.
	_assert_float_near(
		storm.get_flash_max_alpha(),
		ThunderStorm.resolve_flash_max_alpha(false, OS.has_feature("android")),
		"Il flash deve usare l'alpha massimo di piattaforma."
	)
	var peak_alpha := 0.0
	for _step in 30:
		storm._process(0.01)
		peak_alpha = maxf(peak_alpha, storm.get_flash_alpha())
	assert_true(
		peak_alpha <= storm.get_flash_max_alpha() + STORM_FLOAT_TOLERANCE,
		"Il flash non deve superare l'alpha massimo dichiarato."
	)
	assert_eq(
		storm.get_flash_phase(), ThunderStorm.FlashPhase.DONE, "Il flash deve essere chiuso entro 0,30 s dall'impatto."
	)
	_assert_float_near(storm.get_flash_alpha(), 0.0, "Il flash chiuso deve essere trasparente.")
	assert_eq(storm.get_flash_rect(), Rect2(), "L'overlay fullscreen deve essere rimosso quando il flash finisce.")

	# Il resto della tempesta cade senza riaprire il budget di flash.
	storm._process(storm.get_total_duration())
	assert_eq(storm.get_flash_count(), 1, "Una attivazione deve accendere un solo flash, anche con molti fulmini.")
	assert_eq(storm.get_strikes_resolved(), strike_count, "Tutti i fulmini pianificati devono cadere entro la durata.")
	_assert_float_near(
		far_enemy.get_health_component().health_current, 400.0, "Nessun fulmine deve raggiungere un bersaglio fuori dalla tempesta."
	)
	var boss_damage := 2400.0 - boss.get_health_component().health_current
	assert_true(
		boss_damage >= 2400.0 * boss_ratio - STORM_FLOAT_TOLERANCE,
		"Il Boss sull'origine deve incassare almeno il primo fulmine."
	)
	assert_true(
		boss_damage <= 2400.0 * boss_ratio * float(strike_count) + STORM_FLOAT_TOLERANCE,
		"Il Boss non puo' incassare piu' di un colpo per fulmine pianificato."
	)
	await wait_process_frames(2)
	assert_eq(registry.get_active_effect_count(), 0, "La tempesta esaurita deve liberarsi da sola.")

	# Morte e restart non devono lasciare impatti tardivi.
	var terminal_storm := registry.execute_effect(rank_five, source) as ThunderStorm
	assert_not_null(terminal_storm, "La fixture terminale deve creare una tempesta attiva.")
	var boss_health_before_defeat := boss.get_health_component().health_current
	assert_true(controller.request_defeat(), "Lo stato terminale deve chiudere la run.")
	if terminal_storm != null:
		terminal_storm._process(10.0)
		assert_eq(terminal_storm.get_strikes_resolved(), 0, "Nessun fulmine deve cadere dopo lo stato terminale.")
	_assert_float_near(
		boss.get_health_component().health_current,
		boss_health_before_defeat,
		"Lo stato terminale non deve produrre danno tardivo."
	)
	await wait_process_frames(2)
	assert_eq(registry.get_active_effect_count(), 0, "La fine run deve ripulire la tempesta.")

	_assert_seeded_layout(controller, registry, source, rank_five, positions)


## Le posizioni escono dall'RNG seedato della run: la stessa run rigioca la
## stessa tempesta, una run diversa no.
func _assert_seeded_layout(
	controller: RunController,
	registry: AbilityEffectRegistry,
	source: Node2D,
	definition: AbilityDefinition,
	reference_positions: PackedVector2Array
) -> void:
	assert_true(controller.prepare_restart(), "La fixture deve poter preparare il restart.")
	assert_true(controller.start_run(RUN_SEED), "La seconda run deve ripartire dallo stesso seed.")
	var replay := registry.execute_effect(definition, source) as ThunderStorm
	assert_not_null(replay, "La seconda run deve poter riaprire la tempesta.")
	if replay != null:
		var replay_positions := replay.get_strike_positions()
		assert_eq(
			replay_positions.size(), reference_positions.size(), "Lo stesso seed deve pianificare lo stesso numero di fulmini."
		)
		var identical := replay_positions.size() == reference_positions.size()
		for index in mini(replay_positions.size(), reference_positions.size()):
			if not replay_positions[index].is_equal_approx(reference_positions[index]):
				identical = false
				break
		assert_true(identical, "Lo stesso seed deve rigiocare la stessa tempesta.")

	assert_true(controller.prepare_restart(), "La fixture deve poter preparare il secondo restart.")
	assert_true(controller.start_run(RUN_SEED + 1), "La terza run deve usare un seed diverso.")
	var variant := registry.execute_effect(definition, source) as ThunderStorm
	assert_not_null(variant, "La terza run deve poter riaprire la tempesta.")
	if variant != null:
		var variant_positions := variant.get_strike_positions()
		var differs := false
		for index in mini(variant_positions.size(), reference_positions.size()):
			if not variant_positions[index].is_equal_approx(reference_positions[index]):
				differs = true
				break
		assert_true(differs, "Un seed diverso deve produrre una tempesta diversa.")
	registry.clear_active_effects()


func _spawn_target(
	parent: Node,
	targeting: TargetingSystem,
	is_boss: bool,
	health_max: float,
	position: Vector2
) -> BaseEnemy:
	var target := (
		BOSS_SCENE.instantiate() as BaseEnemy
		if is_boss
		else ENEMY_SCENE.instantiate() as BaseEnemy
	)
	parent.add_child(target)
	await wait_process_frames(2)
	target.set_physics_process(false)
	target.global_position = position
	var health := target.get_health_component()
	if health == null:
		assert_true(false, "Il bersaglio fixture deve avere HealthComponent.")
		return null
	health.set_health_max(health_max)
	health.reset_to_max()
	assert_true(targeting.register_target(target), "Il bersaglio fixture deve registrarsi una volta.")
	return target


func _assert_float_near(actual: float, expected: float, text: String) -> void:
	assert_true(
		absf(actual - expected) <= STORM_FLOAT_TOLERANCE,
		"%s Atteso %.3f, ottenuto %.3f." % [text, expected, actual]
	)
