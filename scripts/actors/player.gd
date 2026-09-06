class_name Player
extends CharacterBody2D

signal health_changed(player: Player, health_current: float, health_max: float)
signal damaged(player: Player, amount: float, health_current: float)
signal died(player: Player)
signal friend_changed(definition: FriendDefinition)
signal facing_direction_changed(direction: Vector2)
## PS-006: le Signature Evil rallentano il Player dall'esterno; la HUD e i
## test leggono il risultato senza toccare i moltiplicatori di upgrade.
signal external_speed_modifiers_changed(player: Player, effective_multiplier: float)

@export_group("Content")
@export var friend_definition: FriendDefinition

@export_group("Movement")
@export_range(0.0, 2000.0, 1.0) var move_speed: float = 360.0

@export_range(1.0, 1024.0, 1.0, "or_greater") var pickup_radius := 160.0:
	set(value):
		pickup_radius = maxf(value, 1.0) if is_finite(value) else 1.0

@export_range(1.0, 128.0, 0.5) var collision_radius: float = 24.0:
	set(value):
		collision_radius = maxf(value, 1.0)
		if is_node_ready():
			_sync_collision_radius()

@export_group("Visual")
@export_range(1.0, 2.0, 0.05) var visual_scale_multiplier := 1.25:
	set(value):
		visual_scale_multiplier = (
			clampf(value, 1.0, 2.0)
			if is_finite(value)
			else 1.0
		)
		if is_node_ready():
			_update_character_feedback()

@export_group("Combat Feedback")
@export_range(0.0, 1.0, 0.005) var damage_flash_duration := PresentationTimings.PLAYER_DAMAGE_FLASH_SECONDS
@export_range(0.0, 1.0, 0.01) var damage_reaction_duration := PresentationTimings.PLAYER_DAMAGE_REACTION_SECONDS
@export_range(0.0, 0.5, 0.01) var damage_squash_strength := 0.13

const DEFAULT_FACING_DIRECTION := Vector2.RIGHT
const HORIZONTAL_FACING_EPSILON := 0.001

## Slancio di Magno (B45): sale mentre la direzione resta entro questa soglia
## angolare (coseno) dal frame precedente, decade altrimenti. Tracciato per
## chiunque a costo trascurabile; solo la passiva di Magno lo rende visibile
## o rilevante per il gameplay.
const MOMENTUM_DIRECTION_COS_THRESHOLD := 0.85
const MOMENTUM_RAMP_SECONDS := 1.4
const MOMENTUM_DECAY_SECONDS := 0.5
const MOMENTUM_TRAIL_MAX_POINTS := 14
const MOMENTUM_TRAIL_SAMPLE_INTERVAL := 0.03
const MOMENTUM_TRAIL_MINIMUM_RATIO := 0.02
const MOMENTUM_TRAIL_COLOR := Color(1.0, 0.78, 0.32, 1.0)

var movement_input := Vector2.ZERO:
	set(value):
		movement_input = value.limit_length(1.0)
		_update_facing_from_movement(movement_input)
		if is_node_ready():
			_sync_character_animation_state()

var _arena_layout: ArenaLayout
var _world_bounds := Rect2()
var _run_controller: RunController
var _damage_flash_remaining := 0.0
var _damage_reaction_remaining := 0.0
var _death_handled := false
var _base_health_max := 100.0
var _base_move_speed := 360.0
var _base_pickup_radius := 160.0
var _character_move_speed_multiplier := 1.0
var _character_pickup_radius_multiplier := 1.0
var _character_health_max_multiplier := 1.0
var _move_speed_multiplier := 1.0
var _pickup_radius_multiplier := 1.0
var _health_max_multiplier := 1.0
var _damage_taken_multiplier := 1.0
## Due Dita e Parto di Alea (PS-105): devia per un istante la direzione
## effettiva di movimento rispetto a quella voluta (`movement_input`), senza
## alterare facing/animazione. Zero fuori da Brilla e per chiunque altro.
var _movement_drift_rotation_radians := 0.0
var _passive_controller: FriendPassiveController
var _character_base_scale := Vector2.ONE
var _facing_direction := DEFAULT_FACING_DIRECTION
var _character_idle_texture: Texture2D
var _character_walk_frames: Array[Texture2D] = []
var _character_walk_frame_index := 0
var _character_walk_elapsed := 0.0
var _character_is_walking := false
var _last_movement_direction := DEFAULT_FACING_DIRECTION
var _momentum_ratio := 0.0
var _momentum_reference_direction := Vector2.ZERO
var _momentum_trail_enabled := false
var _momentum_trail_points: PackedVector2Array = PackedVector2Array()
var _momentum_trail_sample_elapsed := 0.0
var _thunder_charge_active := false
var _external_speed_modifiers: Dictionary = {}
var _external_impulse_velocity := Vector2.ZERO
var _external_impulse_remaining := 0.0

