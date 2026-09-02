extends GutGameplayTest

## PS-076: infittisce il ritmo di spawn ordinario del piccione base di un
## fattore 12/7 (~1,71x) rispetto alla baseline B28/B37 (`0,60 -> 0,12 s`,
## `18 HP`, `20` danno da contatto) e riduce HP e danno da contatto in
## proporzione inversa, cosi' che il danno atteso al Player nel tempo resti
## equivalente (stesso principio gia' usato per il budget XP in
## `EnemySpawnProfile.get_experience_reward_scale`). Questo file verifica la
## nuova baseline dichiarata, l'equivalenza del rischio atteso e l'aumento
## misurabile del ritmo di spawn rispetto alla baseline precedente.

const ENEMY_SCENE: PackedScene = preload("res://scenes/actors/base_enemy.tscn")
const SPAWN_PROFILE := preload("res://data/spawn_profiles/default_enemy_spawn_profile.tres")
const WINDOWS_PERFORMANCE_PROFILE := preload("res://data/performance/windows_performance_profile.tres")
const MOBILE_PERFORMANCE_PROFILE := preload("res://data/performance/mobile_performance_profile.tres")
const FLOAT_TOL := 0.0001

## Baseline pre-PS-076 (B28/B37), conservata qui solo come riferimento di
## confronto: non esiste piu' come risorsa nei dati correnti.
const LEGACY_BASE_SPAWN_INTERVAL := 0.6
const LEGACY_MIN_SPAWN_INTERVAL := 0.12
const LEGACY_SPAWN_ACCELERATION := 0.003
const LEGACY_MAX_ALIVE_ENEMIES := 140
const LEGACY_HEALTH_MAX := 18.0
const LEGACY_CONTACT_DAMAGE := 20.0


func test_declared_baseline_matches_data() -> void:
	var profile := SPAWN_PROFILE as EnemySpawnProfile
	var enemy := ENEMY_SCENE.instantiate() as BaseEnemy
	var health := enemy.get_node("HealthComponent") as HealthComponent
	var contact := enemy.get_node("ContactDamage") as ContactDamage

	assert_not_null(profile, "PS-076 richiede lo SpawnProfile ordinario.")
	assert_not_null(health, "PS-076 richiede la vita del nemico base dichiarata.")
	assert_not_null(contact, "PS-076 richiede il danno da contatto del nemico base dichiarato.")
	if profile == null or health == null or contact == null:
		enemy.free()
		return

	assert_almost_eq(profile.base_spawn_interval, 0.35, FLOAT_TOL, "PS-076 deve infittire la cadenza ordinaria a 0,35s.")
	assert_almost_eq(profile.min_spawn_interval, 0.07, FLOAT_TOL, "PS-076 deve infittire la cadenza bullet-hell a 0,07s.")
	assert_almost_eq(profile.spawn_acceleration, 0.00175, FLOAT_TOL, "PS-076 deve scalare l'accelerazione in proporzione.")
	assert_eq(profile.max_alive_enemies, 250, "PS-076 deve alzare il cap al nuovo limite validato dal proprietario su B18V.")
	assert_almost_eq(health.health_max, 10.0, FLOAT_TOL, "PS-076 deve ridurre la vita base del piccione a 10.")
	assert_almost_eq(contact.damage, 12.0, FLOAT_TOL, "PS-076 deve ridurre il danno da contatto del piccione a 12.")

	enemy.free()


## Il cap alzato non deve superare l'inviluppo prestazionale dichiarato da
## B18V: alzato a 250 su entrambe le piattaforme dal proprietario dopo prova
## diretta su device (Windows e Android reggono 250 nemici a 60 FPS).
func test_max_alive_enemies_stays_within_b18v_stress_envelope() -> void:
	var profile := SPAWN_PROFILE as EnemySpawnProfile
	var windows_profile := WINDOWS_PERFORMANCE_PROFILE as PerformanceProfile
	var mobile_profile := MOBILE_PERFORMANCE_PROFILE as PerformanceProfile
	assert_true(
		profile != null and windows_profile != null and mobile_profile != null,
		"PS-076 richiede profilo spawn e profili prestazionali B18V."
	)
	if profile == null or windows_profile == null or mobile_profile == null:
		return
	assert_true(
		profile.max_alive_enemies <= windows_profile.stress_enemy_count
		and profile.max_alive_enemies <= mobile_profile.stress_enemy_count,
		"Il nuovo cap non deve superare lo stress B18V gia' validato (250)."
	)
	assert_true(
		profile.max_alive_enemies > LEGACY_MAX_ALIVE_ENEMIES,
		"PS-076 deve alzare il cap rispetto alla baseline B28 (140), non lasciarlo invariato."
	)


