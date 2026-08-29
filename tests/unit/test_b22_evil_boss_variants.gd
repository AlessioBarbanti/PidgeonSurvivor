extends GutGameplayTest


func test_evil_boss_resolver_contract() -> void:
	var movement_slice := await instantiate_movement_slice()

	var encounter := movement_slice.get_boss_encounter() as BossEncounter
	var registry := movement_slice.get_friend_registry() as FriendRegistry
	var controller := movement_slice.get_run_controller() as RunController
	assert_not_null(encounter, "B22 richiede BossEncounter.")
	assert_true(
		registry != null and registry.get_definitions().size() == 8, "B22 richiede gli otto profili Evil."
	)
	if encounter == null or registry == null:
		return

	controller.set_process(false)

	var baseline := encounter.boss_definition
	assert_true(baseline != null and baseline.is_valid(), "Il Boss baseline deve essere valido.")
	if baseline == null:
		return
	assert_eq(baseline.id, &"special_pigeon", "B22 deve usare il piccione speciale come baseline.")
	assert_false(baseline.is_evil_variant(), "Il piccione baseline non deve essere una variante Evil.")
	assert_not_null(baseline.get_visual_texture(), "Il piccione speciale deve avere uno sprite runtime.")
	assert_eq(
		BossEncounter.resolve_variant(baseline, [], 77, 0, 1.0), baseline,
		"Un catalogo Evil vuoto deve ricadere sul piccione speciale."
	)

	encounter.evil_boss_chance = 0.0
	for seed_value in range(1, 65):
		assert_eq(
			encounter.resolve_definition_for_event(seed_value, 0), baseline,
			"evil_boss_chance=0 deve sempre scegliere il piccione speciale."
		)

	encounter.evil_boss_chance = 1.0
	var covered_profiles: Dictionary = {}
	for seed_value in range(1, 2049):
		var resolved := encounter.resolve_definition_for_event(seed_value, 0)
		assert_true(
			resolved != null and resolved.is_evil_variant(), "evil_boss_chance=1 deve sempre scegliere un Evil."
		)
		if resolved == null or not resolved.is_evil_variant():
			continue
		var friend := resolved.friend_profile
		assert_true(
			friend != null and registry.resolve_definition(friend.id) == friend,
			"Ogni Evil deve provenire dal FriendRegistry autorevole."
		)
		if friend == null:
			continue
		covered_profiles[friend.id] = true
		assert_eq(resolved.id, StringName("evil_%s" % friend.id), "L'ID Evil deve derivare dal profilo.")
		assert_eq(
			resolved.get_safe_title(), friend.get_public_evil_display_name(),
			"Il titolo deve rispettare la convenzione Evil <Nome>."
		)
		assert_eq(
			resolved.get_visual_texture(), friend.get_gameplay_idle_right(),
			"La variante Evil deve riusare lo sprite gameplay del Player."
		)
		assert_true(
			_same_gameplay_contract(resolved, baseline), "La variante Evil non deve cambiare il gameplay Boss."
		)
	assert_eq(covered_profiles.size(), 8, "La selezione seed deve coprire tutti gli otto Evil.")

	var first := encounter.resolve_definition_for_event(220022, 3)
	var second := encounter.resolve_definition_for_event(220022, 3)
	assert_true(
		first != null
		and second != null
		and first.id == second.id
		and first.friend_profile == second.friend_profile,
		"Seed e indice soglia uguali devono risolvere lo stesso Evil."
	)

	encounter.evil_boss_chance = 0.25
	var evil_count := 0
	for seed_value in range(1, 401):
		if encounter.resolve_definition_for_event(seed_value, 0).is_evil_variant():
			evil_count += 1
	assert_true(
		evil_count >= 70 and evil_count <= 130,
		"Il default 25% deve produrre una distribuzione plausibile e deterministica."
	)

	controller.prepare_restart()


