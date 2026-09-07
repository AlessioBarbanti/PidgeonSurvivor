class_name WaveEventScheduler
extends Node

## Scheduler degli eventi d'ondata (PS-008 / B46): formazioni finite e
## riconoscibili che compongono temporaneamente pesi e settori effettivi di
## EnemySpawner, senza mai possedere una seconda curva ordinaria parallela a
## quella late-run PS-007. Segue lo schema di EnemySpawner: possiede un RNG
## privato riseedato sul seed di run, avanza solo mentre RunController e in
## RUNNING (il resto e' garantito dalla pausa dello SceneTree) e si ferma
## esplicitamente durante un Boss attivo, cosicche' pausa, level-up, Boss
## Intro e combattimento Boss congelino sempre scheduler e telegraph.

signal wave_event_telegraph_changed(
	event_id: StringName,
	display_text: String,
	phase: TelegraphPhase,
	seconds_remaining: float
)
signal wave_event_started(event_id: StringName)
signal wave_event_ended(event_id: StringName)

enum Phase { IDLE, TELEGRAPH, ACTIVE }
enum TelegraphPhase { HIDDEN, ACTIVE }

@export var profile: WaveEventSchedulerProfile

var _run_controller: RunController
var _game_director: GameDirector
var _enemy_spawner: EnemySpawner
var _rng := RandomNumberGenerator.new()
var _phase := Phase.IDLE
var _active_definition: WaveEventDefinition
var _phase_elapsed := 0.0
var _cooldown_elapsed := 0.0
var _cooldown_target := 0.0
var _formation_spawn_elapsed := 0.0
var _formation_spawned_count := 0


func _ready() -> void:
	_rng.seed = 1


func _process(delta: float) -> void:
	if not _can_run_scheduler():
		return

	var safe_delta := maxf(delta, 0.0) if is_finite(delta) else 0.0
	if _game_director.has_blocking_boss_event():
		_handle_boss_active()
		return

	match _phase:
		Phase.IDLE:
			_advance_idle(safe_delta)
		Phase.TELEGRAPH:
			_advance_telegraph(safe_delta)
		Phase.ACTIVE:
			_advance_active(safe_delta)


func configure(
	run_controller: RunController,
	game_director: GameDirector,
	enemy_spawner: EnemySpawner
) -> bool:
	set_run_controller(run_controller)
	_game_director = game_director
	_enemy_spawner = enemy_spawner
	_clear_active_event()
	_cooldown_elapsed = 0.0
	_cooldown_target = _roll_cooldown()
	return has_valid_configuration()


func set_run_controller(value: RunController) -> void:
	if value == _run_controller:
		return

	_disconnect_run_controller()
	_run_controller = value
	if not is_instance_valid(_run_controller):
		return

	if not _run_controller.run_started.is_connected(_on_run_started):
		_run_controller.run_started.connect(_on_run_started)
	if not _run_controller.restart_prepared.is_connected(_on_restart_prepared):
		_run_controller.restart_prepared.connect(_on_restart_prepared)


func get_run_controller() -> RunController:
	return _run_controller if is_instance_valid(_run_controller) else null


func get_game_director() -> GameDirector:
	return _game_director if is_instance_valid(_game_director) else null


func get_enemy_spawner() -> EnemySpawner:
	return _enemy_spawner if is_instance_valid(_enemy_spawner) else null


func has_valid_configuration() -> bool:
	return (
		profile != null
		and profile.is_valid()
		and is_instance_valid(_run_controller)
		and is_instance_valid(_game_director)
		and is_instance_valid(_enemy_spawner)
	)


func get_phase() -> Phase:
	return _phase


func get_active_event_id() -> StringName:
	return _active_definition.event_id if _active_definition != null else &""


func is_telegraph_active() -> bool:
	return _phase == Phase.TELEGRAPH


func is_event_active() -> bool:
	return _phase == Phase.ACTIVE


func get_telegraph_remaining() -> float:
	if _phase != Phase.TELEGRAPH or _active_definition == null:
		return 0.0
	return maxf(_active_definition.telegraph_duration_seconds - _phase_elapsed, 0.0)


func get_cooldown_target() -> float:
	return _cooldown_target


func _exit_tree() -> void:
	_disconnect_run_controller()
	_clear_active_event()


func _can_run_scheduler() -> bool:
	return has_valid_configuration() and _run_controller.is_running()


