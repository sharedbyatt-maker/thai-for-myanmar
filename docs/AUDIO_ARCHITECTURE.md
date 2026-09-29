# Thai audio architecture and source review

Research snapshot: 2026-09-29.

## Decision

The playback architecture is asset-first: use a phrase-and-form-specific bundled Thai audio file when the manifest exactly matches the Thai text on screen, then try the existing verified Thai-only system TTS. A non-Thai system voice is never an allowed fallback.

The app now has this player, an empty versioned manifest, UI loading/stop states, and tests for mappings and safe fallback. **No audio source has cleared the text, rights, and human-listening checks.** The manifest deliberately contains zero entries; there are no placeholder or generated phrase recordings in the app.

When cleared assets are added, MP3 files are bundled under `assets/audio/thai/`. Android will carry those Flutter assets in the app package and can play them offline. Flutter Web can fetch the same files from the static site; the current site does not establish that every browser has cached them for offline web use. The player uses the `audioplayers` package (MIT licensed, Android and web implementations). Its bundled `AssetSource` API is the integration point. No actual audio file is present, so codec playback and audible quality are not yet verified on either platform.

Every mapping records `phraseId`, `form` (`male`, `female`, or `shared`), the exact Thai source string, and a relative MP3 asset path. Runtime matching rejects an entry if the currently selected polite form differs from its source text. The validator also rejects stale text, unknown phrase IDs, missing files, duplicate mappings, unsafe paths, and orphaned audio files.

## Corpus and current coverage

The current main corpus has 500 phrases in 35 categories. 486 phrases have separate male and female Thai forms; 14 are neutral. That creates 986 selected phrase/form outputs. Their Thai text totals 21,559 characters and has no exact duplicates in the current corpus. The script computes these totals from the dataset so they change with future edits.

| Coverage measure | Current |
| --- | ---: |
| Phrases with controlled audio | 0 / 500 |
| Male-form audio mappings | 0 / 486 |
| Female-form audio mappings | 0 / 486 |
| Neutral-form audio mappings | 0 / 14 |
| Selected forms still missing audio | 986 |
| Bundled audio size | 0 bytes |

The last value is not an estimate of final size. Asset size must be measured after a licensed voice and finalized Thai text are available.

## Source comparison

| Option | Strengths | Limits and current decision |
| --- | --- | --- |
| Bundled verified recordings or generated files | Stable output, no runtime secret or request latency, offline on Android; static files also work from the web origin | Audio rights and each final phrase must be approved first. This is the selected delivery architecture, not yet a selected voice/source. |
| Hosted static files | Keeps the Android app download smaller and can be served from the existing site | Requires network for first playback and an offline cache for later use; adds asset hosting and version/cache maintenance. No separate host is needed for a static site, but no files are ready. |
| Browser/device TTS | No bundled audio or per-phrase asset work; can remain a fallback | Voice availability and selection are user-agent/device dependent. The existing implementation verifies a Thai voice and refuses a non-Thai default, but this cannot guarantee a normal sound experience on every device. |
| Google Cloud Text-to-Speech, generated once | Audio files may be used in apps/media under Google Cloud terms, so static output needs no runtime key. Chirp 3 HD currently includes 1 million characters/month, then costs US$30 per million. | An active billing account is required even within the free quota; overage is billable. No account, billing, credentials, or samples were created. Even with a source, audio needs human listening for Thai tones, vowel length, particles, and rhythm. |
| Thai native-speaker recordings | Best route to deliberate natural rhythm and pronunciation if recorded and reviewed by a qualified speaker | Requires a speaker, recording/review time, and written rights for app distribution, offline use, and any future commercial use. No recording or release is available. Do not copy third-party pronunciation recordings into the app. |
| Open Thai TTS model | Could produce a local batch without a runtime service | The reviewed Meta MMS Thai and Wayu-Paxa Edge model cards are CC-BY-NC-4.0. A Thai F5-TTS card labels its fine-tune CC-BY-4.0 but warns that long text and some words can be inaccurate; the broader F5 model/data licensing and voice provenance need independent clearance. An OmniVoice Thai fine-tune lists Apache-2.0 for the model, but its card names public and custom voice data while the linked dataset page does not show a license; it also reports ASR transcript errors and only two speakers. None currently clears both rights and listening checks. |
| VachanaTTS ONNX | The model card labels the package MIT, lists four Thai male/female voices, and says it runs on CPU/GPU. | Its linked code repo says the model is fine-tuned from Meta MMS-TTS-THA, whose model card says CC-BY-NC-4.0. The separate MIT label does not settle the upstream model/data rights. Treat it as a research candidate only until that license chain and voice-data provenance are cleared; no sample has been human-reviewed. |

The current 21,559-character corpus would fit inside Chirp 3 HD's listed monthly free character allowance if the account had no other usage. After that allowance, synthesizing this text once would be about US$0.65 at the listed rate, before any SSML characters. This arithmetic does not remove the billing-account requirement or authorize spending, so Google was not used.

## Release gates

1. A fluent Thai–Myanmar reviewer finalizes Thai text and male/female variants and rechecks the paired Myanmar meanings and readings. The current language audit is provisional; its 500 MEDIUM ratings are not independent certification.
2. Choose either a qualified native speaker with a signed distribution release or a provider/model whose model, voice-data, output, offline, redistribution, and commercial terms are all documented.
3. Listen to representative Thai examples before expanding coverage. No human has listened to audio in this review, so native-like pronunciation is **not verified**.
4. Add final recordings only after the canonical text is approved. Run `python3 tool/validate_audio_manifest.py`, the Flutter tests, and web/Android device playback checks. Measure the actual bundled bytes then.

## Research links

- [Flutter assets](https://docs.flutter.dev/ui/assets/assets-and-images) and [Flutter web release bundles](https://docs.flutter.dev/deployment/web)
- [`audioplayers` platform support and bundled asset API](https://github.com/bluefireteam/audioplayers/blob/main/getting_started.md); [package MIT license](https://pub.dev/packages/audioplayers/license)
- [W3C Web Speech API](https://dvcs.w3.org/hg/speech-api/raw-file/tip/webspeechapi)
- [Google Cloud TTS pricing](https://cloud.google.com/text-to-speech/pricing), [data logging](https://docs.cloud.google.com/text-to-speech/docs/data-logging), [quotas and generated-audio use](https://docs.cloud.google.com/text-to-speech/quotas), and [getting started](https://cloud.google.com/text-to-speech/docs/getting-started)
- [VachanaTTS ONNX model card and four speaker IDs](https://huggingface.co/VIZINTZOR/VachanaTTS) and [its code repository, which identifies the MMS-TTS-THA fine-tune](https://github.com/VYNCX/VachanaTTS)
- [Google Cloud TTS setup, which requires billing](https://docs.cloud.google.com/text-to-speech/docs/get-started)
- [Meta MMS Thai model card](https://huggingface.co/facebook/mms-tts-tha)
- [Wayu-Paxa TTS Edge model card](https://huggingface.co/wayu-ai/wayu-paxa-tts-edge)
- [OmniVoice Thai fine-tune](https://huggingface.co/hotdogs/omnivoice-thai) and its [linked training dataset](https://huggingface.co/datasets/Thanarit/Thai-Voice-Test7)
- [VIZINTZOR Thai F5-TTS model card](https://huggingface.co/VIZINTZOR/F5-TTS-THAI) and [upstream F5-TTS model licensing notes](https://github.com/SWivid/F5-TTS/blob/main/src/f5_tts/infer/SHARED.md)