@onready var _collision_shape: CollisionShape2D = %CollisionShape
@onready var _health_component: HealthComponent = %HealthComponent
@onready var _weapon_controller: WeaponController = %WeaponController
@onready var _ability_controller: AbilityController = %AbilityController
@onready var _character_sprite: Sprite2D = %CharacterSprite
@onready var _passive_state_particles: PassiveStateParticles = %PassiveStateParticles
@onready var _thunder_charge_aura: ThunderChargeAura = %ThunderChargeAura


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	_make_collision_shape_unique()
	_sync_collision_radius()
	_base_health_max = _health_component.health_max
	_base_move_speed = move_speed
	_base_pickup_radius = pickup_radius
	_character_base_scale = _character_sprite.scale
	_connect_health_component()
	_connect_arena_layout()
	_refresh_character_visual()
	_clamp_to_playfield()


func _exit_tree() -> void:
	_disconnect_run_controller()
	_disconnect_health_component()
	_disconnect_arena_layout()


func _physics_process(delta: float) -> void:
	if is_instance_valid(_run_controller) and not _run_controller.is_running():
		velocity = Vector2.ZERO
		return
	if not is_alive():
		velocity = Vector2.ZERO
		return

	var safe_delta := maxf(delta, 0.0) if is_finite(delta) else 0.0
	_damage_flash_remaining = maxf(_damage_flash_remaining - safe_delta, 0.0)
	_damage_reaction_remaining = maxf(
		_damage_reaction_remaining - safe_delta,
		0.0
	)
	_health_component.advance_invulnerability(safe_delta)
	if _external_impulse_remaining > 0.0:
		velocity = _external_impulse_velocity
		_external_impulse_remaining = maxf(
			_external_impulse_remaining - safe_delta,
			0.0
		)
		if _external_impulse_remaining <= 0.0:
			_external_impulse_velocity = Vector2.ZERO
	else:
		velocity = movement_input.rotated(_movement_drift_rotation_radians) * move_speed
	move_and_slide()
	_clamp_to_playfield()
	_advance_character_animation(safe_delta)
	_advance_momentum(safe_delta)
	_update_character_feedback()


func set_movement_input(value: Vector2) -> void:
	movement_input = value


func clear_movement_input() -> void:
	movement_input = Vector2.ZERO
	velocity = Vector2.ZERO


## Character-agnostic come `set_momentum_trail_enabled()`: e' la passiva
## equipaggiata a deciderlo (solo Alea in Brilla, PS-105), il Player resta
## agnostico rispetto a quale personaggio sia attivo. Non tocca
## `movement_input` ne' il facing: solo la direzione effettiva di
## `_physics_process()`.
func set_movement_drift_rotation(radians: float) -> void:
	_movement_drift_rotation_radians = radians if is_finite(radians) else 0.0


func get_movement_drift_rotation() -> float:
	return _movement_drift_rotation_radians


func get_facing_direction() -> Vector2:
	return _facing_direction


func get_last_movement_direction() -> Vector2:
	return _last_movement_direction


## Slancio 0..1 accumulato muovendosi in linea retta (B45/Magno). Letto a
## lancio da chi copia l'Onda d'Urto Tellurica (Cosplay incluso), dato che
## `source` e' sempre il Player vivo al momento dell'esecuzione dell'abilita'.
func get_momentum_ratio() -> float:
	return _momentum_ratio


## Mostra/nasconde la scia procedurale dello slancio: e' la passiva
## equipaggiata a deciderlo (solo Magno), il Player resta agnostico rispetto
## a quale personaggio sia attivo.
func set_momentum_trail_enabled(value: bool) -> void:
	if _momentum_trail_enabled == value:
		return
	_momentum_trail_enabled = value
	if not value:
		_momentum_trail_points.clear()
	queue_redraw()


func is_character_walking() -> bool:
	return _character_is_walking


func get_character_walk_frame_index() -> int:
	return _character_walk_frame_index


func get_character_texture() -> Texture2D:
	return _character_sprite.texture if is_instance_valid(_character_sprite) else null


func is_character_flipped_horizontally() -> bool:
	return _character_sprite.flip_h if is_instance_valid(_character_sprite) else false


## Esposto per gli smoke: verifica che il tell di stato non ridipinga lo sprite
## (PS-001). Fuori dal lampeggio da danno deve restare `Color.WHITE`.
func get_character_self_modulate() -> Color:
	return (
		_character_sprite.self_modulate
		if is_instance_valid(_character_sprite)
		else Color.WHITE
	)


func get_character_visual_offset() -> Vector2:
	return _character_sprite.position if is_instance_valid(_character_sprite) else Vector2.ZERO


func get_character_visual_rotation() -> float:
	return _character_sprite.rotation if is_instance_valid(_character_sprite) else 0.0


