# Manifest sfondo arena B18S

Lo sfondo raster dell'arena e stato prodotto il 25 agosto 2026 con OpenAI
ImageGen built-in. Origine: progetto IL GIOCO; autore: progetto IL GIOCO con
assistenza OpenAI ImageGen; licenza: Licenza del progetto. Non sono stati usati
asset grafici esterni, marchi o personaggi reali.

## Prompt finale selezionato

```text
Use case: stylized-concept
Asset type: seamless responsive game arena floor texture
Primary request: create an original top-down raster background for the arena floor of a caricatured pixel-art arcade friendship-survival game
Scene/backdrop: abstract worn night-blue stone and asphalt floor, subtly warm violet and muted teal mineral variation, faint irregular scuffs and tiny non-semantic speckles distributed evenly
Subject: background texture only, no focal element
Style/medium: polished hand-crafted pixel art, restrained chunky pixel clusters, low-frequency material variation, low contrast
Composition/framing: orthographic top-down, edge-to-edge texture, visually seamless in both axes, uniform density, safe for center crop and repetition across 16:9, 20:9 and 4:3
Lighting/mood: dim ambient night lighting, matte surface, quiet playful arcade mood
Color palette: deep desaturated navy, charcoal, muted aubergine, tiny subdued teal accents; keep luminance compressed and dark
Constraints: gameplay actors, pickups, hostile projectiles and telegraphs must remain much brighter and clearer; no readable objects; no implied collision; no perspective; no horizon; no vignette; no text; no logo; no watermark
Avoid: grid lines, cyan border, tiles with straight seams, paths, walls, pits, cracks that form barriers, arrows, circles, targets, doors, furniture, grills, food, pigeons, characters, props, UI shapes, bright highlights, high contrast, large stains, obvious landmarks
```

Sono state generate due varianti indipendenti. La seconda e stata scartata
perche i blocchi regolari potevano sembrare ostacoli; soltanto la prima e stata
trasformata e inserita nel repository.

## File runtime

| Percorso | Generatore | Dimensioni | Trasformazioni | SHA-256 |
|---|---|---:|---|---|
| `assets/art/arena/arena_floor_imagegen.png` | OpenAI ImageGen built-in | `768x512` RGB PNG | Output selezionato `1536x1024` RGB, SHA-256 sorgente `3F037310B8B821970148915ABCC73D39BE689B9A273DD5D226AE28A10237816C`; downscale esatto `2:1` nearest-neighbor, metadata generatore rimossi dalla riscrittura PNG; nessun crop, ritocco o testo | `210523A96CF0370885BE49E937D85EBD035DF992D8FBC2089A89F36347A615BC` |

Il runtime usa crop centrale aspect-cover sul `playfield_rect`, filtro nearest e
modulazione scura. Il raster non modifica confini, collisioni o coordinate;
`ArenaView` conserva il pavimento procedurale B18B soltanto come fallback se la
texture non e assegnata.
