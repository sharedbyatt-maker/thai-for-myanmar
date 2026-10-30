# Weekly League implementation and activation

## Release and hosted verification

PR #24 was merged on 2026-10-30 as
`f96450509d6cb4efff8d917a13eb20f7f7804a02`. The release uses the existing
Render static site, `srv-dat7fp3bc2fs73bg6iag`, at
https://thai-for-myanmar-web-preview.onrender.com/.
The PR's final verification notes record the production deploy and runtime check;
older pre-release blockers are resolved as described below.

The existing Free Supabase project is `zkdghtwwjktokkykgefa`
(`thai-for-myanmar-leagues`), Singapore, organization `bufhfhpikxiqfethjqml`.
Public frontend config contains the project URL and an enabled publishable key;
no server secret or service-role key is used in the client.

Hosted migration versions are `20261030113624` (`weekly_leagues`) and
`20261030113630` (`question_catalog`). They match the two checked-in migrations
by name, whose filenames have earlier timestamps. Both are already applied:
**do not recreate the project or apply duplicate migrations to reconcile dates**.
The hosted catalog contains 502 questions / 112 lessons.

Google sign-in and PKCE were tested on the hosted PR preview with the original
owner and an additional user-selected Google account. The additional account
returned to the app, chose a public alias/avatar, joined a real 3-person board,
answered five questions correctly and received 45 server-confirmed points.
A full browser refresh restored the session and the same score. Earlier owner
verification also covered logout/login, opt-out/rejoin without duplicate
membership, and idempotent retry of a completed round. No simulated competitors
or disposable fixture accounts were inserted into the live board.

The app offers Google sign-in only. It requests only basic identity scopes
(`openid`, `email`, `profile`), prompts for account selection, and waits for an
actual Supabase session before loading the board. Public password signup and
recovery are absent: adding them requires production SMTP and end-to-end tests.

All four CI jobs passed on feature head
`3bb6442ab805fd9bb240b59d883c9f719911a961`, run `41062801898`:
PostgreSQL scoring/privacy, source/content/Flutter tests, mobile/desktop Web,
and Android build/emulator verification. The suite includes 28 League, callback,
widget and session tests. Native Android Google OAuth on a device and native iOS
release remain unverified; Android callback scaffolding and manifest fixtures
were checked, and no iOS release is claimed.

Hosted advisor recheck found seven intentional private-table
`rls_enabled_no_policy` INFO notices and one leaked-password-protection warning.
Private tables deliberately deny direct client access; do not add public SELECT
policies to silence these notices. Leaked-password protection is a paid-plan
feature; this Free project uses Google sign-in in the app and no upgrade was made.
[Private-table advisor explanation](https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy).

## Rules

- Optional account sign-in and explicit public alias/avatar consent.
- Five tiers: Bronze, Silver, Gold, Diamond, Elephant.
- Up to 20 actual accounts per weekly group; no simulated users.
- Bangkok Monday 00:00 boundaries, computed on the database server.
- Only the League challenge awards competitive points. Local flashcard self-ratings
  and personal XP are never uploaded or accepted as a score.
- A round uses one existing catalog lesson (1–5 questions) with server-generated
  Thai-to-Myanmar choices. Correct unique phrases earn 5 points once per Bangkok
  day; first perfect completion earns 20 once per lesson, within the total
  100-point daily cap. Awards can be truncated at that cap.
- Failed or duplicate requests cannot double-credit. Submit is idempotent for the
  same round, so a network timeout can safely be retried.
- A round expires in 20 minutes and cannot be credited across week rollover. Only
  one active round is returned at a time, with at most 40 created per account/day.
- Ties favor the earlier score achievement, then a stable UUID tie breaker.
- At least five eligible scorers are needed for promotion; the highest quarter
  (rounded up) advances once on next participation. No demotion in this release.
- Opt-out hides the account from its current group and blocks scoring. It preserves
  the auth account and prior-week results. Rejoining resumes the current week's
  points instead of creating a duplicate participant.

