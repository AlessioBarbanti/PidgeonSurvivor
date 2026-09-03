class_name FriendPassiveController
extends Node

signal passive_equipped(definition: FriendDefinition)
signal damage_avoided(passive_id: StringName)
signal delayed_healing_changed(recoverable_health: float)
signal thunder_charge_tier_changed(tier: int)
signal shield_changed(active: bool, remaining: float)
signal random_effect_started(positive: bool, stat_id: StringName, multiplier: float)
signal thermal_mode_changed(hot: bool)
signal hyperfocus_changed(focused: bool, phase_duration: float)
signal marked_targets_changed(marked_count: int)
signal luck_charge_changed(luck_bonus: float)
signal distraction_shortened(remaining: float)
signal migi_shell_charges_changed(charges: int, max_charges: int)
signal instinctive_dodge_triggered(position: Vector2, direction: Vector2)

const MAGNO_AERODYNAMIC_FLOW := &"magno_aerodynamic_flow"
const BEA_SIXTH_SENSE := &"bea_sixth_sense"
const ZAT_DELAYED_HEALING := &"zat_delayed_healing"
const ALEA_EAGLE_NEVER_MISSES := &"alea_eagle_never_misses"
const ALEO_INTERNAL_THERMOSTAT := &"aleo_internal_thermostat"
const LOLLO_HYPERACTIVITY := &"lollo_hyperactivity"
const MIGI_TURTLE_SHELL := &"migi_turtle_shell"
const MARGHE_CONTAGIOUS_SMILE := &"marghe_contagious_smile"

const ALEO_COLD_AURA_MODIFIER := &"aleo_cold_aura"
const MARGHE_SMILE_MODIFIER := &"marghe_contagious_smile"
const MINIMUM_MULTIPLIER := 0.001

## Colori del particellare usato come "tell" delle passive a fasi (PS-001,
## particellare non aderente da PS-079). Restano puramente presentazionali:
## nessuna regola di gameplay li legge.
##
## Fino a PS-001 erano tinte moltiplicative applicate con `self_modulate`
## sull'intero sprite, con valori fuori gamma (`1.32`) pensati per schiarire.
## Ridipingevano il personaggio: Alea in fase positiva diventava tutta verde.
## PS-001 li aveva spostati in un contorno attorno alla sagoma; PS-079 li
## sposta di nuovo, questa volta in un piccolo particellare che si solleva
## sopra la testa senza mai toccare il profilo dello sprite. Il significato di
## ogni colore non cambia: solo il canale che lo mostra.
##
## PS-029: `TELL_LOLLO_DISTRACTED` e `TELL_MIGI_SHIELD` erano desaturati
## o quasi identici alla loro controparte (differenza cromatica minima,
## criterio di accettazione esplicito), quindi si mimetizzavano con lo sfondo
## arena o l'uno con l'altro. Rifatti piu' saturi e distanti in tonalita' dalla
## rispettiva fase opposta; le altre coppie avevano gia' contrasto sufficiente.
const TELL_NEUTRAL := Color(0.0, 0.0, 0.0, 0.0)
const TELL_ALEO_HOT := Color(1.0, 0.55, 0.18, 1.0)
const TELL_ALEO_COLD := Color(0.35, 0.78, 1.0, 1.0)
const TELL_LOLLO_FOCUSED := Color(1.0, 0.88, 0.28, 1.0)
const TELL_LOLLO_DISTRACTED := Color(0.30, 0.36, 0.98, 1.0)
const TELL_ALEA_POSITIVE := Color(0.36, 1.0, 0.52, 1.0)
const TELL_ALEA_NEGATIVE := Color(1.0, 0.38, 0.42, 1.0)
const TELL_MIGI_SHELL_READY := Color(0.32, 0.94, 0.84, 1.0)
const TELL_MIGI_SHIELD := Color(0.68, 0.32, 1.0, 1.0)

var _run_controller: RunController
var _player: Player
var _weapon_controller: WeaponController
var _targeting_system: TargetingSystem
var _definition: FriendDefinition
var _rng := RandomNumberGenerator.new()

var _recoverable_health := 0.0
var _thunder_charge_tier := ThunderChargeAura.TIER_LOW
var _recovery_delay_remaining := 0.0
var _recovery_duration_remaining := 0.0
var _shield_remaining := 0.0
var _shield_cooldown_remaining := 0.0
var _shield_hits_remaining := 0
var _alea_interval_remaining := 0.0
var _alea_effect_remaining := 0.0
var _alea_move_multiplier := 1.0
var _alea_fire_multiplier := 1.0
var _alea_luck_bonus := 0.0
var _aleo_hot := true
var _aleo_chilled_targets: Array[BaseEnemy] = []
var _aleo_cold_damage_accumulator := 0.0
var _lollo_focused := true
var _lollo_phase_remaining := 0.0
var _marghe_marked_targets: Array[BaseEnemy] = []
var _bea_dodge_cooldown_remaining := 0.0
var _migi_shell_charges := 0
var _migi_shell_regen_remaining := 0.0


