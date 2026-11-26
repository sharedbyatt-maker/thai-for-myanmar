# Chang Thai owner console

The admin interface is served at /admin/ by the existing Render build. It uses the existing Chang Thai Supabase project. Passwords and Firebase service-account keys never belong in this repository.

## Activation

1. Apply the chang_thai_admin_controls migration to the Chang Thai Supabase project. Give the explicitly approved Auth user the boolean `chang_thai_admin` in server-managed app metadata. Confirm the user has set a password through a secure owner-controlled process. The admin database policies additionally require a password session. Ordinary League accounts and Google-only sessions cannot write settings or read drafts.
2. For Android notifications, create a dedicated Firebase project and register package `com.sharedbyatt.thaiformyanmar`. Enable Cloud Messaging and use a dedicated sender with only the permissions needed to create FCM messages. Store its service-account JSON as `CHANG_THAI_FCM_SERVICE_ACCOUNT` in Supabase Edge Function secrets. Deploy `send-chang-thai-notification` with gateway JWT verification disabled; the function requires a valid user bearer token checked with Supabase Auth, the server-managed admin role, and the password authentication method.
3. Run `python3 tool/configure_android.py` after Flutter scaffolding. It copies the public Firebase Android client configuration from `tool/android_controls/google-services.json` unless an app-local config already exists. On a Firebase-enabled build opt in via Settings, verify delivery to a test phone with the app backgrounded, and update the Play privacy and Data Safety declarations for the exact binary.
4. Android ads remain off by default. Configure the app's Privacy & messaging forms in AdMob and verify the production consent and release settings before enabling ads.

## Publishing

- Draft changes are private. Publish atomically updates the public settings and increments its revision. Conflicting edits are rejected rather than silently overwritten.
- Lesson changes use existing unit, lesson and line IDs. The editor can patch titles, unit goal/tips, translations, Latin pronunciation and Thai text for a selected voice. Supply an MP3 when changing Thai text, and listen to both voices and any associated spoken chunks before publishing. Uploads use unique filenames. Bundled content remains available on Android offline, and updated lines with replacement audio become active there after the matching file is cached and the app restarts. Web uses the published recordings online.
- In-app announcements use a published title, message and expiry. Android push is an explicit action on a published revision. One push request is allowed per revision, including when Firebase's result is uncertain. The TTL never exceeds the announcement expiry or Firebase's maximum. Firebase acceptance is not proof of receipt on a handset.
- Update notices compare the actual Android version code to the published latest and minimum version codes. They link to the existing Play package. Uploading binaries remains a Play Console operation. Lower versions receive an advisory update message; offline learning is not blocked.


## Android AdMob

An Android build with ads support loads the published ad configuration at launch. An unavailable configuration keeps production ads off for that launch. An admin can edit all six IDs and switches and publish a master off setting. Changes apply when the ads-enabled Android app next opens. The manifest App ID belongs to the Android binary.

| Format | Placement |
| --- | --- |
| Banner | Android Profile |
| Native | Review, after scheduled-review content, using Google's labeled small template |
| Interstitial | Confirmed transition after a newly completed lesson; shows only if ready |
| Rewarded | Optional button on lesson completion offering one extra local practice round |
| Rewarded interstitial | Eligible lesson transition with an explanation and an explicit skip option |
| App open | Returning after at least two minutes away, on Learn or Quests after at least three completed lessons |

Full-screen formats share a default eight-minute cooldown and three-per-day device cap. Automatic lesson transitions are eligible every four newly completed lessons by default. App open also has a 24-hour limit. Rewarded interstitial and regular interstitial share the same transition, and a skipped rewarded offer does not fall back to another ad. Quick Speak, SOS, review exercises, and active lessons stay ad-free. The reward grants a local practice round only and is independent of course XP and League scoring.

Use `flutter run --dart-define=ENABLE_ADS=true` on Android for Google test ads. The generated debug manifest uses Google's test App ID. Build the production AAB with `flutter build appbundle --release --dart-define=ENABLE_ADS=true --dart-define=ADMOB_PRODUCTION=true`. The generated release manifest uses the owner-provided Chang Thai App ID. Ad unit IDs are set in Admin, where the owner-provided IDs prefill fields and can be replaced. Leave the master switch off until physical Android testing, app setup in AdMob, UMP messaging, privacy policy, and Play declarations are complete. The app uses UMP eligibility before requesting ads and exposes privacy choices when UMP requires them.
