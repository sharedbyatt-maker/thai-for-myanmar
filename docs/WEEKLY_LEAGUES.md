# Weekly League implementation and activation

## Current release status

PR #24 is ready for review on `codex/weekly-leagues`: the owner explicitly
authorized removing Draft status to enable preview testing before hosted login
verification. This does not authorize skipping the hosted checks before merge.
Main remains `b88c99963210d198a4e8b0c2ae234b988061e1dc`; Render deployment
`dep-dbi7hgh7lnhs73e6tme0` is still live at
`a121d20ee104ec10afd3b4c35155a6e584fa8e5e`. League is not deployed to production.

Fresh hosted verification on 2026-10-30 confirmed the existing Free Supabase
project `zkdghtwwjktokkykgefa` (`thai-for-myanmar-leagues`), Singapore, in
organization `bufhfhpikxiqfethjqml`, is `ACTIVE_HEALTHY`.

Hosted migration history uses versions `20261030113624` (`weekly_leagues`) and
`20261030113630` (`question_catalog`). Their names match the two checked-in SQL
files, whose filenames have earlier timestamps. Both are already applied;
**do not apply duplicate migrations to reconcile filename timestamps**.

The hosted catalog contains 502 questions / 112 lessons. Before real login testing,
profiles and rounds were both zero; real owner sign-in testing has since created
one actual profile, one weekly membership and one completed round. No bots or
fabricated competitors were inserted. All seven private tables have RLS and deny direct SELECT to anon and
authenticated roles. All five public League wrappers are SECURITY INVOKER; anon
has no execute privilege, authenticated does. An actual anonymous HTTP RPC request
returned 401 / PostgreSQL code `42501`. Security/performance advisors reported no
ERROR/WARNING findings; seven intentional RLS-without-policy INFO notices remain.
No public SELECT policy was added. See the
[advisor explanation](https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy).

The enabled modern publishable key and URL were obtained from the existing
project and written to `assets/data/league_config.json`. No secret key is used.
An authenticated-by-publishable-key Auth settings request confirmed Google is
**enabled** after the owner saved the Google client/provider configuration, email is enabled and anonymous sign-ins are disabled. This checks
provider availability, not successful account login.

The earlier handover records hosted scoring/retry/opt-out transaction tests,
rolled back with no test profiles left. This continuation reran the local real
PostgreSQL/PGlite suite; real hosted Google OAuth and scoring still need testing.
The original owner successfully signed into Supabase with ChatGPT using
revengeblaze2025@gmail.com. The dashboard confirmed the correct organization and
project. An expired OAuth state was resolved by a fresh login using the same
account. The earlier browser authorization blocker is resolved.

The exact web and Android redirect URLs below were saved and verified in the
Supabase dashboard; the existing recovery redirect was retained. Auth rate limits
were inspected: sign-up/sign-in 30 requests per 5 minutes per IP, refresh 150 per
5 minutes, token verification 30 per 5 minutes. CAPTCHA is disabled; no CAPTCHA
secret is configured, and protection was not enabled without a working client
integration. These observations do not certify resistance to multi-account abuse.

The frontend now uses Google OAuth only; unusable public email signup/recovery
controls were removed. OAuth launch is not treated as successful login. Auth
session changes reload the board, web returns reopen League, and Android callback
routing is configured by `tool/configure_android.py`. Real Google login remains
unverified. Web OAuth callbacks now stay on the initiating app origin, so PR
previews can complete PKCE without redirecting into the production build. Each
preview callback must be explicitly added to the Supabase allowlist before testing. Google Cloud returned “Site Unavailable — Unable to access this site”
in this continuation's cloud browser, including one reload. This is an access
limitation of that browser, not evidence that Google is down.

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
Configure auth rate limits and CAPTCHA before public launch. No cash prizes or
paid score boosts are implemented.

## Preview testing status

All four CI jobs for code commit `7fb0604ecf827179532f38b06f84f3ed75d5d6ca`
passed, including Android and mobile/desktop Web flows. On the next change, rerun
checks for the current head. Google provider availability is now enabled, but
the public non-team account check remains pending. The owner-account hosted
flow has now passed login, join, challenge, score, refresh and session restoration.

A local preview cannot be reached by this cloud browser (connection refused).
The owner successfully signed into Happy's Render workspace with
`happylearnkids2025@gmail.com` using the secure email/password form. Supabase stays
on `revengeblaze2025@gmail.com`.

