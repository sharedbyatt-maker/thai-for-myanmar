# Privacy and Google Play Data Safety draft

This is an implementation summary for a future owner-reviewed privacy policy, not legal advice or a published policy.

## V1 data handling

- No account, password, server database, location, contacts, microphone, photo, or file access is required.
- Favorites, recent phrases, theme, polite-form preference, learned phrase IDs, and quiz completion count are stored locally on the user's device/browser.
- Search and learning content are bundled; search text is not sent to a project backend.
- No first-party analytics or crash reporting SDK is included.
- Thai TTS calls the operating system or browser speech engine. Actual voice processing and any network behavior depend on the selected platform voice/provider; the app does not upload a separate recording.
- AdMob support is opt-in and currently disabled by default. When enabled for Android, Google Mobile Ads may collect/use device and advertising data under Google's SDK disclosures and the publisher's account configuration. Review the current Google Play Data Safety requirements and Google SDK disclosures before enabling production ads.

## Before public release

The owner should publish a privacy policy URL, provide accurate Play Console Data Safety answers for the exact SDK and ad configuration, complete any consent requirements applicable to the user's audience and region, and use owner-issued AdMob identifiers. Do not claim that the app collects no data if production ads are enabled.
