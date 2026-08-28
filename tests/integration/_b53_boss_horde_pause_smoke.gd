extends SceneTree

const MOVEMENT_SLICE_SCENE := preload("res://scenes/game/movement_slice.tscn")
const INITIAL_VIEWPORT_SIZE := Vector2i(1280, 720)
const BOSS_THRESHOLD_SECONDS := 240.01
const LARGE_TICK_SECONDS := 5.0

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	paused = false
	root.content_scale_size = INITIAL_VIEWPORT_SIZE
	root.size = INITIAL_VIEWPORT_SIZE
	await _wait_processed_frame()

	await _validate_pause_and_resume()
	await _validate_reset_on_restart_while_active()
	await _validate_deterministic_sequence()
	await _finish()


## Copre: stop con Boss attivo, nemici esistenti inalterati, nessun backlog di
## spawn, ripresa una sola volta dopo l'uscita.
func _validate_pause_and_resume() -> void:
	var built := await _build_fixture(51001)
	var movement_slice: Control = built["movement_slice"]
	var controller: RunController = built["controller"]
	var encounter: BossEncounter = built["encounter"]
	var spawner: EnemySpawner = built["spawner"]
	var experience: ExperienceSystem = built["experience"]
	if movement_slice == null:
		return

	# Nemici gia' presenti prima del Boss: devono restare tracciati invariati
	# per tutta la sospensione.
	var pre_boss_enemy := spawner.try_spawn_enemy()
	_expect(pre_boss_enemy != null, "La fixture deve poter generare un nemico prima del Boss.")
	var pre_boss_alive := spawner.get_alive_count()

	controller._process(BOSS_THRESHOLD_SECONDS)
	_expect(controller.get_state() == RunController.RunState.BOSS_INTRO, "La soglia fissa deve aprire BOSS_INTRO.")
	var boss := encounter.get_active_boss()
	_expect(boss != null, "BOSS_INTRO deve creare il Boss.")
	_expect(
		spawner.is_ordinary_spawn_suspended(),
		"Lo spawn ordinario deve sospendersi dall'ingresso effettivo del Boss."
	)
	_expect(
		spawner.get_spawned_enemies().has(pre_boss_enemy),
		"Il nemico gia' presente deve restare tracciato durante l'ingresso del Boss."
	)

	# L'intro da sola non fa scattare lo spawner (is_running() e' gia' falso in
	# BOSS_INTRO): qui si verifica che resti sospeso anche durante il combattimento
	# vero e proprio, quando il clock torna a scorrere.
	_expect(encounter.complete_intro(), "L'intro del Boss deve poter essere confermata.")
	_expect(controller.is_running(), "Dopo l'intro la run deve tornare in RUNNING con il Boss vivo.")

	spawner._process(LARGE_TICK_SECONDS)
	_expect(
		spawner.get_alive_count() == pre_boss_alive,
		"Nessun nemico ordinario deve comparire mentre il Boss e' attivo (atteso %d, ottenuto %d)."
		% [pre_boss_alive, spawner.get_alive_count()]
	)
	_expect(
		spawner.get_spawned_enemies().has(pre_boss_enemy),
		"Il nemico gia' presente deve restare invariato durante il combattimento contro il Boss."
	)

	# La morte del Boss deve riattivare lo spawner e farlo ripartire pulito,
	# con un solo nemico per tick e nessuna raffica arretrata.
	_kill_active_boss(encounter, controller, experience)
	_expect(encounter.get_active_boss() == null, "Il Boss sconfitto non deve restare attivo.")
	_expect(
		not spawner.is_ordinary_spawn_suspended(),
		"La sconfitta del Boss deve riattivare subito lo spawn ordinario."
	)

	# Un tick con un ritardo grande quanto si vuole innesca un solo evento di
	# spawn (che puo' generare piu' di un nemico se l'archetipo scelto ha un
	# cluster, comportamento ordinario invariato): la vera prova contro la
	# raffica arretrata e' che _spawn_elapsed torni a zero dopo l'evento,
	# cosicche' un tick immediatamente successivo, troppo corto per un nuovo
	# intervallo, non generi altri nemici.
	var alive_before_resume := spawner.get_alive_count()
	spawner._process(LARGE_TICK_SECONDS)
	var alive_after_one_event := spawner.get_alive_count()
	_expect(
		alive_after_one_event > alive_before_resume,
		"La ripresa deve generare almeno un nemico al primo tick dopo la sconfitta del Boss."
	)
	spawner._process(0.01)
	_expect(
		spawner.get_alive_count() == alive_after_one_event,
		(
			"Un tick troppo corto per un nuovo intervallo non deve generare altri nemici: "
			+ "un residuo qui rivelerebbe una raffica arretrata (atteso %d, ottenuto %d)."
		) % [alive_after_one_event, spawner.get_alive_count()]
	)

	await _teardown_fixture(built)


