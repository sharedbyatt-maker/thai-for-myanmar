# One-click Thai audio ZIP (Windows / GitHub web)

This manual workflow generates original Thai MP3s with Google Cloud Chirp 3 HD and prepares the exact manifest expected by the existing asset-first player. It does not use another website's audio, commit generated files, deploy the app, or put credentials into Flutter.

Current corpus: 502 phrases, 488 paired male/female phrases and 14 neutral phrases = **990 MP3 files**, 21,629 source characters. Counts are calculated again on every run. Neutral forms use the female voice; male/female forms use Charon/Kore respectively. These are initial voice choices, not a claim of reviewed pronunciation quality.

## One-time setup

1. Merge the audio-generation pull request into `main`. GitHub only lists a new `workflow_dispatch` workflow after it exists on the default branch.
2. In [Google Cloud Console](https://console.cloud.google.com/), create or select a project, attach an active billing account, and enable **Cloud Text-to-Speech API** (`texttospeech.googleapis.com`). Generation can incur charges. Review [current pricing](https://cloud.google.com/text-to-speech/pricing), set a project budget alert, and review API quotas. Budget alerts are notifications, not a hard spending cap.
3. Under **IAM & Admin → Service Accounts**, create a dedicated service account for this project. Grant **Service Usage Consumer** (`roles/serviceusage.serviceUsageConsumer`) on the billing/quota project. Do not grant Owner or Editor just for this workflow. The workflow uses that same project's ID from the credential JSON as the quota project.
4. On that service account, use **Keys → Add key → Create new key → JSON**. Keep this file private. If organization policy prevents JSON keys, use an administrator-approved Workload Identity Federation setup instead; do not disable the organization's policy. The checked-in workflow currently expects JSON authentication.
5. In this GitHub repository, open **Settings → Secrets and variables → Actions → New repository secret**. Name it **`GOOGLE_TTS_CREDENTIALS_JSON`**. Paste the entire JSON file contents as the value. Do not paste the key into chat, source files, issues or pull requests. Delete the downloaded local copy when you have securely stored the secret and no longer need it. Revoke the key when the generation project is finished.

## Generate everything

1. Open **Actions → Generate Thai audio ZIP → Run workflow**.
2. Select branch **main** and scope **all**.
3. Check **Generate audio using Google Cloud (may incur charges)** and click **Run workflow**. Leaving it unchecked produces a free plan only; no cloud credentials are read.
4. Open the run and wait for completion. Download **thai-audio-all-…** from **Artifacts** at the bottom of the run page. GitHub downloads this as a ZIP. No Flutter, Android SDK or Mac is needed on your computer.

For the first run, scope **sample** generates the first five phrases (nine files in the current dataset), so you can listen before generating all 990. A later all run reuses matching cached sample audio.

## What is in the ZIP?

The artifact can contain `thai-audio/` and `thai-audio-plan/` folders. In `thai-audio/`:

- `assets/audio/thai/*.mp3`: one file per selected phrase/form.
- `assets/data/thai_audio_manifest.json`: exact Thai text and phrase/form mappings.
- `generation-report.json`: complete/incomplete status, generated/reused counts, voices, missing forms and pending human review.
- `REVIEW_BEFORE_IMPORT.txt`: import reminder.

The plan folder contains `generation-plan.json`; it is not an audio bundle. Files expire from GitHub Artifacts after 30 days, so download and retain the ZIP.

## Retry and cost behavior

Each successful MP3 is decoded with ffmpeg and checkpointed with a content hash. A rerun reuses verified cached files only if phrase text, form, voice and encoding still match. Cache is best-effort and may expire or be evicted; if unavailable, synthesis is charged again. Do not promise zero additional cost for reruns. Transient HTTP failures have bounded retries, which may also create additional provider usage. Request timeouts are not automatically retried within the same call.

The script preflights both Thai voices, stops at the first unrecoverable failure, preserves the partial bundle, and refuses corpora above 100,000 source characters. This is a size guard, not a dollar cap. A failed run's artifact is not evidence of full coverage. Look for **`status: complete`** and `readyForms == requestedForms` in the report. For the current all scope, both counts should be 990. If interrupted hard by runner cancellation/timeout, the latest successful cache files may still be recoverable, but a complete report is not guaranteed.

Common setup problems: missing secret, billing not enabled, API disabled, insufficient Service Usage Consumer permission, voice unavailable, or quota/rate limits. Do not upload logs containing credentials. The script suppresses provider response bodies and credential details.

## Put the reviewed files into the app

Generated is not the same as human-reviewed. Listen to the male/female particles, Thai tones, vowel length, numbers, placeholders and emergency phrases with a fluent Thai reviewer. First test the sample on Android and the browser. The workflow leaves the production manifest unchanged until this review is done.

After approval, extract the `assets/` contents from the audio bundle into the repository root on a new branch. Replace the audio manifest, include the matching MP3 files, run `python tool/validate_audio_manifest.py`, and run the existing Flutter checks/builds. If replacing an older audio pack, remove only obsolete MP3 files identified by the validator; keep all mapped files. Submit a PR with the report and review notes, then merge to make the app use bundled audio automatically.

Android bundles the files for offline playback. Web serves the same files, but this workflow does not implement offline browser caching. This change generates normal-speed recordings; a slow-playback UI is a separate follow-up.

## Official references

- [Thai voices](https://docs.cloud.google.com/text-to-speech/docs/list-voices-and-types)
- [Chirp 3 HD](https://docs.cloud.google.com/text-to-speech/docs/chirp3-hd)
- [Cloud TTS authentication](https://docs.cloud.google.com/text-to-speech/docs/authentication)
- [Synthesis REST API](https://docs.cloud.google.com/text-to-speech/docs/reference/rest/v1/text/synthesize)
