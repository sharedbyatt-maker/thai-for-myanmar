# Phrase content and validation

## Current V1 corpus

The bundled data currently contains **302 phrase records in 35 categories**. Categories cover greetings, introductions, numbers, money, time and dates, common questions and answers, food, shopping, convenience stores, daily life, transport and directions, workplace and factory, accommodation, apartment/landlord conversations, restaurants and street food, taxi/public transport, health and clinics, pharmacy, emergency, police, immigration/documents, bank, phone/SIM, job search, salary, overtime, and leave.

The long-term content target is about 500 genuinely useful phrases. This pass added 215 records to the original 87, for 302 total. No fluent Myanmar/Thai reviewer was available, so the library was not padded to the target; further expansion should wait for bilingual review. The validator checks structure and duplicate text; it does not certify fluency, pronunciation, or medical, legal, immigration, or employment accuracy. Myanmar and Thai speakers should review all translations before broad public release, with extra care for high-risk phrases. Content is written as practical communication help, not professional advice.

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
