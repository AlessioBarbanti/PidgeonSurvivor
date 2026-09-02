# Registro storico — prompt e reference di generazione

Data di avvio: 2 settembre 2026.

Questo archivio conserva solo informazioni che possono essere riprodotte o
verificate nel repository. Non sostituisce i manifest degli asset: ciascun
manifest resta autorevole per file runtime, trasformazioni e hash del derivato.

## Regole di conservazione

- Le reference di stile già nel progetto sono citate con percorso, ruolo e
  SHA-256.
- Le foto personali consegnate dal proprietario sono reference autorizzate, non
  asset runtime: quando disponibili, vanno in
  `docs/characters/references/<id>/` (spostate da
  `assets/art/characters/references/<id>/` il 2 settembre 2026, PS-084), con
  `.gdignore`, esclusione dai tre preset export, hash e data di consegna nel
  manifest del cast.
- Non ricostruiamo né rigeneriamo un'immagine per fingere di aver conservato
  l'originale. Se i byte non sono nel checkout, il registro lo dichiara.

## B41 — Icone upgrade a tema griglia

Riferimento comune: `assets/art/icons/upgrades/hd/upgrade_damage_meat_fork.png`.

- Ruolo: **style reference** soltanto — pixel-art arcade, palette griglia,
  outline scuro e densità dei cluster; non è un edit target.
- SHA-256: `AEA17B6EE93CE03DD2EC6430F08DCED45D3FA94AFF04923FC71404E75C34FD85`.
- Generatore: OpenAI ImageGen built-in.
- Trasparenza successiva: chroma verde, poi `remove_chroma_key.py` con
  `--auto-key border --soft-matte --transparent-threshold 12
  --opaque-threshold 220 --despill --edge-contract 1`.

### Colpo Perforante — Spiedino

Output promosso: `assets/art/icons/upgrades/hd/upgrade_piercing_rounds_spiedino.png`.

```text
Use case: stylized-concept
Asset type: square HD source for a 128x128 Godot upgrade icon
Input images: Image 1 is a style reference only; do not edit or reproduce its exact object.

Primary request: create a single iconic barbecue skewer representing a projectile that pierces through multiple enemies.

Subject: one long glowing metal barbecue skewer passing cleanly through exactly three separate boneless grilled meat chunks. The skewer points dynamically toward the upper-right and visibly enters the first piece, crosses the central piece and exits from the last one. All three pieces must remain aligned along the same skewer so the penetration concept is immediately understandable. Add only a few compact golden sparks near the pointed tip to emphasize forward movement.

Style/medium: polished arcade pixel art matching Image 1, crisp clustered pixels, chunky dark outlines, rich grilled red-brown meat, visible golden sear marks, steel highlights and a restrained warm amber glow; high contrast and game-ready.

Composition/framing: one centered diagonal skewer filling about 80% of a square canvas, with the three meat chunks evenly spaced and forming one strong continuous silhouette. Keep generous padding around every edge. No crop, circular badge or frame.

Background: perfectly flat uniform solid #00ff00 chroma-key everywhere for later background removal. No shadow, floor, gradient, texture, reflection or lighting variation in the background. Do not use #00ff00 in the subject.

Constraints: exactly one skewer and exactly three boneless meat chunks; the metal skewer must be clearly visible between the pieces and emerging from both ends. No ribs, bones, pork chops, plate, fork, hands, people, faces, text, letters, numbers, logo, watermark, border, realistic photo, bullets, gun or extra food. Crisp isolated edges.
```

### Raffica Doppia — Doppia costina

Output promosso: `assets/art/icons/upgrades/hd/upgrade_double_barrel_costine.png`.

