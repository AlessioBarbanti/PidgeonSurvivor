class_name DifficultyProfile
extends Resource

## PS-170: profilo dichiarativo di difficolta'. Il moltiplicatore agisce solo
## su resistenza e pericolosita' dei nemici e si compone con le curve gia'
## esistenti; densita', eventi d'ondata, soglie Boss ed economia restano
## fuori, cosi' a parita' di seed la sequenza non cambia fra i livelli.
##
## E' una scelta di gameplay e resta separata da PerformanceProfile, che non
## puo' alterare il bilanciamento in modo invisibile.

## Identificatore stabile: e' la chiave persistita e quella letta dal
## riepilogo, non l'etichetta mostrata.
@export var id: StringName = &""
## Etichetta mostrata nel selettore e nel riepilogo finale.
@export var label: String = ""
## Descrizione mostrata sotto il selettore: niente numeri di bilanciamento,
## quelli vivono qui nel dato.
@export_multiline var description: String = ""
## Moltiplicatore di pressione applicato a HP e danno dei nemici.
@export_range(0.05, 8.0, 0.01) var pressure_multiplier := 1.0:
	set(value):
		pressure_multiplier = clampf(value, 0.05, 8.0) if is_finite(value) else 1.0


func is_valid() -> bool:
	return (
		not String(id).strip_edges().is_empty()
		and not label.strip_edges().is_empty()
		and not description.strip_edges().is_empty()
		and is_finite(pressure_multiplier)
		and pressure_multiplier > 0.0
	)