func get_character_visual_scale() -> Vector2:
	return _character_sprite.scale if is_instance_valid(_character_sprite) else Vector2.ONE


func get_character_base_scale() -> Vector2:
	return _character_base_scale


func get_friend_definition() -> FriendDefinition:
	return friend_definition


func set_friend_definition(definition: FriendDefinition) -> bool:
	if definition == null or not definition.is_valid():
		return false
	friend_definition = definition
	_refresh_character_visual()
	friend_changed.emit(friend_definition)
	return true


func set_passive_controller(controller: FriendPassiveController) -> void:
	_passive_controller = controller


func get_passive_controller() -> FriendPassiveController:
	return _passive_controller if is_instance_valid(_passive_controller) else null


## `source_position` (mondo) e' opzionale: alcune passive (Sesto Senso Equino
## di Bea) la usano per calcolare una direzione di fuga dalla minaccia.
## `Vector2.INF` (default) segnala "fonte sconosciuta" ai chiamanti che non
## la conoscono ancora.
func take_contact_damage(amount: float, source_position: Vector2 = Vector2.INF) -> bool:
	if (
		not is_instance_valid(_run_controller)
		or not _run_controller.is_running()
		or not is_instance_valid(_health_component)
		or _death_handled
	):
		return false
	var resolved_amount := amount
	if is_instance_valid(_passive_controller):
		resolved_amount = _passive_controller.resolve_incoming_damage(amount, source_position)
	resolved_amount *= _damage_taken_multiplier
	if resolved_amount <= 0.0:
		return false
	return _health_component.take_damage(resolved_amount)


func reset_for_run() -> void:
	_death_handled = false
	clear_external_speed_modifiers()
	clear_external_impulse()
	_damage_flash_remaining = 0.0
	_damage_reaction_remaining = 0.0
	reset_upgrade_stat_multipliers()
	clear_movement_input()
	_movement_drift_rotation_radians = 0.0
	_set_facing_direction(DEFAULT_FACING_DIRECTION)
	_last_movement_direction = DEFAULT_FACING_DIRECTION
	_momentum_ratio = 0.0
	_momentum_reference_direction = Vector2.ZERO
	# PS-041: svuotare l'array non basta. CanvasItem non si ridisegna da solo
	# quando i dati cambiano: senza questa richiesta esplicita, l'ultimo
	# frame disegnato dalla run precedente resta a schermo finche'
	# _advance_momentum_trail() non ridisegna al primo tick utile.
	if not _momentum_trail_points.is_empty():
		_momentum_trail_points.clear()
		queue_redraw()
	_momentum_trail_sample_elapsed = 0.0
	if is_instance_valid(_health_component):
		_health_component.set_health_max(get_base_health_max())
		_health_component.reset_to_max()
	_update_character_feedback()


func set_arena_layout(value: ArenaLayout) -> void:
	if value == _arena_layout:
		return

	_disconnect_arena_layout()
	_arena_layout = value
	_connect_arena_layout()
	_clamp_to_playfield()


func get_arena_layout() -> ArenaLayout:
	return _arena_layout


## Confinamento opzionale in un'arena piu' grande dello schermo (B38). Finche'
## non viene assegnato un rettangolo con area, il Player resta confinato nel
## playfield di `ArenaLayout` come prima di B38.
func set_world_bounds(value: Rect2) -> void:
	_world_bounds = value
	_clamp_to_playfield()


func get_world_bounds() -> Rect2:
	return _world_bounds


func set_run_controller(value: RunController) -> void:
	if value == _run_controller:
		return
	_disconnect_run_controller()
	_run_controller = value
	_connect_run_controller()
	_sync_passive_state_tell_visibility()
	_sync_thunder_charge_aura_visibility()


func get_run_controller() -> RunController:
	return _run_controller if is_instance_valid(_run_controller) else null


func get_health_component() -> HealthComponent:
	return _health_component if is_instance_valid(_health_component) else null


func get_weapon_controller() -> WeaponController:
	return _weapon_controller


func get_ability_controller() -> AbilityController:
	return _ability_controller


func get_pickup_radius() -> float:
	return pickup_radius


func set_upgrade_stat_multipliers(
	move_speed_multiplier: float,
	pickup_radius_multiplier: float,
	health_max_multiplier: float = 1.0,
	preserve_health_ratio: bool = true,
	damage_taken_multiplier: float = 1.0
) -> bool:
	if (
		not is_finite(move_speed_multiplier)
		or move_speed_multiplier <= 0.0
		or not is_finite(pickup_radius_multiplier)
		or pickup_radius_multiplier <= 0.0
		or not is_finite(health_max_multiplier)
		or health_max_multiplier <= 0.0
		or not is_finite(damage_taken_multiplier)
		or damage_taken_multiplier <= 0.0
	):
		return false

	_move_speed_multiplier = move_speed_multiplier
	_pickup_radius_multiplier = pickup_radius_multiplier
	_health_max_multiplier = health_max_multiplier
	_damage_taken_multiplier = damage_taken_multiplier
	_recalculate_effective_stats(preserve_health_ratio)
	return true


