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
	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	root.add_child(movement_slice)
	await _wait_processed_frame()

	var encounter := movement_slice.get_boss_encounter() as BossEncounter
	var registry := movement_slice.get_friend_registry() as FriendRegistry
	var controller := movement_slice.get_run_controller() as RunController
	var director := movement_slice.get_game_director() as GameDirector
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	var experience := movement_slice.get_experience_system() as ExperienceSystem
	var boss_ui := movement_slice.get_boss_ui() as BossUI
	_expect(encounter != null, "B22 richiede BossEncounter.")
	_expect(registry != null and registry.get_definitions().size() == 8, "B22 richiede gli otto profili Evil.")
	_expect(controller != null and controller.is_running(), "La fixture B22 deve iniziare in RUNNING.")
	if (
		encounter == null
		or registry == null
		or controller == null
		or director == null
		or spawner == null
		or experience == null
		or boss_ui == null
	):
		await _finish_fixture(movement_slice)
		return

	controller.set_process(false)
	spawner.set_process(false)
	_validate_resolver(encounter, registry)
	await _validate_two_runs(
		movement_slice,
		encounter,
		controller,
		director,
		experience,
		boss_ui
	)
	await _finish_fixture(movement_slice)


func _validate_resolver(encounter: BossEncounter, registry: FriendRegistry) -> void:
	var baseline := encounter.boss_definition
	_expect(baseline != null and baseline.is_valid(), "Il Boss baseline deve essere valido.")
	if baseline == null:
		return
	_expect(baseline.id == &"special_pigeon", "B22 deve usare il piccione speciale come baseline.")
	_expect(not baseline.is_evil_variant(), "Il piccione baseline non deve essere una variante Evil.")
	_expect(baseline.get_visual_texture() != null, "Il piccione speciale deve avere uno sprite runtime.")
	_expect(
		BossEncounter.resolve_variant(baseline, [], 77, 0, 1.0) == baseline,
		"Un catalogo Evil vuoto deve ricadere sul piccione speciale."
	)

	encounter.evil_boss_chance = 0.0
	for seed_value in range(1, 65):
		_expect(
			encounter.resolve_definition_for_event(seed_value, 0) == baseline,
			"evil_boss_chance=0 deve sempre scegliere il piccione speciale."
		)

	encounter.evil_boss_chance = 1.0
	var covered_profiles: Dictionary = {}
	for seed_value in range(1, 2049):
		var resolved := encounter.resolve_definition_for_event(seed_value, 0)
		_expect(resolved != null and resolved.is_evil_variant(), "evil_boss_chance=1 deve sempre scegliere un Evil.")
		if resolved == null or not resolved.is_evil_variant():
			continue
		var friend := resolved.friend_profile
		_expect(
			friend != null and registry.resolve_definition(friend.id) == friend,
			"Ogni Evil deve provenire dal FriendRegistry autorevole."
		)
		if friend == null:
			continue
		covered_profiles[friend.id] = true
		_expect(resolved.id == StringName("evil_%s" % friend.id), "L'ID Evil deve derivare dal profilo.")
		_expect(
			resolved.get_safe_title() == friend.get_public_evil_display_name(),
			"Il titolo deve rispettare la convenzione Evil <Nome>."
		)
		_expect(
			resolved.get_visual_texture() == friend.get_gameplay_idle_right(),
			"La variante Evil deve riusare lo sprite gameplay del Player."
		)
		_expect(_same_gameplay_contract(resolved, baseline), "La variante Evil non deve cambiare il gameplay Boss.")
	_expect(covered_profiles.size() == 8, "La selezione seed deve coprire tutti gli otto Evil.")

	var first := encounter.resolve_definition_for_event(220022, 3)
	var second := encounter.resolve_definition_for_event(220022, 3)
	_expect(
		first != null
		and second != null
		and first.id == second.id
		and first.friend_profile == second.friend_profile,
		"Seed e indice soglia uguali devono risolvere lo stesso Evil."
	)

	encounter.evil_boss_chance = 0.25
	var evil_count := 0
	var first_default_evil_seed := -1
	for seed_value in range(1, 401):
		if encounter.resolve_definition_for_event(seed_value, 0).is_evil_variant():
			evil_count += 1
			if first_default_evil_seed < 0:
				first_default_evil_seed = seed_value
	_expect(evil_count >= 70 and evil_count <= 130, "Il default 25% deve produrre una distribuzione plausibile e deterministica.")
	print("B22_DEFAULT_EVIL_SEED seed=%d" % first_default_evil_seed)
	var probe_start := int(Time.get_unix_time_from_system()) + 15
	var next_evil_seed := -1
	for seed_value in range(probe_start, probe_start + 120):
		if encounter.resolve_definition_for_event(seed_value, 0).is_evil_variant():
			next_evil_seed = seed_value
			break
	print("B22_NEXT_EVIL_SEED seed=%d" % next_evil_seed)


