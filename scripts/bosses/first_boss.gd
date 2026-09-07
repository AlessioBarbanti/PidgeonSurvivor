class_name FirstBoss
extends BaseEnemy

signal attack_telegraphed(
	boss: FirstBoss,
	pattern_id: StringName,
	duration: float
)
signal attack_executed(
	boss: FirstBoss,
	pattern_id: StringName,
	affected_count: int
)
## PS-006: la Signature scelta viene annunciata all'inizio del telegraph, cosi'
## il giocatore sa cosa sta arrivando prima che diventi pericolosa. Per Evil
## Lollo e' anche il momento in cui si conosce la copia estratta.
signal signature_announced(
	boss: FirstBoss,
	signature: BossSignatureDefinition
)

const RADIAL_VOLLEY := &"radial_volley"
const TARGETED_BLAST := &"targeted_blast"
const SIGNATURE := &"signature"

## PS-033: senza più una HUD dedicata, la barra vita disegnata da BaseEnemy
## sopra lo sprite resta l'unico indicatore del Boss e va resa più leggibile.
const BOSS_HEALTH_BAR_THICKNESS := 9.0
const BOSS_HEALTH_BAR_LENGTH_SCALE := 1.6

## PS-006: la carica del Tuono di Evil Zat legge il danno gia' subito dal Boss,
## la controparte del danno recuperabile che alimenta la versione Player
## (PS-004). Soglie e moltiplicatori restano configurabili dai dati.
const THUNDER_MEDIUM_THRESHOLD := 0.2
const THUNDER_HIGH_THRESHOLD := 0.5
const THUNDER_AURA_ROTATION_SPEED := 1.4

enum SignatureMotion {
	NONE,
	## Powerslide di Evil Bea: scatto rettilineo lungo la traiettoria mostrata.
	DASH,
	## Gran Piroetta di Evil Alea: inseguimento lento che non puo' cambiare
	## direzione all'istante.
	SPIN,
}

@export var definition: BossDefinition
@export var projectile_scene: PackedScene
@export var decoy_scene: PackedScene

var _projectile_parent: Node
var _attack_cooldown_remaining := 0.0
var _active_pattern_id: StringName
var _telegraph_remaining := 0.0
var _telegraph_duration := 0.0
var _targeted_position := Vector2.ZERO
var _next_pattern_index := 0
var _radial_volley_count := 0
var _targeted_blast_count := 0
var _signature_count := 0
var _active_projectiles: Array[BossProjectile] = []

var _signature: BossSignatureDefinition
var _announced_signature: BossSignatureDefinition
var _copy_candidates: Array[BossSignatureDefinition] = []
var _schedule_index := 0
var _targeting_system: TargetingSystem
var _enemy_parent: Node
var _signature_origin := Vector2.ZERO
var _signature_direction := Vector2.RIGHT
var _signature_corridor_end := Vector2.INF
var _signature_serial := 0
var _active_signature_areas: Array[BossSignatureArea] = []
var _active_decoy: BossDecoy
var _signature_motion := SignatureMotion.NONE
var _signature_motion_remaining := 0.0
var _signature_motion_speed := 0.0
var _signature_motion_turn_rate := 0.0
var _thunder_charge_tier := ThunderChargeAura.TIER_LOW

@onready var _boss_sprite := get_node_or_null("BossSprite") as Sprite2D
@onready var _thunder_aura := get_node_or_null("ThunderChargeAura") as ThunderChargeAura


func _ready() -> void:
	super._ready()
	health_bar_thickness = BOSS_HEALTH_BAR_THICKNESS
	health_bar_length_scale = BOSS_HEALTH_BAR_LENGTH_SCALE
	_sync_boss_visual()
	_sync_thunder_aura()


func _exit_tree() -> void:
	clear_attack_runtime()
	super._exit_tree()


func _physics_process(delta: float) -> void:
	if _advance_signature_motion(delta):
		_sync_boss_facing()
		_advance_attack_cycle(delta)
		return
	super._physics_process(delta)
	_sync_boss_facing()
	_advance_thunder_aura(delta)
	_advance_attack_cycle(delta)


func _draw() -> void:
	super._draw()
	_draw_active_telegraph()
	_draw_signature_motion()


