class_name EnemySpawner
extends Node

signal enemy_spawned(enemy: BaseEnemy)
signal enemy_removed(enemy_instance_id: int)

## Lati dell'anello di spawn: 0=Nord, 1=Est, 2=Sud, 3=Ovest.
const ALL_SECTORS: Array[int] = [0, 1, 2, 3]

@export var enemy_scene: PackedScene
@export var spawn_profile: EnemySpawnProfile
## Archetipi aggiuntivi oltre al piccione (B40): il piccione resta selezionato
## tramite enemy_scene e partecipa allo stesso pool pesato con
## spawn_profile.base_archetype_weight.
@export var archetypes: Array[EnemyArchetypeDefinition] = []

var _run_controller: RunController
var _arena_layout: ArenaLayout
var _target: Node2D
var _enemy_parent: Node
var _camera: Camera2D
var _hostile_projectile_parent: Node
var _spawned_enemies: Array[BaseEnemy] = []
var _rng := RandomNumberGenerator.new()
var _spawn_elapsed := 0.0
var _cleanup_elapsed := 0.0
var _awaiting_initial_spawn := true
var _invalid_scene_warning_emitted := false
var _active_sectors: Array[int] = ALL_SECTORS.duplicate()
var _sector_elapsed := 0.0
var _sector_hold_duration := 0.0
var _sector_override_active := false
var _ordinary_spawn_suspended := false
var _spawn_interval_multiplier := 1.0
var _archetype_weight_overrides: Dictionary[StringName, float] = {}
var _last_archetype_spawn_times: Dictionary[StringName, float] = {}


func _ready() -> void:
	_rng.seed = 1


func _process(delta: float) -> void:
	if not _can_run_scheduler():
		return

	var safe_delta := maxf(delta, 0.0)
	_cleanup_elapsed += safe_delta

	if not _sector_override_active:
		_sector_elapsed += safe_delta
		if _sector_elapsed >= _sector_hold_duration:
			_roll_active_sectors()

	var cleanup_interval := spawn_profile.get_effective_cleanup_interval()
	if _cleanup_elapsed >= cleanup_interval:
		_cleanup_elapsed = 0.0
		cleanup_outside_despawn_rect()

	if _ordinary_spawn_suspended:
		return
	_spawn_elapsed += safe_delta

	var interval := spawn_profile.initial_spawn_delay
	if not _awaiting_initial_spawn:
		interval = spawn_profile.get_spawn_interval(
			_run_controller.get_run_time()
		) * _spawn_interval_multiplier
	if _spawn_elapsed < interval:
		return

	if get_alive_count() >= spawn_profile.max_alive_enemies:
		_spawn_elapsed = minf(_spawn_elapsed, interval)
		return

	var enemy := try_spawn_enemy()
	if enemy == null:
		_spawn_elapsed = minf(_spawn_elapsed, interval)
		return

	_spawn_elapsed = 0.0
	_awaiting_initial_spawn = false


func configure(
	run_controller: RunController,
	arena_layout: ArenaLayout,
	target: Node2D,
	enemy_parent: Node,
	camera: Camera2D = null,
	hostile_projectile_parent: Node = null
) -> void:
	set_run_controller(run_controller)
	_arena_layout = arena_layout
	_target = target
	_enemy_parent = enemy_parent
	_camera = camera
	_hostile_projectile_parent = hostile_projectile_parent


func get_hostile_projectile_parent() -> Node:
	return (
		_hostile_projectile_parent
		if is_instance_valid(_hostile_projectile_parent)
		else null
	)


