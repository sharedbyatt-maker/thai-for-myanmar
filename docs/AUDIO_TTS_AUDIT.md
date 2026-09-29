# Thai voice selection and audio safety audit

## Scope

The app uses flutter_tts 4.2.5 for system speech. This audit covers the Web Preview and Android code paths. It does not claim that a device voice sounds natural to a native Thai speaker.

## Root cause and cross-browser follow-up

The previous SpeechService requested th-TH but did not inspect the available voice list, select a Thai voice, or reject a failed language request. It also treated a zero or null result from speak as success.

In flutter_tts 4.2.5, the Web implementation reads `speechSynthesis.getVoices()` as a snapshot. It does not subscribe to `voiceschanged`. The application retried snapshots for only 800 ms. A desktop browser that exposed its voices later could therefore be reported as unavailable even when a Thai voice subsequently appeared. The plugin's Web `setVoice` also silently does nothing when an exact name/locale match is absent.

The old app matcher accepted only `th`, `th-TH`, and `th-TH-*`. It rejected genuine Thai language tags such as `th-SG`. That filter is now based on a valid `th` primary language subtag, with `th-TH` preferred, other `th-*` tags next, and bare `th` last.

The live preview can run a desktop environment different from the learner's Windows PC. The hidden `?tts-debug=1` page reports that device's browser, platform, voice counts, Thai voices, voice-change events, selected voice, and last result locally. Use it to distinguish a delayed voice list from a device/browser with no Thai voice. It sends no diagnostic data.

The Android plugin checks language availability before setting its language and returns a failure value when it is unavailable, but the application previously ignored that result. Android TextToSpeech itself may use the closest language match and explicitly recommends checking availability first.

## Current safeguards

- Re-enumerate voices for each utterance. On Web, wait for `voiceschanged` and recheck the inventory within a bounded three-second window; native platforms retain bounded polling.
- Accept valid Thai language tags, normalize case and underscores, and prefer exact `th-TH`, then other `th-*`, then base `th`.
- Request th-TH and explicitly select the enumerated Thai voice before speaking.
- The Web path attaches the selected `SpeechSynthesisVoice` object to each utterance and refuses to dispatch if that exact Thai voice is no longer present.
- Treat explicit platform failures, speech errors, missing start/completion callbacks, and timeouts as unavailable.
- Report success only after the engine starts and completes the utterance.
- Serialize utterances so one request cannot change voice settings while another is still running.
- Show a Burmese message that a usable Thai voice is unavailable and provide a safe retry. The Thai phrase remains visible for the learner to show to a Thai speaker.

## Platform behavior and limits

| Platform | Voice discovery | Selection | Safe failure |
|---|---|---|---|
| Web | The Web Speech API exposes voice names and BCP 47 locales; `voiceschanged` prompts a bounded recheck | Selects the actual Thai `SpeechSynthesisVoice` and assigns it to each utterance | Missing Thai locale, unavailable API, failed dispatch, speech error, or missing callbacks returns unavailable |
| Android | flutter_tts returns installed engine voices and locales | Requests th-TH, then selects the exact enumerated voice | Missing/unsupported Thai voice or a rejected selection returns unavailable |

The system voice is device-, browser-, and engine-dependent. A Thai locale label is a technical language signal, not proof of native-like tone, vowel length, or naturalness. The Web plugin does not expose a read-back property for the selected voice; the app checks its returned voice inventory, requests that exact name/locale, then requires speech start and completion. Audible quality still requires human listening.

The existing speech rate remains 0.43 because no controlled human listening comparison was available to justify changing it. No paid TTS provider or generated phrase audio was added.

## Cross-browser source and license review

- Reviewed the exact flutter_tts 4.2.5 Web package source. flutter_tts is MIT-licensed; its Web `getVoices()` returns the current snapshot and the plugin does not register a `voiceschanged` listener. Android and other native platforms continue using the plugin adapter.
- Followed the Web Speech API behavior documented by MDN: `getVoices()` returns the current device/browser voice list, and `voiceschanged` fires when that list changes. No MDN sample code was copied.
- Added Dart's `web` 1.1.1 package for typed browser API bindings. It is BSD-3-Clause licensed. No plugin implementation code was copied or modified.

## Alternatives considered

- System/browser TTS with strict Thai voice selection is free and needs no backend, but availability and voice quality vary by device.
- A hosted TTS service could standardize voice quality, but requires network access and may introduce recurring cost and privacy/licensing review; paid service setup is outside this authorization.
- Prerecorded audio for 500 fixed phrases could improve consistency and offline playback, but requires verified Thai speakers, explicit recording/distribution rights, substantial asset storage, and a maintenance path. No unverified bulk-generated audio was shipped.

## Language corpus status

The existing content review ledger covers all 500 IDs and records an AI-assisted review. Its cited Thai dictionary and medical usage references are lexical spot checks; they do not externally validate every complete sentence, Myanmar translation, or Myanmar-script reading. Therefore language, Myanmar meaning, and pronunciation remain provisional pending broader source-backed verification and an independent fluent Thai–Myanmar review. This TTS change does not claim to finish that separate workstream.

## References

- flutter_tts 4.2.5 package and Web feature list: https://pub.dev/packages/flutter_tts/versions/4.2.5
- flutter_tts Web implementation: https://github.com/dlutton/flutter_tts/blob/master/lib/flutter_tts_web.dart
- Dart `web` package 1.1.1: https://pub.dev/packages/web/versions/1.1.1
- flutter_tts Dart API: https://pub.dev/documentation/flutter_tts/latest/flutter_tts/FlutterTts-class.html
- MDN, SpeechSynthesis.getVoices(): https://developer.mozilla.org/en-US/docs/Web/API/SpeechSynthesis/getVoices
- MDN, SpeechSynthesis.voiceschanged: https://developer.mozilla.org/en-US/docs/Web/API/SpeechSynthesis/voiceschanged_event
- MDN, SpeechSynthesisUtterance.voice: https://developer.mozilla.org/en-US/docs/Web/API/SpeechSynthesisUtterance/voice
- Android TextToSpeech.setLanguage(): https://developer.android.com/reference/android/speech/tts/TextToSpeech#setLanguage(java.util.Locale)
- Existing corpus references are listed in docs/CONTENT_REVIEW_LEDGER.md.
