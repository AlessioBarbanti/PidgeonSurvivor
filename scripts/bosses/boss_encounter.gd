class_name BossEncounter
extends Node

signal boss_intro_started(boss: FirstBoss, schedule_index: int)
signal boss_intro_completed(boss: FirstBoss, schedule_index: int)
signal boss_spawned(boss: FirstBoss, schedule_index: int)
signal boss_defeated(boss: FirstBoss, experience_reward: int)

@export var boss_scene: PackedScene
@export var boss_definition: BossDefinition

var _run_controller: RunController
var _game_director: GameDirector
var _arena_layout: ArenaLayout
var _player: Player
var _enemy_parent: Node
var _boss_projectile_parent: Node
var _targeting_system: TargetingSystem
var _experience_system: ExperienceSystem
var _boss_ui: BossUI
var _active_boss: FirstBoss
var _active_schedule_index := -1
var _reward_granted := false
var _last_experience_reward := 0
var _last_defeated_title := ""


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _exit_tree() -> void:
	_clear_active_boss(false)
	_disconnect_dependencies()


func configure(
	run_controller: RunController,
	game_director: GameDirector,
	arena_layout: ArenaLayout,
	player: Player,
	enemy_parent: Node,
	boss_projectile_parent: Node,
	targeting_system: TargetingSystem,
	experience_system: ExperienceSystem,
	boss_ui: BossUI
) -> bool:
	_disconnect_dependencies()
	_run_controller = run_controller
	_game_director = game_director
	_arena_layout = arena_layout
	_player = player
	_enemy_parent = enemy_parent
	_boss_projectile_parent = boss_projectile_parent
	_targeting_system = targeting_system
	_experience_system = experience_system
	_boss_ui = boss_ui
	_connect_dependencies()
	reset_for_run()
	return has_valid_configuration()


func has_valid_configuration() -> bool:
	return (
		boss_scene != null
		and boss_definition != null
		and boss_definition.is_valid()
		and is_instance_valid(_run_controller)
		and is_instance_valid(_game_director)
		and _game_director.get_run_controller() == _run_controller
		and is_instance_valid(_arena_layout)
		and is_instance_valid(_player)
		and is_instance_valid(_enemy_parent)
		and _enemy_parent.is_inside_tree()
		and is_instance_valid(_boss_projectile_parent)
		and _boss_projectile_parent.is_inside_tree()
		and is_instance_valid(_targeting_system)
		and is_instance_valid(_experience_system)
		and _experience_system.get_run_controller() == _run_controller
		and is_instance_valid(_boss_ui)
	)


func complete_intro() -> bool:
	if (
		not is_instance_valid(_active_boss)
		or not is_instance_valid(_run_controller)
		or _run_controller.get_state() != RunController.RunState.BOSS_INTRO
	):
		return false
	var boss := _active_boss
	var schedule_index := _active_schedule_index
	_boss_ui.hide_intro()
	if not _run_controller.complete_boss_intro():
		_boss_ui.show_intro(boss_definition)
		return false
	boss_intro_completed.emit(boss, schedule_index)
	return true


func reset_for_run() -> void:
	_clear_active_boss(true)
	_reward_granted = false
	_last_experience_reward = 0
	_last_defeated_title = ""
	if is_instance_valid(_boss_ui):
		_boss_ui.reset_presentation()


func get_active_boss() -> FirstBoss:
	return _active_boss if is_instance_valid(_active_boss) else null


func get_active_schedule_index() -> int:
	return _active_schedule_index


func get_last_experience_reward() -> int:
	return _last_experience_reward


func get_last_defeated_title() -> String:
	return _last_defeated_title


func get_run_controller() -> RunController:
	return _run_controller if is_instance_valid(_run_controller) else null


func get_game_director() -> GameDirector:
	return _game_director if is_instance_valid(_game_director) else null


func get_targeting_system() -> TargetingSystem:
	return _targeting_system if is_instance_valid(_targeting_system) else null


func get_boss_ui() -> BossUI:
	return _boss_ui if is_instance_valid(_boss_ui) else null


func get_boss_projectile_parent() -> Node:
	return (
		_boss_projectile_parent
		if is_instance_valid(_boss_projectile_parent)
		else null
	)


static func calculate_spawn_position(
	playfield_rect: Rect2,
	player_position: Vector2,
	boss_radius: float
) -> Vector2:
	if not playfield_rect.has_area():
		return Vector2(INF, INF)
	var inset := maxf(boss_radius, 0.0) + 36.0
	var inner_rect := playfield_rect.grow(-inset)
	if not inner_rect.has_area():
		return playfield_rect.get_center()
	var candidates: Array[Vector2] = [
		inner_rect.position,
		Vector2(inner_rect.end.x, inner_rect.position.y),
		inner_rect.end,
		Vector2(inner_rect.position.x, inner_rect.end.y),
	]
	var selected := candidates[0]
	var selected_distance := selected.distance_squared_to(player_position)
	for index in range(1, candidates.size()):
		var distance := candidates[index].distance_squared_to(player_position)
		if distance > selected_distance:
			selected = candidates[index]
			selected_distance = distance
	return selected