## Rettangolo di riferimento per spawn/despawn: le dimensioni dello schermo
## effettivamente visibile (PS-095), centrate sulla vista corrente della
## camera invece che sul rettangolo statico del viewport. Senza camera
## assegnata (es. i fixture di test) il comportamento storico resta
## identico. Usa il viewport reale di `ArenaLayout` e non il suo
## `playfield_rect`: `project.godot` dichiara
## `window/stretch/aspect="expand"`, quindi mondo e camera riempiono
## l'intero viewport senza letterbox, mentre `playfield_rect` resta
## deliberatamente piu' stretto su schermi piu' larghi del suo
## `target_aspect_ratio` (es. Android landscape 20:9) per motivi di
## composizione (PS-045). Usare quella dimensione qui trattava un crop
## artistico come "lo schermo", lasciando nemici comparire dentro l'area
## davvero visibile. Leggere il viewport dal vivo evita anche la finestra in
## cui `playfield_rect` e' ancora quello precedente a un resize/cambio
## orientamento, perche' `ArenaLayout.refresh_layout()` lo aggiorna in modo
## differito (`call_deferred`).
func get_visible_reference_rect() -> Rect2:
	var playfield_rect := _arena_layout.get_playfield_rect()
	if not is_instance_valid(_camera) or not playfield_rect.has_area():
		return playfield_rect
	var viewport_rect := _arena_layout.get_viewport_rect()
	var reference_size := viewport_rect.size if viewport_rect.has_area() else playfield_rect.size
	var center := _camera.get_screen_center_position()
	return Rect2(center - reference_size * 0.5, reference_size)


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
	return _run_controller


func get_arena_layout() -> ArenaLayout:
	return _arena_layout


func get_target() -> Node2D:
	return _target


func get_enemy_parent() -> Node:
	return _enemy_parent


func reset_for_run(seed_value: int, clear_existing: bool = true) -> void:
	_rng.seed = seed_value
	_spawn_elapsed = 0.0
	_cleanup_elapsed = 0.0
	_awaiting_initial_spawn = true
	_invalid_scene_warning_emitted = false
	_ordinary_spawn_suspended = false
	_sector_override_active = false
	_spawn_interval_multiplier = 1.0
	_archetype_weight_overrides.clear()
	_last_archetype_spawn_times.clear()
	_roll_active_sectors()
	if clear_existing:
		clear_spawned_enemies()


## Sospensione dello spawn ordinario durante un Boss attivo (B53): non tocca
## clock, pattern, proiettili o collisioni, solo la schedulazione di nuovi
## nemici ordinari. I nemici gia' presenti restano invariati; alla ripresa
## _spawn_elapsed riprende esattamente da dove si era fermato, senza raffica
## arretrata perche' try_spawn_enemy() genera al piu' un nemico per frame.
func set_ordinary_spawn_suspended(value: bool) -> void:
	_ordinary_spawn_suspended = value


func is_ordinary_spawn_suspended() -> bool:
	return _ordinary_spawn_suspended


func get_active_sectors() -> Array[int]:
	return _active_sectors.duplicate()


## Forza temporaneamente i settori attivi (PS-008): sospende la rotazione
## periodica finche' l'override resta attivo. Usato dagli eventi d'ondata per
## formazioni riconoscibili (es. tutti i lati per l'Accerchiamento, un solo
## lato per lo Stormo laterale) senza toccare l'RNG della rotazione ordinaria.
func set_active_sector_override(sectors: Array[int]) -> void:
	var safe_sectors := sectors if sectors.size() > 0 else ALL_SECTORS
	_sector_override_active = true
	_active_sectors = safe_sectors.duplicate()
	_sector_elapsed = 0.0


func clear_active_sector_override() -> void:
	if not _sector_override_active:
		return
	_sector_override_active = false
	_roll_active_sectors()


func is_sector_override_active() -> bool:
	return _sector_override_active


## Moltiplicatore temporaneo sul peso effettivo di un archetipo (PS-008): usato
## dal Nido di tiratori per aumentare la presenza relativa del tiratore nel
## pool ordinario esistente, senza introdurre una seconda curva di pesi.
func set_archetype_weight_override(archetype_id: StringName, multiplier: float) -> void:
	if String(archetype_id).is_empty():
		return
	_archetype_weight_overrides[archetype_id] = (
		maxf(multiplier, 0.0) if is_finite(multiplier) else 0.0
	)