func set_character_stat_multipliers(
	move_speed_multiplier: float,
	pickup_radius_multiplier: float = 1.0,
	health_max_multiplier: float = 1.0
) -> bool:
	if (
		not is_finite(move_speed_multiplier)
		or move_speed_multiplier <= 0.0
		or not is_finite(pickup_radius_multiplier)
		or pickup_radius_multiplier <= 0.0
		or not is_finite(health_max_multiplier)
		or health_max_multiplier <= 0.0
	):
		return false
	_character_move_speed_multiplier = move_speed_multiplier
	_character_pickup_radius_multiplier = pickup_radius_multiplier
	_character_health_max_multiplier = health_max_multiplier
	_recalculate_effective_stats(true)
	return true


## Tell di stato della passiva equipaggiata (B42/B44, ridisegnato da PS-001,
## riportato al particellare da PS-079): rende leggibile in quale fase si
## trova il profilo senza toccare collisioni, statistiche o timing di
## gameplay.
##
## Fino a PS-001 era una tinta piena applicata con `self_modulate` sull'intero
## sprite: moltiplicando ogni pixel ridipingeva il personaggio e ne cancellava
## l'identita' cromatica. PS-001 lo aveva spostato in un contorno attorno alla
## sagoma, bocciato a sua volta perche' rompeva la silhouette pixel-art
## (PS-079): il colore vive ora in un piccolo particellare che si solleva
## sopra la testa, staccato dal corpo per costruzione.
func set_passive_state_tell(value: Color) -> bool:
	if not is_instance_valid(_passive_state_particles):
		return false
	var accepted := _passive_state_particles.set_state_color(value)
	_sync_passive_state_tell_visibility()
	return accepted


func clear_passive_state_tell() -> void:
	if not is_instance_valid(_passive_state_particles):
		return
	_passive_state_particles.clear_state_color()


func get_passive_state_tell_color() -> Color:
	if not is_instance_valid(_passive_state_particles):
		return Color(0.0, 0.0, 0.0, 0.0)
	return _passive_state_particles.get_state_color()


func has_passive_state_tell() -> bool:
	return (
		is_instance_valid(_passive_state_particles)
		and _passive_state_particles.has_state_color()
	)


func is_passive_state_tell_presented() -> bool:
	return (
		is_instance_valid(_passive_state_particles)
		and _passive_state_particles.is_state_presented()
	)


## Osservabilita' per lo smoke PS-079: tiene conto anche del lampeggio da
## invulnerabilita', per verificare che il flash da danno mantenga la
## precedenza sul tell (PS-001) senza dover leggere pixel.
func is_passive_state_tell_effectively_visible() -> bool:
	return (
		is_instance_valid(_passive_state_particles)
		and _passive_state_particles.is_effectively_visible()
	)


## La rotazione/sollevamento delle particelle avanza solo mentre la run e'
## RUNNING (stesso principio di `advance_thunder_charge_aura`): il nodo
## stesso non conosce il RunController.
func advance_passive_state_particles(delta: float) -> void:
	if is_instance_valid(_passive_state_particles):
		_passive_state_particles.advance(delta)


## Osservabilita' per lo smoke PS-079.
func get_passive_state_particles_orbit_angle() -> float:
	return (
		_passive_state_particles.get_orbit_angle()
		if is_instance_valid(_passive_state_particles)
		else 0.0
	)


func _sync_passive_state_tell_visibility() -> void:
	if not is_instance_valid(_passive_state_particles):
		return
	_passive_state_particles.set_state_presented(
		is_instance_valid(_run_controller) and _run_controller.is_running()
	)


## Aura orbitante di Guarigione Ritardata (PS-004): stesso schema del tell di
## stato, ma la fascia (numero/colore/velocita') arriva da
## `FriendPassiveController` invece che da un colore singolo.
func set_thunder_charge_tier(tier: int) -> bool:
	if not is_instance_valid(_thunder_charge_aura):
		return false
	_thunder_charge_active = true
	var accepted := _thunder_charge_aura.set_tier(tier)
	_sync_thunder_charge_aura_visibility()
	return accepted


func set_thunder_charge_rotation_speed(value: float) -> void:
	if is_instance_valid(_thunder_charge_aura):
		_thunder_charge_aura.set_rotation_speed(value)


func advance_thunder_charge_aura(delta: float) -> void:
	if is_instance_valid(_thunder_charge_aura):
		_thunder_charge_aura.advance(delta)


func clear_thunder_charge_aura() -> void:
	_thunder_charge_active = false
	if is_instance_valid(_thunder_charge_aura):
		_thunder_charge_aura.set_presented(false)


