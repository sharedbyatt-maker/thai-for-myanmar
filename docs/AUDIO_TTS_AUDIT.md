# Thai voice selection and audio safety audit

## Scope

The app uses flutter_tts 4.2.5 for system speech. This audit covers the Web Preview and Android code paths. It does not claim that a device voice sounds natural to a native Thai speaker.

## Root cause

The previous SpeechService requested th-TH but did not inspect the available voice list, select a Thai voice, or reject a failed language request. It also treated a zero or null result from speak as success.

In flutter_tts 4.2.5, the Web implementation scans speechSynthesis.getVoices() for a th-TH prefix. When no matching voice is in the current list, it leaves the utterance's previous/default voice untouched while the method handler still returns success. The Web setVoice method also silently does nothing when an exact name/locale match is absent. An empty or late-loading voice list can therefore leave the browser default voice in place. The application previously reported success for that path.

The Android plugin checks language availability before setting its language and returns a failure value when it is unavailable, but the application previously ignored that result. Android TextToSpeech itself may use the closest language match and explicitly recommends checking availability first.

## Current safeguards

- Re-enumerate voices for each utterance and retry briefly for browsers that populate voices asynchronously.
- Accept only locale tags th or th-TH (including th-TH subtags); prefer th-TH and choose deterministically.
- Request th-TH and explicitly select the enumerated Thai voice before speaking.
- Treat explicit platform failures, speech errors, missing start/completion callbacks, and timeouts as unavailable.
- Report success only after the engine starts and completes the utterance.
- Serialize utterances so one request cannot change voice settings while another is still running.
- Show a Burmese message that a usable Thai voice is unavailable. The Thai phrase remains visible for the learner to show to a Thai speaker.

## Platform behavior and limits

| Platform | Voice discovery | Selection | Safe failure |
|---|---|---|---|
| Web | flutter_tts returns browser voice names and BCP 47 locales | Sends the selected name and locale to the Web Speech implementation | No Thai locale, failed request, speech error, or missing completion returns unavailable |
| Android | flutter_tts returns installed engine voices and locales | Requests th-TH, then selects the exact enumerated voice | Missing/unsupported Thai voice or a rejected selection returns unavailable |

The system voice is device-, browser-, and engine-dependent. A Thai locale label is a technical language signal, not proof of native-like tone, vowel length, or naturalness. The Web plugin does not expose a read-back property for the selected voice; the app checks its returned voice inventory, requests that exact name/locale, then requires speech start and completion. Audible quality still requires human listening.

The speech rate remains 0.43 because no controlled human listening comparison was available to justify changing it. No paid TTS provider or generated phrase audio was added.

## Alternatives considered

- System/browser TTS with strict Thai voice selection is free and needs no backend, but availability and voice quality vary by device.
- A hosted TTS service could standardize voice quality, but requires network access and may introduce recurring cost and privacy/licensing review; paid service setup is outside this authorization.
- Prerecorded audio for 500 fixed phrases could improve consistency and offline playback, but requires verified Thai speakers, explicit recording/distribution rights, substantial asset storage, and a maintenance path. No unverified bulk-generated audio was shipped.

## Language corpus status

The existing content review ledger covers all 500 IDs and records an AI-assisted review. Its cited Thai dictionary and medical usage references are lexical spot checks; they do not externally validate every complete sentence, Myanmar translation, or Myanmar-script reading. Therefore language, Myanmar meaning, and pronunciation remain provisional pending broader source-backed verification and an independent fluent Thai–Myanmar review. This TTS change does not claim to finish that separate workstream.

## References

- flutter_tts 4.2.5 package and Web feature list: https://pub.dev/packages/flutter_tts/versions/4.2.5
- flutter_tts Web implementation: https://github.com/dlutton/flutter_tts/blob/master/lib/flutter_tts_web.dart
- flutter_tts Dart API: https://pub.dev/documentation/flutter_tts/latest/flutter_tts/FlutterTts-class.html
- MDN, SpeechSynthesis.getVoices(): https://developer.mozilla.org/en-US/docs/Web/API/SpeechSynthesis/getVoices
- MDN, SpeechSynthesisUtterance.voice: https://developer.mozilla.org/en-US/docs/Web/API/SpeechSynthesisUtterance/voice
- Android TextToSpeech.setLanguage(): https://developer.android.com/reference/android/speech/tts/TextToSpeech#setLanguage(java.util.Locale)
- Existing corpus references are listed in docs/CONTENT_REVIEW_LEDGER.md.
