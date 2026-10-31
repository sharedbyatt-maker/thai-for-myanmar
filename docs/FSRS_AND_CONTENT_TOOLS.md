# Local FSRS reviews and read-only Thai content checks

## What users receive

Existing review modes now schedule their cards with Dart-FSRS 2.0.1 (FSRS-6).
The Review tab shows a small personalized review card after a learner has
studied at least one phrase. Due phrases can be revisited in five-item audio →
Myanmar-choice sessions. This is a review session, not another completed catalog
lesson, and cannot award a new lesson-completion bonus.

All scheduling runs in Dart on the device, including Flutter Web. No new server,
Python service, ASR model or paid API is used. The existing Render site and League
backend do not change. Quests, XP caps and competitive scoring remain separate.

## Scheduling and migration

- Use the pinned MIT `fsrs` 2.0.1 package with preset parameters and a 0.9 target
  retention. This is a model target, not a guarantee or a trained user-specific
  parameter set. Fuzzing is disabled for reproducible schedules.
- Grades 0–2 map to Again, 3 to Hard, 4 to Good and 5 to Easy. Failed cards can
  become due in a minute; new Good cards have a ten-minute learning step. The
  minute precision is preserved in storage and all due checks compare instants.
- Objective first-try correct answers are calibrated to Good (quality 4), not
  Easy: recognizing a newly taught phrase once should still enter the learning
  steps. Quality 5 is reserved for explicit Easy self-ratings on standalone
  flashcards. Guided first-attempt accuracy and XP remain correct.
- Convert review times to UTC for FSRS. The interface displays local time. The
  visible Review tab refreshes each minute; inactive tabs stop their timer.
- Keep schema-version-1 progress and old per-card fields. Old saved due dates,
  counters, completed lessons, XP, streaks and favorites survive load unchanged.
  A legacy card begins conservative FSRS learning only on its next actual review;
  old SM-2 ease/intervals are not claimed to be FSRS stability or invented history.
- Each card stores optional validated FSRS memory and the last eight real review
  log entries. These logs are a bounded diagnostic trail, not an optimizer dataset.
  Damaged optional memory falls back to the intact compatibility record. Device
  clock regressions clamp scheduling to the latest recorded review time.

## Content tooling

The pinned PyThaiNLP 5.4.0 checker runs only in developer tooling/CI. It uses the
bundled Thai word dictionary, `newmm` tokenization, normalization suggestions and
dictionary-based spelling candidates, with automatic corpus downloads disabled.

```sh
python -m pip install -r tool/requirements-content.txt
python -m unittest discover -s tool/tests -p test_content_audit.py -v
python tool/audit_thai_content.py
```

The UTF-8 report is written to `build/content-audit.json` (override with
`--output`). Every PR's **Audit Thai content with PyThaiNLP** job uploads the
`thai-content-audit` artifact. It includes a source SHA-256 and package version
so suggestions can be tied to the reviewed corpus. CI also checks that source
assets were not rewritten.

Structural errors (duplicate IDs, empty Thai, unsafe control characters or
Myanmar script inside a Thai field) fail the audit. Normalization and dictionary
findings request human review; they do not automatically change text or fail CI.
The first full run covered 502 phrases / 1,478 source fields, found no structural
errors, and flagged six fields belonging to `shopping_specific_size` and
`home_water_leak`. Loanword/tokenization issues can cause false positives, so
their suggestions have deliberately not been applied. This tool does not certify
Thai fluency, Myanmar translations or pronunciation accuracy.

All 990 audio mappings and their exact text stay intact. If a future human review
changes Thai text, matching audio must be regenerated and validated before release.

## Validation

Tests cover actual FSRS progression, minute-level due boundaries/timezones,
legacy migration, malformed memory, JSON continuation, bounded logs and clock
correction. Widget coverage checks live due-time refresh and starting a guided
listening review without adding XP merely by opening it. Browser/Android
integration verifies FSRS memory after a complete lesson and a visible next-review
schedule after reload. Content-tool tests cover deterministic/read-only results,
normalization suggestions and structural rejection. Final results and deployment
evidence are recorded in the implementation PR.