## Copre: reset pulito. Il restart in mezzo a un Boss attivo (rimosso senza
## passare da boss_defeated) non deve lasciare il flag sospeso nella run
## successiva.
func _validate_reset_on_restart_while_active() -> void:
	var built := await _build_fixture(51002)
	var movement_slice: Control = built["movement_slice"]
	var controller: RunController = built["controller"]
	var encounter: BossEncounter = built["encounter"]
	var spawner: EnemySpawner = built["spawner"]
	if movement_slice == null:
		return

	controller._process(BOSS_THRESHOLD_SECONDS)
	_expect(encounter.get_active_boss() != null, "La fixture di restart deve raggiungere BOSS_INTRO.")
	_expect(spawner.is_ordinary_spawn_suspended(), "Il Boss attivo deve sospendere lo spawner prima del restart.")

	_expect(controller.request_defeat(), "Il test deve poter forzare DEFEAT con il Boss ancora vivo.")
	_expect(
		movement_slice.restart_run(51003),
		"Il restart deve poter ripartire in-place con il Boss ancora tracciato."
	)
	await _wait_processed_frame()
	_expect(
		not spawner.is_ordinary_spawn_suspended(),
		"Il restart non deve lasciare il flag di sospensione attivo nella run successiva."
	)
	_expect(encounter.get_active_boss() == null, "Il restart deve rimuovere il Boss pendente.")

	# La nuova run deve poter generare nemici ordinari normalmente.
	var enemy := spawner.try_spawn_enemy()
	_expect(enemy != null, "Dopo il restart lo spawner deve tornare pienamente operativo.")

	await _teardown_fixture(built)


## Copre: determinismo della sequenza. Due run con lo stesso seed, entrambe
## sospese e riprese allo stesso modo attorno al Boss, devono riprodurre la
## stessa sequenza di archetipi post-ripresa.
func _validate_deterministic_sequence() -> void:
	var run_a := await _run_scripted_sequence(64002)
	var run_b := await _run_scripted_sequence(64002)
	_expect(
		run_a.size() > 0 and run_a == run_b,
		"Due run con lo stesso seed devono produrre la stessa sequenza post-ripresa attorno al Boss."
	)


func _run_scripted_sequence(seed_value: int) -> Array[float]:
	var built := await _build_fixture(seed_value)
	var movement_slice: Control = built["movement_slice"]
	var controller: RunController = built["controller"]
	var encounter: BossEncounter = built["encounter"]
	var spawner: EnemySpawner = built["spawner"]
	var experience: ExperienceSystem = built["experience"]
	var signatures: Array[float] = []
	if movement_slice == null:
		return signatures

	controller._process(BOSS_THRESHOLD_SECONDS)
	if encounter.get_active_boss() == null:
		await _teardown_fixture(built)
		return signatures
	encounter.complete_intro()
	spawner._process(LARGE_TICK_SECONDS)
	_kill_active_boss(encounter, controller, experience)
	for _tick_index in range(6):
		spawner._process(LARGE_TICK_SECONDS)
	for enemy in spawner.get_spawned_enemies():
		signatures.append(enemy.move_speed)

	await _teardown_fixture(built)
	return signatures


func _kill_active_boss(
	encounter: BossEncounter,
	controller: RunController,
	experience: ExperienceSystem
) -> void:
	var boss := encounter.get_active_boss()
	if boss == null:
		_failures.append("Impossibile uccidere un Boss assente.")
		return
	var health := boss.get_health_component()
	if health == null:
		_failures.append("Il Boss attivo deve avere una HealthComponent.")
		return
	boss.take_damage(health.health_current)
	while controller.get_state() == RunController.RunState.LEVEL_UP:
		if not experience.complete_level_up():
			break


func _build_fixture(seed_value: int) -> Dictionary:
	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	root.add_child(movement_slice)
	await _wait_processed_frame()

	var controller := movement_slice.get_run_controller() as RunController
	var encounter := movement_slice.get_boss_encounter() as BossEncounter
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	var experience := movement_slice.get_experience_system() as ExperienceSystem
	if controller == null or encounter == null or spawner == null or experience == null:
		_failures.append("B53 richiede RunController, BossEncounter, EnemySpawner ed ExperienceSystem dalla scena.")
		movement_slice.queue_free()
		await process_frame
		return {"movement_slice": null}

	# L'avvio automatico della scena usa un seed non deterministico (orologio
	# di sistema): per confrontare due run serve forzare il seed richiesto
	# passando da un terminale, come fa il flusso reale di restart.
	if not controller.is_terminal():
		controller.request_defeat()
	_expect(
		movement_slice.restart_run(seed_value),
		"La fixture B53 deve poter avviare la run con il seed richiesto."
	)
	await _wait_processed_frame()
	controller.set_process(false)
	spawner.set_process(false)

	return {
		"movement_slice": movement_slice,
		"controller": controller,
		"encounter": encounter,
		"spawner": spawner,
		"experience": experience,
	}


func _teardown_fixture(built: Dictionary) -> void:
	var movement_slice: Control = built.get("movement_slice")
	var controller: RunController = built.get("controller")
	if controller != null and not controller.is_terminal():
		controller.request_defeat()
	if controller != null:
		controller.prepare_restart()
	paused = false
	if is_instance_valid(movement_slice):
		movement_slice.queue_free()
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _wait_processed_frame() -> void:
	await process_frame
	await process_frame


func _finish() -> void:
	paused = false
	await process_frame
	if _failures.is_empty():
		print("B53_BOSS_HORDE_PAUSE_SMOKE_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	printerr("B53_BOSS_HORDE_PAUSE_SMOKE_FAIL count=%d" % _failures.size())
	quit(1)
