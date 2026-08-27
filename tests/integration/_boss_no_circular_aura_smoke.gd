extends SceneTree

const MOVEMENT_SLICE_SCENE := preload("res://scenes/game/movement_slice.tscn")
const INITIAL_VIEWPORT_SIZE := Vector2i(1280, 720)

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	paused = false
	root.content_scale_size = INITIAL_VIEWPORT_SIZE
	root.size = INITIAL_VIEWPORT_SIZE
	await _wait_processed_frame()

	await _validate_baseline_boss()
	await _validate_evil_boss()
	await _finish()


func _validate_baseline_boss() -> void:
	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	root.add_child(movement_slice)
	await _wait_processed_frame()

	var controller := movement_slice.get_run_controller() as RunController
	var encounter := movement_slice.get_boss_encounter() as BossEncounter
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	if controller == null or encounter == null or spawner == null:
		_failures.append("B30 richiede RunController, BossEncounter ed EnemySpawner dalla scena.")
		movement_slice.queue_free()
		await process_frame
		return

	controller.set_process(false)
	spawner.set_process(false)
	encounter.evil_boss_chance = 0.0
	controller._process(240.01)
	var boss := encounter.get_active_boss()
	_expect(boss != null, "BOSS_INTRO deve creare il piccione speciale baseline.")
	if boss == null:
		controller.prepare_restart()
		movement_slice.queue_free()
		await process_frame
		return

	_expect(
		boss.has_visual_sprite(),
		"Il Boss deve dichiarare di avere già un proprio sprite visivo."
	)
	_expect(
		boss.get_enemy_sprite() == null,
		"Il Boss non deve possedere l'AnimatedSprite2D di riserva dei nemici base."
	)
	_expect(
		boss.get_boss_visual_texture() != null,
		"Il Boss deve mostrare lo sprite dedicato invece del cerchio di riserva."
	)

	var ordinary_enemy := spawner.try_spawn_enemy()
	_expect(ordinary_enemy != null, "Il test deve poter creare un nemico base di confronto.")
	if ordinary_enemy != null:
		_expect(
			ordinary_enemy.has_visual_sprite(),
			"Un nemico base con EnemySprite deve continuare a dichiarare uno sprite visivo."
		)

	controller.prepare_restart()
	paused = false
	movement_slice.queue_free()
	await process_frame


func _validate_evil_boss() -> void:
	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	root.add_child(movement_slice)
	await _wait_processed_frame()

	var controller := movement_slice.get_run_controller() as RunController
	var encounter := movement_slice.get_boss_encounter() as BossEncounter
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	if controller == null or encounter == null or spawner == null:
		_failures.append("B30 richiede RunController, BossEncounter ed EnemySpawner dalla scena.")
		movement_slice.queue_free()
		await process_frame
		return

	controller.set_process(false)
	spawner.set_process(false)
	encounter.evil_boss_chance = 1.0
	controller._process(240.01)
	var boss := encounter.get_active_boss()
	var definition := encounter.get_active_definition()
	_expect(boss != null and definition != null, "BOSS_INTRO deve creare un Evil quando la probabilità è 1.")
	if boss == null or definition == null:
		controller.prepare_restart()
		movement_slice.queue_free()
		await process_frame
		return

	_expect(definition.is_evil_variant(), "La fixture al 100% deve risolvere un Evil.")
	_expect(
		boss.has_visual_sprite(),
		"Anche l'Evil deve dichiarare di avere già un proprio sprite visivo."
	)
	_expect(
		boss.get_boss_visual_modulate() == BossEncounter.EVIL_SPRITE_MODULATE,
		"La palette viola/magenta Evil deve restare affidata alla modulazione dello sprite, non al cerchio."
	)
	_expect(
		definition.body_color == BossEncounter.EVIL_BODY_COLOR,
		"I dati Evil devono conservare la tinta viola scura come identità, anche se non più disegnata a cerchio."
	)

	controller.prepare_restart()
	paused = false
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
		print("B30_BOSS_NO_CIRCULAR_AURA_SMOKE_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	printerr("B30_BOSS_NO_CIRCULAR_AURA_SMOKE_FAIL count=%d" % _failures.size())
	quit(1)