func _process(delta: float) -> void:
	if (
		_definition == null
		or not is_instance_valid(_run_controller)
		or not _run_controller.is_running()
	):
		return
	var safe_delta := maxf(delta, 0.0) if is_finite(delta) else 0.0
	if safe_delta <= 0.0:
		return
	# Il particellare del tell (PS-079) anima sempre mentre la run e'
	# RUNNING, a prescindere da quale ramo sotto lo mantiene attivo: e'
	# innocuo per i profili senza fase (nessun colore, nulla da disegnare).
	if is_instance_valid(_player):
		_player.advance_passive_state_particles(safe_delta)
	match _definition.passive_id:
		ZAT_DELAYED_HEALING:
			_advance_delayed_healing(safe_delta)
			_advance_thunder_charge_rotation(safe_delta)
		ALEA_EAGLE_NEVER_MISSES:
			_advance_alea_effect(safe_delta)
		ALEO_INTERNAL_THERMOSTAT:
			_advance_aleo_thermostat(safe_delta)
		LOLLO_HYPERACTIVITY:
			_advance_lollo_hyperfocus(safe_delta)
		MIGI_TURTLE_SHELL:
			_advance_migi_shield(safe_delta)
			_advance_migi_shell_charges(safe_delta)
		MARGHE_CONTAGIOUS_SMILE:
			_refresh_marghe_aura()
		BEA_SIXTH_SENSE:
			_advance_bea_dodge_cooldown(safe_delta)
		MAGNO_AERODYNAMIC_FLOW:
			_apply_character_multipliers()


func _exit_tree() -> void:
	_clear_aleo_cold_aura()
	_clear_marghe_aura()
	_disconnect_dependencies()


func configure(
	run_controller: RunController,
	player: Player,
	weapon_controller: WeaponController,
	targeting_system: TargetingSystem
) -> bool:
	_disconnect_dependencies()
	_run_controller = run_controller
	_player = player
	_weapon_controller = weapon_controller
	_targeting_system = targeting_system
	if not _has_valid_dependencies():
		return false
	_player.set_passive_controller(self)
	_player.damaged.connect(_on_player_damaged)
	_targeting_system.target_registered.connect(_on_target_registered)
	_run_controller.run_started.connect(_on_run_started)
	_run_controller.restart_prepared.connect(_on_restart_prepared)
	return true


func equip_definition(definition: FriendDefinition) -> bool:
	if not _has_valid_dependencies() or not is_supported_definition(definition):
		return false
	_definition = definition
	_reset_runtime(_run_controller.get_seed())
	passive_equipped.emit(_definition)
	return true


func get_definition() -> FriendDefinition:
	return _definition


func get_passive_id() -> StringName:
	return _definition.passive_id if _definition != null else &""


func get_recoverable_health() -> float:
	return _recoverable_health


## Fascia di carica corrente (PS-004): letta da Tempesta di Tuoni per
## scalare il danno e dall'aura per il proprio tell. Fuori da Zat resta
## sempre in fascia bassa.
func get_thunder_charge_tier() -> int:
	if (
		_definition == null
		or _definition.passive_id != ZAT_DELAYED_HEALING
		or not is_instance_valid(_player)
	):
		return ThunderChargeAura.TIER_LOW
	var health := _player.get_health_component()
	if health == null or health.health_max <= 0.0:
		return ThunderChargeAura.TIER_LOW
	var ratio := _recoverable_health / health.health_max
	var high_threshold := _definition.get_passive_float(&"charge_threshold_high", 0.12, 0.0)
	var medium_threshold := _definition.get_passive_float(&"charge_threshold_medium", 0.05, 0.0)
	if ratio >= high_threshold:
		return ThunderChargeAura.TIER_HIGH
	if ratio >= medium_threshold:
		return ThunderChargeAura.TIER_MEDIUM
	return ThunderChargeAura.TIER_LOW


func is_shield_active() -> bool:
	return _shield_remaining > 0.0 and _shield_hits_remaining > 0


func get_shield_remaining() -> float:
	return _shield_remaining


func is_hyperfocused() -> bool:
	return _lollo_focused


func get_hyperfocus_remaining() -> float:
	return maxf(_lollo_phase_remaining, 0.0)


