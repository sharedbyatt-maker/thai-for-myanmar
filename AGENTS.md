## Start here

Read [the Chang Thai V1 handoff](docs/PROJECT_HANDOFF.md) before changing the project. Scope work to the owner's request and verify current release state against the linked sources.

## Owner-approved V1 baseline

The owner's accepted Chang Thai V1 source snapshot is permanently referenced by the
`baseline/chang-thai-v1` branch at commit
[`52b2fd8f3a180a076ebfb87966782f9393920df7`](https://github.com/sharedbyatt-maker/thai-for-myanmar/commit/52b2fd8f3a180a076ebfb87966782f9393920df7).
Treat this branch as a read-only reference: do not develop on it, move it, or force-push it.
Start all future work from the current `main` branch, and compare changes against this
baseline when needed. The detailed accepted feature/startup state and release caveats
are recorded in [docs/PROJECT_HANDOFF.md](docs/PROJECT_HANDOFF.md).

Do not change the launcher icon or splash/startup sequence unless the owner explicitly
asks. Preserve the Android application ID `com.sharedbyatt.thaiformyanmar`. Do not
assume the CI release APK is production-signed or that the app has been published to
Google Play. Check the Play Console upload key and next unused version code before
changing the Android release version.

## Owner's Learn UI requirement

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
