# Manifest grafico welcome B18O

Fondale originale prodotto il 24 agosto 2026 con la modalità built-in di OpenAI
ImageGen per la schermata iniziale di IL GIOCO. La variante runtime corrente usa
come edit target la reference pixel-art fornita dal proprietario del progetto
nella sessione del 24 agosto e integrata dopo la sua richiesta esplicita di
procedere. Non sono state usate fotografie o persone reali. Il runtime non
dipende dal servizio di generazione.

Origine: OpenAI ImageGen built-in.  
Autore: progetto IL GIOCO con assistenza OpenAI ImageGen.  
Licenza: Licenza del progetto.

## Logo welcome fornito

`welcome_logo.png` è stato fornito dal proprietario del progetto nella sessione
del 24 agosto 2026 con richiesta esplicita di usarlo al centro della welcome.
Autore, generatore e licenza a monte non sono stati dichiarati; il registro non
li inventa. Il file viene consumato senza trasformazioni come `TextureRect`
proporzionale. Il testo e l'insegna appartengono al logo, mentre pulsanti,
impostazioni, focus e target touch restano UI nativa Godot.
Il rebrand confermato nella stessa data riconosce come esatte le stringhe già
presenti nel raster: titolo `Pidgeon Survivor` e sottotitolo
`It's grilling time!`; il file non richiede trasformazioni.

## Prompt fondale base

```text
Use case: stylized-concept
Asset type: 16:9 game title-screen background for a Windows and Android friendship-survival arcade game
Primary request: create an original, polished pixel-art splash background that feels playful, warm, chaotic, and unmistakably like a real game menu rather than a debug screen
Scene/backdrop: a whimsical night-time outdoor survival arena inspired by an Italian summer party, with warm string lights, a few picnic tables and barbecue glow in the far background, subtle city silhouettes and an energetic flock of pigeons swooping around the outer edges
Subject: a small ensemble of eight distinct, silly chibi adventurer friends gathered along the lower left and lower right edges, ready for absurd action; readable as a friendly ensemble but not based on real people
Style/medium: professional hand-crafted 2D pixel-art arcade illustration, crisp clustered pixels, chunky silhouettes, limited but rich palette, playful caricature, not photorealistic, not painterly, not cyber-tech
Composition/framing: wide landscape 16:9; keep the central 45% of the canvas visually quiet, dark, and low-detail as protected negative space for a title and menu panel; place characters, pigeons, props, sparks, confetti, and brighter accents mainly around the left/right edges and lower corners; support safe cropping to 20:9 and 4:3
Lighting/mood: deep navy twilight, warm amber barbecue and string-light highlights, cyan moonlight accents, small magenta details; cheerful and adventurous with gentle depth
Color palette: deep navy and indigo base, warm amber and golden yellow, cyan highlights, restrained magenta accents; sufficient dark midtones behind UI
Constraints: no text, no letters, no numbers, no logo, no UI controls, no frame, no watermark; no realistic faces; no gore; no guns; no false obstacle grid; no bulky sci-fi panels; maintain strong readability and low contrast in the central UI-safe area; the image itself must fill the full canvas without a border
```

## Prompt prima variante cast abilità