func resolve_incoming_damage(amount: float, source_position: Vector2 = Vector2.INF) -> float:
	if (
		_definition == null
		or not is_finite(amount)
		or amount <= 0.0
		or not is_instance_valid(_run_controller)
		or not _run_controller.is_running()
	):
		return maxf(amount, 0.0) if is_finite(amount) else 0.0

	if _definition.passive_id == BEA_SIXTH_SENSE and _bea_dodge_cooldown_remaining <= 0.0:
		_trigger_instinctive_dodge(source_position)
		return 0.0

	if _definition.passive_id == MIGI_TURTLE_SHELL and is_shield_active():
		_shield_hits_remaining -= 1
		if _shield_hits_remaining <= 0:
			_shield_remaining = 0.0
			shield_changed.emit(false, 0.0)
			_refresh_passive_state_tell()
		damage_avoided.emit(_definition.passive_id)
		return 0.0

	if _definition.passive_id == MIGI_TURTLE_SHELL and _migi_shell_charges > 0:
		_migi_shell_charges -= 1
		migi_shell_charges_changed.emit(
			_migi_shell_charges,
			_definition.get_passive_int(&"shell_charge_max", 2, 0)
		)
		damage_avoided.emit(_definition.passive_id)
		_refresh_passive_state_tell()
		return 0.0

	var reduction := 0.0
	if _definition.passive_id == ALEO_INTERNAL_THERMOSTAT and not _aleo_hot:
		reduction = _definition.get_passive_float(
			&"cold_damage_reduction",
			0.0,
			0.0,
			0.95
		)
	return amount * (1.0 - reduction)


## Annulla il colpo, avvia il cooldown e prova a scartare Bea lontano dalla
## minaccia con un breve i-frame. Se non esiste una destinazione sicura (o
## la fonte del danno non e' nota), non la sposta ma il colpo resta comunque
## annullato: nessun salvataggio casuale, nessun colpo che passa.
func _trigger_instinctive_dodge(source_position: Vector2) -> void:
	_bea_dodge_cooldown_remaining = _definition.get_passive_float(
		&"dodge_cooldown",
		9.0,
		AbilityDefinition.MINIMUM_POSITIVE_VALUE
	)
	damage_avoided.emit(_definition.passive_id)
	if not is_instance_valid(_player):
		return
	var direction := _resolve_dodge_direction(source_position)
	var shove_distance := _definition.get_passive_float(&"shove_distance", 90.0, 0.0)
	if shove_distance > 0.0:
		_player.try_shove_to_safe_position(direction, shove_distance)
	var iframe_duration := _definition.get_passive_float(
		&"iframe_duration",
		0.4,
		AbilityDefinition.MINIMUM_POSITIVE_VALUE
	)
	var health := _player.get_health_component()
	if health != null:
		health.grant_invulnerability(iframe_duration)
	instinctive_dodge_triggered.emit(_player.global_position, direction)


func _resolve_dodge_direction(source_position: Vector2) -> Vector2:
	if is_instance_valid(_player) and source_position.is_finite():
		var offset := _player.global_position - source_position
		if not offset.is_zero_approx():
			return offset.normalized()
	if is_instance_valid(_player):
		return -_player.get_last_movement_direction()
	return Vector2.LEFT


func is_supported_definition(definition: FriendDefinition) -> bool:
	if definition == null or not definition.is_valid():
		return false
	return definition.passive_id in [
		MAGNO_AERODYNAMIC_FLOW,
		BEA_SIXTH_SENSE,
		ZAT_DELAYED_HEALING,
		ALEA_EAGLE_NEVER_MISSES,
		ALEO_INTERNAL_THERMOSTAT,
		LOLLO_HYPERACTIVITY,
		MIGI_TURTLE_SHELL,
		MARGHE_CONTAGIOUS_SMILE,
	]


func _advance_delayed_healing(delta: float) -> void:
	if _recoverable_health <= 0.0:
		return
	if _recovery_delay_remaining > 0.0:
		_recovery_delay_remaining = maxf(_recovery_delay_remaining - delta, 0.0)
		return
	if _recovery_duration_remaining <= 0.0:
		_recovery_duration_remaining = _definition.get_passive_float(
			&"recovery_duration",
			1.0,
			AbilityDefinition.MINIMUM_POSITIVE_VALUE
		)
	var healing_request := minf(
		_recoverable_health,
		_recoverable_health * delta / _recovery_duration_remaining
	)
	var health := _player.get_health_component()
	var applied := health.heal(healing_request) if health != null else 0.0
	if applied <= 0.0:
		_recoverable_health = 0.0
	else:
		_recoverable_health = maxf(_recoverable_health - applied, 0.0)
	_recovery_duration_remaining = maxf(_recovery_duration_remaining - delta, 0.0)
	delayed_healing_changed.emit(_recoverable_health)
	_refresh_thunder_charge_aura()


## La rotazione dell'aura avanza a ogni tick di RUNNING indipendentemente dal
## fatto che la fascia sia cambiata: e' lei stessa, insieme al colore, a
## comunicare la fascia corrente (PS-004).
func _advance_thunder_charge_rotation(delta: float) -> void:
	if is_instance_valid(_player):
		_player.advance_thunder_charge_aura(delta)


