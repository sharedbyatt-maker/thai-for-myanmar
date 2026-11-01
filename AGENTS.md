# Owner's Learn UI requirement

The owner explicitly wants a Duolingo-inspired Learn experience: a winding vertical
lesson path, raised circular lesson nodes, clear current/completed/locked states,
a pinned unit banner and a node-anchored start preview. Keep the app's original
purple/teal branding and elephant companion. Do not replace the primary Learn
path with text-heavy unit cards or a lesson list when changing curriculum/content.

Curriculum, audio generation and progress changes must preserve this interface.
Keep the 26-unit authored course and existing progress/audio unless the owner
explicitly requests a content change. New audio is deferred until the final
distribution pass. Do not generate audio as part of a UI change.

See `docs/LEARN_UI_CONTRACT.md` and the path/preview regression tests.

Preserve the complete learning experience, not only the shape of the path:
earned/available lesson XP, total XP, daily goal, streak, personal Rank/badges,
unit progress, review/continue/history controls and the next-lesson completion
flow. Mobile metrics stay visible while scrolling; desktop has a support rail.
Visible rewards must match actual saved rewards. Course participation XP is
separate from listening evidence and competitive League scoring. Do not drop
these connections during later curriculum or visual updates.