## Verifica l'equivalenza di rischio dichiarata: la cadenza di spawn del
## nemico base sale di un fattore costante (12/7) a ogni istante di run, e
## danno da contatto/HP scendono in proporzione inversa, cosi' che il danno
## atteso al Player nel tempo resti entro una tolleranza del 5% rispetto alla
## baseline B28/B37.
func test_expected_contact_damage_per_second_stays_equivalent() -> void:
	var profile := SPAWN_PROFILE as EnemySpawnProfile
	var enemy := ENEMY_SCENE.instantiate() as BaseEnemy
	var contact := enemy.get_node("ContactDamage") as ContactDamage
	assert_not_null(profile, "Serve il profilo ordinario per il confronto di rischio.")
	assert_not_null(contact, "Serve il danno da contatto del piccione per il confronto di rischio.")
	if profile == null or contact == null:
		enemy.free()
		return

	for run_time in [0.0, 30.0, 90.0, 160.0, 240.0]:
		var legacy_interval := maxf(
			LEGACY_MIN_SPAWN_INTERVAL, LEGACY_BASE_SPAWN_INTERVAL - run_time * LEGACY_SPAWN_ACCELERATION
		)
		var new_interval := profile.get_spawn_interval(run_time)

		# Il rapporto fra le due cadenze deve restare costante (12/7) a ogni
		# istante: base, min e accelerazione sono state scalate dallo stesso
		# fattore, non solo i due estremi della curva.
		assert_almost_eq(
			legacy_interval / new_interval,
			12.0 / 7.0,
			0.01,
			"Il rapporto fra cadenza legacy e nuova deve restare 12/7 a %.0fs." % run_time
		)

		var legacy_damage_per_second := LEGACY_CONTACT_DAMAGE / legacy_interval
		var new_damage_per_second := contact.damage / new_interval
		var ratio := new_damage_per_second / legacy_damage_per_second
		assert_true(
			ratio >= 0.95 and ratio <= 1.10,
			(
				"Il danno da contatto atteso/sec a %.0fs deve restare entro tolleranza (rapporto %.3f)."
				% [run_time, ratio]
			)
		)

	enemy.free()


## Senza alcuna modifica al meccanismo B28 (basato sull'intervallo di
## riferimento, non su base/min ordinari), il budget XP/sec deve restare
## identico a prima di PS-076: la cadenza ordinaria puo' cambiare liberamente
## senza richiedere alcun ritocco a `progression_experience_multiplier` o ai
## valori di riferimento.
func test_xp_budget_per_second_is_unaffected_by_the_new_cadence() -> void:
	var profile := SPAWN_PROFILE as EnemySpawnProfile
	assert_not_null(profile, "Serve il profilo ordinario per il budget XP.")
	if profile == null:
		return
	for run_time in [0.0, 60.0, 160.0, 240.0]:
		var xp_per_second := profile.get_experience_reward_scale(run_time) / profile.get_spawn_interval(run_time)
		var target_xp_per_second := (
			profile.progression_experience_multiplier / profile.get_progression_reference_spawn_interval(run_time)
		)
		assert_almost_eq(
			xp_per_second,
			target_xp_per_second,
			FLOAT_TOL,
			"Il budget XP/sec a %.0fs deve restare quello dichiarato da B28, invariato da PS-076." % run_time
		)