## Spinge la fascia corrente sull'aura del Player e annuncia il cambio di
## fascia. Va chiamata a ogni variazione della quota recuperabile (colpo,
## recupero, reset) cosi' l'aura resta il tell affidabile della passiva anche
## fuori dall'attivazione del Tuono (PS-003, D3).
func _refresh_thunder_charge_aura() -> void:
	if not is_instance_valid(_player):
		return
	if _definition == null or _definition.passive_id != ZAT_DELAYED_HEALING:
		_player.clear_thunder_charge_aura()
		_thunder_charge_tier = ThunderChargeAura.TIER_LOW
		return
	var tier := get_thunder_charge_tier()
	_player.set_thunder_charge_tier(tier)
	_player.set_thunder_charge_rotation_speed(_resolve_thunder_rotation_speed(tier))
	if tier != _thunder_charge_tier:
		_thunder_charge_tier = tier
		thunder_charge_tier_changed.emit(tier)


func _resolve_thunder_rotation_speed(tier: int) -> float:
	match tier:
		ThunderChargeAura.TIER_MEDIUM:
			return _definition.get_passive_float(&"aura_rotation_speed_medium", 1.4, 0.0)
		ThunderChargeAura.TIER_HIGH:
			return _definition.get_passive_float(&"aura_rotation_speed_high", 2.6, 0.0)
		_:
			return _definition.get_passive_float(&"aura_rotation_speed_low", 0.6, 0.0)


func _advance_alea_effect(delta: float) -> void:
	if _alea_effect_remaining > 0.0:
		_alea_effect_remaining = maxf(_alea_effect_remaining - delta, 0.0)
		if _alea_effect_remaining <= 0.0:
			_alea_move_multiplier = 1.0
			_alea_fire_multiplier = 1.0
			_apply_character_multipliers()
			_refresh_passive_state_tell()
	_alea_interval_remaining -= delta
	if _alea_interval_remaining > 0.0:
		return
	_alea_interval_remaining = _definition.get_passive_float(
		&"trigger_interval",
		12.0,
		AbilityDefinition.MINIMUM_POSITIVE_VALUE
	)
	_activate_alea_effect()


## La fortuna accumulata dalle kill si somma alla probabilita' base e viene
## spesa integralmente a ogni tiro: il giocatore puo' influenzare la scommessa
## invece di subirla.
func get_luck_bonus() -> float:
	return _alea_luck_bonus


func get_effective_positive_chance() -> float:
	if _definition == null or _definition.passive_id != ALEA_EAGLE_NEVER_MISSES:
		return 0.0
	var base_chance := _definition.get_passive_float(
		&"positive_chance",
		0.6,
		0.0,
		1.0
	)
	var chance_cap := _definition.get_passive_float(
		&"luck_chance_cap",
		0.95,
		0.0,
		1.0
	)
	return minf(base_chance + _alea_luck_bonus, chance_cap)


func _charge_alea_luck() -> void:
	var luck_per_kill := _definition.get_passive_float(
		&"luck_per_kill",
		0.0,
		0.0,
		1.0
	)
	if luck_per_kill <= 0.0:
		return
	var chance_cap := _definition.get_passive_float(
		&"luck_chance_cap",
		0.95,
		0.0,
		1.0
	)
	_alea_luck_bonus = minf(_alea_luck_bonus + luck_per_kill, chance_cap)
	luck_charge_changed.emit(_alea_luck_bonus)


func _activate_alea_effect() -> void:
	var positive := _rng.randf() < get_effective_positive_chance()
	_alea_luck_bonus = 0.0
	luck_charge_changed.emit(_alea_luck_bonus)
	var multiplier := _definition.get_passive_float(
		&"positive_multiplier" if positive else &"negative_multiplier",
		1.2 if positive else 0.9,
		MINIMUM_MULTIPLIER
	)
	var stat_id := &"move_speed" if _rng.randi_range(0, 1) == 0 else &"fire_rate"
	_alea_move_multiplier = multiplier if stat_id == &"move_speed" else 1.0
	_alea_fire_multiplier = multiplier if stat_id == &"fire_rate" else 1.0
	_alea_effect_remaining = _definition.get_passive_float(
		&"effect_duration",
		5.0,
		AbilityDefinition.MINIMUM_POSITIVE_VALUE
	)
	_apply_character_multipliers()
	_refresh_passive_state_tell()
	random_effect_started.emit(positive, stat_id, multiplier)


func _advance_lollo_hyperfocus(delta: float) -> void:
	_lollo_phase_remaining -= delta
	if _lollo_phase_remaining > 0.0:
		return
	_lollo_focused = not _lollo_focused
	_lollo_phase_remaining = _roll_lollo_phase_duration(_lollo_focused)
	_apply_character_multipliers()
	_refresh_passive_state_tell()
	hyperfocus_changed.emit(_lollo_focused, _lollo_phase_remaining)


