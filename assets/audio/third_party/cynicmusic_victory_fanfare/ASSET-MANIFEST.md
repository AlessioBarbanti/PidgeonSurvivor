# Victory music (PS-080)

`victory_music.wav` is the `GameAudio` end-run victory track: a short musical
cue distinct from the existing `VICTORY` SFX jingle, played once when the run
ends in `RunController.RunState.VICTORY`.

## Victory Fanfare Short

| Field | Value |
|---|---|
| Runtime file | `victory_music.wav` |
| Official original | `Heavy_ConceptB.wav` |
| Author | cynicmusic (http://cynicmusic.com) |
| Official source | https://opengameart.org/content/victory-fanfare-short |
| Direct official download | https://opengameart.org/sites/default/files/Heavy_ConceptB.wav |
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
| Format | WAV, PCM 16-bit, stereo, 44100 Hz, ~11.9 s |
| SHA-256 | `CF7ACA1193530C804F41A22CFD9A2813C25D3C244FA96AD88C88C6206DAA033D` |

The OpenGameArt page describes it as "a several bar victory fanfare for RPG,
boss win, etc.", licensed CC0. The author's page additionally invites contact
for attribution if used, but CC0 does not require it; the project credits it
voluntarily in `docs/credits.md` regardless.

`../LICENSE-CC0-1.0.txt` is the unmodified CC0 1.0 legal code downloaded from
https://creativecommons.org/publicdomain/zero/1.0/legalcode.txt (SHA-256
`A2010F343487D3F7618AFFE54F789F5487602331C0A8D03F49E9A7C547CF0499`).
