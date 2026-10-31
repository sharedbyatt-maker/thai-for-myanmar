# Practical curriculum: introduction pilot

The first task-based lesson is available from Learn as **မိတ်ဆက်တတ်မယ်**.
The existing 112-lesson path and 502-phrase library remain available. This is
one complete pilot, not a claim that the entire curriculum has been replaced.

## Goal and sequence

Goal: understand a name question, introduce yourself using your own name,
construct an origin statement, and rehearse asking the other person's name.

1. Hear/read a short greeting → name question → example answer exchange.
2. Notice the pronoun + ชื่อ + name + polite particle pattern; enter a name.
3. Arrange tokens to construct a personalized answer; receive explanation and
   retry when wrong. Position identities allow repeated tokens in a name.
4. Answer a name question from audio with Thai text initially hidden. Answers
   unlock only after acknowledged playback. Revealing the transcript requires
   hiding it and replaying before grading. Muted/unavailable/cancelled playback
   cannot count as a passed listening check.
5. Hear/read the origin question and Myanmar-origin answer; notice มาจาก.
6. Apply the pattern to a Thai-origin friend: choose ประเทศไทย rather than
   repeating the Myanmar example. The alternate full sentence is not shown
   beforehand. Country vocabulary is introduced in step 5; this is text-only
   construction, not an unrecorded audio prompt.
7. Rehearse the whole exchange and explicitly save a practice completion.

The lesson captures the selected polite style at entry so its grammar/particles
stay consistent. It does not record the microphone or automatically evaluate
free speech. A name can use Myanmar/Thai/Latin script, is used only in memory,
and is never sent to TTS or a backend. The displayed mixed-script personalized
sentence is a spoken-response scaffold, not Thai spelling assessment.

## Honest progress

`practical:introductions:v1` has its own persisted practice timestamp under the
existing local learning snapshot. It does not mark an old lesson complete,
raise the old lesson rank, increment session counters, or award League points.
After all tasks, one acknowledged listening review of `intro_ask_name` is
recorded in the existing listening/FSRS path. Personal review XP retains its
existing unique-per-phrase daily cap. Repeated save taps cannot duplicate the
completion review. Exiting midway does not record a completion.

A finished practice session is not a pronunciation certification or proof of
spontaneous real-world conversation. Revisit without hints on another day;
longitudinal learning outcomes and fluent-speaker feedback remain to be measured.
The current pilot does not schedule a separate lesson-level reminder or sync
progress across devices. Existing FSRS review selection remains available.

## Audio plan

Finalize each lesson's Thai text and interaction sequence **before generating
new recordings**. Audio requirements are attached to the lesson while writing,
not added as a final untracked step. Exact phrase/form/text matching prevents
playing an old recording for a changed sentence.

This pilot reuses six existing lines with both male and female exact bundled
mappings (12 recordings). No new MP3, translation, manifest entry, paid TTS call,
cloud service or synthesis account was created.

| Phrase ID | Use |
| --- | --- |
| greet_hello | Greeting model |
| intro_ask_name | Model and hidden-text listening check |
| intro_name | Name-template model; personal name is not synthesized |
| intro_from_city | Origin-question model |
| intro_myanmar | Origin-answer model |
| intro_nice_to_meet | Closing model |

The pack contains generated audio, not independently certified native-speaker
recordings. Names/placeholders and Thai particles still need human listening
review. Technical coverage tests do not establish pronunciation quality.

For future food-ordering and shopping pilots: first finalize dialogue/patterns
and alternate scenarios, enumerate required male/female utterances, reuse exact
existing recordings, then generate only genuinely new lines through the existing
local Audio Studio. Review pronunciation before importing those new files and
before enabling audio-dependent checks. Do not substitute a different sentence
or award a listening pass just because a playback button was pressed.

## Verification

The pilot tests exact audio coverage in both styles; full male/female flows at
320px large text and short landscape with 2x text; wrong construction/retry;
transcript assistance; unavailable playback; completion persistence separated
from old lessons; and exit-without-credit. CI explicitly includes this suite
alongside existing lesson, League and app tests.