func clear_archetype_weight_overrides() -> void:
	_archetype_weight_overrides.clear()


func get_archetype_weight_override(archetype_id: StringName) -> float:
	return float(_archetype_weight_overrides.get(archetype_id, 1.0))


## Moltiplicatore temporaneo sull'intervallo di spawn ordinario (PS-008): usato
## dagli eventi configurati come "ridotti" invece che "sostituiti". >1 rallenta
## il ritmo ordinario; 1 lo lascia invariato.
func set_spawn_interval_multiplier(multiplier: float) -> void:
	_spawn_interval_multiplier = maxf(multiplier, 0.01) if is_finite(multiplier) else 1.0


func get_archetype_by_id(archetype_id: StringName) -> EnemyArchetypeDefinition:
	for archetype in archetypes:
		if archetype != null and archetype.id == archetype_id:
			return archetype
	return null


func try_spawn_enemy() -> BaseEnemy:
	if not _has_valid_spawn_dependencies():
		return null
	if get_alive_count() >= spawn_profile.max_alive_enemies:
		return null

	var playfield_rect := get_visible_reference_rect()
	if not playfield_rect.has_area():
		return null

	var spawn_position := _sample_position(playfield_rect)
	if not spawn_position.is_finite():
		return null

	var chosen_archetype := _pick_archetype(_run_controller.get_run_time())
	if chosen_archetype == null:
		return _spawn_base_enemy(spawn_position)

	var first_enemy := _spawn_archetype_enemy(chosen_archetype, spawn_position)
	if first_enemy == null:
		return null
	_last_archetype_spawn_times[chosen_archetype.id] = _run_controller.get_run_time()
	for _cluster_index in range(1, chosen_archetype.spawn_cluster_size):
		if get_alive_count() >= spawn_profile.max_alive_enemies:
			break
		var extra_position := _sample_position(playfield_rect)
		if not extra_position.is_finite():
			break
		_spawn_archetype_enemy(chosen_archetype, extra_position)
	return first_enemy


## Istanzia un archetipo fuori dal ciclo di spawn ordinario (B40): usato dal
## divisore per generare i propri frammenti nella posizione di morte. Rispetta
## comunque il cap max_alive_enemies e passa dalla stessa pipeline di
## registrazione di ogni altro nemico, cosicche' i frammenti vengano ripuliti
## da clear_spawned_enemies()/cleanup_outside_despawn_rect() come tutti gli
## altri.
func spawn_archetype_instance(
	definition: EnemyArchetypeDefinition,
	position: Vector2
) -> BaseEnemy:
	if (
		definition == null
		or not definition.is_valid()
		or spawn_profile == null
		or not is_instance_valid(_run_controller)
		or not _run_controller.is_running()
		or not is_instance_valid(_target)
		or not is_instance_valid(_enemy_parent)
		or not _enemy_parent.is_inside_tree()
	):
		return null
	if get_alive_count() >= spawn_profile.max_alive_enemies:
		return null
	return _spawn_archetype_enemy(definition, position)


func _sample_position(playfield_rect: Rect2) -> Vector2:
	return sample_spawn_position(
		playfield_rect,
		spawn_profile.inner_spawn_margin,
		spawn_profile.get_effective_outer_spawn_margin(),
		_target.global_position,
		spawn_profile.min_player_distance,
		spawn_profile.spawn_sample_attempts,
		_rng,
		_active_sectors
	)


