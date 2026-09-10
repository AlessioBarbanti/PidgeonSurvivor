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

## Fondale originale ritirato

| Percorso | Generatore | Dimensioni | Trasformazioni | SHA-256 |
|---|---|---:|---|---|
| `assets/art/ui/character_select/hd/character_select_backdrop_cyan_legacy.png` | OpenAI ImageGen built-in | `1672x941` RGB PNG | Primo output selezionato, conservato come master storico fuori da import ed export quando il runtime e stato sostituito dalla variante bronzo | `8C48FA0F8480873B605E2436B6DF6265340CB933CE1C37ABB68106BA311AAC99` |

Il raster e soltanto decorativo. Testi, personaggi, icone, pannelli, focus e hit
target restano nodi Godot dati e non sono incorporati nell'immagine.

## Fondale selezione bronzo

Il 29 agosto 2026 il fondale blu/ciano del selettore e stato sostituito con una
variante interna in tavolozza notte, carbone e bronzo, coerente con le cornici
modali. Origine: progetto IL GIOCO; autore: progetto IL GIOCO con assistenza
OpenAI ImageGen; licenza: Licenza del progetto. Nessun testo, personaggio,
ritratto, oggetto interattivo o UI e incorporato nel raster.

```text
Use case: stylized-concept
Asset type: full-screen 16:9 background plate for the Godot character-selection screen of a dark pixel-art survivor game. It will sit behind dynamic portraits, text, cards and orange-gold buttons.
Primary request: create an empty, premium pixel-art character selection backdrop in a deep charcoal-black night palette, with muted antique bronze and warm ember-brown details. Replace any cyan/blue sci-fi feeling with a grounded dark tavern and forge atmosphere: shadowy timber beams, a distant unlit grill hearth, faint stone floor perspective, barely visible smoke and floating ember specks. The central 70 percent must stay calm, dark and low contrast for the selected character and UI.
Style/medium: polished 2D pixel art, sharp crisp game-ready finish, restrained fantasy arcade ornament.
Composition/framing: wide landscape background; use sparse dark bronze structural ornaments only at the outer edges and corners; central area unobstructed; no framing panel in the middle.
Lighting/mood: midnight tavern, subtle warm edge light, cinematic but quiet.
Color palette: nearly black charcoal, desaturated warm brown, dark bronze, antique muted gold, sparse deep burgundy; absolutely no cyan, electric blue, neon, or bright orange focal object.
Constraints: background plate only; no characters, creatures, portraits, hands, items, weapons, UI panels, buttons, arrows, logos, letters, numbers, readable signs, watermark, or border that would compete with the in-game modal frames. Keep it low contrast and leave generous calm negative space in the center.
```

| Percorso | Generatore | Dimensioni | Trasformazioni | SHA-256 |
|---|---|---:|---|---|
| `assets/art/ui/character_select/hd/character_select_backdrop_bronze_source.png` | OpenAI ImageGen built-in | `1536x1024` RGB PNG | Master originale, escluso da import ed export con `.gdignore` | `85A818FC25D9FE4D3A8ED367FA2D9AE869EE7C9FECBCF1D35E90413C83F21140` |
| `assets/art/ui/character_select/character_select_backdrop.png` | Derivazione deterministica | `1536x864` RGBA PNG | Crop verticale centrale da y=`80` a y=`944`, nearest-neighbor tramite System.Drawing; `TextureRect` aspect-cover nel runtime | `CAEBF8988BFB6BCB4CBEF213253E3BEE0BACC8871DB3842019E802259234CC16` |

Il ritratto correntemente selezionato usa inoltre la cornice nove-slice
`assets/art/ui/pause/pause_panel_frame.png`; le anteprime laterali e le due card
Passiva/Abilita restano volutamente piu sobrie.

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

## Base CTA arancione — proporzioni corrette (PS-155)

L'11 settembre 2026 il proprietario ha rigenerato personalmente il master HD
della placca arancione (`character_select_cta_source.png`, sostituito
in-place; la versione precedente resta come `character_select_cta_source_OLD.png`,
fuori da import/export) perche' i due grandi ornamenti a diamante ai lati
comprimevano otticamente l'altezza percepita della placca, rendendo il
pulsante "RIPRENDI" (arancione) visibilmente piu' alto del pulsante blu
affiancato nel menu di pausa a parita' di `custom_minimum_size`. Origine:
proprietario; licenza: Licenza del progetto.

| Percorso | Dimensioni | Trasformazioni | SHA-256 |
|---|---:|---|---|
| `assets/art/ui/character_select/hd/character_select_cta_source.png` | `2172x724` RGBA PNG (stesso canvas, contenuto visibile piu' basso) | Master fornito dal proprietario, escluso da import/export con `.gdignore` | `A70B6AE208F373832D9C3F7098500E957C7709001F89A95A88B5D15F6ECA17C1` |
| `assets/art/ui/character_select/character_select_cta_base.png` | `760x149` RGBA PNG (era `754x181`) | Bounds alpha soglia `8`, padding `4`, scala `35%` nearest-neighbor tramite `tools/process-character-select-cta.ps1` (stesso comando, nuovo master in input) | `D02E96381CC870C0BD0CDAB2294481B417FC6F597A9F545BCCA0255BD9132B13` |

Aggiornati di conseguenza, nelle 5 scene che riusano questo derivato
(`pause_overlay.tscn`, `welcome_screen.tscn`, `character_select_overlay.tscn`,
`tutorial_screen.tscn`, `end_screen.tscn`): la regione `AtlasTexture` da
`Rect2(0,0,754,181)` a `Rect2(0,0,760,149)`, e `texture_margin_top/bottom`
scalato in proporzione (era `34`→`28` dove il CTA e' quello principale delle
schermate welcome/selettore/tutorial, `24`→`20` dove e' quello piu' compatto
di pausa/fine partita). In `pause_overlay.tscn`, dove il problema era piu'
visibile, aggiunto anche un `content_margin_top`/`content_margin_bottom`
esplicito (`26`/`14`, non piu' il default implicito allineato al
`texture_margin`) per ricentrare il testo tutto-maiuscolo (senza discendenti)
rispetto alla placca piu' bassa.
