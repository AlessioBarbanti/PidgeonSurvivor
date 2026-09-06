class_name WeaponController
extends Node2D

signal projectile_fired(projectile: Projectile, target: BaseEnemy)

@export var weapon_profile: WeaponProfile
@export var projectile_scene: PackedScene

var _run_controller: RunController
var _targeting_system: TargetingSystem
var _projectile_parent: Node
var _source: Node2D
var _arena_layout: ArenaLayout
var _cooldown_remaining := 0.0
var _last_aim_direction := Vector2.RIGHT
var _invalid_projectile_scene_warning_emitted := false
var _projectile_scene_valid := true
var _base_shots_per_second := 0.0
var _base_damage := 0.0
var _character_fire_rate_multiplier := 1.0
var _character_damage_multiplier := 1.0
var _fire_rate_multiplier := 1.0
var _damage_multiplier := 1.0
var _projectile_speed_multiplier := 1.0
var _projectile_chain_enabled := false
var _projectile_chain_jumps := 0
var _projectile_chain_damage_falloff := 1.0
var _projectile_chain_radius := 0.0
var _projectile_aim_spread_degrees := 0.0
var _aim_rng := RandomNumberGenerator.new()
var _base_pierce_count := 1
var _base_pierce_damage_falloff := 1.0
var _base_multishot_count := 1
var _base_multishot_spread_degrees := 0.0
var _pierce_count := 1
var _pierce_damage_falloff := 1.0
var _multishot_count := 1
var _multishot_spread_degrees := 0.0
var _multishot_fan_mirror := false
var _death_burst_enabled := false
var _death_burst_radius := 0.0
var _death_burst_damage_multiplier := 0.0
## Probabilità critica (PS-093): due sorgenti additive, mai un unico campo
## condiviso — `_character_critical_chance_bonus` dallo scarto base del
## personaggio (`FriendDefinition.base_critical_chance_bonus`),
## `_critical_chance_bonus` dalla carta catalogo "Salamoia Bolognese". La
## somma resta sempre limitata da `MAXIMUM_CRITICAL_CHANCE`. Il moltiplicatore
## di danno critico è di sola pertinenza della carta: nessun personaggio ha
## un moltiplicatore base diverso da neutro.
const MAXIMUM_CRITICAL_CHANCE := 0.35
var _character_critical_chance_bonus := 0.0
var _critical_chance_bonus := 0.0
var _critical_damage_multiplier := 1.0
var _last_shot_was_critical := false
var _critical_rng := RandomNumberGenerator.new()
## PS-085: sorgente di mira/consenso a sparare esterna quando lo sparo e'
## manuale — sostituisce TargetingSystem.get_nearest_alive() come origine
## della direzione, senza toccare bilanciamento o modificatori upgrade.
var _manual_fire_enabled := false
var _manual_aim_active := false
var _manual_aim_direction := Vector2.RIGHT


func _exit_tree() -> void:
	_disconnect_run_controller()


func _process(delta: float) -> void:
	if not _has_valid_dependencies() or not _run_controller.is_running():
		return

	if _cooldown_remaining > 0.0:
		_cooldown_remaining = maxf(_cooldown_remaining - maxf(delta, 0.0), 0.0)
	if _cooldown_remaining <= 0.0:
		try_fire()


func configure(
	run_controller: RunController,
	targeting_system: TargetingSystem,
	projectile_parent: Node,
	source: Node2D = null,
	arena_layout: ArenaLayout = null
) -> void:
	_disconnect_run_controller()
	_run_controller = run_controller
	_targeting_system = targeting_system
	_projectile_parent = projectile_parent
	_source = source if is_instance_valid(source) else get_parent() as Node2D
	_arena_layout = arena_layout
	_capture_base_stats()
	_connect_run_controller()
	var seed_value := _run_controller.get_seed() if is_instance_valid(_run_controller) else 0
	_seed_aim_rng(seed_value)
	_seed_critical_rng(seed_value)
	reset_for_run(false)