func get_thunder_charge_tier() -> int:
	return _thunder_charge_aura.get_tier() if is_instance_valid(_thunder_charge_aura) else 0


func is_thunder_charge_presented() -> bool:
	return is_instance_valid(_thunder_charge_aura) and _thunder_charge_aura.is_presented()


func _sync_thunder_charge_aura_visibility() -> void:
	if not is_instance_valid(_thunder_charge_aura):
		return
	_thunder_charge_aura.set_presented(
		_thunder_charge_active
		and is_instance_valid(_run_controller)
		and _run_controller.is_running()
	)


func reset_character_stat_multipliers() -> void:
	_character_move_speed_multiplier = 1.0
	_character_pickup_radius_multiplier = 1.0
	_character_health_max_multiplier = 1.0
	_recalculate_effective_stats(true)


## Rallentamento imposto da una fonte esterna al Player (le Signature Evil di
## PS-006). Vive in un dizionario separato dai moltiplicatori di upgrade e di
## personaggio: quando l'effetto scade il Player torna esattamente alla
## velocita' che aveva, senza che nessuno debba ricordarsela.
func set_external_speed_modifier(modifier_id: StringName, multiplier: float) -> bool:
	if (
		String(modifier_id).is_empty()
		or not is_finite(multiplier)
		or multiplier <= 0.0
	):
		return false
	if (
		_external_speed_modifiers.has(modifier_id)
		and is_equal_approx(float(_external_speed_modifiers[modifier_id]), multiplier)
	):
		return true
	_external_speed_modifiers[modifier_id] = multiplier
	_recalculate_effective_stats(true)
	external_speed_modifiers_changed.emit(self, get_external_speed_multiplier())
	return true


func remove_external_speed_modifier(modifier_id: StringName) -> bool:
	if not _external_speed_modifiers.erase(modifier_id):
		return false
	_recalculate_effective_stats(true)
	external_speed_modifiers_changed.emit(self, get_external_speed_multiplier())
	return true


func clear_external_speed_modifiers() -> void:
	if _external_speed_modifiers.is_empty():
		return
	_external_speed_modifiers.clear()
	_recalculate_effective_stats(true)
	external_speed_modifiers_changed.emit(self, 1.0)


func has_external_speed_modifier(modifier_id: StringName) -> bool:
	return _external_speed_modifiers.has(modifier_id)


func get_external_speed_multiplier() -> float:
	var multiplier := 1.0
	for value: Variant in _external_speed_modifiers.values():
		multiplier *= maxf(float(value), 0.0)
	return multiplier


## Spinta imposta dall'esterno (knockback dell'Onda d'Urto Tellurica). Per la
## sua durata sostituisce l'input di movimento, poi il controllo torna intero
## al giocatore: non tocca ne' statistiche ne' comandi.
func apply_external_impulse(impulse_velocity: Vector2, duration: float) -> bool:
	if (
		not impulse_velocity.is_finite()
		or impulse_velocity.is_zero_approx()
		or not is_finite(duration)
		or duration <= 0.0
	):
		return false
	_external_impulse_velocity = impulse_velocity
	_external_impulse_remaining = duration
	return true


func clear_external_impulse() -> void:
	_external_impulse_velocity = Vector2.ZERO
	_external_impulse_remaining = 0.0


func is_external_impulse_active() -> bool:
	return _external_impulse_remaining > 0.0


func reset_upgrade_stat_multipliers() -> void:
	_move_speed_multiplier = 1.0
	_pickup_radius_multiplier = 1.0
	_health_max_multiplier = 1.0
	_damage_taken_multiplier = 1.0
	_recalculate_effective_stats(true)


func get_base_move_speed() -> float:
	return _base_move_speed * _character_move_speed_multiplier


func get_base_pickup_radius() -> float:
	return _base_pickup_radius * _character_pickup_radius_multiplier


func get_move_speed_multiplier() -> float:
	return _move_speed_multiplier


func get_pickup_radius_multiplier() -> float:
	return _pickup_radius_multiplier


func get_base_health_max() -> float:
	return _base_health_max * _character_health_max_multiplier


func get_health_max_multiplier() -> float:
	return _health_max_multiplier


func get_damage_taken_multiplier() -> float:
	return _damage_taken_multiplier


func get_character_move_speed_multiplier() -> float:
	return _character_move_speed_multiplier


func get_character_health_max_multiplier() -> float:
	return _character_health_max_multiplier


func is_alive() -> bool:
	return (
		is_instance_valid(_health_component)
		and not _death_handled
		and _health_component.is_alive()
	)


func get_damage_flash_remaining() -> float:
	return _damage_flash_remaining


func get_damage_reaction_remaining() -> float:
	return _damage_reaction_remaining


func is_damage_blink_active() -> bool:
	return (
		is_instance_valid(_health_component)
		and _health_component.is_invulnerable()
	)


