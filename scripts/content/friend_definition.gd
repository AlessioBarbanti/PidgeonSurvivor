class_name FriendDefinition
extends Resource

## Intervallo consentito agli scarti di statistiche base per profilo. Il
## limite tiene gli scarti nell'ordine di grandezza dichiarato dalla linea
## guida di design e impedisce che un dato malformato sostituisca la baseline.
const MINIMUM_BASE_STAT_MULTIPLIER := 0.5
const MAXIMUM_BASE_STAT_MULTIPLIER := 2.0

@export_group("Identity")
@export var id: StringName = &""
@export var display_name := ""
@export_multiline var role := ""
@export var tags: Array[StringName] = []

@export_group("Gameplay Identity")
@export var passive_title := ""
@export_multiline var passive_description := ""
@export var passive_id: StringName = &""
@export var passive_parameters: Dictionary = {}
@export var active_ability_id: StringName = &""
@export var active_ability_title := ""
@export_multiline var active_ability_description := ""

## Scarti di partenza dichiarati per profilo (B47). Il default neutro `1.0`
## lascia un profilo non aggiornato identico alla baseline condivisa; i valori
## compongono moltiplicativamente con passive e upgrade senza mutare i dati
## base di Player e arma.
@export_group("Base Stats")
@export_range(
	MINIMUM_BASE_STAT_MULTIPLIER,
	MAXIMUM_BASE_STAT_MULTIPLIER,
	0.01
) var base_health_multiplier := 1.0
@export_range(
	MINIMUM_BASE_STAT_MULTIPLIER,
	MAXIMUM_BASE_STAT_MULTIPLIER,
	0.01
) var base_move_speed_multiplier := 1.0
@export_range(
	MINIMUM_BASE_STAT_MULTIPLIER,
	MAXIMUM_BASE_STAT_MULTIPLIER,
	0.01
) var base_fire_rate_multiplier := 1.0

## Assi estesi (PS-093): stesso pattern dei tre assi B47 sopra — default
## neutro `1.0`, stesso range, compongono moltiplicativamente con l'upgrade
## corrispondente del catalogo (stadio "character" + stadio "upgrade", mai un
## unico campo condiviso) senza mutare i dati base condivisi.
@export_range(
	MINIMUM_BASE_STAT_MULTIPLIER,
	MAXIMUM_BASE_STAT_MULTIPLIER,
	0.01
) var base_damage_multiplier := 1.0
@export_range(
	MINIMUM_BASE_STAT_MULTIPLIER,
	MAXIMUM_BASE_STAT_MULTIPLIER,
	0.01
) var base_xp_gain_multiplier := 1.0
@export_range(
	MINIMUM_BASE_STAT_MULTIPLIER,
	MAXIMUM_BASE_STAT_MULTIPLIER,
	0.01
) var base_pickup_radius_multiplier := 1.0
@export_range(
	MINIMUM_BASE_STAT_MULTIPLIER,
	MAXIMUM_BASE_STAT_MULTIPLIER,
	0.01
) var base_damage_taken_multiplier := 1.0
## Probabilità critica (PS-093): additivo in punti percentuali, non un
## moltiplicatore — una probabilità non ha una baseline `×1,0` da scalare.
## Si compone per somma con l'eventuale carta catalogo "Salamoia Bolognese",
## poi il totale viene sempre limitato al cap dichiarato da
## `WeaponController` (`MAXIMUM_CRITICAL_CHANCE`).
@export_range(0.0, 1.0, 0.01) var base_critical_chance_bonus := 0.0

@export_group("Evil Counterpart")
@export var evil_display_name := ""

@export_group("Replaceable Assets")
@export var portrait: Texture2D
@export var evil_portrait: Texture2D
@export var portrait_placeholder: Texture2D
@export var evil_portrait_placeholder: Texture2D
@export var portrait_source := ""
@export var portraits_are_placeholders := true
@export var voice_clip: AudioStream

@export_group("Frontend Portrait")
@export var selection_portrait: Texture2D
@export var passive_icon: Texture2D

@export_group("Gameplay Sprite")
@export var gameplay_idle_right: Texture2D
@export var gameplay_walk_right_frames: Array[Texture2D] = []
@export_range(1.0, 30.0, 0.5) var gameplay_walk_fps := 8.0