```text
Use case: stylized-concept
Asset type: square HD source for a 128x128 Godot upgrade icon
Input images: Image 1 is a style reference only; do not edit or reproduce its exact object.

Primary request: create two iconic grilled pork ribs representing exactly two projectiles fired simultaneously in a slight fan spread.

Subject: exactly two distinct matching pork ribs, each consisting of one thick grilled meat portion attached to one clearly readable curved ivory bone. Both ribs launch toward the upper-right in parallel trajectories with a small symmetrical fan spread. Each rib has its own short compact warm amber motion streak and a few orange sparks behind it. Their silhouettes must remain clearly separated and instantly readable as a pair at small size.

Style/medium: polished arcade pixel art matching Image 1, crisp clustered pixels, chunky dark outlines, rich grilled red-brown meat, golden sear marks, ivory bones and warm amber highlights; high contrast and game-ready.

Composition/framing: exactly two ribs arranged in a balanced V-shaped double-projectile composition, filling about 76% of a square canvas. Both ribs must have the same visual weight and remain completely visible, with generous even padding. No overlap that could make them appear to be a single object. No crop, circular badge or frame.

Background: perfectly flat uniform solid #00ff00 chroma-key everywhere for later background removal. No shadow, floor, gradient, texture, reflection or lighting variation in the background. Do not use #00ff00 in the subjects.

Constraints: exactly two pork ribs, each with exactly one visible bone; no third rib, no pork chops, skewers, plate, fork, hands, people, faces, text, letters, numbers, logo, watermark, border, realistic photo, bullets, gun or extra food. Both projectiles must point in the same general direction. Crisp isolated edges.
```

### Esplosione Finale — Coppa

Output promosso: `assets/art/icons/upgrades/hd/upgrade_death_burst_coppa.png`.

```text
Use case: stylized-concept
Asset type: square HD source for a 128x128 Godot upgrade icon
Input images: Image 1 is a style reference only; do not edit or reproduce its exact object.

Primary request: create a single iconic round slice of Italian pork coppa representing a damaging explosion triggered on enemy death.

Subject: one thick round/oval grilled coppa steak with visible marbling and crosshatched sear marks at the center of a compact radial burst of red-orange embers and golden flame spikes. The meat must remain the dominant readable silhouette; the burst must clearly radiate outward but stay compact and not become a generic sun badge.

Style/medium: polished arcade pixel art matching Image 1, crisp clustered pixels, chunky dark outline, rich burgundy and red-brown meat, creamy marbling, warm amber/yellow explosion highlights; high contrast and game-ready.

Composition/framing: one centered coppa slice filling about 62% of a square canvas, surrounded by a compact eight-direction burst, generous even outer padding, no crop, no circular badge, no frame.

Background: perfectly flat uniform solid #00ff00 chroma-key everywhere for later background removal. No shadow, floor, gradient, texture, reflection or lighting variation in the background. Do not use #00ff00 in the subject.

Constraints: exactly one coppa cut; no plate, bone, skewer, fork, hands, people, faces, text, letters, numbers, logo, watermark, border, realistic photo, bullets or gun. Crisp isolated edges.
```

Per i master, derivati e hash finali, vedere
`assets/art/icons/upgrades/ASSET-MANIFEST.md`.

## Identity pass del cast — reference fotografiche 28 agosto 2026

Le fotografie sono state fornite dal proprietario nella conversazione come
reference di identità per caricature pixel-art e archiviate il 2 settembre
2026. Sono asset del progetto forniti dal proprietario: autorizzati soltanto
come `subject reference`, mai come asset runtime o base per un output
fotorealistico.

| ID | File | Dimensioni | SHA-256 |
|---|---|---:|---|
| `alea` | `docs/characters/references/alea/source-01.png` | `253×798` | `2FCB9AD3F90DE40599907FFB5C9F1AF8114597A4751AA8DA362E520C04D487AD` |
| `aleo` | `docs/characters/references/aleo/source-01.png` | `580×1100` | `DAEFD8C29AAB7A7DECECD997298E7C2066C7E0467ADBCB3C63B04F8C54E33C1D` |
| `bea` | `docs/characters/references/bea/source-01.png` | `447×1035` | `B0F0F7DC18A934F9380869FD15E09B0A7EF93397E4213B14D09E12652DBE703D` |
| `bea` | `docs/characters/references/bea/source-02.png` | `777×1028` | `FA797E49ADDDA7A30989BA972AAE59B16100E1E13AA2A7B534947445C54B45FB` |
| `bea` | `docs/characters/references/bea/source-03.png` | `214×508` | `F3794909B95BE04A5E30AD7E9FD65D0721E9A4679E85BB6F94D7BD7C258F1404` |
| `lollo` | `docs/characters/references/lollo/source-01.png` | `391×426` | `C80304AFE1836325D782FC4E62136F97B9F6C149CD62CCEA9193A233CF555835` |
| `magno` | `docs/characters/references/magno/source-01.png` | `281×885` | `17CE00B8A0ECFA221A350F491369A6B5C2E043494B26E7C9D5ABEAD5D87712F6` |
| `marghe` | `docs/characters/references/marghe/source-01.png` | `816×1196` | `8C74E4A47DFC77C2AD6C17A04D85972A368F3B084E44379560782032ABEDF59A` |
| `marghe` | `docs/characters/references/marghe/source-02.png` | `341×521` | `2C4593CF49593CAF8BB4B216EB55EC3FD804D976CAAA531389E94AEB9A54336B` |
| `migi` | `docs/characters/references/migi/source-01.png` | `262×731` | `FE5F8E1F7B75B77297185F39D8736B3A9F2CDF0477269496B56F794EE3FC3028` |
| `zat` | `docs/characters/references/zat/source-01.png` | `267×424` | `D41903DA299BC961C17C8648071CFAC6C9F7FC531E77B5AF2E842E20F64EC523` |
| `zat` | `docs/characters/references/zat/source-02.png` | `382×503` | `378C0D88D143A6C3989B53F8FEE5430FAF188E3D1AAA9EFCCEE2338F6E590ED2` |
| `zat` | `docs/characters/references/zat/source-03.png` | `519×1128` | `9C3F986858C2E8F1E1598FE944A681E2787D4E34998B4CA329E23591AC51D510` |
| `zat` | `docs/characters/references/zat/source-04.png` | `643×1274` | `777BFD6809120E19E1A8B27B5BEC737117EFABF91FC7FBE8D807CEAD352F68E6` |