## Le kill accorciano la fase distratta: la distrazione resta una fase reale
## ma diventa un'interazione invece di un pedaggio passivo. La fase di
## iperfocus non viene mai accorciata.
func _shorten_lollo_distraction() -> void:
	if _lollo_focused or _lollo_phase_remaining <= 0.0:
		return
	var reduction := _definition.get_passive_float(
		&"distraction_seconds_per_kill",
		0.0,
		0.0
	)
	if reduction <= 0.0:
		return
	_lollo_phase_remaining = maxf(_lollo_phase_remaining - reduction, 0.0)
	distraction_shortened.emit(_lollo_phase_remaining)


func _roll_lollo_phase_duration(focused: bool) -> float:
	var minimum := _definition.get_passive_float(
		&"focus_duration_min" if focused else &"distracted_duration_min",
		4.0 if focused else 3.0,
		AbilityDefinition.MINIMUM_POSITIVE_VALUE
	)
	var maximum := maxf(
		_definition.get_passive_float(
			&"focus_duration_max" if focused else &"distracted_duration_max",
			8.0 if focused else 6.0,
			AbilityDefinition.MINIMUM_POSITIVE_VALUE
		),
		minimum
	)
	return _rng.randf_range(minimum, maximum)


func _advance_aleo_thermostat(delta: float) -> void:
	var hot := _resolve_aleo_hot_mode()
	if hot != _aleo_hot:
		_aleo_hot = hot
		_apply_character_multipliers()
		_refresh_passive_state_tell()
		thermal_mode_changed.emit(_aleo_hot)
	if _aleo_hot:
		_clear_aleo_cold_aura()
		_aleo_cold_damage_accumulator = 0.0
		return
	_refresh_aleo_cold_aura()
	_advance_aleo_cold_damage(delta)


## Componente offensiva della fase fredda: l'aura non si limita a rallentare,
## ma erode i nemici che restano dentro. Scendere sotto meta' vita diventa
## cosi' una scelta tattica invece di un premio di consolazione, e il verbo
## resta distinto dall'amplificazione di Marghe.
func _advance_aleo_cold_damage(delta: float) -> void:
	var damage_per_second := _definition.get_passive_float(
		&"cold_aura_damage_per_second",
		0.0,
		0.0
	)
	var tick_interval := _definition.get_passive_float(
		&"cold_aura_tick_interval",
		0.25,
		AbilityDefinition.MINIMUM_POSITIVE_VALUE
	)
	if damage_per_second <= 0.0 or _aleo_chilled_targets.is_empty():
		_aleo_cold_damage_accumulator = 0.0
		return
	_aleo_cold_damage_accumulator += delta
	if _aleo_cold_damage_accumulator < tick_interval:
		return
	var elapsed := _aleo_cold_damage_accumulator
	_aleo_cold_damage_accumulator = 0.0
	var tick_damage := damage_per_second * elapsed
	if tick_damage <= 0.0:
		return
	for target in _aleo_chilled_targets:
		if is_instance_valid(target) and target.is_alive():
			target.take_damage(tick_damage)


func get_cold_damage_accumulator() -> float:
	return _aleo_cold_damage_accumulator


func get_chilled_target_count() -> int:
	var count := 0
	for target in _aleo_chilled_targets:
		if is_instance_valid(target):
			count += 1
	return count


func is_thermal_hot() -> bool:
	return _aleo_hot


func _resolve_aleo_hot_mode() -> bool:
	if not is_instance_valid(_player):
		return true
	var health := _player.get_health_component()
	if health == null or health.health_max <= 0.0:
		return true
	var threshold := _definition.get_passive_float(&"hot_threshold", 0.5, 0.0, 1.0)
	return health.health_current > health.health_max * threshold


func _refresh_aleo_cold_aura() -> void:
	var radius := _definition.get_passive_float(&"cold_aura_radius", 0.0, 0.0)
	var slow_factor := _definition.get_passive_float(
		&"cold_slow_factor",
		1.0,
		MINIMUM_MULTIPLIER,
		1.0
	)
	if (
		radius <= 0.0
		or slow_factor >= 1.0
		or not is_instance_valid(_player)
		or not is_instance_valid(_targeting_system)
	):
		_clear_aleo_cold_aura()
		return
	var inside: Array[BaseEnemy] = []
	for target in _targeting_system.get_alive_targets():
		if not AbilityEffectRegistry.is_point_within_radius(
			_player.global_position,
			target.global_position,
			radius
		):
			continue
		target.set_speed_modifier(ALEO_COLD_AURA_MODIFIER, slow_factor)
		inside.append(target)
	for target in _aleo_chilled_targets:
		if is_instance_valid(target) and not target in inside:
			target.remove_speed_modifier(ALEO_COLD_AURA_MODIFIER)
	_aleo_chilled_targets = inside


func _clear_aleo_cold_aura() -> void:
	for target in _aleo_chilled_targets:
		if is_instance_valid(target):
			target.remove_speed_modifier(ALEO_COLD_AURA_MODIFIER)
	_aleo_chilled_targets.clear()


