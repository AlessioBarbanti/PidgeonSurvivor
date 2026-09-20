extends GutGameplayTest

## PS-170 — Selettore di difficolta' nelle impostazioni (tab GIOCO). Copre la
## persistenza con fallback sicuro, lo snapshot immutabile della run, la
## composizione numerica sopra le curve esistenti e il fatto che la sequenza
## a parita' di seed non cambi fra i livelli.

const RUN_SEED := 4242
const SAMPLE_ENEMIES := 12
const PROBE_SETTINGS_PATH := "user://test_ps170_difficulty.cfg"
## 1.25 / 0.80: il rapporto atteso fra DIFFICILE e FACILE su ogni valore di
## HP, qualunque sia l'archetipo estratto.
const HARD_OVER_EASY := 1.5625


func test_difficulty_choice_persists_and_falls_back_to_normal() -> void:
	var movement_slice := await instantiate_movement_slice()
	var settings := movement_slice.get_difficulty_settings() as DifficultySettings
	assert_true(settings != null, "PS-170 richiede il nodo delle impostazioni di difficolta'.")
	if settings == null:
		return

	var profiles := settings.get_profiles()
	assert_eq(profiles.size(), 4, "Il catalogo deve dichiarare esattamente i quattro profili.")
	if profiles.size() != 4:
		return

	# Un nodo di prova con un file dedicato: il test non tocca la scelta reale
	# del giocatore ne' il file di configurazione della sessione.
	DirAccess.remove_absolute(PROBE_SETTINGS_PATH)
	var first_session := _build_probe(profiles)
	await wait_process_frames(1)
	assert_eq(
		first_session.get_selected_profile_id(), &"normal",
		"Senza file di configurazione il primo avvio deve usare normal."
	)
	assert_true(first_session.select_profile(&"hard"), "hard deve essere selezionabile.")

	var second_session := _build_probe(profiles)
	await wait_process_frames(1)
	assert_eq(
		second_session.get_selected_profile_id(), &"hard",
		"Una scelta valida deve sopravvivere alla sessione."
	)

	# Id inesistente nel file: ritorno sicuro a normal, non un profilo nullo.
	var corrupted := ConfigFile.new()
	corrupted.set_value(
		DifficultySettings.SETTINGS_SECTION,
		DifficultySettings.PROFILE_ID_KEY,
		"profilo_che_non_esiste"
	)
	assert_eq(corrupted.save(PROBE_SETTINGS_PATH), OK, "Il file di prova deve essere scrivibile.")

	var recovered_session := _build_probe(profiles)
	await wait_process_frames(1)
	assert_eq(
		recovered_session.get_selected_profile_id(), &"normal",
		"Un id corrotto deve ricadere su normal invece di lasciare la scelta vuota."
	)
	assert_true(
		recovered_session.get_selected_profile() != null,
		"get_selected_profile() non deve mai tornare null con un catalogo valido."
	)
	DirAccess.remove_absolute(PROBE_SETTINGS_PATH)


func test_difficulty_selector_shows_every_option_and_greys_out_during_a_run() -> void:
	var movement_slice := await instantiate_movement_slice()
	var overlay := movement_slice.get_settings_overlay() as SettingsOverlay
	var settings := movement_slice.get_difficulty_settings() as DifficultySettings
	var controller := movement_slice.get_run_controller() as RunController
	assert_true(
		overlay != null and settings != null and controller != null,
		"PS-170 richiede overlay impostazioni, registro e run controller."
	)
	if overlay == null or settings == null or controller == null:
		return

	controller.set_process(false)

	assert_eq(
		overlay.get_difficulty_option_labels(),
		["FACILE", "NORMALE", "DIFFICILE", "PAVONE"],
		"Il selettore deve mostrare tutte e quattro le opzioni, nell'ordine dichiarato."
	)
	assert_eq(
		overlay.get_selected_difficulty_id(), settings.get_selected_profile_id(),
		"Il selettore deve evidenziare l'opzione corrente."
	)
	assert_true(
		not overlay.get_difficulty_description_text().strip_edges().is_empty(),
		"Il selettore deve mostrare la descrizione dell'opzione corrente."
	)

	# La run di test e' gia' avviata: fuori da BOOT il selettore resta
	# leggibile ma grigio, perche' la run ha gia' la sua difficolta'.
	assert_true(controller.is_running(), "Il caso richiede una run avviata.")
	assert_true(overlay.is_difficulty_locked(), "Durante una partita il selettore deve essere bloccato.")
	for profile in settings.get_profiles():
		var button := overlay.get_difficulty_button(profile.id)
		assert_true(button != null, "Ogni profilo deve avere il suo bottone.")
		if button == null:
			return
		assert_true(button.disabled, "Durante una partita ogni opzione deve essere grigia: %s" % profile.id)

	assert_true(controller.prepare_restart(), "Tornare in BOOT deve essere possibile.")
	assert_false(overlay.is_difficulty_locked(), "Fuori da una run il selettore torna utilizzabile.")
	var normal_button := overlay.get_difficulty_button(&"normal")
	assert_true(normal_button != null and not normal_button.disabled, "In BOOT le opzioni tornano attive.")