@export_group("Safe Copy Fallbacks")
@export var safe_display_name := "Personaggio"
@export_multiline var safe_role := "Profilo in aggiornamento."
@export var safe_passive_title := "Passiva"
@export_multiline var safe_passive_description := "Descrizione in aggiornamento."
@export var safe_active_ability_title := "Abilità attiva"
@export_multiline var safe_active_ability_description := "Descrizione in aggiornamento."
@export var safe_evil_display_name := "Evil Friend"

@export_group("Publication Approval")
@export var content_approved := false
@export var portraits_approved := false
@export var audio_approved := false
@export var approved_by := ""
@export var approval_date := ""
@export_multiline var approval_reference := ""


func is_valid() -> bool:
	if (
		not is_valid_id(id)
		or display_name.strip_edges().is_empty()
		or role.strip_edges().is_empty()
		or passive_title.strip_edges().is_empty()
		or passive_description.strip_edges().is_empty()
		or not is_valid_id(passive_id)
		or not is_valid_id(active_ability_id)
		or active_ability_title.strip_edges().is_empty()
		or active_ability_description.strip_edges().is_empty()
		or evil_display_name.strip_edges().is_empty()
		or safe_display_name.strip_edges().is_empty()
		or safe_role.strip_edges().is_empty()
		or safe_passive_title.strip_edges().is_empty()
		or safe_passive_description.strip_edges().is_empty()
		or safe_active_ability_title.strip_edges().is_empty()
		or safe_active_ability_description.strip_edges().is_empty()
		or safe_evil_display_name.strip_edges().is_empty()
		or portrait_placeholder == null
		or evil_portrait_placeholder == null
	):
		return false

	var seen_tags: Dictionary = {}
	for tag in tags:
		if not is_valid_id(tag) or seen_tags.has(tag):
			return false
		seen_tags[tag] = true

	if portraits_approved and (portrait == null or evil_portrait == null):
		return false
	if audio_approved and voice_clip == null:
		return false
	if (
		(content_approved or portraits_approved or audio_approved)
		and not has_valid_approval_record()
	):
		return false
	return true


func is_publication_ready() -> bool:
	return (
		is_valid()
		and content_approved
		and portraits_approved
		and (voice_clip == null or audio_approved)
	)


func has_valid_approval_record() -> bool:
	return (
		not approved_by.strip_edges().is_empty()
		and _is_iso_date(approval_date)
		and not approval_reference.strip_edges().is_empty()
	)


func get_public_display_name() -> String:
	return display_name.strip_edges() if content_approved else safe_display_name.strip_edges()


func get_public_role() -> String:
	return role.strip_edges() if content_approved else safe_role.strip_edges()


func get_public_passive_title() -> String:
	return passive_title.strip_edges() if content_approved else safe_passive_title.strip_edges()


func get_public_passive_description() -> String:
	return (
		passive_description.strip_edges()
		if content_approved
		else safe_passive_description.strip_edges()
	)


func get_passive_float(
	parameter_name: StringName,
	default_value: float = 0.0,
	minimum_value: float = -INF,
	maximum_value: float = INF
) -> float:
	var raw_value: Variant = passive_parameters.get(parameter_name, default_value)
	var parsed_value := float(raw_value)
	if not is_finite(parsed_value):
		parsed_value = default_value
	return clampf(parsed_value, minimum_value, maximum_value)


func get_passive_int(
	parameter_name: StringName,
	default_value: int = 0,
	minimum_value: int = -2147483648,
	maximum_value: int = 2147483647
) -> int:
	return clampi(
		int(passive_parameters.get(parameter_name, default_value)),
		minimum_value,
		maximum_value
	)


func get_passive_bool(parameter_name: StringName, default_value: bool = false) -> bool:
	return bool(passive_parameters.get(parameter_name, default_value))


func get_base_health_multiplier() -> float:
	return _sanitize_base_stat_multiplier(base_health_multiplier)


func get_base_move_speed_multiplier() -> float:
	return _sanitize_base_stat_multiplier(base_move_speed_multiplier)


func get_base_fire_rate_multiplier() -> float:
	return _sanitize_base_stat_multiplier(base_fire_rate_multiplier)


func get_base_damage_multiplier() -> float:
	return _sanitize_base_stat_multiplier(base_damage_multiplier)


func get_base_xp_gain_multiplier() -> float:
	return _sanitize_base_stat_multiplier(base_xp_gain_multiplier)


func get_base_pickup_radius_multiplier() -> float:
	return _sanitize_base_stat_multiplier(base_pickup_radius_multiplier)


func get_base_damage_taken_multiplier() -> float:
	return _sanitize_base_stat_multiplier(base_damage_taken_multiplier)