func test_evil_boss_two_run_cycle() -> void:
	var movement_slice := await instantiate_movement_slice()

	var encounter := movement_slice.get_boss_encounter() as BossEncounter
	var controller := movement_slice.get_run_controller() as RunController
	var director := movement_slice.get_game_director() as GameDirector
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	var experience := movement_slice.get_experience_system() as ExperienceSystem
	var boss_ui := movement_slice.get_boss_ui() as BossUI
	assert_true(controller != null and controller.is_running(), "La fixture B22 deve iniziare in RUNNING.")
	if (
		encounter == null
		or controller == null
		or director == null
		or spawner == null
		or experience == null
		or boss_ui == null
	):
		return

	controller.set_process(false)
	spawner.set_process(false)

	var baseline := encounter.boss_definition
	encounter.evil_boss_chance = 1.0
	for run_index in range(2):
		controller._process(240.01)
		var boss := encounter.get_active_boss()
		var definition := encounter.get_active_definition()
		assert_eq(
			controller.get_state(), RunController.RunState.BOSS_INTRO, "Ogni soglia deve aprire BOSS_INTRO."
		)
		assert_true(boss != null and definition != null, "Ogni run deve creare un solo Boss risolto.")
		if boss == null or definition == null:
			return
		assert_true(definition.is_evil_variant(), "La fixture composta al 100% deve creare un Evil.")
		assert_eq(boss.get_definition(), definition, "FirstBoss deve consumare la definizione risolta.")
		assert_true(
			_same_gameplay_contract(definition, baseline), "Il Boss composto deve conservare il gameplay baseline."
		)
		assert_true(
			boss.get_boss_visual_texture() == definition.get_visual_texture()
			and boss.get_boss_visual_modulate() == BossEncounter.EVIL_SPRITE_MODULATE,
			"Lo sprite Evil deve usare il Player con palette viola/magenta."
		)
		assert_eq(
			boss_ui.get_intro_title_text(), definition.get_safe_title().to_upper(),
			"La UI deve mostrare il titolo Evil risolto."
		)
		assert_eq(
			get_tree().get_nodes_in_group(&"bosses").size(), 1, "Può esistere un solo Boss attivo."
		)
		assert_true(encounter.complete_intro(), "L'intro B22 deve poter terminare.")
		var health := boss.get_health_component()
		assert_not_null(health, "Il Boss Evil deve conservare HealthComponent.")
		if health == null:
			return
		assert_true(boss.take_damage(health.health_current), "Il danno letale deve sconfiggere l'Evil.")
		assert_false(boss.take_damage(1.0), "La ricompensa non deve poter essere attivata due volte.")
		assert_eq(
			experience.experience_total, baseline.experience_reward,
			"Ogni run deve assegnare una sola ricompensa baseline."
		)
		await wait_process_frames(2)
		assert_null(encounter.get_active_boss(), "Il Boss sconfitto non deve restare attivo.")
		assert_false(director.has_blocking_boss_event(), "La sconfitta deve rilasciare il lock Boss.")
		assert_eq(
			movement_slice.get_boss_projectile_parent().get_child_count(), 0,
			"Il terminale deve ripulire i proiettili Boss."
		)
		if run_index == 0:
			assert_true(
				controller.request_defeat(), "La fixture deve poter chiudere la run in DEFEAT per il restart."
			)
			assert_true(movement_slice.restart_run(220023), "Il DEFEAT deve avviare una seconda run.")
			await wait_process_frames(2)
			controller.set_process(false)
			assert_eq(experience.experience_total, 0, "Il restart deve azzerare la ricompensa precedente.")
			assert_null(
				encounter.get_active_definition(), "Il restart non deve conservare la variante precedente."
			)

	if is_instance_valid(controller):
		controller.prepare_restart()


func _same_gameplay_contract(candidate: BossDefinition, baseline: BossDefinition) -> bool:
	return (
		is_equal_approx(candidate.health_max, baseline.health_max)
		and is_equal_approx(candidate.move_speed, baseline.move_speed)
		and is_equal_approx(candidate.collision_radius, baseline.collision_radius)
		and is_equal_approx(candidate.contact_damage, baseline.contact_damage)
		and candidate.experience_reward == baseline.experience_reward
		and is_equal_approx(candidate.initial_attack_delay, baseline.initial_attack_delay)
		and is_equal_approx(candidate.pattern_interval, baseline.pattern_interval)
		and is_equal_approx(candidate.radial_telegraph_duration, baseline.radial_telegraph_duration)
		and candidate.radial_projectile_count == baseline.radial_projectile_count
		and is_equal_approx(candidate.radial_projectile_damage, baseline.radial_projectile_damage)
		and is_equal_approx(candidate.radial_projectile_speed, baseline.radial_projectile_speed)
		and is_equal_approx(candidate.radial_projectile_lifetime, baseline.radial_projectile_lifetime)
		and is_equal_approx(candidate.radial_projectile_radius, baseline.radial_projectile_radius)
		and is_equal_approx(candidate.targeted_telegraph_duration, baseline.targeted_telegraph_duration)
		and is_equal_approx(candidate.targeted_blast_radius, baseline.targeted_blast_radius)
		and is_equal_approx(candidate.targeted_blast_damage, baseline.targeted_blast_damage)
	)