func configure_boss(
	definition_value: BossDefinition,
	target: Player,
	run_controller: RunController,
	projectile_parent: Node
) -> bool:
	if (
		definition_value == null
		or not definition_value.is_valid()
		or not is_instance_valid(target)
		or not is_instance_valid(run_controller)
		or not is_instance_valid(projectile_parent)
		or projectile_scene == null
	):
		return false

	definition = definition_value
	_projectile_parent = projectile_parent
	_signature = definition.signature
	move_speed = definition.move_speed
	collision_radius = definition.collision_radius
	body_color = definition.body_color
	outline_color = definition.outline_color
	accent_color = definition.accent_color
	_sync_boss_visual()
	set_target(target)
	set_run_controller(run_controller)

	var health_component := get_health_component()
	var contact_damage := get_contact_damage()
	if health_component == null or contact_damage == null:
		return false
	health_component.set_health_max(definition.health_max)
	health_component.reset_to_max()
	contact_damage.damage = definition.contact_damage
	reset_attack_cycle()
	_sync_thunder_aura()
	return true


## Contesto runtime della Signature (PS-006). Resta separato da
## `configure_boss` perche' serve solo agli Evil: il piccione baseline non ha
## Signature e continua a girare sui due soli pattern comuni.
func configure_signature(
	copy_candidates: Array[BossSignatureDefinition],
	schedule_index: int,
	targeting_system: TargetingSystem,
	enemy_parent: Node
) -> bool:
	_copy_candidates = copy_candidates.duplicate()
	_schedule_index = maxi(schedule_index, 0)
	_targeting_system = targeting_system
	_enemy_parent = enemy_parent
	_sync_thunder_aura()
	return has_signature()


func reset_attack_cycle() -> void:
	clear_attack_runtime()
	_attack_cooldown_remaining = (
		definition.initial_attack_delay
		if definition != null
		else 0.0
	)
	_next_pattern_index = 0
	_radial_volley_count = 0
	_targeted_blast_count = 0
	_signature_count = 0
	queue_redraw()


func clear_attack_runtime() -> void:
	_active_pattern_id = &""
	_telegraph_remaining = 0.0
	_telegraph_duration = 0.0
	_targeted_position = Vector2.ZERO
	var projectiles_to_clear := _active_projectiles.duplicate()
	_active_projectiles.clear()
	for projectile in projectiles_to_clear:
		if is_instance_valid(projectile) and not projectile.is_queued_for_deletion():
			projectile.expire()
	clear_signature_runtime()
	queue_redraw()


## Rimuove ogni residuo della Signature: aree, scie, cloni, telegraph e stato
## di movimento. Viene invocata dal cleanup Boss, dal restart e dall'uscita
## dall'albero, cosi' la morte del Boss non lascia mai nulla in arena.
func clear_signature_runtime() -> void:
	_announced_signature = null
	_signature_corridor_end = Vector2.INF
	_signature_motion = SignatureMotion.NONE
	_signature_motion_remaining = 0.0
	_signature_motion_speed = 0.0
	_signature_motion_turn_rate = 0.0
	var areas_to_clear := _active_signature_areas.duplicate()
	_active_signature_areas.clear()
	for area in areas_to_clear:
		if is_instance_valid(area) and not area.is_queued_for_deletion():
			area.queue_free()
	if is_instance_valid(_active_decoy):
		if is_instance_valid(_targeting_system):
			_targeting_system.unregister_target(_active_decoy)
		_active_decoy.expire()
	_active_decoy = null
	if is_instance_valid(_thunder_aura):
		_thunder_aura.set_tier(ThunderChargeAura.TIER_LOW)
	_thunder_charge_tier = ThunderChargeAura.TIER_LOW


func get_definition() -> BossDefinition:
	return definition


func get_signature_definition() -> BossSignatureDefinition:
	return _signature


func has_signature() -> bool:
	return _signature != null and _signature.is_valid()


## Signature effettivamente annunciata dal telegraph in corso. Per Evil Lollo
## e' la copia estratta, per tutti gli altri coincide con la propria.
func get_announced_signature() -> BossSignatureDefinition:
	return _announced_signature


func get_signature_count() -> int:
	return _signature_count


func get_active_signature_areas() -> Array[BossSignatureArea]:
	_prune_signature_areas()
	return _active_signature_areas.duplicate()


func get_active_signature_area_count() -> int:
	_prune_signature_areas()
	return _active_signature_areas.size()


func get_active_decoy() -> BossDecoy:
	return _active_decoy if is_instance_valid(_active_decoy) else null


