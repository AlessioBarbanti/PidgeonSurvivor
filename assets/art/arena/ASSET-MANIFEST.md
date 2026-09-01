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
| Lavatoio in pietra | `hd/obstacle_stone_washbasin.png` | `generated/obstacle_stone_washbasin.png` | `74×83` | — |
| Pavimento ghiaia | `hd/texture_gravel.png` | `generated/texture_gravel.png` | `256×256` | `8EF8E91C6EBBEF5B8D68EB2CFD3777C69C79EE713ABE701103D709D73E20CFED` |
| Pavimento cotto (riservato) | `hd/texture_pavement.png` | `generated/texture_pavement.png` | `256×256` | `D3C0BB9A5EEDDD77BDD5449B283D450D43FEFDD7B0AA5A04C6E3D8D782F28F98` |

I master `hd/*.png` restano fuori da import, EXE, APK e AAB (stessa
convenzione B27 di `icons/upgrades/hd/`).

## B50 — Rimozione della rete/recinzione

`obstacle_steel_net.png` (master `hd/` e derivato `generated/`) e' stato
rimosso dal repository: le due reti metalliche dell'arena (`FenceWest`,
`FenceEast`) collidevano su tutto il rettangolo pur essendo visivamente per
lo piu' vuote, e il piano di evoluzione del gameplay ne richiede la
rimozione senza sostituirle con un'altra rete. Nessun altro ostacolo usa
questa texture.

## PS-058 — Ghiacciaia e catasta di casse

Integrati il 1 settembre 2026. Origine: asset originali del progetto IL GIOCO
generati con OpenAI ImageGen built-in dopo l'art review dei cinque prop B38;
quattro dei prop recenti e la cattura 20:9 dell'arena sono stati forniti al
primo passaggio come riferimenti di stile e scala. Autore: progetto IL GIOCO
con assistenza OpenAI ImageGen. Licenza: Licenza del progetto. Non sono stati
usati asset grafici esterni, marchi, testo o persone reali.

### Prompt finale — ghiacciaia

```text
Use case: stylized-concept
Asset type: transparent pixel-art game arena obstacle master for Pidgeon Survivor
Input images: the recent local arena props are style references only; the recent Pixel 9 gameplay capture is a runtime scale and composition reference
Primary request: create one original vintage portable ice cooler, clearly readable as a cooler at very small game scale
Scene/backdrop: genuinely transparent background, isolated cutout only
Subject: a squat rectangular hard-sided picnic ice cooler, desaturated powder-blue body, pale ivory-blue hinged lid with a chunky rim, two compact dark metal side handles, simple latch, subtle wear; no contents and no text
Style/medium: polished hand-crafted pixel art matching the supplied arena props; crisp dark brown-black outline; restrained chunky readable pixel clusters; no anti-aliased painted look
Composition/framing: centered single object, orthographic slightly front-facing view like the supplied bench and stone washbasin; silhouette aspect ratio about 9:7; object fills the canvas with even tight transparent padding; all feet/base visible
Lighting/mood: warm dim ambient arena light, key light from upper left, compact contact darkening contained inside the object's footprint
Color palette: desaturated powder blue, cool ivory, charcoal and tiny muted brass accents; luminance and saturation compatible with the supplied warm wood and stone props
Materials/textures: lightly scuffed painted metal/plastic, strong planar shading, sparse detail that survives at 90x70 pixels
Constraints: preserve a clean rectangular collision-readable silhouette; actual alpha transparency; one cooler only; no cast shadow beyond the silhouette; no floor; no scenery; no ice cubes; no bottles; no food; no people; no pigeons; no text; no logo; no watermark
Avoid: glossy modern product render, photorealism, smooth gradients, thin handles, ornate decoration, excessive highlights, blue glow, cyan neon, isometric top-down view, soft fuzzy edges
```

Il primo candidato aveva una scacchiera incorporata in un PNG RGB ed e' stato
scartato. Il master conservato e' il risultato del seguente passaggio ImageGen
di estrazione sfondo, verificato come PNG RGBA con alfa reale:

