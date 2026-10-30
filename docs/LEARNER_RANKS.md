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
