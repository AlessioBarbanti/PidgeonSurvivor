class_name SplitterEnemy
extends BaseEnemy

## Divisore (B40): alla morte genera un numero fisso di frammenti tramite lo
## spawner, cosicche' contino per il cap max_alive_enemies e per la pulizia a
## restart come ogni altro nemico. I frammenti usano un archetipo distinto
## senza proprio split_fragment_definition, quindi la divisione non e' mai
## ricorsiva per costruzione.

var _split_fragment_definition: EnemyArchetypeDefinition
var _split_fragment_count := 0
var _spawner: EnemySpawner


func configure_splitter(
	fragment_definition: EnemyArchetypeDefinition,
	fragment_count: int,
	spawner: EnemySpawner
) -> void:
	_split_fragment_definition = fragment_definition
	_split_fragment_count = maxi(fragment_count, 0)
	_spawner = spawner


func _on_died() -> void:
	var spawn_position := global_position
	var fragment_definition := _split_fragment_definition
	var fragment_count := _split_fragment_count
	var spawner := _spawner
	super._on_died()
	if (
		fragment_definition == null
		or fragment_count <= 0
		or not is_instance_valid(spawner)
	):
		return
	for _fragment_index in fragment_count:
		spawner.spawn_archetype_instance(fragment_definition, spawn_position)
