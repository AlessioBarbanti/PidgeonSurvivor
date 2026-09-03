# Boss music (PS-073)

`boss_music_loop.mp3` is the `GameAudio` boss track: it replaces the run
background music for the duration of `BOSS_INTRO` and the boss fight, and the
run music resumes from where it was interrupted once the Boss is defeated.

## Vilified (2012)

| Field | Value |
|---|---|
| Runtime file | `boss_music_loop.mp3` |
| Official original | `Vilified (2012)_0.mp3` |
| Author | Matthew Pablo |
| Official source | https://opengameart.org/content/vilified |
| Direct official download | https://opengameart.org/sites/default/files/Vilified%20%282012%29_0.mp3 |
| License | Creative Commons Attribution 3.0 (CC-BY 3.0) — **attribution required**, unlike every other audio asset integrated so far in this project |
| Acquired | 4 September 2026 |
| Transformation | Downloaded from the official OpenGameArt file URL; renamed only for the runtime convention. No re-encoding: the runtime file is byte-identical to the download. ffmpeg is not available in this environment and the project already has precedent (`../artisticdude_swishes/ASSET-MANIFEST.md`) for keeping a delivered file in its original format when Godot imports it natively — Godot 4 imports MP3 natively as `AudioStreamMP3`, which exposes the same `loop` property as `AudioStreamOggVorbis`. `GameAudio` enables looping on the boss stream the same way it already does for the run/menu OGG streams. |
| Format | MP3, 320 kbps CBR, 5:16 | 
| SHA-256 | `59BE12C712BC9E67E8DF323CAA926F77839B7C2299AE11E5E8049628F20D8DBB` |

The OpenGameArt page credits only Matthew Pablo and describes the piece as
"an epic orchestral-rock track with a very electronic feel towards the end".
The file's own ID3 tags additionally list "Matthew Pablo & Raayl" as
participating artists; since the license page — the authoritative source for
CC-BY attribution — names only Matthew Pablo, the credit in `docs/credits.md`
follows the page but mentions Raayl's ID3 credit for transparency.

Unlike `../super_wreck_roadway_loop.ogg`, this is a full song rather than a
track engineered as a seamless loop: it has no dedicated loop point, so a
restart-from-start seam may be audible on a boss fight long enough to loop.
This is a perceptual concern for the manual gate in PS-073, not something to
fix by re-encoding without the owner's direction.

CC-BY 3.0 requires attribution: the credit lives in `docs/credits.md` and is
**not optional** here, unlike the voluntary CC0 credits for the project's
other audio assets.
