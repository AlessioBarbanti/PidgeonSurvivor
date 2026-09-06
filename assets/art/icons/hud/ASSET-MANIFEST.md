# Icone HUD

## Calice Sobrietà di Alea — PS-104/PS-106 (06/09/2026)

**PLACEHOLDER — in attesa di PS-104.** I due file sotto non sono arte
definitiva: sono stand-in generati deterministicamente da
`tools/generate-art-placeholder.ps1` per permettere a
[PS-106](../../../../docs/cards/3_in_sprint/PS-106-integra-icona-calice-sobrieta-alea-hud.md)
di cablarsi in HUD prima che l'asset reale esista (PS-110). Riconoscibili dal
pixel `(0,0)`, sempre magenta pieno (`255,0,255,255`). La geometria (due
derivati `128×128` RGBA, stessa canvas, pensati per un `TextureProgressBar`
con riempimento verticale dal basso) è quella fissata da
[PS-104](../../../../docs/cards/2_to_do/PS-104-icona-calice-sobrieta-alea.md)
in modalità pianificazione: quando l'asset reale verrà generato, sostituirà
questi stessi file allo stesso percorso, senza richiedere modifiche al
cablaggio.

| Percorso | Generatore | Dimensioni | Trasformazioni | SHA-256 |
|---|---:|---:|---|---|
| `generated/alea_sobriety_glass_empty.png` | `tools/generate-art-placeholder.ps1` (placeholder, non arte) | `128x128` RGBA PNG | `-Width 128 -Height 128 -Label "GLASS"` | `9270822897DD584063E1B1F98A1A017420A20AF1B0215B2D21068FB4D5BACE15` |
| `generated/alea_sobriety_wine_fill.png` | `tools/generate-art-placeholder.ps1` (placeholder, non arte) | `128x128` RGBA PNG | `-Width 128 -Height 128 -Label "WINE"` | `2D17581D985C7FBEC1AF4D4878023DAF0812224C93DA714ABE0EE05CA748DA4C` |

Nessun master `hd/`: un placeholder non ha origine artistica da preservare.