Reference locali ancora disponibili:

- `assets/art/ui/welcome/welcome_ability_cast_background.png` — **style e
  composition reference** per palette, linguaggio pixel-art e relazione tra i
  personaggi; non sostituisce le fotografie originali.
- `assets/art/characters/<id>/hd/poses.png` — **output master**, non reference
  fotografica; è utile per continuità di silhouette, scala e tre pose.

Il prompt comune B18U e le correzioni per personaggio restano in
`assets/art/characters/ASSET-MANIFEST.md`; gli originali recuperati e le
ricostruzioni dichiarate sono nella sezione seguente di questo archivio.

Ogni nuova foto richiede percorso, SHA-256, persona rappresentata, ruolo
ImageGen (`subject reference`) e conferma del proprietario. Non usare mai le
foto come asset runtime o per un output fotorealistico.

## Identity pass del cast — prompt delle strisce Player

### Stato delle fonti

I due prompt seguenti sono **prompt originali recuperati**, copiati senza
modificarne il testo da `img_char_prompts.md` il 2 settembre 2026 e verificati
per corrispondenza visiva con i master correnti (`aleo/hd/poses.png`,
`magno/hd/poses.png`). Il file sorgente è stato rimosso lo stesso giorno dopo
l'archiviazione verbatim: questo archivio resta il solo punto di
consultazione storico. I prompt per Alea, Bea, Lollo, Marghe, Migi e Zat non
sono presenti nel checkout come messaggi ImageGen originali: la sezione
successiva li dichiara invece **ricostruzioni probabili**, non prove storiche.

Fonti usate per le ricostruzioni: il prompt condiviso B18U e le correzioni nel
manifest del cast, `docs/characters.md`, i documenti
`docs/characters/<id>.md`, il fondale welcome come `style` e `composition
reference`, le fotografie in `docs/characters/references/<id>/` come `subject
reference` e il master `assets/art/characters/<id>/hd/poses.png` come `edit
target` quando serve preservare registrazione e scala.

### Aleo — originale recuperato

