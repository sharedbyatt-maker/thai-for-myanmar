# Bundled Thai audio pack

This imported owner-generated pack covers all 502 phrases and 990 selected forms:
488 male, 488 female, and 14 shared mappings. MP3 payload totals 31,392,000 bytes
(about 31.4 MB). All 990 files decoded successfully on the review host, and
phrase/form/Thai-text mappings match the current source dataset exactly.

The existing asset-first player uses these bundled files before Thai-only device
TTS. Android packages the audio for offline playback. Web serves the same assets;
this import does not implement offline browser caching.

Source: `kunato/wayu-kokoro-thai-v1`, pinned revision
`abf63dc118365bea784fa881bdd1dce4b2cc1fd4`. Selected voices: male 9
(`m_young_clear`), female 2 (`f_young_clear`), speed 1.0. Neutral forms use the
female voice. These are generated recordings, not native-speaker recordings.

The model card declares Apache-2.0. Model/voice provenance and pronunciation
have not been independently certified. Human listening review remains pending,
especially tones, particles, numbers, placeholders and high-risk phrases.
Technical coverage/decode validation is not a language-quality certification.

Generation metadata and the source ZIP checksum are retained in `docs/audio/`.
The pack is ready for device testing and human review; importing it does not
claim the app is ready for unrestricted public release.

## Authored course Units 1–5 — imported 2026-11-04

The owner's completed Windows pack adds 79 unique, Normal-speed MP3s (1,514,112
bytes; 94.6 seconds combined). Male speaker 9 / female speaker 2 / speed 1.0
match the original pack. Every new MP3 decoded with ffmpeg; each mapping matches
the exact current course text and form. The original 990 files and their manifest
are unchanged, for 1,069 unique bundled MP3s total.

Units 1–5 now have technical coverage of all 101 required bindings: 16 exact old
bindings plus 85 newly supplied bindings. Another 17 exact-text aliases elsewhere
reuse these same MP3s without generating additional audio. The additive course
manifest contains 102 mappings to 79 unique assets. The remaining whole-course
inventory is 347 unique recordings / 380 bindings; Units 6–26 are not fully voiced.

The course source is unchanged (SHA256
`624e010a37ab25772f8df3aaf6abde9a193afcd832a8689df223408271700dc4`). Import
provenance, source ZIP checksum, exact asset hashes, durations, original report
and source plan are in `docs/audio/course-units-1-5/`. Coverage and decoding are
technical checks; independent Thai pronunciation/tone listening review is still
pending. No new speech-recognition or speaking-mastery claim is made.
