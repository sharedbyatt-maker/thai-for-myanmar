# Chang Thai V1 handoff

Recorded 23 November 2026, Thailand time. This is the starting point for a new maintainer or AI session. The GitHub repository is [sharedbyatt-maker/thai-for-myanmar](https://github.com/sharedbyatt-maker/thai-for-myanmar). Check current `main`, GitHub Actions and Render before reporting a new release status.

## Product and scope

Chang Thai teaches practical Thai to Burmese speakers, particularly people living, working or travelling in Thailand. The owner selected the current product as **V1**. Release Android first using the owner's existing Google Play developer account. Keep iPhone users on the existing website via Safari **Add to Home Screen**. Native iOS starts after the owner obtains an Apple Developer account. Collect feedback after Android V1 and plan feature or design changes as V2. Keep changes limited to the owner's requested scope.

## Working baseline

- **Web** — [Render preview](https://thai-for-myanmar-web-preview.onrender.com/) is the existing public static site. It auto-deploys `main` and uses Flutter **3.47.5**. The technical URL and repository name retain their original slugs. The latest verified product deploy at handoff was commit [1074666](https://github.com/sharedbyatt-maker/thai-for-myanmar/commit/10746668e1cd7f5653e33b417a852fadd05eec65). Web favicon, startup branding, PWA icons and iPhone Home Screen icon come from the owner's asset pack. Offline Web behavior is not guaranteed.
- **Android** — Chang Thai display name, package ID `com.sharedbyatt.thaiformyanmar`. Keep this ID for future updates. CI generates Android platform files with Flutter **3.47.5** and JDK 17 and runs `python3 tool/configure_android.py`. Owner-supplied launcher densities and splash artwork are in `tool/android_brand/`. Android 12+ uses the system launch icon before Flutter draws. Test the complete startup sequence on a physical phone. The branding APK build passed on [this run](https://github.com/sharedbyatt-maker/thai-for-myanmar/actions/runs/45146350717). For the mascot baseline, use [the exact-source run](https://github.com/sharedbyatt-maker/thai-for-myanmar/actions/runs/45149102109); its source and Flutter tests had passed at handoff. Verify its final jobs and artifacts before relying on them.
- **Learning** — 26 authored units, 178 lessons, 502 Quick Speak phrases. Thai text, Myanmar meaning and English-letter pronunciation in guided lessons. Listening questions reveal pronunciation only when Thai is revealed. The 990 base recordings plus 426 course recordings resolve all 535 authored-course audio bindings, including aliases. The last import added 347 MP3s. Technical validation passed; independent Thai pronunciation and tone review is pending.
- **UI and assets** — Winding Learn path, pinned unit banner, up-arrow/return-to-current-lesson button, icon-only mobile tabs and transparent topic-matched Learn mascots. Speaking and completion screens have their own poses. Preserve existing theme, lesson unlocks, streak, XP, local progress, browsing and audio behavior. See [AGENTS.md](../AGENTS.md) and [Learn UI contract](LEARN_UI_CONTRACT.md).
- **Data and connectivity** — Core Android lessons, bundled audio, search, favorites and progress are offline-first. Optional weekly League uses Google sign-in and Supabase; League data is separate from local learning progress. Ads are disabled by default. See [privacy implementation notes](PRIVACY_DRAFT.md).

## Android V1 release handoff

The owner received **Chang-Thai-V1-Android-Play-Store.zip** for Muse AI. The ZIP is a source and publishing handoff, with the exact product source at 1074666, build/signing helpers, launcher and splash assets, Play listing copy, feature graphic, and privacy/Data Safety drafts. It excludes credentials, signing keys and a production-signed AAB. The ZIP is not a required dependency for rebuilding: start with this repo, the [Android release guide](ANDROID_RELEASE.md), [listing](STORE_LISTING.md), and [Play icon](store-assets/chang-thai-play-icon.png). The product snapshot intentionally predates this documentation commit.

1. Verify whether Play Console already has an entry using the exact application ID and confirm its registered upload key and next unused version code. Proposed first public version is **1.0.0**, code **1** only if unused. The repo's baseline version is separate from that proposed release version.
2. Build a review APK and test a real device: branding, launch, offline lessons/audio, progress across restart, navigation, Light/Dark modes and sign-in if enabled. Capture genuine Android listing screenshots. Get the owner's public support contact and confirm listing, audience, countries and release settings.
3. Before submitting, publish a reviewed public privacy policy and surface the policy in-app. Complete accurate Play Data Safety and other declarations for the actual build. If optional League permits account creation, verify in-app and public account-deletion routes and server deletion behavior. The deletion entry points are the signed-in League screen and the [public instructions](https://thai-for-myanmar-web-preview.onrender.com/delete-account.html). The Supabase Edge Function validates the bearer token through Auth and deletes only that account. Verify both entry points with disposable accounts before release.
4. Build the final release AAB and sign it with the owner's registered upload key. Keep signing material and Play credentials outside Git. Verify package ID, certificate, version and Play target/compatibility requirements. CI release-mode output alone does not establish production signing.
5. Upload to Play Console Internal testing, verify delivery, then proceed to production with the owner. Public Android publication was not completed at handoff. Keep Web, native iOS and V2 work outside the Android publishing task.

## Verification commands

Use Flutter 3.47.5, Python 3 and the checked-in CI configuration.

```sh
flutter pub get
python3 tool/validate_content.py
python3 tool/validate_course_v2.py
python3 tool/validate_audio_manifest.py
flutter analyze --fatal-infos
flutter test
```

For Android scaffolding and build commands, see [Android release guide](ANDROID_RELEASE.md) and [CI](../.github/workflows/ci.yml). Before saying a change is deployed, check the target Render deploy and live URL. Before saying CI is green, check the exact commit's workflow conclusion.
