extends GutGameplayTest


func test_baseline_boss_uses_dedicated_sprite() -> void:
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_run_controller() as RunController
	var encounter := movement_slice.get_boss_encounter() as BossEncounter
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	assert_true(
		controller != null and encounter != null and spawner != null,
		"B30 richiede RunController, BossEncounter ed EnemySpawner dalla scena."
	)
	if controller == null or encounter == null or spawner == null:
		return

	controller.set_process(false)
	spawner.set_process(false)
	encounter.evil_boss_chance = 0.0
	controller._process(120.01)
	var boss := encounter.get_active_boss()
	assert_not_null(boss, "BOSS_INTRO deve creare il piccione speciale baseline.")
	if boss == null:
		controller.prepare_restart()
		return

	assert_true(boss.has_visual_sprite(), "Il Boss deve dichiarare di avere già un proprio sprite visivo.")
	assert_null(
		boss.get_enemy_sprite(), "Il Boss non deve possedere l'AnimatedSprite2D di riserva dei nemici base."
	)
	assert_not_null(
		boss.get_boss_visual_texture(), "Il Boss deve mostrare lo sprite dedicato invece del cerchio di riserva."
	)

	var ordinary_enemy := spawner.try_spawn_enemy()
	assert_not_null(ordinary_enemy, "Il test deve poter creare un nemico base di confronto.")
	if ordinary_enemy != null:
		assert_true(
			ordinary_enemy.has_visual_sprite(), "Un nemico base con EnemySprite deve continuare a dichiarare uno sprite visivo."
		)

	controller.prepare_restart()


func test_evil_boss_uses_dedicated_sprite_and_palette() -> void:
	var movement_slice := await instantiate_movement_slice()

	var controller := movement_slice.get_run_controller() as RunController
	var encounter := movement_slice.get_boss_encounter() as BossEncounter
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	assert_true(
		controller != null and encounter != null and spawner != null,
		"B30 richiede RunController, BossEncounter ed EnemySpawner dalla scena."
	)
	if controller == null or encounter == null or spawner == null:
		return

	controller.set_process(false)
	spawner.set_process(false)
	encounter.evil_boss_chance = 1.0
	controller._process(120.01)
	var boss := encounter.get_active_boss()
	var definition := encounter.get_active_definition()
	assert_true(boss != null and definition != null, "BOSS_INTRO deve creare un Evil quando la probabilità è 1.")
	if boss == null or definition == null:
		controller.prepare_restart()
		return

	assert_true(definition.is_evil_variant(), "La fixture al 100% deve risolvere un Evil.")
	assert_true(boss.has_visual_sprite(), "Anche l'Evil deve dichiarare di avere già un proprio sprite visivo.")
	assert_eq(
		boss.get_boss_visual_modulate(),
		BossEncounter.EVIL_SPRITE_MODULATE,
		"La palette viola/magenta Evil deve restare affidata alla modulazione dello sprite, non al cerchio."
	)
	assert_eq(
		definition.body_color,
		BossEncounter.EVIL_BODY_COLOR,
		"I dati Evil devono conservare la tinta viola scura come identità, anche se non più disegnata a cerchio."
	)

	controller.prepare_restart()
