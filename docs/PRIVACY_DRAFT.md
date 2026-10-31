# Privacy and Google Play Data Safety draft

This is an implementation summary for a future owner-reviewed privacy policy, not legal advice or a published policy.

## V1 data handling

- Core offline lessons do not require an account. Location, contacts, microphone, photos and file access are not requested. The optional weekly League requires an internet connection and Google sign-in.
- Favorites, recent phrases, theme, polite-form preference, learned phrase IDs, quiz completion count, learning progress, audio volume, and phrase correction drafts are stored locally on the user's device/browser. A correction draft is sent only if the user copies and sends it through another app.
- Search and learning content are bundled; search text is not sent to a project backend.
- No first-party analytics or crash reporting SDK is included.
- Thai TTS calls the operating system or browser speech engine. Actual voice processing and any network behavior depend on the selected platform voice/provider; the app does not upload a separate recording.
- AdMob support is opt-in and currently disabled by default. When enabled for Android, Google Mobile Ads may collect/use device and advertising data under Google's SDK disclosures and the publisher's account configuration. Review the current Google Play Data Safety requirements and Google SDK disclosures before enabling production ads.

## Optional weekly League

Google sign-in sends the basic identity scopes (openid, email, profile) to Supabase Auth. The app does not receive the Google password. Supabase stores the account identity, selected alias/avatar, membership, submitted challenge answers and competitive scoring records. The leaderboard exposes aliases, avatars, ranks and points, with a flag identifying the current account; it does not expose emails or Auth UUIDs. Opting out hides League participation; it does not delete the account or erase all server records. Offline progress remains device/browser-local and is not synchronized by League login. See [League operations and verification](WEEKLY_LEAGUES.md).

## Before public release

The owner should publish a privacy policy URL, provide accurate Play Console Data Safety answers for the exact SDK and ad configuration, complete any consent requirements applicable to the user's audience and region, and use owner-issued AdMob identifiers. Do not claim that the app collects no data if production ads are enabled.
