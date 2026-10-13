# Learning upgrade

This upgrade keeps the existing offline Flutter app and its 500 Thai–Myanmar
phrases. It does not add accounts, cloud databases, subscriptions or analytics.

## Learner flow

- Home offers a dismissible Burmese starting guide, daily goal, streak and
  access to learning history. A daily suggestion rotates among ordinary
  phrases rather than always showing one fixed phrase.
- Learn divides every category into lessons of at most five phrases. Each
  phrase can be listened to, revealed and rated for recall. Completed lessons
  are saved; the next unfinished lesson is offered on return.
- Practice offers flashcards, Thai-to-Myanmar meaning questions, listening
  questions, matching and sentence-piece ordering. Category and due/new/
  difficult/favorite/all filters can be selected before starting.
- Myanmar-to-Thai meaning practice is also retained, with its own review track.
  Direction is chosen before the session and cannot reveal an answer by being
  switched midway through a question.
- Listening questions never reveal Thai text or pronunciation before an answer.
  Answers stay disabled until verified audio finishes. Missing audio earns no
  grade or progress; learners can retry or switch to flashcards.
- Sentence ordering is a reading practice option, not a requirement for new
  learners. It uses 26 existing phrases with exact male/female text matches;
  it does not attempt to split arbitrary Thai text on whitespace.
- A session records each phrase once. Leaving early preserves graded answers
  without marking the session or lesson complete. Summaries offer another
  flashcard session for mistakes.
- Progress shows seven days of activity, distinct practiced phrases, completed
  lessons/sessions and accuracy. Flashcard accuracy is self-reported recall;
  it is not a pronunciation or fluency score.

## Local persistence

Existing favorites, recent history, viewed IDs, theme, polite form and quiz
count retain their original keys. New learning state is stored under
`thai_for_myanmar.learning.v1`; pronunciation volume has a separate key.
Review records are independent for each `(phrase ID, learning mode)`.
Due-day scheduling uses local calendar dates and an SM-2 interval calculation.
Corrupt individual records are skipped without discarding intact learning data.
Settings and progress remain usable in memory when storage writes fail.

## Audio

Bundled exact-text recordings remain the first choice, followed by verified
Thai-only TTS. This change adds local-voice preference, volume support and the
Android TTS service query. Speech stops when the app is backgrounded.

No new recordings or paid TTS calls are part of this change. Native Thai voice
availability still depends on the device. The web build still uses the browser's
Web Speech API. To plan owned recordings, run:

```sh
python3 tool/prepare_thai_audio.py --limit 30
```

The command only outputs exact phrase/form/text/asset jobs; it does not call
an external service or modify the catalog. After producing and checking owned
recordings, use the existing catalog schema and audio validator.

## Validation

New tests cover review intervals, missed-day streaks, persistence, damaged
records, complete lesson coverage, exact sentence reconstruction, completion
tracking, unavailable listening and enlarged-text landscape layout. CI runs
them alongside existing playback, content and integration checks.

See `THIRD_PARTY_NOTICES.md` for license and provenance details.
