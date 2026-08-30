# Aleo — prompt di rigenerazione arte (rework termotecnico)

Il rework gameplay del 28 agosto 2026 ha sostituito il muratore con un
termotecnico: passiva **Termostato Interno**, attiva **Shock Termico**. Questo
file raccoglie i prompt riproducibili usati per rigenerare l'arte, nello stile
già adottato per il resto del cast. Lo stato di integrazione è in fondo.

Origine dichiarata: la direzione visuale di Aleo è ispirata ai tratti di una
persona reale, con consenso esplicito dichiarato dal proprietario del progetto.
Il risultato resta una caricatura pixel-art e non una somiglianza fotografica.
Per questo i prompt sostituiscono la clausola «no real person» usata per il
resto del cast con «caricature only, never a photographic likeness».

I manifest dedicati (`assets/art/characters/players/ASSET-MANIFEST.md`,
`assets/art/icons/passives/ASSET-MANIFEST.md`, `assets/art/vfx/ASSET-MANIFEST.md`)
registrano autore, generatore, trasformazioni e SHA-256 degli asset entrati nel
runtime.

## 1. Striscia sprite Player (`hd/aleo_source.png`)

```text
Use case: stylized-concept
Asset type: three-frame 2D Godot character sprite strip
Primary request: create one original caricatural character in exactly three registered right-facing poses in one horizontal row: locomotion pose A, neutral idle, locomotion pose B
Subject: Aleo, a young adult male heating-and-cooling technician; sturdy heavy build with broad shoulders and a full torso, medium-length wavy auburn hair swept to one side and falling past the ears, full auburn beard and moustache, rectangular black-framed glasses; plain dark charcoal t-shirt, anthracite work trousers, burnt-orange technician tool belt, ice-cyan piping accents; a large adjustable wrench held in one hand and a round pressure gauge clipped at the belt; calm, quietly confident expression
Style/medium: polished caricatural arcade pixel art matching the approved welcome cast; crisp dark outline, limited palette, chunky readable pixel clusters
Composition/framing: exactly three equal-width cells, full body visible, identical scale, baseline, center and proportions, generous padding, no dividers
Scene/backdrop: perfectly flat uniform #00ff00 chroma-key background everywhere
Constraints: caricature only, never a photographic likeness; faces right; no logo, trademark, text, watermark, shadows, gradient, scenery, floor or gameplay VFX; keep frost and heat effects out of the sprite, they are separate VFX; crisp edges suitable for deterministic downscale to 32x32 per frame
Avoid: photorealism, smooth vector style, emoji style, extra characters, hard hat or masonry props
```

Il ritratto del carosello **non** richiede un prompt separato:
`tools/process-carousel-portrait.ps1` lo deriva dalla cella idle centrale dello
stesso master HD.

## 2. Icona passiva — Termostato Interno

```text
Use case: stylized-concept
Asset type: passive ability icon for a Godot pixel-fantasy character selection screen
Primary request: create one square pixel-art emblem for the passive ability "Termostato Interno"
Subject: a bold front-facing round thermostat dial split vertically down the middle; the left half glows ice-cyan with two compact frost crystals, the right half glows burnt-orange with two compact heat waves; a single short needle points up from the centre of the dial, and the rim carries plain tick marks instead of numbers
Style/medium: polished 32-bit fantasy pixel art, crisp chunky pixels, readable when reduced to 72x72, matching a dark medieval-fantasy game UI with restrained ice-cyan and burnt-orange focal details
Composition/framing: centered single emblem, generous padding, strong silhouette, no enclosing card or outer frame
Scene/backdrop: perfectly flat solid #00ff00 chroma-key background for background removal
Constraints: one icon only; no text, no letters, no numbers, no logo, no watermark; no cast shadow, contact shadow, reflection, gradients or texture in the background; keep the subject fully separated from the background; do not use #00ff00 anywhere in the emblem
Avoid: photorealism, smooth vector style, emoji style, circular app-icon container, UI mockup, multiple icons
```