## Conta gli spawn prodotti dalla stessa cadenza discreta usata da
## `EnemySpawner._process` (accumulo di delta contro l'intervallo corrente,
## reset a ogni spawn), per la baseline legacy e per il nuovo profilo, sulla
## stessa finestra temporale: il nuovo ritmo deve produrre misurabilmente piu'
## nemici nella stessa finestra, in proporzione al fattore dichiarato.
func test_ordinary_spawn_rate_increases_measurably_over_time() -> void:
	var profile := SPAWN_PROFILE as EnemySpawnProfile
	assert_not_null(profile, "Serve il profilo ordinario per contare gli spawn.")
	if profile == null:
		return

	var legacy_profile := EnemySpawnProfile.new()
	legacy_profile.base_spawn_interval = LEGACY_BASE_SPAWN_INTERVAL
	legacy_profile.min_spawn_interval = LEGACY_MIN_SPAWN_INTERVAL
	legacy_profile.spawn_acceleration = LEGACY_SPAWN_ACCELERATION

	var window_seconds := 30.0
	var delta := 0.02
	var legacy_count := _count_ordinary_spawns(legacy_profile, window_seconds, delta)
	var new_count := _count_ordinary_spawns(profile, window_seconds, delta)

	assert_true(
		new_count > legacy_count,
		"Il nuovo profilo deve produrre piu' nemici della baseline legacy in %.0fs (legacy %d, nuovo %d)."
		% [window_seconds, legacy_count, new_count]
	)
	var ratio := float(new_count) / float(legacy_count)
	assert_true(
		ratio >= 1.5 and ratio <= 1.9,
		"L'aumento del ritmo di spawn deve restare vicino al fattore dichiarato 12/7 (rapporto osservato %.2f)." % ratio
	)

	print("ENEMY_DENSITY_REBALANCE_SMOKE_OK")


## Determinismo: lo stesso seed deve produrre la stessa sequenza di spawn
## reali con il nuovo profilo, esattamente come prima di PS-076 (nessuna
## modifica alla logica dell'RNG dello spawner, solo ai dati).
func test_same_seed_produces_identical_spawn_sequence() -> void:
	var positions_a := await _spawn_positions_with_seed(4242, 12)
	var positions_b := await _spawn_positions_with_seed(4242, 12)
	assert_eq(positions_a.size(), 12, "La prima sequenza deve produrre 12 spawn.")
	assert_eq(positions_b.size(), 12, "La seconda sequenza deve produrre 12 spawn.")
	for index in mini(positions_a.size(), positions_b.size()):
		assert_vector_near(
			positions_a[index],
			positions_b[index],
			"Lo spawn #%d deve restare deterministico per lo stesso seed." % index
		)


func _count_ordinary_spawns(profile: EnemySpawnProfile, window_seconds: float, delta: float) -> int:
	var elapsed := 0.0
	var count := 0
	var t := 0.0
	while t < window_seconds:
		elapsed += delta
		var interval := profile.get_spawn_interval(t)
		if elapsed >= interval:
			count += 1
			elapsed = 0.0
		t += delta
	return count


func _spawn_positions_with_seed(seed_value: int, spawn_count: int) -> Array[Vector2]:
	var fixture := Node2D.new()
	var arena := ArenaLayout.new()
	arena.respect_display_safe_area = false
	var controller := RunController.new()
	controller.set_process(false)
	var target := Node2D.new()
	var enemy_parent := Node2D.new()
	var spawner := EnemySpawner.new()
	spawner.set_process(false)
	spawner.enemy_scene = ENEMY_SCENE
	spawner.spawn_profile = SPAWN_PROFILE
	spawner.configure(controller, arena, target, enemy_parent)
	fixture.add_child(arena)
	fixture.add_child(controller)
	fixture.add_child(target)
	fixture.add_child(enemy_parent)
	fixture.add_child(spawner)
	add_child_autofree(fixture)
	await wait_process_frames(1)
	spawner.set_process(false)
	controller.set_process(false)
	target.global_position = arena.get_playfield_rect().get_center()

	controller.start_run(seed_value)
	var positions: Array[Vector2] = []
	for _spawn_index in spawn_count:
		var enemy := spawner.try_spawn_enemy()
		if enemy != null:
			positions.append(enemy.global_position)
			enemy.set_physics_process(false)
	controller.prepare_restart()
	return positions