## Data protection and limitations

All score tables and answer keys are in `league_private`, have RLS enabled, and
have no direct table grants for anon/authenticated users. Public RPC wrappers run
as invokers. Private definer implementations pin an empty search_path, qualify
objects, verify auth.uid and ownership, and are executable only by authenticated
users. Joining requires an email-confirmed Supabase user. Answers are disclosed
only after an owned, completed submission. No email or auth UUID is returned by
the leaderboard API; only alias, avatar, rank, points and a `mine` flag.

The database serializes awards by profile and group assignment by week/tier.
These controls bound replay/score forgery; they do not establish that an account
is a unique human or stop someone from looking up the bundled translations.
Auth rate limits are in place; CAPTCHA remains unconfigured as documented below.
No cash prizes or paid score boosts are implemented.

## Auth redirects and operations

Supabase Site URL:
`https://thai-for-myanmar-web-preview.onrender.com/`.
Exact allowed redirects configured for this release:

- Production: `https://thai-for-myanmar-web-preview.onrender.com/?league-auth=1`
- PR preview: `https://thai-for-myanmar-web-preview-pr-24.onrender.com/?league-auth=1`
- Android: `com.sharedbyatt.thaiformyanmar://league-callback/`
- The existing password-recovery redirect was retained for compatibility.

Google's Web OAuth client returns to
`https://zkdghtwwjktokkykgefa.supabase.co/auth/v1/callback`.
Keep its client secret exclusively in the provider configuration. Keep nonce
checks and the email requirement enabled, and anonymous sign-ins disabled.
Web callbacks must return to the initiating origin so the PKCE verifier is
available; explicitly allowlist each new preview callback before using it.

Android platform files are generated by Flutter. Run
`python3 tool/configure_android.py` after generation: it preserves the launcher,
adds Internet permission and the app_links callback, and disables Flutter's
competing deep-link handler. Test real device OAuth before an Android public
release. Native iOS callback configuration and release are separate work.

The selected Render workspace remains Happy's workspace,
`tea-dapr1v8u01pc73dlng40`. Production auto-deploys `main`; do not trigger a
second manual deploy after a merge. PR preview generation was returned to Manual.
No replacement project, paid service or paid plan was created.

Inspected Auth limits were 30 sign-up/sign-in requests per five minutes per IP,
150 refreshes per five minutes and 30 token verifications per five minutes.
CAPTCHA is not configured. Existing rate limits and scoring checks do not prove
unique humans or prevent multiple Google accounts. No cash prizes or paid score
boosts are supported. Reassess abuse controls as the audience grows.

Free Supabase projects can pause after prolonged inactivity; monitor the project
and revisit capacity, backups and service guarantees before promising an SLA.

## Preserved learning content

502 phrases across 35 categories remain available with the 112-lesson path.
All 990 selected audio forms are bundled (488 male, 488 female, 14 shared),
covering every phrase with no missing mapping. The user's locally generated
Windows Kokoro audio remains unchanged. Structural validators do not certify
native pronunciation or language fluency.

## Tests

```sh
python tool/league/build_seed.py
npm ci --prefix tool/league
npm test --prefix tool/league
flutter test test/league_screen_test.dart test/widget_test.dart test/study_session_test.dart
flutter analyze --fatal-infos
flutter build web --release
```

The Node suite executes real PostgreSQL SQL using pinned PGlite 0.5.13, with test
Auth roles/users. It checks all 502 questions/112 lessons, private access denial,
verified account requirement, 20-member group capacity, round ownership, minimum
age, answer checking, duplicate submissions, daily cap, opt-out and rollover.
It does not replace a hosted Supabase/Auth integration test or advisors.

## Official references checked 2026-10-30

- https://supabase.com/changelog.md
- https://supabase.com/docs/guides/database/functions
- https://supabase.com/docs/guides/database/postgres/row-level-security
- https://supabase.com/docs/guides/auth/auth-smtp
- https://supabase.com/docs/guides/platform/free-project-pausing
