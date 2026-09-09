extends GutGameplayTest

## PS-085 — Sparo manuale come modalita' alternativa allo sparo automatico.
## Copre: parita' bit-per-bit dell'automatico anche con una mira manuale
## "spinta" in background, nessun colpo in Manuale a riposo, la direzione del
## colpo manuale che segue la mira invece del bersaglio piu' vicino, e la
## persistenza della modalita' (in-run e su disco).

const TEST_SETTINGS_PATH := "user://ps085_fire_mode_settings_gut.cfg"
const DIRECTION_TOLERANCE := 0.01


func test_manual_fire_mode() -> void:
	_remove_test_settings()
	var context := await _build_context()
	if context.is_empty():
		return
	var movement_slice: Control = context["slice"]
	var controller: RunController = context["controller"]
	var spawner: EnemySpawner = context["spawner"]
	var targeting: TargetingSystem = context["targeting"]
	var player: Player = context["player"]
	var weapon: WeaponController = context["weapon"]
	var settings: FireModeSettings = context["settings"]
	var settings_overlay: SettingsOverlay = context["settings_overlay"]

	assert_false(settings.is_manual_fire_enabled(), "PS-085: il default deve restare Automatico.")
	assert_false(weapon.is_manual_fire_enabled(), "WeaponController deve partire in Automatico.")

	controller.set_process(false)
	spawner.set_process(false)
	weapon.set_process(false)

	spawner.reset_for_run(5150)
	spawner._process(spawner.spawn_profile.initial_spawn_delay)
	assert_eq(spawner.get_alive_count(), 1, "PS-085 richiede un bersaglio spawnato per confrontare le due modalita'.")
	if spawner.get_alive_count() != 1:
		controller.prepare_restart()
		_remove_test_settings()
		return
	var enemy := spawner.get_spawned_enemies()[0]
	enemy.set_physics_process(false)
	enemy.global_position = player.global_position + Vector2(120.0, 0.0)
	assert_true(targeting.has_target(enemy), "Il bersaglio spawnato deve entrare nel TargetingSystem.")

	# --- Automatico: nessuna regressione, anche con una mira manuale gia' attiva in background ---
	weapon.reset_for_run(false)
	weapon.set_manual_aim_state(Vector2.UP, true)
	var automatic_projectile := weapon.try_fire()
	assert_true(automatic_projectile != null, "L'automatico deve continuare a colpire il bersaglio piu' vicino.")
	if automatic_projectile != null:
		assert_vector_near(
			automatic_projectile.direction, Vector2.RIGHT,
			"L'automatico deve puntare al bersaglio, ignorando una mira manuale in background.", DIRECTION_TOLERANCE
		)
		automatic_projectile.expire()

	# --- Il Manuale si attiva dal toggle dell'overlay condiviso (PS-137), non da un setter interno ---
	settings_overlay.get_manual_fire_check_button().button_pressed = true
	assert_true(settings.is_manual_fire_enabled(), "Il toggle SPARO MANUALE dell'overlay deve attivare il Manuale.")
	assert_true(weapon.is_manual_fire_enabled(), "WeaponController deve riflettere subito la modalita' Manuale.")

	# --- Manuale, a riposo: nessun colpo anche con bersaglio a portata e cooldown pronto ---
	weapon.reset_for_run(false)
	assert_true(
		weapon.try_fire() == null,
		"Il Manuale non deve sparare mentre il giocatore non sta mirando, anche con un bersaglio a portata."
	)

	# --- La mira reale (joystick touch dedicato) attraversa l'intera pipeline
	# TouchJoystick -> InputRouter -> movement_slice -> WeaponController, non
	# solo la gate interna di WeaponController esercitata sopra/sotto ---
	var aim_joystick: TouchJoystick = movement_slice.get_aim_touch_joystick()
	assert_true(aim_joystick != null, "PS-085 richiede l'AimTouchJoystick nella scena.")
	if aim_joystick != null:
		assert_true(
			aim_joystick.dynamic_origin, "Il joystick di mira deve usare un'origine dinamica come quello di movimento."
		)
		assert_true(
			aim_joystick.is_capture_enabled(), "Il Manuale attivo deve abilitare la cattura del joystick di mira."
		)
		var aim_capture_rect: Rect2 = movement_slice.get_aim_touch_joystick_capture_rect()
		assert_true(aim_capture_rect.has_area(), "Il Manuale deve produrre una zona di acquisizione valida per la mira.")
		var aim_origin: Vector2 = aim_capture_rect.get_center()
		aim_joystick._input(make_touch_event(9, true, aim_origin))
		assert_eq(aim_joystick.active_finger_index, 9, "Il tocco valido deve possedere il joystick di mira.")
		assert_false(weapon.is_manually_aiming(), "Il tocco iniziale, ancora a riposo, non deve far mirare.")
		var aim_drag_position: Vector2 = aim_origin + Vector2.RIGHT * aim_joystick.base_radius
		aim_joystick._input(make_drag_event(9, aim_drag_position, Vector2.ZERO))
		assert_true(weapon.is_manually_aiming(), "Il drag oltre la deadzone deve far mirare attivamente.")
		var touch_projectile := weapon.try_fire()
		assert_true(touch_projectile != null, "La mira touch attiva deve permettere il fuoco manuale.")
		if touch_projectile != null:
			assert_vector_near(
				touch_projectile.direction, Vector2.RIGHT,
				"Il colpo deve seguire la direzione del joystick di mira touch.", DIRECTION_TOLERANCE
			)
			touch_projectile.expire()
		aim_joystick._input(make_touch_event(9, false, aim_drag_position))
		assert_false(weapon.is_manually_aiming(), "Il rilascio del joystick di mira deve fermare il fuoco manuale.")

		# --- Multitouch a tre contatti indipendenti: movimento, mira e
		# abilita' non devono mai rubarsi il dito a vicenda ---
		var movement_joystick: TouchJoystick = movement_slice.get_touch_joystick()
		var hud: GameHud = movement_slice.get_hud()
		var ability: AbilityController = movement_slice.get_ability_controller()
		if movement_joystick != null and hud != null and ability != null:
			var movement_capture_rect: Rect2 = movement_slice.get_touch_joystick_capture_rect()
			var aim_capture_rect_multi: Rect2 = movement_slice.get_aim_touch_joystick_capture_rect()
			assert_true(
				movement_capture_rect.has_area() and aim_capture_rect_multi.has_area(),
				"Le due zone dinamiche devono restare valide in Manuale."
			)
			var movement_origin: Vector2 = movement_capture_rect.get_center()
			var aim_origin_multi: Vector2 = aim_capture_rect_multi.get_center()
			movement_joystick._input(make_touch_event(10, true, movement_origin))
			aim_joystick._input(make_touch_event(11, true, aim_origin_multi))
			movement_joystick._input(
				make_drag_event(10, movement_origin + Vector2.UP * movement_joystick.base_radius, Vector2.ZERO)
			)
			aim_joystick._input(
				make_drag_event(11, aim_origin_multi + Vector2.DOWN * aim_joystick.base_radius, Vector2.ZERO)
			)
			assert_eq(movement_joystick.active_finger_index, 10, "Il dito di movimento deve restare proprietario del suo joystick.")
			assert_eq(aim_joystick.active_finger_index, 11, "Il dito di mira deve restare proprietario del suo joystick.")
			assert_vector_near(
				movement_joystick.movement_vector, Vector2.UP,
				"Il movimento non deve essere alterato dalla mira simultanea.", DIRECTION_TOLERANCE
			)
			assert_true(weapon.is_manually_aiming(), "La mira simultanea al movimento deve restare attiva.")
			var ability_position: Vector2 = hud.get_active_ability_button_rect().get_center()
			await _dispatch_touch_tap(12, ability_position)
			assert_true(
				ability.get_cooldown_remaining() > 0.0,
				"Il terzo dito deve attivare l'abilita' senza interferire con gli altri due."
			)
			assert_eq(movement_joystick.active_finger_index, 10, "L'abilita' non deve rubare il joystick di movimento.")
			assert_eq(aim_joystick.active_finger_index, 11, "L'abilita' non deve rubare il joystick di mira.")
			movement_joystick._input(make_touch_event(10, false, movement_origin))
			aim_joystick._input(make_touch_event(11, false, aim_origin_multi))
			assert_false(weapon.is_manually_aiming(), "Il rilascio del dito di mira deve fermare il fuoco manuale.")

	# --- Manuale, mirando via API diretta (stesso percorso di mouse/gamepad
	# in InputRouter): il colpo segue la direzione di mira, non il bersaglio piu' vicino ---
	weapon.reset_for_run(false)
	weapon.set_manual_aim_state(Vector2.UP, true)
	var manual_projectile := weapon.try_fire()
	assert_true(manual_projectile != null, "Il Manuale deve sparare mentre il giocatore mira attivamente.")
	if manual_projectile != null:
		assert_vector_near(
			manual_projectile.direction, Vector2.UP,
			"Il colpo manuale deve seguire la direzione di mira, non il bersaglio piu' vicino.", DIRECTION_TOLERANCE
		)
		manual_projectile.expire()

	# --- Rilasciare la mira ferma di nuovo il fuoco manuale ---
	weapon.reset_for_run(false)
	weapon.set_manual_aim_state(Vector2.UP, false)
	assert_true(weapon.try_fire() == null, "Il rilascio della mira deve fermare il fuoco manuale.")

	# --- La modalita' sopravvive al restart della run in corso ---
	controller.prepare_restart()
	assert_true(controller.start_run(5151), "PS-085 deve poter riavviare la run.")
	assert_true(weapon.is_manual_fire_enabled(), "Il restart della run non deve azzerare la modalita' di sparo.")
	assert_true(settings.is_manual_fire_enabled(), "FireModeSettings resta Manuale attraverso il restart.")

	# --- La modalita' sopravvive anche a una nuova istanza (persistenza su disco) ---
	var reloaded := FireModeSettings.new()
	reloaded.settings_path = TEST_SETTINGS_PATH
	add_child_autofree(reloaded)
	assert_true(reloaded.is_manual_fire_enabled(), "La modalita' Manuale deve sopravvivere a una nuova istanza.")

	# --- Il toggle dell'overlay riporta in Automatico e si propaga subito ---
	settings_overlay.get_manual_fire_check_button().button_pressed = false
	assert_false(settings.is_manual_fire_enabled(), "Il toggle pausa deve poter tornare in Automatico.")
	assert_false(weapon.is_manual_fire_enabled(), "WeaponController deve tornare in Automatico con la pausa.")

	controller.prepare_restart()
	_remove_test_settings()
	print("MANUAL_FIRE_MODE_SMOKE_OK")


