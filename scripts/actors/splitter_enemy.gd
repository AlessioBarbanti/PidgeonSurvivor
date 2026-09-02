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
		# PS-057: la morte arriva sincrona dal flush delle query fisiche
		# (projectile.try_hit -> take_damage -> died), lo stesso momento in
		# cui il server fisico rifiuta ogni cambiamento di stato. Aggiungere
		# subito un frammento alla scena tocca il server fisico fin dentro
		# add_child() (le sue CollisionShape2D entrano nell'albero) e poi in
		# _ready() (duplicazione delle shape, abilitazione di Hurtbox e
		# ContactDamage): differire l'intero spawn al prossimo punto sicuro
		# elimina la causa alla radice invece di rincorrere ogni singola
		# chiamata rifiutata. spawn_archetype_instance() resta sincrona per
		# gli altri chiamanti (wave_event_scheduler.gd ne usa il valore di
		# ritorno), quindi il rinvio resta qui, non nello spawner.
		spawner.call_deferred("spawn_archetype_instance", fragment_definition, spawn_position)
