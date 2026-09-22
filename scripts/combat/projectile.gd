class_name Projectile
extends Area2D

signal hit_processed(target: BaseEnemy, damage: float)
signal expired(projectile: Projectile)
signal chain_jumped(from_target: BaseEnemy, to_target: BaseEnemy, damage: float)

const ENEMY_HURTBOX_MASK := 1 << 1
const VISUAL_REFERENCE_RADIUS := 5.0
## Divisore minimo per il progresso delle traiettorie a rampa: evita la
## divisione per zero su un proiettile creato con lifetime nulla.
const MINIMUM_RAMP_LIFETIME := 0.001

## Traiettorie dichiarate dalle armi (PS-198). Un solo campo su Projectile
## invece di una sottoclasse per arma: il corpo del proiettile, le collisioni
## e tutti gli effetti delle Specialita' restano esattamente gli stessi,
## cambia solo come il punto si sposta nel tempo.
const TRAJECTORY_STRAIGHT := &"straight"
const TRAJECTORY_SPLIT := &"split"
const TRAJECTORY_ORBIT := &"orbit"
## PS-200. `FADING` e `BUILDING` condividono la stessa matematica con fattore
## minore o maggiore di 1: restano due nomi distinti perche' sono due scelte di
## progetto opposte (un colpo che si esaurisce, uno che prende forza), e il
## criterio dei cinque assi di PS-196 le deve poter distinguere.
const TRAJECTORY_RETURN := &"return"
const TRAJECTORY_FADING := &"fading"
const TRAJECTORY_BUILDING := &"building"
const TRAJECTORY_LINGERING := &"lingering"
## PS-202: disegno a primitive dichiarato dai dati dell'arma (`visual`), per
## provare in partita un'arma prima di commissionarne l'arte. Senza `visual`
## il colpo resta lo sprite della brace.
const VISUAL_LID := &"lid"
const LID_FILL_COLOR := Color(0.30, 0.31, 0.34)
const LID_RIM_COLOR := Color(0.78, 0.80, 0.84)
const LID_HANDLE_COLOR := Color(0.12, 0.12, 0.13)
const LID_TRAIL_COLOR := Color(1.0, 0.62, 0.28, 0.22)
## PS-207: un colpo `building` che dichiara `heat_full_distance` si arroventa
## col volo: il danno va da `heat_start_damage_factor` a
## `heat_end_damage_factor` sui primi `heat_full_distance` px, e il colore
## dalla brace scura al bianco rovente. Oltre 1 il colore schiarisce lo sprite.
const HEAT_COLD_COLOR := Color(0.55, 0.24, 0.14)
const HEAT_HOT_COLOR := Color(1.6, 1.5, 1.3)
## La scia e' la strada fatta in questo tempo: si allunga con la velocita'.
const HEAT_TRAIL_SECONDS := 0.05

var damage := 0.0
var direction := Vector2.RIGHT
var speed := 0.0
var lifetime_remaining := 0.0
var projectile_radius := 6.0

var _run_controller: RunController
var _spent := false
var _chain_enabled := false
var _chain_jumps_remaining := 0
var _chain_damage_falloff := 1.0
var _chain_radius := 0.0
var _chain_current_damage := 0.0
var _aim_spread_degrees := 0.0
var _targeting_system: TargetingSystem
var _hit_target_ids: Dictionary = {}
var _pierce_enabled := false
var _pierce_remaining := 1
var _pierce_damage_falloff := 1.0
var _pierce_current_damage := 0.0
var _death_burst_enabled := false
var _death_burst_radius := 0.0
var _death_burst_damage_multiplier := 0.0
var _trajectory := TRAJECTORY_STRAIGHT
var _elapsed := 0.0
var _split_delay := 0.0
var _split_turn_radians := 0.0
var _split_done := false
var _orbit_anchor: Node2D
var _orbit_radius := 0.0
var _orbit_angle := 0.0
var _orbit_start_angle := 0.0
var _visual := &""
var _initial_lifetime := 0.0
var _turn_seconds := 0.0
var _returned := false
var _end_speed_factor := 1.0
var _speed_factor := 1.0
var _travel_seconds := 0.0
var _distance_travelled := 0.0
var _heat_full_distance := 0.0
var _heat_start_damage_factor := 1.0
var _heat_end_damage_factor := 1.0

@onready var _collision_shape: CollisionShape2D = %CollisionShape
@onready var _projectile_sprite: Sprite2D = %ProjectileSprite


