# Tutorial artwork manifest

## `tutorial_story_strip.png`

- Date: 2026-08-28.
- Generator: OpenAI built-in ImageGen (`image_gen`), generation
  `01a048a2-200d-7e62-a226-aa9a036d6c59`.
- Author: OpenAI, directed by the project owner and Codex.
- License: project-specific generated artwork; no third-party source material
  is embedded or redistributed.
- Role: HD source strip for the B54 objective, movement and Boss lessons.
- Style reference: the current welcome screenshot was supplied only as palette,
  finish and mood guidance. The prompt explicitly prohibited tracing, cropping,
  compositing or reusing its characters, logo, UI, icons and sprites.
- Prompt: create a polished fantasy pixel-art strip with three equal scenes:
  surviving a pigeon horde around a grill ember; moving while automatically
  firing at the nearest pigeon; reading a giant pigeon Boss telegraph and
  escaping through a cyan safe gap. No text, HUD, controller symbols, existing
  assets, debug geometry, 3D render or watermark.
- Source dimensions: `2172×724` RGBA PNG.
- Source SHA-256:
  `3EFE92E23D9A502A860D8A4E4B47A22A4837D64FC05C0A9C48D0C71CC5362079`.

## Runtime derivation

The three `718×718` runtime PNGs are deterministic interior crops of the source
strip. A three-pixel inset removes the outer frame; panel origins are `x=3`,
`x=727` and `x=1451`, all at `y=3`. No resampling, repainting or screenshot
content is introduced.

| Runtime file | Role | SHA-256 |
|---|---|---|
| `generated/tutorial_objective.png` | Survive the horde | `1811E97686A759B0F9570386FD783AC440135D12BDA317A79549CCAF87C9ADB1` |
| `generated/tutorial_movement.png` | Move and auto-fire | `2049839CF681C90D20A5604793C1063DB920067287CF7D8CBDE20EEC48F66914` |
| `generated/tutorial_boss.png` | Read the Boss telegraph | `C83D23FCBB80F9C9E8512063CAE1EF26A6F9E6DF0020CEA69DF34A5E0E5C2347` |

The remaining B54 lessons intentionally reuse existing approved runtime icons:
ability icons under `assets/art/icons/abilities/generated/`, upgrade icons under
`assets/art/icons/upgrades/generated/`, and enemy icons under
`assets/art/icons/enemies/generated/`.

## PS-049 — `tutorial_ability_button.png`, `tutorial_pickups.png`, `tutorial_telegraphs.png`

Replaces the three `fake_tutorial_*.png` placeholders wired by PS-048 (removed
from `generated/`, never referenced again) with definitive illustrations. Each
file is a **composite**, not a single AI generation: an ambient background
generated with ImageGen (via Codex CLI's built-in `gpt-image` tool, MCP
`imagegen` plugin), with the gameplay-accurate elements — the ones the
acceptance criteria require to be faithful, not merely evocative — composited
on top **deterministically** with Python/Pillow, using either real runtime
pixels or the exact geometry/colors read from the runtime scripts. No AI
generation was used for any element that needs to match the runtime exactly.

### Backgrounds (ImageGen, Codex CLI `gpt-image`, `high` quality, `1024×1024`)

Generated in one `generate_image_set` session for a shared style guide (warm
painterly pixel-art consistent with `tutorial_objective.png` /
`tutorial_movement.png` / `tutorial_boss.png`, deep navy shadows, warm ember
highlights, no characters, no text, no existing UI, no watermark).