The existing Render static site's PR preview mode was set to Manual and PR #24
has `render-preview`. With no preview appearing, PR #24 was marked ready with
explicit owner approval. Its label remains intact. A proposed removal/re-add of
the label was rejected by automatic approval review because it could disrupt the
requested preview; removal was not performed. The repository has exactly one
open PR (#24), so preview generation was set to Automatic on this service alone
as an additive alternative. Return it to Manual after integration testing.
No paid service or replacement app was created; production remains unchanged.

CI run `41057386131` on code commit `36e03cf8fd014bc92c7007b2e7f798126cbc4a13`
passed source/tests, PostgreSQL and Web jobs. Android built its APKs but the test
harness failed before running app tests: `Failed to start Dart Development
Service`. The failed Android job was rerun; CI run 41057386131 is now successful. The
next code change must pass its own CI before merge.

## Real hosted verification on the PR preview

Preview `srv-dbi98kfb9u1s73ds71mg` deployed commit
`5df304d025eac2530d1ce0168e65aec12d95eb4b` live via
`dep-dbi98knb9u1s73ds71pg`. Its callback was explicitly allowlisted:
`https://thai-for-myanmar-web-preview-pr-24.onrender.com/?league-auth=1`.

Owner Google sign-in successfully returned through PKCE to League and created a
confirmed Auth account. Nickname `Revenge Blaze` and elephant avatar joined a
real 1/20-person Bronze board. The server chose five questions; answering all five
correctly produced **45 points** (25 phrase points + 20 first-completion bonus).
Both app and hosted database confirmed this result.

Full page refresh and logout/login restored the same 45 points. Opt-out hid the
profile; rejoining restored its original score with exactly one membership row.
A hosted SQL transaction retried the already-finished real round using its owner
claim and checked identical result/unchanged credits, then rolled back. This
checks server retry behavior; it is separate from the browser OAuth test.

The SDK/Google reused the previously signed-in browser account automatically.
The login request now includes `prompt=select_account` so users can explicitly
choose their Google account and a non-team account can be tested before launch.
Public-account verification and production deployment are still pending.

## Activation steps for the maintainer

1. Continue using the existing project `zkdghtwwjktokkykgefa`. Hosted migration
   names and private tables were rechecked above; do not recreate or reapply them.
2. Public config is now populated using the enabled `sb_publishable_...` key.
   Never commit service-role/secret keys, management tokens or database passwords.
3. In Google Auth Platform, use an owner-authorized project, External audience,
   app name **Thai for Myanmar**, owner-selected support/contact email and only
   `openid`, `email`, `profile` scopes. Configure a **Web application** OAuth client:
   - JavaScript origin: `https://thai-for-myanmar-web-preview.onrender.com`
   - Redirect URI: `https://zkdghtwwjktokkykgefa.supabase.co/auth/v1/callback`
   - Public release must not remain restricted to Testing/test users.
   - No billing, paid APIs, Gmail/Drive/Calendar access or Google TTS is needed.
4. Enter the Client ID/Secret directly in the existing project's Google provider
   settings, not chat, Git or logs. Enable Google while preserving nonce checks
   and the requirement for an email. Keep anonymous sign-in disabled and email
   confirmation enabled. Inspect auth rate limits/CAPTCHA before launch.
5. Already saved and verified: Supabase Site URL is
   `https://thai-for-myanmar-web-preview.onrender.com/`. The exact allowed
   redirect URLs now include (the Google client still redirects only to Supabase's callback):
   - Web: `https://thai-for-myanmar-web-preview.onrender.com/?league-auth=1`
   - Android: `com.sharedbyatt.thaiformyanmar://league-callback/`
   PKCE is handled by the pinned Supabase Flutter SDK. On web, start and complete
   sign-in in the same browser. On Android, generate scaffolding and run
   `python3 tool/configure_android.py`; app_links receives the callback and opens
   League for warm and cold starts. iOS native configuration/release is not done.
6. Run hosted security/performance advisors, inspect grants/RLS and check anon
   denial. Do not add public SELECT policies to silence private-table INFO notices.
7. With real owner-controlled accounts (including a non-team Google account),
   test login → alias/avatar → join → real board → challenge → server score →
   identical retry → refresh → logout/login restore → opt-out/rejoin. Verify
   callback denial/cancellation and Android return routing. No fake competitors.
8. Run CI and release builds. Only after public auth and hosted checks pass, mark
   PR #24 ready and merge. Observe the auto-deploy for the actual merge commit;
   do not trigger a duplicate deploy. Verify released login/scoring before calling
   League live. Keep this draft blocked until those requirements are met.

Supabase's default SMTP does not support general public email signup. Email auth
is intentionally absent from the UI; reintroducing it requires working production
SMTP, confirmation and password recovery tests.

Free Supabase projects can pause after low activity over seven days. Revisit
capacity/backups and service guarantees before treating a free tier as an SLA.

## Verification for this continuation

- Flutter 3.47.9 / Dart 3.13.7; analyzer clean.
- 28 League/widget/session and callback tests passed, including OAuth launch versus actual
  session arrival, sign-out clearing the board and failed-launch retry.
- PostgreSQL/PGlite scoring/privacy suite passed; generated seed unchanged.
- Content/audio validators passed (502 phrases / 990 mappings).
- Android manifest fixture passed: valid XML, preserved launcher, callback,
  internet permission and idempotent configuration. Native OAuth is unverified.
- Release JavaScript Web build passed. Optional Wasm dry-run warnings remain in
  the existing flutter_tts dependency; no Wasm release is claimed.
- No main merge or Render deployment has been performed.

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
