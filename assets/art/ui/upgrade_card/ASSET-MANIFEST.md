# Manifest asset — Ornamento d'angolo carte upgrade

## PS-139/PS-152 — Rivetto d'angolo isolato

### Asset runtime promosso — 2026-09-10

Il proprietario ha promosso esplicitamente il candidato PS-152 con
«Promosso!». Il derivato ha sostituito in-place il placeholder di PS-139,
senza modifiche a scena o script. Il placeholder storico era stato prodotto
col comando seguente e aveva SHA-256
`D0AE41E1BDD5D6E1243429110BCBC1DE770F6105BFB8387B971F16608B0F99A4`.

Comando:
`tools/generate-art-placeholder.ps1 -OutputPath assets/art/ui/upgrade_card/upgrade_card_corner.png -Width 128 -Height 128 -Label CORNER`

### Produzione PS-152

- Origine: progetto IL GIOCO; nuova sintesi guidata soltanto nello stile da
  `assets/art/ui/pause/pause_panel_frame.png` (palette, pixel density e
  trattamento del metallo; nessun soggetto o elemento compositivo copiato).
- Generatore/autore: progetto IL GIOCO con assistenza OpenAI ImageGen built-in.
- Licenza: Licenza del progetto.
- Stato: approvato dal proprietario e promosso al percorso runtime. La copia
  `_review/` resta come evidenza non importata del candidato approvato.

Prompt di generazione selezionato:

```text
Generate a NEW isolated pixel-art UI object on genuine transparent alpha. The previously generated L-shaped corner bracket is rejected; do not repeat that design.

Object: ONE compact decorative antique-metal medallion / corner cap, essentially a small square plate with subtly clipped or rounded corners, viewed perfectly front-on. It has concentric stepped metal facets and ONE small round central rivet. The outer silhouette is compact and self-contained on all four sides. Absolutely NO arms, NO rails, NO frame strips, NO lines extending away from the plate, NO L shape, NO diagonal tail, NO separate pieces.

Visual family: restrained premium hand-painted pixel art like the Pidgeon Survivor pause-frame hardware: dark bronze recesses, muted antique-gold edges, tiny warm worn highlights, near-black creases. Crisp deliberate low-resolution blocks, limited palette, not shiny yellow, not over-contrasted.

Symmetry/reuse: fully symmetric horizontally and vertically, neutral frontal lighting, no directional shadow, so the same asset remains visually correct under horizontal and vertical mirroring.

Composition: center the complete compact plate on a square transparent canvas with generous clear space around it. Keep its full silhouette uncut. No backdrop of any kind; genuine alpha outside the object.

Constraints: no text, letters, logo, watermark, crest, gemstones, iconography, blue/cyan, card background, scenery, checkerboard drawn into the pixels, drop shadow, glow, border rail, or extra objects. Output a clean square PNG suitable as an HD source for deterministic alpha-cropping and padding.
```

Il tentativo ImageGen di estrazione dello sfondo ha restituito ancora un PNG
RGB opaco con checkerboard rasterizzato. La trasformazione deterministica ha
quindi isolato il soggetto ex-novo ad alta risoluzione (non il vecchio frame
pausa): pixel visibile se media RGB `<110` oppure escursione cromatica
`max(R,G,B)-min(R,G,B)>25`; crop sorgente `x:329..924`, `y:328..923`;
riduzione nearest-neighbor `596→415`, ancoraggio a `(0,0)` su canvas
`512×512`; derivato `128×128` con riduzione nearest-neighbor 4:1. Bounds alpha
del derivato: `0,0..103,103`; margine destro/inferiore `24 px` (18,75%);
nessun pixel a alpha parziale.

| Percorso | Dimensioni | Trasformazioni | SHA-256 |
|---|---:|---|---|
| `assets/art/ui/upgrade_card/hd/upgrade_card_corner_source.png` | `512×512` RGBA | Master ripulito e ancorato; escluso da import/export tramite `.gdignore` | `73E403DED530F9D6B14AA1F9CD7EF46DB98C63047B7D381F20A891B0351CAD59` |
| `assets/art/ui/upgrade_card/_review/upgrade_card_corner_candidate.png` | `128×128` RGBA | Derivato nearest-neighbor 4:1; candidato isolato su fondo navy e confrontato col frame pausa | `96AAFF52390536086C7E200EAFAB95E5487AEDFC846377D7BE5A344DE21E5E44` |
| `assets/art/ui/upgrade_card/upgrade_card_corner.png` | `128×128` RGBA | Derivato runtime promosso; 4 istanze via `flip_h`/`flip_v` in `upgrade_card.tscn` | `96AAFF52390536086C7E200EAFAB95E5487AEDFC846377D7BE5A344DE21E5E44` |
