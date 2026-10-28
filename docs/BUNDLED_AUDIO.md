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