func is_damage_blink_visible() -> bool:
	if not is_damage_blink_active():
		return true
	var blink_interval := PresentationTimings.PLAYER_DAMAGE_BLINK_INTERVAL_SECONDS
	var invulnerability_duration := _health_component.invulnerability_duration
	if blink_interval <= 0.0 or invulnerability_duration <= 0.0:
		return true
	var elapsed := clampf(
		invulnerability_duration - _health_component.invulnerability_remaining,
		0.0,
		invulnerability_duration
	)
	return (floori(elapsed / blink_interval) % 2) == 0


func get_visual_damage_scale() -> Vector2:
	if damage_reaction_duration <= 0.0 or _damage_reaction_remaining <= 0.0:
		return Vector2.ONE
	var strength := clampf(
		_damage_reaction_remaining / damage_reaction_duration,
		0.0,
		1.0
	)
	return Vector2(
		1.0 + damage_squash_strength * strength,
		1.0 - damage_squash_strength * strength
	)


func _make_collision_shape_unique() -> void:
	var circle_shape := CircleShape2D.new()
	if _collision_shape.shape is CircleShape2D:
		circle_shape = _collision_shape.shape.duplicate() as CircleShape2D
	_collision_shape.shape = circle_shape


func _refresh_character_visual() -> void:
	if not is_instance_valid(_character_sprite):
		return
	_character_idle_texture = (
		friend_definition.get_gameplay_idle_right()
		if friend_definition != null
		else null
	)
	_character_walk_frames = (
		friend_definition.get_gameplay_walk_right_frames()
		if friend_definition != null
		else [] as Array[Texture2D]
	)
	_character_walk_frame_index = 0
	_character_walk_elapsed = 0.0
	_character_is_walking = false
	_sync_character_animation_state()
	_update_character_feedback()


func _update_character_feedback() -> void:
	if not is_instance_valid(_character_sprite):
		return
	_character_sprite.scale = (
		_character_base_scale
		* visual_scale_multiplier
		* get_visual_damage_scale()
	)
	# Lo sprite conserva i propri colori: solo il flash da danno lo altera,
	# e ha la precedenza sul tell di stato (PS-001).
	_character_sprite.self_modulate = (
		Color(1.0, 0.72, 0.8, 1.0)
		if _damage_flash_remaining > 0.0
		else Color.WHITE
	)
	_character_sprite.visible = (
		_character_sprite.texture != null
		and is_damage_blink_visible()
	)


func _update_facing_from_movement(value: Vector2) -> void:
	if value.is_zero_approx():
		return
	_last_movement_direction = value.normalized()
	if absf(value.x) <= HORIZONTAL_FACING_EPSILON:
		return
	_set_facing_direction(Vector2.RIGHT if value.x > 0.0 else Vector2.LEFT)


func _set_facing_direction(value: Vector2) -> void:
	var resolved := Vector2.RIGHT if value.x >= 0.0 else Vector2.LEFT
	if resolved == _facing_direction:
		if is_instance_valid(_character_sprite):
			_character_sprite.flip_h = resolved == Vector2.LEFT
		return
	_facing_direction = resolved
	if is_instance_valid(_character_sprite):
		_character_sprite.flip_h = _facing_direction == Vector2.LEFT
	facing_direction_changed.emit(_facing_direction)


func _sync_character_animation_state() -> void:
	if not is_instance_valid(_character_sprite):
		return
	var should_walk := (
		not movement_input.is_zero_approx()
	)
	if should_walk != _character_is_walking:
		_character_is_walking = should_walk
		_character_walk_frame_index = 0
		_character_walk_elapsed = 0.0
	_apply_character_frame()


func _advance_character_animation(delta: float) -> void:
	_sync_character_animation_state()
	if not _character_is_walking or _character_walk_frames.size() < 2:
		return
	var fps := (
		friend_definition.gameplay_walk_fps
		if friend_definition != null
		else 8.0
	)
	var frame_duration := 1.0 / maxf(fps, 1.0)
	_character_walk_elapsed += maxf(delta, 0.0)
	while _character_walk_elapsed >= frame_duration:
		_character_walk_elapsed -= frame_duration
		_character_walk_frame_index = (
			(_character_walk_frame_index + 1) % _character_walk_frames.size()
		)
	_apply_character_frame()


func _advance_momentum(delta: float) -> void:
	if movement_input.is_zero_approx():
		_momentum_ratio = maxf(_momentum_ratio - delta / MOMENTUM_DECAY_SECONDS, 0.0)
		_momentum_reference_direction = Vector2.ZERO
	else:
		var direction := movement_input.normalized()
		var aligned := (
			_momentum_reference_direction.is_zero_approx()
			or direction.dot(_momentum_reference_direction) >= MOMENTUM_DIRECTION_COS_THRESHOLD
		)
		if aligned:
			_momentum_ratio = clampf(_momentum_ratio + delta / MOMENTUM_RAMP_SECONDS, 0.0, 1.0)
		else:
			_momentum_ratio = maxf(_momentum_ratio - delta / MOMENTUM_DECAY_SECONDS, 0.0)
		_momentum_reference_direction = direction
	_advance_momentum_trail(delta)


