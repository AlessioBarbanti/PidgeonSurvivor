extends GutGameplayTest

## PS-124 — Gli eventi d'ondata Accerchiamento e Stormo laterale non devono
## generare meno nemici, nella propria finestra, di quanti ne genererebbe lo
## spawn ordinario nella stessa finestra allo stesso run_time: un evento
## telegrafato come minaccia non deve leggersi come una pausa.
##
## Metodo: stesso seed per la misura "evento" e per la misura "baseline
## ordinaria", cosi' lo stream RNG dello spawner e' identico fino al momento
## in cui inizia la finestra di misura (nessuno spawn viene contato durante
## la rampa fino a RUN_TIME_OFFSET: il run_time avanza solo tramite
## RunController._process, mai tramite EnemySpawner._process, cosi' il cap
## max_alive_enemies non si satura prima della finestra da misurare).

const RUN_TIME_OFFSET := 150.0
const MEASUREMENT_DT := 0.05
const MAX_TRIGGER_TICKS := 4000


func test_accerchiamento_meets_or_beats_ordinary_baseline() -> void:
	await _assert_event_not_weaker_than_baseline("res://data/wave_events/wave_event_accerchiamento.tres")


func test_stormo_laterale_meets_or_beats_ordinary_baseline() -> void:
	await _assert_event_not_weaker_than_baseline("res://data/wave_events/wave_event_stormo_laterale.tres")


func test_nido_di_tiratori_is_unchanged() -> void:
	var definition := load("res://data/wave_events/wave_event_nido_tiratori.tres") as WaveEventDefinition
	assert_not_null(definition, "Definizione Nido di tiratori mancante.")
	if definition == null:
		return
	assert_eq(
		definition.ordinary_spawn_mode,
		WaveEventDefinition.ORDINARY_MODE_UNCHANGED,
		"Nido di tiratori deve restare 'Unchanged': cambia la qualita' della minaccia, non la quantita' (PS-124 non lo tocca)."
	)

	print("PS124_WAVE_EVENT_PRESSURE_SMOKE_OK")


func _assert_event_not_weaker_than_baseline(definition_path: String) -> void:
	var real_definition := load(definition_path) as WaveEventDefinition
	assert_not_null(real_definition, "Definizione evento mancante: %s" % definition_path)
	if real_definition == null:
		return

	var baseline_count := await _measure_baseline_ordinary_spawn(real_definition.duration_seconds)
	var event_count := await _measure_event_spawn(real_definition)

	assert_true(
		event_count >= baseline_count,
		(
			"%s genera %d corpi nella propria finestra contro i %d dello spawn ordinario equivalente: "
			+ "un evento telegrafato deve essere una minaccia, non una pausa."
		) % [definition_path, event_count, baseline_count]
	)


## Nessuno scheduler coinvolto: misura quanti nemici lo spawn ordinario da
## solo genererebbe in `window_seconds` a partire da RUN_TIME_OFFSET.
func _measure_baseline_ordinary_spawn(window_seconds: float) -> int:
	var built := await _build_fixture()
	var controller: RunController = built.get("controller")
	var spawner: EnemySpawner = built.get("spawner")
	if controller == null or spawner == null:
		_teardown_fixture(built)
		return 0

	controller._process(RUN_TIME_OFFSET)
	var start_count := spawner.get_spawned_enemies().size()
	var elapsed := 0.0
	while elapsed < window_seconds:
		var step := minf(MEASUREMENT_DT, window_seconds - elapsed)
		controller._process(step)
		spawner._process(step)
		elapsed += step
	var delta := spawner.get_spawned_enemies().size() - start_count

	_teardown_fixture(built)
	return delta


## Innesca davvero `real_definition` tramite il vero WaveEventScheduler (min
## start alla soglia di misura, cooldown al minimo consentito) e misura
## quanti nemici vengono generati durante la sua fase attiva.
func _measure_event_spawn(real_definition: WaveEventDefinition) -> int:
	var built := await _build_fixture()
	var controller: RunController = built.get("controller")
	var spawner: EnemySpawner = built.get("spawner")
	var scheduler: WaveEventScheduler = built.get("scheduler")
	var director: GameDirector = built.get("director")
	if controller == null or spawner == null or scheduler == null or director == null:
		_teardown_fixture(built)
		return 0

	var events: Array[WaveEventDefinition] = [real_definition]
	var profile := WaveEventSchedulerProfile.new()
	profile.events = events
	profile.min_start_seconds = RUN_TIME_OFFSET
	profile.cooldown_min_seconds = 1.0
	profile.cooldown_max_seconds = 1.0
	scheduler.profile = profile
	scheduler.configure(controller, director, spawner)

	controller._process(RUN_TIME_OFFSET)

	var guard := 0
	while not scheduler.is_event_active() and guard < MAX_TRIGGER_TICKS:
		controller._process(MEASUREMENT_DT)
		spawner._process(MEASUREMENT_DT)
		scheduler._process(MEASUREMENT_DT)
		guard += 1
	assert_true(
		scheduler.is_event_active(),
		"%s deve entrare in fase attiva entro un tempo ragionevole." % real_definition.event_id
	)

	var start_count := spawner.get_spawned_enemies().size()
	var elapsed := 0.0
	while elapsed < real_definition.duration_seconds:
		var step := minf(MEASUREMENT_DT, real_definition.duration_seconds - elapsed)
		controller._process(step)
		spawner._process(step)
		scheduler._process(step)
		elapsed += step
	var delta := spawner.get_spawned_enemies().size() - start_count

	_teardown_fixture(built)
	return delta


func _build_fixture() -> Dictionary:
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_run_controller() as RunController
	var scheduler := movement_slice.get_wave_event_scheduler() as WaveEventScheduler
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	var director := movement_slice.get_game_director() as GameDirector
	assert_true(
		controller != null and scheduler != null and spawner != null and director != null,
		"PS-124 richiede RunController, WaveEventScheduler, EnemySpawner e GameDirector dalla scena."
	)
	if controller == null or scheduler == null or spawner == null or director == null:
		return {}

	if not controller.is_terminal():
		controller.request_defeat()
	assert_true(
		movement_slice.restart_run(124001),
		"La fixture PS-124 deve poter avviare la run con seed fisso."
	)
	await wait_process_frames(2)
	controller.set_process(false)
	spawner.set_process(false)
	scheduler.set_process(false)

	# I salti di run_time con controller._process(RUN_TIME_OFFSET) fanno
	# scattare in modo sincrono la soglia Boss reale (120s) tramite
	# run_time_changed: questo test misura solo pressione di spawn/eventi
	# d'ondata, non il Boss (stesso accorgimento di
	# test_ps008_wave_events.gd:_collect_event_sequence).
	var neutral_director_profile := director.profile.duplicate(true) as GameDirectorProfile
	neutral_director_profile.boss_thresholds_seconds = PackedFloat32Array()
	director.profile = neutral_director_profile
	director.configure(controller, spawner)

	return {
		"movement_slice": movement_slice,
		"controller": controller,
		"scheduler": scheduler,
		"spawner": spawner,
		"director": director,
	}


func _teardown_fixture(built: Dictionary) -> void:
	var controller: RunController = built.get("controller")
	if controller == null:
		return
	if not controller.is_terminal():
		controller.request_defeat()
	controller.prepare_restart()