func is_signature_motion_active() -> bool:
	return _signature_motion != SignatureMotion.NONE and _signature_motion_remaining > 0.0


func get_signature_corridor_end() -> Vector2:
	return _signature_corridor_end


func get_thunder_charge_tier() -> int:
	return _thunder_charge_tier


func get_thunder_charge_aura() -> ThunderChargeAura:
	return _thunder_aura if is_instance_valid(_thunder_aura) else null


func has_visual_sprite() -> bool:
	return is_instance_valid(_boss_sprite)


func get_boss_visual_texture() -> Texture2D:
	return _boss_sprite.texture if is_instance_valid(_boss_sprite) else null


func get_boss_visual_modulate() -> Color:
	return _boss_sprite.self_modulate if is_instance_valid(_boss_sprite) else Color.WHITE


func get_active_pattern_id() -> StringName:
	return _active_pattern_id


func is_telegraph_active() -> bool:
	return not _active_pattern_id.is_empty() and _telegraph_remaining > 0.0


func get_telegraph_remaining() -> float:
	return _telegraph_remaining


func get_targeted_position() -> Vector2:
	return _targeted_position


func get_radial_volley_count() -> int:
	return _radial_volley_count


func get_targeted_blast_count() -> int:
	return _targeted_blast_count


func get_active_projectile_count() -> int:
	_prune_projectiles()
	return _active_projectiles.size()


func get_attack_cooldown_remaining() -> float:
	return _attack_cooldown_remaining


func _sync_boss_visual() -> void:
	if not is_instance_valid(_boss_sprite) or definition == null:
		return
	_boss_sprite.texture = definition.get_visual_texture()
	_boss_sprite.self_modulate = definition.sprite_modulate
	var texture_size := (
		_boss_sprite.texture.get_size()
		if _boss_sprite.texture != null
		else Vector2.ZERO
	)
	if texture_size.x > 0.0 and texture_size.y > 0.0:
		var target_diameter := collision_radius * 1.9
		var scale_factor := target_diameter / maxf(texture_size.x, texture_size.y)
		_boss_sprite.scale = Vector2.ONE * clampf(scale_factor, 1.0, 4.0)
	_boss_sprite.visible = _boss_sprite.texture != null
	_sync_boss_facing()


func _sync_boss_facing() -> void:
	if not is_instance_valid(_boss_sprite):
		return
	var target := get_target()
	if target == null:
		return
	var offset_to_target := target.global_position - global_position
	if not is_zero_approx(offset_to_target.x):
		_boss_sprite.flip_h = offset_to_target.x < 0.0


## L'aura orbitante di PS-004 e' puramente presentazionale e non conosce il
## Player: qui viene riusata tale e quale come tell della carica del Tuono di
## Evil Zat, senza duplicarne il disegno.
func _sync_thunder_aura() -> void:
	if not is_instance_valid(_thunder_aura):
		return
	var uses_thunder := (
		has_signature()
		and _signature.effect_id == BossSignatureRegistry.THUNDER_STORM
	)
	_thunder_aura.set_presented(uses_thunder)
	if not uses_thunder:
		_thunder_aura.set_rotation_speed(0.0)
		_thunder_aura.set_tier(ThunderChargeAura.TIER_LOW)
		_thunder_charge_tier = ThunderChargeAura.TIER_LOW
		return
	_thunder_aura.position = Vector2(0.0, -collision_radius - 26.0)
	_refresh_thunder_charge_tier()


func _refresh_thunder_charge_tier() -> void:
	var health_component := get_health_component()
	if health_component == null or health_component.health_max <= 0.0:
		return
	var missing_ratio := clampf(
		1.0 - health_component.health_current / health_component.health_max,
		0.0,
		1.0
	)
	var medium_threshold := _signature.get_effect_float(
		&"medium_tier_threshold",
		THUNDER_MEDIUM_THRESHOLD,
		0.0
	)
	var high_threshold := _signature.get_effect_float(
		&"high_tier_threshold",
		THUNDER_HIGH_THRESHOLD,
		0.0
	)
	var tier := ThunderChargeAura.TIER_LOW
	if missing_ratio >= high_threshold:
		tier = ThunderChargeAura.TIER_HIGH
	elif missing_ratio >= medium_threshold:
		tier = ThunderChargeAura.TIER_MEDIUM
	_thunder_charge_tier = tier
	if not is_instance_valid(_thunder_aura):
		return
	_thunder_aura.set_tier(tier)
	_thunder_aura.set_rotation_speed(
		_signature.get_effect_float(
			&"aura_rotation_speed",
			THUNDER_AURA_ROTATION_SPEED,
			0.0
		) * float(tier + 1)
	)


