class_name TutorialPageDefinition
extends Resource

## Layout della vetrina illustrata di una pagina tutorial.
## `GRID_2X2` dispone quattro icone in matrice; `WALKERS_2_3` dispone cinque
## sprite-strip camminanti su due file (due sopra, tre sotto).
enum ShowcaseLayout {
	GRID_2X2,
	WALKERS_2_3,
}

const GRID_ITEM_COUNT := 4
const WALKERS_ITEM_COUNT := 5

@export var id: StringName
@export var eyebrow: String
@export var title: String
@export_multiline var body: String
@export var artwork: Texture2D
@export var showcase_layout: ShowcaseLayout = ShowcaseLayout.GRID_2X2
@export var showcase_textures: Array[Texture2D] = []


func get_showcase_item_requirement() -> int:
	return (
		WALKERS_ITEM_COUNT
		if showcase_layout == ShowcaseLayout.WALKERS_2_3
		else GRID_ITEM_COUNT
	)


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
	if showcase_textures.is_empty():
		return true
	if showcase_textures.size() != get_showcase_item_requirement():
		return false
	for texture in showcase_textures:
		if texture == null:
			return false
	return true
