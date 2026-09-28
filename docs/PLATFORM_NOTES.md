# Web and Android behavior

| Feature | Android | Web Preview |
| --- | --- | --- |
| Bundled lessons, categories, search, quiz | Local bundled JSON; works offline after install. | Included in the downloaded Web bundle; requires loading the page once. |
| Favorites and progress | Device-local preferences. | Browser-origin local storage through the preferences plugin. Clearing browser storage or changing the preview URL can reset it. |
| Thai TTS | Uses the device TTS engine and its installed Thai voice. | Uses browser speech synthesis and voices exposed by the operating system/browser. Voice availability and pronunciation vary. |
| Ads | Optional Android banner on Home only; disabled by default and fail-closed. | Ads are not compiled into the Web target. |
| Navigation/back | Material bottom navigation and Android system back behavior. | Browser history and Web back behavior depend on the browser. |
| Fonts | Android system fonts provide Thai and Myanmar fallback. | Browser and operating system provide the glyph fallback. Appearance may differ. |
| Offline use | Core features work from bundled assets. TTS depends on a local Thai voice. | A first page load is needed; browser cache may allow later use, but Web offline behavior is not a release promise. |

The Web Preview is an owner UI review tool. It does not verify Android TTS, Android storage, ad SDK behavior, Play signing, or physical-device layout. CI builds Android outputs, but no physical Android device is available for this project at present.