func try_fire() -> Projectile:
	if (
		not _has_valid_dependencies()
		or not _run_controller.is_running()
		or _cooldown_remaining > 0.0
	):
		return null

	var target: BaseEnemy = null
	var base_aim_direction := _last_aim_direction
	var muzzle_offset := 0.0

	if _manual_fire_enabled:
		if not _manual_aim_active:
			return null
		base_aim_direction = _manual_aim_direction
		muzzle_offset = weapon_profile.muzzle_offset
	else:
		target = _targeting_system.get_nearest_alive(_source.global_position)
		if target == null:
			return null
		var offset_to_target := target.global_position - _source.global_position
		if not offset_to_target.is_zero_approx():
			base_aim_direction = offset_to_target.normalized()
			muzzle_offset = minf(weapon_profile.muzzle_offset, offset_to_target.length())

	var fan_offsets := calculate_multishot_fan_offsets(
		get_effective_multishot_count(),
		get_effective_multishot_spread_degrees(),
		_multishot_fan_mirror
	)
	_multishot_fan_mirror = not _multishot_fan_mirror
	var last_projectile: Projectile = null
	var last_aim_direction := base_aim_direction
	for fan_offset in fan_offsets:
		var aim_direction := _apply_aim_spread(base_aim_direction.rotated(fan_offset))
		var projectile := _spawn_projectile(aim_direction, muzzle_offset)
		if projectile == null:
			continue
		last_projectile = projectile
		last_aim_direction = aim_direction
		projectile_fired.emit(projectile, target)

	if last_projectile == null:
		return null

	_last_aim_direction = last_aim_direction
	rotation = _last_aim_direction.angle()
	_cooldown_remaining = get_effective_fire_interval()
	queue_redraw()
	return last_projectile


func _spawn_projectile(aim_direction: Vector2, muzzle_offset: float) -> Projectile:
	var instance := projectile_scene.instantiate()
	if not instance is Projectile:
		if is_instance_valid(instance):
			instance.free()
		if not _invalid_projectile_scene_warning_emitted:
			_invalid_projectile_scene_warning_emitted = true
			_projectile_scene_valid = false
			push_warning(
				"WeaponController: projectile_scene deve avere Projectile come nodo root."
			)
		return null

	var projectile := instance as Projectile
	_projectile_parent.add_child(projectile)
	projectile.global_position = _source.global_position + aim_direction * muzzle_offset
	if not projectile.initialize(
		aim_direction,
		resolve_shot_damage(),
		get_effective_projectile_speed(),
		weapon_profile.projectile_lifetime,
		weapon_profile.projectile_radius,
		_run_controller
	):
		projectile.queue_free()
		return null
	if not projectile.configure_signature_effects(
		_projectile_chain_enabled,
		_projectile_chain_jumps,
		_projectile_chain_damage_falloff,
		_projectile_chain_radius,
		_projectile_aim_spread_degrees,
		_targeting_system
	):
		projectile.expire()
		return null
	if not projectile.configure_shape_effects(
		get_effective_pierce_count(),
		get_effective_pierce_damage_falloff(),
		_death_burst_enabled,
		_death_burst_radius,
		_death_burst_damage_multiplier
	):
		projectile.expire()
		return null
	return projectile


func reset_for_run(clear_existing_projectiles: bool = true) -> void:
	_cooldown_remaining = 0.0
	reset_upgrade_stat_multipliers()
	_last_aim_direction = Vector2.RIGHT
	_last_shot_was_critical = false
	_invalid_projectile_scene_warning_emitted = false
	_projectile_scene_valid = true
	_manual_aim_active = false
	rotation = 0.0
	queue_redraw()
	if clear_existing_projectiles:
		clear_projectiles()


## PS-085: impostazione persistente (FireModeSettings), non un dato di run:
## non viene toccata da reset_for_run().
func set_manual_fire_enabled(value: bool) -> void:
	_manual_fire_enabled = value


func is_manual_fire_enabled() -> bool:
	return _manual_fire_enabled


## Aggiornata ogni frame da InputRouter.manual_aim_changed tramite
## movement_slice: la direzione resta quella dell'ultimo impegno anche
## quando active passa a false, cosi' come _last_aim_direction per
## l'automatico.
func set_manual_aim_state(direction: Vector2, active: bool) -> void:
	_manual_aim_active = active
	if active and direction.is_finite() and not direction.is_zero_approx():
		_manual_aim_direction = direction.normalized()


