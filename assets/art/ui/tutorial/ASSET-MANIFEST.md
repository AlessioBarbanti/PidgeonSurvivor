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