```text
Use case: identity-preserve
Asset type: revised three-frame 2D Godot character sprite strip for IL GIOCO

Input images:
- Image 1 is the real-person identity reference for Aleo. Preserve the recognizable broad facial structure, medium-length side-parted brown hair, rectangular dark eyeglasses, full brown beard and moustache, fair complexion, calm expression and stocky heavy build. Translate these traits respectfully into caricatural pixel art rather than photorealism.
- Image 2 is the exact current Aleo HD sprite-strip edit target. Preserve its canvas, three-cell horizontal layout, right-facing pose registration, full-body scale, baseline, spacing and crisp silhouette.
- Image 3 is the approved IL GIOCO welcome-screen style reference. Match its polished absurd arcade pixel-art language, dark outline, limited palette and chunky readable clusters.

Primary request: redesign Aleo so he resembles the person in Image 1 much more closely and is now clearly a thermotechnician/HVAC specialist who playfully controls heat and cold, not a mason or generic construction worker.

Subject and clothing: adult stocky thermotechnician with medium-length side-parted brown hair visible, rectangular dark glasses, full brown beard and moustache, fair skin and a friendly self-assured expression. Remove the hard hat. Replace the olive construction uniform with a practical dark charcoal work T-shirt under a compact work vest or utility harness. Use restrained warm orange/red accents on one side and icy cyan/blue accents on the other. Include work trousers, sturdy boots, protective gloves, compact HVAC manifold gauges and short red/blue service hoses or a small pipe-temperature probe integrated into the belt. Keep props compact and readable at 32x32; no bucket and no masonry trowel.

Pose requirements: exactly three equal-width registered right-facing full-body poses in one horizontal row: sturdy work step A, planted neutral idle, sturdy work step B. The two locomotion poses must differ clearly while identity, proportions, equipment placement, baseline and scale remain consistent.

Hot/cold theme: communicate heat and cold primarily through costume color accents, red/blue gauges, hose tips and tiny non-emissive thermal symbols on equipment. No large flames, ice clouds, attack effects, magic aura, floor effects or gameplay VFX in this sprite sheet.

Scene/backdrop: perfectly flat, uniform, solid #00ff00 chroma-key background over the entire canvas, with no shadows, gradients, texture, reflections, floor plane or lighting variation. Do not use #00ff00 anywhere in the subject.

Style/medium: polished caricatural arcade pixel art matching Image 3; crisp dark outline, limited color palette, chunky readable pixel clusters, intentionally humorous but respectful.

Composition/invariants: preserve Image 2's exact landscape canvas, three equal cells, generous padding, full body visibility, right-facing direction, center, baseline, scale, pose registration and no dividers. Keep all equipment inside its own cell.

Constraints: no real-world company branding, logos, trademarks, text, numbers or watermark; no extra characters; no helmet; no masonry tools; no machinery; no scenery; no photorealistic rendering; no cropped body parts; no duplicated poses; no object crossing between cells.
```

### Magno — originale recuperato

```text
Use case: identity-preserve
Asset type: revised three-frame 2D Godot character sprite strip for IL GIOCO

Input images:
- Image 1 is the real-person identity reference for Magno. Preserve the recognizable long oval facial structure, medium-length swept-back wavy brown hair, short full brown beard and moustache, fair complexion, gentle confident expression, tall proportions and athletic build. Translate these traits respectfully into caricatural pixel art rather than photorealism.
- Image 2 is the exact current Magno HD sprite-strip edit target. Preserve its canvas, three-cell horizontal layout, right-facing pose registration, full-body scale, baseline, spacing, muscular heroic silhouette and crisp outline.
- Image 3 is the approved IL GIOCO welcome-screen style reference. Match its polished absurd arcade pixel-art language, limited palette, dark outline and chunky readable clusters.

Primary request: redesign Magno so his human face, hair and beard resemble the person in Image 1 much more closely while preserving Magno's exaggerated muscular, seismic and bovine visual identity.

Subject: Magno is fully human, with swept-back medium-length wavy brown hair, a short full brown beard and moustache, fair skin, a long friendly face and calm self-assured smile inspired by Image 1. Keep an intentionally exaggerated broad chest, powerful shoulders, thick arms and heroic muscular legs, while retaining tall human proportions rather than a squat bodybuilder shape.

Bovine identity: preserve clearly readable but purely decorative bovine motifs: a rugged headband with two small stylized horn ornaments sitting in front of or around the hair without hiding it, a bold generic bull-head emblem on the dark sleeveless shirt, horn-shaped shoulder or belt details and earthy hide/leather accents. He must remain an ordinary human with human ears, nose, hands, feet and skin. No muzzle, hooves, tail, animal fur, animal skull head, real horns growing from the body or minotaur anatomy.

Clothing and palette: dark charcoal sleeveless athletic shirt inspired by the black shirt in Image 1, rugged brown earth-tone trousers, leather bracers, heavy boots, warm ochre/gold accents and only a small restrained teal stone accent if needed to preserve cast continuity. No logos, letters or numbers.

Pose requirements: exactly three equal-width registered right-facing full-body poses in one horizontal row: heavy seismic step A, planted powerful neutral idle, heavy seismic step B. The two locomotion poses must differ clearly while identity, hair, beard, proportions, costume, equipment placement, baseline and scale remain consistent.

Seismic theme: communicate weight and earth power through stance, heavy boots, stone-like accessories and earthy colors only. No cracks, dust clouds, shockwaves, glowing aura, floor effects or gameplay VFX in this sprite sheet.

Scene/backdrop: perfectly flat, uniform, solid #00ff00 chroma-key background over the entire canvas, with no shadows, gradients, texture, reflections, floor plane or lighting variation. Do not use #00ff00 anywhere in the subject.

Style/medium: polished caricatural arcade pixel art matching Image 3; crisp dark outline, limited palette, chunky readable pixel clusters, intentionally humorous but respectful.

Composition/invariants: preserve Image 2's exact landscape canvas, three equal cells, generous padding, full-body visibility, right-facing direction, center, baseline, scale, pose registration and no dividers. Keep every decorative element inside its own cell.

Constraints: preserve the person's recognizable hair, beard, facial proportions and friendly expression while keeping Magno muscular and bovine-themed; fictional game-character interpretation only; no real-world branding, logos, trademarks, text, numbers or watermark; no extra characters; no weapons; no scenery; no photorealistic rendering; no cropped body parts; no duplicated poses; no object crossing between cells.
```

