# Phrase content and validation

## Current V1 corpus

The bundled dataset contains **500 phrase records across 35 categories**. This continuation added 198 practical phrases to the existing 302-record corpus without changing its category structure. Coverage includes daily situations as well as workplace, factory, supervisor, salary, overtime, leave, medical, pharmacy, emergency, police, and document conversations.

The user rejected the previous corpus on language quality. A further AI-assisted correction pass has reviewed the Thai, Myanmar meaning, English context, and Myanmar reading aid across all 500 records. This remains **provisional learner material**: no independent fluent Thai–Myanmar reviewer has signed off. The validator confirms structure and several known failure patterns, not naturalness, fluency, or pronunciation accuracy. A fluent bilingual review is necessary before broad public release, with particular care for high-risk phrases. Phrases are for communication only, not medical, legal, immigration, or employment advice.

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

Pronunciation is an approximate reading aid written for Myanmar speakers, not a formal phonetic transcription. A single slash separates the **complete male and female readings** in the same order as `thaiMale` and `thaiFemale`. Spaces separate spoken syllables or short word groups. The polite question particle `คะ` is shown as `ခ` (short kha); statement `ค่ะ` as `ခါ့` (falling kha); `ครับ` as `ခရပ်`. The distinct Thai words `ไม่` (negation) and `ไหม` (question) are approximated as `မိုင့်` and `မိုင်`. `งาน` (work, /ŋaːn/) and `เงิน` (money, /ŋɤn/) use `ငါန်` and `ငွန်း` respectively. These distinctions are teaching cues, not exact phonetics. Thai has five lexical tones and vowels/consonants that Myanmar script alone cannot reliably encode. Learners should listen to a Thai speaker or device TTS where available. Do not use this reading aid as the only source for a critical conversation.

## High-risk phrases

Hospital, emergency, police, immigration, document, workplace, and employment phrases help users communicate. They do not provide diagnosis, legal rights advice, contract interpretation, or emergency dispatch. For important matters, ask a qualified interpreter or professional. Emergency Quick Speak remains immediately available and is never covered by an ad.
