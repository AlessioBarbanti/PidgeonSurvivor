class_name CombatFeedback
extends Node2D

signal feedback_spawned(kind: StringName, world_position: Vector2)

const HIT_SPARK := &"hit_spark"
const DEATH_BURST := &"death_burst"
const PLAYER_DAMAGE := &"player_damage"

@export_range(0.04, 1.0, 0.01) var hit_spark_duration := PresentationTimings.HIT_SPARK_SECONDS
@export_range(0.08, 2.0, 0.01) var death_burst_duration := PresentationTimings.DEATH_BURST_SECONDS
@export_range(0.08, 1.0, 0.01) var player_damage_duration := PresentationTimings.PLAYER_DAMAGE_BURST_SECONDS
@export var hit_color := Color(1.0, 0.83, 0.35, 0.92)
@export var death_color := Color(1.0, 0.31, 0.46, 0.96)
@export var player_damage_color := Color(1.0, 0.18, 0.38, 0.9)

var _run_controller: RunController
var _enemy_spawner: EnemySpawner
var _player: Player
var _boss_encounter: BossEncounter
var _effects: Array[Dictionary] = []
var _tracked_enemies: Dictionary = {}
var _spawn_counts: Dictionary = {
	HIT_SPARK: 0,
	DEATH_BURST: 0,
	PLAYER_DAMAGE: 0,
}


func _ready() -> void:
	set_process(false)


func _exit_tree() -> void:
	_disconnect_sources()


func configure(
	run_controller: RunController,
	enemy_spawner: EnemySpawner,
	player: Player,
	boss_encounter: BossEncounter = null
) -> bool:
	if (
		not is_node_ready()
		or not is_instance_valid(run_controller)
		or not is_instance_valid(enemy_spawner)
		or not is_instance_valid(player)
	):
		return false
	_disconnect_sources()
	_run_controller = run_controller
	_enemy_spawner = enemy_spawner
	_player = player
	_boss_encounter = boss_encounter
	_enemy_spawner.enemy_spawned.connect(_on_enemy_spawned)
	if is_instance_valid(_boss_encounter):
		_boss_encounter.boss_spawned.connect(_on_boss_spawned)
	_player.damaged.connect(_on_player_damaged)
	_run_controller.run_started.connect(_on_run_started)
	_run_controller.restart_prepared.connect(_on_restart_prepared)
	for enemy in _enemy_spawner.get_spawned_enemies():
		_track_enemy(enemy)
	return true


func get_run_controller() -> RunController:
	return _run_controller if is_instance_valid(_run_controller) else null


func get_enemy_spawner() -> EnemySpawner:
	return _enemy_spawner if is_instance_valid(_enemy_spawner) else null


func get_player() -> Player:
	return _player if is_instance_valid(_player) else null


func get_boss_encounter() -> BossEncounter:
	return _boss_encounter if is_instance_valid(_boss_encounter) else null


func get_active_effect_count() -> int:
	return _effects.size()


func get_spawn_count(kind: StringName) -> int:
	return int(_spawn_counts.get(kind, 0))


func get_active_effect_remaining(kind: StringName) -> float:
	var longest_remaining := 0.0
	for effect in _effects:
		if StringName(effect.get("kind", &"")) != kind:
			continue
		longest_remaining = maxf(
			longest_remaining,
			float(effect.get("duration", 0.0)) - float(effect.get("elapsed", 0.0))
		)
	return longest_remaining


func clear_feedback() -> void:
	_effects.clear()
	set_process(false)
	queue_redraw()


func _process(delta: float) -> void:
	if not is_instance_valid(_run_controller) or not _run_controller.is_running():
		return
	var safe_delta := maxf(delta, 0.0) if is_finite(delta) else 0.0
	for index in range(_effects.size() - 1, -1, -1):
		var effect := _effects[index]
		effect["elapsed"] = float(effect.get("elapsed", 0.0)) + safe_delta
		_effects[index] = effect
		if float(effect["elapsed"]) >= float(effect["duration"]):
			_effects.remove_at(index)
	set_process(not _effects.is_empty())
	queue_redraw()