func _advance_thunder_aura(delta: float) -> void:
	if not is_instance_valid(_thunder_aura) or not _thunder_aura.is_presented():
		return
	var run_controller := get_run_controller()
	if run_controller == null or not run_controller.is_running():
		return
	_refresh_thunder_charge_tier()
	_thunder_aura.advance(delta)


func _get_thunder_damage_scale() -> float:
	match _thunder_charge_tier:
		ThunderChargeAura.TIER_HIGH:
			return _announced_signature.get_effect_float(&"high_tier_multiplier", 3.0, 0.0)
		ThunderChargeAura.TIER_MEDIUM:
			return _announced_signature.get_effect_float(&"medium_tier_multiplier", 2.0, 0.0)
	return 1.0


func _advance_attack_cycle(delta: float) -> void:
	var run_controller := get_run_controller()
	if (
		definition == null
		or not definition.is_valid()
		or not is_alive()
		or run_controller == null
		or not run_controller.is_running()
	):
		return

	var safe_delta := maxf(delta, 0.0) if is_finite(delta) else 0.0
	if is_telegraph_active():
		_telegraph_remaining = maxf(_telegraph_remaining - safe_delta, 0.0)
		queue_redraw()
		if _telegraph_remaining <= 0.0:
			_execute_active_pattern()
		return

	_attack_cooldown_remaining = maxf(
		_attack_cooldown_remaining - safe_delta,
		0.0
	)
	# Un nuovo telegraph non puo' partire mentre il Boss e' ancora in
	# Powerslide o in Piroetta: due preavvisi sovrapposti renderebbero
	# illeggibile quello in corso.
	if _attack_cooldown_remaining <= 0.0 and not is_signature_motion_active():
		_begin_next_pattern()


## Rotazione dei pattern. Con una Signature disponibile diventa un ciclo di
## tre: entrambi i pattern Boss comuni restano nella rotazione.
func _resolve_next_pattern_id() -> StringName:
	if not has_signature():
		return RADIAL_VOLLEY if _next_pattern_index % 2 == 0 else TARGETED_BLAST
	match _next_pattern_index % 3:
		0:
			return RADIAL_VOLLEY
		1:
			return TARGETED_BLAST
	return SIGNATURE


func _begin_next_pattern() -> void:
	if definition == null or not is_alive():
		return
	_active_pattern_id = _resolve_next_pattern_id()
	match _active_pattern_id:
		RADIAL_VOLLEY:
			_telegraph_duration = definition.radial_telegraph_duration
		TARGETED_BLAST:
			_telegraph_duration = definition.targeted_telegraph_duration
			var target := get_target()
			_targeted_position = (
				target.global_position
				if is_instance_valid(target)
				else global_position
			)
		SIGNATURE:
			if not _begin_signature_telegraph():
				_active_pattern_id = RADIAL_VOLLEY
				_telegraph_duration = definition.radial_telegraph_duration
	_telegraph_remaining = _telegraph_duration
	attack_telegraphed.emit(self, _active_pattern_id, _telegraph_duration)
	queue_redraw()


## Estrae la Signature che verra' eseguita e ne blocca origine e traiettoria.
## Da qui in poi il telegraph mostra esattamente cio' che accadra': per Evil
## Lollo, la forma della Signature copiata.
func _begin_signature_telegraph() -> bool:
	_announced_signature = _resolve_announced_signature()
	if _announced_signature == null:
		return false
	_telegraph_duration = _announced_signature.telegraph_duration
	var target := get_target()
	var target_position := (
		target.global_position
		if is_instance_valid(target)
		else global_position
	)
	var offset := target_position - global_position
	_signature_direction = (
		offset.normalized()
		if not offset.is_zero_approx()
		else Vector2.RIGHT
	)
	_signature_origin = global_position
	_signature_corridor_end = Vector2.INF
	match _announced_signature.effect_id:
		BossSignatureRegistry.THERMAL_SHOCK:
			# L'area viene fissata sul Player adesso: da qui in poi allontanarsi
			# e' sempre sufficiente per non trovarsi nella detonazione.
			_signature_origin = target_position
	signature_announced.emit(self, _announced_signature)
	return true


