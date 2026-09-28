# Phrase content and validation

## Current starter corpus

The bundled data currently contains **87 phrase records in 35 categories**. Categories cover greetings, introductions, numbers, money, time and dates, common questions and answers, food, shopping, daily life, transport and directions, workplace and factory, accommodation, restaurant/street-food/taxi/public transport, health and clinics, pharmacy, emergency, police, immigration/documents, bank, phone/SIM, job search, salary, overtime, and leave.

This is a useful starter set, not the requested future 500-phrase library. It is honest to extend gradually after language review rather than pad the dataset. The validator reports structural validity only; it does not certify that a translation or pronunciation is fluent or medically/legal correct.

## Phrase fields

Each phrase has a stable lowercase ID, a category ID, display Thai, Myanmar meaning, Myanmar-readable pronunciation, English meaning, non-empty search keywords, and tags. `thaiMale` and `thaiFemale` can supply a spoken form with the appropriate polite particle. `note` is optional and `high-risk` tags cause the phrase view to show a caution.

## Editing steps

1. Add or correct a phrase in `assets/data/phrases.json`.
2. Add a category in `assets/data/phrase_categories.json` only when a distinct browse destination is useful.
3. Add Myanmar search synonyms to `keywords`.
4. Mark workplace, health, police, immigration/document, employment, and emergency content with the `high-risk` tag.
5. Run `python3 tool/validate_content.py`, `flutter analyze`, and `flutter test`.
6. Ask fluent Myanmar and Thai reviewers to check meaning, naturalness, and pronunciation. Record their approval in the project review history before describing content as language-reviewed.

## Pronunciation note

Pronunciation is an approximate reading aid written for Myanmar speakers, not a formal phonetic transcription. Thai tones and some consonants cannot be represented exactly this way. Device TTS is provided as another aid where an installed Thai voice is available.

## High-risk phrases

Hospital, emergency, police, immigration, document, workplace, and employment phrases help users communicate. They do not provide diagnosis, legal rights advice, contract interpretation, or emergency dispatch. For important matters, ask for a qualified interpreter or professional confirmation. Emergency Quick Speak stays immediately available and is never covered by an ad.
