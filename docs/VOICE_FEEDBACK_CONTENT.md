# Voice setup, phrase feedback, and content additions

The visible Settings voice test plays the bundled `greet_hello` phrase through
the existing asset-first/strict Thai TTS service. A completed playback says the
test finished; the user must still listen to assess quality. If the service
reports unavailable, the screen gives platform-specific steps to locate or
install Thai text-to-speech voices. Menu names vary between devices. No voice
files are bundled by this change.

The phrase detail correction form persists a draft in SharedPreferences. The
saved list in Settings lets the user copy or delete it. The app does not claim
to send a draft to the project; the user must paste and send it separately.
Each draft carries the phrase ID, selected Thai form, Myanmar meaning,
description and timestamp. Saves and deletes report failure rather than claiming
success. Local storage holds up to 100 reports.

Two non-sensitive everyday phrases were added after checking absence from the
existing 500 phrases and checking their meaning/context against the earlier
owner prototype (`data/phrases_v1.json`):

| ID | Thai | Myanmar | Context |
| --- | --- | --- | --- |
| `apartment_elevator_available` | `มีลิฟต์ไหมครับ / มีลิฟต์ไหมคะ` | ဓာတ်လှေကား ရှိပါသလား။ | Apartment or building facilities |
| `phone_call_back` | `ช่วยโทรกลับมาได้ไหมครับ / ช่วยโทรกลับมาได้ไหมคะ` | ပြန်ဖုန်းဆက်ပေးလို့ရမလား။ | Phone conversation |

Sources for lexical/context checks: the owner's draft phrases at
https://github.com/sharedbyatt-maker/thai-helper-app/blob/master/data/phrases_v1.json;
Thailand's health-facility standard uses `มีลิฟต์` in building context at
https://pmhos.moph.go.th/hs4/; the Thai government's telephone-service
handbook uses `โทรกลับไป` in a callback request at
https://webportal.bangkok.go.th/public/user_files_editor/71/Services/มาตรฐานงานด้านการติดต่อทางโทรศัพท์.pdf . The two
added sentences and Myanmar-script pronunciation are editorial drafts. The
source checks support the topic and lexical usage but do not constitute a
fluent Thai–Myanmar speaker's full-sentence or pronunciation signoff. Ask for
independent fluent review before broad release, as with the existing corpus.

The older 500-row review ledger remains a snapshot of the earlier corpus; the
two new IDs are documented here. Structural validation now expects 502 rows
and reports the expanded audio coverage denominator. Existing lesson grouping
will include the new phrases without changing earlier IDs or progress keys.
