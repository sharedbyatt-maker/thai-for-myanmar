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

The AAB produced without owner signing material is **not ready for Google Play upload**. Do not distribute a debug-signed or unsigned release as a production app.

## Owner-controlled items before publishing

1. Create/verify the Google Play Console account and accept Google's current agreements.
2. Choose and review the final app title and store listing.
3. Create an upload key in a secure owner-controlled environment; store its keystore and passwords outside GitHub. Configure protected GitHub/CI secrets only after agreeing to the release process.
4. Replace the test AdMob app ID in the generated Android manifest and provide the production banner unit ID using the documented `ADMOB_ANDROID_BANNER_ID` define. Keep ads disabled until this is done and the privacy/consent flow has been reviewed.
5. Publish a privacy policy URL and complete Data Safety declarations based on enabled SDKs.
6. Create a Play Console internal testing release, upload the owner-signed AAB, and complete any Play review and target API requirements shown by the Console.

Never commit `.jks`, `.keystore`, key properties, passwords, Play credentials, or production AdMob IDs. Google Play account ownership and final policy/store acceptance remain with the owner.