## Evil Lollo estrae una Signature altrui con RNG seedato: stesso seed, stessa
## soglia Boss e stesso numero d'uso producono sempre la stessa copia. Cosplay
## Casuale non e' fra i candidati, quindi la ricorsione e' impossibile.
func _resolve_announced_signature() -> BossSignatureDefinition:
	if not has_signature():
		return null
	if _signature.effect_id != BossSignatureRegistry.RANDOM_COSPLAY:
		return _signature
	var run_controller := get_run_controller()
	if run_controller == null:
		return null
	return BossSignatureRegistry.select_copy(
		_copy_candidates,
		run_controller.get_seed(),
		_schedule_index,
		_signature_count
	)


func _execute_active_pattern() -> void:
	var executed_pattern := _active_pattern_id
	var affected_count := 0
	match executed_pattern:
		RADIAL_VOLLEY:
			affected_count = _spawn_radial_volley()
			_radial_volley_count += 1
		TARGETED_BLAST:
			affected_count = _execute_targeted_blast()
			_targeted_blast_count += 1
		SIGNATURE:
			affected_count = _execute_signature()
			_signature_count += 1
		_:
			return

	_active_pattern_id = &""
	_telegraph_remaining = 0.0
	_telegraph_duration = 0.0
	_attack_cooldown_remaining = definition.pattern_interval
	if executed_pattern == SIGNATURE and _announced_signature != null:
		_attack_cooldown_remaining += _announced_signature.recovery_seconds
	_next_pattern_index += 1
	attack_executed.emit(self, executed_pattern, affected_count)
	queue_redraw()


func _execute_signature() -> int:
	if _announced_signature == null:
		return 0
	var spawned := 0
	if BossSignatureRegistry.spawns_decoy(_announced_signature.effect_id):
		spawned += 1 if _spawn_signature_decoy() != null else 0
	var area_mode := BossSignatureRegistry.get_area_mode(_announced_signature.effect_id)
	if area_mode != BossSignatureRegistry.AreaMode.NONE:
		spawned += 1 if _spawn_signature_area(area_mode) != null else 0
	_begin_signature_motion()
	return spawned


func _spawn_signature_area(mode: BossSignatureRegistry.AreaMode) -> BossSignatureArea:
	var run_controller := get_run_controller()
	var player := get_target() as Player
	if (
		run_controller == null
		or player == null
		or not is_instance_valid(_projectile_parent)
		or not _projectile_parent.is_inside_tree()
	):
		return null
	var origin := global_position
	var source: Node2D = null
	var corridor_end := Vector2.INF
	var damage_scale := 1.0
	match mode:
		BossSignatureRegistry.AreaMode.TWO_PHASE_BURST:
			origin = _signature_origin
		BossSignatureRegistry.AreaMode.TRAIL_CORRIDOR:
			corridor_end = global_position + _signature_direction * _get_dash_distance()
			_signature_corridor_end = corridor_end
		BossSignatureRegistry.AreaMode.FOLLOWING_CONTACT:
			source = self
		BossSignatureRegistry.AreaMode.FOLLOWING_SLOW_ABSORB:
			source = self
		BossSignatureRegistry.AreaMode.INSTANT_BURST:
			damage_scale = _get_thunder_damage_scale()
	# PS-126: la carica del Tuono (thunder_damage_scale) e la pressione di
	# ricorrenza sono due leve indipendenti che si compongono, non si
	# sostituiscono: entrambe finiscono nello stesso _damage_scale che
	# BossSignatureArea applica gia' in ogni modalita'.
	damage_scale *= pressure_multiplier

	var area := BossSignatureArea.new()
	area.name = "BossSignatureArea_%s" % _announced_signature.id
	_projectile_parent.add_child(area)
	_signature_serial += 1
	if not area.initialize(
		mode,
		_announced_signature,
		origin,
		source,
		player,
		run_controller,
		StringName("boss_signature_%s_%d" % [_announced_signature.id, _signature_serial]),
		damage_scale,
		corridor_end
	):
		area.queue_free()
		return null
	_active_signature_areas.append(area)
	area.tree_exiting.connect(
		_on_signature_area_tree_exiting.bind(area),
		CONNECT_ONE_SHOT
	)
	return area


