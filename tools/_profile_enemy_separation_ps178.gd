extends SceneTree

## PS-178: confronto CPU locale a popolazione fissa, senza soglie CI dipendenti
## dall'hardware. Eseguire da solo con --headless --script tools/_profile_enemy_separation_ps178.gd.
## Misura 20 query complete e un passo fisico; non misura rendering o Pixel 9.
const ENEMY_SCENE: PackedScene = preload("res://scenes/actors/ranged_enemy.tscn")
const DEFINITION: EnemyArchetypeDefinition = preload("res://data/enemies/enemy_archetype_ranged.tres")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for count: int in [50, 150, 250]:
		var fixture := Node2D.new()
		var controller := RunController.new()
		controller.set_process(false)
		var target := Node2D.new()
		fixture.add_child(controller)
		fixture.add_child(target)
		root.add_child(fixture)
		controller.start_run(178)
		var enemies: Array[BaseEnemy] = []
		for index in count:
			var enemy := ENEMY_SCENE.instantiate() as RangedEnemy
			enemy.position = Vector2(float(index % 20) * 30.0 + 250.0, float(index / 20) * 30.0)
			fixture.add_child(enemy)
			enemy.set_physics_process(false)
			enemy.apply_archetype_definition(DEFINITION)
			enemy.configure_ranged(DEFINITION, null)
			enemy.set_run_controller(controller)
			enemy.set_target(target)
			enemies.append(enemy)
		await physics_frame
		var checksum := Vector2.ZERO
		var start := Time.get_ticks_usec()
		for _repeat in 20:
			for enemy in enemies:
				checksum += enemy._compute_separation_velocity()
		var separation_ms := float(Time.get_ticks_usec() - start) / 20000.0
		start = Time.get_ticks_usec()
		for enemy in enemies:
			enemy._physics_process(1.0 / 60.0)
		var total_ms := float(Time.get_ticks_usec() - start) / 1000.0
		print("PS178_CPU_PROBE enemies=%d separation_batch_ms=%.3f actor_step_ms=%.3f checksum=%s" % [
			count, separation_ms, total_ms, checksum,
		])
		controller.prepare_restart()
		fixture.queue_free()
		await process_frame
		await process_frame
	quit()
