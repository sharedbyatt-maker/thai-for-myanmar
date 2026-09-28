# Phrase content and validation

## Current V1 corpus

The bundled dataset contains **500 phrase records across 35 categories**. This continuation added 198 practical phrases to the existing 302-record corpus without changing its category structure. Coverage includes daily situations as well as workplace, factory, supervisor, salary, overtime, leave, medical, pharmacy, emergency, police, and document conversations.

The additions received a structured editorial pass for Thai–Myanmar–English meaning alignment, natural conversational wording, polite particles, and Myanmar-readable pronunciation. No independent fluent Thai–Myanmar reviewer has signed off on the corpus. The validator confirms structure and integrity, not language fluency or pronunciation accuracy. A fluent bilingual review remains necessary before broad public release, with particular care for high-risk phrases. Phrases are for communication only, not medical, legal, immigration, or employment advice.

## Phrase fields

Each phrase has a stable lowercase ID, a category ID, Thai display text, Myanmar meaning, Myanmar-readable pronunciation, English meaning, non-empty search keywords, and tags. `thaiMale` and `thaiFemale` supply spoken forms with appropriate polite particles where the wording calls for them. `note` is optional.

## Editing steps

1. Add or correct a phrase in `assets/data/phrases.json`.
2. Add a category in `assets/data/phrase_categories.json` only when a distinct browse destination is useful.
3. Add useful Myanmar search synonyms to `keywords`.
4. Mark workplace, health, police, immigration/document, employment, and emergency phrases as `high-risk`. Mark emergency-category phrases with the `emergency` tag. Allergy-related phrases may also use `high-risk` when a misunderstanding could cause harm.
5. Run `python3 tool/validate_content.py`, `flutter analyze`, and `flutter test`.
6. Ask fluent Myanmar and Thai reviewers to check meaning, naturalness, and pronunciation. Record their approval before describing the corpus as language-reviewed.

## Pronunciation note

Pronunciation is an approximate reading aid written for Myanmar speakers, not a formal phonetic transcription. Thai tones and some consonants cannot be represented exactly this way. Device TTS is provided as another aid where an installed Thai voice is available.

## High-risk phrases

Hospital, emergency, police, immigration, document, workplace, and employment phrases help users communicate. They do not provide diagnosis, legal rights advice, contract interpretation, or emergency dispatch. For important matters, ask a qualified interpreter or professional. Emergency Quick Speak remains immediately available and is never covered by an ad.