func _ready() -> void:
	# Simmetrico a BossProjectile: la zona Zen di Evil Migi (PS-006) assorbe i
	# proiettili alleati e ha bisogno di poterli enumerare senza conoscere il
	# nodo che li ospita.
	add_to_group(&"player_projectiles")
	_make_collision_shape_unique()
	_sync_collision_radius()
	_sync_visual_scale()
	collision_layer = 0
	collision_mask = ENEMY_HURTBOX_MASK
	monitoring = true
	monitorable = false
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	if _spent or not is_instance_valid(_run_controller) or not _run_controller.is_running():
		return

	var safe_delta := maxf(delta, 0.0)
	var movement_delta := minf(safe_delta, maxf(lifetime_remaining, 0.0))
	_elapsed += movement_delta
	match _trajectory:
		TRAJECTORY_ORBIT:
			# Il frammento e' agganciato alla sorgente: se la sorgente sparisce
			# sparisce anche l'orbita, invece di restare a girare attorno al
			# nulla all'ultima posizione nota.
			if not is_instance_valid(_orbit_anchor):
				expire()
				return
			_orbit_angle += (speed / _orbit_radius) * movement_delta
			global_position = (
				_orbit_anchor.global_position
				+ Vector2.RIGHT.rotated(_orbit_angle) * _orbit_radius
			)
			direction = Vector2.RIGHT.rotated(_orbit_angle + PI * 0.5)
			rotation = direction.angle()
		TRAJECTORY_SPLIT:
			if not _split_done and _elapsed >= _split_delay:
				_split_done = true
				direction = direction.rotated(_split_turn_radians)
				rotation = direction.angle()
			global_position += direction * speed * movement_delta
		TRAJECTORY_RETURN:
			# Il ritorno non ricolpisce chi ha gia' colpito all'andata
			# (`_hit_target_ids`): al rientro prende chi si e' chiuso alle
			# spalle. Azzerare il registro raddoppierebbe il danno su bersaglio
			# singolo e sfonderebbe il tetto di kill-rate dichiarato.
			if not _returned and _elapsed >= _turn_seconds:
				_returned = true
				direction = -direction
				rotation = direction.angle()
			global_position += direction * speed * movement_delta
		TRAJECTORY_FADING, TRAJECTORY_BUILDING:
			_speed_factor = lerpf(
				1.0, _end_speed_factor, clampf(_elapsed / _initial_lifetime, 0.0, 1.0)
			)
			var step := speed * _speed_factor * movement_delta
			global_position += direction * step
			_distance_travelled += step
			if is_heated():
				_sync_heat_visual()
		TRAJECTORY_LINGERING:
			# Oltre la corsa dichiarata il colpo si ferma e resta dov'e':
			# continua a colpire chi ci passa sopra finche' la perforazione
			# base dell'arma non e' esaurita o la lifetime non scade.
			# Si muove solo per la porzione di passo che cade dentro la
			# finestra di corsa: con un confronto secco su `_elapsed`, un
			# frame piu' lungo della corsa la salterebbe per intero e il
			# colpo resterebbe incollato alla volata.
			var travel_delta := clampf(
				_travel_seconds - (_elapsed - movement_delta), 0.0, movement_delta
			)
			if travel_delta > 0.0:
				global_position += direction * speed * travel_delta
		_:
			global_position += direction * speed * movement_delta
	if not _visual.is_empty():
		queue_redraw()
	lifetime_remaining -= safe_delta
	if lifetime_remaining <= 0.0:
		expire()
		return

func initialize(
	initial_direction: Vector2,
	initial_damage: float,
	initial_speed: float,
	initial_lifetime: float,
	initial_radius: float,
	run_controller: RunController
) -> bool:
	if (
		initial_direction.is_zero_approx()
		or not initial_direction.is_finite()
		or not is_finite(initial_damage)
		or initial_damage <= 0.0
	):
		return false

	direction = initial_direction.normalized()
	damage = initial_damage
	speed = maxf(initial_speed, 0.0) if is_finite(initial_speed) else 0.0
	lifetime_remaining = maxf(initial_lifetime, 0.0) if is_finite(initial_lifetime) else 0.0
	projectile_radius = maxf(initial_radius, 1.0) if is_finite(initial_radius) else 1.0
	_run_controller = run_controller
	rotation = direction.angle()
	if is_node_ready():
		_sync_collision_radius()
		_sync_visual_scale()
	return lifetime_remaining > 0.0 and is_instance_valid(_run_controller)