func is_manually_aiming() -> bool:
	return _manual_aim_active


func clear_projectiles() -> void:
	if not is_instance_valid(_projectile_parent):
		return
	for child in _projectile_parent.get_children():
		if child is Projectile and not child.is_queued_for_deletion():
			(child as Projectile).expire()


func get_run_controller() -> RunController:
	return _run_controller if is_instance_valid(_run_controller) else null


func get_targeting_system() -> TargetingSystem:
	return _targeting_system if is_instance_valid(_targeting_system) else null


func get_projectile_parent() -> Node:
	return _projectile_parent if is_instance_valid(_projectile_parent) else null


func get_arena_layout() -> ArenaLayout:
	return _arena_layout if is_instance_valid(_arena_layout) else null


func get_cooldown_remaining() -> float:
	return _cooldown_remaining


func is_ready_to_fire() -> bool:
	return _cooldown_remaining <= 0.0


func set_upgrade_stat_multipliers(
	fire_rate_multiplier: float,
	damage_multiplier: float,
	projectile_speed_multiplier: float = 1.0
) -> bool:
	if (
		not is_finite(fire_rate_multiplier)
		or fire_rate_multiplier <= 0.0
		or not is_finite(damage_multiplier)
		or damage_multiplier <= 0.0
		or not is_finite(projectile_speed_multiplier)
		or projectile_speed_multiplier <= 0.0
	):
		return false
	_fire_rate_multiplier = fire_rate_multiplier
	_damage_multiplier = damage_multiplier
	_projectile_speed_multiplier = projectile_speed_multiplier
	return true


func reset_upgrade_stat_multipliers() -> void:
	_fire_rate_multiplier = 1.0
	_damage_multiplier = 1.0
	_projectile_speed_multiplier = 1.0
	reset_projectile_upgrade_modifiers()
	reset_projectile_shape_modifiers()
	reset_critical_strike_modifiers()


## "Salamoia Bolognese" (PS-093): probabilità critica additiva per rango e
## moltiplicatore di danno, entrambi di sola pertinenza della carta — nessun
## personaggio dichiara un moltiplicatore di danno critico proprio, solo una
## chance base (vedi `set_character_stat_multipliers`).
func set_critical_strike_modifiers(chance_bonus: float, damage_multiplier: float) -> bool:
	if (
		not is_finite(chance_bonus)
		or chance_bonus < 0.0
		or not is_finite(damage_multiplier)
		or damage_multiplier <= 0.0
	):
		return false
	_critical_chance_bonus = chance_bonus
	_critical_damage_multiplier = damage_multiplier
	return true


func reset_critical_strike_modifiers() -> void:
	_critical_chance_bonus = 0.0
	_critical_damage_multiplier = 1.0


func set_character_stat_multipliers(
	fire_rate_multiplier: float,
	damage_multiplier: float = 1.0,
	critical_chance_bonus: float = 0.0
) -> bool:
	if (
		not is_finite(fire_rate_multiplier)
		or fire_rate_multiplier <= 0.0
		or not is_finite(damage_multiplier)
		or damage_multiplier <= 0.0
		or not is_finite(critical_chance_bonus)
		or critical_chance_bonus < 0.0
	):
		return false
	_character_fire_rate_multiplier = fire_rate_multiplier
	_character_damage_multiplier = damage_multiplier
	_character_critical_chance_bonus = critical_chance_bonus
	return true


func reset_character_stat_multipliers() -> void:
	_character_fire_rate_multiplier = 1.0
	_character_damage_multiplier = 1.0
	_character_critical_chance_bonus = 0.0