func _advance_idle(delta: float) -> void:
	if _run_controller.get_run_time() < profile.get_effective_min_start_seconds():
		return
	_cooldown_elapsed += delta
	if _cooldown_elapsed < _cooldown_target:
		return
	_try_start_event()


func _try_start_event() -> void:
	var eligible := profile.get_eligible_events()
	if eligible.is_empty():
		_cooldown_elapsed = 0.0
		_cooldown_target = _roll_cooldown()
		return

	var weights: Array[float] = []
	for definition in eligible:
		weights.append(definition.weight)
	var chosen_index := EnemySpawner.pick_weighted_index(weights, _rng)
	if chosen_index < 0:
		_cooldown_elapsed = 0.0
		_cooldown_target = _roll_cooldown()
		return

	_active_definition = eligible[chosen_index]
	_phase_elapsed = 0.0
	if _active_definition.requires_telegraph:
		_phase = Phase.TELEGRAPH
		_emit_telegraph(TelegraphPhase.ACTIVE)
	else:
		_begin_active_event()


func _advance_telegraph(delta: float) -> void:
	_phase_elapsed += delta
	if _phase_elapsed >= _active_definition.telegraph_duration_seconds:
		_begin_active_event()
		return
	_emit_telegraph(TelegraphPhase.ACTIVE)


func _begin_active_event() -> void:
	_phase = Phase.ACTIVE
	_phase_elapsed = 0.0
	_formation_spawn_elapsed = 0.0
	_formation_spawned_count = 0
	_emit_telegraph(TelegraphPhase.HIDDEN)
	_apply_spawner_overrides()
	wave_event_started.emit(_active_definition.event_id)


func _advance_active(delta: float) -> void:
	_phase_elapsed += delta
	_advance_formation_spawns(delta)
	if _phase_elapsed >= _active_definition.duration_seconds:
		_end_active_event()


func _advance_formation_spawns(delta: float) -> void:
	if (
		String(_active_definition.formation_archetype_id).is_empty()
		or _formation_spawned_count >= _active_definition.formation_enemy_count
	):
		return
	_formation_spawn_elapsed += delta
	if _formation_spawn_elapsed < _active_definition.formation_spawn_interval_seconds:
		return
	_formation_spawn_elapsed = 0.0
	if _spawn_formation_unit():
		_formation_spawned_count += 1


## Riusa la stessa pipeline geometrica dello spawn ordinario (margini e
## distanza minima del profilo dati, campionamento statico condiviso) cosicche'
## la formazione non introduca una seconda logica di posizionamento.
func _spawn_formation_unit() -> bool:
	var archetype := _enemy_spawner.get_archetype_by_id(_active_definition.formation_archetype_id)
	if archetype == null:
		return false
	var spawn_profile := _enemy_spawner.spawn_profile
	if spawn_profile == null:
		return false
	var playfield_rect := _enemy_spawner.get_visible_reference_rect()
	if not playfield_rect.has_area():
		return false
	var target := _enemy_spawner.get_target()
	if target == null:
		return false

	var position := EnemySpawner.sample_spawn_position(
		playfield_rect,
		spawn_profile.inner_spawn_margin,
		spawn_profile.get_effective_outer_spawn_margin(),
		target.global_position,
		spawn_profile.min_player_distance,
		spawn_profile.spawn_sample_attempts,
		_rng,
		_enemy_spawner.get_active_sectors()
	)
	if not position.is_finite():
		return false
	return _enemy_spawner.spawn_archetype_instance(archetype, position) != null


func _apply_spawner_overrides() -> void:
	match _active_definition.effect_id:
		WaveEventDefinition.EFFECT_SURROUND:
			_enemy_spawner.set_active_sector_override(EnemySpawner.ALL_SECTORS.duplicate())
		WaveEventDefinition.EFFECT_LATERAL_SWARM:
			var sectors: Array[int] = [
				EnemySpawner.ALL_SECTORS[_rng.randi_range(0, EnemySpawner.ALL_SECTORS.size() - 1)]
			]
			_enemy_spawner.set_active_sector_override(sectors)
		WaveEventDefinition.EFFECT_RANGED_NEST:
			_enemy_spawner.set_archetype_weight_override(
				_active_definition.ranged_archetype_id,
				_active_definition.ranged_weight_multiplier
			)

	match _active_definition.ordinary_spawn_mode:
		WaveEventDefinition.ORDINARY_MODE_REPLACED:
			_enemy_spawner.set_ordinary_spawn_suspended(true)
		WaveEventDefinition.ORDINARY_MODE_REDUCED:
			_enemy_spawner.set_spawn_interval_multiplier(
				_active_definition.ordinary_spawn_interval_multiplier
			)