## Traiettoria dichiarata dall'arma, applicata dopo `initialize()` perche'
## legge `direction`. Una traiettoria sconosciuta o con parametri malformati
## degrada al colpo dritto invece di far fallire lo sparo.
func configure_trajectory(
	trajectory: StringName,
	parameters: Dictionary = {},
	anchor: Node2D = null
) -> bool:
	_trajectory = TRAJECTORY_STRAIGHT
	_elapsed = 0.0
	_split_done = false
	_returned = false
	_speed_factor = 1.0
	_distance_travelled = 0.0
	_heat_full_distance = 0.0
	_heat_start_damage_factor = 1.0
	_heat_end_damage_factor = 1.0
	_initial_lifetime = maxf(lifetime_remaining, MINIMUM_RAMP_LIFETIME)
	_visual = StringName(parameters.get("visual", &""))
	if is_instance_valid(_projectile_sprite):
		_projectile_sprite.visible = _visual.is_empty()
	queue_redraw()
	match trajectory:
		TRAJECTORY_SPLIT:
			var delay := float(parameters.get("delay", 0.0))
			var turn_degrees := float(parameters.get("turn_degrees", 0.0))
			if not is_finite(delay) or delay < 0.0 or not is_finite(turn_degrees):
				return false
			_split_delay = delay
			_split_turn_radians = deg_to_rad(turn_degrees)
			_trajectory = TRAJECTORY_SPLIT
		TRAJECTORY_ORBIT:
			var radius := float(parameters.get("radius", 0.0))
			if not is_finite(radius) or radius <= 0.0 or not is_instance_valid(anchor):
				return false
			_orbit_radius = radius
			_orbit_anchor = anchor
			_orbit_angle = direction.angle()
			_orbit_start_angle = _orbit_angle
			global_position = (
				anchor.global_position + Vector2.RIGHT.rotated(_orbit_angle) * radius
			)
			_trajectory = TRAJECTORY_ORBIT
		TRAJECTORY_RETURN:
			var outbound_seconds := float(parameters.get("outbound_seconds", 0.0))
			if not is_finite(outbound_seconds) or outbound_seconds <= 0.0:
				return false
			_turn_seconds = outbound_seconds
			_trajectory = TRAJECTORY_RETURN
		TRAJECTORY_FADING, TRAJECTORY_BUILDING:
			var end_speed_factor := float(parameters.get("end_speed_factor", 1.0))
			if not is_finite(end_speed_factor) or end_speed_factor < 0.0:
				return false
			_end_speed_factor = end_speed_factor
			_trajectory = trajectory
			if trajectory == TRAJECTORY_BUILDING and not _configure_heat(parameters):
				return false
		TRAJECTORY_LINGERING:
			var travel_seconds := float(parameters.get("travel_seconds", 0.0))
			if not is_finite(travel_seconds) or travel_seconds < 0.0:
				return false
			_travel_seconds = travel_seconds
			_trajectory = TRAJECTORY_LINGERING
	return true


func get_trajectory() -> StringName:
	return _trajectory


func is_heated() -> bool:
	return _heat_full_distance > 0.0


## 0 appena partito, 1 dopo `heat_full_distance` px di volo (PS-207).
func get_heat_ratio() -> float:
	return clampf(_distance_travelled / _heat_full_distance, 0.0, 1.0) if is_heated() else 0.0


func get_heat_damage_factor() -> float:
	if not is_heated():
		return 1.0
	return lerpf(_heat_start_damage_factor, _heat_end_damage_factor, get_heat_ratio())


func get_heat_trail_length() -> float:
	return speed * _speed_factor * HEAT_TRAIL_SECONDS if is_heated() else 0.0


func _configure_heat(parameters: Dictionary) -> bool:
	if not parameters.has("heat_full_distance"):
		return true
	var full_distance := float(parameters.get("heat_full_distance", 0.0))
	var start_factor := float(parameters.get("heat_start_damage_factor", 1.0))
	var end_factor := float(parameters.get("heat_end_damage_factor", 1.0))
	if (
		not is_finite(full_distance) or full_distance <= 0.0
		or not is_finite(start_factor) or start_factor <= 0.0
		or not is_finite(end_factor) or end_factor <= 0.0
	):
		return false
	_heat_full_distance = full_distance
	_heat_start_damage_factor = start_factor
	_heat_end_damage_factor = end_factor
	_sync_heat_visual()
	return true


func _sync_heat_visual() -> void:
	if is_instance_valid(_projectile_sprite):
		_projectile_sprite.modulate = HEAT_COLD_COLOR.lerp(HEAT_HOT_COLOR, get_heat_ratio())
	queue_redraw()


func get_orbit_radius() -> float:
	return _orbit_radius


func get_visual() -> StringName:
	return _visual


func has_split() -> bool:
	return _split_done


