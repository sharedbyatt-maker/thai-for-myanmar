# Connected Learn course

The primary Learn tab now uses the authored course-v2.1: 26 units in six sections,
178 lessons and 402 utterance/chunk records. It replaces the five-phrase category
chunks as the default path. Vocabulary introduction, pattern noticing, supported
construction, listening/meaning checks, substitution and dialogue are separate
steps. Units have explicit prior-unit dependencies; lessons unlock sequentially.
Existing content, audio, favorites, XP and the original lesson history remain.
The old path and introduction pilot are available only through the history link.
The primary interface remains a winding circular-node path with a pinned unit
banner and anchored lesson-start previews. Curriculum changes must preserve the
owner's interface requirements in `docs/LEARN_UI_CONTRACT.md`.

The content is provisional, not independently certified Thai–Myanmar teaching
material. This is a public **website preview**, not a claim that the audio course
is ready for broad distribution. Text practice is available throughout the path;
required new audio and human language/listening review remain deferred by the
owner. No paid API, cloud TTS, ASR, new service or database change was added.

## What a learner can do now

- Follow the primary course from greeting/name questions through food, shopping,
  travel, work, housing, health communication and services.
- Read a unit's goal/guide, study words and see meaningful phrase parts, assemble
  supported sentences, practice substitutions and rehearse dialogues.
- Replay **exact existing bundled** audio when available. Missing course audio
  is explicitly labelled. It never silently speaks a different sentence or uses
  TTS as proof of completed bundled listening.
- Explicitly choose text practice when audio is pending. Contextual Myanmar
  options are text practice; this is not evidence of Thai listening proficiency.
  Thai reading is not required for selecting Myanmar-labelled supported chunks.
- Resume a lesson and retain completed practice after reload. Construction and
  attempts are separate from unassisted recall or free speech.
- Enter a personal name only in session memory for an ungraded rehearsal. It is
  never synthesized, sent to a backend, saved as a scored answer or substituted
  by an unrelated sample-name recording.

A passed practice lesson is labelled practice completion, not language mastery.
It does not automatically complete a legacy lesson or award League points.
It earns 20 personal practice XP on its first saved completion, including text
practice. Home/Profile/ranks use the same reward source; replay earns no further
completion XP. Existing course completions keep that credit. Successful course
practice and dated completions also feed goals, streaks and quests through a
durable daily ledger, without modifying legacy review or listening evidence.
Course events preserve first-attempt/correct, attempts, assistance, replays and
actual playback completion. Course FSRS cards are updated only by completed,
unaided bundled listening checks. A wrong first retrieval is Again; a supported
retry cannot overwrite it with a second immediate Good. Due course checks are
inserted at the start of a fresh lesson; base-step cursors remain stable.
Completed units also offer one delayed check after one day and another after
seven days. These checks retain the same text/assistance rules and do not imply
listening mastery when answered in text mode; their two-stage schedule is saved.
Normal replay is recorded without automatically being treated as a wrong answer.
No microphone, pronunciation scoring or speaking certification is present.

## Data and authoring

`tool/build_course_v2.py` is the authored source, not a category-to-deck generator.
It writes `assets/data/course_v2.json`. `tool/validate_course_v2.py` checks forward
prerequisites, duplicates, required introduction before assessment, exact chunk
reconstruction and source-audio identity. Every model/chunk has a stable ID.
Myanmar glosses on chips are scaffolding, not a claim of word-for-word equivalence.
Further natural variants and language quality must be reviewed before release.

`CourseProgress` is an optional field inside the existing version-1 local
snapshot. Legacy XP/cards/streak/favorites/completions are not migrated into new
mastery. Course completions and cursor/event/memory records are separately
namespaced. Malformed optional course entries do not erase legacy progress.
The last 600 course events are retained as bounded diagnostics, not a research
or speech dataset. A production curriculum change must version lesson identity.

## Guided practice and remaining audio

Units 1–5 have guided vocabulary checks, gaps, dialogue replies and scenarios.
Units 6–26 build on that structure with word checks, a substitution gap, two
guided replies and two checkpoint scenarios. One scenario reuses a model from a
specific earlier unit. For example, Unit 6 reuses Unit 4’s rice request after a
bottled-water order. These are supported exercises. The day-one and day-seven
reviews use different models from the same unit.

The first five units now bundle all 101 required bindings. The imported pack
added 79 MP3 files and 102 exact bindings, including aliases elsewhere in the
course. The original phrase pack retains its 990 files. Human listening review
is still pending.

Run from the repository root:

    python3 tool/build_course_v2.py
    python3 tool/validate_course_v2.py
    python3 tool/course_audio_plan.py --output docs/audio/course-v2-required.json

The checked-in deterministic plan contains 535 required bindings, 155 already
resolved, and 380 missing bindings grouped into **347 unique recordings**. A
binding is not necessarily a distinct MP3: aliases reuse identical text and form.
Adding or editing course text can change these counts.

Finish language/exercise text review before generating. Later, download the
current repository on Windows, open `Start_Audio_Studio.bat`, choose the preferred
voices/speed and use **သင်ရိုးအသံ ထုတ်မယ်**. The new `course` mode generates only
currently missing recordings through the same local CPU Kokoro engine/cache.
It makes no synthesis API call and does not run merely by loading the website.

The course ZIP contains `assets/data/course_audio_manifest.json`, generated
MP3s, a source-hash/alias inventory, generation report and engine provenance.
It deliberately contains no replacement of `thai_audio_manifest.json` or
`phrases.json`, protecting the original 990 mappings. A partial ZIP remains
partial; inspect `generation-report.json`. Review tones, particles, full names
and complete playback before importing. Generated audio is not a native-speaker
recording. Do not splice chunk clips together as a natural sentence model.

After review, import the pack's `assets/` into an app branch, validate the exact
course manifest against the current inventory and source text, run Flutter and
browser checks, then merge/deploy. Keep prior course manifest entries when
building later delta packs. The combined runtime catalog automatically recognizes
new exact course entries on the next app build. Editing a course text invalidates
an old exact-text binding. A correct technical match is not pronunciation review.

## Verification

CI validates reproducible course JSON and audio plan, course tooling, Studio
course ZIP aliases and legacy-manifest protection. Flutter tests cover the main
path, locks, real vs pending audio, interrupted playback, text-only completion,
first-wrong history, FSRS serialization, supported construction and large text.
Existing legacy tests now target the explicitly retained history screen.
Browser and Android integration cover the new course entry/completion and the
retained legacy lesson plus existing app flows. Release evidence belongs in the PR.