## Sceglie il profilo base (ritorna null) o un archetipo eleggibile in questo
## istante di run, con un pool pesato che include sempre il piccione tramite
## spawn_profile.base_archetype_weight (contratto: "il profilo base domina i
## primi minuti e gli altri entrano progressivamente").
func _pick_archetype(run_time: float) -> EnemyArchetypeDefinition:
	var eligible: Array[EnemyArchetypeDefinition] = []
	var weights: Array[float] = [spawn_profile.get_effective_base_archetype_weight(run_time)]
	for archetype in archetypes:
		if archetype == null or not archetype.is_valid():
			continue
		if not archetype.is_eligible_at(run_time):
			continue
		eligible.append(archetype)
		var effective_weight := spawn_profile.get_effective_archetype_weight(
			archetype.spawn_weight,
			archetype.late_run_weight_multiplier,
			run_time
		)
		if _archetype_weight_overrides.has(archetype.id):
			effective_weight *= _archetype_weight_overrides[archetype.id]
		weights.append(effective_weight)

	var guaranteed_ranged := _resolve_guaranteed_ranged(eligible, run_time)
	if guaranteed_ranged != null:
		return guaranteed_ranged

	var chosen_index := pick_weighted_index(weights, _rng)
	if chosen_index <= 0:
		return null
	return eligible[chosen_index - 1]


func _resolve_guaranteed_ranged(
	eligible: Array[EnemyArchetypeDefinition],
	run_time: float
) -> EnemyArchetypeDefinition:
	if (
		spawn_profile == null
		or run_time < spawn_profile.late_run_ranged_guarantee_start_seconds
		or String(spawn_profile.late_run_ranged_archetype_id).is_empty()
	):
		return null
	var last_spawn_time := get_last_archetype_spawn_time(
		spawn_profile.late_run_ranged_archetype_id
	)
	if run_time - last_spawn_time < spawn_profile.late_run_ranged_max_gap_seconds:
		return null
	for archetype in eligible:
		if archetype.id == spawn_profile.late_run_ranged_archetype_id:
			return archetype
	return null


func _spawn_base_enemy(position: Vector2) -> BaseEnemy:
	var instance := enemy_scene.instantiate()
	if not instance is BaseEnemy:
		if is_instance_valid(instance):
			instance.free()
		if not _invalid_scene_warning_emitted:
			_invalid_scene_warning_emitted = true
			push_warning(
				"EnemySpawner: enemy_scene deve avere BaseEnemy come nodo root."
			)
		return null
	var enemy := instance as BaseEnemy
	if not _finalize_spawned_enemy(enemy, position):
		return null
	return enemy


func _spawn_archetype_enemy(
	archetype: EnemyArchetypeDefinition,
	position: Vector2
) -> BaseEnemy:
	if archetype == null or archetype.scene == null:
		return null
	var instance := archetype.scene.instantiate()
	if not instance is BaseEnemy:
		if is_instance_valid(instance):
			instance.free()
		return null
	var enemy := instance as BaseEnemy
	if not _finalize_spawned_enemy(enemy, position, archetype):
		return null
	_configure_archetype_behavior(enemy, archetype)
	return enemy


## Percorso comune di registrazione: aggiunta alla scena, posizionamento,
## dati dell'archetipo (se presente), inseguimento/RNG/XP e tracking dello
## spawner. Va chiamato dopo add_child perche' apply_archetype_definition
## legge componenti @onready risolti solo a nodo entrato nell'albero.
func _finalize_spawned_enemy(
	enemy: BaseEnemy,
	position: Vector2,
	archetype: EnemyArchetypeDefinition = null
) -> bool:
	_enemy_parent.add_child(enemy)
	enemy.global_position = position
	if archetype != null and not enemy.apply_archetype_definition(archetype):
		enemy.queue_free()
		return false
	_apply_post_curve_pressure(enemy)
	enemy.set_target(_target)
	enemy.set_pursuit_offset(_sample_pursuit_offset())
	enemy.set_run_controller(_run_controller)
	enemy.experience_reward_scale = spawn_profile.get_experience_reward_scale(
		_run_controller.get_run_time()
	)
	if not enemy.is_in_group(&"enemies"):
		enemy.add_to_group(&"enemies")

	_spawned_enemies.append(enemy)
	enemy.tree_exiting.connect(
		_on_enemy_tree_exiting.bind(enemy),
		CONNECT_ONE_SHOT
	)
	enemy_spawned.emit(enemy)
	return true