func test_difficulty_scales_pressure_without_changing_the_spawn_sequence() -> void:
	var easy_sample := await _collect_run_sample(&"easy")
	var hard_sample := await _collect_run_sample(&"hard")

	var easy_positions: Array = easy_sample["positions"]
	var hard_positions: Array = hard_sample["positions"]
	assert_true(easy_positions.size() >= 2, "Servono abbastanza spawn per confrontare la sequenza.")
	if easy_positions.size() < 2:
		return
	assert_eq(
		hard_positions, easy_positions,
		"A parita' di seed la sequenza di spawn non deve cambiare con la difficolta'."
	)

	var easy_health: Array = easy_sample["health"]
	var hard_health: Array = hard_sample["health"]
	assert_eq(hard_health.size(), easy_health.size(), "Stessa sequenza, stesso numero di nemici.")
	for index in easy_health.size():
		var easy_value: float = easy_health[index]
		var hard_value: float = hard_health[index]
		assert_true(easy_value > 0.0, "Ogni nemico deve avere HP positivi.")
		if easy_value <= 0.0:
			return
		assert_almost_eq(
			hard_value / easy_value, HARD_OVER_EASY, 0.001,
			"Fra i livelli deve variare solo la pressione, nel rapporto 1.25/0.80."
		)


func test_run_difficulty_is_an_immutable_snapshot_shown_in_the_recap() -> void:
	var movement_slice := await instantiate_movement_slice()
	var controller := movement_slice.get_run_controller() as RunController
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	var encounter := movement_slice.get_boss_encounter() as BossEncounter
	var settings := movement_slice.get_difficulty_settings() as DifficultySettings
	var end_screen := movement_slice.get_end_screen() as EndScreen
	assert_true(
		controller != null and spawner != null and encounter != null
		and settings != null and end_screen != null,
		"PS-170 richiede l'intero frontend di run."
	)
	if (
		controller == null or spawner == null or encounter == null
		or settings == null or end_screen == null
	):
		return

	controller.set_process(false)
	spawner.set_process(false)

	# persist=false: il test non scrive sulla scelta reale del giocatore.
	assert_true(settings.select_profile(&"easy", false), "easy deve essere selezionabile.")
	assert_true(controller.prepare_restart(), "Serve ripartire da BOOT per fotografare la scelta.")
	assert_true(controller.start_run(RUN_SEED), "La run di prova deve poter partire.")

	assert_almost_eq(spawner.difficulty_multiplier, 0.8, 0.0001, "Lo spawner riceve il moltiplicatore scelto.")
	assert_almost_eq(encounter.difficulty_multiplier, 0.8, 0.0001, "Anche i Boss ricevono lo stesso valore.")

	# Cambiare la scelta a run avviata non deve spostare la partita in corso.
	assert_true(settings.select_profile(&"pavone", false), "pavone deve essere selezionabile.")
	assert_almost_eq(
		spawner.difficulty_multiplier, 0.8, 0.0001,
		"Lo snapshot della run non si aggiorna quando cambiano le impostazioni."
	)
	var run_difficulty: DifficultyProfile = movement_slice.get_run_difficulty()
	assert_true(run_difficulty != null, "La run deve conoscere la propria difficolta'.")
	if run_difficulty == null:
		return
	assert_eq(run_difficulty.id, &"easy", "La run resta su quella fotografata all'avvio.")

	assert_true(controller.request_defeat(), "Il riepilogo va letto da un terminale reale.")
	assert_true(
		end_screen.get_stats_text().contains("FACILE"),
		"Il riepilogo deve mostrare l'etichetta della difficolta' giocata: %s"
		% end_screen.get_stats_text()
	)

	# Lo snapshot da solo basta a disegnare la riga: EndScreen non consulta
	# nessun sistema di gameplay vivo per sapere a che difficolta' si giocava.
	var detached_summary := RunSummary.new()
	detached_summary.difficulty_id = &"hard"
	detached_summary.difficulty_label = "DIFFICILE"
	detached_summary.level = 7
	end_screen.show_defeat(detached_summary)
	assert_true(
		end_screen.get_stats_text().contains("DIFFICILE"),
		"La riga statistiche deve nascere dal solo RunSummary: %s" % end_screen.get_stats_text()
	)

	print("PS170_DIFFICULTY_SELECTOR_SMOKE_OK")


func _build_probe(profiles: Array[DifficultyProfile]) -> DifficultySettings:
	var probe := DifficultySettings.new()
	# I profili vanno assegnati prima dell'ingresso in scena: _ready() legge
	# subito il file e deve poter risolvere l'id salvato.
	probe.profiles = profiles
	probe.settings_path = PROBE_SETTINGS_PATH
	add_child_autofree(probe)
	return probe


func _collect_run_sample(profile_id: StringName) -> Dictionary:
	var movement_slice := await instantiate_movement_slice()
	var controller := movement_slice.get_run_controller() as RunController
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	var settings := movement_slice.get_difficulty_settings() as DifficultySettings
	var sample := {"positions": [], "health": []}
	if controller == null or spawner == null or settings == null:
		return sample

	controller.set_process(false)
	spawner.set_process(false)
	settings.select_profile(profile_id, false)
	controller.prepare_restart()
	controller.start_run(RUN_SEED)

	var positions: Array = []
	var health: Array = []
	for _index in range(SAMPLE_ENEMIES):
		var enemy := spawner.try_spawn_enemy()
		if enemy == null:
			break
		positions.append(enemy.global_position.snapped(Vector2(0.01, 0.01)))
		var health_component := enemy.get_health_component()
		health.append(health_component.health_max if health_component != null else 0.0)
	sample["positions"] = positions
	sample["health"] = health
	return sample