func _spawn_boss(schedule_index: int) -> FirstBoss:
	if (
		not has_valid_configuration()
		or is_instance_valid(_active_boss)
		or not _run_controller.is_running()
		or not _run_controller.request_boss_intro()
	):
		return null

	var instance := boss_scene.instantiate()
	if not instance is FirstBoss:
		if is_instance_valid(instance):
			instance.free()
		_abort_intro_and_release_event()
		push_error("BossEncounter: boss_scene deve avere FirstBoss come nodo root.")
		return null

	var boss := instance as FirstBoss
	_enemy_parent.add_child(boss)
	if not boss.configure_boss(
		boss_definition,
		_player,
		_run_controller,
		_boss_projectile_parent
	):
		boss.queue_free()
		_abort_intro_and_release_event()
		push_error("BossEncounter: configurazione Boss non valida.")
		return null

	var spawn_position := calculate_spawn_position(
		_arena_layout.get_playfield_rect(),
		_player.global_position,
		boss_definition.collision_radius
	)
	if not spawn_position.is_finite():
		boss.queue_free()
		_abort_intro_and_release_event()
		push_error("BossEncounter: playfield non valido per lo spawn Boss.")
		return null
	boss.global_position = spawn_position

	if not _game_director.register_active_boss(boss, schedule_index):
		boss.queue_free()
		_abort_intro_and_release_event()
		push_error("BossEncounter: il Director ha rifiutato il Boss richiesto.")
		return null

	_active_boss = boss
	_active_schedule_index = schedule_index
	_reward_granted = false
	_active_boss.died.connect(_on_boss_died)
	_active_boss.tree_exiting.connect(_on_boss_tree_exiting, CONNECT_ONE_SHOT)
	_targeting_system.register_target(_active_boss)
	_boss_ui.bind_boss(_active_boss, boss_definition)
	_boss_ui.show_intro(boss_definition)
	boss_spawned.emit(_active_boss, schedule_index)
	boss_intro_started.emit(_active_boss, schedule_index)
	return _active_boss


func _clear_active_boss(queue_for_deletion: bool) -> void:
	var boss := _active_boss
	if is_instance_valid(boss):
		if is_instance_valid(_targeting_system):
			_targeting_system.unregister_target(boss)
		if boss.died.is_connected(_on_boss_died):
			boss.died.disconnect(_on_boss_died)
		if boss.tree_exiting.is_connected(_on_boss_tree_exiting):
			boss.tree_exiting.disconnect(_on_boss_tree_exiting)
		boss.clear_attack_runtime()
		if queue_for_deletion and not boss.is_queued_for_deletion():
			boss.queue_free()
	_active_boss = null
	_active_schedule_index = -1
	if is_instance_valid(_boss_ui):
		_boss_ui.reset_presentation()


func _abort_intro_and_release_event() -> void:
	if is_instance_valid(_boss_ui):
		_boss_ui.reset_presentation()
	if is_instance_valid(_game_director):
		_game_director.complete_active_boss_event()
	if (
		is_instance_valid(_run_controller)
		and _run_controller.get_state() == RunController.RunState.BOSS_INTRO
	):
		_run_controller.complete_boss_intro()


func _connect_dependencies() -> void:
	if is_instance_valid(_game_director):
		_game_director.boss_event_requested.connect(_on_boss_event_requested)
	if is_instance_valid(_run_controller):
		_run_controller.restart_prepared.connect(_on_restart_prepared)
		_run_controller.run_ended.connect(_on_run_ended)
	if is_instance_valid(_boss_ui):
		_boss_ui.intro_continue_requested.connect(_on_intro_continue_requested)


func _disconnect_dependencies() -> void:
	if is_instance_valid(_game_director):
		if _game_director.boss_event_requested.is_connected(_on_boss_event_requested):
			_game_director.boss_event_requested.disconnect(_on_boss_event_requested)
	if is_instance_valid(_run_controller):
		if _run_controller.restart_prepared.is_connected(_on_restart_prepared):
			_run_controller.restart_prepared.disconnect(_on_restart_prepared)
		if _run_controller.run_ended.is_connected(_on_run_ended):
			_run_controller.run_ended.disconnect(_on_run_ended)
	if is_instance_valid(_boss_ui):
		if _boss_ui.intro_continue_requested.is_connected(_on_intro_continue_requested):
			_boss_ui.intro_continue_requested.disconnect(_on_intro_continue_requested)
	_run_controller = null
	_game_director = null
	_arena_layout = null
	_player = null
	_enemy_parent = null
	_boss_projectile_parent = null
	_targeting_system = null
	_experience_system = null
	_boss_ui = null


func _on_boss_event_requested(
	schedule_index: int,
	_threshold_seconds: float
) -> void:
	_spawn_boss(schedule_index)


func _on_intro_continue_requested() -> void:
	complete_intro()


func _on_boss_died(boss: BaseEnemy) -> void:
	if boss != _active_boss or _reward_granted:
		return
	_reward_granted = true
	_targeting_system.unregister_target(_active_boss)
	_last_defeated_title = boss_definition.get_safe_title()
	_last_experience_reward = 0
	if _experience_system.add_experience(boss_definition.experience_reward):
		_last_experience_reward = boss_definition.experience_reward
	_game_director.complete_active_boss_event()
	boss_defeated.emit(_active_boss, _last_experience_reward)


func _on_boss_tree_exiting() -> void:
	_active_boss = null
	_active_schedule_index = -1
	if is_instance_valid(_boss_ui):
		_boss_ui.clear_boss()


func _on_restart_prepared() -> void:
	reset_for_run()


func _on_run_ended(
	_final_state: RunController.RunState,
	_run_time: float
) -> void:
	if is_instance_valid(_boss_ui):
		_boss_ui.hide_intro()
