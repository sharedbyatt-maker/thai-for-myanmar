# Weekly League implementation and activation

## Current release status

Prepared on `codex/weekly-leagues`; do not activate or merge until a real Supabase
project, public authentication and end-to-end tests are verified. The current
live Flutter app remains unchanged. `assets/data/league_config.json` intentionally
contains empty values and never fabricates competitors when unconfigured.

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

## Activation steps for the maintainer

1. Connect Supabase project access. Inspect available organizations and existing
   projects; use a dedicated Free-plan project if the available quota permits.
   Do not choose a paid plan without the owner's explicit budget authorization.
2. Apply the two ordered SQL files under `supabase/migrations/` to the new project.
   The files were created with Supabase CLI 2.122.0 `migration new`; the second is
   generated from the bundled content by `python tool/league/build_seed.py`.
3. Configure Auth: email/password enabled, email confirmation required, minimum
   password length 8, anonymous sign-in disabled. Set Site URL to
   `https://thai-for-myanmar-web-preview.onrender.com/` and explicitly allow
   `https://thai-for-myanmar-web-preview.onrender.com/?league-recovery=1`.
4. Configure production email delivery or another verified provider before opening
   public registration. Supabase's default SMTP only sends to organization team
   addresses; it is not a public production mail service. Test confirmation and
   password recovery (same-browser PKCE) using accounts controlled by the owner.
5. Put only the project's HTTPS URL and **publishable** `sb_publishable_...` key in
   `assets/data/league_config.json`. Never put secret/service-role keys, management
   tokens, database passwords or email credentials in Git or app assets.
6. Run Supabase security/performance advisors and inspect grants, RLS and query
   plans. Verify anonymous denial, two-account isolation, real score submission,
   replay safety, opt-out and rollover. Do not insert test bots into a public board.
7. Run local/CI checks, review mobile/desktop UI, merge and observe the specific
   Render deployment becoming live. Verify the actual released frontend against
   the real backend. Then remove this pre-release status and record project ref,
   migration status and tested commit in this document (no credentials).

Free Supabase projects can pause after low activity over seven days. Revisit
capacity/backups and service guarantees before treating a free tier as an SLA.

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
