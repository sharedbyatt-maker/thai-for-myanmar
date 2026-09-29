# Architecture and local development

## Product shape

This is one Flutter application with bundled JSON content and local-only user state. There is no account service, API backend, analytics SDK, or cloud database in V1.

```text
assets/data/*.json -> PhraseRepository -> Home / Learn / Situations / Speak / Quiz
                                  AppState -> device-local preferences
                           ThaiPlaybackService -> verified bundled Thai audio when mapped
                                               -> SpeechService -> verified Android/browser Thai TTS fallback
                                  AdBannerSlot -> Android only, opt-in
```

## Main files

| Path | Purpose |
| --- | --- |
| `lib/main.dart` | Loads bundled content and local state, then starts the app. |
| `lib/models/phrase.dart` | Typed phrase and category records. |
| `lib/data/phrase_repository.dart` | Offline search and category lookup. |
| `lib/services/app_state.dart` | Favorites, recent phrases, learned IDs, theme, polite form, and quiz count. |
| `lib/services/thai_playback_service.dart` | Asset-first Thai playback with exact phrase/form/text matching and safe TTS fallback. |
| `lib/services/thai_audio_catalog.dart` | Loads the versioned mapping from phrase/form/text to bundled audio assets. |
| `lib/services/speech_service.dart` | Thai-only system TTS fallback with a safe unavailable result. |
| `lib/services/ad_slot*.dart` | Conditional Android banner support and a Web no-op. |
| `lib/screens/` | Navigation destinations and phrase flows. |
| `assets/data/` | Versioned phrase and category datasets. |
| `tool/validate_content.py` | CI content structure and reference validation. |
| `tool/validate_audio_manifest.py` | Validates audio mappings, exact Thai text, asset paths, coverage, and orphaned files. |
| `tool/configure_android.py` | Applies package name, test AdMob app ID, label, and launcher icon to generated Android scaffolding. |
| `.github/workflows/ci.yml` | CI verification and retained Android/Web build artifacts. |

## Local setup

Use Flutter stable and Java 17 or newer. The repository keeps Flutter-generated platform folders out of source control to avoid checking in tool-version-specific Gradle wrappers. Generate them once in a fresh checkout:

```sh
flutter create . --platforms=android,web --org=com.sharedbyatt --project-name=thai_for_myanmar
python3 tool/configure_android.py
flutter pub get
```

Then use `flutter run -d chrome` for the Web Preview or `flutter run` with an emulator/device. Platform generation does not overwrite the existing Dart application files. CI performs these same setup steps before its checks.

## Content flow

`PhraseRepository.load` reads JSON from Flutter assets, so lessons and search do not call a server. Search normalizes case and whitespace and searches Thai, Myanmar, pronunciation, English, keywords, and tags. `tool/validate_content.py` checks required fields, IDs, duplicates, category references, searchable keywords, high-risk labels, and that every category has content.

## Local persistence

`AppState` stores favorites, learned phrase IDs, the last 12 opened phrases, theme choice, polite voice ending, and completed quiz count with `shared_preferences`. If browser/device storage fails, the app continues for the current session in memory. The browser and Android keep separate state.

## Adding content

Edit `assets/data/phrases.json` and/or `phrase_categories.json`, then run `python3 tool/validate_content.py` and the Flutter tests. Keep phrase IDs stable after users may have saved them. Search aliases belong in `keywords`; do not put lists of phrases in widget code. Have the Myanmar meaning, Thai naturalness, gendered polite endings, and Myanmar-readable pronunciation checked by fluent speakers before a public launch.

## CI behavior

Pull requests and `main` pushes run formatting, static analysis, Flutter tests, content and audio-manifest validation, Android debug APK and release-mode AAB builds, and a release Web build. Build artifacts include the APK, AAB, Web bundle, and generated Android scaffold for owner review. GitHub Pages publication was removed in PR #4. The owner Web Preview is deployed separately as a free Render static site; this workflow verifies the Web bundle but does not currently deploy it to Render.
