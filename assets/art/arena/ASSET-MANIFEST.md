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

## B38 — Ostacoli e pavimento ghiaia della grigliata

Origine: sette master HD PNG RGBA/RGB forniti direttamente dal proprietario
nella cartella `hd/` e gia' prodotti fuori da questo repository; il repository
non inventa prompt, generatore, autore o licenza di terzi non consegnati.

Trasformazione: `tools/process-arena-obstacle.ps1` (variante non quadrata di
`process-upgrade-icon.ps1`), ritaglio sul bounding box alpha (soglia `8`,
padding `8`; le due texture opache usano l'intera immagine), riduzione
nearest-neighbor a una risoluzione pixelizzata dedicata per elemento invece di
un canvas quadrato forzato, cosi' ogni ostacolo conserva il proprio aspect
ratio naturale. Le due texture del pavimento ricevono inoltre una
moltiplicazione RGB `(0.55, 0.52, 0.46)` e la rimozione del canale alpha
(sempre opaco): riporta la luminanza media grezza (`~0.35`) sotto `0.22` e il
picco (`~0.91`) sotto `0.52`, mantenendo il pavimento recessivo rispetto a
Player, nemici, XP e pickup senza affidarsi soltanto alla modulazione
runtime — stesso criterio del pavimento B18S.

Runtime: `ArenaView.background_texture` passa dal pavimento B18S alla ghiaia;
`background_modulate = Color(0.88, 0.86, 0.82, 0.95)` resta una rifinitura
leggera, coerente con il valore B18S originale. `texture_pavement.png` e'
derivato ma non ancora cablato in `ArenaView`: resta riservato a un futuro
accento "zona cottura" pavimentata attorno al camino.

| Elemento | Master HD (escluso da import/export) | Derivato runtime | Dimensioni | SHA-256 runtime |
|---|---|---:|---:|---|
| Camino | `hd/obstacle_fireplace.png` | `generated/obstacle_fireplace.png` | `130×130` | — |
| Tavolo di legno | `hd/obstacle_wooden_table.png` | `generated/obstacle_wooden_table.png` | `96×95` | — |
| Panca | `hd/obstacle_bench.png` | `generated/obstacle_bench.png` | `118×84` | — |
| Filo dei panni | `hd/obstacle_clothesline.png` | `generated/obstacle_clothesline.png` | `60×100` | — |
| Rete/recinzione | `hd/obstacle_steel_net.png` | `generated/obstacle_steel_net.png` | `170×45` | — |
| Lavatoio in pietra | `hd/obstacle_stone_washbasin.png` | `generated/obstacle_stone_washbasin.png` | `74×83` | — |
| Pavimento ghiaia | `hd/texture_gravel.png` | `generated/texture_gravel.png` | `256×256` | `8EF8E91C6EBBEF5B8D68EB2CFD3777C69C79EE713ABE701103D709D73E20CFED` |
| Pavimento cotto (riservato) | `hd/texture_pavement.png` | `generated/texture_pavement.png` | `256×256` | `D3C0BB9A5EEDDD77BDD5449B283D450D43FEFDD7B0AA5A04C6E3D8D782F28F98` |

I master `hd/*.png` restano fuori da import, EXE, APK e AAB (stessa
convenzione B27 di `icons/upgrades/hd/`).
