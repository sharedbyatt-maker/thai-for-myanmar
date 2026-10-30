# Video-inspired learning interface

The user supplied a 29.4-second Duolingo Chess recording showing the learning path, section banners, current-step return control, practice choices, quests, leagues and profile. The recording does not demonstrate an in-lesson question flow. Its closing phone-settings frames are unrelated to this implementation.

This update adapts those useful patterns to Thai for Myanmar's original indigo/elephant identity:

- Colored unit banners follow the visible path section. Real unit completion progress, current-step rings, the original elephant and a return-to-current control orient learners along all 112 lessons. Unit guides and existing lesson preview cards remain accessible.
- Six destinations expose Learn, Everyday, Review, Quests, League and Personal. Inactive League tabs stop periodic refresh polling.
- Daily quests use actual reviews, unique phrase review XP and dated catalog-lesson completion. Weekly and monthly challenges count actual activity days. Twelve practice days earn a monthly badge derived from saved history; no claim button awards extra XP.
- Dated completions are an optional backward-compatible field in the existing version-1 local progress format. Older undated completions are preserved without inventing completion dates. Personal quests use the device's calendar, consistent with existing offline progress.
- League badges, own-rank overview and promotion zones use the existing server board. A promotion zone appears only with at least five positive scorers; its size is the rounded-up highest quarter. Server scoring, authentication, RLS and the 100-point daily cap are unchanged.
- Practice choices and the profile use stronger visual grouping and real saved metrics.

All 502 phrases and 990 bundled audio mappings are preserved. No copied Duolingo assets, fake competitors, artificial follower counts, hearts, paid boosts or new paid resources are introduced. Social feeds and chess opponents are not fabricated as language-learning features.

Validation includes legacy-history compatibility, day/week/month rollover, duplicate-safe dated lessons, real monthly badges, large-text mobile navigation, scroll-following banners, current-step return, promotion thresholds, and browser screenshots at 390px and 1280px. See the implementation PR for final CI and deployment evidence.