## Additivo in punti percentuali (0.0-1.0), non un moltiplicatore: niente
## baseline `1.0` da cui scostarsi, un dato malformato o fuori range collassa
## semplicemente a "nessuno scarto" invece che alla baseline neutra dei
## quattro assi moltiplicativi sopra.
func get_base_critical_chance_bonus() -> float:
	if not is_finite(base_critical_chance_bonus):
		return 0.0
	return clampf(base_critical_chance_bonus, 0.0, 1.0)


## Vero quando il profilo dichiara almeno uno scarto diverso dalla baseline
## condivisa, così i consumatori possono distinguere un profilo neutro da uno
## caratterizzato senza confrontare i tre valori a mano.
func has_base_stat_spread() -> bool:
	return (
		not is_equal_approx(get_base_health_multiplier(), 1.0)
		or not is_equal_approx(get_base_move_speed_multiplier(), 1.0)
		or not is_equal_approx(get_base_fire_rate_multiplier(), 1.0)
	)


## Come `has_base_stat_spread()`, ma sui cinque assi estesi di PS-093
## (i quattro moltiplicativi e la probabilità critica additiva).
func has_extended_base_stat_spread() -> bool:
	return (
		not is_equal_approx(get_base_damage_multiplier(), 1.0)
		or not is_equal_approx(get_base_xp_gain_multiplier(), 1.0)
		or not is_equal_approx(get_base_pickup_radius_multiplier(), 1.0)
		or not is_equal_approx(get_base_damage_taken_multiplier(), 1.0)
		or get_base_critical_chance_bonus() > 0.0
	)


func get_public_active_ability_title() -> String:
	return (
		active_ability_title.strip_edges()
		if content_approved
		else safe_active_ability_title.strip_edges()
	)


func get_public_active_ability_description() -> String:
	return (
		active_ability_description.strip_edges()
		if content_approved
		else safe_active_ability_description.strip_edges()
	)


func get_public_evil_display_name() -> String:
	return (
		evil_display_name.strip_edges()
		if content_approved
		else safe_evil_display_name.strip_edges()
	)


func get_public_portrait() -> Texture2D:
	return portrait if portraits_approved and portrait != null else portrait_placeholder


func get_public_selection_portrait() -> Texture2D:
	return selection_portrait if selection_portrait != null else get_public_portrait()


func get_public_passive_icon() -> Texture2D:
	return passive_icon if passive_icon != null else get_public_selection_portrait()


func get_public_evil_portrait() -> Texture2D:
	return (
		evil_portrait
		if portraits_approved and evil_portrait != null
		else evil_portrait_placeholder
	)


func get_public_voice_clip() -> AudioStream:
	return voice_clip if audio_approved else null


func get_gameplay_idle_right() -> Texture2D:
	return gameplay_idle_right if gameplay_idle_right != null else get_public_portrait()


func get_gameplay_walk_right_frames() -> Array[Texture2D]:
	var valid_frames: Array[Texture2D] = []
	for frame in gameplay_walk_right_frames:
		if frame != null:
			valid_frames.append(frame)
	if valid_frames.is_empty():
		var idle_frame := get_gameplay_idle_right()
		if idle_frame != null:
			valid_frames.append(idle_frame)
	return valid_frames


func has_directional_gameplay_animation() -> bool:
	return (
		get_gameplay_idle_right() != null
		and get_gameplay_walk_right_frames().size() >= 2
		and is_finite(gameplay_walk_fps)
		and gameplay_walk_fps > 0.0
	)


static func _sanitize_base_stat_multiplier(value: float) -> float:
	if not is_finite(value):
		return 1.0
	return clampf(
		value,
		MINIMUM_BASE_STAT_MULTIPLIER,
		MAXIMUM_BASE_STAT_MULTIPLIER
	)


static func is_valid_id(value: StringName) -> bool:
	var text := String(value)
	return (
		not text.is_empty()
		and text == text.to_lower()
		and text.is_valid_identifier()
	)


static func _is_iso_date(value: String) -> bool:
	var parts := value.split("-", false)
	if parts.size() != 3 or parts[0].length() != 4 or parts[1].length() != 2 or parts[2].length() != 2:
		return false
	if not parts[0].is_valid_int() or not parts[1].is_valid_int() or not parts[2].is_valid_int():
		return false
	var year := int(parts[0])
	var month := int(parts[1])
	var day := int(parts[2])
	return year >= 2000 and month >= 1 and month <= 12 and day >= 1 and day <= 31