func _validate_two_runs(
	movement_slice: Control,
	encounter: BossEncounter,
	controller: RunController,
	director: GameDirector,
	experience: ExperienceSystem,
	boss_ui: BossUI
) -> void:
	var baseline := encounter.boss_definition
	encounter.evil_boss_chance = 1.0
	for run_index in range(2):
		controller._process(240.01)
		var boss := encounter.get_active_boss()
		var definition := encounter.get_active_definition()
		_expect(controller.get_state() == RunController.RunState.BOSS_INTRO, "Ogni soglia deve aprire BOSS_INTRO.")
		_expect(boss != null and definition != null, "Ogni run deve creare un solo Boss risolto.")
		if boss == null or definition == null:
			return
		_expect(definition.is_evil_variant(), "La fixture composta al 100% deve creare un Evil.")
		_expect(boss.get_definition() == definition, "FirstBoss deve consumare la definizione risolta.")
		_expect(_same_gameplay_contract(definition, baseline), "Il Boss composto deve conservare il gameplay baseline.")
		_expect(
			boss.get_boss_visual_texture() == definition.get_visual_texture()
			and boss.get_boss_visual_modulate() == BossEncounter.EVIL_SPRITE_MODULATE,
			"Lo sprite Evil deve usare il Player con palette viola/magenta."
		)
		_expect(
			boss_ui.get_intro_title_text() == definition.get_safe_title().to_upper(),
			"La UI deve mostrare il titolo Evil risolto."
		)
		_expect(get_nodes_in_group(&"bosses").size() == 1, "Può esistere un solo Boss attivo.")
		_expect(encounter.complete_intro(), "L'intro B22 deve poter terminare.")
		var health := boss.get_health_component()
		_expect(health != null, "Il Boss Evil deve conservare HealthComponent.")
		if health == null:
			return
		_expect(boss.take_damage(health.health_current), "Il danno letale deve sconfiggere l'Evil.")
		_expect(not boss.take_damage(1.0), "La ricompensa non deve poter essere attivata due volte.")
		_expect(
			experience.experience_total == baseline.experience_reward,
			"Ogni run deve assegnare una sola ricompensa baseline."
		)
		await _wait_processed_frame()
		_expect(encounter.get_active_boss() == null, "Il Boss sconfitto non deve restare attivo.")
		_expect(not director.has_blocking_boss_event(), "La sconfitta deve rilasciare il lock Boss.")
		_expect(
			movement_slice.get_boss_projectile_parent().get_child_count() == 0,
			"Il terminale deve ripulire i proiettili Boss."
		)
		if run_index == 0:
			_expect(controller.request_defeat(), "La fixture deve poter chiudere la run in DEFEAT per il restart.")
			_expect(movement_slice.restart_run(220023), "Il DEFEAT deve avviare una seconda run.")
			await _wait_processed_frame()
			controller.set_process(false)
			_expect(experience.experience_total == 0, "Il restart deve azzerare la ricompensa precedente.")
			_expect(encounter.get_active_definition() == null, "Il restart non deve conservare la variante precedente.")


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


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _wait_processed_frame() -> void:
	await process_frame
	await process_frame


func _finish_fixture(movement_slice: Control) -> void:
	var controller := movement_slice.get_run_controller() as RunController
	if controller != null:
		controller.prepare_restart()
	paused = false
	movement_slice.queue_free()
	await process_frame
	if _failures.is_empty():
		print("B22_EVIL_BOSS_VARIANTS_SMOKE_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	printerr("B22_EVIL_BOSS_VARIANTS_SMOKE_FAIL count=%d" % _failures.size())
	quit(1)
