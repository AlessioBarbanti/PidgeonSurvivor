extends GutGameplayTest

## PS-127: il Piccione Malvagio baseline diventa un incontro raro (~10% invece
## del 50%) e deliberatamente piu' duro di ogni Evil: terzo pattern nativo
## (Scia di Piume), cooldown fra pattern piu' basso, specchio a doppio attacco
## da meta' vita. Gli otto Evil non devono cambiare in nessun modo.


func test_baseline_pattern_cycle_includes_feather_line_with_faster_cooldown() -> void:
	var slice := await instantiate_movement_slice()
	var controller := slice.get_run_controller() as RunController
	var encounter := slice.get_boss_encounter() as BossEncounter
	assert_true(controller != null and encounter != null, "PS-127 richiede le dipendenze Boss della scena.")
	if controller == null or encounter == null:
		return

	controller.set_process(false)
	encounter.evil_boss_chance = 0.0
	controller._process(120.01)

	var boss := encounter.get_active_boss()
	var definition := encounter.get_active_definition()
	assert_true(boss != null and definition != null and not definition.is_evil_variant(), "evil_boss_chance=0 deve aprire il Piccione Malvagio.")
	if boss == null or definition == null:
		return
	assert_true(encounter.complete_intro(), "L'intro deve poter terminare per far avanzare il ciclo d'attacco.")

	boss._physics_process(definition.initial_attack_delay + 0.01)
	assert_eq(boss.get_active_pattern_id(), FirstBoss.RADIAL_VOLLEY, "Il primo pattern del baseline resta la Raffica Radiale.")
	boss._physics_process(boss.get_telegraph_remaining() + 0.01)
	assert_eq(boss.get_radial_volley_count(), 1, "La Raffica Radiale deve eseguirsi una volta.")
	assert_almost_eq(
		boss.get_attack_cooldown_remaining(), definition.baseline_pattern_interval, FLOAT_TOLERANCE,
		"Il baseline deve usare baseline_pattern_interval, non pattern_interval, come cooldown."
	)

	boss._physics_process(definition.baseline_pattern_interval + 0.01)
	assert_eq(boss.get_active_pattern_id(), FirstBoss.TARGETED_BLAST, "Il secondo pattern resta l'Area Mirata.")
	boss._physics_process(definition.targeted_telegraph_duration + 0.01)
	assert_eq(boss.get_targeted_blast_count(), 1, "L'Area Mirata deve eseguirsi una volta.")

	boss._physics_process(definition.baseline_pattern_interval + 0.01)
	assert_eq(
		boss.get_active_pattern_id(), FirstBoss.FEATHER_LINE,
		"PS-127: il terzo slot del ciclo baseline deve essere la Scia di Piume, non fermarsi a due pattern."
	)
	assert_true(boss.is_telegraph_active(), "La Scia di Piume deve telegrafare prima di sparare.")
	var fan_directions := boss.get_feather_line_directions()
	assert_eq(
		fan_directions.size(), definition.feather_line_count * 2,
		"Il ventaglio deve avere feather_line_count linee, ciascuna come coppia di raggi opposti."
	)
	for direction in fan_directions:
		assert_almost_eq(direction.length(), 1.0, FLOAT_TOLERANCE, "Ogni raggio del ventaglio deve essere un versore.")

	boss._physics_process(definition.feather_line_telegraph_duration + 0.01)
	assert_true(boss.is_feather_line_active(), "A fine telegraph lo stream della Scia di Piume deve avviarsi.")
	assert_eq(boss.get_feather_line_fired_count(), 0, "Nessuna piuma deve partire nello stesso frame in cui finisce il telegraph.")

	boss._physics_process(definition.feather_line_launch_interval * definition.feather_line_projectile_count + 0.1)
	assert_false(boss.is_feather_line_active(), "Lo stream deve chiudersi dopo aver lanciato tutte le piume.")
	assert_eq(
		boss.get_feather_line_fired_count(), definition.feather_line_projectile_count,
		"Devono partire esattamente i \"battiti\" del ventaglio dichiarati dai dati."
	)
	var rays_per_tick := definition.feather_line_count * 2
	assert_eq(
		boss.get_active_projectile_count(),
		definition.radial_projectile_count + rays_per_tick * definition.feather_line_projectile_count,
		"Ogni battito deve lanciare una piuma per ciascun raggio del ventaglio (linee x 2 direzioni), sommate ai proiettili radiali ancora in volo."
	)

	boss._physics_process(definition.baseline_pattern_interval + 0.01)
	assert_eq(
		boss.get_active_pattern_id(), FirstBoss.RADIAL_VOLLEY,
		"Il ciclo a tre deve richiudersi sulla Raffica Radiale, non restare bloccato sulla Scia di Piume."
	)

	controller.prepare_restart()