func _advance_migi_shield(delta: float) -> void:
	_shield_cooldown_remaining = maxf(_shield_cooldown_remaining - delta, 0.0)
	if _shield_remaining <= 0.0:
		return
	_shield_remaining = maxf(_shield_remaining - delta, 0.0)
	if _shield_remaining <= 0.0:
		_shield_hits_remaining = 0
		shield_changed.emit(false, 0.0)
		_refresh_passive_state_tell()


func _activate_migi_shield() -> void:
	_shield_remaining = _definition.get_passive_float(
		&"shield_duration",
		4.0,
		AbilityDefinition.MINIMUM_POSITIVE_VALUE
	)
	_shield_hits_remaining = _definition.get_passive_int(&"shield_hits", 1, 1)
	_shield_cooldown_remaining = _definition.get_passive_float(
		&"shield_cooldown",
		20.0,
		AbilityDefinition.MINIMUM_POSITIVE_VALUE
	)
	shield_changed.emit(true, _shield_remaining)
	_refresh_passive_state_tell()


func _advance_bea_dodge_cooldown(delta: float) -> void:
	_bea_dodge_cooldown_remaining = maxf(_bea_dodge_cooldown_remaining - delta, 0.0)


func get_bea_dodge_cooldown_remaining() -> float:
	return _bea_dodge_cooldown_remaining


## Guscio piccolo di Migi (B45): cariche che annullano un colpo intero,
## rigenerate nel tempo fino al tetto dichiarato. Scala minore e piu'
## frequente rispetto al guscio grande (lo scudo d'emergenza sotto soglia
## HP), coerente con l'identita' "Tartarughina" a scale crescenti.
func _advance_migi_shell_charges(delta: float) -> void:
	var max_charges := _definition.get_passive_int(&"shell_charge_max", 2, 0)
	if _migi_shell_charges >= max_charges:
		_migi_shell_regen_remaining = 0.0
		return
	_migi_shell_regen_remaining -= delta
	if _migi_shell_regen_remaining > 0.0:
		return
	_migi_shell_charges += 1
	_migi_shell_regen_remaining = _definition.get_passive_float(
		&"shell_charge_regen_seconds",
		12.0,
		AbilityDefinition.MINIMUM_POSITIVE_VALUE
	)
	migi_shell_charges_changed.emit(_migi_shell_charges, max_charges)
	_refresh_passive_state_tell()


func get_migi_shell_charges() -> int:
	return _migi_shell_charges


func get_migi_shell_charge_max() -> int:
	return _definition.get_passive_int(&"shell_charge_max", 2, 0) if _definition != null else 0


## Traduce la fase corrente della passiva nel tell visivo del Player. E'
## puramente presentazionale: nessun ramo qui dentro tocca statistiche,
## collisioni o timing.
func _refresh_passive_state_tell() -> void:
	if not is_instance_valid(_player):
		return
	if _definition == null:
		_player.clear_passive_state_tell()
		return
	var tell_color := TELL_NEUTRAL
	match _definition.passive_id:
		ALEO_INTERNAL_THERMOSTAT:
			tell_color = TELL_ALEO_HOT if _aleo_hot else TELL_ALEO_COLD
		LOLLO_HYPERACTIVITY:
			tell_color = TELL_LOLLO_FOCUSED if _lollo_focused else TELL_LOLLO_DISTRACTED
		ALEA_EAGLE_NEVER_MISSES:
			if _alea_effect_remaining > 0.0:
				var positive := (
					_alea_move_multiplier > 1.0
					or _alea_fire_multiplier > 1.0
				)
				tell_color = TELL_ALEA_POSITIVE if positive else TELL_ALEA_NEGATIVE
		MIGI_TURTLE_SHELL:
			if is_shield_active():
				tell_color = TELL_MIGI_SHIELD
			elif _migi_shell_charges > 0:
				tell_color = TELL_MIGI_SHELL_READY
	if tell_color == TELL_NEUTRAL:
		_player.clear_passive_state_tell()
	else:
		_player.set_passive_state_tell(tell_color)


