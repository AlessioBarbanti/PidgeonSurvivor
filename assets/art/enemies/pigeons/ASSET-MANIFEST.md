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