func test_evil_boss_keeps_original_two_common_pattern_cycle_and_cooldown() -> void:
	var slice := await instantiate_movement_slice()
	var controller := slice.get_run_controller() as RunController
	var encounter := slice.get_boss_encounter() as BossEncounter
	assert_true(controller != null and encounter != null, "PS-127 richiede le dipendenze Boss della scena.")
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
	assert_true(encounter.complete_intro(), "L'intro deve poter terminare per far avanzare il ciclo d'attacco.")

	boss._physics_process(definition.initial_attack_delay + 0.01)
	assert_eq(boss.get_active_pattern_id(), FirstBoss.RADIAL_VOLLEY, "Il primo pattern resta la Raffica Radiale.")
	boss._physics_process(boss.get_telegraph_remaining() + 0.01)
	assert_almost_eq(
		boss.get_attack_cooldown_remaining(), definition.pattern_interval, FLOAT_TOLERANCE,
		"PS-127 non deve toccare il cooldown degli Evil: resta pattern_interval, mai baseline_pattern_interval."
	)

	boss._physics_process(definition.pattern_interval + 0.01)
	assert_eq(boss.get_active_pattern_id(), FirstBoss.TARGETED_BLAST, "Il secondo pattern resta l'Area Mirata.")
	boss._physics_process(definition.targeted_telegraph_duration + 0.01)

	boss._physics_process(definition.pattern_interval + 0.01)
	assert_eq(
		boss.get_active_pattern_id(), FirstBoss.SIGNATURE,
		"Il terzo slot degli Evil resta la Signature: PS-127 non deve introdurre la Scia di Piume nel loro ciclo."
	)

	controller.prepare_restart()