func _apply_character_multipliers() -> void:
	if not _has_valid_dependencies():
		return
	var move_multiplier := 1.0
	var fire_multiplier := 1.0
	var damage_multiplier := 1.0
	if _definition != null:
		match _definition.passive_id:
			ALEO_INTERNAL_THERMOSTAT:
				if _aleo_hot:
					damage_multiplier = _definition.get_passive_float(
						&"hot_damage_multiplier",
						1.0,
						MINIMUM_MULTIPLIER
					)
			MAGNO_AERODYNAMIC_FLOW:
				var base_multiplier := _definition.get_passive_float(
					&"move_speed_multiplier",
					1.0,
					MINIMUM_MULTIPLIER
				)
				var max_multiplier := maxf(
					_definition.get_passive_float(
						&"max_move_speed_multiplier",
						base_multiplier,
						MINIMUM_MULTIPLIER
					),
					base_multiplier
				)
				var momentum_ratio := (
					_player.get_momentum_ratio() if is_instance_valid(_player) else 0.0
				)
				move_multiplier = lerpf(base_multiplier, max_multiplier, momentum_ratio)
			LOLLO_HYPERACTIVITY:
				move_multiplier = _definition.get_passive_float(
					(
						&"focus_move_speed_multiplier"
						if _lollo_focused
						else &"distracted_move_speed_multiplier"
					),
					1.0,
					MINIMUM_MULTIPLIER
				)
				fire_multiplier = _definition.get_passive_float(
					(
						&"focus_fire_rate_multiplier"
						if _lollo_focused
						else &"distracted_fire_rate_multiplier"
					),
					1.0,
					MINIMUM_MULTIPLIER
				)
			ALEA_EAGLE_NEVER_MISSES:
				move_multiplier = _alea_move_multiplier
				fire_multiplier = _alea_fire_multiplier
	# Gli scarti di partenza B47 compongono moltiplicativamente con la passiva
	# e restano neutri per i profili che non li dichiarano.
	var health_multiplier := 1.0
	if _definition != null:
		move_multiplier *= _definition.get_base_move_speed_multiplier()
		fire_multiplier *= _definition.get_base_fire_rate_multiplier()
		health_multiplier = _definition.get_base_health_multiplier()
	_player.set_character_stat_multipliers(move_multiplier, 1.0, health_multiplier)
	_weapon_controller.set_character_stat_multipliers(fire_multiplier, damage_multiplier)


## Aura di indebolimento: i nemici dentro il raggio subiscono piu' danno da
## qualsiasi sorgente, arma e abilita' comprese. Sostituisce la riduzione di
## salute massima pre-B42, che a 18 HP non cambiava il numero di colpi
## necessari e restava quindi invisibile in partita.
func _refresh_marghe_aura() -> void:
	var radius := _definition.get_passive_float(&"aura_radius", 0.0, 0.0)
	var damage_multiplier := _definition.get_passive_float(
		&"damage_taken_multiplier",
		1.0,
		1.0
	)
	if (
		radius <= 0.0
		or damage_multiplier <= 1.0
		or not is_instance_valid(_player)
		or not is_instance_valid(_targeting_system)
	):
		_clear_marghe_aura()
		return
	var affects_bosses := _definition.get_passive_bool(&"affects_bosses", false)
	var inside: Array[BaseEnemy] = []
	for target in _targeting_system.get_alive_targets():
		if target.is_in_group(&"bosses") and not affects_bosses:
			continue
		if not AbilityEffectRegistry.is_point_within_radius(
			_player.global_position,
			target.global_position,
			radius
		):
			continue
		target.set_damage_taken_modifier(MARGHE_SMILE_MODIFIER, damage_multiplier)
		inside.append(target)
	for target in _marghe_marked_targets:
		if is_instance_valid(target) and not target in inside:
			target.remove_damage_taken_modifier(MARGHE_SMILE_MODIFIER)
	var changed := inside.size() != _marghe_marked_targets.size()
	_marghe_marked_targets = inside
	if changed:
		marked_targets_changed.emit(_marghe_marked_targets.size())


func _clear_marghe_aura() -> void:
	if _marghe_marked_targets.is_empty():
		return
	for target in _marghe_marked_targets:
		if is_instance_valid(target):
			target.remove_damage_taken_modifier(MARGHE_SMILE_MODIFIER)
	_marghe_marked_targets.clear()
	marked_targets_changed.emit(0)


func get_marked_target_count() -> int:
	var count := 0
	for target in _marghe_marked_targets:
		if is_instance_valid(target):
			count += 1
	return count


func _reset_runtime(seed_value: int) -> void:
	_rng.seed = seed_value if seed_value != 0 else 1
	_recoverable_health = 0.0
	_recovery_delay_remaining = 0.0
	_recovery_duration_remaining = 0.0
	_shield_remaining = 0.0
	_shield_cooldown_remaining = 0.0
	_shield_hits_remaining = 0
	_alea_effect_remaining = 0.0
	_alea_move_multiplier = 1.0
	_alea_fire_multiplier = 1.0
	_alea_luck_bonus = 0.0
	_clear_aleo_cold_aura()
	_clear_marghe_aura()
	_aleo_cold_damage_accumulator = 0.0
	_aleo_hot = true
	_alea_interval_remaining = (
		_definition.get_passive_float(
			&"trigger_interval",
			12.0,
			AbilityDefinition.MINIMUM_POSITIVE_VALUE
		)
		if _definition != null and _definition.passive_id == ALEA_EAGLE_NEVER_MISSES
		else 0.0
	)
	_lollo_focused = true
	_lollo_phase_remaining = 0.0
	if _definition != null and _definition.passive_id == LOLLO_HYPERACTIVITY:
		_lollo_phase_remaining = _roll_lollo_phase_duration(_lollo_focused)
		hyperfocus_changed.emit(_lollo_focused, _lollo_phase_remaining)
	_bea_dodge_cooldown_remaining = 0.0
	var migi_shell_max := (
		_definition.get_passive_int(&"shell_charge_max", 2, 0)
		if _definition != null and _definition.passive_id == MIGI_TURTLE_SHELL
		else 0
	)
	_migi_shell_charges = migi_shell_max
	_migi_shell_regen_remaining = (
		_definition.get_passive_float(
			&"shell_charge_regen_seconds",
			12.0,
			AbilityDefinition.MINIMUM_POSITIVE_VALUE
		)
		if migi_shell_max > 0
		else 0.0
	)
	migi_shell_charges_changed.emit(_migi_shell_charges, migi_shell_max)
	if is_instance_valid(_player):
		_player.set_momentum_trail_enabled(
			_definition != null and _definition.passive_id == MAGNO_AERODYNAMIC_FLOW
		)
	_apply_character_multipliers()
	_refresh_passive_state_tell()
	if _definition != null and _definition.passive_id == MARGHE_CONTAGIOUS_SMILE:
		_refresh_marghe_aura()
	_refresh_thunder_charge_aura()
	delayed_healing_changed.emit(0.0)
	shield_changed.emit(false, 0.0)
	luck_charge_changed.emit(_alea_luck_bonus)


