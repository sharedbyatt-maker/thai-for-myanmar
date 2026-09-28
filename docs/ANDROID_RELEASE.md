# Android and Google Play preparation

## Current Android identity

- Display name: **Thai for Myanmar**
- Android application ID: `com.sharedbyatt.thaiformyanmar`
- Flutter version: `0.1.0+1` (`0.1.0` version name, `1` build number)
- V1 account requirement: none
- AdMob: disabled by default; the Android scaffold uses Google's public test app ID for debug verification only.

## Builds

GitHub Actions builds and keeps:

- a debug APK for emulator/manual testing;
- a release-mode AAB for build verification;
- the generated Android project scaffold.

The latest verified Android run used Flutter stable 3.47.5. Its generated Android template defaults to `compileSdk 36` and `targetSdk 36`, meeting Google Play's current new-app target requirement. The workflow tracks Flutter stable, so confirm the final AAB target API in Play Console before release.

The AAB produced without owner signing material is **not ready for Google Play upload**. Do not distribute a debug-signed or unsigned release as a production app.

## Owner-controlled items before publishing

1. Create/verify the Google Play Console account and accept Google's current agreements.
2. Choose and review the final app title and store listing.
3. Create an upload key in a secure owner-controlled environment; store its keystore and passwords outside GitHub. Configure protected GitHub/CI secrets only after agreeing to the release process.
4. Replace the test AdMob app ID in the generated Android manifest and provide the production banner unit ID using the documented `ADMOB_ANDROID_BANNER_ID` define. Keep ads disabled until this is done and the privacy/consent flow has been reviewed.
5. Publish a privacy policy URL and complete Data Safety declarations based on enabled SDKs.
6. Create a Play Console internal testing release, upload the owner-signed AAB, and target Android 16 (API 36) or higher for new-app submissions and updates under the current policy (effective August 31, 2026).
7. If this is a personal developer account created after November 13, 2023, complete Google's required closed test with at least 12 opted-in testers for 14 continuous days before applying for production access.

Never commit `.jks`, `.keystore`, key properties, passwords, Play credentials, or production AdMob IDs. Google Play account ownership and final policy/store acceptance remain with the owner.
