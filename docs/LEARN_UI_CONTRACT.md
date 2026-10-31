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
