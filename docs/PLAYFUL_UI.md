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