func set_projectile_upgrade_modifiers(
	chain_enabled: bool,
	chain_jumps: int,
	chain_damage_falloff: float,
	chain_radius: float,
	aim_spread_degrees: float
) -> bool:
	if (
		chain_jumps < 0
		or not is_finite(chain_damage_falloff)
		or chain_damage_falloff <= 0.0
		or chain_damage_falloff > 1.0
		or not is_finite(chain_radius)
		or chain_radius < 0.0
		or (chain_enabled and (chain_jumps <= 0 or chain_radius <= 0.0))
		or not is_finite(aim_spread_degrees)
		or aim_spread_degrees < 0.0
		or aim_spread_degrees >= 90.0
	):
		return false
	_projectile_chain_enabled = chain_enabled
	_projectile_chain_jumps = chain_jumps
	_projectile_chain_damage_falloff = chain_damage_falloff
	_projectile_chain_radius = chain_radius
	_projectile_aim_spread_degrees = aim_spread_degrees
	return true


func reset_projectile_upgrade_modifiers() -> void:
	_projectile_chain_enabled = false
	_projectile_chain_jumps = 0
	_projectile_chain_damage_falloff = 1.0
	_projectile_chain_radius = 0.0
	_projectile_aim_spread_degrees = 0.0


func set_projectile_shape_modifiers(
	pierce_count: int,
	pierce_damage_falloff: float,
	multishot_count: int,
	multishot_spread_degrees: float,
	death_burst_enabled: bool,
	death_burst_radius: float,
	death_burst_damage_multiplier: float
) -> bool:
	if (
		pierce_count < 1
		or not is_finite(pierce_damage_falloff)
		or pierce_damage_falloff <= 0.0
		or pierce_damage_falloff > 1.0
		or multishot_count < 1
		or not is_finite(multishot_spread_degrees)
		or multishot_spread_degrees < 0.0
		or multishot_spread_degrees >= 180.0
		or (multishot_count > 1 and multishot_spread_degrees <= 0.0)
		or not is_finite(death_burst_radius)
		or death_burst_radius < 0.0
		or not is_finite(death_burst_damage_multiplier)
		or death_burst_damage_multiplier < 0.0
		or (death_burst_enabled and (death_burst_radius <= 0.0 or death_burst_damage_multiplier <= 0.0))
	):
		return false
	_pierce_count = pierce_count
	_pierce_damage_falloff = pierce_damage_falloff
	_multishot_count = multishot_count
	_multishot_spread_degrees = multishot_spread_degrees
	_death_burst_enabled = death_burst_enabled
	_death_burst_radius = death_burst_radius
	_death_burst_damage_multiplier = death_burst_damage_multiplier
	return true


func reset_projectile_shape_modifiers() -> void:
	_pierce_count = 1
	_pierce_damage_falloff = 1.0
	_multishot_count = 1
	_multishot_spread_degrees = 0.0
	_death_burst_enabled = false
	_death_burst_radius = 0.0
	_death_burst_damage_multiplier = 0.0


func get_effective_pierce_count() -> int:
	return maxi(_base_pierce_count, _pierce_count)


func get_effective_pierce_damage_falloff() -> float:
	return _pierce_damage_falloff if _pierce_count >= _base_pierce_count else _base_pierce_damage_falloff


func get_effective_multishot_count() -> int:
	return maxi(_base_multishot_count, _multishot_count)


func get_effective_multishot_spread_degrees() -> float:
	return (
		_multishot_spread_degrees
		if _multishot_count >= _base_multishot_count
		else _base_multishot_spread_degrees
	)


func is_death_burst_enabled() -> bool:
	return _death_burst_enabled


func get_death_burst_radius() -> float:
	return _death_burst_radius


func get_death_burst_damage_multiplier() -> float:
	return _death_burst_damage_multiplier


func is_projectile_chain_enabled() -> bool:
	return _projectile_chain_enabled


func get_projectile_chain_jumps() -> int:
	return _projectile_chain_jumps


func get_projectile_chain_damage_falloff() -> float:
	return _projectile_chain_damage_falloff


func get_projectile_chain_radius() -> float:
	return _projectile_chain_radius


func get_projectile_aim_spread_degrees() -> float:
	return _projectile_aim_spread_degrees


func get_base_shots_per_second() -> float:
	return _base_shots_per_second * _character_fire_rate_multiplier


func get_base_damage() -> float:
	return _base_damage * _character_damage_multiplier


func get_fire_rate_multiplier() -> float:
	return _fire_rate_multiplier


func get_damage_multiplier() -> float:
	return _damage_multiplier