### Prompt comuni ricostruiti — non originali

Questi testi sono il miglior recupero riproducibile della generazione allora
probabilmente usata. Non vanno citati come prompt effettivi: riuniscono solo
vincoli documentati prima o durante l'identity pass. Per ciascuno: Image 1 è
la fotografia indicata nel prospetto precedente (`subject reference`), Image 2
è il rispettivo `hd/poses.png` (`edit target`) e Image 3 è il fondale welcome
(`style and composition reference`).

Vincoli condivisi impliciti in ogni prompt: tre pose full-body rivolte a destra
in una riga orizzontale, passo A | idle | passo B, celle uguali, stessa
baseline/scala/registrazione, sfondo piatto `#00ff00`, pixel art arcade
caricaturale con outline scuro e palette limitata; niente testo, marchi,
fotorealismo, scenografia, ombre, corpo tagliato, pose duplicate o VFX di
gameplay.

| ID | Prompt ricostruito probabile |
|---|---|
| `alea` | Redesign Alea as a recognizable warm-blonde classical ballerina in ivory-white and gold, with a readable tutu and graceful elegant walking steps. Keep her human proportions and a poised friendly face. Make the three poses distinct but quiet and balanced; the circular ribbon and eagle of Gran Piroetta are separate VFX and must not appear in the sprite strip. |
| `bea` | Redesign Bea as a recognizable athletic roller skater with long dark curly hair, dark eyeglasses and her distinctive purple bandana. Give her a purple sporty jacket or top, wrist protection and visible inline skates. Use a believable skating locomotion cycle: one skate is always planted on the ground, never both skates lifted or a floating pose. No helmet, no blue waves, fire trail or Powerslide VFX in the strip. |
| `lollo` | Redesign Lollo as a recognizable lean, energetic dark-haired cosplayer with a compact retrofuturist wasteland survivor outfit: blue suit, yellow details, cyan goggles and original unbranded accessories. Keep both feet clearly on the baseline so he does not appear to float. Use an alert, fast but readable three-pose walk cycle; no existing franchise costume, logo, number or brand. |
| `marghe` | Redesign Marghe as a recognizable woman with very long dark hair and eyeglasses, a soft fuller body shape, and a confident rhythmic reggaeton dancer identity. Use a purple, magenta and gold outfit with readable silhouette and lively but registered walking steps. Preserve her warm expression; the shadow clone is separate VFX and must not appear in the strip. |
| `migi` | Redesign Migi as a recognizable calm woman with dark hair, eyeglasses and a collected expression, wearing a teal protective outfit with a compact segmented turtle-shell motif. Use deliberate, grounded walking poses and a restrained teal palette. The protective dome and slow-wave effects are separate VFX and must not appear in the strip. |
| `zat` | Redesign Zat as a recognizable agile medical/electric character with a neat brown/teal bob haircut, white-cyan uniform, teal gloves and a generic heart-shaped medical symbol. Use quick but grounded walking poses; no nurse cap, Red Cross symbol, electric bolt, healing light or other ability VFX in the strip. |

Le ricostruzioni vanno sostituite da messaggi ImageGen originali qualora questi
vengano ritrovati; fino ad allora servono come prompt di riuso, non come prova
di provenienza.