func _draw() -> void:
	for effect in _effects:
		var duration := maxf(float(effect.get("duration", 0.1)), 0.001)
		var progress := clampf(float(effect.get("elapsed", 0.0)) / duration, 0.0, 1.0)
		var kind := StringName(effect.get("kind", &""))
		match kind:
			HIT_SPARK:
				_draw_hit_spark(effect, progress)
			DEATH_BURST:
				_draw_death_burst(effect, progress)
			PLAYER_DAMAGE:
				_draw_player_damage(effect, progress)


func _track_enemy(enemy: BaseEnemy) -> void:
	if not is_instance_valid(enemy):
		return
	var instance_id := enemy.get_instance_id()
	if _tracked_enemies.has(instance_id):
		return
	var exiting_callable := _on_enemy_tree_exiting.bind(instance_id)
	enemy.damaged.connect(_on_enemy_damaged)
	enemy.died.connect(_on_enemy_died)
	enemy.tree_exiting.connect(exiting_callable)
	_tracked_enemies[instance_id] = {
		"enemy": enemy,
		"exiting_callable": exiting_callable,
	}


func _untrack_enemy(instance_id: int) -> void:
	if not _tracked_enemies.has(instance_id):
		return
	var record: Dictionary = _tracked_enemies[instance_id]
	var enemy := record.get("enemy") as BaseEnemy
	if is_instance_valid(enemy):
		if enemy.damaged.is_connected(_on_enemy_damaged):
			enemy.damaged.disconnect(_on_enemy_damaged)
		if enemy.died.is_connected(_on_enemy_died):
			enemy.died.disconnect(_on_enemy_died)
		var exiting_callable: Callable = record.get("exiting_callable", Callable())
		if exiting_callable.is_valid() and enemy.tree_exiting.is_connected(exiting_callable):
			enemy.tree_exiting.disconnect(exiting_callable)
	_tracked_enemies.erase(instance_id)


func _disconnect_sources() -> void:
	for instance_id in _tracked_enemies.keys().duplicate():
		_untrack_enemy(int(instance_id))
	if is_instance_valid(_enemy_spawner):
		if _enemy_spawner.enemy_spawned.is_connected(_on_enemy_spawned):
			_enemy_spawner.enemy_spawned.disconnect(_on_enemy_spawned)
	if is_instance_valid(_player):
		if _player.damaged.is_connected(_on_player_damaged):
			_player.damaged.disconnect(_on_player_damaged)
	if is_instance_valid(_boss_encounter):
		if _boss_encounter.boss_spawned.is_connected(_on_boss_spawned):
			_boss_encounter.boss_spawned.disconnect(_on_boss_spawned)
	if is_instance_valid(_run_controller):
		if _run_controller.run_started.is_connected(_on_run_started):
			_run_controller.run_started.disconnect(_on_run_started)
		if _run_controller.restart_prepared.is_connected(_on_restart_prepared):
			_run_controller.restart_prepared.disconnect(_on_restart_prepared)
	_run_controller = null
	_enemy_spawner = null
	_player = null
	_boss_encounter = null
	clear_feedback()


func _spawn_effect(
	kind: StringName,
	world_position: Vector2,
	duration: float,
	radius: float,
	seed_value: int
) -> void:
	_effects.append({
		"kind": kind,
		"position": world_position,
		"duration": maxf(duration, 0.01),
		"elapsed": 0.0,
		"radius": maxf(radius, 1.0),
		"seed": seed_value,
	})
	_spawn_counts[kind] = int(_spawn_counts.get(kind, 0)) + 1
	set_process(true)
	feedback_spawned.emit(kind, world_position)
	queue_redraw()


func _on_enemy_spawned(enemy: BaseEnemy) -> void:
	_track_enemy(enemy)