func has_returned() -> bool:
	return _returned


func configure_signature_effects(
	chain_enabled: bool,
	chain_jumps: int,
	chain_damage_falloff: float,
	chain_radius: float,
	aim_spread_degrees: float,
	targeting_system: TargetingSystem = null
) -> bool:
	if (
		chain_jumps < 0
		or not is_finite(chain_damage_falloff)
		or chain_damage_falloff <= 0.0
		or chain_damage_falloff > 1.0
		or not is_finite(chain_radius)
		or chain_radius < 0.0
		or (chain_enabled and (chain_jumps <= 0 or chain_radius <= 0.0))
		or (chain_enabled and not is_instance_valid(targeting_system))
		or not is_finite(aim_spread_degrees)
		or aim_spread_degrees < 0.0
		or aim_spread_degrees >= 90.0
	):
		return false
	_chain_enabled = chain_enabled
	_chain_jumps_remaining = chain_jumps
	_chain_damage_falloff = chain_damage_falloff
	_chain_radius = chain_radius
	_chain_current_damage = damage
	_aim_spread_degrees = aim_spread_degrees
	_targeting_system = targeting_system
	_hit_target_ids.clear()
	return true


func configure_shape_effects(
	pierce_count: int,
	pierce_damage_falloff: float,
	death_burst_enabled: bool,
	death_burst_radius: float,
	death_burst_damage_multiplier: float
) -> bool:
	if (
		pierce_count < 1
		or not is_finite(pierce_damage_falloff)
		or pierce_damage_falloff <= 0.0
		or pierce_damage_falloff > 1.0
		or not is_finite(death_burst_radius)
		or death_burst_radius < 0.0
		or not is_finite(death_burst_damage_multiplier)
		or death_burst_damage_multiplier < 0.0
		or (death_burst_enabled and (death_burst_radius <= 0.0 or death_burst_damage_multiplier <= 0.0))
	):
		return false
	# La perforazione cede il passo alla catena (Gossip): sono due modi diversi
	# di continuare oltre il primo bersaglio e non compongono la stessa vita.
	_pierce_enabled = pierce_count > 1 and not _chain_enabled
	_pierce_remaining = pierce_count
	_pierce_damage_falloff = pierce_damage_falloff
	_pierce_current_damage = damage
	_death_burst_enabled = death_burst_enabled
	_death_burst_radius = death_burst_radius
	_death_burst_damage_multiplier = death_burst_damage_multiplier
	return true


func try_hit(target: BaseEnemy) -> bool:
	if (
		_spent
		or not is_instance_valid(_run_controller)
		or not _run_controller.is_running()
		or not is_instance_valid(target)
		or target.is_queued_for_deletion()
		or not target.is_alive()
	):
		return false

	var target_instance_id := target.get_instance_id()
	if _hit_target_ids.has(target_instance_id):
		return false
	_hit_target_ids[target_instance_id] = true
	var is_multi_hit := _chain_enabled or _pierce_enabled
	var hit_damage := _current_hit_damage()
	# Il latch precede il danno: callback duplicate o rientranti non possono
	# riutilizzare lo stesso bersaglio durante la catena o la perforazione.
	if not is_multi_hit:
		_spent = true
		_disable_immediately()
	var damage_applied := target.take_damage(hit_damage)
	if damage_applied:
		hit_processed.emit(target, hit_damage)
		if _death_burst_enabled and not target.is_alive():
			_trigger_death_burst(target.global_position)
	if not is_multi_hit:
		queue_free()
		return damage_applied

	if _chain_enabled:
		if not damage_applied or _chain_jumps_remaining <= 0:
			expire()
			return damage_applied

		_chain_jumps_remaining -= 1
		_chain_current_damage *= _chain_damage_falloff
		global_position = target.global_position
		var next_target := _targeting_system.get_nearest_alive_excluding(
			global_position,
			_hit_target_ids
		)
		if (
			next_target == null
			or global_position.distance_to(next_target.global_position) > _chain_radius
		):
			expire()
			return damage_applied
		chain_jumped.emit(target, next_target, _chain_current_damage)
		try_hit(next_target)
		return damage_applied

	_pierce_remaining -= 1
	if not damage_applied or _pierce_remaining <= 0:
		expire()
		return damage_applied
	_pierce_current_damage *= _pierce_damage_falloff
	return damage_applied


func _current_hit_damage() -> float:
	if _chain_enabled:
		return _chain_current_damage * get_heat_damage_factor()
	if _pierce_enabled:
		return _pierce_current_damage * get_heat_damage_factor()
	return damage * get_heat_damage_factor()


