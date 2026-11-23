# Chang Thai owner console

The admin interface is served at /admin/ by the existing Render build. It uses the existing Chang Thai Supabase project. Passwords and Firebase service-account keys never belong in this repository.

## Activation

1. Apply the chang_thai_admin_controls migration to the Chang Thai Supabase project. Give the explicitly approved Auth user the boolean `chang_thai_admin` in server-managed app metadata. Confirm the user has set a password through a secure owner-controlled process. The admin database policies additionally require a password session. Ordinary League accounts and Google-only sessions cannot write settings or read drafts.
2. For Android notifications, create a dedicated Firebase project and register package `com.sharedbyatt.thaiformyanmar`. Enable Cloud Messaging and use a dedicated sender with only the permissions needed to create FCM messages. Store its service-account JSON as `CHANG_THAI_FCM_SERVICE_ACCOUNT` in Supabase Edge Function secrets. Deploy `send-chang-thai-notification` with gateway JWT verification disabled; the function requires a valid user bearer token checked with Supabase Auth, the server-managed admin role, and the password authentication method.
3. Place the project's Android client configuration at `android/app/google-services.json` after Flutter scaffolding and before running `python3 tool/configure_android.py`. A build without that file keeps the notification setting out of the Android UI. On a Firebase-enabled build opt in via Settings, verify delivery to a test phone with the app backgrounded, and update the Play privacy and Data Safety declarations for the exact binary.
4. V1 banners remain off by default. The admin can enable the Android Profile banner for an eligible Android release. To serve production banners the Android build still needs the correct AdMob App ID, banner unit ID and production build flags, with required consent handling. Web and iOS advertising are not integrated.

## Publishing

- Draft changes are private. Publish atomically updates the public settings and increments its revision. Conflicting edits are rejected rather than silently overwritten.
- Lesson changes use existing unit, lesson and line IDs. The editor can patch titles, unit goal/tips, translations, Latin pronunciation and Thai text for a selected voice. Supply an MP3 when changing Thai text, and listen to both voices and any associated spoken chunks before publishing. Uploads use unique filenames. Bundled content remains available on Android offline, and updated lines with replacement audio become active there after the matching file is cached and the app restarts. Web uses the published recordings online.
- In-app announcements use a published title, message and expiry. Android push is an explicit action on a published revision. One push request is allowed per revision, including when Firebase's result is uncertain. The TTL never exceeds the announcement expiry or Firebase's maximum. Firebase acceptance is not proof of receipt on a handset.
- Update notices compare the actual Android version code to the published latest and minimum version codes. They link to the existing Play package. Uploading binaries remains a Play Console operation. Lower versions receive an advisory update message; offline learning is not blocked.
