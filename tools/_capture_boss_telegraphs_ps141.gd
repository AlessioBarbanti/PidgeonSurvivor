extends SceneTree

## Cattura di sviluppo con renderer Windows reale. La scena composta viene
## congelata dopo l'avvio: i countdown sono campionati senza dipendere dal
## framerate. Non sostituisce una partita o l'approvazione percettiva owner.
const RUN_SCENE := preload("res://scenes/game/movement_slice.tscn")
const BASE := preload("res://data/bosses/first_boss.tres")
const CATALOG := preload("res://data/bosses/evil_signature_catalog.tres")
const OUT_DIR := "res://exports/ui-screenshots/ps141-boss-telegraphs"

var _slice: Control
var _boss: FirstBoss
var _player: Player
var _controller: RunController
var _encounter: BossEncounter
var _center := Vector2.ZERO
var _failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	DisplayServer.window_set_size(root.size)
	ProjectSettings.set_setting("application/run/b18o_force_welcome_for_test", true)
	_slice = RUN_SCENE.instantiate() as Control
	root.add_child(_slice)
	ProjectSettings.set_setting("application/run/b18o_force_welcome_for_test", false)
	await _frames(15)
	var lifecycle := _slice.call("get_platform_lifecycle") as PlatformLifecycle
	if lifecycle != null:
		lifecycle.get_parent().remove_child(lifecycle)
		lifecycle.free()
	var welcome := _slice.call("get_welcome_screen") as WelcomeScreen
	welcome.get_play_button().emit_signal("pressed")
	await _frames(3)
	_slice.call("start_selected_run", 141144)
	await _frames(3)
	_controller = _slice.call("get_run_controller") as RunController
	_player = _slice.call("get_player") as Player
	_encounter = _slice.call("get_boss_encounter") as BossEncounter
	var director := _slice.call("get_game_director") as GameDirector
	director.call("_evaluate_run_time", director.get_thresholds()[0])
	_boss = _encounter.get_active_boss()
	if _boss == null:
		printerr("CAPTURE_FAIL boss non creato")
		quit(1)
		return
	_encounter.complete_intro()
	_slice.process_mode = Node.PROCESS_MODE_DISABLED
	_controller.set_process(false)
	_controller.set_physics_process(false)
	_center = _encounter.get_visible_reference_rect().get_center()
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	for evil: bool in [false, true]:
		var definition := BASE.duplicate(true) as BossDefinition
		if evil:
			definition.telegraph_color = BossEncounter.EVIL_TELEGRAPH_COLOR
			definition.visual_kind = BossDefinition.VisualKind.EVIL_FRIEND
			definition.friend_profile = load("res://data/friends/alea.tres") as FriendDefinition
		_configure(definition)
		var palette := "evil" if evil else "normal"
		for pattern: StringName in [FirstBoss.RADIAL_VOLLEY, FirstBoss.TARGETED_BLAST, FirstBoss.FEATHER_LINE]:
			_configure(definition)
			_prepare(pattern)
			await _countdown("%s_%s" % [palette, pattern])
			_player.global_position = _center + Vector2(-420, 180)
			_boss.call("_execute_active_pattern")
			if pattern == FirstBoss.FEATHER_LINE:
				_boss.call("_advance_feather_line_stream", 0.01)
			for child: Node in _encounter.get_boss_projectile_parent().get_children():
				if child is BossProjectile:
					child.call("_physics_process", 0.35)
			_boss.queue_redraw()
			await _shot("%s_%s_active" % [palette, pattern])
	for signature: BossSignatureDefinition in CATALOG.signatures:
		var definition := BASE.duplicate(true) as BossDefinition
		definition.telegraph_color = BossEncounter.EVIL_TELEGRAPH_COLOR
		definition.visual_kind = BossDefinition.VisualKind.EVIL_FRIEND
		definition.friend_profile = load("res://data/friends/%s.tres" % signature.friend_id) as FriendDefinition
		definition.signature = signature
		_configure(definition)
		_prepare(FirstBoss.SIGNATURE)
		await _countdown(String(signature.id))
		# Allontana il Player dopo aver fissato la mira, evitando flash danno.
		_player.global_position = _center + Vector2(-420, 180)
		_boss.call("_execute_active_pattern")
		for area: BossSignatureArea in _boss.get_active_signature_areas():
			area.call("_advance_state", 0.18)
			area.queue_redraw()
		_boss.queue_redraw()
		await _shot("%s_active" % signature.id)
		for area: BossSignatureArea in _boss.get_active_signature_areas():
			if area.get_mode() == BossSignatureRegistry.AreaMode.TWO_PHASE_BURST:
				area.call("_advance_state", signature.get_effect_float(&"cold_seconds", 1.0) + 0.01)
				area.queue_redraw()
				await _shot("%s_detonation" % signature.id)
	print("PS141_CAPTURE_DONE" if not _failed else "CAPTURE_FAIL")
	quit(1 if _failed else 0)


func _configure(definition: BossDefinition) -> void:
	_boss.clear_attack_runtime()
	_boss.configure_boss(definition, _player, _controller, _encounter.get_boss_projectile_parent())
	_boss.configure_signature(CATALOG.get_copy_candidates(), 0, _slice.call("get_targeting_system") as TargetingSystem, _boss.get_parent())
	_boss.global_position = _center + Vector2(-110, 0)
	_player.global_position = _center + Vector2(170, 70)


func _prepare(pattern: StringName) -> void:
	_boss.set("_active_pattern_id", pattern)
	_boss.set("_targeted_position", _player.global_position)
	_boss.set("_telegraph_duration", 1.0)
	if pattern == FirstBoss.FEATHER_LINE:
		_boss.call("_begin_feather_line_telegraph")
	elif pattern == FirstBoss.SIGNATURE:
		_boss.call("_begin_signature_telegraph")


func _countdown(label: String) -> void:
	for progress: float in [0.05, 0.5, 0.95]:
		_boss.set("_telegraph_remaining", float(_boss.get("_telegraph_duration")) * (1.0 - progress))
		_boss.queue_redraw()
		await _shot("%s_%02d" % [label, roundi(progress * 100.0)])


func _shot(label: String) -> void:
	await _frames(3)
	await RenderingServer.frame_post_draw
	var screenshot := root.get_texture().get_image()
	var path := "%s/%s.png" % [OUT_DIR, label]
	var error := screenshot.save_png(path)
	_failed = _failed or error != OK or not _controller.is_running()
	print("PS141_SHOT %s error=%d size=%s" % [path, error, screenshot.get_size()])


func _frames(count: int) -> void:
	for index: int in count:
		await process_frame
