# Cornice finestre pausa

La cornice raster e stata prodotta il 29 agosto 2026 con OpenAI ImageGen
built-in per sostituire i pannelli piatti di pausa, conferma cambio personaggio,
tutorial, terminale e introduzione Boss. Origine: progetto IL GIOCO; autore:
progetto IL GIOCO con assistenza OpenAI ImageGen; licenza: Licenza del
progetto. Non incorpora testi, icone, personaggi, pulsanti o controlli: restano
nodi Godot accessibili e localizzati.

## Prompt finale selezionato

```text
Use case: stylized-concept
Asset type: nine-slice UI panel texture for a 2D Godot game menu, to sit behind text and existing ornate orange and blue buttons.
Primary request: create a rectangular, border-safe menu panel in pixel-art style, viewed perfectly front-on. The center must be an almost-black subtly mottled charcoal/blue-black surface with extremely low contrast, leaving a large clean uninterrupted empty center for UI controls. Around all four edges, draw a restrained antique-gold and dark-bronze carved frame, slightly worn, with tiny rivets and squared ornamental corner plates. Add only a small symmetric gold diamond crest at the top center and a matching tiny bottom-center accent. No objects in the center.
Style/medium: premium hand-painted pixel-art UI, crisp low-resolution silhouette, limited palette, no blur.
Composition/framing: symmetrical wide rectangular panel; all decoration stays in the outer 12 percent border so it can be used as a 9-slice texture.
Lighting/mood: dark tavern / night arcade, warm aged metal edge, readable but not flashy.
Color palette: blue-black, charcoal, old bronze, muted antique gold, faint warm brown grain.
Constraints: no text, no letters, no icons, no buttons, no characters, no logos, no watermark, no cyan, no bright central decoration; keep the inside clean and dark for labels, sliders and buttons; do not put a heavy shadow outside the frame.
```

| Percorso | Generatore | Dimensioni | Trasformazioni | SHA-256 |
|---|---|---:|---|---|
| `assets/art/ui/pause/hd/pause_panel_frame_source.png` | OpenAI ImageGen built-in | `1536x1024` RGB PNG | Master originale, escluso da import ed export tramite `.gdignore` | `91A4AF8D78E34C784C7C214970C9E1AD8A677650FCFB56CCA4AC6906A43B9D31` |
| `assets/art/ui/pause/pause_panel_frame.png` | Derivazione deterministica | `768x512` RGBA PNG | Riduzione al 50% nearest-neighbor tramite System.Drawing; `StyleBoxTexture` nove-slice con margini esterni `56x52` nella pausa | `51FB964FA9CDDDC645B4E4A6C3F4C4F813C894105F89F1498F2B864B855D6CBB` |

Il runtime usa esclusivamente il derivato attraverso `StyleBoxTexture`
nove-slice in `pause_overlay.tscn`, `tutorial_screen.tscn`, `end_screen.tscn`
e `boss_ui.tscn`, e per il solo ritratto selezionato in
`character_select_overlay.gd`. La resa finale resta soggetta a conferma
percettiva su Windows e Pixel 9.