## PS-126: applica il moltiplicatore di pressione oltre
## late_run_curve_full_seconds a ogni nemico spawnato (piccione base incluso,
## non solo gli archetipi). A moltiplicatore 1.0 (prima della soglia, o con
## post_curve_growth_per_minute a 0.0) e' un no-op sostanziale, ma il campo
## pubblico viene comunque assegnato: le sottoclassi con un danno a distanza
## proprio (RangedEnemy) lo leggono al momento di sparare, cosi' anche quello
## scala invece di restare piatto per sempre.
func _apply_post_curve_pressure(enemy: BaseEnemy) -> void:
	var multiplier := spawn_profile.get_post_curve_pressure_multiplier(_run_controller.get_run_time())
	enemy.pressure_multiplier = multiplier
	if is_equal_approx(multiplier, 1.0):
		return
	var health_component := enemy.get_health_component()
	if health_component != null:
		health_component.set_health_max(health_component.health_max * multiplier)
		health_component.reset_to_max()
	var contact_damage_component := enemy.get_contact_damage()
	if contact_damage_component != null:
		contact_damage_component.damage *= multiplier


func _configure_archetype_behavior(
	enemy: BaseEnemy,
	archetype: EnemyArchetypeDefinition
) -> void:
	if enemy is SplitterEnemy and archetype.split_fragment_definition != null:
		(enemy as SplitterEnemy).configure_splitter(
			archetype.split_fragment_definition,
			archetype.split_fragment_count,
			self
		)
	elif enemy is RangedEnemy:
		(enemy as RangedEnemy).configure_ranged(archetype, _hostile_projectile_parent)


func cleanup_outside_despawn_rect() -> int:
	if not is_instance_valid(_arena_layout) or spawn_profile == null:
		return 0

	var despawn_rect := get_visible_reference_rect().grow(
		spawn_profile.get_effective_despawn_margin()
	)
	if not despawn_rect.has_area():
		return 0
	var removed_count := 0
	for enemy in _spawned_enemies.duplicate():
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			continue
		if not is_point_in_rect_inclusive(despawn_rect, enemy.global_position):
			enemy.queue_free()
			removed_count += 1
	return removed_count


func clear_spawned_enemies() -> void:
	var enemies_to_clear := _spawned_enemies.duplicate()
	_spawned_enemies.clear()
	for enemy in enemies_to_clear:
		if not is_instance_valid(enemy):
			continue
		var instance_id: int = enemy.get_instance_id()
		enemy.clear_chase_dependencies()
		if not enemy.is_queued_for_deletion():
			enemy.queue_free()
		enemy_removed.emit(instance_id)


func get_alive_count() -> int:
	_prune_invalid_enemies()
	return _spawned_enemies.size()


func get_spawned_enemies() -> Array[BaseEnemy]:
	_prune_invalid_enemies()
	return _spawned_enemies.duplicate()


func get_last_archetype_spawn_time(archetype_id: StringName) -> float:
	return float(_last_archetype_spawn_times.get(archetype_id, -INF))


func get_spawn_elapsed() -> float:
	return _spawn_elapsed


func is_waiting_for_initial_spawn() -> bool:
	return _awaiting_initial_spawn


