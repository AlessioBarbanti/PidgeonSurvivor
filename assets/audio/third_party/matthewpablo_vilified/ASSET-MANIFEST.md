# Boss music (PS-073)

`boss_music_loop.ogg` is the `GameAudio` boss track: it replaces the run
background music for the duration of `BOSS_INTRO` and the boss fight, and the
run music resumes from where it was interrupted once the Boss is defeated.

## Vilified (2012)

| Field | Value |
|---|---|
| Runtime file | `boss_music_loop.ogg` |
| Repository master | `hd/boss_music_loop_source.mp3` (excluded from Godot import and every export preset) |
| Official original | `Vilified (2012)_0.mp3` |
| Author | Matthew Pablo |
| Official source | https://opengameart.org/content/vilified |
| Direct official download | https://opengameart.org/sites/default/files/Vilified%20%282012%29_0.mp3 |
| License | Creative Commons Attribution 3.0 (CC-BY 3.0) — **attribution required**, unlike every other audio asset integrated so far in this project |
| Acquired | 4 September 2026 |
| Transformation | The official MP3 is retained byte-identical as the repository master. `tools/process-music-track.ps1` selects the first audio stream, removes the embedded 1600×1200 cover and metadata, and encodes the runtime derivative as deterministic Ogg Vorbis at 112 kbps, stereo, 44100 Hz. Duration drift: 0.006 ms; size reduction: 69.35%. |
| Master format | MP3, 320 kbps CBR, stereo, 44100 Hz, 5:16.839 |
| Runtime format | Ogg Vorbis, target 112 kbps, stereo, 44100 Hz, 5:16.839 |
| Master size | 14,734,430 bytes |
| Runtime size | 4,516,812 bytes (−69.35%) |
| Master SHA-256 | `59BE12C712BC9E67E8DF323CAA926F77839B7C2299AE11E5E8049628F20D8DBB` |
| Runtime SHA-256 | `09E189CF473A9F6D1E489A1B66ACE3D5FB32CE99FBDF1329249D9C2C5F169D59` |

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