func _build_context() -> Dictionary:
	# Non usa instantiate_movement_slice(): il settings_path isolato di
	# FireModeSettings va assegnato PRIMA che _ready() carichi da disco, come
	# fa test_b18p_touch_control_settings.gd per TouchControlSettings. In
	# isolamento (-FocusedSmoke) pero' manca il reset di viewport che
	# altrimenti arriva "gratis" da un test precedente nello stesso processo
	# batch: senza queste due righe get_tree().root resta al minimo headless
	# (64x64) e ogni rect letto dalla HUD (es. il pulsante abilita') risulta
	# fuori schermo.
	get_tree().root.content_scale_size = INITIAL_VIEWPORT_SIZE
	get_tree().root.size = INITIAL_VIEWPORT_SIZE
	await wait_process_frames(2)
	var movement_slice := MOVEMENT_SLICE_SCENE.instantiate() as Control
	movement_slice.set("gut_test_run_seed_override", GUT_TEST_RUN_SEED)
	var settings := movement_slice.get_node_or_null("FireModeSettings") as FireModeSettings
	assert_true(settings != null, "PS-085 richiede FireModeSettings nella scena.")
	if settings == null:
		movement_slice.free()
		return {}
	settings.settings_path = TEST_SETTINGS_PATH
	add_child_autofree(movement_slice)
	await wait_process_frames(2)

	var controller := movement_slice.get_run_controller() as RunController
	var spawner := movement_slice.get_enemy_spawner() as EnemySpawner
	var targeting := movement_slice.get_node_or_null("TargetingSystem") as TargetingSystem
	var player := movement_slice.get_player() as Player
	var weapon := movement_slice.get_weapon_controller() as WeaponController
	var settings_overlay := movement_slice.get_settings_overlay() as SettingsOverlay
	assert_true(
		controller != null and spawner != null and targeting != null and player != null
		and weapon != null and settings_overlay != null,
		"PS-085 richiede tutte le dipendenze della scena composta."
	)
	if (
		controller == null or spawner == null or targeting == null or player == null
		or weapon == null or settings_overlay == null
	):
		return {}
	assert_true(controller.is_running(), "La fixture PS-085 deve avviare la run.")
	if not controller.is_running():
		return {}
	return {
		"slice": movement_slice,
		"controller": controller,
		"spawner": spawner,
		"targeting": targeting,
		"player": player,
		"weapon": weapon,
		"settings": settings,
		"settings_overlay": settings_overlay,
	}


func _dispatch_touch_tap(index: int, position: Vector2) -> void:
	Input.parse_input_event(make_touch_event(index, true, position))
	await wait_process_frames(1)
	Input.parse_input_event(make_touch_event(index, false, position))
	await wait_process_frames(1)


func _remove_test_settings() -> void:
	var absolute_path := ProjectSettings.globalize_path(TEST_SETTINGS_PATH)
	if FileAccess.file_exists(absolute_path):
		DirAccess.remove_absolute(absolute_path)