```text
Use case: precise-object-edit
Asset type: 16:9 Windows and Android game welcome-screen background
Input images: Image 1 is the edit target and establishes the exact pixel-art style, environment, lighting, palette, framing, pigeon design, and protected central menu area.
Primary request: replace only the eight generic human adventurers in Image 1 with exactly eight original fictional characters whose clothing, pose, props, silhouette, and restrained VFX clearly communicate the approved IL GIOCO roster abilities. Do not base them on real people. Keep the rest of Image 1 visually unchanged.

Character replacements, exactly one of each:
1. Magno — a broad, powerful seismic strongman with a playful bovine motif such as small decorative horns or a bull emblem; planted stance; one fist causing a compact circular earthquake shockwave and a few ground cracks.
2. Bea — an agile inline roller skater caught in a dramatic low powerslide; sporty silhouette; a short curved trail of orange fire behind the skates.
3. Zat — a resourceful field nurse and storm healer carrying a compact medical satchel with a generic cyan heart symbol, never a Red Cross emblem; one hand emitting soft healing light while a yellow-cyan thunderbolt arcs overhead.
4. Alea — a graceful classical ballerina in mid grand pirouette; clear tutu/skirt silhouette and pointed pose; a bright circular motion ribbon with a subtle eagle-feather accent.
5. Aleo — a sturdy construction worker with hard hat, rolled sleeves, trowel and small cement bucket; a fresh gray cement splash hardening into a slowing patch near the boots.
6. Lollo — a hyperactive chaotic cosplayer wearing an original patchwork costume assembled from several generic archetypes, with a removable mask and colorful accessories; no copyrighted or recognizable franchise costume.
7. Migi — a calm meditating martial-arts monk or yogi; serene pose inside a translucent cyan turtle-shell shield and slow concentric zen waves.
8. Marghe — an energetic reggaeton street dancer in a confident rhythmic pose; magenta-gold beat accents and one flat shadow silhouette echoing the dance as a VFX clone, clearly not a ninth physical character.

Placement: preserve the existing eight character slots around the outer lower edges. Put Aleo in the upper-left slot; Magno, Alea, and Marghe across the lower-left group. Put Lollo in the upper-right slot; Migi, Bea, and Zat across the lower-right group. Keep every important face, prop, and effect outside the central 45% UI-safe area.

Style/medium: polished hand-crafted 2D pixel-art arcade illustration matching Image 1 exactly; crisp clustered pixels, chunky readable silhouettes, limited rich palette, expressive caricature, consistent scale and outline weight. Characters should feel like one cohesive friendship-survival cast, not unrelated costume mascots.
Lighting/mood: preserve the deep navy summer night, warm amber barbecue/string-light illumination, cyan moonlight, restrained magenta accents, and cheerful absurd-survival tone.
Composition/framing: preserve Image 1's 16:9 canvas, camera angle, moon, sky, pigeons, barbecue party environment, tables, props, ground perspective, and dark quiet center. Maintain safe crop behavior for 20:9 and 4:3.
Constraints: exactly eight physical human characters; the Marghe shadow clone is a flat translucent VFX silhouette only. No text, letters, numbers, logo, UI, buttons, frame, border, watermark, realistic faces, real-person likenesses, gore, guns, copyrighted costumes, Red Cross emblem, extra humans, or extra humanoids. Do not brighten, clutter, or populate the central menu-safe area. Change only the eight character designs and the small ability effects immediately around them; keep all other image elements unchanged.
```

## Prompt correzione cast — runtime corrente

```text
Use case: precise-object-edit
Asset type: 16:9 Windows and Android game welcome-screen background
Input images: Image 1 is the exact edit target.
Primary request: make only the following four targeted character corrections while preserving the entire image, the other four characters, and the central menu-safe space.

1. Migi — the seated zen character inside the glowing cyan turtle-shell shield near the center-right: redesign her as an adult woman with clearly visible black hair and readable glasses. She does not need to be a monk. Give her a relaxed modern teal-and-dark outfit, a calm seated pose, and a thoughtful friendly expression. Preserve the cyan turtle-shell shield and concentric slowing waves so her defensive Zen ability remains unmistakable.
2. Marghe — the reggaeton dancer in purple at the lower-left, next to the magenta shadow clone: make her visibly fuller-bodied and softly curvy, with very long flowing black hair. Preserve her energetic confident dance pose, purple street-dance clothing, magenta-gold beat accents, and flat shadow-clone VFX.
3. Bea — the roller skater performing the fiery powerslide in the lower-right foreground: add one clearly visible purple garment, preferably a purple sporty jacket or hoodie. Preserve her low powerslide pose, inline skates, speed arc, and orange fire trail.
4. Lollo — the cosplayer on the upper-right platform: redesign the costume as an original retro-futuristic post-apocalyptic lone-survivor cosplay, evoking a cheerful vault explorer through a blue utility jumpsuit with yellow trim, rugged boots, utility belt, improvised shoulder protection, and a weathered explorer accessory. Keep it an original design: no Fallout logo, no vault number, no Pip-Boy copy, no franchise iconography, and no exact reproduction of any copyrighted character. Preserve Lollo's hyperactive theatrical pose and removable cosplay prop.

Strict invariants: keep Magno, Alea, Aleo, and Zat unchanged. Preserve the exact 16:9 canvas size, hand-crafted pixel-art style, character positions, camera, moon, pigeons, barbecue party environment, lighting, palette, dark central 45% negative space, props, and crop safety. Keep exactly eight physical human characters; Marghe's shadow clone remains a flat translucent VFX silhouette, not a ninth person. Do not add, remove, or move characters. No text, letters, numbers, logos, UI, frame, border, watermark, realistic faces, real-person likenesses, guns, gore, branded costumes, or extra humanoids.
```

