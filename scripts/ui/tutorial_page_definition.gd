class_name TutorialPageDefinition
extends Resource

@export var id: StringName
@export var eyebrow: String
@export var title: String
@export_multiline var body: String
@export var artwork: Texture2D
@export var showcase_textures: Array[Texture2D] = []
@export var showcase_labels: Array[String] = []


func is_valid() -> bool:
	if (
		id.is_empty()
		or eyebrow.strip_edges().is_empty()
		or title.strip_edges().is_empty()
		or body.strip_edges().is_empty()
	):
		return false
	if artwork == null and showcase_textures.is_empty():
		return false
	if showcase_textures.size() != showcase_labels.size():
		return false
	for index in showcase_textures.size():
		if showcase_textures[index] == null or showcase_labels[index].strip_edges().is_empty():
			return false
	return true
