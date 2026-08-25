class_name FriendDefinition
extends Resource

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