func get_projectile_speed_multiplier() -> float:
	return _projectile_speed_multiplier


func get_character_fire_rate_multiplier() -> float:
	return _character_fire_rate_multiplier


func get_character_damage_multiplier() -> float:
	return _character_damage_multiplier


func get_effective_shots_per_second() -> float:
	return get_base_shots_per_second() * _fire_rate_multiplier


func get_effective_damage() -> float:
	return get_base_damage() * _damage_multiplier


func get_character_critical_chance_bonus() -> float:
	return _character_critical_chance_bonus


func get_critical_chance_bonus() -> float:
	return _critical_chance_bonus


func get_critical_damage_multiplier() -> float:
	return _critical_damage_multiplier


## Somma delle due sorgenti (scarto base del personaggio + carta catalogo),
## sempre limitata al cap dichiarato: mai un singolo personaggio o una
## singola carta possono superarlo da soli, ma nemmeno insieme.
func get_effective_critical_chance() -> float:
	return clampf(
		_character_critical_chance_bonus + _critical_chance_bonus,
		0.0,
		MAXIMUM_CRITICAL_CHANCE
	)


## Danno effettivo di un singolo colpo, con l'eventuale critico già risolto e
## applicato. Chiamata una sola volta per proiettile, allo spawn: il pierce
## applica il proprio decadimento sul valore già risolto qui, non ne innesca
## uno nuovo per bersaglio colpito (stesso contratto di `get_effective_damage()`
## rispetto al pierce, solo con il critico deciso a monte). Deterministica per
## seed: `_critical_rng` è seminato dal seed di run, mai dall'orologio di
## sistema, e resta indipendente dallo stream di mira (`_aim_rng`).
func resolve_shot_damage() -> float:
	var base_damage := get_effective_damage()
	_last_shot_was_critical = _critical_rng.randf() < get_effective_critical_chance()
	if not _last_shot_was_critical:
		return base_damage
	return base_damage * get_critical_damage_multiplier()


func was_last_shot_critical() -> bool:
	return _last_shot_was_critical


func get_effective_projectile_speed() -> float:
	return weapon_profile.projectile_speed * _projectile_speed_multiplier if weapon_profile != null else 0.0


func get_effective_fire_interval() -> float:
	var shots_per_second := get_effective_shots_per_second()
	return 1.0 / shots_per_second if shots_per_second > 0.0 else INF


func _has_valid_dependencies() -> bool:
	return (
		weapon_profile != null
		and get_effective_shots_per_second() > 0.0
		and projectile_scene != null
		and _projectile_scene_valid
		and is_instance_valid(_run_controller)
		and is_instance_valid(_targeting_system)
		and is_instance_valid(_projectile_parent)
		and _projectile_parent.is_inside_tree()
		and is_instance_valid(_source)
	)


func _capture_base_stats() -> void:
	if weapon_profile == null:
		_base_shots_per_second = 0.0
		_base_damage = 0.0
		_base_pierce_count = 1
		_base_pierce_damage_falloff = 1.0
		_base_multishot_count = 1
		_base_multishot_spread_degrees = 0.0
		return
	_base_shots_per_second = weapon_profile.shots_per_second
	_base_damage = weapon_profile.damage
	_base_pierce_count = weapon_profile.base_pierce_count
	_base_pierce_damage_falloff = weapon_profile.base_pierce_damage_falloff
	_base_multishot_count = weapon_profile.base_multishot_count
	_base_multishot_spread_degrees = weapon_profile.base_multishot_spread_degrees


func _connect_run_controller() -> void:
	if not is_instance_valid(_run_controller):
		return
	if not _run_controller.run_started.is_connected(_on_run_started):
		_run_controller.run_started.connect(_on_run_started)
	if not _run_controller.restart_prepared.is_connected(_on_restart_prepared):
		_run_controller.restart_prepared.connect(_on_restart_prepared)


func _disconnect_run_controller() -> void:
	if not is_instance_valid(_run_controller):
		_run_controller = null
		return
	if _run_controller.run_started.is_connected(_on_run_started):
		_run_controller.run_started.disconnect(_on_run_started)
	if _run_controller.restart_prepared.is_connected(_on_restart_prepared):
		_run_controller.restart_prepared.disconnect(_on_restart_prepared)
	_run_controller = null


