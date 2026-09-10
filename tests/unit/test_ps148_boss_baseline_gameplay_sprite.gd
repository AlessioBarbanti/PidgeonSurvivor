extends GutGameplayTest

## PS-148: il Boss baseline (Piccione Malvagio) deve mostrare sul campo lo
## sprite di gameplay ritagliato da pigeon_special.png, non il busto 256x256
## riservato alla Boss intro. Regressione introdotta da PS-129, che ha
## sostituito il contenuto di `portrait` senza disaccoppiarlo da
## `get_visual_texture()`.


func test_baseline_gameplay_sprite_is_not_the_boss_intro_portrait() -> void:
	var slice := await instantiate_movement_slice()
	var controller := slice.get_run_controller() as RunController
	var encounter := slice.get_boss_encounter() as BossEncounter
	assert_true(controller != null and encounter != null, "PS-148 richiede le dipendenze Boss della scena.")
	if controller == null or encounter == null:
		return

	controller.set_process(false)
	encounter.evil_boss_chance = 0.0
	controller._process(120.01)

	var boss := encounter.get_active_boss()
	var definition := encounter.get_active_definition()
	assert_true(
		boss != null and definition != null and not definition.is_evil_variant(),
		"evil_boss_chance=0 deve aprire il Piccione Malvagio."
	)
	if boss == null or definition == null:
		return

	assert_not_null(
		definition.sprite,
		"Il Boss baseline deve avere uno sprite di gameplay dedicato, distinto da `portrait`."
	)
	assert_eq(
		definition.get_visual_texture(), definition.sprite,
		"get_visual_texture() deve risolvere lo sprite di gameplay per il baseline, non `portrait`."
	)
	assert_ne(
		definition.get_visual_texture(), definition.get_safe_portrait(),
		"Lo sprite mostrato in game non deve coincidere col busto della Boss intro."
	)
	assert_eq(
		boss.get_boss_visual_texture(), definition.sprite,
		"Il nodo BossSprite in scena deve mostrare lo sprite di gameplay, non il ritratto."
	)

	controller.prepare_restart()
	print("PS148_BASELINE_GAMEPLAY_SPRITE_SMOKE_OK")


func test_evil_boss_gameplay_sprite_stays_the_friend_idle_texture() -> void:
	var slice := await instantiate_movement_slice()
	var controller := slice.get_run_controller() as RunController
	var encounter := slice.get_boss_encounter() as BossEncounter
	assert_true(controller != null and encounter != null, "PS-148 richiede le dipendenze Boss della scena.")
	if controller == null or encounter == null:
		return

	controller.set_process(false)
	encounter.evil_boss_chance = 1.0
	controller._process(120.01)

	var boss := encounter.get_active_boss()
	var definition := encounter.get_active_definition()
	assert_true(boss != null and definition != null and definition.is_evil_variant(), "evil_boss_chance=1 deve aprire un Evil.")
	if boss == null or definition == null:
		return
	var friend := definition.friend_profile
	assert_true(friend != null, "Ogni Evil deve avere un profilo friend valido.")
	if friend == null:
		return

	assert_eq(
		definition.get_visual_texture(), friend.get_gameplay_idle_right(),
		"PS-148 non deve toccare il ramo Evil: lo sprite resta quello idle del friend."
	)
	assert_eq(
		boss.get_boss_visual_texture(), friend.get_gameplay_idle_right(),
		"Il nodo BossSprite di un Evil deve continuare a mostrare lo sprite idle del friend."
	)

	controller.prepare_restart()
