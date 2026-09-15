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
var run_time := 0.0
var top_upgrades: Array[UpgradeService.RankedUpgrade] = []