func _spawn_signature_decoy() -> BossDecoy:
	var run_controller := get_run_controller()
	var player := get_target() as Player
	var parent := _enemy_parent if is_instance_valid(_enemy_parent) else _projectile_parent
	if (
		decoy_scene == null
		or run_controller == null
		or player == null
		or not is_instance_valid(parent)
		or not parent.is_inside_tree()
		or is_instance_valid(_active_decoy)
	):
		return null
	var instance := decoy_scene.instantiate()
	if not instance is BossDecoy:
		if is_instance_valid(instance):
			instance.free()
		push_error("FirstBoss: decoy_scene deve avere BossDecoy come nodo root.")
		return null

	var decoy := instance as BossDecoy
	parent.add_child(decoy)
	# Il clone si mette fra Boss e Player: l'auto-targeting sceglie il bersaglio
	# piu' vicino, quindi lo preferisce senza che nulla tocchi i comandi.
	decoy.global_position = global_position + _signature_direction * _announced_signature.get_effect_float(
		&"clone_offset",
		120.0,
		BossSignatureDefinition.MINIMUM_POSITIVE_VALUE
	)
	if not decoy.initialize(
		get_boss_visual_texture(),
		_announced_signature.get_effect_float(
			&"clone_health",
			240.0,
			BossSignatureDefinition.MINIMUM_POSITIVE_VALUE
		),
		_announced_signature.get_effect_float(
			&"clone_radius",
			collision_radius * 0.74,
			1.0
		),
		_announced_signature.duration_seconds,
		run_controller
	):
		decoy.queue_free()
		return null
	_active_decoy = decoy
	decoy.tree_exiting.connect(_on_decoy_tree_exiting.bind(decoy), CONNECT_ONE_SHOT)
	if is_instance_valid(_targeting_system):
		_targeting_system.register_target(decoy)
	return decoy


func _get_dash_distance() -> float:
	if _announced_signature == null:
		return 0.0
	return _announced_signature.get_effect_float(
		&"dash_distance",
		320.0,
		BossSignatureDefinition.MINIMUM_POSITIVE_VALUE
	)


func _begin_signature_motion() -> void:
	if _announced_signature == null:
		return
	match _announced_signature.effect_id:
		BossSignatureRegistry.POWERSLIDE:
			var dash_speed := _announced_signature.get_effect_float(
				&"dash_speed",
				620.0,
				BossSignatureDefinition.MINIMUM_POSITIVE_VALUE
			)
			var dash_distance := _get_dash_distance()
			_signature_motion = SignatureMotion.DASH
			_signature_motion_speed = dash_speed
			_signature_motion_remaining = dash_distance / dash_speed
			_signature_motion_turn_rate = 0.0
		BossSignatureRegistry.GRAND_SPIN:
			_signature_motion = SignatureMotion.SPIN
			_signature_motion_speed = _announced_signature.get_effect_float(
				&"chase_speed",
				110.0,
				0.0
			)
			_signature_motion_turn_rate = _announced_signature.get_effect_float(
				&"turn_rate",
				1.1,
				0.0
			)
			_signature_motion_remaining = _announced_signature.duration_seconds


## Movimento imposto dalla Signature. Restituisce `true` quando ha gestito il
## frame, cosi' l'inseguimento ordinario di `BaseEnemy` resta sospeso.
func _advance_signature_motion(delta: float) -> bool:
	if not is_signature_motion_active():
		return false
	var run_controller := get_run_controller()
	if run_controller == null or not run_controller.is_running() or not is_alive():
		velocity = Vector2.ZERO
		return true
	var safe_delta := maxf(delta, 0.0) if is_finite(delta) else 0.0
	if _signature_motion == SignatureMotion.SPIN:
		_steer_signature_direction(safe_delta)
	velocity = _signature_direction * _signature_motion_speed
	move_and_slide()
	_signature_motion_remaining = maxf(_signature_motion_remaining - safe_delta, 0.0)
	if _signature_motion_remaining <= 0.0:
		_signature_motion = SignatureMotion.NONE
		_signature_motion_speed = 0.0
		velocity = Vector2.ZERO
	queue_redraw()
	return true


