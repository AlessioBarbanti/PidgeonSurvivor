# Bea dodge cue (PS-072)

`dodge.ogg` is the `GameAudio.DODGE` cue played when Bea's Sesto Senso Equino
passive (Instinctive Dodge) triggers.

## Swishes Sound Pack — swish-9.wav

| Field | Value |
|---|---|
| Runtime file | `dodge.ogg` |
| Original file | `swishes/swish-9.wav` (from `swishes.zip`) |
| Author | artisticdude |
| Official source | https://opengameart.org/content/swishes-sound-pack |
| Direct official download | https://opengameart.org/sites/default/files/swishes.zip |
| License | Creative Commons Zero 1.0 Universal (CC0 1.0) |
| Acquired | 4 September 2026 |
| Transformation | Extracted `swish-9.wav` (the longest, fullest take in the
  pack, ~0.20s) from the official zip. Transcoded from the original
  24-bit/44.1kHz stereo WAV to Ogg Vorbis with `ffmpeg -c:a libvorbis -q:a 6`
  to match the `.ogg` convention used by every other runtime cue in
  `assets/audio/`; renamed only for the runtime convention. Original WAV
  SHA-256 (pre-transcode, not kept in the repository):
  `123883F006CE55FEECBFF11EEA5F87C4493DF4399989983037144570A23723C1`. |
| SHA-256 (`dodge.ogg`) | `6F2BC3D6901B3F090FC0741B8E12845C4B19CA8743B4AFEA96650979351047D0` |

The pack ships 13 short weapon-swing "swish" takes released as one CC0
collection; `swish-9` was picked over the others because its longer tail
reads as an air-movement whoosh rather than a hit tick, matching the "scarto"
tone required by PS-072 without borrowing any existing combat cue.

CC0 does not require attribution; the project nevertheless keeps the credit
in `docs/credits.md`.

`../LICENSE-CC0-1.0.txt` is the unmodified CC0 1.0 legal code downloaded from
https://creativecommons.org/publicdomain/zero/1.0/legalcode.txt.
