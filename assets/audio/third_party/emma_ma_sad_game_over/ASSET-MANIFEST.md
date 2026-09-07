# Defeat music (PS-080)

`defeat_music.wav` is the `GameAudio` end-run defeat track: a short musical
cue distinct from the existing `DEFEAT` SFX jingle, played once when the run
ends in `RunController.RunState.DEFEAT`.

## Sad game over

| Field | Value |
|---|---|
| Runtime file | `defeat_music.wav` |
| Official original | `sad_game_over.wav` |
| Author | Emma_MA |
| Official source | https://opengameart.org/content/sad-game-over |
| Direct official download | https://opengameart.org/sites/default/files/sad_game_over.wav |
| License | Creative Commons Zero 1.0 Universal (CC0 1.0) |
| Acquired | 7 September 2026 |
| Transformation | Downloaded from the official OpenGameArt file URL; renamed only for the
runtime convention. No re-encoding: the runtime file is byte-identical to the
download. ffmpeg is not available in this environment; the project already
has precedent (`../matthewpablo_vilified/ASSET-MANIFEST.md`,
`../artisticdude_swishes/ASSET-MANIFEST.md`) for keeping a delivered file in
its original format when Godot imports it natively — Godot 4 imports WAV
natively as `AudioStreamWAV`. This track is a one-shot cue, never looped, so
no loop flag is set at runtime. |
| Format | WAV, PCM 16-bit, stereo, 44100 Hz, ~19.0 s |
| SHA-256 | `4C36050C26197C339373CDD885EC6881F9F89899852AA574C4F58C7AEBCAD32A` |

The OpenGameArt page describes it as a melancholic electric piano composition
"released into the public domain as of January 2017", designed for
game-over/death screen scenarios. CC0 does not require attribution; the
project credits it voluntarily in `docs/credits.md` regardless.

`../LICENSE-CC0-1.0.txt` is the unmodified CC0 1.0 legal code downloaded from
https://creativecommons.org/publicdomain/zero/1.0/legalcode.txt (SHA-256
`A2010F343487D3F7618AFFE54F789F5487602331C0A8D03F49E9A7C547CF0499`).
