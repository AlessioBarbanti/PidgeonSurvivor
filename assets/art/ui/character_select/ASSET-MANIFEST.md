# Manifest fondale selezione personaggi B18W

Il fondale raster del selettore e stato prodotto il 25 agosto 2026 con OpenAI
ImageGen built-in, usando il mockup fornito dal proprietario soltanto come
riferimento di atmosfera, palette e finitura. Origine: progetto IL GIOCO;
autore: progetto IL GIOCO con assistenza OpenAI ImageGen; licenza: Licenza del
progetto. Non sono stati incorporati personaggi, testi, marchi, icone o pannelli
del riferimento.

## Prompt finale selezionato

```text
Use case: ui-mockup
Asset type: reusable full-screen raster background plate for a Godot 4 character-selection screen
Input image: use the user's attached mockup only as a visual reference for palette, pixel-art finish, ornamental framing, and dark action-RPG atmosphere; do not copy its characters, text, panels, buttons, or layout.
Primary request: create an empty premium pixel-art action-RPG menu backdrop in deep midnight navy, designed to sit behind native Godot controls.
Composition/framing: landscape 16:9; a thin ornate dark steel and carved-stone outer frame hugs all four edges, with small cyan-blue crystal ornaments in the four corners; the entire central 85% remains open, calm, low-contrast, and readable for dynamic UI. Add only very subtle smoky nebula texture above and a faint dark stone floor texture below.
Style/medium: crisp polished pixel art, coherent with a modern indie survivors game, restrained fantasy ornament, sharp nearest-neighbor-friendly edges.
Color palette: near-black navy, deep desaturated blue, gunmetal, sparse electric cyan highlights; no warm focal colors.
Constraints: background plate only; absolutely no people, characters, creatures, portraits, icons, cards, panels, buttons, arrows, logos, typography, readable symbols, watermark, or baked UI labels. Keep decoration at the edges so responsive controls remain readable. No photorealism, no 3D render, no blur.
```

## File runtime

| Percorso | Generatore | Dimensioni | Trasformazioni | SHA-256 |
|---|---|---:|---|---|
| `assets/art/ui/character_select/character_select_backdrop.png` | OpenAI ImageGen built-in | `1672x941` RGB PNG | Output selezionato copiato senza crop, ritocco, testo o riscrittura; il runtime lo usa come `NinePatchRect` per preservare cornice e angoli su 16:9, 20:9 e 4:3 | `8C48FA0F8480873B605E2436B6DF6265340CB933CE1C37ABB68106BA311AAC99` |

Il raster e soltanto decorativo. Testi, personaggi, icone, pannelli, focus e hit
target restano nodi Godot dati e non sono incorporati nell'immagine.

## Base CTA ornamentale

La base del pulsante e stata generata separatamente con OpenAI ImageGen
built-in, senza testo. Il generatore ha restituito direttamente un PNG RGBA:
il controllo locale ha rilevato angoli con alpha `0` e bounds visivi
`2145x510` dentro il canvas `2172x724`; non e stata quindi necessaria la
rimozione chroma-key.

```text
Use case: ui-mockup
Asset type: text-free reusable CTA button base for a Godot 4 pixel-art action-RPG menu
Primary request: create one wide horizontal ornamental button plaque, centered and fully isolated on a perfectly flat solid #00ff00 chroma-key background for background removal.
Subject: a premium burnt-orange and dark-bronze fantasy action-RPG button base, approximately 5:1 width-to-height; double gold pixel-art bevel, inset inner frame, subtle hammered-metal texture, symmetrical small diamond-shaped end ornaments, strong readable empty central area for dynamic text.
Style/medium: crisp polished pixel art, restrained dark steel fantasy ornament matching a midnight-navy menu with cyan crystal corners; clean game-ready silhouette, sharp nearest-neighbor-friendly edges.
Color palette: burnt orange, amber, antique gold, dark bronze, near-black edge accents; do not use green anywhere in the button.
Composition: generous uniform green padding on all sides; front-facing orthographic UI asset; perfectly horizontal and symmetrical.
Constraints: no text, no letters, no numbers, no logo, no character, no icon other than abstract geometric diamonds, no watermark. The background must be one uniform #00ff00 with no gradient, texture, floor, lighting variation, shadow, reflection, glow, or green spill. Keep every ornament attached to the single button silhouette; no detached particles.
```

| Percorso | Generatore | Dimensioni | Trasformazioni | SHA-256 |
|---|---|---:|---|---|
| `assets/art/ui/character_select/hd/character_select_cta_source.png` | OpenAI ImageGen built-in | `2172x724` RGBA PNG | Master originale, escluso da import ed export con `.gdignore` e preset | `6795351B24BBADBB5B8D84C34C71377D30370CB3C4C1DAC9C2FE435C734D90FC` |
| `assets/art/ui/character_select/character_select_cta_base.png` | Derivazione deterministica | `754x181` RGBA PNG | Bounds alpha con soglia `8`, padding `4`, scala `35%` nearest-neighbor tramite `tools/process-character-select-cta.ps1`; il testo dinamico non e incorporato | `03AA00A7C86264DDEEB4FE681C1F5268216B7602CFBF89BA7C35F723B0F7D43D` |
| `assets/art/ui/character_select/hd/secondary_button_cta_source.png` | Fornito dal proprietario | `2172x724` RGBA PNG | Master originale, escluso da import ed export con `.gdignore` e preset; placca blu e oro senza testo | `753C48D69DE071E2640B7807C75C5994FD846D5B982B07A87BB46CD53A85DFD1` |
| `assets/art/ui/character_select/secondary_button_cta_base.png` | Derivazione deterministica | `667x127` RGBA PNG | Bounds alpha con soglia `8`, padding `4`, scala `35%` nearest-neighbor tramite `tools/process-character-select-cta.ps1`; il testo dinamico non e incorporato | `ADECF80340F2808442B9CF3400EDD3283FADEA4603E7B610B569691DE6A48971` |
