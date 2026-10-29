# Listen-first learning interface

The app now opens a lesson path and uses four destinations: Learn, Everyday,
Review, and Personal. Original indigo elephant artwork and a warm neutral theme
replace the dense dashboard. No Duolingo artwork, brand assets, or content is used.

- Lessons keep the existing five-phrase decks and stable lesson IDs. Every lesson
  remains accessible; completed lessons show checks. Progress comes from saved
  reviews, not fabricated XP or a new scoring system.
- Everyday provides six common situations, full category access, search, saved
  phrases, and the existing full-screen Quick Speak board. None are lesson-locked.
- Phrase lists show meaning and Thai, with direct playback and favorites. Detailed
  pronunciation remains available by opening a phrase.
- Study sessions focus on one prompt with a large audio control. Pronunciation
  starts hidden, explanatory notes are expandable, and answer actions remain
  separate from the scrolling prompt. Listening still requires successful audio
  before an answer can earn progress; unavailable audio has a flashcard fallback.
- Review offers all six existing exercise modes using visual selectors; category
  and review filters are in an expandable section. Completed flashcards offer
  a listening follow-up. There are no hearts, paid unlocks, or leaderboard gates.
- Personal holds favorites, actual learning history, and existing voice/theme
  settings. Existing local-storage keys and the 990 audio assets are unchanged.

Validation should cover mobile/desktop layouts, large text, direct search,
Quick Speak, persisted lesson completion, audio state tests, and all content/audio
validators. Audio coverage is not independent Thai pronunciation certification.

## Ready-to-use polish and continuous path

The Learn destination now contains one continuous, lazily built path across all
35 topics, preserving the five-phrase lesson IDs and real completion checks.
A pinned, searchable topic picker jumps to a topic without removing other units;
the continue action follows the selected topic. Row extents account for text
scaling so topic navigation can scroll accurately without building the entire
long path at once. Every lesson remains available without paid or progress locks.

Daily goal rings and seven-day activity use saved reviews. Everyday has inline
search, saved filtering, and recent phrases; successful audio playback updates
recency without marking a phrase as mastered. Phrase detail keeps audio and
meaning visible while pronunciation and notes are expandable. The web entry
shows an accessible startup indicator, retry recovery, reduced-motion support,
and the app's own icon. This does not add offline web caching or Play publishing.