static func sample_spawn_position(
	viewport_rect: Rect2,
	inner_margin: float,
	outer_margin: float,
	player_position: Vector2,
	minimum_player_distance: float,
	sample_attempts: int,
	rng: RandomNumberGenerator,
	allowed_sides: Array[int] = ALL_SECTORS
) -> Vector2:
	if not viewport_rect.has_area() or rng == null:
		return Vector2(INF, INF)

	var safe_inner := maxf(inner_margin, 0.0)
	var safe_outer := maxf(outer_margin, safe_inner)
	var safe_minimum_distance := maxf(minimum_player_distance, 0.0)
	var attempts := maxi(sample_attempts, 1)
	var outer_rect := viewport_rect.grow(safe_outer)
	var required_distance_squared := safe_minimum_distance * safe_minimum_distance
	var safe_allowed_sides := allowed_sides if allowed_sides.size() > 0 else ALL_SECTORS

	for _attempt in range(attempts):
		var side := safe_allowed_sides[rng.randi_range(0, safe_allowed_sides.size() - 1)]
		var depth := rng.randf_range(safe_inner, safe_outer)
		var candidate := Vector2.ZERO
		match side:
			0:
				candidate = Vector2(
					rng.randf_range(outer_rect.position.x, outer_rect.end.x),
					viewport_rect.position.y - depth
				)
			1:
				candidate = Vector2(
					viewport_rect.end.x + depth,
					rng.randf_range(outer_rect.position.y, outer_rect.end.y)
				)
			2:
				candidate = Vector2(
					rng.randf_range(outer_rect.position.x, outer_rect.end.x),
					viewport_rect.end.y + depth
				)
			_:
				candidate = Vector2(
					viewport_rect.position.x - depth,
					rng.randf_range(outer_rect.position.y, outer_rect.end.y)
				)

		if candidate.distance_squared_to(player_position) >= required_distance_squared:
			return candidate

	# Se i tentativi casuali non trovano un punto valido, l'angolo esterno piu
	# lontano e il massimo geometrico dell'anello rettangolare. Rispetta quindi
	# la distanza minima ogni volta che questa e realizzabile; se non lo e,
	# restituisce comunque il miglior fallback possibile.
	return get_farthest_rect_corner(outer_rect, player_position)


static func get_farthest_rect_corner(
	bounds: Rect2,
	point: Vector2
) -> Vector2:
	if not bounds.has_area():
		return Vector2(INF, INF)

	var farthest_corner := bounds.position
	var farthest_distance_squared := -1.0
	var corners: Array[Vector2] = [
		bounds.position,
		Vector2(bounds.end.x, bounds.position.y),
		bounds.end,
		Vector2(bounds.position.x, bounds.end.y),
	]
	for corner in corners:
		var distance_squared: float = corner.distance_squared_to(point)
		if distance_squared > farthest_distance_squared:
			farthest_corner = corner
			farthest_distance_squared = distance_squared
	return farthest_corner


static func is_point_in_rect_inclusive(
	bounds: Rect2,
	point: Vector2,
	tolerance: float = 0.001
) -> bool:
	var safe_tolerance := maxf(tolerance, 0.0)
	return (
		point.x >= bounds.position.x - safe_tolerance
		and point.y >= bounds.position.y - safe_tolerance
		and point.x <= bounds.end.x + safe_tolerance
		and point.y <= bounds.end.y + safe_tolerance
	)


## Sceglie senza ripetizioni `count` settori tra i quattro disponibili usando
## l'RNG fornito, cosicche' la combinazione resti deterministica per seed.
static func pick_sector_combination(
	count: int,
	rng: RandomNumberGenerator
) -> Array[int]:
	var pool := ALL_SECTORS.duplicate()
	var picked: Array[int] = []
	if rng == null:
		return picked
	var safe_count := clampi(count, 1, pool.size())
	for _index in range(safe_count):
		var pick_index := rng.randi_range(0, pool.size() - 1)
		picked.append(pool[pick_index])
		pool.remove_at(pick_index)
	return picked