func _advance_momentum_trail(delta: float) -> void:
	if not _momentum_trail_enabled or _momentum_ratio <= MOMENTUM_TRAIL_MINIMUM_RATIO:
		if not _momentum_trail_points.is_empty():
			_momentum_trail_points.clear()
			queue_redraw()
		return
	_momentum_trail_sample_elapsed += delta
	if _momentum_trail_sample_elapsed < MOMENTUM_TRAIL_SAMPLE_INTERVAL:
		return
	_momentum_trail_sample_elapsed = 0.0
	_momentum_trail_points.append(global_position)
	if _momentum_trail_points.size() > MOMENTUM_TRAIL_MAX_POINTS:
		_momentum_trail_points.remove_at(0)
	queue_redraw()


func _draw() -> void:
	if not _momentum_trail_enabled or _momentum_trail_points.size() < 2:
		return
	var point_count := _momentum_trail_points.size()
	for index in point_count - 1:
		var age_ratio := float(index) / float(point_count)
		var alpha := _momentum_ratio * age_ratio * 0.55
		if alpha <= 0.01:
			continue
		var from_point := to_local(_momentum_trail_points[index])
		var to_point := to_local(_momentum_trail_points[index + 1])
		var width := 3.0 + 4.0 * _momentum_ratio * age_ratio
		draw_line(from_point, to_point, Color(MOMENTUM_TRAIL_COLOR, alpha), width, true)


func _apply_character_frame() -> void:
	if not is_instance_valid(_character_sprite):
		return
	if _character_is_walking and not _character_walk_frames.is_empty():
		_character_sprite.texture = _character_walk_frames[_character_walk_frame_index]
		var gait_phase := _character_walk_frame_index % 4
		_character_sprite.position = (
			Vector2(0.0, -2.0)
			if gait_phase == 1 or gait_phase == 3
			else Vector2.ZERO
		)
		_character_sprite.rotation = (
			-0.035 if gait_phase == 0
			else 0.035 if gait_phase == 2
			else 0.0
		)
	else:
		_character_sprite.texture = _character_idle_texture
		_character_sprite.position = Vector2.ZERO
		_character_sprite.rotation = 0.0
	_character_sprite.visible = _character_sprite.texture != null
	_character_sprite.flip_h = _facing_direction == Vector2.LEFT


func _recalculate_effective_stats(preserve_health_ratio: bool) -> void:
	move_speed = get_base_move_speed() * _move_speed_multiplier * get_external_speed_multiplier()
	pickup_radius = get_base_pickup_radius() * _pickup_radius_multiplier
	if is_instance_valid(_health_component):
		_health_component.set_health_max(
			get_base_health_max() * _health_max_multiplier,
			preserve_health_ratio
		)


func _sync_collision_radius() -> void:
	if _collision_shape.shape is CircleShape2D:
		var circle_shape := _collision_shape.shape as CircleShape2D
		circle_shape.radius = collision_radius


func _connect_arena_layout() -> void:
	if not is_instance_valid(_arena_layout):
		return
	if not _arena_layout.playfield_changed.is_connected(
		_on_playfield_changed
	):
		_arena_layout.playfield_changed.connect(_on_playfield_changed)


func _disconnect_arena_layout() -> void:
	if not is_instance_valid(_arena_layout):
		return
	if _arena_layout.playfield_changed.is_connected(_on_playfield_changed):
		_arena_layout.playfield_changed.disconnect(_on_playfield_changed)


func _on_playfield_changed(_playfield_rect: Rect2) -> void:
	if is_instance_valid(_run_controller) and not _run_controller.is_running():
		return
	_clamp_to_playfield()


func _connect_run_controller() -> void:
	if not is_instance_valid(_run_controller):
		return
	if not _run_controller.state_changed.is_connected(_on_run_state_changed):
		_run_controller.state_changed.connect(_on_run_state_changed)
	if not _run_controller.run_started.is_connected(_on_run_started):
		_run_controller.run_started.connect(_on_run_started)
	if not _run_controller.restart_prepared.is_connected(_on_restart_prepared):
		_run_controller.restart_prepared.connect(_on_restart_prepared)


func _disconnect_run_controller() -> void:
	if not is_instance_valid(_run_controller):
		_run_controller = null
		return
	if _run_controller.state_changed.is_connected(_on_run_state_changed):
		_run_controller.state_changed.disconnect(_on_run_state_changed)
	if _run_controller.run_started.is_connected(_on_run_started):
		_run_controller.run_started.disconnect(_on_run_started)
	if _run_controller.restart_prepared.is_connected(_on_restart_prepared):
		_run_controller.restart_prepared.disconnect(_on_restart_prepared)
	_run_controller = null


