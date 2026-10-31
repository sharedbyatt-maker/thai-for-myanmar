# Guided lessons and application audit

## Lesson design

The supplied screenshots show a large audio prompt, optional pronunciation,
translation and bottom actions. Catalog lessons now use an original elephant
study card followed by an active recall exercise for each phrase. Exercises
alternate Thai-to-Myanmar, Myanmar-to-Thai and listening comprehension.

Selecting an option does not submit it. Learners explicitly check the answer,
receive text/icon feedback and retry mistakes before continuing. Study-only
reveals earn no review XP. Each successfully recalled phrase records once in
the existing flashcard schedule; a retry receives quality 3 rather than 5.
The summary reports first-attempt correctness separately from completion.
Existing standalone review modes remain available.

Normal and 0.8x audio use the existing bundled files, with request-scoped rates
also applied to system Thai TTS fallback. A subsequent normal request restores
1x. Listening choices require completed audio playback. If audio is unavailable,
learners explicitly switch to a visible-text exercise rather than receiving
credit for unheard audio. Muted playback explains how to restore the volume.

The design draws on Duolingo's published scaffolding, feedback and targeted
practice principles, using original layout and assets:

- https://blog.duolingo.com/keeping-you-at-the-frontier-of-learning-with-adaptive-lessons/
- https://blog.duolingo.com/guide-to-duolingo-practice-hub/

## Confirmed issues addressed

- A damaged or incorrectly typed preference could stop the entire load before
  intact learning history was read. Individual fields now validate independently,
  retain valid history and bound recent entries, volume and counters.
- A reused audio button could finish an old request against its new phrase.
  Phrase changes cancel old playback; generation/style checks prevent stale
  failure messages or incorrect recent-history entries.
- Session audio callbacks could update a later exercise. Request generations
  now guard stage changes as well as phrase changes.
- Silent playback at zero volume could be presented as successful playback by
  generic phrase buttons. Muted requests now explain the setting without playing
  or adding recent history.
- Incorrect practice could automatically label a new phrase as learned. Only a
  successful review now adds that label; failed attempts still enter the review
  schedule and activity history, and existing learned entries are preserved.
- Back navigation could discard an active session accidentally. A confirmation
  preserves already recorded reviews and explains that lesson completion credit
  requires finishing. Empty and untouched sessions can still close directly.
- Captured rapid taps on a guided action could otherwise skip feedback or a
  newly opened stage. Each rendered primary action can transition only once.

## Audit scope and validation

Review covers lesson routing and previews, all six practice modes, local settings
and history, quests/ranks, Thai playback lifecycle, responsive navigation,
search/favorites, corpus/audio validation and existing League scoring/privacy
regression checks. Browser integration exercises mobile and desktop learning,
new reveal/recall/listening/feedback states, exit confirmation and persisted
completion; Android runs the same core lesson flow.

Local validation: 114 Flutter tests passed, the analyzer reported no issues,
all 12 audio-tool tests passed, and corpus validation confirmed 502 phrases,
35 categories and all 990 audio mappings. The new short-window/large-text test
caught a fixed-header overflow; moving the prompt into scrollable content fixed
it. Guided exercise content is a small eager column so audio fallback and option
reordering remain reachable without lazy-child lookup problems.

No database migration, new paid service, copied competitor audio, artificial
hearts/currency or changes to competitive scoring are included. Local personal
progress and server League points remain separate. Automated tests cannot
certify every Thai/Myanmar translation, native pronunciation, real iOS builds or
every vendor/browser audio implementation. Final test and deployment evidence
is recorded in the implementation PR.
