# Third-party notices and feature provenance

## FSRS and Thai content tooling

Runtime scheduling uses `fsrs` 2.0.1 (Dart-FSRS), MIT License, from
https://github.com/open-spaced-repetition/dart-fsrs.
Its full license is bundled in `third_party/licenses/dart_fsrs_mit.txt`.
The earlier SM-2 adapter's license remains retained for provenance and legacy
storage compatibility; its interval formula is no longer used for reviews.

The developer-only content checker uses PyThaiNLP 5.4.0 (Apache-2.0).
Bundled corpus data have their own licenses; see the installed package's notices
and https://pythainlp.org/dev-docs/notes/license.html.
No PyThaiNLP corpus/model data is copied into the app, and no Python runtime or
remote NLP service is added to the Flutter app.

## Adapted source code

The former `lib/learning/review_card.dart` adapted the pure-Dart SM-2 scheduler from
[Pouple-Tim/Language-Learning-App](https://github.com/Pouple-Tim/Language-Learning-App),
reviewed at commit `e55fe3ccfd5228d977f2c6b6fe0e86ed379375a8`.
Copyright (c) 2026 Timousss. MIT License.
The complete license is retained in `third_party/licenses/pouple_tim_mit.txt`.
It is also bundled as a Flutter asset in distributed Android/Web builds.

Adaptations include input validation, independent learning-mode records, safe
deserialization and calendar-date scheduling across daylight-saving changes.

## Independently implemented learning features

The other additions are original code for Thai for Myanmar using the existing
phrase corpus. These projects were reviewed for general product patterns:

| Project | Pattern applied here |
| --- | --- |
| Pouple-Tim/Language-Learning-App | Study modes, due/new/difficult filters, five-item lessons and session summaries. |
| lai2570/Burmese_language_app | Burmese-first study UI, saved-word review and configurable pronunciation volume. No protected content or source code was copied. |
| seyed0123/word-wolf | Daily goals, streaks and visible learning progress. No backend or account system copied. |
| google/bespoke | Separate recognition/listening practice and audio prepared before distribution. No Google source code or external datasets copied. |
| dov-vai/ClozeCall | General recall/review pattern. No GPL source or language packs copied. |
| ofcRS/learn-thai | Short lessons and learn-before-test flow. No source, audio, lessons or assets copied. |

Repositories without clear reuse permission, including Thai-MM-Language-Platform,
Parakeet, LexiLearn and BurmaLingo, were inspected as references only. No code,
translations, recordings, curricula or assets from them were imported.

The 74 recordings in ofcRS/learn-thai were not imported. The Chinese recordings
and educational assets from Burmese_language_app were not imported either.
Thai for Myanmar now includes 990 locally generated, matching Thai recordings;
none of the above projects' recordings were imported.