## La Piroetta non puo' cambiare direzione all'istante: la rotazione verso il
## Player e' limitata a `turn_rate` radianti al secondo, cosi' mantenere le
## distanze resta una scelta di posizionamento e non un riflesso.
func _steer_signature_direction(delta: float) -> void:
	var target := get_target()
	if not is_instance_valid(target) or _signature_motion_turn_rate <= 0.0:
		return
	var offset := target.global_position - global_position
	if offset.is_zero_approx():
		return
	var desired_angle := offset.angle()
	var current_angle := _signature_direction.angle()
	var angle_delta := clampf(
		angle_difference(current_angle, desired_angle),
		-_signature_motion_turn_rate * delta,
		_signature_motion_turn_rate * delta
	)
	_signature_direction = Vector2.RIGHT.rotated(current_angle + angle_delta)


func _spawn_radial_volley() -> int:
	if (
		projectile_scene == null
		or not is_instance_valid(_projectile_parent)
		or not _projectile_parent.is_inside_tree()
	):
		return 0
	var run_controller := get_run_controller()
	var player := get_target() as Player
	if run_controller == null or player == null:
		return 0

	var spawned_count := 0
	for projectile_index in definition.radial_projectile_count:
		var instance := projectile_scene.instantiate()
		if not instance is BossProjectile:
			if is_instance_valid(instance):
				instance.free()
			continue
		var projectile := instance as BossProjectile
		_projectile_parent.add_child(projectile)
		projectile.global_position = global_position
		var angle := TAU * float(projectile_index) / float(definition.radial_projectile_count)
		if not projectile.initialize(
			Vector2.RIGHT.rotated(angle),
			definition.radial_projectile_damage * pressure_multiplier,
			definition.radial_projectile_speed,
			definition.radial_projectile_lifetime,
			definition.radial_projectile_radius,
			run_controller,
			player
		):
			projectile.queue_free()
			continue
		_active_projectiles.append(projectile)
		projectile.tree_exiting.connect(
			_on_projectile_tree_exiting.bind(projectile),
			CONNECT_ONE_SHOT
		)
		spawned_count += 1
	return spawned_count


func _execute_targeted_blast() -> int:
	var run_controller := get_run_controller()
	var player := get_target() as Player
	if (
		run_controller == null
		or not run_controller.is_running()
		or player == null
		or not player.is_alive()
	):
		return 0
	var effective_radius := definition.targeted_blast_radius + player.collision_radius
	if player.global_position.distance_squared_to(_targeted_position) > effective_radius * effective_radius:
		return 0
	return 1 if player.take_contact_damage(definition.targeted_blast_damage * pressure_multiplier, _targeted_position) else 0


func _draw_active_telegraph() -> void:
	if not is_telegraph_active() or definition == null:
		return
	var progress := 1.0 - clampf(
		_telegraph_remaining / maxf(_telegraph_duration, BossDefinition.MINIMUM_POSITIVE_VALUE),
		0.0,
		1.0
	)
	var color := definition.telegraph_color
	match _active_pattern_id:
		RADIAL_VOLLEY:
			var ring_radius := collision_radius + 24.0 + progress * 18.0
			draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 48, color, 5.0, true)
			for projectile_index in definition.radial_projectile_count:
				var direction := Vector2.RIGHT.rotated(
					TAU * float(projectile_index) / float(definition.radial_projectile_count)
				)
				draw_line(
					direction * (collision_radius + 8.0),
					direction * (collision_radius + 38.0),
					color,
					3.0,
					true
				)
		TARGETED_BLAST:
			var local_target := _targeted_position - global_position
			draw_circle(
				local_target,
				definition.targeted_blast_radius * progress,
				Color(color, 0.16)
			)
			draw_arc(
				local_target,
				definition.targeted_blast_radius,
				0.0,
				TAU,
				64,
				color,
				5.0,
				true
			)
			var crosshair_radius := definition.targeted_blast_radius * 0.72
			for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
				draw_line(
					local_target + direction * crosshair_radius * 0.62,
					local_target + direction * crosshair_radius,
					Color(1.0, 1.0, 1.0, color.a),
					4.0,
					true
				)
		SIGNATURE:
			_draw_signature_telegraph(progress)