## PS-119: `reset_ordinary_suspension` deve restare `false` quando a chiamare
## e' `_handle_boss_active()`. `ordinary_spawn_suspended` non e' di proprieta'
## di questo scheduler: durante un Boss attivo il flag lo possiede il ciclo
## di vita del Boss (movement_slice.gd), che lo rimette a `false` solo alla
## sconfitta. Riattivarlo qui clobberebbe quella sospensione con il Boss
## ancora vivo.
func _clear_spawner_overrides(reset_ordinary_suspension: bool = true) -> void:
	if not is_instance_valid(_enemy_spawner):
		return
	_enemy_spawner.clear_active_sector_override()
	_enemy_spawner.clear_archetype_weight_overrides()
	if reset_ordinary_suspension:
		_enemy_spawner.set_ordinary_spawn_suspended(false)
	_enemy_spawner.set_spawn_interval_multiplier(1.0)


func _end_active_event() -> void:
	var ended_id := _active_definition.event_id
	_clear_spawner_overrides()
	_active_definition = null
	_phase = Phase.IDLE
	_cooldown_elapsed = 0.0
	_cooldown_target = _roll_cooldown()
	wave_event_ended.emit(ended_id)


func _clear_active_event() -> void:
	var had_active := _active_definition != null
	if had_active:
		_clear_spawner_overrides()
	_active_definition = null
	_phase = Phase.IDLE
	_phase_elapsed = 0.0
	_formation_spawn_elapsed = 0.0
	_formation_spawned_count = 0
	_emit_telegraph(TelegraphPhase.HIDDEN)


## Un evento maturato mentre il Boss e' attivo (dalla richiesta fino alla sua
## uscita, GameDirector.has_blocking_boss_event) non puo' iniziare e non deve
## accodarsi: viene interrotto qui secondo la regola dati del profilo, che
## resta l'unica fonte di verita' su scarto o rinvio.
func _handle_boss_active() -> void:
	if _phase == Phase.IDLE:
		return

	var ended_id := _active_definition.event_id if _active_definition != null else &""
	_clear_spawner_overrides(false)
	_active_definition = null
	_phase = Phase.IDLE
	_phase_elapsed = 0.0
	_emit_telegraph(TelegraphPhase.HIDDEN)
	if profile.is_postpone_policy():
		_cooldown_elapsed = _cooldown_target
	else:
		_cooldown_elapsed = 0.0
		_cooldown_target = _roll_cooldown()
	if not ended_id.is_empty():
		wave_event_ended.emit(ended_id)


func _emit_telegraph(phase: TelegraphPhase) -> void:
	if _active_definition == null:
		wave_event_telegraph_changed.emit(&"", "", TelegraphPhase.HIDDEN, 0.0)
		return
	var remaining := (
		maxf(_active_definition.telegraph_duration_seconds - _phase_elapsed, 0.0)
		if phase == TelegraphPhase.ACTIVE
		else 0.0
	)
	wave_event_telegraph_changed.emit(
		_active_definition.event_id,
		_active_definition.telegraph_display_text,
		phase,
		remaining
	)


func _roll_cooldown() -> float:
	if profile == null:
		return 0.0
	return _rng.randf_range(
		profile.get_effective_cooldown_min_seconds(),
		profile.get_effective_cooldown_max_seconds()
	)


func _disconnect_run_controller() -> void:
	if not is_instance_valid(_run_controller):
		_run_controller = null
		return
	if _run_controller.run_started.is_connected(_on_run_started):
		_run_controller.run_started.disconnect(_on_run_started)
	if _run_controller.restart_prepared.is_connected(_on_restart_prepared):
		_run_controller.restart_prepared.disconnect(_on_restart_prepared)
	_run_controller = null


func _on_run_started(seed_value: int) -> void:
	_clear_active_event()
	_rng.seed = seed_value
	_cooldown_elapsed = 0.0
	_cooldown_target = _roll_cooldown()


func _on_restart_prepared() -> void:
	_clear_active_event()
	_cooldown_elapsed = 0.0
	_cooldown_target = 0.0