func test_split_doubles_normal_attacks_on_baseline_only_and_activates_once() -> void:
	var slice := await instantiate_movement_slice()
	var controller := slice.get_run_controller() as RunController
	var encounter := slice.get_boss_encounter() as BossEncounter
	var player := slice.get_player() as Player
	assert_true(controller != null and encounter != null and player != null, "PS-127 richiede le dipendenze Boss/Player della scena.")
	if controller == null or encounter == null or player == null:
		return

	controller.set_process(false)
	encounter.evil_boss_chance = 0.0
	controller._process(120.01)

	var boss := encounter.get_active_boss()
	var definition := encounter.get_active_definition()
	assert_true(boss != null and definition != null, "La fixture deve creare il Boss baseline.")
	if boss == null or definition == null:
		return
	assert_true(encounter.complete_intro(), "L'intro deve poter terminare.")

	var boss_health := boss.get_health_component()
	assert_false(boss.is_split_active(), "Lo specchio a doppio attacco non deve essere attivo a vita piena.")
	assert_true(boss.take_damage(boss_health.health_max * 0.5), "Il danno deve portare il baseline esattamente a meta' vita.")
	assert_true(boss.is_split_active(), "A meta' vita esatta (<=split_health_ratio) lo specchio deve attivarsi.")

	# Raffica Radiale: raddoppia i proiettili spawnati (origine reale + fantasma).
	boss._physics_process(definition.initial_attack_delay + 0.01)
	boss._physics_process(boss.get_telegraph_remaining() + 0.01)
	assert_eq(
		boss.get_active_projectile_count(), definition.radial_projectile_count * 2,
		"Con lo specchio attivo la Raffica Radiale deve produrre il doppio dei proiettili."
	)

	# Area Mirata: raddoppia il danno quando il Player resta dentro entrambe le aree.
	boss._physics_process(definition.baseline_pattern_interval + 0.01)
	player.global_position = boss.get_targeted_position()
	var player_health := player.get_health_component()
	player_health.invulnerability_duration = 0.0
	player_health.clear_invulnerability()
	var health_before_blast := player_health.health_current
	boss._physics_process(definition.targeted_telegraph_duration + 0.01)
	assert_almost_eq(
		player_health.health_current, health_before_blast - definition.targeted_blast_damage * 2.0, FLOAT_TOLERANCE,
		"Con lo specchio attivo l'Area Mirata deve colpire sia dalla posizione reale sia da quella fantasma."
	)

	# Scia di Piume: raddoppia il totale di piume lanciate (ventaglio intero da entrambe le origini).
	boss._physics_process(definition.baseline_pattern_interval + 0.01)
	boss._physics_process(definition.feather_line_telegraph_duration + 0.01)
	boss._physics_process(definition.feather_line_launch_interval * definition.feather_line_projectile_count + 0.1)
	var rays_per_tick := definition.feather_line_count * 2
	assert_eq(
		boss.get_active_projectile_count(),
		definition.radial_projectile_count * 2 + rays_per_tick * definition.feather_line_projectile_count * 2,
		"Con lo specchio attivo la Scia di Piume deve raddoppiare anch'essa i proiettili totali (ventaglio da entrambe le origini)."
	)

	# Un'ulteriore perdita di vita non deve alterare uno stato gia' attivo.
	boss.take_damage(1.0)
	assert_true(boss.is_split_active(), "Lo specchio resta attivo per il resto dell'incontro.")

	controller.prepare_restart()


func test_split_never_activates_on_evil_boss() -> void:
	var slice := await instantiate_movement_slice()
	var controller := slice.get_run_controller() as RunController
	var encounter := slice.get_boss_encounter() as BossEncounter
	assert_true(controller != null and encounter != null, "PS-127 richiede le dipendenze Boss della scena.")
	if controller == null or encounter == null:
		return

	controller.set_process(false)
	encounter.evil_boss_chance = 1.0
	controller._process(120.01)

	var boss := encounter.get_active_boss()
	assert_true(boss != null, "La fixture deve creare un Boss Evil.")
	if boss == null:
		return
	assert_true(encounter.complete_intro(), "L'intro deve poter terminare.")

	var boss_health := boss.get_health_component()
	assert_true(boss.take_damage(boss_health.health_max * 0.9), "Il danno deve portare l'Evil ben sotto meta' vita.")
	assert_false(
		boss.is_split_active(),
		"Lo specchio a doppio attacco e' esclusivo del baseline: un Evil non deve mai attivarlo, a qualunque vita residua."
	)

	controller.prepare_restart()


func test_baseline_boss_chance_default_is_ten_percent() -> void:
	var slice := await instantiate_movement_slice()
	var encounter := slice.get_boss_encounter() as BossEncounter
	assert_not_null(encounter, "PS-127 richiede BossEncounter.")
	if encounter == null:
		return

	assert_almost_eq(
		encounter.evil_boss_chance, 0.9, FLOAT_TOLERANCE,
		"Il default deve rendere il baseline raro (10%) invece che paritario (50%, PS-037)."
	)

	var baseline_count := 0
	for seed_value in range(1, 401):
		if not encounter.resolve_definition_for_event(seed_value, 0).is_evil_variant():
			baseline_count += 1
	assert_true(
		baseline_count >= 15 and baseline_count <= 65,
		"Il default 10%% (PS-127) deve produrre una distribuzione plausibile e deterministica (osservato: %d/400)." % baseline_count
	)

	print("PS127_HARD_RARE_BOSS_SMOKE_OK")
