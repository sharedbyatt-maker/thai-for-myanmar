# Learner ranks

Six personal ranks at 0, 5, 15, 30, 60 and 112 distinct completed catalog lessons.
Existing completion IDs are preserved; unknown IDs do not count. Each distinct
lesson contributes 20 XP, computed from the existing completion set. Replays
never earn duplicate lesson XP. XP does not change rank thresholds.

Starting with this update, successful reviews (quality >= 3, including self-rated
flashcards) earn 5 XP per distinct phrase per local calendar day, across all modes,
up to 50 review XP per day. Legacy reviews do not receive invented bonus XP.
The optional xpPhrases field persists under the existing version-1 progress schema.
Old backups remain readable. All progress is local to the device/browser, without
account sync or a competitive leaderboard. Ranks describe learning activity,
not certified Thai fluency. Rank-up is announced in the session summary.

## Session feedback and badge details

Session summaries show actual XP gained since opening the session, including
lesson and review XP, with a rank progress card. A zero-XP replay still records
practice. Catalog lessons offer a direct next incomplete lesson action after
completion. Badges open scrollable details with their unlock threshold. XP rules
are collapsed by default to keep Personal readable. Today's review bonus is
shown separately from total XP.
