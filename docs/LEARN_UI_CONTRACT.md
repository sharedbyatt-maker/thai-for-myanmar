# Learn interface — preserve across content updates

The owner reaffirmed this requirement on 2026-10-31 after a curriculum update
incorrectly changed the homepage to unit cards.

- The primary Learn tab is one long, winding lesson path across the connected
  course. Unit dividers and a pinned, changing unit banner organize the path.
- Lessons use raised circular icons. Completed practice has a check; the current
  lesson has a colored ring/start label; future lessons have a subdued lock.
- Tapping an available node opens a dismissible preview anchored to that node.
  Starting from that preview opens the lesson. Opening/dismissing earns nothing.
- Keep the main page concise. Put goals/details in previews and the guide, and
  keep the unit chooser optional. Include return-to-current navigation and resume
  at the current lesson on first load.
- Keep the original purple/teal palette, elephant illustration and native icon
  system; do not copy Duolingo's characters or brand assets.
- Unit guides use the same circular lesson path rather than another card list.
- Preserve authored content, IDs, prerequisites, progress, original audio and
  explicit pending-audio/text-practice behavior. A visual completion indicator is
  practice completion, not a claim of pronunciation or listening mastery.

`test/course_v2_test.dart` verifies path geometry, locks, preview entry/cancellation,
large text and resume. Chrome integration captures the path and preview at mobile
and desktop widths. Future curriculum changes must retain those behaviors.

## Complete feature contract

The owner flagged a second regression on 2026-11-01: restoring circular nodes
without XP and the surrounding learning features was insufficient.

| Feature | Required behavior |
| --- | --- |
| Lesson reward | Preview states +20 XP for a new lesson; the first saved completion earns exactly that amount. Replays state +0 XP. Opening/dismissing a preview earns nothing. |
| Total XP | Home and Profile share `LearnerRank`, including known legacy and course completions plus the existing review bonus. Existing dated course completions retain credit. Unknown IDs earn nothing. |
| Activity | Successful supported practice counts toward goals/streaks without becoming listening evidence. Durable daily activity survives the bounded diagnostic-event log. Replays count as practice without another completion XP reward. |
| Mobile | Streak, total XP and daily-goal metrics stay visible above the scrolling path; tapping opens real details/settings. |
| Desktop | A right support rail shows stats, the adjustable goal, personal Rank progress, actual review counts, the next lesson/reward and history access. Navigation retains visible labels. |
| Unit banner | Keep the pinned title, unit progress, chooser and guide, with a compact layout for short/enlarged-text screens. |
| Completion | Show actual earned XP, offer the next available lesson through its preview and retain return-to-path navigation. |
| Integrity | Keep source IDs, progress, original audio, pending-audio behavior and competitive League scoring intact. XP rewards participation, not pronunciation certification. |

Regression coverage: `test/course_rewards_test.dart`, `test/course_v2_test.dart`
and the existing Profile/goal/quest tests; browser integration verifies saved XP
and captures mobile/desktop, light/dark and lesson-preview/summary screens.

## Additive milestone feedback — 2026-11-01

Preserve the same path, XP, navigation, authored IDs/audio and backend rules.
Completed nodes retain their exercise icon plus a small check. The final node is
labelled as a unit checkpoint; it reuses the authored reflection, not a new test
or a certification of speaking. First full-unit completion has a one-time visual
celebration, with no extra XP or currency. Replays retain +0 completion XP.

Lesson summaries show actual saved daily activity and unit progress, the practiced
lesson, and newly reached daily goal. No accuracy/speed is invented from bounded
events. Profile outcomes count only fully practiced units; delayed-probe evidence
is separately labelled as supported practice, never language mastery. Read-only
insights do not migrate or clear saved data. The path's review cue uses known due
cards and scheduled probes; a resumed session finishes before queued fresh-session
reviews, matching the existing scheduling behavior. Quest feedback reflects the
existing goals and does not grant a second reward. Reduced-motion preferences
must be respected. Future changes preserve these alongside the full inventory.