## Il preavviso della Signature disegna la forma esatta che sta per diventare
## pericolosa. Per Evil Lollo e' anche l'annuncio della copia: la sagoma e il
## colore appartengono alla Signature estratta, non a Cosplay Casuale.
func _draw_signature_telegraph(progress: float) -> void:
	if _announced_signature == null:
		return
	var accent := _announced_signature.accent_color
	var radius := _announced_signature.area_radius
	var is_copy := (
		has_signature()
		and _signature.effect_id == BossSignatureRegistry.RANDOM_COSPLAY
	)
	if is_copy:
		draw_arc(
			Vector2.ZERO,
			collision_radius + 16.0 + progress * 10.0,
			0.0,
			TAU,
			48,
			Color(_signature.accent_color, _signature.accent_color.a),
			5.0,
			true
		)
	match BossSignatureRegistry.get_area_mode(_announced_signature.effect_id):
		BossSignatureRegistry.AreaMode.EXPANDING_FRONT, BossSignatureRegistry.AreaMode.INSTANT_BURST:
			draw_arc(Vector2.ZERO, radius, 0.0, TAU, 72, accent, 5.0, true)
			draw_arc(
				Vector2.ZERO,
				maxf(radius * progress, 1.0),
				0.0,
				TAU,
				72,
				Color(1.0, 1.0, 1.0, accent.a * 0.85),
				4.0,
				true
			)
		BossSignatureRegistry.AreaMode.TRAIL_CORRIDOR:
			var local_end := _signature_direction * _get_dash_distance()
			draw_line(Vector2.ZERO, local_end, Color(accent, accent.a * 0.35), radius * 2.0, true)
			draw_line(Vector2.ZERO, local_end, accent, 5.0, true)
			draw_line(
				Vector2.ZERO,
				local_end * progress,
				Color(1.0, 1.0, 1.0, accent.a),
				3.0,
				true
			)
			draw_arc(local_end, radius, 0.0, TAU, 48, accent, 4.0, true)
		BossSignatureRegistry.AreaMode.TWO_PHASE_BURST:
			var local_origin := _signature_origin - global_position
			draw_circle(local_origin, radius, Color(accent, accent.a * 0.2))
			draw_arc(local_origin, radius, 0.0, TAU, 64, accent, 5.0, true)
			draw_arc(
				local_origin,
				maxf(radius * progress, 1.0),
				0.0,
				TAU,
				64,
				Color(1.0, 1.0, 1.0, accent.a),
				4.0,
				true
			)
		BossSignatureRegistry.AreaMode.FOLLOWING_CONTACT, BossSignatureRegistry.AreaMode.FOLLOWING_SLOW_ABSORB:
			draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, accent, 5.0, true)
			for blade_index in 6:
				var direction := Vector2.RIGHT.rotated(
					progress * TAU + TAU * float(blade_index) / 6.0
				)
				draw_line(
					direction * radius * 0.6,
					direction * radius,
					Color(1.0, 1.0, 1.0, accent.a),
					3.0,
					true
				)
		_:
			draw_arc(
				Vector2.ZERO,
				collision_radius + 30.0,
				0.0,
				TAU,
				48,
				accent,
				5.0,
				true
			)


## Durante Powerslide e Piroetta il Boss stesso e' l'area pericolosa: qui la si
## rende esplicita anche quando l'area persistente non copre ancora la sagoma.
func _draw_signature_motion() -> void:
	if not is_signature_motion_active() or _announced_signature == null:
		return
	var accent := _announced_signature.accent_color
	draw_arc(Vector2.ZERO, collision_radius + 10.0, 0.0, TAU, 48, accent, 5.0, true)
	draw_line(
		Vector2.ZERO,
		_signature_direction * (collision_radius + 46.0),
		Color(1.0, 1.0, 1.0, accent.a),
		4.0,
		true
	)


func _prune_projectiles() -> void:
	for index in range(_active_projectiles.size() - 1, -1, -1):
		if not is_instance_valid(_active_projectiles[index]):
			_active_projectiles.remove_at(index)


func _prune_signature_areas() -> void:
	for index in range(_active_signature_areas.size() - 1, -1, -1):
		if not is_instance_valid(_active_signature_areas[index]):
			_active_signature_areas.remove_at(index)


func _on_projectile_tree_exiting(projectile: BossProjectile) -> void:
	_active_projectiles.erase(projectile)


func _on_signature_area_tree_exiting(area: BossSignatureArea) -> void:
	_active_signature_areas.erase(area)


func _on_decoy_tree_exiting(decoy: BossDecoy) -> void:
	if is_instance_valid(_targeting_system):
		_targeting_system.unregister_target(decoy)
	if _active_decoy == decoy:
		_active_decoy = null
