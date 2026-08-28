# B18H pigeon sprites

Original assets commissioned for IL GIOCO on 2026-08-24 with the built-in
OpenAI image generation tool. No third-party image or character was supplied as
an input. The runtime game has no dependency on the generation service.

## Production prompt

Both strips requested the same right-facing caricatural pixel-art pigeon in
three registered poses: neutral, wings raised and wings lowered. The base
variant specifies gray-blue plumage, a light chest, green/violet neck and orange
beak/feet. The special variant specifies charcoal/indigo plumage, a magenta
collar and gold accents. Both require a dark outline, transparent background,
limited palette, no text, no watermark and no environment.

## Transformations and files

The generated three-cell sources were split into equal cells. Each cell was
resampled with nearest-neighbor to `44x44` and centered on a transparent `48x48`
canvas. The three canvases were then stored as one horizontal `144x48` RGBA PNG.
No color retouching or third-party source compositing was applied.

| Runtime file | Origin | Author | Usage status | SHA-256 |
|---|---|---|---|---|
| `pigeon_base.png` | Original OpenAI-assisted generation for IL GIOCO | Progetto IL GIOCO | Proprietary project asset; approved for this release | `3e909e0fb6ac79c7b6d3eea3b96d0357f50a2711e6d743a1e28068ddf417ee81` |
| `pigeon_special.png` | Original OpenAI-assisted generation for IL GIOCO | Progetto IL GIOCO | Proprietary project asset; approved for this release | `5a5c632c26c0c8484110c536feee569b45d623929776f85691768d0a1f523d28` |

The base strip is used by `scenes/actors/base_enemy.tscn`. The special strip is
registered in the same `SpriteFrames` resource for visual fixtures and future
data-driven variants, but it is not selected by the current spawner.

## B49 — Sprite degli archetipi speciali

- Data generazione: 28 agosto 2026.
- Origine: OpenAI ImageGen built-in. Autore: progetto IL GIOCO con assistenza
  OpenAI ImageGen. Licenza: Licenza del progetto.
- Prompt condiviso: sprite-sheet da arena, non icona UI; tre celle orizzontali
  uguali con lo stesso piccione rivolto a destra nelle pose ali su, neutra e ali
  giù; pixel-art 16-bit semplice, contorno scuro, palette limitata, nessun
  testo, UI, cornice, persona, ambiente, ombra o watermark. Sfondo chroma verde
  uniforme richiesto per ricavare l'alpha.
- Trasformazioni: ogni sorgente originale a chroma è conservata in `hd/`, poi
  `remove_chroma_key.py --auto-key border --soft-matte --transparent-threshold
  12 --opaque-threshold 220 --despill --edge-contract 1` ha prodotto il master
  RGBA. `tools/process-cast-sprite.ps1` estrae la componente opaca per ciascuna
  delle tre celle, la riduce nearest-neighbor e la centra in una cella `48×48`;
  l'output è uno strip `144×48` RGBA. `hd/.gdignore` esclude raw e master dagli
  import/export; solo gli strip sono candidati runtime.
- Stato: strip assegnati a `EnemyArchetypeDefinition.sprite_frames` per
  sciamatore, corazzato, divisore e tiratore (`data/enemies/*.tres`), con
  `AnimatedSprite2D` dedicato nelle rispettive scene
  (`configurable_enemy.tscn`, `splitter_enemy.tscn`, `ranged_enemy.tscn`).
  Il frammento del divisore resta sul disegno procedurale B40, senza texture
  propria. Nessun cambio a hitbox, parametri, spawn o comportamento. Verifica
  Windows eseguita il 28 agosto 2026 con le cinque sprite (base + quattro
  archetipi) renderizzate affiancate: restano distinguibili a colpo d'occhio.
  La verifica fisica su Pixel 9 in un'orda densa in gioco resta un gate B49.

| Archetipo | Direzione | Sorgente chroma SHA-256 | Master RGBA SHA-256 | Strip runtime | SHA-256 strip |
|---|---|---|---|---|---|
| Sciamatore | Arancio-marrone, rapido e compatto | `3677E8E7A7054069174BEAFC22A805A0435B253C46D7F9418BE40BDE194E461E` | `AA07E29750212C97E376A0634D2486A104338AA897CDAA2BAE13933211C5D882` | `pigeon_swarmer.png` (`144×48`) | `161F2B59EA28C87921F65441C76B91DF44359FB1B33CFD7A87AB63A66127F6C8` |
| Corazzato | Grigio massiccio, pettorale e casco da coperchio | `9D77E2F8E5CF58855A6A93321371759567507719D3B6C3482EF27568114921C9` | `2AB7F97E8AAFD1A9729C6FEDB9E4864073131F5A7EB268B6331F2BE1381A74AA` | `pigeon_armored.png` (`144×48`) | `32E29433FE87C4DF387AF4A8BD525D20A6415F9CA7F1CE1A56D6A1DC561E48B8` |
| Divisore | Viola rotondo, crepa lavanda e due testine emergenti | `D3F5965C538D8C5F150D3E3BDB7C957F5036F5D4A1FAC324688FE36EEEB2B614` | `1143F4D207303C682F35B6238FA896FFCE2503989805ADA0FEE6B64C07086E2D` | `pigeon_splitter.png` (`144×48`) | `F74250F3B8B0AF0FF812ABF95945B3F94709DC472028E11C5B14C59EC0DBA35C` |
| Tiratore | Teal snello, fionda piccola e leggibile | `10C17FCCE7D0B7545E502FFE7D1C6F237F772C7A4A3B417C4B53430948FD765E` | `02B21D8FB481AEDCEB597AAF1D7D4B6FB12AA31FF4498CD94DD4F3BCC64E1964` | `pigeon_ranged.png` (`144×48`) | `90E6F2B2FE5CA05A244AC74010CB74E1EDBE1A4899BD58D05821A072C10BF104` |