func _connect_health_component() -> void:
	if not is_instance_valid(_health_component):
		return
	if not _health_component.health_changed.is_connected(_on_health_changed):
		_health_component.health_changed.connect(_on_health_changed)
	if not _health_component.damaged.is_connected(_on_damaged):
		_health_component.damaged.connect(_on_damaged)
	if not _health_component.died.is_connected(_on_died):
		_health_component.died.connect(_on_died)
	if not _health_component.invulnerability_changed.is_connected(
		_on_invulnerability_changed
	):
		_health_component.invulnerability_changed.connect(
			_on_invulnerability_changed
		)


func _disconnect_health_component() -> void:
	if not is_instance_valid(_health_component):
		return
	if _health_component.health_changed.is_connected(_on_health_changed):
		_health_component.health_changed.disconnect(_on_health_changed)
	if _health_component.damaged.is_connected(_on_damaged):
		_health_component.damaged.disconnect(_on_damaged)
	if _health_component.died.is_connected(_on_died):
		_health_component.died.disconnect(_on_died)
	if _health_component.invulnerability_changed.is_connected(
		_on_invulnerability_changed
	):
		_health_component.invulnerability_changed.disconnect(
			_on_invulnerability_changed
		)


func _on_health_changed(health_current: float, health_max: float) -> void:
	health_changed.emit(self, health_current, health_max)


func _on_damaged(amount: float, health_current: float) -> void:
	_damage_flash_remaining = maxf(damage_flash_duration, 0.0)
	_damage_reaction_remaining = maxf(damage_reaction_duration, 0.0)
	_update_character_feedback()
	damaged.emit(self, amount, health_current)


func _on_died() -> void:
	if _death_handled:
		return
	_death_handled = true
	clear_movement_input()
	died.emit(self)


func _on_invulnerability_changed(_active: bool, _remaining: float) -> void:
	_update_character_feedback()


func _on_run_state_changed(
	_previous_state: RunController.RunState,
	_current_state: RunController.RunState
) -> void:
	_sync_passive_state_tell_visibility()
	_sync_thunder_charge_aura_visibility()


func _on_run_started(_seed_value: int) -> void:
	reset_for_run()


func _on_restart_prepared() -> void:
	reset_for_run()


func _clamp_to_playfield() -> void:
	if _world_bounds.has_area():
		global_position = ArenaWorld.clamp_circle_center_in_rect(
			_world_bounds,
			global_position,
			collision_radius
		)
	elif is_instance_valid(_arena_layout):
		global_position = _arena_layout.clamp_circle_center(
			global_position,
			collision_radius
		)
	else:
		return


## Sesto Senso Equino di Bea (B45): prova a spostare il Player lungo
## `direction` per `distance`, rispettando confinamento mondo/HUD e senza
## mai atterrare dentro un ostacolo statico. Se non esiste una destinazione
## sicura (spostamento quasi nullo dopo il confinamento, o punto bloccato),
## non sposta il Player e restituisce `false`: il colpo va comunque annullato
## e l'i-frame concesso a monte, ma senza spostamento casuale.
func try_shove_to_safe_position(direction: Vector2, distance: float) -> bool:
	if (
		not direction.is_finite()
		or direction.is_zero_approx()
		or not is_finite(distance)
		or distance <= 0.0
	):
		return false
	var desired := global_position + direction.normalized() * distance
	var confined := _confine_point(desired)
	if confined.distance_to(global_position) < collision_radius * 0.5:
		return false
	if _point_blocked_by_obstacle(confined):
		return false
	global_position = confined
	return true


## Confinamento pubblico di un punto arbitrario nello spazio di mondo:
## stessa catena usata dal Player ogni frame. Serve a chi calcola una
## destinazione per il Player (Powerslide di Bea) senza dover conoscere i
## limiti dell'arena, che NON coincidono con il playfield a schermo di
## ArenaLayout.
func confine_world_point(point: Vector2) -> Vector2:
	if not point.is_finite():
		return global_position
	return _confine_point(point)


func _confine_point(point: Vector2) -> Vector2:
	if _world_bounds.has_area():
		return ArenaWorld.clamp_circle_center_in_rect(_world_bounds, point, collision_radius)
	if is_instance_valid(_arena_layout):
		return _arena_layout.clamp_circle_center(point, collision_radius)
	return point


func _point_blocked_by_obstacle(point: Vector2) -> bool:
	if not is_inside_tree():
		return false
	for obstacle in get_tree().get_nodes_in_group(&"static_obstacles"):
		if obstacle is StaticObstacle and (obstacle as StaticObstacle).get_footprint_rect().has_point(point):
			return true
	return false