func _has_valid_dependencies() -> bool:
	return (
		is_instance_valid(_run_controller)
		and is_instance_valid(_player)
		and is_instance_valid(_weapon_controller)
		and is_instance_valid(_targeting_system)
	)


func _disconnect_dependencies() -> void:
	if is_instance_valid(_player):
		_player.clear_passive_state_tell()
		_player.clear_thunder_charge_aura()
		_player.set_momentum_trail_enabled(false)
		if _player.damaged.is_connected(_on_player_damaged):
			_player.damaged.disconnect(_on_player_damaged)
		if _player.get_passive_controller() == self:
			_player.set_passive_controller(null)
	if (
		is_instance_valid(_targeting_system)
		and _targeting_system.target_registered.is_connected(_on_target_registered)
	):
		_targeting_system.target_registered.disconnect(_on_target_registered)
	if is_instance_valid(_run_controller):
		if _run_controller.run_started.is_connected(_on_run_started):
			_run_controller.run_started.disconnect(_on_run_started)
		if _run_controller.restart_prepared.is_connected(_on_restart_prepared):
			_run_controller.restart_prepared.disconnect(_on_restart_prepared)
	_run_controller = null
	_player = null
	_weapon_controller = null
	_targeting_system = null


func _on_player_damaged(_player_value: Player, amount: float, _health_current: float) -> void:
	if _definition == null:
		return
	if _definition.passive_id == ZAT_DELAYED_HEALING:
		_recoverable_health += amount * _definition.get_passive_float(
			&"recoverable_fraction",
			0.0,
			0.0,
			1.0
		)
		_recovery_delay_remaining = _definition.get_passive_float(
			&"recovery_delay",
			3.0,
			0.0
		)
		_recovery_duration_remaining = _definition.get_passive_float(
			&"recovery_duration",
			4.0,
			AbilityDefinition.MINIMUM_POSITIVE_VALUE
		)
		delayed_healing_changed.emit(_recoverable_health)
		_refresh_thunder_charge_aura()
	elif (
		_definition.passive_id == MIGI_TURTLE_SHELL
		and _shield_cooldown_remaining <= 0.0
		and not is_shield_active()
	):
		var health := _player.get_health_component()
		var threshold := _definition.get_passive_float(
			&"shield_health_threshold",
			0.35,
			0.0,
			1.0
		)
		if health != null and health.health_current / health.health_max <= threshold:
			_activate_migi_shield()


## Le passive che reagiscono alle kill si agganciano al singolo nemico allo
## spawn: la connessione muore insieme al nodo, quindi non serve pulizia
## esplicita oltre a quella gia' prevista dal targeting.
func _on_target_registered(target: BaseEnemy) -> void:
	if _definition == null or not is_instance_valid(target):
		return
	if not _reacts_to_kills():
		return
	if not target.died.is_connected(_on_target_died):
		target.died.connect(_on_target_died)


func _on_target_died(_target: BaseEnemy) -> void:
	if (
		_definition == null
		or not is_instance_valid(_run_controller)
		or not _run_controller.is_running()
	):
		return
	match _definition.passive_id:
		ALEA_EAGLE_NEVER_MISSES:
			_charge_alea_luck()
		LOLLO_HYPERACTIVITY:
			_shorten_lollo_distraction()


func _reacts_to_kills() -> bool:
	return _definition != null and _definition.passive_id in [
		ALEA_EAGLE_NEVER_MISSES,
		LOLLO_HYPERACTIVITY,
	]


func _on_run_started(seed_value: int) -> void:
	_reset_runtime(seed_value)


func _on_restart_prepared() -> void:
	_reset_runtime(1)