## Sceglie un indice fra pesi paralleli con l'RNG fornito, cosicche' la scelta
## resti deterministica per seed (stesso principio di pick_sector_combination).
## Ritorna -1 se il pool e' vuoto o tutti i pesi sono <= 0.
static func pick_weighted_index(weights: Array[float], rng: RandomNumberGenerator) -> int:
	if rng == null or weights.is_empty():
		return -1
	var total := 0.0
	for weight in weights:
		if is_finite(weight) and weight > 0.0:
			total += weight
	if total <= 0.0:
		return -1

	var roll := rng.randf() * total
	var cumulative := 0.0
	for index in weights.size():
		var weight: float = weights[index]
		if not is_finite(weight) or weight <= 0.0:
			continue
		cumulative += weight
		if roll < cumulative:
			return index

	# Arrotondamento in virgola mobile: ricade sull'ultimo peso valido.
	for index in range(weights.size() - 1, -1, -1):
		if is_finite(weights[index]) and weights[index] > 0.0:
			return index
	return -1


func _exit_tree() -> void:
	_disconnect_run_controller()


func _can_run_scheduler() -> bool:
	return (
		is_instance_valid(_run_controller)
		and _run_controller.is_running()
		and _has_valid_spawn_dependencies()
	)


func _has_valid_spawn_dependencies() -> bool:
	return (
		spawn_profile != null
		and spawn_profile.max_alive_enemies > 0
		and enemy_scene != null
		and is_instance_valid(_run_controller)
		and is_instance_valid(_arena_layout)
		and is_instance_valid(_target)
		and is_instance_valid(_enemy_parent)
		and _enemy_parent.is_inside_tree()
	)


func _prune_invalid_enemies() -> void:
	for index in range(_spawned_enemies.size() - 1, -1, -1):
		if not is_instance_valid(_spawned_enemies[index]):
			_spawned_enemies.remove_at(index)


## Ruota i settori di spawn attivi senza sequenza fissa: nella maggior parte
## dei casi resta attivo un solo lato, occasionalmente due, raramente un picco
## a 3-4 lati simultanei come impennata di difficolta.
func _roll_active_sectors() -> void:
	if spawn_profile == null:
		_active_sectors = ALL_SECTORS.duplicate()
		_sector_elapsed = 0.0
		_sector_hold_duration = 1.0
		return

	var run_time := (
		_run_controller.get_run_time()
		if is_instance_valid(_run_controller)
		else 0.0
	)
	var spike_chance := spawn_profile.get_effective_sector_spike_chance(run_time)
	var multi_chance := spawn_profile.get_effective_sector_multi_chance(run_time)
	var roll := _rng.randf()
	var count := 1
	if roll < spike_chance:
		count = _rng.randi_range(3, 4)
	elif roll < spike_chance + multi_chance:
		count = 2

	_active_sectors = pick_sector_combination(count, _rng)
	_sector_hold_duration = _rng.randf_range(
		spawn_profile.get_effective_sector_hold_duration_min(),
		spawn_profile.get_effective_sector_hold_duration_max()
	)
	_sector_elapsed = 0.0


func _sample_pursuit_offset() -> Vector2:
	if spawn_profile == null:
		return Vector2.ZERO
	var radius := _rng.randf_range(
		spawn_profile.get_effective_pursuit_offset_min_radius(),
		spawn_profile.get_effective_pursuit_offset_max_radius()
	)
	var angle := _rng.randf_range(0.0, TAU)
	return Vector2.RIGHT.rotated(angle) * radius


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
	reset_for_run(seed_value)


func _on_restart_prepared() -> void:
	_spawn_elapsed = 0.0
	_cleanup_elapsed = 0.0
	_awaiting_initial_spawn = true
	_ordinary_spawn_suspended = false
	_sector_override_active = false
	_spawn_interval_multiplier = 1.0
	_archetype_weight_overrides.clear()
	_last_archetype_spawn_times.clear()
	clear_spawned_enemies()


func _on_enemy_tree_exiting(enemy: BaseEnemy) -> void:
	var index := _spawned_enemies.find(enemy)
	if index < 0:
		return
	var instance_id := enemy.get_instance_id()
	_spawned_enemies.remove_at(index)
	enemy_removed.emit(instance_id)