func _trigger_death_burst(origin: Vector2) -> void:
	if not is_instance_valid(_targeting_system):
		return
	var burst_damage := damage * _death_burst_damage_multiplier
	if burst_damage <= 0.0:
		return
	for enemy in _targeting_system.get_alive_targets():
		if not is_instance_valid(enemy) or not enemy.is_alive():
			continue
		if origin.distance_to(enemy.global_position) > _death_burst_radius:
			continue
		enemy.take_damage(burst_damage)


func expire() -> void:
	if _spent:
		return
	_spent = true
	_disable_immediately()
	expired.emit(self)
	queue_free()


func is_spent() -> bool:
	return _spent


func get_run_controller() -> RunController:
	return _run_controller if is_instance_valid(_run_controller) else null


func is_chain_enabled() -> bool:
	return _chain_enabled


func get_chain_jumps_remaining() -> int:
	return _chain_jumps_remaining


func get_chain_damage_falloff() -> float:
	return _chain_damage_falloff


func get_chain_radius() -> float:
	return _chain_radius


func get_aim_spread_degrees() -> float:
	return _aim_spread_degrees


func is_pierce_enabled() -> bool:
	return _pierce_enabled


func get_pierce_remaining() -> int:
	return _pierce_remaining


func get_pierce_damage_falloff() -> float:
	return _pierce_damage_falloff


func is_death_burst_enabled() -> bool:
	return _death_burst_enabled


func get_death_burst_radius() -> float:
	return _death_burst_radius


func get_death_burst_damage_multiplier() -> float:
	return _death_burst_damage_multiplier


func has_hit_target(target: BaseEnemy) -> bool:
	return is_instance_valid(target) and _hit_target_ids.has(target.get_instance_id())


# ponytail: primitive provvisorie del solo Coperchio (PS-202); lasciano il
# posto a uno sprite dedicato se la prova passa e si apre la card art.
func _draw() -> void:
	if is_heated():
		# Il nodo e' ruotato sulla direzione: la scia sta sul semiasse -X.
		var heat_color := HEAT_COLD_COLOR.lerp(HEAT_HOT_COLOR, get_heat_ratio())
		var trail_end := Vector2.LEFT * get_heat_trail_length()
		draw_line(Vector2.ZERO, trail_end, Color(heat_color, 0.35), projectile_radius * 2.0, true)
		draw_line(Vector2.ZERO, trail_end * 0.6, Color(heat_color, 0.7), projectile_radius, true)
	if _visual != VISUAL_LID:
		return
	# La scia e' l'arco gia' spazzato, disegnato attorno al personaggio largo
	# quanto il coperchio: e' lei a far leggere il colpo come un fendente.
	if _trajectory == TRAJECTORY_ORBIT and is_instance_valid(_orbit_anchor):
		draw_arc(
			to_local(_orbit_anchor.global_position),
			_orbit_radius,
			_orbit_start_angle - global_rotation,
			_orbit_angle - global_rotation,
			16,
			LID_TRAIL_COLOR,
			projectile_radius * 2.0
		)
	draw_circle(Vector2.ZERO, projectile_radius, LID_FILL_COLOR)
	draw_arc(Vector2.ZERO, projectile_radius, 0.0, TAU, 24, LID_RIM_COLOR, 3.0)
	draw_rect(
		Rect2(
			-projectile_radius * 0.15, -projectile_radius * 0.4,
			projectile_radius * 0.3, projectile_radius * 0.8
		),
		LID_HANDLE_COLOR
	)


func _on_area_entered(area: Area2D) -> void:
	if _spent or not area is Hurtbox:
		return
	var receiver := (area as Hurtbox).get_damage_receiver()
	if receiver is BaseEnemy:
		try_hit(receiver as BaseEnemy)


func _disable_immediately() -> void:
	set_physics_process(false)
	set_deferred("monitoring", false)
	set_deferred("collision_mask", 0)


func _make_collision_shape_unique() -> void:
	var circle_shape := CircleShape2D.new()
	if _collision_shape.shape is CircleShape2D:
		circle_shape = _collision_shape.shape.duplicate() as CircleShape2D
	_collision_shape.shape = circle_shape


func _sync_collision_radius() -> void:
	if _collision_shape.shape is CircleShape2D:
		(_collision_shape.shape as CircleShape2D).radius = projectile_radius


func _sync_visual_scale() -> void:
	if is_instance_valid(_projectile_sprite):
		_projectile_sprite.scale = Vector2.ONE * (projectile_radius / VISUAL_REFERENCE_RADIUS)
