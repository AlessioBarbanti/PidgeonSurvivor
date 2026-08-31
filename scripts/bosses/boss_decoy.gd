class_name BossDecoy
extends BaseEnemy

## Clone ballerino di Evil Marghe (PS-006).
##
## E' un bersaglio registrabile nel `TargetingSystem`: l'auto-targeting del
## Player puo' preferirlo al Boss reale perche' viene piazzato piu' vicino, non
## perche' qualcuno riscriva i comandi del giocatore. Non insegue, non
## infligge danno da contatto e non passa dallo spawner, quindi non produce
## esperienza.

signal decoy_expired(decoy: BossDecoy)

const GHOST_MODULATE := Color(0.42, 0.98, 1.0, 0.78)
const NOTE_COUNT := 5
const NOTE_COLOR := Color(0.35, 0.92, 1.0, 1.0)
const VISUAL_SCALE := 0.82

var _duration_total := 0.0
var _duration_remaining := 0.0
var _dance_elapsed := 0.0
var _expire_handled := false

@onready var _decoy_sprite := get_node_or_null("DecoySprite") as Sprite2D


func _ready() -> void:
	super._ready()
	set_target(null)
	var contact_damage := get_contact_damage()
	if contact_damage != null:
		contact_damage.damage = 0.0
		contact_damage.disable()


func initialize(
	source_texture: Texture2D,
	decoy_health: float,
	decoy_radius: float,
	duration: float,
	run_controller: RunController
) -> bool:
	if (
		not is_finite(decoy_health)
		or decoy_health <= 0.0
		or not is_finite(decoy_radius)
		or decoy_radius <= 0.0
		or not is_finite(duration)
		or duration <= 0.0
		or not is_instance_valid(run_controller)
	):
		return false
	collision_radius = decoy_radius
	_duration_total = duration
	_duration_remaining = duration
	set_run_controller(run_controller)
	var health_component := get_health_component()
	if health_component == null:
		return false
	health_component.set_health_max(decoy_health)
	health_component.reset_to_max()
	_sync_decoy_sprite(source_texture)
	queue_redraw()
	return true


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	var run_controller := get_run_controller()
	if not is_instance_valid(run_controller) or not run_controller.is_running():
		return
	var safe_delta := maxf(delta, 0.0) if is_finite(delta) else 0.0
	_dance_elapsed += safe_delta
	_duration_remaining = maxf(_duration_remaining - safe_delta, 0.0)
	_sync_dance_pose()
	queue_redraw()
	if _duration_remaining <= 0.0:
		expire()


func _draw() -> void:
	super._draw()
	var alpha := clampf(
		_duration_remaining / maxf(_duration_total, 0.001),
		0.0,
		1.0
	)
	for note_index in NOTE_COUNT:
		var lane := float(note_index % 3) - 1.0
		var rise := fmod(_dance_elapsed * 26.0 + float(note_index) * 11.0, 52.0)
		var note_origin := Vector2(
			collision_radius * 0.9 + lane * 11.0,
			-collision_radius - rise * 0.6
		)
		var note_color := Color(NOTE_COLOR, alpha * (1.0 - rise / 60.0))
		draw_circle(note_origin, 3.0, note_color)
		draw_line(
			note_origin + Vector2(2.6, 0.0),
			note_origin + Vector2(2.6, -11.0),
			note_color,
			2.0,
			true
		)


func get_duration_remaining() -> float:
	return _duration_remaining


func get_decoy_texture() -> Texture2D:
	return _decoy_sprite.texture if is_instance_valid(_decoy_sprite) else null


func get_decoy_modulate() -> Color:
	return _decoy_sprite.self_modulate if is_instance_valid(_decoy_sprite) else Color.WHITE


func expire() -> void:
	if _expire_handled:
		return
	_expire_handled = true
	_duration_remaining = 0.0
	decoy_expired.emit(self)
	if not is_queued_for_deletion():
		queue_free()


## Stessa silhouette del Boss, tinta spettrale e scala ridotta: il clone resta
## riconoscibile come copia senza poter essere scambiato per l'originale.
func _sync_decoy_sprite(source_texture: Texture2D) -> void:
	if not is_instance_valid(_decoy_sprite):
		return
	_decoy_sprite.texture = source_texture
	_decoy_sprite.self_modulate = GHOST_MODULATE
	var texture_size := (
		source_texture.get_size()
		if source_texture != null
		else Vector2.ZERO
	)
	if texture_size.x > 0.0 and texture_size.y > 0.0:
		var target_diameter := collision_radius * 1.9 * VISUAL_SCALE
		var scale_factor := target_diameter / maxf(texture_size.x, texture_size.y)
		_decoy_sprite.scale = Vector2.ONE * clampf(scale_factor, 1.0, 4.0)
	_decoy_sprite.visible = _decoy_sprite.texture != null


func _sync_dance_pose() -> void:
	if not is_instance_valid(_decoy_sprite):
		return
	var beat := sin(_dance_elapsed * TAU * 2.0)
	_decoy_sprite.position = Vector2(beat * 4.0, -absf(beat) * 5.0)
	_decoy_sprite.rotation = beat * 0.09
