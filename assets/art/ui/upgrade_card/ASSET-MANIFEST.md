# Manifest asset — Ornamento d'angolo carte upgrade

## PS-139/PS-152 — Rivetto d'angolo isolato

- Stato: **placeholder** (PS-109/PS-110). PS-139 ha cablato la scena su
  questo percorso prima che l'asset reale esistesse; PS-152 (`tipo: art`,
  in corso) sostituirà il file con il derivato reale prodotto da ImageGen,
  senza altre modifiche a scena o script.
- Il pixel `(0,0)` del derivato è magenta pieno (`255,0,255,255`), la firma
  di riconoscimento dei placeholder generati da
  `tools/generate-art-placeholder.ps1` (vedi
  [PS-110](../../../../docs/cards/5_completed/PS-110-placeholder-asset-e-stato-in-attesa-asset.md)):
  non è un derivato reale, non ha alpha reale attorno a una silhouette.
- Comando usato:
  `tools/generate-art-placeholder.ps1 -OutputPath assets/art/ui/upgrade_card/upgrade_card_corner.png -Width 128 -Height 128 -Label CORNER`

| Percorso | Dimensioni | Uso | SHA-256 |
|---|---:|---|---|
| `assets/art/ui/upgrade_card/upgrade_card_corner.png` | `128×128` RGBA (placeholder) | Ornamento d'angolo, 4 istanze via `flip_h`/`flip_v` in `scenes/ui/upgrade_card.tscn` | `D0AE41E1BDD5D6E1243429110BCBC1DE770F6105BFB8387B971F16608B0F99A4` |

Quando PS-152 consegna l'asset reale, questa riga va aggiornata con
dimensioni/hash definitivi e una sezione che documenti origine, autore,
licenza, prompt e trasformazioni — stesso schema già in uso in
[`assets/art/ui/pause/ASSET-MANIFEST.md`](../pause/ASSET-MANIFEST.md).