```text
Use case: background-extraction
Asset type: transparent pixel-art game arena obstacle master
Input images: Image 1 is the edit target
Primary request: remove only the baked checkerboard background from Image 1 and replace it with genuine full alpha transparency
Constraints: preserve the cooler itself exactly: same silhouette, proportions, colors, pixel clusters, dark outline, lid, latch, handles, wear, lighting and framing; do not redesign, crop, rotate, recolor, relight, sharpen, blur or add anything; preserve clean hard pixel-art edges without halos; return one isolated cooler on actual transparent background; no floor; no cast shadow; no checkerboard pixels; no text; no logo; no watermark
```

### Prompt finale — catasta di casse

```text
Use case: stylized-concept
Asset type: transparent pixel-art game arena obstacle master for Pidgeon Survivor
Input images: the recent local arena props and newly generated cooler are style references only; the recent Pixel 9 gameplay capture is a runtime scale and composition reference
Primary request: create one original compact stack of weathered wooden storage crates, clearly readable as stacked crates at very small game scale
Scene/backdrop: genuinely transparent background, isolated cutout only
Subject: three stout wooden slat crates in an irregular stable stack, two on the bottom and one centered slightly offset above; each crate has a simple dark recessed opening or diagonal reinforcement, broad planks, a few large iron nail heads, worn corners; no contents and no markings
Style/medium: polished hand-crafted pixel art matching the supplied arena props; crisp dark brown-black outline; restrained chunky readable pixel clusters; no anti-aliased painted look
Composition/framing: centered single prop group, orthographic slightly front-facing view like the supplied bench and stone washbasin; overall silhouette aspect ratio about 13:11; group fills the canvas with even tight transparent padding; complete base visible
Lighting/mood: warm dim ambient arena light, key light from upper left, compact contact darkening contained inside the stack footprint
Color palette: medium and dark warm walnut, muted amber edge highlights, charcoal recesses and iron; luminance and saturation compatible with the supplied bench and table, but distinct through the stacked silhouette
Materials/textures: rough aged planks, simplified wood grain, strong planar shading, sparse detail that survives at 130x110 pixels
Constraints: preserve a compact collision-readable outer silhouette; actual alpha transparency; exactly one stack of three crates; no loose crate outside the stack; no cast shadow beyond the silhouette; no floor; no scenery; no food; no weapons; no people; no pigeons; no text; no logos, labels, symbols or watermark
Avoid: shipping logos, photorealism, smooth gradients, thin broken boards, excessive splinters, ornate decoration, bright orange glow, isometric top-down view, soft fuzzy edges
```

Trasformazione di entrambi i master: `tools/process-arena-obstacle.ps1`, crop
sul bounding box alpha con `VisibleAlphaThreshold=8` e `Padding=8`, quindi
riduzione nearest-neighbor ai box runtime. I derivati sono assegnati soltanto
a `World/Obstacles/IceCooler` e `World/Obstacles/WoodCrateStack`; posizione,
footprint e collisione restano quelli fissati da PS-045. I master `hd/*.png`
restano esclusi da import, EXE, APK e AAB tramite `.gdignore` e i tre filtri
di `export_presets.cfg`.

| Elemento | Percorso | Dimensioni | SHA-256 |
|---|---|---:|---|
| Ghiacciaia, master HD | `hd/obstacle_ice_cooler.png` | `1466x1073` RGBA | `A0846B2CAB0703310141B058D05F3F68301F2D93BD99F102424E7F73D3006BC1` |
| Ghiacciaia, derivato runtime | `generated/obstacle_ice_cooler.png` | `90x70` RGBA | `B622E428C0C77174D8BD48705C89575083156D5EEFE10AE87AFB595A3B5344D5` |
| Catasta di casse, master HD | `hd/obstacle_wood_crate_stack.png` | `1367x1151` RGBA | `E51137F9C0D9024128B92E7A70BE5919A9FCE79B954F33CDBF168680DD94687C` |
| Catasta di casse, derivato runtime | `generated/obstacle_wood_crate_stack.png` | `130x110` RGBA | `0DBF4A5D9AA1DF30B7BCE0C9B5BB4D53E28E4A2F691F46FF259DDFFB69D15243` |