- Style guide: "Pidgeon Survivor tutorial-illustration family: warm, painterly
  pixel-art, same finish as the game's dungeon/backyard camp scenes — soft
  painted pixel clusters (not flat vector, not photographic), deep navy-black
  shadows (#070E1B–#0E1725), warm ember/amber highlights (#F59A24, #DBB060),
  restrained cool accents only where noted. Nighttime backyard-grill setting,
  cobblestone or packed-dirt ground, subtle ambient glow, gentle vignette
  toward the edges. No characters, no readable text, no logos, no watermark,
  no existing game UI chrome (no health bars, no buttons, no icons pasted
  in) — these are pure atmospheric backdrops that other elements will be
  composited onto afterward. Square 1:1 compositions, edge-to-edge (no
  border, no frame)."
- `bg_ability_corner` prompt: "Bottom-right corner of a cobblestone
  backyard-grill courtyard at night, seen from above at a slight isometric
  tilt. Warm dim ambient light from an off-frame campfire in the upper-left,
  long soft shadows stretching toward the lower-right. The lower-right corner
  itself fades into a soft dark vignette suggesting the edge of a screen.
  Ground texture only: worn stone tiles, faint moss, a sliver of a wooden
  bench at the top edge. Calm, empty, ready to host a glowing circular UI
  dial in the corner later." — used under `tutorial_ability_button.png`.
- `bg_pickups_ground` prompt: "Wide cobblestone courtyard floor at night lit
  by warm firelight from the top of frame, seen from above at a slight
  isometric tilt. Empty except for ambient scattered embers and a couple of
  soft warm light pools on the stones. Calm and uncluttered so three small
  glowing objects can be composited on top later, left-to-right across the
  middle of the frame." — used under `tutorial_pickups.png`.
- `bg_telegraphs_arena` prompt: "Dark stone arena floor at night, viewed from
  above at a slight isometric tilt, matching the mood of a giant pigeon boss
  battle: worn flagstones, faint embers drifting, a subdued reddish-orange
  ambient glow pulsing up from the ground as if a magic circle is about to
  appear, deep shadow toward the edges. Empty center-ground so three separate
  glowing warning shapes can be composited on top later, arranged left,
  center and right." — used under `tutorial_telegraphs.png`.

### `tutorial_ability_button.png`

Shows the real HUD ability dial (`TouchAbilityButton`) in its two states,
side by side, at the bottom of the frame (screen-corner hint from the
background itself, no fake HUD added).

- Ready state (right): a real, undoctored crop of the ability button at
  runtime, taken from
  `exports/ui-screenshots/pixel9-20x9/04_gameplay_hud.png` (regenerated for
  this card via `godot_console --path . --script
  tools/_capture_ui_screenshots.gd`, after `godot_console --headless
  --editor --path . --quit` to refresh the import cache) — same gold ring,
  same `earthquake.png` ability icon (Magno's, the roster's default
  character), same floor texture.
- Recharging state (left): the same real crop, edited pixel-exactly with the
  runtime's own formulas from `scripts/ui/touch_ability_button.gd`
  (`_draw_cooldown_sector` / `_draw`): the gold ring pixels are recolored to
  `Palette.ORANGE` (`#F59A24`), a dark pie-slice (`RGBA 5,8,14,209`, matching
  `COOLDOWN_OVERLAY_COLOR`) is drawn clockwise from 12 o'clock covering 55%
  of the circle, and a countdown digit is drawn in `Palette.CREAM`. Not an AI
  reinterpretation: same pixels, same math as the runtime widget.
- Both discs are pasted with a matched circular alpha mask and a soft glow
  onto `bg_ability_corner`, then the composite is downscaled.

### `tutorial_pickups.png`

Shows the XP → level-up-card sequence as the main, connected row, with the
heal pickup placed lower and separate (own glow color, own heart accent, not
on the arrow path) so it does not read as a mandatory step.

- XP crystal: redrawn at high resolution from the exact vertices and colors
  in `scripts/progression/experience_pickup.gd` (`outer_points`,
  `inner_points`, `outline_color`, `body_color`, white center dot) — same
  silhouette and palette as the runtime pickup, only bigger and with an added
  soft glow and a gentle gem-facet shade for polish.
- Heal pickup ("coscia di piccione"): the existing definitive sprite reused
  as-is, cropped to its alpha bounds — `assets/art/pickups/hd/health_pickup.png`
  (see the pickups manifest for its own provenance). No redraw.
- Level-up card: no runtime texture exists for this (it's a pure Control
  panel), so it is a stylized panel drawn to match the real chrome sampled
  from `exports/ui-screenshots/pixel9-20x9/05_upgrade_overlay.png` (dark
  slate fill, thin steel-blue border), topped with the existing
  `assets/art/icons/upgrades/generated/a_tutta_brace.png` icon and generic
  body-copy bars (no baked text, consistent with the textless sibling
  illustrations).

### `tutorial_telegraphs.png`

Shows the three real Boss telegraph shapes from
`scripts/bosses/first_boss.gd` (`_draw_active_telegraph` /
`_draw_signature_telegraph`), redrawn at high resolution with the exact
`BossDefinition.telegraph_color` (`RGBA 255,61,46,184` ≈ `Color(1.0, 0.24,
0.18, 0.72)`) and a soft outer glow:

- Line (left): matches the Signature `TRAIL_CORRIDOR` mode (e.g. Evil Bea's
  Powerslide) — a glowing corridor with a bright edge and an arrowhead.
- Ring (center): matches `RADIAL_VOLLEY` — a ring outline with eight radial
  tick spokes, same as the boss's own volley telegraph.
- Area (right): matches `TARGETED_BLAST` — a filled translucent circle with
  a bright edge and a white crosshair.

All three are given equal size and visual weight so none reads as the Boss's
"universal" signal.

### Generator, authorship and license

- Generator (backgrounds only): OpenAI `gpt-image`, invoked through Codex
  CLI by the `imagegen` MCP plugin (`generate_image_set`).
- Compositing (all gameplay-accurate elements): deterministic Python/Pillow
  script, not AI — crops, alpha masking, procedural shape drawing from
  runtime source values, and resizing only.
- Author: OpenAI (backgrounds), directed by the project owner and the
  Game Art Designer agent; compositing by the Game Art Designer agent.
- License: project-specific generated/composited artwork; no third-party
  source material is embedded or redistributed.

### Runtime derivation

Master canvases are `1024×1024` RGB (background resolution, the ceiling of
useful detail given the source crops involved). The runtime derivative is a
single deterministic `LANCZOS` resize to `718×718` — no crop, no repaint —
matching the square canvas already validated by PS-048.

| Illustration | Master HD (excluded from import/export) | SHA-256 master | Runtime derivative | SHA-256 runtime |
|---|---|---|---|---|
| Ability button | `hd/tutorial_ability_button.png` (`1024×1024`) | `A9C9283FFA24737FEFF4AAE4D7A7B4D77AC1F16C0C5C37FFC83A12E9675FED84` | `generated/tutorial_ability_button.png` (`718×718`) | `F71AD339CF4B381A992A0210ADCD796268B89041D6B6CAB78488439DA399CEB9` |
| Pickups | `hd/tutorial_pickups.png` (`1024×1024`) | `7717FBD24C1EEBFD187401AD60D14CD7E72D6564719FF78BDC7130BAC4BF51D7` | `generated/tutorial_pickups.png` (`718×718`) | `7B1F9757F0391CE4A779322718C7FF6E058EA62257E06E37D6EF2012BFB252B5` |
| Telegraphs | `hd/tutorial_telegraphs.png` (`1024×1024`) | `1C41AD764FDF1382BEFDBFF118B25F30919DE6EA89227EABC440A546B7215022` | `generated/tutorial_telegraphs.png` (`718×718`) | `28C4087E0C9C84DF25D95115FACCF3DDBE72F36724C6C7BAD085EA0986841C39` |

`hd/.gdignore` and the three export presets (fixed by this card to also list
`assets/art/ui/tutorial/hd/**`, which was missing) keep every master out of
import, EXE, APK and AAB.