## Prompt correzione Bea — runtime corrente

```text
Use case: precise-object-edit
Asset type: 16:9 Windows and Android game welcome-screen background
Input images: Image 1 is the exact edit target.
Primary request: modify only Bea, the inline roller skater in the purple sporty jacket performing a fiery low powerslide in the lower-right foreground.

Bea correction: remove her orange helmet completely. She must have no helmet, cap, hat, hood, headband, or other headwear. Replace the helmet with long, voluminous, naturally curly hair in the same dark hair color already visible on the character. The curls should be clearly readable as long and curly, flowing backward with the speed of the powerslide while keeping her face unobstructed. Preserve Bea's friendly expression, purple jacket, body proportions, exact low skating pose, inline skates, cyan speed arc, and orange fire trail.

Strict invariants: change only Bea's head and hair. Keep Migi, Marghe, Lollo, Magno, Alea, Aleo, and Zat exactly unchanged. Preserve all eight character positions, every other costume and face, Marghe's shadow-clone VFX, the exact 16:9 canvas, pixel-art style, palette, lighting, moon, pigeons, barbecue party scenery, props, central dark menu-safe space, and crop safety. Keep exactly eight physical human characters. Do not add or remove people, effects, text, letters, numbers, logos, UI, watermark, frame, realistic rendering, real-person likeness, guns, gore, or branded elements. This is a single-character helmet-removal and hairstyle edit only.
```

## Prompt correzione Lollo e Zat — runtime corrente

```text
Edit the supplied finished 16:9 pixel-art game welcome illustration with two precise character corrections only.

1) LOLLO: He is the man standing on the small upper-right platform, wearing the original blue-and-yellow retro-futuristic post-apocalyptic survivor cosplay with goggles. Change only his hair color so it is clearly dark: near-black or very dark brown. Keep his existing hairstyle, goggles, face, costume, pose, proportions, lighting, platform, and non-branded original design exactly unchanged.

2) ZAT: She is the rightmost electric field nurse in the lower-right character group, behind/near Bea, currently casting cyan healing light and yellow-cyan lightning. Give her a clear neat chin-length bob haircut ("caschetto" means a bob haircut, absolutely NOT a helmet or any headgear), preserving her existing teal hair color. Make her outfit unmistakably a white-and-teal nurse uniform: a practical clean nurse tunic or dress with collar and belt, with a generic cyan heart medical emblem; do not use a Red Cross emblem. Preserve her face, pose, position, healing glow, lightning power, body proportions, and lighting.

Preserve every other person exactly as in the source: Bea remains helmetless with long dark curly hair and a purple garment while powersliding; Migi remains a woman with glasses and black hair inside the turtle shield; Marghe remains fuller-bodied with extremely long black hair; Magno, Alea, and Aleo remain unchanged. Preserve the exact environment, composition, pixel-art rendering, palette, central negative space for UI, effects, crop, and 16:9 framing. Exactly eight physical human characters total. Do not add, remove, duplicate, move, resize, or redesign any character. No text, letters, numbers, logos, watermarks, borders, UI, extra limbs, helmets, or additional figures.
```

## Prompt pulizia reference e ricomposizione cast — runtime corrente

