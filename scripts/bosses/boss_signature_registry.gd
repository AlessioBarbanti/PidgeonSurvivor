class_name BossSignatureRegistry
extends RefCounted

## Registro delle Signature Evil (PS-006): dichiara quali comportamenti
## esistono, quali parametri ciascuno pretende e come si risolve la copia
## seedata di Evil Lollo.
##
## Come per `AbilityEffectRegistry`, i file dati si limitano a dichiarare un
## `effect_id` piu' i parametri: nessuna logica vive nei `.tres`.

const TELLURIC_SHOCKWAVE := &"boss_telluric_shockwave"
const POWERSLIDE := &"boss_powerslide"
const THUNDER_STORM := &"boss_thunder_storm"
const GRAND_SPIN := &"boss_grand_spin"
const THERMAL_SHOCK := &"boss_thermal_shock"
const RANDOM_COSPLAY := &"boss_random_cosplay"
const ZEN_SLOWDOWN := &"boss_zen_slowdown"
const REGGAETON_CLONE := &"boss_reggaeton_clone"

const COPY_SEED_SALT := 0x10110C05
const COPY_SEED_FACTOR := 0x27220A95
const COPY_USE_FACTOR := 0x5F356495

## Forma persistente lasciata a terra dalla Signature. `NONE` vale per le
## Signature che non spawnano un'area (il clone di Marghe).
enum AreaMode {
	NONE,
	## Fronte anulare che si espande dall'origine: danno e knockback una sola
	## volta, quando il fronte attraversa il Player.
	EXPANDING_FRONT,
	## Corridoio statico lungo la traiettoria del Powerslide: danno nel tempo.
	TRAIL_CORRIDOR,
	## Aura ancorata al Boss che pulsa danno da contatto.
	FOLLOWING_CONTACT,
	## Area statica in due fasi: prima rallenta, poi detona.
	TWO_PHASE_BURST,
	## Aura ancorata al Boss: rallenta il Player e assorbe i proiettili
	## alleati, senza mai infliggere danno.
	FOLLOWING_SLOW_ABSORB,
	## Colpo radiale istantaneo all'esecuzione, con coda solo visiva.
	INSTANT_BURST,
}

const _EFFECT_AREA_MODES := {
	TELLURIC_SHOCKWAVE: AreaMode.EXPANDING_FRONT,
	POWERSLIDE: AreaMode.TRAIL_CORRIDOR,
	THUNDER_STORM: AreaMode.INSTANT_BURST,
	GRAND_SPIN: AreaMode.FOLLOWING_CONTACT,
	THERMAL_SHOCK: AreaMode.TWO_PHASE_BURST,
	RANDOM_COSPLAY: AreaMode.NONE,
	ZEN_SLOWDOWN: AreaMode.FOLLOWING_SLOW_ABSORB,
	REGGAETON_CLONE: AreaMode.NONE,
}

const _REQUIRED_PARAMETERS := {
	TELLURIC_SHOCKWAVE: [&"expansion_speed", &"front_thickness", &"knockback_force"],
	POWERSLIDE: [&"dash_distance", &"dash_speed", &"dot_tick"],
	THUNDER_STORM: [&"medium_tier_multiplier", &"high_tier_multiplier"],
	GRAND_SPIN: [&"hits_per_second", &"chase_speed", &"turn_rate"],
	THERMAL_SHOCK: [&"cold_seconds", &"slow_factor"],
	RANDOM_COSPLAY: [],
	ZEN_SLOWDOWN: [&"slow_factor"],
	REGGAETON_CLONE: [&"clone_health", &"clone_offset"],
}


static func get_supported_effect_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for effect_id: StringName in _EFFECT_AREA_MODES.keys():
		ids.append(effect_id)
	return ids


static func is_supported(effect_id: StringName) -> bool:
	return _EFFECT_AREA_MODES.has(effect_id)


## Evil Lollo non puo' copiare se stesso: escludere `RANDOM_COSPLAY` dai
## candidati e' l'unica regola che serve per impedire la ricorsione.
static func is_copyable(effect_id: StringName) -> bool:
	return is_supported(effect_id) and effect_id != RANDOM_COSPLAY


static func get_area_mode(effect_id: StringName) -> AreaMode:
	if not is_supported(effect_id):
		return AreaMode.NONE
	return _EFFECT_AREA_MODES[effect_id] as AreaMode


## Le Signature che muovono il Boss stesso invece di lasciare solo un'area.
static func moves_boss(effect_id: StringName) -> bool:
	return effect_id == POWERSLIDE or effect_id == GRAND_SPIN


static func spawns_decoy(effect_id: StringName) -> bool:
	return effect_id == REGGAETON_CLONE


static func has_required_parameters(definition: BossSignatureDefinition) -> bool:
	if definition == null or not is_supported(definition.effect_id):
		return false
	for parameter_name: StringName in _REQUIRED_PARAMETERS[definition.effect_id]:
		if not definition.effect_parameters.has(parameter_name):
			return false
		if not is_finite(float(definition.effect_parameters[parameter_name])):
			return false
	return true


## Candidati copiabili da Evil Lollo, in ordine stabile: la lista non dipende
## dall'ordine di visita di un dizionario, cosi' lo stesso seed sceglie sempre
## la stessa Signature.
static func get_copy_candidates(
	catalog_signatures: Array[BossSignatureDefinition]
) -> Array[BossSignatureDefinition]:
	var candidates: Array[BossSignatureDefinition] = []
	for signature in catalog_signatures:
		if (
			signature == null
			or not signature.is_valid()
			or not is_copyable(signature.effect_id)
		):
			continue
		candidates.append(signature)
	candidates.sort_custom(_compare_signature_ids)
	return candidates


## Estrazione deterministica della copia: dipende solo dal seed della run,
## dall'indice della soglia Boss e da quante volte la Signature e' gia' stata
## usata in questo incontro.
static func select_copy(
	catalog_signatures: Array[BossSignatureDefinition],
	run_seed: int,
	schedule_index: int,
	use_index: int
) -> BossSignatureDefinition:
	var candidates := get_copy_candidates(catalog_signatures)
	if candidates.is_empty():
		return null
	var rng := RandomNumberGenerator.new()
	rng.seed = (
		run_seed
		^ COPY_SEED_SALT
		^ ((schedule_index + 1) * COPY_SEED_FACTOR)
		^ ((use_index + 1) * COPY_USE_FACTOR)
	)
	return candidates[rng.randi_range(0, candidates.size() - 1)]


static func _compare_signature_ids(
	left: BossSignatureDefinition,
	right: BossSignatureDefinition
) -> bool:
	return String(left.id) < String(right.id)
