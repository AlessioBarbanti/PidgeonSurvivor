extends GutGameplayTest

## PS-113: PerformanceProfile.target_fps era dichiarato e validato ma mai
## applicato a Engine.max_fps da nessun punto del codice, quindi il motore
## rendeva senza limite di frame — probabile causa principale di calore e
## consumo batteria su Android di fascia bassa a refresh rate alto.

const CUSTOM_TARGET_FPS := 45

var _original_max_fps := 0


func before_each() -> void:
	_original_max_fps = Engine.max_fps


func after_each() -> void:
	Engine.max_fps = _original_max_fps


func test_active_profile_caps_engine_max_fps() -> void:
	var movement_slice := await instantiate_movement_slice()

	var profile := movement_slice.get_active_performance_profile() as PerformanceProfile
	assert_not_null(profile, "PS-113 richiede un PerformanceProfile risolto per la piattaforma corrente.")
	if profile == null:
		return
	assert_eq(
		Engine.max_fps,
		profile.target_fps,
		"PS-113: Engine.max_fps deve seguire target_fps (%d) del profilo attivo." % profile.target_fps
	)

	var controller := movement_slice.get_run_controller() as RunController
	if controller != null and controller.is_running():
		controller.prepare_restart()


func test_injected_profile_target_fps_drives_engine_cap() -> void:
	# Dimostra che il cap segue il profilo iniettato, non un valore fisso
	# hardcoded altrove nella scena.
	const MOVEMENT_SLICE_SCENE := preload("res://scenes/game/movement_slice.tscn")
	var slice := MOVEMENT_SLICE_SCENE.instantiate() as Control

	var custom_profile := PerformanceProfile.new()
	custom_profile.profile_id = &"ps113_test"
	custom_profile.target_fps = CUSTOM_TARGET_FPS
	custom_profile.render_scale = 1.0
	custom_profile.max_transient_feedback = 150
	custom_profile.stress_enemy_count = 150
	custom_profile.stress_projectile_count = 200
	custom_profile.stress_pickup_count = 200
	assert_true(custom_profile.is_valid(), "PS-113: il profilo di test deve essere valido di per se'.")

	slice.set("gut_test_run_seed_override", GUT_TEST_RUN_SEED)
	slice.set("windows_performance_profile", custom_profile)
	slice.set("mobile_performance_profile", custom_profile)

	add_child_autofree(slice)
	await wait_process_frames(2)

	assert_eq(
		Engine.max_fps,
		CUSTOM_TARGET_FPS,
		(
			"PS-113: iniettando un profilo con target_fps=%d, Engine.max_fps deve seguirlo — "
			+ "se restasse al valore dei profili dati (60) il cap sarebbe hardcoded, non pilotato dal profilo."
		) % CUSTOM_TARGET_FPS
	)

	var controller := slice.get_run_controller() as RunController
	if controller != null and controller.is_running():
		controller.prepare_restart()

	print("PS113_FPS_CAP_OK")