```text
Use case: precise-object-edit
Asset type: 16:9 Windows and Android game welcome-screen background
Input images: Image 1 is the edit target and visual reference.

Primary request: turn Image 1 into a clean background plate for a native responsive Godot menu. Remove every baked-in interface element from the center: remove the entire wooden "Pidgeon Survivor" title sign, the subtitle ribbon, the large dark menu frame, both baked buttons, every word, every letter, every icon, and every UI decoration attached to those panels. Reconstruct the concealed night sky, distant town, stone ground, party lighting, and scenery seamlessly in the exact same polished hand-crafted pixel-art style.

Composition: create a protected central UI-safe region spanning approximately x=31% to 69% and y=9% to 70% of the canvas. Keep this region dark, quiet, low-detail, and completely free of people, faces, bodies, props, pigeons, bright VFX, signs, frames, and text. It will hold a native title plaque and two native buttons. Preserve the moon, flying pigeons, barbecue glow, string lights, city silhouettes, platforms, tables, and warm night-party atmosphere around the outer edges.

Characters: preserve exactly the same eight fictional human characters, their designs, faces, clothing, poses, abilities, scale, and pixel-art rendering:
- Aleo, upper-left construction worker with hard hat, trowel, and bucket.
- Magno, lower-left broad seismic strongman with bovine motif.
- Alea, classical ballerina with golden circular pirouette ribbon.
- Marghe, fuller-bodied reggaeton dancer in purple with extremely long black hair and a flat magenta shadow-clone VFX.
- Lollo, upper-right blue-and-yellow original retro-futuristic survivor cosplayer with clearly dark hair and goggles.
- Migi, woman with glasses and black hair inside the cyan turtle-shell shield.
- Bea, helmetless inline skater with long dark curly hair, purple jacket, and fiery powerslide.
- Zat, electric field nurse with a neat teal chin-length bob haircut, no headgear, white-and-teal nurse uniform, cyan heart emblem, healing light, and yellow-cyan thunderbolt.

Move characters only as much as required to keep their complete faces, heads, identifying clothing, and ability props outside the protected central region. Shift Marghe farther toward the lower-left group; shift Migi and Bea farther toward the lower-right group. Keep everyone naturally grounded and fully readable. Limbs or subtle trails may approach the center, but no face or torso may sit behind the future menu area. Preserve the friendly ensemble balance and safe cropping for 20:9 and 4:3.

Style/medium: match Image 1 exactly—professional crisp clustered 2D pixel art, chunky readable silhouettes, rich limited palette, expressive caricature, deep navy night, warm amber light, cyan highlights, restrained magenta accents.

Strict constraints: exactly eight physical humans total; Marghe's shadow clone remains a flat translucent VFX silhouette and not a ninth person. No text, letters, numbers, logos, watermark, UI, buttons, panels, plaques, frames, borders, realistic faces, real-person likenesses, gore, guns, copyrighted costumes, Red Cross emblem, extra humans, or humanoids. Do not redesign any character. Do not add new objects. The output must be only the clean full-canvas background illustration.
```

L'output built-in grezzo è un PNG RGB `1711×919`, SHA-256
`19726b70acbb2b8b55ac9fcb192024e8c26deff8bb6ba6510ad7598f77f157ce`.
Per ripristinare il contratto 16:9 è stato applicato un crop centrale senza
ricampionamento: `38 px` a sinistra e `39 px` a destra. Nessun ritocco manuale,
ridimensionamento o testo raster è stato aggiunto.

## File runtime

| Percorso | Dimensioni | Trasformazioni | SHA-256 |
|---|---:|---|---|
| `welcome_party_background.png` | `1672×941` RGB PNG | Fondale base conservato per confronto; output built-in copiato senza alterazioni | `06b6509bd7f2b4e0078b3bafe640404f4990bea4a7c0b0bd4124abd9cc573bed` |
| `welcome_ability_cast_background.png` | `1634×919` RGB PNG | Edit ImageGen della reference, poi crop centrale 16:9 senza ricampionamento; mostrato con `KEEP_ASPECT_COVERED` più tint runtime | `93f85fd7f2a76f889a56961ed17dde667e0c8621ee085fe402aa0349f17c24d0` |
| `welcome_logo.png` | `1536×1024` RGBA PNG | Versione finale modificata e fornita dal proprietario, nessuna trasformazione locale; visualizzata proporzionalmente in un `TextureRect` centrale | `c2a63add4753ece374cf673d636d12cce55e55cd43624aed645bf8f5c347fa9f` |

Il fondale è dedicato alla welcome e non sostituisce lo sfondo arena pianificato
in B18S. Il pannello, il titolo e i pulsanti restano UI nativa Godot per
preservare testo esatto, focus, safe area e accessibilità multipiattaforma.
