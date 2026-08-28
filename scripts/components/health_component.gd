class_name HealthComponent
extends Node

signal health_changed(health_current: float, health_max: float)
signal damaged(amount: float, health_current: float)
signal died()
signal invulnerability_changed(active: bool, remaining: float)

const MINIMUM_HEALTH := 0.001

@export_range(0.001, 1000000.0, 0.1, "or_greater") var health_max := 100.0:
	set(value):
		health_max = maxf(value, MINIMUM_HEALTH) if is_finite(value) else MINIMUM_HEALTH
		if _initialized and not _setting_health_max:
			_set_health_current(minf(_health_current, health_max))

@export_range(0.0, 60.0, 0.01, "or_greater") var invulnerability_duration := 0.0:
	set(value):
		invulnerability_duration = maxf(value, 0.0) if is_finite(value) else 0.0

var health_current: float:
	get:
		return _health_current

var invulnerability_remaining: float:
	get:
		return _invulnerability_remaining

var _health_current := 0.0
var _initialized := false
var _dead := false
var _setting_health_max := false
var _damage_transition_active := false
var _invulnerability_remaining := 0.0


func _ready() -> void:
	reset_to_max()


func take_damage(amount: float) -> bool:
	if (
		not _initialized
		or _dead
		or _damage_transition_active
		or is_invulnerable()
		or not is_finite(amount)
		or amount <= 0.0
	):
		return false

	var applied_damage := minf(amount, _health_current)
	if applied_damage <= 0.0:
		return false

	var next_health := clampf(_health_current - applied_damage, 0.0, health_max)
	var became_dead := next_health <= 0.0
	# Il latch letale precede ogni segnale esterno: una callback rientrante non
	# puo far applicare un secondo danno durante la stessa transizione.
	_dead = became_dead
	_damage_transition_active = true
	if not became_dead and invulnerability_duration > 0.0:
		_set_invulnerability_remaining(invulnerability_duration)
	_set_health_current(next_health)
	damaged.emit(applied_damage, _health_current)
	if became_dead:
		died.emit()
	_damage_transition_active = false
	return true


func heal(amount: float) -> float:
	if (
		not _initialized
		or _dead
		or _damage_transition_active
		or not is_finite(amount)
		or amount <= 0.0
	):
		return 0.0
	var applied_healing := minf(amount, health_max - _health_current)
	if applied_healing <= 0.0:
		return 0.0
	_set_health_current(_health_current + applied_healing)
	return applied_healing


func reset_to_max() -> void:
	if _damage_transition_active:
		return
	_initialized = true
	_dead = false
	_set_invulnerability_remaining(0.0)
	_set_health_current(health_max)


func advance_invulnerability(delta: float) -> bool:
	if (
		_invulnerability_remaining <= 0.0
		or not is_finite(delta)
		or delta <= 0.0
	):
		return false

	_set_invulnerability_remaining(
		maxf(_invulnerability_remaining - delta, 0.0)
	)
	return true


func clear_invulnerability() -> void:
	_set_invulnerability_remaining(0.0)


## Concede i-frame senza infliggere danno: usato da un colpo annullato a
## monte (es. lo Scarto Istintivo di Bea), che quindi non passa da
## take_damage() e non attiverebbe l'invulnerabilita' automatica.
func grant_invulnerability(duration: float) -> bool:
	if not _initialized or _dead or not is_finite(duration) or duration <= 0.0:
		return false
	_set_invulnerability_remaining(maxf(_invulnerability_remaining, duration))
	return true


func set_health_max(value: float, preserve_ratio: bool = false) -> void:
	var previous_max := health_max
	var previous_current := _health_current
	_setting_health_max = true
	health_max = value
	_setting_health_max = false
	if not _initialized:
		return

	if preserve_ratio and previous_max > 0.0:
		_set_health_current(health_max * clampf(previous_current / previous_max, 0.0, 1.0))
	else:
		_set_health_current(minf(previous_current, health_max))
	_dead = _health_current <= 0.0


func is_alive() -> bool:
	return _initialized and not _dead and _health_current > 0.0


func is_invulnerable() -> bool:
	return is_alive() and _invulnerability_remaining > 0.0


func _set_health_current(value: float) -> void:
	_health_current = clampf(value, 0.0, health_max)
	health_changed.emit(_health_current, health_max)


func _set_invulnerability_remaining(value: float) -> void:
	var next_value := maxf(value, 0.0) if is_finite(value) else 0.0
	if next_value <= 0.000001:
		next_value = 0.0
	if _invulnerability_remaining == next_value:
		return
	_invulnerability_remaining = next_value
	invulnerability_changed.emit(
		_invulnerability_remaining > 0.0,
		_invulnerability_remaining
	)