func _on_boss_spawned(boss: FirstBoss, _schedule_index: int) -> void:
	_track_enemy(boss)


func _on_enemy_damaged(enemy: BaseEnemy, _amount: float, _health_current: float) -> void:
	if not is_instance_valid(enemy):
		return
	_spawn_effect(
		HIT_SPARK,
		enemy.global_position,
		hit_spark_duration,
		enemy.collision_radius,
		enemy.get_instance_id()
	)


func _on_enemy_died(enemy: BaseEnemy) -> void:
	if not is_instance_valid(enemy):
		return
	_spawn_effect(
		DEATH_BURST,
		enemy.global_position,
		death_burst_duration,
		enemy.collision_radius,
		enemy.get_instance_id()
	)


func _on_player_damaged(
	player: Player,
	_amount: float,
	_health_current: float
) -> void:
	if not is_instance_valid(player):
		return
	_spawn_effect(
		PLAYER_DAMAGE,
		player.global_position,
		player_damage_duration,
		player.collision_radius,
		player.get_instance_id()
	)


func _on_enemy_tree_exiting(instance_id: int) -> void:
	_tracked_enemies.erase(instance_id)


func _on_run_started(_seed_value: int) -> void:
	clear_feedback()


func _on_restart_prepared() -> void:
	clear_feedback()


func _draw_hit_spark(effect: Dictionary, progress: float) -> void:
	var center: Vector2 = effect["position"]
	var radius := float(effect["radius"])
	var fade := 1.0 - progress
	var color := hit_color
	color.a *= fade
	draw_arc(center, radius * (0.75 + progress * 0.65), 0.0, TAU, 16, color, 2.0, true)
	var seed_angle := _seed_angle(int(effect["seed"]))
	for index in range(4):
		var direction := Vector2.RIGHT.rotated(seed_angle + TAU * float(index) / 4.0)
		var inner := center + direction * radius * (0.5 + progress * 0.45)
		var outer := center + direction * radius * (1.05 + progress * 0.8)
		draw_line(inner, outer, color, 2.0, true)


func _draw_death_burst(effect: Dictionary, progress: float) -> void:
	var center: Vector2 = effect["position"]
	var radius := float(effect["radius"])
	var fade := 1.0 - progress
	var color := death_color
	color.a *= fade
	draw_circle(center, radius * (1.0 - progress) * 0.82, color)
	draw_arc(center, radius * (0.8 + progress * 1.45), 0.0, TAU, 24, color, 2.4, true)
	if fade <= 0.001:
		return
	var seed_angle := _seed_angle(int(effect["seed"]))
	for index in range(9):
		var direction := Vector2.RIGHT.rotated(seed_angle + TAU * float(index) / 9.0)
		var distance := radius * (0.4 + progress * (1.35 + 0.08 * float(index % 3)))
		var particle_center := center + direction * distance
		var particle_size := radius * (0.2 + 0.06 * float(index % 2)) * fade
		draw_circle(particle_center, maxf(particle_size * 0.7, 0.5), color)


func _draw_player_damage(effect: Dictionary, progress: float) -> void:
	var center: Vector2 = effect["position"]
	var radius := float(effect["radius"])
	var fade := 1.0 - progress
	var color := player_damage_color
	color.a *= fade
	for ring_index in range(2):
		var ring_radius := radius * (1.1 + progress * (0.8 + 0.35 * float(ring_index)))
		draw_arc(center, ring_radius, 0.0, TAU, 24, color, 2.0, true)
	for index in range(4):
		var direction := Vector2.RIGHT.rotated(PI * 0.25 + TAU * float(index) / 4.0)
		draw_line(
			center + direction * radius * 0.9,
			center + direction * radius * (1.45 + progress * 0.55),
			color,
			2.4,
			true
		)


static func _seed_angle(seed_value: int) -> float:
	return fmod(absf(float(seed_value)) * 0.0174533, TAU)