## 3. Icona attiva e texture VFX — Shock Termico

```text
Use case: stylized-concept
Asset type: square active-ability icon and VFX texture for a Godot arcade survival game
Primary request: create one square pixel-art emblem for the active ability "Shock Termico"
Subject: a compact ring of ice-cyan frost shards contracting inward around a bursting burnt-orange heat core, with two short steam curls escaping the top; the frozen outer ring and the exploding hot centre must read as one single thermal-shock event
Style/medium: caricatural arcade pixel art, crisp clustered pixels, limited palette, sharp silhouette readable at 42 px
Composition/framing: centered single emblem, square canvas, uniform margin, no card, frame or container
Scene/backdrop: perfectly flat uniform chroma-key background for background removal
Constraints: one emblem only; no text, letters, numbers, logo, watermark, frame or UI; no cast shadow, reflection or background gradient; keep the subject fully separated from the background
Avoid: photorealism, smooth vector style, emoji style, multiple icons, realistic flames, realistic ice photography
```

## 4. Correzione del fondale welcome B18O

Il fondale mostra ancora Aleo come muratore nello slot in alto a sinistra.

```text
Use case: precise-object-edit
Asset type: 16:9 Windows and Android game welcome-screen background
Input images: Image 1 is the exact edit target.
Primary request: replace only the construction worker in the upper-left character slot with the reworked Aleo, preserving the entire rest of the image, the other seven characters and the central menu-safe space.

Aleo — a young adult male heating-and-cooling technician with a sturdy heavy build, medium-length wavy auburn hair swept to one side, a full auburn beard and rectangular black-framed glasses; dark charcoal shirt, anthracite work trousers, burnt-orange tool belt and ice-cyan piping accents; a large adjustable wrench in one hand and a round pressure gauge at the belt. Replace the grey cement splash at his boots with a small split thermal effect: a patch of ice-cyan frost on one side and a low burnt-orange heat shimmer on the other.

Style/medium: polished hand-crafted 2D pixel-art arcade illustration matching Image 1 exactly; crisp clustered pixels, chunky readable silhouettes, limited rich palette, expressive caricature, consistent scale and outline weight with the other seven characters.
Lighting/mood: preserve the deep navy summer night, warm amber barbecue and string-light illumination, cyan moonlight and the cheerful absurd-survival tone.
Composition/framing: preserve Image 1's 16:9 canvas, camera angle, moon, sky, pigeons, party environment, tables, props, ground perspective and dark quiet centre. Maintain safe crop behaviour for 20:9 and 4:3.
Constraints: change only the upper-left character and the small ability effect immediately around him; caricature only, never a photographic likeness; exactly eight physical human characters; no text, letters, numbers, logo, UI, buttons, frame, border, watermark, gore or guns; do not brighten, clutter or populate the central menu-safe area.
```

## Stato: integrato il 28 agosto 2026

I quattro asset sono stati generati e sono entrati nel runtime lo stesso giorno.

| Asset | File runtime | Master conservato |
|---|---|---|
| Striscia sprite | `assets/art/characters/players/aleo.png` | `hd/aleo_source.png` |
| Ritratto carosello | `assets/art/characters/players/carousel/aleo.png` | derivato dal master sprite |
| Icona passiva | `assets/art/icons/passives/generated/aleo_internal_thermostat.png` | `hd/aleo_internal_thermostat_source.png` |
| Icona attiva | `assets/art/icons/abilities/generated/thermal_shock.png` | `hd/thermal_shock_source.png` |

I raster del muratore, `aleo_solid_structure.png` e `cement.png`, sono stati
rimossi con le rispettive righe di manifest. Il prompt 4, la correzione del
fondale welcome, resta l'unico non ancora eseguito: nel fondale B18O Aleo è
ancora il muratore.
