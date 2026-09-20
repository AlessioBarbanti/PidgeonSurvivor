class_name RunSummary
extends RefCounted

## PS-053: snapshot della run appena conclusa, costruito da
## MovementSlice da dati già posseduti da run, esperienza, Boss e servizio
## upgrade. La UI del terminale legge solo questo, senza toccare i sistemi
## di gameplay direttamente.

var character_name := ""
var character_portrait: Texture2D
var level := 1
var bosses_defeated := 0
## PS-184: totale dei nemici morti per danno nella run, Boss compresi.
var enemies_defeated := 0
## PS-170: difficolta' fotografata all'avvio della run. L'id e' la chiave
## stabile, l'etichetta e' cio' che il riepilogo mostra. Entrambi vuoti se
## lo snapshot non la conosce: il riepilogo omette il segmento invece di
## inventare un livello.
var difficulty_id: StringName = &""
var difficulty_label := ""
var run_time := 0.0
var top_upgrades: Array[UpgradeService.RankedUpgrade] = []