func _apply_aim_spread(aim_direction: Vector2) -> Vector2:
	if _projectile_aim_spread_degrees <= 0.0:
		return aim_direction
	var spread_radians := deg_to_rad(_projectile_aim_spread_degrees)
	return aim_direction.rotated(_aim_rng.randf_range(-spread_radians, spread_radians))


func _seed_aim_rng(seed_value: int) -> void:
	# Stream locale: la stessa run e la stessa sequenza di colpi producono la
	# stessa dispersione, senza consumare l'RNG della pesca o dello spawn.
	_aim_rng.seed = seed_value ^ 0x42454552


func _seed_critical_rng(seed_value: int) -> void:
	# Stream locale e indipendente da _aim_rng: la stessa run produce sempre
	# la stessa sequenza di critici, senza consumare lo stream di mira.
	_critical_rng.seed = seed_value ^ 0x43524954


func _on_run_started(seed_value: int) -> void:
	_seed_aim_rng(seed_value)
	_seed_critical_rng(seed_value)
	reset_for_run()


func _on_restart_prepared() -> void:
	reset_for_run()


## Angoli deterministici (radianti) del ventaglio di colpi multipli, centrati
## sulla direzione di mira. Nessun RNG: la dispersione e' dichiarata dalla
## carta, non casuale, cosi' resta identica a parita' di seed senza consumare
## lo stream dell'RNG di mira.
## Offset angolari del ventaglio, ancorati alla linea di mira: un proiettile
## resta sempre a 0 gradi cosi un bersaglio fermo viene sempre colpito, e gli
## extra si aggiungono a coppie simmetriche (+/-passo, +/-2 passi, ...). Il
## passo resta `spread_degrees / (count - 1)`, cioe la dispersione dichiarata
## per proiettile dall'upgrade. Con un numero pari di proiettili il colpo
## spaiato finisce sul lato scelto da `mirror`, che il controller alterna a
## ogni raffica per non favorire sempre lo stesso fianco.
static func calculate_multishot_fan_offsets(
	count: int,
	spread_degrees: float,
	mirror := false
) -> Array[float]:
	var offsets: Array[float] = []
	if count <= 1:
		offsets.append(0.0)
		return offsets
	var step := deg_to_rad(spread_degrees) / float(count - 1)
	var extra_side := -1.0 if mirror else 1.0
	offsets.append(0.0)
	var ring := 1
	while offsets.size() < count:
		offsets.append(extra_side * float(ring) * step)
		if offsets.size() < count:
			offsets.append(-extra_side * float(ring) * step)
		ring += 1
	offsets.sort()
	return offsets


## Kill/s teorico di una build completa contro nemici da enemy_health, a zero
## overkill e zero tempo di volo (stesso metodo dell'appendice B41): somma il
## danno di tutti i bersagli perforati da un proiettile, lo moltiplica per i
## proiettili del ventaglio e per la cadenza effettiva, poi divide per la vita
## nemica. Funzione pura, usata dallo smoke B41 per il tetto aritmetico.
static func calculate_full_build_kill_rate_per_second(
	base_shots_per_second: float,
	base_damage: float,
	fire_rate_multiplier: float,
	damage_multiplier: float,
	multishot_count: int,
	pierce_count: int,
	pierce_damage_falloff: float,
	enemy_health: float
) -> float:
	if (
		enemy_health <= 0.0
		or base_shots_per_second <= 0.0
		or base_damage <= 0.0
		or fire_rate_multiplier <= 0.0
		or damage_multiplier <= 0.0
	):
		return 0.0
	var effective_shots_per_second := base_shots_per_second * fire_rate_multiplier
	var effective_damage := base_damage * damage_multiplier
	var pierce_damage_sum := 0.0
	var hit_damage := effective_damage
	for _hit_index in range(maxi(pierce_count, 1)):
		pierce_damage_sum += hit_damage
		hit_damage *= pierce_damage_falloff
	var total_dps := effective_shots_per_second * float(maxi(multishot_count, 1)) * pierce_damage_sum
	return total_dps / enemy_health
